extends Node

# Procedural Sound Manager for K-Games 2
# Generates rich procedural audio streams in-memory (PCM 22050Hz Mono)

var player: AudioStreamPlayer = null
var sound_cache: Dictionary = {}
var sound_enabled: bool = true

func _ready():
	player = AudioStreamPlayer.new()
	player.bus = "Master"
	add_child(player)
	_generate_all_sounds()

func set_sound_enabled(enabled: bool):
	sound_enabled = enabled

func play(sound_id: String, pitch_rnd: float = 0.05):
	if not sound_enabled or not player:
		return
	if sound_cache.has(sound_id):
		var asp = AudioStreamPlayer.new()
		asp.stream = sound_cache[sound_id]
		asp.pitch_scale = 1.0 + randf_range(-pitch_rnd, pitch_rnd)
		add_child(asp)
		asp.finished.connect(asp.queue_free)
		asp.play()

func _generate_all_sounds():
	sound_cache["click"] = _generate_tone(880.0, 0.04, 0.3, "sine")
	sound_cache["select"] = _generate_tone(660.0, 0.08, 0.4, "sine")
	sound_cache["move"] = _generate_wood_tap()
	sound_cache["dice"] = _generate_dice_roll()
	sound_cache["card"] = _generate_card_flip()
	sound_cache["shoot"] = _generate_explosion()
	sound_cache["win"] = _generate_chime()

func _create_wav(samples: PackedByteArray, sample_rate: int = 22050) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = samples
	return wav

func _generate_tone(freq: float, duration: float, volume: float, waveform: String) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples)

	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var env = 1.0 - (float(i) / float(total_samples)) # Linear decay
		var sample_val = 0.0

		if waveform == "sine":
			sample_val = sin(TAU * freq * t)
		elif waveform == "square":
			sample_val = 1.0 if sin(TAU * freq * t) > 0.0 else -1.0
		elif waveform == "triangle":
			sample_val = 2.0 * abs(2.0 * (t * freq - floor(t * freq + 0.5))) - 1.0

		var byte_val = int(clamp((sample_val * env * volume * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		data[i] = byte_val

	return _create_wav(data, sample_rate)

func _generate_wood_tap() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.12
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples)

	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 35.0)
		var s = sin(TAU * 220.0 * t) * 0.6 + sin(TAU * 440.0 * t) * 0.3 + (randf() * 2.0 - 1.0) * 0.1
		var byte_val = int(clamp((s * env * 0.7 * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		data[i] = byte_val

	return _create_wav(data, sample_rate)

func _generate_dice_roll() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.28
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples)

	var rattle_freq = 520.0
	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 12.0)
		var bounce = sin(TAU * 14.0 * t) # Multi-bounce rhythm
		var noise = (randf() * 2.0 - 1.0) * 0.4
		var tone = sin(TAU * (rattle_freq + sin(TAU * 30.0 * t) * 80.0) * t) * 0.5
		var s = (tone + noise) * max(0.0, bounce)
		var byte_val = int(clamp((s * env * 0.7 * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		data[i] = byte_val

	return _create_wav(data, sample_rate)

func _generate_card_flip() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.09
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples)

	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 45.0)
		var noise = (randf() * 2.0 - 1.0) * 0.7
		var flick = sin(TAU * (1200.0 - t * 8000.0) * t) * 0.3
		var s = noise + flick
		var byte_val = int(clamp((s * env * 0.6 * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		data[i] = byte_val

	return _create_wav(data, sample_rate)

func _generate_explosion() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.35
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples)

	var last_noise = 0.0
	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 9.0)
		var white = randf() * 2.0 - 1.0
		# Low pass filter for deep rumble
		var brown = (last_noise + (0.08 * white)) / 1.08
		last_noise = brown
		var sub = sin(TAU * (90.0 - t * 150.0) * t) * 0.4
		var s = brown * 2.5 + sub
		var byte_val = int(clamp((s * env * 0.8 * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		data[i] = byte_val

	return _create_wav(data, sample_rate)

func _generate_chime() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.4
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples)

	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 7.0)
		var s = sin(TAU * 523.25 * t) * 0.4 + sin(TAU * 659.25 * t) * 0.3 + sin(TAU * 783.99 * t) * 0.3
		var byte_val = int(clamp((s * env * 0.7 * 0.5 + 0.5) * 255.0, 0.0, 255.0))
		data[i] = byte_val

	return _create_wav(data, sample_rate)
