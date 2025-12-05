extends TileMap
class_name MazeGen

var starting_pos = Vector2i()
const main_layer = 0

const SOURCE_ID = 0
const WALL_ATLAS = Vector2i(0, 0)
const FLOOR_ATLAS = Vector2i(3, 0)
const HOUSE_UNCLAIMED = Vector2i(1, 0)
const HOUSE_CLAIMED   = Vector2i(2, 0)

@export var y_dim: int = 35
@export var x_dim: int = 35
@export var starting_coords := Vector2i(0, 0)

@export_category("Generation")
@export var allow_loops: bool = false
@export var step_delay: float = 0.0
@export var grid_size: int = 15
@export var enemy_count: int = 4
@export var house_count: int = 4
@export var max_enemies: int = 6
@export var seed: int = 0

var rng := RandomNumberGenerator.new()
var adj4 = [
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

var houses := []
var walkable_tiles := []
var dead_end_tiles := []
var spawn_point := Vector2i()
var goal_point := Vector2i()

var astar := AStar2D.new()
var house_scene = preload("res://nodes/house.tscn")
var enemy_scene = preload("res://nodes/enemy.tscn")

func generate_maze():
	x_dim = grid_size
	y_dim = grid_size

	if seed == 0:
		seed = int(Time.get_ticks_msec())
	rng.seed = seed

	wipe_layer(main_layer)
	place_border()
	dfs(starting_coords)

	find_dead_ends()
	build_nav_region()
	place_houses()
	choose_spawn_and_goal()
	center_maze()
	place_enemies()

	print("generation seed lol: ", seed)

func wipe_layer(layer: int):
	var used = get_used_cells(layer)
	for u in used:
		set_cell(layer, u)

func place_border():
	for y in range(-1, y_dim):
		set_cell(main_layer, Vector2i(-1, y), SOURCE_ID, WALL_ATLAS)
	for x in range(-1, x_dim):
		set_cell(main_layer, Vector2i(x, -1), SOURCE_ID, WALL_ATLAS)
	for y in range(-1, y_dim + 1):
		set_cell(main_layer, Vector2i(x_dim, y), SOURCE_ID, WALL_ATLAS)
	for x in range(-1, x_dim + 1):
		set_cell(main_layer, Vector2i(x, y_dim), SOURCE_ID, WALL_ATLAS)

func is_wall(pos: Vector2i) -> bool:
	return get_cell_atlas_coords(main_layer, pos) == WALL_ATLAS

func will_be_converted_to_wall(pos: Vector2i) -> bool:
	return pos.x % 2 == 1 and pos.y % 2 == 1

func can_move_to(pos: Vector2i) -> bool:
	return (
		pos.x >= 0 and pos.x < x_dim and
		pos.y >= 0 and pos.y < y_dim and
		not is_wall(pos)
	)
	
func build_nav_region():
	var nav_region = NavigationRegion2D.new()
	var nav_poly = NavigationPolygon.new()
	nav_region.navigation_polygon = nav_poly
	
	var polys = []
	var ts = tile_set.tile_size

	# Create a rectangle polygon for each walkable tile
	for tile in walkable_tiles:
		var x = tile.x * ts.x
		var y = tile.y * ts.y
		var rect = PackedVector2Array([
			Vector2(x, y),
			Vector2(x + ts.x, y),
			Vector2(x + ts.x, y + ts.y),
			Vector2(x, y + ts.y)
		])
		polys.append(rect)

	nav_poly.add_outline(polys[0])
	for p in polys:
		nav_poly.add_outline(p)

	nav_poly.make_polygons_from_outlines()
	add_child(nav_region)

func dfs(start: Vector2i):
	var stack: Array[Vector2i] = [start]
	var seen := {}

	while stack.size() > 0:
		var current: Vector2i = stack.pop_back()

		if current in seen or not can_move_to(current):
			continue
		seen[current] = true

		if current.x % 2 == 1 and current.y % 2 == 1:
			set_cell(main_layer, current, SOURCE_ID, WALL_ATLAS)
			continue

		set_cell(main_layer, current, SOURCE_ID, FLOOR_ATLAS)
		walkable_tiles.append(current)

		if step_delay > 0:
			await get_tree().create_timer(step_delay).timeout

		var found_new = false
		adj4.shuffle()

		for dir in adj4:
			var nxt = current + dir
			if nxt not in seen and can_move_to(nxt):
				var chance = 1
				if allow_loops:
					chance = rng.randi_range(1, 5)

				if will_be_converted_to_wall(nxt) and chance == 1:
					set_cell(main_layer, nxt, SOURCE_ID, WALL_ATLAS)
				else:
					found_new = true
					stack.append(nxt)

		if not found_new:
			set_cell(main_layer, current, SOURCE_ID, WALL_ATLAS)

func find_dead_ends():
	dead_end_tiles.clear()

	for tile in walkable_tiles:
		var neighbors = 0
		for dir in adj4:
			if can_move_to(tile + dir) and not is_wall(tile + dir):
				neighbors += 1
		if neighbors == 1:
			dead_end_tiles.append(tile)

func place_houses():
	dead_end_tiles.shuffle()

	var placed = 0
	for tile in dead_end_tiles:
		if placed >= house_count:
			break
		set_cell(main_layer, tile, SOURCE_ID, HOUSE_UNCLAIMED)
		
		var house = house_scene.instantiate()
		house.position = map_to_local(tile)
		add_child(house)
		
		houses.append(house)
		placed += 1
		
func place_enemies():
	var count := 0
	for house in houses:
		if count >= max_enemies:
			break
		var enemy = enemy_scene.instantiate()
		enemy.position = house.position
		add_child(enemy)
		count += 1

func choose_spawn_and_goal():
	var candidates = walkable_tiles.filter(
		func(t):
			return t not in dead_end_tiles
	)

	if candidates.size() < 2:
		return

	# pick random valid locations
	candidates.shuffle()

	spawn_point = candidates[0]
	goal_point = candidates[candidates.size() - 1]

func center_maze():
	var tile_size = tile_set.tile_size
	var w = x_dim * tile_size.x
	var h = y_dim * tile_size.y
	position = Vector2(-w * 0.5, -h * 0.5)

func get_spawn_point() -> Vector2i:
	return spawn_point

func get_goal_point() -> Vector2i:
	return goal_point
