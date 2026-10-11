extends CanvasLayer
## Everything on screen. Text is short and big so Dad can read it out and
## Felix can start reading it himself; numbers always come with dots.

signal answered(n: int)
signal action_pressed
signal activity_chosen(name: String)
signal target_chosen(t: int)
signal home_pressed
signal card_closed

const INK := Color(0.22, 0.32, 0.15)
const CREAM := Color(1, 0.98, 0.9, 0.95)
const GREEN := Color(0.35, 0.55, 0.25)
const ACTIVITIES := [["nest", "🥚", "Nest"], ["hide", "🌿", "Hide"], ["river", "🌊", "River"],
	["dig", "🦴", "Dig"], ["feed", "🍓", "Feed"], ["park", "🦕", "My park"]]

var font: Font
var question: PanelContainer
var question_label: Label
var eggs_label: Label
var home_button: Button
var answers: HBoxContainer
var action_button: Button
var banner: Label
var hint: Control
var menu: Control
var card: PanelContainer
var card_title: Label
var card_text: Label
var rounds: Label
var _target_buttons := {}
var _asked_at := 0.0

func _ready() -> void:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Arial Rounded MT Bold", "Arial Rounded MT", "Helvetica Neue", "Arial"])
	var emoji := SystemFont.new()
	emoji.font_names = PackedStringArray(["Apple Color Emoji", "Noto Color Emoji"])
	f.fallbacks = [emoji]
	font = f
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font = f
	theme.default_font_size = 40
	root.theme = theme
	_build(root)

func _panel_style(bg := CREAM, border := GREEN, radius := 28, width := 5) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	return sb

func _button(text: String, size := 40, bg := CREAM) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_stylebox_override("normal", _panel_style(bg))
	b.add_theme_stylebox_override("hover", _panel_style(bg.lightened(0.3), GREEN.lightened(0.2)))
	b.add_theme_stylebox_override("pressed", _panel_style(bg.darkened(0.1)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

func _build(root: Control) -> void:
	# Question across the top.
	question = PanelContainer.new()
	question.add_theme_stylebox_override("panel", _panel_style())
	question_label = Label.new()
	question_label.add_theme_font_size_override("font_size", 50)
	question_label.add_theme_color_override("font_color", INK)
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question.add_child(question_label)
	question.anchor_left = 0.5
	question.anchor_right = 0.5
	question.offset_top = 22
	question.grow_horizontal = Control.GROW_DIRECTION_BOTH
	question.visible = false
	root.add_child(question)
	# Egg count, top right.
	var ep := PanelContainer.new()
	ep.add_theme_stylebox_override("panel", _panel_style(CREAM, Color(0.85, 0.7, 0.4), 24, 4))
	eggs_label = Label.new()
	eggs_label.add_theme_font_size_override("font_size", 38)
	eggs_label.add_theme_color_override("font_color", INK)
	ep.add_child(eggs_label)
	ep.anchor_left = 1.0
	ep.anchor_right = 1.0
	ep.offset_left = -190
	ep.offset_right = -20
	ep.offset_top = 20
	root.add_child(ep)
	# Round dots, under the egg count.
	rounds = Label.new()
	rounds.add_theme_font_size_override("font_size", 30)
	rounds.add_theme_color_override("font_color", Color(1, 1, 1))
	rounds.add_theme_color_override("font_outline_color", INK)
	rounds.add_theme_constant_override("outline_size", 8)
	rounds.anchor_left = 1.0
	rounds.anchor_right = 1.0
	rounds.offset_left = -220
	rounds.offset_right = -24
	rounds.offset_top = 96
	rounds.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(rounds)
	# Home, top left.
	home_button = _button("🏠", 40)
	home_button.position = Vector2(20, 20)
	home_button.pressed.connect(func(): home_pressed.emit())
	root.add_child(home_button)
	# Answer buttons along the bottom.
	answers = HBoxContainer.new()
	answers.add_theme_constant_override("separation", 10)
	answers.anchor_left = 0.5
	answers.anchor_right = 0.5
	answers.anchor_top = 1.0
	answers.anchor_bottom = 1.0
	answers.offset_top = -150
	answers.offset_bottom = -22
	answers.grow_horizontal = Control.GROW_DIRECTION_BOTH
	answers.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(answers)
	# One big action button (e.g. "Feed Rex!"), bottom right.
	action_button = _button("Go!", 46, Color(0.98, 0.86, 0.5))
	action_button.anchor_left = 1.0
	action_button.anchor_right = 1.0
	action_button.anchor_top = 1.0
	action_button.anchor_bottom = 1.0
	action_button.offset_left = -330
	action_button.offset_right = -24
	action_button.offset_top = -130
	action_button.offset_bottom = -24
	action_button.visible = false
	action_button.pressed.connect(func(): action_pressed.emit())
	root.add_child(action_button)
	# Ten-frame hint, middle left.
	hint = TenFrame.new()
	hint.anchor_top = 0.5
	hint.anchor_bottom = 0.5
	hint.offset_left = 24
	hint.offset_top = -120
	hint.visible = false
	root.add_child(hint)
	# Banner, centre.
	banner = Label.new()
	banner.add_theme_font_size_override("font_size", 76)
	banner.add_theme_color_override("font_color", Color(1, 0.96, 0.6))
	banner.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.05))
	banner.add_theme_constant_override("outline_size", 22)
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	banner.visible = false
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner)
	_build_menu(root)
	_build_card(root)

func _build_menu(root: Control) -> void:
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 22)
	menu.set_anchors_preset(Control.PRESET_CENTER)
	menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(menu)
	var title := Label.new()
	title.text = "Dino Ten"
	title.add_theme_font_size_override("font_size", 110)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.55))
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.4, 0.15))
	title.add_theme_constant_override("outline_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(title)
	var targets := HBoxContainer.new()
	targets.alignment = BoxContainer.ALIGNMENT_CENTER
	targets.add_theme_constant_override("separation", 24)
	menu.add_child(targets)
	for t in [5, 10]:
		var b := _button("Make %d" % t, 50)
		b.custom_minimum_size = Vector2(250, 0)
		b.pressed.connect(func(): target_chosen.emit(t))
		targets.add_child(b)
		_target_buttons[t] = b
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	menu.add_child(grid)
	for a in ACTIVITIES:
		var b := _button("%s  %s" % [a[1], a[2]], 46)
		b.custom_minimum_size = Vector2(290, 110)
		var name: String = a[0]
		b.pressed.connect(func(): activity_chosen.emit(name))
		grid.add_child(b)

func _build_card(root: Control) -> void:
	card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(CREAM, Color(0.85, 0.55, 0.3), 32, 6))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.custom_minimum_size = Vector2(620, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	card.add_child(v)
	card_title = Label.new()
	card_title.add_theme_font_size_override("font_size", 58)
	card_title.add_theme_color_override("font_color", Color(0.55, 0.3, 0.1))
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(card_title)
	card_text = Label.new()
	card_text.add_theme_font_size_override("font_size", 40)
	card_text.add_theme_color_override("font_color", INK)
	card_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	card_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_text.custom_minimum_size = Vector2(560, 0)
	v.add_child(card_text)
	var ok := _button("OK", 44)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(func():
		card.visible = false
		card_closed.emit())
	v.add_child(ok)
	card.visible = false
	root.add_child(card)

# --- used by the game -------------------------------------------------------------

func set_eggs(n: int) -> void:
	eggs_label.text = "🥚 %d" % n

func pulse_eggs() -> void:
	var p: Control = eggs_label.get_parent()
	p.pivot_offset = p.size / 2
	var t := create_tween()
	t.tween_property(p, "scale", Vector2(1.3, 1.3), 0.12)
	t.tween_property(p, "scale", Vector2.ONE, 0.2)

func set_rounds(done: int, total: int) -> void:
	if total <= 0:
		rounds.text = ""
		return
	var s := ""
	for i in total:
		s += "● " if i < done else "○ "
	rounds.text = s.strip_edges()

func ask(text: String) -> void:
	question_label.text = text
	question.visible = text != ""
	if text != "":
		question.pivot_offset = question.size / 2
		question.scale = Vector2(0.9, 0.9)
		create_tween().tween_property(question, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

## Show buttons 0..top. Returns the number chosen (await it).
func ask_number(top: int, dots_per_row := 5) -> int:
	clear_answers()
	for n in range(0, top + 1):
		var b := _button("", 46)
		b.custom_minimum_size = Vector2(92 if top > 5 else 130, 120)
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		var l := Label.new()
		l.text = str(n)
		l.add_theme_font_size_override("font_size", 50)
		l.add_theme_color_override("font_color", INK)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
		var d := Dots.new()
		d.count = n
		d.per_row = dots_per_row
		d.custom_minimum_size = Vector2(80, 30)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(d)
		b.add_child(v)
		b.pressed.connect(func(): answered.emit(n))
		answers.add_child(b)
	_asked_at = Time.get_ticks_msec() / 1000.0
	var game := get_parent()
	if game.get("bot"):
		get_tree().create_timer(0.5).timeout.connect(func(): answered.emit(game.bot_answer(top)))
	var n: int = await answered
	clear_answers()
	return n

func seconds_since_asked() -> float:
	return Time.get_ticks_msec() / 1000.0 - _asked_at

func clear_answers() -> void:
	for c in answers.get_children():
		c.queue_free()

func show_action(text: String) -> void:
	action_button.text = text
	action_button.visible = text != ""

func show_hint(target: int, a: int, b: int) -> void:
	(hint as TenFrame).set_frame(target, a, b)
	hint.visible = true

func hide_hint() -> void:
	hint.visible = false

func flash(text: String, seconds := 1.6) -> void:
	banner.text = text
	banner.visible = true
	banner.pivot_offset = banner.size / 2
	banner.scale = Vector2(0.3, 0.3)
	banner.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(seconds)
	t.tween_property(banner, "modulate:a", 0.0, 0.3)
	t.tween_callback(func(): banner.visible = false)
	await t.finished

func show_menu(on: bool, target := 10) -> void:
	menu.visible = on
	question.visible = false
	home_button.visible = not on
	set_rounds(0, 0)
	for t in _target_buttons:
		var b: Button = _target_buttons[t]
		var bg := Color(0.98, 0.86, 0.5) if t == target else CREAM
		b.add_theme_stylebox_override("normal", _panel_style(bg, GREEN if t != target else Color(0.8, 0.5, 0.1)))

func show_card(title: String, text: String) -> void:
	card_title.text = title
	card_text.text = text
	card.visible = true
	card.pivot_offset = card.size / 2
	card.scale = Vector2(0.5, 0.5)
	create_tween().tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	if get_parent().get("bot"):
		get_tree().create_timer(0.6).timeout.connect(func():
			card.visible = false
			card_closed.emit())
	await card_closed


## A row (or rows) of dots under each number: the number as a picture.
class Dots extends Control:
	var count := 0
	var per_row := 5
	func _draw() -> void:
		var r := 5.5
		var gap := 14.0
		var rows := int(ceil(count / float(per_row))) if count > 0 else 0
		for i in count:
			var row := i / per_row
			var col := i % per_row
			var in_row: int = min(per_row, count - row * per_row)
			var x := size.x / 2 + (col - (in_row - 1) / 2.0) * gap
			var y := size.y / 2 + (row - (rows - 1) / 2.0) * gap
			draw_circle(Vector2(x, y), r, Color(0.85, 0.42, 0.2))


## The ten frame: `a` eggs filled, `b` more shown as the missing ones.
class TenFrame extends Control:
	var target := 10
	var a := 0
	var b := 0
	func set_frame(p_target: int, p_a: int, p_b: int) -> void:
		target = p_target
		a = p_a
		b = p_b
		var cols := 5
		var rows := 2 if target > 5 else 1
		custom_minimum_size = Vector2(cols * 64 + 30, rows * 64 + 30)
		size = custom_minimum_size
		queue_redraw()
	func _draw() -> void:
		var cols := 5
		var rows := 2 if target > 5 else 1
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.98, 0.9, 0.95), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.55, 0.25), false, 5.0)
		for i in rows * cols:
			var c := Vector2(15 + (i % cols) * 64 + 32, 15 + (i / cols) * 64 + 32)
			draw_rect(Rect2(c - Vector2(30, 30), Vector2(60, 60)), Color(0.35, 0.55, 0.25), false, 3.0)
			if i < a:
				draw_circle(c, 22, Color(0.98, 0.9, 0.72))
				draw_arc(c, 22, 0, TAU, 32, Color(0.55, 0.4, 0.2), 3.0)
			elif i < a + b:
				draw_circle(c, 22, Color(0.95, 0.55, 0.3, 0.85))
				draw_arc(c, 22, 0, TAU, 32, Color(0.6, 0.25, 0.1), 3.0)
