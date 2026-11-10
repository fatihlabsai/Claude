## Sound manager: a pool of one-shot players plus looping music and ambience.
## Sounds: Kenney (CC0), OpenGameArt (CC0 / CC-BY 3.0), horns synthesised for this game.
extends Node

const SFX := ["click", "board", "ding", "bonus", "sad", "tick", "toss", "hit_big", "hit_small", "bump", "win", "lose", "target", "gull1", "gull2", "gull3", "gull_happy", "splash", "wave", "horn", "ship_horn"]

var streams := {}
var pool: Array[AudioStreamPlayer] = []
var music_menu: AudioStreamPlayer
var music_game: AudioStreamPlayer
var ambience: AudioStreamPlayer
var muted := false
var _music_mode := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in SFX:
		streams[n] = load("res://assets/audio/sfx/%s.ogg" % n)
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	music_menu = _looper("res://assets/audio/music/menu.ogg", -9.0)
	music_game = _looper("res://assets/audio/music/game.ogg", -11.0)
	ambience = _looper("res://assets/audio/music/ambience.ogg", -15.0)

func _looper(path: String, db: float) -> AudioStreamPlayer:
	var s: AudioStreamOggVorbis = load(path)
	s.loop = true
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = db
	p.set_meta("base_db", db)
	add_child(p)
	return p

func play(n: String, db := 0.0, pitch := 1.0) -> void:
	if not streams.has(n):
		return
	for p in pool:
		if not p.playing:
			p.stream = streams[n]
			p.volume_db = db
			p.pitch_scale = pitch
			p.play()
			return

func set_music(mode: String) -> void:
	if mode == _music_mode:
		return
	_music_mode = mode
	if not ambience.playing:
		ambience.play()
	var on := music_menu if mode == "menu" else music_game
	var off := music_game if mode == "menu" else music_menu
	if not on.playing:
		on.volume_db = -40
		on.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(on, "volume_db", on.get_meta("base_db"), 1.2)
	tw.tween_property(off, "volume_db", -40.0, 1.2)
	tw.chain().tween_callback(func(): if _music_mode != "" and off != (music_menu if _music_mode == "menu" else music_game): off.stop())

func set_muted(m: bool) -> void:
	muted = m
	AudioServer.set_bus_mute(0, m)
