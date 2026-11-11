## Sandstorm scheduler (shared by game and balance sim).
## Timeline (in absolute game seconds): warn_at -> start_at -> end_at.
class_name Weather
extends RefCounted

const WARN := 60.0
var rng := RandomNumberGenerator.new()
var warn_at := 0.0
var start_at := 0.0
var end_at := 0.0
var dir := 0.0          # storm direction (radians, where it comes from)
var count := 0

func setup(seed_v: int) -> void:
	rng.seed = seed_v * 7 + 3
	# first storm: somewhere during day 2 daylight
	_plan(GameData.DAY_LEN + rng.randf_range(60.0, 240.0))

func _plan(start: float) -> void:
	start_at = start
	warn_at = start - WARN
	end_at = start + rng.randf_range(45.0, 90.0)
	dir = rng.randf() * TAU

## Returns "" / "warn" / "storm" for absolute time t and advances the schedule.
func state(t: float) -> String:
	if t >= end_at:
		count += 1
		var day := int(t / GameData.DAY_LEN) + 1
		var shrink := pow(0.9, maxi(day - 2, 0))
		_plan(t + rng.randf_range(300.0, 540.0) * shrink + WARN)
	if t >= start_at:
		return "storm"
	if t >= warn_at:
		return "warn"
	return ""

## Storm intensity 0..1 with soft ramps (for visuals).
func intensity(t: float) -> float:
	if t < start_at - 8.0 or t > end_at + 6.0:
		return 0.0
	return clampf((t - (start_at - 8.0)) / 8.0, 0.0, 1.0) * clampf((end_at + 6.0 - t) / 6.0, 0.0, 1.0)

func to_dict() -> Dictionary:
	return {"warn": warn_at, "start": start_at, "end": end_at, "dir": dir, "count": count, "rng": rng.state}

func from_dict(d: Dictionary) -> void:
	warn_at = d.warn; start_at = d.start; end_at = d.end; dir = d.dir; count = int(d.count)
	rng.state = int(d.rng)
