## Renders item icons from the Kenney 3D models once at startup (SubViewport).
class_name Icons
extends Node

static var tex := {}
signal done

func build(parent: Node) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(96, 96)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	parent.add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.position = Vector3(0, 1.2, 2.0)
	cam.look_at_from_position(Vector3(1.4, 1.6, 2.0), Vector3.ZERO)
	vp.add_child(cam)
	var l := DirectionalLight3D.new()
	l.rotation = Vector3(-0.9, 0.6, 0)
	l.light_energy = 1.3
	vp.add_child(l)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.82, 0.8)
	e.ambient_light_energy = 0.9
	env.environment = e
	vp.add_child(env)
	for id in GameData.ITEMS:
		var it: Dictionary = GameData.ITEMS[id]
		if it.get("icon", "") == "":
			continue
		var holder := Node3D.new()
		vp.add_child(holder)
		var m := Models.instance(it.icon)
		holder.add_child(m)
		if it.tint != Color(1, 1, 1):
			Models.tint(m, it.tint)
		var aabb := _aabb(m)
		var sz := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
		m.position = -aabb.get_center()
		cam.size = sz * 1.35
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		tex[id] = ImageTexture.create_from_image(img)
		holder.queue_free()
	vp.queue_free()
	done.emit()

func _aabb(n: Node, xf := Transform3D.IDENTITY) -> AABB:
	var acc := AABB()
	var first := true
	var stack := [[n, xf * (n as Node3D).transform]]
	while not stack.is_empty():
		var e: Array = stack.pop_back()
		var node: Node = e[0]
		var t: Transform3D = e[1]
		if node is MeshInstance3D and node.mesh:
			var b: AABB = t * node.mesh.get_aabb()
			acc = b if first else acc.merge(b)
			first = false
		for c in node.get_children():
			if c is Node3D:
				stack.append([c, t * c.transform])
	return acc
