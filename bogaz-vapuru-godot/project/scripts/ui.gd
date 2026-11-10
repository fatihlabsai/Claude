## All user interface: Turkish menus, HUD, minimap, off-screen indicators,
## toast messages, touch controls and screen transitions.
## Buttons use Kenney UI Pack textures (CC0); fonts are Baloo 2 and Nunito (OFL).
extends CanvasLayer

const NAVY := Color("#1d3557")
const CREAM := Color("#fff8e8")

var main: Node
var font_bold: FontVariation
var font_semi: FontVariation
var font_body: Font
var th: Theme
var root: Control
var vignette: ColorRect
var indicators: Control
var hud: Control
var chips := {}
var dest_row: HBoxContainer
var hud_top_box: VBoxContainer
var dest_key := ""
var can_bar: ProgressBar
var simit_icons: Control
var ak_arrow: Control
var minimap: Control
var toast_panel: PanelContainer
var toast_label: Label
var toast_tw: Tween
var touch_root: Control
var joy: Control
var simit_btn: Control
var fade: ColorRect
var screens := {}
var current := ""
var mute_buttons: Array[Button] = []
var title_best: Label
var title_label: Label
var results_box: VBoxContainer
var results_title: Label
var over_box: VBoxContainer
var scores_box: VBoxContainer
var busy := false

var joy_vec: Vector2:
	get:
		return joy.vec if (touch_root and touch_root.visible) else Vector2.ZERO

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bf: FontFile = load("res://assets/fonts/Baloo2.ttf")
	font_bold = FontVariation.new()
	font_bold.base_font = bf
	font_bold.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 800}
	font_semi = FontVariation.new()
	font_semi.base_font = bf
	font_semi.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 600}
	font_body = load("res://assets/fonts/Nunito.ttf")
	_make_theme()
	root = Control.new()
	root.theme = th
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	vignette = ColorRect.new()
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vm := ShaderMaterial.new()
	vm.shader = load("res://shaders/vignette.gdshader")
	vignette.material = vm
	root.add_child(vignette)
	indicators = _cb_control(_draw_indicators)
	indicators.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(indicators)
	_build_hud()
	_build_touch()
	_build_toast()
	_build_screens()
	fade = ColorRect.new()
	fade.color = Color(NAVY, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(fade)

# ------------------------------------------------------------------ theme
func _tex_box(path: String, mod := Color.WHITE, top_extra := 0.0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(path)
	sb.texture_margin_left = 18
	sb.texture_margin_right = 18
	sb.texture_margin_top = 16
	sb.texture_margin_bottom = 20
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 8 + top_extra
	sb.content_margin_bottom = 14 - top_extra
	sb.modulate_color = mod
	return sb

func _make_theme() -> void:
	th = Theme.new()
	th.default_font = font_semi
	th.default_font_size = 20
	for v in [["Button", "yellow"], ["BtnBlue", "blue"], ["BtnWhite", "grey"], ["BtnRed", "red"], ["BtnGreen", "green"]]:
		var tname: String = v[0]
		if tname != "Button":
			th.set_type_variation(tname, "Button")
		var p := "res://assets/ui/%s_rectangle_depth_gloss.png" % v[1]
		th.set_stylebox("normal", tname, _tex_box(p))
		th.set_stylebox("hover", tname, _tex_box(p, Color(1.08, 1.08, 1.08)))
		th.set_stylebox("pressed", tname, _tex_box(p, Color(0.85, 0.85, 0.85), 3))
		th.set_stylebox("disabled", tname, _tex_box(p, Color(0.7, 0.7, 0.7, 0.6)))
		var focus := StyleBoxFlat.new()
		focus.draw_center = false
		focus.set_border_width_all(3)
		focus.border_color = Color(1, 1, 1, 0.9)
		focus.set_corner_radius_all(14)
		focus.set_expand_margin_all(3)
		th.set_stylebox("focus", tname, focus)
		var fc := Color.WHITE if v[1] in ["blue", "red", "green"] else NAVY
		th.set_color("font_color", tname, fc)
		th.set_color("font_hover_color", tname, fc)
		th.set_color("font_pressed_color", tname, fc)
		th.set_color("font_focus_color", tname, fc)
		th.set_font("font", tname, font_bold)
		th.set_font_size("font_size", tname, 22)
	th.set_color("font_color", "Label", NAVY)
	var panel := StyleBoxFlat.new()
	panel.bg_color = CREAM
	panel.set_border_width_all(4)
	panel.border_color = NAVY
	panel.set_corner_radius_all(24)
	panel.shadow_color = Color(0.04, 0.1, 0.2, 0.35)
	panel.shadow_size = 14
	panel.shadow_offset = Vector2(0, 8)
	panel.set_content_margin_all(24)
	th.set_stylebox("panel", "PanelContainer", panel)
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(1, 1, 1, 0.92)
	chip.set_border_width_all(2)
	chip.border_color = NAVY
	chip.set_corner_radius_all(14)
	chip.content_margin_left = 10
	chip.content_margin_right = 10
	chip.content_margin_top = 1
	chip.content_margin_bottom = 1
	chip.shadow_color = Color(0.04, 0.1, 0.2, 0.25)
	chip.shadow_size = 3
	chip.shadow_offset = Vector2(0, 2)
	th.set_type_variation("Chip", "PanelContainer")
	th.set_stylebox("panel", "Chip", chip)
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color("#d6dde6")
	pb_bg.set_corner_radius_all(6)
	var pb_fg := StyleBoxFlat.new()
	pb_fg.bg_color = Color("#2bb36b")
	pb_fg.set_corner_radius_all(6)
	th.set_stylebox("background", "ProgressBar", pb_bg)
	th.set_stylebox("fill", "ProgressBar", pb_fg)
	var sbar := StyleBoxFlat.new()
	sbar.bg_color = Color(0.11, 0.21, 0.34, 0.35)
	sbar.set_corner_radius_all(4)
	th.set_stylebox("grabber", "VScrollBar", sbar)
	th.set_stylebox("grabber_highlight", "VScrollBar", sbar)
	th.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())

func _cb_control(f: Callable) -> Control:
	var c := Control.new()
	c.set_script(load("res://scripts/control_cb.gd"))
	c.fn = f
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _label(text: String, size := 20, col := NAVY, font: Font = null, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if font:
		l.add_theme_font_override("font", font)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", NAVY)
	return l

func _button(text: String, variation: String, cb: Callable, min_w := 280.0) -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	b.custom_minimum_size = Vector2(min_w, 58)
	b.pressed.connect(func():
		main.sfx.play("click", -4)
		cb.call())
	b.mouse_entered.connect(func(): if not b.disabled: b.create_tween().tween_property(b, "scale", Vector2(1.04, 1.04), 0.08))
	b.mouse_exited.connect(func(): b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.08))
	b.resized.connect(func(): b.pivot_offset = b.size / 2)
	return b

# ------------------------------------------------------------------ HUD
func _chip(key: String, caption: String, parent: Control) -> Label:
	var pc := PanelContainer.new()
	pc.theme_type_variation = "Chip"
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 6)
	pc.add_child(hb)
	var cap := _label(caption, 12, Color("#5b6f86"), font_bold)
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(cap)
	var val := _label("0", 20, NAVY, font_bold)
	hb.add_child(val)
	parent.add_child(pc)
	chips[key] = {"panel": pc, "label": val, "box": hb, "val": ""}
	return val

func _build_hud() -> void:
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(hud)
	var top := VBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 8
	top.offset_right = -8
	top.offset_top = 8
	top.add_theme_constant_override("separation", 6)
	hud.add_child(top)
	hud_top_box = top
	var flow := HFlowContainer.new()
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	top.add_child(flow)
	_chip("sefer", "SEFER", flow)
	_chip("puan", "PUAN", flow)
	_chip("sure", "SÜRE", flow)
	_chip("hedef", "TESLİM", flow)
	_chip("yolcu", "YOLCU", flow)
	var cl := _chip("can", "CAN", flow)
	cl.visible = false
	can_bar = ProgressBar.new()
	can_bar.show_percentage = false
	can_bar.custom_minimum_size = Vector2(70, 12)
	can_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	can_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	can_bar.max_value = 100
	chips.can.box.add_child(can_bar)
	var sl := _chip("simit", "SİMİT", flow)
	sl.visible = false
	simit_icons = _cb_control(_draw_simit_icons)
	simit_icons.custom_minimum_size = Vector2(5 * 15 + 2, 26)
	chips.simit.box.add_child(simit_icons)
	_chip("akinti", "AKINTI", flow)
	ak_arrow = _cb_control(_draw_ak_arrow)
	ak_arrow.custom_minimum_size = Vector2(22, 26)
	chips.akinti.box.add_child(ak_arrow)
	chips.akinti.box.move_child(ak_arrow, 1)
	var pb := _button("Duraklat", "", func(): main.pause_game(), 0)
	pb.custom_minimum_size = Vector2(0, 40)
	pb.add_theme_font_size_override("font_size", 17)
	pb.focus_mode = Control.FOCUS_NONE
	flow.add_child(pb)
	var mb := _button("Ses: Açık", "BtnWhite", func(): _toggle_mute(), 0)
	mb.custom_minimum_size = Vector2(0, 40)
	mb.add_theme_font_size_override("font_size", 17)
	mb.focus_mode = Control.FOCUS_NONE
	mute_buttons.append(mb)
	flow.add_child(mb)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(center)
	dest_row = HBoxContainer.new()
	dest_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dest_row.add_theme_constant_override("separation", 6)
	center.add_child(dest_row)
	minimap = _cb_control(_draw_minimap)
	minimap.custom_minimum_size = Vector2(112, 148)
	minimap.size = minimap.custom_minimum_size
	hud.add_child(minimap)

func _draw_simit_icons(c: Control) -> void:
	var f = main.ferry
	if f == null:
		return
	for i in f.simit_max:
		var on: bool = i < f.simit
		var p := Vector2(8 + i * 15, 13)
		if on:
			Art.draw_simit(c, p, 7, 0.3 + i)
		else:
			c.draw_arc(p, 5, 0, TAU, 16, Color(0.36, 0.43, 0.53, 0.5), 3.0, true)
	if f.simit < f.simit_max:
		var p2 := Vector2(8 + f.simit * 15, 13)
		c.draw_arc(p2, 8, -PI / 2, -PI / 2 + TAU * f.simit_charge / 3.0, 16, Color("#e3a65a"), 2.0, true)

func _draw_ak_arrow(c: Control) -> void:
	var a: float = main.cur.ang
	var ctr := c.size / 2
	var d := Vector2(cos(a), sin(a))
	var n := Vector2(-d.y, d.x)
	c.draw_line(ctr - d * 8, ctr + d * 6, NAVY, 3.0, true)
	c.draw_colored_polygon(PackedVector2Array([ctr + d * 10, ctr + d * 3 + n * 5, ctr + d * 3 - n * 5]), NAVY)

func _set_chip(key: String, v: String) -> void:
	var ch: Dictionary = chips[key]
	if ch.val == v:
		return
	ch.val = v
	ch.label.text = v

func _process(_dt: float) -> void:
	if not main:
		return
	vignette.material.set_shader_parameter("flash_col", Color(main.flash_col, main.flash * 0.42))
	indicators.queue_redraw()
	if not hud.visible:
		return
	var f = main.ferry
	if f == null:
		return
	_set_chip("sefer", str(main.sefer))
	_set_chip("puan", Geo.fmt(main.score))
	var sec := maxi(0, int(ceil(main.time_left)))
	_set_chip("sure", str(sec))
	chips.sure.label.add_theme_color_override("font_color", Color("#e8434b") if sec <= 10 else NAVY)
	_set_chip("hedef", "%d/%d" % [main.delivered, main.target])
	chips.hedef.label.add_theme_color_override("font_color", Color("#2b9a5b") if main.delivered >= main.target else NAVY)
	_set_chip("yolcu", "%d/%d" % [f.pax.size(), f.cap])
	can_bar.value = main.can
	(can_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color("#e8434b") if main.can < 35 else Color("#2bb36b")
	var s: float = main.cur.str
	_set_chip("akinti", "Zayıf" if s < 18 else ("Orta" if s < 35 else "Güçlü"))
	simit_icons.queue_redraw()
	ak_arrow.queue_redraw()
	minimap.queue_redraw()
	if simit_btn.count != f.simit:
		simit_btn.count = f.simit
		simit_btn.queue_redraw()
	# destination chips
	var counts := {}
	for q in f.pax:
		counts[q.dest] = counts.get(q.dest, 0) + 1
	var key := str(counts) + str(f.pax.size() >= f.cap)
	if key != dest_key:
		dest_key = key
		for ch in dest_row.get_children():
			ch.queue_free()
		if f.pax.is_empty():
			dest_row.add_child(_note("Vapur boş — iskelelerdeki yolcuları al!"))
		else:
			for p in main.piers:
				if counts.has(p.id):
					dest_row.add_child(_dest_chip(p.name + " ×" + str(counts[p.id]), p.color))
			if f.pax.size() >= f.cap:
				dest_row.add_child(_note("Vapur dolu!"))
	_layout_minimap()

func _note(t: String) -> Control:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.21, 0.34, 0.6)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	pc.add_theme_stylebox_override("panel", sb)
	pc.add_child(_label(t, 16, Color.WHITE, font_semi))
	return pc

func _dest_chip(t: String, col: Color) -> Control:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_border_width_all(2)
	sb.border_color = NAVY
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	pc.add_theme_stylebox_override("panel", sb)
	pc.add_child(_label(t, 16, Color.WHITE, font_bold))
	return pc

func _layout_minimap() -> void:
	var vs := root.get_viewport_rect().size
	if main.touch_mode:
		minimap.position = Vector2(vs.x - minimap.size.x - 10, vs.y * 0.32)
	else:
		minimap.position = vs - minimap.size - Vector2(12, 12)

func _draw_minimap(c: Control) -> void:
	var W := c.size.x
	var H := c.size.y
	var sx := W / Geo.WORLD_W
	var sy := H / (Geo.WORLD_BOTTOM - Geo.WATER_TOP)
	var X := func(x): return x * sx
	var Y := func(y): return (y - Geo.WATER_TOP) * sy
	c.draw_rect(Rect2(Vector2(2, 3), c.size), Color(0.04, 0.1, 0.2, 0.3))
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color("#f1e4c4"))
	var poly := PackedVector2Array()
	var y := Geo.WATER_TOP
	while y <= Geo.WORLD_BOTTOM:
		poly.append(Vector2(X.call(Geo.eu_x(y)), Y.call(y)))
		y += 40
	y = Geo.WORLD_BOTTOM
	while y >= Geo.WATER_TOP:
		poly.append(Vector2(X.call(Geo.as_x(y)), Y.call(y)))
		y -= 40
	c.draw_colored_polygon(poly, Color("#58b9e2"))
	c.draw_rect(Rect2(0, Y.call(Geo.BRIDGE_Y) - 1, W, 2), Color("#7a8a9a"))
	var f = main.ferry
	var dests := {}
	if f:
		for q in f.pax:
			dests[q.dest] = true
	for p in main.piers:
		var hl := dests.has(p.id)
		var r := (6.0 + sin(main.t * 6) * 1.5) if hl else 4.5
		var pp := Vector2(X.call(p.bx), Y.call(p.by))
		c.draw_circle(pp, r + 1.5, NAVY)
		c.draw_circle(pp, r, p.color)
		if p.queue.size() > 0:
			var s := str(p.queue.size())
			c.draw_string(font_bold, Vector2(X.call(p.sx) - p.dir * 12 - 4, Y.call(p.by) + 5), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, NAVY)
	for s in main.ships:
		if s.y > Geo.WATER_TOP:
			c.draw_rect(Rect2(X.call(s.x) - 2, Y.call(s.y - s.L / 2), 4, s.L * sy), Color("#c0392b"))
	for k in main.kayiks:
		c.draw_rect(Rect2(X.call(k.x) - 1.5, Y.call(k.y) - 1.5, 3, 3), Color("#7a4a2a"))
	for vp in main.vapurs:
		c.draw_circle(Vector2(X.call(vp.x), Y.call(vp.y)), 2.5, Color.WHITE)
	var v: Rect2 = main.view_rect()
	c.draw_rect(Rect2(X.call(v.position.x), Y.call(v.position.y), v.size.x * sx, v.size.y * sy), Color(0.11, 0.21, 0.34, 0.7), false, 1.5)
	if f:
		var fp := Vector2(X.call(f.x), Y.call(f.y))
		var d := Vector2(cos(f.ang), sin(f.ang))
		var n := Vector2(-d.y, d.x)
		c.draw_colored_polygon(PackedVector2Array([fp + d * 8, fp - d * 5 + n * 5, fp - d * 5 - n * 5]), Color("#ffcf33"))
		c.draw_polyline(PackedVector2Array([fp + d * 8, fp - d * 5 + n * 5, fp - d * 5 - n * 5, fp + d * 8]), NAVY, 1.5, true)
	c.draw_rect(Rect2(Vector2.ZERO, c.size), NAVY, false, 2.0)

func _edge_point(p: Vector2, margin: float) -> Dictionary:
	var vs := root.get_viewport_rect().size
	var ctr := vs / 2
	var d := p - ctr
	var top := maxf(hud_top_box.get_global_rect().end.y + 26.0, 90.0) if hud_top_box else 100.0
	top = minf(top, ctr.y - 40.0)
	var bottom := 190.0 if main.touch_mode else 60.0
	var hw := ctr.x - margin
	var h_top := ctr.y - top
	var h_bot := vs.y - ctr.y - bottom
	var k := INF
	if d.x != 0:
		k = minf(k, hw / absf(d.x))
	if d.y < 0:
		k = minf(k, h_top / -d.y)
	elif d.y > 0:
		k = minf(k, h_bot / d.y)
	return {"p": ctr + d * k, "a": d.angle()}

func _draw_indicators(c: Control) -> void:
	if not (main.state == "play" or main.state == "paused"):
		return
	var f = main.ferry
	if f == null:
		return
	var v: Rect2 = main.view_rect()
	var counts := {}
	for q in f.pax:
		counts[q.dest] = counts.get(q.dest, 0) + 1
	for p in main.piers:
		if not counts.has(p.id):
			continue
		if v.grow(-20).has_point(Vector2(p.bx, p.by)):
			continue
		var e := _edge_point(main.world_to_screen(Vector2(p.bx, p.by)), 40)
		var ep: Vector2 = e.p
		var dir := Vector2.from_angle(e.a)
		var nn := Vector2(-dir.y, dir.x)
		var tip := ep + dir * 34
		c.draw_colored_polygon(PackedVector2Array([tip, ep + dir * 18 + nn * 11, ep + dir * 18 - nn * 11]), p.color)
		c.draw_polyline(PackedVector2Array([tip, ep + dir * 18 + nn * 11, ep + dir * 18 - nn * 11, tip]), NAVY, 2.5, true)
		var label: String = p.name + " ×" + str(counts[p.id])
		var w := font_bold.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 16
		Art.rrect(c, Rect2(ep + Vector2(-w / 2 - 2, -13), Vector2(w + 4, 26)), 11, NAVY)
		Art.rrect(c, Rect2(ep + Vector2(-w / 2, -11), Vector2(w, 22)), 9, p.color)
		c.draw_string(font_bold, ep + Vector2(-w / 2 + 8, 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	for s in main.ships:
		var ahead: float = (v.position.y - (s.y + s.L / 2)) if sin(s.ang) > 0 else ((s.y - s.L / 2) - v.end.y)
		if ahead < 0 or ahead > 420 or s.x < v.position.x or s.x > v.end.x:
			continue
		var e := _edge_point(main.world_to_screen(Vector2(s.x, s.y)), 30)
		var ep: Vector2 = e.p
		var a: float = 0.6 + 0.4 * sin(main.t * 10)
		var tri := PackedVector2Array([ep + Vector2(0, -16), ep + Vector2(16, 12), ep + Vector2(-16, 12)])
		c.draw_colored_polygon(tri, Color(1, 0.3, 0.3, a))
		c.draw_polyline(Art.closed(tri), Color(NAVY, a), 2.5, true)
		c.draw_rect(Rect2(ep + Vector2(-1.5, -7), Vector2(3, 10)), Color(1, 1, 1, a))
		c.draw_rect(Rect2(ep + Vector2(-1.5, 5), Vector2(3, 3)), Color(1, 1, 1, a))

# ------------------------------------------------------------------ touch
func _build_touch() -> void:
	touch_root = Control.new()
	touch_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(touch_root)
	joy = Control.new()
	joy.set_script(load("res://scripts/joystick.gd"))
	touch_root.add_child(joy)
	joy.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joy.position = Vector2(18, -joy.size.y - 18)
	simit_btn = Control.new()
	simit_btn.set_script(load("res://scripts/touch_button.gd"))
	simit_btn.font = font_bold
	touch_root.add_child(simit_btn)
	simit_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	simit_btn.pressed_btn.connect(func(): main.throw_simit())
	touch_root.resized.connect(_layout_touch)
	_layout_touch()

func _layout_touch() -> void:
	var vs := root.get_viewport_rect().size
	joy.position = Vector2(20, vs.y - joy.size.y - 22)
	simit_btn.position = Vector2(vs.x - simit_btn.size.x - 18, vs.y - simit_btn.size.y - 26)

# ------------------------------------------------------------------ toast
func _build_toast() -> void:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.set_anchors_preset(Control.PRESET_CENTER_TOP)
	cc.anchor_left = 0
	cc.anchor_right = 1
	cc.offset_top = 128
	root.add_child(cc)
	toast_panel = PanelContainer.new()
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.21, 0.34, 0.88)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 6
	sb.content_margin_bottom = 8
	sb.border_color = Color("#ffcf33")
	sb.set_border_width_all(2)
	toast_panel.add_theme_stylebox_override("panel", sb)
	toast_label = _label("", 22, Color.WHITE, font_bold)
	toast_panel.add_child(toast_label)
	toast_panel.modulate.a = 0
	cc.add_child(toast_panel)

func toast(msg: String, dur := 2.0) -> void:
	toast_label.text = msg
	if toast_tw:
		toast_tw.kill()
	toast_panel.pivot_offset = toast_panel.size / 2
	toast_tw = create_tween()
	toast_tw.tween_property(toast_panel, "modulate:a", 1.0, 0.18)
	toast_tw.parallel().tween_property(toast_panel, "scale", Vector2.ONE, 0.25).from(Vector2(0.8, 0.8)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tw.tween_interval(dur)
	toast_tw.tween_property(toast_panel, "modulate:a", 0.0, 0.3)

# ------------------------------------------------------------------ screens
func _overlay(name: String, dim := 0.38) -> Dictionary:
	var o := Control.new()
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	o.visible = false
	root.add_child(o)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.12, 0.22, dim)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(bg)
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(cc)
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(pc)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	pc.add_child(vb)
	var d := {"root": o, "panel": pc, "box": vb, "primary": null}
	screens[name] = d
	return d

func _heading(t: String, size := 38) -> Label:
	var l := _label(t, size, NAVY, font_bold)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _stat_rows(box: VBoxContainer, rows: Array) -> void:
	for ch in box.get_children():
		ch.queue_free()
	for r in rows:
		var total: bool = r.size() > 2 and r[2] == "total"
		var pc := PanelContainer.new()
		pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#ffe9a8") if total else Color(1, 1, 1, 0.7)
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		pc.add_theme_stylebox_override("panel", sb)
		var hb := HBoxContainer.new()
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pc.add_child(hb)
		var a := _label(str(r[0]), 19, NAVY, font_semi)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(a)
		hb.add_child(_label(str(r[1]), 21 if total else 19, NAVY, font_bold))
		pc.custom_minimum_size = Vector2(minf(440, root.get_viewport_rect().size.x - 110), 0)
		box.add_child(pc)

func _build_screens() -> void:
	# --- title
	var tt := _overlay("title", 0.0)
	var tbox: VBoxContainer = tt.box
	(tt.panel as PanelContainer).add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	title_label = _label("Boğaz Vapuru", 76, Color("#ffd23f"), font_bold, 18)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_shadow_color", Color(0.04, 0.1, 0.2, 0.45))
	title_label.add_theme_constant_override("shadow_offset_y", 6)
	title_label.add_theme_constant_override("shadow_offset_x", 0)
	tbox.add_child(title_label)
	var sub := _note("Avrupa ile Asya arasında yolcu taşı, martılara simit at!")
	var subc := CenterContainer.new()
	subc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subc.add_child(sub)
	tbox.add_child(subc)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tbox.add_child(sp)
	for b in [
		_button("Başla", "", func(): transition(func(): main.start_game())),
		_button("Nasıl Oynanır", "BtnBlue", func(): show_screen("how")),
		_button("Skor Tablosu", "BtnWhite", func(): show_screen("scores")),
	]:
		var c := CenterContainer.new()
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(b)
		tbox.add_child(c)
		if tt.primary == null:
			tt.primary = b
	var mb := _button("Ses: Açık", "BtnWhite", func(): _toggle_mute(), 180)
	mb.custom_minimum_size = Vector2(180, 46)
	mb.add_theme_font_size_override("font_size", 18)
	mute_buttons.append(mb)
	var mc := CenterContainer.new()
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_child(mb)
	tbox.add_child(mc)
	title_best = _label("Rekor: Henüz skor yok", 22, Color.WHITE, font_bold, 8)
	title_best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tbox.add_child(title_best)
	var cr := _label("Godot 4 sürümü • Grafik ve ses: Kenney, OpenGameArt ve özgün çizimler • Müzik: Eric Matyas (soundimage.org, CC-BY 3.0) ve NBJDLukasAbsolute (CC0) • Ayrıntılar: CREDITS.md", 13, Color(1, 1, 1, 0.92), font_semi, 5)
	cr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cr.custom_minimum_size = Vector2(minf(520, 560), 0)
	tbox.add_child(cr)
	# --- how to play
	var hw := _overlay("how")
	hw.box.add_child(_heading("Nasıl Oynanır"))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(520, 360)
	sc.set_meta("scroll", true)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.custom_minimum_size = Vector2(500, 0)
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_override("normal_font", font_body)
	rt.add_theme_font_override("bold_font", font_bold)
	rt.add_theme_font_size_override("normal_font_size", 17)
	rt.add_theme_font_size_override("bold_font_size", 18)
	rt.add_theme_color_override("default_color", NAVY)
	rt.mouse_filter = Control.MOUSE_FILTER_PASS
	rt.text = _how_text()
	sc.add_child(rt)
	hw.box.add_child(sc)
	var hb := _button("Kapat", "", func(): show_screen("title"))
	hw.primary = hb
	hw.box.add_child(_centered(hb))
	# --- scores
	var ss := _overlay("scores")
	ss.box.add_child(_heading("Skor Tablosu"))
	scores_box = VBoxContainer.new()
	scores_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ss.box.add_child(scores_box)
	var sb := _button("Geri", "", func(): show_screen("title"))
	ss.primary = sb
	ss.box.add_child(_centered(sb))
	# --- pause
	var ps := _overlay("pause")
	ps.box.add_child(_heading("Duraklatıldı"))
	var pl := _label("Vapur demir attı, martılar bekliyor.", 19, NAVY, font_semi)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ps.box.add_child(pl)
	var rb := _button("Devam", "", func(): main.resume_game())
	ps.primary = rb
	ps.box.add_child(_centered(rb))
	ps.box.add_child(_centered(_button("Menüye Dön", "BtnWhite", func(): transition(func(): main.go_menu()))))
	# --- results
	var rs := _overlay("results")
	results_title = _heading("Sefer Tamamlandı!")
	rs.box.add_child(results_title)
	results_box = VBoxContainer.new()
	results_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	results_box.add_theme_constant_override("separation", 4)
	rs.box.add_child(results_box)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	var nb := _button("Sonraki Sefer", "BtnGreen", func(): transition(func(): main.next_sefer()), 220)
	rs.primary = nb
	row.add_child(nb)
	row.add_child(_button("Menü", "BtnWhite", func(): transition(func(): main.go_menu()), 140))
	rs.box.add_child(row)
	# --- game over
	var ov := _overlay("over")
	ov.box.add_child(_heading("Oyun Bitti", 44))
	over_box = VBoxContainer.new()
	over_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over_box.add_theme_constant_override("separation", 4)
	ov.box.add_child(over_box)
	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row2.add_theme_constant_override("separation", 12)
	var tb := _button("Tekrar", "", func(): transition(func(): main.start_game()), 180)
	ov.primary = tb
	row2.add_child(tb)
	row2.add_child(_button("Menü", "BtnWhite", func(): transition(func(): main.go_menu()), 140))
	ov.box.add_child(row2)

func _centered(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc

func _how_text() -> String:
	var dot := func(col: String) -> String: return "[color=%s]●[/color]" % col
	return "[b]Amaç[/b]\nSen bir İstanbul vapurunun kaptanısın! Her seferde süre bitmeden [b]hedef sayıda yolcuyu[/b] doğru iskeleye taşı. Hedefi tutturursan bir sonraki, daha zorlu sefere geçersin.\n\n" + \
		"[b]Kumanda[/b]\n[b]↑ / W[/b] ileri, [b]↓ / S[/b] fren ve geri, [b]← → / A D[/b] dümen.\nDokunmatik ekranda sol alttaki kolu gitmek istediğin yöne çek; vapur o yöne döner ve ilerler.\n\n" + \
		"[b]Yanaşma[/b]\nİskelenin önündeki halkaya [b]yavaşça[/b] gir. Yeterince yavaşsan vapur [b]“Yanaşıldı”[/b] olur: yolcular kendiliğinden iner ve biner. Hareket ettiğinde vapur iskeleden ayrılır.\n\n" + \
		"[b]Yolcular[/b]\nYolcunun rengi gideceği iskeleyi gösterir: %s Karaköy, %s Beşiktaş, %s Kadıköy, %s Üsküdar. Yolcular yalnızca kendi iskelelerinde iner. Vapura en fazla 8 yolcu sığar. Çok bekleyen yolcu küsüp gider (-25 puan).\n\n" % [dot.call("#e8434b"), dot.call("#2f7fe0"), dot.call("#2bb36b"), dot.call("#f08a1c")] + \
		"[b]Puan[/b]\nHer teslimat puan ve +1 saniye kazandırır. Aynı iskelede art arda inen yolcular kombo yapar; dolu vapurla yanaşmak [b]Tam Kadro[/b] bonusu verir. Tankerin yanından sıyırarak geçmek [b]Kıl Payı[/b] bonusudur.\n\n" + \
		"[b]Tehlikeler[/b]\nTankerler ve yük gemileri ağır hasar verir (-34 can), diğer vapurlar -20, kayıklar -10. Can biterse oyun biter. [b]Akıntı[/b] vapuru sürekli sürükler; yönünü sudaki oklar ve göstergedeki ok gösterir. İleriki seferlerde akıntı ve trafik artar.\n\n" + \
		"[b]Simit ve Martılar[/b]\n[b]Boşluk[/b] ya da [b]Simit At[/b] ile önündeki martıya simit at. Fareyle veya parmağınla suya dokunarak o yöne de atabilirsin. İsabet eden her simit bonus puan getirir. Simitler zamanla yeniden dolar (en fazla 5).\n\n" + \
		"[b]Duraklatma[/b]\n[b]P[/b] ya da [b]Esc[/b] tuşu veya [b]Duraklat[/b] düğmesi."

func _toggle_mute() -> void:
	main.toggle_mute()
	_update_mute_labels()

func _update_mute_labels() -> void:
	for b in mute_buttons:
		b.text = "Ses: Kapalı" if main.save.muted else "Ses: Açık"

func refresh() -> void:
	if not main or not hud:
		return
	var in_game: bool = main.state == "play" or main.state == "paused"
	hud.visible = in_game
	touch_root.visible = main.touch_mode and main.state == "play"
	_layout_touch()
	var vs := root.get_viewport_rect().size
	for k in screens:
		var p: PanelContainer = screens[k].panel
		for sc in screens[k].box.get_children():
			if sc is ScrollContainer:
				sc.custom_minimum_size = Vector2(minf(520, vs.x - 90), minf(380, vs.y - 260))
				(sc.get_child(0) as Control).custom_minimum_size.x = minf(500, vs.x - 110)
	title_label.add_theme_font_size_override("font_size", 76 if vs.x > 640 else 58)

func show_screen(name: String) -> void:
	current = name
	for k in screens:
		screens[k].root.visible = (k == name)
	if name == "title":
		var hs := int(main.save.hs)
		title_best.text = ("Rekor: " + Geo.fmt(hs) + " puan") if hs > 0 else "Rekor: Henüz skor yok"
		_update_mute_labels()
		var tw := title_label.create_tween().set_loops()
		title_label.pivot_offset = title_label.size / 2
		tw.tween_property(title_label, "rotation", 0.025, 1.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(title_label, "rotation", -0.025, 1.6).set_trans(Tween.TRANS_SINE)
	if name == "scores":
		var hs2 := int(main.save.hs)
		var last := int(main.save.last)
		var bs := int(main.save.sefer)
		_stat_rows(scores_box, [
			["Rekor", (Geo.fmt(hs2) + " puan") if hs2 > 0 else "Henüz skor yok", "total"],
			["Son skor", (Geo.fmt(last) + " puan") if last >= 0 else "Henüz skor yok"],
			["En ileri sefer", (str(bs) + ". sefer") if bs > 0 else "—"],
		])
	refresh()
	if name != "":
		var d: Dictionary = screens[name]
		var pc: PanelContainer = d.panel
		pc.modulate.a = 0
		await get_tree().process_frame
		pc.pivot_offset = pc.size / 2
		var tw2 := pc.create_tween().set_parallel(true)
		tw2.tween_property(pc, "modulate:a", 1.0, 0.2)
		tw2.tween_property(pc, "scale", Vector2.ONE, 0.32).from(Vector2(0.86, 0.86)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if d.primary and current == name:
			(d.primary as Button).grab_focus()
	else:
		var f := root.get_viewport().gui_get_focus_owner()
		if f:
			f.release_focus()

func debug_rects() -> Dictionary:
	var out := {}
	for k in screens:
		var b = screens[k].primary
		if b and screens[k].root.visible:
			var r: Rect2 = (b as Control).get_global_rect()
			out[k] = [r.position.x, r.position.y, r.size.x, r.size.y]
	if touch_root.visible:
		var jr := joy.get_global_rect()
		var sr := simit_btn.get_global_rect()
		out["joy"] = [jr.position.x, jr.position.y, jr.size.x, jr.size.y]
		out["simit"] = [sr.position.x, sr.position.y, sr.size.x, sr.size.y]
	return out

func back_to_title() -> void:
	if current in ["how", "scores"]:
		main.sfx.play("click", -4)
		show_screen("title")

func show_results(data: Dictionary) -> void:
	results_title.text = data.title
	_stat_rows(results_box, data.rows)
	var n := _label(data.note, 16, NAVY, font_semi)
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.custom_minimum_size = Vector2(minf(440, root.get_viewport_rect().size.x - 110), 0)
	results_box.add_child(n)
	show_screen("results")

func show_over(data: Dictionary) -> void:
	for ch in over_box.get_children():
		ch.queue_free()
	var r := _label(data.reason, 18, Color("#a8323a"), font_semi)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size = Vector2(minf(440, root.get_viewport_rect().size.x - 110), 0)
	over_box.add_child(r)
	var big := _label(data.score, 46, Color("#ffd23f"), font_bold, 12)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_box.add_child(big)
	if data.record:
		var badge := _dest_chip("Yeni Rekor!", Color("#e8434b"))
		over_box.add_child(_centered(badge))
		var tw := badge.create_tween().set_loops()
		badge.pivot_offset = Vector2(60, 15)
		tw.tween_property(badge, "scale", Vector2(1.1, 1.1), 0.4)
		tw.tween_property(badge, "scale", Vector2.ONE, 0.4)
	else:
		var hl := _label("Rekor: " + data.hs + " puan", 18, NAVY, font_semi)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		over_box.add_child(hl)
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 4)
	over_box.add_child(rows)
	_stat_rows(rows, data.rows)
	show_screen("over")

func transition(fn: Callable) -> void:
	if busy:
		return
	busy = true
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.85, 0.22)
	await tw.finished
	fn.call()
	var tw2 := create_tween()
	tw2.tween_property(fade, "color:a", 0.0, 0.4)
	await tw2.finished
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
