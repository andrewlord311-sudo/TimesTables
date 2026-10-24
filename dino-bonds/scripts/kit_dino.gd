extends Node3D
## A dinosaur built in code from a shape in species.gd: smooth lofted body,
## tail, neck and head, legs that walk, and the bits that make each species
## itself (sail, frill, horns, plates, club, crest...). Same toon look, outline
## and big cartoon eyes as the Quaternius ones (dino.gd), and the same calls:
## setup(), play("Idle"/"Walk"/"Run"/"Attack"/"Jump"), is_playing(), roar().
## Local space: +Z forward, +Y up, feet on y = 0.

const Species := preload("res://scripts/species.gd")
const VARIANT_SHIFT := [0.0, 0.33, 0.62, 0.15, 0.8]
const BONE := Color(0.93, 0.89, 0.78)

signal roared

var species := ""
var height := 2.0
var variant := 0
var sfx: Node
var spec := {}

var rig: Node3D                 # everything, scaled to `height`
var tail: Node3D
var neck: Node3D
var legs: Array = []            # [node, phase offset, rest rotation]
var arms: Array = []
var flippers: Array = []
var _mats: Array[StandardMaterial3D] = []
var _cols: Array[Color] = []
var _state := "Idle"
var _speed := 1.0
var _one_shot := 0.0            # seconds left of Attack / Jump
var _t := 0.0
var _scale := 1.0

# --- set up -------------------------------------------------------------------

func setup(p_species: String, p_height: float, p_variant := 0) -> void:
	species = p_species
	height = p_height
	variant = p_variant
	spec = Species.info(species)
	_t = randf() * 10.0
	rig = Node3D.new()
	add_child(rig)
	var col: Array = spec.get("col", ["#7fae5a", "#efe8c8", "#4b6b30"])
	var main := _shift(Color(col[0]))
	var belly := Color(col[1])
	var accent := _shift(Color(col[2]))
	var m_main := _toon(main)
	var m_belly := _toon(belly)
	var m_acc := _toon(accent)
	_build(m_main, m_belly, m_acc)
	# Scale so the top of the dinosaur is at `height`.
	var top := 0.01
	for mi in rig.find_children("*", "MeshInstance3D", true, false):
		var aabb: AABB = (mi as MeshInstance3D).get_aabb()
		var xf: Transform3D = rig.global_transform.affine_inverse() * (mi as MeshInstance3D).global_transform if is_inside_tree() else _rel(mi)
		for k in 8:
			top = maxf(top, (xf * aabb.get_endpoint(k)).y)
	_scale = height / top
	rig.scale = Vector3.ONE * _scale
	for m in _mats:
		if m.next_pass:
			(m.next_pass as StandardMaterial3D).grow_amount = 0.022 / _scale
	play("Idle")

## Transform of a node relative to the rig, without needing the scene tree.
func _rel(n: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var p := n
	while p and p != rig:
		xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf

func _shift(c: Color) -> Color:
	if variant > 0 and c.s > 0.2:
		c.h = fmod(c.h + VARIANT_SHIFT[variant % VARIANT_SHIFT.size()], 1.0)
	return c

func play(name: String, speed := 1.0) -> void:
	if name == "Attack" or name == "Jump":
		_one_shot = 1.0 if name == "Attack" else 0.7
	_state = name
	_speed = speed

func is_playing(name: String) -> bool:
	if name == "Attack" or name == "Jump":
		return _state == name and _one_shot > 0.0
	return _state == name

func roar(pitch := 1.0) -> void:
	play("Attack")
	if sfx:
		var big := clampf(height / 3.0, 0.4, 2.0)
		sfx.play("roar", pitch / sqrt(big))
	roared.emit()

func set_fossil(on: bool, seconds := 0.0) -> void:
	for i in _mats.size():
		var want: Color = BONE if on else _cols[i]
		if seconds <= 0.0:
			_mats[i].albedo_color = want
		else:
			create_tween().tween_property(_mats[i], "albedo_color", want, seconds)

# --- moving -------------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	var moving := _state == "Walk" or _state == "Run"
	var swim: bool = spec.get("pose", "") == "swim"
	var freq := (9.0 if _state == "Run" else 5.0) * _speed
	var amp := 0.55 if _state == "Run" else 0.35
	var ph := _t * freq
	if _one_shot > 0.0:
		_one_shot -= delta
		if _one_shot <= 0.0:
			_state = "Idle"
	for l in legs:
		var n: Node3D = l[0]
		n.rotation.x = (sin(ph + l[1]) * amp) if moving else lerpf(n.rotation.x, 0.0, delta * 6.0)
	for a in arms:
		(a as Node3D).rotation.x = sin(_t * 1.6) * 0.08 + (sin(ph) * 0.2 if moving else 0.0)
	for f in flippers:
		var side: float = f[1]
		(f[0] as Node3D).rotation.z = side * sin(_t * 3.0 * maxf(_speed, 0.6) + f[2]) * 0.35
	if tail:
		tail.rotation.y = sin(_t * (6.0 if swim else 1.4) * (1.6 if moving else 1.0)) * (0.28 if swim else 0.1)
	# body bob while walking; gentle breathing otherwise
	var bob := absf(sin(ph)) * 0.04 if moving else sin(_t * 2.0) * 0.008
	var y := bob
	if _state == "Jump":
		var u := 1.0 - _one_shot / 0.7
		y += sin(clampf(u, 0.0, 1.0) * PI) * 0.5
	rig.position.y = y * _scale
	if neck:
		var nod := sin(_t * 1.1) * 0.05
		if _state == "Attack":
			var u := 1.0 - _one_shot
			nod = -0.35 * sin(clampf(u * 2.0, 0.0, 1.0) * PI * 0.5) + 0.45 * maxf(0.0, sin((u - 0.35) * PI * 1.6))
		elif moving:
			nod = sin(ph * 2.0) * 0.04
		neck.rotation.x = lerpf(neck.rotation.x, nod, minf(1.0, delta * 10.0))

# --- building -----------------------------------------------------------------

func _build(m_main: Material, m_belly: Material, m_acc: Material) -> void:
	var pose: String = spec.get("pose", "biped")
	var hip: float = spec.get("hip", 1.0)
	var body: Array = spec.get("body", [1.2, 0.6, 0.5])
	var L: float = body[0]
	var H: float = body[1]
	var W: float = body[2]
	var shoulder: float = spec.get("shoulder", hip + H * 0.25) if pose == "quad" else hip + H * 0.22
	if pose == "swim":
		hip = H * 0.5
		shoulder = H * 0.5
	var zr := -L * 0.5
	var zf := L * 0.5
	# Torso: a fat loft from tail root to chest.
	var prof := [0.55, 0.85, 1.0, 1.0, 0.95, 0.82, 0.62]
	var st := []
	for i in prof.size():
		var u := float(i) / (prof.size() - 1)
		var cy := lerpf(hip, shoulder, u) + sin(u * PI) * H * 0.08
		st.append([Vector3(0, cy, lerpf(zr, zf, u)), W * 0.5 * prof[i], H * 0.5 * prof[i]])
	rig.add_child(_mi(_loft(st), m_main))
	# Pale belly peeking out underneath.
	rig.add_child(_ball(Vector3(0, (hip + shoulder) * 0.5 - H * 0.28, 0), Vector3(W * 0.36, H * 0.28, L * 0.36), m_belly))
	# Tail.
	var tl: Array = spec.get("tail", [1.4, 0.2, 0.1])
	tail = Node3D.new()
	tail.position = Vector3(0, hip + H * 0.05, zr + L * 0.08)
	rig.add_child(tail)
	var ts := []
	for i in 9:
		var u := i / 8.0
		var r := float(tl[1]) * (1.0 - u * 0.9) + 0.012
		ts.append([Vector3(0, -float(tl[2]) * u * u + (H * 0.06 * u if pose != "swim" else 0.0), -float(tl[0]) * u), r * (1.0 if pose != "swim" else 0.8), r * (1.0 if pose != "swim" else 1.15)])
	tail.add_child(_mi(_loft(ts), m_main))
	# Neck and head as one smooth loft.
	var nk: Array = spec.get("neck", [0.5, 35, 0.2])
	var hd: Array = spec.get("head", [0.6, 0.3, 0.26])
	neck = Node3D.new()
	neck.position = Vector3(0, shoulder, zf - L * 0.12)
	rig.add_child(neck)
	var a := deg_to_rad(float(nk[1]))
	var dir := Vector3(0, sin(a), cos(a))
	var ns := []
	var nr: float = nk[2]
	for i in 5:
		var u := i / 4.0
		ns.append([dir * float(nk[0]) * u, nr * lerpf(1.35, 1.0, u), nr * lerpf(1.45, 1.0, u)])
	var h0: Vector3 = dir * float(nk[0])
	var hdir := Vector3(0, sin(a * 0.15) - 0.12, 1.0).normalized()
	var hup := hdir.cross(Vector3(1, 0, 0))
	var hl: float = float(hd[0]) * 1.15
	var hh: float = float(hd[1]) * 1.25
	var hw: float = float(hd[2]) * 1.25
	var snout: String = spec.get("snout", "rex")
	var shape := {
		"rex": [[0.95, 0.95], [1.0, 1.0], [0.95, 0.95], [0.8, 0.82], [0.62, 0.66], [0.45, 0.5]],
		"croc": [[0.9, 0.95], [1.0, 1.0], [0.6, 0.62], [0.36, 0.36], [0.3, 0.3], [0.32, 0.3], [0.24, 0.22]],
		"beak": [[0.9, 0.95], [1.0, 1.0], [0.88, 0.85], [0.62, 0.6], [0.36, 0.34], [0.1, 0.1]],
		"duck": [[0.9, 0.95], [1.0, 1.0], [0.82, 0.78], [0.66, 0.5], [0.7, 0.38], [0.6, 0.28]],
		"small": [[0.9, 0.95], [1.0, 1.0], [0.92, 0.9], [0.72, 0.7], [0.45, 0.45]],
	}
	var sh: Array = shape.get(snout, shape["rex"])
	for i in sh.size():
		var u := float(i) / (sh.size() - 1)
		var droop := -hh * 0.12 * u * u
		ns.append([h0 + hdir * (0.15 * hl + hl * u * 0.95) + hup * droop, hw * 0.5 * float(sh[i][0]), hh * 0.5 * float(sh[i][1])])
	neck.add_child(_mi(_loft(ns), m_main))
	# Pale throat.
	var nup := dir.cross(Vector3(1, 0, 0))
	var throat := _ball(Vector3.ZERO, Vector3.ONE, m_belly)
	throat.transform = Transform3D(Basis(Vector3(nr * 0.9, 0, 0), nup * nr * 0.8, dir * (float(nk[0]) * 0.5 + nr)), h0 * 0.5 - nup * nr * 0.35)
	neck.add_child(throat)
	var head := {"o": h0 + hdir * 0.15 * hl, "f": hdir, "u": hup, "l": hl, "h": hh, "w": hw}
	_eyes(head)
	_mouth(head, snout)
	# Legs.
	var lg: Array = spec.get("legs", [0.18, 0.16])
	if pose == "biped":
		for side in [-1.0, 1.0]:
			_leg(Vector3(side * W * 0.32, hip, zr + L * 0.32), hip, float(lg[0]), true, 0.0 if side < 0 else PI, m_main, m_belly)
		var ar: Array = spec.get("arms", [0.4, 0.07])
		for side in [-1.0, 1.0]:
			_arm(Vector3(side * W * 0.38, shoulder - H * 0.2, zf - L * 0.08), float(ar[0]), float(ar[1]), m_main, m_acc, side)
	elif pose == "quad":
		for side in [-1.0, 1.0]:
			_leg(Vector3(side * W * 0.34, hip, zr + L * 0.22), hip, float(lg[0]), false, 0.0 if side < 0 else PI, m_main, m_belly)
			_leg(Vector3(side * W * 0.34, shoulder - H * 0.05, zf - L * 0.2), shoulder - H * 0.05, float(lg[1]), false, PI if side < 0 else 0.0, m_main, m_belly)
	_features(spec.get("feat", []), head, st, {"hip": hip, "shoulder": shoulder, "L": L, "H": H, "W": W, "zr": zr, "zf": zf, "tail": tl}, m_main, m_belly, m_acc)

func _leg(at: Vector3, length: float, r: float, bent: bool, phase: float, mat: Material, foot_mat: Material) -> void:
	var n := Node3D.new()
	n.position = at
	rig.add_child(n)
	var pts := []
	if bent:
		pts = [[Vector3(0, 0.05, 0), r * 1.9, r * 2.1], [Vector3(0, -length * 0.42, length * 0.16), r * 1.15, r * 1.15],
			[Vector3(0, -length * 0.8, -length * 0.06), r * 0.75, r * 0.75], [Vector3(0, -length + r * 0.5, length * 0.04), r * 0.7, r * 0.6]]
	else:
		pts = [[Vector3(0, 0.05, 0), r * 1.7, r * 1.9], [Vector3(0, -length * 0.5, 0.02), r * 1.1, r * 1.1], [Vector3(0, -length + r * 0.4, 0), r * 1.05, r * 1.0]]
	n.add_child(_mi(_loft(pts), mat))
	var foot := _ball(Vector3(0, -length + r * 0.45, r * (1.1 if bent else 0.3)), Vector3(r * (1.2 if bent else 1.25), r * 0.5, r * (2.0 if bent else 1.25)), mat)
	n.add_child(foot)
	legs.append([n, phase])

func _arm(at: Vector3, length: float, r: float, mat: Material, acc: Material, side: float) -> void:
	var n := Node3D.new()
	n.position = at
	rig.add_child(n)
	n.add_child(_mi(_loft([[Vector3.ZERO, r * 1.3, r * 1.4], [Vector3(side * r, -length * 0.45, length * 0.2), r, r],
		[Vector3(side * r * 0.5, -length * 0.75, length * 0.55), r * 0.75, r * 0.75]]), mat))
	n.add_child(_ball(Vector3(side * r * 0.5, -length * 0.78, length * 0.6), Vector3.ONE * r * 0.9, mat))
	n.set_meta("hand", Vector3(side * r * 0.5, -length * 0.78, length * 0.6))
	n.set_meta("len", length)
	arms.append(n)

func _eyes(hd: Dictionary) -> void:
	var r := clampf(float(hd["h"]) * 0.24, 0.05, 0.14)
	var white := _plain(Color(1, 1, 1), true, r)
	var black := _plain(Color(0.08, 0.06, 0.06), false, 0)
	var shine := _plain(Color(1, 1, 1), false, 0, true)
	for side in [-1.0, 1.0]:
		var c: Vector3 = hd["o"] + hd["f"] * float(hd["l"]) * 0.22 + hd["u"] * float(hd["h"]) * 0.26 + Vector3(side, 0, 0) * float(hd["w"]) * 0.4
		var out := Vector3(side, 0, 0)
		neck.add_child(_ball(c, Vector3.ONE * r, white))
		neck.add_child(_ball(c + (out * 0.62 + hd["f"] * 0.5 + hd["u"] * 0.1).normalized() * r * 0.6, Vector3.ONE * r * 0.58, black))
		neck.add_child(_ball(c + (out * 0.7 + hd["f"] * 0.4 + hd["u"] * 0.5).normalized() * r, Vector3.ONE * r * 0.18, shine))

## A friendly smile line and nostrils.
func _mouth(hd: Dictionary, snout: String) -> void:
	var dark := _plain(Color(0.15, 0.1, 0.09), false, 0)
	var tipu := 0.95 if snout != "croc" else 1.0
	for side in [-1.0, 1.0]:
		var nose: Vector3 = hd["o"] + hd["f"] * float(hd["l"]) * tipu * 0.95 + hd["u"] * float(hd["h"]) * 0.12 + Vector3(side * float(hd["w"]) * 0.1, 0, 0)
		neck.add_child(_ball(nose, Vector3.ONE * float(hd["h"]) * 0.04, dark))

# --- the bits that make each species itself -------------------------------------

func _features(feat: Array, hd: Dictionary, torso: Array, b: Dictionary, m_main: Material, m_belly: Material, m_acc: Material) -> void:
	var L: float = b["L"]
	var H: float = b["H"]
	var W: float = b["W"]
	var tl: Array = b["tail"]
	var tlen: float = tl[0]
	var o: Vector3 = hd["o"]
	var f: Vector3 = hd["f"]
	var u: Vector3 = hd["u"]
	var hl: float = hd["l"]
	var hh: float = hd["h"]
	var hw: float = hd["w"]
	for name in feat:
		match name:
			"armour":
				for i in 7:
					var z := lerpf(b["zr"] + L * 0.1, b["zf"] - L * 0.1, i / 6.0)
					for ang in [-0.9, -0.45, 0.0, 0.45, 0.9]:
						var p := _torso_surface(torso, z, ang)
						rig.add_child(_cone(p, Vector3(sin(ang), cos(ang), 0), H * 0.11, H * 0.09, m_acc))
				for side in [-1.0, 1.0]:
					for i in 5:
						var z := lerpf(b["zr"] + L * 0.05, b["zf"] - L * 0.05, i / 4.0)
						rig.add_child(_cone(_torso_surface(torso, z, side * 1.45), Vector3(side, -0.2, 0), H * 0.18, H * 0.07, m_belly))
			"club":
				var tip := Vector3(0, -float(tl[2]), -tlen * 0.97)
				tail.add_child(_ball(tip + Vector3(0.09, 0, 0), Vector3(0.15, 0.11, 0.17), m_acc))
				tail.add_child(_ball(tip - Vector3(0.09, 0, 0), Vector3(0.15, 0.11, 0.17), m_acc))
			"cheek_horns":
				for side in [-1.0, 1.0]:
					neck.add_child(_cone(o + Vector3(side * hw * 0.45, 0, 0) - u * hh * 0.1, Vector3(side, 0.3, -0.5).normalized(), hh * 0.35, hh * 0.12, m_belly))
			"nose_bump":
				neck.add_child(_ball(o + f * hl * 0.3 + u * hh * 0.42, Vector3(hw * 0.32, hh * 0.32, hl * 0.25), m_main))
			"back_bumps":
				for i in 8:
					rig.add_child(_ball(_torso_surface(torso, lerpf(b["zr"], b["zf"], i / 7.0), 0.0), Vector3.ONE * H * 0.06, m_acc))
				for i in 8:
					tail.add_child(_ball(Vector3(0, float(tl[1]) * (1.0 - i / 9.0) - float(tl[2]) * pow(i / 9.0, 2), -tlen * i / 9.0), Vector3.ONE * float(tl[1]) * 0.25, m_acc))
			"sail":
				var pts := []
				for i in 9:
					var t := i / 8.0
					var z := lerpf(b["zr"] - L * 0.05, b["zf"] - L * 0.05, t)
					var top := _torso_surface(torso, z, 0.0)
					pts.append(Vector2(z, top.y + H * 0.9 * sin(t * PI) * (0.75 + 0.25 * sin(t * PI * 2.0 + 0.6))))
				var base := []
				for i in 9:
					var z := lerpf(b["zf"] - L * 0.05, b["zr"] - L * 0.05, i / 8.0)
					base.append(Vector2(z, _torso_surface(torso, z, 0.0).y - H * 0.15))
				rig.add_child(_mi(_fin(pts + base, 0.03), m_acc))
			"dome":
				neck.add_child(_ball(o + u * hh * 0.35 - f * hl * 0.05, Vector3(hw * 0.58, hh * 0.55, hl * 0.42), m_acc))
				for k in 5:
					var ang := -1.2 + k * 0.6
					neck.add_child(_cone(o + u * hh * 0.2 - f * hl * 0.25 + Vector3(sin(ang) * hw * 0.45, 0, 0), (-f + Vector3(sin(ang), 0.2, 0)).normalized(), hh * 0.18, hh * 0.06, m_belly))
			"crest_double":
				for side in [-1.0, 1.0]:
					var base: Vector3 = o + Vector3(side * hw * 0.16, 0, 0) + u * hh * 0.4
					var pts := [Vector2(0, 0), Vector2(hl * 0.25, hh * 0.65), Vector2(hl * 0.55, hh * 0.75), Vector2(hl * 0.85, 0.05), Vector2(hl * 0.4, -0.02)]
					var crest := _mi(_fin(pts, 0.015), m_acc)
					crest.transform = Transform3D(Basis(Vector3(1, 0, 0), u, f), base)
					neck.add_child(crest)
			"crest_fan":
				var pts := []
				for i in 9:
					var t := i / 8.0 * PI
					pts.append(Vector2(-cos(t) * hl * 0.45, sin(t) * hh * 1.15))
				var crest := _mi(_fin(pts, 0.03), m_acc)
				crest.transform = Transform3D(Basis(Vector3(1, 0, 0), u, f), o + f * hl * 0.25 + u * hh * 0.3)
				neck.add_child(crest)
			"small_crest":
				var crest := _mi(_fin([Vector2(0, 0), Vector2(hl * 0.2, hh * 0.25), Vector2(hl * 0.35, 0)], 0.015), m_acc)
				crest.transform = Transform3D(Basis(Vector3(1, 0, 0), u, f), o + f * hl * 0.35 + u * hh * 0.25)
				neck.add_child(crest)
			"brow_horns":
				for side in [-1.0, 1.0]:
					neck.add_child(_cone(o + f * hl * 0.25 + u * hh * 0.45 + Vector3(side * hw * 0.25, 0, 0), (u + f * 0.2).normalized(), hh * 0.3, hh * 0.1, m_acc))
			"bull_horns":
				for side in [-1.0, 1.0]:
					neck.add_child(_cone(o + f * hl * 0.15 + u * hh * 0.4 + Vector3(side * hw * 0.3, 0, 0), (Vector3(side, 0, 0) + u * 0.8).normalized(), hh * 0.45, hh * 0.13, m_belly))
			"nose_horn":
				neck.add_child(_cone(o + f * hl * 0.7 + u * hh * 0.3, (u + f * 0.35).normalized(), hh * 0.75, hh * 0.15, m_belly))
			"frill":
				var fr := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = hh * 1.05
				cm.bottom_radius = hh * 1.05
				cm.height = 0.05
				cm.radial_segments = 20
				fr.mesh = cm
				fr.material_override = m_acc
				# a disc behind the head, facing forward and leaning back
				fr.transform = Transform3D(Basis(Vector3(1, 0, 0), u, f), o - f * hl * 0.05 + u * hh * 0.45) * Transform3D(Basis(Vector3(1, 0, 0), 1.04), Vector3.ZERO)
				fr.scale = Vector3(1.15, 1, 0.9)
				neck.add_child(fr)
				neck.set_meta("frill", fr)
			"frill_spikes":
				for k in 7:
					var ang := -1.35 + k * 0.45
					var dirv := (Vector3(sin(ang), 0, 0) + u * cos(ang) * 0.9 - f * cos(ang) * 0.55).normalized()
					var at: Vector3 = o - f * hl * 0.05 + u * hh * 0.45 + dirv * hh * 1.0
					neck.add_child(_cone(at, dirv, hh * (0.75 if absf(ang) < 0.5 else 0.5), hh * 0.12, m_belly))
			"plates_small":
				for i in 6:
					var z := lerpf(b["zf"] - L * 0.1, b["zr"] + L * 0.05, i / 5.0)
					var p := _torso_surface(torso, z, 0.0)
					var s := H * (0.35 + 0.15 * sin(i / 5.0 * PI))
					rig.add_child(_mi(_fin([Vector2(z - s * 0.4, p.y - 0.03), Vector2(z, p.y + s), Vector2(z + s * 0.4, p.y - 0.03)], 0.025), m_acc))
			"back_spikes":
				for side in [-1.0, 1.0]:
					for i in 3:
						var z := lerpf(b["zr"] + L * 0.15, b["zr"] - L * 0.05, i / 2.0)
						rig.add_child(_cone(_torso_surface(torso, z, side * 0.35), Vector3(side * 0.4, 1, -0.2).normalized(), H * 0.45, H * 0.07, m_acc))
			"tail_spikes":
				for side in [-1.0, 1.0]:
					for i in 3:
						var t := 0.45 + i * 0.2
						var p := Vector3(side * float(tl[1]) * (1.0 - t * 0.9) * 0.6, float(tl[1]) * (1.0 - t * 0.9) * 0.6 - float(tl[2]) * t * t + H * 0.06 * t, -tlen * t)
						tail.add_child(_cone(p, Vector3(side, 0.7, -0.3).normalized(), H * 0.4, H * 0.06, m_acc))
			"shoulder_spikes":
				for side in [-1.0, 1.0]:
					rig.add_child(_cone(_torso_surface(torso, b["zf"] - L * 0.2, side * 1.2), Vector3(side, 0.1, -0.3).normalized(), H * 0.55, H * 0.08, m_acc))
			"thumb_spike":
				for a in arms:
					var hand: Vector3 = a.get_meta("hand")
					a.add_child(_cone(hand, Vector3(0, 0.6, 1).normalized(), float(a.get_meta("len")) * 0.35, 0.03, m_belly))
			"long_claws":
				for a in arms:
					var hand: Vector3 = a.get_meta("hand")
					for k in 3:
						a.add_child(_cone(hand + Vector3((k - 1) * 0.04, 0, 0), Vector3((k - 1) * 0.15, -0.55, 1).normalized(), float(a.get_meta("len")) * 0.7, 0.03, m_belly))
			"feathers":
				for a in arms:
					var hand: Vector3 = a.get_meta("hand")
					for k in 4:
						a.add_child(_cone(hand * (0.4 + k * 0.17) + Vector3(0, 0, -0.03), Vector3(0, -0.4, -1).normalized(), 0.14, 0.04, m_acc))
				var tipz := -tlen
				for k in 6:
					var ang := k * TAU / 6.0
					tail.add_child(_cone(Vector3(0, -float(tl[2]) * 0.9, tipz * 0.85), Vector3(cos(ang) * 0.5, sin(ang) * 0.5, -1).normalized(), 0.22, 0.05, m_acc))
			"stripes", "bumps":
				for i in 5:
					var z := lerpf(b["zr"], b["zf"] - L * 0.15, i / 4.0)
					var p := _torso_surface(torso, z, 0.0)
					var sz := Vector3(W * 0.42, H * 0.06, L * 0.035) if name == "stripes" else Vector3.ONE * H * 0.07
					rig.add_child(_ball(p - Vector3(0, H * 0.02, 0), sz, m_acc))
					if name == "bumps":
						for side in [-1.0, 1.0]:
							rig.add_child(_ball(_torso_surface(torso, z, side * 0.5), Vector3.ONE * H * 0.05, m_acc))
			"flippers":
				for fz in [b["zf"] - L * 0.2, b["zr"] + L * 0.2]:
					for side in [-1.0, 1.0]:
						var n := Node3D.new()
						n.position = _torso_surface(torso, fz, side * 1.7)
						rig.add_child(n)
						var big := 1.0 if fz > 0 else 0.75
						n.add_child(_ball(Vector3(side * 0.38 * big, -0.05, -0.08), Vector3(0.42 * big, 0.06, 0.2 * big), m_main))
						flippers.append([n, side, fz])
			"tail_fin":
				var tip := Vector3(0, 0, -tlen * 0.95)
				var fin := _mi(_fin([Vector2(0, 0), Vector2(-0.5, 0.6), Vector2(-0.25, 0.0), Vector2(-0.5, -0.45)], 0.03), m_main)
				fin.transform = Transform3D(Basis(), tip)
				tail.add_child(fin)

## A point on the torso's surface at z, `ang` radians round from the top.
func _torso_surface(torso: Array, z: float, ang: float) -> Vector3:
	var best = torso[0]
	var nxt = torso[0]
	for i in torso.size() - 1:
		if z >= (torso[i][0] as Vector3).z and z <= (torso[i + 1][0] as Vector3).z:
			best = torso[i]
			nxt = torso[i + 1]
	var z0: float = (best[0] as Vector3).z
	var z1: float = (nxt[0] as Vector3).z
	var u := 0.0 if z1 == z0 else (z - z0) / (z1 - z0)
	var c: Vector3 = (best[0] as Vector3).lerp(nxt[0], u)
	var rx: float = lerpf(best[1], nxt[1], u)
	var ry: float = lerpf(best[2], nxt[2], u)
	return Vector3(c.x + sin(ang) * rx, c.y + cos(ang) * ry, z)

# --- meshes -------------------------------------------------------------------

func _toon(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.roughness = 0.55
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.6
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var o := StandardMaterial3D.new()
	o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	o.cull_mode = BaseMaterial3D.CULL_FRONT
	o.albedo_color = col.darkened(0.72)
	o.grow = true
	o.grow_amount = 0.02
	m.next_pass = o
	_mats.append(m)
	_cols.append(col)
	return m

func _plain(col: Color, outlined: bool, r: float, unshaded := false) -> StandardMaterial3D:
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
	return m

func _mi(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	return mi

static var _sphere: SphereMesh
func _ball(pos: Vector3, radii: Vector3, mat: Material) -> MeshInstance3D:
	if _sphere == null:
		_sphere = SphereMesh.new()
		_sphere.radius = 1.0
		_sphere.height = 2.0
		_sphere.radial_segments = 16
		_sphere.rings = 10
	var mi := _mi(_sphere, mat)
	mi.position = pos
	mi.scale = radii
	return mi

## A cone standing at `at`, pointing along `dir`.
static var _cones := {}
func _cone(at: Vector3, dir: Vector3, length: float, r: float, mat: Material) -> MeshInstance3D:
	if not _cones.has("c"):
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 1.0
		cm.height = 1.0
		cm.radial_segments = 8
		cm.rings = 1
		_cones["c"] = cm
	var mi := _mi(_cones["c"], mat)
	var y := dir.normalized()
	var x := y.cross(Vector3(0, 0, 1) if absf(y.z) < 0.9 else Vector3(1, 0, 0)).normalized()
	var z := x.cross(y)
	mi.transform = Transform3D(Basis(x * r, y * length, z * r), at + y * length * 0.5)
	return mi

## A smooth tube through rings at the given centres, each ring square to the
## path: stations are [centre, half-width, half-height].
func _loft(raw: Array, seg := 18) -> ArrayMesh:
	var stations := _smooth_path(raw, 4)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var rings := []
	var n := stations.size()
	for i in n:
		var c: Vector3 = stations[i][0]
		var t: Vector3 = ((stations[mini(i + 1, n - 1)][0] as Vector3) - (stations[maxi(i - 1, 0)][0] as Vector3)).normalized()
		var side := (Vector3(1, 0, 0) - t * t.x).normalized()
		var up := t.cross(side)
		var ring := []
		for k in seg:
			var a := TAU * k / seg
			ring.append(c + side * cos(a) * float(stations[i][1]) + up * sin(a) * float(stations[i][2]))
		rings.append(ring)
	for i in n - 1:
		for k in seg:
			var a: Vector3 = rings[i][k]
			var b: Vector3 = rings[i][(k + 1) % seg]
			var c: Vector3 = rings[i + 1][k]
			var d: Vector3 = rings[i + 1][(k + 1) % seg]
			for v in [a, c, b, b, c, d]:
				st.add_vertex(v)
	for e in [0, n - 1]:
		var centre := Vector3.ZERO
		for v in rings[e]:
			centre += v
		centre /= seg
		for k in seg:
			var a: Vector3 = rings[e][k]
			var b: Vector3 = rings[e][(k + 1) % seg]
			if e == 0:
				for v in [centre, a, b]:
					st.add_vertex(v)
			else:
				for v in [centre, b, a]:
					st.add_vertex(v)
	st.index()
	st.generate_normals()
	return st.commit()

## Catmull-Rom through the stations (centres and radii), `k` steps per span,
## so a handful of stations makes a smooth, rounded tube.
func _smooth_path(raw: Array, k: int) -> Array:
	if raw.size() < 3:
		return raw
	var out := []
	var n := raw.size()
	for i in n - 1:
		var p0: Array = raw[maxi(i - 1, 0)]
		var p1: Array = raw[i]
		var p2: Array = raw[i + 1]
		var p3: Array = raw[mini(i + 2, n - 1)]
		for j in k:
			var t := float(j) / k
			var row := []
			for c in 3:
				row.append(_cr(p0[c], p1[c], p2[c], p3[c], t))
			out.append(row)
	out.append(raw[n - 1])
	return out

func _cr(a, b, c, d, t: float):
	var t2 := t * t
	var t3 := t2 * t
	return (b * 2.0 + (c - a) * t + (a * 2.0 - b * 5.0 + c * 4.0 - d) * t2 + (b * 3.0 - a - c * 3.0 + d) * t3) * 0.5

## A flat shape in the YZ plane (points are (z, y)), with thickness along X.
func _fin(pts: Array, thick: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= pts.size()
	var n := pts.size()
	for side in [1.0, -1.0]:
		var x: float = thick * 0.5 * side
		for i in n:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % n]
			var tri := [Vector3(x, c.y, c.x), Vector3(x, a.y, a.x), Vector3(x, b.y, b.x)]
			if side < 0:
				tri = [tri[0], tri[2], tri[1]]
			for v in tri:
				st.add_vertex(v)
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var q := [Vector3(thick * 0.5, a.y, a.x), Vector3(-thick * 0.5, a.y, a.x), Vector3(thick * 0.5, b.y, b.x), Vector3(-thick * 0.5, b.y, b.x)]
		for v in [q[0], q[1], q[2], q[2], q[1], q[3]]:
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()
