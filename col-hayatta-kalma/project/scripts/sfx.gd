## Sound manager: pooled one-shots, looping music (menu/day/night) and ambience loops.
## Sounds: Kenney (CC0) and OpenGameArt (CC0) — see CREDITS.md.
extends Node

const SFX := ["bottle", "chop", "click", "close", "cloth", "craft", "creak", "drink", "error", "hint", "hit", "hurt", "lose", "metal", "open", "pickup", "slice", "stone", "warn", "win", "wood", "step_sand1", "step_sand2", "step_sand3", "step_stone1", "step_stone2", "step_stone3"]

var streams := {}
var pool: Array[AudioStreamPlayer] = []
var music := {}
var loops := {}
var _mode := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in SFX:
		streams[n] = load("res://assets/audio/sfx/%s.ogg" % n)
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	for m in ["menu", "day", "night"]:
		music[m] = _looper("res://assets/audio/music/%s.ogg" % m, -10.0)
	loops["storm"] = _looper("res://assets/audio/sfx/storm.ogg", -6.0)
	loops["breeze"] = _looper("res://assets/audio/sfx/breeze.ogg", -18.0)
	loops["fire"] = _looper("res://assets/audio/sfx/fire.ogg", -8.0)
	Settings.changed.connect(_on_settings)

func _looper(path: String, db: float) -> AudioStreamPlayer:
	var s: AudioStreamOggVorbis = load(path)
	s.loop = true
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = -60.0
	p.set_meta("base", db)
	add_child(p)
	return p

func play(n: String, db := 0.0, pitch := 1.0) -> void:
	if not streams.has(n):
		return
	for p in pool:
		if not p.playing:
			p.stream = streams[n]
			p.volume_db = db
			p.pitch_scale = pitch * randf_range(0.95, 1.05)
			p.play()
			return

func set_music(mode: String) -> void:
	if mode == _mode:
		return
	_mode = mode
	for k in music:
		var p: AudioStreamPlayer = music[k]
		var on: bool = k == mode and Settings.music
		if on and not p.playing:
			p.volume_db = -40.0
			p.play()
		var tw := create_tween()
		tw.tween_property(p, "volume_db", p.get_meta("base") if on else -60.0, 2.0)
		if not on:
			tw.tween_callback(func(): if _mode != k: p.stop())

## Sets the loudness of an ambience loop (0 = silent, 1 = full).
func set_loop(n: String, level: float) -> void:
	var p: AudioStreamPlayer = loops[n]
	if level <= 0.01:
		if p.playing:
			p.stop()
		return
	if not p.playing:
		p.play()
	p.volume_db = p.get_meta("base") + linear_to_db(clampf(level, 0.01, 1.0))

func _on_settings() -> void:
	var m := _mode
	_mode = ""
	set_music(m)
