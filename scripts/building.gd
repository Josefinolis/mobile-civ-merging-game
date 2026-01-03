extends Control
class_name Building
## Building - Represents a single building on the grid that can be dragged and merged

signal drag_started(building: Building)
signal drag_ended(building: Building)
signal merge_requested(source: Building, target: Building)

@onready var sprite: ColorRect = $Sprite
@onready var level_label: Label = $LevelLabel
@onready var name_label: Label = $NameLabel
@onready var coin_indicator: Label = $CoinIndicator

var grid_position: Vector2i = Vector2i.ZERO
var building_level: int = 0
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func setup(level: int, grid_pos: Vector2i) -> void:
	building_level = level
	grid_position = grid_pos
	_update_visuals()

func _update_visuals() -> void:
	if building_level <= 0:
		visible = false
		return

	visible = true

	var data: Dictionary = GameManager.building_data.get(building_level, {})
	var building_name: String = data.get("name", "Building")
	var color: Color = data.get("color", Color.WHITE)
	var coins_per_sec: float = data.get("coins_per_sec", 0)

	if sprite:
		sprite.color = color

	if level_label:
		level_label.text = str(building_level)

	if name_label:
		name_label.text = building_name

	if coin_indicator:
		coin_indicator.text = "+%.1f/s" % coins_per_sec

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag(event.position)
			else:
				_end_drag()

	elif event is InputEventMouseMotion and is_dragging:
		_update_drag(event.position)

func _start_drag(mouse_pos: Vector2) -> void:
	if building_level <= 0:
		return

	is_dragging = true
	drag_offset = mouse_pos
	original_position = position
	z_index = 100  # Bring to front while dragging
	drag_started.emit(self)

func _update_drag(mouse_pos: Vector2) -> void:
	position = position + (mouse_pos - drag_offset)

func _end_drag() -> void:
	if not is_dragging:
		return

	is_dragging = false
	z_index = 0
	drag_ended.emit(self)

func reset_position() -> void:
	position = original_position

func animate_merge() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func animate_spawn() -> void:
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
