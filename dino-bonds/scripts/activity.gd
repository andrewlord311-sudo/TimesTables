extends Node3D
## Shared bits for every play spot. An activity's run() is a coroutine: it
## plays its rounds and returns. The 🏠 button calls stop(), which unblocks
## whatever it's waiting for so it can tidy up and return early.

signal tap(body)

const Dino := preload("res://scripts/dino.gd")

var game: Node3D
var stopped := false

func _ready() -> void:
	game.tapped.connect(func(b): tap.emit(b))

func stop() -> void:
	stopped = true
	tap.emit(null)
	game.ui.answered.emit(-1)
	game.ui.action_pressed.emit()

func target() -> int:
	return game.progress.target

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

## Ask a number question; returns the answer, or -1 if stopped.
func ask_number(text: String, right: int, top := -1, lo := 0) -> int:
	game.ui.ask(text)
	game.expected = right
	var n: int = await game.ui.ask_number(target() if top < 0 else top, 5, lo)
	game.expected = -1
	return n

func record(part: int, right: bool) -> void:
	game.progress.record(part, right, game.ui.seconds_since_asked())

## A cream dinosaur egg mesh.
func egg_mesh(radius := 0.2) -> MeshInstance3D:
	var egg := MeshInstance3D.new()
	var em := SphereMesh.new()
	em.radius = radius
	em.height = radius * 2.7
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/egg.gdshader")
	em.material = m
	egg.mesh = em
	return egg

func toon(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.roughness = 0.5
	m.rim_enabled = true
	m.rim = 0.3
	return m

## A floating number above something (always faces the camera).
func number_label(n: int, size := 160, col := Color(1, 1, 1)) -> Label3D:
	var l := Label3D.new()
	l.text = str(n)
	l.font = game.ui.font
	l.font_size = size
	l.pixel_size = 0.004
	l.modulate = col
	l.outline_modulate = Color(0.25, 0.18, 0.08)
	l.outline_size = 36
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	return l

func pop_in(node: Node3D, seconds := 0.25) -> void:
	var s := node.scale
	node.scale = s * 0.05
	create_tween().tween_property(node, "scale", s, seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## A jump along an arc from a to b (await it).
func hop(node: Node3D, a: Vector3, b: Vector3, height := 0.8, seconds := 0.45) -> void:
	var t := create_tween()
	t.tween_method(func(u: float):
		node.position = a.lerp(b, u) + Vector3(0, sin(u * PI) * height, 0), 0.0, 1.0, seconds)
	await t.finished
