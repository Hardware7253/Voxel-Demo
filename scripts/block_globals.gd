extends Node

const BLOCK_SIZE: float = 8

# The length of the raycast will be block_highlight_len * block_size
const BLOCK_HIGHLIGHT_LEN: int = 50 

# Key should be a Vector3i for the block positioin
var blocks_dict := {}
