## Tiny helper: a Node2D/Control-less canvas item whose _draw calls a Callable.
extends Node2D

var fn: Callable

func _draw() -> void:
	if fn.is_valid():
		fn.call(self)
