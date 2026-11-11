## Player avatar: Kenney "Animated Characters Survivors" (CC0) humanoid with its
## idle / run clips, plus procedural gestures (pose_overlay.gd) for actions.
## Movement is kinematic over the heightmap with circle collision (no physics engine).
class_name Player
extends Node3D

const HEIGHT := 1.78
const PoseOverlay := preload("res://scripts/pose_overlay.gd")

var world: World
var model: Node3D
var anim: AnimationPlayer
var overlay: Node
var skel: Skeleton3D
var pos := Vector2(3, 4)
var facing := 0.0
var vel := Vector2.ZERO
var moving := false
var running := false
var climbing := false
var action_t := 0.0        # time left in a one-shot action
var action_len := 1.0
var dead := false
var _step_t := 0.0
var _cur := ""
var spear: Node3D
var _hand: BoneAttachment3D

func setup(w: World) -> void:
	world = w
	model = load("res://assets/models/survivor/characterMedium.fbx").instantiate()
	add_child(model)
	skel = model.find_children("*", "Skeleton3D", true, false)[0]
	# skin
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/models/survivor/survivorMaleB.png")
	mat.roughness = 0.85
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = mat
	# scale to a realistic height
	var head := skel.find_bone("Head_end")
	var toe := skel.find_bone("LeftToes")
	var hy := (skel.global_transform * skel.get_bone_global_rest(head).origin).y
	var ty := (skel.global_transform * skel.get_bone_global_rest(toe).origin).y
	var s := HEIGHT / maxf(hy - minf(ty, 0.0), 0.001)
	model.scale = Vector3.ONE * s
	# animations from the separate clip files
	anim = AnimationPlayer.new()
	model.add_child(anim)
	var lib := AnimationLibrary.new()
	for pair in [["idle", "Root|Idle"], ["sprint", "Root|Run"], ["walk", "Root|Run"], ["jump", "Root|Jump"]]:
		var file: String = {"sprint": "run", "walk": "run"}.get(pair[0], pair[0])
		var src: Node = load("res://assets/models/survivor/%s.fbx" % file).instantiate()
		var ap: AnimationPlayer = src.find_child("AnimationPlayer", true, false)
		var a: Animation = ap.get_animation(pair[1]).duplicate()
		a.loop_mode = Animation.LOOP_LINEAR if pair[0] != "jump" else Animation.LOOP_NONE
		lib.add_animation(pair[0], a)
		src.free()
	anim.add_animation_library("", lib)
	anim.root_node = NodePath("..")
	overlay = PoseOverlay.new()
	skel.add_child(overlay)
	_hand = BoneAttachment3D.new()
	_hand.bone_name = "RightHand"
	skel.add_child(_hand)
	# shadow blob (cheap contact shadow, helps on low quality without real shadows)
	var blob := MeshInstance3D.new()
	var q := QuadMesh.new(); q.size = Vector2(1.1, 1.1); q.orientation = PlaneMesh.FACE_Y
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
	anim.play(n, 0.2)
	anim.speed_scale = speed

## One-shot gesture. Names kept from the old Kenney clips.
func act(n: String, dur := 0.6) -> void:
	action_t = dur
	action_len = dur
	overlay.kind = {"attack-melee-right": "attack", "pick-up": "pick"}.get(n, "interact")
	overlay.t = 0.0
	_cur = n
	_play("idle")
	_cur = n

func die() -> void:
	dead = true
	overlay.kind = ""
	_cur = "die"
	anim.pause()
	var tw := create_tween().set_parallel()
	tw.tween_property(model, "rotation:x", -PI / 2, 0.9).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(model, "position:y", 0.15, 0.9)

func revive() -> void:
	dead = false
	model.rotation = Vector3.ZERO
	model.position = Vector3.ZERO
	_cur = ""
	_play("idle")

func set_spear(on: bool) -> void:
	if on and spear == null:
		spear = Models.instance("chars/weapon-spear")
		# BoneAttachment inherits the skeleton scale; undo it
		spear.scale = Vector3.ONE * (2.2 / model.scale.x)
		spear.rotation = Vector3(PI / 2, 0, 0)
		_hand.add_child(spear)
	elif not on and spear:
		spear.queue_free(); spear = null

## dir: desired movement (x, z) with length 0..1
func move(dir: Vector2, want_run: bool, speed_mul: float, dt: float, can_run: bool) -> void:
	if dead:
		return
	if action_t > 0.0:
		action_t -= dt
		overlay.t = 1.0 - action_t / action_len
		if action_t <= 0.0:
			overlay.kind = ""
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
			_play("sprint", 1.05)
		else:
			# the run clip slowed down reads as a brisk walk
			_play("walk", 0.62 * spd / GameData.WALK_SPEED + 0.05)

func forward() -> Vector2:
	return Vector2(sin(facing), cos(facing))
