extends PanelContainer
## IAPPanel - In-App Purchase panel for buying boost products

signal closed

@onready var close_button: Button = $MarginContainer/VBox/Header/CloseButton
@onready var coins_label: Label = $MarginContainer/VBox/Header/CoinsLabel
@onready var products_container: VBoxContainer = $MarginContainer/VBox/ScrollContainer/ProductsContainer
@onready var boost_status_label: Label = $MarginContainer/VBox/VIPStatus

var product_items: Dictionary = {}

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	IAPManager.purchase_completed.connect(_on_purchase_completed)
	IAPManager.purchase_failed.connect(_on_purchase_failed)
	GameManager.coins_changed.connect(_on_coins_changed)

	_create_product_items()
	visible = false

func _process(_delta: float) -> void:
	# Update active boosts status
	if boost_status_label and visible:
		var status_parts: Array = []
		if IAPManager.is_coin_boost_active():
			status_parts.append("x2 Money: %s" % IAPManager.get_coin_boost_remaining())
		if IAPManager.is_energy_boost_active():
			status_parts.append("x2 Energy: %s" % IAPManager.get_energy_boost_remaining())

		if status_parts.size() > 0:
			boost_status_label.text = " | ".join(status_parts)
			boost_status_label.add_theme_color_override("font_color", Color.GOLD)
		else:
			boost_status_label.text = ""

func _create_product_items() -> void:
	if not products_container:
		print("[IAP Panel] ERROR: products_container is null")
		return

	for child in products_container.get_children():
		child.queue_free()

	product_items.clear()

	var all_products = IAPManager.get_all_products()
	print("[IAP Panel] Products available: ", all_products.keys())

	# Add header for boosts
	_add_section_header("POWER BOOSTS (24h)")

	# Add all products in order
	var product_order = ["boost_coins", "boost_energy", "super_power"]
	for product_id in product_order:
		if all_products.has(product_id):
			var item = _create_product_item(product_id)
			products_container.add_child(item)
			product_items[product_id] = item
			print("[IAP Panel] Added product: ", product_id)

	print("[IAP Panel] Total items created: ", product_items.size())

func _add_section_header(title: String) -> void:
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.add_child(label)

	products_container.add_child(margin)

func _create_product_item(product_id: String) -> PanelContainer:
	var product = IAPManager.get_product(product_id)

	var panel = PanelContainer.new()
	panel.name = product_id

	var style = StyleBoxFlat.new()

	# Special styling for featured items
	if product.get("best_value", false):
		style.bg_color = Color("#3D5A3D")
		style.border_color = Color.GOLD
		style.set_border_width_all(2)
	elif product.get("popular", false):
		style.bg_color = Color("#3D4A5A")
		style.border_color = Color("#5588FF")
		style.set_border_width_all(2)
	else:
		style.bg_color = Color("#2A2A3A")

	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	panel.add_child(hbox)

	# Icon
	var icon_label = Label.new()
	icon_label.text = product.get("icon", "?")
	icon_label.add_theme_font_size_override("font_size", 36)
	icon_label.custom_minimum_size = Vector2(50, 50)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)

	# Info container
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(info_vbox)

	# Name row with badges
	var name_hbox = HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 8)
	info_vbox.add_child(name_hbox)

	var name_label = Label.new()
	name_label.text = product.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_hbox.add_child(name_label)

	# Bonus badge
	if product.has("bonus"):
		var bonus_label = Label.new()
		bonus_label.text = product.bonus
		bonus_label.add_theme_font_size_override("font_size", 14)
		bonus_label.add_theme_color_override("font_color", Color.GOLD)
		name_hbox.add_child(bonus_label)

	# Best value badge
	if product.get("best_value", false):
		var badge = Label.new()
		badge.text = "BEST VALUE"
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", Color.GOLD)
		name_hbox.add_child(badge)

	# Popular badge
	if product.get("popular", false):
		var badge = Label.new()
		badge.text = "POPULAR"
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", Color("#5588FF"))
		name_hbox.add_child(badge)

	# Description
	var desc_label = Label.new()
	desc_label.text = product.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	info_vbox.add_child(desc_label)

	# Buy button
	var buy_button = Button.new()
	buy_button.name = "BuyButton"
	buy_button.text = product.get("price", "$?.??")
	buy_button.custom_minimum_size = Vector2(90, 50)
	buy_button.add_theme_font_size_override("font_size", 18)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color("#FF9800")
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	buy_button.add_theme_stylebox_override("normal", btn_style)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color("#FFB74D")
	btn_hover.corner_radius_top_left = 8
	btn_hover.corner_radius_top_right = 8
	btn_hover.corner_radius_bottom_left = 8
	btn_hover.corner_radius_bottom_right = 8
	buy_button.add_theme_stylebox_override("hover", btn_hover)

	var btn_pressed = StyleBoxFlat.new()
	btn_pressed.bg_color = Color("#E65100")
	btn_pressed.corner_radius_top_left = 8
	btn_pressed.corner_radius_top_right = 8
	btn_pressed.corner_radius_bottom_left = 8
	btn_pressed.corner_radius_bottom_right = 8
	buy_button.add_theme_stylebox_override("pressed", btn_pressed)

	var btn_disabled = StyleBoxFlat.new()
	btn_disabled.bg_color = Color("#555555")
	btn_disabled.corner_radius_top_left = 8
	btn_disabled.corner_radius_top_right = 8
	btn_disabled.corner_radius_bottom_left = 8
	btn_disabled.corner_radius_bottom_right = 8
	buy_button.add_theme_stylebox_override("disabled", btn_disabled)

	buy_button.pressed.connect(_on_buy_pressed.bind(product_id))
	hbox.add_child(buy_button)

	return panel

func _update_product_item(product_id: String) -> void:
	if not product_items.has(product_id):
		return

	var panel = product_items[product_id]
	var hbox = panel.get_child(0)
	var buy_button: Button = hbox.get_node_or_null("BuyButton")

	if buy_button:
		var available = IAPManager.is_product_available(product_id)
		if not available:
			buy_button.text = "OWNED"
			buy_button.disabled = true
		else:
			var product = IAPManager.get_product(product_id)
			buy_button.text = product.get("price", "$?.??")
			buy_button.disabled = false

func _update_all_items() -> void:
	for product_id in product_items.keys():
		_update_product_item(product_id)

	if coins_label:
		coins_label.text = "%d" % GameManager.coins

func show_panel() -> void:
	print("[IAP Panel] show_panel called, items: ", product_items.size())
	_update_all_items()
	visible = true

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

func _on_buy_pressed(product_id: String) -> void:
	AudioManager.play_button_click()

	# Animate button
	if product_items.has(product_id):
		var panel = product_items[product_id]
		var tween = create_tween()
		tween.tween_property(panel, "scale", Vector2(0.95, 0.95), 0.1)
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.1)

	# Attempt purchase
	IAPManager.purchase(product_id)

func _on_purchase_completed(product_id: String) -> void:
	AudioManager.play_level_up()
	_update_all_items()

	# Show success animation
	if product_items.has(product_id):
		var panel = product_items[product_id]
		var tween = create_tween()
		tween.tween_property(panel, "modulate", Color.GREEN, 0.15)
		tween.tween_property(panel, "modulate", Color.WHITE, 0.3)

func _on_purchase_failed(product_id: String, reason: String) -> void:
	AudioManager.play_error()
	print("Purchase failed: ", product_id, " - ", reason)

func _on_coins_changed(_new_amount: int) -> void:
	if coins_label:
		coins_label.text = "%d" % GameManager.coins
