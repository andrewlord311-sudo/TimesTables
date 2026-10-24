extends "res://scripts/activity.gd"
## Dino World: the park grown into a whole island to explore. Felix steers
## Rex (tap the ground to walk there, or the arrow keys) round a meadow, a
## forest of tall trees, a lake, rocky hills and a smoking volcano. Every kind
## of dinosaur lives here, plus all the babies he has hatched. Tap one for its
## card; the first time he meets a kind it goes in his dino book.
## The island is built far beyond the valley, and only while he is in it.

const Species := preload("res://scripts/species.gd")
const Ptero := preload("res://scripts/pterosaur.gd")
const C := Vector3(0, 0, 170)          # centre of the island
const R := 46.0                        # walkable radius
const AREAS := {
	"meadow":  {"at": Vector3(0, 0, 8),    "r": 14.0, "label": "Meadow"},
	"trees":   {"at": Vector3(-25, 0, -4), "r": 10.0, "label": "Tall trees"},
	"lake":    {"at": Vector3(23, 0, -2),  "r": 9.0,  "label": "Lake"},
	"rocks":   {"at": Vector3(-15, 0, -27),"r": 8.0,  "label": "Rocky hills"},
	"volcano": {"at": Vector3(15, 0, -32), "r": 9.0,  "label": "Volcano"},
}
const LAKE_R := 8.0

var dinos: Array[Node3D] = []
var info := {}                # dino -> {"sp", "home", "goal", "speed", "wait", "baby"}
var mosa: Node3D
var pteros: Array = []
var walk_to := Vector3.ZERO
var walking := false
var cards := 0
var hatch_spot := Vector3.ZERO
var _t := 0.0
var _busy := false
var blockers: Array[Node3D] = []   # big trees and rocks, hidden when they block the view of Rex

func run() -> void:
	game.camera_spot("park", 1.6)
	await game.walk_rex(game.world.spot("park")["at"] + Vector3(0, 0, 4.0))
	if stopped:
		return
	await game.ui.flash("To Dino World!", 0.8)
	_build_island()
	_add_dinos()
	game.rex_driven = true
	game.rex.position = C + Vector3(0, 0, 24)
	game.rex.rotation.y = PI
	walk_to = game.rex.position
	hatch_spot = game.rex.position + Vector3(2, 0, -2)
	_cam(0.01)
	_show_book()
	while not stopped:
		var body = await tap
		if body == null:
			break
		var d := _dino_of(body)
		if d == null or _busy:
			continue
		_busy = true
		await _meet(d)
		_busy = false
		cards += 1
		if game.bot and cards >= 3:
			break
	game.rex_driven = false
	game.rex.position = game.world.spot("park")["at"]
	game.ui.ask("")

func _dino_of(body) -> Node3D:
	if body == null:
		return null
	var n: Node = body
	while n and not info.has(n):
		n = n.get_parent()
	return n as Node3D

## Rex turns to face it, it roars, and up comes its card.
func _meet(d: Node3D) -> void:
	var sp: String = info[d]["sp"]
	walking = false
	game.face(game.rex, d.position)
	game.face(d, game.rex.position)
	if d.has_method("roar"):
		d.roar(1.0 if not info[d]["baby"] else 1.6)
	var first: bool = game.progress.see(sp)
	var title: String = game.NAMES[sp]
	if info[d]["baby"]:
		title = "Your baby " + title
	var text: String = game.FACTS[sp]
	if first:
		game.sfx.play("chime")
		text += "\nNew in your dino book!"
	await game.ui.show_card(title, text)
	_show_book()

func _show_book() -> void:
	var total := 0
	for sp in Species.ALL:
		total += 1
	game.ui.ask("Dino book: %d of %d. Tap a dino!" % [game.progress.seen.size(), total])

# --- moving about -------------------------------------------------------------

func ground_tap(p: Vector3) -> void:
	if _busy:
		return
	p.y = 0
	if Vector2(p.x - C.x, p.z - C.z).length() > R:
		p = C + (p - C).normalized() * R
	walk_to = _out_of_lake(p, 1.5)
	walking = true

func _process(delta: float) -> void:
	if not game.rex_driven:
		return
	_t += delta
	var rex: Node3D = game.rex
	# Arrow keys / WASD steer Rex directly (relative to the screen).
	var steer := Vector3(Input.get_axis("ui_left", "ui_right"), 0, Input.get_axis("ui_up", "ui_down"))
	if Input.is_physical_key_pressed(KEY_A): steer.x -= 1
	if Input.is_physical_key_pressed(KEY_D): steer.x += 1
	if Input.is_physical_key_pressed(KEY_W): steer.z -= 1
	if Input.is_physical_key_pressed(KEY_S): steer.z += 1
	var moving := false
	var speed := 5.5
	if steer.length() > 0.1 and not _busy:
		walking = false
		var step := steer.normalized() * speed * delta
		var np := rex.position + step
		if Vector2(np.x - C.x, np.z - C.z).length() <= R:
			rex.position = _out_of_lake(np, 1.5)
		rex.rotation.y = lerp_angle(rex.rotation.y, atan2(steer.x, steer.z), 1.0 - exp(-delta * 10.0))
		moving = true
	elif walking:
		var to := walk_to - rex.position
		to.y = 0
		if to.length() < 0.2:
			walking = false
		else:
			var far := to.length() > 8.0
			speed = 8.0 if far else 4.5
			rex.position += to.normalized() * minf(speed * delta, to.length())
			rex.position = _out_of_lake(rex.position, 1.5)
			rex.rotation.y = lerp_angle(rex.rotation.y, atan2(to.x, to.z), 1.0 - exp(-delta * 9.0))
			moving = true
	if moving:
		rex.play("Run" if speed > 6.0 else "Walk", speed / (6.0 if speed > 6.0 else 2.6))
	elif not rex.is_playing("Attack") and not rex.is_playing("Jump"):
		rex.play("Idle")
	_cam(0.3)
	_move_dinos(delta)
	_move_sea(delta)

func _cam(seconds: float) -> void:
	var p: Vector3 = game.rex.position
	game.camera_to(p + Vector3(0, 8.0, 10.0), p + Vector3(0, 1.2, -1.0), seconds)
	# Anything big between Rex and the camera (which is always due south) goes see-through.
	for b in blockers:
		var dz := b.position.z - p.z
		b.visible = not (absf(b.position.x - p.x) < 4.0 and dz > -1.5 and dz < 11.0)

func _out_of_lake(p: Vector3, pad: float) -> Vector3:
	var lake: Vector3 = C + AREAS["lake"]["at"]
	var d := Vector2(p.x - lake.x, p.z - lake.z)
	if d.length() < LAKE_R + pad:
		var n := d.normalized() if d.length() > 0.01 else Vector2(1, 0)
		return Vector3(lake.x + n.x * (LAKE_R + pad), p.y, lake.z + n.y * (LAKE_R + pad))
	return p

func _move_dinos(delta: float) -> void:
	for d in dinos:
		var s: Dictionary = info[d]
		if d.has_method("is_playing") and d.is_playing("Attack"):
			continue
		var to: Vector3 = s["goal"] - d.position
		to.y = 0
		if s["wait"] > 0.0:
			s["wait"] -= delta
			d.play("Idle")
			continue
		if to.length() < 0.3:
			s["wait"] = randf_range(1.5, 6.0)
			s["goal"] = _spot_in(s["home"], s["baby"])
			continue
		d.position = _out_of_lake(d.position + to.normalized() * minf(s["speed"] * delta, to.length()), 1.0)
		d.rotation.y = lerp_angle(d.rotation.y, atan2(to.x, to.z), 1.0 - exp(-delta * 4.0))
		d.play("Walk", s["anim"])

func _move_sea(delta: float) -> void:
	var lake: Vector3 = C + AREAS["lake"]["at"]
	if mosa:
		var a := _t * 0.35
		var r := LAKE_R * 0.55
		mosa.position = lake + Vector3(cos(a) * r, -0.35 + sin(_t * 1.3) * 0.08, sin(a) * r)
		mosa.rotation.y = atan2(-sin(a), cos(a)) + PI
		if fmod(_t, 14.0) < delta:
			mosa.play("Jump")
	for p in pteros:
		var node: Node3D = p[0]
		var a: float = _t * p[2] + p[1]
		var c: Vector3 = p[3]
		node.position = c + Vector3(cos(a) * p[4], 9.0 + sin(_t * 0.7 + p[1]) * 1.2, sin(a) * p[4])
		node.rotation = Vector3(0, atan2(-sin(a), cos(a)) + (PI if p[2] < 0 else 0.0), 0.25 * signf(p[2]))

func _spot_in(area: String, baby: bool) -> Vector3:
	var a: Dictionary = AREAS[area]
	for i in 12:
		var ang := randf() * TAU
		var r := sqrt(randf()) * float(a["r"]) * (0.8 if baby else 1.0)
		var p: Vector3 = C + a["at"] + Vector3(cos(ang) * r, 0, sin(ang) * r)
		if area == "lake":
			# along the shore, not in the water
			p = C + a["at"] + Vector3(cos(ang), 0, sin(ang)) * (LAKE_R + 1.5 + randf() * 3.0)
		if Vector2(p.x - C.x, p.z - C.z).length() < R - 1.0:
			return _out_of_lake(p, 1.2)
	return C + a["at"]

# --- who lives here -------------------------------------------------------------

func _add_dinos() -> void:
	# Every kind (two of the smaller plant-eaters), grown-up size.
	for sp in Species.ALL:
		var s: Dictionary = Species.ALL[sp]
		var home: String = s.get("home", "meadow")
		if home == "sky" or home == "water":
			continue
		var count := 2 if float(s.get("size", 2.0)) < 2.7 and home in ["meadow", "lake"] else 1
		for k in count:
			var h: float = float(s.get("size", 2.0)) * 0.85
			_spawn(sp, h, k, home, false)
	# Felix's own babies, in the meadow.
	var park: Array = game.progress.park
	for i in mini(park.size(), 30):
		var p: Dictionary = park[i]
		var sp: String = p["species"]
		var h := 1.1 if not sp in ["Apatosaurus", "Brachiosaurus", "Diplodocus"] else 1.7
		_spawn(sp, h, int(p["colour"]), "meadow", true)
	# The sea monster and the flyers.
	mosa = game.make_dino("Mosasaurus", 1.3)
	add_child(mosa)
	info[mosa] = {"sp": "Mosasaurus", "home": "lake", "goal": Vector3.ZERO, "speed": 0.0, "wait": 0.0, "baby": false, "anim": 1.0}
	game.tappable(mosa, 2.2, Vector3(0, 0.8, 0))
	mosa.play("Walk", 1.0)
	var cols := [[Color(0.95, 0.55, 0.25), Color(0.99, 0.8, 0.55), Color(0.9, 0.3, 0.3)],
		[Color(0.35, 0.62, 0.9), Color(0.75, 0.9, 1.0), Color(0.98, 0.75, 0.25)],
		[Color(0.75, 0.5, 0.88), Color(0.95, 0.85, 1.0), Color(0.98, 0.6, 0.3)]]
	for i in 3:
		var pt: Node3D = Ptero.new()
		add_child(pt)
		pt.setup(cols[i][0], cols[i][1], cols[i][2])
		pt.scale = Vector3.ONE * 1.6
		info[pt] = {"sp": "Pteranodon", "home": "sky", "goal": Vector3.ZERO, "speed": 0.0, "wait": 0.0, "baby": false, "anim": 1.0}
		game.tappable(pt, 2.0, Vector3(0, -0.3, 0.3))
		var centre: Vector3 = C + (AREAS["lake"]["at"] if i < 2 else AREAS["meadow"]["at"])
		pteros.append([pt, i * 2.1, 0.35 if i % 2 == 0 else -0.28, centre, 6.0 + i * 2.0])

func _spawn(sp: String, h: float, colour: int, home: String, baby: bool) -> void:
	var d: Node3D = game.make_dino(sp, h, colour)
	add_child(d)
	d.position = _spot_in(home, baby)
	d.rotation.y = randf() * TAU
	game.tappable(d, maxf(0.7, h * 0.45), Vector3(0, h * 0.5, 0))
	dinos.append(d)
	var speed := clampf(0.7 + h * 0.25, 0.8, 2.2)
	info[d] = {"sp": sp, "home": home, "goal": _spot_in(home, baby), "speed": speed, "wait": randf() * 4.0,
		"baby": baby, "anim": clampf(speed / (0.9 + h * 0.3), 0.6, 1.4)}

# --- the island -------------------------------------------------------------------

func _toon(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.roughness = 0.9
	return m

func _disc(at: Vector3, r: float, y: float, col: Color, h := 0.2) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 48
	cm.material = _toon(col)
	mi.mesh = cm
	mi.position = at + Vector3(0, y - h * 0.5, 0)
	add_child(mi)
	return mi

func _nature(name: String, pos: Vector3, scale: float) -> Node3D:
	var n: Node3D = load("res://assets/nature/%s.gltf" % name).instantiate()
	n.position = pos
	n.scale = Vector3.ONE * scale
	n.rotation.y = randf() * TAU
	add_child(n)
	game.world._windify(n)
	return n

func _free_spot(min_d := 0.0) -> Vector3:
	# somewhere on the island but not on a play area or in the lake
	for i in 30:
		var ang := randf() * TAU
		var r := sqrt(randf()) * (R + 4.0)
		var p := C + Vector3(cos(ang) * r, 0, sin(ang) * r)
		var ok := Vector2(p.x - C.x, p.z - (C.z + 24)).length() > 6.0   # Rex's arrival spot
		for k in AREAS:
			var a: Vector3 = C + AREAS[k]["at"]
			if Vector2(p.x - a.x, p.z - a.z).length() < float(AREAS[k]["r"]) * 0.7 + min_d:
				ok = false
		if ok:
			return p
	return C + Vector3(R, 0, 0)

func _build_island() -> void:
	_disc(C, R + 14.0, 0.0, Color(0.42, 0.7, 0.32), 1.0)
	_disc(C + AREAS["meadow"]["at"], 16.0, 0.01, Color(0.55, 0.8, 0.38))
	_disc(C + AREAS["rocks"]["at"], 10.0, 0.01, Color(0.62, 0.6, 0.52))
	_disc(C + AREAS["volcano"]["at"], 11.0, 0.01, Color(0.5, 0.38, 0.3))
	_disc(C + AREAS["trees"]["at"], 12.0, 0.01, Color(0.3, 0.55, 0.26))
	_disc(C + AREAS["lake"]["at"], LAKE_R + 1.6, 0.02, Color(0.93, 0.85, 0.6))
	var water := _disc(C + AREAS["lake"]["at"], LAKE_R, 0.06, Color(0.3, 0.6, 0.9))
	var wm: StandardMaterial3D = (water.mesh as CylinderMesh).material
	wm.albedo_color = Color(0.3, 0.62, 0.92, 0.85)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.roughness = 0.1
	wm.metallic_specular = 0.8
	# A ring of mountains all round, so it feels like its own land.
	var mm := _toon(Color(0.4, 0.58, 0.32))
	for i in 22:
		var a := TAU * i / 22.0
		var r := R + 16.0 + randf() * 6.0
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.5
		cm.bottom_radius = 9.0 + randf() * 4.0
		cm.height = 10.0 + randf() * 9.0
		cm.radial_segments = 9
		cm.material = mm
		mi.mesh = cm
		mi.position = C + Vector3(cos(a) * r, cm.height * 0.5 - 1.0, sin(a) * r)
		add_child(mi)
	_volcano(C + AREAS["volcano"]["at"] + Vector3(4, 0, -9))
	# Tall trees in the forest, rocks in the hills, plants everywhere.
	for i in 26:
		var a := randf() * TAU
		var r := 3.0 + sqrt(randf()) * 11.0
		var p: Vector3 = C + AREAS["trees"]["at"] + Vector3(cos(a) * r, 0, sin(a) * r)
		blockers.append(_nature(["CommonTree_1", "CommonTree_2", "CommonTree_3", "Pine_2", "TwistedTree_2"][i % 5], p, randf_range(2.2, 3.2)))
	for i in 12:
		var a := randf() * TAU
		var p: Vector3 = C + AREAS["rocks"]["at"] + Vector3(cos(a), 0, sin(a)) * randf_range(3.0, 10.0)
		blockers.append(_nature(["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"][i % 3], p, randf_range(1.2, 2.2)))
	for i in 40:
		blockers.append(_nature(["CommonTree_4", "CommonTree_5", "Bush_Common", "Bush_Common_Flowers", "Fern_1", "Plant_7_Big"][i % 6], _free_spot(2.0), randf_range(1.4, 2.6)))
	for i in 70:
		blockers.append(_nature(["Grass_Common_Tall", "Flower_3_Group", "Flower_4_Group", "Grass_Wispy_Tall", "Clover_1"][i % 5], _free_spot(), randf_range(1.0, 1.8)))
	for k in AREAS:
		var l := Label3D.new()
		l.text = AREAS[k]["label"]
		l.font = game.ui.font
		l.font_size = 110
		l.pixel_size = 0.01
		l.outline_size = 40
		l.outline_modulate = Color(0.25, 0.18, 0.08)
		l.modulate = Color(1, 0.95, 0.6)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.position = C + AREAS[k]["at"] + Vector3(0, 8.5, 0)
		add_child(l)

func _volcano(at: Vector3) -> void:
	var v := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 2.2
	cm.bottom_radius = 9.0
	cm.height = 11.0
	cm.radial_segments = 18
	cm.material = _toon(Color(0.45, 0.33, 0.27))
	v.mesh = cm
	v.position = at + Vector3(0, 5.5, 0)
	add_child(v)
	var lava := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 2.0
	lm.bottom_radius = 2.0
	lm.height = 0.2
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(1, 0.45, 0.1)
	lmat.emission_enabled = true
	lmat.emission = Color(1, 0.4, 0.05)
	lmat.emission_energy_multiplier = 3
	lm.material = lmat
	lava.mesh = lm
	lava.position = at + Vector3(0, 11.05, 0)
	add_child(lava)
	var smoke := CPUParticles3D.new()
	smoke.amount = 20
	smoke.lifetime = 7
	smoke.preprocess = 7
	var puff := SphereMesh.new()
	puff.radius = 1.1
	puff.height = 2.2
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.85, 0.85, 0.88, 0.85)
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.vertex_color_use_as_albedo = true
	puff.material = pmat
	smoke.mesh = puff
	smoke.direction = Vector3(0.2, 1, 0)
	smoke.spread = 12
	smoke.initial_velocity_min = 1.2
	smoke.initial_velocity_max = 2.0
	smoke.gravity = Vector3(0.2, 0.1, 0)
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.9))
	grad.set_color(1, Color(1, 1, 1, 0))
	smoke.color_ramp = grad
	smoke.position = at + Vector3(0, 11.5, 0)
	add_child(smoke)

# --- test bot ---------------------------------------------------------------------

var _tour := -1
func bot_tick() -> void:
	if _busy or dinos.is_empty():
		return
	# `--tour`: walk round every area without tapping (for screenshots), then stop.
	if "--tour" in OS.get_cmdline_user_args():
		if walking:
			return
		_tour += 1
		var keys := AREAS.keys()
		if _tour >= keys.size():
			tap.emit(null)
			return
		ground_tap(C + AREAS[keys[_tour]]["at"] + Vector3(0, 0, AREAS[keys[_tour]]["r"]))
		return
	if randf() < 0.5:
		ground_tap(dinos[randi() % dinos.size()].position + Vector3(2, 0, 2))
		return
	var d := dinos[randi() % dinos.size()]
	for c in d.get_children():
		if c is StaticBody3D:
			game.tapped.emit(c)
			return
