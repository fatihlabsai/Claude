## Procedural one-shot gestures (attack swing, pick up, interact) layered on top of
## the Kenney animation clips, which only ship idle / run / jump.
extends SkeletonModifier3D

var kind := ""      # "attack" | "pick" | "interact"
var t := 0.0        # 0..1 progress of the gesture
var _b := {}

func _bone(n: String) -> int:
	if not _b.has(n):
		_b[n] = get_skeleton().find_bone(n)
	return _b[n]

func _rot(n: String, axis: Vector3, ang: float) -> void:
	var sk := get_skeleton()
	var i := _bone(n)
	if i < 0 or absf(ang) < 0.0001:
		return
	var q := sk.get_bone_pose_rotation(i)
	sk.set_bone_pose_rotation(i, q * Quaternion(axis.normalized(), ang))

func _process_modification() -> void:
	if kind == "":
		return
	var k := sin(clampf(t, 0.0, 1.0) * PI)       # 0 -> 1 -> 0
	match kind:
		"attack":
			# wind up then a fast overhead-forward swing with the right arm
			var sw := sin(clampf(t, 0.0, 1.0) * PI * 1.0)
			var phase := -1.0 if t < 0.35 else 1.0
			_rot("Spine", Vector3(0, 1, 0), 0.35 * phase * sw)
			_rot("RightArm", Vector3(1, 0, 0), -1.6 * k)
			_rot("RightArm", Vector3(0, 0, 1), 0.5 * phase * k)
			_rot("RightForeArm", Vector3(1, 0, 0), -0.6 * k)
		"pick":
			_rot("Spine", Vector3(1, 0, 0), 0.55 * k)
			_rot("Chest", Vector3(1, 0, 0), 0.35 * k)
			_rot("RightArm", Vector3(1, 0, 0), -0.9 * k)
			_rot("LeftArm", Vector3(1, 0, 0), -0.7 * k)
			_rot("LeftUpLeg", Vector3(1, 0, 0), -0.5 * k)
			_rot("RightUpLeg", Vector3(1, 0, 0), -0.5 * k)
			_rot("LeftLeg", Vector3(1, 0, 0), 0.8 * k)
			_rot("RightLeg", Vector3(1, 0, 0), 0.8 * k)
		"interact":
			_rot("Spine", Vector3(1, 0, 0), 0.2 * k)
			_rot("RightArm", Vector3(1, 0, 0), -1.1 * k)
			_rot("RightForeArm", Vector3(1, 0, 0), -0.7 * k * (0.8 + 0.2 * sin(t * 30.0)))
