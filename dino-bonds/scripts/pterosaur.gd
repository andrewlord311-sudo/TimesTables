extends Node3D
## A friendly low-poly pterosaur built in code, to match the Quaternius
## dinosaurs (there's no free animated one): a lofted body and long beak,
## a crest, two-part wings that flap, toon shading, an outline, big eyes.
## Local space: +Z forward, +Y up.

var body_col := Color(0.95, 0.55, 0.25)
var wing_col := Color(0.99, 0.80, 0.55)
var crest_col := Color(0.9, 0.3, 0.3)
var flap_speed := 7.0
var _t := 0.0
var _wings: Array = []   # [inner, outer, side]

func setup(p_body: Color, p_wing: Color, p_crest: Color) -> void:
	body_col = p_body
	wing_col = p_wing
	crest_col = p_crest
	_t = randf() * 10.0
	var body_mat := _toon(body_col, true)
	# Body, tail to neck: stations are [z, y, radius x, radius y].
	_add(_loft([[-1.0, 0.02, 0.01, 0.01], [-0.75, 0.0, 0.06, 0.05], [-0.4, 0.0, 0.16, 0.14], [0.0, 0.02, 0.22, 0.19],
		[0.3, 0.05, 0.17, 0.16], [0.5, 0.1, 0.09, 0.1]]), body_mat)
	# Neck, head and long beak.
	_add(_loft([[0.45, 0.08, 0.08, 0.09], [0.62, 0.16, 0.12, 0.13], [0.8, 0.2, 0.12, 0.12], [0.98, 0.16, 0.07, 0.07],
		[1.25, 0.1, 0.035, 0.035], [1.55, 0.05, 0.005, 0.008]]), body_mat)
	# Crest sweeping back off the head.
	_add(_prism([Vector3(0, 0.3, 0.86), Vector3(0, 0.62, 0.38), Vector3(0, 0.27, 0.6)], 0.025), _toon(crest_col, true))
	# Wings: inner (shoulder to wrist) and outer (wrist to tip) on each side.
	var wing_mat := _toon(wing_col, false)
	for side in [-1.0, 1.0]:
		var inner := Node3D.new()
		inner.position = Vector3(0.14 * side, 0.08, 0.15)
		add_child(inner)
		inner.add_child(_mesh(_plate([Vector3(0, 0, 0.12), Vector3(0.85 * side, 0.02, 0.2), Vector3(0.8 * side, 0.0, -0.25), Vector3(0, 0, -0.5)], 0.02), wing_mat))
		inner.add_child(_mesh(_loft_x(0.0, 0.85 * side, 0.12, 0.2, 0.035), _toon(body_col, false)))  # arm along the front edge
		var outer := Node3D.new()
		outer.position = Vector3(0.85 * side, 0.02, 0.0)
		inner.add_child(outer)
		outer.add_child(_mesh(_plate([Vector3(0, 0, 0.2), Vector3(1.25 * side, 0.0, -0.05), Vector3(1.32 * side, 0, -0.12), Vector3(0, 0, -0.25)], 0.015), wing_mat))
		outer.add_child(_mesh(_loft_x(0.0, 1.3 * side, 0.2, -0.06, 0.025), _toon(body_col, false)))
		_wings.append([inner, outer, side])
	_eyes()

func _process(delta: float) -> void:
	_t += delta * flap_speed
	for w in _wings:
		var side: float = w[2]
		(w[0] as Node3D).rotation.z = side * (sin(_t) * 0.55 + 0.1)
		(w[1] as Node3D).rotation.z = side * (sin(_t - 0.7) * 0.45)

# --- geometry -----------------------------------------------------------------

func _toon(col: Color, outlined: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.roughness = 0.55
	m.rim_enabled = true
	m.rim = 0.35
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if outlined:
		var o := StandardMaterial3D.new()
		o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		o.cull_mode = BaseMaterial3D.CULL_FRONT
		o.albedo_color = col.darkened(0.72)
		o.grow = true
		o.grow_amount = 0.018
		m.next_pass = o
	return m

func _mesh(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	return mi

func _add(mesh: Mesh, mat: Material) -> void:
	add_child(_mesh(mesh, mat))

## A smooth tube through elliptical rings: stations are [z, y, radius x, radius y].
func _loft(stations: Array, seg := 12) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var rings := []
	for s in stations:
		var ring := []
		for k in seg:
			var a := TAU * k / seg
			ring.append(Vector3(cos(a) * float(s[2]), float(s[1]) + sin(a) * float(s[3]), float(s[0])))
		rings.append(ring)
	for i in rings.size() - 1:
		for k in seg:
			var a: Vector3 = rings[i][k]
			var b: Vector3 = rings[i][(k + 1) % seg]
			var c: Vector3 = rings[i + 1][k]
			var d: Vector3 = rings[i + 1][(k + 1) % seg]
			for v in [a, b, c, b, d, c]:
				st.add_vertex(v)
	# close both ends
	for e in [0, rings.size() - 1]:
		var centre := Vector3.ZERO
		for v in rings[e]:
			centre += v
		centre /= seg
		for k in seg:
			var a: Vector3 = rings[e][k]
			var b: Vector3 = rings[e][(k + 1) % seg]
			if e == 0:
				for v in [centre, b, a]:
					st.add_vertex(v)
			else:
				for v in [centre, a, b]:
					st.add_vertex(v)
	st.index()
	st.generate_normals()
	return st.commit()

## A thin tube running along X (wing arms): from x0 to x1, z going z0 to z1.
func _loft_x(x0: float, x1: float, z0: float, z1: float, r: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 8
	var n := 6
	var rings := []
	for i in n + 1:
		var u := float(i) / n
		var c := Vector3(lerpf(x0, x1, u), 0.0, lerpf(z0, z1, u))
		var rr := r * (1.0 - 0.6 * u)
		var ring := []
		for k in seg:
			var a := TAU * k / seg
			ring.append(c + Vector3(0, sin(a) * rr, cos(a) * rr))
		rings.append(ring)
	for i in n:
		for k in seg:
			var a: Vector3 = rings[i][k]
			var b: Vector3 = rings[i][(k + 1) % seg]
			var c: Vector3 = rings[i + 1][k]
			var d: Vector3 = rings[i + 1][(k + 1) % seg]
			for v in [a, b, c, b, d, c]:
				st.add_vertex(v)
	st.index()
	st.generate_normals()
	return st.commit()

## A flat plate (the wing membrane) from a polygon, with a little thickness.
func _plate(pts: Array, thick: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [1.0, -1.0]:
		var off := Vector3(0, thick * 0.5 * side, 0)
		for i in range(1, pts.size() - 1):
			var a: Vector3 = pts[0] + off
			var b: Vector3 = pts[i] + off
			var c: Vector3 = pts[i + 1] + off
			for v in ([a, b, c] if side > 0 else [a, c, b]):
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()

## A triangle with thickness (the crest).
func _prism(tri: Array, thick: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var l := []
	var r := []
	for p in tri:
		l.append(p + Vector3(-thick, 0, 0))
		r.append(p + Vector3(thick, 0, 0))
	for v in [l[0], l[1], l[2], r[0], r[2], r[1]]:
		st.add_vertex(v)
	for i in 3:
		var j := (i + 1) % 3
		for v in [l[i], r[i], l[j], l[j], r[i], r[j]]:
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()

func _eyes() -> void:
	for side in [-1.0, 1.0]:
		var c := Vector3(0.11 * side, 0.29, 0.76)
		_ball(c, 0.095, Color(1, 1, 1), true)
		_ball(c + Vector3(0.05 * side, 0.005, 0.045), 0.056, Color(0.08, 0.06, 0.06), false)
		_ball(c + Vector3(0.08 * side, 0.04, 0.06), 0.018, Color(1, 1, 1), false, true)

func _ball(pos: Vector3, r: float, col: Color, outlined: bool, unshaded := false) -> void:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
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
	var mi := MeshInstance3D.new()
	mi.mesh = sm
	mi.position = pos
	add_child(mi)
