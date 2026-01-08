extends Control
class_name UIManager
## UIManager - Handles all UI updates and user interactions

@onready var coins_label: Label = $TopBar/HBox/CoinsContainer/CoinsLabel
@onready var coins_title: Label = $TopBar/HBox/CoinsContainer/CoinsTitle
@onready var energy_label: Label = $TopBar/HBox/EnergyContainer/EnergyLabel
@onready var energy_title: Label = $TopBar/HBox/EnergyContainer/EnergyTitle
@onready var income_label: Label = $TopBar/HBox/IncomeContainer/IncomeLabel
@onready var income_title: Label = $TopBar/HBox/IncomeContainer/IncomeTitle
@onready var spawn_button: Button = $BottomBar/HBox/SpawnButton
@onready var shop_button: Button = $BottomBar/HBox/ShopButton
@onready var daily_reward_button: Button = $BottomBar/HBox/DailyRewardButton
@onready var iap_button: Button = $BottomBar/HBox/IAPButton
@onready var settings_button: Button = $TopBar/HBox/SettingsButton
@onready var top_bar: PanelContainer = $TopBar
@onready var bottom_bar: PanelContainer = $BottomBar
@onready var game_grid = $GridContainer/GameGrid
@onready var settings_panel = $SettingsPanel
@onready var shop_panel = $ShopPanel
@onready var daily_reward_panel = $DailyRewardPanel
@onready var iap_panel = $IAPPanel
@onready var settings_overlay: ColorRect = $SettingsOverlay
@onready var quest_panel: PanelContainer = $QuestPanel

var _coins_display: float = 0.0
var _active_panel: String = ""  # Track which panel is open
var _time: float = 0.0

func _ready() -> void:
	# Enhance UI with visual effects
	_enhance_ui()

	# Connect signals
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.energy_changed.connect(_on_energy_changed)
	GameManager.building_unlocked.connect(_on_building_unlocked)

	if spawn_button:
		spawn_button.pressed.connect(_on_spawn_pressed)

	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)

	if settings_panel:
		settings_panel.closed.connect(_on_settings_closed)

	if shop_button:
		shop_button.pressed.connect(_on_shop_pressed)

	if shop_panel:
		shop_panel.closed.connect(_on_shop_closed)

	if daily_reward_button:
		daily_reward_button.pressed.connect(_on_daily_reward_pressed)

	if daily_reward_panel:
		daily_reward_panel.closed.connect(_on_daily_reward_closed)

	if iap_button:
		iap_button.pressed.connect(_on_iap_pressed)

	if iap_panel:
		iap_panel.closed.connect(_on_iap_closed)

	if settings_overlay:
		settings_overlay.gui_input.connect(_on_overlay_input)

	if game_grid:
		game_grid.merge_completed.connect(_on_merge_completed)

	# Connect daily reward signals for button notification
	DailyRewardManager.reward_available.connect(_on_reward_available)
	DailyRewardManager.reward_claimed.connect(_on_reward_claimed)

	# Connect shop signals to update UI when upgrades are purchased
	ShopManager.upgrade_purchased.connect(_on_upgrade_purchased)

	# Initial UI update
	_update_ui()
	_update_daily_button_notification()

func _enhance_ui() -> void:
	# Create stylish bar backgrounds
	_style_panel(top_bar, Color(0.1, 0.12, 0.18, 0.95), Color(0.2, 0.25, 0.35, 0.5))
	_style_panel(bottom_bar, Color(0.1, 0.12, 0.18, 0.95), Color(0.2, 0.25, 0.35, 0.5))

	# Add icons to stat labels
	if coins_title:
		coins_title.text = "COINS"
	if energy_title:
		energy_title.text = "ENERGY"
	if income_title:
		income_title.text = "INCOME"

	# Style buttons with gradients
	_style_button(spawn_button, Color(0.2, 0.5, 0.9), Color(0.15, 0.4, 0.8))
	_style_button(shop_button, Color(0.2, 0.6, 0.3), Color(0.15, 0.5, 0.25))
	_style_button(daily_reward_button, Color(0.8, 0.6, 0.2), Color(0.7, 0.5, 0.15))
	_style_button(iap_button, Color(0.9, 0.5, 0.15), Color(0.8, 0.4, 0.1))

	# Style panels
	_style_panel(settings_panel, Color(0.12, 0.14, 0.2, 0.98), Color(0.3, 0.35, 0.5, 0.3))
	_style_panel(shop_panel, Color(0.12, 0.14, 0.2, 0.98), Color(0.2, 0.4, 0.3, 0.3))
	_style_panel(daily_reward_panel, Color(0.12, 0.14, 0.2, 0.98), Color(0.4, 0.35, 0.2, 0.3))
	_style_panel(iap_panel, Color(0.12, 0.14, 0.2, 0.98), Color(0.5, 0.35, 0.15, 0.4))
	_style_panel(quest_panel, Color(0.1, 0.12, 0.18, 0.95), Color(0.5, 0.45, 0.2, 0.4))

func _style_panel(panel: PanelContainer, bg_color: Color, border_color: Color) -> void:
	if not panel:
		return
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", style)

func _style_button(button: Button, color1: Color, color2: Color) -> void:
	if not button:
		return
	# Normal style
	var normal = StyleBoxFlat.new()
	normal.bg_color = color1
	normal.set_corner_radius_all(10)
	normal.shadow_color = Color(0, 0, 0, 0.3)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0, 2)
	normal.border_color = color1.lightened(0.3)
	normal.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", normal)

	# Hover style
	var hover = StyleBoxFlat.new()
	hover.bg_color = color1.lightened(0.15)
	hover.set_corner_radius_all(10)
	hover.border_color = color1.lightened(0.4)
	hover.set_border_width_all(2)
	button.add_theme_stylebox_override("hover", hover)

	# Pressed style
	var pressed = StyleBoxFlat.new()
	pressed.bg_color = color2
	pressed.set_corner_radius_all(10)
	button.add_theme_stylebox_override("pressed", pressed)

	# Disabled style
	var disabled = StyleBoxFlat.new()
	disabled.bg_color = Color(0.3, 0.3, 0.3, 0.8)
	disabled.set_corner_radius_all(10)
	button.add_theme_stylebox_override("disabled", disabled)

func _process(delta: float) -> void:
	# Smooth coin counter animation
	if abs(_coins_display - GameManager.coins) > 0.1:
		_coins_display = lerp(_coins_display, float(GameManager.coins), delta * 10)
		if coins_label:
			coins_label.text = _format_number(_coins_display)

	# Update income display
	if income_label:
		var income = GameManager.get_coins_per_second()
		income_label.text = "+%s/s" % _format_number(income)

func _update_ui() -> void:
	_coins_display = GameManager.coins
	if coins_label:
		coins_label.text = _format_number(GameManager.coins)
	if energy_label:
		energy_label.text = "%d/%d" % [GameManager.energy, GameManager.max_energy]
	if spawn_button:
		spawn_button.disabled = GameManager.energy <= 0

func _on_coins_changed(new_amount: int) -> void:
	# Pulse animation on coin label when coins change significantly
	if coins_label and abs(new_amount - _coins_display) > 1:
		var tween = coins_label.create_tween()
		tween.tween_property(coins_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(coins_label, "scale", Vector2(1.0, 1.0), 0.1)

func _on_energy_changed(new_amount: int) -> void:
	if energy_label:
		energy_label.text = "%d/%d" % [new_amount, GameManager.max_energy]

		# Pulse animation on energy change
		var tween = energy_label.create_tween()
		if new_amount < GameManager.max_energy:
			# Red pulse when energy used
			tween.tween_property(energy_label, "modulate", Color(1.5, 0.7, 0.7, 1), 0.1)
		else:
			# Green pulse when energy full
			tween.tween_property(energy_label, "modulate", Color(0.7, 1.5, 0.7, 1), 0.1)
		tween.tween_property(energy_label, "modulate", Color(1, 1, 1, 1), 0.2)

	if spawn_button:
		spawn_button.disabled = new_amount <= 0
		# Visual feedback when button becomes disabled/enabled
		if new_amount <= 0:
			spawn_button.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			spawn_button.modulate = Color(1, 1, 1, 1)

func _on_building_unlocked(level: int) -> void:
	var data = GameManager.building_data.get(level, {})
	var building_name = data.get("name", "Building")
	print("New building unlocked: ", building_name)

	# Show achievement popup for levels 7+
	if level >= 7:
		_show_achievement_popup(level, building_name, data.get("color", Color.WHITE))

func _on_spawn_pressed() -> void:
	if game_grid:
		# Play button click sound
		AudioManager.play_button_click()

		# Button press animation
		if spawn_button:
			var tween = spawn_button.create_tween()
			tween.tween_property(spawn_button, "scale", Vector2(0.9, 0.9), 0.05)
			tween.tween_property(spawn_button, "scale", Vector2(1.05, 1.05), 0.1)
			tween.tween_property(spawn_button, "scale", Vector2(1.0, 1.0), 0.05)

		if game_grid.spawn_new_building():
			# Success feedback - flash the button green briefly
			if spawn_button:
				var original_color = spawn_button.modulate
				var tween2 = spawn_button.create_tween()
				tween2.tween_property(spawn_button, "modulate", Color(0.5, 1.5, 0.5, 1), 0.1)
				tween2.tween_property(spawn_button, "modulate", original_color, 0.2)

func _on_merge_completed(new_level: int) -> void:
	# Could play sound or show effect
	var data = GameManager.building_data.get(new_level, {})
	print("Merged to: ", data.get("name", "Unknown"))

func _format_number(value: float) -> String:
	if value >= 1000000000:
		return "%.1fB" % (value / 1000000000)
	elif value >= 1000000:
		return "%.1fM" % (value / 1000000)
	elif value >= 1000:
		return "%.1fK" % (value / 1000)
	else:
		return str(int(value))

func _on_settings_pressed() -> void:
	AudioManager.play_button_click()

	# Button animation
	if settings_button:
		var tween = settings_button.create_tween()
		tween.tween_property(settings_button, "rotation", 0.5, 0.2)
		tween.tween_property(settings_button, "rotation", 0.0, 0.2)

	_show_settings()

func _show_settings() -> void:
	_active_panel = "settings"

	if settings_overlay:
		settings_overlay.visible = true
		settings_overlay.modulate.a = 0
		var tween = settings_overlay.create_tween()
		tween.tween_property(settings_overlay, "modulate:a", 1.0, 0.2)

	if settings_panel:
		settings_panel.show_panel()

func _hide_settings() -> void:
	if settings_overlay:
		var tween = settings_overlay.create_tween()
		tween.tween_property(settings_overlay, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): settings_overlay.visible = false)

	if settings_panel:
		settings_panel.hide_panel()

	_active_panel = ""

func _on_settings_closed() -> void:
	_hide_settings()

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		AudioManager.play_button_click()
		_hide_active_panel()

# Shop panel functions
func _on_shop_pressed() -> void:
	AudioManager.play_button_click()

	# Button animation
	if shop_button:
		var tween = shop_button.create_tween()
		tween.tween_property(shop_button, "scale", Vector2(0.9, 0.9), 0.05)
		tween.tween_property(shop_button, "scale", Vector2(1.05, 1.05), 0.1)
		tween.tween_property(shop_button, "scale", Vector2(1.0, 1.0), 0.05)

	_show_shop()

func _show_shop() -> void:
	_active_panel = "shop"

	if settings_overlay:
		settings_overlay.visible = true
		settings_overlay.modulate.a = 0
		var tween = settings_overlay.create_tween()
		tween.tween_property(settings_overlay, "modulate:a", 1.0, 0.2)

	if shop_panel:
		shop_panel.show_panel()

func _hide_shop() -> void:
	if settings_overlay:
		var tween = settings_overlay.create_tween()
		tween.tween_property(settings_overlay, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): settings_overlay.visible = false)

	if shop_panel:
		shop_panel.hide_panel()

	_active_panel = ""

func _on_shop_closed() -> void:
	_hide_shop()

# Daily reward panel functions
func _on_daily_reward_pressed() -> void:
	AudioManager.play_button_click()

	# Button animation
	if daily_reward_button:
		var tween = daily_reward_button.create_tween()
		tween.tween_property(daily_reward_button, "scale", Vector2(0.9, 0.9), 0.05)
		tween.tween_property(daily_reward_button, "scale", Vector2(1.05, 1.05), 0.1)
		tween.tween_property(daily_reward_button, "scale", Vector2(1.0, 1.0), 0.05)

	_show_daily_reward()

func _show_daily_reward() -> void:
	_active_panel = "daily_reward"

	if settings_overlay:
		settings_overlay.visible = true
		settings_overlay.modulate.a = 0
		var tween = settings_overlay.create_tween()
		tween.tween_property(settings_overlay, "modulate:a", 1.0, 0.2)

	if daily_reward_panel:
		daily_reward_panel.show_panel()

func _hide_daily_reward() -> void:
	if settings_overlay:
		var tween = settings_overlay.create_tween()
		tween.tween_property(settings_overlay, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): settings_overlay.visible = false)

	if daily_reward_panel:
		daily_reward_panel.hide_panel()

	_active_panel = ""

func _on_daily_reward_closed() -> void:
	_hide_daily_reward()

# IAP panel functions
func _on_iap_pressed() -> void:
	AudioManager.play_button_click()

	# Button animation
	if iap_button:
		var tween = iap_button.create_tween()
		tween.tween_property(iap_button, "scale", Vector2(0.9, 0.9), 0.05)
		tween.tween_property(iap_button, "scale", Vector2(1.05, 1.05), 0.1)
		tween.tween_property(iap_button, "scale", Vector2(1.0, 1.0), 0.05)

	_show_iap()

func _show_iap() -> void:
	_active_panel = "iap"

	if settings_overlay:
		settings_overlay.visible = true
		settings_overlay.modulate.a = 0
		var tween = settings_overlay.create_tween()
		tween.tween_property(settings_overlay, "modulate:a", 1.0, 0.2)

	if iap_panel:
		iap_panel.show_panel()

func _hide_iap() -> void:
	if settings_overlay:
		var tween = settings_overlay.create_tween()
		tween.tween_property(settings_overlay, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): settings_overlay.visible = false)

	if iap_panel:
		iap_panel.hide_panel()

	_active_panel = ""

func _on_iap_closed() -> void:
	_hide_iap()

func _hide_active_panel() -> void:
	match _active_panel:
		"settings":
			_hide_settings()
		"shop":
			_hide_shop()
		"daily_reward":
			_hide_daily_reward()
		"iap":
			_hide_iap()

# Update daily button to show notification when reward available
func _update_daily_button_notification() -> void:
	if daily_reward_button:
		if DailyRewardManager.is_reward_available():
			# Show pulsing animation to indicate reward available
			daily_reward_button.modulate = Color(1.0, 1.0, 0.5, 1.0)
		else:
			daily_reward_button.modulate = Color(1, 1, 1, 1)

func _on_reward_available() -> void:
	_update_daily_button_notification()

func _on_reward_claimed(_day: int, _rewards: Dictionary) -> void:
	_update_daily_button_notification()
	_update_ui()  # Update energy display after claiming rewards

func _on_upgrade_purchased(upgrade_id: String, _new_level: int) -> void:
	# Update UI when upgrades that affect display are purchased
	if upgrade_id == "energy_capacity" or upgrade_id == "energy_regen":
		_update_ui()  # Refresh energy display with new max

# Achievement popup for first building milestones (level 7+)
func _show_achievement_popup(level: int, building_name: String, building_color: Color) -> void:
	# Play achievement sound
	AudioManager.play_achievement()

	# Create overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.z_index = 500
	add_child(overlay)

	# Fade in overlay
	var overlay_tween = overlay.create_tween()
	overlay_tween.tween_property(overlay, "color:a", 0.7, 0.3)

	# Create container for text
	var container = VBoxContainer.new()
	container.anchor_left = 0.5
	container.anchor_right = 0.5
	container.anchor_top = 0.5
	container.anchor_bottom = 0.5
	container.offset_left = -300
	container.offset_right = 300
	container.offset_top = -150
	container.offset_bottom = 150
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.z_index = 501
	add_child(container)

	# "NEW BUILDING!" title
	var title = Label.new()
	title.text = "NEW BUILDING!"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)

	# Building name
	var name_label = Label.new()
	name_label.text = building_name.to_upper()
	name_label.add_theme_font_size_override("font_size", 64)
	name_label.add_theme_color_override("font_color", building_color)
	name_label.add_theme_constant_override("outline_size", 5)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(name_label)

	# Level indicator
	var level_label = Label.new()
	level_label.text = "Level %d" % level
	level_label.add_theme_font_size_override("font_size", 32)
	level_label.add_theme_color_override("font_color", Color.WHITE)
	level_label.add_theme_constant_override("outline_size", 3)
	level_label.add_theme_color_override("font_outline_color", Color.BLACK)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(level_label)

	# Start animation - scale up from 0
	container.scale = Vector2(0, 0)
	container.pivot_offset = container.size / 2

	var tween = container.create_tween()
	tween.tween_property(container, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.15)

	# Pulse animation on the name
	var name_tween = name_label.create_tween().set_loops(3)
	name_tween.tween_property(name_label, "modulate", Color(1.5, 1.5, 1.5, 1), 0.2)
	name_tween.tween_property(name_label, "modulate", Color(1, 1, 1, 1), 0.2)

	# Auto-dismiss after 2.5 seconds
	await get_tree().create_timer(2.5).timeout

	# Fade out
	var fade_tween = create_tween()
	fade_tween.tween_property(overlay, "color:a", 0.0, 0.3)
	fade_tween.parallel().tween_property(container, "modulate:a", 0.0, 0.3)
	fade_tween.parallel().tween_property(container, "scale", Vector2(0.8, 0.8), 0.3)

	await fade_tween.finished
	overlay.queue_free()
	container.queue_free()
