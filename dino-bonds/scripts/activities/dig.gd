extends "res://scripts/activity.gd"
## The Fossil Dig: bone pieces marked with dots lie in the sand. Tap two that
## make 5 (or 10) and they click together. Find every way — 1+9, 2+8, 3+7,
## 4+6, 5+5 — and the skeleton is complete... and comes to life!

const BONE_COL := Color(0.95, 0.91, 0.8)
const PICK_COL := Color(1.0, 0.82, 0.45)

var at := Vector3.ZERO
var pieces: Array[Node3D] = []
var values := {}            # piece -> number on it
var picked: Node3D = null
var found := 0
var pairs: Array = []
var fossil: Node3D

func run() -> void:
	at = game.world.spot("dig")["at"]
	game.camera_spot("dig")
	await game.walk_rex(at + Vector3(5.6, 0, -0.6))
	game.face(game.rex, at)
	# Every pair that makes the target (0+5 counts for 5; 10 uses 1-9 to 5+5).
	pairs = []
	var lo := 0 if target() == 5 else 1
	for a in range(lo, target() / 2 + 1):
		pairs.append([a, target() - a])
	var species: String = ["Stegosaurus", "Triceratops", "Apatosaurus", "Parasaurolophus", "Velociraptor"][randi() % 5]
	_lay_out()
	_make_fossil(species)
	game.ui.ask("Find two bones that make %d!" % target())
	game.ui.set_rounds(0, pairs.size())
	while found < pairs.size() and not stopped:
		var body = await tap
		if body == null:
			break
		var piece: Node3D = body.get_parent()
		if not values.has(piece):
			continue
		if picked == null:
			_pick(piece)
		elif picked == piece:
			_unpick(piece)
		else:
			var a: int = values[picked]
			var b: int = values[piece]
			if a + b == target():
				record(min(a, b), true)
				await _join(picked, piece)
				picked = null
				found += 1
				game.ui.set_rounds(found, pairs.size())
				await game.well_done("%d and %d make %d!" % [a, b, target()])
				if found < pairs.size():
					game.ui.ask("Find two more!")
			else:
				record(min(a, b), false)
				game.sfx.play("soft")
				var other := picked
				_unpick(other)
				_wiggle(piece)
				_wiggle(other)
				game.ui.ask("%d and %d make %d. Try again!" % [a, b, a + b])
	game.ui.set_rounds(0, 0)
	if found == pairs.size() and not stopped:
		await _come_alive(species)

func _lay_out() -> void:
	var nums := []
	for p in pairs:
		nums.append(p[0])
		nums.append(p[1])
	nums.shuffle()
	var per_row := 4 if nums.size() > 6 else 3
	for i in nums.size():
		var row := i / per_row
		var col := i % per_row
		var in_row: int = min(per_row, nums.size() - row * per_row)
		var piece := _bone(int(nums[i]))
		piece.scale = Vector3.ONE * 1.25
		piece.position = at + Vector3((col - (in_row - 1) / 2.0) * 2.05, 0.12, -0.2 + row * 1.3)
		piece.rotation.y = randf_range(-0.2, 0.2)
		add_child(piece)
		pieces.append(piece)
		values[piece] = int(nums[i])
		game.tappable(piece, 0.6, Vector3(0, 0.2, 0))

## A cartoon bone: a shaft with two knobs at each end, dots on top, and its number.
func _bone(n: int) -> Node3D:
	var root := Node3D.new()
	var mat := toon(BONE_COL)
	var shaft := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.11
	cap.height = 1.0
	cap.material = mat
	shaft.mesh = cap
	shaft.rotation.z = PI / 2
	root.add_child(shaft)
	for sx in [-0.5, 0.5]:
		for sz in [-0.1, 0.1]:
			var k := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.14
			sm.height = 0.28
			sm.material = mat
			k.mesh = sm
			k.position = Vector3(sx, 0, sz)
			root.add_child(k)
	var dot_mat := toon(Color(0.8, 0.38, 0.18))
	for d in n:
		var dot := MeshInstance3D.new()
		var dm := SphereMesh.new()
		dm.radius = 0.045
		dm.height = 0.09
		dm.material = dot_mat
		dot.mesh = dm
		var row := d / 5
		var col := d % 5
		dot.position = Vector3((col - 2) * 0.13, 0.1, (row - 0.5) * 0.12 if n > 5 else 0.0)
		root.add_child(dot)
	var lbl := number_label(n, 120)
	lbl.position = Vector3(0, 0.42, -0.1)
	root.add_child(lbl)
	root.set_meta("mat", mat)
	return root

func _pick(p: Node3D) -> void:
	picked = p
	game.ui._asked_at = Time.get_ticks_msec() / 1000.0
	game.sfx.play("pop")
	(p.get_meta("mat") as StandardMaterial3D).albedo_color = PICK_COL
	create_tween().tween_property(p, "position:y", 0.45, 0.15)

func _unpick(p: Node3D) -> void:
	if picked == p:
		picked = null
	(p.get_meta("mat") as StandardMaterial3D).albedo_color = BONE_COL
	create_tween().tween_property(p, "position:y", 0.12, 0.15)

func _wiggle(p: Node3D) -> void:
	var t := create_tween()
	var r := p.rotation.y
	for k in 3:
		t.tween_property(p, "rotation:y", r + 0.25, 0.06)
		t.tween_property(p, "rotation:y", r - 0.25, 0.06)
	t.tween_property(p, "rotation:y", r, 0.05)

## The two pieces fly together and click into the skeleton pile.
func _join(a: Node3D, b: Node3D) -> void:
	game.sfx.play("chime")
	var mid := at + Vector3(0, 0.6, -1.6)
	var ta := create_tween()
	ta.tween_property(a, "position", mid + Vector3(-0.3, 0, 0), 0.4).set_trans(Tween.TRANS_SINE)
	var tb := create_tween()
	tb.tween_property(b, "position", mid + Vector3(0.3, 0, 0), 0.4).set_trans(Tween.TRANS_SINE)
	await tb.finished
	game.sfx.play("crack", 1.6)
	for p in [a, b]:
		values.erase(p)
		var t := create_tween()
		t.tween_property(p, "scale", Vector3.ONE * 0.05, 0.25)
		t.tween_callback(p.queue_free)
	# the fossil underneath fills in a little more
	var t2 := create_tween()
	t2.tween_property(fossil, "position:y", lerpf(-2.6, -0.9, float(found + 1) / pairs.size()), 0.4)

func _make_fossil(species: String) -> void:
	fossil = Dino.new()
	add_child(fossil)
	fossil.setup(species, 2.4)
	fossil.sfx = game.sfx
	fossil.set_fossil(true)
	fossil.position = at + Vector3(0, -2.6, -2.4)
	fossil.rotation.y = 0.5
	fossil.anim.pause()

func _come_alive(species: String) -> void:
	game.ui.ask("The bones are all here…")
	var t := create_tween()
	t.tween_property(fossil, "position:y", 0.0, 1.2).set_trans(Tween.TRANS_BACK)
	await t.finished
	fossil.set_fossil(false, 1.2)
	await wait(1.3)
	fossil.anim.play()
	fossil.roar()
	game.ui.ask("")
	await game.ui.flash("A %s!" % game.NAMES[species], 1.4)
	await game.ui.show_card("You found a %s!" % game.NAMES[species], game.FACTS[species])

func bot_tick() -> void:
	if values.is_empty():
		return
	var keys := values.keys()
	if picked == null:
		_bot_tap(keys[randi() % keys.size()])
		return
	var want: int = target() - int(values[picked])
	for k in keys:
		if k != picked and int(values[k]) == want and randf() < 0.75:
			_bot_tap(k)
			return
	_bot_tap(keys[randi() % keys.size()])

func _bot_tap(piece: Node3D) -> void:
	for c in piece.get_children():
		if c is StaticBody3D:
			game.tapped.emit(c)
