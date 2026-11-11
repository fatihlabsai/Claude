## In-game HUD: stats, clock, compass, prompts, toasts, storm banner, hint bubble
## and touch controls. Reads state from the game (main.gd) every frame.
extends Control

const JoystickScript := preload("res://scripts/joystick.gd")
const TouchButton := preload("res://scripts/touch_button.gd")

var game: Node
var touch := false
var joy: Control
var b_act: Control
var b_atk: Control
var b_drink: Control
var b_run: Control
var top_btns := {}
var toasts: Array = []          # [{text, t, col}]
var hint := {}                  # {text, target:String, t}
var rects := {}
var run_held := false

func setup(g: Node, is_touch: bool) -> void:
	game = g
	touch = is_touch
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in ["bag", "map", "pause"]:
		var b := TouchButton.new()
		b.icon = k; b.radius = 28.0 if not touch else 32.0
		b.col = Color("#b9773f") if k != "pause" else Color("#7d6a58")
		add_child(b)
		top_btns[k] = b
		b.pressed_btn.connect(func(): game.on_hud_button(k))
	if touch:
		joy = JoystickScript.new()
		add_child(joy)
		b_act = _tb("hand", "Etkileşim", Color("#e2683c"), 58.0)
		b_atk = _tb("attack", "Saldır", Color("#c0503a"), 42.0)
		b_drink = _tb("water", "İç", Color("#3a8fd6"), 42.0)
		b_run = _tb("run", "Koş", Color("#d6a13a"), 38.0)
		b_act.pressed_btn.connect(func(): game.do_interact())
		b_atk.pressed_btn.connect(func(): game.do_attack())
		b_drink.pressed_btn.connect(func(): game.do_drink())
		b_run.pressed_btn.connect(func(): run_held = true)
		b_run.released_btn.connect(func(): run_held = false)

func _tb(icon: String, text: String, col: Color, r: float) -> Control:
	var b := TouchButton.new()
	b.icon = icon; b.text = text; b.col = col; b.radius = r
	add_child(b)
	return b

func move_vec() -> Vector2:
	return joy.vec if joy else Vector2.ZERO

func want_run() -> bool:
	return run_held or (joy != null and joy.running())

func toast(text: String, col := Color.WHITE) -> void:
	toasts.push_front({"text": text, "t": 3.2, "col": col})
	if toasts.size() > 5:
		toasts.pop_back()

func show_hint(text: String, target := "") -> void:
	hint = {"text": text, "target": target, "t": 12.0}
	Sfx.play("hint", -6.0)

func _layout() -> void:
	var vs := get_viewport_rect().size
	var x := vs.x - 16.0
	for k in ["pause", "map", "bag"]:
		var b: Control = top_btns[k]
		b.position = Vector2(x - b.size.x, 10)
		x -= b.size.x + 6
		rects[k] = Rect2(b.position, b.size)
	if touch:
		var bottom := vs.y - 18.0
		joy.position = Vector2(14, bottom - joy.size.y)
		b_act.position = Vector2(vs.x - b_act.size.x - 16, bottom - b_act.size.y)
		b_atk.position = b_act.position + Vector2(-b_atk.size.x - 6, b_act.size.y - b_atk.size.y + 4)
		b_drink.position = b_act.position + Vector2(b_act.size.x - b_drink.size.x, -b_drink.size.y - 6)
		b_run.position = b_atk.position + Vector2(-8, -b_run.size.y - 18)
		rects["joy"] = Rect2(joy.position, joy.size)
		rects["act"] = Rect2(b_act.position, b_act.size)
		rects["atk"] = Rect2(b_atk.position, b_atk.size)
		rects["drink"] = Rect2(b_drink.position, b_drink.size)
		rects["run"] = Rect2(b_run.position, b_run.size)

func _process(dt: float) -> void:
	for t in toasts:
		t.t -= dt
	toasts = toasts.filter(func(t): return t.t > 0.0)
	if not hint.is_empty():
		hint.t -= dt
		if hint.t <= 0.0:
			hint = {}
	if touch and game.player:
		b_act.enabled = game.prompt != ""
		b_drink.badge = str(game.canteen)
		b_act.queue_redraw(); b_drink.queue_redraw()
	_layout()
	queue_redraw()

# ---------------------------------------------------------------- drawing
func _text(p: Vector2, s: String, size: int, col := Color.WHITE, center := false, head := true, outline := 5) -> void:
	var f: Font = UiKit.head_font if head else UiKit.body_font
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := p - Vector2(w / 2 if center else 0.0, 0)
	if outline > 0:
		draw_string_outline(f, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(0.17, 0.09, 0.03, 0.9))
	draw_string(f, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _bar(p: Vector2, w: float, v: float, col: Color, icon: String, label: String, warn := false) -> void:
	var h := 16.0
	UiKit.draw_icon(self, icon, p + Vector2(12, h / 2), 11.0, col)
	var r := Rect2(p + Vector2(28, 0), Vector2(w, h))
	draw_style_box(UiKit.flat_box(Color(0.12, 0.07, 0.03, 0.6), 8), r)
	var fill := Rect2(r.position + Vector2(2, 2), Vector2((w - 4) * clampf(v / 100.0, 0.0, 1.0), h - 4))
	var c := col
	if warn and int(Time.get_ticks_msec() / 300) % 2 == 0:
		c = c.lightened(0.45)
	draw_style_box(UiKit.flat_box(c, 6), fill)
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, 4)), Color(1, 1, 1, 0.22))
	_text(r.position + Vector2(w + 8, h - 2), label, 15, Color.WHITE, false, false, 4)

func _temp_gauge(p: Vector2, w: float, t: float) -> void:
	var h := 16.0
	var lo := 34.0; var hi := 41.0
	var col := Color("#58b85c")
	if t >= GameData.HEAT_LIMIT - 0.6: col = Color("#ff7a30")
	if t >= GameData.HEAT_LIMIT: col = Color("#e5383b")
	if t <= GameData.COLD_LIMIT + 0.6: col = Color("#5fb3ff")
	if t <= GameData.COLD_LIMIT: col = Color("#2f6fe0")
	UiKit.draw_icon(self, "temp", p + Vector2(12, h / 2), 11.0, col)
	var r := Rect2(p + Vector2(28, 0), Vector2(w, h))
	draw_style_box(UiKit.flat_box(Color(0.12, 0.07, 0.03, 0.6), 8), r)
	var segs := [[34.0, 35.0, Color("#2f6fe0")], [35.0, 36.0, Color("#79b7f0")], [36.0, 38.6, Color("#6cc070")], [38.6, 39.5, Color("#ffb347")], [39.5, 41.0, Color("#e5383b")]]
	for s in segs:
		var x0: float = r.position.x + 2 + (w - 4) * (s[0] - lo) / (hi - lo)
		var x1: float = r.position.x + 2 + (w - 4) * (s[1] - lo) / (hi - lo)
		draw_rect(Rect2(x0, r.position.y + 4, x1 - x0, h - 8), Color(s[2], 0.7))
	var mx := r.position.x + 2 + (w - 4) * clampf((t - lo) / (hi - lo), 0.0, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(mx, r.position.y + h + 1), Vector2(mx - 6, r.position.y - 4), Vector2(mx + 6, r.position.y - 4)]), Color.WHITE)
	draw_polyline(PackedVector2Array([Vector2(mx, r.position.y + h + 1), Vector2(mx - 6, r.position.y - 4), Vector2(mx + 6, r.position.y - 4), Vector2(mx, r.position.y + h + 1)]), Color("#3a2414"), 2.0)
	_text(r.position + Vector2(w + 8, h - 2), "%.1f°C" % t, 15, col.lightened(0.3), false, false, 4)

func _draw() -> void:
	if game == null or game.player == null:
		return
	var vs := get_viewport_rect().size
	var s: Survival = game.s
	# --- clock / day ---
	var cp := Vector2(16, 12)
	draw_style_box(UiKit.flat_box(Color(0.15, 0.08, 0.03, 0.55), 14), Rect2(cp, Vector2(178, 64)))
	var night: bool = GameData.is_night(game.tod)
	var sc := cp + Vector2(30, 32)
	if night:
		draw_circle(sc, 14, Color("#f1ead2")); draw_circle(sc + Vector2(6, -4), 12, Color(0.15, 0.08, 0.03, 1))
	else:
		for k in 8:
			var a := k * TAU / 8
			draw_line(sc + Vector2(cos(a), sin(a)) * 15, sc + Vector2(cos(a), sin(a)) * 20, Color("#ffcf40"), 3.0, true)
		draw_circle(sc, 12, Color("#ffcf40"))
	_text(cp + Vector2(58, 28), "%d. Gün" % game.day, 22, Color("#ffe7b8"))
	_text(cp + Vector2(58, 52), "%s  ·  %d°C" % [GameData.clock_text(game.tod), roundi(GameData.air_temp(game.tod, game.day))], 17, Color.WHITE, false, false, 4)
	rects["clock"] = Rect2(cp, Vector2(178, 64))
	# --- stats ---
	var sp := Vector2(16, vs.y - 150) if not touch else Vector2(16, 86)
	var bw := 150.0 if not touch else 128.0
	draw_style_box(UiKit.flat_box(Color(0.15, 0.08, 0.03, 0.45), 14), Rect2(sp - Vector2(6, 8), Vector2(bw + 104, 140)))
	_bar(sp, bw, s.water, Color("#3fb4ef"), "water", "Su %d" % roundi(s.water), s.water < 25)
	_bar(sp + Vector2(0, 26), bw, s.food, Color("#e79a4b"), "food", "Yemek %d" % roundi(s.food), s.food < 25)
	_temp_gauge(sp + Vector2(0, 52), bw, s.temp)
	_bar(sp + Vector2(0, 78), bw, s.stamina, Color("#ffd23f"), "stamina", "Güç %d" % roundi(s.stamina), s.stamina < 15)
	_bar(sp + Vector2(0, 104), bw, s.hp, Color("#e5383b"), "hp", "Sağlık %d" % roundi(s.hp), s.hp < 30)
	rects["stats"] = Rect2(sp - Vector2(6, 8), Vector2(bw + 104, 140))
	# --- canteen ---
	var cn := sp + Vector2(0, -34) if not touch else sp + Vector2(0, 142)
	draw_style_box(UiKit.flat_box(Color(0.15, 0.08, 0.03, 0.55), 12), Rect2(cn - Vector2(6, 4), Vector2(36 + game.cap * 22, 30)))
	_text(cn + Vector2(0, 20), "Matara", 15, Color("#bfe6ff"), false, false, 4)
	for i in game.cap:
		var dc := cn + Vector2(62 + i * 20, 11)
		var full: bool = i < game.canteen
		UiKit.draw_icon(self, "water", dc, 8.0) if full else draw_circle(dc + Vector2(0, 2), 5, Color(1, 1, 1, 0.25))
	rects["canteen"] = Rect2(cn - Vector2(6, 4), Vector2(36 + game.cap * 22, 30))
	if not touch:
		_text(cn + Vector2(36 + game.cap * 22, 20), "[Q]", 15, Color(1, 1, 1, 0.7), false, false, 4)
	# --- compass ---
	_compass(Vector2(vs.x / 2, 30), minf(420.0, vs.x * 0.5))
	# --- status icons (poison/heat/cold/shade) ---
	var st := []
	if s.poison > 0.0: st.append(["Zehirlendin", Color("#9be15d")])
	if s.heat_stroke(): st.append(["Sıcak çarpması!", Color("#ff7a30")])
	if s.hypothermia(): st.append(["Donuyorsun!", Color("#7fc8ff")])
	if game.in_shade and not night: st.append(["Gölgedesin", Color("#ffe7b8")])
	if game.near_fire: st.append(["Ateşin yanındasın", Color("#ffb347")])
	if game.shelter_name != "" and game.storm_state != "": st.append(["Sığınaktasın: " + game.shelter_name, Color("#b8f0b8")])
	# --- storm banner (drawn first so the status lines can sit below it) ---
	var banner_bottom := 0.0
	if game.storm_state == "warn" or game.storm_state == "storm":
		var warn: bool = game.storm_state == "warn"
		var msg: String = ("KUM FIRTINASI YAKLAŞIYOR · %d sn · Sığınak bul!" % ceili(game.storm_eta)) if warn else "KUM FIRTINASI!"
		var bw2 := minf(460.0 if warn else 300.0, vs.x - 24.0)
		var fs := 18 if warn else 20
		while fs > 11 and UiKit.head_font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > bw2 - 24.0:
			fs -= 1
		var by := 60.0 if not touch else 64.0
		var br := Rect2(Vector2(vs.x / 2 - bw2 / 2, by), Vector2(bw2, 34))
		if warn:
			draw_style_box(UiKit.flat_box(Color(0.75, 0.32, 0.1, 0.85), 10, 2, Color("#ffd27a")), br)
		else:
			draw_style_box(UiKit.flat_box(Color(0.6, 0.25, 0.08, 0.85), 10), br)
		_text(Vector2(vs.x / 2, by + 17 + fs * 0.36), msg, fs, Color.WHITE, true)
		rects["storm_banner"] = br
		banner_bottom = br.end.y
	var yy := 96.0 if not touch else 300.0
	# status lines never overlap the banner (baseline + ascent below its bottom edge)
	yy = maxf(yy, banner_bottom + 26.0)
	for i in st.size():
		_text(Vector2(vs.x / 2, yy + i * 24), st[i][0], 18, st[i][1], true, true, 5)
		rects["status%d" % i] = Rect2(Vector2(vs.x / 2 - 120, yy + i * 24 - 18), Vector2(240, 24))
	# --- interaction prompt ---
	if game.prompt != "":
		var py := vs.y - (90.0 if not touch else 250.0)
		var txt: String = ("[E] " if not touch else "") + game.prompt
		var f := UiKit.head_font
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 32
		var pr := Rect2(Vector2(vs.x / 2 - w / 2, py - 28), Vector2(w, 40))
		draw_style_box(UiKit.flat_box(Color(0.15, 0.08, 0.03, 0.75), 12, 2, Color("#f4d39b")), pr)
		_text(Vector2(vs.x / 2, py), txt, 22, Color("#fff4dc"), true)
		rects["prompt"] = pr
	# --- toasts ---
	var ty := vs.y * 0.36
	for i in toasts.size():
		var t: Dictionary = toasts[i]
		var a := clampf(t.t, 0.0, 1.0)
		_text(Vector2(vs.x / 2, ty - i * 26), t.text, 20, Color(t.col, a), true, true, 5)
	# --- hint bubble ---
	if not hint.is_empty():
		_hint_bubble(vs)

func _compass(c: Vector2, w: float) -> void:
	var r := Rect2(c - Vector2(w / 2, 16), Vector2(w, 34))
	draw_style_box(UiKit.flat_box(Color(0.15, 0.08, 0.03, 0.55), 12), r)
	var yaw: float = game.cam_yaw
	var jitter: float = game.compass_jitter
	var fov := PI * 0.9
	var marks := [["K", 0.0], ["KD", PI * 0.25], ["D", PI * 0.5], ["GD", PI * 0.75], ["G", PI], ["GB", PI * 1.25], ["B", PI * 1.5], ["KB", PI * 1.75]]
	for m in marks:
		var d := wrapf(m[1] - yaw + jitter, -PI, PI)
		if absf(d) < fov / 2:
			var x := c.x + d / (fov / 2) * (w / 2 - 14)
			var major: bool = m[0].length() == 1
			_text(Vector2(x, c.y + 7), m[0], 18 if major else 14, Color("#ffcf40") if m[0] == "K" else Color.WHITE, true, true, 4)
	for lm in game.compass_marks():
		var d2 := wrapf(lm.a - yaw + jitter, -PI, PI)
		if absf(d2) < fov / 2:
			var x2 := c.x + d2 / (fov / 2) * (w / 2 - 14)
			draw_circle(Vector2(x2, c.y + 13), 4.0, lm.col)
	draw_line(Vector2(c.x, r.position.y + 2), Vector2(c.x, r.position.y + 8), Color.WHITE, 2.0)

func _hint_bubble(vs: Vector2) -> void:
	var f := UiKit.body_font
	var maxw := minf(440.0, vs.x - 40)
	var lines := _wrap(hint.text, f, 18, maxw - 30)
	var h := 22.0 * lines.size() + 26
	var target: Rect2 = rects.get(hint.target, Rect2())
	var pos := Vector2(vs.x / 2 - maxw / 2, vs.y * 0.18 if not touch else vs.y * 0.42)
	var br := Rect2(pos, Vector2(maxw, h))
	draw_style_box(UiKit.flat_box(Color("#fff4dc"), 14, 3, Color("#3a2414")), br)
	if target.size != Vector2.ZERO:
		var tc := target.get_center()
		var from := Vector2(clampf(tc.x, br.position.x + 20, br.end.x - 20), br.end.y if tc.y > br.end.y else br.position.y)
		var tip := tc.move_toward(from, minf(30.0, tc.distance_to(from) * 0.5))
		draw_line(from, tip, Color("#3a2414"), 4.0, true)
		draw_line(from, tip, Color("#fff4dc"), 2.0, true)
		draw_circle(tip, 6, Color("#e2683c"))
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
		draw_rect(target.grow(4 + pulse * 3), Color(1, 0.8, 0.3, 0.8), false, 3.0)
	for i in lines.size():
		draw_string(f, br.position + Vector2(15, 30 + i * 22), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#3a2414"))
	rects["hint"] = br

func _wrap(text: String, f: Font, size: int, w: float) -> Array:
	var out := []
	var cur := ""
	for word in text.split(" "):
		var t := word if cur == "" else cur + " " + word
		if f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > w and cur != "":
			out.append(cur); cur = word
		else:
			cur = t
	if cur != "":
		out.append(cur)
	return out
