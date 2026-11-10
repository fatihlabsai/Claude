## One horizontal slice of the static city. Splitting the city into slices lets
## Godot cull the parts that are off-screen, which keeps mobile/web fast.
extends Node2D

var items: Array = []
var land: Node = null

func _draw() -> void:
	for it in items:
		land.draw_item(self, it)
