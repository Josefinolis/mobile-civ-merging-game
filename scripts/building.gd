extends Control
class_name Building
## Building - Represents a single building on the grid that can be dragged and merged

signal drag_started(building: Building)
signal drag_ended(building: Building)
signal merge_requested(source: Building, target: Building)

@onready var main_body: ColorRect = $BuildingBase/MainBody
@onready var roof: ColorRect = $BuildingBase/Roof
@onready var roof_highlight: ColorRect = $BuildingBase/Roof/RoofHighlight
@onready var window_row: HBoxContainer = $BuildingBase/WindowRow
@onready var door: ColorRect = $BuildingBase/Door
@onready var chimney: ColorRect = $BuildingBase/Chimney
@onready var decoration: ColorRect = $BuildingBase/Decoration
@onready var level_badge: ColorRect = $LevelBadge
@onready var level_label: Label = $LevelBadge/LevelLabel
@onready var name_label: Label = $NameLabel
@onready var coin_indicator: Label = $CoinIndicator
@onready var shadow: ColorRect = $Shadow

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
	var base_color: Color = data.get("color", Color.WHITE)
	var coins_per_sec: float = data.get("coins_per_sec", 0)

	# Apply colors with variations
	var roof_color = base_color.darkened(0.3)
	var body_color = base_color
	var highlight_color = base_color.lightened(0.2)

	if main_body:
		main_body.color = body_color
	if roof:
		roof.color = roof_color
	if roof_highlight:
		roof_highlight.color = highlight_color
	if door:
		door.color = base_color.darkened(0.5)

	# Update windows based on level
	_update_windows()

	# Show chimney for level 3+
	if chimney:
		chimney.visible = building_level >= 3
		chimney.color = roof_color.darkened(0.2)

	# Show decoration for level 5+
	if decoration:
		decoration.visible = building_level >= 5
		decoration.color = base_color.lightened(0.3)

	# Level badge color based on tier
	if level_badge:
		level_badge.color = _get_badge_color()

	if level_label:
		level_label.text = str(building_level)

	if name_label:
		name_label.text = building_name

	if coin_indicator:
		if coins_per_sec >= 1:
			coin_indicator.text = "+%.0f/s" % coins_per_sec
		else:
			coin_indicator.text = "+%.1f/s" % coins_per_sec

func _update_windows() -> void:
	if not window_row:
		return

	var windows = window_row.get_children()
	var window_count = min(building_level, 3)

	# Window glow color based on level
	var window_color = Color(0.95, 0.95, 0.7, 1)  # Default warm yellow
	if building_level >= 7:
		window_color = Color(0.7, 0.9, 1.0, 1)  # Blue glow for high levels
	elif building_level >= 5:
		window_color = Color(1.0, 0.9, 0.7, 1)  # Golden glow

	for i in range(windows.size()):
		var window = windows[i]
		window.visible = i < window_count
		if window.visible:
			window.color = window_color

func _get_badge_color() -> Color:
	if building_level >= 9:
		return Color(0.9, 0.7, 0.1, 0.95)  # Gold
	elif building_level >= 7:
		return Color(0.6, 0.2, 0.7, 0.95)  # Purple
	elif building_level >= 5:
		return Color(0.2, 0.5, 0.8, 0.95)  # Blue
	elif building_level >= 3:
		return Color(0.2, 0.6, 0.3, 0.95)  # Green
	else:
		return Color(0.3, 0.3, 0.4, 0.9)  # Gray

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

	# Pickup animation - scale up slightly
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_ease(Tween.EASE_OUT)

	# Play pickup sound
	AudioManager.play_pickup()

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
	# Bounce back animation when can't merge
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "position", original_position, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

	# Shake effect
	tween.tween_property(self, "rotation", 0.1, 0.05)
	tween.tween_property(self, "rotation", -0.1, 0.05)
	tween.tween_property(self, "rotation", 0.0, 0.05)

func animate_merge() -> void:
	# Juicy merge animation with multiple phases
	var tween = create_tween()

	# Phase 1: Quick squash
	tween.tween_property(self, "scale", Vector2(0.8, 1.2), 0.08)

	# Phase 2: Expand with overshoot
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.12).set_ease(Tween.EASE_OUT)

	# Phase 3: Bounce back
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.08)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.06)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.06)

	# Flash effect on main body
	if main_body:
		tween.parallel().tween_property(main_body, "modulate", Color(2, 2, 2, 1), 0.1)
		tween.tween_property(main_body, "modulate", Color(1, 1, 1, 1), 0.2)

func animate_spawn() -> void:
	scale = Vector2.ZERO
	modulate.a = 0
	rotation = -0.2

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	# Pop in with rotation
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.25)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(self, "rotation", 0.05, 0.25)

	# Settle
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.15)

func animate_invalid_drop() -> void:
	# Red flash and shake for invalid action
	var tween = create_tween()
	if main_body:
		tween.tween_property(main_body, "modulate", Color(1.5, 0.5, 0.5, 1), 0.1)
		tween.tween_property(main_body, "modulate", Color(1, 1, 1, 1), 0.2)

	tween.parallel().tween_property(self, "position:x", position.x + 5, 0.03)
	tween.tween_property(self, "position:x", position.x - 5, 0.03)
	tween.tween_property(self, "position:x", position.x + 3, 0.03)
	tween.tween_property(self, "position:x", position.x, 0.03)

func get_center_position() -> Vector2:
	return position + size / 2

func get_building_color() -> Color:
	var data: Dictionary = GameManager.building_data.get(building_level, {})
	return data.get("color", Color.WHITE)
