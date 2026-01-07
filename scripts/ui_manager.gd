extends Control
class_name UIManager
## UIManager - Handles all UI updates and user interactions

@onready var coins_label: Label = $TopBar/HBox/CoinsContainer/CoinsLabel
@onready var energy_label: Label = $TopBar/HBox/EnergyContainer/EnergyLabel
@onready var income_label: Label = $TopBar/HBox/IncomeContainer/IncomeLabel
@onready var spawn_button: Button = $BottomBar/HBox/SpawnButton
@onready var shop_button: Button = $BottomBar/HBox/ShopButton
@onready var daily_reward_button: Button = $BottomBar/HBox/DailyRewardButton
@onready var settings_button: Button = $TopBar/HBox/SettingsButton
@onready var game_grid = $GridContainer/GameGrid
@onready var settings_panel = $SettingsPanel
@onready var shop_panel = $ShopPanel
@onready var daily_reward_panel = $DailyRewardPanel
@onready var settings_overlay: ColorRect = $SettingsOverlay

var _coins_display: float = 0.0
var _active_panel: String = ""  # Track which panel is open

func _ready() -> void:
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

	if settings_overlay:
		settings_overlay.gui_input.connect(_on_overlay_input)

	if game_grid:
		game_grid.merge_completed.connect(_on_merge_completed)

	# Connect daily reward signals for button notification
	DailyRewardManager.reward_available.connect(_on_reward_available)
	DailyRewardManager.reward_claimed.connect(_on_reward_claimed)

	# Initial UI update
	_update_ui()
	_update_daily_button_notification()

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
	# Could show a popup here

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

func _hide_active_panel() -> void:
	match _active_panel:
		"settings":
			_hide_settings()
		"shop":
			_hide_shop()
		"daily_reward":
			_hide_daily_reward()

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
