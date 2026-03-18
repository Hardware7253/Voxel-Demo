extends Node3D

# Returns the positions of blocks adjacent to this one
func get_adjacents(block_pos: Vector3) -> Array[Vector3i]:
	var adjacent_dirs = [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	var adjacents: Array[Vector3i]
	for adjacent_dir in adjacent_dirs:
		var adjacent_pos = Vector3i(adjacent_dir * BlockGlobals.BLOCK_SIZE + block_pos)

		if BlockGlobals.blocks_dict.has(adjacent_pos):
			adjacents.append(adjacent_pos)	

	print(adjacents)
	return adjacents 

# Updates the given blocks neighbors
func update_neighbors(block_pos: Vector3, block_grid: Node3D):
	var adjacents = get_adjacents(block_pos)
	for adjacent in adjacents:
		var adjacent_block_inst: Node3D = BlockGlobals.blocks_dict[Vector3i(adjacent)]
		update_block(adjacent_block_inst, block_grid)

# Updates the given block, and the blocks adjacent 
func update_block_and_neighbors(block_pos: Vector3, block_grid: Node3D):
	update_neighbors(block_pos, block_grid)
	update_block(BlockGlobals.blocks_dict[Vector3i(block_pos)], block_grid)

# Update the given block instance
# The block my change based on what's adjacent to itself
func update_block(block: Node3D, block_grid: Node3D):
	if block.has_method("update_from_adjacent"):
		var block_replaced: bool = block.update_from_adjacent(get_adjacents(block.global_position), block_grid)
		if block_replaced:
			block.queue_free()


			
