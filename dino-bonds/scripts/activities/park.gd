extends "res://scripts/activity.gd"
## My Park: every dinosaur Felix has hatched wanders the meadow. Tap one to
## see its card. 🏠 to go back.

var at := Vector3.ZERO
var babies: Array[Node3D] = []
var goals := {}
var _left := false

func run() -> void:
	at = game.world.spot("park")["at"]
	game.camera_spot("park", 2.2)
	await game.walk_rex(at + Vector3(4.0, 0, 2.0))
	var park: Array = game.progress.park
	if park.is_empty():
		game.ui.ask("Win eggs to fill your park!")
		await wait(2.5)
		return
	game.ui.ask("Your park: %d dinos! Tap one." % park.size())
	for i in min(park.size(), 18):
		var info: Dictionary = park[i]
		var d: Node3D = Dino.new()
		add_child(d)
		d.setup(info["species"], 1.15 if info["species"] != "Apatosaurus" else 1.6, int(info["colour"]))
		d.sfx = game.sfx
		d.position = _random_spot()
		d.set_meta("species", info["species"])
		game.tappable(d, 0.9, Vector3(0, 0.6, 0))
		babies.append(d)
		goals[d] = d.position
	var shown := 0
	while not stopped:
		var body = await tap
		if body == null:
			break
		var d: Node3D = body.get_parent()
		if not babies.has(d):
			continue
		var sp: String = d.get_meta("species")
		d.roar(1.6)
		await game.ui.show_card(game.NAMES[sp], game.FACTS[sp])
		shown += 1
		if game.bot and shown >= 2:
			break

func _random_spot() -> Vector3:
	var a := randf() * TAU
	var r := sqrt(randf()) * 5.0
	return at + Vector3(cos(a) * r, 0, sin(a) * r * 0.6)

func _process(delta: float) -> void:
	for d in babies:
		var to: Vector3 = goals[d] - d.position
		if to.length() < 0.2:
			if randf() < delta * 0.4:
				goals[d] = _random_spot()
			elif not d.is_playing("Attack"):
				d.play("Idle")
			continue
		d.position += to.normalized() * min(1.2 * delta, to.length())
		d.rotation.y = lerp_angle(d.rotation.y, atan2(to.x, to.z), 1.0 - exp(-delta * 6.0))
		if not d.is_playing("Attack"):
			d.play("Walk", 0.9)

func bot_tick() -> void:
	if babies.is_empty():
		return
	var d := babies[randi() % babies.size()]
	for c in d.get_children():
		if c is StaticBody3D:
			game.tapped.emit(c)
			return
