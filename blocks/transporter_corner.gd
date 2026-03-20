extends StaticBody3D

# Updates this block based on what block surrounds it
# If the block is updated this function will spawn the new block and enter it into the blocks_dict
# Returns true if the old block instance should be deleted 
func update_from_adjacent(adjacents: Array[Vector3i], block_grid: Node3D) -> bool:
	var adjacent_blocks: Array[Node3D] = []
	for adjacent_pos in adjacents:
		var block = BlockGlobals.blocks_dict[adjacent_pos]

		var block_name: String = block.get_meta("block_name")
		if block_name == "transporter_corner" or block_name == "transporter":
			adjacent_blocks.append(block)

	if len(adjacent_blocks) != 2:
		return false 

	var pos_1 := BlockGlobals.to_grid(adjacent_blocks[0].global_position)
	var pos_2 := BlockGlobals.to_grid(adjacent_blocks[1].global_position)

	var own_pos: Vector3i = BlockGlobals.to_grid(self.global_position)
	var dir1 = pos_1 - own_pos
	var dir2 = pos_2 - own_pos

	if dir1 == -dir2:
		var new_block: Node3D = load("res://blocks/transporter.tscn").instantiate()
		block_grid.add_child(new_block);
		new_block.global_position = self.global_position
		new_block.basis = self.basis
		BlockGlobals.blocks_dict[BlockGlobals.to_grid(self.global_position)] = new_block

		# Align the block to the placement normal
		var block_align_dir: Vector3 = new_block.get_meta("align_direction")
		if block_align_dir != null:
			MathGlobals.rotate_to_match_dir(new_block, block_align_dir, Vector3(dir1).normalized())


		return true 

	return false 
