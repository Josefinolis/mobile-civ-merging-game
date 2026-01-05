extends Node
## ParticleEffects - Creates visual feedback effects (Autoload)

func create_merge_particles(parent: Node, pos: Vector2, color: Color) -> void:
	# Create burst of particles on merge
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(8, 8)
		particle.position = pos - Vector2(4, 4)
		particle.color = color
		particle.z_index = 200
		parent.add_child(particle)

		# Random direction
		var angle = (i / 8.0) * TAU + randf() * 0.5
		var distance = randf_range(50, 100)
		var target_pos = pos + Vector2(cos(angle), sin(angle)) * distance

		# Animate particle
		var tween = particle.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target_pos, 0.4).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, 0.4)
		tween.tween_property(particle, "scale", Vector2(0.3, 0.3), 0.4)
		tween.set_parallel(false)
		tween.tween_callback(particle.queue_free)

func create_coin_particles(parent: Node, pos: Vector2, count: int = 5) -> void:
	# Create floating coin indicators
	for i in range(count):
		var coin = Label.new()
		coin.text = "+"
		coin.add_theme_color_override("font_color", Color.GOLD)
		coin.add_theme_font_size_override("font_size", 16)
		coin.position = pos + Vector2(randf_range(-20, 20), randf_range(-10, 10))
		coin.z_index = 200
		parent.add_child(coin)

		var target_pos = coin.position + Vector2(0, -40)

		var tween = coin.create_tween()
		tween.set_parallel(true)
		tween.tween_property(coin, "position", target_pos, 0.6).set_ease(Tween.EASE_OUT)
		tween.tween_property(coin, "modulate:a", 0.0, 0.6).set_delay(0.3)
		tween.set_parallel(false)
		tween.tween_callback(coin.queue_free)

func create_spawn_effect(parent: Node, pos: Vector2, effect_size: Vector2) -> void:
	# Create expanding ring effect
	var ring = ColorRect.new()
	ring.size = effect_size * 0.5
	ring.position = pos + effect_size * 0.25
	ring.color = Color(1, 1, 1, 0.5)
	ring.z_index = 50
	parent.add_child(ring)

	var tween = ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "size", effect_size * 1.5, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "position", pos - effect_size * 0.25, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)

func create_level_up_text(parent: Node, pos: Vector2, level: int, building_name: String) -> void:
	# Create floating level up text
	var label = Label.new()
	label.text = "Lv.%d %s!" % [level, building_name]
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.position = pos
	label.z_index = 250
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)

	var tween = label.create_tween()
	tween.tween_property(label, "position:y", pos.y - 50, 0.8).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.4)
	tween.tween_callback(label.queue_free)

func screen_shake(camera: Node, intensity: float = 5.0, duration: float = 0.2) -> void:
	if not camera:
		return
	var original_offset = Vector2.ZERO
	if camera.has_method("get_offset"):
		original_offset = camera.get_offset()

	var tween = camera.create_tween()
	var steps = int(duration / 0.02)
	for i in range(steps):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", offset, 0.02)
	tween.tween_property(camera, "offset", original_offset, 0.02)
