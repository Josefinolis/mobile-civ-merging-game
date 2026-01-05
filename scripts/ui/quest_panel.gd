extends PanelContainer
class_name QuestPanel
## QuestPanel - Displays active quests and their progress

signal quest_claimed(quest: Dictionary)

@onready var quests_container: VBoxContainer = $MarginContainer/VBox/QuestsContainer
@onready var title_label: Label = $MarginContainer/VBox/TitleBar/Title

var quest_item_scene: PackedScene

func _ready() -> void:
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_progress_updated.connect(_on_quest_progress_updated)
	QuestManager.quests_refreshed.connect(_refresh_quests)

	_refresh_quests()

func _refresh_quests() -> void:
	# Clear existing quest items
	for child in quests_container.get_children():
		child.queue_free()

	# Add quest items
	for quest in QuestManager.get_active_quests():
		var quest_item = _create_quest_item(quest)
		quests_container.add_child(quest_item)

func _create_quest_item(quest: Dictionary) -> Control:
	var item = PanelContainer.new()
	item.name = quest.id

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	item.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	item.add_child(vbox)

	# Description
	var desc_label = Label.new()
	desc_label.text = quest.description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(desc_label)

	# Progress bar container
	var progress_hbox = HBoxContainer.new()
	progress_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(progress_hbox)

	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size = Vector2(150, 16)
	progress_bar.max_value = quest.target
	progress_bar.value = min(quest.progress, quest.target)
	progress_bar.show_percentage = false
	progress_hbox.add_child(progress_bar)

	# Progress text
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "%d/%d" % [min(quest.progress, quest.target), quest.target]
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	progress_hbox.add_child(progress_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_hbox.add_child(spacer)

	# Reward display
	var reward_label = Label.new()
	reward_label.text = "+%d coins, +%d energy" % [quest.reward_coins, quest.reward_energy]
	reward_label.add_theme_font_size_override("font_size", 11)
	reward_label.add_theme_color_override("font_color", Color.GOLD)
	progress_hbox.add_child(reward_label)

	# If completed, show differently
	if quest.completed:
		style.bg_color = Color(0.1, 0.3, 0.1, 0.9)
		desc_label.add_theme_color_override("font_color", Color.GREEN)
		progress_label.text = "COMPLETE!"
		progress_label.add_theme_color_override("font_color", Color.GREEN)

	return item

func _on_quest_completed(quest: Dictionary) -> void:
	_refresh_quests()

	# Animate the completion
	_show_completion_effect(quest)

func _on_quest_progress_updated(quest_id: String, progress: int, target: int) -> void:
	# Find and update the specific quest item
	for child in quests_container.get_children():
		if child.name == quest_id:
			var progress_bar = child.find_child("ProgressBar", true, false)
			var progress_label = child.find_child("ProgressLabel", true, false)

			if progress_bar:
				# Animate progress bar
				var tween = progress_bar.create_tween()
				tween.tween_property(progress_bar, "value", min(progress, target), 0.3)

			if progress_label:
				progress_label.text = "%d/%d" % [min(progress, target), target]
			break

func _show_completion_effect(quest: Dictionary) -> void:
	# Create floating completion text
	var label = Label.new()
	label.text = "Quest Complete! +%d coins +%d energy" % [quest.reward_coins, quest.reward_energy]
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.GOLD)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(size.x / 2 - 100, -30)
	label.z_index = 300
	add_child(label)

	var tween = label.create_tween()
	tween.tween_property(label, "position:y", -60, 1.0).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_callback(label.queue_free)
