extends Node
## GameManager - Handles global game state, currency, and energy

signal coins_changed(new_amount: int)
signal energy_changed(new_amount: int)
signal building_unlocked(building_level: int)

# Currency
var coins: int = 0:
	set(value):
		coins = max(0, value)
		coins_changed.emit(coins)

# Energy system
var energy: int = 10:
	set(value):
		energy = clamp(value, 0, max_energy)
		energy_changed.emit(energy)

var max_energy: int = 10
var energy_regen_time: float = 30.0  # seconds per energy point
var _energy_timer: float = 0.0

# Building definitions
var building_data: Dictionary = {
	1: {"name": "Tent", "coins_per_sec": 0.1, "color": Color("#8D6E63")},
	2: {"name": "Hut", "coins_per_sec": 0.3, "color": Color("#A1887F")},
	3: {"name": "Cabin", "coins_per_sec": 0.8, "color": Color("#795548")},
	4: {"name": "House", "coins_per_sec": 2.0, "color": Color("#5D4037")},
	5: {"name": "Villa", "coins_per_sec": 5.0, "color": Color("#4CAF50")},
	6: {"name": "Mansion", "coins_per_sec": 12.0, "color": Color("#2196F3")},
	7: {"name": "Tower", "coins_per_sec": 30.0, "color": Color("#9C27B0")},
	8: {"name": "Skyscraper", "coins_per_sec": 75.0, "color": Color("#F44336")},
	9: {"name": "Monument", "coins_per_sec": 200.0, "color": Color("#FFD700")},
	10: {"name": "Wonder", "coins_per_sec": 500.0, "color": Color("#E91E63")},
}

var max_building_level: int = 10
var highest_unlocked_level: int = 1

# Grid state
var grid_size: Vector2i = Vector2i(4, 5)
var grid: Array = []  # 2D array of building levels (0 = empty)

# Fractional coin accumulator (for smooth generation)
var _coin_accumulator: float = 0.0

func _ready() -> void:
	_initialize_grid()
	# Start with some coins
	coins = 100

func _process(delta: float) -> void:
	_process_energy_regen(delta)
	_process_coin_generation(delta)

func _initialize_grid() -> void:
	grid.clear()
	for x in range(grid_size.x):
		var column: Array = []
		for y in range(grid_size.y):
			column.append(0)
		grid.append(column)

func _process_energy_regen(delta: float) -> void:
	if energy < max_energy:
		_energy_timer += delta
		if _energy_timer >= energy_regen_time:
			_energy_timer = 0.0
			energy += 1

func _process_coin_generation(delta: float) -> void:
	var coins_to_add: float = 0.0
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var level: int = grid[x][y]
			if level > 0 and building_data.has(level):
				coins_to_add += building_data[level]["coins_per_sec"] * delta

	if coins_to_add > 0:
		# Accumulate fractional coins
		_coin_accumulator += coins_to_add
		# Only add whole coins to prevent precision issues
		if _coin_accumulator >= 1.0:
			var whole_coins = int(_coin_accumulator)
			coins += whole_coins
			_coin_accumulator -= whole_coins

func get_building_at(pos: Vector2i) -> int:
	if _is_valid_position(pos):
		return grid[pos.x][pos.y]
	return -1

func set_building_at(pos: Vector2i, level: int) -> void:
	if _is_valid_position(pos):
		grid[pos.x][pos.y] = level
		if level > highest_unlocked_level:
			highest_unlocked_level = level
			building_unlocked.emit(level)

func clear_building_at(pos: Vector2i) -> void:
	if _is_valid_position(pos):
		grid[pos.x][pos.y] = 0

func can_merge(level1: int, level2: int) -> bool:
	return level1 == level2 and level1 > 0 and level1 < max_building_level

func merge_result(level: int) -> int:
	if level < max_building_level:
		return level + 1
	return level

func spawn_building() -> bool:
	if energy <= 0:
		return false

	var empty_positions: Array = []
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			if grid[x][y] == 0:
				empty_positions.append(Vector2i(x, y))

	if empty_positions.is_empty():
		return false

	energy -= 1
	var pos: Vector2i = empty_positions[randi() % empty_positions.size()]
	# Spawn level 1 (tent) mostly, sometimes level 2
	var spawn_level: int = 1 if randf() > 0.2 else 2
	set_building_at(pos, spawn_level)
	return true

func _is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y

func get_coins_per_second() -> float:
	var total: float = 0.0
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var level: int = grid[x][y]
			if level > 0 and building_data.has(level):
				total += building_data[level]["coins_per_sec"]
	return total
