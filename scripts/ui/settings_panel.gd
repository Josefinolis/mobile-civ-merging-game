extends PanelContainer
## SettingsPanel - Modal settings panel with SFX volume control and version info

signal closed

@onready var close_button: Button = $MarginContainer/VBox/Header/CloseButton
@onready var sfx_slider: HSlider = $MarginContainer/VBox/SFXRow/SFXSlider
@onready var sfx_toggle: CheckButton = $MarginContainer/VBox/SFXRow/SFXToggle
@onready var version_label: Label = $MarginContainer/VBox/VersionLabel

const APP_VERSION = "1.4.0"

func _ready() -> void:
	if sfx_slider:
		sfx_slider.value = AudioManager.get_sfx_volume() * 100
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	if sfx_toggle:
		sfx_toggle.button_pressed = AudioManager.is_sfx_enabled()
		sfx_toggle.toggled.connect(_on_sfx_toggled)

	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	if version_label:
		version_label.text = "Version " + APP_VERSION

	visible = false

func show_panel() -> void:
	if sfx_slider:
		sfx_slider.value = AudioManager.get_sfx_volume() * 100
	if sfx_toggle:
		sfx_toggle.button_pressed = AudioManager.is_sfx_enabled()

	visible = true
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func hide_panel() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): visible = false)

func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value / 100.0)

func _on_sfx_toggled(pressed: bool) -> void:
	if AudioManager.is_sfx_enabled() != pressed:
		AudioManager.toggle_sfx()

func _on_close_pressed() -> void:
	AudioManager.play_button_click()
	hide_panel()
	closed.emit()
