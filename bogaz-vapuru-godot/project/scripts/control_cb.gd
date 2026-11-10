## Control whose _draw calls a Callable (used for minimap, indicators, icons).
extends Control

var fn: Callable

func _draw() -> void:
	if fn.is_valid():
		fn.call(self)
