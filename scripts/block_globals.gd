extends Node

const BLOCK_SIZE: int = 8

# The length of the raycast will be block_highlight_len * block_size
const BLOCK_HIGHLIGHT_LEN: int = 50 

# Key should be a Vector3i for the block positioin
var blocks_dict := {}

# Converts a global position to a blocks_dict key
func to_grid(pos: Vector3) -> Vector3i:
	return Vector3i(round(pos.x), round(pos.y), round(pos.z))
