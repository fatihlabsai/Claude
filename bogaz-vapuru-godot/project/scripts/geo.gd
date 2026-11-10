## Geography, constants and difficulty curve shared by every script.
## Ported 1:1 from the HTML5 version so the gameplay feels identical.
class_name Geo
extends RefCounted

const WORLD_W := 1400.0
const WORLD_TOP := -320.0
const WORLD_BOTTOM := 1800.0
const WATER_TOP := -40.0
const DOCK_R := 72.0
const BRIDGE_Y := 150.0
const MAIDEN := Vector2(1000, 1010)
const MAIDEN_R := 26.0

# Shore control points: [y, x]. North is up. Europe on the left, Asia on the right.
const EU_PTS := [[-320, 300], [0, 312], [150, 345], [300, 322], [450, 292], [560, 280], [680, 300], [820, 322], [960, 330], [1100, 312], [1250, 300], [1360, 300], [1480, 332], [1600, 362], [1700, 352], [1800, 340]]
const AS_PTS := [[-320, 1090], [0, 1082], [150, 1055], [300, 1068], [480, 1090], [650, 1100], [800, 1092], [950, 1100], [1100, 1125], [1250, 1160], [1400, 1205], [1500, 1225], [1600, 1240], [1700, 1255], [1800, 1270]]

const PIER_DEFS := [
	{"id": 0, "name": "Karaköy", "side": "eu", "y": 1340.0, "color": Color("#e8434b")},
	{"id": 1, "name": "Beşiktaş", "side": "eu", "y": 560.0, "color": Color("#2f7fe0")},
	{"id": 2, "name": "Kadıköy", "side": "as", "y": 1500.0, "color": Color("#2bb36b")},
	{"id": 3, "name": "Üsküdar", "side": "as", "y": 650.0, "color": Color("#f08a1c")},
]

const SKIN := [Color("#f3c9a5"), Color("#e0ac85"), Color("#c68c5f"), Color("#f6d7bd"), Color("#a8714a")]
const HAIR := [Color("#3b2a1e"), Color("#6b4a2b"), Color("#1f1f1f"), Color("#c9a15a"), Color("#8a8a8a"), Color("#a0522d")]
const NAVY := Color("#1d3557")

static func _interp(pts: Array, y: float) -> float:
	if y <= pts[0][0]:
		return pts[0][1]
	for i in range(1, pts.size()):
		if y <= pts[i][0]:
			var a: Array = pts[i - 1]
			var b: Array = pts[i]
			var t = (y - a[0]) / float(b[0] - a[0])
			var s := (1.0 - cos(PI * t)) / 2.0
			return a[1] + (b[1] - a[1]) * s
	return pts[pts.size() - 1][1]

static func eu_x(y: float) -> float:
	return _interp(EU_PTS, y) + 4.0 * sin(y * 0.021)

static func as_x(y: float) -> float:
	return _interp(AS_PTS, y) + 4.0 * sin(y * 0.019 + 1.3)

## Difficulty for a given sefer (trip) number.
static func diff(s: int) -> Dictionary:
	return {
		"tanker_every": maxf(3.6, 10.0 - s * 0.9), "tanker_spd": minf(80.0, 30.0 + s * 5.0), "max_ships": mini(6, 2 + s / 2),
		"kayiks": mini(11, 3 + s), "kayik_spd": minf(48.0, 16.0 + s * 3.5),
		"vapurs": (mini(3, 1 + (s - 1) / 2) if s >= 2 else 0), "vapur_spd": minf(80.0, 50.0 + s * 3.0),
		"cur": minf(55.0, 10.0 + (s - 1) * 6.0), "cur_swing": minf(1.2, 0.35 + s * 0.1),
		"pax_every": maxf(2.6, 5.6 - s * 0.3), "patience": maxf(24.0, 46.0 - (s - 1) * 2.5),
		"target": mini(30, 5 + (s - 1) * 3), "time": 100.0, "pts": 100 + (s - 1) * 20,
		"gulls": mini(9, 4 + s / 2), "gull_pts": 50 + (s - 1) * 10,
	}

static func ang_diff(a: float, b: float) -> float:
	return wrapf(a - b, -PI, PI)

static func fmt(n: float) -> String:
	# Turkish thousands separator: 12.345
	var v := int(round(n))
	var neg := v < 0
	var s := str(absi(v))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if neg else "") + s + out
