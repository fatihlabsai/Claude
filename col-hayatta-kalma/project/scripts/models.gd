## Model cache: loads Kenney GLB scenes, bakes them into single meshes for
## MultiMesh use, and instantiates animated models.
class_name Models
extends RefCounted

static var _scenes := {}
static var _meshes := {}

static func scene(path: String) -> PackedScene:
	if not _scenes.has(path):
		_scenes[path] = load("res://assets/models/%s.glb" % path)
	return _scenes[path]

static func instance(path: String) -> Node3D:
	return scene(path).instantiate()

## A single ArrayMesh with every surface of the model baked in (cached).
static func mesh(path: String) -> ArrayMesh:
	if _meshes.has(path):
		return _meshes[path]
	var root := instance(path)
	var out := ArrayMesh.new()
	_bake(root, Transform3D.IDENTITY, out)
	root.free()
	_meshes[path] = out
	return out

static func _bake(n: Node, xf: Transform3D, out: ArrayMesh) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var m: Mesh = (n as MeshInstance3D).mesh
		for s in m.get_surface_count():
			var arr := m.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			for i in v.size():
				v[i] = t * v[i]
			arr[Mesh.ARRAY_VERTEX] = v
			if arr[Mesh.ARRAY_NORMAL] != null:
				var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
				var b := t.basis.inverse().transposed()
				for i in nr.size():
					nr[i] = (b * nr[i]).normalized()
				arr[Mesh.ARRAY_NORMAL] = nr
			arr[Mesh.ARRAY_TANGENT] = null
			# skin data is not needed for static props
			arr[Mesh.ARRAY_BONES] = null
			arr[Mesh.ARRAY_WEIGHTS] = null
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			var mat: Material = (n as MeshInstance3D).get_active_material(s)
			out.surface_set_material(out.get_surface_count() - 1, mat)
	for c in n.get_children():
		_bake(c, t, out)

## Recursively sets a tinted copy of every material (albedo multiplied by col).
static func tint(n: Node, col: Color) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for s in mi.get_surface_override_material_count():
			var m := mi.get_active_material(s)
			if m is StandardMaterial3D:
				var c := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				c.albedo_color = c.albedo_color * col
				mi.set_surface_override_material(s, c)
	for c in n.get_children():
		tint(c, col)

static func find_anim(n: Node) -> AnimationPlayer:
	return n.find_child("AnimationPlayer", true, false) as AnimationPlayer
