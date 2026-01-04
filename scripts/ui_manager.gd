extends Control
class_name UIManager
## UIManager - Handles all UI updates and user interactions

@onready var coins_label: Label = $TopBar/HBox/CoinsContainer/CoinsLabel
@onready var energy_label: Label = $TopBar/HBox/EnergyContainer/EnergyLabel
@onready var income_label: Label = $TopBar/HBox/IncomeContainer/IncomeLabel
@onready var spawn_button: Button = $BottomBar/HBox/SpawnButton
@onready var game_grid: GameGrid = $GridContainer/GameGrid

var _coins_display: float = 0.0

func _ready() -> void:
	# Connect signals
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.energy_changed.connect(_on_energy_changed)
	GameManager.building_unlocked.connect(_on_building_unlocked)

	if spawn_button:
		spawn_button.pressed.connect(_on_spawn_pressed)

	if game_grid:
		game_grid.merge_completed.connect(_on_merge_completed)

	# Initial UI update
	_update_ui()

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
	# Animation handled in _process
	pass

func _on_energy_changed(new_amount: int) -> void:
	if energy_label:
		energy_label.text = "%d/%d" % [new_amount, GameManager.max_energy]
	if spawn_button:
		spawn_button.disabled = new_amount <= 0

func _on_building_unlocked(level: int) -> void:
	var data = GameManager.building_data.get(level, {})
	var building_name = data.get("name", "Building")
	print("New building unlocked: ", building_name)
	# Could show a popup here

func _on_spawn_pressed() -> void:
	if game_grid:
		game_grid.spawn_new_building()

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
