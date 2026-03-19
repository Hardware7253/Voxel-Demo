extends Node3D 

@export var speed := 5
@export var mouse_sensitivity := 2.0
@export var sprint_mod := 2.0

var raw_speed = speed * BlockGlobals.BLOCK_SIZE

var mouse_captured := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	move_camera(delta)

# Move player according to inputs
# This was modelled after the minecraft creative movement
var is_sprinting := false;
func move_camera(delta: float):
	var dir_vec := Vector3.ZERO

	if Input.is_action_just_pressed("sprint"):
		is_sprinting = !is_sprinting; 
	
	if Input.is_action_pressed("fly_up"):
		dir_vec += Vector3.UP
		
	if Input.is_action_pressed("fly_down"):
		dir_vec += Vector3.DOWN
		
	if Input.is_action_pressed("move_left"):
		dir_vec += Vector3.LEFT
		
	if Input.is_action_pressed("move_right"):
		dir_vec += Vector3.RIGHT
	
	if Input.is_action_pressed("move_forward"):
		dir_vec += Vector3.FORWARD
		
	if Input.is_action_pressed("move_backward"):
		dir_vec += Vector3.BACK

	if Input.is_action_just_pressed("ui_cancel"):
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_captured = not mouse_captured


	var move_vec := dir_vec.rotated(Vector3.UP, self.rotation.y)
	move_vec *= raw_speed

	if is_sprinting:
		move_vec *= sprint_mod

	move_vec *= delta;

	self.global_position += move_vec

# Control camera pitch and yaw
var pitch := 0.0
func _input(event):
	if event is InputEventMouseMotion:
		var sense := mouse_sensitivity / 1000.0

		# Yaw (left/right)
		rotate_y(-event.relative.x * sense)

		# Pitch (up/down)
		pitch -= event.relative.y * sense 
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))

		self.rotation.x = pitch
