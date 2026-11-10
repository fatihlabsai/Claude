## Procedural vector art (original work for this project): ferries, ships,
## seagulls, simit, people, flags. Everything is drawn with CanvasItem calls so
## it stays crisp at any zoom level.
class_name Art
extends RefCounted

const NAVY := Color("#1d3557")
const SHADOW := Color(0.02, 0.12, 0.22, 0.28)

static var _hull_cache := {}

static func hull_points(L: float, B: float, bow: float, stern_r: float) -> PackedVector2Array:
	var key := "%d_%d_%d_%d" % [int(L * 10), int(B * 10), int(bow * 10), int(stern_r * 10)]
	if _hull_cache.has(key):
		return _hull_cache[key]
	var pts := PackedVector2Array()
	var hb := B / 2.0
	var xs := L / 2.0 - bow
	var tip := Vector2(L / 2.0, 0)
	var n := 10
	# starboard side bow curve (y < 0 is port in our local frame, doesn't matter)
	for i in range(n + 1):
		var t := float(i) / n
		pts.append(_qbez(Vector2(xs, -hb), Vector2(L / 2.0 - bow * 0.08, -hb * 0.95), tip, t))
	for i in range(1, n + 1):
		var t := float(i) / n
		pts.append(_qbez(tip, Vector2(L / 2.0 - bow * 0.08, hb * 0.95), Vector2(xs, hb), t))
	# stern with rounded corners
	var sx := -L / 2.0
	for i in range(n + 1):
		var a := PI / 2.0 + (PI / 2.0) * float(i) / n
		pts.append(Vector2(sx + stern_r, hb - stern_r) + Vector2(cos(a), sin(a)) * stern_r)
	for i in range(n + 1):
		var a := PI + (PI / 2.0) * float(i) / n
		pts.append(Vector2(sx + stern_r, -hb + stern_r) + Vector2(cos(a), sin(a)) * stern_r)
	_hull_cache[key] = pts
	return pts

static func _qbez(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)

static func scaled(pts: PackedVector2Array, sx: float, sy: float, off := Vector2.ZERO) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	for i in pts.size():
		out[i] = Vector2(pts[i].x * sx, pts[i].y * sy) + off
	return out

static func closed(pts: PackedVector2Array) -> PackedVector2Array:
	var p := pts.duplicate()
	p.append(pts[0])
	return p

static func rrect(c: CanvasItem, r: Rect2, rad: float, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(rad))
	sb.anti_aliasing = true
	c.draw_style_box(sb, r)

static func ellipse(c: CanvasItem, center: Vector2, rx: float, ry: float, col: Color, seg := 20) -> void:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * i / seg
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	c.draw_colored_polygon(pts, col)

## Shadow cast on the water by a hull (drawn first, under everything).
static func hull_shadow(c: CanvasItem, pos: Vector2, ang: float, L: float, B: float, bow: float, stern_r: float, off: Vector2, alpha := 1.0) -> void:
	c.draw_set_transform(pos + off, ang, Vector2.ONE)
	var col := SHADOW
	col.a *= alpha
	c.draw_colored_polygon(hull_points(L * 1.02, B * 1.08, bow, stern_r), col)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

## Istanbul city-line ferry (Şehir Hatları style), top-down, facing +x.
static func draw_vapur(c: CanvasItem, pos: Vector2, ang: float, t: float, o: Dictionary) -> void:
	var L := 76.0
	var B := 26.0
	var hull_col: Color = o.get("hull", Color("#fbfbf8"))
	var band: Color = o.get("band", Color("#e8434b"))
	var cabin: Color = o.get("cabin", Color("#f5f8fb"))
	var funnel: Color = o.get("funnel", Color("#ffcf33"))
	var roll: float = o.get("roll", 0.0)
	var alpha: float = o.get("alpha", 1.0)
	var pax: Array = o.get("pax", [])
	var mod := Color(1, 1, 1, alpha)
	if o.get("blink", false):
		mod = Color(1, 0.55, 0.55, alpha * 0.55)
	var hull := hull_points(L, B, 16, 7)
	c.draw_set_transform(pos, ang, Vector2.ONE)
	# hull layers
	c.draw_colored_polygon(scaled(hull, 1.04, 1.1), NAVY * mod)
	c.draw_colored_polygon(hull, hull_col * mod)
	c.draw_colored_polygon(scaled(hull, 0.97, 0.78), band * mod)
	c.draw_colored_polygon(scaled(hull, 0.93, 0.66), Color("#e7d3a8") * mod)
	# deck planks
	for i in range(-30, 32, 4):
		c.draw_line(Vector2(i, -7.5), Vector2(i, 7.5), Color(0.6, 0.45, 0.25, 0.18 * alpha), 1.0)
	# superstructure with a little parallax roll for a 3D feel
	var lift := Vector2(0, roll)
	var cab_r := Rect2(Vector2(-25, -9.5) + lift * 3.0, Vector2(44, 19))
	rrect(c, Rect2(cab_r.position + Vector2(1.5, 2.0), cab_r.size), 5, Color(0, 0, 0, 0.18 * alpha))
	rrect(c, cab_r, 5, cabin * mod)
	rrect(c, cab_r.grow(-2.5), 4, cabin.lightened(0.35) * mod)
	# windows on both sides
	for i in 8:
		var wx := -22.0 + i * 5.0
		c.draw_rect(Rect2(Vector2(wx, -9.2) + lift * 3.0, Vector2(3, 1.6)), Color("#26476e") * mod)
		c.draw_rect(Rect2(Vector2(wx, 7.6) + lift * 3.0, Vector2(3, 1.6)), Color("#26476e") * mod)
	# life rafts
	for rx in [-19.0, -9.0, 5.0]:
		rrect(c, Rect2(Vector2(rx, -6.5) + lift * 4.0, Vector2(6, 2.6)), 1.3, Color("#ff7a1a") * mod)
		rrect(c, Rect2(Vector2(rx, 3.9) + lift * 4.0, Vector2(6, 2.6)), 1.3, Color("#ff7a1a") * mod)
	# wheelhouse
	var wh := Rect2(Vector2(12, -7.5) + lift * 5.0, Vector2(9, 15))
	rrect(c, wh, 3, Color("#eef2f6") * mod)
	c.draw_rect(Rect2(wh.position + Vector2(6.5, 1.5), Vector2(1.8, 12)), Color("#1f3b5c") * mod)
	# funnel (yellow with black top, Şehir Hatları style)
	var fp := Vector2(-3, 0) + lift * 7.0
	ellipse(c, fp + Vector2(1.5, 2), 6.2, 5.0, Color(0, 0, 0, 0.2 * alpha))
	ellipse(c, fp, 6.2, 5.0, funnel * mod)
	ellipse(c, fp, 3.8, 3.0, Color("#222222") * mod)
	ellipse(c, fp + Vector2(-2.2, -1.8), 1.6, 1.0, Color(1, 1, 1, 0.45 * alpha))
	# passengers on the aft and bow decks
	var seats := [Vector2(-33, -5), Vector2(-33, 0), Vector2(-33, 5), Vector2(-29, -5), Vector2(-29, 0), Vector2(-29, 5), Vector2(25, -3), Vector2(25, 3)]
	for i in mini(pax.size(), seats.size()):
		var q: Dictionary = pax[i]
		var sp: Vector2 = seats[i]
		c.draw_circle(sp, 2.3, (q.get("col", Color.WHITE) as Color) * mod)
		c.draw_circle(sp + Vector2(0.3, -0.4), 1.1, (q.get("skin", Color("#f3c9a5")) as Color) * mod)
	# bow mooring & anchor marks
	c.draw_circle(Vector2(31, 0), 1.6, Color("#555555") * mod)
	# stern flag
	draw_flag(c, Vector2(-38.5, 0) + lift * 6.0, 0.55, t, ang, mod.a)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

## Tanker or container ship, facing +x. s is a Dictionary with ship data.
static func draw_ship(c: CanvasItem, s, t: float) -> void:
	var L: float = s.L
	var B: float = s.B
	var hull := hull_points(L, B, L * 0.2, 9)
	c.draw_set_transform(Vector2(s.x, s.y), s.ang, Vector2.ONE)
	var hc: Color = s.hull
	c.draw_colored_polygon(scaled(hull, 1.02, 1.08), hc.darkened(0.45))
	c.draw_colored_polygon(hull, hc)
	c.draw_colored_polygon(scaled(hull, 0.95, 0.8), s.deck)
	var roll := sin(t * 1.1 + s.x * 0.01) * 0.6
	var lift := Vector2(0, roll)
	if s.kind == "tanker":
		# pipelines, manifolds and tank hatches
		c.draw_line(Vector2(-L / 2 + 40, -3), Vector2(L / 2 - 30, -3), Color("#d8d8d0"), 2.0)
		c.draw_line(Vector2(-L / 2 + 40, 3), Vector2(L / 2 - 30, 3), Color("#c0c0b8"), 1.5)
		var n := int((L - 80) / 26)
		for i in n:
			var hx := -L / 2 + 52 + i * 26.0
			c.draw_circle(Vector2(hx, -B * 0.24), 4.0, Color(0, 0, 0, 0.18))
			c.draw_circle(Vector2(hx, -B * 0.24), 3.2, Color("#efe6d6"))
			c.draw_circle(Vector2(hx, B * 0.24), 4.0, Color(0, 0, 0, 0.18))
			c.draw_circle(Vector2(hx, B * 0.24), 3.2, Color("#efe6d6"))
			c.draw_line(Vector2(hx, -B * 0.3), Vector2(hx, B * 0.3), Color(0, 0, 0, 0.12), 1.0)
		# bow mast
		c.draw_circle(Vector2(L / 2 - 26, 0), 2.5, Color("#f5f5f5"))
	else:
		var boxes: Array = s.boxes
		var x0 := -L / 2 + 40
		var x1 := L / 2 - 28
		var cols := int((x1 - x0) / 13)
		var bi := 0
		for i in cols:
			for r in 3:
				var bw := 12.0
				var bh := (B - 12) / 3.0
				var bx := x0 + i * 13.0
				var by := -B / 2 + 6 + r * bh
				var h := 1 + (i * 7 + r * 3) % 3
				if (i * 5 + r) % 11 == 0:
					continue
				var col: Color = boxes[bi % boxes.size()]
				bi += 1
				c.draw_rect(Rect2(bx + 1.5, by + 1.5, bw - 1, bh - 1), Color(0, 0, 0, 0.25))
				c.draw_rect(Rect2(Vector2(bx, by) + lift * h, Vector2(bw - 1, bh - 1)), col)
				c.draw_line(Vector2(bx + 2, by + 1) + lift * h, Vector2(bx + 2, by + bh - 2) + lift * h, col.lightened(0.3), 1.0)
				c.draw_line(Vector2(bx + 6, by + 1) + lift * h, Vector2(bx + 6, by + bh - 2) + lift * h, col.darkened(0.2), 1.0)
	# aft superstructure
	var sr := Rect2(Vector2(-L / 2 + 8, -B / 2 + 5) + lift * 6, Vector2(26, B - 10))
	rrect(c, Rect2(sr.position + Vector2(3, 4), sr.size), 3, Color(0, 0, 0, 0.25))
	rrect(c, sr, 3, Color("#f4f4f0"))
	rrect(c, sr.grow(-3), 2, Color("#ffffff"))
	c.draw_rect(Rect2(sr.position + Vector2(sr.size.x - 4, 2), Vector2(2.2, sr.size.y - 4)), Color("#22384f"))
	var fp := Vector2(-L / 2 + 15, 0) + lift * 10
	rrect(c, Rect2(fp - Vector2(5, 6) + Vector2(2, 3), Vector2(10, 12)), 3, Color(0, 0, 0, 0.25))
	rrect(c, Rect2(fp - Vector2(5, 6), Vector2(10, 12)), 3, s.funnel)
	rrect(c, Rect2(fp - Vector2(3, 4), Vector2(6, 8)), 2, Color("#2a2a2a"))
	# navigation lights
	var blink := 0.5 + 0.5 * sin(t * 4 + s.x)
	c.draw_circle(Vector2(L / 2 - 8, -B / 2 + 4), 1.8, Color(1, 0.2, 0.2, 0.5 + blink * 0.5))
	c.draw_circle(Vector2(L / 2 - 8, B / 2 - 4), 1.8, Color(0.2, 1, 0.4, 0.5 + blink * 0.5))
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

## Rowboat (kayık): Kenney dinghy sprite + an original rower and oars.
static func draw_kayik(c: CanvasItem, k, t: float, tex: Texture2D) -> void:
	c.draw_set_transform(Vector2(k.x, k.y), k.ang + PI / 2, Vector2.ONE)
	var sz := Vector2(17, 33)
	c.draw_texture_rect(tex, Rect2(-sz / 2, sz), false, Color(1, 1, 1).lerp(k.col, 0.35))
	var stroke := sin(t * 4.0 + k.ph)
	var oc := Color("#7a5230")
	for sg in [-1.0, 1.0]:
		var base := Vector2(sg * 5, 1)
		var tip := base + Vector2(sg * 11, 3 + stroke * 5).rotated(0)
		c.draw_line(base, tip, oc, 1.6, true)
		c.draw_circle(tip, 1.6, oc)
	c.draw_circle(Vector2(0, 2), 4.0, Color(0, 0, 0, 0.2))
	c.draw_circle(Vector2(0, 1), 3.4, k.skin)
	c.draw_circle(Vector2(0, 0.5), 2.6, k.hat)
	if k.rod:
		c.draw_line(Vector2(2, -2), Vector2(14, -16), Color("#3a3a3a"), 1.0, true)
		c.draw_line(Vector2(14, -16), Vector2(16, -8 + stroke), Color(1, 1, 1, 0.6), 0.8, true)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

## Seagull (martı) flapping, with its shadow on the water.
static func draw_gull(c: CanvasItem, g, t: float) -> void:
	var a := atan2(g.vy, g.vx)
	var h: float = g.h
	var flap := sin(t * (8.5 if g.state != "happy" else 13.0) + g.ph)
	var span := 13.0 * h * (0.55 + 0.45 * absf(flap))
	var pos := Vector2(g.x, g.y)
	# shadow
	c.draw_set_transform(pos + Vector2(10, 16) * h, a, Vector2.ONE)
	var sh := Color(0.02, 0.12, 0.22, 0.18)
	c.draw_colored_polygon(PackedVector2Array([Vector2(4 * h, 0), Vector2(-2 * h, -span), Vector2(-5 * h, -span * 0.9), Vector2(-6 * h, 0), Vector2(-5 * h, span * 0.9), Vector2(-2 * h, span)]), sh)
	# wings
	c.draw_set_transform(pos, a, Vector2.ONE)
	var wing_back := -4.0 * h - flap * 2.0 * h
	for sg in [-1.0, 1.0]:
		var w := PackedVector2Array([Vector2(3 * h, sg * 1.5 * h), Vector2(0, sg * span * 0.55), Vector2(wing_back, sg * span), Vector2(-4 * h, sg * span * 0.8), Vector2(-3 * h, sg * 1.5 * h)])
		c.draw_colored_polygon(w, Color("#c9d1da"))
		c.draw_colored_polygon(PackedVector2Array([Vector2(0, sg * span * 0.55), Vector2(wing_back, sg * span), Vector2(-2.5 * h, sg * span * 0.7)]), Color("#e3e8ee"))
		c.draw_colored_polygon(PackedVector2Array([Vector2(wing_back - 0.5 * h, sg * span), Vector2(-4 * h, sg * span * 0.8), Vector2(wing_back + 0.8 * h, sg * span * 0.82)]), Color("#2b2b2b"))
	# body, tail and head
	ellipse(c, Vector2(-0.5 * h, 0), 6.5 * h, 2.6 * h, Color("#ffffff"), 14)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-5 * h, -1.8 * h), Vector2(-9.5 * h, -2.2 * h), Vector2(-9.5 * h, 2.2 * h), Vector2(-5 * h, 1.8 * h)]), Color("#f2f4f6"))
	c.draw_circle(Vector2(5 * h, 0), 2.4 * h, Color("#ffffff"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(6.8 * h, -0.8 * h), Vector2(9.8 * h, 0), Vector2(6.8 * h, 0.8 * h)]), Color("#ffb21a"))
	c.draw_circle(Vector2(5.6 * h, -1.2 * h), 0.55 * h, Color("#222222"))
	c.draw_circle(Vector2(5.6 * h, 1.2 * h), 0.55 * h, Color("#222222"))
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

## Simit: a sesame-covered bread ring.
static func draw_simit(c: CanvasItem, pos: Vector2, r: float, rot: float, alpha := 1.0) -> void:
	var m := Color(1, 1, 1, alpha)
	c.draw_arc(pos, r * 0.66, 0, TAU, 24, Color("#9a5a22") * m, r * 0.72, true)
	c.draw_arc(pos, r * 0.66, 0, TAU, 24, Color("#c98039") * m, r * 0.56, true)
	c.draw_arc(pos, r * 0.7, rot + PI * 1.05, rot + PI * 1.7, 10, Color("#f0b46a") * m, r * 0.2, true)
	for i in 9:
		var a := rot + TAU * i / 9.0 + (0.25 if i % 2 == 0 else 0.0)
		var rr := r * (0.5 + 0.3 * float(i % 3) / 2.0)
		c.draw_circle(pos + Vector2(cos(a), sin(a)) * rr, maxf(0.45, r * 0.09), Color("#fff1cf") * m)

## Small waving Turkish flag. `base_ang` keeps it streaming away from travel direction.
static func draw_flag(c: CanvasItem, pos: Vector2, s: float, t: float, base_ang := 0.0, alpha := 1.0) -> void:
	var pts := PackedVector2Array()
	var n := 6
	var w := 14.0 * s
	var hgt := 9.0 * s
	for i in range(n + 1):
		var u := float(i) / n
		pts.append(pos + Vector2(-u * w, -hgt / 2 + sin(t * 7.0 - u * 4.0) * 1.4 * s * u))
	for i in range(n, -1, -1):
		var u := float(i) / n
		pts.append(pos + Vector2(-u * w, hgt / 2 + sin(t * 7.0 - u * 4.0) * 1.4 * s * u))
	c.draw_colored_polygon(pts, Color(0.89, 0.04, 0.09, alpha))
	var mid := pos + Vector2(-w * 0.42, sin(t * 7.0 - 1.7) * 0.6 * s)
	c.draw_circle(mid, hgt * 0.28, Color(1, 1, 1, alpha))
	c.draw_circle(mid + Vector2(-hgt * 0.07, 0), hgt * 0.23, Color(0.89, 0.04, 0.09, alpha))
	c.draw_circle(mid + Vector2(-hgt * 0.3, 0), hgt * 0.08, Color(1, 1, 1, alpha))

## Upright pole flag used on land (3/4 view).
static func draw_pole_flag(c: CanvasItem, pos: Vector2, s: float, t: float) -> void:
	c.draw_line(pos, pos + Vector2(0, -26 * s), Color("#d9d9d9"), 1.6 * s, true)
	var top := pos + Vector2(0, -26 * s)
	var pts := PackedVector2Array()
	var n := 7
	var w := 16.0 * s
	var hgt := 10.0 * s
	for i in range(n + 1):
		var u := float(i) / n
		pts.append(top + Vector2(u * w, sin(t * 6.0 - u * 5.0) * 1.6 * s * u))
	for i in range(n, -1, -1):
		var u := float(i) / n
		pts.append(top + Vector2(u * w, hgt + sin(t * 6.0 - u * 5.0) * 1.6 * s * u))
	c.draw_colored_polygon(pts, Color("#e30a17"))
	var mid := top + Vector2(w * 0.38, hgt / 2 + sin(t * 6.0 - 1.9) * 0.8 * s)
	c.draw_circle(mid, hgt * 0.27, Color.WHITE)
	c.draw_circle(mid + Vector2(hgt * 0.07, 0), hgt * 0.22, Color("#e30a17"))
	c.draw_circle(mid + Vector2(hgt * 0.3, 0), hgt * 0.07, Color.WHITE)

## Waiting passenger (3/4 view) with a patience ring.
static func draw_person(c: CanvasItem, pos: Vector2, col: Color, skin: Color, hair: Color, alpha: float, bob: float) -> void:
	var m := Color(1, 1, 1, alpha)
	ellipse(c, pos + Vector2(0, 5), 5, 2.2, Color(0, 0, 0, 0.22 * alpha), 12)
	rrect(c, Rect2(pos + Vector2(-4, -6 + bob), Vector2(8, 10)), 3.5, col * m)
	c.draw_rect(Rect2(pos + Vector2(-4, -1 + bob), Vector2(8, 1.4)), col.darkened(0.25) * m)
	c.draw_circle(pos + Vector2(0, -9 + bob), 3.6, skin * m)
	c.draw_arc(pos + Vector2(0, -9.5 + bob), 3.4, PI * 1.05, PI * 1.95, 8, hair * m, 2.4, true)
