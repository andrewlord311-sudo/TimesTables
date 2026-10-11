extends "res://scripts/activity.gd"
## Pterosaur Catch, the speed round: "7 and ? make 10". Pterosaurs swoop across
## the sky carrying numbers; tap the one with the partner. It swoops down to
## Rex. Missed ones come round again; a wrong one squawks and does a loop.
## It gets a little faster each catch. Answers are timed quietly (no clock on
## screen) so slow ones come up again more often.

const Ptero := preload("res://scripts/pterosaur.gd")
const ROUNDS := 8
const COLOURS := [[Color(0.95, 0.55, 0.25), Color(0.99, 0.8, 0.55), Color(0.9, 0.3, 0.3)],
	[Color(0.35, 0.62, 0.9), Color(0.75, 0.9, 1.0), Color(0.98, 0.75, 0.25)],
	[Color(0.55, 0.78, 0.35), Color(0.9, 0.98, 0.7), Color(0.85, 0.35, 0.6)],
	[Color(0.75, 0.5, 0.88), Color(0.95, 0.85, 1.0), Color(0.98, 0.6, 0.3)]]

var at := Vector3.ZERO
var flyers: Array[Node3D] = []
var info := {}              # flyer -> {"n": .., "dir": ±1, "speed": .., "busy": bool}
var shown := 0              # the part shown in the question
var answer := 0             # the partner to catch
var speed := 2.4
var caught := false
var missed_this_round := false
var hatch_spot := Vector3.ZERO

func run() -> void:
	at = game.world.spot("sky")["at"]
	hatch_spot = at + Vector3(-2.4, 0, 3.2)
	game.camera_spot("sky")
	await game.walk_rex(at + Vector3(2.0, 0, 1.0))
	game.rex.rotation.y = PI  # looking up at the sky, away from us
	_clouds()
	for i in 3:
		var p: Node3D = Ptero.new()
		add_child(p)
		var c: Array = COLOURS[i % COLOURS.size()]
		p.setup(c[0], c[1], c[2])
		p.scale = Vector3.ONE * 1.35
		game.tappable(p, 1.25, Vector3(0, -0.4, 0.2))
		var lbl := number_label(0, 230)
		lbl.position = Vector3(0, -1.05, 0.2)
		lbl.name = "Number"
		p.add_child(lbl)
		var dots := Label3D.new()
		dots.font = game.ui.font
		dots.font_size = 84
		dots.pixel_size = 0.004
		dots.modulate = Color(1, 0.85, 0.5)
		dots.outline_modulate = Color(0.25, 0.18, 0.08)
		dots.outline_size = 22
		dots.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		dots.no_depth_test = true
		dots.position = Vector3(0, -1.85, 0.2)
		dots.name = "Dots"
		p.add_child(dots)
		flyers.append(p)
		info[p] = {"n": 0, "dir": 1.0, "speed": 1.0, "busy": false, "lane": i}
	for r in ROUNDS:
		if stopped:
			break
		game.ui.set_rounds(r, ROUNDS)
		shown = game.progress.pick_part(shown)
		if (shown == 0 or shown == target()) and randf() < 0.7:
			shown = game.progress.pick_part(shown)  # the 0 bonds are easy: keep them rare here
		answer = target() - shown
		caught = false
		missed_this_round = false
		_deal()
		game.ui.ask("%d and ? make %d. Catch it!" % [shown, target()])
		game.ui._asked_at = Time.get_ticks_msec() / 1000.0
		while not caught and not stopped:
			var body = await tap
			if body == null:
				break
			var p: Node3D = body.get_parent()
			if not info.has(p) or info[p]["busy"]:
				continue
			if int(info[p]["n"]) == answer:
				caught = true
				record(shown, not missed_this_round)
				await _swoop(p)
				await game.well_done("%d and %d make %d!" % [shown, answer, target()])
			else:
				if not missed_this_round:
					missed_this_round = true
				_loop(p)
				game.ui.ask("That is %d. %d and %d make %d. Try again!" % [int(info[p]["n"]), shown, int(info[p]["n"]), shown + int(info[p]["n"])])
		speed += 0.3
	game.ui.set_rounds(0, 0)

## Give the flyers their numbers: one carries the answer, the others don't.
func _deal() -> void:
	var others := []
	for n in range(0, target() + 1):
		if n != answer:
			others.append(n)
	others.shuffle()
	var right_one := randi() % flyers.size()
	for i in flyers.size():
		var n: int = answer if i == right_one else int(others[i])
		_launch(flyers[i], n, i * 3.2)

## Send a flyer across the sky (from off-screen, after `delay` seconds' worth of distance).
func _launch(p: Node3D, n: int, delay_dist := 0.0) -> void:
	var lane: int = info[p]["lane"]
	var dir := 1.0 if lane % 2 == 0 else -1.0  # lanes alternate, so numbers don't pile up
	info[p]["n"] = n
	info[p]["dir"] = dir
	info[p]["speed"] = speed * randf_range(0.85, 1.15)
	info[p]["busy"] = false
	(p.get_node("Number") as Label3D).text = str(n)
	(p.get_node("Dots") as Label3D).text = _dots(n)
	p.rotation = Vector3(0, PI / 2 * dir, 0)
	p.position = at + Vector3(-dir * (13.0 + delay_dist), 4.4 + lane * 1.5, -1.6 - lane * 1.3)

func _dots(n: int) -> String:
	if n == 0:
		return ""
	var top := "●".repeat(min(n, 5))
	return top if n <= 5 else top + "\n" + "●".repeat(n - 5)

func _process(delta: float) -> void:
	for p in flyers:
		if info[p]["busy"]:
			continue
		var dir: float = info[p]["dir"]
		p.position.x += dir * float(info[p]["speed"]) * delta
		p.position.y += sin(Time.get_ticks_msec() / 500.0 + int(info[p]["lane"])) * 0.4 * delta
		# Off the far side: come round again with a number (the answer stays in play).
		if (dir > 0 and p.position.x > at.x + 14.0) or (dir < 0 and p.position.x < at.x - 14.0):
			var n: int = info[p]["n"]
			if not _answer_flying(p):
				n = answer
			_launch(p, n)

func _answer_flying(except: Node3D) -> bool:
	for p in flyers:
		if p != except and int(info[p]["n"]) == answer and not info[p]["busy"]:
			return true
	return false

## Caught! It swoops down to Rex, then flies off again.
func _swoop(p: Node3D) -> void:
	info[p]["busy"] = true
	game.sfx.play("squeak", 1.2)
	var start := p.position
	var down: Vector3 = game.rex.position + Vector3(0, 3.6, 0.8)
	var t := create_tween()
	t.tween_property(p, "position", down, 0.6).set_trans(Tween.TRANS_SINE)
	await t.finished
	game.rex.roar(1.1)
	await wait(0.6)
	var t2 := create_tween()
	t2.tween_property(p, "position", start + Vector3(0, 6, 0), 0.8)
	await t2.finished

## A wrong one: squawk and a loop-the-loop.
func _loop(p: Node3D) -> void:
	info[p]["busy"] = true
	game.sfx.play("squeak", 0.7)
	var t := create_tween()
	t.tween_property(p, "rotation:z", p.rotation.z + TAU, 0.7)
	t.tween_callback(func(): info[p]["busy"] = false)

func _clouds() -> void:
	var mat := toon(Color(1, 1, 1))
	for c in [Vector3(-8, 9.5, -9), Vector3(6, 11, -11), Vector3(-1, 12.5, -14), Vector3(11, 8.5, -8)]:
		var cloud := Node3D.new()
		cloud.position = at + c
		add_child(cloud)
		for k in 5:
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = randf_range(0.9, 1.5)
			sm.height = sm.radius * 1.6
			sm.material = mat
			mi.mesh = sm
			mi.position = Vector3((k - 2) * 1.1, randf_range(-0.2, 0.4), randf_range(-0.3, 0.3))
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.add_child(mi)

func bot_tick() -> void:
	for p in flyers:
		if info[p]["busy"]:
			continue
		var on_screen: bool = game.cam.is_position_in_frustum(p.global_position)
		if on_screen and (int(info[p]["n"]) == answer or randf() < 0.15):
			for c in p.get_children():
				if c is StaticBody3D:
					game.tapped.emit(c)
					return
