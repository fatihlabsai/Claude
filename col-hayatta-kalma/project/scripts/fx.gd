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
	m.vertex_color_use_as_albedo = true
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
	fl.mesh = billboard("flame_02", Color(1, 1, 1), false, 1.35)
	fl.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE; fl.emission_sphere_radius = 0.25
	fl.direction = Vector3.UP; fl.spread = 10.0
	fl.initial_velocity_min = 0.8; fl.initial_velocity_max = 1.6
	fl.gravity = Vector3(0, 0.6, 0)
	fl.scale_amount_min = 0.7; fl.scale_amount_max = 1.3
	var sc := Curve.new(); sc.add_point(Vector2(0, 1.0)); sc.add_point(Vector2(1, 0.15))
	fl.scale_amount_curve = sc
	var gr := Gradient.new()
	gr.set_color(0, Color(1.0, 0.95, 0.6, 1)); gr.add_point(0.35, Color(1.0, 0.6, 0.15, 0.95)); gr.set_color(2, Color(0.85, 0.2, 0.05, 0))
	fl.color_ramp = gr
	fl.position.y = 0.25
	root.add_child(fl)
	var gl := CPUParticles3D.new()
	gl.name = "Glow"
	gl.amount = 3; gl.lifetime = 0.6
	gl.mesh = billboard("light_01", Color(1.0, 0.65, 0.3, 0.5), true, 2.6)
	gl.gravity = Vector3.ZERO; gl.initial_velocity_min = 0.0; gl.initial_velocity_max = 0.0
	gl.position.y = 0.5
	root.add_child(gl)
	var sm := CPUParticles3D.new()
	sm.name = "Smoke"
	sm.amount = amount(12); sm.lifetime = 2.6
	sm.mesh = billboard("smoke_07", Color(1, 1, 1), false, 1.2)
	sm.direction = Vector3.UP; sm.spread = 12.0
	sm.initial_velocity_min = 0.8; sm.initial_velocity_max = 1.3
	sm.scale_amount_min = 0.8; sm.scale_amount_max = 1.6
	var sc2 := Curve.new(); sc2.add_point(Vector2(0, 0.5)); sc2.add_point(Vector2(1, 2.0))
	sm.scale_amount_curve = sc2
	var gr2 := Gradient.new()
	gr2.set_color(0, Color(0.6, 0.56, 0.52, 0.35)); gr2.set_color(1, Color(0.62, 0.6, 0.58, 0))
	sm.color_ramp = gr2
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
	p.mesh = billboard(n, Color(1, 1, 1), false, size)
	p.direction = Vector3.UP; p.spread = 70.0
	p.initial_velocity_min = spd * 0.5; p.initial_velocity_max = spd
	p.gravity = Vector3(0, -3.0, 0)
	var gr := Gradient.new(); gr.set_color(0, col); gr.set_color(1, Color(col.r, col.g, col.b, 0))
	p.color_ramp = gr
	p.position = pos
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
