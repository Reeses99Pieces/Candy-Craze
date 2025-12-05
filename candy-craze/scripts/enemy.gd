extends CharacterBody2D

@export var move_speed: float = 50
@export var detection_range: float = 200
@export var lost_sight_time: float = 2
@export var avoid_time: float = 5

@export var safe = false

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var ray: RayCast2D = $RayCast2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var target_player: Node = null
var time_unseen := 0.0
var wander_timer := 0.0
var maze
var avoid_timer := 0.0
var avoid_player: Node = null
var spawn_position: Vector2

enum State { WANDER, CHASE, AVOID }
var state = State.WANDER

func _ready():
	maze = get_parent()
	spawn_position = global_position
	_pick_new_wander_target()

func _physics_process(delta):
	_update_collision_state()
	match state:
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase(delta)
		State.AVOID:
			_process_avoid(delta)
	_move_agent()

func _update_collision_state():
	if state == State.WANDER:
		collision.disabled = true
	else:
		collision.disabled = false

func _move_agent():
	var next_pos = agent.get_next_path_position()
	if next_pos == Vector2.ZERO:
		return
	var dir = (next_pos - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()

func _check_for_player():
	if state == State.AVOID:
		return
	var players = get_tree().get_nodes_in_group("Players")
	var closest = null
	var closest_dist = INF
	for p in players:
		var d = global_position.distance_to(p.global_position)
		if d < detection_range and d < closest_dist:
			closest = p
			closest_dist = d
	if closest == null:
		return
	ray.target_position = closest.global_position - global_position
	ray.force_raycast_update()
	if not ray.is_colliding() or ray.get_collider() == closest and not closest.safe:
		target_player = closest
		state = State.CHASE
		agent.target_position = closest.global_position

func _pick_new_wander_target():
	var tiles = maze.walkable_tiles
	if tiles.is_empty():
		return
	var tile = tiles[randi() % tiles.size()]
	var ts = maze.tile_set.tile_size
	agent.target_position = Vector2(tile.x * ts.x + ts.x * 0.5, tile.y * ts.y + ts.y * 0.5)

func _process_wander(delta):
	_check_for_player()
	wander_timer -= delta
	if wander_timer <= 0:
		_pick_new_wander_target()
		wander_timer = randf_range(2.0, 4.0)

func _process_chase(delta):
	if target_player == null:
		state = State.WANDER
		_pick_new_wander_target()
		return
	agent.target_position = target_player.global_position
	ray.target_position = target_player.global_position - global_position
	ray.force_raycast_update()
	if ray.is_colliding() and ray.get_collider() != target_player:
		time_unseen += delta
		if time_unseen >= lost_sight_time:
			target_player = null
			state = State.WANDER
			_pick_new_wander_target()
			return
	else:
		time_unseen = 0

func _process_avoid(delta):
	avoid_timer -= delta
	if avoid_timer <= 0:
		avoid_player = null
		state = State.WANDER
		_pick_new_wander_target()
		return
	agent.target_position = spawn_position

func _on_area_2d_body_entered(body):
	if body.is_in_group("Players") and not body.in_house:
		avoid_player = body
		avoid_timer = avoid_time
		state = State.AVOID
		target_player = null
		time_unseen = 0
		body._change_points(-1)
