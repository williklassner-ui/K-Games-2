extends Node

# High-Fidelity Acoustic Sound Manager for K-Games 2
# Generates rich, organic, studio-grade 16-bit 44.1kHz audio streams in-memory
# Zero synthetic beeps - all sounds use physical acoustic modeling & harmonic synthesis

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

func play(sound_id: String, pitch_rnd: float = 0.04):
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
	sound_cache["click"] = _generate_click()
	sound_cache["select"] = _generate_select()
	sound_cache["move"] = _generate_wood_tap()
	sound_cache["dice"] = _generate_dice_roll()
	sound_cache["card"] = _generate_card_flip()
	sound_cache["shoot"] = _generate_explosion()
	sound_cache["win"] = _generate_chime()
	sound_cache["splash"] = _generate_splash()
	sound_cache["miss"] = _generate_splash()
	sound_cache["twist"] = _generate_twist()
	sound_cache["carrot"] = _generate_twist()
	sound_cache["loss"] = _generate_loss()

func _create_wav(samples: PackedByteArray, sample_rate: int = 44100) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = samples
	return wav

# 1. Haptischer, weicher UI-Klick (Soft Pop - absolut kein Gepiepse, dezent und edel)
func _generate_click() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.024
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)

	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var attack = min(1.0, t / 0.001)
		var decay = exp(-t * 220.0)
		var env = attack * decay
		
		# Weicher Klick-Resonanzkörper (720Hz & 1350Hz) mit mikro-gedämpftem Rauschimpuls
		var res1 = sin(TAU * 720.0 * t) * 0.45
		var res2 = sin(TAU * 1350.0 * t) * 0.25
		var click_tap = (randf() * 2.0 - 1.0) * 0.15 * exp(-t * 500.0)
		var sample_val = (res1 + res2 + click_tap) * env * 0.42

		var s16 = int(clamp(sample_val, -1.0, 1.0) * 32760.0)
		data.encode_s16(i * 2, s16)

	return _create_wav(data, sample_rate)

# 2. Edler Marimba- / Holz-Akzent (Warmer weicher Ton, organisch statt Synthesizer-Pieps)
func _generate_select() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.11
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)

	# Rosewood Marimba Bar Modellierung (G4 392Hz mit warmem Resonanzunterton 196Hz)
	var f0 = 392.0
	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var attack = min(1.0, t / 0.0015)
		var decay = exp(-t * 32.0)
		var env = attack * decay

		var mallet = (randf() * 2.0 - 1.0) * 0.12 * exp(-t * 280.0)
		var h1 = sin(TAU * f0 * t) * 0.55
		var h_sub = sin(TAU * (f0 * 0.5) * t) * 0.25
		var h2 = sin(TAU * (f0 * 2.0) * t) * 0.12
		var h3 = sin(TAU * (f0 * 3.0) * t) * 0.05
		var sample_val = (h1 + h_sub + h2 + h3 + mallet) * env * 0.5

		var s16 = int(clamp(sample_val, -1.0, 1.0) * 32760.0)
		data.encode_s16(i * 2, s16)

	return _create_wav(data, sample_rate)

# 3. Akustischer Holz-Schachfiguren-/Spielstein-Zug auf Samt-Holzbrett
func _generate_wood_tap() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.16
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)

	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		# Phase 1: sanftes Schieben über Samt/Filz (0 bis 25ms)
		var slide = (randf() * 2.0 - 1.0) * 0.08 * exp(-t * 80.0)

		# Phase 2: Schwerer Holz-Aufsetzer "Tock" (tiefe Holzkorpus-Resonanz 145Hz + 360Hz)
		var t_impact = max(0.0, t - 0.012)
		var env_impact = exp(-t_impact * 30.0) if t >= 0.012 else 0.0
		var wood_body = sin(TAU * 145.0 * t_impact) * 0.5 + sin(TAU * 360.0 * t_impact) * 0.35 + sin(TAU * 820.0 * t_impact) * 0.15
		var tap_thump = wood_body * env_impact

		var sample_val = (slide + tap_thump) * 0.65
		var s16 = int(clamp(sample_val, -1.0, 1.0) * 32760.0)
		data.encode_s16(i * 2, s16)

	return _create_wav(data, sample_rate)

# 4. Echtes Würfeln: Mehrfaches physikalisches Taumeln & Klackern der Würfel
func _generate_dice_roll() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.44
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)

	# 5 aufeinanderfolgende Aufprall-Ereignisse mit abnehmender Intensität und leicht wechselnden Frequenzen
	var impacts = [
		{"time": 0.00, "amp": 0.85, "freq": 780.0, "decay": 60.0},
		{"time": 0.07, "amp": 0.65, "freq": 910.0, "decay": 68.0},
		{"time": 0.15, "amp": 0.48, "freq": 650.0, "decay": 75.0},
		{"time": 0.23, "amp": 0.32, "freq": 860.0, "decay": 85.0},
		{"time": 0.31, "amp": 0.18, "freq": 720.0, "decay": 95.0}
	]

	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var sample_val = 0.0

		for imp in impacts:
			var dt = t - imp["time"]
			if dt >= 0.0 and dt < 0.12:
				var env = exp(-dt * imp["decay"])
				var click_noise = (randf() * 2.0 - 1.0) * 0.2 * exp(-dt * 300.0)
				var tone = sin(TAU * imp["freq"] * dt) * 0.5 + sin(TAU * (imp["freq"] * 0.35) * dt) * 0.3
				sample_val += (tone + click_noise) * env * imp["amp"]

		# Brettesonanz (weicher Tischunterton)
		var table_rumble = sin(TAU * 160.0 * t) * 0.08 * exp(-t * 8.0)
		sample_val = (sample_val + table_rumble) * 0.5

		var s16 = int(clamp(sample_val, -1.0, 1.0) * 32760.0)
		data.encode_s16(i * 2, s16)

	return _create_wav(data, sample_rate)

# 5. Realistisches Karten-Gleiten & Schnappen (Card Slide & Crisp Snap)
func _generate_card_flip() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.14
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)

	var last_noise = 0.0
	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var sample_val = 0.0

		# Phase 1: Reibungsgeräusch der Karte auf dem Spieltuch
		var raw_noise = randf() * 2.0 - 1.0
		var band_noise = raw_noise - last_noise
		last_noise = raw_noise * 0.6
		var friction = band_noise * 0.25 * exp(-t * 40.0)

		# Phase 2: Elastisches Schnappen der Kartenkante (Snap bei 50ms)
		var t_snap = t - 0.045
		var snap = 0.0
		if t_snap >= 0.0:
			var snap_env = exp(-t_snap * 65.0)
			snap = (sin(TAU * 1750.0 * t_snap) * 0.45 + (randf() * 2.0 - 1.0) * 0.3) * snap_env

		sample_val = (friction + snap) * 0.65
		var s16 = int(clamp(sample_val, -1.0, 1.0) * 32760.0)
		data.encode_s16(i * 2, s16)

	return _create_wav(data, sample_rate)

# 6. Wuchtiger Kanonenschuss & Tiefen-Explosion (Cinematic Shockwave & Sub-Bass)
func _generate_explosion() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.55
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)

	var brown_noise = 0.0
	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		
		# 1. Druckwellen-Schlag (Supersonic Initial Crack)
		var crack = (randf() * 2.0 - 1.0) * exp(-t * 250.0) * 0.45
		
		# 2. Sub-Bass Wucht (Frequenz fällt von 120Hz auf 35Hz ab)
		var sub_freq = 35.0 + 85.0 * exp(-t * 7.5)
		var sub_bass = sin(TAU * sub_freq * t) * 0.65 * exp(-t * 6.0)

		# 3. Tiefes Grollen (Low-pass gefiltertes Explosionsrauschen)
		var white = randf() * 2.0 - 1.0
		brown_noise = (brown_noise * 0.95) + (white * 0.05)
		var rumble = brown_noise * 3.2 * exp(-t * 5.5)

		var sample_val = (crack + sub_bass + rumble) * 0.75
		var s16 = int(clamp(sample_val, -1.0, 1.0) * 32760.0)
		data.encode_s16(i * 2, s16)

	return _create_wav(data, sample_rate)

# 7. Glanzvoller harmonischer Siegesklang (Lush F-Dur Akkordkaskade mit Glockenobertönen)
func _generate_chime() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.85
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)

	# F-Dur 9th Arpeggio: F4, A4, C5, E5, A5
	var chime_notes = [
		{"time": 0.00, "freq": 349.23}, # F4
		{"time": 0.09, "freq": 440.00}, # A4
		{"time": 0.18, "freq": 523.25}, # C5
		{"time": 0.27, "freq": 659.25}, # E5
		{"time": 0.36, "freq": 880.00}  # A5
	]

	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var sample_val = 0.0

		for note in chime_notes:
			var dt = t - note["time"]
			if dt >= 0.0:
				var attack = min(1.0, dt / 0.002)
				var decay = exp(-dt * 3.8)
				var env = attack * decay
				# Harmonischer Glockenklang: Grundton + echter physikalischer Glocken-Oberton (2.76x)
				var f = note["freq"]
				var bell = sin(TAU * f * dt) * 0.45 + sin(TAU * (f * 2.76) * dt) * 0.15 + sin(TAU * (f * 5.4) * dt) * 0.05
				sample_val += bell * env * 0.35

		var s16 = int(clamp(sample_val, -1.0, 1.0) * 32760.0)
		data.encode_s16(i * 2, s16)

	return _create_wav(data, sample_rate)

# 8. Realistisches Wasserplätschern / Spritzer (für Schiffe versenken Wasser-Fehlschüsse)
func _generate_splash() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.36
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)

	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		# Tiefer Wassereintritt ("Plop" 80Hz)
		var plunge = sin(TAU * (140.0 - t * 240.0) * t) * 0.4 * exp(-t * 22.0)
		
		# Wasserbläschen & Tropfenspritzer (bubbly resonances)
		var bubble1 = sin(TAU * (480.0 + sin(TAU * 40.0 * t) * 120.0) * t) * 0.2 * exp(-t * 15.0)
		var bubble2 = sin(TAU * (820.0 - t * 600.0) * t) * 0.15 * exp(-t * 20.0)
		var spray = (randf() * 2.0 - 1.0) * 0.15 * exp(-t * 18.0)

		var sample_val = (plunge + bubble1 + bubble2 + spray) * 0.65
		var s16 = int(clamp(sample_val, -1.0, 1.0) * 32760.0)
		data.encode_s16(i * 2, s16)

	return _create_wav(data, sample_rate)

# 9. Taktiles mechanisches Karotten-Drehen & Rasten (Lotti Karotti Klack-Klack)
func _generate_twist() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.26
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)

	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var sample_val = 0.0

		# Klick 1 bei 0ms
		var dt1 = t
		var click1 = (sin(TAU * 850.0 * dt1) * 0.5 + sin(TAU * 320.0 * dt1) * 0.4) * exp(-dt1 * 55.0)
		var snap1 = (randf() * 2.0 - 1.0) * 0.25 * exp(-dt1 * 180.0)

		# Klick 2 bei 110ms (Rastmechanismus)
		var dt2 = t - 0.11
		var click2 = 0.0
		var snap2 = 0.0
		if dt2 >= 0.0:
			click2 = (sin(TAU * 980.0 * dt2) * 0.55 + sin(TAU * 340.0 * dt2) * 0.45) * exp(-dt2 * 60.0)
			snap2 = (randf() * 2.0 - 1.0) * 0.3 * exp(-dt2 * 200.0)

		sample_val = (click1 + snap1 + click2 + snap2) * 0.6
		var s16 = int(clamp(sample_val, -1.0, 1.0) * 32760.0)
		data.encode_s16(i * 2, s16)

	return _create_wav(data, sample_rate)

# 10. Weicher dezenter Niederlage-Gong (Sanfter Moll-Resonanzklang)
func _generate_loss() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.55
	var total_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)

	# D-Moll Dreiklang D3 (146.8Hz), F3 (174.6Hz), A3 (220.0Hz)
	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var attack = min(1.0, t / 0.003)
		var env = attack * exp(-t * 5.0)
		var gong = sin(TAU * 146.83 * t) * 0.4 + sin(TAU * 174.61 * t) * 0.3 + sin(TAU * 220.0 * t) * 0.25
		var sample_val = gong * env * 0.5

		var s16 = int(clamp(sample_val, -1.0, 1.0) * 32760.0)
		data.encode_s16(i * 2, s16)

	return _create_wav(data, sample_rate)
