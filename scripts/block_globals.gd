extends Node

const BLOCK_SIZE: int = 8

# The length of the raycast will be block_highlight_len * block_size
const BLOCK_HIGHLIGHT_LEN: int = 50 

# Key should be a Vector3i for the block positioin
var blocks_dict := {}

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
