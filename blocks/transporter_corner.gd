extends StaticBody3D

@export var replacement_block: PackedScene

# Updates this block based on what block surrounds it
# If the block is updated this function will spawn the new block and enter it into the blocks_dict
# Returns true if the old block instance should be deleted 
func update_from_adjacent(adjacents: Array[Vector3i], block_grid: Node3D) -> bool:
	if len(adjacents) != 2:
		return false 

	var adjacent_blocks: Array[Node3D]  
	for adjacent_pos in adjacents:
		var block = BlockGlobals.blocks_dict[adjacent_pos]

		var block_name: String = block.get_meta("name")
		if block_name == "transporter_corner" or block_name == "transporter":
			adjacent_blocks.append(block)
		else:
			return false 

	var pos_1 := Vector3i(BlockGlobals.blocks_dict[adjacents[0]].global_position)
	var pos_2 := Vector3i(BlockGlobals.blocks_dict[adjacents[1]].global_position)
	var same_coord := 0

	# If the 2 adjacent blocks are arranged in a line we want to change this block to the replacement block
	for i in range(0, 3):
		if pos_1[i] == pos_2[i]:
			same_coord += 1

	if same_coord == 2:
		var new_block: Node3D = replacement_block.instantiate()
		block_grid.add_child(new_block);
		new_block.global_position = self.global_position
		new_block.basis = self.basis
		BlockGlobals.blocks_dict[Vector3i(self.global_position)] = new_block
		return true 

	return false 
