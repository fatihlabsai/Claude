## UI helpers: theme built from Kenney UI Pack Adventure (CC0) + Baloo 2 / Nunito fonts.
class_name UiKit
extends RefCounted

static var head_font: Font
static var body_font: Font
static var theme: Theme

const INK := Color("#3a2414")
const CREAM := Color("#fff4dc")
const SAND := Color("#f4d39b")
const ACCENT := Color("#e2683c")

static func init() -> void:
	if theme:
		return
	head_font = load("res://assets/fonts/Baloo2.ttf")
	body_font = load("res://assets/fonts/Nunito.ttf")
	theme = Theme.new()
	theme.default_font = body_font
	theme.default_font_size = 20
	var panel := tex_box("panel_brown", 16)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	var bn := tex_box("button_brown", 12); bn.content_margin_left = 18; bn.content_margin_right = 18; bn.content_margin_top = 8; bn.content_margin_bottom = 10
	var bh := bn.duplicate(); bh.modulate_color = Color(1.12, 1.08, 1.0)
	var bp := bn.duplicate(); bp.modulate_color = Color(0.85, 0.82, 0.78)
	var bd := bn.duplicate(); bd.modulate_color = Color(0.6, 0.6, 0.6, 0.8)
	theme.set_stylebox("normal", "Button", bn)
	theme.set_stylebox("hover", "Button", bh)
	theme.set_stylebox("pressed", "Button", bp)
	theme.set_stylebox("disabled", "Button", bd)
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_font("font", "Button", head_font)
	theme.set_font_size("font_size", "Button", 24)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(st, "Button", CREAM)
	theme.set_color("font_disabled_color", "Button", Color(0.85, 0.8, 0.75, 0.7))
	theme.set_color("font_outline_color", "Button", Color(0.2, 0.1, 0.05))
	theme.set_constant("outline_size", "Button", 4)
	theme.set_color("font_color", "Label", INK)
	theme.set_font("font", "Label", body_font)

static func tex_box(n: String, margin: int) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load("res://assets/ui/%s.png" % n)
	s.texture_margin_left = margin; s.texture_margin_right = margin
	s.texture_margin_top = margin; s.texture_margin_bottom = margin
	s.content_margin_left = margin + 6; s.content_margin_right = margin + 6
	s.content_margin_top = margin + 4; s.content_margin_bottom = margin + 4
	return s

static func label(text: String, size := 20, col := INK, head := false, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if head:
		l.add_theme_font_override("font", head_font)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.03, 0.9))
	return l

static func button(text: String, cb: Callable, size := 24, min_w := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	if min_w > 0:
		b.custom_minimum_size.x = min_w
	b.pressed.connect(func(): Sfx.play("click", -6.0); cb.call())
	b.focus_mode = Control.FOCUS_NONE
	return b

static func flat_box(col: Color, radius := 12, border := 0, bcol := Color.BLACK) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(radius)
	if border > 0:
		s.set_border_width_all(border)
		s.border_color = bcol
	s.content_margin_left = 10; s.content_margin_right = 10; s.content_margin_top = 6; s.content_margin_bottom = 6
	return s

## Draws small vector icons used by HUD and item slots without textures.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, r: float, col := Color.WHITE) -> void:
	var ink := Color(0.18, 0.1, 0.05)
	match kind:
		"water":
			var pts := PackedVector2Array()
			for i in 17:
				var a := PI * i / 16.0
				pts.append(c + Vector2(cos(a) * r * 0.62, sin(a) * r * 0.62 + r * 0.15))
			pts.append(c + Vector2(0, -r))
			ci.draw_colored_polygon(pts, Color("#3fb4ef"))
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), ink, 2.0, true)
			ci.draw_circle(c + Vector2(-r * 0.22, r * 0.05), r * 0.13, Color(1, 1, 1, 0.7))
		"food":
			ci.draw_circle(c + Vector2(r * 0.12, -r * 0.12), r * 0.55, Color("#c8743a"))
			ci.draw_arc(c + Vector2(r * 0.12, -r * 0.12), r * 0.55, 0, TAU, 20, ink, 2.0, true)
			ci.draw_line(c + Vector2(-r * 0.25, r * 0.25), c + Vector2(-r * 0.75, r * 0.75), Color("#f3e6cf"), r * 0.25, true)
			ci.draw_circle(c + Vector2(-r * 0.78, r * 0.62), r * 0.15, Color("#f3e6cf"))
			ci.draw_circle(c + Vector2(-r * 0.62, r * 0.78), r * 0.15, Color("#f3e6cf"))
		"temp":
			ci.draw_line(c + Vector2(0, -r * 0.8), c + Vector2(0, r * 0.3), Color.WHITE, r * 0.38, true)
			ci.draw_line(c + Vector2(0, -r * 0.5), c + Vector2(0, r * 0.3), col, r * 0.18, true)
			ci.draw_circle(c + Vector2(0, r * 0.55), r * 0.36, col)
			ci.draw_arc(c + Vector2(0, r * 0.55), r * 0.36, 0, TAU, 16, ink, 2.0, true)
		"stamina":
			var b := PackedVector2Array([c + Vector2(r * 0.2, -r), c + Vector2(-r * 0.55, r * 0.15), c + Vector2(-r * 0.05, r * 0.15), c + Vector2(-r * 0.25, r), c + Vector2(r * 0.6, -r * 0.2), c + Vector2(r * 0.08, -r * 0.2)])
			ci.draw_colored_polygon(b, Color("#ffd23f"))
			ci.draw_polyline(b + PackedVector2Array([b[0]]), ink, 2.0, true)
		"hp":
			ci.draw_circle(c + Vector2(-r * 0.33, -r * 0.2), r * 0.42, Color("#e5383b"))
			ci.draw_circle(c + Vector2(r * 0.33, -r * 0.2), r * 0.42, Color("#e5383b"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.74, -r * 0.05), c + Vector2(r * 0.74, -r * 0.05), c + Vector2(0, r * 0.8)]), Color("#e5383b"))
			ci.draw_circle(c + Vector2(-r * 0.4, -r * 0.32), r * 0.12, Color(1, 1, 1, 0.6))
		"rope":
			for k in 3:
				ci.draw_arc(c, r * (0.35 + k * 0.18), 0, TAU, 20, Color("#c9a063"), r * 0.13, true)
			ci.draw_line(c + Vector2(r * 0.65, 0), c + Vector2(r * 0.9, r * 0.6), Color("#c9a063"), r * 0.13, true)
		"bandage":
			ci.draw_set_transform(c, -0.6, Vector2.ONE)
			ci.draw_rect(Rect2(Vector2(-r * 0.85, -r * 0.3), Vector2(r * 1.7, r * 0.6)), Color("#f7f2e8"))
			ci.draw_rect(Rect2(Vector2(-r * 0.25, -r * 0.3), Vector2(r * 0.5, r * 0.6)), Color("#e8d6b8"))
			ci.draw_rect(Rect2(Vector2(-r * 0.85, -r * 0.3), Vector2(r * 1.7, r * 0.6)), ink, false, 2.0)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"antenna":
			ci.draw_line(c + Vector2(0, r * 0.8), c + Vector2(0, -r * 0.7), Color("#9aa3ad"), r * 0.14, true)
			ci.draw_circle(c + Vector2(0, -r * 0.75), r * 0.16, Color("#e5383b"))
			ci.draw_arc(c + Vector2(0, -r * 0.75), r * 0.45, -2.4, -0.7, 10, Color("#ffd23f"), 2.5, true)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.35, r * 0.55), Vector2(r * 0.7, r * 0.3)), Color("#5c636b"))
		"battery":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.4, -r * 0.65), Vector2(r * 0.8, r * 1.4)), Color("#3c4148"))
			ci.draw_rect(Rect2(c + Vector2(-r * 0.15, -r * 0.82), Vector2(r * 0.3, r * 0.18)), Color("#c9ced4"))
			ci.draw_rect(Rect2(c + Vector2(-r * 0.4, -r * 0.1), Vector2(r * 0.8, r * 0.3)), Color("#ffd23f"))
		"circuit":
			ci.draw_rect(Rect2(c - Vector2(r * 0.7, r * 0.55), Vector2(r * 1.4, r * 1.1)), Color("#2f8f4e"))
			for k in 4:
				ci.draw_line(c + Vector2(-r * 0.55, -r * 0.35 + k * r * 0.24), c + Vector2(r * 0.2, -r * 0.35 + k * r * 0.24), Color("#e7c35a"), 2.0)
			ci.draw_rect(Rect2(c + Vector2(r * 0.15, -r * 0.25), Vector2(r * 0.38, r * 0.45)), Color("#1d1d1d"))
		"bag":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.35), Vector2(r * 1.4, r * 1.1)), Color("#a8683a"))
			ci.draw_arc(c + Vector2(0, -r * 0.35), r * 0.4, PI, TAU, 12, Color("#5b3a1e"), r * 0.14, true)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.35), Vector2(r * 1.4, r * 1.1)), ink, false, 2.0)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.2, -r * 0.1), Vector2(r * 0.4, r * 0.3)), Color("#ffd23f"))
		"map":
			var pts := PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.6), c + Vector2(-r * 0.25, -r * 0.8), c + Vector2(r * 0.25, -r * 0.6), c + Vector2(r * 0.8, -r * 0.8), c + Vector2(r * 0.8, r * 0.6), c + Vector2(r * 0.25, r * 0.8), c + Vector2(-r * 0.25, r * 0.6), c + Vector2(-r * 0.8, r * 0.8)])
			ci.draw_colored_polygon(pts, Color("#f3dfb3"))
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), ink, 2.0, true)
			ci.draw_line(c + Vector2(-r * 0.4, r * 0.3), c + Vector2(r * 0.4, -r * 0.3), Color("#e5383b"), 2.5, true)
		"pause":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.5, -r * 0.6), Vector2(r * 0.35, r * 1.2)), Color.WHITE)
			ci.draw_rect(Rect2(c + Vector2(r * 0.15, -r * 0.6), Vector2(r * 0.35, r * 1.2)), Color.WHITE)
		"hand":
			ci.draw_circle(c + Vector2(0, r * 0.15), r * 0.45, Color("#ffd8a8"))
			for k in 4:
				ci.draw_line(c + Vector2(-r * 0.36 + k * r * 0.24, 0), c + Vector2(-r * 0.36 + k * r * 0.24, -r * 0.7), Color("#ffd8a8"), r * 0.2, true)
			ci.draw_line(c + Vector2(-r * 0.4, r * 0.2), c + Vector2(-r * 0.75, -r * 0.1), Color("#ffd8a8"), r * 0.2, true)
		"attack":
			ci.draw_line(c + Vector2(-r * 0.7, r * 0.7), c + Vector2(r * 0.6, -r * 0.6), Color("#8b5a2b"), r * 0.16, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.85, -r * 0.85), c + Vector2(r * 0.3, -r * 0.55), c + Vector2(r * 0.55, -r * 0.3)]), Color("#cfd6dc"))
		"run":
			for k in 3:
				ci.draw_line(c + Vector2(-r * 0.8 + k * r * 0.2, -r * 0.4 + k * r * 0.4), c + Vector2(-r * 0.1 + k * r * 0.2, -r * 0.4 + k * r * 0.4), Color.WHITE, 3.0, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.1, -r * 0.6), c + Vector2(r * 0.8, 0), c + Vector2(r * 0.1, r * 0.6)]), Color.WHITE)
