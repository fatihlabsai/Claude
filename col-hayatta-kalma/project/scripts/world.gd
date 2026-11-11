## Builds and owns the 3D world: terrain, points of interest, resource nodes,
## decorations, placed objects. Also answers spatial queries (collision, shade,
## shelter, interactables).
class_name World
extends Node3D

const REG := 4                 # regions per side for MultiMesh culling
const GRID := 8.0              # spatial hash cell (m)

var g: WorldGen
var nodes: Array = []          # runtime node state: {t, p, ready_at, vis:[ [mmi, idx, xf], ...], fruit:[...]}
var obstacles := {}            # cell -> [[Vector2, r]]
var shades: Array = []         # [[Vector2, r]]
var shelters: Array = []       # [[Vector2, r, name]]
var inter: Array = []          # interactable POIs: {kind, p, r, label, ...}
var placed: Array = []         # placed objects {kind, p, node, ...}
var crates: Array = []         # post-storm crates
var wells_b: Array = []        # buckets per well
var opened := {}               # "ruin:2" -> true
var water_nodes: Array = []
var smoke: CPUParticles3D
var _mm := {}                  # key -> {mesh, xforms:[region][], mmi:[region]}
var _chunk_mat: ShaderMaterial
var stone_mat := StandardMaterial3D.new()
var dark_mat := StandardMaterial3D.new()

func build(gen: WorldGen) -> void:
	g = gen
	stone_mat.albedo_color = Color("#d8aa72"); stone_mat.roughness = 0.9
	dark_mat.albedo_color = Color("#2b1d14")
	_build_terrain()
	_build_water()
	_build_wreck()
	for i in g.ruins.size():
		_build_ruin(i)
	for i in g.wells.size():
		_build_well(i)
	for i in g.caves.size():
		_build_cave(i)
	_build_caravan()
	_build_obelisk()
	_build_nodes()
	_build_decor()
	_flush_mm()

# ---------------------------------------------------------------- terrain
func _biome_color(p: Vector2, h: float) -> Color:
	var b := g.biome(p)
	var n := g.n_det.get_noise_2dv(p * 0.7) * 0.5 + 0.5
	var sand := Color("#e6cba0").lerp(Color("#d9b386"), n)
	var c := sand
	var rf := g.rock_factor(p)
	c = c.lerp(Color("#c47a4a").lerp(Color("#a8623d"), n), smoothstep(0.35, 0.7, rf))
	c = c.lerp(Color("#f4ecdc").lerp(Color("#e6dccb"), n), smoothstep(0.4, 0.75, g.salt_factor(p)))
	var of := g.oasis_factor(p)
	c = c.lerp(Color("#9cbf5a").lerp(Color("#79a64a"), n), smoothstep(0.15, 0.6, of))
	if b == WorldGen.B.SCRUB:
		c = c.lerp(Color("#d8b06a"), 0.45)
	# darker dune troughs, lighter crests
	c = c.darkened(clampf(0.08 - h * 0.012, -0.06, 0.12))
	return c

func _build_terrain() -> void:
	var sh := load("res://shaders/sand.gdshader")
	_chunk_mat = ShaderMaterial.new()
	_chunk_mat.shader = sh
	var per := 30
	var chunks := int((WorldGen.N - 1) / per)
	var colors := PackedColorArray(); colors.resize(WorldGen.N * WorldGen.N)
	for j in WorldGen.N:
		for i in WorldGen.N:
			var p := Vector2(-WorldGen.HALF + i * WorldGen.CELL, -WorldGen.HALF + j * WorldGen.CELL)
			colors[j * WorldGen.N + i] = _biome_color(p, g.heights[j * WorldGen.N + i])
	for cj in chunks:
		for ci in chunks:
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for j in per + 1:
				for i in per + 1:
					var gi := ci * per + i; var gj := cj * per + j
					var x := -WorldGen.HALF + gi * WorldGen.CELL
					var z := -WorldGen.HALF + gj * WorldGen.CELL
					var hl := g.heights[gj * WorldGen.N + maxi(gi - 1, 0)]
					var hr := g.heights[gj * WorldGen.N + mini(gi + 1, WorldGen.N - 1)]
					var hd := g.heights[maxi(gj - 1, 0) * WorldGen.N + gi]
					var hu := g.heights[mini(gj + 1, WorldGen.N - 1) * WorldGen.N + gi]
					st.set_normal(Vector3(hl - hr, 2.0 * WorldGen.CELL, hd - hu).normalized())
					st.set_color(colors[gj * WorldGen.N + gi])
					st.add_vertex(Vector3(x, g.heights[gj * WorldGen.N + gi], z))
			for j in per:
				for i in per:
					var a := j * (per + 1) + i
					st.add_index(a); st.add_index(a + 1); st.add_index(a + per + 1)
					st.add_index(a + 1); st.add_index(a + per + 2); st.add_index(a + per + 1)
			var mi := MeshInstance3D.new()
			mi.mesh = st.commit()
			mi.material_override = _chunk_mat
			add_child(mi)
	# a huge flat sand skirt beyond the map edge so the horizon is never empty
	var skirt := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(2400, 2400)
	skirt.mesh = pm
	skirt.position.y = 0.6
	var sm := StandardMaterial3D.new(); sm.albedo_color = Color("#e9b46c"); sm.roughness = 1.0
	skirt.material_override = sm
	add_child(skirt)

func _build_water() -> void:
	var wm := ShaderMaterial.new(); wm.shader = load("res://shaders/water.gdshader")
	for o in g.oases:
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new(); cm.top_radius = 17.0; cm.bottom_radius = 17.0; cm.height = 0.2; cm.radial_segments = 40
		mi.mesh = cm
		mi.material_override = wm
		mi.position = Vector3(o.x, -0.75, o.y)
		add_child(mi)
		water_nodes.append(mi)
		_obstacle(o, 13.5)
		inter.append({"kind": "oasis", "p": o, "r": 17.5, "label": "Vahada su iç"})
		shades.append([o, 0.0])

# ---------------------------------------------------------------- helpers
func ground(p: Vector2) -> float:
	return g.height(p.x, p.y)

func put(path: String, p: Vector2, s: float, rot := 0.0, parent: Node = self, yoff := 0.0) -> Node3D:
	var n := Models.instance(path)
	n.scale = Vector3.ONE * s
	n.rotation.y = rot
	n.position = Vector3(p.x, ground(p) + yoff, p.y)
	parent.add_child(n)
	return n

func box(size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO, parent: Node = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.material_override = mat
	mi.position = pos; mi.rotation = rot
	parent.add_child(mi)
	return mi

func _obstacle(p: Vector2, r: float) -> void:
	var cell := Vector2i(floori(p.x / GRID), floori(p.y / GRID))
	var span := int(ceil(r / GRID))
	for dj in range(-span, span + 1):
		for di in range(-span, span + 1):
			var k := cell + Vector2i(di, dj)
			if not obstacles.has(k):
				obstacles[k] = []
			obstacles[k].append([p, r])

## Pushes a circle (pos, radius) out of obstacles. Returns the corrected position.
func collide(p: Vector2, r: float) -> Vector2:
	var cell := Vector2i(floori(p.x / GRID), floori(p.y / GRID))
	for o in obstacles.get(cell, []):
		var d: Vector2 = p - o[0]
		var min_d: float = o[1] + r
		var l := d.length()
		if l < min_d:
			p = o[0] + (d / maxf(l, 0.001)) * min_d
	var lim := WorldGen.HALF - 3.0
	return Vector2(clampf(p.x, -lim, lim), clampf(p.y, -lim, lim))

func shaded(p: Vector2) -> bool:
	for s in shades:
		if p.distance_squared_to(s[0]) < s[1] * s[1]:
			return true
	for pl in placed:
		if pl.kind == "shelter" and p.distance_to(pl.p) < 3.2:
			return true
	return sheltered(p) != ""

## Returns the shelter name if p is inside a storm shelter, else "".
func sheltered(p: Vector2) -> String:
	for s in shelters:
		if p.distance_squared_to(s[0]) < s[1] * s[1]:
			return s[2]
	for pl in placed:
		if pl.kind == "shelter" and p.distance_to(pl.p) < 3.2:
			return "Gölgelik"
	return ""

func in_cave(p: Vector2) -> bool:
	for c in g.caves:
		if p.distance_to(c.p) < 6.5:
			return true
	return false

# ---------------------------------------------------------------- points of interest
func _mat(c: Color, rough := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = rough
	return m

func _build_wreck() -> void:
	var root := Node3D.new()
	root.position = Vector3(0, ground(Vector2.ZERO), 0)
	root.rotation.y = 0.5
	add_child(root)
	var white := _mat(Color("#eef0f2"), 0.5)
	var red := _mat(Color("#d9483b"), 0.5)
	var grey := _mat(Color("#7d848c"), 0.6)
	var glass := _mat(Color("#2d4a63"), 0.2)
	# fuselage (tilted cylinder) + nose + tail
	var fus := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 1.0; cm.bottom_radius = 1.15; cm.height = 7.5
	fus.mesh = cm; fus.material_override = white
	fus.rotation = Vector3(0, 0, PI / 2 - 0.08); fus.position = Vector3(0, 0.9, 0)
	root.add_child(fus)
	box(Vector3(7.4, 0.25, 2.2), Vector3(0, 1.1, 0), red, Vector3(0, 0, -0.08), root).scale = Vector3(1, 1, 1.02)
	var nose := MeshInstance3D.new()
	var sp := SphereMesh.new(); sp.radius = 1.12; sp.height = 2.0
	nose.mesh = sp; nose.material_override = white; nose.position = Vector3(3.8, 0.62, 0)
	root.add_child(nose)
	box(Vector3(1.0, 0.6, 1.6), Vector3(3.3, 1.55, 0), glass, Vector3(0, 0, -0.3), root)
	box(Vector3(0.2, 1.8, 1.3), Vector3(-3.6, 1.9, 0), red, Vector3(0, 0, 0.3), root)          # tail fin
	box(Vector3(1.4, 0.15, 3.2), Vector3(-3.4, 1.3, 0), white, Vector3(0.1, 0, 0), root)
	box(Vector3(2.0, 0.18, 6.0), Vector3(0.6, 0.55, 3.6), white, Vector3(0.18, 0.1, 0), root)   # wing
	box(Vector3(1.9, 0.18, 3.0), Vector3(0.9, 0.2, -3.2), grey, Vector3(-0.35, 0.4, 0.1), root) # broken wing
	box(Vector3(0.3, 0.3, 1.6), Vector3(4.9, 0.4, 0), grey, Vector3(0.3, 0, 0.2), root)          # propeller blade
	# debris
	for k in 6:
		var a := k * 1.1 + 0.4
		var p := Vector2(cos(a), sin(a)) * (5.0 + k)
		box(Vector3(0.6 + k * 0.1, 0.12, 0.4), Vector3(p.x, 0.05, p.y), grey if k % 2 else white, Vector3(0.2, a, 0.1), root)
	put("survival/box-large", Vector2(-1.5, 3.2).rotated(-0.5), 3.0, 0.3)
	put("survival/barrel", Vector2(2.4, -2.6).rotated(-0.5), 3.0, 0.0)
	var crate := put("survival/chest", Vector2(-2.2, -2.4).rotated(-0.5), 3.2, 1.2)
	inter.append({"kind": "wreck_crate", "p": Vector2(-2.2, -2.4).rotated(-0.5), "r": 2.4, "label": "Enkaz sandığını aç", "node": crate})
	inter.append({"kind": "radio", "p": Vector2(3.2, 1.6).rotated(-0.5), "r": 2.4, "label": "Telsiz"})
	for k in 5:
		var x := -3.0 + k * 1.5
		_obstacle(Vector2(x, 0).rotated(-0.5), 1.25)
	shades.append([Vector2.ZERO, 5.0])
	shelters.append([Vector2.ZERO, 5.0, "Uçak enkazı"])
	# smoke column (visible from far away for the first two days)
	smoke = CPUParticles3D.new()
	smoke.amount = 40; smoke.lifetime = 7.0
	smoke.position = Vector3(-1.0, 2.0, 0)
	smoke.direction = Vector3(0.15, 1, 0); smoke.spread = 8.0
	smoke.initial_velocity_min = 2.0; smoke.initial_velocity_max = 3.0
	smoke.gravity = Vector3(0.4, 0.3, 0)
	smoke.scale_amount_min = 2.0; smoke.scale_amount_max = 4.0
	var curve := Curve.new(); curve.add_point(Vector2(0, 0.4)); curve.add_point(Vector2(1, 2.5))
	smoke.scale_amount_curve = curve
	smoke.color = Color(0.25, 0.22, 0.2, 0.55)
	smoke.mesh = Fx.billboard("smoke_04", Color(1, 1, 1, 1))
	root.add_child(smoke)

func _build_ruin(i: int) -> void:
	var c: Vector2 = g.ruins[i]
	var root := Node3D.new()
	root.position = Vector3(c.x, ground(c), c.y)
	root.rotation.y = g.rng.randf() * TAU
	add_child(root)
	# small temple: columns holding a stone slab roof (storm shelter)
	var cols := [Vector2(-3.5, -2.5), Vector2(3.5, -2.5), Vector2(-3.5, 2.5), Vector2(3.5, 2.5), Vector2(0, -2.5), Vector2(0, 2.5)]
	for k in cols.size():
		var p: Vector2 = cols[k]
		var col := Models.instance("nature/statue_column" if k != 4 or i % 2 == 0 else "nature/statue_columnDamaged")
		col.scale = Vector3(3.2, 3.6, 3.2)
		col.position = Vector3(p.x, 0, p.y)
		root.add_child(col)
		_obstacle(c + p.rotated(-root.rotation.y), 0.55)
	box(Vector3(8.6, 0.5, 6.6), Vector3(0, 3.65, 0), stone_mat, Vector3(0.0, 0, 0.03), root)
	box(Vector3(8.6, 0.3, 0.8), Vector3(0, 0.15, -3.4), stone_mat, Vector3.ZERO, root)
	# collapsed blocks and a statue head around
	for k in 7:
		var a := g.rng.randf() * TAU
		var p := Vector2(cos(a), sin(a)) * g.rng.randf_range(6.0, 9.0)
		var b := Models.instance("nature/statue_block")
		b.scale = Vector3.ONE * g.rng.randf_range(2.5, 3.5)
		b.position = Vector3(p.x, 0, p.y); b.rotation = Vector3(g.rng.randf() * 0.3, a, g.rng.randf() * 0.3)
		root.add_child(b)
		_obstacle(c + p.rotated(-root.rotation.y), 0.6)
	var head := Models.instance("nature/statue_head")
	head.scale = Vector3.ONE * 3.0
	head.position = Vector3(6.5, -0.3, 3.5); head.rotation = Vector3(0.25, 2.2, 0.15)
	root.add_child(head)
	_obstacle(c + Vector2(6.5, 3.5).rotated(-root.rotation.y), 1.2)
	var pot := Models.instance("nature/pot_large"); pot.scale = Vector3.ONE * 2.5; pot.position = Vector3(-2.4, 0, 1.5); root.add_child(pot)
	var ch := Models.instance("survival/chest"); ch.scale = Vector3.ONE * 3.0; ch.position = Vector3(1.5, 0, 0.6); ch.rotation.y = 0.3; root.add_child(ch)
	var chest_p := c + Vector2(1.5, 0.6).rotated(-root.rotation.y)
	inter.append({"kind": "chest", "id": "ruin:%d" % i, "p": chest_p, "r": 2.2, "label": "Eski sandığı aç", "node": ch})
	shades.append([c, 5.5])
	shelters.append([c, 5.0, "Harabe"])

func _build_well(i: int) -> void:
	var w: Dictionary = g.wells[i]
	var p: Vector2 = w.p
	var root := Node3D.new()
	root.position = Vector3(p.x, ground(p), p.y)
	add_child(root)
	var ring := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = 1.3; cm.bottom_radius = 1.4; cm.height = 1.0; cm.radial_segments = 14
	ring.mesh = cm; ring.material_override = stone_mat; ring.position.y = 0.5
	root.add_child(ring)
	var inner := MeshInstance3D.new()
	var im := CylinderMesh.new(); im.top_radius = 1.0; im.bottom_radius = 1.0; im.height = 0.05; im.radial_segments = 14
	inner.mesh = im
	inner.material_override = dark_mat if w.dry else _mat(Color("#1b5f73"), 0.1)
	inner.position.y = 0.98
	root.add_child(inner)
	var stand := Models.instance("survival/campfire-stand"); stand.scale = Vector3.ONE * 6.0; root.add_child(stand)
	var b := Models.instance("survival/bucket"); b.scale = Vector3.ONE * 3.0; b.position = Vector3(0, 1.1, 0); root.add_child(b)
	_obstacle(p, 1.4)
	wells_b.append(0 if w.dry else 4)
	inter.append({"kind": "well", "i": i, "p": p, "r": 2.6, "label": "Kuyu"})

func _build_cave(i: int) -> void:
	var c: Dictionary = g.caves[i]
	var p: Vector2 = c.p
	var root := Node3D.new()
	root.position = Vector3(p.x, ground(p) - 0.4, p.y)
	root.rotation.y = -c.a + PI / 2
	add_child(root)
	var cave := Models.instance("nature/cliff_blockCave_rock")
	cave.scale = Vector3(8.0, 6.0, 8.0)
	root.add_child(cave)
	for k in 3:
		var r := Models.instance("nature/rock_tall" + ["A", "B", "C"][k])
		r.scale = Vector3.ONE * (4.0 + k)
		r.position = Vector3(-5.0 + k * 5.0, 0, -4.5)
		r.rotation.y = k * 1.3
		root.add_child(r)
	# collision: the block minus its open front
	var dir := Vector2(cos(c.a), sin(c.a))
	_obstacle(p - dir * 2.2, 2.4)
	_obstacle(p + dir.orthogonal() * 3.4, 1.4)
	_obstacle(p - dir.orthogonal() * 3.4, 1.4)
	shades.append([p, 5.0])
	shelters.append([p, 5.0, "Mağara"])
	var box_p := p + Vector2(cos(c.a), sin(c.a)) * 0.3
	var bx := put("survival/box", box_p, 3.0, g.rng.randf() * TAU)
	inter.append({"kind": "chest", "id": "cave:%d" % i, "p": box_p, "r": 2.2, "label": "Sandığı aç", "node": bx})

func _build_caravan() -> void:
	var c := g.caravan
	var root := Node3D.new()
	root.position = Vector3(c.x, ground(c), c.y)
	root.rotation.y = atan2(c.x, c.y)
	add_child(root)
	var wall := _mat(Color("#d9b07a"), 0.9)
	var L := 26.0
	for side in 4:
		var rot := side * PI / 2
		for seg in [-1, 1]:
			var gate := side == 0
			var length := (L / 2 - 3.0) if gate else L / 2
			var off = (3.0 + length / 2) * seg if gate else (L / 4) * seg
			var pos := Vector3(off, 1.8, -L / 2).rotated(Vector3.UP, rot)
			box(Vector3(length, 3.6, 1.2), pos, wall, Vector3(0, rot, 0), root)
		for k in 2:
			var tw := Vector3(L / 2 * (1 if k else -1), 2.6, -L / 2).rotated(Vector3.UP, rot)
			box(Vector3(2.4, 5.2, 2.4), tw, wall, Vector3(0, rot, 0), root)
	# walls collision (approximate with circles along the edges, gate open toward the map)
	for k in range(-6, 7):
		for side in 4:
			if side == 0 and absi(k) <= 1:
				continue
			var lp := Vector2(k * 2.0, -L / 2).rotated(side * PI / 2)
			_obstacle(c + lp.rotated(-root.rotation.y), 1.2)
	for k in 3:
		var t := Models.instance("nature/tent_detailedOpen")
		t.scale = Vector3.ONE * 6.0
		t.position = Vector3(-7 + k * 7, 0, 7)
		t.rotation.y = PI
		root.add_child(t)
	for k in 4:
		var palm := Models.instance("nature/tree_palmTall"); palm.scale = Vector3.ONE * 4.5
		palm.position = Vector3(-9 + k * 6, 0, -2); root.add_child(palm)
	var fire := Models.instance("nature/campfire_stones"); fire.scale = Vector3.ONE * 4.0; root.add_child(fire)
	var flag := box(Vector3(0.2, 9.0, 0.2), Vector3(0, 4.5, -L / 2 - 1.5), _mat(Color("#5b3a1e")), Vector3.ZERO, root)
	box(Vector3(2.4, 1.4, 0.05), Vector3(1.2, 8.2, -L / 2 - 1.5), _mat(Color("#2a8f5a")), Vector3.ZERO, root)
	shades.append([c, 13.0])
	shelters.append([c, 13.0, "Kervansaray"])
	inter.append({"kind": "caravan", "p": c, "r": 12.0, "label": "Kervansaray"})

func _build_obelisk() -> void:
	var o := put("nature/statue_obelisk", g.obelisk, 13.0)
	_obstacle(g.obelisk, 2.2)
	shades.append([g.obelisk, 2.5])

# ---------------------------------------------------------------- resource nodes (MultiMesh)
const NODE_LOOK := {
	"cactus": [["nature/cactus_tall", 3.0, Color(1, 1, 1)], ["nature/cactus_short", 3.4, Color(1, 1, 1)]],
	"pear": [["nature/cactus_short", 2.6, Color(0.85, 1.0, 0.8)]],
	"bush": [["nature/plant_bushDetailed", 2.8, Color(0.95, 0.85, 0.55)], ["nature/plant_bush", 3.4, Color(0.9, 0.8, 0.5)]],
	"stone": [["nature/rock_smallA", 2.4, Color(0.95, 0.9, 0.85)], ["nature/rock_smallD", 2.2, Color(0.9, 0.85, 0.8)]],
	"larva": [["nature/rock_smallFlatA", 3.2, Color(0.85, 0.7, 0.6)]],
	"palm": [["nature/tree_palm", 4.0, Color(1, 1, 1)], ["nature/tree_palmBend", 4.2, Color(1, 1, 1)], ["nature/tree_palmTall", 4.0, Color(1, 1, 1)], ["nature/tree_palmDetailedTall", 3.6, Color(1, 1, 1)]],
}
const NODE_LABEL := {"cactus": "Kaktüsü kes", "pear": "Frenk inciri topla", "bush": "Çalı topla", "stone": "Taş al", "larva": "Taşı kaldır", "palm": "Palmiye"}
const RESPAWN := {"cactus": 3.0, "pear": 1.0, "bush": 2.0, "stone": 2.0, "larva": 1.0, "palm": 2.0}

static var _tinted := {}
func tinted_mesh(path: String, col: Color) -> Mesh:
	var key := path + str(col)
	if _tinted.has(key):
		return _tinted[key]
	var base := Models.mesh(path)
	var m: ArrayMesh = base
	if col != Color(1, 1, 1):
		m = base.duplicate()
		for s in m.get_surface_count():
			var mat = base.surface_get_material(s)
			if mat is StandardMaterial3D:
				var c: StandardMaterial3D = mat.duplicate()
				c.albedo_color = c.albedo_color * col
				m.surface_set_material(s, c)
	_tinted[key] = m
	return m

func _region(p: Vector2) -> int:
	var rx := clampi(int((p.x + WorldGen.HALF) / (2 * WorldGen.HALF) * REG), 0, REG - 1)
	var rz := clampi(int((p.y + WorldGen.HALF) / (2 * WorldGen.HALF) * REG), 0, REG - 1)
	return rz * REG + rx

## Queues one MultiMesh instance; returns [key, region, index].
func _mm_add(path: String, col: Color, xf: Transform3D, p: Vector2) -> Array:
	var key := path + str(col)
	if not _mm.has(key):
		var regs := []
		for r in REG * REG:
			regs.append([])
		_mm[key] = {"mesh": tinted_mesh(path, col), "x": regs, "mmi": []}
	var r := _region(p)
	_mm[key].x[r].append(xf)
	return [key, r, _mm[key].x[r].size() - 1]

func _flush_mm() -> void:
	for key in _mm:
		var e: Dictionary = _mm[key]
		e.mmi = []
		for r in REG * REG:
			var xs: Array = e.x[r]
			if xs.is_empty():
				e.mmi.append(null)
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = e.mesh
			mm.instance_count = xs.size()
			for i in xs.size():
				mm.set_instance_transform(i, xs[i])
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			add_child(mmi)
			e.mmi.append(mmi)

func _set_visible(ref: Array, xf: Transform3D, on: bool) -> void:
	var mmi: MultiMeshInstance3D = _mm[ref[0]].mmi[ref[1]]
	if mmi == null:
		return
	mmi.multimesh.set_instance_transform(ref[2], xf if on else Transform3D(Basis().scaled(Vector3.ONE * 0.0001), xf.origin - Vector3(0, 50, 0)))

func _xf(p: Vector2, rot: float, s: float, yoff := 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, rot).scaled(Vector3.ONE * s), Vector3(p.x, ground(p) + yoff, p.y))

func _build_nodes() -> void:
	var fruit_mesh_path := "food/pear"
	for i in g.nodes.size():
		var n: Dictionary = g.nodes[i]
		var looks: Array = NODE_LOOK[n.t]
		var look: Array = looks[i % looks.size()]
		var xf := _xf(n.p, n.r, look[1] * n.s, -0.05)
		var st := {"t": n.t, "p": n.p, "ready_at": 0.0, "vis": [], "fruit": [], "xf": [], "fxf": []}
		var ref := _mm_add(look[0], look[2], xf, n.p)
		if n.t in ["palm", "pear"]:
			# the plant stays, only its fruit is harvested
			if n.t == "palm":
				_obstacle(n.p, 0.45)
				shades.append([n.p, 2.8])
				for k in 3:
					var a = n.r + k * TAU / 3
					var fp = n.p + Vector2(cos(a), sin(a)) * 0.6
					var fxf := _xf(fp, a, 1.6, 4.2 * n.s)
					st.fruit.append(_mm_add("food/grapes", Color(0.55, 0.32, 0.18), fxf, n.p)); st.fxf.append(fxf)
			else:
				_obstacle(n.p, 0.35)
				for k in 3:
					var a = n.r + k * TAU / 3
					var fp = n.p + Vector2(cos(a), sin(a)) * 0.45
					var fxf := _xf(fp, a, 0.9, 1.2 * n.s)
					st.fruit.append(_mm_add(fruit_mesh_path, Color(1.25, 0.4, 0.55), fxf, n.p)); st.fxf.append(fxf)
		else:
			st.vis.append(ref); st.xf.append(xf)
			if n.t == "cactus":
				_obstacle(n.p, 0.4)
		nodes.append(st)
		inter.append({"kind": "node", "i": i, "p": n.p, "r": 1.9 if n.t != "palm" else 2.2, "label": NODE_LABEL[n.t]})

func _build_decor() -> void:
	for d in g.decor:
		var path: String = d.m
		var folder := "survival/" if path.begins_with("rock-sand") else "nature/"
		var col := Color(1, 1, 1)
		var s: float = d.s * 2.6
		if path.begins_with("grass") or path.begins_with("plant"):
			col = Color(1.05, 0.9, 0.55)
			s = d.s * 3.0
		elif path.begins_with("rock_large") or path.begins_with("rock_tall"):
			col = Color(1.0, 0.72, 0.55)
			s = d.s * 3.5
		elif path.begins_with("rock-sand"):
			s = d.s * 3.0
		var xf := _xf(d.p, d.r, s, -0.1)
		_mm_add(folder + path, col, xf, d.p)
		if d.solid:
			var rr = 1.2 * d.s * (1.4 if path.begins_with("rock_large") else 1.0)
			_obstacle(d.p, rr)
			if path.begins_with("rock_tall"):
				shades.append([d.p, 1.8 * d.s])

## Is the node harvestable now?
func node_ready(i: int, t: float) -> bool:
	return t >= nodes[i].ready_at

func harvest_node(i: int, t: float) -> void:
	var st: Dictionary = nodes[i]
	st.ready_at = t + RESPAWN[st.t] * GameData.DAY_LEN
	for k in st.vis.size():
		_set_visible(st.vis[k], st.xf[k], false)
	for k in st.fruit.size():
		_set_visible(st.fruit[k], st.fxf[k], false)
	st["hidden"] = true

## Respawns nodes whose timer ran out (call ~1/s).
func update_nodes(t: float) -> void:
	for st in nodes:
		if st.get("hidden", false) and t >= st.ready_at:
			st.hidden = false
			for k in st.vis.size():
				_set_visible(st.vis[k], st.xf[k], true)
			for k in st.fruit.size():
				_set_visible(st.fruit[k], st.fxf[k], true)

## Nearest interactable within reach of p (with optional facing preference).
func find_interact(p: Vector2, t: float) -> Dictionary:
	var best := {}
	var bd := INF
	for it in inter + placed + crates:
		if it.get("gone", false):
			continue
		var d: float = p.distance_to(it.p)
		var r: float = it.get("r", 2.0)
		if d > r:
			continue
		if it.kind == "node" and not node_ready(it.i, t):
			continue
		if it.kind in ["wreck_crate", "chest"] and opened.get(it.get("id", "wreck"), false):
			continue
		if it.kind == "caravan":
			continue
		# prefer small targets over area ones (oasis/caravan)
		var score := d - (0.0 if it.kind != "oasis" else -10.0)
		if score < bd:
			bd = score; best = it
	return best

# ---------------------------------------------------------------- placed objects
## kind: fire / dew / trap / shelter / crate / carcass
func place(kind: String, p: Vector2, data := {}) -> Dictionary:
	var root := Node3D.new()
	root.position = Vector3(p.x, ground(p), p.y)
	add_child(root)
	var it := {"kind": kind, "p": p, "node": root, "r": 2.2}
	it.merge(data, true)
	match kind:
		"fire":
			put("nature/campfire_stones", Vector2.ZERO, 3.0, 0.0, root).position = Vector3.ZERO
			var logs := put("nature/campfire_logs", Vector2.ZERO, 3.2, 0.5, root); logs.position = Vector3(0, 0.05, 0)
			it.logs = logs
			var ash := put("nature/campfire_logs", Vector2.ZERO, 3.0, 1.1, root); ash.position = Vector3(0, 0.02, 0)
			Models.tint(ash, Color(0.25, 0.22, 0.22)); ash.visible = false
			it.ash = ash
			it.fx = Fx.fire(root)
			it.left = data.get("left", GameData.FIRE_TIME)
			it.label = "Ateş"
			_obstacle(p, 0.6)
		"dew":
			var st := put("survival/campfire-stand", Vector2.ZERO, 4.0, 0.0, root); st.position = Vector3.ZERO
			var cloth := box(Vector3(1.2, 0.04, 1.2), Vector3(0, 1.05, 0), _mat(Color("#e8e1d0")), Vector3(0.15, 0, 0), root)
			var b := put("survival/bottle", Vector2.ZERO, 3.0, 0.0, root); b.position = Vector3(0, 0, 0)
			it.label = "Çiy toplayıcı"
			it.water = data.get("water", 0.0)
		"trap":
			var bx := put("survival/box-open", Vector2.ZERO, 3.0, 0.0, root); bx.position = Vector3(0, 0.25, 0); bx.rotation.x = -0.35
			var st2 := put("nature/log", Vector2.ZERO, 0.8, 0.0, root); st2.position = Vector3(0, 0, 0.3); st2.rotation.x = -1.2
			it.label = "Tuzak"
			it.caught = data.get("caught", false)
			it.rabbit = null
		"shelter":
			var tent := put("survival/tent-canvas", Vector2.ZERO, 6.0, data.get("rot", 0.0), root); tent.position = Vector3.ZERO
			it.label = "Gölgelik"
			it.r = 3.2
		"crate":
			var c := put("survival/box", Vector2.ZERO, 3.2, randf() * TAU, root); c.position = Vector3(0, -0.1, 0)
			it.label = "Kumdan çıkan sandık"
			_beacon(root)
		"carcass":
			var cm := Models.instance(data.get("model", "pets/animal-bunny"))
			cm.scale = Vector3.ONE * data.get("scale", 0.25)
			cm.rotation = Vector3(0, randf() * TAU, PI / 2)
			cm.position.y = 0.15
			root.add_child(cm)
			it.label = data.get("label", "Avı topla")
	if kind in ["crate", "carcass"]:
		crates.append(it)
	else:
		placed.append(it)
	return it

func _beacon(root: Node3D) -> void:
	var p := CPUParticles3D.new()
	p.amount = Fx.amount(10); p.lifetime = 1.4
	p.mesh = Fx.billboard("star_04", Color(1, 0.9, 0.5), true, 0.4)
	p.direction = Vector3.UP; p.spread = 20.0
	p.initial_velocity_min = 1.0; p.initial_velocity_max = 2.0
	p.gravity = Vector3.ZERO
	p.position.y = 0.8
	root.add_child(p)

func remove_item(it: Dictionary) -> void:
	it.gone = true
	if it.has("node") and is_instance_valid(it.node):
		it.node.queue_free()
	placed.erase(it)
	crates.erase(it)

func set_fire_lit(it: Dictionary, on: bool) -> void:
	if it.fx and is_instance_valid(it.fx):
		it.fx.visible = on
		for c in it.fx.get_children():
			if c is CPUParticles3D:
				c.emitting = on
	it.logs.visible = on
	it.ash.visible = not on

func fires_near(p: Vector2, r: float) -> Array:
	var out := []
	for it in placed:
		if it.kind == "fire" and it.left > 0.0 and p.distance_to(it.p) < r:
			out.append(it)
	return out

func water_source_count() -> int:
	return wells_b.filter(func(b): return b > 0).size() + g.oases.size()
