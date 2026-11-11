## Çölde Hayatta Kalma — game controller: scene setup, day/night, weather,
## survival rules, interaction, crafting, saving, tutorial and the test bridge.
extends Node3D

const HudScript := preload("res://scripts/hud.gd")
const InvScript := preload("res://scripts/inv_panel.gd")
const MapScript := preload("res://scripts/map_view.gd")
const MenuScript := preload("res://scripts/menus.gd")
const SAVE := "user://save.json"
const FOG := 150

# --- scene ---
var env: Environment
var sun: DirectionalLight3D
var cam: Camera3D
var ui: CanvasLayer
var hud: Control
var inv_panel: Control
var map_view: Control
var menus: Control
var storm_rect: ColorRect
var vig_rect: ColorRect
var loading: Label
var sand_fx: CPUParticles3D
var heli: Node3D

# --- world/game ---
var g: WorldGen
var world: World
var player: Player
var animals: Animals
var weather := Weather.new()
var s := Survival.new()
var inv: Array = []
var canteen := 2
var cap := GameData.CANTEEN_CAP
var t_abs := 0.0
var tod := 0.0
var day := 1
var seed_v := 0
var playing := false
var paused := false
var panel := ""
var touch := false
var zoom := 1.0
var cam_pos := Vector3.ZERO

# --- per-frame derived state (read by HUD) ---
var prompt := ""
var target := {}
var in_shade := false
var near_fire := false
var shelter_name := ""
var ambient_shown := 30.0
var cam_yaw := 0.0
var compass_jitter := 0.0
var storm_state := ""
var storm_eta := 0.0

# --- progress ---
var fog := PackedByteArray()
var map_base: Image
var discovered := {}
var markers: Array = []
var radio := {"installed": false, "sent_at": -1.0, "arrived": false}
var tut := {}
var last_day_seen := 1
var _tick := 0.0
var _slow := 0.0
var _attack_cd := 0.0
var _hurt_flash := 0.0
var _bridge_t := 0.0
var _test := false
var _fps := 0.0
var _title_t := 0.0
var world_ready := false
var world_used := false
var _dl_shown := true

func _ready() -> void:
	UiKit.init()
	touch = Settings.touch
	_test = OS.has_feature("web") and str(JavaScriptBridge.eval("location.search", true)).contains("test=1")
	_setup_input()
	_setup_scene()
	Settings.changed.connect(_apply_quality)
	var icons := Icons.new()
	add_child(icons)
	icons.build(self)
	# backdrop world for the title screen: the saved world or a fresh seed
	var sv := _read_save()
	await _generate(int(sv.seed) if sv else _random_seed())
	_apply_quality()
	_show_title()
	if "--smoke" in OS.get_cmdline_user_args():
		add_child(load("res://tools/smoke.gd").new())

func _random_seed() -> int:
	return int(Time.get_unix_time_from_system()) % 1000000 + randi() % 1000

# ---------------------------------------------------------------- setup
func _setup_input() -> void:
	var keys := {
		"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"run": [KEY_SHIFT], "interact": [KEY_E, KEY_SPACE], "attack": [KEY_F], "drink": [KEY_Q],
		"bag": [KEY_TAB, KEY_I], "map": [KEY_M], "pause": [KEY_ESCAPE, KEY_P],
	}
	for a in keys:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		for k in keys[a]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(a, ev)

func _setup_scene() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#f5d7a1")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.9, 0.8)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.fog_enabled = true
	env.fog_light_color = Color("#f2d2a0")
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_curve = 1.6
	env.fog_sky_affect = 1.0
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.shadow_bias = 0.08
	add_child(sun)
	cam = Camera3D.new()
	cam.fov = 50.0
	cam.near = 0.3
	add_child(cam)
	cam.make_current()
	# sandstorm particles follow the camera target
	sand_fx = CPUParticles3D.new()
	sand_fx.amount = 160
	sand_fx.lifetime = 1.6
	sand_fx.mesh = Fx.billboard("dirt_02", Color(0.95, 0.74, 0.45, 0.55), false, 0.6)
	sand_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sand_fx.emission_box_extents = Vector3(22, 5, 22)
	sand_fx.gravity = Vector3.ZERO
	sand_fx.initial_velocity_min = 14.0; sand_fx.initial_velocity_max = 22.0
	sand_fx.spread = 8.0
	sand_fx.emitting = false
	add_child(sand_fx)
	# UI layers
	ui = CanvasLayer.new()
	add_child(ui)
	vig_rect = ColorRect.new()
	vig_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vig_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new(); vm.shader = load("res://shaders/vignette.gdshader")
	vig_rect.material = vm
	ui.add_child(vig_rect)
	storm_rect = ColorRect.new()
	storm_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	storm_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new(); sm.shader = load("res://shaders/storm.gdshader")
	storm_rect.material = sm
	storm_rect.visible = false
	ui.add_child(storm_rect)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiKit.theme
	ui.add_child(root)
	hud = HudScript.new()
	root.add_child(hud)
	hud.setup(self, touch)
	hud.visible = false
	inv_panel = InvScript.new(); root.add_child(inv_panel); inv_panel.setup(self)
	map_view = MapScript.new(); root.add_child(map_view); map_view.setup(self)
	menus = MenuScript.new(); root.add_child(menus); menus.setup(self)
	loading = UiKit.label("Çöl oluşturuluyor…", 30, Color("#fff4dc"), true, 6)
	loading.set_anchors_preset(Control.PRESET_CENTER)
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(loading)

func _apply_quality() -> void:
	var q := Settings.q()
	sun.shadow_enabled = q.shadows
	sun.directional_shadow_max_distance = 30.0 if Settings.quality == 1 else 50.0
	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	get_viewport().scaling_3d_scale = q.scale
	cam.far = q.far + 20.0
	sand_fx.amount = Fx.amount(160)

# ---------------------------------------------------------------- world generation / flow
func _generate(sd: int) -> void:
	world_ready = false
	loading.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	if world:
		world.queue_free()
		animals.queue_free()
		player.queue_free()
		if heli:
			heli.queue_free(); heli = null
	seed_v = sd
	g = WorldGen.new()
	g.generate(sd)
	world = World.new()
	add_child(world)
	world.build(g)
	animals = Animals.new()
	animals.world = world
	add_child(animals)
	animals.bite.connect(_on_bite)
	player = Player.new()
	add_child(player)
	player.setup(world)
	player.pos = Vector2(3.5, 4.5)
	player.move(Vector2.ZERO, false, 1.0, 0.0, false)
	_make_map_base()
	loading.visible = false
	world_ready = true

func _make_map_base() -> void:
	map_base = Image.create(FOG, FOG, false, Image.FORMAT_RGB8)
	for j in FOG:
		for i in FOG:
			var p := Vector2(-WorldGen.HALF + (i + 0.5) * 4.0, -WorldGen.HALF + (j + 0.5) * 4.0)
			var c := world._biome_color(p, g.height(p.x, p.y))
			# contour shading for the dunes
			var sh := g.height(p.x - 2, p.y) - g.height(p.x + 2, p.y)
			map_base.set_pixel(i, j, c.lightened(clampf(sh * 0.08, -0.2, 0.2)))

func _show_title() -> void:
	playing = false
	hud.visible = false
	menus.show_title()
	Sfx.set_music("menu")
	Sfx.set_loop("storm", 0.0)
	Sfx.set_loop("fire", 0.0)
	tod = 120.0
	_update_sky(0.0)

func _reset_state(diff: int) -> void:
	s = Survival.new()
	s.diff = diff
	inv.clear()
	for i in GameData.SLOTS:
		inv.append(null)
	canteen = 2
	cap = GameData.CANTEEN_CAP
	t_abs = 20.0
	day = 1
	last_day_seen = 1
	discovered = {"wreck": true}
	markers = []
	radio = {"installed": false, "sent_at": -1.0, "arrived": false}
	tut = {}
	fog = PackedByteArray(); fog.resize(FOG * FOG)
	weather = Weather.new()
	weather.setup(seed_v)
	player.dead = false
	player.pos = Vector2(3.5, 4.5)
	player.set_spear(false)

func new_game(diff: int) -> void:
	menus.hide_all()
	_delete_save()
	if world == null or seed_v == 0 or world_used:
		await _generate(_random_seed())
	_reset_state(diff)
	world_used = true
	_start_play()
	hud.toast("Uçak düştü... Ama hayattasın.", Color("#ffe7b8"))

func continue_game() -> void:
	var sv := _read_save()
	if sv == null:
		return
	menus.hide_all()
	if int(sv.seed) != seed_v or world_used:
		await _generate(int(sv.seed))
	_reset_state(int(sv.diff))
	_load_save(sv)
	world_used = true
	_start_play()
	hud.toast("%d. gün, şafak." % day, Color("#ffe7b8"))

func _start_play() -> void:
	playing = true
	paused = false
	panel = ""
	hud.visible = true
	animals.clear()
	player.visible = true
	_update_env_state()

func resume() -> void:
	menus.hide_all()
	paused = false

func quit_to_title(save := true) -> void:
	if save and playing and not s.dead():
		write_save()
	menus.hide_all()
	close_panels()
	world_used = true
	_show_title()

func on_hud_button(k: String) -> void:
	if not playing or paused:
		return
	match k:
		"bag": _toggle_panel("bag")
		"map": _toggle_panel("map")
		"pause": _pause()

func _pause() -> void:
	close_panels()
	paused = true
	menus.show_pause()

func _toggle_panel(p: String) -> void:
	if panel == p:
		close_panels()
		return
	close_panels()
	panel = p
	Sfx.play("open", -6.0)
	if p == "bag":
		inv_panel.open()
	else:
		map_view.open()

func close_panels() -> void:
	if panel != "":
		Sfx.play("close", -8.0)
	panel = ""
	inv_panel.visible = false
	map_view.visible = false

# ---------------------------------------------------------------- save / load
func has_save() -> bool:
	return FileAccess.file_exists(SAVE)

func save_info() -> Dictionary:
	var sv := _read_save()
	return {"day": int(sv.day) if sv else 1, "diff": int(sv.diff) if sv else 1}

func _read_save() -> Variant:
	if not FileAccess.file_exists(SAVE):
		return null
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	return d if d is Dictionary and d.get("v", 0) == 1 else null

func _delete_save() -> void:
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

func write_save() -> void:
	var nodes := {}
	for i in world.nodes.size():
		if world.nodes[i].get("hidden", false):
			nodes[str(i)] = world.nodes[i].ready_at
	var pl := []
	for it in world.placed:
		pl.append({"kind": it.kind, "x": it.p.x, "y": it.p.y, "left": it.get("left", 0.0), "water": it.get("water", 0.0), "caught": it.get("caught", false)})
	var cr := []
	for it in world.crates:
		cr.append({"kind": it.kind, "x": it.p.x, "y": it.p.y, "loot": it.get("loot", {}), "model": it.get("model", ""), "scale": it.get("scale", 0.25), "label": it.get("label", "")})
	var inv_s := []
	for e in inv:
		inv_s.append(e if e else {})
	var d := {
		"v": 1, "seed": seed_v, "diff": s.diff, "t": t_abs, "day": day, "s": s.to_dict(),
		"pos": [player.pos.x, player.pos.y], "inv": inv_s, "canteen": canteen, "cap": cap,
		"nodes": nodes, "opened": world.opened, "wells": world.wells_b, "placed": pl, "crates": cr,
		"fog": Marshalls.raw_to_base64(fog.compress(FileAccess.COMPRESSION_DEFLATE)),
		"discovered": discovered, "markers": markers.map(func(m): return [m.x, m.y]),
		"radio": radio, "weather": weather.to_dict(), "tut": tut, "lds": last_day_seen,
	}
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))
		f.close()

func _load_save(d: Dictionary) -> void:
	t_abs = float(d.t)
	day = int(d.day)
	last_day_seen = int(d.get("lds", day))
	s.from_dict(d.s)
	player.pos = Vector2(d.pos[0], d.pos[1])
	for i in GameData.SLOTS:
		var e: Dictionary = d.inv[i] if i < d.inv.size() else {}
		inv[i] = {"id": e.id, "n": int(e.n)} if e.has("id") else null
	canteen = int(d.canteen); cap = int(d.cap)
	for k in d.nodes:
		world.harvest_node(int(k), 0.0)
		world.nodes[int(k)].ready_at = float(d.nodes[k])
	world.opened = d.opened
	world.wells_b = d.wells.map(func(b): return int(b))
	for p in d.placed:
		var it := world.place(p.kind, Vector2(p.x, p.y), {"left": float(p.left), "water": float(p.water), "caught": bool(p.caught)})
		if it.kind == "fire":
			world.set_fire_lit(it, it.left > 0.0)
	for c in d.crates:
		var data := {"loot": c.loot}
		if c.kind == "carcass":
			data.merge({"model": c.model, "scale": float(c.scale), "label": c.label})
		world.place(c.kind, Vector2(c.x, c.y), data)
	fog = Marshalls.base64_to_raw(d.fog).decompress(FOG * FOG, FileAccess.COMPRESSION_DEFLATE)
	discovered = d.discovered
	markers = d.markers.map(func(m): return Vector2(m[0], m[1]))
	radio = d.radio
	weather.from_dict(d.weather)
	tut = d.tut
	player.set_spear(count("mizrak") > 0)
	if radio.get("arrived", false):
		_spawn_heli(false)

# ---------------------------------------------------------------- main loop
func _process(dt: float) -> void:
	_fps = lerpf(_fps, 1.0 / maxf(dt, 0.001), 0.05)
	_bridge(dt)
	if not world_ready:
		return
	dt = minf(dt, 0.1)
	if not playing:
		_title_cam(dt)
		return
	if paused or s.dead() or panel == "map":
		_update_camera(dt)
		return
	t_abs += dt
	tod = fmod(t_abs, GameData.DAY_LEN)
	day = int(t_abs / GameData.DAY_LEN) + 1
	_attack_cd -= dt
	_hurt_flash = maxf(0.0, _hurt_flash - dt)
	# --- movement ---
	var dir := Vector2.ZERO
	if panel == "":
		dir = Vector2(Input.get_action_strength("right") - Input.get_action_strength("left"), Input.get_action_strength("down") - Input.get_action_strength("up"))
		if hud.touch:
			var jv: Vector2 = hud.move_vec()
			if jv.length() > dir.length():
				dir = jv
		dir = dir.limit_length(1.0)
	var want_run: bool = Input.is_action_pressed("run") or hud.want_run()
	var spd_mul := 0.6 if storm_state == "storm" and shelter_name == "" else 1.0
	if s.exhausted > 0.0:
		spd_mul *= 0.55
	player.move(dir, want_run, spd_mul, dt, s.can_run())
	if player.moving:
		var f := player.forward()
		cam_yaw = atan2(f.x, -f.y)
	# --- environment & survival ---
	_update_env_state()
	var night := GameData.is_night(tod)
	var sun_k := 0.0 if (in_shade or night) else GameData.sun_strength(tod) * (0.4 if storm_state == "storm" else 1.0)
	s.tick(dt, {"sun": sun_k, "ambient": ambient_shown, "moving": player.moving, "running": player.running,
		"night": night, "storm": storm_state == "storm" and shelter_name == "", "climbing": player.climbing})
	# --- world systems ---
	_update_fires(dt, night)
	animals.spawn_tick(dt, player.pos, night, storm_state == "storm")
	animals.update(dt, player.pos, night, world.fires_near(player.pos, 90.0))
	_tick -= dt
	if _tick <= 0.0:
		_tick = 0.12
		target = world.find_interact(player.pos, t_abs)
		prompt = _prompt_for(target)
	_slow -= dt
	if _slow <= 0.0:
		_slow = 0.5
		world.update_nodes(t_abs)
		_reveal()
		_tutorial()
		_check_rescue()
	if day != last_day_seen:
		_new_day()
	_update_sky(dt)
	_update_camera(dt)
	_update_overlays(dt)
	if s.dead() and not player.dead:
		_on_death()

func _update_env_state() -> void:
	var p := player.pos
	in_shade = world.shaded(p)
	shelter_name = world.sheltered(p)
	var fires := world.fires_near(p, GameData.FIRE_RADIUS)
	near_fire = not fires.is_empty()
	var amb := GameData.air_temp(tod, day)
	var night := GameData.is_night(tod)
	if not in_shade and not night:
		amb += GameData.SUN_HEAT * GameData.sun_strength(tod) * (0.4 if storm_state == "storm" else 1.0)
	if near_fire:
		var d: float = p.distance_to(fires[0].p)
		amb += 25.0 * clampf(1.3 - d / GameData.FIRE_RADIUS, 0.3, 1.0)
	if night and shelter_name == "Gölgelik":
		amb += 10.0
	if night and world.in_cave(p):
		amb += 8.0
	if storm_state == "storm" and shelter_name == "":
		amb -= 4.0
	ambient_shown = amb
	var ws := weather.state(t_abs)
	if ws == "warn" and storm_state != "warn":
		Sfx.play("warn", -2.0)
		hud.toast("Ufukta turuncu bir duvar... Kum fırtınası geliyor!", Color("#ffb347"))
	if ws == "" and storm_state == "storm":
		_after_storm()
	storm_state = ws
	storm_eta = maxf(0.0, weather.start_at - t_abs)

func _update_sky(_dt: float) -> void:
	var night := GameData.is_night(tod)
	var ss := GameData.sun_strength(tod)
	var h := GameData.hour_of(tod)
	var storm_k := weather.intensity(t_abs) if playing else 0.0
	var q := Settings.q()
	var day_sky := Color("#f7d9a3")
	var dusk := Color("#f08a4b")
	var night_sky := Color("#0d1426")
	var sky: Color
	var amb_col: Color
	var amb_e: float
	if not night:
		var edge := 1.0 - clampf(ss * 1.6, 0.0, 1.0)
		sky = day_sky.lerp(dusk, edge * 0.7)
		amb_col = Color(1.0, 0.92, 0.82).lerp(Color(1.0, 0.7, 0.55), edge)
		amb_e = lerpf(0.36, 0.5, ss)
		var el := deg_to_rad(lerpf(8.0, 68.0, ss))
		var az := lerpf(-1.4, 1.4, tod / GameData.DAY_PART)
		sun.rotation = Vector3(-el, az + PI, 0)
		sun.light_color = Color(1.0, 0.96, 0.9).lerp(Color(1.0, 0.62, 0.38), edge)
		sun.light_energy = lerpf(0.35, 1.05, ss)
	else:
		var nt := (tod - GameData.DAY_PART) / (GameData.DAY_LEN - GameData.DAY_PART)
		var fade := clampf(minf(nt, 1.0 - nt) * 6.0, 0.0, 1.0)
		sky = dusk.lerp(night_sky, fade) if nt < 0.5 else Color("#f0b27a").lerp(night_sky, fade)
		amb_col = Color(0.42, 0.5, 0.78)
		amb_e = lerpf(0.36, 0.17, fade)
		sun.rotation = Vector3(-deg_to_rad(55.0), lerpf(1.2, -1.2, nt) + PI, 0)
		sun.light_color = Color(0.62, 0.72, 1.0)
		sun.light_energy = lerpf(0.4, 0.2, fade)
	var storm_col := Color("#d39a5c")
	env.background_color = sky.lerp(storm_col, storm_k)
	env.ambient_light_color = amb_col.lerp(Color(1.0, 0.8, 0.6), storm_k * 0.6)
	env.ambient_light_energy = amb_e + storm_k * 0.15
	env.fog_light_color = sky.lerp(storm_col, storm_k)
	# depth fog hides the draw-distance edge; the storm pulls it right up to the player
	var far_f: float = q.far
	var sheltered_k := 1.6 if shelter_name != "" else 1.0
	env.fog_depth_end = lerpf(far_f, 30.0 * sheltered_k, storm_k)
	env.fog_depth_begin = lerpf(far_f * 0.45, 13.0, storm_k)
	env.fog_density = lerpf(1.0, 0.92, storm_k)
	sun.light_energy *= 1.0 - storm_k * 0.55

func _update_camera(dt: float) -> void:
	var vs := get_viewport().get_visible_rect().size
	var portrait := vs.y > vs.x
	var z := zoom * (1.35 if portrait else 1.0)
	var off := Vector3(0, 13.0, 10.0) * z
	var tgt := player.position + Vector3(0, 0.8, 0)
	var want := tgt + off
	cam_pos = want if cam_pos == Vector3.ZERO else cam_pos.lerp(want, minf(1.0, dt * 6.0))
	if _hurt_flash > 0.3:
		cam_pos += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.06
	cam.position = cam_pos
	cam.look_at(cam_pos - off + Vector3(0, 0.0, 0) , Vector3.UP)
	cam.keep_aspect = Camera3D.KEEP_WIDTH if portrait else Camera3D.KEEP_HEIGHT
	cam.fov = 62.0 if portrait else 50.0
	sand_fx.position = player.position + Vector3(0, 2, 0)

func _title_cam(dt: float) -> void:
	_title_t += dt
	tod = fmod(150.0 + _title_t * 2.0, GameData.DAY_LEN)
	var a := _title_t * 0.06
	var c := Vector3(0, g.height(0, 0), 0)
	cam.position = c + Vector3(cos(a) * 22.0, 11.0, sin(a) * 22.0)
	cam.look_at(c + Vector3(0, 1.5, 0), Vector3.UP)
	cam.keep_aspect = Camera3D.KEEP_HEIGHT if get_viewport().get_visible_rect().size.x > get_viewport().get_visible_rect().size.y else Camera3D.KEEP_WIDTH
	_update_sky(dt)
	cam_pos = Vector3.ZERO

func _update_overlays(_dt: float) -> void:
	var k := weather.intensity(t_abs)
	storm_rect.visible = k > 0.01
	var sm := storm_rect.material as ShaderMaterial
	sm.set_shader_parameter("amount", k * (0.35 if shelter_name != "" else 0.6))
	var wd := Vector2.from_angle(weather.dir)
	sm.set_shader_parameter("wind", Vector2(wd.x, wd.y * 0.3))
	sand_fx.emitting = k > 0.2
	sand_fx.direction = Vector3(wd.x, -0.05, wd.y)
	compass_jitter = sin(t_abs * 2.3) * 0.5 * k + sin(t_abs * 5.1) * 0.25 * k
	Sfx.set_loop("storm", k + (0.25 if storm_state == "warn" else 0.0))
	Sfx.set_loop("breeze", 0.0 if k > 0.3 else 0.6)
	var fires := world.fires_near(player.pos, 12.0)
	Sfx.set_loop("fire", 0.0 if fires.is_empty() else clampf(1.0 - player.pos.distance_to(fires[0].p) / 12.0, 0.0, 1.0))
	Sfx.set_music("night" if GameData.is_night(tod) else "day")
	var vm := vig_rect.material as ShaderMaterial
	vm.set_shader_parameter("hurt", clampf((30.0 - s.hp) / 30.0, 0.0, 1.0) + _hurt_flash)
	vm.set_shader_parameter("heat", clampf((s.temp - 38.6) / 1.2, 0.0, 1.0))
	vm.set_shader_parameter("cold", clampf((35.8 - s.temp) / 1.0, 0.0, 1.0))
	vm.set_shader_parameter("thirst", clampf((25.0 - s.water) / 25.0, 0.0, 1.0))
	vm.set_shader_parameter("night", 1.0 if GameData.is_night(tod) else 0.0)

# ---------------------------------------------------------------- input
func _unhandled_input(ev: InputEvent) -> void:
	if not playing:
		return
	if ev.is_action_pressed("pause"):
		if menus.current == "pause":
			resume()
		elif panel != "":
			close_panels()
		elif not s.dead():
			_pause()
		return
	if paused or s.dead():
		return
	if ev.is_action_pressed("bag"):
		_toggle_panel("bag")
	elif ev.is_action_pressed("map"):
		_toggle_panel("map")
	elif panel != "":
		return
	elif ev.is_action_pressed("interact"):
		do_interact()
	elif ev.is_action_pressed("attack"):
		do_attack()
	elif ev.is_action_pressed("drink"):
		do_drink()
	elif ev is InputEventKey and ev.pressed and not ev.echo and ev.physical_keycode >= KEY_1 and ev.physical_keycode <= KEY_4:
		use_slot(ev.physical_keycode - KEY_1)   # quick slots 1-4
	elif ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_LEFT and not touch and ev.device != InputEvent.DEVICE_ID_EMULATION:
			do_attack()
		elif ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 0.08, 0.6, 1.5)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 0.08, 0.6, 1.5)

# ---------------------------------------------------------------- inventory
func count(id: String) -> int:
	var n := 0
	for e in inv:
		if e and e.id == id:
			n += e.n
	return n

## Adds items; returns how many did not fit.
func add_item(id: String, n := 1) -> int:
	for e in inv:
		if n > 0 and e and e.id == id and e.n < GameData.STACK:
			var k: int = mini(n, GameData.STACK - e.n)
			e.n += k; n -= k
	for i in inv.size():
		if n > 0 and inv[i] == null:
			var k: int = mini(n, GameData.STACK)
			inv[i] = {"id": id, "n": k}; n -= k
	return n

func remove_item(id: String, n := 1) -> void:
	for i in range(inv.size() - 1, -1, -1):
		var e: Variant = inv[i]
		if n > 0 and e and e.id == id:
			var k: int = mini(n, e.n)
			e.n -= k; n -= k
			if e.n <= 0:
				inv[i] = null

func give(id: String, n := 1) -> void:
	var left := add_item(id, n)
	var name: String = GameData.ITEMS[id].name
	if left < n:
		hud.toast("+%d %s" % [n - left, name], Color("#fff4dc"))
		Sfx.play("pickup", -4.0)
	if left > 0:
		hud.toast("Çanta dolu! %s yere bırakıldı." % name, Color("#ff9a7a"))
		world.place("crate", player.pos + player.forward() * 1.2, {"loot": {id: left}, "label": "Bırakılan eşya"})

func use_slot(i: int) -> void:
	var e: Variant = inv[i]
	if e == null:
		return
	var it: Dictionary = GameData.ITEMS[e.id]
	if not it.has("use"):
		return
	var u: Dictionary = it.use
	if u.has("water"): s.drink(u.water)
	if u.has("food"): s.eat(u.food)
	if u.has("hp"): s.hp = minf(100.0, s.hp + u.hp)
	Sfx.play("drink" if u.has("water") and not u.has("food") else ("cloth" if u.has("hp") else "chop"), -4.0)
	var id: String = e.id
	e.n -= 1
	if e.n <= 0:
		inv[i] = null
	if u.has("sick") and randf() < u.sick:
		s.water = maxf(0.0, s.water - 12.0)
		s.food = maxf(0.0, s.food - 6.0)
		s.damage(5.0, "bozuk yemek")
		hud.toast("Midene dokundu! (çiğ et) -12 su", Color("#b8e05d"))
	if it.has("after"):
		give(it.after)
	player.act("interact-right", 0.5)
	hud.toast("%s: %s" % [it.get("verb", "Kullan"), it.name], Color("#d8ffd0"))

func drop_slot(i: int) -> void:
	var e: Variant = inv[i]
	if e == null:
		return
	world.place("crate", player.pos + player.forward() * 1.3, {"loot": {e.id: e.n}, "label": "Bırakılan eşya"})
	inv[i] = null
	Sfx.play("cloth", -6.0)

func can_craft(r: Dictionary) -> bool:
	for id in r.needs:
		if count(id) < r.needs[id]:
			return false
	if r.id == "up:canteen" and cap >= GameData.CANTEEN_CAP_BIG:
		return false
	if r.id in ["bicak", "mizrak"] and count(r.id) > 0:
		return false
	return true

func craft(r: Dictionary) -> void:
	if not can_craft(r):
		Sfx.play("error", -6.0)
		return
	var rid: String = r.id
	if not rid.contains(":"):
		# make sure the result fits (consumed ingredients free space first)
		var free := 0
		for e in inv:
			if e == null or (e.id == rid and e.n < GameData.STACK):
				free += 1
		var frees_slot := false
		for id in r.needs:
			if count(id) == r.needs[id]:
				frees_slot = true
		if free == 0 and not frees_slot:
			hud.toast("Çantada yer yok!", Color("#ff9a7a"))
			Sfx.play("error", -6.0)
			return
	for id in r.needs:
		remove_item(id, r.needs[id])
	Sfx.play("craft", -4.0)
	player.act("interact-right", 0.7)
	if rid.begins_with("place:"):
		var kind := rid.substr(6)
		var p := world.collide(player.pos + player.forward() * 1.8, 0.8)
		var it := world.place(kind, p, {"rot": player.facing})
		if kind == "fire":
			Fx.puff(world, it.node.position + Vector3(0, 0.5, 0), "spark_01", Color(1, 0.7, 0.3), 12, 3.0, 0.3)
			if not tut.has("fire_use"):
				tut.fire_use = true
				hud.show_hint("Ateşin yanında ısınırsın. Ateşe yaklaşıp etkileşimle odun atabilir (+60 sn) ve çiğ eti pişirebilirsin.", "")
		close_panels()
		hud.toast("%s kuruldu." % r.name, Color("#d8ffd0"))
	elif rid == "up:canteen":
		cap = GameData.CANTEEN_CAP_BIG
		hud.toast("Matara artık %d yudum alıyor." % cap, Color("#bfe6ff"))
	else:
		give(rid)
		if rid == "mizrak":
			player.set_spear(true)

# ---------------------------------------------------------------- actions
func do_drink() -> void:
	if not playing or paused or s.dead():
		return
	if canteen > 0:
		canteen -= 1
		s.drink(GameData.CANTEEN_SIP)
		Sfx.play("drink", -2.0)
		player.act("interact-right", 0.5)
		tut["drank"] = true
		hud.toast("Bir yudum su (+%d). Matara: %d/%d" % [GameData.CANTEEN_SIP, canteen, cap], Color("#bfe6ff"))
	elif count("su_sise") > 0:
		for i in inv.size():
			if inv[i] and inv[i].id == "su_sise":
				use_slot(i)
				return
	else:
		Sfx.play("error", -6.0)
		hud.toast("Matara boş! Vaha veya kuyu bul.", Color("#ff9a7a"))

func do_attack() -> void:
	if not playing or paused or s.dead() or _attack_cd > 0.0 or panel != "":
		return
	_attack_cd = 0.55
	var spear := count("mizrak") > 0
	var knife := count("bicak") > 0
	var dmg := 35.0 if spear else (18.0 if knife else 10.0)
	var reach := 2.9 if spear else 1.9
	if s.stamina < 8.0:
		hud.toast("Çok yorgunsun.", Color("#ffd27a"))
		return
	s.stamina -= 10.0
	player.act("attack-melee-right", 0.5)
	Sfx.play("slice" if spear or knife else "hit", -4.0)
	var a = animals.hit(player.pos, player.forward(), reach, dmg)
	if a != null:
		Sfx.play("hit", -2.0)
		if a.hp <= 0.0:
			_on_kill(a)

func _on_kill(a) -> void:
	var k: Dictionary = Animals.KINDS[a.kind]
	var knife := count("bicak") > 0
	var loot := {}
	match a.kind:
		"rabbit", "fennec": loot = {"cig_et": 1}
		"partridge": loot = {"cig_kus": 1}
		"jackal": loot = {"cig_et": 2}
		"snake": loot = {"yilan_eti": 1}
	if knife and a.kind in ["rabbit", "fennec", "jackal"]:
		loot["deri"] = 1
	hud.toast("%s avlandı!" % k.name, Color("#ffe7b8"))
	if not loot.is_empty():
		var model: String = k.model if k.model != "" else "pets/animal-bunny"
		world.place("carcass", a.pos, {"loot": loot, "model": model, "scale": k.scale * 0.9, "label": "%s: avı topla" % k.name})
	animals.kill(a)
	if not knife and a.kind in ["rabbit", "fennec", "jackal"]:
		hud.toast("Bıçağın olsaydı deri de alırdın.", Color("#ffd27a"))

func _on_bite(dmg: float, poison: float, who: String) -> void:
	if not playing or s.dead():
		return
	s.damage(dmg, who)
	if poison > 0.0:
		s.poison = maxf(s.poison, poison)
	_hurt_flash = 0.6
	Sfx.play("hurt", 0.0)
	hud.toast("-%d sağlık (%s)" % [dmg, who], Color("#ff7a7a"))

func _prompt_for(it: Dictionary) -> String:
	if it.is_empty():
		return ""
	match it.kind:
		"node":
			var t: String = world.nodes[it.i].t
			if t == "cactus" and count("bicak") == 0:
				return "Kaktüsü kes (bıçaksız: diken!)"
			return it.label
		"oasis": return "Vahadan su iç ve doldur"
		"well":
			if g.wells[it.i].dry: return "Kuyu (kurumuş)"
			if world.wells_b[it.i] <= 0: return "Kuyu (boş, bekle)"
			return "Kuyudan su çek (%d kova)" % world.wells_b[it.i]
		"radio":
			if radio.installed: return "Telsiz (sinyal gönderildi)"
			return "Telsizi onar (%d/3 parça)" % _parts_have()
		"fire":
			if it.left <= 0.0: return "Ateşi yak (1 odun)"
			if _raw_meat() != "": return "Eti pişir"
			return "Ateşe odun at (%d sn)" % ceili(it.left)
		"dew": return "Çiyi topla (+%d su)" % int(it.water) if it.water >= 5.0 else "Çiy toplayıcı (gece birikir)"
		"trap": return "Tuzaktaki tavşanı al" if it.caught else "Tuzak (gece kurulu)"
		"shelter": return ""
		"heli": return "Helikoptere bin!"
	return it.get("label", "")

func _parts_have() -> int:
	return int(count("anten") > 0) + int(count("pil") > 0) + int(count("devre") > 0)

func _raw_meat() -> String:
	for id in ["cig_et", "cig_kus", "yilan_eti"]:
		if count(id) > 0:
			return id
	return ""

func do_interact() -> void:
	if not playing or paused or s.dead() or panel != "":
		return
	var it := target
	if it.is_empty() or prompt == "":
		return
	match it.kind:
		"node": _harvest(it.i)
		"oasis":
			_drink_source(); player.act("pick-up", 0.8)
		"well":
			var i: int = it.i
			if g.wells[i].dry:
				hud.toast("Kuyu kurumuş. Başka kuyu ara.", Color("#ff9a7a")); Sfx.play("error", -6.0)
			elif count("kova") == 0 or count("ip") == 0:
				hud.toast("Su çekmek için kova ve ip gerek.", Color("#ff9a7a")); Sfx.play("error", -6.0)
			elif world.wells_b[i] <= 0:
				hud.toast("Kuyu boşaldı. 2 günde bir kova dolar.", Color("#ff9a7a"))
			else:
				world.wells_b[i] -= 1
				Sfx.play("creak", -4.0)
				_drink_source()
				player.act("interact-right", 1.0)
		"wreck_crate":
			world.opened["wreck"] = true
			Sfx.play("open", -2.0)
			player.act("pick-up", 0.8)
			for id in ["konserve", "su_sise", "bez", "kova"]:
				give(id, {"konserve": 3, "su_sise": 2, "bez": 3, "kova": 1}[id])
			hud.show_hint("Pilotun notu: \"Telsiz bozuldu. Anten, pil ve devre kartı lazım. Eski harabelere ve mağaralara bak. Kervansaray haritanın kenarında, pusuladaki yeşil işaret yönünde.\"", "map")
		"chest":
			world.opened[it.id] = true
			Sfx.play("open", -2.0)
			player.act("pick-up", 0.8)
			_loot_chest(it.id)
		"radio":
			if radio.installed:
				hud.toast("Sinyal gönderildi. Kurtarma ekibi yolda!", Color("#d8ffd0"))
			elif _parts_have() == 3:
				for id in ["anten", "pil", "devre"]:
					remove_item(id, 1)
				radio.installed = true
				radio.sent_at = t_abs
				Sfx.play("win", -4.0)
				hud.show_hint("Telsiz çalıştı! Kurtarma helikopteri 1 gün içinde enkazın yanına inecek. O zamana kadar hayatta kal.", "")
			else:
				var miss := []
				for id in ["anten", "pil", "devre"]:
					if count(id) == 0: miss.append(GameData.ITEMS[id].name)
				hud.toast("Eksik: " + ", ".join(miss), Color("#ffd27a"))
		"fire": _use_fire(it)
		"dew":
			if it.water >= 5.0:
				s.drink(it.water); hud.toast("Çiy suyu +%d" % int(it.water), Color("#bfe6ff"))
				it.water = 0.0; Sfx.play("drink", -2.0)
		"trap":
			if it.caught:
				it.caught = false
				give("cig_et")
				if count("bicak") > 0: give("deri")
				Sfx.play("pickup")
		"crate", "carcass":
			var loot: Dictionary = it.get("loot", {})
			if it.kind == "crate" and loot.is_empty():
				loot = _crate_loot()
			for id in loot:
				give(id, loot[id])
			Sfx.play("open" if it.kind == "crate" else "slice", -4.0)
			player.act("pick-up", 0.7)
			world.remove_item(it)
		"heli": _win("Telsiz çağrın işe yaradı. Helikopter seni çölden çıkardı.")

func _drink_source() -> void:
	s.drink(GameData.SOURCE_DRINK)
	var filled := canteen < cap
	canteen = cap
	var b := count("bos_sise")
	if b > 0:
		remove_item("bos_sise", b)
		add_item("su_sise", b)
	Sfx.play("drink", 0.0)
	hud.toast("Kana kana içtin (+%d). Matara doldu%s." % [GameData.SOURCE_DRINK, (", %d şişe doldu" % b) if b > 0 else ""], Color("#bfe6ff"))

func _harvest(i: int) -> void:
	var st: Dictionary = world.nodes[i]
	match st.t:
		"cactus":
			if count("bicak") > 0:
				s.drink(15.0); s.eat(5.0)
				Sfx.play("slice")
				if randf() < 0.25:
					s.water = maxf(0.0, s.water - 10.0)
					hud.toast("Kaktüs suyu acı çıktı, midene dokundu (-10 su)", Color("#b8e05d"))
				else:
					hud.toast("Kaktüs suyu +15, +5 yemek", Color("#bfe6ff"))
			else:
				s.drink(8.0)
				s.damage(5.0, "kaktüs dikeni")
				_hurt_flash = 0.4
				Sfx.play("hurt", -4.0)
				hud.toast("Dikenler battı! (-5 sağlık) Biraz su: +8. Taş bıçak yap.", Color("#ff9a7a"))
		"pear":
			give("incir", 2); Sfx.play("pickup")
		"bush":
			give("odun"); give("cubuk"); give("lif")
			Sfx.play("wood", -4.0)
		"stone":
			give("tas", 2 if randf() < 0.3 else 1)
			Sfx.play("stone", -4.0)
		"larva":
			Sfx.play("stone", -4.0)
			var r := randf()
			if r < 0.5:
				s.eat(5.0); hud.toast("Taşın altında larva vardı: +5 yemek (iğrenç ama besleyici)", Color("#ffe7b8"))
			elif r < 0.75:
				hud.toast("Taşın altından akrep çıktı!", Color("#ff7a7a"))
				animals.spawn("scorpion", st.p + Vector2(0.8, 0.4))
			else:
				hud.toast("Altında bir şey yok.", Color("#fff4dc"))
		"palm":
			give("hurma", 2); give("lif", 2)
			Sfx.play("pickup")
	world.harvest_node(i, t_abs)
	player.act("pick-up", 0.7)
	Fx.puff(world, Vector3(st.p.x, world.ground(st.p) + 0.4, st.p.y), "dirt_02", Color(0.9, 0.75, 0.5, 0.9), 8, 2.0, 0.4)

func _loot_chest(id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id) + seed_v
	var loot := {"bez": rng.randi_range(1, 2), "ip": 1}
	if rng.randf() < 0.6: loot["bos_sise"] = 1
	if rng.randf() < 0.5: loot["konserve"] = 1
	if rng.randf() < 0.35: loot["sargi"] = 1
	if rng.randf() < 0.3: loot["su_sise"] = 1
	for part in g.radio_parts:
		var rp: Dictionary = g.radio_parts[part]
		if id == "%s:%d" % [rp.kind, rp.i]:
			loot[part] = 1
			Sfx.play("win", -6.0)
			hud.toast("Telsiz parçası bulundu: %s!" % GameData.ITEMS[part].name, Color("#ffe066"))
	for k in loot:
		give(k, loot[k])

func _crate_loot() -> Dictionary:
	var opts := [{"konserve": 1, "bez": 1}, {"su_sise": 1}, {"ip": 1, "bos_sise": 1}, {"konserve": 1, "su_sise": 1}, {"sargi": 1, "tas": 2}]
	return opts[randi() % opts.size()]

func _use_fire(it: Dictionary) -> void:
	if it.left <= 0.0:
		if count("odun") > 0:
			remove_item("odun", 1)
			it.left = GameData.FIRE_ADD
			world.set_fire_lit(it, true)
			Sfx.play("wood")
		else:
			hud.toast("Ateşi yakmak için odun gerek.", Color("#ff9a7a"))
		return
	var raw := _raw_meat()
	if raw != "":
		var cooked: String = {"cig_et": "pismis_et", "cig_kus": "pismis_kus", "yilan_eti": "pismis_yilan"}[raw]
		var n := count(raw)
		remove_item(raw, n)
		give(cooked, n)
		player.act("interact-right", 1.0)
		Sfx.play("craft", -6.0)
		return
	if count("odun") > 0:
		remove_item("odun", 1)
		it.left = minf(it.left + GameData.FIRE_ADD, 300.0)
		Sfx.play("wood")
		Fx.puff(world, it.node.position + Vector3(0, 0.6, 0), "spark_01", Color(1, 0.7, 0.3), 10, 3.0, 0.25)
		hud.toast("Ateş: %d sn" % ceili(it.left), Color("#ffb347"))
	else:
		hud.toast("Odunun yok. Çalılardan topla.", Color("#ffd27a"))

# ---------------------------------------------------------------- world systems
func _update_fires(dt: float, night: bool) -> void:
	var storm := storm_state == "storm"
	for it in world.placed:
		match it.kind:
			"fire":
				if it.left > 0.0:
					it.left -= dt
					var l: OmniLight3D = it.fx.get_node("Light")
					l.light_energy = 2.0 + sin(t_abs * 13.0) * 0.25 + sin(t_abs * 7.3) * 0.2
					if storm and world.sheltered(it.p) == "":
						it.left = 0.0
						if player.pos.distance_to(it.p) < 40.0:
							hud.toast("Fırtına ateşi söndürdü!", Color("#ffb347"))
					if it.left <= 0.0:
						it.left = 0.0
						world.set_fire_lit(it, false)
			"dew":
				if night:
					it.water = minf(30.0, it.water + dt * 30.0 / 150.0)

func _new_day() -> void:
	last_day_seen = day
	Sfx.play("hint", -4.0)
	hud.toast("%d. Gün" % day, Color("#ffe7b8"))
	for it in world.placed:
		if it.kind == "trap" and not it.caught and randf() < 0.4:
			it.caught = true
	if day % 2 == 1:
		for i in world.wells_b.size():
			if not g.wells[i].dry:
				world.wells_b[i] = mini(world.wells_b[i] + 1, 4)
	world.smoke.emitting = day <= 2
	write_save()
	hud.toast("Oyun kaydedildi.", Color(1, 1, 1, 0.8))

func _after_storm() -> void:
	hud.toast("Fırtına dindi. Kumdan bir şeyler çıkmış olabilir!", Color("#ffe7b8"))
	for k in 2:
		for tries in 12:
			var a := randf() * TAU
			var p := player.pos + Vector2(cos(a), sin(a)) * randf_range(18.0, 45.0)
			if absf(p.x) < WorldGen.HALF - 10 and absf(p.y) < WorldGen.HALF - 10 and world.collide(p, 0.8).distance_to(p) < 0.01:
				world.place("crate", p, {})
				break

func _reveal() -> void:
	var p := player.pos
	var ci := int((p.x + WorldGen.HALF) / 4.0)
	var cj := int((p.y + WorldGen.HALF) / 4.0)
	var r := 10 if storm_state != "storm" else 3
	for j in range(cj - r, cj + r + 1):
		for i in range(ci - r, ci + r + 1):
			if i >= 0 and j >= 0 and i < FOG and j < FOG and (i - ci) * (i - ci) + (j - cj) * (j - cj) <= r * r:
				fog[j * FOG + i] = 1
	for poi in _all_pois():
		if not discovered.get(poi.key, false) and p.distance_to(poi.p) < poi.get("see", 40.0):
			discovered[poi.key] = true
			hud.toast("Keşfedildi: %s" % poi.name, Color("#ffe066"))
			Sfx.play("hint", -8.0)

func _all_pois() -> Array:
	var out := [{"key": "wreck", "p": Vector2.ZERO, "name": "Uçak enkazı", "col": Color("#e5383b")},
		{"key": "obelisk", "p": g.obelisk, "name": "Dikilitaş", "col": Color("#f4d39b"), "see": 75.0},
		{"key": "caravan", "p": g.caravan, "name": "Kervansaray", "col": Color("#2a8f5a"), "see": 60.0}]
	for i in g.oases.size():
		out.append({"key": "oasis:%d" % i, "p": g.oases[i], "name": "Vaha", "col": Color("#3fb4ef"), "see": 55.0})
	for i in g.ruins.size():
		out.append({"key": "ruin:%d" % i, "p": g.ruins[i], "name": "Harabe", "col": Color("#c79a5b")})
	for i in g.wells.size():
		out.append({"key": "well:%d" % i, "p": g.wells[i].p, "name": "Kuyu" + (" (kuru)" if g.wells[i].dry else ""), "col": Color("#7a5a3a") if g.wells[i].dry else Color("#1b9fd0"), "see": 30.0})
	for i in g.caves.size():
		out.append({"key": "cave:%d" % i, "p": g.caves[i].p, "name": "Mağara", "col": Color("#6b4a3a")})
	return out

func known_pois() -> Array:
	return _all_pois().filter(func(p): return discovered.get(p.key, false))

func compass_marks() -> Array:
	var out := []
	for poi in known_pois():
		var d: Vector2 = poi.p - player.pos
		if d.length() > 6.0:
			out.append({"a": atan2(d.x, -d.y), "col": poi.col})
	if not discovered.get("caravan", false):
		var d2 := g.caravan - player.pos
		out.append({"a": atan2(d2.x, -d2.y), "col": Color("#45d483")})
	for m in markers:
		var d3: Vector2 = m - player.pos
		out.append({"a": atan2(d3.x, -d3.y), "col": Color("#e5383b")})
	return out

func explored_pct() -> int:
	var n := 0
	for b in fog:
		n += b
	return int(100.0 * n / maxf(1.0, fog.size()))

func toggle_marker(w: Vector2) -> void:
	for m in markers:
		if m.distance_to(w) < 16.0:
			markers.erase(m)
			Sfx.play("close", -6.0)
			return
	if markers.size() >= 3:
		markers.pop_front()
	markers.append(w)
	Sfx.play("click", -4.0)

func _tutorial() -> void:
	if day > 1 and not tut.has("storm") and storm_state == "":
		return
	var h := GameData.hour_of(tod)
	if not tut.has("start") and t_abs > 23.0:
		tut.start = true
		hud.show_hint("Uçak düştü ama hayattasın! Önce enkazdaki sandığı aç: yanına git ve %s." % ("Etkileşim tuşuna bas" if touch else "[E] tuşuna bas"), "act" if touch else "")
	elif not tut.has("drink") and (s.water < 55.0 or t_abs > 75.0) and tut.has("start"):
		tut.drink = true
		hud.show_hint("Matarandan su iç: %s. Matara 4 yudum alır; vahada ve kuyularda doldurursun. Su biterse sağlığın hızla düşer!" % ("İç tuşu" if touch else "[Q]"), "drink" if touch else "canteen")
	elif not tut.has("shade") and day == 1 and h >= 10.3 and not in_shade:
		tut.shade = true
		hud.show_hint("Öğle güneşi vücut ısını yükseltiyor (termometre). Kırmızıya ulaşırsa sıcak çarpar. Palmiye, kaya, enkaz ya da harabe gölgesinde bekle; koşmak ısıtır.", "stats")
	elif not tut.has("fire") and day == 1 and h >= 16.3:
		tut.fire = true
		hud.show_hint("Gece çöl donar! Çalılardan odun, yerden taş topla; sonra Çanta > Üret > Kamp ateşi (3 odun + 2 taş). Geceyi ateşin yanında geçir.", "bag")
	elif not tut.has("storm") and storm_state == "warn":
		tut.storm = true
		hud.show_hint("Kum fırtınası geliyor! 60 saniyen var: mağara, harabe, enkaz veya kendi gölgeliğine gir. Açıkta kalırsan canın gider ve ateşler söner.", "map")

func _check_rescue() -> void:
	if radio.installed and not radio.arrived and t_abs >= radio.sent_at + GameData.DAY_LEN:
		radio.arrived = true
		_spawn_heli(true)
		hud.show_hint("Pervane sesi! Kurtarma helikopteri enkazın yanına indi. Hemen oraya git!", "")
	if player.pos.distance_to(g.caravan) < 12.0:
		_win("Kervansaraya ulaştın. Kervancılar sana su ve gölge verdi.")

func _spawn_heli(anim: bool) -> void:
	heli = Node3D.new()
	var p := Vector2(14, -10)
	heli.position = Vector3(p.x, g.height(p.x, p.y), p.y)
	add_child(heli)
	var body := world.box(Vector3(2.2, 1.6, 4.2), Vector3(0, 1.2, 0), world._mat(Color("#e8b92f"), 0.4), Vector3.ZERO, heli)
	world.box(Vector3(1.6, 0.8, 1.2), Vector3(0, 1.5, 2.0), world._mat(Color("#2d4a63"), 0.2), Vector3.ZERO, heli)
	world.box(Vector3(0.4, 0.4, 4.0), Vector3(0, 1.6, -3.6), world._mat(Color("#e8b92f"), 0.4), Vector3.ZERO, heli)
	world.box(Vector3(0.15, 1.2, 0.8), Vector3(0, 2.0, -5.5), world._mat(Color("#d9483b"), 0.4), Vector3.ZERO, heli)
	for sx in [-1, 1]:
		world.box(Vector3(0.15, 0.15, 4.0), Vector3(sx * 1.1, 0.1, 0), world._mat(Color("#333333")), Vector3.ZERO, heli)
	var rotor := world.box(Vector3(9.0, 0.08, 0.4), Vector3(0, 2.25, 0), world._mat(Color("#333333")), Vector3.ZERO, heli)
	rotor.name = "Rotor"
	var tw := rotor.create_tween().set_loops()
	tw.tween_property(rotor, "rotation:y", TAU, 0.25).from(0.0)
	if anim:
		heli.position.y += 40.0
		create_tween().tween_property(heli, "position:y", g.height(p.x, p.y), 6.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	world.inter.append({"kind": "heli", "p": p, "r": 4.5, "label": "Helikopter"})
	world._obstacle(p, 2.0)

func _win(how: String) -> void:
	if not playing:
		return
	playing = false
	_delete_save()
	hud.visible = false
	Sfx.play("win")
	world_used = true
	menus.show_win(how, day, explored_pct())

func _on_death() -> void:
	player.die()
	close_panels()
	Sfx.play("lose")
	var why := s.cause if s.cause != "" else "bilinmiyor"
	await get_tree().create_timer(2.0).timeout
	hud.visible = false
	menus.show_dead(why, day, explored_pct())

# ---------------------------------------------------------------- test bridge (web only)
func _bridge(dt: float) -> void:
	if not OS.has_feature("web"):
		return
	_bridge_t -= dt
	if _bridge_t > 0.0:
		return
	_bridge_t = 0.25
	# the page's "Bilgisayara indir" link only shows on menus so it never covers the HUD
	var dl: bool = menus.visible and menus.current != ""
	if dl != _dl_shown:
		_dl_shown = dl
		JavaScriptBridge.eval("var e=document.getElementById('desktop-download');if(e)e.style.display='%s';" % ("" if dl else "none"), true)
	var r := {}
	for ui_node in [hud, menus, inv_panel, map_view]:
		if not ui_node.visible:
			continue
		var src: Dictionary = ui_node.rects
		for k in src:
			var rc: Rect2 = src[k]
			r[k] = [rc.position.x, rc.position.y, rc.size.x, rc.size.y]
	var st := {
		"ready": world_ready, "screen": menus.current if menus.visible and menus.current != "" else ("play" if playing else "loading"),
		"playing": playing, "paused": paused, "panel": panel, "touch": touch, "quality": Settings.quality,
		"vs": [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y], "rects": r,
		"fps": snappedf(_fps, 0.1), "day": day, "tod": snappedf(tod, 0.1), "clock": GameData.clock_text(tod),
		"storm": storm_state, "storm_k": snappedf(weather.intensity(t_abs), 0.01), "prompt": prompt, "shelter": shelter_name,
		"has_save": has_save(), "hint": hud.hint.get("text", ""), "tut": tut.keys(),
	}
	if world_ready and player:
		st["pos"] = [snappedf(player.pos.x, 0.01), snappedf(player.pos.y, 0.01)]
		st["anim"] = player._cur
		st["stats"] = {"water": snappedf(s.water, 0.01), "food": snappedf(s.food, 0.01), "temp": snappedf(s.temp, 0.01), "stamina": snappedf(s.stamina, 0.1), "hp": snappedf(s.hp, 0.1)}
		st["canteen"] = canteen
		st["inv"] = inv.map(func(e): return (e.id + "x" + str(e.n)) if e else "")
		st["fires"] = world.placed.filter(func(i): return i.kind == "fire").size()
		st["fires_lit"] = world.placed.filter(func(i): return i.kind == "fire" and i.left > 0.0).size()
		st["animals"] = animals.list.size()
	JavaScriptBridge.eval("window.__col=" + JSON.stringify(st) + ";", true)
	if _test:
		var cmds: Variant = JavaScriptBridge.eval("JSON.stringify((window.__colCmd||[]).splice(0))", true)
		if cmds is String and cmds != "[]":
			for c in JSON.parse_string(cmds):
				_test_cmd(str(c))

## Test-only: advance game time while ticking survival and fires (player standing still).
func _fast_forward(v: float) -> void:
	var steps := int(v / 0.5)
	for i in steps:
		t_abs += 0.5
		tod = fmod(t_abs, GameData.DAY_LEN)
		var night := GameData.is_night(tod)
		var sun_k := 0.0 if (in_shade or night) else GameData.sun_strength(tod)
		_update_env_state()
		s.tick(0.5, {"sun": sun_k, "ambient": ambient_shown, "moving": false, "running": false,
			"night": night, "storm": storm_state == "storm" and shelter_name == "", "climbing": false})
		_update_fires(0.5, night)

## Debug commands, only reachable from the browser console with ?test=1 in the URL.
func _test_cmd(c: String) -> void:
	var a := c.split(":")
	match a[0]:
		"time": _fast_forward(float(a[1]))
		"settime": t_abs = (day - 1) * GameData.DAY_LEN + float(a[1])
		"storm": weather._plan(t_abs + float(a[1]) if a.size() > 1 else t_abs + 5.0)
		"give": add_item(a[1], int(a[2]) if a.size() > 2 else 1)
		"tp": player.pos = Vector2(float(a[1]), float(a[2]))
		"quality": Settings.set_quality(int(a[1]))
		"hint": hud.hint = {}
		"save": write_save()
		"goto":
			var tgt: Vector2 = {"oasis": g.oases[0], "ruin": g.ruins[0], "caravan": g.caravan, "well": g.wells[0].p, "cave": g.caves[0].p}.get(a[1], g.wreck)
			var off := Vector2(float(a[2]) if a.size() > 2 else 20.0, 0.0)
			player.pos = world.collide(tgt + off, 0.5)
