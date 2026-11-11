## Wildlife: spawns animals around the player by biome/time and runs their simple AI.
class_name Animals
extends Node3D

const KINDS := {
	"rabbit": {"model": "pets/animal-bunny", "scale": 0.28, "hp": 20.0, "walk": 1.4, "flee": 6.4, "tint": Color(1.0, 0.92, 0.8), "name": "Tavşan"},
	"partridge": {"model": "pets/animal-chick", "scale": 0.24, "hp": 10.0, "walk": 1.0, "flee": 4.3, "tint": Color(0.95, 0.8, 0.6), "name": "Keklik"},
	"fennec": {"model": "pets/animal-fox", "scale": 0.3, "hp": 25.0, "walk": 1.6, "flee": 6.0, "tint": Color(1.15, 1.0, 0.75), "name": "Fennek"},
	"jackal": {"model": "pets/animal-fox", "scale": 0.42, "hp": 40.0, "walk": 1.8, "flee": 5.5, "chase": 5.0, "tint": Color(0.72, 0.64, 0.56), "name": "Çakal", "hostile": true},
	"snake": {"model": "", "scale": 1.0, "hp": 15.0, "walk": 0.6, "flee": 1.6, "name": "Yılan", "hostile": true},
	"scorpion": {"model": "", "scale": 1.0, "hp": 8.0, "walk": 0.8, "flee": 2.2, "name": "Akrep", "hostile": true},
}
const MAX := 14

var world: World
var list: Array = []
var _spawn_t := 0.0
signal bite(dmg: float, poison: float, who: String)

class Animal:
	var kind := ""
	var node: Node3D
	var anim: AnimationPlayer
	var pos := Vector2.ZERO
	var dir := Vector2.ZERO
	var hp := 10.0
	var state := "wander"
	var t := 0.0
	var cd := 0.0
	var facing := 0.0
	var parts: Array = []
	var cur := ""

func spawn_tick(dt: float, ppos: Vector2, night: bool, storm: bool) -> void:
	_spawn_t -= dt
	# despawn far animals
	for a in list.duplicate():
		if a.pos.distance_to(ppos) > 95.0:
			_remove(a)
	if _spawn_t > 0.0 or list.size() >= MAX or storm:
		return
	_spawn_t = 1.5
	var ang := randf() * TAU
	var p := ppos + Vector2(cos(ang), sin(ang)) * randf_range(32.0, 60.0)
	if absf(p.x) > WorldGen.HALF - 8 or absf(p.y) > WorldGen.HALF - 8:
		return
	var b := world.g.biome(p)
	var table := []
	match b:
		WorldGen.B.DUNE: table = [["rabbit", 0.25], ["fennec", 0.25], ["jackal", 0.35 if night else 0.0], ["scorpion", 0.5 if night else 0.1]]
		WorldGen.B.SCRUB: table = [["rabbit", 0.5], ["partridge", 0.5], ["jackal", 0.4 if night else 0.05], ["snake", 0.1]]
		WorldGen.B.ROCK: table = [["snake", 0.45], ["rabbit", 0.25], ["scorpion", 0.35]]
		WorldGen.B.OASIS: table = [["partridge", 0.5], ["jackal", 0.7 if night else 0.15], ["snake", 0.3]]
		WorldGen.B.SALT: table = [["scorpion", 0.15]]
	var tot := 0.0
	for e in table: tot += e[1]
	if tot <= 0.0:
		return
	var r := randf() * maxf(tot, 1.0)
	var acc := 0.0
	for e in table:
		acc += e[1]
		if r < acc:
			spawn(e[0], p)
			return

func spawn(kind: String, p: Vector2) -> Animal:
	var k: Dictionary = KINDS[kind]
	var a := Animal.new()
	a.kind = kind; a.pos = p; a.hp = k.hp
	a.facing = randf() * TAU
	if k.model != "":
		a.node = Models.instance(k.model)
		a.node.scale = Vector3.ONE * k.scale
		if k.has("tint"):
			Models.tint(a.node, k.tint)
		a.anim = Models.find_anim(a.node)
	elif kind == "snake":
		a.node = _make_snake(a)
	else:
		a.node = _make_scorpion(a)
	add_child(a.node)
	list.append(a)
	_place(a)
	return a

func _sphere(r: float, col: Color, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new(); s.radius = r; s.height = r * 2; s.radial_segments = 8; s.rings = 4
	var m := StandardMaterial3D.new(); m.albedo_color = col; m.roughness = 0.6
	s.material = m
	mi.mesh = s
	parent.add_child(mi)
	return mi

func _make_snake(a: Animal) -> Node3D:
	var root := Node3D.new()
	for i in 9:
		var col := Color("#8c7a3c") if i % 2 == 0 else Color("#5f4f25")
		var seg := _sphere(0.11 - i * 0.006, col, root)
		seg.scale = Vector3(1, 0.7, 1.2)
		a.parts.append(seg)
	var head := a.parts[0] as MeshInstance3D
	head.scale = Vector3(1.3, 0.8, 1.5)
	for s in [-1, 1]:
		var eye := _sphere(0.025, Color.BLACK, head)
		eye.position = Vector3(0.06 * s, 0.05, 0.07)
	return root

func _make_scorpion(a: Animal) -> Node3D:
	var root := Node3D.new()
	var col := Color("#3b2a1f")
	var body := _sphere(0.16, col, root); body.scale = Vector3(1, 0.5, 1.4); body.position.y = 0.1
	for i in 4:
		var t := _sphere(0.07, col, root)
		t.position = Vector3(0, 0.12 + i * 0.09, -0.2 - i * 0.05 + (i * i) * 0.03)
		a.parts.append(t)
	var sting := _sphere(0.05, Color("#c23b22"), root)
	sting.position = Vector3(0, 0.5, -0.12)
	a.parts.append(sting)
	for s in [-1, 1]:
		var claw := _sphere(0.07, col, root); claw.scale = Vector3(0.8, 0.5, 1.4)
		claw.position = Vector3(0.14 * s, 0.08, 0.3)
		for l in 3:
			var leg := _sphere(0.03, col, root); leg.scale = Vector3(4.0, 0.6, 0.6)
			leg.position = Vector3(0.18 * s, 0.05, 0.1 - l * 0.1)
	return root

func _remove(a: Animal) -> void:
	list.erase(a)
	if is_instance_valid(a.node):
		a.node.queue_free()

func _place(a: Animal) -> void:
	a.node.position = Vector3(a.pos.x, world.ground(a.pos), a.pos.y)
	a.node.rotation.y = a.facing

func _anim(a: Animal, n: String, spd := 1.0) -> void:
	if a.anim == null or a.cur == n or not a.anim.has_animation(n):
		return
	a.cur = n
	a.anim.play(n, 0.2)
	a.anim.speed_scale = spd

func update(dt: float, ppos: Vector2, night: bool, fires: Array) -> void:
	for a in list.duplicate():
		var k: Dictionary = KINDS[a.kind]
		a.t -= dt
		a.cd -= dt
		var to_p: Vector2 = ppos - a.pos
		var dist := to_p.length()
		var near_fire := false
		for f in fires:
			if a.pos.distance_to(f.p) < 8.0:
				near_fire = true
		var spd := 0.0
		match a.state:
			"wander":
				if a.t <= 0.0:
					a.t = randf_range(1.5, 4.0)
					a.dir = Vector2.from_angle(randf() * TAU) if randf() < 0.65 else Vector2.ZERO
				spd = k.walk
				if k.get("hostile", false):
					var aggro := 9.0 if a.kind == "jackal" else 2.0
					if a.kind == "jackal" and not night:
						aggro = 4.0
					if dist < aggro and not near_fire:
						a.state = "chase"
				elif dist < (7.0 if a.kind != "partridge" else 5.0):
					a.state = "flee"; a.t = 4.0
			"flee":
				a.dir = -to_p.normalized()
				spd = k.flee
				if a.t <= 0.0 and dist > 14.0:
					a.state = "wander"
			"chase":
				a.dir = to_p.normalized()
				spd = k.get("chase", k.walk)
				if near_fire or a.hp < k.hp * 0.35:
					a.state = "flee"; a.t = 6.0
				elif dist > 22.0:
					a.state = "wander"
				var reach := 1.3 if a.kind == "jackal" else 1.1
				if dist < reach:
					spd = 0.0
					if a.cd <= 0.0:
						match a.kind:
							"jackal": a.cd = 1.3; bite.emit(8.0, 0.0, "çakal")
							"snake": a.cd = 3.0; bite.emit(15.0, 10.0, "yılan zehri")
							"scorpion": a.cd = 2.5; bite.emit(8.0, 5.0, "akrep zehri")
						_anim(a, "gesture-negative", 1.5)
						if a.kind == "snake":
							a.state = "wander"; a.t = 2.5; a.dir = -to_p.normalized()
		if a.dir.length() > 0.01 and spd > 0.0:
			var np: Vector2 = a.pos + a.dir * spd * dt
			np = world.collide(np, 0.25)
			a.pos = np
			a.facing = lerp_angle(a.facing, atan2(a.dir.x, a.dir.y), minf(1.0, dt * 8.0))
			_anim(a, "run" if spd > 2.5 else "walk", 1.0 + spd * 0.15)
		else:
			_anim(a, "idle")
		_place(a)
		if a.parts.size() > 0:
			_wiggle(a, spd)

func _wiggle(a: Animal, spd: float) -> void:
	var tt := Time.get_ticks_msec() / 1000.0
	if a.kind == "snake":
		for i in a.parts.size():
			var seg: Node3D = a.parts[i]
			seg.position = Vector3(sin(tt * (3.0 + spd * 4.0) - i * 0.9) * 0.1 * (0.4 + i * 0.12), 0.07, -i * 0.13)
	else:
		for i in a.parts.size():
			a.parts[i].position.y += sin(tt * 4.0 + i) * 0.001

## Player attack: returns the animal hit (or null).
func hit(from: Vector2, fwd: Vector2, reach: float, dmg: float) -> Animal:
	var best: Animal = null
	var bd := reach
	for a in list:
		var d: Vector2 = a.pos - from
		var l := d.length()
		if l < bd and (l < 0.8 or d.normalized().dot(fwd) > 0.35):
			bd = l; best = a
	if best:
		best.hp -= dmg
		Fx.puff(self, best.node.position + Vector3(0, 0.4, 0), "dirt_02", Color(0.85, 0.6, 0.4, 0.9), 8, 2.0, 0.4)
		if best.hp > 0.0:
			best.state = "flee" if not KINDS[best.kind].get("hostile", false) or best.hp < KINDS[best.kind].hp * 0.35 else "chase"
			best.t = 5.0
	return best

func kill(a: Animal) -> void:
	_remove(a)

func clear() -> void:
	for a in list.duplicate():
		_remove(a)
