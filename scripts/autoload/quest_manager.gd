extends Node
## QuestManager - Handles quests/missions system

signal quest_ready_to_claim(quest: Dictionary)
signal quest_claimed(quest: Dictionary)
signal quest_progress_updated(quest_id: String, progress: int, target: int)
signal quests_refreshed
signal claimable_count_changed(count: int)

# Quest types
enum QuestType {
	BUILD_BUILDINGS,      # Build X buildings
	MERGE_TIMES,          # Merge X times
	REACH_BUILDING_LEVEL, # Get a building to level X
	EARN_COINS,           # Earn X coins total
	HAVE_BUILDINGS,       # Have X buildings of level Y on grid
}

# Active quests
var active_quests: Array = []
var completed_quest_ids: Array = []

# Stats for tracking
var total_merges: int = 0
var total_builds: int = 0
var total_coins_earned: int = 0
var highest_building_level: int = 1

# Quest definitions pool - Balanced for 14 building levels
var quest_pool: Array = [
	# BUILD quests - Early game
	{"id": "build_3", "type": QuestType.BUILD_BUILDINGS, "description": "Build 3 buildings", "target": 3, "reward_coins": 25, "reward_energy": 1},
	{"id": "build_5", "type": QuestType.BUILD_BUILDINGS, "description": "Build 5 buildings", "target": 5, "reward_coins": 40, "reward_energy": 1},
	{"id": "build_8", "type": QuestType.BUILD_BUILDINGS, "description": "Build 8 buildings", "target": 8, "reward_coins": 60, "reward_energy": 2},
	{"id": "build_12", "type": QuestType.BUILD_BUILDINGS, "description": "Build 12 buildings", "target": 12, "reward_coins": 90, "reward_energy": 2},
	{"id": "build_15", "type": QuestType.BUILD_BUILDINGS, "description": "Build 15 buildings", "target": 15, "reward_coins": 120, "reward_energy": 3},
	{"id": "build_20", "type": QuestType.BUILD_BUILDINGS, "description": "Build 20 buildings", "target": 20, "reward_coins": 160, "reward_energy": 3},
	{"id": "build_30", "type": QuestType.BUILD_BUILDINGS, "description": "Build 30 buildings", "target": 30, "reward_coins": 250, "reward_energy": 4},
	{"id": "build_50", "type": QuestType.BUILD_BUILDINGS, "description": "Build 50 buildings", "target": 50, "reward_coins": 400, "reward_energy": 5},
	{"id": "build_75", "type": QuestType.BUILD_BUILDINGS, "description": "Build 75 buildings", "target": 75, "reward_coins": 600, "reward_energy": 6},
	{"id": "build_100", "type": QuestType.BUILD_BUILDINGS, "description": "Build 100 buildings", "target": 100, "reward_coins": 800, "reward_energy": 8},

	# MERGE quests
	{"id": "merge_2", "type": QuestType.MERGE_TIMES, "description": "Merge 2 times", "target": 2, "reward_coins": 20, "reward_energy": 1},
	{"id": "merge_5", "type": QuestType.MERGE_TIMES, "description": "Merge 5 times", "target": 5, "reward_coins": 50, "reward_energy": 1},
	{"id": "merge_10", "type": QuestType.MERGE_TIMES, "description": "Merge 10 times", "target": 10, "reward_coins": 100, "reward_energy": 2},
	{"id": "merge_15", "type": QuestType.MERGE_TIMES, "description": "Merge 15 times", "target": 15, "reward_coins": 150, "reward_energy": 2},
	{"id": "merge_25", "type": QuestType.MERGE_TIMES, "description": "Merge 25 times", "target": 25, "reward_coins": 250, "reward_energy": 3},
	{"id": "merge_40", "type": QuestType.MERGE_TIMES, "description": "Merge 40 times", "target": 40, "reward_coins": 400, "reward_energy": 4},
	{"id": "merge_60", "type": QuestType.MERGE_TIMES, "description": "Merge 60 times", "target": 60, "reward_coins": 600, "reward_energy": 5},
	{"id": "merge_100", "type": QuestType.MERGE_TIMES, "description": "Merge 100 times", "target": 100, "reward_coins": 1000, "reward_energy": 8},

	# REACH LEVEL quests - All 14 levels
	{"id": "reach_level_2", "type": QuestType.REACH_BUILDING_LEVEL, "description": "Create a Hut (Lv.2)", "target": 2, "reward_coins": 30, "reward_energy": 1},
	{"id": "reach_level_3", "type": QuestType.REACH_BUILDING_LEVEL, "description": "Create a Cabin (Lv.3)", "target": 3, "reward_coins": 50, "reward_energy": 1},
	{"id": "reach_level_4", "type": QuestType.REACH_BUILDING_LEVEL, "description": "Create a Cottage (Lv.4)", "target": 4, "reward_coins": 80, "reward_energy": 2},
	{"id": "reach_level_5", "type": QuestType.REACH_BUILDING_LEVEL, "description": "Create a House (Lv.5)", "target": 5, "reward_coins": 120, "reward_energy": 2},
	{"id": "reach_level_6", "type": QuestType.REACH_BUILDING_LEVEL, "description": "Create a Villa (Lv.6)", "target": 6, "reward_coins": 200, "reward_energy": 3},
	{"id": "reach_level_7", "type": QuestType.REACH_BUILDING_LEVEL, "description": "Create a Mansion (Lv.7)", "target": 7, "reward_coins": 350, "reward_energy": 4},
	{"id": "reach_level_8", "type": QuestType.REACH_BUILDING_LEVEL, "description": "Create a Tower (Lv.8)", "target": 8, "reward_coins": 600, "reward_energy": 5},
	{"id": "reach_level_9", "type": QuestType.REACH_BUILDING_LEVEL, "description": "Create a Skyscraper (Lv.9)", "target": 9, "reward_coins": 1000, "reward_energy": 6},
	{"id": "reach_level_10", "type": QuestType.REACH_BUILDING_LEVEL, "description": "Create a Castle (Lv.10)", "target": 10, "reward_coins": 1800, "reward_energy": 8},
	{"id": "reach_level_11", "type": QuestType.REACH_BUILDING_LEVEL, "description": "Create a Palace (Lv.11)", "target": 11, "reward_coins": 3000, "reward_energy": 10},
	{"id": "reach_level_12", "type": QuestType.REACH_BUILDING_LEVEL, "description": "Create a Citadel (Lv.12)", "target": 12, "reward_coins": 5000, "reward_energy": 12},
	{"id": "reach_level_13", "type": QuestType.REACH_BUILDING_LEVEL, "description": "Create a Monument (Lv.13)", "target": 13, "reward_coins": 8000, "reward_energy": 15},
	{"id": "reach_level_14", "type": QuestType.REACH_BUILDING_LEVEL, "description": "Create a Wonder (Lv.14)", "target": 14, "reward_coins": 15000, "reward_energy": 20},

	# EARN COINS quests - Progressive
	{"id": "earn_100", "type": QuestType.EARN_COINS, "description": "Earn 100 coins", "target": 100, "reward_coins": 25, "reward_energy": 1},
	{"id": "earn_250", "type": QuestType.EARN_COINS, "description": "Earn 250 coins", "target": 250, "reward_coins": 60, "reward_energy": 1},
	{"id": "earn_500", "type": QuestType.EARN_COINS, "description": "Earn 500 coins", "target": 500, "reward_coins": 120, "reward_energy": 2},
	{"id": "earn_1000", "type": QuestType.EARN_COINS, "description": "Earn 1,000 coins", "target": 1000, "reward_coins": 250, "reward_energy": 2},
	{"id": "earn_2000", "type": QuestType.EARN_COINS, "description": "Earn 2,000 coins", "target": 2000, "reward_coins": 500, "reward_energy": 3},
	{"id": "earn_5000", "type": QuestType.EARN_COINS, "description": "Earn 5,000 coins", "target": 5000, "reward_coins": 1200, "reward_energy": 5},
	{"id": "earn_10000", "type": QuestType.EARN_COINS, "description": "Earn 10,000 coins", "target": 10000, "reward_coins": 2500, "reward_energy": 8},
	{"id": "earn_25000", "type": QuestType.EARN_COINS, "description": "Earn 25,000 coins", "target": 25000, "reward_coins": 6000, "reward_energy": 12},

	# HAVE BUILDINGS quests - Various levels
	{"id": "have_3_tents", "type": QuestType.HAVE_BUILDINGS, "description": "Have 3 Tents", "target": 3, "target_level": 1, "reward_coins": 20, "reward_energy": 1},
	{"id": "have_4_huts", "type": QuestType.HAVE_BUILDINGS, "description": "Have 4 Huts", "target": 4, "target_level": 2, "reward_coins": 50, "reward_energy": 1},
	{"id": "have_3_cabins", "type": QuestType.HAVE_BUILDINGS, "description": "Have 3 Cabins", "target": 3, "target_level": 3, "reward_coins": 80, "reward_energy": 2},
	{"id": "have_2_cottages", "type": QuestType.HAVE_BUILDINGS, "description": "Have 2 Cottages", "target": 2, "target_level": 4, "reward_coins": 100, "reward_energy": 2},
	{"id": "have_3_houses", "type": QuestType.HAVE_BUILDINGS, "description": "Have 3 Houses", "target": 3, "target_level": 5, "reward_coins": 180, "reward_energy": 3},
	{"id": "have_2_villas", "type": QuestType.HAVE_BUILDINGS, "description": "Have 2 Villas", "target": 2, "target_level": 6, "reward_coins": 250, "reward_energy": 3},
	{"id": "have_2_mansions", "type": QuestType.HAVE_BUILDINGS, "description": "Have 2 Mansions", "target": 2, "target_level": 7, "reward_coins": 400, "reward_energy": 4},
	{"id": "have_2_towers", "type": QuestType.HAVE_BUILDINGS, "description": "Have 2 Towers", "target": 2, "target_level": 8, "reward_coins": 700, "reward_energy": 5},
	{"id": "have_2_skyscrapers", "type": QuestType.HAVE_BUILDINGS, "description": "Have 2 Skyscrapers", "target": 2, "target_level": 9, "reward_coins": 1200, "reward_energy": 7},
	{"id": "have_2_castles", "type": QuestType.HAVE_BUILDINGS, "description": "Have 2 Castles", "target": 2, "target_level": 10, "reward_coins": 2000, "reward_energy": 10},
]

const MAX_ACTIVE_QUESTS = 3

func _ready() -> void:
	# Generate initial quests
	_generate_quests()

func _generate_quests() -> void:
	active_quests.clear()

	# Get available quests (not completed)
	var available = quest_pool.filter(func(q): return q.id not in completed_quest_ids)

	# Shuffle and pick MAX_ACTIVE_QUESTS
	available.shuffle()

	for i in range(min(MAX_ACTIVE_QUESTS, available.size())):
		var quest = available[i].duplicate(true)
		quest["progress"] = 0
		quest["completed"] = false
		active_quests.append(quest)

	quests_refreshed.emit()

func on_building_spawned() -> void:
	total_builds += 1
	_update_quests_of_type(QuestType.BUILD_BUILDINGS, total_builds)

func on_merge_completed(new_level: int) -> void:
	total_merges += 1
	_update_quests_of_type(QuestType.MERGE_TIMES, total_merges)

	if new_level > highest_building_level:
		highest_building_level = new_level
		_update_quests_of_type(QuestType.REACH_BUILDING_LEVEL, new_level)

	# Check HAVE_BUILDINGS quests
	_check_have_buildings_quests()

func on_coins_earned(amount: int) -> void:
	total_coins_earned += amount
	_update_quests_of_type(QuestType.EARN_COINS, total_coins_earned)

func _check_have_buildings_quests() -> void:
	for quest in active_quests:
		if quest.type == QuestType.HAVE_BUILDINGS and not quest.completed:
			var target_level = quest.get("target_level", 1)
			var count = _count_buildings_of_level(target_level)
			quest.progress = count
			quest_progress_updated.emit(quest.id, count, quest.target)

			if count >= quest.target:
				_complete_quest(quest)

func _count_buildings_of_level(level: int) -> int:
	var count = 0
	for x in range(GameManager.grid_size.x):
		for y in range(GameManager.grid_size.y):
			if GameManager.grid[x][y] == level:
				count += 1
	return count

func _update_quests_of_type(type: QuestType, value: int) -> void:
	for quest in active_quests:
		if quest.type == type and not quest.completed:
			if type == QuestType.BUILD_BUILDINGS:
				quest.progress = total_builds
			elif type == QuestType.MERGE_TIMES:
				quest.progress = total_merges
			elif type == QuestType.EARN_COINS:
				quest.progress = total_coins_earned
			elif type == QuestType.REACH_BUILDING_LEVEL:
				quest.progress = highest_building_level

			quest_progress_updated.emit(quest.id, quest.progress, quest.target)

			if quest.progress >= quest.target:
				_complete_quest(quest)

func _complete_quest(quest: Dictionary) -> void:
	if quest.get("ready_to_claim", false) or quest.get("claimed", false):
		return

	quest["ready_to_claim"] = true
	quest_ready_to_claim.emit(quest)
	claimable_count_changed.emit(get_claimable_count())
	quests_refreshed.emit()

# Claim a completed quest and get rewards
func claim_quest(quest_id: String) -> bool:
	for quest in active_quests:
		if quest.id == quest_id and quest.get("ready_to_claim", false):
			quest["ready_to_claim"] = false
			quest["claimed"] = true
			completed_quest_ids.append(quest.id)

			# Give rewards
			GameManager.coins += quest.reward_coins
			GameManager.energy = min(GameManager.energy + quest.reward_energy, GameManager.max_energy)

			quest_claimed.emit(quest)
			AudioManager.play_quest_complete()

			claimable_count_changed.emit(get_claimable_count())

			# Replace claimed quest with a new one
			call_deferred("_replace_completed_quest", quest)
			return true
	return false

# Get number of quests ready to claim
func get_claimable_count() -> int:
	var count = 0
	for quest in active_quests:
		if quest.get("ready_to_claim", false):
			count += 1
	return count

# Check if any quest is ready to claim
func has_claimable_quests() -> bool:
	return get_claimable_count() > 0

func _replace_completed_quest(completed_quest: Dictionary) -> void:
	# Remove completed quest
	active_quests.erase(completed_quest)

	# Find a new quest
	var available = quest_pool.filter(func(q):
		return q.id not in completed_quest_ids and not active_quests.any(func(aq): return aq.id == q.id)
	)

	if available.size() > 0:
		available.shuffle()
		var new_quest = available[0].duplicate(true)
		new_quest["progress"] = 0
		new_quest["completed"] = false

		# Set initial progress based on type
		match new_quest.type:
			QuestType.BUILD_BUILDINGS:
				new_quest.progress = total_builds
			QuestType.MERGE_TIMES:
				new_quest.progress = total_merges
			QuestType.EARN_COINS:
				new_quest.progress = total_coins_earned
			QuestType.REACH_BUILDING_LEVEL:
				new_quest.progress = highest_building_level

		active_quests.append(new_quest)

	quests_refreshed.emit()

func get_active_quests() -> Array:
	return active_quests

func reset_daily_quests() -> void:
	completed_quest_ids.clear()
	total_builds = 0
	total_merges = 0
	total_coins_earned = 0
	_generate_quests()
