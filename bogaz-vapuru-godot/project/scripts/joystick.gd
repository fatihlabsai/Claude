## On-screen joystick for touch screens (multi-touch safe; ignores the
## emulated mouse events Godot generates from touches).
extends Control

const R := 62.0
var vec := Vector2.ZERO
var idx := -1
var knob := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(R * 2 + 24, R * 2 + 24)
	size = custom_minimum_size

func _center() -> Vector2:
	return size / 2

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed and idx == -1:
			idx = ev.index
			_update(ev.position)
		elif not ev.pressed and ev.index == idx:
			_reset()
		accept_event()
	elif ev is InputEventScreenDrag:
		if ev.index == idx:
			_update(ev.position)
		accept_event()
	elif ev is InputEventMouseButton and ev.device != InputEvent.DEVICE_ID_EMULATION:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				idx = 99
				_update(ev.position)
			elif idx == 99:
				_reset()
		accept_event()
	elif ev is InputEventMouseMotion and ev.device != InputEvent.DEVICE_ID_EMULATION and idx == 99:
		_update(ev.position)
		accept_event()

func _update(p: Vector2) -> void:
	var d := p - _center()
	if d.length() > R:
		d = d.normalized() * R
	knob = d
	vec = d / R
	queue_redraw()

func _reset() -> void:
	idx = -1
	knob = Vector2.ZERO
	vec = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	var c := _center()
	draw_circle(c + Vector2(0, 4), R + 6, Color(0.04, 0.1, 0.2, 0.25))
	draw_circle(c, R + 6, Color(1, 1, 1, 0.28))
	draw_arc(c, R + 6, 0, TAU, 48, Color(0.11, 0.21, 0.34, 0.75), 3.0, true)
	draw_circle(c, R * 0.55, Color(1, 1, 1, 0.12))
	for i in 4:
		var a := i * PI / 2
		var p := c + Vector2(cos(a), sin(a)) * (R - 6)
		var tri := PackedVector2Array([p + Vector2(cos(a), sin(a)) * 7, p + Vector2(cos(a + 2.3), sin(a + 2.3)) * 6, p + Vector2(cos(a - 2.3), sin(a - 2.3)) * 6])
		draw_colored_polygon(tri, Color(0.11, 0.21, 0.34, 0.55))
	var k := c + knob
	draw_circle(k + Vector2(0, 3), 27, Color(0.04, 0.1, 0.2, 0.3))
	draw_circle(k, 27, Color("#ffcf33"))
	draw_circle(k, 21, Color("#ffe27a"))
	draw_arc(k, 27, 0, TAU, 32, Color("#1d3557"), 3.0, true)
	draw_circle(k + Vector2(-7, -8), 6, Color(1, 1, 1, 0.45))
