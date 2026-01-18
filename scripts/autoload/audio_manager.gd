extends Node
## AudioManager - Handles all game audio with pre-generated procedural sounds

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

# Cached sounds (pre-generated at startup)
var _cached_sounds: Dictionary = {}
var _cached_music: AudioStreamWAV

func _ready() -> void:
	# Pre-generate all sounds at startup to avoid lag
	_pregenerate_sounds()

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

func _pregenerate_sounds() -> void:
	# Generate all sounds once at startup
	_cached_sounds["spawn"] = _generate_spawn_sound()
	_cached_sounds["merge"] = _generate_merge_sound()
	_cached_sounds["levelup"] = _generate_levelup_sound()
	_cached_sounds["click"] = _generate_click_sound()
	_cached_sounds["pickup"] = _generate_pickup_sound()
	_cached_sounds["drop"] = _generate_drop_sound()
	_cached_sounds["error"] = _generate_error_sound()
	_cached_sounds["coin"] = _generate_coin_sound()
	_cached_sounds["quest_complete"] = _generate_quest_complete_sound()
	_cached_sounds["achievement"] = _generate_achievement_sound()
	_cached_music = _generate_ambient_music()

func _get_available_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	# If all busy, return first one (will interrupt)
	return sfx_players[0]

# === SOUND EFFECTS ===

# Helper to play cached SFX with optional volume multiplier and pitch variation
func _play_sfx(sfx_key: String, volume_mult: float = 1.0, pitch_min: float = 1.0, pitch_max: float = 1.0) -> void:
	if not master_enabled or not sfx_enabled:
		return
	var player = _get_available_player()
	player.stream = _cached_sounds[sfx_key]
	player.volume_db = linear_to_db(sfx_volume * volume_mult)
	player.pitch_scale = randf_range(pitch_min, pitch_max) if pitch_min != pitch_max else 1.0
	player.play()

func play_spawn() -> void:
	_play_sfx("spawn", 0.6, 0.95, 1.05)

func play_merge() -> void:
	_play_sfx("merge", 0.8, 0.98, 1.02)

func play_level_up() -> void:
	_play_sfx("levelup")

func play_button_click() -> void:
	_play_sfx("click", 0.5, 0.98, 1.02)

func play_pickup() -> void:
	_play_sfx("pickup", 0.4, 0.95, 1.05)

func play_drop() -> void:
	_play_sfx("drop", 0.5)

func play_error() -> void:
	_play_sfx("error", 0.4)

func play_coin() -> void:
	_play_sfx("coin", 0.3, 0.9, 1.1)

func play_quest_complete() -> void:
	_play_sfx("quest_complete")

func play_achievement() -> void:
	_play_sfx("achievement", 1.2)

# === IMPROVED SOUND GENERATION ===

func _generate_spawn_sound() -> AudioStreamWAV:
	# Pleasant "pop" with harmonics - like a bubble
	var sample_rate = 44100
	var duration = 0.12
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

		# Rising frequency for pop effect
		var base_freq = 400 + progress * 600

		# Fundamental + harmonics for warmer sound
		var sample = sin(t * base_freq * TAU) * 0.6
		sample += sin(t * base_freq * 2 * TAU) * 0.25
		sample += sin(t * base_freq * 3 * TAU) * 0.1

		# Quick attack, smooth decay envelope
		var envelope = 1.0
		if progress < 0.05:
			envelope = progress / 0.05
		else:
			envelope = pow(1.0 - (progress - 0.05) / 0.95, 2.0)

		sample = sample * envelope * 0.4
		data[i] = int(clamp((sample * 0.5 + 0.5) * 255, 0, 255))

	audio.data = data
	return audio

func _generate_merge_sound() -> AudioStreamWAV:
	# Satisfying major chord with shimmer
	var sample_rate = 44100
	var duration = 0.25
	var samples = int(duration * sample_rate)
	var audio = AudioStreamWAV.new()
	audio.mix_rate = sample_rate
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(samples)

	# C major chord frequencies (C5, E5, G5)
	var frequencies = [523.25, 659.25, 783.99]

	for i in range(samples):
		var t = float(i) / sample_rate
		var progress = float(i) / samples

		var sample = 0.0
		for j in range(frequencies.size()):
			var freq = frequencies[j]
			# Add slight detuning for richness
			var detune = sin(t * 3.0 + j * 2.0) * 2.0
			# Fundamental
			sample += sin(t * (freq + detune) * TAU) * 0.4
			# Soft overtone
			sample += sin(t * (freq + detune) * 2 * TAU) * 0.15

		sample = sample / frequencies.size()

		# Envelope with quick attack, sustain, decay
		var envelope = 1.0
		if progress < 0.02:
			envelope = progress / 0.02
		elif progress < 0.3:
			envelope = 1.0
		else:
			envelope = pow(1.0 - (progress - 0.3) / 0.7, 1.5)

		sample = sample * envelope * 0.5
		data[i] = int(clamp((sample * 0.5 + 0.5) * 255, 0, 255))

	audio.data = data
	return audio

func _generate_levelup_sound() -> AudioStreamWAV:
	# Triumphant ascending arpeggio
	var sample_rate = 44100
	var note_duration = 0.1
	var frequencies = [523.25, 659.25, 783.99, 1046.5]  # C5, E5, G5, C6
	var total_duration = note_duration * frequencies.size() + 0.15
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

		var sample = 0.0

		# Layer multiple notes with overlap
		for note_idx in range(frequencies.size()):
			var note_start = note_idx * note_duration
			var note_end = note_start + note_duration * 2.0

			if t >= note_start and t < note_end:
				var note_t = t - note_start
				var note_progress = note_t / (note_duration * 2.0)
				var freq = frequencies[note_idx]

				# Note with harmonics
				var note_sample = sin(note_t * freq * TAU) * 0.5
				note_sample += sin(note_t * freq * 2 * TAU) * 0.2

				# Per-note envelope
				var note_env = 1.0
				if note_progress < 0.1:
					note_env = note_progress / 0.1
				else:
					note_env = pow(1.0 - (note_progress - 0.1) / 0.9, 2.0)

				sample += note_sample * note_env

		# Overall envelope
		var master_env = 1.0
		if overall_progress > 0.7:
			master_env = 1.0 - (overall_progress - 0.7) / 0.3

		sample = sample * master_env * 0.4
		data[i] = int(clamp((sample * 0.5 + 0.5) * 255, 0, 255))

	audio.data = data
	return audio

func _generate_click_sound() -> AudioStreamWAV:
	# Soft, pleasant click
	var sample_rate = 44100
	var duration = 0.05
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

		# High frequency click with quick decay
		var freq = 1200 - progress * 400
		var sample = sin(t * freq * TAU) * 0.5
		sample += sin(t * freq * 0.5 * TAU) * 0.3

		# Very quick envelope
		var envelope = pow(1.0 - progress, 3.0)

		sample = sample * envelope * 0.3
		data[i] = int(clamp((sample * 0.5 + 0.5) * 255, 0, 255))

	audio.data = data
	return audio

func _generate_pickup_sound() -> AudioStreamWAV:
	# Gentle rising tone - like picking up something light
	var sample_rate = 44100
	var duration = 0.08
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

		# Rising frequency
		var freq = 350 + progress * 250
		var sample = sin(t * freq * TAU) * 0.6
		sample += sin(t * freq * 2 * TAU) * 0.2

		# Smooth envelope
		var envelope = sin(progress * PI)

		sample = sample * envelope * 0.3
		data[i] = int(clamp((sample * 0.5 + 0.5) * 255, 0, 255))

	audio.data = data
	return audio

func _generate_drop_sound() -> AudioStreamWAV:
	# Soft thud - like placing something down
	var sample_rate = 44100
	var duration = 0.1
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

		# Low frequency thud with pitch drop
		var freq = 200 - progress * 100
		var sample = sin(t * freq * TAU) * 0.7
		sample += sin(t * freq * 0.5 * TAU) * 0.3

		# Quick decay envelope
		var envelope = pow(1.0 - progress, 2.5)

		sample = sample * envelope * 0.4
		data[i] = int(clamp((sample * 0.5 + 0.5) * 255, 0, 255))

	audio.data = data
	return audio

func _generate_error_sound() -> AudioStreamWAV:
	# Gentle "nope" sound - two descending tones
	var sample_rate = 44100
	var duration = 0.15
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

		# Two-tone descending
		var freq1 = 400 if progress < 0.5 else 300
		var sample = sin(t * freq1 * TAU) * 0.5
		sample += sin(t * freq1 * 0.5 * TAU) * 0.3

		# Envelope with gap between tones
		var envelope = 1.0
		if progress < 0.45:
			envelope = 1.0 - pow(progress / 0.45, 0.5) * 0.3
		elif progress < 0.55:
			envelope = 0.3
		else:
			envelope = 0.7 * pow(1.0 - (progress - 0.55) / 0.45, 2.0)

		sample = sample * envelope * 0.3
		data[i] = int(clamp((sample * 0.5 + 0.5) * 255, 0, 255))

	audio.data = data
	return audio

func _generate_coin_sound() -> AudioStreamWAV:
	# Pleasant coin ding
	var sample_rate = 44100
	var duration = 0.15
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

		# Bell-like sound with harmonics
		var freq = 880.0  # A5
		var sample = sin(t * freq * TAU) * 0.4
		sample += sin(t * freq * 2.0 * TAU) * 0.25
		sample += sin(t * freq * 3.0 * TAU) * 0.15
		sample += sin(t * freq * 4.0 * TAU) * 0.1

		# Bell envelope - quick attack, long decay
		var envelope = 1.0
		if progress < 0.01:
			envelope = progress / 0.01
		else:
			envelope = pow(1.0 - (progress - 0.01) / 0.99, 1.5)

		sample = sample * envelope * 0.35
		data[i] = int(clamp((sample * 0.5 + 0.5) * 255, 0, 255))

	audio.data = data
	return audio

func _generate_quest_complete_sound() -> AudioStreamWAV:
	# Celebratory fanfare
	var sample_rate = 44100
	var note_duration = 0.12
	var frequencies = [523.25, 659.25, 783.99, 1046.5, 1318.5]  # C5, E5, G5, C6, E6
	var total_duration = note_duration * frequencies.size() + 0.2
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

		var sample = 0.0

		for note_idx in range(frequencies.size()):
			var note_start = note_idx * note_duration
			var note_end = note_start + note_duration * 2.5

			if t >= note_start and t < note_end:
				var note_t = t - note_start
				var note_progress = note_t / (note_duration * 2.5)
				var freq = frequencies[note_idx]

				# Rich sound with harmonics
				var note_sample = sin(note_t * freq * TAU) * 0.4
				note_sample += sin(note_t * freq * 2 * TAU) * 0.2
				note_sample += sin(note_t * freq * 3 * TAU) * 0.1

				# Per-note envelope
				var note_env = 1.0
				if note_progress < 0.05:
					note_env = note_progress / 0.05
				else:
					note_env = pow(1.0 - (note_progress - 0.05) / 0.95, 1.5)

				sample += note_sample * note_env

		# Overall envelope
		var master_env = 1.0
		if overall_progress > 0.75:
			master_env = 1.0 - (overall_progress - 0.75) / 0.25

		sample = sample * master_env * 0.4
		data[i] = int(clamp((sample * 0.5 + 0.5) * 255, 0, 255))

	audio.data = data
	return audio

func _generate_achievement_sound() -> AudioStreamWAV:
	# Epic celebratory fanfare - longer and more dramatic
	var sample_rate = 44100
	var note_duration = 0.15
	# Dramatic ascending pattern with final chord
	var frequencies = [
		[392.00],  # G4 (dramatic start)
		[493.88],  # B4
		[587.33],  # D5
		[783.99],  # G5
		[783.99, 987.77, 1174.66],  # G5 major chord finale
	]
	var total_duration = note_duration * 4 + 0.5  # Extra time for final chord
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

		var sample = 0.0

		for note_idx in range(frequencies.size()):
			var note_start = note_idx * note_duration
			var is_final = note_idx == frequencies.size() - 1
			var this_duration = note_duration * 3.0 if is_final else note_duration * 1.8
			var note_end = note_start + this_duration

			if t >= note_start and t < note_end:
				var note_t = t - note_start
				var note_progress = note_t / this_duration
				var chord = frequencies[note_idx]

				for freq in chord:
					# Rich harmonics for epic sound
					var note_sample = sin(note_t * freq * TAU) * 0.35
					note_sample += sin(note_t * freq * 2 * TAU) * 0.2
					note_sample += sin(note_t * freq * 3 * TAU) * 0.1
					note_sample += sin(note_t * freq * 4 * TAU) * 0.05

					# Per-note envelope
					var note_env = 1.0
					if note_progress < 0.05:
						note_env = note_progress / 0.05
					elif is_final:
						# Final chord sustains longer
						if note_progress > 0.7:
							note_env = pow(1.0 - (note_progress - 0.7) / 0.3, 1.5)
					else:
						note_env = pow(1.0 - (note_progress - 0.05) / 0.95, 1.2)

					sample += note_sample * note_env / chord.size()

		# Overall envelope
		var master_env = 1.0
		if overall_progress > 0.85:
			master_env = 1.0 - (overall_progress - 0.85) / 0.15

		sample = sample * master_env * 0.5
		data[i] = int(clamp((sample * 0.5 + 0.5) * 255, 0, 255))

	audio.data = data
	return audio

# === MUSIC ===

func _start_background_music() -> void:
	if music_enabled and music_player and _cached_music:
		music_player.stream = _cached_music
		music_player.volume_db = linear_to_db(music_volume * 0.5)
		music_player.play()

func _on_music_finished() -> void:
	if music_enabled:
		_start_background_music()

func _generate_ambient_music() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 30.0
	var samples = int(duration * sample_rate)

	var audio = AudioStreamWAV.new()
	audio.mix_rate = sample_rate
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(samples)

	# Relaxing chord progression
	var chords = [
		[261.63, 329.63, 392.00],  # C major
		[220.00, 277.18, 329.63],  # A minor
		[246.94, 311.13, 369.99],  # B dim (softer)
		[196.00, 246.94, 293.66],  # G major
	]

	var chord_duration = duration / chords.size()
	var samples_per_chord = int(chord_duration * sample_rate)

	for i in range(samples):
		var t = float(i) / sample_rate
		var overall_progress = float(i) / samples

		var chord_index = int(i / samples_per_chord) % chords.size()
		var chord = chords[chord_index]
		var chord_progress = fmod(float(i), samples_per_chord) / samples_per_chord

		var sample = 0.0
		for j in range(chord.size()):
			var freq = chord[j]
			var detune = sin(t * 0.1 + j) * 1.5
			var tremolo = 0.85 + 0.15 * sin(t * (0.3 + j * 0.05))
			sample += sin(t * (freq + detune) * TAU) * tremolo

		sample = sample / chord.size()

		# Sub bass
		var bass_freq = chord[0] / 2.0
		sample += sin(t * bass_freq * TAU) * 0.25

		# Chord transition envelope
		var envelope = 1.0
		if chord_progress < 0.1:
			envelope = chord_progress / 0.1
		elif chord_progress > 0.9:
			envelope = (1.0 - chord_progress) / 0.1
		envelope = smoothstep(0.0, 1.0, envelope)

		# Master envelope
		var master_env = 1.0
		if overall_progress < 0.05:
			master_env = overall_progress / 0.05
		elif overall_progress > 0.95:
			master_env = (1.0 - overall_progress) / 0.05

		sample = sample * envelope * master_env * 0.25

		data[i] = int(clamp((sample * 0.5 + 0.5) * 255, 0, 255))

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
