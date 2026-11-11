## Player avatar: Kenney Mini Character with its built-in animations.
## Movement is kinematic over the heightmap with circle collision (no physics engine).
class_name Player
extends Node3D

var world: World
var model: Node3D
var anim: AnimationPlayer
var pos := Vector2(3, 4)
var facing := 0.0
var vel := Vector2.ZERO
var moving := false
var running := false
var climbing := false
var action_t := 0.0        # time left in a one-shot action animation
var dead := false
var _step_t := 0.0
var _cur := ""
var spear: Node3D

func setup(w: World) -> void:
	world = w
	model = Models.instance("chars/character-male-f")
	model.scale = Vector3.ONE * 2.4
	add_child(model)
	anim = Models.find_anim(model)
	# shadow blob (cheap contact shadow, helps on low quality without real shadows)
	var blob := MeshInstance3D.new()
	var q := QuadMesh.new(); q.size = Vector2(1.3, 1.3); q.orientation = PlaneMesh.FACE_Y
	var m := StandardMaterial3D.new()
	m.albedo_texture = Fx.tex("circle_05"); m.albedo_color = Color(0, 0, 0, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q.material = m
	blob.mesh = q; blob.position.y = 0.06
	add_child(blob)
	_play("idle")

func _play(n: String, speed := 1.0) -> void:
	if anim == null or not anim.has_animation(n):
		return
	if _cur == n and anim.is_playing():
		anim.speed_scale = speed
		return
	_cur = n
	anim.play(n, 0.15)
	anim.speed_scale = speed

func act(n: String, dur := 0.6) -> void:
	action_t = dur
	_cur = ""
	_play(n, 1.3)

func die() -> void:
	dead = true
	_cur = ""
	_play("die")

func set_spear(on: bool) -> void:
	if on and spear == null:
		spear = Models.instance("chars/weapon-spear")
		spear.scale = Vector3.ONE * 2.6
		spear.position = Vector3(0.45, 0.35, 0.1)
		spear.rotation = Vector3(0.4, 0, -0.15)
		model.add_child(spear)
		spear.scale = Vector3.ONE * 1.1
	elif not on and spear:
		spear.queue_free(); spear = null

## dir: desired movement (x, z) with length 0..1
func move(dir: Vector2, want_run: bool, speed_mul: float, dt: float, can_run: bool) -> void:
	if dead:
		return
	if action_t > 0.0:
		action_t -= dt
		dir *= 0.25
	moving = dir.length() > 0.12
	running = moving and want_run and can_run
	var spd := (GameData.RUN_SPEED if running else GameData.WALK_SPEED) * minf(dir.length() * 1.15, 1.0) * speed_mul
	var h0 := world.ground(pos)
	if moving:
		var nd := dir.normalized()
		var np := pos + nd * spd * dt
		var h1 := world.ground(np)
		climbing = h1 - h0 > 0.05 * spd * dt * 2.0
		if climbing:
			np = pos + nd * spd * 0.8 * dt
		pos = world.collide(np, 0.4)
		var target := atan2(nd.x, nd.y)
		facing = lerp_angle(facing, target, minf(1.0, dt * 12.0))
		_step_t -= dt * (1.6 if running else 1.0)
		if _step_t <= 0.0:
			_step_t = 0.42
			var rocky := world.g.biome(pos) == WorldGen.B.ROCK
			Sfx.play(("step_stone%d" if rocky else "step_sand%d") % (randi() % 3 + 1), -14.0 if not running else -10.0)
	else:
		climbing = false
	position = Vector3(pos.x, world.ground(pos), pos.y)
	rotation.y = facing
	if action_t <= 0.0:
		if not moving:
			_play("idle")
		elif running:
			_play("sprint", 1.1)
		else:
			_play("walk", spd / GameData.WALK_SPEED * 1.1)

func forward() -> Vector2:
	return Vector2(sin(facing), cos(facing))
