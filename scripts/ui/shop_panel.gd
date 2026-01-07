extends PanelContainer
## ShopPanel - Modal shop panel for purchasing upgrades

signal closed

@onready var close_button: Button = $MarginContainer/VBox/Header/CloseButton
@onready var coins_label: Label = $MarginContainer/VBox/Header/CoinsLabel
@onready var upgrades_container: VBoxContainer = $MarginContainer/VBox/ScrollContainer/UpgradesContainer

var upgrade_items: Dictionary = {}

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Conectar señales
	GameManager.coins_changed.connect(_on_coins_changed)
	ShopManager.upgrade_purchased.connect(_on_upgrade_purchased)

	# Crear items de upgrade
	_create_upgrade_items()

	# Start hidden
	visible = false

func _create_upgrade_items() -> void:
	# Limpiar contenedor
	for child in upgrades_container.get_children():
		child.queue_free()

	upgrade_items.clear()

	# Crear un item por cada upgrade
	for upgrade_id in ShopManager.get_all_upgrade_ids():
		var item: PanelContainer = _create_upgrade_item(upgrade_id)
		upgrades_container.add_child(item)
		upgrade_items[upgrade_id] = item

func _create_upgrade_item(upgrade_id: String) -> PanelContainer:
	var data: Dictionary = ShopManager.get_upgrade_data(upgrade_id)

	# Container principal
	var panel = PanelContainer.new()
	panel.name = upgrade_id

	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2A2A3A")
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	# Icono
	var icon_label = Label.new()
	icon_label.text = data.get("icon", "?")
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.custom_minimum_size = Vector2(40, 40)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)

	# Info container
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	# Nombre y nivel
	var name_hbox = HBoxContainer.new()
	info_vbox.add_child(name_hbox)

	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = data.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_hbox.add_child(name_label)

	var level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color("#888899"))
	name_hbox.add_child(level_label)

	# Descripción
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = data.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	info_vbox.add_child(desc_label)

	# Valor actual
	var value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.add_theme_font_size_override("font_size", 13)
	value_label.add_theme_color_override("font_color", Color("#4CAF50"))
	info_vbox.add_child(value_label)

	# Botón de compra
	var buy_button = Button.new()
	buy_button.name = "BuyButton"
	buy_button.custom_minimum_size = Vector2(90, 45)
	buy_button.add_theme_font_size_override("font_size", 14)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color("#4CAF50")
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	buy_button.add_theme_stylebox_override("normal", btn_style)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color("#66BB6A")
	btn_hover.corner_radius_top_left = 6
	btn_hover.corner_radius_top_right = 6
	btn_hover.corner_radius_bottom_left = 6
	btn_hover.corner_radius_bottom_right = 6
	buy_button.add_theme_stylebox_override("hover", btn_hover)

	var btn_pressed = StyleBoxFlat.new()
	btn_pressed.bg_color = Color("#388E3C")
	btn_pressed.corner_radius_top_left = 6
	btn_pressed.corner_radius_top_right = 6
	btn_pressed.corner_radius_bottom_left = 6
	btn_pressed.corner_radius_bottom_right = 6
	buy_button.add_theme_stylebox_override("pressed", btn_pressed)

	var btn_disabled = StyleBoxFlat.new()
	btn_disabled.bg_color = Color("#555555")
	btn_disabled.corner_radius_top_left = 6
	btn_disabled.corner_radius_top_right = 6
	btn_disabled.corner_radius_bottom_left = 6
	btn_disabled.corner_radius_bottom_right = 6
	buy_button.add_theme_stylebox_override("disabled", btn_disabled)

	buy_button.pressed.connect(_on_buy_pressed.bind(upgrade_id))
	hbox.add_child(buy_button)

	return panel

func _update_upgrade_item(upgrade_id: String) -> void:
	if not upgrade_items.has(upgrade_id):
		return

	var panel: PanelContainer = upgrade_items[upgrade_id]
	var data: Dictionary = ShopManager.get_upgrade_data(upgrade_id)
	var current_level: int = ShopManager.get_upgrade_level(upgrade_id)
	var max_level: int = ShopManager.get_max_level(upgrade_id)
	var cost: int = ShopManager.get_upgrade_cost(upgrade_id)
	var current_value: float = ShopManager.get_upgrade_value(upgrade_id)

	# Obtener nodos
	var hbox = panel.get_child(0)
	var info_vbox = hbox.get_child(1)
	var name_hbox = info_vbox.get_child(0)
	var level_label: Label = name_hbox.get_node("LevelLabel")
	var value_label: Label = info_vbox.get_node("ValueLabel")
	var buy_button: Button = hbox.get_node("BuyButton")

	# Actualizar nivel
	level_label.text = " Lv.%d/%d" % [current_level, max_level]

	# Actualizar valor mostrado según el tipo
	var value_text: String = ""
	match upgrade_id:
		"coin_multiplier":
			value_text = "Current: x%.2f" % current_value
		"energy_capacity":
			value_text = "Current: %d max" % int(current_value)
		"energy_regen":
			value_text = "Current: %.1fs per energy" % current_value
		"spawn_level_chance":
			value_text = "Current: %.0f%% chance" % (current_value * 100)
		"offline_earnings":
			value_text = "Current: %.0f%% efficiency" % (current_value * 100)
		"critical_merge":
			value_text = "Current: %.0f%% chance" % (current_value * 100)

	value_label.text = value_text

	# Actualizar botón
	if current_level >= max_level:
		buy_button.text = "MAX"
		buy_button.disabled = true
	else:
		buy_button.text = "%d" % cost
		buy_button.disabled = not ShopManager.can_purchase(upgrade_id)

func _update_all_items() -> void:
	for upgrade_id in upgrade_items.keys():
		_update_upgrade_item(upgrade_id)

	# Actualizar monedas
	if coins_label:
		coins_label.text = "%d" % GameManager.coins

func show_panel() -> void:
	_update_all_items()
	visible = true

	# Animate in
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func hide_panel() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): visible = false)

func _on_close_pressed() -> void:
	AudioManager.play_button_click()
	hide_panel()
	closed.emit()

func _on_buy_pressed(upgrade_id: String) -> void:
	AudioManager.play_button_click()
	if ShopManager.purchase_upgrade(upgrade_id):
		# Animar el item comprado
		if upgrade_items.has(upgrade_id):
			var panel = upgrade_items[upgrade_id]
			var tween = create_tween()
			tween.tween_property(panel, "scale", Vector2(1.05, 1.05), 0.1)
			tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.1)

func _on_coins_changed(_new_amount: int) -> void:
	_update_all_items()

func _on_upgrade_purchased(_upgrade_id: String, _new_level: int) -> void:
	_update_all_items()
