## Static scenery of both shores of the Bosphorus: ground, quay, roads, pastel
## Istanbul houses in a 3/4 view, parks and landmarks (Galata, Dolmabahçe,
## mosques, Kız Kulesi, Haydarpaşa...). All shapes are original procedural art;
## shoreline rocks use Kenney's Pirate Pack (CC0).
extends Node2D

const PALETTE := ["#f7b7a3", "#ffd98e", "#a8e0c9", "#f6a6b2", "#c5b3e6", "#9ed0f0", "#ffe9b8", "#f4c095", "#b8e0a8", "#fff3e0", "#ffc9de", "#d8ecff", "#f2d0a4", "#e7c6ff"]
const ROOFS := ["#c8553d", "#d9694f", "#b84a3a", "#a9443a", "#d97b55", "#8e9aa6", "#c9c3b8"]
const LAND_COL := Color("#ecdfc0")
const INLET_Y0 := 1392.0
const INLET_Y1 := 1446.0
const CHUNK := 160.0

var rng := RandomNumberGenerator.new()
var rocks: Array[Texture2D] = []
var flags: Array = []        # [pos, scale] for live waving flags
var excl: Array = []         # Rect2 exclusion zones for houses
var items: Array = []

func _ready() -> void:
	rng.seed = 20251110
	for i in 3:
		rocks.append(load("res://assets/sprites/rock_%d.png" % (i + 1)))
	_build()

func _build() -> void:
	var base := Node2D.new()
	base.set_script(load("res://scripts/land_chunk.gd"))
	base.land = self
	base.items = [{"t": "ground"}]
	add_child(base)
	_landmarks()
	_houses()
	_trees_and_parks()
	_shore_rocks()
	items.sort_custom(func(a, b): return a.y < b.y)
	# group into slices by sort-y
	var groups := {}
	for it in items:
		var k := int(floor(it.y / CHUNK))
		if not groups.has(k):
			groups[k] = []
		groups[k].append(it)
	var keys := groups.keys()
	keys.sort()
	for k in keys:
		var ch := Node2D.new()
		ch.set_script(load("res://scripts/land_chunk.gd"))
		ch.land = self
		ch.items = groups[k]
		add_child(ch)

func eu_edge(y: float) -> float:
	return Geo.eu_x(y)

func as_edge(y: float) -> float:
	return Geo.as_x(y)

func in_inlet(y: float, pad := 0.0) -> bool:
	return y > INLET_Y0 - pad and y < INLET_Y1 + pad

func _blocked(r: Rect2) -> bool:
	for e in excl:
		if e.intersects(r):
			return true
	return false

# ------------------------------------------------------------------ layout
func _landmarks() -> void:
	var y: float
	# Europe
	y = 205.0
	_add_lm("ortakoy", Vector2(Geo.eu_x(y) - 46, y), Rect2(Geo.eu_x(y) - 100, y - 90, 100, 110))
	y = 470.0
	_add_lm("palace", Vector2(Geo.eu_x(y) - 60, y), Rect2(Geo.eu_x(y) - 290, y - 70, 290, 95))
	_add_lm("park", Vector2(Geo.eu_x(330) - 190, 330), Rect2(Geo.eu_x(330) - 330, 255, 280, 140))
	y = 1235.0
	_add_lm("galata", Vector2(Geo.eu_x(y) - 150, y), Rect2(Geo.eu_x(y) - 180, y - 120, 60, 135))
	y = 1640.0
	_add_lm("mosque_big", Vector2(Geo.eu_x(y) - 170, y), Rect2(Geo.eu_x(y) - 270, y - 130, 200, 150))
	y = 1530.0
	_add_lm("mosque", Vector2(Geo.eu_x(y) - 70, y), Rect2(Geo.eu_x(y) - 125, y - 100, 110, 115))
	_add_lm("park", Vector2(Geo.eu_x(1520) - 230, 1520), Rect2(Geo.eu_x(1520) - 330, 1470, 190, 110))
	# Asia
	y = 250.0
	_add_lm("camlica", Vector2(Geo.as_x(y) + 260, y), Rect2(Geo.as_x(y) + 150, y - 190, 260, 230))
	y = 740.0
	_add_lm("mosque", Vector2(Geo.as_x(y) + 80, y), Rect2(Geo.as_x(y) + 25, y - 100, 115, 115))
	y = 1290.0
	_add_lm("selimiye", Vector2(Geo.as_x(y) + 150, y), Rect2(Geo.as_x(y) + 60, y - 90, 200, 110))
	y = 1420.0
	_add_lm("station", Vector2(Geo.as_x(y) + 70, y), Rect2(Geo.as_x(y) + 15, y - 80, 120, 95))
	_add_lm("park", Vector2(Geo.as_x(960) + 160, 960), Rect2(Geo.as_x(960) + 80, 900, 180, 120))
	# piers
	for p in Geo.PIER_DEFS:
		var side: String = p.side
		var dir := 1.0 if side == "eu" else -1.0
		var sx := Geo.eu_x(p.y) if side == "eu" else Geo.as_x(p.y)
		var tx := sx - dir * 62
		_add_lm("terminal", Vector2(tx, p.y), Rect2(tx - 50, p.y - 70, 100, 100), {"col": p.color, "dir": dir, "name": p.name})
	# Maiden's tower islet (in the water)
	items.append({"t": "maiden", "y": Geo.MAIDEN.y + 20, "p": Geo.MAIDEN})
	flags.append([Geo.MAIDEN + Vector2(2, -62), 0.8])

func _add_lm(t: String, p: Vector2, ex: Rect2, extra := {}) -> void:
	excl.append(ex)
	var it := {"t": t, "y": p.y, "p": p}
	it.merge(extra)
	items.append(it)
	match t:
		"galata": flags.append([p + Vector2(0, -104), 0.9])
		"palace": flags.append([p + Vector2(-110, -58), 0.8])
		"terminal": flags.append([p + Vector2(-extra.dir * 20, -38), 0.7])
		"station": flags.append([p + Vector2(0, -52), 0.7])
		"selimiye": flags.append([p + Vector2(0, -48), 0.7])

func _houses() -> void:
	var y := -60.0
	while y < Geo.WORLD_BOTTOM + 40:
		var d := rng.randf_range(18, 26)
		for side in ["eu", "as"]:
			var edge := Geo.eu_x(y + d) if side == "eu" else Geo.as_x(y + d)
			var dir := -1.0 if side == "eu" else 1.0
			var x := edge + dir * rng.randf_range(50, 58)
			var limit := 540.0
			var gone := 0.0
			while gone < limit:
				var w := rng.randf_range(20, 40)
				var bx := x - w if dir < 0 else x
				var r := Rect2(bx, y - 34, w, d + 34)
				var ok := not _blocked(r)
				if side == "eu" and in_inlet(y + d, 30):
					ok = false
				if ok and rng.randf() < 0.93:
					var col := Color(PALETTE[rng.randi() % PALETTE.size()])
					var roof := Color(ROOFS[rng.randi() % ROOFS.size()])
					var h := rng.randf_range(10, 28) * (1.15 if gone > 220 else 1.0)
					items.append({"t": "bld", "y": y + d, "r": Rect2(bx, y, w, d), "h": h, "col": col, "roof": roof, "pitch": rng.randf() < 0.6, "seed": rng.randi()})
				elif rng.randf() < 0.5 and not _blocked(r):
					items.append({"t": "tree", "y": y + d * 0.7, "p": Vector2(bx + w / 2, y + d * 0.6), "r": rng.randf_range(6, 10), "col": rng.randi() % 3})
				var step := w + rng.randf_range(3, 8)
				x += dir * step
				gone += step
		y += d + rng.randf_range(10, 16)

func _trees_and_parks() -> void:
	# boulevard trees along the coastal road
	var y := -40.0
	while y < Geo.WORLD_BOTTOM:
		for side in ["eu", "as"]:
			if side == "eu" and in_inlet(y, 26):
				continue
			var x := Geo.eu_x(y) - 44 if side == "eu" else Geo.as_x(y) + 44
			var near_pier := false
			for p in Geo.PIER_DEFS:
				if absf(p.y - y) < 60:
					near_pier = true
			if not near_pier and rng.randf() < 0.75:
				items.append({"t": "tree", "y": y + 4, "p": Vector2(x, y), "r": rng.randf_range(5, 7), "col": rng.randi() % 3})
		y += rng.randf_range(20, 30)

func _shore_rocks() -> void:
	var y := 0.0
	while y < Geo.WORLD_BOTTOM:
		y += rng.randf_range(60, 140)
		for side in ["eu", "as"]:
			var skip := false
			for p in Geo.PIER_DEFS:
				if absf(p.y - y) < 90:
					skip = true
			if skip or rng.randf() < 0.5 or (side == "eu" and in_inlet(y, 30)):
				continue
			var x := Geo.eu_x(y) + 6 if side == "eu" else Geo.as_x(y) - 6
			items.append({"t": "rock", "y": y - 200, "p": Vector2(x, y), "i": rng.randi() % 3, "s": rng.randf_range(0.14, 0.22), "rot": rng.randf() * TAU})

# ------------------------------------------------------------------ drawing
func draw_item(c: CanvasItem, it: Dictionary) -> void:
	match it.t:
		"ground": _draw_ground(c)
		"bld": _draw_building(c, it)
		"tree": _draw_tree(c, it.p, it.r, it.col)
		"rock":
			var tex: Texture2D = rocks[it.i]
			var sz = tex.get_size() * it.s
			c.draw_set_transform(it.p, it.rot, Vector2.ONE)
			c.draw_texture_rect(tex, Rect2(-sz / 2, sz), false)
			c.draw_set_transform_matrix(Transform2D.IDENTITY)
		"ortakoy": _draw_mosque(c, it.p, 0.7, Color("#f3efe6"), 2, true)
		"mosque": _draw_mosque(c, it.p, 0.85, Color("#e9e1d0"), 2, false)
		"mosque_big": _draw_mosque(c, it.p, 1.25, Color("#e6ddca"), 4, false)
		"palace": _draw_palace(c, it.p)
		"galata": _draw_galata(c, it.p)
		"camlica": _draw_camlica(c, it.p)
		"selimiye": _draw_selimiye(c, it.p)
		"station": _draw_station(c, it.p)
		"park": _draw_park(c, it.p)
		"terminal": _draw_terminal(c, it)
		"maiden": _draw_maiden(c, it.p)

func _shore_poly(side: String, y0: float, y1: float, far: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var y := y0
	while y <= y1:
		pts.append(Vector2(Geo.eu_x(y) if side == "eu" else Geo.as_x(y), y))
		y += 8.0
	pts.append(Vector2(Geo.eu_x(y1) if side == "eu" else Geo.as_x(y1), y1))
	pts.append(Vector2(far, y1))
	pts.append(Vector2(far, y0))
	return pts

func _offset_line(side: String, off: float, y0: float, y1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var y := y0
	var dir := -1.0 if side == "eu" else 1.0
	while y <= y1:
		var x := (Geo.eu_x(y) if side == "eu" else Geo.as_x(y)) + dir * off
		pts.append(Vector2(x, y))
		y += 8.0
	return pts

func _draw_ground(c: CanvasItem) -> void:
	var top := Geo.WATER_TOP - 80
	var bot := Geo.WORLD_BOTTOM + 400
	# Europe (with the Golden Horn inlet cut out) and Asia
	for seg in [[top, INLET_Y0], [INLET_Y1, bot]]:
		c.draw_colored_polygon(_shore_poly("eu", seg[0], seg[1], -700), LAND_COL)
	c.draw_colored_polygon(_shore_poly("as", top, bot, 2200), LAND_COL)
	# Golden Horn water + Galata bridge
	var ix := Geo.eu_x((INLET_Y0 + INLET_Y1) / 2)
	var inlet := PackedVector2Array([Vector2(ix + 4, INLET_Y0), Vector2(-700, INLET_Y0 - 6), Vector2(-700, INLET_Y1 + 6), Vector2(ix + 4, INLET_Y1)])
	c.draw_colored_polygon(inlet, Color("#3c9fd3"))
	for i in 7:
		var yy := INLET_Y0 + 8 + i * 6.5
		c.draw_line(Vector2(-700, yy), Vector2(ix - 6, yy + sin(i) * 2), Color(1, 1, 1, 0.08), 1.0)
	c.draw_line(Vector2(-700, INLET_Y0 - 2), Vector2(ix + 2, INLET_Y0), Color("#c7c2b8"), 4.0)
	c.draw_line(Vector2(-700, INLET_Y1 + 2), Vector2(ix + 2, INLET_Y1), Color("#c7c2b8"), 4.0)
	var gx := ix - 120
	c.draw_rect(Rect2(gx + 4, INLET_Y0 - 6, 20, INLET_Y1 - INLET_Y0 + 12), Color(0, 0, 0, 0.18))
	c.draw_rect(Rect2(gx, INLET_Y0 - 8, 20, INLET_Y1 - INLET_Y0 + 16), Color("#9aa3ad"))
	c.draw_rect(Rect2(gx + 3, INLET_Y0 - 8, 14, INLET_Y1 - INLET_Y0 + 16), Color("#6f7882"))
	for i in 5:
		var yy := INLET_Y0 + i * 12.0
		c.draw_circle(Vector2(gx + 1, yy), 1.2, Color("#ffe9a8"))
		c.draw_circle(Vector2(gx + 19, yy + 6), 1.2, Color("#ffe9a8"))
	# promenade (sand-stone), quay edge and coastal road
	for side in ["eu", "as"]:
		var segs := [[top, INLET_Y0 - 4], [INLET_Y1 + 4, bot]] if side == "eu" else [[top, bot]]
		for seg in segs:
			var road := _offset_line(side, 30, seg[0], seg[1])
			c.draw_polyline(_offset_line(side, 9, seg[0], seg[1]), Color("#e2d3b3"), 18.0)
			c.draw_polyline(road, Color("#8a8c92"), 15.0)
			c.draw_polyline(road, Color("#9a9ca3"), 11.0)
			# dashed centre line
			for i in range(0, road.size() - 2, 3):
				c.draw_line(road[i], road[i + 1], Color(1, 1, 1, 0.7), 1.2)
			c.draw_polyline(_offset_line(side, 40, seg[0], seg[1]), Color("#d6c6a4"), 4.0)
			c.draw_polyline(_offset_line(side, 1.5, seg[0], seg[1]), Color("#c8c2b6"), 4.0)
			c.draw_polyline(_offset_line(side, -1.0, seg[0], seg[1]), Color("#8f8a80"), 1.5)
	# pier decks reaching into the water
	for p in Geo.PIER_DEFS:
		_draw_pier_deck(c, p)

func _draw_pier_deck(c: CanvasItem, p: Dictionary) -> void:
	var dir := 1.0 if p.side == "eu" else -1.0
	var sx := Geo.eu_x(p.y) if p.side == "eu" else Geo.as_x(p.y)
	var tip := sx + dir * 58
	var x0 := minf(sx, tip)
	var r := Rect2(x0 - 4, p.y - 42, 66, 84)
	c.draw_rect(Rect2(r.position + Vector2(5, 7), r.size), Color(0.02, 0.12, 0.22, 0.25))
	c.draw_rect(r, Color("#8a5a35"))
	for i in range(0, 84, 5):
		c.draw_rect(Rect2(r.position.x + 1, r.position.y + i + 1, 64, 3.6), Color("#b98552") if (i / 5) % 2 == 0 else Color("#a9764a"))
	c.draw_rect(r, Color("#5e3d22"), false, 2.0)
	# fenders (old tyres) and bollards on the water edge
	for i in 5:
		var fy = p.y - 34 + i * 17.0
		c.draw_arc(Vector2(tip + dir * 1, fy), 3.6, 0, TAU, 14, Color("#222222"), 2.2, true)
		c.draw_circle(Vector2(tip - dir * 6, fy), 2.2, Color("#3a3a3a"))
	# canopy stripe in the pier colour
	c.draw_rect(Rect2(x0 + 6, p.y - 30, 46, 6), (p.color as Color).darkened(0.1))
	c.draw_rect(Rect2(x0 + 6, p.y + 24, 46, 6), (p.color as Color).darkened(0.1))

func _draw_building(c: CanvasItem, it: Dictionary) -> void:
	var r: Rect2 = it.r
	var h: float = it.h
	var col: Color = it.col
	var roof_r := Rect2(r.position.x, r.position.y - h, r.size.x, r.size.y)
	var front := Rect2(r.position.x, r.position.y - h + r.size.y, r.size.x, h)
	# cast shadow (sun from the upper left)
	c.draw_colored_polygon(PackedVector2Array([r.position + Vector2(r.size.x, r.size.y), r.position + Vector2(r.size.x, -h + r.size.y), r.position + Vector2(r.size.x + h * 0.6, r.size.y - h * 0.2), r.position + Vector2(r.size.x + h * 0.6, r.size.y + 4)]), Color(0.3, 0.2, 0.1, 0.16))
	c.draw_rect(front, col.darkened(0.18))
	# windows
	var cols := int((r.size.x - 4) / 6)
	var rows := int((h - 4) / 7)
	var wseed: int = it.seed
	for j in rows:
		for i in cols:
			var lit := ((wseed >> ((i + j * 3) % 24)) & 1) == 1
			c.draw_rect(Rect2(front.position.x + 3 + i * 6, front.position.y + 3 + j * 7, 3, 4), Color("#fff3c4") if lit and j % 2 == 0 else Color("#4a6a8a").lerp(col, 0.35))
	c.draw_rect(Rect2(front.position.x, front.end.y - 2, front.size.x, 2), col.darkened(0.35))
	# roof
	var roof: Color = it.roof
	if it.pitch:
		c.draw_rect(roof_r, roof)
		c.draw_rect(Rect2(roof_r.position, Vector2(roof_r.size.x, roof_r.size.y * 0.5)), roof.lightened(0.12))
		c.draw_line(roof_r.position + Vector2(2, roof_r.size.y * 0.5), roof_r.position + Vector2(roof_r.size.x - 2, roof_r.size.y * 0.5), roof.darkened(0.25), 1.2)
	else:
		c.draw_rect(roof_r, col.lightened(0.25))
		c.draw_rect(roof_r.grow(-2), col.lightened(0.1))
		if wseed % 3 == 0:
			c.draw_rect(Rect2(roof_r.position + Vector2(4, 4), Vector2(6, 5)), Color("#9aa3ad"))
	c.draw_rect(roof_r, col.darkened(0.3), false, 1.0)

func _draw_tree(c: CanvasItem, p: Vector2, r: float, kind: int) -> void:
	var greens := [Color("#5fae5a"), Color("#4f9e57"), Color("#78bf63")]
	var g: Color = greens[kind % 3]
	Art.ellipse(c, p + Vector2(r * 0.5, r * 0.6), r, r * 0.7, Color(0.2, 0.25, 0.1, 0.2), 14)
	c.draw_circle(p, r, g.darkened(0.15))
	c.draw_circle(p + Vector2(-r * 0.2, -r * 0.25), r * 0.75, g)
	c.draw_circle(p + Vector2(-r * 0.35, -r * 0.4), r * 0.3, g.lightened(0.25))

func _dome(c: CanvasItem, base: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(0, 17):
		var a := PI + PI * i / 16.0
		pts.append(base + Vector2(cos(a) * r, sin(a) * r * 0.95))
	c.draw_colored_polygon(pts, col)
	var hl := PackedVector2Array()
	for i in range(0, 9):
		var a := PI + PI * 0.5 * i / 8.0
		hl.append(base + Vector2(cos(a) * r * 0.82, sin(a) * r * 0.8))
	hl.append(base)
	c.draw_colored_polygon(hl, col.lightened(0.18))
	c.draw_line(base + Vector2(-r, 0), base + Vector2(r, 0), col.darkened(0.3), 1.5)

func _minaret(c: CanvasItem, base: Vector2, hgt: float, s: float, col: Color) -> void:
	var w := 4.5 * s
	c.draw_rect(Rect2(base.x - w / 2 + 2, base.y - 2, w, 4), Color(0, 0, 0, 0.15))
	c.draw_rect(Rect2(base.x - w / 2, base.y - hgt, w, hgt), col)
	c.draw_rect(Rect2(base.x, base.y - hgt, w / 2, hgt), col.darkened(0.1))
	for k in [0.62, 0.82]:
		c.draw_rect(Rect2(base.x - w * 0.85, base.y - hgt * k, w * 1.7, 2.2 * s), col.darkened(0.2))
	c.draw_colored_polygon(PackedVector2Array([Vector2(base.x - w * 0.6, base.y - hgt), Vector2(base.x + w * 0.6, base.y - hgt), Vector2(base.x, base.y - hgt - 13 * s)]), Color("#7d8b99"))
	c.draw_line(Vector2(base.x, base.y - hgt - 13 * s), Vector2(base.x, base.y - hgt - 17 * s), Color("#d4af37"), 1.0)

func _draw_mosque(c: CanvasItem, p: Vector2, s: float, col: Color, minarets: int, waterfront: bool) -> void:
	var w := 70.0 * s
	var hb := 26.0 * s
	Art.ellipse(c, p + Vector2(10 * s, 4 * s), w * 0.65, 10 * s, Color(0.3, 0.2, 0.1, 0.16))
	# courtyard wall
	c.draw_rect(Rect2(p.x - w / 2, p.y - hb, w, hb), col.darkened(0.08))
	c.draw_rect(Rect2(p.x - w / 2, p.y - hb - 4 * s, w, 4 * s), col.lightened(0.1))
	# arched windows
	for i in 6:
		var ax := p.x - w / 2 + 6 * s + i * (w - 12 * s) / 5.0
		c.draw_rect(Rect2(ax - 2.5 * s, p.y - hb * 0.65, 5 * s, hb * 0.45), Color("#5b6f86"))
		c.draw_circle(Vector2(ax, p.y - hb * 0.65), 2.5 * s, Color("#5b6f86"))
	var dome_col := Color("#8d9cab")
	_dome(c, Vector2(p.x - w * 0.3, p.y - hb - 4 * s), 9 * s, dome_col)
	_dome(c, Vector2(p.x + w * 0.3, p.y - hb - 4 * s), 9 * s, dome_col)
	c.draw_rect(Rect2(p.x - 16 * s, p.y - hb - 14 * s, 32 * s, 10 * s), col)
	_dome(c, Vector2(p.x, p.y - hb - 14 * s), 18 * s, dome_col)
	c.draw_line(Vector2(p.x, p.y - hb - 31 * s), Vector2(p.x, p.y - hb - 40 * s), Color("#d4af37"), 1.5)
	c.draw_circle(Vector2(p.x, p.y - hb - 41 * s), 1.6 * s, Color("#d4af37"))
	var mh := 78.0 * s
	if minarets >= 2:
		_minaret(c, Vector2(p.x - w / 2 - 4 * s, p.y), mh, s, col.lightened(0.05))
		_minaret(c, Vector2(p.x + w / 2 + 4 * s, p.y), mh, s, col.lightened(0.05))
	if minarets >= 4:
		_minaret(c, Vector2(p.x - w / 2 + 6 * s, p.y - 18 * s), mh * 0.8, s * 0.9, col)
		_minaret(c, Vector2(p.x + w / 2 - 6 * s, p.y - 18 * s), mh * 0.8, s * 0.9, col)
	if waterfront:
		c.draw_rect(Rect2(p.x - w / 2 - 6, p.y, w + 12, 4), Color("#cfc6b5"))

func _draw_palace(c: CanvasItem, p: Vector2) -> void:
	var w := 220.0
	var h := 30.0
	var x0 := p.x - w + 30
	Art.ellipse(c, Vector2(x0 + w / 2 + 12, p.y + 3), w * 0.52, 8, Color(0.3, 0.2, 0.1, 0.15))
	c.draw_rect(Rect2(x0, p.y - h, w, h), Color("#f4efe4"))
	c.draw_rect(Rect2(x0, p.y - h - 8, w, 8), Color("#d9d2c4"))
	for i in 28:
		var wx := x0 + 4 + i * 7.7
		c.draw_rect(Rect2(wx, p.y - h + 6, 3, 9), Color("#6c829b"))
		c.draw_rect(Rect2(wx, p.y - h + 19, 3, 7), Color("#6c829b"))
		c.draw_line(Vector2(wx - 1.5, p.y - h), Vector2(wx - 1.5, p.y), Color("#e2dacb"), 1.0)
	# central hall
	c.draw_rect(Rect2(x0 + w / 2 - 26, p.y - h - 22, 52, h + 22), Color("#faf6ee"))
	_dome(c, Vector2(x0 + w / 2, p.y - h - 22), 14, Color("#b9c2cb"))
	c.draw_rect(Rect2(x0 + w / 2 - 8, p.y - 14, 16, 14), Color("#c9a24a"))
	# garden strip & gate
	c.draw_rect(Rect2(x0, p.y + 2, w, 6), Color("#7fbf6a"))
	c.draw_rect(Rect2(x0 + w - 18, p.y - 26, 16, 26), Color("#efe7d6"))
	c.draw_rect(Rect2(x0 + w - 14, p.y - 16, 8, 16), Color("#c9a24a"))

func _draw_galata(c: CanvasItem, p: Vector2) -> void:
	var w := 24.0
	var h := 76.0
	Art.ellipse(c, p + Vector2(14, 3), 22, 7, Color(0.3, 0.2, 0.1, 0.2))
	c.draw_rect(Rect2(p.x - w / 2, p.y - h, w, h), Color("#dccbaa"))
	c.draw_rect(Rect2(p.x + 2, p.y - h, w / 2 - 2, h), Color("#c4b18e"))
	for j in 5:
		for i in 3:
			c.draw_rect(Rect2(p.x - 8 + i * 6, p.y - h + 14 + j * 12, 2.5, 5), Color("#5d4d3a"))
	c.draw_rect(Rect2(p.x - w / 2 - 3, p.y - h - 4, w + 6, 6), Color("#b49f7c"))
	for i in 6:
		c.draw_rect(Rect2(p.x - w / 2 - 2 + i * 5, p.y - h - 11, 2, 7), Color("#8a7a60"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(p.x - w / 2 - 2, p.y - h - 11), Vector2(p.x + w / 2 + 2, p.y - h - 11), Vector2(p.x, p.y - h - 42)]), Color("#647b91"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(p.x, p.y - h - 11), Vector2(p.x + w / 2 + 2, p.y - h - 11), Vector2(p.x, p.y - h - 42)]), Color("#506579"))

func _draw_camlica(c: CanvasItem, p: Vector2) -> void:
	# green hill
	Art.ellipse(c, p + Vector2(0, -10), 125, 70, Color("#8cc77a"), 32)
	Art.ellipse(c, p + Vector2(-20, -24), 90, 46, Color("#9fd38b"), 32)
	for i in 14:
		var a := TAU * i / 14.0
		_draw_tree(c, p + Vector2(cos(a) * 100, -10 + sin(a) * 52), 7, i % 3)
	# TV tower
	var tx := p.x + 70
	c.draw_rect(Rect2(tx - 3, p.y - 140, 6, 120), Color("#dfe4ea"))
	c.draw_rect(Rect2(tx - 9, p.y - 110, 18, 10), Color("#aab4c0"))
	c.draw_rect(Rect2(tx - 7, p.y - 128, 14, 6), Color("#aab4c0"))
	c.draw_line(Vector2(tx, p.y - 140), Vector2(tx, p.y - 175), Color("#e8434b"), 2.0)
	_draw_mosque(c, p + Vector2(-30, -8), 0.95, Color("#f1ece2"), 4, false)

func _draw_selimiye(c: CanvasItem, p: Vector2) -> void:
	var w := 180.0
	var h := 26.0
	Art.ellipse(c, p + Vector2(10, 3), w * 0.55, 8, Color(0.3, 0.2, 0.1, 0.16))
	c.draw_rect(Rect2(p.x - w / 2, p.y - h - 50, w, 50), Color("#d8c49c"))
	c.draw_rect(Rect2(p.x - w / 2 + 14, p.y - h - 40, w - 28, 34), Color("#a8c98a"))
	c.draw_rect(Rect2(p.x - w / 2, p.y - h, w, h), Color("#e8d8b4"))
	for i in 22:
		c.draw_rect(Rect2(p.x - w / 2 + 6 + i * 7.8, p.y - h + 8, 3, 8), Color("#6a5a48"))
	for sx in [-1.0, 1.0]:
		for sy in [0.0, 1.0]:
			var tp := Vector2(p.x + sx * (w / 2 - 6), p.y - sy * 50)
			c.draw_rect(Rect2(tp.x - 9, tp.y - h - 14, 18, h + 14), Color("#efe2c4"))
			c.draw_colored_polygon(PackedVector2Array([tp + Vector2(-11, -h - 14), tp + Vector2(11, -h - 14), tp + Vector2(0, -h - 34)]), Color("#56677a"))

func _draw_station(c: CanvasItem, p: Vector2) -> void:
	var w := 96.0
	var h := 40.0
	Art.ellipse(c, p + Vector2(10, 3), w * 0.55, 8, Color(0.3, 0.2, 0.1, 0.18))
	c.draw_rect(Rect2(p.x - w / 2, p.y - h, w, h), Color("#d2b48c"))
	c.draw_rect(Rect2(p.x - w / 2, p.y - h - 10, w, 10), Color("#b5523b"))
	for j in 3:
		for i in 9:
			c.draw_rect(Rect2(p.x - w / 2 + 8 + i * 9.6, p.y - h + 5 + j * 11, 4, 7), Color("#4c5f73"))
	for sx in [-1.0, 1.0]:
		var tp := Vector2(p.x + sx * (w / 2 - 4), p.y)
		c.draw_rect(Rect2(tp.x - 9, tp.y - h - 16, 18, h + 16), Color("#c9a77c"))
		c.draw_colored_polygon(PackedVector2Array([tp + Vector2(-11, -h - 16), tp + Vector2(11, -h - 16), tp + Vector2(0, -h - 40)]), Color("#4e5d6e"))

func _draw_park(c: CanvasItem, p: Vector2) -> void:
	Art.ellipse(c, p, 110, 52, Color("#9fd08a"), 32)
	Art.ellipse(c, p + Vector2(-8, -6), 96, 42, Color("#aedb98"), 32)
	c.draw_arc(p, 60, 0.3, 2.6, 16, Color("#e9dcc0"), 4.0, true)
	var r := RandomNumberGenerator.new()
	r.seed = int(p.x * 7 + p.y)
	for i in 26:
		var a := r.randf() * TAU
		var d := sqrt(r.randf())
		_draw_tree(c, p + Vector2(cos(a) * 92 * d, sin(a) * 40 * d), r.randf_range(6, 11), r.randi() % 3)

func _draw_terminal(c: CanvasItem, it: Dictionary) -> void:
	var p: Vector2 = it.p
	var col: Color = it.col
	var w := 64.0
	var h := 26.0
	Art.ellipse(c, p + Vector2(10, 4), 40, 8, Color(0.3, 0.2, 0.1, 0.2))
	c.draw_rect(Rect2(p.x - w / 2, p.y - h, w, h), Color("#f3ead8"))
	c.draw_rect(Rect2(p.x - w / 2, p.y - h, w, 4), col)
	for i in 6:
		var ax := p.x - w / 2 + 7 + i * 10.0
		c.draw_rect(Rect2(ax, p.y - h + 9, 5, 10), Color("#5d7590"))
		c.draw_circle(Vector2(ax + 2.5, p.y - h + 9), 2.5, Color("#5d7590"))
	# hipped roof
	c.draw_colored_polygon(PackedVector2Array([Vector2(p.x - w / 2 - 4, p.y - h), Vector2(p.x + w / 2 + 4, p.y - h), Vector2(p.x + w / 2 - 10, p.y - h - 16), Vector2(p.x - w / 2 + 10, p.y - h - 16)]), Color("#5b6b62"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(p.x - w / 2 + 10, p.y - h - 16), Vector2(p.x + w / 2 - 10, p.y - h - 16), Vector2(p.x + w / 2 - 14, p.y - h - 20), Vector2(p.x - w / 2 + 14, p.y - h - 20)]), Color("#6d7f75"))
	# clock
	c.draw_circle(Vector2(p.x, p.y - h - 8), 4.5, Color("#fdf8ea"))
	c.draw_arc(Vector2(p.x, p.y - h - 8), 4.5, 0, TAU, 14, Color("#3a3a3a"), 1.0, true)
	c.draw_line(Vector2(p.x, p.y - h - 8), Vector2(p.x, p.y - h - 11), Color("#3a3a3a"), 1.0)
	c.draw_line(Vector2(p.x, p.y - h - 8), Vector2(p.x + 2, p.y - h - 8), Color("#3a3a3a"), 1.0)

func _draw_maiden(c: CanvasItem, p: Vector2) -> void:
	Art.ellipse(c, p + Vector2(6, 8), 34, 26, Color(0.02, 0.12, 0.22, 0.25), 24)
	Art.ellipse(c, p, 32, 25, Color("#b9a98c"), 24)
	Art.ellipse(c, p + Vector2(-2, -3), 27, 20, Color("#d8c9aa"), 24)
	for i in 9:
		var a := TAU * i / 9.0 + 0.3
		var tex: Texture2D = rocks[i % 3]
		var sz := tex.get_size() * 0.16
		c.draw_set_transform(p + Vector2(cos(a) * 30, sin(a) * 23), a, Vector2.ONE)
		c.draw_texture_rect(tex, Rect2(-sz / 2, sz), false)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)
	# small building and the tower
	c.draw_rect(Rect2(p.x - 18, p.y - 16, 30, 16), Color("#f4efe4"))
	c.draw_rect(Rect2(p.x - 18, p.y - 20, 30, 4), Color("#a8b3bd"))
	c.draw_rect(Rect2(p.x - 4, p.y - 52, 12, 46), Color("#f7f3ea"))
	c.draw_rect(Rect2(p.x + 3, p.y - 52, 5, 46), Color("#e3dccd"))
	c.draw_rect(Rect2(p.x - 6, p.y - 54, 16, 4), Color("#cfc6b4"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(p.x - 6, p.y - 54), Vector2(p.x + 10, p.y - 54), Vector2(p.x + 2, p.y - 70)]), Color("#7d8b99"))
	for j in 3:
		c.draw_rect(Rect2(p.x, p.y - 46 + j * 12, 3, 5), Color("#5d7590"))
