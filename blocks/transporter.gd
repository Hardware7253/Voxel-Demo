extends StaticBody3D

# Updates this block based on what block surrounds it
# If the block is updated this function will spawn the new block and enter it into the blocks_dict
# Returns true if the old block instance should be deleted 
func update_from_adjacent(adjacents: Array[Vector3i], block_grid: Node3D) -> bool:
	if len(adjacents) != 2:
		var new_block: Node3D = load("res://blocks/transporter_corner.tscn").instantiate()
		block_grid.add_child(new_block);
		new_block.global_position = self.global_position
		new_block.basis = self.basis
		BlockGlobals.blocks_dict[BlockGlobals.to_grid(self.global_position)] = new_block
		return true 

	return false 
