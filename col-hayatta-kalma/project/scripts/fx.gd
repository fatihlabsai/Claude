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

static var _flame_shader: Shader

static func flame_mat(particle: bool, inten: float, sd := 0.0) -> ShaderMaterial:
	if _flame_shader == null:
		_flame_shader = load("res://shaders/flame.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _flame_shader
	m.set_shader_parameter("particle", particle)
	m.set_shader_parameter("intensity", inten)
	m.set_shader_parameter("seed", sd)
	return m

## Realistic campfire: shader flame body + flame licks + embers + smoke + flickering light.
## Returns the root node.
static func fire(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Fire"
	parent.add_child(root)
	# two overlapping flame bodies with different phase -> never looks like a static sprite
	for k in 2:
		var body := MeshInstance3D.new()
		body.name = "Body%d" % k
		var q := QuadMesh.new(); q.size = Vector2(1.25, 1.9) * (1.0 - k * 0.3)
		q.material = flame_mat(false, 1.0 if k == 0 else 1.2, k * 0.37)
		body.mesh = q
		body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.position = Vector3(0.05 * k, 0.88 - k * 0.2, 0)
		root.add_child(body)
	var fl := CPUParticles3D.new()
	fl.name = "Flames"
	fl.amount = amount(14); fl.lifetime = 0.9
	var fq := QuadMesh.new(); fq.size = Vector2(0.55, 0.8); fq.material = flame_mat(true, 0.9)
	fl.mesh = fq
	fl.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE; fl.emission_sphere_radius = 0.22
	fl.direction = Vector3.UP; fl.spread = 12.0
	fl.initial_velocity_min = 0.5; fl.initial_velocity_max = 1.1
	fl.gravity = Vector3(0, 0.5, 0)
	fl.scale_amount_min = 0.7; fl.scale_amount_max = 1.2
	var sc := Curve.new(); sc.add_point(Vector2(0, 0.8)); sc.add_point(Vector2(0.4, 1.0)); sc.add_point(Vector2(1, 0.3))
	fl.scale_amount_curve = sc
	fl.position.y = 0.35
	root.add_child(fl)
	var gl := MeshInstance3D.new()
	gl.name = "Glow"
	var gq := QuadMesh.new(); gq.size = Vector2(2.8, 2.8)
	var gm := StandardMaterial3D.new()
	gm.albedo_texture = tex("light_01"); gm.albedo_color = Color(1.0, 0.5, 0.18, 0.4)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	gm.disable_fog = true
	gq.material = gm
	gl.mesh = gq
	gl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gl.position.y = 0.6
	root.add_child(gl)
	var sm := CPUParticles3D.new()
	sm.name = "Smoke"
	sm.amount = amount(14); sm.lifetime = 3.2
	sm.mesh = billboard("smoke_07", Color(0.32, 0.29, 0.27, 0.32), false, 1.0)
	sm.direction = Vector3(0.1, 1, 0); sm.spread = 10.0
	sm.initial_velocity_min = 0.7; sm.initial_velocity_max = 1.1
	sm.gravity = Vector3(0.25, 0.15, 0.05)
	sm.angle_min = 0.0; sm.angle_max = 360.0
	sm.scale_amount_min = 0.7; sm.scale_amount_max = 1.4
	var sc2 := Curve.new(); sc2.add_point(Vector2(0, 0.4)); sc2.add_point(Vector2(1, 2.4))
	sm.scale_amount_curve = sc2
	sm.position.y = 1.4
	root.add_child(sm)
	var em := CPUParticles3D.new()
	em.name = "Embers"
	em.amount = amount(18); em.lifetime = 1.8
	em.mesh = billboard("spark_01", Color(1, 0.55, 0.15), true, 0.09)
	em.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE; em.emission_sphere_radius = 0.25
	em.direction = Vector3.UP; em.spread = 25.0
	em.initial_velocity_min = 1.2; em.initial_velocity_max = 2.8
	em.gravity = Vector3(0.3, -0.25, 0)
	em.damping_min = 0.3; em.damping_max = 0.8
	em.tangential_accel_min = -1.5; em.tangential_accel_max = 1.5
	em.scale_amount_min = 0.5; em.scale_amount_max = 1.3
	em.position.y = 0.45
	root.add_child(em)
	var l := OmniLight3D.new()
	l.set_script(load("res://scripts/fire_flicker.gd"))
	l.name = "Light"
	l.light_color = Color(1.0, 0.58, 0.26)
	l.light_energy = 2.2
	l.omni_range = 11.0
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
