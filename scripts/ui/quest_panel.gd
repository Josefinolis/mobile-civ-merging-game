extends PanelContainer
## QuestPanel - Collapsible panel showing active quests

signal quest_claimed_signal(quest: Dictionary)

@onready var quests_container: VBoxContainer = $MarginContainer/VBox/QuestsContainer
@onready var title_button: Button = $MarginContainer/VBox/TitleBar/TitleButton
@onready var collapse_icon: Label = $MarginContainer/VBox/TitleBar/CollapseIcon
var alert_icon: Label = null

var is_expanded: bool = false
var quest_items: Dictionary = {}

func _ready() -> void:
	QuestManager.quest_ready_to_claim.connect(_on_quest_ready_to_claim)
	QuestManager.quest_claimed.connect(_on_quest_claimed)
	QuestManager.quest_progress_updated.connect(_on_quest_progress_updated)
	QuestManager.quests_refreshed.connect(_refresh_quests)
	QuestManager.claimable_count_changed.connect(_update_alert_icon)

	if title_button:
		title_button.pressed.connect(_toggle_panel)

	# Create alert icon if not exists
	_create_alert_icon()

	# Start collapsed
	_set_expanded(false)
	_refresh_quests()
	_update_alert_icon(QuestManager.get_claimable_count())

func _create_alert_icon() -> void:
	if alert_icon:
		return
	# Find or create alert icon in title bar
	var title_bar = $MarginContainer/VBox/TitleBar
	if title_bar:
		alert_icon = Label.new()
		alert_icon.name = "AlertIcon"
		alert_icon.text = "!"
		alert_icon.add_theme_font_size_override("font_size", 24)
		alert_icon.add_theme_color_override("font_color", Color.RED)
		alert_icon.add_theme_constant_override("outline_size", 3)
		alert_icon.add_theme_color_override("font_outline_color", Color.WHITE)
		alert_icon.visible = false
		title_bar.add_child(alert_icon)
		title_bar.move_child(alert_icon, 0)

func _update_alert_icon(count: int) -> void:
	if alert_icon:
		alert_icon.visible = count > 0
		if count > 0:
			# Pulse animation
			var tween = alert_icon.create_tween().set_loops()
			tween.tween_property(alert_icon, "scale", Vector2(1.3, 1.3), 0.4)
			tween.tween_property(alert_icon, "scale", Vector2(1.0, 1.0), 0.4)

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
		tween.tween_property(self, "custom_minimum_size:y", 200, 0.2)
	else:
		tween.tween_property(self, "custom_minimum_size:y", 50, 0.2)

func _refresh_quests() -> void:
	# Update title with quest count
	var active_count = QuestManager.get_active_quests().size()
	var claimable_count = QuestManager.get_claimable_count()
	if title_button:
		if claimable_count > 0:
			title_button.text = "QUESTS (%d ready!)" % claimable_count
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

	var is_ready = quest.get("ready_to_claim", false)

	# Progress indicator (circle)
	var progress_circle = Label.new()
	progress_circle.name = "Circle"
	if is_ready:
		progress_circle.text = "[!!!]"
		progress_circle.add_theme_color_override("font_color", Color.LIME)
	else:
		var percent = float(quest.progress) / float(quest.target) * 100
		progress_circle.text = "[%d%%]" % int(percent)
		progress_circle.add_theme_color_override("font_color", Color.YELLOW)
	progress_circle.add_theme_font_size_override("font_size", 18)
	item.add_child(progress_circle)

	# Description (shortened)
	var desc_label = Label.new()
	desc_label.name = "Desc"
	desc_label.text = _shorten_description(quest.description)
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.add_theme_color_override("font_color", Color.LIME if is_ready else Color.WHITE)
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(desc_label)

	if is_ready:
		# Claim button
		var claim_btn = Button.new()
		claim_btn.name = "ClaimBtn"
		claim_btn.text = "CLAIM"
		claim_btn.add_theme_font_size_override("font_size", 16)
		claim_btn.custom_minimum_size = Vector2(70, 30)
		claim_btn.pressed.connect(_on_claim_pressed.bind(quest.id))
		# Style the button
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.8, 0.3)
		style.set_corner_radius_all(6)
		claim_btn.add_theme_stylebox_override("normal", style)
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.3, 0.9, 0.4)
		hover_style.set_corner_radius_all(6)
		claim_btn.add_theme_stylebox_override("hover", hover_style)
		item.add_child(claim_btn)
	else:
		# Reward preview
		var reward_label = Label.new()
		reward_label.name = "Reward"
		reward_label.text = "+%d" % quest.reward_coins
		reward_label.add_theme_font_size_override("font_size", 18)
		reward_label.add_theme_color_override("font_color", Color.GOLD)
		item.add_child(reward_label)

	return item

func _on_claim_pressed(quest_id: String) -> void:
	AudioManager.play_button_click()
	if QuestManager.claim_quest(quest_id):
		# Show reward effect will be triggered by signal
		pass

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

func _on_quest_ready_to_claim(quest: Dictionary) -> void:
	_refresh_quests()
	# Flash the title button to indicate a quest is ready
	if title_button:
		var tween = title_button.create_tween()
		tween.tween_property(title_button, "modulate", Color.LIME, 0.1)
		tween.tween_property(title_button, "modulate", Color.WHITE, 0.3)

func _on_quest_claimed(quest: Dictionary) -> void:
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
