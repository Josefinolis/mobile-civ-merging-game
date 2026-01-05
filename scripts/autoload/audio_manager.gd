extends Node
## AudioManager - Handles all game audio with procedurally generated sounds

signal settings_changed

# Audio players pool
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 8

# Music player
var music_player: AudioStreamPlayer
var music_enabled: bool = true
var music_volume: float = 0.4

# Sound settings
var sfx_volume: float = 0.7
var sfx_enabled: bool = true
var master_enabled: bool = true

func _ready() -> void:
	# Create pool of audio players for SFX
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)

	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)

	# Start background music after a short delay
	call_deferred("_start_background_music")

func _get_available_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	# If all busy, return first one (will interrupt)
	return sfx_players[0]

# === SOUND EFFECTS ===

func play_spawn() -> void:
	if not master_enabled or not sfx_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_spawn_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.6)
	player.pitch_scale = randf_range(0.95, 1.05)
	player.play()

func play_merge() -> void:
	if not master_enabled or not sfx_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_merge_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.8)
	player.pitch_scale = randf_range(0.98, 1.02)
	player.play()

func play_level_up() -> void:
	if not master_enabled or not sfx_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_levelup_sound()
	player.volume_db = linear_to_db(sfx_volume)
	player.play()

func play_button_click() -> void:
	if not master_enabled or not sfx_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_click_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.5)
	player.pitch_scale = randf_range(0.98, 1.02)
	player.play()

func play_pickup() -> void:
	if not master_enabled or not sfx_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_pickup_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.4)
	player.pitch_scale = randf_range(0.95, 1.05)
	player.play()

func play_drop() -> void:
	if not master_enabled or not sfx_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_drop_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.5)
	player.play()

func play_error() -> void:
	if not master_enabled or not sfx_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_error_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.4)
	player.play()

func play_coin() -> void:
	if not master_enabled or not sfx_enabled:
		return
	var player = _get_available_player()
	player.stream = _generate_coin_sound()
	player.volume_db = linear_to_db(sfx_volume * 0.3)
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()

func play_quest_complete() -> void:
	if not master_enabled or not sfx_enabled:
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

# === MUSIC ===

func _start_background_music() -> void:
	if music_enabled and music_player:
		music_player.stream = _generate_ambient_music()
		music_player.volume_db = linear_to_db(music_volume * 0.5)
		music_player.play()

func _on_music_finished() -> void:
	# Loop the music
	if music_enabled:
		_start_background_music()

func _generate_ambient_music() -> AudioStreamWAV:
	# Generate relaxing ambient music - slow evolving pads
	var sample_rate = 22050
	var duration = 30.0  # 30 seconds of music
	var samples = int(duration * sample_rate)

	var audio = AudioStreamWAV.new()
	audio.mix_rate = sample_rate
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(samples)

	# Chord progression (relaxing minor/major mix)
	var chords = [
		[261.63, 329.63, 392.00],  # C major
		[220.00, 277.18, 329.63],  # A minor
		[246.94, 311.13, 369.99],  # B minor (soft)
		[196.00, 246.94, 293.66],  # G major
	]

	var chord_duration = duration / chords.size()
	var samples_per_chord = int(chord_duration * sample_rate)

	for i in range(samples):
		var t = float(i) / sample_rate
		var overall_progress = float(i) / samples

		# Determine current chord
		var chord_index = int(i / samples_per_chord) % chords.size()
		var chord = chords[chord_index]
		var chord_progress = fmod(float(i), samples_per_chord) / samples_per_chord

		# Mix frequencies with slow LFO modulation
		var sample = 0.0
		for j in range(chord.size()):
			var freq = chord[j]
			# Add slight detuning for warmth
			var detune = sin(t * 0.1 + j) * 2.0
			# Slow tremolo
			var tremolo = 0.8 + 0.2 * sin(t * (0.5 + j * 0.1))
			sample += sin(t * (freq + detune) * TAU) * tremolo

		sample = sample / chord.size()

		# Add sub bass
		var bass_freq = chord[0] / 2.0
		sample += sin(t * bass_freq * TAU) * 0.3

		# Gentle envelope for chord transitions
		var envelope = 1.0
		if chord_progress < 0.1:
			envelope = chord_progress / 0.1
		elif chord_progress > 0.9:
			envelope = (1.0 - chord_progress) / 0.1
		envelope = smoothstep(0.0, 1.0, envelope)

		# Overall fade in/out
		var master_env = 1.0
		if overall_progress < 0.05:
			master_env = overall_progress / 0.05
		elif overall_progress > 0.95:
			master_env = (1.0 - overall_progress) / 0.05

		sample = sample * envelope * master_env * 0.3

		data[i] = int((sample * 0.5 + 0.5) * 255)

	audio.data = data
	return audio

func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

# === SETTINGS ===

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * 0.5)
	settings_changed.emit()

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	settings_changed.emit()

func toggle_music() -> void:
	music_enabled = not music_enabled
	if music_enabled:
		_start_background_music()
	elif music_player:
		music_player.stop()
	settings_changed.emit()

func toggle_sfx() -> void:
	sfx_enabled = not sfx_enabled
	settings_changed.emit()

func toggle_sound() -> void:
	master_enabled = not master_enabled
	if not master_enabled:
		if music_player:
			music_player.stop()
	else:
		if music_enabled:
			_start_background_music()
	settings_changed.emit()

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume

func is_music_enabled() -> bool:
	return music_enabled

func is_sfx_enabled() -> bool:
	return sfx_enabled
