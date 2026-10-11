extends Node3D
## One Quaternius dinosaur, made friendlier: smooth shading, toon materials in
## brighter colours, a dark outline, and big cartoon eyes on the head bone.

const PALETTES := {
	"Trex": {"Green": Color(0.38, 0.66, 0.30), "LightGreen": Color(0.98, 0.88, 0.58),
		"Red": Color(0.93, 0.48, 0.52), "LightYellow": Color(1.0, 0.98, 0.90), "Black": Color(0.13, 0.11, 0.10)},
	"Triceratops": {"Purple": Color(0.36, 0.58, 0.86), "LightBrown": Color(0.98, 0.90, 0.72), "Brown": Color(0.27, 0.40, 0.70)},
	"Parasaurolophus": {"Green": Color(0.95, 0.62, 0.30), "LightGreen": Color(0.99, 0.86, 0.62),
		"LightYellow": Color(0.98, 0.80, 0.45), "Red": Color(0.86, 0.36, 0.30)},
	"Stegosaurus": {"DarkBrown": Color(0.62, 0.40, 0.70), "LightBrown": Color(0.95, 0.82, 0.92), "Brown": Color(0.95, 0.55, 0.35)},
}

const EYE_BACK := {"Trex": 0.13, "Triceratops": 0.12, "Parasaurolophus": 0.06, "Stegosaurus": 0.05}
const EYE_DOWN := {"Triceratops": 0.07}  # below the brow horns, not at their tips
const EYE_SIZE := {}

var species := "Trex"
var height := 2.4
var anim: AnimationPlayer
var _prefix := ""

func setup(p_species: String, p_height: float) -> void:
	species = p_species
	height = p_height
	var model: Node3D = load("res://assets/dinos/%s.fbx" % species).instantiate()
	add_child(model)
	var sk: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var mi: MeshInstance3D = model.find_children("*", "MeshInstance3D", true, false)[0]
	var armature: Node3D = model.get_node("Armature")
	var arm_scale := armature.transform.basis.get_scale().x
	# Measure the dinosaur as it really stands: every vertex taken through its
	# bind pose and its bone's rest pose into skeleton space. (The raw meshes in
	# this pack aren't oriented alike -- the Triceratops lies on its side until
	# skinned -- and the bind poses carry scales, so the mesh itself can't be trusted.)
	var pts := _skeleton_space_points(sk, mi)
	var lo := pts[0]
	var hi := pts[0]
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	model.scale = Vector3.ONE * (height / (max(hi.z - lo.z, 0.0001) * arm_scale))
	_restyle(mi, arm_scale * model.scale.x)
	_add_eyes(sk, pts, lo, hi)
	anim = model.find_children("*", "AnimationPlayer", true, false)[0]
	for a in anim.get_animation_list():
		if a.ends_with("_Idle"):
			_prefix = a.trim_suffix("Idle")
	for loop_name in ["Idle", "Walk", "Run"]:
		var an := anim.get_animation(_prefix + loop_name)
		if an:
			an.loop_mode = Animation.LOOP_LINEAR
	play("Idle")

func play(name: String, speed := 1.0) -> void:
	var full := _prefix + name
	if anim and anim.has_animation(full):
		if anim.current_animation != full:
			anim.play(full, 0.25, speed)
		else:
			anim.speed_scale = speed

func is_playing(name: String) -> bool:
	return anim.current_animation == _prefix + name and anim.is_playing()

# --- looks -----------------------------------------------------------------

func _restyle(mi: MeshInstance3D, world_per_unit: float) -> void:
	var src: ArrayMesh = mi.mesh
	var smooth := _smoothed(src)
	var pal: Dictionary = PALETTES.get(species, {})
	for s in smooth.get_surface_count():
		var old := src.surface_get_material(s)
		var key := old.resource_name if old else ""
		var col: Color = pal.get(key, old.albedo_color.lightened(0.25) if old is BaseMaterial3D else Color.WHITE)
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		m.specular_mode = BaseMaterial3D.SPECULAR_TOON
		m.roughness = 0.55
		m.rim_enabled = true
		m.rim = 0.35
		m.rim_tint = 0.6
		var outline := StandardMaterial3D.new()
		outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		outline.cull_mode = BaseMaterial3D.CULL_FRONT
		outline.albedo_color = col.darkened(0.72)
		outline.grow = true
		outline.grow_amount = 0.022 / world_per_unit
		m.next_pass = outline
		smooth.surface_set_material(s, m)
	mi.mesh = smooth

## The pack is flat-shaded (every face its own normal). Average the normals of
## vertices that share a position so the toon shading reads as soft and round.
func _smoothed(src: ArrayMesh) -> ArrayMesh:
	var all := []
	var acc := {}
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		all.append(arr)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		for i in v.size():
			var k := v[i].snapped(Vector3.ONE * 1e-6)
			acc[k] = acc.get(k, Vector3.ZERO) + n[i]
	var out := ArrayMesh.new()
	for s in all.size():
		var arr: Array = all[s]
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n := PackedVector3Array()
		n.resize(v.size())
		for i in v.size():
			n[i] = (acc[v[i].snapped(Vector3.ONE * 1e-6)] as Vector3).normalized()
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_TANGENT] = null
		var flags := src.surface_get_format(s) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, flags)
	return out

## Vertex positions in skeleton space at the rest pose (each vertex follows the
## bone it's weighted to most). Skeleton space is the same for every species:
## +Z up, and the head is along -Y.
func _skeleton_space_points(sk: Skeleton3D, mi: MeshInstance3D) -> PackedVector3Array:
	var skin := mi.skin
	var to_skel := []
	for i in skin.get_bind_count():
		var b := skin.get_bind_bone(i)
		if b < 0:
			b = sk.find_bone(skin.get_bind_name(i))
		to_skel.append(sk.get_bone_global_rest(b) * skin.get_bind_pose(i))
	var out := PackedVector3Array()
	for s in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
		var per: int = bones.size() / maxi(v.size(), 1)
		for i in v.size():
			var best := 0
			for k in per:
				if weights[i * per + k] > weights[i * per + best]:
					best = k
			out.append((to_skel[bones[i * per + best]] as Transform3D) * v[i])
	return out

## Big cartoon eyes. The pack's models have no eyes of their own, so find the
## head from the shape: the snout is the furthest point forward (-Y), and the
## eyes sit a little behind it, high on each side. They hang off the head bone
## so they move with it.
func _add_eyes(sk: Skeleton3D, pts: PackedVector3Array, lo: Vector3, hi: Vector3) -> void:
	var hb := sk.find_bone("Head")
	if hb < 0:
		return
	var length := hi.y - lo.y
	var eye_y: float = lo.y + length * float(EYE_BACK.get(species, 0.13))
	var band := length * 0.025
	var top := -INF
	for p in pts:
		if abs(p.y - eye_y) < band:
			top = max(top, p.z)
	var eye_z := top - length * float(EYE_DOWN.get(species, 0.03))
	var half_w := 0.0
	for p in pts:
		if abs(p.y - eye_y) < band and abs(p.z - eye_z) < length * 0.03:
			half_w = max(half_w, abs(p.x))
	if half_w == 0.0:
		return
	var att := BoneAttachment3D.new()
	att.bone_name = "Head"
	sk.add_child(att)
	var to_head := sk.get_bone_global_rest(hb).affine_inverse()
	var r := length * float(EYE_SIZE.get(species, 0.024))
	for sx in [-1.0, 1.0]:
		var c := Vector3(sx * (half_w - r * 0.35), eye_y, eye_z)
		var out := Vector3(sx, 0, 0)
		var fwd := Vector3(0, -1, 0)
		_sphere(att, to_head * c, r, Color(1, 1, 1), true)
		_sphere(att, to_head * (c + (out * 0.62 + fwd * 0.45 + Vector3(0, 0, 0.12)).normalized() * r * 0.6), r * 0.58, Color(0.08, 0.06, 0.06), false)
		_sphere(att, to_head * (c + (out * 0.75 + fwd * 0.4 + Vector3(0, 0, 0.5)).normalized() * r * 1.0), r * 0.18, Color(1, 1, 1), false, true)

func _sphere(parent: Node3D, pos: Vector3, r: float, col: Color, outlined: bool, unshaded := false) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2
	sm.radial_segments = 24
	sm.rings = 12
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.roughness = 0.3
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if outlined:
		var o := StandardMaterial3D.new()
		o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		o.cull_mode = BaseMaterial3D.CULL_FRONT
		o.albedo_color = Color(0.12, 0.1, 0.09)
		o.grow = true
		o.grow_amount = r * 0.12
		m.next_pass = o
	sm.material = m
	mi.mesh = sm
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
