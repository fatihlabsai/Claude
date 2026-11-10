## Boğaz Vapuru — Godot 4 port. Game state, simulation and world rendering.
## Gameplay logic is a faithful port of the original HTML5 Canvas version.
extends Node2D

# ------------------------------------------------------------------ entities
class Pier:
	var id: int
	var name: String
	var side: String
	var y: float
	var color: Color
	var dir: float
	var sx: float
	var tip: float
	var bx: float
	var by: float
	var tx: float
	var queue: Array = []
	var spawn_t := 0.0
	var pulse := 0.0

class Ferry:
	var x := 0.0
	var y := 0.0
	var ang := -PI / 2
	var spd := 0.0
	var kx := 0.0
	var ky := 0.0
	var L := 76.0
	var B := 26.0
	var inv := 0.0
	var docked: Pier = null
	var left_pier: Pier = null
	var undock_cd := 0.0
	var pax: Array = []
	var cap := 8
	var simit := 5
	var simit_max := 5
	var simit_charge := 0.0
	var throw_cd := 0.0
	var transfer_t := 0.6
	var dock_delivered := 0
	var full_on_arrive := false
	var full_given := false
	var wake_t := 0.0
	var smoke_t := 0.0
	var slow_hint := 0.0
	var roll := 0.0
	var trail: Array = []

class Ship:
	var kind := "tanker"
	var x := 0.0
	var y := 0.0
	var ang := 0.0
	var L := 200.0
	var B := 44.0
	var hull := Color.RED
	var deck := Color.GRAY
	var funnel := Color.YELLOW
	var boxes: Array = []
	var spd := 0.0
	var base := 0.0
	var near := false
	var horn_cd := 0.0
	var wake_t := 0.0
	var smoke_t := 0.0
	var trail: Array = []

class Kayik:
	var x := 0.0
	var y := 0.0
	var ang := 0.0
	var t_ang := 0.0
	var spd := 0.0
	var base := 0.0
	var turn_t := 0.0
	var ph := 0.0
	var col := Color.WHITE
	var skin := Color.WHITE
	var hat := Color.WHITE
	var rod := false
	var L := 32.0
	var B := 12.0
	var kx := 0.0
	var ky := 0.0
	var spin := 0.0
	var hit_cd := 0.0
	var tex_i := 0

class AiVapur:
	var x := 0.0
	var y := 0.0
	var lane := 0.0
	var ang := 0.0
	var t_ang := 0.0
	var spd := 0.0
	var state := "move"
	var wait_t := 0.0
	var L := 76.0
	var B := 26.0
	var pax: Array = []
	var wake_t := 0.0
	var smoke_t := 0.0
	var fade := 0.0
	var trail: Array = []
	var band := Color.RED
	var funnel := Color.YELLOW

class Gull:
	var x := 0.0
	var y := 0.0
	var vx := 0.0
	var vy := 0.0
	var sp := 70.0
	var h := 1.0
	var ph := 0.0
	var state := "fly"
	var life := 0.0
	var follow := false
	var orbit_a := 0.0
	var orbit_r := 100.0
	var orbit_dir := 1.0
	var follow_t := 10.0
	var squawk_t := 5.0
	var happy_t := 0.0

class Simit:
	var x0 := 0.0
	var y0 := 0.0
	var tx := 0.0
	var ty := 0.0
	var t := 0.0
	var T := 0.5
	var x := 0.0
	var y := 0.0
	var z := 0.0
	var state := "fly"
	var life := 0.0
	var rot := 0.0

class Part:
	var x := 0.0
	var y := 0.0
	var vx := 0.0
	var vy := 0.0
	var life := 1.0
	var max := 1.0
	var size := 4.0
	var col := Color.WHITE
	var type := "spark"
	var rot := 0.0

class FText:
	var x := 0.0
	var y := 0.0
	var txt := ""
	var col := Color.WHITE
	var size := 16.0
	var life := 1.5
	var max := 1.5

# ------------------------------------------------------------------ state
const SHIP_BOX := ["#e8434b", "#2f7fe0", "#ffcf33", "#2bb36b", "#f08a1c", "#8e5bd6", "#e8e8e8", "#4fc3c8"]
const DEMO_PATH := [Vector2(700, 380), Vector2(520, 600), Vector2(880, 980), Vector2(600, 1350), Vector2(820, 1500), Vector2(700, 900)]
const SAVE_PATH := "user://bogaz_vapuru.cfg"

var state := "menu"
var t := 0.0
var sefer := 1
var score := 0
var time_left := 0.0
var target := 0
var can := 100.0
var delivered := 0
var total_delivered := 0
var gulls_fed := 0
var total_gulls := 0
var near_miss := 0
var lost_pax := 0
var sefer_start_score := 0
var run_start_hs := 0
var new_record := false

var piers: Array[Pier] = []
var ferry: Ferry = null
var ships: Array = []
var kayiks: Array = []
var vapurs: Array = []
var gulls: Array = []
var simits: Array = []
var parts: Array = []
var texts: Array = []
var streaks: Array = []

var cur := {"ang": PI / 2, "target": PI / 2, "str": 10.0, "shift_t": 18.0}
var cam := Vector2(700, 900)
var shake := 0.0
var demo_t := 0.0
var flash := 0.0
var flash_col := Color(1, 0.27, 0.27)
var tanker_t := 2.0
var gull_t := 0.5
var bump_cd := 0.0
var last_sec := -1
var day_phase := 0.2
var menu_diff: Dictionary = Geo.diff(2)

var save := {"hs": 0, "last": -1, "sefer": 0, "muted": false}

# nodes
var camera: Camera2D
var water: Node2D
var water_mat: ShaderMaterial
var layers := {}
var land: Node2D
var sky: Node2D
var modulate_node: CanvasModulate
var ui: CanvasLayer
var sfx: Node
var font: FontVariation
var font_body: Font
var tex_soft: Texture2D
var tex_smoke: Texture2D
var tex_star: Texture2D
var tex_glow: Texture2D
var dinghies: Array[Texture2D] = []
var noise_tex: ImageTexture
var view_size := Vector2(1280, 720)   # world units visible
var touch_mode := false
var touch_used := false
var keys := {"up": false, "down": false, "left": false, "right": false}

# ================================================================== setup
func _ready() -> void:
	randomize()
	_setup_input()
	_load_save()
	var base_font: FontFile = load("res://assets/fonts/Baloo2.ttf")
	font = FontVariation.new()
	font.base_font = base_font
	font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	font_body = load("res://assets/fonts/Nunito.ttf")
	tex_soft = load("res://assets/particles/soft.png")
	tex_smoke = load("res://assets/particles/smoke.png")
	tex_star = load("res://assets/particles/star.png")
	tex_glow = load("res://assets/particles/glow.png")
	for i in 3:
		dinghies.append(load("res://assets/sprites/dinghy_large_%d.png" % (i + 1)))
	for d in Geo.PIER_DEFS:
		var p := Pier.new()
		p.id = d.id
		p.name = d.name
		p.side = d.side
		p.y = d.y
		p.color = d.color
		p.dir = 1.0 if p.side == "eu" else -1.0
		p.sx = Geo.eu_x(p.y) if p.side == "eu" else Geo.as_x(p.y)
		p.tip = p.sx + p.dir * 58
		p.bx = p.sx + p.dir * 80
		p.by = p.y
		p.tx = p.sx - p.dir * 62
		piers.append(p)
	_build_scene()
	sfx = load("res://scripts/sfx.gd").new()
	add_child(sfx)
	sfx.set_muted(save.muted)
	ui = load("res://scripts/ui.gd").new()
	ui.main = self
	add_child(ui)
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()
	init_menu_scene()
	cam = clamp_cam(DEMO_PATH[0])
	ui.show_screen("title")
	sfx.set_music("menu")

func _setup_input() -> void:
	var map := {
		"up": [KEY_UP, KEY_W], "down": [KEY_DOWN, KEY_S], "left": [KEY_LEFT, KEY_A], "right": [KEY_RIGHT, KEY_D],
		"simit": [KEY_SPACE], "pause": [KEY_P, KEY_ESCAPE],
	}
	for a in map:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		for k in map[a]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(a, ev)

func _make_noise() -> ImageTexture:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.012
	n.fractal_octaves = 3
	n.seed = 7
	var img := n.get_seamless_image(256, 256, false, false, 0.1, true)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _build_scene() -> void:
	noise_tex = _make_noise()
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	modulate_node = CanvasModulate.new()
	add_child(modulate_node)
	# water surface with an animated shader
	water = _layer("water")
	water_mat = ShaderMaterial.new()
	water_mat.shader = load("res://shaders/water.gdshader")
	water_mat.set_shader_parameter("noise_tex", noise_tex)
	var eu := PackedVector2Array()
	var asp := PackedVector2Array()
	for p in Geo.EU_PTS:
		eu.append(Vector2(p[0], p[1]))
	for p in Geo.AS_PTS:
		asp.append(Vector2(p[0], p[1]))
	water_mat.set_shader_parameter("eu_pts", eu)
	water_mat.set_shader_parameter("as_pts", asp)
	water.material = water_mat
	_layer("under")
	land = Node2D.new()
	land.set_script(load("res://scripts/land.gd"))
	add_child(land)
	_layer("piers")
	_layer("boats")
	sky = Node2D.new()
	sky.set_script(load("res://scripts/sky.gd"))
	sky.set("main", self)
	add_child(sky)
	_layer("air")
	_layer("bridge")
	_layer("gulls")
	_layer("texts")

func _layer(kind: String) -> Node2D:
	var n := Node2D.new()
	n.set_script(load("res://scripts/layer.gd"))
	n.kind = kind
	n.main = self
	add_child(n)
	layers[kind] = n
	return n

func _on_resize() -> void:
	var vs := get_viewport_rect().size
	var z := clampf(minf(vs.x, vs.y) / 640.0, 0.5, 2.5)
	camera.zoom = Vector2(z, z)
	view_size = vs / z
	refresh_touch_mode()

func refresh_touch_mode() -> void:
	var vs := get_viewport_rect().size
	var tm := touch_used or DisplayServer.is_touchscreen_available() or vs.x < vs.y
	if tm != touch_mode:
		touch_mode = tm
	if ui:
		ui.refresh()

# ================================================================== persistence
func _load_save() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		for k in save:
			save[k] = cf.get_value("save", k, save[k])

func _write_save() -> void:
	var cf := ConfigFile.new()
	for k in save:
		cf.set_value("save", k, save[k])
	cf.save(SAVE_PATH)

func save_scores() -> void:
	if score > int(save.hs):
		save.hs = score
	if score > run_start_hs and score > 0:
		new_record = true
	save.last = score
	if sefer > int(save.sefer):
		save.sefer = sefer
	_write_save()

func toggle_mute() -> void:
	save.muted = not save.muted
	sfx.set_muted(save.muted)
	_write_save()

# ================================================================== helpers
func add_score(n: int) -> void:
	score = maxi(0, score + n)

func add_part(x: float, y: float, vx: float, vy: float, life: float, size: float, col: Color, type: String) -> void:
	if parts.size() > 650:
		parts.pop_front()
	var p := Part.new()
	p.x = x; p.y = y; p.vx = vx; p.vy = vy; p.life = life; p.max = life; p.size = size; p.col = col; p.type = type
	p.rot = randf() * TAU
	parts.append(p)

func add_text(x: float, y: float, txt: String, col := Color.WHITE, size := 16.0) -> void:
	if texts.size() > 40:
		texts.pop_front()
	var f := FText.new()
	f.x = x; f.y = y; f.txt = txt; f.col = col; f.size = size
	texts.append(f)

func burst(x: float, y: float, n: int, cols: Array, spd: float, type: String, life: float, size: float) -> void:
	for i in n:
		var a := randf() * TAU
		var v := spd * randf_range(0.4, 1.2)
		add_part(x, y, cos(a) * v, sin(a) * v, life * randf_range(0.6, 1.2), size * randf_range(0.6, 1.4), cols[randi() % cols.size()], type)

func splash(x: float, y: float, n: int, strength := 1.0) -> void:
	for i in n:
		var a := randf() * TAU
		var v := randf_range(20, 70) * strength
		add_part(x, y, cos(a) * v, sin(a) * v - 10, randf_range(0.4, 0.8), randf_range(1.5, 3.0) * strength, Color(1, 1, 1, 0.95), "drop")
	add_part(x, y, 0, 0, 0.9, 10 * strength, Color.WHITE, "ring")
	add_part(x, y, 0, 0, 1.2, 5 * strength, Color.WHITE, "ring")

func clamp_cam(p: Vector2) -> Vector2:
	var min_y := -250.0 + view_size.y / 2
	var max_y := Geo.WORLD_BOTTOM - view_size.y / 2
	var cx := Geo.WORLD_W / 2 if view_size.x >= Geo.WORLD_W else clampf(p.x, view_size.x / 2, Geo.WORLD_W - view_size.x / 2)
	var cy := (min_y + max_y) / 2 if min_y > max_y else clampf(p.y, min_y, max_y)
	return Vector2(cx, cy)

func view_rect() -> Rect2:
	return Rect2(cam - view_size / 2, view_size)

func world_to_screen(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * p

func screen_to_world(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * p

# ================================================================== current
func cur_at(x: float, y: float) -> Vector2:
	var e := Geo.eu_x(y)
	var a := Geo.as_x(y)
	var u := clampf((x - e) / (a - e), 0, 1)
	var s: float = cur.str * (0.3 + 0.7 * sin(PI * u))
	return Vector2(cos(cur.ang), sin(cur.ang)) * s

func update_current(dt: float, d: Dictionary, playing: bool) -> void:
	cur.shift_t -= dt
	if cur.shift_t <= 0:
		cur.shift_t = randf_range(14, 24)
		cur.target = PI / 2 + randf_range(-d.cur_swing, d.cur_swing)
		if sefer >= 3 and randf() < 0.2:
			cur.target = -PI / 2 + randf_range(-0.4, 0.4)
		if playing:
			ui.toast("Akıntı yön değiştiriyor!", 1.6)
	cur.ang += Geo.ang_diff(cur.target, cur.ang) * minf(1, dt * 0.5)
	cur.str = d.cur * (0.85 + 0.15 * sin(t * 0.3))
	var v := view_rect()
	while streaks.size() < 60:
		streaks.append({"x": randf_range(v.position.x, v.end.x), "y": randf_range(v.position.y, v.end.y), "life": randf_range(0, 3), "max": 3.0})
	for s in streaks:
		var c := cur_at(s.x, s.y)
		s.x += c.x * 2.2 * dt
		s.y += c.y * 2.2 * dt
		s.life -= dt
		if s.life <= 0 or not v.grow(60).has_point(Vector2(s.x, s.y)):
			s.x = randf_range(v.position.x, v.end.x)
			s.y = randf_range(v.position.y, v.end.y)
			s.max = randf_range(2, 3.5)
			s.life = s.max

# ================================================================== collisions
func body_circles(o) -> Array:
	var n := maxi(1, int(round(o.L / o.B)))
	var r: float = o.B / 2
	var out := []
	for i in n:
		var off: float = 0.0 if n == 1 else -o.L / 2 + r + i * (o.L - 2 * r) / (n - 1)
		out.append(Vector3(o.x + cos(o.ang) * off, o.y + sin(o.ang) * off, r))
	return out

func closest_gap(a, b) -> Dictionary:
	var ca := body_circles(a)
	var cb := body_circles(b)
	var best := {"gap": 1e9, "nx": 0.0, "ny": 0.0}
	for p in ca:
		for q in cb:
			var dx: float = p.x - q.x
			var dy: float = p.y - q.y
			var dd := sqrt(dx * dx + dy * dy)
			if dd < 0.001:
				dd = 0.001
			var gap: float = dd - p.z - q.z
			if gap < best.gap:
				best = {"gap": gap, "nx": dx / dd, "ny": dy / dd}
	return best

func shore_clamp(o, half_l: float, r: float) -> bool:
	var hit := false
	for off in [-half_l, 0.0, half_l]:
		var px: float = o.x + cos(o.ang) * off
		var py: float = o.y + sin(o.ang) * off
		var e := Geo.eu_x(py) + r
		var a := Geo.as_x(py) - r
		if px < e:
			o.x += e - px
			hit = true
		elif px > a:
			o.x -= px - a
			hit = true
		for p in piers:
			var xa := minf(p.sx, p.tip) - r
			var xb := maxf(p.sx, p.tip) + r
			var ya := p.y - 42 - r
			var yb := p.y + 42 + r
			var qx: float = o.x + cos(o.ang) * off
			var qy: float = o.y + sin(o.ang) * off
			if qx > xa and qx < xb and qy > ya and qy < yb:
				var pen_x: float = (xb - qx) if p.dir > 0 else (qx - xa)
				var pen_t: float = qy - ya
				var pen_b: float = yb - qy
				var m := minf(pen_x, minf(pen_t, pen_b))
				if m == pen_x:
					o.x += p.dir * pen_x
				elif m == pen_t:
					o.y -= pen_t
				else:
					o.y += pen_b
				hit = true
		var qx2: float = o.x + cos(o.ang) * off
		var qy2: float = o.y + sin(o.ang) * off
		var dm := Vector2(qx2, qy2).distance_to(Geo.MAIDEN)
		var rr := Geo.MAIDEN_R + r
		if dm < rr:
			var k := (rr - dm) / maxf(dm, 1.0)
			o.x += (qx2 - Geo.MAIDEN.x) * k
			o.y += (qy2 - Geo.MAIDEN.y) * k
			hit = true
	if o.y < Geo.WATER_TOP + 40:
		o.y = Geo.WATER_TOP + 40
		hit = true
	if o.y > Geo.WORLD_BOTTOM - 24:
		o.y = Geo.WORLD_BOTTOM - 24
		hit = true
	return hit

# ================================================================== passengers
func queue_spot(p: Pier, i: int) -> Vector2:
	var col := i % 2
	var row := i / 2
	return Vector2(p.tip - p.dir * (12 + col * 17), p.y - 26 + row * 18)

func spawn_passenger(p: Pier, d: Dictionary) -> void:
	var cross := []
	var same := []
	for q in piers:
		if q == p:
			continue
		if q.side != p.side:
			cross.append(q)
		else:
			same.append(q)
	var dst: Pier = cross.pick_random() if randf() < 0.65 else same.pick_random()
	p.queue.append({"dest": dst.id, "pat": d.patience * randf_range(0.9, 1.1), "max_pat": d.patience * 1.1, "skin": Geo.SKIN.pick_random(), "hair": Geo.HAIR.pick_random(), "fade": 0.0})

func update_piers(dt: float, d: Dictionary, playing: bool) -> void:
	for p in piers:
		p.pulse = maxf(0, p.pulse - dt * 1.2)
		p.spawn_t -= dt
		if p.spawn_t <= 0:
			p.spawn_t = d.pax_every * randf_range(0.7, 1.4)
			if p.queue.size() < 8:
				spawn_passenger(p, d)
		var served := ferry != null and ferry.docked == p
		for i in range(p.queue.size() - 1, -1, -1):
			var q: Dictionary = p.queue[i]
			q.fade = minf(1, q.fade + dt * 3)
			if not served:
				q.pat -= dt
			if q.pat <= 0:
				var s := queue_spot(p, i)
				p.queue.remove_at(i)
				if playing:
					lost_pax += 1
					add_score(-25)
					add_text(s.x, s.y - 26, "Yolcu küstü! -25", Color("#ffd0d0"), 13)
					sfx.play("sad", -6)

func dock_at(f: Ferry, p: Pier) -> void:
	f.docked = p
	f.transfer_t = 0.5
	f.dock_delivered = 0
	f.full_on_arrive = f.pax.size() >= f.cap
	f.full_given = false
	f.spd = 0
	p.pulse = 1
	sfx.play("horn", -4)
	add_text(p.bx, p.by - 46, "Yanaşıldı!", Color.WHITE, 18)
	for i in 16:
		add_part(p.bx + randf_range(-30, 30), p.by + randf_range(-36, 36), randf_range(-20, 20), randf_range(-20, 20), 0.9, randf_range(5, 9), Color.WHITE, "foam")

func do_transfers(dt: float, f: Ferry, p: Pier, d: Dictionary) -> void:
	f.transfer_t -= dt
	if f.transfer_t > 0:
		return
	var idx := -1
	for i in f.pax.size():
		if f.pax[i].dest == p.id:
			idx = i
			break
	if idx >= 0:
		f.pax.remove_at(idx)
		f.dock_delivered += 1
		delivered += 1
		total_delivered += 1
		var mult := 1.0 + 0.25 * (f.dock_delivered - 1)
		var pts := int(round(d.pts * mult))
		add_score(pts)
		time_left += 1
		var label := "+" + str(pts)
		if f.dock_delivered > 1:
			label += "  Kombo ×" + ("%.2f" % mult).replace(".", ",")
		add_text(p.tip + p.dir * 10, p.by - 24 - f.dock_delivered * 5, label, Color("#ffe14d"), 17)
		sfx.play("ding", -6, 1.0 + 0.06 * (f.dock_delivered - 1))
		burst(p.tip, p.y, 12, [Color("#ffe14d"), p.color, Color.WHITE, Color("#ff7ab6")], 80, "conf", 1.2, 4)
		if f.full_on_arrive and not f.full_given:
			f.full_given = true
			var b := 150 + (sefer - 1) * 25
			add_score(b)
			add_text(p.bx, p.by - 70, "Tam Kadro! +" + str(b), Color("#7dffb0"), 18)
			sfx.play("bonus", -4)
		if state == "play" and delivered == target:
			ui.toast("Hedefe ulaşıldı! Fazlası bonus!", 2)
			sfx.play("target", -3)
		f.transfer_t = 0.32
		return
	if f.pax.size() < f.cap and p.queue.size() > 0:
		var q: Dictionary = p.queue.pop_front()
		f.pax.append({"dest": q.dest, "col": piers[q.dest].color, "skin": q.skin})
		sfx.play("board", -10, randf_range(0.95, 1.1))
		add_part(p.tip, p.y, p.dir * 30, 0, 0.5, 4, piers[q.dest].color, "spark")
		f.transfer_t = 0.28
		return
	f.transfer_t = 0.2

# ================================================================== player ferry
func new_ferry(p: Pier) -> Ferry:
	var f := Ferry.new()
	f.x = p.bx
	f.y = p.by
	f.docked = p
	return f

func read_input(f: Ferry) -> Vector2:
	var thr := 0.0
	var turn := 0.0
	if Input.is_action_pressed("up"): thr += 1
	if Input.is_action_pressed("down"): thr -= 1
	if Input.is_action_pressed("left"): turn -= 1
	if Input.is_action_pressed("right"): turn += 1
	var joy: Vector2 = ui.joy_vec if ui else Vector2.ZERO
	if joy.length() > 0.18:
		var des := joy.angle()
		var dd := Geo.ang_diff(des, f.ang)
		turn = clampf(dd * 2.2, -1, 1)
		thr = joy.length() * maxf(0.12, cos(dd))
	return Vector2(thr, turn)

func update_ferry(dt: float, d: Dictionary) -> void:
	var f := ferry
	f.inv = maxf(0, f.inv - dt)
	f.undock_cd = maxf(0, f.undock_cd - dt)
	f.throw_cd = maxf(0, f.throw_cd - dt)
	f.slow_hint = maxf(0, f.slow_hint - dt)
	if f.simit < f.simit_max:
		f.simit_charge += dt
		if f.simit_charge >= 3:
			f.simit_charge = 0
			f.simit += 1
	else:
		f.simit_charge = 0
	_emit_smoke(f, dt, Vector2(-3, 0), 0.16)
	var inp := read_input(f)
	f.roll = lerpf(f.roll, clampf(-inp.y * absf(f.spd) / 60.0, -1.2, 1.2) + sin(t * 2.0) * 0.25, minf(1, dt * 3))
	if f.docked:
		var p := f.docked
		if absf(inp.x) > 0.1 or absf(inp.y) > 0.1:
			f.docked = null
			f.undock_cd = 1.6
			f.left_pier = p
			f.spd = 18.0 if inp.x >= 0 else -10.0
			sfx.play("horn", -6, 1.05)
			add_text(f.x, f.y - 40, "Kalkış!", Color.WHITE, 15)
		else:
			var k := minf(1, dt * 3)
			f.x = lerpf(f.x, p.bx, k)
			f.y = lerpf(f.y, p.by, k)
			var tgt := -PI / 2 if absf(Geo.ang_diff(-PI / 2, f.ang)) < PI / 2 else PI / 2
			f.ang += Geo.ang_diff(tgt, f.ang) * k
			f.spd = 0
			f.kx = 0
			f.ky = 0
			do_transfers(dt, f, p, d)
			_update_trail(f.trail, f, dt, 1.6, false)
			return
	if inp.x > 0:
		f.spd += 70 * inp.x * dt
	elif inp.x < 0:
		f.spd += (120.0 if f.spd > 0 else 40.0) * inp.x * dt
	else:
		f.spd -= f.spd * 0.45 * dt
	f.spd = clampf(f.spd, -45, 135)
	var tr := 1.45 * (0.45 + 0.55 * minf(1, absf(f.spd) / 70))
	f.ang += inp.y * tr * dt
	var cu := cur_at(f.x, f.y)
	var kd := exp(-2.5 * dt)
	f.kx *= kd
	f.ky *= kd
	f.x += (cos(f.ang) * f.spd + cu.x + f.kx) * dt
	f.y += (sin(f.ang) * f.spd + cu.y + f.ky) * dt
	bump_cd = maxf(0, bump_cd - dt)
	if shore_clamp(f, 30, 12):
		if absf(f.spd) > 45 and bump_cd <= 0:
			sfx.play("bump", -4)
			shake = maxf(shake, 5)
			bump_cd = 0.6
			add_text(f.x, f.y - 30, "Dikkat, kıyı!", Color.WHITE, 13)
			splash(f.x + cos(f.ang) * 34, f.y + sin(f.ang) * 34, 8, 1.0)
		f.spd *= pow(0.1, dt)
	var sp := absf(f.spd)
	_update_trail(f.trail, f, dt, 1.6, sp > 8)
	f.wake_t -= dt
	if sp > 8 and f.wake_t <= 0:
		f.wake_t = 0.06
		var sx := f.x - cos(f.ang) * 36
		var sy := f.y - sin(f.ang) * 36
		var nx := -sin(f.ang)
		var ny := cos(f.ang)
		for sg in [-1.0, 1.0]:
			add_part(sx + nx * sg * 7, sy + ny * sg * 7, nx * sg * 14, ny * sg * 14, 1.1, 3 + sp * 0.03, Color.WHITE, "foam")
		if sp > 40:
			add_part(f.x + cos(f.ang) * 36 + nx * randf_range(-6, 6), f.y + sin(f.ang) * 36 + ny * randf_range(-6, 6), nx * randf_range(-30, 30), ny * randf_range(-30, 30), 0.5, randf_range(1.2, 2.2), Color.WHITE, "drop")
	if f.undock_cd <= 0:
		for p in piers:
			var dd := Vector2(f.x, f.y).distance_to(Vector2(p.bx, p.by))
			if p == f.left_pier:
				if dd > Geo.DOCK_R + 12:
					f.left_pier = null
				else:
					continue
			if dd < Geo.DOCK_R:
				if absf(f.spd) < 42:
					dock_at(f, p)
					break
				f.slow_hint = 0.3

func _emit_smoke(o, dt: float, local: Vector2, every: float) -> void:
	o.smoke_t -= dt
	if o.smoke_t <= 0:
		o.smoke_t = every
		var p := Vector2(o.x, o.y) + local.rotated(o.ang)
		add_part(p.x, p.y, randf_range(-5, 5) - cos(o.ang) * 8 + 6, randf_range(-14, -6) - sin(o.ang) * 8, 1.8, 5, Color(0.55, 0.57, 0.62), "smoke")

func _update_trail(trail: Array, o, dt: float, life: float, emit: bool) -> void:
	for pt in trail:
		pt.age += dt
	while trail.size() > 0 and trail[0].age > life:
		trail.pop_front()
	if emit:
		var last: Dictionary = trail[trail.size() - 1] if trail.size() > 0 else {}
		var stern = Vector2(o.x, o.y) - Vector2(cos(o.ang), sin(o.ang)) * (o.L / 2 - 4)
		if last.is_empty() or last.p.distance_to(stern) > 7 or last.age > 0.12:
			trail.append({"p": stern, "n": Vector2(-sin(o.ang), cos(o.ang)), "age": 0.0, "w": o.B * 0.32})

func hit_ferry(kind: String, nx: float, ny: float) -> void:
	var f := ferry
	if f.inv > 0 or state != "play":
		return
	var C: Dictionary = {
		"ship": {"dmg": 34, "pen": 100, "force": 170.0, "label": "Gemiye çarptın!", "shake": 16.0},
		"vapur": {"dmg": 20, "pen": 50, "force": 130.0, "label": "Vapura çarptın!", "shake": 10.0},
		"kayik": {"dmg": 10, "pen": 25, "force": 90.0, "label": "Kayığa çarptın!", "shake": 6.0},
	}[kind]
	can = maxf(0, can - C.dmg)
	add_score(-C.pen)
	f.inv = 1.6
	f.kx = nx * C.force
	f.ky = ny * C.force
	f.spd *= 0.15
	shake = C.shake
	flash = 0.55
	flash_col = Color(1, 0.27, 0.27)
	add_text(f.x, f.y - 44, C.label, Color("#ff6b6b"), 17)
	add_text(f.x, f.y - 22, "-%d can  -%d puan" % [C.dmg, C.pen], Color.WHITE, 13)
	sfx.play("hit_small" if kind == "kayik" else "hit_big", -2)
	burst(f.x, f.y, 18, [Color.WHITE, Color("#c9a57c"), Color("#8a5a35"), Color("#ffcf33")], 100, "spark", 0.7, 3)
	splash(f.x - nx * 20, f.y - ny * 20, 14, 1.4)
	if can <= 0:
		game_over("Vapur ağır hasar aldı!")

# ================================================================== traffic
func spawn_ship(d: Dictionary) -> bool:
	var south := randf() < 0.55
	var x: float = ([565.0, 640.0] if south else [760.0, 835.0]).pick_random() + randf_range(-12, 12)
	var y := -170.0 if south else Geo.WORLD_BOTTOM + 240
	for s in ships:
		if absf(s.x - x) < 70 and absf(s.y - y) < 340:
			return false
	var s := Ship.new()
	s.kind = "tanker" if randf() < 0.5 else "cargo"
	var tank := s.kind == "tanker"
	for i in 60:
		s.boxes.append(Color(SHIP_BOX.pick_random()))
	s.x = x
	s.y = y
	s.ang = PI / 2 if south else -PI / 2
	s.L = randf_range(190, 230) if tank else randf_range(170, 210)
	s.B = 44.0 if tank else 40.0
	s.hull = Color(["#b8473d", "#2f5d8a", "#3c7a52", "#7a3b6b"].pick_random() if tank else ["#2f4f7a", "#a83a3a", "#2b6b5a", "#4a4a5a"].pick_random())
	s.deck = Color(["#c9725f", "#a8b2a0", "#c99e6a"].pick_random()) if tank else Color("#8d8f94")
	s.funnel = Color(["#ffcf33", "#e8434b", "#2f7fe0", "#ffffff"].pick_random())
	s.spd = d.tanker_spd * randf_range(0.85, 1.1)
	s.base = s.spd
	s.horn_cd = randf_range(1, 4)
	ships.append(s)
	return true

func spawn_kayik(d: Dictionary, anywhere: bool) -> void:
	var v := view_rect().grow(30)
	for tries in 25:
		var y := randf_range(60, Geo.WORLD_BOTTOM - 60)
		var x := randf_range(Geo.eu_x(y) + 60, Geo.as_x(y) - 60)
		if ferry and Vector2(x, y).distance_to(Vector2(ferry.x, ferry.y)) < 380:
			continue
		if not anywhere and v.has_point(Vector2(x, y)):
			continue
		var bad := false
		for p in piers:
			if Vector2(x, y).distance_to(Vector2(p.bx, p.by)) < 150:
				bad = true
		if bad or Vector2(x, y).distance_to(Geo.MAIDEN) < 90:
			continue
		var k := Kayik.new()
		k.x = x
		k.y = y
		k.ang = randf() * TAU
		k.t_ang = randf() * TAU
		k.base = d.kayik_spd * randf_range(0.6, 1.0)
		k.turn_t = randf_range(1, 3)
		k.ph = randf() * TAU
		k.col = Color(["#9b5e2e", "#2aa3b8", "#e8434b", "#ffffff", "#3c7a52"].pick_random())
		k.skin = Geo.SKIN.pick_random()
		k.hat = Color(["#d64545", "#2f5d8a", "#f5f5f5", "#3c7a52"].pick_random())
		k.rod = randf() < 0.45
		k.tex_i = randi() % 3
		kayiks.append(k)
		return

func spawn_vapur(d: Dictionary) -> void:
	var lanes := []
	for ly in [300.0, 880.0, 1180.0]:
		var used := false
		for v in vapurs:
			if v.lane == ly:
				used = true
		if not used:
			lanes.append(ly)
	if lanes.is_empty():
		return
	var lane: float = lanes.pick_random()
	var east := randf() < 0.5
	var x := Geo.eu_x(lane) + 110 if east else Geo.as_x(lane) - 110
	if ferry and Vector2(x, lane).distance_to(Vector2(ferry.x, ferry.y)) < 220:
		x = Geo.as_x(lane) - 110 if east else Geo.eu_x(lane) + 110
	var v := AiVapur.new()
	for i in 8:
		if randf() < 0.7:
			v.pax.append({"col": Color(["#d9d9e8", "#ffffff", "#c7b8a8", "#a9c7d8", "#e8434b", "#2f7fe0"].pick_random()), "skin": Geo.SKIN.pick_random()})
	v.x = x
	v.y = lane
	v.lane = lane
	v.ang = 0.0 if x < 700 else PI
	v.t_ang = v.ang
	v.spd = d.vapur_spd
	v.band = Color(["#2f7fe0", "#1d3557", "#2bb36b"].pick_random())
	v.funnel = Color(["#ffcf33", "#e8434b"].pick_random())
	vapurs.append(v)

func update_traffic(dt: float, d: Dictionary, playing: bool) -> void:
	var f := ferry
	tanker_t -= dt
	if tanker_t <= 0:
		tanker_t = d.tanker_every * randf_range(0.7, 1.3)
		if ships.size() < d.max_ships and not spawn_ship(d):
			tanker_t = 1
	for i in range(ships.size() - 1, -1, -1):
		var s: Ship = ships[i]
		var spd := s.base
		for o in ships:
			if o != s and absf(o.x - s.x) < 60 and signf(o.ang) == signf(s.ang):
				var ahead: float = (o.y - s.y) * signf(sin(s.ang))
				if ahead > 0 and ahead < (o.L + s.L) / 2 + 70:
					spd = minf(spd, o.base * 0.9)
		s.spd = lerpf(s.spd, spd, minf(1, dt))
		s.x += cos(s.ang) * s.spd * dt
		s.y += sin(s.ang) * s.spd * dt
		s.horn_cd -= dt
		if playing and f and s.horn_cd <= 0 and Vector2(s.x, s.y).distance_to(Vector2(f.x, f.y)) < 300:
			sfx.play("ship_horn", -6)
			s.horn_cd = 9
		_update_trail(s.trail, s, dt, 2.6, s.y > Geo.WATER_TOP)
		_emit_smoke(s, dt, Vector2(-s.L / 2 + 15, 0), 0.22)
		s.wake_t -= dt
		if s.wake_t <= 0 and s.y > Geo.WATER_TOP:
			s.wake_t = 0.1
			var bow := Vector2(s.x, s.y) + Vector2(cos(s.ang), sin(s.ang)) * s.L / 2
			add_part(bow.x + randf_range(-6, 6), bow.y + randf_range(-6, 6), randf_range(-10, 10), randf_range(-10, 10), 0.8, 6, Color.WHITE, "foam")
		if s.y > Geo.WORLD_BOTTOM + 320 or s.y < -280:
			ships.remove_at(i)
	# kayıklar
	while kayiks.size() < d.kayiks:
		var n := kayiks.size()
		spawn_kayik(d, not playing and t < 1)
		if kayiks.size() == n:
			break
	for k in kayiks:
		k.turn_t -= dt
		k.hit_cd = maxf(0, k.hit_cd - dt)
		if k.turn_t <= 0:
			k.t_ang = k.ang + randf_range(-1.3, 1.3)
			k.turn_t = randf_range(1, 3.5)
		if k.x < Geo.eu_x(k.y) + 70: k.t_ang = randf_range(-0.5, 0.5)
		if k.x > Geo.as_x(k.y) - 70: k.t_ang = PI + randf_range(-0.5, 0.5)
		if k.y < 70: k.t_ang = PI / 2
		if k.y > Geo.WORLD_BOTTOM - 70: k.t_ang = -PI / 2
		for p in piers:
			if Vector2(k.x, k.y).distance_to(Vector2(p.bx, p.by)) < 130:
				k.t_ang = atan2(k.y - p.by, k.x - p.bx)
		if Vector2(k.x, k.y).distance_to(Geo.MAIDEN) < 90:
			k.t_ang = atan2(k.y - Geo.MAIDEN.y, k.x - Geo.MAIDEN.x)
		for s in ships:
			if absf(k.x - s.x) < 70 and absf(k.y - s.y) < s.L / 2 + 50:
				k.t_ang = PI if k.x < s.x else 0.0
		k.ang += Geo.ang_diff(k.t_ang, k.ang) * minf(1, dt * 1.5) + k.spin * dt
		k.spin *= exp(-2 * dt)
		k.spd = k.base * (0.6 + 0.4 * sin(t * 2 + k.ph))
		var cu := cur_at(k.x, k.y)
		var kd := exp(-2.5 * dt)
		k.kx *= kd
		k.ky *= kd
		k.x += (cos(k.ang) * k.spd + cu.x * 0.5 + k.kx) * dt
		k.y += (sin(k.ang) * k.spd + cu.y * 0.5 + k.ky) * dt
		shore_clamp(k, 10, 7)
		if randf() < dt * 2.5:
			add_part(k.x - cos(k.ang) * 15, k.y - sin(k.ang) * 15, 0, 0, 0.9, 2.5, Color.WHITE, "foam")
	# other ferries
	if vapurs.size() < d.vapurs:
		spawn_vapur(d)
	while vapurs.size() > d.vapurs:
		vapurs.pop_back()
	for v in vapurs:
		v.fade = minf(1, v.fade + dt)
		if v.state == "move":
			v.x += cos(v.ang) * v.spd * dt
			v.y = lerpf(v.y, v.lane, minf(1, dt))
			var east := cos(v.ang) > 0
			if (east and v.x > Geo.as_x(v.y) - 95) or (not east and v.x < Geo.eu_x(v.y) + 95):
				v.state = "wait"
				v.wait_t = 2.5
				v.t_ang = v.ang + PI
		else:
			v.wait_t -= dt
			v.ang += Geo.ang_diff(v.t_ang, v.ang) * minf(1, dt * 1.6)
			if v.wait_t <= 0:
				v.ang = v.t_ang
				v.state = "move"
		_update_trail(v.trail, v, dt, 1.4, v.state == "move")
		_emit_smoke(v, dt, Vector2(-3, 0), 0.22)
	if not playing or f == null or f.docked:
		return
	for s in ships:
		if absf(s.y - f.y) > s.L / 2 + 80 or absf(s.x - f.x) > 120:
			continue
		var c := closest_gap(f, s)
		if c.gap < 0:
			hit_ferry("ship", c.nx, c.ny)
			f.x += c.nx * (-c.gap + 2)
			f.y += c.ny * (-c.gap + 2)
		elif c.gap < 26 and not s.near and absf(f.spd) > 35 and f.inv <= 0:
			s.near = true
			near_miss += 1
			add_score(25)
			add_text(f.x, f.y - 40, "Kıl payı! +25", Color("#ffe14d"), 16)
			sfx.play("tick", -2, 1.3)
			flash = 0.25
			flash_col = Color(1, 0.9, 0.35)
	for v in vapurs:
		if Vector2(v.x, v.y).distance_to(Vector2(f.x, f.y)) > 110:
			continue
		var c := closest_gap(f, v)
		if c.gap < 0:
			hit_ferry("vapur", c.nx, c.ny)
			f.x += c.nx * (-c.gap + 2)
			f.y += c.ny * (-c.gap + 2)
	for k in kayiks:
		if Vector2(k.x, k.y).distance_to(Vector2(f.x, f.y)) > 80:
			continue
		var c := closest_gap(f, k)
		if c.gap < 0:
			k.kx = -c.nx * 120
			k.ky = -c.ny * 120
			k.spin = randf_range(-4, 4)
			if f.inv <= 0 and k.hit_cd <= 0:
				hit_ferry("kayik", c.nx, c.ny)
				k.hit_cd = 1
			f.x += c.nx * (-c.gap + 1)
			f.y += c.ny * (-c.gap + 1)

# ================================================================== gulls & simit
func spawn_gull() -> void:
	var v := view_rect()
	var f := ferry
	var side := randi() % 4
	var x: float
	var y: float
	match side:
		0:
			x = randf_range(v.position.x, v.end.x); y = v.position.y - 50
		1:
			x = randf_range(v.position.x, v.end.x); y = v.end.y + 50
		2:
			x = v.position.x - 50; y = randf_range(v.position.y, v.end.y)
		_:
			x = v.end.x + 50; y = randf_range(v.position.y, v.end.y)
	var c := Vector2(f.x, f.y) if f else v.get_center()
	var tgt := c + Vector2(randf_range(-220, 220), randf_range(-200, 200))
	var a := atan2(tgt.y - y, tgt.x - x)
	var g := Gull.new()
	g.sp = randf_range(55, 85)
	g.x = x
	g.y = y
	g.vx = cos(a) * g.sp
	g.vy = sin(a) * g.sp
	g.h = randf_range(1, 1.6)
	g.ph = randf() * TAU
	g.follow = f != null and randf() < 0.4
	g.orbit_a = randf() * TAU
	g.orbit_r = randf_range(85, 150)
	g.orbit_dir = 1.0 if randf() < 0.5 else -1.0
	g.follow_t = randf_range(8, 14)
	g.squawk_t = randf_range(2, 9)
	gulls.append(g)

func update_gulls(dt: float, d: Dictionary, playing: bool) -> void:
	var v := view_rect()
	var f := ferry
	var active := 0
	for g in gulls:
		if g.state != "happy":
			active += 1
	gull_t -= dt
	if active < d.gulls and gull_t <= 0:
		spawn_gull()
		gull_t = randf_range(0.8, 2)
	for i in range(gulls.size() - 1, -1, -1):
		var g: Gull = gulls[i]
		g.life += dt
		if g.state == "fly":
			if g.follow and f and Vector2(g.x, g.y).distance_to(Vector2(f.x, f.y)) < 320:
				g.state = "orbit"
			var a := atan2(g.vy, g.vx) + sin(t * 1.3 + g.ph) * 0.5 * dt
			g.vx = cos(a) * g.sp
			g.vy = sin(a) * g.sp
		elif g.state == "orbit":
			g.orbit_a += dt * 0.8 * g.orbit_dir
			var tx := f.x + cos(g.orbit_a) * g.orbit_r
			var ty := f.y + sin(g.orbit_a) * g.orbit_r * 0.8
			g.vx += ((tx - g.x) * 1.6 - g.vx * 0.9) * dt
			g.vy += ((ty - g.y) * 1.6 - g.vy * 0.9) * dt
			var s := Vector2(g.vx, g.vy).length()
			if s > 120:
				g.vx *= 120 / s
				g.vy *= 120 / s
			if s < 25:
				g.vx += cos(g.orbit_a + 1.57) * 10
				g.vy += sin(g.orbit_a + 1.57) * 10
			g.follow_t -= dt
			if g.follow_t <= 0:
				g.state = "fly"
				g.follow = false
				var sp := maxf(Vector2(g.vx, g.vy).length(), 1.0)
				g.sp = 70
				g.vx *= 70 / sp
				g.vy *= 70 / sp
		else:
			g.happy_t += dt
			g.vy -= 70 * dt
			g.vx *= exp(-dt)
			g.h += dt * 0.9
			if randf() < dt * 6:
				add_part(g.x, g.y - 6, randf_range(-10, 10), -30, 1, 5, Color("#ff6fa8"), "heart")
		g.x += g.vx * dt
		g.y += g.vy * dt
		g.squawk_t -= dt
		if g.squawk_t <= 0:
			g.squawk_t = randf_range(6, 14)
			if v.has_point(Vector2(g.x, g.y)) and randf() < 0.5:
				sfx.play(["gull1", "gull2", "gull3"].pick_random(), -14, randf_range(0.9, 1.15))
		var far := not v.grow(500).has_point(Vector2(g.x, g.y))
		if (g.state == "happy" and g.happy_t > 2.6) or (g.life > 4 and far) or g.life > 50:
			gulls.remove_at(i)

func lead_target(g: Gull, fx: float, fy: float) -> Vector2:
	var T := clampf(Vector2(fx, fy).distance_to(Vector2(g.x, g.y)) / 380.0, 0.3, 0.95)
	return Vector2(g.x + g.vx * T, g.y + g.vy * T)

func throw_simit(tpos = null) -> void:
	var f := ferry
	if state != "play" or f == null or f.throw_cd > 0:
		return
	if f.simit < 1:
		add_text(f.x, f.y - 42, "Simit kalmadı!", Color("#ffe6c0"), 14)
		sfx.play("tick", -6, 0.8)
		f.throw_cd = 0.4
		return
	var tgt: Vector2
	if tpos == null:
		var best: Gull = null
		var bs := 1e9
		for g in gulls:
			if g.state == "happy":
				continue
			var dx: float = g.x - f.x
			var dy: float = g.y - f.y
			var dd := sqrt(dx * dx + dy * dy)
			if dd > 420 or dd < 20:
				continue
			var a := absf(Geo.ang_diff(atan2(dy, dx), f.ang))
			if a > 1.15:
				continue
			var sc := dd * (1 + a)
			if sc < bs:
				bs = sc
				best = g
		tgt = lead_target(best, f.x, f.y) if best else Vector2(f.x, f.y) + Vector2(cos(f.ang), sin(f.ang)) * 240
	else:
		var tp: Vector2 = tpos
		var dv := tp - Vector2(f.x, f.y)
		var dd := maxf(dv.length(), 1.0)
		tgt = Vector2(f.x, f.y) + dv / dd * minf(dd, 420)
		var best: Gull = null
		var bd := 75.0
		for g in gulls:
			if g.state == "happy":
				continue
			var q := Vector2(g.x, g.y).distance_to(tp)
			if q < bd:
				bd = q
				best = g
		if best:
			tgt = lead_target(best, f.x, f.y)
	var s := Simit.new()
	s.x0 = f.x; s.y0 = f.y; s.tx = tgt.x; s.ty = tgt.y; s.x = f.x; s.y = f.y
	s.T = clampf(Vector2(f.x, f.y).distance_to(tgt) / 380.0, 0.3, 0.95)
	simits.append(s)
	f.simit -= 1
	f.throw_cd = 0.25
	sfx.play("toss", -6, randf_range(1.0, 1.2))

func update_simits(dt: float, d: Dictionary) -> void:
	for i in range(simits.size() - 1, -1, -1):
		var s: Simit = simits[i]
		if s.state == "fly":
			s.t += dt
			var u := minf(1, s.t / s.T)
			s.x = lerpf(s.x0, s.tx, u)
			s.y = lerpf(s.y0, s.ty, u)
			s.z = sin(PI * u) * 34 + (1 - u) * 8
			s.rot += dt * 10
			var hit: Gull = null
			if u > 0.12:
				for g in gulls:
					if g.state != "happy" and Vector2(s.x, s.y - s.z * 0.5).distance_to(Vector2(g.x, g.y)) < 28:
						hit = g
						break
			if hit:
				hit.state = "happy"
				hit.happy_t = 0
				hit.vx *= 0.4
				hit.vy = -40
				gulls_fed += 1
				total_gulls += 1
				var pts: int = d.gull_pts
				add_score(pts)
				add_text(hit.x, hit.y - 22, ["Martı mutlu!", "Afiyet olsun!", "Tam isabet!", "Simit keyfi!"].pick_random() + " +" + str(pts), Color.WHITE, 16)
				burst(hit.x, hit.y, 7, [Color("#ff6fa8"), Color("#ff9ec7")], 40, "heart", 1.1, 6)
				burst(hit.x, hit.y, 12, [Color("#fff4d6"), Color("#e3a65a")], 70, "spark", 0.6, 2.5)
				burst(hit.x, hit.y, 4, [Color("#fff6c8")], 30, "star", 0.8, 10)
				sfx.play("gull_happy", -4, randf_range(0.95, 1.1))
				simits.remove_at(i)
				continue
			if u >= 1:
				s.state = "float"
				s.life = 2.6
				splash(s.x, s.y, 10, 0.8)
				sfx.play("splash", -10, randf_range(1.1, 1.3))
		else:
			s.life -= dt
			var c := cur_at(s.x, s.y)
			s.x += c.x * dt
			s.y += c.y * dt
			s.rot += dt * 0.5
			if s.life <= 0:
				simits.remove_at(i)

func update_fx(dt: float) -> void:
	for i in range(parts.size() - 1, -1, -1):
		var p: Part = parts[i]
		p.life -= dt
		if p.life <= 0:
			parts.remove_at(i)
			continue
		p.x += p.vx * dt
		p.y += p.vy * dt
		match p.type:
			"foam", "smoke":
				var k := exp(-1.5 * dt)
				p.vx *= k
				p.vy *= k
			"conf":
				p.vy += 60 * dt
				p.rot += dt * 8
			"drop":
				p.vy += 90 * dt
			"heart":
				p.vy -= 10 * dt
			"star":
				p.rot += dt * 3
	for i in range(texts.size() - 1, -1, -1):
		var tx: FText = texts[i]
		tx.life -= dt
		tx.y -= 22 * dt
		if tx.life <= 0:
			texts.remove_at(i)
	flash = maxf(0, flash - dt * 1.5)
	shake = maxf(0, shake - dt * 30)

# ================================================================== camera
func update_camera(dt: float) -> void:
	var tgt: Vector2
	if state == "menu":
		demo_t += dt * 0.06
		var n := DEMO_PATH.size()
		var i := int(floor(demo_t)) % n
		var u := fmod(demo_t, 1.0)
		var s := (1 - cos(PI * u)) / 2
		tgt = DEMO_PATH[i].lerp(DEMO_PATH[(i + 1) % n], s)
	elif ferry:
		tgt = Vector2(ferry.x, ferry.y) + Vector2(cos(ferry.ang), sin(ferry.ang)) * ferry.spd * 0.7
	else:
		tgt = cam
	var c := clamp_cam(tgt)
	var k := 1.0 if state == "menu" else minf(1, dt * 3)
	cam = clamp_cam(cam.lerp(c, k))

# ================================================================== flow
func clear_world() -> void:
	ships.clear(); kayiks.clear(); vapurs.clear(); gulls.clear()
	simits.clear(); parts.clear(); texts.clear(); streaks.clear()

func init_menu_scene() -> void:
	clear_world()
	for p in piers:
		p.queue.clear()
		p.spawn_t = randf_range(0, 2)
		p.pulse = 0
		for i in 3:
			spawn_passenger(p, menu_diff)
	ferry = new_ferry(piers[2])
	for i in 5:
		var dst: int = [0, 1, 3].pick_random()
		ferry.pax.append({"dest": dst, "col": piers[dst].color, "skin": Geo.SKIN.pick_random()})
	cur.ang = PI / 2
	cur.target = PI / 2
	cur.str = menu_diff.cur
	cur.shift_t = 20
	if spawn_ship(menu_diff):
		ships[ships.size() - 1].y = 520
	if spawn_ship(menu_diff):
		ships[ships.size() - 1].y = 1250
	for i in 6:
		spawn_kayik(menu_diff, true)
	tanker_t = 6
	demo_t = 0

func go_menu() -> void:
	if state in ["play", "paused", "results"]:
		save_scores()
	state = "menu"
	init_menu_scene()
	ui.show_screen("title")
	sfx.set_music("menu")

func start_game() -> void:
	sefer = 1
	score = 0
	can = 100
	total_delivered = 0
	total_gulls = 0
	run_start_hs = int(save.hs)
	new_record = false
	start_sefer()

func start_sefer() -> void:
	var d := Geo.diff(sefer)
	time_left = d.time
	target = d.target
	delivered = 0
	gulls_fed = 0
	near_miss = 0
	lost_pax = 0
	sefer_start_score = score
	clear_world()
	for p in piers:
		p.queue.clear()
		p.spawn_t = randf_range(1, 3)
		p.pulse = 0
		spawn_passenger(p, d)
		spawn_passenger(p, d)
	ferry = new_ferry(piers[0])
	cur.ang = PI / 2
	cur.target = PI / 2
	cur.str = d.cur
	cur.shift_t = randf_range(15, 22)
	tanker_t = 2.5
	gull_t = 0.3
	last_sec = -1
	flash = 0
	shake = 0
	state = "play"
	cam = clamp_cam(Vector2(ferry.x, ferry.y))
	ui.show_screen("")
	ui.toast("Sefer %d — Hedef: %d yolcu" % [sefer, target], 2.6)
	sfx.play("horn", -3)
	sfx.set_music("game")

func end_sefer() -> void:
	if delivered < target:
		game_over("Süre doldu! Hedef %d yolcuydu, %d yolcu taşındı." % [target, delivered])
		return
	var extra := (delivered - target) * 50
	var can_bonus := int(round(can)) * 2
	add_score(extra + can_bonus)
	state = "results"
	save_scores()
	ui.show_results({
		"title": "Sefer %d Tamamlandı!" % sefer,
		"rows": [
			["Teslim edilen yolcu", "%d / %d" % [delivered, target]],
			["Martıya simit", str(gulls_fed)],
			["Kıl payı geçiş", str(near_miss)],
			["Küsen yolcu", str(lost_pax)],
			["Fazla yolcu bonusu", "+" + Geo.fmt(extra)],
			["Sağlam gövde bonusu", "+" + Geo.fmt(can_bonus)],
			["Sefer puanı", Geo.fmt(score - sefer_start_score)],
			["Toplam puan", Geo.fmt(score), "total"],
		],
		"note": "Sonraki seferde trafik ve akıntı artacak. Tamirciler gövdeyi biraz onardı (+25 can).",
	})
	sfx.play("win", -2)

func next_sefer() -> void:
	sefer += 1
	can = minf(100, can + 25)
	start_sefer()

func game_over(reason: String) -> void:
	state = "over"
	save_scores()
	ui.show_over({
		"reason": reason, "score": Geo.fmt(score) + " puan", "record": new_record, "hs": Geo.fmt(save.hs),
		"rows": [["Ulaşılan sefer", str(sefer)], ["Toplam teslim edilen yolcu", str(total_delivered)], ["Mutlu edilen martı", str(total_gulls)]],
	})
	sfx.play("lose", -2)

func pause_game() -> void:
	if state != "play":
		return
	state = "paused"
	ui.show_screen("pause")

func resume_game() -> void:
	if state != "paused":
		return
	state = "play"
	ui.show_screen("")

# ================================================================== input
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch and ev.pressed:
		if not touch_used:
			touch_used = true
			refresh_touch_mode()
		if state == "play":
			throw_simit(screen_to_world(ev.position))
			get_viewport().set_input_as_handled()
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if state == "play":
			throw_simit(get_global_mouse_position())
			get_viewport().set_input_as_handled()
		return
	if ev.is_action_pressed("simit") and not ev.is_echo():
		if state == "play":
			throw_simit()
			get_viewport().set_input_as_handled()
	elif ev.is_action_pressed("pause") and not ev.is_echo():
		if state == "play":
			pause_game()
			get_viewport().set_input_as_handled()
		elif state == "paused":
			resume_game()
			get_viewport().set_input_as_handled()
		elif state == "menu" and ev is InputEventKey and ev.physical_keycode == KEY_ESCAPE:
			ui.back_to_title()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if state == "play" and t > 1.0:
			pause_game()

# ================================================================== main loop
func _process(delta: float) -> void:
	var dt := clampf(delta, 0.0, 0.05)
	if state == "play":
		t += dt
		var d := Geo.diff(sefer)
		time_left -= dt
		update_current(dt, d, true)
		update_ferry(dt, d)
		update_piers(dt, d, true)
		update_traffic(dt, d, true)
		if state == "play":
			update_gulls(dt, d, true)
			update_simits(dt, d)
			var sec := int(ceil(time_left))
			if sec <= 10 and sec > 0 and sec != last_sec:
				last_sec = sec
				sfx.play("tick", -4)
			if time_left <= 0:
				time_left = 0
				end_sefer()
		update_fx(dt)
	elif state != "paused":
		t += dt
		var d: Dictionary = menu_diff if state == "menu" else Geo.diff(sefer)
		update_current(dt, d, false)
		if state == "menu" and ferry:
			ferry.roll = sin(t * 2.0) * 0.3
		update_piers(dt, d, false)
		update_traffic(dt, d, false)
		update_gulls(dt, d, false)
		update_simits(dt, d)
		update_fx(dt)
	if state != "paused":
		update_camera(dt)
	var sh := Vector2.ZERO
	if shake > 0:
		sh = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	camera.position = cam
	camera.offset = sh
	# time of day: each sefer goes from bright noon towards a golden Bosphorus sunset
	var ph := 0.22
	if state in ["play", "paused", "results", "over"]:
		ph = clampf(0.08 * (sefer - 1) + 0.42 * (1.0 - time_left / 100.0), 0.0, 0.85)
	day_phase = lerpf(day_phase, ph, minf(1, dt * 2))
	modulate_node.color = Color(1, 1, 1).lerp(Color(1.0, 0.86, 0.78), day_phase * 0.55)
	water_mat.set_shader_parameter("phase", day_phase)
	water_mat.set_shader_parameter("cur_vec", Vector2(cos(cur.ang), sin(cur.ang)) * cur.str)
	for k in layers:
		layers[k].queue_redraw()
	_publish_state(delta)

# Small read-only status object for automated browser tests (window.__bogaz).
var _pub_t := 0.0
func _publish_state(delta: float) -> void:
	if not OS.has_feature("web"):
		return
	_pub_t -= delta
	if _pub_t > 0:
		return
	_pub_t = 0.25
	var info := {
		"state": state, "screen": ui.current, "sefer": sefer, "score": score, "time": time_left, "touch": touch_mode,
		"ferry": [ferry.x, ferry.y, ferry.spd, ferry.simit, ferry.pax.size(), ferry.docked != null] if ferry else [],
		"vs": [get_viewport_rect().size.x, get_viewport_rect().size.y], "rects": ui.debug_rects(), "fps": Engine.get_frames_per_second(),
	}
	JavaScriptBridge.eval("window.__bogaz = " + JSON.stringify(info) + ";", true)

# ================================================================== rendering
func text_at(c: CanvasItem, pos: Vector2, s: String, size: int, col: Color, outline := 5) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := pos + Vector2(-w / 2, size * 0.32)
	c.draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(0.11, 0.21, 0.34, 0.9 * col.a))
	c.draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _visible(p: Vector2, margin: float) -> bool:
	return view_rect().grow(margin).has_point(p)

func draw_water(c: CanvasItem) -> void:
	c.draw_rect(Rect2(-260, Geo.WATER_TOP - 20, Geo.WORLD_W + 520, Geo.WORLD_BOTTOM - Geo.WATER_TOP + 420), Color.WHITE)

func _draw_wake(c: CanvasItem, trail: Array, life: float, spread: float, alpha := 1.0) -> void:
	var n := trail.size()
	if n < 2:
		return
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var mid := PackedVector2Array()
	var cols := PackedColorArray()
	var midc := PackedColorArray()
	for i in n:
		var pt: Dictionary = trail[i]
		var u: float = pt.age / life
		var off: float = pt.w + pt.age * spread
		left.append(pt.p + pt.n * off)
		right.append(pt.p - pt.n * off)
		mid.append(pt.p)
		cols.append(Color(1, 1, 1, (1.0 - u) * 0.75 * alpha))
		midc.append(Color(0.9, 0.97, 1.0, (1.0 - u) * (1.0 - u) * 0.45 * alpha))
	c.draw_polyline_colors(mid, midc, trail[0].w * 1.6, true)
	c.draw_polyline_colors(left, cols, 2.2, true)
	c.draw_polyline_colors(right, cols, 2.2, true)

func _dashed_circle(c: CanvasItem, center: Vector2, r: float, off: float, col: Color, w: float) -> void:
	var n := 18
	for i in n:
		var a0 := TAU * i / n + off
		c.draw_arc(center, r, a0, a0 + TAU / n * 0.55, 6, col, w, true)

func draw_under(c: CanvasItem) -> void:
	var v := view_rect()
	# current streaks
	if cur.str >= 1:
		var ca := cos(cur.ang)
		var sa := sin(cur.ang)
		var ln: float = 10 + cur.str * 0.55
		for s in streaks:
			if s.y < Geo.WATER_TOP:
				continue
			var a: float = sin(PI * (s.life / s.max)) * 0.42
			if a <= 0.02:
				continue
			var col := Color(1, 1, 1, a)
			var p := Vector2(s.x, s.y)
			c.draw_line(p - Vector2(ca, sa) * ln, p, col, 1.6, true)
			c.draw_line(p, p - Vector2(ca * 4 + sa * 3, sa * 4 - ca * 3), col, 1.6, true)
			c.draw_line(p, p - Vector2(ca * 4 - sa * 3, sa * 4 + ca * 3), col, 1.6, true)
	# wakes
	for s in ships:
		_draw_wake(c, s.trail, 2.6, 16)
	for vp in vapurs:
		_draw_wake(c, vp.trail, 1.4, 22, vp.fade)
	if ferry:
		_draw_wake(c, ferry.trail, 1.6, 24)
	# dock rings
	var dests := {}
	if ferry:
		for q in ferry.pax:
			dests[q.dest] = true
	for p in piers:
		if not _visible(Vector2(p.bx, p.by), 120):
			continue
		var hl := dests.has(p.id)
		var col := p.color if hl else Color(1, 1, 1)
		col.a = (0.65 + 0.3 * sin(t * 5)) if hl else 0.45
		_dashed_circle(c, Vector2(p.bx, p.by), Geo.DOCK_R * 0.8, t * 0.4, col, 4.0 if hl else 2.5)
		if hl:
			c.draw_circle(Vector2(p.bx, p.by), Geo.DOCK_R * 0.8, Color(p.color, 0.08 + 0.05 * sin(t * 5)))
		if p.pulse > 0:
			c.draw_arc(Vector2(p.bx, p.by), Geo.DOCK_R * (1.3 - p.pulse * 0.5), 0, TAU, 40, Color(p.color, p.pulse), 3.0, true)
	# water-level particles
	for p in parts:
		var u: float = p.life / p.max
		if p.type == "foam":
			var sz: float = p.size * (1.6 - u * 0.6) * 2.4
			c.draw_texture_rect(tex_soft, Rect2(Vector2(p.x, p.y) - Vector2(sz, sz) / 2, Vector2(sz, sz)), false, Color(1, 1, 1, u * 0.75))
		elif p.type == "ring":
			c.draw_arc(Vector2(p.x, p.y), p.size * (2.0 - u), 0, TAU, 24, Color(1, 1, 1, u * 0.8), 2.0, true)
	# floating simits
	for sm in simits:
		if sm.state == "float":
			Art.draw_simit(c, Vector2(sm.x, sm.y + sin(t * 3 + sm.x)), 5, sm.rot, minf(1, sm.life))

func draw_piers(c: CanvasItem) -> void:
	for p in piers:
		if not _visible(Vector2(p.bx, p.by), 160):
			continue
		for i in p.queue.size():
			var q: Dictionary = p.queue[i]
			var s := queue_spot(p, i)
			var bob := sin(t * 3 + i) * 0.6
			Art.draw_person(c, s, piers[q.dest].color, q.skin, q.hair, minf(1, q.fade), bob)
			var ratio: float = q.pat / q.max_pat
			if ratio < 0.3 and sin(t * 12) > -0.2:
				c.draw_circle(s + Vector2(6, -19), 4.6, Color("#ffdf3d"))
				c.draw_arc(s + Vector2(6, -19), 4.6, 0, TAU, 14, Geo.NAVY, 1.0, true)
				c.draw_rect(Rect2(s + Vector2(5.2, -22), Vector2(1.6, 3.6)), Color("#c0202a"))
				c.draw_rect(Rect2(s + Vector2(5.2, -17.6), Vector2(1.6, 1.4)), Color("#c0202a"))
		# name sign above the terminal
		var w := font.get_string_size(p.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 20
		var sp := Vector2(p.tx, p.y - 80)
		Art.rrect(c, Rect2(sp + Vector2(-w / 2 + 2, -12 + 3), Vector2(w, 24)), 9, Color(0.11, 0.21, 0.34, 0.35))
		Art.rrect(c, Rect2(sp + Vector2(-w / 2 - 2, -14), Vector2(w + 4, 28)), 11, Geo.NAVY)
		Art.rrect(c, Rect2(sp + Vector2(-w / 2, -12), Vector2(w, 24)), 9, p.color)
		Art.rrect(c, Rect2(sp + Vector2(-w / 2 + 3, -10), Vector2(w - 6, 9)), 5, Color(1, 1, 1, 0.18))
		var tw := font.get_string_size(p.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		c.draw_string(font, sp + Vector2(-tw / 2, 5.5), p.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

func draw_boats(c: CanvasItem) -> void:
	var sun := Vector2(6, 9)
	for k in kayiks:
		if _visible(Vector2(k.x, k.y), 40):
			Art.ellipse(c, Vector2(k.x, k.y) + sun * 0.5, 9, 9, Color(0.02, 0.12, 0.22, 0.14), 12)
	for vp in vapurs:
		if _visible(Vector2(vp.x, vp.y), 80):
			Art.hull_shadow(c, Vector2(vp.x, vp.y), vp.ang, 76, 26, 16, 7, sun, vp.fade)
	for s in ships:
		if _visible(Vector2(s.x, s.y), 160):
			Art.hull_shadow(c, Vector2(s.x, s.y), s.ang, s.L, s.B, s.L * 0.2, 9, sun * 1.6)
	if ferry:
		Art.hull_shadow(c, Vector2(ferry.x, ferry.y), ferry.ang, 76, 26, 16, 7, sun + Vector2(ferry.roll, 0))
	for k in kayiks:
		if _visible(Vector2(k.x, k.y), 40):
			Art.draw_kayik(c, k, t, dinghies[k.tex_i])
	for vp in vapurs:
		if _visible(Vector2(vp.x, vp.y), 80):
			Art.draw_vapur(c, Vector2(vp.x, vp.y), vp.ang, t, {"band": vp.band, "funnel": vp.funnel, "pax": vp.pax, "alpha": vp.fade, "roll": sin(t * 1.7 + vp.lane) * 0.4})
	for s in ships:
		if _visible(Vector2(s.x, s.y), 160):
			Art.draw_ship(c, s, t)
	if ferry:
		var bob := sin(t * 2) * 0.02
		Art.draw_vapur(c, Vector2(ferry.x, ferry.y), ferry.ang + bob, t, {"pax": ferry.pax, "roll": ferry.roll, "blink": ferry.inv > 0 and int(t * 12) % 2 == 0, "band": Color("#e8434b")})

func draw_air(c: CanvasItem) -> void:
	for p in parts:
		var u: float = p.life / p.max
		match p.type:
			"smoke":
				var sz: float = p.size * (2.2 - u * 1.2) * 3.2
				c.draw_set_transform(Vector2(p.x, p.y), p.rot + (1 - u), Vector2.ONE)
				c.draw_texture_rect(tex_smoke, Rect2(-Vector2(sz, sz) / 2, Vector2(sz, sz)), false, Color(p.col, u * 0.5))
				c.draw_set_transform_matrix(Transform2D.IDENTITY)
			"heart":
				var s: float = p.size * 0.5
				var pp := Vector2(p.x, p.y)
				var col := Color(p.col, minf(1, u * 1.5))
				c.draw_circle(pp + Vector2(-s * 0.55, -s * 0.3), s * 0.62, col)
				c.draw_circle(pp + Vector2(s * 0.55, -s * 0.3), s * 0.62, col)
				c.draw_colored_polygon(PackedVector2Array([pp + Vector2(-s * 1.15, -s * 0.1), pp + Vector2(s * 1.15, -s * 0.1), pp + Vector2(0, s * 1.2)]), col)
			"conf":
				c.draw_set_transform(Vector2(p.x, p.y), p.rot, Vector2.ONE)
				c.draw_rect(Rect2(-p.size / 2, -p.size / 4, p.size, p.size / 2), Color(p.col, minf(1, u * 2)))
				c.draw_set_transform_matrix(Transform2D.IDENTITY)
			"star":
				var sz2: float = p.size * (0.6 + u)
				c.draw_set_transform(Vector2(p.x, p.y), p.rot, Vector2.ONE)
				c.draw_texture_rect(tex_star, Rect2(-Vector2(sz2, sz2) / 2, Vector2(sz2, sz2)), false, Color(p.col, u))
				c.draw_set_transform_matrix(Transform2D.IDENTITY)
			"drop":
				c.draw_circle(Vector2(p.x, p.y), p.size * (0.5 + u * 0.5), Color(1, 1, 1, u * 0.9))
			"spark":
				c.draw_circle(Vector2(p.x, p.y), p.size, Color(p.col, u))
	# flying simits
	for sm in simits:
		if sm.state == "fly":
			Art.ellipse(c, Vector2(sm.x + sm.z * 0.3, sm.y + sm.z * 0.2), 5, 2.4, Color(0.04, 0.16, 0.27, 0.22), 12)
			Art.draw_simit(c, Vector2(sm.x, sm.y - sm.z), 5.5, sm.rot)
	# flags on landmarks
	for fl in land.flags:
		if _visible(fl[0], 40):
			Art.draw_pole_flag(c, fl[0], fl[1], t)

func draw_bridge(c: CanvasItem) -> void:
	var y := Geo.BRIDGE_Y
	var v := view_rect()
	if v.position.y > y + 60 or v.end.y < y - 130:
		return
	var x0 := Geo.eu_x(y) - 34
	var x1 := Geo.as_x(y) + 34
	var L := -300.0
	var R := Geo.WORLD_W + 300
	c.draw_rect(Rect2(L, y + 20, R - L, 14), Color(0.04, 0.16, 0.27, 0.2))
	c.draw_rect(Rect2(L, y - 11, R - L, 22), Color("#c3cbd5"))
	c.draw_rect(Rect2(L, y - 9, R - L, 18), Color("#e9edf2"))
	c.draw_rect(Rect2(L, y - 9, R - L, 2.5), Color("#b7c0cb"))
	c.draw_rect(Rect2(L, y + 6.5, R - L, 2.5), Color("#b7c0cb"))
	var xx := L
	while xx < R:
		c.draw_line(Vector2(xx, y), Vector2(xx + 10, y), Color(0.55, 0.59, 0.63, 0.8), 1.0)
		xx += 20
	var car_cols := [Color("#e8434b"), Color("#ffcf33"), Color("#2f7fe0"), Color.WHITE, Color("#2bb36b"), Color("#f08a1c"), Color("#333a44")]
	var span := R - L
	for i in 18:
		var dirn := 1.0 if i % 2 == 1 else -1.0
		var cx := fposmod(t * (45 + (i % 3) * 12) * dirn + i * 211, span) + L
		var cy := y + (1.8 if dirn > 0 else -6.0)
		Art.rrect(c, Rect2(cx - 5, cy, 10, 4.5), 1.5, car_cols[i % car_cols.size()])
		c.draw_rect(Rect2(cx + (2 if dirn > 0 else -4), cy + 0.8, 2, 3), Color(0.2, 0.3, 0.45, 0.7))
	var top_y := y - 96
	var cable := PackedVector2Array()
	for i in 41:
		var u := float(i) / 40.0
		cable.append(Art._qbez(Vector2(x0, top_y), Vector2((x0 + x1) / 2, y + 40), Vector2(x1, top_y), u))
	for off in [-1.5, 1.5]:
		c.draw_polyline(Art.scaled(cable, 1, 1, Vector2(0, off)), Color("#8c96a3"), 2.2, true)
		var side_l := PackedVector2Array()
		var side_r := PackedVector2Array()
		for i in 11:
			var u := float(i) / 10.0
			side_l.append(Art._qbez(Vector2(L, y - 14), Vector2((x0 + L) / 2, top_y + 50), Vector2(x0, top_y), u) + Vector2(0, off))
			side_r.append(Art._qbez(Vector2(x1, top_y), Vector2((x1 + R) / 2, top_y + 50), Vector2(R, y - 14), u) + Vector2(0, off))
		c.draw_polyline(side_l, Color("#8c96a3"), 2.2, true)
		c.draw_polyline(side_r, Color("#8c96a3"), 2.2, true)
	var hx := x0 + 22
	while hx < x1:
		var u := (hx - x0) / (x1 - x0)
		var cy := Art._qbez(Vector2(x0, top_y), Vector2((x0 + x1) / 2, y + 40), Vector2(x1, top_y), u).y
		c.draw_line(Vector2(hx, cy), Vector2(hx, y - 8), Color(0.55, 0.59, 0.63, 0.7), 0.8)
		hx += 22
	for tx in [x0, x1]:
		c.draw_rect(Rect2(tx - 5, top_y + 6, 14, y - top_y + 6), Color(0, 0, 0, 0.12))
		c.draw_rect(Rect2(tx - 7, top_y, 5, y - top_y + 6), Color("#d4dae2"))
		c.draw_rect(Rect2(tx + 2, top_y, 5, y - top_y + 6), Color("#c4cbd4"))
		c.draw_rect(Rect2(tx - 7, top_y + 20, 14, 4), Color("#b7c0cb"))
		c.draw_rect(Rect2(tx - 7, top_y + 52, 14, 4), Color("#b7c0cb"))
		var on := sin(t * 4) > 0
		c.draw_circle(Vector2(tx, top_y - 3), 2.6, Color("#ff3b3b") if on else Color("#a02020"))
		if on:
			c.draw_texture_rect(tex_glow, Rect2(Vector2(tx, top_y - 3) - Vector2(12, 12), Vector2(24, 24)), false, Color(1, 0.3, 0.3, 0.6))

func draw_gulls(c: CanvasItem) -> void:
	for g in gulls:
		if _visible(Vector2(g.x, g.y), 40):
			Art.draw_gull(c, g, t)

func draw_texts(c: CanvasItem) -> void:
	for tx in texts:
		var u: float = tx.life / tx.max
		var sc := 1.0 + maxf(0, u - 0.85) * 3.0
		text_at(c, Vector2(tx.x, tx.y), tx.txt, int(tx.size * sc), Color(tx.col, minf(1, u * 2.5)))
	if ferry and state == "play":
		var label := ""
		var col := Color.WHITE
		if ferry.docked:
			label = "Yanaşıldı"
			col = Color("#bfffd6")
		elif ferry.slow_hint > 0:
			label = "Yavaşla!"
			col = Color("#ffe14d")
		if label != "":
			text_at(c, Vector2(ferry.x, ferry.y - 32), label, 14, col, 4)
