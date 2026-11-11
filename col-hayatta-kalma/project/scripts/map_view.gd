## Full-screen map with fog of war, discovered points of interest and up to 3 markers.
extends Control

const RES := 150                       # fog/map pixels per side (4 m each)
var game: Node
var tex: ImageTexture
var map_rect := Rect2()
var rects := {}

func setup(g: Node) -> void:
	game = g
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

func open() -> void:
	var img := Image.create(RES, RES, false, Image.FORMAT_RGB8)
	var base: Image = game.map_base
	var paper := Color("#d9c39a")
	for j in RES:
		for i in RES:
			var seen: bool = game.fog[j * RES + i] > 0
			var c: Color = base.get_pixel(i, j)
			img.set_pixel(i, j, c if seen else paper.darkened(0.05 + 0.04 * float((i * 7 + j * 13) % 5) / 5.0))
	tex = ImageTexture.create_from_image(img)
	visible = true
	queue_redraw()

func _gui_input(ev: InputEvent) -> void:
	var p := Vector2.INF
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		p = ev.position
	elif ev is InputEventScreenTouch and ev.pressed:
		p = ev.position
	if p == Vector2.INF:
		return
	accept_event()
	if rects.has("close") and rects.close.has_point(p):
		game.close_panels()
		return
	if map_rect.has_point(p):
		var w := _to_world(p)
		game.toggle_marker(w)
		queue_redraw()

func _to_world(p: Vector2) -> Vector2:
	var f := (p - map_rect.position) / map_rect.size
	return Vector2(-WorldGen.HALF + f.x * 2 * WorldGen.HALF, -WorldGen.HALF + f.y * 2 * WorldGen.HALF)

func _to_map(w: Vector2) -> Vector2:
	return map_rect.position + (w + Vector2.ONE * WorldGen.HALF) / (2 * WorldGen.HALF) * map_rect.size

func _process(_dt: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.08, 0.04, 0.02, 0.6))
	var side := minf(vs.x - 40, vs.y - 190)
	map_rect = Rect2(Vector2((vs.x - side) / 2, 70), Vector2(side, side))
	draw_style_box(UiKit.tex_box("panel_brown", 16), map_rect.grow(18))
	if tex:
		draw_texture_rect(tex, map_rect, false)
	var f := UiKit.head_font
	_t(Vector2(vs.x / 2, 52), "Harita", 30, Color("#fff4dc"))
	# discovered points of interest
	for poi in game.known_pois():
		var mp := _to_map(poi.p)
		draw_circle(mp, 7, poi.col)
		draw_arc(mp, 7, 0, TAU, 16, Color("#3a2414"), 2.0)
		_t(mp + Vector2(0, -11), poi.name, 14, Color.WHITE)
	# caravan estimate (pilot's note) if not yet found
	if not game.discovered.get("caravan", false):
		var dir: Vector2 = game.g.caravan.normalized()
		var edge := _to_map(dir * (WorldGen.HALF - 14))
		draw_circle(edge, 9, Color(0.2, 0.6, 0.3, 0.8))
		_t(edge + Vector2(0, -14), "Kervansaray? (tahmini)", 14, Color("#d8ffd8"))
	for m in game.markers:
		var mp2 := _to_map(m)
		draw_colored_polygon(PackedVector2Array([mp2, mp2 + Vector2(-7, -16), mp2 + Vector2(7, -16)]), Color("#e5383b"))
		draw_circle(mp2 + Vector2(0, -17), 7, Color("#e5383b"))
		draw_circle(mp2 + Vector2(0, -17), 3, Color.WHITE)
	# player arrow
	var pp := _to_map(game.player.pos)
	var fwd: Vector2 = game.player.forward()
	var side_v := fwd.orthogonal()
	var tri := PackedVector2Array([pp + fwd * 12, pp - fwd * 7 + side_v * 7, pp - fwd * 7 - side_v * 7])
	draw_colored_polygon(tri, Color("#ffcf40"))
	draw_polyline(tri + PackedVector2Array([tri[0]]), Color("#3a2414"), 2.0)
	# north
	_t(map_rect.position + Vector2(18, 26), "Kuzey", 18, Color("#3a2414"), 0)
	var info := "Haritaya dokunarak işaret koy/kaldır (en fazla 3). Keşfedilen: %%%d" % game.explored_pct()
	_t(Vector2(vs.x / 2, map_rect.end.y + 42), info, 16, Color("#fff4dc"))
	var cr := Rect2(Vector2(vs.x / 2 - 70, map_rect.end.y + 52), Vector2(140, 44))
	if cr.end.y > vs.y - 4:
		cr.position.y = vs.y - 50
	draw_style_box(UiKit.tex_box("button_brown", 12), cr)
	_t(cr.get_center() + Vector2(0, 8), "Kapat", 22, Color("#fff4dc"))
	rects["close"] = cr
	rects["mapview"] = map_rect

func _t(p: Vector2, s: String, size: int, col: Color, outline := 5) -> void:
	var f := UiKit.head_font
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if outline > 0:
		draw_string_outline(f, p - Vector2(w / 2, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(0.17, 0.09, 0.03, 0.9))
	draw_string(f, p - Vector2(w / 2, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
