## Round touch button with a vector icon and a label. Emits pressed_btn / released_btn.
extends Control

signal pressed_btn
signal released_btn
var icon := "hand"
var text := ""
var col := Color("#e2683c")
var radius := 46.0
var down := false
var enabled := true
var badge := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(radius * 2 + 12, radius * 2 + 12)
	size = custom_minimum_size

func _gui_input(ev: InputEvent) -> void:
	var pressed := false
	var handled := false
	if ev is InputEventScreenTouch:
		pressed = ev.pressed; handled = true
	elif ev is InputEventMouseButton and ev.device != InputEvent.DEVICE_ID_EMULATION and ev.button_index == MOUSE_BUTTON_LEFT:
		pressed = ev.pressed; handled = true
	if handled:
		if pressed and not down:
			down = true
			pressed_btn.emit()
		elif not pressed and down:
			down = false
			released_btn.emit()
		queue_redraw()
		accept_event()

func _draw() -> void:
	var c := size / 2
	var r := radius * (0.93 if down else 1.0)
	var base := col if enabled else Color(0.55, 0.52, 0.5)
	draw_circle(c + Vector2(0, 5), r, Color(0.15, 0.08, 0.03, 0.32))
	draw_circle(c, r, base.darkened(0.15))
	draw_circle(c + Vector2(0, -3), r - 5, base)
	draw_arc(c, r, 0, TAU, 40, Color("#3a2414"), 3.5, true)
	UiKit.draw_icon(self, icon, c + Vector2(0, -8 if text != "" else 0), r * 0.42)
	if text != "" and UiKit.head_font:
		var fs := 17
		var w := UiKit.head_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string_outline(UiKit.head_font, c + Vector2(-w / 2, r * 0.62), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color("#3a2414"))
		draw_string(UiKit.head_font, c + Vector2(-w / 2, r * 0.62), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	if badge != "":
		var bc := c + Vector2(r * 0.72, -r * 0.72)
		draw_circle(bc, 14, Color("#ffd23f"))
		draw_arc(bc, 14, 0, TAU, 24, Color("#3a2414"), 2.5, true)
		var bw := UiKit.head_font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(UiKit.head_font, bc + Vector2(-bw / 2, 6), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#3a2414"))
