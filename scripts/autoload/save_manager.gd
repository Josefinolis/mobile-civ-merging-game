extends Node
## SaveManager - Handles saving and loading game data

const SAVE_PATH = "user://savegame.json"

func _ready() -> void:
	# Load game on start
	call_deferred("load_game")

func save_game() -> void:
	var save_data: Dictionary = {
		"coins": GameManager.coins,
		"energy": GameManager.energy,
		"highest_unlocked_level": GameManager.highest_unlocked_level,
		"grid": _serialize_grid(),
		"timestamp": Time.get_unix_time_from_system(),
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved successfully")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, starting fresh")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		print("Could not open save file")
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("Error parsing save file: ", json.get_error_message())
		return

	var save_data: Dictionary = json.get_data()

	# Restore game state
	GameManager.coins = save_data.get("coins", 0)
	GameManager.energy = save_data.get("energy", 10)
	GameManager.highest_unlocked_level = save_data.get("highest_unlocked_level", 1)

	# Restore grid
	var grid_data: Array = save_data.get("grid", [])
	_deserialize_grid(grid_data)

	# Calculate offline earnings
	var saved_timestamp: float = save_data.get("timestamp", 0)
	if saved_timestamp > 0:
		_calculate_offline_earnings(saved_timestamp)

	print("Game loaded successfully")

func _serialize_grid() -> Array:
	var data: Array = []
	for x in range(GameManager.grid_size.x):
		var column: Array = []
		for y in range(GameManager.grid_size.y):
			column.append(GameManager.grid[x][y])
		data.append(column)
	return data

func _deserialize_grid(data: Array) -> void:
	if data.is_empty():
		return

	for x in range(min(data.size(), GameManager.grid_size.x)):
		for y in range(min(data[x].size(), GameManager.grid_size.y)):
			GameManager.grid[x][y] = data[x][y]

func _calculate_offline_earnings(saved_timestamp: float) -> void:
	var current_time = Time.get_unix_time_from_system()
	var elapsed_seconds = current_time - saved_timestamp

	# Cap offline earnings at 8 hours
	elapsed_seconds = min(elapsed_seconds, 8 * 60 * 60)

	if elapsed_seconds > 60:  # Only calculate if away for more than a minute
		var coins_per_second = GameManager.get_coins_per_second()
		var offline_coins = int(coins_per_second * elapsed_seconds * 0.5)  # 50% efficiency offline

		if offline_coins > 0:
			GameManager.coins += offline_coins
			print("Earned ", offline_coins, " coins while away!")

func _notification(what: int) -> void:
	# Auto-save when app goes to background or closes
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()
