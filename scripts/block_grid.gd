extends Node3D

@export var highlight: PackedScene;
@export var block: PackedScene;

@export var block_detector: RayCast3D
@export var adjacency_checker: Node3D

var highlight_active := false
var highlight_instance: Node3D; # Instance of the highlight square
var highlighted_block_instance: Node3D; 
var highlight_normal := Vector3.ZERO

const GHOST_BLOCK_TRANSPARENCY := 0.5

func _ready() -> void:

	# Spawn block highlight node and set it's size
	highlight_instance = highlight.instantiate()
	self.add_child(highlight_instance)
	highlight_instance.visible = false
	var highlight_mesh = highlight_instance.get_child(0)
	highlight_mesh.scale = Vector3(BlockGlobals.BLOCK_SIZE, 0.001, BlockGlobals.BLOCK_SIZE) 
	
	# Resize the block detector
	block_detector.scale.y = BlockGlobals.BLOCK_HIGHLIGHT_LEN * BlockGlobals.BLOCK_SIZE
	
	# Spawn some blocks
	for i in range(0, 10):
		place_block(Vector3(i * BlockGlobals.BLOCK_SIZE, 0, 0), block)

func reset_highlight():
	highlight_active = false
	highlight_instance.visible = false
	highlighted_block_instance = null
	highlight_normal = Vector3.ZERO

# Highlight the blcok that the block detector raycast is colliding with
func highlight_block():
	if block_detector.is_colliding():
		var collision_point = block_detector.get_collision_point()
		var norm = block_detector.get_collision_normal()
		var collider: Node3D = block_detector.get_collider()
		
		if not is_instance_valid(collider):
			return
		
		highlight_active = true
		highlight_normal = norm
		highlighted_block_instance = collider

		# var highlight_mesh: MeshInstance3D = highlight_instance.get_child(0)
		highlight_instance.rotation = Vector3.ZERO

		highlight_instance.global_position = collider.global_position + (BlockGlobals.BLOCK_SIZE * norm / 2)
		highlight_instance.visible = true 

		# Align the highlight to the collision normal
		var highlight_align_dir: Vector3 = highlight_instance.get_meta("align_direction")
		if highlight_align_dir != null:
			MathGlobals.rotate_to_match_dir(highlight_instance, highlight_align_dir, norm)

	else:
		reset_highlight()

# Places a block at the provided position and returns the instance
# null will be returned if the position was occupied
func place_block(block_pos: Vector3, block_scene: PackedScene, spawn_temp_block := false) -> Node3D:
	var block_grid_pos: Vector3i = BlockGlobals.to_grid(block_pos)
	if BlockGlobals.blocks_dict.has(block_grid_pos):
		return null

	var new_block: Node3D = block_scene.instantiate()
	self.add_child(new_block);
	new_block.global_position = block_pos 

	if not spawn_temp_block:
		BlockGlobals.blocks_dict[BlockGlobals.to_grid(block_grid_pos)] = new_block
		adjacency_checker.update_block_and_neighbors(block_pos, self)

	return new_block

# Places the temp block with an offset from the real block
# Used for placing blocks in a line
# Null will be returned if the temp block could not be placed
func place_temp_block(block_pos: Vector3, temp_block_offset: Vector3, block_scene: PackedScene) -> Node3D:

	# Allow for the temp block to be placed through one block
	# This allows for drag placement through intersections of blocks
	for i in range(1, 3):
		var temp_block_pos := block_pos + (temp_block_offset * i)
		var temp_block_instance = place_block(temp_block_pos, block_scene, true)
		if is_instance_valid(temp_block_instance):
			BlockGlobals.get_mesh(temp_block_instance).transparency = GHOST_BLOCK_TRANSPARENCY
			return temp_block_instance

	return null	

# Handles the user input for placing and deleting blocks
var next_block_offset: Vector3
var temp_block: Node3D
func place_blocks():
	if Input.is_action_just_released("place_block") and is_instance_valid(temp_block):
		temp_block.queue_free()
		reset_highlight()

	if not highlight_active:
		return

	if not is_instance_valid(highlighted_block_instance):
		return

	if Input.is_action_just_pressed("place_block"):
		next_block_offset = highlight_normal * BlockGlobals.BLOCK_SIZE
		var new_block_position = highlighted_block_instance.global_position + next_block_offset
		place_block(new_block_position, block)

		# Spawn temp block for placing multiple in a line
		temp_block = place_temp_block(new_block_position, next_block_offset, block)

	# Place next blocks in the same direction if the key is held down
	if Input.is_action_pressed("place_block") and is_instance_valid(temp_block):
		if block_detector.is_colliding():
			var collider: Node3D = block_detector.get_collider()
			var temp_block_grid_pos: Vector3i = BlockGlobals.to_grid(temp_block.position)
			if BlockGlobals.to_grid(collider.position) == temp_block_grid_pos:

				# Turn the temp block into a real block
				BlockGlobals.get_mesh(temp_block).transparency = 0
				BlockGlobals.blocks_dict[temp_block_grid_pos] = temp_block 
				adjacency_checker.update_block_and_neighbors(temp_block_grid_pos, self)

				# Spawn a new temp block
				temp_block = place_temp_block(temp_block.global_position, next_block_offset, block)
		
	if Input.is_action_just_pressed("delete_block") or Input.is_action_pressed("quick_delete"):
		var deleted_position := highlighted_block_instance.global_position
		BlockGlobals.blocks_dict.erase(BlockGlobals.to_grid(deleted_position))
		adjacency_checker.update_neighbors(deleted_position, self)
		highlighted_block_instance.queue_free()
		reset_highlight()


func _process(_delta: float) -> void:
	highlight_block()
	place_blocks()
	# print("active:", highlight_active, " pos:", highlight_block_pos, " normal:", highlight_normal)
