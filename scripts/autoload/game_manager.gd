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

# Building definitions - 14 levels with Wonder as the ultimate
var building_data: Dictionary = {
	1: {"name": "Tent", "coins_per_sec": 0.1, "color": Color("#8D6E63")},
	2: {"name": "Hut", "coins_per_sec": 0.3, "color": Color("#A1887F")},
	3: {"name": "Cabin", "coins_per_sec": 0.7, "color": Color("#795548")},
	4: {"name": "Cottage", "coins_per_sec": 1.5, "color": Color("#6D4C41")},
	5: {"name": "House", "coins_per_sec": 3.0, "color": Color("#5D4037")},
	6: {"name": "Villa", "coins_per_sec": 6.0, "color": Color("#4CAF50")},
	7: {"name": "Mansion", "coins_per_sec": 12.0, "color": Color("#2196F3")},
	8: {"name": "Tower", "coins_per_sec": 25.0, "color": Color("#9C27B0")},
	9: {"name": "Skyscraper", "coins_per_sec": 50.0, "color": Color("#F44336")},
	10: {"name": "Castle", "coins_per_sec": 100.0, "color": Color("#607D8B")},
	11: {"name": "Palace", "coins_per_sec": 200.0, "color": Color("#00BCD4")},
	12: {"name": "Citadel", "coins_per_sec": 400.0, "color": Color("#FF5722")},
	13: {"name": "Monument", "coins_per_sec": 800.0, "color": Color("#FFD700")},
	14: {"name": "Wonder", "coins_per_sec": 2000.0, "color": Color("#E91E63")},
}

var max_building_level: int = 14
var highest_unlocked_level: int = 1

# Grid state
var grid_size: Vector2i = Vector2i(5, 6)
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
		# Apply energy regen multiplier from IAP boost (x2 = twice as fast)
		var regen_multiplier: float = 1.0
		if IAPManager:
			regen_multiplier = IAPManager.get_energy_regen_multiplier()
		_energy_timer += delta * regen_multiplier
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
		# Apply multipliers from upgrades and bonuses
		var coin_multiplier: float = 1.0
		if ShopManager:
			coin_multiplier *= ShopManager.get_coin_multiplier()
		if DailyRewardManager:
			coin_multiplier *= DailyRewardManager.get_active_coin_bonus()
		if IAPManager:
			coin_multiplier *= IAPManager.get_coin_multiplier()

		coins_to_add *= coin_multiplier

		# Accumulate fractional coins
		_coin_accumulator += coins_to_add
		# Only add whole coins to prevent precision issues
		if _coin_accumulator >= 1.0:
			var whole_coins = int(_coin_accumulator)
			coins += whole_coins
			_coin_accumulator -= whole_coins
			# Notify QuestManager of coins earned
			if QuestManager:
				QuestManager.on_coins_earned(whole_coins)

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
	if level1 <= 0 or level2 <= 0:
		return false
	return level1 == level2 and level1 < max_building_level

func merge_result(level: int) -> int:
	if level <= 0 or level >= max_building_level:
		return level
	var new_level: int = level + 1
	if ShopManager and ShopManager.roll_critical_merge():
		new_level = min(level + 2, max_building_level)
	return new_level

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

	# Use ShopManager's spawn level upgrade if available
	var spawn_level: int = 1
	if ShopManager:
		spawn_level = ShopManager.roll_spawn_level()
	else:
		# Fallback: Spawn level 1 mostly, sometimes level 2
		spawn_level = 1 if randf() > 0.2 else 2

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

	# Apply multipliers from upgrades and bonuses
	var coin_multiplier: float = 1.0
	if ShopManager:
		coin_multiplier *= ShopManager.get_coin_multiplier()
	if DailyRewardManager:
		coin_multiplier *= DailyRewardManager.get_active_coin_bonus()
	if IAPManager:
		coin_multiplier *= IAPManager.get_coin_multiplier()

	return total * coin_multiplier
