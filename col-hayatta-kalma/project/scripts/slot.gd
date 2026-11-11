## Inventory slot / item icon widget.
extends Control

signal clicked
var item := ""
var count := 0
var selected := false
var small := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(78, 78)

func _gui_input(ev: InputEvent) -> void:
	if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
		clicked.emit()
		accept_event()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if not small:
		draw_style_box(UiKit.flat_box(Color("#f6e3bd") if not selected else Color("#ffd27a"), 10, 3 if selected else 2, Color("#3a2414") if selected else Color("#a0784e")), r)
	if item == "":
		return
	draw_item(self, item, r.grow(-6 if not small else 0))
	if count > 1:
		var f := UiKit.head_font
		var s := str(count)
		var fs := 20 if not small else 15
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string_outline(f, Vector2(size.x - w - 6, size.y - 6), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color("#3a2414"))
		draw_string(f, Vector2(size.x - w - 6, size.y - 6), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)

static func draw_item(ci: CanvasItem, id: String, r: Rect2) -> void:
	var it: Dictionary = GameData.ITEMS.get(id, {})
	if Icons.tex.has(id):
		ci.draw_texture_rect(Icons.tex[id], r, false)
	elif it.has("draw"):
		UiKit.draw_icon(ci, it.draw, r.get_center(), r.size.x * 0.42)
	else:
		UiKit.draw_icon(ci, "bag", r.get_center(), r.size.x * 0.35)
