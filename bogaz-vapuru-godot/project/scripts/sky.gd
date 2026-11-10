## Northern horizon: sky gradient (shader) and three parallax layers of
## silhouettes — distant hills, the city with mosques and the Fatih Sultan
## Mehmet bridge, and the wooded shores with Rumeli Hisarı. Original art.
extends Node2D

const H := -40.0
var main: Node
var sky_rect: Node2D
var layers: Array = []   # [node, factor]
var rng := RandomNumberGenerator.new()
var city: Array = []
var hills_far := PackedVector2Array()
var hills_near_l := PackedVector2Array()
var hills_near_r := PackedVector2Array()

func _ready() -> void:
	rng.seed = 1453
	sky_rect = _cb(func(c): c.draw_rect(Rect2(-1200, -900, 3800, 900 + H), Color.WHITE))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/sky.gdshader")
	mat.set_shader_parameter("noise_tex", main.noise_tex)
	sky_rect.material = mat
	_gen()
	layers.append([_cb(_draw_far), 0.25])
	layers.append([_cb(_draw_city), 0.5])
	layers.append([_cb(_draw_near), 0.78])
	_cb(_draw_haze)

func _cb(f: Callable) -> Node2D:
	var n := Node2D.new()
	n.set_script(load("res://scripts/draw_cb.gd"))
	n.fn = f
	add_child(n)
	return n

func _gen() -> void:
	var x := -1200.0
	while x <= 2600:
		hills_far.append(Vector2(x, H - 46 - 22 * sin(x * 0.0042) - 12 * sin(x * 0.013 + 1.0) - 6 * sin(x * 0.04)))
		x += 30
	hills_far.append(Vector2(2600, H + 2))
	hills_far.append(Vector2(-1200, H + 2))
	# city skyline blocks and landmarks
	x = -1200.0
	while x < 2600:
		var w := rng.randf_range(10, 28)
		var h := rng.randf_range(6, 22)
		if absf(x - 700) < 230:
			h *= 0.45
		city.append({"t": "b", "x": x, "w": w, "h": h})
		x += w + rng.randf_range(-2, 4)
	for mx in [-260.0, 120.0, 330.0, 1060.0, 1380.0, 1700.0]:
		city.append({"t": "m", "x": mx, "s": rng.randf_range(0.7, 1.1)})
	city.append({"t": "tower", "x": 1540.0})
	for side in [-1.0, 1.0]:
		var pts := PackedVector2Array()
		var x0 := -1200.0 if side < 0 else 1090.0
		var x1 := 310.0 if side < 0 else 2600.0
		x = x0
		while x <= x1:
			var edge := 1.0 - clampf((x - (x1 - 140)) / 140.0, 0, 1) if side < 0 else clampf((x - x0) / 140.0, 0, 1)
			pts.append(Vector2(x, H - edge * (30 + 14 * sin(x * 0.02) + 6 * sin(x * 0.07))))
			x += 12
		pts.append(Vector2(x1, H + 2))
		pts.append(Vector2(x0, H + 2))
		if side < 0:
			hills_near_l = pts
		else:
			hills_near_r = pts

func _tint(day: Color, dusk: Color) -> Color:
	return day.lerp(dusk, main.day_phase)

func _process(_dt: float) -> void:
	if not main:
		return
	for l in layers:
		l[0].position.x = (main.cam.x - 700.0) * (1.0 - l[1])
	sky_rect.material.set_shader_parameter("phase", main.day_phase)
	for c in get_children():
		c.queue_redraw()

func _draw_far(c: Node2D) -> void:
	c.draw_colored_polygon(hills_far, _tint(Color("#a9c3d8"), Color("#c9a3a8")))

func _draw_city(c: Node2D) -> void:
	var col := _tint(Color("#7f9cb8"), Color("#8a6d86"))
	var win := _tint(Color(1, 1, 1, 0.0), Color(1.0, 0.86, 0.5, 0.85))
	for b in city:
		match b.t:
			"b":
				c.draw_rect(Rect2(b.x, H - b.h, b.w, b.h + 1), col)
				if main.day_phase > 0.45 and int(b.x) % 3 == 0:
					c.draw_rect(Rect2(b.x + 3, H - b.h + 3, 2, 2), win)
			"m":
				var s: float = b.s
				var x: float = b.x
				c.draw_rect(Rect2(x - 26 * s, H - 14 * s, 52 * s, 14 * s), col)
				_dome(c, Vector2(x, H - 14 * s), 15 * s, col)
				_dome(c, Vector2(x - 18 * s, H - 14 * s), 7 * s, col)
				_dome(c, Vector2(x + 18 * s, H - 14 * s), 7 * s, col)
				for mx in [x - 32 * s, x + 32 * s]:
					c.draw_rect(Rect2(mx - 1.6 * s, H - 58 * s, 3.2 * s, 58 * s), col)
					c.draw_colored_polygon(PackedVector2Array([Vector2(mx - 2.2 * s, H - 58 * s), Vector2(mx + 2.2 * s, H - 58 * s), Vector2(mx, H - 68 * s)]), col)
			"tower":
				var x2: float = b.x
				c.draw_rect(Rect2(x2 - 2, H - 90, 4, 90), col)
				c.draw_rect(Rect2(x2 - 6, H - 70, 12, 6), col)
	# Fatih Sultan Mehmet bridge, far up the Bosphorus
	var bx0 := 470.0
	var bx1 := 930.0
	var dy := H - 22
	c.draw_rect(Rect2(bx0 - 260, dy, (bx1 - bx0) + 520, 3), col)
	for tx in [bx0, bx1]:
		c.draw_rect(Rect2(tx - 3, dy - 44, 2, 46), col)
		c.draw_rect(Rect2(tx + 1, dy - 44, 2, 46), col)
	var pts := PackedVector2Array()
	for i in 25:
		var u := i / 24.0
		pts.append(Vector2(lerpf(bx0, bx1, u), dy - 44 + 40 * 4.0 * u * (1 - u)))
	c.draw_polyline(pts, col, 1.2, true)
	c.draw_line(Vector2(bx0 - 260, dy), Vector2(bx0, dy - 44), col, 1.0, true)
	c.draw_line(Vector2(bx1, dy - 44), Vector2(bx1 + 260, dy), col, 1.0, true)

func _dome(c: Node2D, base: Vector2, r: float, col: Color) -> void:
	var p := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		p.append(base + Vector2(cos(a) * r, sin(a) * r))
	c.draw_colored_polygon(p, col)

func _draw_near(c: Node2D) -> void:
	var col := _tint(Color("#5d8a7a"), Color("#6b5a6e"))
	c.draw_colored_polygon(hills_near_l, col)
	c.draw_colored_polygon(hills_near_r, col)
	# Rumeli Hisarı towers on the European hill
	var hc := _tint(Color("#8c9a95"), Color("#7d6a78"))
	for tx in [170.0, 228.0, 280.0]:
		var hh := 30.0 if tx == 228.0 else 22.0
		c.draw_rect(Rect2(tx - 8, H - 26 - hh, 16, hh + 10), hc)
		c.draw_colored_polygon(PackedVector2Array([Vector2(tx - 10, H - 26 - hh), Vector2(tx + 10, H - 26 - hh), Vector2(tx, H - 42 - hh)]), hc.darkened(0.15))
	c.draw_rect(Rect2(170, H - 34, 110, 8), hc)
	# trees along the near shores
	for i in 30:
		var tx2 := -1150.0 + i * 50.0 if i < 30 else 0.0
		if tx2 < 300:
			c.draw_circle(Vector2(tx2, H - 24 - 8 * sin(i)), 10, col.darkened(0.12))
	for i in 30:
		var tx3 := 1110.0 + i * 50.0
		c.draw_circle(Vector2(tx3, H - 22 - 8 * sin(i * 1.3)), 10, col.darkened(0.12))

func _draw_haze(c: Node2D) -> void:
	var hz := _tint(Color(0.86, 0.94, 0.99), Color(1.0, 0.78, 0.6))
	var top := Color(hz, 0.0)
	var pts := PackedVector2Array([Vector2(-1200, H - 46), Vector2(2600, H - 46), Vector2(2600, H + 4), Vector2(-1200, H + 4)])
	c.draw_polygon(pts, PackedColorArray([top, top, Color(hz, 0.75), Color(hz, 0.75)]))
	var pts2 := PackedVector2Array([Vector2(-1200, H + 2), Vector2(2600, H + 2), Vector2(2600, H + 30), Vector2(-1200, H + 30)])
	c.draw_polygon(pts2, PackedColorArray([Color(hz, 0.55), Color(hz, 0.55), Color(hz, 0.0), Color(hz, 0.0)]))
