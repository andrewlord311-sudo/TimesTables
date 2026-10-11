extends "res://scripts/activity.gd"
## The Nest: a nest laid out as a five or ten frame. Rounds 1-2, Felix taps the
## empty hollows to roll eggs in, counting up. Rounds 3-5, he says how many
## more first, then the eggs roll in to show it.

var nest_root: Node3D
var hollows: Array[Node3D] = []
var eggs: Array[Node3D] = []

func run() -> void:
	var at: Vector3 = game.world.spot("nest")["at"]
	game.camera_spot("nest")
	await game.walk_rex(at + Vector3(3.2, 0, 1.4))
	game.face(game.rex, at)
	for r in game.ROUNDS:
		if stopped:
			break
		game.ui.set_rounds(r, game.ROUNDS)
		var have: int = game.progress.pick_part()
		if have == target():
			have = target() - 1
		_build(at, have)
		var need := target() - have
		if r < 2:
			game.ui.ask("%d %s. Fill the nest!" % [have, "egg" if have == 1 else "eggs"])
			await _tap_fill(have)
			if stopped:
				break
			await _count_all()
			await game.well_done("%d and %d make %d!" % [have, need, target()])
		else:
			var n := await ask_number("%d %s. How many more?" % [have, "egg" if have == 1 else "eggs"], need)
			if stopped or n < 0:
				break
			record(have, n == need)
			await _auto_fill(have)
			await _count_all()
			if n == need:
				await game.well_done("Yes! %d and %d make %d!" % [have, need, target()])
			else:
				await game.show_me(have, need, "%d more! %d and %d make %d." % [need, have, need, target()])
		await wait(0.4)
	game.ui.set_rounds(0, 0)
	_clear()

func _clear() -> void:
	if nest_root:
		nest_root.queue_free()
	hollows.clear()
	eggs.clear()

func _build(at: Vector3, have: int) -> void:
	_clear()
	nest_root = Node3D.new()
	add_child(nest_root)
	nest_root.position = at
	var rows := 2 if target() > 5 else 1
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.95
	tm.outer_radius = 1.45
	tm.rings = 48
	tm.ring_segments = 14
	var nm := ShaderMaterial.new()
	nm.shader = load("res://shaders/twigs.gdshader")
	tm.material = nm
	ring.mesh = tm
	ring.scale = Vector3(1.7, 0.55, 0.62 if rows == 1 else 0.85)
	ring.position.y = 0.1
	nest_root.add_child(ring)
	var bed := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.08
	cyl.material = toon(Color(0.55, 0.42, 0.25))
	bed.mesh = cyl
	bed.scale = Vector3(1.72, 1, 0.62 if rows == 1 else 0.86)
	bed.position.y = 0.05
	nest_root.add_child(bed)
	for i in target():
		var row := i / 5
		var col := i % 5
		var p := Vector3((col - 2) * 0.58, 0, (row - (rows - 1) / 2.0) * 0.62)
		var hollow := MeshInstance3D.new()
		var hm := CylinderMesh.new()
		hm.top_radius = 0.21
		hm.bottom_radius = 0.17
		hm.height = 0.04
		hm.material = toon(Color(0.36, 0.26, 0.15))
		hollow.mesh = hm
		hollow.position = p + Vector3(0, 0.1, 0)
		nest_root.add_child(hollow)
		hollows.append(hollow)
		game.tappable(hollow, 0.32, Vector3(0, 0.2, 0))
		if i < have:
			_add_egg(i, false)

func _add_egg(i: int, animate: bool) -> void:
	var egg := egg_mesh(0.2)
	var dest := hollows[i].position + Vector3(0, 0.27, 0)
	nest_root.add_child(egg)
	eggs.append(egg)
	if not animate:
		egg.position = dest
		egg.rotation.z = randf_range(-0.12, 0.12)
		return
	game.sfx.play("pop", 0.9 + i * 0.04)
	await hop(egg, dest + Vector3(1.8, 0.6, 1.2), dest, 0.9, 0.35)
	var lbl := number_label(i + 1, 130)
	lbl.position = dest + Vector3(0, 0.55, 0)
	nest_root.add_child(lbl)
	pop_in(lbl)
	get_tree().create_timer(0.9).timeout.connect(lbl.queue_free)

## Felix taps empty hollows; each tap rolls the next egg in.
func _tap_fill(have: int) -> void:
	var filled := have
	while filled < target() and not stopped:
		var body = await tap
		if body == null:
			return
		if hollows.has(body.get_parent()):
			await _add_egg(filled, true)
			filled += 1

func _auto_fill(have: int) -> void:
	for i in range(have, target()):
		await _add_egg(i, true)
		await wait(0.15)

## Count every egg in the nest, one by one.
func _count_all() -> void:
	for i in eggs.size():
		if stopped:
			return
		var lbl := number_label(i + 1, 110, Color(1, 0.95, 0.6))
		lbl.position = eggs[i].position + Vector3(0, 0.5, 0)
		nest_root.add_child(lbl)
		pop_in(lbl, 0.15)
		game.sfx.play("pop", 1.0 + i * 0.06)
		var t := create_tween()
		t.tween_property(eggs[i], "position:y", eggs[i].position.y + 0.12, 0.08)
		t.tween_property(eggs[i], "position:y", eggs[i].position.y, 0.1)
		await wait(0.18)
	await wait(0.4)
	for l in nest_root.get_children():
		if l is Label3D:
			l.queue_free()

func bot_tick() -> void:
	if hollows.size() > eggs.size():
		var h := hollows[eggs.size()]
		for c in h.get_children():
			if c is StaticBody3D:
				game.tapped.emit(c)
				return
