extends Node3D
## Debug/look aid: a pterosaur from three angles, saved to look-test/ptero.png.
func _ready():
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.62, 0.82, 0.97)
	env.environment.ambient_light_color = Color(1,1,1); env.environment.ambient_light_energy = 0.6
	add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, -30, 0); add_child(sun)
	var P = preload("res://scripts/pterosaur.gd")
	for i in 3:
		var p = P.new(); add_child(p)
		p.setup(Color(0.95, 0.55, 0.25), Color(0.99, 0.8, 0.55), Color(0.9, 0.3, 0.3))
		p.position = Vector3((i - 1) * 4.2, 0, 0)
		p.rotation = [Vector3(0.3, 0.6, 0), Vector3(-0.2, PI / 2, 0.1), Vector3(0.9, 0.0, 0)][i]
		p.scale = Vector3.ONE * 1.4
	var cam := Camera3D.new(); add_child(cam)
	cam.position = Vector3(0, 1.0, 5.6); cam.look_at(Vector3(0, 0.2, 0))
	for i in 12: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://look-test/ptero.png")
	get_tree().quit()
