## On-screen joystick (multi-touch safe; ignores emulated mouse events). Pushing
## to the rim (>92%) means "run".
extends Control

const R := 78.0
var vec := Vector2.ZERO
var idx := -1
var knob := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(R * 2 + 40, R * 2 + 40)
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
	elif ev is InputEventMouseButton and ev.device != InputEvent.DEVICE_ID_EMULATION and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			idx = 99; _update(ev.position)
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

func running() -> bool:
	return vec.length() > 0.92

func _draw() -> void:
	var c := _center()
	draw_circle(c + Vector2(0, 4), R + 8, Color(0.2, 0.1, 0.03, 0.25))
	draw_circle(c, R + 8, Color(1, 0.95, 0.85, 0.28))
	draw_arc(c, R + 8, 0, TAU, 48, Color(0.23, 0.14, 0.08, 0.75), 3.0, true)
	draw_arc(c, R * 0.92, 0, TAU, 48, Color(1, 0.8, 0.3, 0.35 if not running() else 0.9), 2.0, true)
	var k := c + knob
	draw_circle(k + Vector2(0, 3), 32, Color(0.2, 0.1, 0.03, 0.3))
	draw_circle(k, 32, Color("#f0a04b") if not running() else Color("#e2683c"))
	draw_circle(k, 25, Color("#ffc977"))
	draw_arc(k, 32, 0, TAU, 32, Color("#3a2414"), 3.0, true)
	draw_circle(k + Vector2(-8, -9), 7, Color(1, 1, 1, 0.45))
