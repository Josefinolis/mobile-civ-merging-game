extends Node
## AudioManager - Handles all game audio with procedurally generated sounds

# Audio players pool
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 8

# Sound settings
var sfx_volume: float = 0.7
var master_enabled: bool = true

func _ready() -> void:
	# Create pool of audio players for SFX
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)

func _get_available_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	# If all busy, return first one (will interrupt)
	return sfx_players[0]

# === SOUND EFFECTS ===

func play_spawn() -> void:
	if not master_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_spawn_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.6)
	player.pitch_scale = randf_range(0.95, 1.05)
	player.play()

func play_merge() -> void:
	if not master_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_merge_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.8)
	player.pitch_scale = randf_range(0.98, 1.02)
	player.play()

func play_level_up() -> void:
	if not master_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_levelup_sound()
	player.volume_db = linear_to_db(sfx_volume)
	player.play()

func play_button_click() -> void:
	if not master_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_click_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.5)
	player.pitch_scale = randf_range(0.98, 1.02)
	player.play()

func play_pickup() -> void:
	if not master_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_pickup_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.4)
	player.pitch_scale = randf_range(0.95, 1.05)
	player.play()

func play_drop() -> void:
	if not master_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_drop_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.5)
	player.play()

func play_error() -> void:
	if not master_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_error_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.4)
	player.play()

func play_coin() -> void:
	if not master_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_coin_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.3)
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()

func play_quest_complete() -> void:
	if not master_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_quest_complete_sound()
	player.volume_db = linear_to_db(sfx_volume)
	player.play()

# === SOUND GENERATION ===

func _generate_spawn_sound() -> AudioStreamWAV:
	# Rising "pop" sound
	return _create_tone(440, 0.08, 0.3, true, 1.5)

func _generate_merge_sound() -> AudioStreamWAV:
	# Satisfying "whoosh + ding" combination
	return _create_chord([523, 659, 784], 0.15, 0.5)  # C major chord

func _generate_levelup_sound() -> AudioStreamWAV:
	# Triumphant ascending notes
	return _create_arpeggio([523, 659, 784, 1047], 0.12, 0.4)

func _generate_click_sound() -> AudioStreamWAV:
	# Short click
	return _create_tone(800, 0.03, 0.2, false, 1.0)

func _generate_pickup_sound() -> AudioStreamWAV:
	# Soft rising tone
	return _create_tone(330, 0.05, 0.2, true, 1.3)

func _generate_drop_sound() -> AudioStreamWAV:
	# Soft thud
	return _create_tone(150, 0.08, 0.3, false, 0.7)

func _generate_error_sound() -> AudioStreamWAV:
	# Low buzz
	return _create_tone(180, 0.1, 0.3, false, 1.0)

func _generate_coin_sound() -> AudioStreamWAV:
	# High pitched ding
	return _create_tone(1200, 0.06, 0.2, false, 1.0)

func _generate_quest_complete_sound() -> AudioStreamWAV:
	# Fanfare-like arpeggio
	return _create_arpeggio([523, 659, 784, 1047, 1319], 0.1, 0.5)

# === AUDIO GENERATION HELPERS ===

func _create_tone(frequency: float, duration: float, volume: float, pitch_rise: bool, rise_factor: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(duration * sample_rate)
	var audio = AudioStreamWAV.new()
	audio.mix_rate = sample_rate
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(samples)

	for i in range(samples):
		var t = float(i) / sample_rate
		var progress = float(i) / samples

		# Frequency modulation for pitch rise
		var freq = frequency
		if pitch_rise:
			freq = frequency * (1.0 + (rise_factor - 1.0) * progress)

		# Generate sine wave
		var sample = sin(t * freq * TAU)

		# Apply envelope (attack-decay)
		var envelope = 1.0
		if progress < 0.1:
			envelope = progress / 0.1
		else:
			envelope = 1.0 - ((progress - 0.1) / 0.9)
		envelope = envelope * envelope  # Smoother decay

		sample = sample * envelope * volume

		# Convert to 8-bit (0-255, with 128 as center)
		data[i] = int((sample * 0.5 + 0.5) * 255)

	audio.data = data
	return audio

func _create_chord(frequencies: Array, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var samples = int(duration * sample_rate)
	var audio = AudioStreamWAV.new()
	audio.mix_rate = sample_rate
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(samples)

	for i in range(samples):
		var t = float(i) / sample_rate
		var progress = float(i) / samples

		# Mix all frequencies
		var sample = 0.0
		for freq in frequencies:
			sample += sin(t * freq * TAU)
		sample = sample / frequencies.size()

		# Envelope
		var envelope = 1.0
		if progress < 0.05:
			envelope = progress / 0.05
		else:
			envelope = 1.0 - ((progress - 0.05) / 0.95)
		envelope = pow(envelope, 1.5)

		sample = sample * envelope * volume
		data[i] = int((sample * 0.5 + 0.5) * 255)

	audio.data = data
	return audio

func _create_arpeggio(frequencies: Array, note_duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_duration = note_duration * frequencies.size()
	var samples = int(total_duration * sample_rate)
	var audio = AudioStreamWAV.new()
	audio.mix_rate = sample_rate
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(samples)

	for i in range(samples):
		var t = float(i) / sample_rate
		var overall_progress = float(i) / samples

		# Determine which note we're on
		var note_index = int(t / note_duration)
		note_index = min(note_index, frequencies.size() - 1)
		var note_t = fmod(t, note_duration)
		var note_progress = note_t / note_duration

		var freq = frequencies[note_index]
		var sample = sin(t * freq * TAU)

		# Per-note envelope
		var envelope = 1.0
		if note_progress < 0.1:
			envelope = note_progress / 0.1
		else:
			envelope = 1.0 - ((note_progress - 0.1) / 0.9) * 0.5

		# Overall fade out
		if overall_progress > 0.7:
			envelope *= 1.0 - ((overall_progress - 0.7) / 0.3)

		sample = sample * envelope * volume
		data[i] = int((sample * 0.5 + 0.5) * 255)

	audio.data = data
	return audio

# === SETTINGS ===

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)

func toggle_sound() -> void:
	master_enabled = not master_enabled
