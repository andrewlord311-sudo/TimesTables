extends Node3D
## Look test: one jungle clearing, Felix's T. rex walking round a nest of eggs,
## two other dinosaurs grazing. Click the ground (or arrow keys) to walk;
## space to roar. With --demo it walks itself round for recording.

const Dino := preload("res://dino.gd")
const NATURE := "res://assets/nature/%s.gltf"

var rex: Node3D
var cam: Camera3D
var target := Vector3.ZERO
var walking := false
var demo := false
var demo_points := [Vector3(2.8, 0, 1.6), Vector3(-0.8, 0, 2.6), Vector3(-2.8, 0, 0.2), Vector3(0.6, 0, -2.4)]
var demo_i := 0
var wait := 1.5
var rng := RandomNumberGenerator.new()
var foliage_cache := {}
var eggs := []

func _ready() -> void:
	demo = "--demo" in OS.get_cmdline_user_args()
	rng.seed = 7
	_environment()
	_ground()
	_scatter()
	_backdrop()
	_nest(Vector3(0, 0, 0))
	rex = Dino.new()
	add_child(rex)
	rex.setup("Trex", 3.0)
	rex.position = Vector3(2.5, 0, 3.0)
	rex.rotation.y = PI
	for d in [["Triceratops", 1.9, Vector3(-6.0, 0, -4.0), 0.9], ["Parasaurolophus", 3.2, Vector3(6.5, 0, -6.0), -0.8], ["Stegosaurus", 2.2, Vector3(-9.0, 0, 1.5), 2.2]]:
		var other: Node3D = Dino.new()
		add_child(other)
		other.setup(d[0], d[1])
		other.position = d[2]
		other.rotation.y = d[3]
	cam = Camera3D.new()
	cam.fov = 50
	add_child(cam)
	cam.position = rex.position + Vector3(0, 3.6, 6.6)
	cam.look_at(rex.position + Vector3(0, 1.3, 0))
	_ui()

# --- world -------------------------------------------------------------------

func _environment() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.32, 0.6, 0.92)
	sm.sky_horizon_color = Color(0.78, 0.9, 0.98)
	sm.ground_horizon_color = Color(0.7, 0.82, 0.6)
	sm.ground_bottom_color = Color(0.3, 0.45, 0.25)
	sm.sun_angle_max = 20
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.08
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.75, 0.86, 0.95)
	env.fog_density = 0.006
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 45
	add_child(sun)

func _ground() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 160)
	pm.subdivide_width = 1
	mi.mesh = pm
	var sh := ShaderMaterial.new()
	sh.shader = load("res://shaders/ground.gdshader")
	mi.material_override = sh
	add_child(mi)

func _place(name: String, pos: Vector3, scale: float, rot := -1.0) -> Node3D:
	var n: Node3D = load(NATURE % name).instantiate()
	n.position = pos
	n.scale = Vector3.ONE * scale
	n.rotation.y = rot if rot >= 0 else rng.randf() * TAU
	add_child(n)
	_windify(n)
	return n

func _windify(n: Node) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var mat: Material = mi.get_active_material(s)
			if not (mat is StandardMaterial3D) or mat.albedo_texture == null:
				continue
			var path: String = mat.albedo_texture.resource_path
			var sway := 0.0
			for key in ["Leaves", "Leaf", "Grass", "Flowers", "Fern", "Plant"]:
				if key in path:
					sway = 0.05 if key.begins_with("Lea") else 0.12
			if sway == 0.0:
				continue
			if not foliage_cache.has(mat):
				var sm := ShaderMaterial.new()
				sm.shader = load("res://shaders/foliage.gdshader")
				sm.set_shader_parameter("tex", mat.albedo_texture)
				sm.set_shader_parameter("tint", mat.albedo_color)
				sm.set_shader_parameter("sway", sway)
				foliage_cache[mat] = sm
			mi.set_surface_override_material(s, foliage_cache[mat])

func _scatter() -> void:
	# A ring of trees round the clearing, open towards the camera.
	for i in 26:
		var a := rng.randf() * TAU
		if abs(wrapf(a - PI * 0.5, -PI, PI)) < 0.55:
			continue  # keep the view from the camera clear
		var r := rng.randf_range(13, 22)
		var tree: String = ["CommonTree_1", "CommonTree_3", "CommonTree_5", "TwistedTree_2"][rng.randi() % 4]
		_place(tree, Vector3(cos(a) * r, 0, sin(a) * r), rng.randf_range(1.1, 1.6))
	# Ferns, big leafy plants, bushes and rocks at the edge of the clearing.
	for i in 55:
		var a := rng.randf() * TAU
		var r := rng.randf_range(7, 14)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if p.z > 5 and abs(p.x) < 6:
			continue
		var kind: String = ["Fern_1", "Fern_1", "Plant_1_Big", "Plant_7_Big", "Bush_Common", "Bush_Common_Flowers", "Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"][rng.randi() % 9]
		var sc := rng.randf_range(0.9, 1.4) if kind.begins_with("Rock") else rng.randf_range(0.55, 0.85)
		_place(kind, p, sc)
	# Grass, flowers, clover and mushrooms everywhere except the dirt round the nest.
	for i in 520:
		var p := Vector3(rng.randf_range(-16, 16), 0, rng.randf_range(-16, 12))
		if p.length() < 5.2:
			continue  # the clearing round the nest stays open so Rex can be seen
		var kind: String = ["Grass_Common_Tall", "Grass_Wispy_Tall", "Grass_Common_Tall", "Flower_3_Group", "Flower_4_Group", "Clover_1", "Pebble_Round_2", "Mushroom_Common"][rng.randi() % 8]
		_place(kind, p, rng.randf_range(0.28, 0.45))
	# A few short grass tufts inside the clearing, below knee height.
	for i in 90:
		var a := rng.randf() * TAU
		var r := rng.randf_range(3.6, 5.2)
		_place(["Grass_Common_Tall", "Clover_1", "Grass_Wispy_Tall"][rng.randi() % 3], Vector3(cos(a) * r, 0, sin(a) * r), rng.randf_range(0.2, 0.3))

func _backdrop() -> void:
	# Rolling green hills and a smoking volcano on the horizon.
	var hill_mat := StandardMaterial3D.new()
	hill_mat.albedo_color = Color(0.36, 0.6, 0.3)
	hill_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	for h in [[Vector3(-30, -6, -45), Vector3(28, 14, 16)], [Vector3(18, -7, -50), Vector3(34, 16, 18)], [Vector3(45, -6, -25), Vector3(20, 11, 20)], [Vector3(-48, -6, -15), Vector3(20, 12, 22)]]:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.material = hill_mat
		mi.mesh = sm
		mi.position = h[0]
		mi.scale = h[1]
		add_child(mi)
	var volcano := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 2.5
	cm.bottom_radius = 13
	cm.height = 16
	cm.radial_segments = 20
	var vm := StandardMaterial3D.new()
	vm.albedo_color = Color(0.48, 0.36, 0.3)
	vm.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	cm.material = vm
	volcano.mesh = cm
	volcano.position = Vector3(-5, 6, -62)
	add_child(volcano)
	var lava := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 2.3
	lm.bottom_radius = 2.3
	lm.height = 0.2
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(1, 0.45, 0.1)
	lmat.emission_enabled = true
	lmat.emission = Color(1, 0.4, 0.05)
	lmat.emission_energy_multiplier = 3
	lm.material = lmat
	lava.mesh = lm
	lava.position = Vector3(-5, 14.05, -62)
	add_child(lava)
	var smoke := CPUParticles3D.new()
	smoke.amount = 28
	smoke.lifetime = 9
	smoke.preprocess = 9
	var puff := SphereMesh.new()
	puff.radius = 1.4
	puff.height = 2.8
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.85, 0.85, 0.88, 0.85)
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	pmat.vertex_color_use_as_albedo = true
	puff.material = pmat
	smoke.mesh = puff
	smoke.direction = Vector3(0.3, 1, 0)
	smoke.spread = 12
	smoke.initial_velocity_min = 1.5
	smoke.initial_velocity_max = 2.5
	smoke.gravity = Vector3(0.25, 0.1, 0)
	smoke.scale_amount_min = 0.8
	smoke.scale_amount_max = 1.6
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.5))
	curve.add_point(Vector2(1, 2.4))
	smoke.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.9))
	grad.set_color(1, Color(1, 1, 1, 0))
	smoke.color_ramp = grad
	smoke.position = Vector3(-5, 14.5, -62)
	add_child(smoke)

func _nest(at: Vector3) -> void:
	# A twiggy nest laid out as a ten frame: 2 rows of 5 hollows, 7 eggs in it.
	var nest := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.95
	tm.outer_radius = 1.45
	tm.rings = 48
	tm.ring_segments = 14
	var nm := ShaderMaterial.new()
	nm.shader = load("res://shaders/twigs.gdshader")
	tm.material = nm
	nest.mesh = tm
	nest.scale = Vector3(1.6, 0.55, 0.8)
	nest.position = at + Vector3(0, 0.12, 0)
	add_child(nest)
	var bed := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.08
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.55, 0.42, 0.25)
	bm.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	cyl.material = bm
	bed.mesh = cyl
	bed.scale = Vector3(1.62, 1, 0.8)
	bed.position = at + Vector3(0, 0.05, 0)
	add_child(bed)
	var egg_mat := ShaderMaterial.new()
	egg_mat.shader = load("res://shaders/egg.gdshader")
	for row in 2:
		for col in 5:
			var p := at + Vector3((col - 2) * 0.56, 0, (row - 0.5) * 0.6)
			var idx := row * 5 + col
			if idx < 7:
				var egg := MeshInstance3D.new()
				var em := SphereMesh.new()
				em.radius = 0.2
				em.height = 0.54
				em.material = egg_mat
				egg.mesh = em
				egg.position = p + Vector3(0, 0.3, 0)
				egg.rotation.z = rng.randf_range(-0.15, 0.15)
				add_child(egg)
				eggs.append(egg)
			else:
				var hollow := MeshInstance3D.new()
				var hm := CylinderMesh.new()
				hm.top_radius = 0.2
				hm.bottom_radius = 0.16
				hm.height = 0.04
				var hmat := StandardMaterial3D.new()
				hmat.albedo_color = Color(0.36, 0.26, 0.15)
				hm.material = hmat
				hollow.mesh = hm
				hollow.position = p + Vector3(0, 0.1, 0)
				add_child(hollow)

func _ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 0.98, 0.9, 0.92)
	sb.set_corner_radius_all(28)
	sb.border_color = Color(0.35, 0.55, 0.25)
	sb.set_border_width_all(5)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	var label := Label.new()
	label.text = "7 eggs.  How many more?"
	label.add_theme_font_size_override("font_size", 46)
	label.add_theme_color_override("font_color", Color(0.22, 0.32, 0.15))
	panel.add_child(label)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_top = 22
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	layer.add_child(panel)

# --- play ----------------------------------------------------------------------

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var from := cam.project_ray_origin(e.position)
		var dir := cam.project_ray_normal(e.position)
		if dir.y < -0.01:
			var hit := from + dir * (-from.y / dir.y)
			_walk_to(hit)
	elif e is InputEventKey and e.pressed and e.keycode == KEY_SPACE:
		_roar()

func _walk_to(p: Vector3) -> void:
	p.y = 0
	if p.length() < 2.4:
		p = p.normalized() * 2.4  # walk round the nest, not over the eggs
	target = p
	walking = true

func _roar() -> void:
	walking = false
	rex.play("Attack")
	for egg in eggs:
		var t := create_tween()
		t.tween_property(egg, "rotation:z", 0.35, 0.08)
		t.tween_property(egg, "rotation:z", -0.3, 0.12)
		t.tween_property(egg, "rotation:z", 0.0, 0.15)

func _process(delta: float) -> void:
	var keys := Vector3(Input.get_axis("ui_left", "ui_right"), 0, Input.get_axis("ui_up", "ui_down"))
	if keys.length() > 0.1:
		walking = false
		_step(keys.normalized(), delta, 3.0)
	elif walking:
		var to := target - rex.position
		if to.length() < 0.15:
			walking = false
		else:
			_step(to.normalized(), delta, 2.4)
	elif demo:
		wait -= delta
		if wait <= 0 and not rex.is_playing("Attack"):
			if demo_i % 3 == 2 and wait > -0.1:
				_roar()
				wait = 2.6
			else:
				_walk_to(demo_points[demo_i % demo_points.size()])
				wait = 1.2
			demo_i += 1
	if not walking and keys.length() < 0.1 and not rex.is_playing("Attack"):
		rex.play("Idle")
	# The camera trails above and in front.
	# It frames the dinosaur *and* the nest, so the eggs stay in view.
	var focus := rex.position.lerp(Vector3.ZERO, 0.45)
	var want := focus + Vector3(0, 5.0, 8.2)
	cam.position = cam.position.lerp(want, 1.0 - exp(-delta * 2.0))
	cam.look_at(cam.position + (focus + Vector3(0, 0.9, 0) - cam.position).normalized())

func _step(dir: Vector3, delta: float, speed: float) -> void:
	var next := rex.position + dir * speed * delta
	if next.length() < 2.3:
		next = next.normalized() * 2.3
	rex.position = next
	var want := atan2(dir.x, dir.z)
	rex.rotation.y = lerp_angle(rex.rotation.y, want, 1.0 - exp(-delta * 9.0))
	rex.play("Walk", speed / 2.4)
