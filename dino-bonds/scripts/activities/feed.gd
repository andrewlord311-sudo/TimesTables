extends "res://scripts/activity.gd"
## Feed the T. rex: red berries in one basket, blue in the other. Put berries
## in Rex's bowl to make exactly 5 (or 10), then press "Feed Rex!". Exactly
## right: a happy stomp. Too few: "More, please!" Too many: a big burp.
## Each round asks for a new way to make it.

const RED := Color(0.9, 0.22, 0.25)
const BLUE := Color(0.3, 0.42, 0.95)

var at := Vector3.ZERO
var bowl_pos := Vector3.ZERO
var baskets := {}           # "red"/"blue" -> basket position
var berries := {}           # berry -> {"colour": .., "home": pos, "in": bool}
var in_bowl := {"red": 0, "blue": 0}
var counter: Label3D
var ways := {}              # red count -> true
var hatch_spot := Vector3.ZERO

func run() -> void:
	at = game.world.spot("feed")["at"]
	hatch_spot = at + Vector3(-2.8, 0, 1.6)
	game.camera_spot("feed")
	await game.walk_rex(at + Vector3(0, 0, -1.4))
	game.face(game.rex, game.cam.position)
	_build()
	for r in game.ROUNDS:
		if stopped:
			break
		game.ui.set_rounds(r, game.ROUNDS)
		_reset_berries()
		game.ui.ask("Make %d for Rex! Red and blue." % target() if r == 0 else "Make %d a new way!" % target())
		game.ui.show_action("Feed Rex!")
		game.ui._asked_at = Time.get_ticks_msec() / 1000.0
		var done := false
		while not done and not stopped:
			await _wait_for_tap_or_feed()
			if stopped:
				break
			if _pressed_feed:
				_pressed_feed = false
				done = await _feed()
		game.ui.show_action("")
	game.ui.set_rounds(0, 0)

var _pressed_feed := false

func _wait_for_tap_or_feed() -> void:
	var waiter := {"done": false}
	var on_tap := func(body):
		if waiter["done"]:
			return
		waiter["done"] = true
		if body and berries.has(body.get_parent()):
			_move_berry(body.get_parent())
	var on_feed := func():
		if waiter["done"]:
			return
		waiter["done"] = true
		_pressed_feed = true
	tap.connect(on_tap, CONNECT_ONE_SHOT)
	game.ui.action_pressed.connect(on_feed, CONNECT_ONE_SHOT)
	while not waiter["done"]:
		await get_tree().process_frame
	if tap.is_connected(on_tap):
		tap.disconnect(on_tap)
	if game.ui.action_pressed.is_connected(on_feed):
		game.ui.action_pressed.disconnect(on_feed)

## Feed! Returns true when the round is over.
func _feed() -> bool:
	var red: int = in_bowl["red"]
	var blue: int = in_bowl["blue"]
	var total := red + blue
	game.ui.show_action("")
	if total == target():
		record(min(red, blue), true)
		await _eat()
		var new_way := not ways.has(red)
		ways[red] = true
		await game.well_done("%d and %d make %d!" % [red, blue, target()] if new_way else "%d and %d again — yum!" % [red, blue])
		return true
	if total < target():
		game.sfx.play("soft")
		_shake_head()
		game.ui.ask("More, please! That is %d." % total)
		await wait(0.8)
		game.ui.show_action("Feed Rex!")
		return false
	# Too many!
	record(min(red, blue), false)
	await _eat()
	game.sfx.play("burp")
	game.ui.ask("BURP! That was %d. Too many!" % total)
	await wait(1.4)
	_reset_berries()
	game.ui.ask("Make %d for Rex!" % target())
	game.ui.show_action("Feed Rex!")
	return false

func _build() -> void:
	bowl_pos = at + Vector3(0, 0, 0.8)
	var bowl := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.75
	bm.bottom_radius = 0.5
	bm.height = 0.45
	bm.material = toon(Color(0.55, 0.35, 0.2))
	bowl.mesh = bm
	bowl.position = bowl_pos + Vector3(0, 0.22, 0)
	add_child(bowl)
	counter = number_label(0, 110)
	counter.position = bowl_pos + Vector3(0, 1.0, 0.2)
	add_child(counter)
	baskets = {"red": at + Vector3(-2.9, 0, 1.4), "blue": at + Vector3(2.9, 0, 1.4)}
	for colour in baskets:
		var b := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.95
		cm.bottom_radius = 0.7
		cm.height = 0.45
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/twigs.gdshader")
		cm.material = m
		b.mesh = cm
		b.position = baskets[colour] + Vector3(0, 0.22, 0)
		add_child(b)
		for i in target():
			var berry := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.17
			sm.height = 0.34
			sm.material = toon(RED if colour == "red" else BLUE)
			berry.mesh = sm
			var row := i / 5
			var col := i % 5
			var home: Vector3 = baskets[colour] + Vector3((col - 2) * 0.33, 0.6 + row * 0.3, (row - 0.5) * 0.3 if target() > 5 else 0.0)
			berry.position = home
			add_child(berry)
			game.tappable(berry, 0.24)
			berries[berry] = {"colour": colour, "home": home, "in": false, "slot": -1}

func _reset_berries() -> void:
	for b in berries:
		var info: Dictionary = berries[b]
		if info["in"]:
			info["in"] = false
			create_tween().tween_property(b, "position", info["home"], 0.3)
	in_bowl = {"red": 0, "blue": 0}
	_update_counter()

## Tap a berry: into the bowl (or, if it's in the bowl, back to its basket).
func _move_berry(b: Node3D) -> void:
	var info: Dictionary = berries[b]
	var colour: String = info["colour"]
	if info["in"]:
		info["in"] = false
		in_bowl[colour] -= 1
		create_tween().tween_property(b, "position", info["home"], 0.25)
	else:
		info["in"] = true
		var n: int = in_bowl["red"] + in_bowl["blue"]
		in_bowl[colour] += 1
		var a := float(n) * 2.4
		var r := 0.18 + 0.05 * n
		var dest := bowl_pos + Vector3(cos(a) * min(r, 0.5), 0.5 + 0.05 * (n / 8), sin(a) * min(r, 0.5) * 0.7)
		game.sfx.play("pop", 1.0 + n * 0.05)
		await hop(b, b.position, dest, 0.8, 0.3)
	_update_counter()

func _update_counter() -> void:
	var red: int = in_bowl["red"]
	var blue: int = in_bowl["blue"]
	counter.text = "%d + %d" % [red, blue] if red + blue > 0 else "0"

func _eat() -> void:
	game.rex.roar(1.3)
	for k in 3:
		await wait(0.25)
		game.sfx.play("chomp", 1.0 + k * 0.1)
	for b in berries:
		if berries[b]["in"]:
			b.visible = false
	await wait(0.4)
	for b in berries:
		var info: Dictionary = berries[b]
		if info["in"]:
			info["in"] = false
			b.position = info["home"]
			b.visible = true
	in_bowl = {"red": 0, "blue": 0}
	_update_counter()

func _shake_head() -> void:
	var r: float = game.rex.rotation.y
	var t := create_tween()
	for k in 2:
		t.tween_property(game.rex, "rotation:y", r + 0.35, 0.12)
		t.tween_property(game.rex, "rotation:y", r - 0.35, 0.12)
	t.tween_property(game.rex, "rotation:y", r, 0.1)

func bot_tick() -> void:
	var total: int = in_bowl["red"] + in_bowl["blue"]
	var aim := target() + (1 if randf() < 0.15 else 0)
	if total >= aim or (total > 0 and randf() < 0.08):
		game.ui.action_pressed.emit()
		return
	var colour := "red" if randf() < 0.5 else "blue"
	for b in berries:
		if not berries[b]["in"] and berries[b]["colour"] == colour:
			for c in b.get_children():
				if c is StaticBody3D:
					game.tapped.emit(c)
					return
