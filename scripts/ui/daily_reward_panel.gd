extends PanelContainer
## DailyRewardPanel - Modal panel showing daily rewards calendar

signal closed

@onready var close_button: Button = $MarginContainer/VBox/Header/CloseButton
@onready var title_label: Label = $MarginContainer/VBox/Header/TitleLabel
@onready var days_container: GridContainer = $MarginContainer/VBox/DaysContainer
@onready var claim_button: Button = $MarginContainer/VBox/ClaimButton
@onready var timer_label: Label = $MarginContainer/VBox/TimerLabel
@onready var streak_label: Label = $MarginContainer/VBox/StreakLabel

var day_panels: Array = []

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	if claim_button:
		claim_button.pressed.connect(_on_claim_pressed)

	# Conectar señales
	DailyRewardManager.reward_claimed.connect(_on_reward_claimed)

	# Crear calendario de días
	_create_day_panels()

	# Start hidden
	visible = false

func _process(_delta: float) -> void:
	if visible and timer_label:
		_update_timer()

func _create_day_panels() -> void:
	# Limpiar contenedor
	for child in days_container.get_children():
		child.queue_free()

	day_panels.clear()

	# Crear 7 paneles para cada día
	for day in range(7):
		var panel: PanelContainer = _create_day_panel(day)
		days_container.add_child(panel)
		day_panels.append(panel)

func _create_day_panel(day: int) -> PanelContainer:
	var rewards: Dictionary = DailyRewardManager.get_day_rewards(day)

	# Container principal
	var panel = PanelContainer.new()
	panel.name = "Day%d" % (day + 1)
	panel.custom_minimum_size = Vector2(75, 90)

	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2A2A3A")
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	# Día número
	var day_label = Label.new()
	day_label.name = "DayLabel"
	day_label.text = "Day %d" % (day + 1)
	day_label.add_theme_font_size_override("font_size", 11)
	day_label.add_theme_color_override("font_color", Color("#888899"))
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(day_label)

	# Icono de recompensa
	var icon_label = Label.new()
	icon_label.name = "IconLabel"
	if day == 6:
		icon_label.text = "x2"  # Día 7 es especial
	else:
		icon_label.text = "%d" % rewards.get("coins", 0)
	icon_label.add_theme_font_size_override("font_size", 18)
	icon_label.add_theme_color_override("font_color", Color("#FFD700"))
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)

	# Energía
	var energy_label = Label.new()
	energy_label.name = "EnergyLabel"
	energy_label.text = "+%d" % rewards.get("energy", 0)
	energy_label.add_theme_font_size_override("font_size", 12)
	energy_label.add_theme_color_override("font_color", Color("#4CAF50"))
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(energy_label)

	# Checkmark container (para días completados)
	var check_label = Label.new()
	check_label.name = "CheckLabel"
	check_label.text = ""
	check_label.add_theme_font_size_override("font_size", 16)
	check_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check_label.visible = false
	vbox.add_child(check_label)

	return panel

func _update_day_panels() -> void:
	var current_day: int = DailyRewardManager.get_current_day()
	var total_claimed: int = DailyRewardManager.get_total_days_claimed()
	var can_claim: bool = DailyRewardManager.is_reward_available()

	for i in range(day_panels.size()):
		var panel: PanelContainer = day_panels[i]
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()

		var vbox = panel.get_child(0)
		var check_label: Label = vbox.get_node("CheckLabel")

		# Calcular cuántas veces se ha completado el ciclo
		var cycles_completed: int = total_claimed / 7
		var days_in_current_cycle: int = total_claimed % 7

		if i < days_in_current_cycle:
			# Día ya reclamado en este ciclo
			style.bg_color = Color("#1A3A1A")
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.border_color = Color("#4CAF50")
			check_label.text = ""
			check_label.add_theme_color_override("font_color", Color("#4CAF50"))
			check_label.visible = true
		elif i == current_day and can_claim:
			# Día actual disponible para reclamar
			style.bg_color = Color("#3A3A1A")
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_color = Color("#FFD700")
			check_label.visible = false
		else:
			# Día futuro
			style.bg_color = Color("#2A2A3A")
			style.border_width_left = 0
			style.border_width_right = 0
			style.border_width_top = 0
			style.border_width_bottom = 0
			check_label.visible = false

		panel.add_theme_stylebox_override("panel", style)

func _update_claim_button() -> void:
	if not claim_button:
		return

	var can_claim: bool = DailyRewardManager.is_reward_available()
	var current_day: int = DailyRewardManager.get_current_day()
	var rewards: Dictionary = DailyRewardManager.get_day_rewards(current_day)

	if can_claim:
		claim_button.text = "CLAIM: %d + %d" % [rewards.get("coins", 0), rewards.get("energy", 0)]
		claim_button.disabled = false

		# Estilo activo
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color("#FFD700")
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_left = 8
		btn_style.corner_radius_bottom_right = 8
		claim_button.add_theme_stylebox_override("normal", btn_style)
		claim_button.add_theme_color_override("font_color", Color("#1A1A2E"))
	else:
		claim_button.text = "Come back tomorrow!"
		claim_button.disabled = true

		# Estilo desactivado
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color("#555555")
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_left = 8
		btn_style.corner_radius_bottom_right = 8
		claim_button.add_theme_stylebox_override("normal", btn_style)
		claim_button.add_theme_stylebox_override("disabled", btn_style)

func _update_timer() -> void:
	if not timer_label:
		return

	var can_claim: bool = DailyRewardManager.is_reward_available()

	if can_claim:
		timer_label.text = "Reward available!"
		timer_label.add_theme_color_override("font_color", Color("#4CAF50"))
	else:
		var time_str: String = DailyRewardManager.get_time_until_next_reward_string()
		timer_label.text = "Next reward in: %s" % time_str
		timer_label.add_theme_color_override("font_color", Color("#AAAAAA"))

func _update_streak() -> void:
	if not streak_label:
		return

	var total_days: int = DailyRewardManager.get_total_days_claimed()
	streak_label.text = "Total days: %d" % total_days

func show_panel() -> void:
	_update_day_panels()
	_update_claim_button()
	_update_timer()
	_update_streak()

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

func _on_claim_pressed() -> void:
	AudioManager.play_button_click()
	var rewards: Dictionary = DailyRewardManager.claim_reward()

	if not rewards.is_empty():
		# Animar el botón
		var tween = create_tween()
		tween.tween_property(claim_button, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(claim_button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_reward_claimed(_day: int, _rewards: Dictionary) -> void:
	_update_day_panels()
	_update_claim_button()
	_update_streak()
