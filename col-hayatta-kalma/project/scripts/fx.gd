## Small helpers for particle effects (Kenney Particle Pack textures, CC0).
class_name Fx
extends RefCounted

static var _tex := {}

static func tex(n: String) -> Texture2D:
	if not _tex.has(n):
		_tex[n] = load("res://assets/particles/%s.png" % n)
	return _tex[n]

static func billboard(n: String, col: Color, additive := false, size := 1.0) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2.ONE * size
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex(n)
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	# colour lives in the material: per-particle vertex colours are unreliable on some WebGL drivers
	m.vertex_color_use_as_albedo = false
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.no_depth_test = false
	q.material = m
	return q

static func amount(base: int) -> int:
	return maxi(2, int(base * Settings.q().particles))

## Flames + smoke + embers + warm light. Returns the root node.
static func fire(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Fire"
	parent.add_child(root)
	var fl := CPUParticles3D.new()
	fl.name = "Flames"
	fl.amount = amount(30); fl.lifetime = 0.75
	fl.mesh = billboard("flame_02", Color(1.0, 0.42, 0.08, 0.85), false, 1.3)
	fl.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE; fl.emission_sphere_radius = 0.25
	fl.direction = Vector3.UP; fl.spread = 10.0
	fl.initial_velocity_min = 0.8; fl.initial_velocity_max = 1.6
	fl.gravity = Vector3(0, 0.6, 0)
	fl.scale_amount_min = 0.7; fl.scale_amount_max = 1.3
	var sc := Curve.new(); sc.add_point(Vector2(0, 1.0)); sc.add_point(Vector2(1, 0.15))
	fl.scale_amount_curve = sc
	fl.position.y = 0.25
	root.add_child(fl)
	var core: CPUParticles3D = fl.duplicate()
	core.name = "Core"
	core.amount = amount(16); core.lifetime = 0.5
	core.mesh = billboard("flame_02", Color(1.0, 0.72, 0.22, 0.95), false, 0.8)
	core.scale_amount_curve = sc
	core.position.y = 0.3
	root.add_child(core)
	var gl := MeshInstance3D.new()
	gl.name = "Glow"
	var gq := QuadMesh.new(); gq.size = Vector2(2.6, 2.6)
	var gm := StandardMaterial3D.new()
	gm.albedo_texture = tex("light_01"); gm.albedo_color = Color(1.0, 0.6, 0.25, 0.55)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	gq.material = gm
	gl.mesh = gq
	gl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gl.position.y = 0.6
	root.add_child(gl)
	var sm := CPUParticles3D.new()
	sm.name = "Smoke"
	sm.amount = amount(12); sm.lifetime = 2.6
	sm.mesh = billboard("smoke_07", Color(0.6, 0.56, 0.52, 0.3), false, 1.2)
	sm.direction = Vector3.UP; sm.spread = 12.0
	sm.initial_velocity_min = 0.8; sm.initial_velocity_max = 1.3
	sm.scale_amount_min = 0.8; sm.scale_amount_max = 1.6
	var sc2 := Curve.new(); sc2.add_point(Vector2(0, 0.5)); sc2.add_point(Vector2(1, 2.0))
	sm.scale_amount_curve = sc2
	sm.position.y = 1.0
	root.add_child(sm)
	var em := CPUParticles3D.new()
	em.name = "Embers"
	em.amount = amount(10); em.lifetime = 1.6
	em.mesh = billboard("spark_01", Color(1, 0.7, 0.3), true, 0.12)
	em.direction = Vector3.UP; em.spread = 30.0
	em.initial_velocity_min = 1.0; em.initial_velocity_max = 2.4
	em.gravity = Vector3(0, -0.4, 0)
	em.position.y = 0.4
	root.add_child(em)
	var l := OmniLight3D.new()
	l.name = "Light"
	l.light_color = Color(1.0, 0.62, 0.3)
	l.light_energy = 2.2
	l.omni_range = 9.0
	l.omni_attenuation = 1.2
	l.position.y = 1.0
	root.add_child(l)
	return root

## One-shot puff (dust, hit, sparkle).
static func puff(parent: Node3D, pos: Vector3, n: String, col: Color, count := 8, spd := 2.0, size := 0.5) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true; p.explosiveness = 0.95
	p.amount = amount(count); p.lifetime = 0.7
	p.mesh = billboard(n, col, false, size)
	p.direction = Vector3.UP; p.spread = 70.0
	p.initial_velocity_min = spd * 0.5; p.initial_velocity_max = spd
	p.gravity = Vector3(0, -3.0, 0)
	p.position = pos
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
