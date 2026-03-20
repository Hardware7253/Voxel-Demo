extends Node3D

@export var grid_size := Vector3i(8, 10, 6)
@export var grid_plane: PackedScene

@export var line_thickness := 0.1

const PLANE_MESH_NAME := "MeshInstance3D"
const PLANE_COLLISION_SHAPE_NAME := "CollisionShape3D"

# Scales the plane mesh and collider
# The container scale remains the same
func scale_plane(container: Node3D, size: Vector2):
	var mesh: MeshInstance3D = container.get_node(PLANE_MESH_NAME)
	var collision_shape: CollisionShape3D = container.get_node(PLANE_COLLISION_SHAPE_NAME)

	var new_scale = Vector3(size.x, 1, size.y)
	mesh.scale = new_scale
	collision_shape.scale = new_scale

func set_plane_shader_params(container: Node3D, shader_grid_size: Vector2i):
	var mesh: MeshInstance3D = container.get_node(PLANE_MESH_NAME)
	var material := mesh.get_active_material(0) as ShaderMaterial
	material = material.duplicate()
	mesh.material_override = material
	material.set_shader_parameter("grid_size", Vector2(shader_grid_size))
	material.set_shader_parameter("line_color", Color.RED)
	material.set_shader_parameter("line_thickness", Vector2(line_thickness, line_thickness) / Vector2(shader_grid_size))

# Spawn each face of the grid box
func _ready() -> void:

	var plane_dirs = [Vector3i.UP, Vector3i.DOWN, Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]

	var plane_size_map = {
		Vector3i.UP: Vector2(grid_size.x, grid_size.z),
		Vector3i.DOWN: Vector2(grid_size.x, grid_size.z),
		Vector3i.LEFT: Vector2(grid_size.y, grid_size.z),
		Vector3i.RIGHT: Vector2(grid_size.y, grid_size.z),
		Vector3i.FORWARD: Vector2(grid_size.x, grid_size.y),
		Vector3i.BACK: Vector2(grid_size.x, grid_size.y),
	}

	var plane_rotation_map = {
		Vector3i.UP: Vector3(0, 0, 180),
		Vector3i.DOWN: Vector3(0, 0, 0),
		Vector3i.LEFT: Vector3(0, 0, -90),
		Vector3i.RIGHT: Vector3(0, 0, 90),
		Vector3i.FORWARD: Vector3(90, 0, 0),
		Vector3i.BACK: Vector3(-90, 0, 0),
	}


	var half_size = Vector3(grid_size) / 2.0
	var plane_offset_map = {
		Vector3i.UP: Vector3(0, half_size.y, 0),
		Vector3i.DOWN: Vector3(0, -half_size.y, 0),

		Vector3i.LEFT: Vector3(-half_size.x, 0, 0),
		Vector3i.RIGHT: Vector3(half_size.x, 0, 0),

		Vector3i.FORWARD: Vector3(0, 0, -half_size.z),
		Vector3i.BACK: Vector3(0, 0, half_size.z),
	}

	for plane_dir in plane_dirs:
		var plane: Node3D = grid_plane.instantiate()
		self.add_child(plane)

		var plane_grid_size: Vector2 = plane_size_map[plane_dir]
		scale_plane(plane, plane_grid_size * BlockGlobals.BLOCK_SIZE)
		plane.position = plane_offset_map[plane_dir] * BlockGlobals.BLOCK_SIZE 
		plane.rotation_degrees = plane_rotation_map[plane_dir]
		set_plane_shader_params(plane, plane_grid_size)


	# Align grid to block placement grid
	self.position += Vector3.ONE * BlockGlobals.BLOCK_SIZE / 2