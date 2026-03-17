extends Node3D

@export var highlight: PackedScene;
@export var block: PackedScene;

@export var block_detector: RayCast3D

var highlight_active := false
var highlight_instance: Node3D; # Instance of the highlight square
var highlighted_block_instace: Node3D; 
var highlight_normal := Vector3.ZERO

func _ready() -> void:

	# Spawn block highlight node and set it's size
	highlight_instance = highlight.instantiate()
	self.add_child(highlight_instance)
	highlight_instance.visible = false
	var highlight_mesh = highlight_instance.get_node("MeshInstance3D")
	highlight_mesh.scale = Vector3(BlockConsts.BLOCK_SIZE, 0.001, BlockConsts.BLOCK_SIZE)
	
	# Resize the block detector
	block_detector.scale.y = BlockConsts.BLOCK_HIGHLIGHT_LEN * BlockConsts.BLOCK_SIZE
	
	# Spawn some blcoks
	for i in range(1, 5):
		var new_block = block.instantiate()
		self.add_child(new_block);
		new_block.position = Vector3(i * BlockConsts.BLOCK_SIZE, 0, 0)

func reset_highlight():
	highlight_active = false
	highlight_instance.visible = false
	highlighted_block_instace = null
	highlight_normal = Vector3.ZERO


# Highlight the blcok that the block detector raycast is colliding with
func highlight_block():
	if block_detector.is_colliding():
		var norm = block_detector.get_collision_normal()
		var collider: Node3D = block_detector.get_collider()
		
		if not is_instance_valid(collider):
			return
		
		var highlighted_block_changed := false
		if is_instance_valid(highlighted_block_instace):
			highlighted_block_changed = highlighted_block_instace.global_position != collider.global_position

		if norm != highlight_normal or highlighted_block_changed:
			highlight_active = true
			highlight_normal = norm
			highlighted_block_instace = collider

			var highlight_mesh: MeshInstance3D = highlight_instance.get_child(0)
			highlight_mesh.rotation = Vector3.ZERO

			highlight_instance.global_position = collider.global_position + (BlockConsts.BLOCK_SIZE * norm / 2)
			highlight_instance.visible = true 
			var angle_x = acos(highlight_mesh.basis.x.dot(norm) / (highlight_mesh.basis.x.length() * norm.length()))
			var angle_z = acos(highlight_mesh.basis.z.dot(norm) / (highlight_mesh.basis.z.length() * norm.length()))
			highlight_mesh.rotation = Vector3(PI / 2 - angle_z, 0, PI / 2 - angle_x)

	else:
		reset_highlight()

# Places a block at the provided position and returns the instance
# null will be returned if the position was occupied
func place_block(block_pos: Vector3, block_parent: Node3D) -> Node3D:
		var space_state = get_world_3d().direct_space_state

		var query = PhysicsPointQueryParameters3D.new()
		query.position = block_pos 
		query.collide_with_bodies = true
		query.collide_with_areas = false
		var result = space_state.intersect_point(query, 1)

		if result.size() > 0:
			return null

		var new_block: Node3D = block.instantiate()
		block_parent.add_child(new_block);
		new_block.global_position = block_pos 
		return new_block


var next_block_offset: Vector3
var temp_block: Node3D
func place_blocks():
	if Input.is_action_just_released("place_block") and is_instance_valid(temp_block):
		temp_block.queue_free()

	if not highlight_active:
		return

	if not is_instance_valid(highlighted_block_instace):
		return

	if Input.is_action_just_pressed("place_block"):
		next_block_offset = highlight_normal * BlockConsts.BLOCK_SIZE
		var new_block_position = highlighted_block_instace.global_position + next_block_offset
		var next_block_position = highlighted_block_instace.global_position + next_block_offset * 2
		place_block(new_block_position, self)

		# Spawn temp block for placing multiple in a line
		temp_block = place_block(next_block_position, self)
		if is_instance_valid(temp_block):
			temp_block.visible = false

	# Place next blocks in the same direction if the key is held down
	if Input.is_action_pressed("place_block") and is_instance_valid(temp_block):
		if block_detector.is_colliding():
			var collider: Node3D = block_detector.get_collider()
			if collider.position == temp_block.position:
				temp_block.visible = true
				temp_block = place_block(temp_block.global_position + next_block_offset, self)

				if is_instance_valid(temp_block):
					temp_block.visible = false
		
	if Input.is_action_just_pressed("delete_block") or Input.is_action_pressed("quick_delete"):
		highlighted_block_instace.queue_free()
		reset_highlight()


func _process(_delta: float) -> void:
	highlight_block()
	place_blocks()
	# print("active:", highlight_active, " pos:", highlight_block_pos, " normal:", highlight_normal)
