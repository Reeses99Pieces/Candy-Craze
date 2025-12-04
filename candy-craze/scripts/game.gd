extends Node2D

var player_scene = preload("res://nodes/player.tscn")
var player = player_scene.instantiate()

@onready var menu: Control = $CanvasLayer/Menu
@onready var map: TileMap = $CanvasLayer/SubViewport/TileMap
@onready var subviewport: SubViewport = $CanvasLayer/SubViewport

func _on_button_pressed() -> void:
	map.generate_maze()
	subviewport.add_child(player)
	player.position = map.get_spawn_point()
	menu.visible = false
