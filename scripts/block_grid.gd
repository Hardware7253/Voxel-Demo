extends Node3D

@export var highlight: PackedScene;
@export var block: PackedScene;

@export var block_detector: RayCast3D
@export var adjacency_checker: Node3D

var highlight_active := false
var highlight_instance: Node3D; # Instance of the highlight square
var highlighted_block_instance: Node3D; 
var highlight_normal := Vector3.ZERO

func _ready() -> void:

	# Spawn block highlight node and set it's size
	highlight_instance = highlight.instantiate()
	self.add_child(highlight_instance)
	highlight_instance.visible = false
	var highlight_mesh = highlight_instance.get_node("MeshInstance3D")
	highlight_mesh.scale = Vector3(BlockGlobals.BLOCK_SIZE, 0.001, BlockGlobals.BLOCK_SIZE)
	
	# Resize the block detector
	block_detector.scale.y = BlockGlobals.BLOCK_HIGHLIGHT_LEN * BlockGlobals.BLOCK_SIZE
	
	# Spawn some blocks
	for i in range(0, 10):
		place_block(Vector3(i * BlockGlobals.BLOCK_SIZE, 0, 0), Vector3.UP, block, self)

func reset_highlight():
	highlight_active = false
	highlight_instance.visible = false
	highlighted_block_instance = null
	highlight_normal = Vector3.ZERO

# Rotates a node to match the direction of the node_alignment_dir to match_dir
# Directions are expected to be unit vectors
func rotate_to_match_dir(node: Node3D, node_alignment_dir: Vector3, match_dir: Vector3):
	var angle = acos(node_alignment_dir.dot(match_dir)) # From θ = cos⁻¹((a·b) / (|a||b|))
	var axis = node_alignment_dir.cross(match_dir)
	if axis.length() > 0.000001:
		node.basis = Basis(axis.normalized(), angle)
	else:
		node.basis = Basis(match_dir, angle)

# Highlight the blcok that the block detector raycast is colliding with
func highlight_block():
	if block_detector.is_colliding():
		var norm = block_detector.get_collision_normal()
		var collider: Node3D = block_detector.get_collider()
		
		if not is_instance_valid(collider):
			return
		
		var highlighted_block_changed := false
		if is_instance_valid(highlighted_block_instance):
			highlighted_block_changed = highlighted_block_instance.global_position != collider.global_position

		if norm != highlight_normal or highlighted_block_changed:
			highlight_active = true
			highlight_normal = norm
			highlighted_block_instance = collider

			var highlight_mesh: MeshInstance3D = highlight_instance.get_child(0)
			highlight_mesh.rotation = Vector3.ZERO

			highlight_instance.global_position = collider.global_position + (BlockGlobals.BLOCK_SIZE * norm / 2)
			highlight_instance.visible = true 

			# Align the highlight to the collision normal
			var highlight_align_dir: Vector3 = highlight_instance.get_meta("align_direction")
			if highlight_align_dir != null:
				rotate_to_match_dir(highlight_instance, highlight_align_dir, norm)

	else:
		reset_highlight()

# Places a block at the provided position and returns the instance
# null will be returned if the position was occupied
func place_block(block_pos: Vector3, place_normal: Vector3, block_scene: PackedScene, block_parent: Node3D, dummy_block:= false) -> Node3D:
	if BlockGlobals.blocks_dict.has(Vector3i(block_pos)):
		return null

	var new_block: Node3D = block_scene.instantiate()
	block_parent.add_child(new_block);
	new_block.global_position = block_pos 

	# Align the block to the placement normal
	var block_align_dir: Vector3 = new_block.get_meta("align_direction")
	if block_align_dir != null:
		rotate_to_match_dir(new_block, block_align_dir, place_normal)

	if not dummy_block:
		BlockGlobals.blocks_dict[Vector3i(block_pos)] = new_block
		adjacency_checker.update_block_and_neighbors(block_pos, self)

	return new_block


# Handles the user input for placing and deleting blocks
var next_block_offset: Vector3
var temp_block: Node3D
func place_blocks():
	if Input.is_action_just_released("place_block") and is_instance_valid(temp_block):
		temp_block.queue_free()

	if not highlight_active:
		return

	if not is_instance_valid(highlighted_block_instance):
		return

	if Input.is_action_just_pressed("place_block"):
		next_block_offset = highlight_normal * BlockGlobals.BLOCK_SIZE
		var new_block_position = highlighted_block_instance.global_position + next_block_offset
		var next_block_position = highlighted_block_instance.global_position + next_block_offset * 2
		place_block(new_block_position, highlight_normal, block, self)

		# Spawn temp block for placing multiple in a line
		temp_block = place_block(next_block_position, highlight_normal, block, self, true)
		if is_instance_valid(temp_block):
			temp_block.visible = false

	# Place next blocks in the same direction if the key is held down
	if Input.is_action_pressed("place_block") and is_instance_valid(temp_block):
		if block_detector.is_colliding():
			var collider: Node3D = block_detector.get_collider()
			if collider.position == temp_block.position:

				# Turn the temp block into a real block
				temp_block.visible = true
				BlockGlobals.blocks_dict[Vector3i(temp_block.global_position)] = temp_block 
				adjacency_checker.update_block_and_neighbors(Vector3i(temp_block.global_position), self)

				# Spawn a new temp block
				temp_block = place_block(temp_block.global_position + next_block_offset, next_block_offset.normalized(), block, self, true)

				if is_instance_valid(temp_block):
					temp_block.visible = false
		
	if Input.is_action_just_pressed("delete_block") or Input.is_action_pressed("quick_delete"):
		var deleted_position := Vector3i(highlighted_block_instance.global_position)
		highlighted_block_instance.queue_free()
		BlockGlobals.blocks_dict.erase(Vector3i(highlighted_block_instance.position))
		adjacency_checker.update_neighbors(deleted_position, self)
		reset_highlight()


func _process(_delta: float) -> void:
	highlight_block()
	place_blocks()
	# print("active:", highlight_active, " pos:", highlight_block_pos, " normal:", highlight_normal)
