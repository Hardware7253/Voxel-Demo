extends Node3D

@export var highlight: PackedScene;
@export var block: PackedScene;

@export var block_detector: RayCast3D
@export var adjacency_checker: Node3D

var highlight_active := false
var highlight_instance: Node3D # Instance of the highlight square
var highlighted_block_pos: Vector3i
var highlight_normal := Vector3.ZERO

const GHOST_BLOCK_TRANSPARENCY := 0.5

func _ready() -> void:

	# Spawn block highlight node and set it's size
	highlight_instance = highlight.instantiate()
	self.add_child(highlight_instance)
	highlight_instance.visible = false
	var highlight_mesh = highlight_instance.get_child(0)
	highlight_mesh.scale = Vector3(BlockGlobals.BLOCK_SIZE, 0.001, BlockGlobals.BLOCK_SIZE) 
	
	# Resize raycast
	block_detector.scale.y = BlockGlobals.BLOCK_HIGHLIGHT_LEN * BlockGlobals.BLOCK_SIZE

func reset_highlight():
	highlight_active = false
	highlight_instance.visible = false

# Sets the highlight instances position based on a block position and collision normal
func set_highlight(block_pos: Vector3, collision_normal: Vector3):
	highlight_active = true
	highlight_normal = collision_normal

	highlight_instance.rotation = Vector3.ZERO

	highlight_instance.global_position = block_pos + (BlockGlobals.BLOCK_SIZE * collision_normal / 2)
	highlighted_block_pos = BlockGlobals.to_grid(block_pos)
	highlight_instance.visible = true 

	# Align the highlight to the collision collision_normal
	if highlight_instance.has_meta("align_direction"):
		var highlight_align_dir: Vector3 = highlight_instance.get_meta("align_direction")
		MathGlobals.rotate_to_match_dir(highlight_instance, highlight_align_dir, collision_normal)

# Highlight blocks and planes to allow placing blocks of them
func highlight_blocks_planes():
	if not (highlight_block() or highlight_plane()):
		reset_highlight()

# Highlight the block that the block detector raycast is colliding with
# Returns true if something is being highlighted
func highlight_block() -> bool:
	if not block_detector.is_colliding():
		reset_highlight()
		return false

	var collision_normal: Vector3 = block_detector.get_collision_normal()
	var collider: Node3D = block_detector.get_collider()
	
	if not is_instance_valid(collider):
		return false

	# Don't highlight out of limits
	# if not BlockGlobals.is_in_limits(collision_normal * BlockGlobals.BLOCK_SIZE + collider.global_position):
	# 	return false

	set_highlight(collider.global_position, collision_normal)
	return true


# Highlight a position on the placement planes
# Returns true if something is being highlighted
# The exclude parameters allows a node to be excluded from the raycast collision
func highlight_plane(exclude: Node3D = null) -> bool:
	var space_state = get_world_3d().direct_space_state

	var query = PhysicsRayQueryParameters3D.create(block_detector.global_position, block_detector.global_position - block_detector.global_basis.y)
	if is_instance_valid(exclude):
		query.exclude = [exclude]

	var result = space_state.intersect_ray(query)
	if result:
		if not is_instance_valid(result.collider):
			return false
	else:
		return false

	# Check for plane
	var collider: Node3D = result.collider
	if not collider.has_meta("plane_normal"):
		return false

	# Check collision and plane normals face the same direction
	var plane_normal: Vector3 = collider.get_meta("plane_normal")
	var collision_normal = result.normal
	if plane_normal.dot(collision_normal) < 0:
		return highlight_plane(collider)

	var collision_point = result.position
	var block_point = BlockGlobals.to_nearest_block_pos(collision_point - collision_normal)
	set_highlight(Vector3(block_point), collision_normal)
	return true


# Places a block at the provided position and returns the instance
# null will be returned if the position was occupied or the position is out of bounds
func place_block(block_pos: Vector3, block_scene: PackedScene, spawn_temp_block := false) -> Node3D:
	var block_grid_pos: Vector3i = BlockGlobals.to_grid(block_pos)
	if BlockGlobals.blocks_dict.has(block_grid_pos):
		return null

	if not BlockGlobals.is_in_limits(block_pos):
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
	if Input.is_action_just_released("quick_place") and is_instance_valid(temp_block):
		temp_block.queue_free()
		reset_highlight()

	if not highlight_active:
		return

	if Input.is_action_just_pressed("place_block") or Input.is_action_just_pressed("quick_place"):
		next_block_offset = highlight_normal * BlockGlobals.BLOCK_SIZE
		var new_block_position = Vector3(highlighted_block_pos) + next_block_offset
		place_block(new_block_position, block)

		# Spawn temp block for placing multiple in a line
		if Input.is_action_pressed("quick_place"):
			temp_block = place_temp_block(new_block_position, next_block_offset, block)

	# Place next blocks in the same direction if the key is held down
	if Input.is_action_pressed("quick_place") and is_instance_valid(temp_block):
		if block_detector.is_colliding():
			var collider: Node3D = block_detector.get_collider()
			var temp_block_grid_pos: Vector3i = BlockGlobals.to_grid(temp_block.position)

			if is_instance_valid(collider):
				if BlockGlobals.to_grid(collider.position) == temp_block_grid_pos:

					# Turn the temp block into a real block
					BlockGlobals.get_mesh(temp_block).transparency = 0
					BlockGlobals.blocks_dict[temp_block_grid_pos] = temp_block 
					adjacency_checker.update_block_and_neighbors(temp_block_grid_pos, self)

					# Spawn a new temp block
					temp_block = place_temp_block(temp_block.global_position, next_block_offset, block)
		
	if Input.is_action_just_pressed("delete_block") or Input.is_action_pressed("quick_delete"):
		if BlockGlobals.blocks_dict.has(highlighted_block_pos):
			var highlighted_block_instance: Node3D = BlockGlobals.blocks_dict[highlighted_block_pos]
			BlockGlobals.blocks_dict.erase(highlighted_block_pos)
			adjacency_checker.update_neighbors(highlighted_block_pos, self)
			highlighted_block_instance.queue_free()
			reset_highlight()


func _process(_delta: float) -> void:
	place_blocks()

func _physics_process(_delta):
	highlight_blocks_planes()
