## Persistent player settings (user://settings.json -> localStorage/IndexedDB on web).
extends Node

signal changed

const PATH := "user://settings.json"
const QUALITY_NAMES := ["Düşük", "Orta", "Yüksek"]
# per quality: shadows, particle amount multiplier, 3D render scale, view distance (m)
const Q := [
	{"shadows": false, "particles": 0.4, "scale": 0.75, "far": 75.0},
	{"shadows": true, "particles": 0.7, "scale": 0.9, "far": 105.0},
	{"shadows": true, "particles": 1.0, "scale": 1.0, "far": 150.0},
]

var quality := 1
var sound := true
var music := true
var touch := false

func _ready() -> void:
	touch = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	quality = 0 if touch else 1
	if FileAccess.file_exists(PATH):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if d is Dictionary:
			quality = clampi(int(d.get("quality", quality)), 0, 2)
			sound = bool(d.get("sound", true))
			music = bool(d.get("music", true))
	_apply_audio()

func q() -> Dictionary:
	return Q[quality]

func set_quality(v: int) -> void:
	quality = clampi(v, 0, 2)
	save(); changed.emit()

func set_sound(v: bool) -> void:
	sound = v; _apply_audio(); save(); changed.emit()

func set_music(v: bool) -> void:
	music = v; _apply_audio(); save(); changed.emit()

func _apply_audio() -> void:
	AudioServer.set_bus_mute(0, not sound)

func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"quality": quality, "sound": sound, "music": music}))
