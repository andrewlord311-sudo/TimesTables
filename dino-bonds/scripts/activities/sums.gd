extends "res://scripts/activity.gd"
## Dino Sums: two little herds walk in, "3 and 2: how many altogether?"
## Felix adds them up, then each dinosaur is counted out loud-ish (numbers pop
## over them) so the answer is always shown. "Make 5" uses numbers 1-5 and
## "Make 10" uses numbers 1-10. It starts with just +1, then +1 or +2, and
## only moves up a step after a visit where he got 4 of 5 right (kept in
## progress.add_level for each range).

const SPECIES := ["Triceratops", "Stegosaurus", "Parasaurolophus", "Velociraptor", "Apatosaurus"]
const MAX_ADDEND := [1, 2, 3, 5, 10]    # the second number, by level

var at := Vector3.ZERO
var herd_a: Array[Node3D] = []
var herd_b: Array[Node3D] = []

func run() -> void:
	at = game.world.spot("nest")["at"]
	game.camera_spot("nest")
	await game.walk_rex(at + Vector3(0, 0, -4.2))
	game.face(game.rex, at)
	var level: int = game.progress.get_add_level()
	var right := 0
	var last := Vector2i.ZERO
	for r in game.ROUNDS:
		if stopped:
			break
		game.ui.set_rounds(r, game.ROUNDS)
		var q := _pick(level, last)
		last = q
		var total := q.x + q.y
		await _herds_in(q.x, q.y)
		var n := await ask_number("%d and %d. How many altogether?" % [q.x, q.y], total, maxi(total, _top(level)), 2)
		if stopped or n < 0:
			break
		if n == total:
			right += 1
		await _count()
		if n == total:
			await game.well_done("Yes! %d and %d make %d!" % [q.x, q.y, total])
		else:
			game.sfx.play("soft")
			await game.ui.flash("%d and %d make %d." % [q.x, q.y, total], 2.4)
		await _herds_out()
	game.ui.set_rounds(0, 0)
	if not stopped and right >= 4:
		game.progress.set_add_level(level + 1)

## The biggest sum that can come up at this level (for the answer buttons).
func _top(level: int) -> int:
	var t := target()
	return t + mini(MAX_ADDEND[level], t)

## A new question: first number 1..t (small to begin with), second 1..the
## level's limit, never the same as last time.
func _pick(level: int, last: Vector2i) -> Vector2i:
	var t := target()
	var a_max := t if level >= 2 else mini(t, 5)
	var b_max := mini(MAX_ADDEND[level], t)
	var q := last
	for i in 12:
		q = Vector2i(randi_range(1, a_max), randi_range(1, b_max))
		if q != last:
			break
	return q

func _group(n: int, species: String, colour: int, cx: float) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var s := 1.0 if n <= 5 else 0.75
	var per_col := 5 if n <= 5 else 5   # up the screen in columns: they stand side-on, so they are long
	var cols := (n + per_col - 1) / per_col
	for i in n:
		var d: Node3D = Dino.new()
		add_child(d)
		d.setup(species, 1.0 * s, colour)
		d.sfx = game.sfx
		var row := i % per_col
		var col := i / per_col
		var rows := mini(n, per_col)
		d.set_meta("spot", at + Vector3(cx + (col - (cols - 1) * 0.5) * 2.6 * s, 0, -0.4 + (row - (rows - 1) * 0.5) * 1.15 * s))
		d.visible = false
		out.append(d)
	return out

func _herds_in(a: int, b: int) -> void:
	var sp: Array = SPECIES.duplicate()
	sp.shuffle()
	herd_a = _group(a, sp[0], 0, -3.3)
	herd_b = _group(b, sp[1], 1, 3.3)
	game.ui.ask("")
	var longest := 0.0
	for d in herd_a + herd_b:
		var to: Vector3 = d.get_meta("spot")
		var from := to + Vector3(-11.0 if d in herd_a else 11.0, 0, 0)
		d.position = from
		d.visible = true
		game.face(d, to)
		d.play("Walk", 1.2)
		var secs := from.distance_to(to) / 4.0
		longest = max(longest, secs)
		var t := create_tween()
		t.tween_property(d, "position", to, secs)
		t.tween_callback(func():
			d.play("Idle")
			d.rotation.y = PI / 2 + 0.45)
	await wait(longest + 0.2)

## Number each dinosaur in turn, left herd first, then the right.
func _count() -> void:
	var k := 0
	for d in herd_a + herd_b:
		k += 1
		var l := number_label(k, 140, Color(1, 0.9, 0.5) if d in herd_a else Color(0.7, 0.9, 1.0))
		l.position = d.position + Vector3(0, 1.6 * d.scale.y + 0.2, 0)
		l.name = "Count"
		add_child(l)
		pop_in(l, 0.15)
		game.sfx.play("pop", 1.0 + minf(k, 12) * 0.05)
		d.play("Jump")
		await wait(0.3)
	await wait(0.5)

func _herds_out() -> void:
	for c in get_children():
		if c is Label3D:
			c.queue_free()
	for d in herd_a + herd_b:
		var t := create_tween()
		t.tween_property(d, "scale", Vector3.ONE * 0.01, 0.25)
		t.tween_callback(d.queue_free)
	await wait(0.35)
	herd_a.clear()
	herd_b.clear()
