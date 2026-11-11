## Flickers the campfire light (energy + small position wobble).
extends OmniLight3D

var base := 1.8
var _t := randf() * 100.0

func _process(dt: float) -> void:
	_t += dt
	var f := 0.82 + 0.1 * sin(_t * 11.0) + 0.07 * sin(_t * 23.7 + 1.3) + 0.06 * sin(_t * 5.3)
	light_energy = base * f
	position = Vector3(sin(_t * 7.1) * 0.05, 1.35 + sin(_t * 9.3) * 0.04, cos(_t * 6.7) * 0.05)
