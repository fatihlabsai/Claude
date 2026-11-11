## Player survival stats. Pure logic so the balance simulation can reuse it.
class_name Survival
extends RefCounted

var water := 70.0
var food := 80.0
var temp := 37.0
var stamina := 100.0
var hp := 100.0
var poison := 0.0       # seconds of poison left
var exhausted := 0.0    # seconds of forced slow walk
var diff := 1
var cause := ""         # last damage cause (for death screen)

func to_dict() -> Dictionary:
	return {"water": water, "food": food, "temp": temp, "stamina": stamina, "hp": hp, "poison": poison}

func from_dict(d: Dictionary) -> void:
	water = d.get("water", water); food = d.get("food", food); temp = d.get("temp", temp)
	stamina = d.get("stamina", stamina); hp = d.get("hp", hp); poison = d.get("poison", 0.0)

func stamina_cap() -> float:
	var cap := 100.0
	if water < 25.0:
		cap = minf(cap, 60.0)
	if food < 30.0:
		cap -= 30.0
	return cap

func can_run() -> bool:
	return exhausted <= 0.0 and stamina > 1.0

func heat_stroke() -> bool:
	return temp >= GameData.HEAT_LIMIT

func hypothermia() -> bool:
	return temp <= GameData.COLD_LIMIT

func well() -> bool:
	return water > 50.0 and food > 50.0 and not heat_stroke() and not hypothermia() and poison <= 0.0

## c: {sun:0..1 exposure, ambient:°C, moving:bool, running:bool, night:bool,
##     storm:bool (exposed to sandstorm), climbing:bool, resting:bool}
func tick(dt: float, c: Dictionary) -> void:
	var m: float = GameData.DIFF_MUL[diff]
	var mn := dt / 60.0
	var sun: float = c.get("sun", 0.0)
	var running: bool = c.get("running", false)
	var moving: bool = c.get("moving", false)
	# --- water ---
	var wmul := 1.0
	if c.get("night", false):
		wmul = GameData.NIGHT_WATER_MUL
	wmul = lerpf(wmul, GameData.SUN_WATER_MUL, sun)
	if heat_stroke():
		wmul *= 1.5
	if c.get("storm", false):
		wmul *= 1.5
	var wd := GameData.WATER_DRAIN * wmul + (GameData.RUN_WATER if running else 0.0)
	water = maxf(0.0, water - wd * m * mn)
	# --- food ---
	var cold: bool = temp < 36.0
	var fd := GameData.FOOD_DRAIN + (GameData.RUN_FOOD if running else 0.0) + (GameData.COLD_FOOD if cold else 0.0)
	food = maxf(0.0, food - fd * m * mn)
	# --- body temperature ---
	var amb: float = c.get("ambient", 28.0)
	var target := 37.0 + GameData.TEMP_K * (amb - 28.0)
	if running:
		target += 1.0
	elif moving:
		target += 0.4
	target = clampf(target, 33.5, 41.0)
	temp = move_toward(temp, target, GameData.TEMP_RATE * mn * (1.0 if m <= 1.0 else m))
	# --- stamina ---
	if exhausted > 0.0:
		exhausted -= dt
	if running and moving:
		stamina -= 15.0 * dt
		if stamina <= 0.0:
			stamina = 0.0
			exhausted = 3.0
	elif c.get("climbing", false) and moving:
		stamina -= 4.0 * dt
	else:
		var regen := 20.0 if not moving else 10.0
		if food <= 0.0 or hypothermia():
			regen *= 0.5
		stamina += regen * dt
	stamina = clampf(stamina, 0.0, stamina_cap())
	# --- health ---
	var dmg := 0.0
	if water <= 0.0:
		dmg += GameData.THIRST_DMG; cause = "susuzluk"
	if food <= 0.0:
		dmg += GameData.HUNGER_DMG; cause = "açlık"
	if heat_stroke():
		dmg += GameData.TEMP_DMG; cause = "sıcak çarpması"
	if hypothermia():
		dmg += GameData.TEMP_DMG; cause = "soğuk"
	if c.get("storm", false):
		dmg += GameData.STORM_DMG; cause = "kum fırtınası"
	if poison > 0.0:
		poison -= dt
		dmg += 1.0; cause = "zehir"
	if dmg > 0.0:
		hp -= dmg * dt * (1.0 if m <= 1.0 else m)
	elif well():
		hp = minf(100.0, hp + GameData.REGEN * dt / m)
	hp = maxf(hp, 0.0)

func damage(v: float, why: String) -> void:
	hp = maxf(0.0, hp - v)
	cause = why

func drink(v: float) -> void:
	water = minf(100.0, water + v)

func eat(v: float) -> void:
	food = minf(100.0, food + v)

func dead() -> bool:
	return hp <= 0.0
