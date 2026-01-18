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
		# Audio settings
		"sfx_enabled": AudioManager.is_sfx_enabled(),
		"sfx_volume": AudioManager.get_sfx_volume(),
		# Quest progress
		"quest_total_builds": QuestManager.total_builds,
		"quest_total_merges": QuestManager.total_merges,
		"quest_total_coins_earned": QuestManager.total_coins_earned,
		"quest_highest_building": QuestManager.highest_building_level,
		"quest_completed_ids": QuestManager.completed_quest_ids,
		# Shop upgrades
		"shop_data": ShopManager.serialize(),
		# Daily rewards
		"daily_reward_data": DailyRewardManager.serialize(),
		# IAP data
		"iap_data": IAPManager.serialize(),
		# Ads data
		"ads_data": AdsManager.serialize(),
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved successfully")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, starting fresh")
		# Initialize daily rewards for new players
		DailyRewardManager.check_reward_availability()
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
		_handle_corrupted_save(json_string, json.get_error_message())
		return

	var save_data = json.get_data()
	if not save_data is Dictionary:
		_handle_corrupted_save(json_string, "Save data is not a valid dictionary")
		return

	# Restore game state
	GameManager.coins = save_data.get("coins", 0)
	GameManager.energy = save_data.get("energy", 10)
	GameManager.highest_unlocked_level = save_data.get("highest_unlocked_level", 1)

	# Restore grid
	var grid_data: Array = save_data.get("grid", [])
	_deserialize_grid(grid_data)

	# Restore audio settings
	if save_data.has("sfx_enabled"):
		if AudioManager.is_sfx_enabled() != save_data.get("sfx_enabled", true):
			AudioManager.toggle_sfx()
	if save_data.has("sfx_volume"):
		AudioManager.set_sfx_volume(save_data.get("sfx_volume", 0.7))

	# Restore quest progress
	if save_data.has("quest_total_builds"):
		QuestManager.total_builds = save_data.get("quest_total_builds", 0)
	if save_data.has("quest_total_merges"):
		QuestManager.total_merges = save_data.get("quest_total_merges", 0)
	if save_data.has("quest_total_coins_earned"):
		QuestManager.total_coins_earned = save_data.get("quest_total_coins_earned", 0)
	if save_data.has("quest_highest_building"):
		QuestManager.highest_building_level = save_data.get("quest_highest_building", 1)
	if save_data.has("quest_completed_ids"):
		QuestManager.completed_quest_ids = save_data.get("quest_completed_ids", [])
		# Regenerate quests with completed IDs loaded
		QuestManager._generate_quests()

	# Restore shop upgrades
	if save_data.has("shop_data"):
		ShopManager.deserialize(save_data.get("shop_data", {}))

	# Restore daily rewards
	if save_data.has("daily_reward_data"):
		DailyRewardManager.deserialize(save_data.get("daily_reward_data", {}))
	else:
		# If no save data, check availability for new players
		DailyRewardManager.check_reward_availability()

	# Restore IAP data
	if save_data.has("iap_data"):
		IAPManager.deserialize(save_data.get("iap_data", {}))

	# Restore Ads data
	if save_data.has("ads_data"):
		AdsManager.deserialize(save_data.get("ads_data", {}))

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

		# Use ShopManager's offline earnings multiplier
		var offline_efficiency: float = 0.5  # Default 50%
		if ShopManager:
			offline_efficiency = ShopManager.get_offline_earnings_multiplier()

		var offline_coins = int(coins_per_second * elapsed_seconds * offline_efficiency)

		if offline_coins > 0:
			GameManager.coins += offline_coins
			print("Earned ", offline_coins, " coins while away!")

func _handle_corrupted_save(json_string: String, error_msg: String) -> void:
	push_error("SAVE FILE CORRUPTED: " + error_msg)

	# Create backup of corrupted file
	var backup_path = SAVE_PATH.replace(".json", "_corrupted_%d.json" % int(Time.get_unix_time_from_system()))
	var backup_file = FileAccess.open(backup_path, FileAccess.WRITE)
	if backup_file:
		backup_file.store_string(json_string)
		backup_file.close()
		print("Corrupted save backed up to: ", backup_path)

	# Delete corrupted save so game can start fresh
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("Corrupted save removed. Starting fresh game.")

	# Initialize for new player
	DailyRewardManager.check_reward_availability()

func _notification(what: int) -> void:
	# Auto-save when app goes to background or closes
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()
