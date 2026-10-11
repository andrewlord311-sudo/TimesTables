extends Node3D
## Debug/look aid: one dinosaur, close camera, saves a PNG and quits.
func _ready():
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.75, 0.88, 0.97)
	env.environment.ambient_light_color = Color(1,1,1); env.environment.ambient_light_energy = 0.6
	add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, -30, 0); add_child(sun)
	var sp: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() else "Trex"
	var d = preload("res://scripts/dino.gd").new(); add_child(d); d.setup(sp, 3.0)
	d.rotation.y = 0.6
	var cam := Camera3D.new(); add_child(cam)
	cam.position = Vector3(1.8, 2.6, 4.2); cam.look_at(Vector3(0, 1.6, 1.0))
	for i in 20: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://look-test/closeup_%s.png" % sp)
	get_tree().quit()
