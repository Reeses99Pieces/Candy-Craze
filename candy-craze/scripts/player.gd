extends CharacterBody2D

@export var move_speed: float = 150.0
@export var cam_strength: float = 0.05        # how "big" the perspective offset is
@export var cam_smooth: float = 0.1           # how smoothly camera moves
@export var cam_max_offset: float = 50.0      # max drift from (0,0)

@onready var cam: Camera2D = $Camera2D

func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_camera()

func _handle_movement() -> void:
	var input_vector = Vector2.ZERO

	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	input_vector = input_vector.normalized()
	velocity = input_vector * move_speed

	move_and_slide()

func _handle_camera():
	if not cam:
		return

	# perspective-style offset based on the player's position in world space
	var offset := global_position * cam_strength

	# clamp maximum drift
	offset = offset.limit_length(cam_max_offset)

	# smoothly move camera toward offset from (0,0)
	var desired := offset
	cam.global_position = cam.global_position.lerp(desired, cam_smooth)
