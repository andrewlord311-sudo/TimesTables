extends "res://scripts/activity.gd"
## The River: a number line of stepping stones, 0 to 5 or 0 to 10, with the
## home rock at the end. Baby Rex is on a stone. "Rex is on 4. How many hops
## to 10?" Too few and he's not there yet; too many and — splash!

const BANK_X := 10.2

var stones: Array[Vector3] = []
var root: Node3D
var on := 0
var rex_scale := Vector3.ONE
var hatch_spot := Vector3(18.8, 0, -1.0)  # on the near bank, in view

func run() -> void:
	var at: Vector3 = game.world.spot("river")["at"]
	game.camera_spot("river")
	_build(at)
	# Rex walks to the bank, becomes Baby Rex, and hops onto the start rock.
	await game.walk_rex(Vector3(BANK_X, 0, stones[0].z))
	rex_scale = game.rex.scale
	game.rex_scale_locked = true
	game.sfx.play("pop")
	var t := create_tween()
	t.tween_property(game.rex, "scale", Vector3.ONE * 0.5, 0.3)
	await t.finished
	game.rex.rotation.y = PI  # face down the line (-z)
	await hop(game.rex, game.rex.position, stones[0], 1.0, 0.5)
	on = 0
	for r in game.ROUNDS:
		if stopped:
			break
		game.ui.set_rounds(r, game.ROUNDS)
		var start: int = game.progress.pick_part()
		if start == target():
			start = 0
		await _jump_to(start, 0.25)
		var need := target() - start
		var n := await ask_number("Rex is on %d. How many hops to %d?" % [start, target()], need)
		if stopped or n < 0:
			break
		record(start, n == need)
		await _hops(n)
		if n == need:
			await game.well_done("Home! %d and %d make %d!" % [start, need, target()])
		elif n < need:
			game.ui.ask("Not there yet!")
			await game.show_me(start, need, "%d hops! %d and %d make %d." % [need, start, need, target()])
			await _hops(need - n)
		else:
			await game.show_me(start, need, "Too far! %d hops. %d and %d make %d." % [need, start, need, target()])
			await _jump_to(target(), 0.4)
		await wait(0.3)
	game.ui.set_rounds(0, 0)
	# Back to the bank and back to full size.
	if is_instance_valid(game.rex):
		await hop(game.rex, game.rex.position, Vector3(BANK_X, 0, stones[0].z), 1.0, 0.5)
		create_tween().tween_property(game.rex, "scale", rex_scale, 0.3)
		game.sfx.play("pop")
	game.rex_scale_locked = false
	game._grow_rex()
	root.queue_free()

func _build(at: Vector3) -> void:
	root = Node3D.new()
	add_child(root)
	var x := at.x
	var span := 8.0
	for i in target() + 1:
		var z := 4.0 - span * i / target()
		var p := Vector3(x, 0.12, z)
		stones.append(p)
		var big := i == 0 or i == target()
		var m := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.62 if big else (0.36 if target() > 5 else 0.55)
		cm.bottom_radius = cm.top_radius * 1.15
		cm.height = 0.3
		cm.radial_segments = 10
		cm.material = toon(Color(0.62, 0.6, 0.56) if not big else Color(0.55, 0.5, 0.42))
		m.mesh = cm
		m.position = p + Vector3(0, -0.04, 0)
		m.rotation.y = randf() * TAU
		root.add_child(m)
		var lbl := number_label(i, 120, Color(1, 1, 1) if i != target() else Color(1, 0.9, 0.4))
		lbl.position = p + Vector3(0, 0.75, 0)
		root.add_child(lbl)
	# A flag on the home rock.
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.03
	pm.bottom_radius = 0.03
	pm.height = 1.4
	pm.material = toon(Color(0.45, 0.3, 0.15))
	pole.mesh = pm
	pole.position = stones[target()] + Vector3(-0.35, 0.7, 0)
	root.add_child(pole)
	var flag := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.02, 0.35, 0.55)
	fm.material = toon(Color(0.95, 0.35, 0.3))
	flag.mesh = fm
	flag.position = stones[target()] + Vector3(-0.35, 1.22, -0.28)
	root.add_child(flag)
	stones[0].y = 0.27
	stones[target()].y = 0.27

## Hop forward n stones from where Rex is (past the home rock means splash).
func _hops(n: int) -> void:
	for k in n:
		if stopped:
			return
		var next := on + 1
		game.sfx.play("hop", 0.9 + next * 0.03)
		game.rex.play("Jump")
		if next > target():
			# Past the home rock: into the water!
			var spot := stones[target()] + Vector3(0, 0, -1.2 * (next - target()))
			spot.y = -0.25
			await hop(game.rex, game.rex.position, spot, 1.0, 0.45)
			game.sfx.play("splash")
			_splash(spot)
			on = next
			await wait(0.6)
			continue
		await hop(game.rex, game.rex.position, stones[next], 0.9, 0.4)
		on = next
		var l := number_label(on, 140, Color(1, 0.95, 0.6))
		l.position = stones[on] + Vector3(0, 1.4, 0)
		root.add_child(l)
		pop_in(l, 0.12)
		get_tree().create_timer(0.7).timeout.connect(l.queue_free)
		await wait(0.12)

## Move Rex to stone i between rounds: a quick pop, not a giant leap.
func _jump_to(i: int, secs: float) -> void:
	if on == i and game.rex.position.distance_to(stones[i]) < 0.1:
		return
	var s: Vector3 = game.rex.scale
	var t := create_tween()
	t.tween_property(game.rex, "scale", s * 0.05, secs * 0.5)
	await t.finished
	game.rex.position = stones[i]
	game.rex.rotation.y = PI
	game.sfx.play("pop")
	var t2 := create_tween()
	t2.tween_property(game.rex, "scale", s, secs * 0.6).set_trans(Tween.TRANS_BACK)
	await t2.finished
	on = i

func _splash(p: Vector3) -> void:
	var s := CPUParticles3D.new()
	s.one_shot = true
	s.amount = 40
	s.lifetime = 0.9
	s.explosiveness = 0.95
	var drop := SphereMesh.new()
	drop.radius = 0.07
	drop.height = 0.14
	drop.material = toon(Color(0.75, 0.92, 1.0))
	s.mesh = drop
	s.direction = Vector3.UP
	s.spread = 50
	s.initial_velocity_min = 2.5
	s.initial_velocity_max = 4.5
	s.gravity = Vector3(0, -9, 0)
	s.position = p + Vector3(0, 0.2, 0)
	root.add_child(s)
	s.emitting = true
	get_tree().create_timer(1.5).timeout.connect(s.queue_free)
