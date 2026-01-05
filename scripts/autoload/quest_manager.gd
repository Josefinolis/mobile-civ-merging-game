extends Node
## QuestManager - Handles quests/missions system

signal quest_completed(quest: Dictionary)
signal quest_progress_updated(quest_id: String, progress: int, target: int)
signal quests_refreshed

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

# Quest definitions pool
var quest_pool: Array = [
	{
		"id": "build_5",
		"type": QuestType.BUILD_BUILDINGS,
		"description": "Build 5 new buildings",
		"target": 5,
		"reward_coins": 50,
		"reward_energy": 2
	},
	{
		"id": "build_10",
		"type": QuestType.BUILD_BUILDINGS,
		"description": "Build 10 new buildings",
		"target": 10,
		"reward_coins": 120,
		"reward_energy": 3
	},
	{
		"id": "merge_3",
		"type": QuestType.MERGE_TIMES,
		"description": "Merge buildings 3 times",
		"target": 3,
		"reward_coins": 30,
		"reward_energy": 1
	},
	{
		"id": "merge_10",
		"type": QuestType.MERGE_TIMES,
		"description": "Merge buildings 10 times",
		"target": 10,
		"reward_coins": 100,
		"reward_energy": 2
	},
	{
		"id": "merge_25",
		"type": QuestType.MERGE_TIMES,
		"description": "Merge buildings 25 times",
		"target": 25,
		"reward_coins": 300,
		"reward_energy": 5
	},
	{
		"id": "reach_level_3",
		"type": QuestType.REACH_BUILDING_LEVEL,
		"description": "Create a Cabin (Level 3)",
		"target": 3,
		"reward_coins": 80,
		"reward_energy": 2
	},
	{
		"id": "reach_level_4",
		"type": QuestType.REACH_BUILDING_LEVEL,
		"description": "Create a House (Level 4)",
		"target": 4,
		"reward_coins": 150,
		"reward_energy": 3
	},
	{
		"id": "reach_level_5",
		"type": QuestType.REACH_BUILDING_LEVEL,
		"description": "Create a Villa (Level 5)",
		"target": 5,
		"reward_coins": 300,
		"reward_energy": 5
	},
	{
		"id": "reach_level_6",
		"type": QuestType.REACH_BUILDING_LEVEL,
		"description": "Create a Mansion (Level 6)",
		"target": 6,
		"reward_coins": 500,
		"reward_energy": 7
	},
	{
		"id": "earn_500",
		"type": QuestType.EARN_COINS,
		"description": "Earn 500 coins",
		"target": 500,
		"reward_coins": 100,
		"reward_energy": 2
	},
	{
		"id": "earn_2000",
		"type": QuestType.EARN_COINS,
		"description": "Earn 2000 coins",
		"target": 2000,
		"reward_coins": 400,
		"reward_energy": 4
	},
	{
		"id": "have_3_huts",
		"type": QuestType.HAVE_BUILDINGS,
		"description": "Have 3 Huts on the grid",
		"target": 3,
		"target_level": 2,
		"reward_coins": 60,
		"reward_energy": 1
	},
	{
		"id": "have_2_cabins",
		"type": QuestType.HAVE_BUILDINGS,
		"description": "Have 2 Cabins on the grid",
		"target": 2,
		"target_level": 3,
		"reward_coins": 100,
		"reward_energy": 2
	},
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
	if quest.completed:
		return

	quest.completed = true
	completed_quest_ids.append(quest.id)

	# Give rewards
	GameManager.coins += quest.reward_coins
	GameManager.energy = min(GameManager.energy + quest.reward_energy, GameManager.max_energy)

	quest_completed.emit(quest)

	# Replace completed quest with a new one
	call_deferred("_replace_completed_quest", quest)

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
