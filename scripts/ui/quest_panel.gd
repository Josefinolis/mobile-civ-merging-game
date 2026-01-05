extends PanelContainer
## QuestPanel - Collapsible panel showing active quests

signal quest_claimed(quest: Dictionary)

@onready var quests_container: VBoxContainer = $MarginContainer/VBox/QuestsContainer
@onready var title_button: Button = $MarginContainer/VBox/TitleBar/TitleButton
@onready var collapse_icon: Label = $MarginContainer/VBox/TitleBar/CollapseIcon

var is_expanded: bool = false
var quest_items: Dictionary = {}

func _ready() -> void:
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_progress_updated.connect(_on_quest_progress_updated)
	QuestManager.quests_refreshed.connect(_refresh_quests)

	if title_button:
		title_button.pressed.connect(_toggle_panel)

	# Start collapsed
	_set_expanded(false)
	_refresh_quests()

func _toggle_panel() -> void:
	_set_expanded(!is_expanded)

func _set_expanded(expanded: bool) -> void:
	is_expanded = expanded
	if quests_container:
		quests_container.visible = expanded
	if collapse_icon:
		collapse_icon.text = "v" if expanded else ">"

	# Animate the panel
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	if expanded:
		tween.tween_property(self, "custom_minimum_size:y", 160, 0.2)
	else:
		tween.tween_property(self, "custom_minimum_size:y", 35, 0.2)

func _refresh_quests() -> void:
	# Update title with quest count
	var active_count = QuestManager.get_active_quests().size()
	var completed_count = QuestManager.get_active_quests().filter(func(q): return q.completed).size()
	if title_button:
		if completed_count > 0:
			title_button.text = "QUESTS (%d/%d)" % [completed_count, active_count]
		else:
			title_button.text = "QUESTS (%d)" % active_count

	# Clear existing quest items
	for child in quests_container.get_children():
		child.queue_free()
	quest_items.clear()

	# Add quest items
	for quest in QuestManager.get_active_quests():
		var quest_item = _create_quest_item(quest)
		quests_container.add_child(quest_item)
		quest_items[quest.id] = quest_item

func _create_quest_item(quest: Dictionary) -> Control:
	var item = HBoxContainer.new()
	item.name = quest.id
	item.add_theme_constant_override("separation", 8)

	# Progress indicator (circle)
	var progress_circle = Label.new()
	progress_circle.name = "Circle"
	if quest.completed:
		progress_circle.text = "[OK]"
		progress_circle.add_theme_color_override("font_color", Color.GREEN)
	else:
		var percent = float(quest.progress) / float(quest.target) * 100
		progress_circle.text = "[%d%%]" % percent
		progress_circle.add_theme_color_override("font_color", Color.YELLOW)
	progress_circle.add_theme_font_size_override("font_size", 10)
	item.add_child(progress_circle)

	# Description (shortened)
	var desc_label = Label.new()
	desc_label.name = "Desc"
	desc_label.text = _shorten_description(quest.description)
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color.WHITE if not quest.completed else Color.GREEN)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(desc_label)

	# Reward
	var reward_label = Label.new()
	reward_label.name = "Reward"
	reward_label.text = "+%d" % quest.reward_coins
	reward_label.add_theme_font_size_override("font_size", 10)
	reward_label.add_theme_color_override("font_color", Color.GOLD)
	item.add_child(reward_label)

	return item

func _shorten_description(desc: String) -> String:
	# Shorten common phrases
	desc = desc.replace("buildings", "bldgs")
	desc = desc.replace("building", "bldg")
	desc = desc.replace("Create a ", "Get ")
	desc = desc.replace("Build ", "")
	desc = desc.replace("Merge ", "Merge ")
	desc = desc.replace("Earn ", "Earn ")
	if desc.length() > 25:
		desc = desc.substr(0, 22) + "..."
	return desc

func _on_quest_completed(quest: Dictionary) -> void:
	_refresh_quests()
	_show_completion_effect(quest)

	# Flash the title button
	if title_button:
		var tween = title_button.create_tween()
		tween.tween_property(title_button, "modulate", Color.GREEN, 0.1)
		tween.tween_property(title_button, "modulate", Color.WHITE, 0.3)

func _on_quest_progress_updated(quest_id: String, progress: int, target: int) -> void:
	if quest_items.has(quest_id):
		var item = quest_items[quest_id]
		var circle = item.get_node_or_null("Circle")
		if circle:
			var percent = float(min(progress, target)) / float(target) * 100
			circle.text = "[%d%%]" % percent

func _show_completion_effect(quest: Dictionary) -> void:
	# Create floating completion text at panel position
	var label = Label.new()
	label.text = "+%d +%d" % [quest.reward_coins, quest.reward_energy]
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.GOLD)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.position = Vector2(size.x - 60, 5)
	label.z_index = 300
	add_child(label)

	var tween = label.create_tween()
	tween.tween_property(label, "position:y", -20, 0.8).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.tween_callback(label.queue_free)
