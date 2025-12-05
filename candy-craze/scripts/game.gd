extends Node2D

var map_scene = preload("res://nodes/maze.tscn")
var player_scene = preload("res://nodes/player.tscn")
var player = player_scene.instantiate()

@onready var game_over: Control = $CanvasLayer/GameOver
@onready var next_level: Control = $CanvasLayer/NextLevel
@onready var menu: Control = $CanvasLayer/Menu
@onready var subviewport: SubViewport = $CanvasLayer/SubViewport
@onready var anims: AnimationPlayer = $AnimationPlayer 

var current_map = false
var level = 0
var houses_left = 0

#rushed last second coding sorry for the mess
func _on_start_pressed() -> void:
	menu.visible = false
	loop_thunder()
	_new_level()
	
func _on_restart_pressed() -> void:
	level = 0
	game_over.visible = false
	_new_level()
	
func _on_next_pressed() -> void:
	next_level.visible = false
	_new_level()
	
func _on_game_over():
	game_over.visible = true

func _on_house_collected():
	houses_left -= 1
	if houses_left <= 0:
		next_level.visible = true

func _new_level():
	level += 1
	
	if current_map:
		current_map.queue_free()
	
	current_map = map_scene.instantiate()

	current_map.grid_size = 13 + (level*2)
	current_map.max_enemies = clamp(level, 1, 4)
	current_map.house_count = 4 + floor(level / 2)

	subviewport.add_child(current_map)
	current_map.generate_maze()

	houses_left = 0
	for child in current_map.get_children():
		if child.has_signal("collected"):
			child.connect("collected", _on_house_collected)
			houses_left += 1
	
	subviewport.add_child(player)
	player.position = current_map.get_spawn_point()
	player.connect("game_over", _on_game_over)

func loop_thunder() -> void:
	while true:
		anims.play("thunder")
		var wait_time := randf_range(8, 10)
		await get_tree().create_timer(wait_time).timeout
