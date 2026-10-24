extends Node3D
## Debug/look aid: every kit dinosaur in a grid, side-on and three-quarter,
## saved to look-test/kit_<page>.png. Run windowed:
##   Godot --path . res://tools/kit_lineup.tscn -- [species ...]
const Species := preload("res://scripts/species.gd")
func _ready():
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.75, 0.88, 0.97)
	env.environment.ambient_light_color = Color(1,1,1); env.environment.ambient_light_energy = 0.6
	add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, -30, 0); add_child(sun)
	var list: Array = OS.get_cmdline_user_args()
	if list.is_empty():
		for k in Species.ALL:
			if Species.is_kit(k): list.append(k)
	var cam := Camera3D.new(); add_child(cam)
	var page := 0
	for start in range(0, list.size(), 4):
		var made := []
		for i in range(start, mini(start + 4, list.size())):
			var j := i - start
			var d = preload("res://scripts/kit_dino.gd").new(); add_child(d); d.setup(list[i], 2.0)
			d.position = Vector3((j % 2) * 4.6 - 2.3, 0, -(j / 2) * 4.5)
			d.rotation.y = PI / 2 + 0.35
			var l := Label3D.new(); l.text = list[i]; l.font_size = 64; l.position = d.position + Vector3(0, -0.4, 1.2); add_child(l)
			made.append(d); made.append(l)
		cam.position = Vector3(0, 3.2, 6.5); cam.look_at(Vector3(0, 0.8, -2.0))
		for f in 12: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://look-test/kit_%d.png" % page)
		page += 1
		for m in made: m.queue_free()
		await get_tree().process_frame
	get_tree().quit()
