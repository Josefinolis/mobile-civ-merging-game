extends Control
class_name Building
## Building - Represents a single building on the grid with detailed procedural graphics

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

# Building visual elements (created procedurally)
var floors: Array = []
var roof_node: ColorRect = null
var base_node: ColorRect = null
var windows_container: Control = null
var door_node: ColorRect = null
var decorations: Array = []
var glow_effect: ColorRect = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_building_container()

func _setup_building_container() -> void:
	if not building_container:
		building_container = Control.new()
		building_container.name = "BuildingContainer"
		building_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		building_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(building_container)
		move_child(building_container, 1)  # After shadow

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

	var data: Dictionary = GameManager.building_data.get(building_level, {})
	var building_name: String = data.get("name", "Building")
	var base_color: Color = data.get("color", Color.WHITE)
	var coins_per_sec: float = data.get("coins_per_sec", 0)

	# Build based on level tier
	match building_level:
		1:
			_build_tent(base_color)
		2:
			_build_hut(base_color)
		3:
			_build_cabin(base_color)
		4:
			_build_house(base_color)
		5:
			_build_villa(base_color)
		6:
			_build_mansion(base_color)
		7:
			_build_tower(base_color)
		8:
			_build_skyscraper(base_color)
		9:
			_build_monument(base_color)
		10:
			_build_wonder(base_color)

	# Update labels
	_update_labels(building_name, coins_per_sec)
	_update_badge()

func _clear_building() -> void:
	floors.clear()
	decorations.clear()
	roof_node = null
	base_node = null
	door_node = null
	glow_effect = null

	for child in building_container.get_children():
		child.queue_free()

# ============ BUILDING TYPE BUILDERS ============

func _build_tent(base_color: Color) -> void:
	# Simple triangular tent
	var tent_base = _create_rect(Vector2(10, 70), Vector2(80, 25), base_color.darkened(0.2))

	# Tent body (trapezoid simulated with rects)
	var tent_left = _create_rect(Vector2(15, 30), Vector2(35, 40), base_color)
	var tent_right = _create_rect(Vector2(50, 30), Vector2(35, 40), base_color.lightened(0.1))

	# Tent peak
	var peak = _create_rect(Vector2(35, 15), Vector2(30, 20), base_color.darkened(0.1))

	# Tent opening
	var opening = _create_rect(Vector2(38, 50), Vector2(24, 20), Color(0.1, 0.1, 0.1, 0.8))

	# Pole
	var pole = _create_rect(Vector2(48, 5), Vector2(4, 15), Color(0.4, 0.3, 0.2))

func _build_hut(base_color: Color) -> void:
	# Circular hut with thatched roof
	var hut_body = _create_rect(Vector2(15, 40), Vector2(70, 50), base_color)
	_add_border(hut_body, base_color.darkened(0.3), 2)

	# Thatched roof (layered)
	var roof1 = _create_rect(Vector2(5, 20), Vector2(90, 15), base_color.darkened(0.2))
	var roof2 = _create_rect(Vector2(10, 10), Vector2(80, 15), base_color.darkened(0.3))
	var roof3 = _create_rect(Vector2(20, 2), Vector2(60, 12), base_color.darkened(0.4))

	# Door
	door_node = _create_rect(Vector2(38, 55), Vector2(24, 35), Color(0.3, 0.2, 0.1))
	_add_border(door_node, Color(0.2, 0.15, 0.08), 2)

	# Window
	_create_window(Vector2(65, 50), Vector2(16, 16), Color(0.9, 0.85, 0.6))

func _build_cabin(base_color: Color) -> void:
	# Log cabin style
	var cabin_body = _create_rect(Vector2(10, 35), Vector2(80, 55), base_color)

	# Log texture (horizontal lines)
	for i in range(5):
		var log_line = _create_rect(Vector2(10, 38 + i * 10), Vector2(80, 2), base_color.darkened(0.15))

	# Pitched roof
	var roof_left = _create_rect(Vector2(0, 15), Vector2(50, 25), base_color.darkened(0.3))
	var roof_right = _create_rect(Vector2(50, 15), Vector2(50, 25), base_color.darkened(0.4))
	var roof_cap = _create_rect(Vector2(40, 8), Vector2(20, 12), base_color.darkened(0.35))

	# Chimney
	var chimney = _create_rect(Vector2(70, 0), Vector2(15, 20), Color(0.5, 0.3, 0.25))
	var smoke = _create_rect(Vector2(73, -5), Vector2(8, 8), Color(0.7, 0.7, 0.7, 0.5))

	# Door
	door_node = _create_rect(Vector2(20, 55), Vector2(22, 35), Color(0.35, 0.2, 0.12))
	var door_frame = _create_rect(Vector2(18, 53), Vector2(26, 2), Color(0.25, 0.15, 0.08))

	# Windows (2)
	_create_window(Vector2(55, 50), Vector2(20, 20), Color(0.95, 0.9, 0.7))
	_create_window(Vector2(55, 50), Vector2(20, 20), Color(0.95, 0.9, 0.7), true)

func _build_house(base_color: Color) -> void:
	# Nice family house
	var house_body = _create_rect(Vector2(8, 30), Vector2(84, 60), base_color)
	_add_border(house_body, base_color.darkened(0.2), 2)

	# Foundation
	var foundation = _create_rect(Vector2(5, 85), Vector2(90, 8), Color(0.4, 0.4, 0.4))

	# Pitched roof with overhang
	var roof_base = _create_rect(Vector2(-5, 15), Vector2(110, 8), base_color.darkened(0.35))
	var roof_left = _create_rect(Vector2(0, 5), Vector2(50, 18), base_color.darkened(0.3))
	var roof_right = _create_rect(Vector2(50, 5), Vector2(50, 18), base_color.darkened(0.4))

	# Chimney with detail
	var chimney = _create_rect(Vector2(72, -5), Vector2(14, 25), Color(0.6, 0.35, 0.3))
	var chimney_cap = _create_rect(Vector2(70, -8), Vector2(18, 5), Color(0.5, 0.3, 0.25))

	# Door with porch
	var porch = _create_rect(Vector2(15, 82), Vector2(35, 6), Color(0.45, 0.35, 0.25))
	door_node = _create_rect(Vector2(22, 52), Vector2(20, 33), Color(0.4, 0.25, 0.15))
	var door_window = _create_rect(Vector2(27, 56), Vector2(10, 12), Color(0.8, 0.9, 1.0, 0.7))

	# Windows with frames (3)
	_create_framed_window(Vector2(55, 45), Vector2(24, 28), Color(0.85, 0.92, 1.0))
	_create_framed_window(Vector2(55, 45), Vector2(24, 28), Color(0.85, 0.92, 1.0))

	# Garage door hint
	var garage = _create_rect(Vector2(60, 58), Vector2(28, 32), Color(0.5, 0.5, 0.55))
	var garage_lines = _create_rect(Vector2(60, 68), Vector2(28, 2), Color(0.4, 0.4, 0.45))

func _build_villa(base_color: Color) -> void:
	# Elegant villa with multiple sections
	# Main body
	var main = _create_rect(Vector2(5, 25), Vector2(60, 65), base_color)
	_add_border(main, base_color.darkened(0.15), 2)

	# Side wing
	var wing = _create_rect(Vector2(60, 40), Vector2(35, 50), base_color.lightened(0.05))
	_add_border(wing, base_color.darkened(0.1), 2)

	# Elegant roof
	var main_roof = _create_rect(Vector2(0, 10), Vector2(70, 20), base_color.darkened(0.25))
	var wing_roof = _create_rect(Vector2(55, 28), Vector2(45, 15), base_color.darkened(0.3))

	# Decorative elements
	var cornice = _create_rect(Vector2(3, 23), Vector2(64, 4), Color.WHITE.darkened(0.1))
	var pillar1 = _create_rect(Vector2(8, 45), Vector2(6, 45), Color.WHITE.darkened(0.05))
	var pillar2 = _create_rect(Vector2(52, 45), Vector2(6, 45), Color.WHITE.darkened(0.05))

	# Grand door
	door_node = _create_rect(Vector2(25, 55), Vector2(18, 35), Color(0.3, 0.2, 0.1))
	var door_arch = _create_rect(Vector2(23, 50), Vector2(22, 8), Color(0.35, 0.25, 0.15))

	# Multiple elegant windows
	_create_framed_window(Vector2(10, 35), Vector2(16, 22), Color(0.9, 0.95, 1.0))
	_create_framed_window(Vector2(42, 35), Vector2(16, 22), Color(0.9, 0.95, 1.0))
	_create_framed_window(Vector2(70, 50), Vector2(18, 24), Color(0.9, 0.95, 1.0))

	# Garden hint
	var garden = _create_rect(Vector2(0, 88), Vector2(100, 6), Color(0.3, 0.5, 0.25))

func _build_mansion(base_color: Color) -> void:
	# Grand mansion with towers
	# Central body
	var central = _create_rect(Vector2(15, 20), Vector2(70, 70), base_color)

	# Left tower
	var tower_l = _create_rect(Vector2(0, 10), Vector2(20, 80), base_color.darkened(0.05))
	var tower_l_roof = _create_rect(Vector2(-2, 0), Vector2(24, 15), base_color.darkened(0.3))
	var tower_l_cap = _create_rect(Vector2(5, -5), Vector2(10, 8), base_color.darkened(0.35))

	# Right tower
	var tower_r = _create_rect(Vector2(80, 10), Vector2(20, 80), base_color.darkened(0.05))
	var tower_r_roof = _create_rect(Vector2(78, 0), Vector2(24, 15), base_color.darkened(0.3))
	var tower_r_cap = _create_rect(Vector2(85, -5), Vector2(10, 8), base_color.darkened(0.35))

	# Central roof
	var main_roof = _create_rect(Vector2(12, 8), Vector2(76, 18), base_color.darkened(0.25))

	# Ornate entrance
	var entrance = _create_rect(Vector2(35, 50), Vector2(30, 40), base_color.lightened(0.1))
	door_node = _create_rect(Vector2(40, 60), Vector2(20, 30), Color(0.25, 0.15, 0.08))
	var door_detail = _create_rect(Vector2(42, 62), Vector2(16, 3), Color(0.5, 0.4, 0.2))

	# Grand columns
	for i in range(4):
		var col = _create_rect(Vector2(20 + i * 20, 30), Vector2(5, 60), Color.WHITE.darkened(0.1))

	# Many windows
	_create_ornate_window(Vector2(5, 35), Vector2(12, 18), Color(0.95, 0.98, 1.0))
	_create_ornate_window(Vector2(22, 28), Vector2(14, 20), Color(0.95, 0.98, 1.0))
	_create_ornate_window(Vector2(64, 28), Vector2(14, 20), Color(0.95, 0.98, 1.0))
	_create_ornate_window(Vector2(84, 35), Vector2(12, 18), Color(0.95, 0.98, 1.0))

func _build_tower(base_color: Color) -> void:
	# Modern tower building
	# Base
	var tower_base = _create_rect(Vector2(20, 75), Vector2(60, 18), Color(0.3, 0.3, 0.35))

	# Main tower body with gradient effect
	for i in range(6):
		var floor_color = base_color.lerp(base_color.lightened(0.2), i / 6.0)
		var floor_rect = _create_rect(Vector2(22, 12 + i * 10), Vector2(56, 12), floor_color)
		if i % 2 == 0:
			_add_border(floor_rect, base_color.darkened(0.1), 1)
		floors.append(floor_rect)

	# Glass facade effect
	for i in range(5):
		for j in range(3):
			var win = _create_rect(Vector2(28 + j * 16, 18 + i * 12), Vector2(12, 8), Color(0.7, 0.85, 0.95, 0.9))

	# Roof with antenna
	var roof = _create_rect(Vector2(18, 5), Vector2(64, 10), base_color.darkened(0.3))
	var antenna = _create_rect(Vector2(48, -8), Vector2(4, 15), Color(0.5, 0.5, 0.55))
	var antenna_tip = _create_rect(Vector2(46, -12), Vector2(8, 5), Color(0.6, 0.2, 0.2))

	# Entrance
	var entrance = _create_rect(Vector2(35, 78), Vector2(30, 15), Color(0.2, 0.2, 0.25))
	var door_glass = _create_rect(Vector2(40, 80), Vector2(20, 10), Color(0.6, 0.8, 0.9, 0.8))

func _build_skyscraper(base_color: Color) -> void:
	# Impressive skyscraper
	# Foundation
	var foundation = _create_rect(Vector2(10, 82), Vector2(80, 12), Color(0.25, 0.25, 0.3))

	# Main building with setbacks
	var section1 = _create_rect(Vector2(12, 55), Vector2(76, 30), base_color)
	var section2 = _create_rect(Vector2(18, 25), Vector2(64, 32), base_color.lightened(0.05))
	var section3 = _create_rect(Vector2(25, 5), Vector2(50, 22), base_color.lightened(0.1))

	# Glass windows grid
	for section in [[14, 58, 72, 25], [20, 28, 60, 28], [27, 8, 46, 18]]:
		for i in range(int(section[3] / 8)):
			for j in range(int(section[2] / 12)):
				var wx = section[0] + 4 + j * 12
				var wy = section[1] + 3 + i * 8
				if wx < section[0] + section[2] - 8 and wy < section[1] + section[3] - 5:
					_create_rect(Vector2(wx, wy), Vector2(8, 5), Color(0.65, 0.8, 0.92, 0.95))

	# Spire
	var spire_base = _create_rect(Vector2(42, -2), Vector2(16, 10), base_color.darkened(0.2))
	var spire = _create_rect(Vector2(47, -15), Vector2(6, 15), Color(0.6, 0.6, 0.65))
	var spire_tip = _create_rect(Vector2(48, -20), Vector2(4, 6), Color(0.7, 0.2, 0.2))

	# Entrance lobby
	var lobby = _create_rect(Vector2(30, 85), Vector2(40, 10), Color(0.15, 0.15, 0.2))
	var lobby_glass = _create_rect(Vector2(35, 86), Vector2(30, 8), Color(0.5, 0.7, 0.85, 0.7))

func _build_monument(base_color: Color) -> void:
	# Ancient monument/temple style
	# Base platform
	var platform1 = _create_rect(Vector2(0, 80), Vector2(100, 14), Color(0.7, 0.65, 0.5))
	var platform2 = _create_rect(Vector2(5, 70), Vector2(90, 12), Color(0.75, 0.7, 0.55))

	# Main structure
	var main = _create_rect(Vector2(15, 25), Vector2(70, 48), base_color)

	# Grand columns
	for i in range(5):
		var col = _create_rect(Vector2(18 + i * 15, 28), Vector2(8, 44), Color(0.9, 0.85, 0.7))
		var cap = _create_rect(Vector2(16 + i * 15, 25), Vector2(12, 5), Color(0.85, 0.8, 0.65))

	# Triangular roof (simulated)
	var roof_l = _create_rect(Vector2(10, 12), Vector2(40, 16), base_color.darkened(0.15))
	var roof_r = _create_rect(Vector2(50, 12), Vector2(40, 16), base_color.darkened(0.2))
	var roof_peak = _create_rect(Vector2(40, 5), Vector2(20, 12), base_color.darkened(0.1))

	# Golden decorations
	var gold_trim = _create_rect(Vector2(12, 23), Vector2(76, 4), Color(0.85, 0.7, 0.2))
	var gold_peak = _create_rect(Vector2(45, 2), Vector2(10, 8), Color(0.9, 0.75, 0.25))

	# Inner sanctum
	var inner = _create_rect(Vector2(35, 40), Vector2(30, 32), Color(0.1, 0.08, 0.05))
	var statue = _create_rect(Vector2(43, 45), Vector2(14, 25), Color(0.8, 0.7, 0.3))

	# Glow effect
	_add_glow(base_color, 0.3)

func _build_wonder(base_color: Color) -> void:
	# Magnificent wonder of the world
	# Grand base
	var base1 = _create_rect(Vector2(-5, 82), Vector2(110, 15), Color(0.8, 0.75, 0.6))
	var base2 = _create_rect(Vector2(0, 72), Vector2(100, 12), Color(0.85, 0.8, 0.65))
	var base3 = _create_rect(Vector2(5, 64), Vector2(90, 10), Color(0.9, 0.85, 0.7))

	# Central spire/dome
	var central = _create_rect(Vector2(30, 20), Vector2(40, 46), base_color)
	var dome_base = _create_rect(Vector2(25, 10), Vector2(50, 15), base_color.lightened(0.1))
	var dome_mid = _create_rect(Vector2(32, 2), Vector2(36, 12), base_color.lightened(0.15))
	var dome_top = _create_rect(Vector2(40, -5), Vector2(20, 10), base_color.lightened(0.2))
	var spire = _create_rect(Vector2(47, -15), Vector2(6, 12), Color(0.9, 0.8, 0.3))

	# Side towers
	var tower_l = _create_rect(Vector2(5, 30), Vector2(22, 35), base_color.darkened(0.05))
	var tower_l_top = _create_rect(Vector2(8, 18), Vector2(16, 15), base_color)
	var tower_l_cap = _create_rect(Vector2(12, 10), Vector2(8, 10), Color(0.85, 0.75, 0.3))

	var tower_r = _create_rect(Vector2(73, 30), Vector2(22, 35), base_color.darkened(0.05))
	var tower_r_top = _create_rect(Vector2(76, 18), Vector2(16, 15), base_color)
	var tower_r_cap = _create_rect(Vector2(80, 10), Vector2(8, 10), Color(0.85, 0.75, 0.3))

	# Intricate details
	for i in range(3):
		_create_rect(Vector2(35 + i * 10, 25), Vector2(8, 12), Color(0.9, 0.95, 1.0, 0.9))

	# Golden ornaments
	var orn1 = _create_rect(Vector2(20, 62), Vector2(60, 4), Color(0.9, 0.8, 0.25))
	var orn2 = _create_rect(Vector2(28, 18), Vector2(44, 3), Color(0.9, 0.8, 0.25))

	# Grand entrance
	var entrance = _create_rect(Vector2(38, 50), Vector2(24, 16), Color(0.15, 0.1, 0.05))
	var arch = _create_rect(Vector2(36, 46), Vector2(28, 6), Color(0.85, 0.75, 0.3))

	# Strong glow effect
	_add_glow(base_color, 0.5)

	# Particle hint (animated in _process if needed)
	decorations.append({"type": "sparkle", "color": Color(1, 0.95, 0.5)})

# ============ HELPER FUNCTIONS ============

func _create_rect(pos: Vector2, rect_size: Vector2, color: Color) -> ColorRect:
	var rect = ColorRect.new()
	rect.position = pos
	rect.size = rect_size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	building_container.add_child(rect)
	return rect

func _add_border(rect: ColorRect, border_color: Color, width: int) -> void:
	var border = ColorRect.new()
	border.position = Vector2(-width, -width)
	border.size = rect.size + Vector2(width * 2, width * 2)
	border.color = border_color
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.z_index = -1
	rect.add_child(border)

func _create_window(pos: Vector2, win_size: Vector2, color: Color, with_cross: bool = false) -> ColorRect:
	var win = _create_rect(pos, win_size, color)

	# Window frame
	var frame = ColorRect.new()
	frame.position = Vector2(-2, -2)
	frame.size = win_size + Vector2(4, 4)
	frame.color = Color(0.25, 0.2, 0.15)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.z_index = -1
	win.add_child(frame)

	if with_cross:
		var h_bar = ColorRect.new()
		h_bar.position = Vector2(0, win_size.y / 2 - 1)
		h_bar.size = Vector2(win_size.x, 2)
		h_bar.color = Color(0.3, 0.25, 0.2)
		h_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		win.add_child(h_bar)

		var v_bar = ColorRect.new()
		v_bar.position = Vector2(win_size.x / 2 - 1, 0)
		v_bar.size = Vector2(2, win_size.y)
		v_bar.color = Color(0.3, 0.25, 0.2)
		v_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		win.add_child(v_bar)

	return win

func _create_framed_window(pos: Vector2, win_size: Vector2, color: Color) -> ColorRect:
	var win = _create_window(pos, win_size, color, true)

	# Decorative top
	var top = ColorRect.new()
	top.position = Vector2(-4, -6)
	top.size = Vector2(win_size.x + 8, 5)
	top.color = Color(0.35, 0.3, 0.25)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win.add_child(top)

	return win

func _create_ornate_window(pos: Vector2, win_size: Vector2, color: Color) -> ColorRect:
	var win = _create_framed_window(pos, win_size, color)

	# Ornate shutters
	var shutter_l = ColorRect.new()
	shutter_l.position = Vector2(-8, 0)
	shutter_l.size = Vector2(5, win_size.y)
	shutter_l.color = Color(0.4, 0.35, 0.3)
	shutter_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win.add_child(shutter_l)

	var shutter_r = ColorRect.new()
	shutter_r.position = Vector2(win_size.x + 3, 0)
	shutter_r.size = Vector2(5, win_size.y)
	shutter_r.color = Color(0.4, 0.35, 0.3)
	shutter_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win.add_child(shutter_r)

	return win

func _add_glow(color: Color, intensity: float) -> void:
	glow_effect = ColorRect.new()
	glow_effect.position = Vector2(-10, -10)
	glow_effect.size = Vector2(120, 120)
	glow_effect.color = Color(color.r, color.g, color.b, intensity * 0.3)
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

	# Find the ColorRect child of level_badge
	for child in level_badge.get_children():
		if child is ColorRect:
			child.color = _get_badge_color()
			return

	# If level_badge itself is a ColorRect
	if level_badge is ColorRect:
		level_badge.color = _get_badge_color()

func _get_badge_color() -> Color:
	if building_level >= 9:
		return Color(0.9, 0.75, 0.1, 0.95)  # Gold
	elif building_level >= 7:
		return Color(0.6, 0.2, 0.7, 0.95)  # Purple
	elif building_level >= 5:
		return Color(0.2, 0.5, 0.8, 0.95)  # Blue
	elif building_level >= 3:
		return Color(0.2, 0.6, 0.3, 0.95)  # Green
	else:
		return Color(0.3, 0.3, 0.4, 0.9)  # Gray

# ============ INTERACTION HANDLERS ============

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
