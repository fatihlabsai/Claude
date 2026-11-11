## Dev tool: godot -- --shots <outdir> [scene,...]  renders scenes to PNG and quits.
extends Node

var m: Node
var outdir := "/tmp/shots"
var scenes := ["title", "day", "oasis", "night", "storm", "cave", "ruin", "caravan"]

func _ready() -> void:
	m = get_parent()
	var a := OS.get_cmdline_user_args()
	var i := a.find("--shots")
	if i >= 0 and a.size() > i + 1:
		outdir = a[i + 1]
	if i >= 0 and a.size() > i + 2:
		scenes = Array(a[i + 2].split(","))
	DirAccess.make_dir_recursive_absolute(outdir)
	_run.call_deferred()

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(outdir + "/" + n + ".png")
	print("shot ", n)

func _run() -> void:
	while not m.world_ready:
		await get_tree().process_frame
	if "title" in scenes:
		await wait(1.5); await shot("title")
	await m.new_game(1)
	m.hud.hint = {}
	m.tut = {"start": true, "drink": true, "shade": true, "fire": true, "storm": true, "drank": true, "fire_use": true}
	for sc in scenes:
		if sc == "title":
			continue
		if sc.begins_with("q") and sc.length() == 2:
			Settings.quality = int(sc.substr(1)); Settings.changed.emit()
			continue
		if sc == "mmstats":
			for key in m.world._mm:
				var e: Dictionary = m.world._mm[key]
				var cnt := 0
				for r in e.x: cnt += r.size()
				var tris := 0
				for si in e.mesh.get_surface_count():
					var a: Array = e.mesh.surface_get_arrays(si)
					tris += (a[Mesh.ARRAY_INDEX].size() if a[Mesh.ARRAY_INDEX] != null else a[Mesh.ARRAY_VERTEX].size()) / 3
				print("FPS MM ", key, " n=", cnt, " tris=", tris, " total=", cnt * tris)
			continue
		if sc == "nosky":
			m.env.background_mode = Environment.BG_COLOR; continue
		if sc == "nomm":
			for c in m.world.get_children():
				if c is MultiMeshInstance3D: c.visible = false
			continue
		if sc == "noterrain":
			for c in m.world.get_children():
				if c is MeshInstance3D and c.material_override == m.world._chunk_mat: c.visible = false
			continue
		if sc == "nofx":
			m.dust_fx.visible = false; m.haze_rect.visible = false; continue
		if sc.begins_with("fps"):
			m.t_abs = 110.0; m.player.pos = Vector2(8, 9)
			await wait(3.0)
			var f0 := Engine.get_process_frames(); var t0 := Time.get_ticks_msec()
			await wait(5.0)
			print("FPS ", sc, " ", (Engine.get_process_frames() - f0) * 1000.0 / (Time.get_ticks_msec() - t0))
			continue
		m.weather._plan(m.t_abs + 9999.0)
		var name: String = sc
		m.zoom = 1.0
		if sc.ends_with("_z"):
			m.zoom = 0.5
			sc = sc.trim_suffix("_z")
		match sc:
			"day":
				m.t_abs = 110.0; m.player.pos = Vector2(8, 9)
			"oasis":
				m.t_abs = 150.0; m._test_cmd("goto:oasis:20")
			"night":
				m.t_abs = 345.0; m._test_cmd("goto:oasis:24")
				m.add_item("odun", 3); m.add_item("tas", 2)
				m.craft(GameData.RECIPES[0])
			"storm":
				m.t_abs = 130.0; m.player.pos = Vector2(8, 9)
				m.weather._plan(m.t_abs + 1.0)
			"cave":
				m.t_abs = 90.0; m._test_cmd("goto:cave:8")
			"ruin":
				m.t_abs = 200.0; m._test_cmd("goto:ruin:14")
			"caravan":
				m.t_abs = 240.0; m._test_cmd("goto:caravan:30")
			"dusk":
				m.t_abs = 285.0; m.player.pos = Vector2(8, 9)
		m.hud.hint = {}
		await wait(2.5 if sc != "storm" else 9.0)
		await shot(name)
	get_tree().quit()
