## Static game data: items, recipes, balance constants (shared by game and balance sim).
class_name GameData
extends RefCounted

const DAY_LEN := 480.0          # real seconds per in-game day
const DAY_PART := 300.0         # first 300 s = daylight (06:00-19:00), rest = night
const SLOTS := 8
const STACK := 5

# --- Survival balance (Normal difficulty, per real minute unless noted) ---
const WATER_DRAIN := 8.0
const SUN_WATER_MUL := 1.75
const NIGHT_WATER_MUL := 0.5
const RUN_WATER := 6.0
const FOOD_DRAIN := 4.0
const RUN_FOOD := 1.0
const COLD_FOOD := 2.0
const TEMP_RATE := 1.5          # °C per minute toward target
const TEMP_K := 0.09
const HEAT_LIMIT := 39.5
const COLD_LIMIT := 35.0
const THIRST_DMG := 1.5         # hp per second at 0 water
const HUNGER_DMG := 0.5
const TEMP_DMG := 0.75
const SUN_HEAT := 18.0          # °C added to air temperature in full sun
const STORM_DMG := 1.0
const REGEN := 0.35             # hp per second when well
const WALK_SPEED := 4.0
const RUN_SPEED := 7.0
const DIFF_MUL := [0.75, 1.0, 1.3]
const DIFF_NAMES := ["Kolay", "Normal", "Zor"]

const CANTEEN_SIP := 20.0
const CANTEEN_CAP := 4
const CANTEEN_CAP_BIG := 8
const SOURCE_DRINK := 40.0

const ITEMS := {
	"tas": {"name": "Taş", "icon": "survival/resource-stone", "tint": Color(1, 1, 1)},
	"cubuk": {"name": "Çubuk", "icon": "nature/log", "tint": Color(1, 1, 1)},
	"odun": {"name": "Odun", "icon": "survival/resource-wood", "tint": Color(1, 1, 1)},
	"lif": {"name": "Lif", "icon": "nature/plant_flatShort", "tint": Color(1.0, 0.85, 0.45)},
	"bez": {"name": "Bez", "icon": "survival/bedroll-packed", "tint": Color(1, 1, 1)},
	"deri": {"name": "Deri", "icon": "food/bag-flat", "tint": Color(0.9, 0.62, 0.4)},
	"ip": {"name": "İp", "icon": "", "draw": "rope"},
	"bos_sise": {"name": "Boş şişe", "icon": "survival/bottle", "tint": Color(1, 1, 1)},
	"su_sise": {"name": "Su şişesi", "icon": "survival/bottle-large", "tint": Color(0.7, 0.9, 1.3), "use": {"water": 30.0}, "after": "bos_sise", "verb": "İç"},
	"konserve": {"name": "Konserve", "icon": "food/can", "tint": Color(1, 1, 1), "use": {"food": 30.0, "water": 5.0}, "verb": "Ye"},
	"cig_et": {"name": "Çiğ et", "icon": "food/meat-raw", "tint": Color(1, 1, 1), "use": {"food": 15.0, "sick": 0.3}, "verb": "Ye"},
	"pismis_et": {"name": "Pişmiş et", "icon": "food/meat-cooked", "tint": Color(1, 1, 1), "use": {"food": 35.0}, "verb": "Ye"},
	"pismis_kus": {"name": "Pişmiş keklik", "icon": "food/meat-cooked", "tint": Color(1.1, 0.95, 0.75), "use": {"food": 20.0}, "verb": "Ye"},
	"cig_kus": {"name": "Çiğ keklik", "icon": "food/meat-raw", "tint": Color(1.1, 0.9, 0.85), "use": {"food": 8.0, "sick": 0.3}, "verb": "Ye"},
	"yilan_eti": {"name": "Yılan eti", "icon": "food/meat-raw", "tint": Color(0.8, 1.0, 0.7), "use": {"food": 8.0, "sick": 0.5}, "verb": "Ye"},
	"pismis_yilan": {"name": "Pişmiş yılan", "icon": "food/meat-cooked", "tint": Color(0.9, 1.0, 0.8), "use": {"food": 25.0}, "verb": "Ye"},
	"hurma": {"name": "Hurma", "icon": "food/grapes", "tint": Color(0.55, 0.32, 0.18), "use": {"food": 12.0, "water": 5.0}, "verb": "Ye"},
	"incir": {"name": "Frenk inciri", "icon": "food/pear", "tint": Color(1.2, 0.45, 0.6), "use": {"food": 8.0, "water": 6.0}, "verb": "Ye"},
	"bicak": {"name": "Taş bıçak", "icon": "food/cooking-knife", "tint": Color(0.85, 0.8, 0.75), "tool": true},
	"mizrak": {"name": "Mızrak", "icon": "chars/weapon-spear", "tint": Color(1, 1, 1), "tool": true},
	"sargi": {"name": "Sargı", "icon": "", "draw": "bandage", "use": {"hp": 25.0}, "verb": "Sar"},
	"kova": {"name": "Kova", "icon": "survival/bucket", "tint": Color(1, 1, 1), "tool": true},
	"anten": {"name": "Telsiz anteni", "icon": "", "draw": "antenna", "quest": true},
	"pil": {"name": "Telsiz pili", "icon": "", "draw": "battery", "quest": true},
	"devre": {"name": "Devre kartı", "icon": "", "draw": "circuit", "quest": true},
}

# result: item id or placeable "place:<kind>" or upgrade
const RECIPES := [
	{"id": "place:fire", "name": "Kamp ateşi", "needs": {"odun": 3, "tas": 2}, "desc": "Isıtır, pişirir, hayvanları kaçırır. 90 sn yanar."},
	{"id": "bicak", "name": "Taş bıçak", "needs": {"tas": 2, "cubuk": 1}, "desc": "Kaktüs keser, av yüzer."},
	{"id": "mizrak", "name": "Mızrak", "needs": {"cubuk": 3, "tas": 1}, "desc": "Av için menzil ve hasar."},
	{"id": "ip", "name": "İp", "needs": {"lif": 3}, "desc": "Kuyu, tuzak ve gölgelik için."},
	{"id": "sargi", "name": "Sargı", "needs": {"bez": 1}, "desc": "+25 sağlık."},
	{"id": "place:dew", "name": "Çiy toplayıcı", "needs": {"bez": 1, "cubuk": 2, "bos_sise": 1}, "desc": "Gece kur, şafakta +30 su."},
	{"id": "place:trap", "name": "Tuzak", "needs": {"cubuk": 2, "ip": 1}, "desc": "Her gece %40 tavşan yakalar."},
	{"id": "place:shelter", "name": "Gölgelik", "needs": {"bez": 2, "cubuk": 3, "ip": 1}, "desc": "Gölge, gece +10°C, fırtına sığınağı."},
	{"id": "up:canteen", "name": "Deri matara", "needs": {"deri": 2, "ip": 1}, "desc": "Matara 8 yudum olur."},
]

const FIRE_TIME := 90.0
const FIRE_ADD := 60.0
const FIRE_RADIUS := 5.0

static func hour_of(t: float) -> float:
	# t = seconds into the day; returns clock hour 0..24 (day starts 06:00)
	if t < DAY_PART:
		return 6.0 + 13.0 * t / DAY_PART
	return fmod(19.0 + 11.0 * (t - DAY_PART) / (DAY_LEN - DAY_PART), 24.0)

static func is_night(t: float) -> bool:
	return t >= DAY_PART

## Sun strength 0..1 for a given time of day.
static func sun_strength(t: float) -> float:
	if t >= DAY_PART:
		return 0.0
	return clampf(sin(PI * t / DAY_PART) * 1.25, 0.0, 1.0)

## Air (shade) temperature in °C for time-of-day t and day number (1-based).
static func air_temp(t: float, day: int) -> float:
	var h := hour_of(t)
	var hot := 1.0 * (day - 1)
	if t < DAY_PART:
		# 06:00 cool (14) -> 13:30 peak (35) -> 19:00 (24)
		var f := sin(PI * clampf((h - 6.0) / 15.0, 0.0, 1.0))
		return 12.0 + 23.0 * f + hot * f
	# night: 19:00 20 -> 01:00 -6 -> 06:00 10 (cold desert night)
	var nh := h if h >= 19.0 else h + 24.0
	if nh < 25.0:
		return lerpf(20.0, -6.0, (nh - 19.0) / 6.0)
	return lerpf(-6.0, 10.0, (nh - 25.0) / 5.0)

static func clock_text(t: float) -> String:
	var h := hour_of(t)
	return "%02d:%02d" % [int(h), int(fmod(h, 1.0) * 60.0)]
