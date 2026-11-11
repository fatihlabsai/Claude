## Headless smoke test of the real game scene: start, move, interact, craft, storm, save/load.
## Run with: godot --headless -- --smoke   (hooked from main.gd, never in normal play)
extends Node

var m: Node
func _ready() -> void:
	m = get_parent()
	_run.call_deferred()

func wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _run() -> void:
	var t0 := Time.get_ticks_msec()
	while not m.world_ready:
		await get_tree().process_frame
	print("world ready ms=", Time.get_ticks_msec() - t0, " menu=", m.menus.current)
	await m.new_game(1)
	await wait(5)
	print("playing=", m.playing, " pos=", m.player.pos, " water=", m.s.water)
	Input.action_press("up"); await wait(60); Input.action_release("up")
	print("after move pos=", m.player.pos)
	m.player.pos = Vector2(-2.2, -2.4).rotated(-0.5) + Vector2(1.6, 0)
	await wait(5)
	m._tick = 0
	await wait(5)
	print("prompt=", m.prompt)
	m.do_interact(); await wait(2)
	print("inv=", m.inv)
	m.do_drink(); print("canteen=", m.canteen, " water=", m.s.water)
	m.add_item("odun", 3); m.add_item("tas", 4); m.add_item("cubuk", 3); m.add_item("lif", 3)
	for r in GameData.RECIPES:
		if r.id in ["bicak", "place:fire", "ip"]:
			m.craft(r)
	print("fires=", m.world.placed.size(), " inv=", m.inv)
	m._tick = 0; await wait(3)
	print("fire prompt=", m.prompt); m.give("cig_et", 1); m.do_interact(); await wait(2); m.do_interact(); await wait(2)
	print("after fire inv=", m.inv, " fires=", m.world.placed)
	m._toggle_panel("bag"); await wait(6)
	print("bag rects=", m.inv_panel.rects.keys().size(), " size=", m.inv_panel.size); m.close_panels()
	m._toggle_panel("map"); await wait(3)
	print("map size=", m.map_view.size, " close=", m.map_view.rects.get("close")); m.close_panels()
	# nodes
	var n0: Dictionary = m.world.nodes[0]
	m.player.pos = n0.p + Vector2(0.5, 0); await wait(3)
	print("node prompt=", m.prompt, " t=", n0.t); m.do_interact(); await wait(2)
	# attack an animal
	var a = m.animals.spawn("rabbit", m.player.pos + m.player.forward() * 1.0)
	for i in 4:
		m._attack_cd = 0; m.s.stamina = 100; m.do_attack(); await wait(2)
	print("animals=", m.animals.list.size(), " crates=", m.world.crates.size())
	# storm
	m.weather._plan(m.t_abs + 3.0)
	await wait(10)
	print("storm=", m.storm_state)
	m.t_abs += 5.0; await wait(10)
	print("storm2=", m.storm_state, " k=", m.weather.intensity(m.t_abs))
	m.t_abs = m.weather.end_at + 1.0; await wait(5)
	print("after storm crates=", m.world.crates.size())
	# night/day change + save
	m.t_abs = GameData.DAY_LEN - 0.5; await get_tree().create_timer(1.5).timeout
	print("day=", m.day, " save=", m.has_save())
	m.quit_to_title(); await wait(5)
	await m.continue_game(); await wait(5)
	print("continued day=", m.day, " inv=", m.inv, " playing=", m.playing)
	# death
	m.s.hp = 0.5; m.s.water = 0; await get_tree().create_timer(3.5).timeout
	print("dead=", m.s.dead(), " menu=", m.menus.current)
	print("SMOKE OK")
	get_tree().quit()
