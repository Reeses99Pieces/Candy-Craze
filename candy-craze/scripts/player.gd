extends CharacterBody2D

signal game_over()

@export var move_speed: float = 70.0
@export var cam_strength: float = 0.05
@export var cam_smooth: float = 0.1
@export var cam_max_offset: float = 50.0

@onready var area: Area2D = $Area2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var light: PointLight2D = $PointLight2D
@onready var cam: Camera2D = $Camera2D

@onready var stats: Control = $CanvasLayer/Stats
@onready var score: Label = $CanvasLayer/Stats/VBoxContainer/Score
@onready var level: Label = $CanvasLayer/Stats/VBoxContainer/Level

var points = 1
var safe: bool = false
var was_safe: bool = false
var in_house: bool = false

func _ready():
	stats.visible = true

func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_camera()
	_update_safe_state()

func _change_points(amount):
	points += amount
	score.text = "CANDY: " + str(points)
	if points < 0:
		emit_signal("game_over")

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
	var offset := global_position * cam_strength
	offset = offset.limit_length(cam_max_offset)
	var desired := offset
	cam.global_position = cam.global_position.lerp(desired, cam_smooth)

func _update_safe_state():
	var is_moving = velocity.length() > 0.1
	in_house = false
	for a in area.get_overlapping_areas():
		if a.is_in_group("Houses"):
			in_house = true
			break
	
	safe = not is_moving or in_house
	if safe != was_safe:
		if safe:
			anim.play("Toggle") # animation for entering safe
		else:
			anim.play_backwards("Toggle") # animation for leaving safe
	was_safe = safe
