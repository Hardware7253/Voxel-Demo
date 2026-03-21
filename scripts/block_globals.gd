extends Node

const BLOCK_SIZE: int = 8

# The length of the raycast will be block_highlight_len * block_size
const BLOCK_HIGHLIGHT_LEN: int = 50 

# Key should be a Vector3i for the block positioin
var blocks_dict := {}

# Defines the min and max x, y, and z coordinates for block placements
# The vector 2 is ordered min, max
var placement_limits: Array[Vector2]

# Converts a blocks global position to a blocks_dict key
func to_grid(pos: Vector3) -> Vector3i:
	return Vector3i(pos.round())

# Returns the blocks mesh, will return null if it doesn't exist
func get_mesh(block_instance: Node3D) -> MeshInstance3D:
	for child in block_instance.get_children():
		if child is MeshInstance3D:
			return child
	return null

# Converts any vector3 to the nearest block integer position
func to_nearest_block_pos(pos: Vector3) -> Vector3i:
	return Vector3i((pos / BLOCK_SIZE).round() * BLOCK_SIZE)

# Reset placement limits
func reset_limits():
	var min_max := Vector2(99999999, -99999999)
	BlockGlobals.placement_limits = [min_max, min_max, min_max]

func update_limits(pos: Vector3):
	for i in range(3):
		if pos[i] < placement_limits[i][0]:
			placement_limits[i][0] = pos[i]
		if pos[i] > placement_limits[i][1]:
			placement_limits[i][1] = pos[i]

# Returns true if the block position is within the placement limits
func is_in_limits(pos: Vector3) -> bool:
	for i in range(3):
		var axis_limits := placement_limits[i]
		var compare_val := pos[i]

		if (compare_val < axis_limits[0] or compare_val > axis_limits[1]):
			return false

	return true 

# Returns the center position calculated from the placement limits
func get_limit_center() -> Vector3:
	var center := Vector3.ZERO
	for i in range(3):
		center[i] = (placement_limits[i][0] + placement_limits[i][1]) / 2
	return center
