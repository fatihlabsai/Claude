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
				m.t_abs = 345.0; m._test_cmd("goto:oasis:20")
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
