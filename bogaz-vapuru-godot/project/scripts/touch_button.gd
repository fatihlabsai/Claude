## Round "Simit At" touch button.
extends Control

signal pressed_btn
var down := false
var count := 5
var font: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(124, 124)
	size = custom_minimum_size

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed:
			_press()
		else:
			down = false
			queue_redraw()
		accept_event()
	elif ev is InputEventMouseButton and ev.device != InputEvent.DEVICE_ID_EMULATION and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_press()
		else:
			down = false
			queue_redraw()
		accept_event()

func _press() -> void:
	down = true
	pressed_btn.emit()
	queue_redraw()

func _draw() -> void:
	var c := size / 2
	var r := 52.0 * (0.94 if down else 1.0)
	draw_circle(c + Vector2(0, 5), r, Color(0.04, 0.1, 0.2, 0.3))
	draw_circle(c, r, Color("#e8434b") if count > 0 else Color("#9aa3ad"))
	draw_circle(c + Vector2(0, -3), r - 6, Color("#ff6b6b") if count > 0 else Color("#b5bcc4"))
	draw_arc(c, r, 0, TAU, 40, Color("#1d3557"), 3.5, true)
	Art.draw_simit(self, c + Vector2(0, -12), 17, 0.4)
	if font:
		var s := "Simit At"
		var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_string_outline(font, c + Vector2(-w / 2, 22), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 4, Color("#1d3557"))
		draw_string(font, c + Vector2(-w / 2, 22), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
		var cs := str(count)
		draw_circle(c + Vector2(r * 0.72, -r * 0.72), 14, Color("#ffcf33"))
		draw_arc(c + Vector2(r * 0.72, -r * 0.72), 14, 0, TAU, 24, Color("#1d3557"), 2.5, true)
		var cw := font.get_string_size(cs, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_string(font, c + Vector2(r * 0.72 - cw / 2, -r * 0.72 + 6), cs, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#1d3557"))
