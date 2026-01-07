extends Control
class_name Building
## Building - Ultra-detailed procedural building graphics

signal drag_started(building: Building)
signal drag_ended(building: Building)
signal merge_requested(source: Building, target: Building)

@onready var building_container: Control = $BuildingContainer
@onready var level_badge: Control = $LevelBadge
@onready var level_label: Label = $LevelBadge/LevelLabel
@onready var name_label: Label = $NameLabel
@onready var coin_indicator: Label = $CoinIndicator
@onready var shadow: ColorRect = $Shadow

var grid_position: Vector2i = Vector2i.ZERO
var building_level: int = 0
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO

var glow_effect: ColorRect = null
var _time: float = 0.0

# Drawing scale and offset for centering
const DESIGN_WIDTH: float = 100.0
const DESIGN_HEIGHT: float = 95.0
var _scale: Vector2 = Vector2.ONE
var _offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_building_container()

func _process(delta: float) -> void:
	_time += delta
	# Animate glow for high-level buildings
	if glow_effect and building_level >= 9:
		var pulse = 0.15 + sin(_time * 2.0) * 0.05
		glow_effect.color.a = pulse

func _setup_building_container() -> void:
	if not building_container:
		building_container = Control.new()
		building_container.name = "BuildingContainer"
		building_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		building_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(building_container)
		move_child(building_container, 1)

func setup(level: int, grid_pos: Vector2i) -> void:
	building_level = level
	grid_position = grid_pos
	_build_visual()

func _build_visual() -> void:
	if building_level <= 0:
		visible = false
		return

	visible = true
	_clear_building()

	# Calculate scale and offset for centering
	_calculate_transform()

	var data: Dictionary = GameManager.building_data.get(building_level, {})
	var building_name: String = data.get("name", "Building")
	var base_color: Color = data.get("color", Color.WHITE)
	var coins_per_sec: float = data.get("coins_per_sec", 0)

	match building_level:
		1: _build_tent_detailed(base_color)
		2: _build_hut_detailed(base_color)
		3: _build_cabin_detailed(base_color)
		4: _build_house_detailed(base_color)
		5: _build_villa_detailed(base_color)
		6: _build_mansion_detailed(base_color)
		7: _build_tower_detailed(base_color)
		8: _build_skyscraper_detailed(base_color)
		9: _build_monument_detailed(base_color)
		10: _build_wonder_detailed(base_color)

	_update_labels(building_name, coins_per_sec)
	_update_badge()

func _clear_building() -> void:
	glow_effect = null
	for child in building_container.get_children():
		child.queue_free()

func _calculate_transform() -> void:
	# Get available space (container size minus margins for labels)
	var available_width: float = size.x if size.x > 0 else 144.0
	var available_height: float = (size.y - 20) if size.y > 0 else 134.0  # Leave space for labels

	# Calculate scale to fill the space (use 95% to leave small margin)
	var scale_x: float = (available_width * 0.95) / DESIGN_WIDTH
	var scale_y: float = (available_height * 0.95) / DESIGN_HEIGHT

	# Use uniform scale to maintain proportions
	var uniform_scale: float = min(scale_x, scale_y)
	_scale = Vector2(uniform_scale, uniform_scale)

	# Calculate offset to center the building
	var scaled_width: float = DESIGN_WIDTH * uniform_scale
	var scaled_height: float = DESIGN_HEIGHT * uniform_scale
	_offset.x = (available_width - scaled_width) / 2.0
	_offset.y = (available_height - scaled_height) / 2.0

# ==================== NIVEL 1: TENT ====================
func _build_tent_detailed(base_color: Color) -> void:
	# Ground/dirt patch
	_rect(Vector2(5, 85), Vector2(90, 10), Color(0.35, 0.25, 0.15))
	_rect(Vector2(10, 88), Vector2(30, 5), Color(0.4, 0.3, 0.18))
	_rect(Vector2(55, 87), Vector2(25, 6), Color(0.38, 0.28, 0.16))

	# Small rocks
	_rect(Vector2(8, 88), Vector2(6, 4), Color(0.5, 0.5, 0.5))
	_rect(Vector2(80, 86), Vector2(8, 5), Color(0.45, 0.45, 0.45))

	# Tent shadow on ground
	_rect(Vector2(15, 78), Vector2(70, 8), Color(0, 0, 0, 0.2))

	# Main tent body - left side
	_rect(Vector2(20, 35), Vector2(30, 45), base_color.darkened(0.1))
	_rect(Vector2(22, 37), Vector2(26, 41), base_color)

	# Main tent body - right side (lighter)
	_rect(Vector2(50, 35), Vector2(30, 45), base_color.lightened(0.1))
	_rect(Vector2(52, 37), Vector2(26, 41), base_color.lightened(0.15))

	# Tent peak/top
	_rect(Vector2(35, 18), Vector2(30, 20), base_color.darkened(0.05))
	_rect(Vector2(40, 12), Vector2(20, 10), base_color.darkened(0.15))
	_rect(Vector2(45, 8), Vector2(10, 6), base_color.darkened(0.2))

	# Tent folds/creases (fabric detail)
	_rect(Vector2(25, 40), Vector2(2, 35), base_color.darkened(0.15))
	_rect(Vector2(35, 38), Vector2(2, 38), base_color.darkened(0.2))
	_rect(Vector2(63, 38), Vector2(2, 38), base_color.darkened(0.1))
	_rect(Vector2(73, 40), Vector2(2, 35), base_color.darkened(0.05))

	# Tent opening (dark interior)
	_rect(Vector2(40, 52), Vector2(20, 28), Color(0.08, 0.06, 0.04))
	_rect(Vector2(42, 54), Vector2(16, 24), Color(0.05, 0.03, 0.02))

	# Flap details
	_rect(Vector2(38, 50), Vector2(4, 30), base_color.darkened(0.15))
	_rect(Vector2(58, 50), Vector2(4, 30), base_color.lightened(0.05))

	# Center pole
	_rect(Vector2(48, 2), Vector2(4, 18), Color(0.45, 0.35, 0.25))
	_rect(Vector2(49, 0), Vector2(2, 4), Color(0.5, 0.4, 0.3))

	# Flag on pole
	_rect(Vector2(52, 2), Vector2(12, 8), Color(0.8, 0.2, 0.2))
	_rect(Vector2(52, 4), Vector2(10, 4), Color(0.9, 0.3, 0.3))

	# Rope details
	_rect(Vector2(15, 75), Vector2(25, 2), Color(0.5, 0.45, 0.35))
	_rect(Vector2(60, 75), Vector2(25, 2), Color(0.5, 0.45, 0.35))

	# Stakes
	_rect(Vector2(12, 78), Vector2(3, 8), Color(0.4, 0.3, 0.2))
	_rect(Vector2(85, 78), Vector2(3, 8), Color(0.4, 0.3, 0.2))

	# Small campfire
	_rect(Vector2(5, 75), Vector2(8, 6), Color(0.3, 0.2, 0.1))
	_rect(Vector2(6, 72), Vector2(6, 5), Color(0.9, 0.5, 0.1))
	_rect(Vector2(7, 70), Vector2(4, 4), Color(1.0, 0.7, 0.2))

# ==================== NIVEL 2: HUT ====================
func _build_hut_detailed(base_color: Color) -> void:
	# Ground
	_rect(Vector2(0, 88), Vector2(100, 8), Color(0.3, 0.4, 0.2))

	# Hut shadow
	_rect(Vector2(12, 82), Vector2(76, 8), Color(0, 0, 0, 0.25))

	# Main circular body (simulated with rectangles)
	_rect(Vector2(18, 45), Vector2(64, 42), base_color)
	_rect(Vector2(15, 50), Vector2(70, 35), base_color)
	_rect(Vector2(20, 43), Vector2(60, 3), base_color.lightened(0.1))

	# Wall texture - horizontal mud/adobe lines
	for i in range(5):
		_rect(Vector2(18, 50 + i * 7), Vector2(64, 2), base_color.darkened(0.1))

	# Wall border/outline
	_rect(Vector2(16, 45), Vector2(3, 42), base_color.darkened(0.2))
	_rect(Vector2(81, 45), Vector2(3, 42), base_color.darkened(0.15))

	# Thatched roof - multiple layers
	_rect(Vector2(5, 22), Vector2(90, 12), base_color.darkened(0.15))
	_rect(Vector2(8, 15), Vector2(84, 10), base_color.darkened(0.25))
	_rect(Vector2(15, 8), Vector2(70, 10), base_color.darkened(0.3))
	_rect(Vector2(25, 2), Vector2(50, 8), base_color.darkened(0.35))
	_rect(Vector2(35, -2), Vector2(30, 6), base_color.darkened(0.4))

	# Roof straw texture
	for i in range(12):
		var x_pos = 10 + i * 7
		_rect(Vector2(x_pos, 18), Vector2(3, 8), base_color.darkened(0.2 + randf() * 0.1))
	for i in range(10):
		var x_pos = 15 + i * 7
		_rect(Vector2(x_pos, 10), Vector2(2, 7), base_color.darkened(0.25 + randf() * 0.1))

	# Door frame
	_rect(Vector2(38, 55), Vector2(24, 32), Color(0.25, 0.18, 0.1))
	_rect(Vector2(40, 57), Vector2(20, 28), Color(0.2, 0.14, 0.08))

	# Door planks
	_rect(Vector2(41, 58), Vector2(8, 26), Color(0.35, 0.25, 0.15))
	_rect(Vector2(51, 58), Vector2(8, 26), Color(0.32, 0.22, 0.12))

	# Door handle
	_rect(Vector2(56, 70), Vector2(3, 5), Color(0.5, 0.4, 0.2))

	# Window (small, round)
	_rect(Vector2(68, 55), Vector2(14, 14), Color(0.2, 0.15, 0.1))
	_rect(Vector2(70, 57), Vector2(10, 10), Color(0.9, 0.8, 0.5, 0.8))
	_rect(Vector2(74, 57), Vector2(2, 10), Color(0.25, 0.18, 0.1))
	_rect(Vector2(70, 61), Vector2(10, 2), Color(0.25, 0.18, 0.1))

	# Small plants around
	_rect(Vector2(5, 82), Vector2(8, 8), Color(0.2, 0.5, 0.2))
	_rect(Vector2(6, 78), Vector2(6, 6), Color(0.25, 0.55, 0.25))
	_rect(Vector2(87, 80), Vector2(10, 10), Color(0.2, 0.45, 0.2))

# ==================== NIVEL 3: CABIN ====================
func _build_cabin_detailed(base_color: Color) -> void:
	# Snow/ground
	_rect(Vector2(0, 88), Vector2(100, 10), Color(0.85, 0.9, 0.95))
	_rect(Vector2(5, 86), Vector2(90, 4), Color(0.9, 0.93, 0.97))

	# Building shadow
	_rect(Vector2(12, 82), Vector2(80, 8), Color(0, 0, 0, 0.2))

	# Main log cabin body
	_rect(Vector2(10, 38), Vector2(80, 48), base_color)

	# Log texture - horizontal logs with depth
	for i in range(6):
		var y_pos = 40 + i * 8
		_rect(Vector2(10, y_pos), Vector2(80, 7), base_color.lightened(0.05 if i % 2 == 0 else 0))
		_rect(Vector2(10, y_pos), Vector2(80, 2), base_color.darkened(0.1))
		_rect(Vector2(10, y_pos + 5), Vector2(80, 2), base_color.darkened(0.15))

	# Log ends (left side)
	for i in range(6):
		_rect(Vector2(6, 40 + i * 8), Vector2(6, 6), base_color.darkened(0.1))
		_rect(Vector2(7, 41 + i * 8), Vector2(4, 4), base_color.lightened(0.1))

	# Log ends (right side)
	for i in range(6):
		_rect(Vector2(88, 40 + i * 8), Vector2(6, 6), base_color.darkened(0.1))
		_rect(Vector2(89, 41 + i * 8), Vector2(4, 4), base_color.lightened(0.1))

	# Roof
	_rect(Vector2(-2, 18), Vector2(54, 24), base_color.darkened(0.3))
	_rect(Vector2(50, 18), Vector2(54, 24), base_color.darkened(0.4))
	_rect(Vector2(0, 20), Vector2(50, 20), base_color.darkened(0.25))
	_rect(Vector2(50, 20), Vector2(50, 20), base_color.darkened(0.35))

	# Roof cap
	_rect(Vector2(40, 12), Vector2(20, 10), base_color.darkened(0.35))

	# Snow on roof
	_rect(Vector2(0, 18), Vector2(100, 4), Color(0.95, 0.97, 1.0))
	_rect(Vector2(5, 16), Vector2(90, 3), Color(0.9, 0.95, 1.0))
	_rect(Vector2(42, 10), Vector2(16, 4), Color(0.95, 0.97, 1.0))

	# Chimney
	_rect(Vector2(70, 2), Vector2(16, 22), Color(0.55, 0.35, 0.3))
	_rect(Vector2(72, 4), Vector2(12, 18), Color(0.6, 0.4, 0.35))
	_rect(Vector2(68, 0), Vector2(20, 4), Color(0.5, 0.3, 0.25))

	# Smoke
	_rect(Vector2(74, -8), Vector2(8, 8), Color(0.8, 0.8, 0.8, 0.4))
	_rect(Vector2(76, -14), Vector2(6, 8), Color(0.85, 0.85, 0.85, 0.3))
	_rect(Vector2(78, -18), Vector2(5, 6), Color(0.9, 0.9, 0.9, 0.2))

	# Door
	_rect(Vector2(22, 52), Vector2(22, 34), Color(0.3, 0.2, 0.12))
	_rect(Vector2(24, 54), Vector2(18, 30), Color(0.4, 0.28, 0.18))
	_rect(Vector2(24, 54), Vector2(8, 30), Color(0.38, 0.26, 0.16))
	_rect(Vector2(34, 54), Vector2(8, 30), Color(0.42, 0.3, 0.2))
	_rect(Vector2(32, 54), Vector2(2, 30), Color(0.3, 0.2, 0.12))

	# Door handle
	_rect(Vector2(38, 68), Vector2(3, 6), Color(0.7, 0.6, 0.3))

	# Windows
	_create_cabin_window(Vector2(55, 48), base_color)
	_create_cabin_window(Vector2(55, 48), base_color)

	# Window with warm glow
	_rect(Vector2(55, 50), Vector2(24, 22), Color(0.25, 0.18, 0.1))
	_rect(Vector2(57, 52), Vector2(20, 18), Color(0.95, 0.85, 0.5, 0.9))
	_rect(Vector2(66, 52), Vector2(2, 18), Color(0.3, 0.2, 0.12))
	_rect(Vector2(57, 60), Vector2(20, 2), Color(0.3, 0.2, 0.12))

	# Woodpile
	_rect(Vector2(85, 72), Vector2(12, 14), Color(0.45, 0.32, 0.2))
	_rect(Vector2(86, 74), Vector2(4, 10), Color(0.5, 0.35, 0.22))
	_rect(Vector2(91, 74), Vector2(4, 10), Color(0.48, 0.33, 0.21))

func _create_cabin_window(pos: Vector2, base_color: Color) -> void:
	pass  # Implemented inline above

# ==================== NIVEL 4: HOUSE ====================
func _build_house_detailed(base_color: Color) -> void:
	# Lawn
	_rect(Vector2(0, 88), Vector2(100, 12), Color(0.3, 0.5, 0.25))
	_rect(Vector2(5, 90), Vector2(40, 6), Color(0.35, 0.55, 0.3))
	_rect(Vector2(55, 89), Vector2(35, 7), Color(0.32, 0.52, 0.27))

	# Driveway
	_rect(Vector2(60, 86), Vector2(35, 14), Color(0.45, 0.45, 0.45))
	_rect(Vector2(62, 88), Vector2(31, 10), Color(0.5, 0.5, 0.5))

	# House shadow
	_rect(Vector2(10, 82), Vector2(85, 8), Color(0, 0, 0, 0.2))

	# Foundation
	_rect(Vector2(6, 82), Vector2(88, 8), Color(0.45, 0.45, 0.45))
	_rect(Vector2(8, 84), Vector2(84, 4), Color(0.5, 0.5, 0.5))

	# Main house body
	_rect(Vector2(8, 32), Vector2(84, 52), base_color)

	# Siding texture
	for i in range(10):
		_rect(Vector2(8, 34 + i * 5), Vector2(84, 1), base_color.darkened(0.08))

	# Corner trim
	_rect(Vector2(8, 32), Vector2(4, 52), base_color.lightened(0.15))
	_rect(Vector2(88, 32), Vector2(4, 52), base_color.lightened(0.1))

	# Roof
	_rect(Vector2(0, 12), Vector2(55, 24), base_color.darkened(0.35))
	_rect(Vector2(45, 12), Vector2(55, 24), base_color.darkened(0.45))
	_rect(Vector2(2, 14), Vector2(51, 20), base_color.darkened(0.3))
	_rect(Vector2(47, 14), Vector2(51, 20), base_color.darkened(0.4))

	# Roof shingles effect
	for i in range(4):
		_rect(Vector2(0, 14 + i * 5), Vector2(100, 2), base_color.darkened(0.35 + i * 0.03))

	# Roof peak
	_rect(Vector2(42, 6), Vector2(16, 10), base_color.darkened(0.35))

	# Chimney
	_rect(Vector2(72, 0), Vector2(14, 18), Color(0.6, 0.35, 0.3))
	_rect(Vector2(70, -2), Vector2(18, 4), Color(0.55, 0.3, 0.25))

	# Front door with frame
	_rect(Vector2(20, 50), Vector2(24, 34), Color(0.9, 0.9, 0.85))
	_rect(Vector2(22, 52), Vector2(20, 30), Color(0.35, 0.22, 0.12))
	_rect(Vector2(24, 54), Vector2(16, 26), Color(0.45, 0.3, 0.18))
	_rect(Vector2(24, 54), Vector2(7, 26), Color(0.42, 0.28, 0.16))
	_rect(Vector2(33, 54), Vector2(7, 26), Color(0.48, 0.32, 0.2))

	# Door window
	_rect(Vector2(27, 56), Vector2(10, 10), Color(0.7, 0.85, 0.95, 0.8))
	_rect(Vector2(31, 56), Vector2(2, 10), Color(0.4, 0.28, 0.16))

	# Door handle
	_rect(Vector2(36, 68), Vector2(3, 5), Color(0.75, 0.65, 0.3))

	# Porch
	_rect(Vector2(15, 80), Vector2(35, 6), Color(0.5, 0.4, 0.3))
	_rect(Vector2(17, 78), Vector2(31, 3), Color(0.55, 0.45, 0.35))

	# Porch pillars
	_rect(Vector2(17, 50), Vector2(4, 32), Color(0.95, 0.95, 0.9))
	_rect(Vector2(44, 50), Vector2(4, 32), Color(0.95, 0.95, 0.9))

	# Main window
	_rect(Vector2(52, 42), Vector2(30, 28), Color(0.95, 0.95, 0.9))
	_rect(Vector2(54, 44), Vector2(26, 24), Color(0.75, 0.88, 0.98))
	# Muntins
	_rect(Vector2(66, 44), Vector2(2, 24), Color(0.9, 0.9, 0.85))
	_rect(Vector2(54, 55), Vector2(26, 2), Color(0.9, 0.9, 0.85))
	# Shutters
	_rect(Vector2(48, 42), Vector2(5, 28), base_color.darkened(0.2))
	_rect(Vector2(83, 42), Vector2(5, 28), base_color.darkened(0.2))

	# Garage door
	_rect(Vector2(58, 55), Vector2(30, 28), Color(0.55, 0.55, 0.55))
	_rect(Vector2(60, 57), Vector2(26, 24), Color(0.65, 0.65, 0.65))
	for i in range(3):
		_rect(Vector2(60, 59 + i * 8), Vector2(26, 2), Color(0.5, 0.5, 0.5))

	# Small windows on garage
	for i in range(4):
		_rect(Vector2(62 + i * 6, 59), Vector2(4, 4), Color(0.75, 0.85, 0.95, 0.6))

	# Bushes
	_rect(Vector2(5, 78), Vector2(10, 10), Color(0.2, 0.45, 0.2))
	_rect(Vector2(6, 76), Vector2(8, 6), Color(0.25, 0.5, 0.25))

	# Flowers
	_rect(Vector2(8, 82), Vector2(3, 3), Color(0.9, 0.3, 0.4))
	_rect(Vector2(12, 81), Vector2(3, 3), Color(0.95, 0.8, 0.2))

# ==================== NIVEL 5: VILLA ====================
func _build_villa_detailed(base_color: Color) -> void:
	# Mediterranean garden
	_rect(Vector2(0, 88), Vector2(100, 12), Color(0.85, 0.8, 0.65))
	_rect(Vector2(5, 90), Vector2(20, 8), Color(0.35, 0.55, 0.3))
	_rect(Vector2(75, 89), Vector2(20, 9), Color(0.32, 0.52, 0.28))

	# Terracotta path
	_rect(Vector2(35, 88), Vector2(30, 12), Color(0.75, 0.55, 0.4))
	_rect(Vector2(38, 90), Vector2(24, 8), Color(0.8, 0.6, 0.45))

	# Building shadow
	_rect(Vector2(8, 84), Vector2(88, 8), Color(0, 0, 0, 0.2))

	# Main villa body
	_rect(Vector2(5, 28), Vector2(60, 60), base_color)
	_rect(Vector2(7, 30), Vector2(56, 56), base_color.lightened(0.05))

	# Side wing
	_rect(Vector2(60, 42), Vector2(38, 46), base_color.lightened(0.08))
	_rect(Vector2(62, 44), Vector2(34, 42), base_color.lightened(0.12))

	# Stucco texture
	for i in range(8):
		for j in range(6):
			if randf() > 0.7:
				_rect(Vector2(10 + j * 10, 35 + i * 7), Vector2(4, 3), base_color.darkened(0.05))

	# Terracotta roof - main
	_rect(Vector2(0, 12), Vector2(70, 20), Color(0.75, 0.4, 0.3))
	_rect(Vector2(2, 14), Vector2(66, 16), Color(0.8, 0.45, 0.35))

	# Roof tiles effect
	for i in range(4):
		_rect(Vector2(0, 14 + i * 4), Vector2(70, 2), Color(0.7, 0.38, 0.28))

	# Wing roof
	_rect(Vector2(55, 30), Vector2(48, 15), Color(0.72, 0.38, 0.28))
	_rect(Vector2(57, 32), Vector2(44, 11), Color(0.78, 0.43, 0.33))

	# Decorative cornice
	_rect(Vector2(3, 26), Vector2(64, 4), Color(0.95, 0.93, 0.88))
	_rect(Vector2(60, 40), Vector2(38, 4), Color(0.95, 0.93, 0.88))

	# Arched entrance
	_rect(Vector2(25, 55), Vector2(20, 33), Color(0.2, 0.15, 0.1))
	_rect(Vector2(27, 50), Vector2(16, 5), Color(0.95, 0.93, 0.88))
	_rect(Vector2(27, 57), Vector2(16, 29), Color(0.15, 0.1, 0.08))

	# Columns
	_rect(Vector2(10, 45), Vector2(6, 43), Color(0.95, 0.93, 0.88))
	_rect(Vector2(11, 47), Vector2(4, 39), Color(0.98, 0.96, 0.92))
	_rect(Vector2(54, 45), Vector2(6, 43), Color(0.95, 0.93, 0.88))
	_rect(Vector2(55, 47), Vector2(4, 39), Color(0.98, 0.96, 0.92))

	# Column capitals
	_rect(Vector2(8, 43), Vector2(10, 4), Color(0.92, 0.9, 0.85))
	_rect(Vector2(52, 43), Vector2(10, 4), Color(0.92, 0.9, 0.85))

	# Arched windows - main
	_create_arched_window(Vector2(12, 35), Vector2(14, 18))
	_create_arched_window(Vector2(44, 35), Vector2(14, 18))

	# Balcony on wing
	_rect(Vector2(65, 55), Vector2(28, 3), Color(0.9, 0.88, 0.82))
	_rect(Vector2(67, 50), Vector2(24, 6), Color(0.85, 0.83, 0.78))

	# Balcony railing
	for i in range(5):
		_rect(Vector2(68 + i * 5, 50), Vector2(2, 6), Color(0.3, 0.3, 0.3))
	_rect(Vector2(67, 49), Vector2(26, 2), Color(0.35, 0.35, 0.35))

	# Wing windows
	_rect(Vector2(68, 60), Vector2(18, 20), Color(0.92, 0.9, 0.85))
	_rect(Vector2(70, 62), Vector2(14, 16), Color(0.7, 0.85, 0.95))
	_rect(Vector2(76, 62), Vector2(2, 16), Color(0.88, 0.86, 0.8))

	# Potted plants
	_rect(Vector2(3, 82), Vector2(8, 8), Color(0.6, 0.45, 0.35))
	_rect(Vector2(4, 76), Vector2(6, 8), Color(0.3, 0.55, 0.3))
	_rect(Vector2(90, 82), Vector2(8, 8), Color(0.6, 0.45, 0.35))
	_rect(Vector2(91, 76), Vector2(6, 8), Color(0.3, 0.55, 0.3))

func _create_arched_window(pos: Vector2, win_size: Vector2) -> void:
	_rect(pos, win_size, Color(0.92, 0.9, 0.85))
	_rect(pos + Vector2(2, 2), win_size - Vector2(4, 4), Color(0.65, 0.8, 0.92))
	_rect(pos + Vector2(win_size.x/2 - 1, 2), Vector2(2, win_size.y - 4), Color(0.88, 0.86, 0.8))

# ==================== NIVEL 6: MANSION ====================
func _build_mansion_detailed(base_color: Color) -> void:
	# Formal garden ground
	_rect(Vector2(0, 88), Vector2(100, 12), Color(0.25, 0.45, 0.25))

	# Garden path
	_rect(Vector2(40, 88), Vector2(20, 12), Color(0.7, 0.65, 0.55))
	_rect(Vector2(42, 90), Vector2(16, 8), Color(0.75, 0.7, 0.6))

	# Main mansion body
	_rect(Vector2(18, 22), Vector2(64, 68), base_color)
	_rect(Vector2(20, 24), Vector2(60, 64), base_color.lightened(0.05))

	# Left tower
	_rect(Vector2(0, 12), Vector2(22, 78), base_color.darkened(0.05))
	_rect(Vector2(2, 14), Vector2(18, 74), base_color)
	_rect(Vector2(-2, 2), Vector2(26, 14), base_color.darkened(0.25))
	_rect(Vector2(0, 4), Vector2(22, 10), base_color.darkened(0.2))
	_rect(Vector2(6, -4), Vector2(10, 10), base_color.darkened(0.3))

	# Right tower
	_rect(Vector2(78, 12), Vector2(22, 78), base_color.darkened(0.05))
	_rect(Vector2(80, 14), Vector2(18, 74), base_color)
	_rect(Vector2(76, 2), Vector2(26, 14), base_color.darkened(0.25))
	_rect(Vector2(78, 4), Vector2(22, 10), base_color.darkened(0.2))
	_rect(Vector2(84, -4), Vector2(10, 10), base_color.darkened(0.3))

	# Central roof
	_rect(Vector2(15, 10), Vector2(70, 16), base_color.darkened(0.3))
	_rect(Vector2(17, 12), Vector2(66, 12), base_color.darkened(0.25))

	# Dormer windows on roof
	_rect(Vector2(35, 5), Vector2(14, 12), base_color)
	_rect(Vector2(37, 7), Vector2(10, 8), Color(0.7, 0.82, 0.92))
	_rect(Vector2(51, 5), Vector2(14, 12), base_color)
	_rect(Vector2(53, 7), Vector2(10, 8), Color(0.7, 0.82, 0.92))

	# Grand entrance
	_rect(Vector2(38, 50), Vector2(24, 40), base_color.lightened(0.1))
	_rect(Vector2(35, 48), Vector2(30, 4), Color(0.95, 0.93, 0.88))

	# Double doors
	_rect(Vector2(40, 58), Vector2(20, 32), Color(0.25, 0.15, 0.08))
	_rect(Vector2(42, 60), Vector2(7, 28), Color(0.35, 0.22, 0.12))
	_rect(Vector2(51, 60), Vector2(7, 28), Color(0.32, 0.2, 0.1))
	_rect(Vector2(49, 60), Vector2(2, 28), Color(0.25, 0.15, 0.08))

	# Door windows
	_rect(Vector2(43, 62), Vector2(5, 8), Color(0.7, 0.82, 0.92, 0.7))
	_rect(Vector2(52, 62), Vector2(5, 8), Color(0.7, 0.82, 0.92, 0.7))

	# Grand columns
	for i in range(4):
		var x_pos = 24 + i * 16
		_rect(Vector2(x_pos, 30), Vector2(6, 60), Color(0.95, 0.93, 0.88))
		_rect(Vector2(x_pos + 1, 32), Vector2(4, 56), Color(0.98, 0.96, 0.92))
		_rect(Vector2(x_pos - 1, 28), Vector2(8, 4), Color(0.92, 0.9, 0.85))

	# Windows - towers
	_create_gothic_window(Vector2(5, 35), Vector2(12, 20))
	_create_gothic_window(Vector2(5, 60), Vector2(12, 18))
	_create_gothic_window(Vector2(83, 35), Vector2(12, 20))
	_create_gothic_window(Vector2(83, 60), Vector2(12, 18))

	# Windows - main building
	_create_gothic_window(Vector2(24, 32), Vector2(14, 18))
	_create_gothic_window(Vector2(62, 32), Vector2(14, 18))

	# Decorative elements
	_rect(Vector2(18, 20), Vector2(64, 4), Color(0.9, 0.88, 0.82))

	# Lanterns
	_rect(Vector2(36, 55), Vector2(3, 8), Color(0.3, 0.3, 0.3))
	_rect(Vector2(36, 52), Vector2(3, 4), Color(0.95, 0.85, 0.4))
	_rect(Vector2(61, 55), Vector2(3, 8), Color(0.3, 0.3, 0.3))
	_rect(Vector2(61, 52), Vector2(3, 4), Color(0.95, 0.85, 0.4))

	# Front steps
	_rect(Vector2(35, 86), Vector2(30, 4), Color(0.6, 0.58, 0.55))
	_rect(Vector2(38, 82), Vector2(24, 4), Color(0.65, 0.63, 0.6))
	_rect(Vector2(40, 78), Vector2(20, 4), Color(0.7, 0.68, 0.65))

func _create_gothic_window(pos: Vector2, win_size: Vector2) -> void:
	_rect(pos, win_size, Color(0.2, 0.18, 0.15))
	_rect(pos + Vector2(2, 2), win_size - Vector2(4, 4), Color(0.6, 0.75, 0.88))
	_rect(pos + Vector2(win_size.x/2 - 1, 0), Vector2(2, win_size.y), Color(0.25, 0.22, 0.18))
	_rect(pos + Vector2(0, win_size.y/2 - 1), Vector2(win_size.x, 2), Color(0.25, 0.22, 0.18))

# ==================== NIVEL 7: TOWER ====================
func _build_tower_detailed(base_color: Color) -> void:
	# Urban ground/plaza
	_rect(Vector2(0, 88), Vector2(100, 12), Color(0.5, 0.5, 0.52))
	_rect(Vector2(5, 90), Vector2(90, 8), Color(0.55, 0.55, 0.57))

	# Building shadow
	_rect(Vector2(25, 82), Vector2(55, 10), Color(0, 0, 0, 0.25))

	# Tower base/lobby
	_rect(Vector2(22, 75), Vector2(56, 15), Color(0.35, 0.35, 0.4))
	_rect(Vector2(24, 77), Vector2(52, 11), Color(0.4, 0.4, 0.45))

	# Main tower body with glass facade
	_rect(Vector2(24, 15), Vector2(52, 62), base_color)
	_rect(Vector2(26, 17), Vector2(48, 58), base_color.lightened(0.1))

	# Glass panels - creating grid pattern
	for i in range(7):
		for j in range(4):
			var glass_color = Color(0.6, 0.78, 0.9, 0.95)
			if (i + j) % 3 == 0:
				glass_color = Color(0.7, 0.85, 0.95, 0.9)
			_rect(Vector2(28 + j * 12, 20 + i * 8), Vector2(10, 6), glass_color)

	# Vertical mullions
	for i in range(5):
		_rect(Vector2(27 + i * 12, 17), Vector2(2, 58), base_color.darkened(0.1))

	# Horizontal spandrels
	for i in range(8):
		_rect(Vector2(24, 17 + i * 8), Vector2(52, 2), base_color.darkened(0.05))

	# Tower crown/top
	_rect(Vector2(20, 8), Vector2(60, 10), base_color.darkened(0.15))
	_rect(Vector2(22, 10), Vector2(56, 6), base_color.darkened(0.1))

	# Mechanical penthouse
	_rect(Vector2(35, 2), Vector2(30, 8), base_color.darkened(0.2))
	_rect(Vector2(37, 4), Vector2(26, 4), Color(0.4, 0.4, 0.42))

	# Antenna
	_rect(Vector2(48, -12), Vector2(4, 16), Color(0.5, 0.5, 0.55))
	_rect(Vector2(47, -15), Vector2(6, 4), Color(0.55, 0.55, 0.6))

	# Aircraft warning light
	_rect(Vector2(48, -16), Vector2(4, 3), Color(0.9, 0.2, 0.2))

	# Entrance canopy
	_rect(Vector2(30, 72), Vector2(40, 4), Color(0.3, 0.3, 0.35))
	_rect(Vector2(32, 73), Vector2(36, 2), Color(0.35, 0.35, 0.4))

	# Entrance doors (glass)
	_rect(Vector2(35, 76), Vector2(30, 12), Color(0.25, 0.25, 0.3))
	_rect(Vector2(37, 78), Vector2(12, 8), Color(0.5, 0.7, 0.85, 0.8))
	_rect(Vector2(51, 78), Vector2(12, 8), Color(0.5, 0.7, 0.85, 0.8))

	# Side setbacks
	_rect(Vector2(18, 45), Vector2(8, 45), base_color.darkened(0.1))
	_rect(Vector2(74, 45), Vector2(8, 45), base_color.darkened(0.1))

	# Small windows on setbacks
	for i in range(5):
		_rect(Vector2(20, 48 + i * 8), Vector2(4, 5), Color(0.6, 0.75, 0.88, 0.8))
		_rect(Vector2(76, 48 + i * 8), Vector2(4, 5), Color(0.6, 0.75, 0.88, 0.8))

	# Street elements
	_rect(Vector2(5, 85), Vector2(12, 15), Color(0.4, 0.4, 0.42))
	_rect(Vector2(8, 80), Vector2(6, 6), Color(0.95, 0.9, 0.5))

# ==================== NIVEL 8: SKYSCRAPER ====================
func _build_skyscraper_detailed(base_color: Color) -> void:
	# City ground
	_rect(Vector2(0, 88), Vector2(100, 12), Color(0.45, 0.45, 0.48))

	# Building shadow
	_rect(Vector2(15, 84), Vector2(75, 10), Color(0, 0, 0, 0.3))

	# Foundation/plaza
	_rect(Vector2(12, 82), Vector2(76, 10), Color(0.55, 0.55, 0.58))
	_rect(Vector2(14, 84), Vector2(72, 6), Color(0.6, 0.6, 0.63))

	# Lower section
	_rect(Vector2(14, 58), Vector2(72, 26), base_color)
	_rect(Vector2(16, 60), Vector2(68, 22), base_color.lightened(0.05))

	# Middle section (setback)
	_rect(Vector2(20, 30), Vector2(60, 30), base_color.lightened(0.08))
	_rect(Vector2(22, 32), Vector2(56, 26), base_color.lightened(0.12))

	# Upper section (more setback)
	_rect(Vector2(28, 8), Vector2(44, 24), base_color.lightened(0.15))
	_rect(Vector2(30, 10), Vector2(40, 20), base_color.lightened(0.18))

	# Crown
	_rect(Vector2(35, 2), Vector2(30, 8), base_color.darkened(0.1))
	_rect(Vector2(37, 4), Vector2(26, 4), base_color.darkened(0.05))

	# Spire
	_rect(Vector2(46, -10), Vector2(8, 14), Color(0.6, 0.6, 0.65))
	_rect(Vector2(48, -18), Vector2(4, 10), Color(0.65, 0.65, 0.7))
	_rect(Vector2(49, -22), Vector2(2, 5), Color(0.7, 0.7, 0.75))

	# Aircraft light
	_rect(Vector2(49, -23), Vector2(2, 2), Color(0.95, 0.2, 0.2))

	# Windows - lower section
	for i in range(3):
		for j in range(8):
			_rect(Vector2(18 + j * 8, 62 + i * 7), Vector2(6, 5), Color(0.55, 0.72, 0.88, 0.95))

	# Windows - middle section
	for i in range(3):
		for j in range(7):
			_rect(Vector2(24 + j * 8, 34 + i * 8), Vector2(6, 6), Color(0.6, 0.75, 0.9, 0.95))

	# Windows - upper section
	for i in range(2):
		for j in range(5):
			_rect(Vector2(32 + j * 8, 12 + i * 8), Vector2(6, 6), Color(0.65, 0.78, 0.92, 0.95))

	# Entrance
	_rect(Vector2(38, 78), Vector2(24, 8), Color(0.3, 0.3, 0.35))
	_rect(Vector2(40, 80), Vector2(8, 5), Color(0.5, 0.68, 0.82, 0.85))
	_rect(Vector2(52, 80), Vector2(8, 5), Color(0.5, 0.68, 0.82, 0.85))

	# Canopy
	_rect(Vector2(35, 75), Vector2(30, 4), Color(0.35, 0.35, 0.4))

	# Setback details
	_rect(Vector2(14, 56), Vector2(72, 3), Color(0.5, 0.5, 0.55))
	_rect(Vector2(20, 28), Vector2(60, 3), Color(0.52, 0.52, 0.57))
	_rect(Vector2(28, 6), Vector2(44, 3), Color(0.54, 0.54, 0.59))

	# Helipad indicator on roof
	_rect(Vector2(40, 3), Vector2(20, 4), Color(0.4, 0.4, 0.45))
	_rect(Vector2(48, 4), Vector2(4, 2), Color(0.95, 0.95, 0.3))

# ==================== NIVEL 9: MONUMENT ====================
func _build_monument_detailed(base_color: Color) -> void:
	# Grand plaza
	_rect(Vector2(-5, 85), Vector2(110, 20), Color(0.75, 0.72, 0.65))
	_rect(Vector2(0, 88), Vector2(100, 12), Color(0.8, 0.77, 0.7))

	# Steps - grand staircase
	_rect(Vector2(-2, 78), Vector2(104, 10), Color(0.82, 0.78, 0.68))
	_rect(Vector2(2, 72), Vector2(96, 8), Color(0.85, 0.8, 0.7))
	_rect(Vector2(6, 66), Vector2(88, 8), Color(0.88, 0.83, 0.72))

	# Main platform
	_rect(Vector2(10, 60), Vector2(80, 8), Color(0.9, 0.85, 0.75))

	# Temple base
	_rect(Vector2(15, 28), Vector2(70, 34), base_color)
	_rect(Vector2(17, 30), Vector2(66, 30), base_color.lightened(0.05))

	# Columns - grand colonnade
	for i in range(6):
		var x_pos = 18 + i * 12
		# Column base
		_rect(Vector2(x_pos - 1, 56), Vector2(8, 6), Color(0.85, 0.8, 0.7))
		# Column shaft
		_rect(Vector2(x_pos, 32), Vector2(6, 26), Color(0.92, 0.88, 0.78))
		_rect(Vector2(x_pos + 1, 34), Vector2(4, 22), Color(0.95, 0.92, 0.82))
		# Column fluting effect
		_rect(Vector2(x_pos + 2, 34), Vector2(1, 22), Color(0.88, 0.84, 0.74))
		# Column capital
		_rect(Vector2(x_pos - 2, 28), Vector2(10, 5), Color(0.9, 0.86, 0.76))
		_rect(Vector2(x_pos - 1, 26), Vector2(8, 3), Color(0.92, 0.88, 0.78))

	# Pediment (triangular roof)
	_rect(Vector2(10, 14), Vector2(40, 16), base_color.darkened(0.1))
	_rect(Vector2(50, 14), Vector2(40, 16), base_color.darkened(0.15))
	_rect(Vector2(12, 16), Vector2(36, 12), base_color.darkened(0.05))
	_rect(Vector2(52, 16), Vector2(36, 12), base_color.darkened(0.1))

	# Pediment peak
	_rect(Vector2(40, 8), Vector2(20, 10), base_color.darkened(0.08))
	_rect(Vector2(42, 10), Vector2(16, 6), base_color)

	# Acroterion (roof ornament)
	_rect(Vector2(46, 2), Vector2(8, 8), Color(0.9, 0.8, 0.3))
	_rect(Vector2(48, 0), Vector2(4, 4), Color(0.95, 0.85, 0.35))

	# Frieze with golden trim
	_rect(Vector2(12, 26), Vector2(76, 4), Color(0.88, 0.75, 0.25))
	_rect(Vector2(14, 27), Vector2(72, 2), Color(0.92, 0.8, 0.3))

	# Inner sanctum (dark interior with statue)
	_rect(Vector2(35, 38), Vector2(30, 24), Color(0.1, 0.08, 0.06))
	_rect(Vector2(37, 40), Vector2(26, 20), Color(0.08, 0.06, 0.04))

	# Statue inside
	_rect(Vector2(44, 42), Vector2(12, 16), Color(0.85, 0.75, 0.35))
	_rect(Vector2(46, 40), Vector2(8, 4), Color(0.9, 0.8, 0.4))
	_rect(Vector2(48, 38), Vector2(4, 4), Color(0.88, 0.78, 0.38))

	# Eternal flame pedestals
	_rect(Vector2(20, 62), Vector2(8, 8), Color(0.85, 0.8, 0.7))
	_rect(Vector2(22, 58), Vector2(4, 5), Color(0.95, 0.6, 0.15))
	_rect(Vector2(23, 55), Vector2(2, 4), Color(1.0, 0.8, 0.3))

	_rect(Vector2(72, 62), Vector2(8, 8), Color(0.85, 0.8, 0.7))
	_rect(Vector2(74, 58), Vector2(4, 5), Color(0.95, 0.6, 0.15))
	_rect(Vector2(75, 55), Vector2(2, 4), Color(1.0, 0.8, 0.3))

	# Glow effect
	_add_glow(Color(0.95, 0.85, 0.4), 0.35)

# ==================== NIVEL 10: WONDER ====================
func _build_wonder_detailed(base_color: Color) -> void:
	# Magnificent gardens/water
	_rect(Vector2(-10, 85), Vector2(120, 20), Color(0.3, 0.55, 0.7))
	_rect(Vector2(0, 88), Vector2(100, 10), Color(0.35, 0.6, 0.75))

	# Reflecting pool effect
	_rect(Vector2(20, 90), Vector2(60, 6), Color(0.4, 0.65, 0.8, 0.7))

	# Grand platform tiers
	_rect(Vector2(-5, 78), Vector2(110, 10), Color(0.92, 0.88, 0.78))
	_rect(Vector2(0, 70), Vector2(100, 10), Color(0.95, 0.9, 0.8))
	_rect(Vector2(5, 64), Vector2(90, 8), Color(0.97, 0.93, 0.83))

	# Central dome structure
	_rect(Vector2(28, 25), Vector2(44, 42), base_color)
	_rect(Vector2(30, 27), Vector2(40, 38), base_color.lightened(0.08))

	# Dome layers
	_rect(Vector2(25, 15), Vector2(50, 14), base_color.lightened(0.12))
	_rect(Vector2(30, 8), Vector2(40, 10), base_color.lightened(0.18))
	_rect(Vector2(35, 2), Vector2(30, 8), base_color.lightened(0.22))
	_rect(Vector2(40, -3), Vector2(20, 7), base_color.lightened(0.25))

	# Golden finial/spire
	_rect(Vector2(46, -12), Vector2(8, 11), Color(0.95, 0.85, 0.3))
	_rect(Vector2(48, -18), Vector2(4, 8), Color(0.98, 0.88, 0.35))
	_rect(Vector2(49, -22), Vector2(2, 5), Color(1.0, 0.9, 0.4))

	# Left minaret
	_rect(Vector2(5, 20), Vector2(18, 48), base_color.darkened(0.05))
	_rect(Vector2(7, 22), Vector2(14, 44), base_color)
	_rect(Vector2(8, 12), Vector2(12, 10), base_color.lightened(0.1))
	_rect(Vector2(10, 6), Vector2(8, 8), base_color.lightened(0.15))
	_rect(Vector2(12, 0), Vector2(4, 8), Color(0.92, 0.82, 0.28))
	_rect(Vector2(13, -4), Vector2(2, 5), Color(0.95, 0.85, 0.32))

	# Right minaret
	_rect(Vector2(77, 20), Vector2(18, 48), base_color.darkened(0.05))
	_rect(Vector2(79, 22), Vector2(14, 44), base_color)
	_rect(Vector2(80, 12), Vector2(12, 10), base_color.lightened(0.1))
	_rect(Vector2(82, 6), Vector2(8, 8), base_color.lightened(0.15))
	_rect(Vector2(84, 0), Vector2(4, 8), Color(0.92, 0.82, 0.28))
	_rect(Vector2(85, -4), Vector2(2, 5), Color(0.95, 0.85, 0.32))

	# Ornate arched entrance
	_rect(Vector2(38, 40), Vector2(24, 28), Color(0.1, 0.08, 0.05))
	_rect(Vector2(36, 35), Vector2(28, 8), base_color.lightened(0.15))
	_rect(Vector2(40, 42), Vector2(20, 24), Color(0.05, 0.03, 0.02))

	# Decorative arches on facade
	for i in range(3):
		_rect(Vector2(32 + i * 12, 30), Vector2(8, 12), Color(0.85, 0.92, 0.98))
		_rect(Vector2(33 + i * 12, 28), Vector2(6, 3), base_color.lightened(0.2))

	# Inlay patterns
	_rect(Vector2(30, 50), Vector2(40, 3), Color(0.9, 0.8, 0.25))
	_rect(Vector2(30, 58), Vector2(40, 2), Color(0.88, 0.78, 0.22))

	# Minaret windows
	for i in range(4):
		_rect(Vector2(10, 28 + i * 10), Vector2(8, 6), Color(0.8, 0.88, 0.95))
		_rect(Vector2(82, 28 + i * 10), Vector2(8, 6), Color(0.8, 0.88, 0.95))

	# Garden elements
	_rect(Vector2(2, 72), Vector2(10, 8), Color(0.25, 0.5, 0.25))
	_rect(Vector2(3, 68), Vector2(8, 6), Color(0.3, 0.55, 0.3))
	_rect(Vector2(88, 72), Vector2(10, 8), Color(0.25, 0.5, 0.25))
	_rect(Vector2(89, 68), Vector2(8, 6), Color(0.3, 0.55, 0.3))

	# Strong glow effect
	_add_glow(base_color, 0.5)

# ==================== HELPER FUNCTIONS ====================
func _rect(pos: Vector2, rect_size: Vector2, color: Color) -> ColorRect:
	var r = ColorRect.new()
	# Apply scale and offset for centering
	r.position = pos * _scale + _offset
	r.size = rect_size * _scale
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	building_container.add_child(r)
	return r

func _add_glow(color: Color, intensity: float) -> void:
	glow_effect = ColorRect.new()
	# Apply scale and offset for centering
	glow_effect.position = Vector2(-15, -15) * _scale + _offset
	glow_effect.size = Vector2(130, 110) * _scale
	glow_effect.color = Color(color.r, color.g, color.b, intensity * 0.25)
	glow_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow_effect.z_index = -2
	building_container.add_child(glow_effect)
	building_container.move_child(glow_effect, 0)

func _update_labels(building_name: String, coins_per_sec: float) -> void:
	if level_label:
		level_label.text = str(building_level)
	if name_label:
		name_label.text = building_name
	if coin_indicator:
		if coins_per_sec >= 1:
			coin_indicator.text = "+%.0f/s" % coins_per_sec
		else:
			coin_indicator.text = "+%.1f/s" % coins_per_sec

func _update_badge() -> void:
	if not level_badge:
		return
	for child in level_badge.get_children():
		if child is ColorRect:
			child.color = _get_badge_color()
			return
	if level_badge is ColorRect:
		level_badge.color = _get_badge_color()

func _get_badge_color() -> Color:
	if building_level >= 9:
		return Color(0.95, 0.8, 0.15, 0.98)
	elif building_level >= 7:
		return Color(0.65, 0.25, 0.75, 0.95)
	elif building_level >= 5:
		return Color(0.25, 0.55, 0.85, 0.95)
	elif building_level >= 3:
		return Color(0.25, 0.65, 0.35, 0.95)
	else:
		return Color(0.35, 0.35, 0.45, 0.92)

# ==================== INTERACTION ====================
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
	z_index = 100
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_ease(Tween.EASE_OUT)
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
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "position", original_position, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(self, "rotation", 0.1, 0.05)
	tween.tween_property(self, "rotation", -0.1, 0.05)
	tween.tween_property(self, "rotation", 0.0, 0.05)

func animate_merge() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.8, 1.2), 0.08)
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.08)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.06)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.06)
	if building_container:
		tween.parallel().tween_property(building_container, "modulate", Color(2, 2, 2, 1), 0.1)
		tween.tween_property(building_container, "modulate", Color(1, 1, 1, 1), 0.2)

func animate_spawn() -> void:
	scale = Vector2.ZERO
	modulate.a = 0
	rotation = -0.2
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.25)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(self, "rotation", 0.05, 0.25)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.15)

func animate_invalid_drop() -> void:
	var tween = create_tween()
	if building_container:
		tween.tween_property(building_container, "modulate", Color(1.5, 0.5, 0.5, 1), 0.1)
		tween.tween_property(building_container, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.parallel().tween_property(self, "position:x", position.x + 5, 0.03)
	tween.tween_property(self, "position:x", position.x - 5, 0.03)
	tween.tween_property(self, "position:x", position.x + 3, 0.03)
	tween.tween_property(self, "position:x", position.x, 0.03)

func get_center_position() -> Vector2:
	return position + size / 2

func get_building_color() -> Color:
	var data: Dictionary = GameManager.building_data.get(building_level, {})
	return data.get("color", Color.WHITE)
