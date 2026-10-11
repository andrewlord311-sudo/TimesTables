extends Node3D
## Dino Ten: Felix's dinosaur number-bonds game.
## The valley with its five play spots and a park. Pick 5 or 10, pick a place,
## play five rounds there, earn eggs; every few eggs one hatches into the park.
##
## Run with `-- --bot` to have a robot play everything (for testing), or
## `-- --bot --only=nest` for one activity.

signal tapped(body: Node)
signal arrived

const Dino := preload("res://scripts/dino.gd")
const ROUNDS := 5
const NAMES := {"Trex": "T. rex", "Triceratops": "Triceratops", "Parasaurolophus": "Parasaurolophus",
	"Stegosaurus": "Stegosaurus", "Apatosaurus": "Apatosaurus", "Velociraptor": "Velociraptor"}
const FACTS := {
	"Trex": "T. rex had big teeth. It ate meat.",
	"Triceratops": "Triceratops had three horns. It ate plants.",
	"Parasaurolophus": "It had a long crest on its head. It ate plants.",
	"Stegosaurus": "It had big plates on its back and spikes on its tail.",
	"Apatosaurus": "It had a very long neck. It ate leaves from tall trees.",
	"Velociraptor": "It was fast and had feathers. It was as big as a turkey.",
}

var world: Node3D
var sfx: Node
var progress: Node
var ui: CanvasLayer
var cam: Camera3D
var rex: Node3D
var activity: Node3D
var expected := -1          # the right answer to the current question (for the bot)
var bot := false
var bot_only := ""
var bot_targets := [5, 10]
var _cam_look := Vector3.ZERO
var _cam_from := Vector3.ZERO
var _cam_to := Vector3.ZERO
var _look_from := Vector3.ZERO
var _look_to := Vector3.ZERO
var _cam_t := 1.0
var _cam_secs := 1.0
var _walk_target := Vector3.ZERO
var _walking := false
var _walk_speed := 3.0
var _bot_clock := 0.0
var _busy := false
var rex_scale_locked := false   # e.g. while Rex is Baby Rex at the river

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	bot = "--bot" in args
	if "--fast" in args:
		Engine.time_scale = 4.0
	for a in args:
		if a.begins_with("--only="):
			bot_only = a.trim_prefix("--only=")
		if a.begins_with("--target="):
			bot_targets = [int(a.trim_prefix("--target="))]
	if "--shots" in args:
		_shots.call_deferred()
	world = preload("res://scripts/world.gd").new()
	add_child(world)
	sfx = preload("res://scripts/sfx.gd").new()
	add_child(sfx)
	progress = preload("res://scripts/progress.gd").new()
	add_child(progress)
	if bot:
		progress.no_save = true
		progress.eggs = 0
		progress.park = []
		progress.stats = {}
	ui = preload("res://scripts/ui.gd").new()
	add_child(ui)
	ui.set_eggs(progress.eggs)
	ui.activity_chosen.connect(_on_activity)
	ui.target_chosen.connect(func(t):
		progress.target = t
		progress.save_game()
		ui.show_menu(true, t)
		sfx.play("pop"))
	ui.home_pressed.connect(_on_home)
	rex = Dino.new()
	add_child(rex)
	rex.setup("Trex", 3.0)
	rex.sfx = sfx
	_grow_rex()
	rex.position = world.spot("menu")["at"]
	cam = Camera3D.new()
	cam.fov = 50
	add_child(cam)
	var m: Dictionary = world.spot("menu")
	cam.position = m["cam"]
	_cam_look = m["look"]
	cam.look_at(_cam_look)
	_cam_to = cam.position
	_look_to = _cam_look
	ui.show_menu(true, progress.target)
	if bot:
		_run_bot.call_deferred()

func _grow_rex() -> void:
	if rex_scale_locked:
		return
	rex.scale = Vector3.ONE * lerpf(0.7, 1.05, progress.growth())

# --- camera and walking -----------------------------------------------------------

func camera_to(pos: Vector3, look: Vector3, seconds := 1.6) -> void:
	_cam_from = cam.position
	_look_from = _cam_look
	_cam_to = pos
	_look_to = look
	_cam_t = 0.0
	_cam_secs = seconds

func camera_spot(name: String, seconds := 1.6) -> void:
	var s: Dictionary = world.spot(name)
	camera_to(s["cam"], s["look"], seconds)

## Walk Rex to a point (await it). Run if it's far.
func walk_rex(p: Vector3, speed := 0.0) -> void:
	p.y = 0
	_walk_target = p
	_walk_speed = speed if speed > 0.0 else (7.0 if rex.position.distance_to(p) > 8.0 else 3.0)
	_walking = true
	await arrived

func face(node: Node3D, p: Vector3) -> void:
	var d := p - node.position
	node.rotation.y = atan2(d.x, d.z)

func _process(delta: float) -> void:
	if _cam_t < 1.0:
		_cam_t = min(1.0, _cam_t + delta / _cam_secs)
		var e := ease(_cam_t, -2.2)
		cam.position = _cam_from.lerp(_cam_to, e)
		_cam_look = _look_from.lerp(_look_to, e)
		cam.look_at(_cam_look)
	if _walking:
		var to := _walk_target - rex.position
		to.y = 0
		if to.length() < 0.12:
			_walking = false
			rex.play("Idle")
			arrived.emit()
		else:
			var step: float = minf(_walk_speed * delta, to.length())
			rex.position += to.normalized() * step
			var want := atan2(to.x, to.z)
			rex.rotation.y = lerp_angle(rex.rotation.y, want, 1.0 - exp(-delta * 9.0))
			rex.play("Run" if _walk_speed > 4.5 else "Walk", _walk_speed / (6.0 if _walk_speed > 4.5 else 2.6))
	elif not rex.is_playing("Attack") and not rex.is_playing("Jump"):
		rex.play("Idle")
	if bot and activity and activity.has_method("bot_tick"):
		_bot_clock += delta
		if _bot_clock > 0.35:
			_bot_clock = 0.0
			activity.bot_tick()

# --- tapping things in the world --------------------------------------------------

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_tap(e.position)
	elif e is InputEventKey and e.pressed and e.keycode == KEY_SPACE and not e.echo:
		rex.roar()

func _tap(screen: Vector2) -> void:
	var from := cam.project_ray_origin(screen)
	var dir := cam.project_ray_normal(screen)
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 200.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit and hit.collider:
		tapped.emit(hit.collider)
		return
	# On the menu, tapping the ground walks Rex there, just for fun.
	if activity == null and not _busy and dir.y < -0.01:
		var p := from + dir * (-from.y / dir.y)
		if p.length() < 30:
			walk_rex(p)

## Make a node tappable: a sphere of `radius` round it. Returns the body.
func tappable(node: Node3D, radius: float, offset := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = radius
	shape.shape = sph
	shape.position = offset
	body.add_child(shape)
	node.add_child(body)
	return body

# --- flow ---------------------------------------------------------------------------

func _on_activity(name: String) -> void:
	if _busy or activity:
		return
	_busy = true
	ui.show_menu(false)
	sfx.play("pop")
	var script: GDScript = load("res://scripts/activities/%s.gd" % name)
	if script == null or not script.can_instantiate():
		push_error("couldn't load activity %s" % name)
		ui.show_menu(true, progress.target)
		_busy = false
		return
	activity = script.new()
	activity.set("game", self)
	add_child(activity)
	await activity.run()
	if is_instance_valid(activity):
		activity.queue_free()
	activity = null
	ui.ask("")
	ui.hide_hint()
	ui.show_action("")
	ui.clear_answers()
	camera_spot("menu", 2.0)
	ui.show_menu(true, progress.target)
	walk_rex(world.spot("menu")["at"])
	_busy = false

func _on_home() -> void:
	if activity and activity.has_method("stop"):
		activity.stop()

## Correct! An egg, and maybe a hatching. Await it.
func reward() -> void:
	sfx.play("chime")
	var hatched: Dictionary = progress.add_egg()
	ui.set_eggs(progress.eggs)
	ui.pulse_eggs()
	_grow_rex()
	if not hatched.is_empty():
		await hatch(hatched)

## An egg appears by Rex, wobbles, cracks, and a baby pops out.
func hatch(info: Dictionary) -> void:
	# Hatch somewhere in clear view: the activity's own spot if it has one,
	# otherwise just in front of what the camera is looking at.
	var at: Vector3 = _cam_look + (cam.position - _cam_look).normalized() * 2.4
	if activity and activity.get("hatch_spot") != null:
		at = activity.get("hatch_spot")
	at.y = 0
	var egg := MeshInstance3D.new()
	var em := SphereMesh.new()
	em.radius = 0.35
	em.height = 0.95
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/egg.gdshader")
	em.material = mat
	egg.mesh = em
	egg.position = at + Vector3(0, 0.48, 0)
	add_child(egg)
	await ui.flash("An egg!", 0.6)
	for i in 3:
		sfx.play("crack", 1.0 + i * 0.1)
		var t := create_tween()
		t.tween_property(egg, "rotation:z", 0.3, 0.08)
		t.tween_property(egg, "rotation:z", -0.3, 0.12)
		t.tween_property(egg, "rotation:z", 0.0, 0.1)
		await t.finished
		await get_tree().create_timer(0.25).timeout
	var baby: Node3D = Dino.new()
	add_child(baby)
	baby.setup(info["species"], 1.1, int(info["colour"]))
	baby.sfx = sfx
	baby.position = at
	face(baby, cam.position)
	baby.scale = Vector3.ONE * 0.1
	egg.queue_free()
	sfx.play("squeak")
	var g := create_tween()
	g.tween_property(baby, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	baby.play("Jump")
	await g.finished
	await ui.show_card("A baby %s!" % NAMES[info["species"]], FACTS[info["species"]] + "\nIt is in your park.")
	var off := create_tween()
	off.tween_property(baby, "scale", Vector3.ONE * 0.01, 0.3)
	await off.finished
	baby.queue_free()

## A correct answer: sound, little celebration from Rex, and the egg.
func well_done(text: String) -> void:
	sfx.play("cheer")
	rex.play("Jump")
	await ui.flash(text, 1.4)
	await reward()

## A wrong answer is never "wrong": show the ten frame and say what it is.
func show_me(shown: int, missing: int, text: String) -> void:
	sfx.play("soft")
	ui.show_hint(progress.target, shown, missing)
	await ui.flash(text, 2.2)
	ui.hide_hint()

# --- test bot -------------------------------------------------------------------------

func bot_answer(top: int) -> int:
	if expected >= 0 and randf() < 0.7:
		return expected
	return randi() % (top + 1)

func _run_bot() -> void:
	await get_tree().create_timer(0.5).timeout
	var acts := ["nest", "hide", "river", "dig", "feed", "sky", "park"]
	if bot_only != "":
		acts = Array(bot_only.split(","))
	for t in bot_targets:
		progress.target = t
		for a in acts:
			print("BOT: %s (make %d)" % [a, t])
			_on_activity(a)
			while _busy:
				await get_tree().create_timer(0.2).timeout
	print("BOT: done, eggs=%d park=%d" % [progress.eggs, progress.park.size()])
	get_tree().quit()

## Testing aid: save a screenshot every couple of seconds to look-test/shots/.
func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://look-test/shots"))
	var i := 0
	while true:
		await get_tree().create_timer(2.0, true, false, true).timeout
		var img := get_viewport().get_texture().get_image()
		var tag: String = "menu"
		if activity:
			tag = (activity.get_script() as GDScript).resource_path.get_file().get_basename()
		img.save_png("res://look-test/shots/%03d_%s.png" % [i, tag])
		i += 1
