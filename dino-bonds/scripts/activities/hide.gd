extends "res://scripts/activity.gd"
## Hide and Seek: a herd of 5 or 10 little dinosaurs walks in. Some wander
## behind the big bush. "6 can see. How many hide?" Then the bush rustles and
## the hiders pop back out, so the answer is always shown, never just marked.

var herd: Array[Node3D] = []
var spots: Array[Vector3] = []
var bush_root: Node3D
var at := Vector3.ZERO

func run() -> void:
	at = game.world.spot("hide")["at"]
	game.camera_spot("hide")
	_bush()
	await game.walk_rex(at + Vector3(6.6, 0, 0.4))
	game.face(game.rex, at)
	var species: String = ["Triceratops", "Stegosaurus", "Velociraptor", "Parasaurolophus"][randi() % 4]
	_make_herd(species)
	# They walk in from the left.
	for i in herd.size():
		herd[i].position = spots[i] + Vector3(-9.0, 0, 0)
		herd[i].visible = true
	await _walk_all(range(herd.size()), func(i): return spots[i], 2.4)
	for r in game.ROUNDS:
		if stopped:
			break
		game.ui.set_rounds(r, game.ROUNDS)
		var see: int = game.progress.pick_part()
		var hide_n := target() - see
		var order := range(herd.size())
		order.shuffle()
		var hiders: Array = order.slice(0, hide_n)
		# The hiders walk round behind the bush.
		game.ui.ask("Some go to hide…")
		await _walk_all(hiders, func(i): return _behind(i), 3.0)
		for i in hiders:
			herd[i].visible = false
		var n := await ask_number("I can see %d. How many hide?" % see, hide_n)
		if stopped or n < 0:
			break
		record(see, n == hide_n)
		# The bush rustles and out they come.
		await _rustle()
		for i in hiders:
			herd[i].visible = true
		await _walk_all(hiders, func(i): return spots[i], 3.0)
		await _count(hiders)
		if n == hide_n:
			await game.well_done("Yes! %d %s hiding!" % [hide_n, "was" if hide_n == 1 else "were"])
		else:
			await game.show_me(see, hide_n, "%d %s hiding. %d and %d make %d." % [hide_n, "was" if hide_n == 1 else "were", see, hide_n, target()])
	game.ui.set_rounds(0, 0)

func _bush() -> void:
	# A wall of giant ferns and leafy plants to hide behind.
	bush_root = Node3D.new()
	add_child(bush_root)
	bush_root.position = at + Vector3(0, 0, -5.2)
	var parts := [["Fern_1", Vector3(-3.6, 0, 0.3), 3.4], ["Plant_7_Big", Vector3(-1.7, 0, -0.2), 2.6], ["Fern_1", Vector3(0, 0, 0.2), 3.8],
		["Plant_7_Big", Vector3(1.8, 0, -0.3), 2.7], ["Fern_1", Vector3(3.7, 0, 0.3), 3.4], ["Plant_1_Big", Vector3(-0.9, 0, 0.9), 2.2],
		["Plant_1_Big", Vector3(1.0, 0, 1.0), 2.2], ["Fern_1", Vector3(-2.4, 0, 1.2), 2.2], ["Fern_1", Vector3(2.5, 0, 1.2), 2.2]]
	for b in parts:
		var n: Node3D = load("res://assets/nature/%s.gltf" % b[0]).instantiate()
		n.position = b[1]
		n.scale = Vector3.ONE * float(b[2])
		n.rotation.y = randf() * TAU
		bush_root.add_child(n)
		game.world._windify(n)

func _make_herd(species: String) -> void:
	var rows := 2 if target() > 5 else 1
	for i in target():
		var d: Node3D = Dino.new()
		add_child(d)
		d.setup(species, 1.15, randi() % 3)
		d.sfx = game.sfx
		d.visible = false
		herd.append(d)
		var row := i / 5
		var col := i % 5
		spots.append(at + Vector3((col - 2) * 1.9 + (0.6 if row == 1 else 0.0), 0, -1.6 + row * 1.5 - (rows - 1) * 0.6))

func _behind(i: int) -> Vector3:
	return bush_root.position + Vector3((i % 5 - 2) * 1.3, 0, -2.6 - (i / 5) * 1.0)

## Walk some of the herd to their targets at once (await it).
func _walk_all(which: Array, dest: Callable, speed: float) -> void:
	var longest := 0.0
	for i in which:
		var d := herd[i]
		var to: Vector3 = dest.call(i)
		var secs := d.position.distance_to(to) / speed
		longest = max(longest, secs)
		game.face(d, to)
		d.play("Walk", 1.2)
		var t := create_tween()
		t.tween_property(d, "position", to, secs)
		t.tween_callback(func():
			d.play("Idle")
			d.rotation.y = PI / 2 + 0.45)  # side-on, turned a little towards the camera
	await wait(longest + 0.1)

func _rustle() -> void:
	game.ui.ask("Who is hiding?")
	game.sfx.play("rustle")
	var t := create_tween()
	for k in 4:
		t.tween_property(bush_root, "rotation:z", 0.04, 0.07)
		t.tween_property(bush_root, "rotation:z", -0.04, 0.07)
	t.tween_property(bush_root, "rotation:z", 0.0, 0.05)
	await t.finished

## Count the ones who were hiding, with a number over each.
func _count(which: Array) -> void:
	var sorted := which.duplicate()
	sorted.sort()
	var k := 0
	for i in sorted:
		k += 1
		var l := number_label(k, 140, Color(1, 0.9, 0.5))
		l.position = herd[i].position + Vector3(0, 1.7, 0)
		add_child(l)
		pop_in(l, 0.15)
		game.sfx.play("pop", 1.0 + k * 0.06)
		herd[i].play("Jump")
		await wait(0.35)
	await wait(0.5)
	for c in get_children():
		if c is Label3D:
			c.queue_free()
