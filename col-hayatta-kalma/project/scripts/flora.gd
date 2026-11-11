## Procedural desert plants (palm, saguaro, prickly pear) built from code so they need no
## external model files. Bark uses the Poly Haven bark texture (CC0). Meshes are registered in
## the Models cache as "proc/<name>" so MultiMesh placement works like any other model.
class_name Flora
extends RefCounted

static var _bark: StandardMaterial3D
static var _leaf: StandardMaterial3D
static var _plant: StandardMaterial3D

static func register() -> void:
	if Models._meshes.has("proc/palm_a"):
		return
	_bark = StandardMaterial3D.new()
	_bark.albedo_texture = load("res://assets/pbr/bark/albedo.jpg")
	_bark.normal_enabled = true
	_bark.normal_texture = load("res://assets/pbr/bark/normal.jpg")
	_bark.albedo_color = Color(1.05, 0.92, 0.78)
	_bark.roughness = 0.95
	_leaf = StandardMaterial3D.new()
	_leaf.vertex_color_use_as_albedo = true
	_leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
	_leaf.roughness = 0.75
	_leaf.backlight_enabled = false
	_plant = StandardMaterial3D.new()
	_plant.vertex_color_use_as_albedo = true
	_plant.roughness = 0.68
	Models._meshes["proc/palm_a"] = palm(4.6, 0.35, 9, 11)
	Models._meshes["proc/palm_b"] = palm(4.0, 0.6, 8, 23)
	Models._meshes["proc/palm_c"] = palm(5.2, 0.2, 10, 37)
	Models._meshes["proc/saguaro_a"] = saguaro(2.3, 2, 5)
	Models._meshes["proc/saguaro_b"] = saguaro(1.7, 1, 9)
	Models._meshes["proc/pear"] = pear(13)

# ---------------------------------------------------------------- tube helper
## Sweeps a (optionally ribbed) circle along a path. cols: base colour, ridge colour.
static func _tube(st: SurfaceTool, path: Array, radii: Array, sides: int, ribs: int, rib_amp: float,
		base: Color, ridge: Color, v_scale: float, cap := true) -> void:
	var rings := []
	var vacc := 0.0
	for i in path.size():
		var p: Vector3 = path[i]
		var t: Vector3 = (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		var ref := Vector3.RIGHT if absf(t.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
		var b1 := t.cross(ref).normalized()
		var b2 := t.cross(b1).normalized()
		if i > 0:
			vacc += (path[i] - path[i - 1]).length()
		var ring := []
		for k in sides + 1:
			var a := TAU * k / sides
			var rib := cos(a * ribs) if ribs > 0 else 0.0
			var r: float = radii[i] * (1.0 + rib_amp * rib)
			var n := (b1 * cos(a) + b2 * sin(a))
			ring.append([p + n * r, n, Vector2(float(k) / sides, vacc * v_scale), base.lerp(ridge, clampf(rib, 0.0, 1.0))])
		rings.append(ring)
	for i in rings.size() - 1:
		for k in sides:
			var q := [rings[i][k], rings[i][k + 1], rings[i + 1][k + 1], rings[i + 1][k]]
			for idx in [0, 2, 1, 0, 3, 2]:
				var v: Array = q[idx]
				st.set_normal(v[1]); st.set_uv(v[2]); st.set_color(v[3]); st.add_vertex(v[0])
	if cap:
		var last: Array = rings[rings.size() - 1]
		var tip: Vector3 = path[path.size() - 1] + (path[path.size() - 1] - path[path.size() - 2]).normalized() * radii[radii.size() - 1] * 0.8
		for k in sides:
			for v in [last[k], [tip, (tip - path[path.size() - 1]).normalized(), Vector2(0.5, 1), base], last[k + 1]]:
				st.set_normal(v[1]); st.set_uv(v[2]); st.set_color(v[3]); st.add_vertex(v[0])

# ---------------------------------------------------------------- palm
static func palm(h: float, lean: float, fronds: int, sd: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new(); rng.seed = sd
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var path := []; var radii := []
	var seg := 16
	var dir := Vector2.from_angle(rng.randf() * TAU)
	for i in seg + 1:
		var t := float(i) / seg
		var off := dir * lean * t * t * h * 0.35
		path.append(Vector3(off.x, t * h, off.y))
		# rough ring bumps every segment, wider base
		radii.append(lerpf(0.26, 0.16, pow(t, 0.6)) * (1.0 + (0.08 if i % 2 == 0 else 0.0)))
	_tube(st, path, radii, 9, 0, 0.0, Color.WHITE, Color.WHITE, 1.4, false)
	st.generate_tangents()
	st.commit(mesh)
	mesh.surface_set_material(0, _bark)
	# crown
	var top: Vector3 = path[seg]
	var lf := SurfaceTool.new(); lf.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dark := Color(0.13, 0.27, 0.08); var light := Color(0.42, 0.55, 0.16); var dry := Color(0.55, 0.45, 0.2)
	for f in fronds:
		var a := TAU * f / fronds + rng.randf_range(-0.2, 0.2)
		var fd := Vector3(cos(a), 0, sin(a))
		var side := fd.cross(Vector3.UP).normalized()
		var length := rng.randf_range(2.3, 3.0)
		var lift := rng.randf_range(0.3, 0.9)
		var is_dry := rng.randf() < 0.18
		var n := 14
		var prev := top
		for i in n:
			var t0 := float(i) / n; var t1 := float(i + 1) / n
			var p0 := top + fd * length * t0 + Vector3.UP * (lift * t0 - 1.6 * t0 * t0) * length * 0.6
			var p1 := top + fd * length * t1 + Vector3.UP * (lift * t1 - 1.6 * t1 * t1) * length * 0.6
			var w := sin(PI * minf(t0 * 1.15 + 0.08, 1.0)) * 0.75
			var c0 := (dry if is_dry else light).lerp(dark, t0 * 0.5)
			# leaflets: drooping strips on both sides
			for sgn: float in [-1.0, 1.0]:
				var tipo := p0 + side * sgn * w + Vector3.DOWN * w * 0.45 + fd * 0.12
				var nrm := (side * sgn).cross(p1 - p0).normalized() * sgn
				if nrm.y < 0: nrm = -nrm
				for v in [[p0, c0], [p1, c0], [tipo, c0.darkened(0.15)]]:
					lf.set_normal(nrm); lf.set_color(v[1]); lf.add_vertex(v[0])
			prev = p1
	# a few hanging dry fronds under the crown
	for f in 4:
		var a := rng.randf() * TAU
		var fd := Vector3(cos(a), 0, sin(a))
		var side := fd.cross(Vector3.UP).normalized()
		var p0 := top + fd * 0.15
		var p1 := top + fd * 0.6 + Vector3.DOWN * 1.4
		var c := Color(0.45, 0.33, 0.16)
		for v in [p0 - side * 0.18, p0 + side * 0.18, p1]:
			lf.set_normal(fd); lf.set_color(c); lf.add_vertex(v)
	lf.commit(mesh)
	mesh.surface_set_material(1, _leaf)
	return mesh

# ---------------------------------------------------------------- saguaro
static func saguaro(h: float, arms: int, sd: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new(); rng.seed = sd
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := Color(0.2, 0.36, 0.17); var ridge := Color(0.42, 0.52, 0.3)
	var path := []; var radii := []
	for i in 13:
		var t := i / 12.0
		path.append(Vector3(0, t * h, 0))
		radii.append(0.2 * (1.0 - pow(t, 6.0) * 0.35))
	_tube(st, path, radii, 24, 12, 0.07, base, ridge, 1.0)
	for k in arms:
		var a := rng.randf() * TAU if k == 0 else a_prev(k, rng)
		var d := Vector3(cos(a), 0, sin(a))
		var y0 := h * rng.randf_range(0.35, 0.55)
		var ap := []; var ar := []
		for i in 9:
			var t := i / 8.0
			var out := minf(t * 2.2, 1.0) * 0.38
			var up := maxf(0.0, t - 0.3) * h * 0.55
			ap.append(Vector3(0, y0 + up + sin(minf(t * 2.2, 1.0) * PI / 2) * 0.15, 0) + d * (out + 0.0))
			ar.append(0.13 * (1.0 - pow(t, 5.0) * 0.3))
		_tube(st, ap, ar, 16, 10, 0.07, base, ridge, 1.0)
	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, _plant)
	return m

static func a_prev(k: int, rng: RandomNumberGenerator) -> float:
	return k * 2.6 + rng.randf_range(-0.4, 0.4)

# ---------------------------------------------------------------- prickly pear
static func _pad(st: SurfaceTool, xf: Transform3D, w: float, hh: float, col: Color) -> void:
	var sm := SphereMesh.new(); sm.radius = 0.5; sm.height = 1.0; sm.radial_segments = 10; sm.rings = 6
	var arr := sm.get_mesh_arrays()
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var sc := Vector3(w, hh, 0.09)
	for i in idx:
		var v := vs[i] * sc + Vector3(0, hh * 0.5, 0)
		var n := (ns[i] / sc).normalized()
		# areoles: pale specks on a grid
		var speck := fmod(absf(vs[i].x * 7.0 + vs[i].y * 9.0), 1.0) < 0.12
		st.set_normal(xf.basis * n)
		st.set_color(col.lightened(0.35) if speck else col)
		st.add_vertex(xf * v)

static func pear(sd: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new(); rng.seed = sd
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var col := Color(0.32, 0.46, 0.22)
	var pads := []
	for k in 3:
		var a := k * TAU / 3 + rng.randf_range(-0.3, 0.3)
		var xf := Transform3D(Basis(Vector3.UP, a).rotated(Vector3(cos(a), 0, -sin(a)), rng.randf_range(-0.25, 0.25)), Vector3(cos(a) * 0.12, 0, sin(a) * 0.12))
		pads.append([xf, 0.42, 0.55])
	var out := []
	for p in pads:
		out.append(p)
		var top: Transform3D = p[0] * Transform3D(Basis(), Vector3(0, p[2] * 0.9, 0))
		for j in 2:
			var tilt := rng.randf_range(-0.6, 0.6)
			var xf2 := top * Transform3D(Basis(Vector3.FORWARD, tilt).rotated(Vector3.UP, rng.randf_range(-0.5, 0.5)), Vector3.ZERO)
			out.append([xf2, 0.36, 0.46])
			if rng.randf() < 0.5:
				out.append([xf2 * Transform3D(Basis(Vector3.FORWARD, rng.randf_range(-0.5, 0.5)), Vector3(0, 0.4, 0)), 0.3, 0.38])
	for p in out:
		_pad(st, p[0], p[1], p[2], col.lerp(Color(0.38, 0.5, 0.3), rng.randf()))
	var m := st.commit()
	m.surface_set_material(0, _plant)
	return m
