extends Node3D
## The valley: sky and sun, ground, river, the five play spots, plants, the
## park meadow, hills and a smoking volcano. Purely scenery -- the activities
## put their own props on the spots defined here.

const NATURE := "res://assets/nature/%s.gltf"

## Where each activity happens, and how the camera looks at it.
const SPOTS := {
	"nest":  {"at": Vector3(0, 0, 0),     "cam": Vector3(0, 5.6, 8.6),     "look": Vector3(0, 0.6, 0)},
	"hide":  {"at": Vector3(-14, 0, -3),  "cam": Vector3(-14, 4.0, 5.4),   "look": Vector3(-14, 1.0, -3.2)},
	"river": {"at": Vector3(14, 0, -1),   "cam": Vector3(20.8, 4.3, -1.0), "look": Vector3(14, 0.4, -1.0)},
	"dig":   {"at": Vector3(0, 0, -16),   "cam": Vector3(0, 5.4, -9.0),    "look": Vector3(0, 0.3, -15.0)},
	"feed":  {"at": Vector3(4, 0, 12),    "cam": Vector3(4, 4.4, 19.6),    "look": Vector3(4, 1.3, 11.6)},
	"sky":   {"at": Vector3(2, 0, 7),     "cam": Vector3(2, 2.0, 15.5),    "look": Vector3(2, 6.0, -2.0)},
	"park":  {"at": Vector3(-12, 0, 15),  "cam": Vector3(-12, 6.0, 23.5),  "look": Vector3(-12, 0.6, 14.6)},
	"menu":  {"at": Vector3(0, 0, 3),     "cam": Vector3(0, 23.0, 31.0),   "look": Vector3(0, 0, -2.0)},
}
const RIVER_X := 14.0
const RIVER_W := 7.0

var rng := RandomNumberGenerator.new()
var foliage_cache := {}

func _ready() -> void:
	rng.seed = 11
	_environment()
	_ground()
	_river()
	_scatter()
	_backdrop()

func spot(name: String) -> Dictionary:
	return SPOTS[name]

## Keep plants off the play spots and out of the river.
func _clear(p: Vector3, pad := 0.0) -> bool:
	for k in ["nest", "hide", "dig", "feed"]:
		var at: Vector3 = SPOTS[k]["at"]
		if Vector2(p.x - at.x, p.z - at.z).length() < 5.6 + pad:
			return false
	var park: Vector3 = SPOTS["park"]["at"]
	if Vector2(p.x - park.x, p.z - park.z).length() < 7.5 + pad:
		return false
	if abs(p.x - RIVER_X) < RIVER_W * 0.5 + 0.6 + pad:
		return false
	# the river is watched from its east bank, across the water
	if p.x > RIVER_X and p.x < 24.5 + pad and p.z > -9.0 - pad and p.z < 7.0 + pad:
		return false
	# keep each spot's view from its camera clear of tall things
	for k in ["nest", "hide", "dig", "feed"]:
		var at: Vector3 = SPOTS[k]["at"]
		var cam: Vector3 = SPOTS[k]["cam"]
		if p.x > min(at.x, cam.x) - 3.0 - pad and p.x < max(at.x, cam.x) + 3.0 + pad and p.z > at.z and p.z < cam.z + 1.0:
			return false
	return true

# --- sky, light, ground ---------------------------------------------------------

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
	env.fog_density = 0.005
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
	sun.directional_shadow_max_distance = 60
	add_child(sun)

func _ground() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	mi.mesh = pm
	var sh := ShaderMaterial.new()
	sh.shader = load("res://shaders/ground.gdshader")
	# earth patches (x, z, radius x, radius z) under the nest, dig, feed and hide spots
	var n: Vector3 = SPOTS["nest"]["at"]
	var d: Vector3 = SPOTS["dig"]["at"]
	var f: Vector3 = SPOTS["feed"]["at"]
	var h: Vector3 = SPOTS["hide"]["at"]
	sh.set_shader_parameter("patches", [Vector4(n.x, n.z, 3.2, 2.0), Vector4(d.x, d.z, 4.6, 3.4),
		Vector4(f.x, f.z, 3.0, 2.2), Vector4(h.x, h.z + 1.0, 4.2, 2.0)])
	sh.set_shader_parameter("sand", [0.0, 1.0, 0.0, 0.0])
	mi.material_override = sh
	add_child(mi)

func _river() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(RIVER_W, 200)
	mi.mesh = pm
	var sh := ShaderMaterial.new()
	sh.shader = load("res://shaders/water.gdshader")
	mi.material_override = sh
	mi.position = Vector3(RIVER_X, 0.04, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	# pebbly banks
	for i in 70:
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := rng.randf_range(-40, 40)
		var x := RIVER_X + side * (RIVER_W * 0.5 + rng.randf_range(-0.2, 0.8))
		var kind: String = ["RockPath_Round_Small_1", "RockPath_Round_Small_2", "Pebble_Round_1", "Pebble_Round_3", "Rock_Medium_2"][rng.randi() % 5]
		if abs(z - SPOTS["river"]["at"].z) < 9.0 and (kind == "Rock_Medium_2" or side > 0):
			continue  # keep the crossing (and the camera's side) clear
		place(kind, Vector3(x, 0, z), rng.randf_range(0.6, 1.1) if kind != "Rock_Medium_2" else 0.6)

# --- plants -------------------------------------------------------------------

func place(name: String, pos: Vector3, scale: float, rot := -1.0) -> Node3D:
	var n: Node3D = load(NATURE % name).instantiate()
	n.position = pos
	n.scale = Vector3.ONE * scale
	n.rotation.y = rot if rot >= 0 else rng.randf() * TAU
	add_child(n)
	_windify(n)
	return n

func _foliage_material(mat: Material) -> Material:
	if not (mat is StandardMaterial3D) or mat.albedo_texture == null:
		return mat
	var path: String = mat.albedo_texture.resource_path
	var sway := 0.0
	for key in ["Leaves", "Leaf", "Grass", "Flowers", "Fern", "Plant"]:
		if key in path:
			sway = 0.05 if key.begins_with("Lea") else 0.12
	if sway == 0.0:
		return mat
	if not foliage_cache.has(mat):
		var sm := ShaderMaterial.new()
		sm.shader = load("res://shaders/foliage.gdshader")
		sm.set_shader_parameter("tex", mat.albedo_texture)
		sm.set_shader_parameter("tint", mat.albedo_color)
		sm.set_shader_parameter("sway", sway)
		foliage_cache[mat] = sm
	return foliage_cache[mat]

func _windify(n: Node) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var m := _foliage_material(mi.get_active_material(s))
			if m != mi.get_active_material(s):
				mi.set_surface_override_material(s, m)

## Lots of one small plant drawn in a single batch.
func _carpet(name: String, positions: Array, smin: float, smax: float) -> void:
	var scene: Node3D = load(NATURE % name).instantiate()
	for src in scene.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (src as MeshInstance3D).mesh.duplicate()
		for s in mesh.get_surface_count():
			mesh.surface_set_material(s, _foliage_material(src.get_active_material(s)))
		var local: Transform3D = _path_transform(src, scene)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = positions.size()
		for i in positions.size():
			var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(smin, smax))
			mm.set_instance_transform(i, Transform3D(b, positions[i]) * local)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
	scene.free()

func _path_transform(node: Node3D, root: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n and n != root:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t

func _scatter() -> void:
	# Trees: a big ring round the valley, plus a few clumps between the spots.
	var trees := ["CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4", "CommonTree_5", "TwistedTree_2", "TwistedTree_4", "Pine_2"]
	for i in 70:
		var a := rng.randf() * TAU
		var r := rng.randf_range(27, 40)
		var p := Vector3(cos(a) * r, 0, sin(a) * r * 0.9 - 4)
		if p.z > 18 and abs(p.x) < 16:
			continue  # the menu camera looks in from the south
		if not _clear(p, 1.5):
			continue
		place(trees[rng.randi() % trees.size()], p, rng.randf_range(1.2, 1.8))
	for i in 40:
		var p := Vector3(rng.randf_range(-24, 24), 0, rng.randf_range(-26, 8))
		if _clear(p, 2.5):
			place(trees[rng.randi() % trees.size()], p, rng.randf_range(1.0, 1.5))
	# Ferns, leafy plants, bushes and rocks.
	var mids := ["Fern_1", "Fern_1", "Plant_1_Big", "Plant_7_Big", "Plant_7", "Bush_Common", "Bush_Common_Flowers", "Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3", "Mushroom_Laetiporus"]
	for i in 170:
		var p := Vector3(rng.randf_range(-28, 26), 0, rng.randf_range(-30, 26))
		if not _clear(p, 0.2):
			continue
		var kind: String = mids[rng.randi() % mids.size()]
		var sc := rng.randf_range(0.9, 1.4) if kind.begins_with("Rock") else rng.randf_range(0.55, 0.9)
		place(kind, p, sc)
	# A carpet of grass, clover, flowers and pebbles, drawn in batches.
	var smalls := {"Grass_Common_Tall": [0.28, 0.42], "Grass_Wispy_Tall": [0.28, 0.42], "Grass_Common_Short": [0.4, 0.6],
		"Grass_Wispy_Short": [0.4, 0.6], "Flower_3_Group": [0.3, 0.42], "Flower_4_Group": [0.3, 0.42], "Clover_1": [0.35, 0.5],
		"Clover_2": [0.35, 0.5], "Pebble_Round_2": [0.4, 0.7], "Mushroom_Common": [0.35, 0.5], "Flower_3_Single": [0.35, 0.5]}
	for name in smalls:
		var pts := []
		var count := 260 if name.begins_with("Grass") else 90
		for i in count:
			var p := Vector3(rng.randf_range(-30, 28), 0, rng.randf_range(-32, 28))
			if abs(p.x - RIVER_X) < RIVER_W * 0.5 + 0.3:
				continue
			var inside_spot := not _clear(p)
			if inside_spot and not (name.begins_with("Grass_Common_Short") or name.begins_with("Clover")):
				continue
			pts.append(p)
		_carpet(name, pts, smalls[name][0], smalls[name][1])

func _backdrop() -> void:
	# Rolling green hills and a smoking volcano on the horizon.
	var hill_mat := StandardMaterial3D.new()
	hill_mat.albedo_color = Color(0.36, 0.6, 0.3)
	hill_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	for h in [[Vector3(-34, -6, -62), Vector3(30, 15, 16)], [Vector3(22, -7, -66), Vector3(36, 17, 18)],
			[Vector3(58, -6, -30), Vector3(20, 12, 24)], [Vector3(-60, -6, -20), Vector3(22, 13, 24)],
			[Vector3(-58, -6, 20), Vector3(20, 10, 20)], [Vector3(60, -6, 22), Vector3(20, 10, 20)]]:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.material = hill_mat
		mi.mesh = sm
		mi.position = h[0]
		mi.scale = h[1]
		add_child(mi)
	var vat := Vector3(-8, 0, -78)
	var volcano := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 3.0
	cm.bottom_radius = 16
	cm.height = 20
	cm.radial_segments = 20
	var vm := StandardMaterial3D.new()
	vm.albedo_color = Color(0.48, 0.36, 0.3)
	vm.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	cm.material = vm
	volcano.mesh = cm
	volcano.position = vat + Vector3(0, 8, 0)
	add_child(volcano)
	var lava := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 2.8
	lm.bottom_radius = 2.8
	lm.height = 0.2
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(1, 0.45, 0.1)
	lmat.emission_enabled = true
	lmat.emission = Color(1, 0.4, 0.05)
	lmat.emission_energy_multiplier = 3
	lm.material = lmat
	lava.mesh = lm
	lava.position = vat + Vector3(0, 18.05, 0)
	add_child(lava)
	var smoke := CPUParticles3D.new()
	smoke.amount = 28
	smoke.lifetime = 9
	smoke.preprocess = 9
	var puff := SphereMesh.new()
	puff.radius = 1.6
	puff.height = 3.2
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
	smoke.position = vat + Vector3(0, 18.5, 0)
	add_child(smoke)
