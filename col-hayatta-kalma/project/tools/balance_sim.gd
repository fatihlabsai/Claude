## Headless balance simulation. Uses the real Survival, Weather and WorldGen code
## with two scripted players on generated maps:
##   careful  - drinks at sources, rests in shade at noon, fire at night, shelters from storms
##   careless - runs around in the sun, only sips the canteen, no fire, ignores storms
## Run: godot --headless -s tools/balance_sim.gd -- [runs] [maxdays]
extends SceneTree

const DT := 0.5

class Agent:
	var s := Survival.new()
	var pos := Vector2.ZERO
	var inv := {}
	var canteen := 2
	var cap := 4
	var target: Variant = null
	var fire_pos: Variant = null
	var fire_left := 0.0
	var shelter: Variant = null   # built shelter position
	var log := []
	func add(id: String, n := 1) -> void:
		inv[id] = inv.get(id, 0) + n
	func has(id: String, n := 1) -> bool:
		return inv.get(id, 0) >= n
	func take(id: String, n := 1) -> void:
		inv[id] = inv.get(id, 0) - n

var g: WorldGen
var w: Weather
var avail := {}          # node index -> time when available again
var well_b := {}         # well index -> buckets
var t := 0.0

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var runs := int(args[0]) if args.size() > 0 else 10
	var maxd := int(args[1]) if args.size() > 1 else 7
	var res := {"careful": [], "careless": []}
	for mode in ["careful", "careless"]:
		for r in runs:
			var out := run(1000 + r * 17, mode, maxd)
			res[mode].append(out)
			print("%-8s seed %d -> %s day %.2f (%s)" % [mode, 1000 + r * 17, "SURVIVED" if out.alive else "died", out.days, out.cause] + "  min water %.0f food %.0f hp %.0f temp %.1f-%.1f" % [out.mins.water, out.mins.food, out.mins.hp, out.mins.tmin, out.mins.tmax])
	for mode in res:
		var days: Array = res[mode].map(func(o): return o.days)
		var alive: int = res[mode].filter(func(o): return o.alive).size()
		var avg: float = days.reduce(func(a, b): return a + b, 0.0) / days.size()
		print("SUMMARY %s: survived %d/%d, avg days %.2f, min %.2f, max %.2f" % [mode, alive, days.size(), avg, days.min(), days.max()])
	quit()

func run(seed_v: int, mode: String, maxd: int) -> Dictionary:
	g = WorldGen.new(); g.generate(seed_v)
	w = Weather.new(); w.setup(seed_v)
	avail.clear(); well_b.clear(); t = 0.0
	for i in g.wells.size():
		well_b[i] = 0 if g.wells[i].dry else 4
	var a := Agent.new()
	a.pos = Vector2(3, 3)
	# wreck loot
	a.add("konserve", 3); a.add("su_sise", 2); a.add("bez", 3); a.add("kova", 1)
	var rng := RandomNumberGenerator.new(); rng.seed = seed_v
	var wander := Vector2.ZERO
	var drank_at := -999.0
	var mins := {"water": 100.0, "food": 100.0, "hp": 100.0, "tmin": 37.0, "tmax": 37.0}
	while t < maxd * GameData.DAY_LEN and not a.s.dead():
		var tod := fmod(t, GameData.DAY_LEN)
		var day := int(t / GameData.DAY_LEN) + 1
		var night := GameData.is_night(tod)
		var ws := w.state(t)
		var moving := false
		var running := false
		if mode == "careful":
			var r := careful_step(a, tod, day, night, ws)
			moving = r[0]; running = r[1]
		else:
			if wander == Vector2.ZERO or a.pos.distance_to(wander) < 3.0:
				wander = Vector2(rng.randf_range(-250, 250), rng.randf_range(-250, 250))
			running = a.s.can_run() and rng.randf() < 0.5
			moving = _move(a, wander, GameData.RUN_SPEED if running else GameData.WALK_SPEED)
			if a.s.water < 20.0 and a.canteen > 0:
				a.canteen -= 1; a.s.drink(GameData.CANTEEN_SIP)
			if a.s.water < 20.0 and a.has("su_sise"):
				a.take("su_sise"); a.s.drink(30.0)
			if a.s.food < 20.0 and a.has("konserve"):
				a.take("konserve"); a.s.eat(30.0); a.s.drink(5.0)
			for o in g.oases:   # drinks only if it stumbles on water (once per visit)
				if a.pos.distance_to(o) < 25.0 and t > drank_at + 90.0:
					a.s.drink(GameData.SOURCE_DRINK); drank_at = t
		# environment
		var shaded := is_shaded(a.pos, a)
		var sun := 0.0 if shaded or night else GameData.sun_strength(tod)
		var amb := GameData.air_temp(tod, day) + GameData.SUN_HEAT * sun
		if a.fire_pos != null and a.fire_left > 0.0 and a.pos.distance_to(a.fire_pos) < GameData.FIRE_RADIUS:
			amb += 25.0
		if night and a.shelter != null and a.pos.distance_to(a.shelter) < 3.0:
			amb += 10.0
		if night and _in_cave(a.pos):
			amb += 8.0
		var storm_exposed := ws == "storm" and not is_sheltered(a.pos, a)
		a.s.tick(DT, {"sun": sun, "ambient": amb, "moving": moving, "running": running, "night": night, "storm": storm_exposed})
		if a.fire_left > 0.0:
			a.fire_left -= DT
		# nightly trap catch at dawn handled crudely
		t += DT
		mins.water = minf(mins.water, a.s.water); mins.food = minf(mins.food, a.s.food); mins.hp = minf(mins.hp, a.s.hp)
		mins.tmin = minf(mins.tmin, a.s.temp); mins.tmax = maxf(mins.tmax, a.s.temp)
	return {"alive": not a.s.dead(), "days": t / GameData.DAY_LEN, "cause": a.s.cause if a.s.dead() else "-", "mins": mins}

func _move(a: Agent, to: Vector2, speed: float) -> bool:
	var d := to - a.pos
	if d.length() < 0.5:
		return false
	a.pos += d.normalized() * minf(speed * DT, d.length())
	return true

func _in_cave(p: Vector2) -> bool:
	for c in g.caves:
		if p.distance_to(c.p) < 6.0: return true
	return false

func shelters(a: Agent) -> Array:
	var out: Array = [g.wreck, g.caravan]
	out.append_array(g.ruins)
	for c in g.caves: out.append(c.p)
	if a.shelter != null: out.append(a.shelter)
	return out

func is_sheltered(p: Vector2, a: Agent) -> bool:
	for q in shelters(a):
		if p.distance_to(q) < 6.0: return true
	return false

func is_shaded(p: Vector2, a: Agent) -> bool:
	if is_sheltered(p, a): return true
	for i in g.nodes.size():
		var n: Dictionary = g.nodes[i]
		if n.t == "palm" and p.distance_to(n.p) < 2.6: return true
	return false

func node_ready(i: int) -> bool:
	return t >= avail.get(i, 0.0)

func nearest_node(p: Vector2, types: Array, maxd := 400.0) -> int:
	var best := -1; var bd := maxd
	for i in g.nodes.size():
		var n: Dictionary = g.nodes[i]
		if n.t in types and node_ready(i):
			var d := p.distance_to(n.p)
			if d < bd: bd = d; best = i
	return best

func harvest(a: Agent, i: int) -> void:
	var n: Dictionary = g.nodes[i]
	match n.t:
		"bush": a.add("odun"); a.add("cubuk"); a.add("lif"); avail[i] = t + 2 * GameData.DAY_LEN
		"stone": a.add("tas"); avail[i] = t + 2 * GameData.DAY_LEN
		"pear": a.s.eat(8); a.s.drink(6); avail[i] = t + GameData.DAY_LEN
		"palm": a.s.eat(24); a.s.drink(10); a.add("lif", 2); avail[i] = t + 2 * GameData.DAY_LEN
		"cactus":
			a.s.drink(15); a.s.eat(5)
			if not a.has("bicak"): a.s.damage(5, "kaktüs")
			avail[i] = t + 3 * GameData.DAY_LEN

func water_sources() -> Array:
	var out: Array = []
	for o in g.oases: out.append(o)
	for i in g.wells.size():
		if well_b[i] > 0: out.append(g.wells[i].p)
	return out

func drink_at(a: Agent, p: Vector2) -> void:
	for i in g.wells.size():
		if g.wells[i].p == p:
			well_b[i] -= 1
	a.s.drink(GameData.SOURCE_DRINK)
	a.canteen = a.cap
	if a.has("bos_sise"):
		a.add("su_sise", a.inv.bos_sise); a.inv.bos_sise = 0

## Careful policy. Returns [moving, running].
func careful_step(a: Agent, tod: float, day: int, night: bool, ws: String) -> Array:
	var h := GameData.hour_of(tod)
	# crafting whenever possible
	if not a.has("bicak") and a.has("tas", 2) and a.has("cubuk"):
		a.take("tas", 2); a.take("cubuk"); a.add("bicak")
	if not a.has("ip") and a.has("lif", 3) and a.shelter == null:
		a.take("lif", 3); a.add("ip")
	if a.shelter == null and a.has("bez", 2) and a.has("cubuk", 3) and a.has("ip"):
		a.take("bez", 2); a.take("cubuk", 3); a.take("ip"); a.shelter = a.pos
	# drink / eat from inventory
	if a.s.water < 50.0 and a.canteen > 0:
		a.canteen -= 1; a.s.drink(GameData.CANTEEN_SIP)
	elif a.s.water < 45.0 and a.has("su_sise"):
		a.take("su_sise"); a.add("bos_sise"); a.s.drink(30.0)
	if a.s.food < 45.0 and a.has("konserve"):
		a.take("konserve"); a.s.eat(30.0); a.s.drink(5.0)
	# 1. storms
	if ws != "":
		if is_sheltered(a.pos, a):
			return [false, false]
		var sp: Vector2 = g.nearest(a.pos, shelters(a))
		var run := ws == "storm" or a.pos.distance_to(sp) > 160.0
		return [_move(a, sp, GameData.RUN_SPEED if run and a.s.can_run() else GameData.WALK_SPEED), run]
	# 2. water
	var low_water := a.s.water < 55.0 and a.canteen == 0
	if low_water or (a.canteen < 2 and not night):
		var wp: Vector2 = g.nearest(a.pos, water_sources())
		if a.pos.distance_to(wp) < 2.0:
			drink_at(a, wp)
		elif low_water or a.pos.distance_to(wp) < 150.0:
			return [_move(a, wp, GameData.WALK_SPEED), false]
	# 3. night: fire camp
	if night or h > 18.3:
		if a.fire_pos == null or a.fire_left <= 0.0:
			if a.has("odun", 3) and a.has("tas", 2):
				a.take("odun", 3); a.take("tas", 2)
				a.fire_pos = a.shelter if (a.shelter != null and a.pos.distance_to(a.shelter) < 40.0) else a.pos
				a.fire_left = GameData.FIRE_TIME
			elif night:
				var cp: Vector2 = g.nearest(a.pos, g.caves.map(func(c): return c.p))
				if a.pos.distance_to(cp) < 100.0:
					return [_move(a, cp, GameData.WALK_SPEED), false]
		if a.fire_pos != null and a.fire_left > 0.0:
			if a.fire_left < 15.0 and a.has("odun"):
				a.take("odun"); a.fire_left += GameData.FIRE_ADD
			return [_move(a, a.fire_pos, GameData.WALK_SPEED), false]
	# 4. noon heat: rest in shade
	if h > 11.0 and h < 15.5 and a.s.temp > 38.3:
		var shade: Variant = nearest_shade(a)
		if shade != null and a.pos.distance_to(shade) < 70.0:
			return [_move(a, shade, GameData.WALK_SPEED), false]
	# 5. food
	if a.s.food < 55.0:
		var i := nearest_node(a.pos, ["palm", "pear"] if a.s.water > 40 else ["palm", "pear", "cactus"])
		if i >= 0:
			if a.pos.distance_to(g.nodes[i].p) < 1.5:
				harvest(a, i)
			return [_move(a, g.nodes[i].p, GameData.WALK_SPEED), false]
	if a.s.water < 50.0 and a.has("bicak"):
		var ci := nearest_node(a.pos, ["cactus"], 40.0)
		if ci >= 0:
			if a.pos.distance_to(g.nodes[ci].p) < 1.5: harvest(a, ci)
			return [_move(a, g.nodes[ci].p, GameData.WALK_SPEED), false]
	# 6. gather fuel and stones
	var need := []
	if a.inv.get("odun", 0) < 5: need.append("bush")
	if a.inv.get("tas", 0) < 4: need.append("stone")
	if not need.is_empty():
		var j := nearest_node(a.pos, need, 120.0)
		if j >= 0:
			if a.pos.distance_to(g.nodes[j].p) < 1.5: harvest(a, j)
			return [_move(a, g.nodes[j].p, GameData.WALK_SPEED), false]
	return [false, false]

func nearest_shade(a: Agent) -> Variant:
	var pts: Array = shelters(a)
	for n in g.nodes:
		if n.t == "palm": pts.append(n.p)
	return g.nearest(a.pos, pts)
