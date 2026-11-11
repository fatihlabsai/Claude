## Procedural (seeded) world layout: heightmap, biomes, points of interest and
## resource node placement. Pure data so both the game and the sim can use it.
class_name WorldGen
extends RefCounted

enum B { DUNE, SCRUB, ROCK, OASIS, SALT }
const HALF := 300.0
const CELL := 2.5
const N := 241                      # heightmap samples per side

var seed_v := 1
var rng := RandomNumberGenerator.new()
var heights := PackedFloat32Array()
var n_dune := FastNoiseLite.new()
var n_det := FastNoiseLite.new()
var n_blob := FastNoiseLite.new()
var n_scrub := FastNoiseLite.new()

var wreck := Vector2.ZERO
var caravan := Vector2.ZERO
var cdir := Vector2.RIGHT
var salt_c := Vector2.ZERO
var salt_r := Vector2(95, 48)      # (across path, along path)
var oases: Array[Vector2] = []
var rocks: Array = []              # [{c:Vector2, r:float}]
var ruins: Array[Vector2] = []
var wells: Array = []              # [{p:Vector2, dry:bool}]
var caves: Array = []              # [{p:Vector2, a:float}]
var obelisk := Vector2.ZERO
var radio_parts := {}              # part id -> {"kind":"ruin"/"cave", "i":int}
var nodes: Array = []              # [{t:String, p:Vector2, r:float, s:float}]
var decor: Array = []              # [{m:String, p:Vector2, r:float, s:float, col:float}]

func generate(s: int) -> void:
	seed_v = s
	rng.seed = s
	for nz in [n_dune, n_det, n_blob, n_scrub]:
		nz.seed = s + nz.get_instance_id() % 997
	n_dune.noise_type = FastNoiseLite.TYPE_PERLIN; n_dune.frequency = 0.012
	n_det.frequency = 0.05
	n_blob.frequency = 0.03
	n_scrub.frequency = 0.02
	n_dune.seed = s; n_det.seed = s + 1; n_blob.seed = s + 2; n_scrub.seed = s + 3
	_layout()
	_build_heights()
	_place_nodes()

func _rand_dir(a: float) -> Vector2:
	return Vector2(cos(a), sin(a))

func _far_from(p: Vector2, pts: Array, d: float) -> bool:
	for q in pts:
		if p.distance_to(q) < d:
			return false
	return true

func _layout() -> void:
	var a0 := rng.randf() * TAU
	cdir = _rand_dir(a0)
	caravan = cdir * 268.0
	salt_c = cdir * 150.0
	var taken: Array = [wreck, caravan, salt_c]
	# oases away from the caravan direction
	for off in [rng.randf_range(100, 130), -rng.randf_range(120, 150)]:
		var p := _rand_dir(a0 + deg_to_rad(off)) * rng.randf_range(165, 215)
		oases.append(p); taken.append(p)
	# rocky plateaus
	var tries := 0
	while rocks.size() < 3 and tries < 400:
		tries += 1
		var p := _rand_dir(rng.randf() * TAU) * rng.randf_range(95, 225)
		if _far_from(p, taken, 110.0) and not in_salt(p, 30.0):
			rocks.append({"c": p, "r": rng.randf_range(38, 52)}); taken.append(p)
	# ruins: one at the far edge of the salt flat, rest spread out
	ruins.append(salt_c + cdir * 30.0 + cdir.orthogonal() * rng.randf_range(-40, 40))
	tries = 0
	while ruins.size() < 5 and tries < 600:
		tries += 1
		var p := _rand_dir(rng.randf() * TAU) * rng.randf_range(60, 255)
		if _far_from(p, taken + ruins, 80.0) and not in_salt(p, 10.0):
			ruins.append(p)
	taken.append_array(ruins)
	# wells: the nearest one is always wet
	tries = 0
	while wells.size() < 6 and tries < 800:
		tries += 1
		var r := rng.randf_range(55, 110) if wells.is_empty() else rng.randf_range(60, 265)
		var p := _rand_dir(rng.randf() * TAU) * r
		var wp: Array = wells.map(func(w): return w.p)
		if _far_from(p, taken + wp, 55.0) and not in_salt(p, 5.0) and not in_rock(p, 5.0):
			wells.append({"p": p, "dry": false})
	var idx := range(1, wells.size())
	idx.shuffle()
	for i in idx.slice(0, 3):
		wells[i].dry = true
	# caves on the rim of each plateau
	for rk in rocks:
		var k := 2 if caves.size() >= 4 else 3
		for j in k:
			var a := rng.randf() * TAU
			var p: Vector2 = rk.c + _rand_dir(a) * (rk.r * 0.72)
			caves.append({"p": p, "a": a})
	obelisk = _rand_dir(a0 + PI + rng.randf_range(-0.6, 0.6)) * rng.randf_range(90, 130)
	# radio parts: ruin (salt edge), a cave, and the ruin farthest from the wreck
	var far_i := 1
	for i in range(1, ruins.size()):
		if ruins[i].length() > ruins[far_i].length():
			far_i = i
	radio_parts = {"devre": {"kind": "ruin", "i": 0}, "anten": {"kind": "ruin", "i": far_i}, "pil": {"kind": "cave", "i": rng.randi() % caves.size()}}

func in_salt(p: Vector2, pad := 0.0) -> bool:
	var d := p - salt_c
	var u := d.dot(cdir.orthogonal()) / (salt_r.x + pad)
	var v := d.dot(cdir) / (salt_r.y + pad)
	return u * u + v * v < 1.0

func salt_factor(p: Vector2) -> float:
	var d := p - salt_c
	var u := d.dot(cdir.orthogonal()) / salt_r.x
	var v := d.dot(cdir) / salt_r.y
	return 1.0 - smoothstep(0.75, 1.05, sqrt(u * u + v * v))

func in_rock(p: Vector2, pad := 0.0) -> bool:
	return rock_factor(p, pad) > 0.5

func rock_factor(p: Vector2, pad := 0.0) -> float:
	var best := 0.0
	for rk in rocks:
		var d: float = p.distance_to(rk.c) + n_blob.get_noise_2dv(p) * 12.0
		best = maxf(best, 1.0 - smoothstep(rk.r * 0.8 - pad, rk.r + pad, d))
	return best

func oasis_factor(p: Vector2) -> float:
	var best := 0.0
	for o in oases:
		best = maxf(best, 1.0 - smoothstep(16.0, 38.0, p.distance_to(o)))
	return best

func biome(p: Vector2) -> int:
	if oasis_factor(p) > 0.3:
		return B.OASIS
	if salt_factor(p) > 0.5:
		return B.SALT
	if rock_factor(p) > 0.5:
		return B.ROCK
	if n_scrub.get_noise_2dv(p) > 0.28:
		return B.SCRUB
	return B.DUNE

func _raw_height(p: Vector2) -> float:
	var q := p.rotated(0.6)
	var ridge := 1.0 - absf(n_dune.get_noise_2d(q.x * 1.0, q.y * 1.7))
	var h := ridge * ridge * 7.5 + n_det.get_noise_2dv(p) * 1.2
	var rf := rock_factor(p)
	h = lerpf(h, 9.0 + n_det.get_noise_2dv(p * 2.0) * 2.5, rf)
	var sf := salt_factor(p)
	h = lerpf(h, 0.3, sf)
	for o in oases:
		var d := p.distance_to(o)
		h = lerpf(h, -1.4, 1.0 - smoothstep(10.0, 30.0, d))
	# flatten around points of interest
	var flats: Array = [[wreck, 16.0], [caravan, 24.0], [obelisk, 6.0]]
	for r in ruins:
		flats.append([r, 13.0])
	for w in wells:
		flats.append([w.p, 6.0])
	for f in flats:
		var w := 1.0 - smoothstep(f[1] * 0.6, f[1] * 1.6, p.distance_to(f[0]))
		h = lerpf(h, 1.5 + rf * 7.5, w)
	# keep map edge low-ish dunes
	return h

func _build_heights() -> void:
	heights.resize(N * N)
	for j in N:
		for i in N:
			heights[j * N + i] = _raw_height(Vector2(-HALF + i * CELL, -HALF + j * CELL))

func height(x: float, z: float) -> float:
	var fx := clampf((x + HALF) / CELL, 0.0, N - 1.001)
	var fz := clampf((z + HALF) / CELL, 0.0, N - 1.001)
	var i := int(fx); var j := int(fz)
	var tx := fx - i; var tz := fz - j
	var a := heights[j * N + i]; var b := heights[j * N + i + 1]
	var c := heights[(j + 1) * N + i]; var d := heights[(j + 1) * N + i + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)

func slope(x: float, z: float) -> float:
	var dx := height(x + 1.0, z) - height(x - 1.0, z)
	var dz := height(x, z + 1.0) - height(x, z - 1.0)
	return Vector2(dx, dz).length() * 0.5

func _poi_clear(p: Vector2) -> bool:
	if p.distance_to(wreck) < 12.0 or p.distance_to(caravan) < 26.0 or p.distance_to(obelisk) < 5.0:
		return false
	for r in ruins:
		if p.distance_to(r) < 11.0: return false
	for w in wells:
		if p.distance_to(w.p) < 5.0: return false
	for c in caves:
		if p.distance_to(c.p) < 9.0: return false
	for o in oases:
		if p.distance_to(o) < 15.0: return false
	return absf(p.x) < HALF - 6 and absf(p.y) < HALF - 6

func _place_nodes() -> void:
	var step := 9.0
	var cnt := int(2 * HALF / step)
	for j in cnt:
		for i in cnt:
			var p := Vector2(-HALF + (i + rng.randf()) * step, -HALF + (j + rng.randf()) * step)
			if not _poi_clear(p):
				continue
			var b := biome(p)
			var r := rng.randf()
			var t := ""
			match b:
				B.DUNE:
					t = _pick(r, [["cactus", 0.03], ["bush", 0.04], ["stone", 0.015], ["pear", 0.008]])
					if t == "" and rng.randf() < 0.06: _decor(p, ["rock-sand-a", "rock-sand-b", "rock-sand-c", "grass"][rng.randi() % 4])
				B.SCRUB:
					t = _pick(r, [["bush", 0.18], ["pear", 0.06], ["cactus", 0.06], ["stone", 0.03]])
					if t == "" and rng.randf() < 0.3: _decor(p, ["grass", "grass_large", "plant_bushSmall", "flower_yellowA"][rng.randi() % 4])
				B.ROCK:
					t = _pick(r, [["stone", 0.12], ["larva", 0.06], ["bush", 0.03], ["cactus", 0.02]])
					if t == "" and rng.randf() < 0.32: _decor(p, ["rock_largeA", "rock_largeB", "rock_largeC", "rock_largeD", "rock_tallA", "rock_tallB", "rock_tallC", "rock_tallD", "rock_tallE"][rng.randi() % 9], true)
				B.OASIS:
					t = _pick(r, [["bush", 0.25], ["pear", 0.08]])
					if t == "" and rng.randf() < 0.5: _decor(p, ["grass_large", "grass", "plant_bushDetailed", "flower_redA"][rng.randi() % 4])
				B.SALT:
					if rng.randf() < 0.01: _decor(p, "rock_smallFlatA")
			if t != "":
				nodes.append({"t": t, "p": p, "r": rng.randf() * TAU, "s": rng.randf_range(0.85, 1.25)})
	# palms ring each oasis
	for o in oases:
		var k := 11 + rng.randi() % 4
		for i in k:
			var a := TAU * i / k + rng.randf_range(-0.2, 0.2)
			nodes.append({"t": "palm", "p": o + _rand_dir(a) * rng.randf_range(15, 22), "r": rng.randf() * TAU, "s": rng.randf_range(0.9, 1.3)})
	# guaranteed starter materials near the wreck
	for i in 4:
		nodes.append({"t": "bush", "p": _rand_dir(rng.randf() * TAU) * rng.randf_range(14, 26), "r": rng.randf() * TAU, "s": 1.0})
		nodes.append({"t": "stone", "p": _rand_dir(rng.randf() * TAU) * rng.randf_range(13, 28), "r": rng.randf() * TAU, "s": 1.0})
	nodes.append({"t": "cactus", "p": _rand_dir(rng.randf() * TAU) * 30.0, "r": 0.0, "s": 1.1})
	# a few palms at some ruins
	for r in ruins.slice(1):
		if rng.randf() < 0.6:
			nodes.append({"t": "palm", "p": r + _rand_dir(rng.randf() * TAU) * 13.0, "r": rng.randf() * TAU, "s": 1.0})

func _pick(r: float, table: Array) -> String:
	var acc := 0.0
	for e in table:
		acc += e[1]
		if r < acc:
			return e[0]
	return ""

func _decor(p: Vector2, m: String, solid := false) -> void:
	decor.append({"m": m, "p": p, "r": rng.randf() * TAU, "s": rng.randf_range(0.8, 1.6) if solid else rng.randf_range(0.7, 1.2), "solid": solid})

## Nearest point of interest of a type to p (returns Vector2 or null).
func nearest(p: Vector2, pts: Array) -> Variant:
	var best: Variant = null
	var bd := INF
	for q in pts:
		var v: Vector2 = q if q is Vector2 else q.p
		var d := p.distance_to(v)
		if d < bd:
			bd = d; best = v
	return best
