## Generic draw layer: forwards _draw() to a function on the main game node so
## that every visual depth (water fx, boats, sky, gulls, texts...) is its own
## CanvasItem and therefore sorts correctly.
extends Node2D

var kind := ""
var main: Node = null

func _draw() -> void:
	if main:
		main.call("draw_" + kind, self)
