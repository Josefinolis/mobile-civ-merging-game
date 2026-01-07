extends Control
class_name GameGrid
## GameGrid - Manages the grid of buildings and handles merging logic

signal merge_completed(new_level: int)

const BUILDING_SCENE_PATH = "res://scenes/building.tscn"

@export var cell_size: Vector2 = Vector2(160, 170)
@export var cell_padding: Vector2 = Vector2(8, 8)

var building_scene: PackedScene
var buildings: Array = []  # 2D array of Building nodes
var dragged_building = null
var highlight_cell: Vector2i = Vector2i(-1, -1)

@onready var cells_container: Control = $CellsContainer
@onready var buildings_container: Control = $BuildingsContainer
@onready var highlight: ColorRect = $Highlight

func _ready() -> void:
	building_scene = load(BUILDING_SCENE_PATH)
	_setup_grid()
	_create_buildings()
	_sync_with_game_manager()

func _setup_grid() -> void:
	# Create cell backgrounds with improved visuals
	for x in range(GameManager.grid_size.x):
		for y in range(GameManager.grid_size.y):
			var cell_pos = _grid_to_pixel(Vector2i(x, y))

			# Cell shadow (offset)
			var shadow = ColorRect.new()
			shadow.custom_minimum_size = cell_size - Vector2(4, 4)
			shadow.size = cell_size - Vector2(4, 4)
			shadow.position = cell_pos + Vector2(6, 6)
			shadow.color = Color(0, 0, 0, 0.25)
			cells_container.add_child(shadow)

			# Cell border/outline
			var border = ColorRect.new()
			border.custom_minimum_size = cell_size - Vector2(2, 2)
			border.size = cell_size - Vector2(2, 2)
			border.position = cell_pos + Vector2(1, 1)
			border.color = Color(0.15, 0.18, 0.25, 0.9)
			cells_container.add_child(border)

			# Main cell background
			var cell = ColorRect.new()
			cell.custom_minimum_size = cell_size - Vector2(6, 6)
			cell.size = cell_size - Vector2(6, 6)
			cell.position = cell_pos + Vector2(3, 3)
			# Alternate colors for checkerboard pattern
			if (x + y) % 2 == 0:
				cell.color = Color(0.22, 0.26, 0.32, 0.85)
			else:
				cell.color = Color(0.18, 0.22, 0.28, 0.85)
			cells_container.add_child(cell)

			# Inner highlight (top-left shine)
			var shine = ColorRect.new()
			shine.custom_minimum_size = Vector2(cell_size.x - 12, 3)
			shine.size = Vector2(cell_size.x - 12, 3)
			shine.position = cell_pos + Vector2(6, 5)
			shine.color = Color(1, 1, 1, 0.08)
			cells_container.add_child(shine)

func _create_buildings() -> void:
	buildings.clear()
	for x in range(GameManager.grid_size.x):
		var column: Array = []
		for y in range(GameManager.grid_size.y):
			var building = building_scene.instantiate()
			building.position = _grid_to_pixel(Vector2i(x, y))
			building.custom_minimum_size = cell_size - cell_padding * 2
			building.size = cell_size - cell_padding * 2
			building.position += cell_padding
			building.grid_position = Vector2i(x, y)
			building.visible = false

			building.drag_started.connect(_on_building_drag_started)
			building.drag_ended.connect(_on_building_drag_ended)

			buildings_container.add_child(building)
			column.append(building)
		buildings.append(column)

func _sync_with_game_manager() -> void:
	for x in range(GameManager.grid_size.x):
		for y in range(GameManager.grid_size.y):
			var level: int = GameManager.grid[x][y]
			buildings[x][y].setup(level, Vector2i(x, y))

func _grid_to_pixel(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * cell_size.x, grid_pos.y * cell_size.y)

func _pixel_to_grid(pixel_pos: Vector2) -> Vector2i:
	var x = int(pixel_pos.x / cell_size.x)
	var y = int(pixel_pos.y / cell_size.y)
	return Vector2i(
		clamp(x, 0, GameManager.grid_size.x - 1),
		clamp(y, 0, GameManager.grid_size.y - 1)
	)

func _on_building_drag_started(building) -> void:
	dragged_building = building
	if highlight:
		highlight.visible = true

func _on_building_drag_ended(building) -> void:
	if highlight:
		highlight.visible = false

	if dragged_building == null:
		return

	# Find the target cell
	var drop_pos = building.position + building.size / 2
	var target_grid_pos = _pixel_to_grid(drop_pos)

	# Check if we're dropping on a different cell
	if target_grid_pos != building.grid_position:
		var target_building = buildings[target_grid_pos.x][target_grid_pos.y]
		var target_level: int = GameManager.get_building_at(target_grid_pos)
		var source_level: int = building.building_level

		# Check if we can merge
		if GameManager.can_merge(source_level, target_level):
			_perform_merge(building, target_building)
		elif target_level == 0:
			# Move to empty cell
			_move_building(building, target_grid_pos)
			AudioManager.play_drop()
		else:
			# Can't merge, return to original position
			AudioManager.play_error()
			building.reset_position()
	else:
		AudioManager.play_drop()
		building.reset_position()

	dragged_building = null

func _perform_merge(source, target) -> void:
	var new_level: int = GameManager.merge_result(source.building_level)
	var merge_color: Color = source.get_building_color()
	var merge_position: Vector2 = target.get_center_position()

	# Clear source position in game manager
	GameManager.clear_building_at(source.grid_position)

	# Update target with new level
	GameManager.set_building_at(target.grid_position, new_level)

	# Update visuals
	source.setup(0, source.grid_position)
	source.position = _grid_to_pixel(source.grid_position) + cell_padding

	target.setup(new_level, target.grid_position)
	target.animate_merge()

	# Play merge sound
	AudioManager.play_merge()

	# Create particle effects
	ParticleEffects.create_merge_particles(self, merge_position, merge_color)
	ParticleEffects.create_coin_particles(self, merge_position, 3)

	# Show level up text
	var data = GameManager.building_data.get(new_level, {})
	var building_name = data.get("name", "Building")
	ParticleEffects.create_level_up_text(self, merge_position - Vector2(40, 30), new_level, building_name)

	# Notify quest manager
	QuestManager.on_merge_completed(new_level)

	merge_completed.emit(new_level)

func _move_building(source, target_pos: Vector2i) -> void:
	var level: int = source.building_level
	var old_pos: Vector2i = source.grid_position

	# Update game manager
	GameManager.clear_building_at(old_pos)
	GameManager.set_building_at(target_pos, level)

	# Update building references
	var target_building = buildings[target_pos.x][target_pos.y]

	# Swap in array
	buildings[old_pos.x][old_pos.y] = target_building
	buildings[target_pos.x][target_pos.y] = source

	# Update positions and grid positions
	source.grid_position = target_pos
	source.position = _grid_to_pixel(target_pos) + cell_padding

	target_building.grid_position = old_pos
	target_building.position = _grid_to_pixel(old_pos) + cell_padding

func _process(_delta: float) -> void:
	if dragged_building and highlight:
		var mouse_pos = get_local_mouse_position()
		var grid_pos = _pixel_to_grid(mouse_pos)

		highlight.position = _grid_to_pixel(grid_pos)
		highlight.size = cell_size

		# Color based on whether merge is possible
		var target_level = GameManager.get_building_at(grid_pos)
		if GameManager.can_merge(dragged_building.building_level, target_level):
			highlight.color = Color(0, 1, 0, 0.3)  # Green = can merge
		elif target_level == 0:
			highlight.color = Color(0, 0.5, 1, 0.3)  # Blue = empty
		else:
			highlight.color = Color(1, 0, 0, 0.3)  # Red = can't merge

func spawn_new_building() -> bool:
	if GameManager.spawn_building():
		_sync_with_game_manager()
		# Find the newly spawned building and animate it
		for x in range(GameManager.grid_size.x):
			for y in range(GameManager.grid_size.y):
				var building = buildings[x][y]
				if building.building_level > 0 and building.scale == Vector2.ZERO:
					building.animate_spawn()
					# Add spawn effect
					var spawn_pos = building.position
					ParticleEffects.create_spawn_effect(self, spawn_pos, building.size)

		# Play spawn sound
		AudioManager.play_spawn()

		# Notify quest manager
		QuestManager.on_building_spawned()
		return true
	return false

func refresh_grid() -> void:
	_sync_with_game_manager()
