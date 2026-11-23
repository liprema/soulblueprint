class_name AkashaAudioManager
extends Node

## Pure-GDScript procedural celestial chime & harmonic pad synthesizer
## using AudioStreamGenerator at 22050 Hz (zero external audio files required).

const SAMPLE_RATE: float = 22050.0
const INV_SAMPLE_RATE: float = 1.0 / SAMPLE_RATE
const MAX_VOICES: int = 24

## D-Major celestial pentatonic scale: D5, E5, F#5, A5, D6
const PENTATONIC_FREQS: Array[float] = [587.33, 659.25, 739.99, 880.00, 1174.66]

## C-Major ascending celestial harp pentatonic scale for wind rings: C5..E6
const WIND_RING_FREQS: Array[float] = [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51]

const VOICE_CHIME: int = 0
const VOICE_PAD: int = 1
const VOICE_FLAP: int = 2

const DELAY_LEN_L: int = 3969 # ~180 ms at 22050 Hz
const DELAY_LEN_R: int = 5292 # ~240 ms at 22050 Hz

@export_range(0.0, 1.5, 0.01) var master_volume: float = 0.78
@export var enabled: bool = true

@onready var _player: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer")

var _playback: AudioStreamGeneratorPlayback
var _voices: Array[Dictionary] = []

var _delay_l: PackedFloat32Array = PackedFloat32Array()
var _delay_r: PackedFloat32Array = PackedFloat32Array()
var _delay_idx_l: int = 0
var _delay_idx_r: int = 0
var _delay_energy: float = 0.0

var _frame_buffer: PackedVector2Array = PackedVector2Array()
var _silence_buffer: PackedVector2Array = PackedVector2Array()
var _noise_state: int = 2463534242

# Continuous procedural flight wind bed state (soft 2-pole LPF airy breeze + subtle harmonic resonance)
var _wind_target_level: float = 0.0
var _wind_current_level: float = 0.0
var _wind_speed_ratio: float = 0.0
var _wind_speed_smooth: float = 0.0
var _wind_lp1_l: float = 0.0
var _wind_lp2_l: float = 0.0
var _wind_hp_l: float = 0.0
var _wind_lp1_r: float = 0.0
var _wind_lp2_r: float = 0.0
var _wind_hp_r: float = 0.0
var _wind_lfo_phase: float = 0.0
var _wind_tone_phase1: float = 0.0
var _wind_tone_phase2: float = 0.0


func _ready() -> void:
	_delay_l.resize(DELAY_LEN_L)
	_delay_l.fill(0.0)
	_delay_r.resize(DELAY_LEN_R)
	_delay_r.fill(0.0)

	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.name = "AudioStreamPlayer"
		add_child(_player)

	var gen: AudioStreamGenerator = _player.stream as AudioStreamGenerator
	if gen == null:
		gen = AudioStreamGenerator.new()
		_player.stream = gen

	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = 0.1

	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	_fill_audio_buffer()


func _process(_delta: float) -> void:
	if not enabled or _playback == null:
		return
	if not _player.playing:
		_player.play()
		_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
		if _playback == null:
			return
	_fill_audio_buffer()


## Radiant 3-note golden harmonic chord (D5 + F#5 + A5 with warm D4 resonance).
func play_soul_call() -> void:
	if not enabled:
		return
	# Warm foundational fifth/octave glow
	_add_voice({
		"type": VOICE_PAD,
		"freq": 293.66, # D4
		"freq_end": 293.66,
		"phase": 0.0,
		"phase2": 0.0,
		"phase3": 0.0,
		"age": 0.0,
		"delay": 0.0,
		"attack": 0.08,
		"decay": 1.35,
		"duration": 3.4,
		"amp": 0.22,
		"pan": 0.0,
		"lp": 0.0,
	})
	# Radiant 3-note golden chord bloom (D5, F#5, A5)
	var chord_freqs: Array[float] = [587.33, 739.99, 880.00]
	var chord_pans: Array[float] = [-0.28, 0.0, 0.28]
	for i in range(chord_freqs.size()):
		_add_voice({
			"type": VOICE_PAD,
			"freq": chord_freqs[i],
			"freq_end": chord_freqs[i],
			"phase": 0.0,
			"phase2": 0.0,
			"phase3": 0.0,
			"age": 0.0,
			"delay": float(i) * 0.048,
			"attack": 0.045,
			"decay": 1.15,
			"duration": 3.1,
			"amp": 0.24,
			"pan": chord_pans[i],
			"lp": 0.0,
		})


## Soft airy rising shimmer for wing flaps and soaring impulses.
func play_wing_flap() -> void:
	if not enabled:
		return
	_add_voice({
		"type": VOICE_FLAP,
		"freq": 440.00, # A4 -> D5 gentle glide
		"freq_end": 587.33,
		"phase": 0.0,
		"phase2": 0.0,
		"phase3": 0.0,
		"age": 0.0,
		"delay": 0.0,
		"attack": 0.06,
		"decay": 0.25,
		"duration": 0.42,
		"amp": 0.24,
		"pan": -0.1,
		"lp": 0.0,
	})
	_add_voice({
		"type": VOICE_FLAP,
		"freq": 659.25, # E5 -> A5 airy shimmer harmonic
		"freq_end": 880.00,
		"phase": 0.0,
		"phase2": 0.0,
		"phase3": 0.0,
		"age": 0.0,
		"delay": 0.025,
		"attack": 0.05,
		"decay": 0.22,
		"duration": 0.36,
		"amp": 0.14,
		"pan": 0.15,
		"lp": 0.0,
	})


## Crystalline pentatonic bell note (D5, E5, F#5, A5, D6).
func play_lantern_chime(index: int = 0) -> void:
	if not enabled:
		return
	var note_idx: int = posmod(index, PENTATONIC_FREQS.size())
	var freq: float = PENTATONIC_FREQS[note_idx]
	var pan: float = lerpf(-0.32, 0.32, float(note_idx) / float(PENTATONIC_FREQS.size() - 1))

	_add_voice({
		"type": VOICE_CHIME,
		"freq": freq,
		"freq_end": freq,
		"phase": 0.0,
		"phase2": 0.0,
		"phase3": 0.0,
		"age": 0.0,
		"delay": 0.0,
		"attack": 0.007,
		"decay": 0.92,
		"duration": 2.8,
		"amp": 0.34,
		"pan": pan,
		"lp": 0.0,
	})


## Distinct gentle harmonic chords for each Mentor speaker.
func play_mentor_chord(mentor_id: String) -> void:
	if not enabled:
		return

	var key: String = mentor_id.strip_edges().to_lower()
	match key:
		"alatea":
			# Ethereal high cyan-gold F#5 + A5 + C#6 shimmer
			var freqs: Array[float] = [739.99, 880.00, 1108.73]
			var pans: Array[float] = [-0.26, 0.0, 0.26]
			for i in range(freqs.size()):
				_add_voice({
					"type": VOICE_PAD,
					"freq": freqs[i],
					"freq_end": freqs[i],
					"phase": 0.0,
					"phase2": 0.0,
					"phase3": 0.0,
					"age": 0.0,
					"delay": float(i) * 0.065,
					"attack": 0.09,
					"decay": 1.35,
					"duration": 3.2,
					"amp": 0.16,
					"pan": pans[i],
					"lp": 0.0,
				})
			# Delicate upper celestial shimmer bell on C#6
			_add_voice({
				"type": VOICE_CHIME,
				"freq": 1108.73,
				"freq_end": 1108.73,
				"phase": 0.0,
				"phase2": 0.0,
				"phase3": 0.0,
				"age": 0.0,
				"delay": 0.14,
				"attack": 0.015,
				"decay": 0.95,
				"duration": 2.4,
				"amp": 0.14,
				"pan": 0.12,
				"lp": 0.0,
			})
		"mira":
			# Warm maternal D4 + F#4 + A4 + C#5 pad
			var freqs: Array[float] = [293.66, 369.99, 440.00, 554.37]
			var pans: Array[float] = [-0.24, -0.08, 0.08, 0.24]
			for i in range(freqs.size()):
				_add_voice({
					"type": VOICE_PAD,
					"freq": freqs[i],
					"freq_end": freqs[i],
					"phase": 0.0,
					"phase2": 0.0,
					"phase3": 0.0,
					"age": 0.0,
					"delay": float(i) * 0.055,
					"attack": 0.14,
					"decay": 1.55,
					"duration": 3.6,
					"amp": 0.17,
					"pan": pans[i],
					"lp": 0.0,
				})
		"kronos":
			# Deep resonant D3 + A3 + D4 pad
			var freqs: Array[float] = [146.83, 220.00, 293.66]
			var pans: Array[float] = [-0.18, 0.0, 0.18]
			for i in range(freqs.size()):
				_add_voice({
					"type": VOICE_PAD,
					"freq": freqs[i],
					"freq_end": freqs[i],
					"phase": 0.0,
					"phase2": 0.0,
					"phase3": 0.0,
					"age": 0.0,
					"delay": float(i) * 0.07,
					"attack": 0.16,
					"decay": 1.7,
					"duration": 3.9,
					"amp": 0.21,
					"pan": pans[i],
					"lp": 0.0,
				})
		"orion":
			# Crystalline E5 + A5 + D6 shimmer
			var freqs: Array[float] = [659.25, 880.00, 1174.66]
			var pans: Array[float] = [-0.25, 0.0, 0.25]
			for i in range(freqs.size()):
				_add_voice({
					"type": VOICE_CHIME,
					"freq": freqs[i],
					"freq_end": freqs[i],
					"phase": 0.0,
					"phase2": 0.0,
					"phase3": 0.0,
					"age": 0.0,
					"delay": float(i) * 0.055,
					"attack": 0.012,
					"decay": 1.1,
					"duration": 2.9,
					"amp": 0.18,
					"pan": pans[i],
					"lp": 0.0,
				})
		_:
			# Gentle celestial fallback D5 + A5
			var freqs: Array[float] = [587.33, 880.00]
			var pans: Array[float] = [-0.15, 0.15]
			for i in range(freqs.size()):
				_add_voice({
					"type": VOICE_PAD,
					"freq": freqs[i],
					"freq_end": freqs[i],
					"phase": 0.0,
					"phase2": 0.0,
					"phase3": 0.0,
					"age": 0.0,
					"delay": float(i) * 0.05,
					"attack": 0.08,
					"decay": 1.1,
					"duration": 2.6,
					"amp": 0.16,
					"pan": pans[i],
					"lp": 0.0,
				})


## Soft ascending 2-note chime (A5 -> D6) for Spark dialogue choices.
func play_choice_chime() -> void:
	if not enabled:
		return
	var notes: Array[float] = [880.00, 1174.66]
	var pans: Array[float] = [-0.14, 0.14]
	for i in range(notes.size()):
		_add_voice({
			"type": VOICE_CHIME,
			"freq": notes[i],
			"freq_end": notes[i],
			"phase": 0.0,
			"phase2": 0.0,
			"phase3": 0.0,
			"age": 0.0,
			"delay": float(i) * 0.075,
			"attack": 0.008,
			"decay": 0.78,
			"duration": 2.2,
			"amp": 0.24,
			"pan": pans[i],
			"lp": 0.0,
		})


## Radiant multi-voice golden chord bloom (D4 + A4 + D5 + F#5 + A5 + D6).
func play_mirror_awakening() -> void:
	if not enabled:
		return
	var freqs: Array[float] = [293.66, 440.00, 587.33, 739.99, 880.00, 1174.66]
	var pans: Array[float] = [0.0, -0.22, 0.22, -0.32, 0.32, 0.0]
	var amps: Array[float] = [0.20, 0.18, 0.18, 0.17, 0.16, 0.14]
	for i in range(freqs.size()):
		_add_voice({
			"type": VOICE_PAD,
			"freq": freqs[i],
			"freq_end": freqs[i],
			"phase": 0.0,
			"phase2": 0.0,
			"phase3": 0.0,
			"age": 0.0,
			"delay": float(i) * 0.065,
			"attack": 0.12,
			"decay": 2.1,
			"duration": 4.8,
			"amp": amps[i],
			"pan": pans[i],
			"lp": 0.0,
		})
	# Shimmering crystalline top bell on D6
	_add_voice({
		"type": VOICE_CHIME,
		"freq": 1174.66,
		"freq_end": 1174.66,
		"phase": 0.0,
		"phase2": 0.0,
		"phase3": 0.0,
		"age": 0.0,
		"delay": 0.38,
		"attack": 0.015,
		"decay": 1.4,
		"duration": 3.5,
		"amp": 0.20,
		"pan": 0.0,
		"lp": 0.0,
	})


## Updates continuous procedural flight wind intensity based on speed and flight state.
func update_flight_wind(speed_ratio: float, is_flying: bool) -> void:
	var clamped_ratio: float = clampf(speed_ratio, 0.0, 1.0)
	_wind_speed_ratio = clamped_ratio
	if not enabled:
		_wind_target_level = 0.0
		return
	if is_flying:
		# Soft baseline sky breeze while soaring, swelling smoothly with speed
		var speed_curve: float = pow(clamped_ratio, 1.35)
		_wind_target_level = clampf(0.18 + speed_curve * 0.82, 0.0, 1.0)
	else:
		# Hushed when resting; gentle airy whisper only during brisk ground sprints
		if clamped_ratio <= 0.28:
			_wind_target_level = 0.0
		else:
			var run_norm: float = clampf((clamped_ratio - 0.28) / 0.72, 0.0, 1.0)
			_wind_target_level = run_norm * run_norm * 0.26


## Ascending pentatonic celestial harp + crystalline overtone for wind rings (C5..E6).
func play_wind_ring_note(ring_index: int) -> void:
	if not enabled:
		return
	var note_idx: int = posmod(ring_index, WIND_RING_FREQS.size())
	var freq: float = WIND_RING_FREQS[note_idx]
	var pan: float = lerpf(-0.34, 0.34, float(note_idx) / float(WIND_RING_FREQS.size() - 1))

	# Primary celestial harp pluck
	_add_voice({
		"type": VOICE_CHIME,
		"freq": freq,
		"freq_end": freq,
		"phase": 0.0,
		"phase2": 0.0,
		"phase3": 0.0,
		"age": 0.0,
		"delay": 0.0,
		"attack": 0.005,
		"decay": 0.88,
		"duration": 2.6,
		"amp": 0.30,
		"pan": pan,
		"lp": 0.0,
	})
	# Sparkling crystalline octave overtone
	_add_voice({
		"type": VOICE_CHIME,
		"freq": freq * 2.0,
		"freq_end": freq * 2.0,
		"phase": 0.0,
		"phase2": 0.0,
		"phase3": 0.0,
		"age": 0.0,
		"delay": 0.022,
		"attack": 0.008,
		"decay": 0.46,
		"duration": 1.45,
		"amp": 0.11,
		"pan": -pan * 0.45,
		"lp": 0.0,
	})


## Warm, rising airy shimmer chord when catching a golden thermal updraft.
func play_updraft_whoosh() -> void:
	if not enabled:
		return
	# Rising airy wind sweep (D4 -> D5)
	_add_voice({
		"type": VOICE_FLAP,
		"freq": 293.66,
		"freq_end": 587.33,
		"phase": 0.0,
		"phase2": 0.0,
		"phase3": 0.0,
		"age": 0.0,
		"delay": 0.0,
		"attack": 0.10,
		"decay": 0.55,
		"duration": 0.85,
		"amp": 0.24,
		"pan": -0.16,
		"lp": 0.0,
	})
	# Secondary fifth airy lift (A4 -> A5)
	_add_voice({
		"type": VOICE_FLAP,
		"freq": 440.00,
		"freq_end": 880.00,
		"phase": 0.0,
		"phase2": 0.0,
		"phase3": 0.0,
		"age": 0.0,
		"delay": 0.045,
		"attack": 0.09,
		"decay": 0.50,
		"duration": 0.78,
		"amp": 0.18,
		"pan": 0.16,
		"lp": 0.0,
	})
	# Warm golden harmonic shimmer chord (D5 + F#5 + A5)
	var chord_freqs: Array[float] = [587.33, 739.99, 880.00]
	var chord_pans: Array[float] = [-0.22, 0.0, 0.22]
	for i in range(chord_freqs.size()):
		_add_voice({
			"type": VOICE_PAD,
			"freq": chord_freqs[i],
			"freq_end": chord_freqs[i],
			"phase": 0.0,
			"phase2": 0.0,
			"phase3": 0.0,
			"age": 0.0,
			"delay": 0.03 + float(i) * 0.048,
			"attack": 0.10,
			"decay": 0.95,
			"duration": 2.3,
			"amp": 0.14,
			"pan": chord_pans[i],
			"lp": 0.0,
		})


## Ultra-soft, delicate high celesta tap for UI hover feedback.
func play_ui_hover() -> void:
	if not enabled:
		return
	_add_voice({
		"type": VOICE_CHIME,
		"freq": 1318.51, # E6 airy celesta tap
		"freq_end": 1318.51,
		"phase": 0.0,
		"phase2": 0.0,
		"phase3": 0.0,
		"age": 0.0,
		"delay": 0.0,
		"attack": 0.006,
		"decay": 0.14,
		"duration": 0.42,
		"amp": 0.065,
		"pan": 0.0,
		"lp": 0.0,
	})


## Warm crystalline pearlescent chime on UI button click.
func play_ui_click() -> void:
	if not enabled:
		return
	var notes: Array[float] = [783.99, 1174.66] # G5 -> D6 pearlescent fifth
	var pans: Array[float] = [-0.10, 0.10]
	var amps: Array[float] = [0.16, 0.13]
	for i in range(notes.size()):
		_add_voice({
			"type": VOICE_CHIME,
			"freq": notes[i],
			"freq_end": notes[i],
			"phase": 0.0,
			"phase2": 0.0,
			"phase3": 0.0,
			"age": 0.0,
			"delay": float(i) * 0.032,
			"attack": 0.005,
			"decay": 0.38,
			"duration": 1.1,
			"amp": amps[i],
			"pan": pans[i],
			"lp": 0.0,
		})


## Enables or mutes procedural celestial audio output.
func set_muted(muted: bool) -> void:
	enabled = not muted
	if muted:
		_voices.clear()
		_delay_l.fill(0.0)
		_delay_r.fill(0.0)
		_delay_energy = 0.0
		_wind_target_level = 0.0
		_wind_current_level = 0.0
		_wind_speed_ratio = 0.0
		_wind_speed_smooth = 0.0
		_wind_lp1_l = 0.0
		_wind_lp2_l = 0.0
		_wind_hp_l = 0.0
		_wind_lp1_r = 0.0
		_wind_lp2_r = 0.0
		_wind_hp_r = 0.0
		if _player != null and _player.playing:
			_player.stop()


func _add_voice(voice: Dictionary) -> void:
	if _voices.size() >= MAX_VOICES:
		_voices.remove_at(0)
	_voices.append(voice)
	_delay_energy = 1.0


func _fill_audio_buffer() -> void:
	var frames_available: int = _playback.get_frames_available()
	if frames_available <= 0:
		return

	# Fast-path: push silence when all voices, wind bed, and shimmer tails have decayed
	var wind_active: bool = _wind_current_level >= 0.0004 or _wind_target_level >= 0.0004
	if _voices.is_empty() and _delay_energy < 0.0002 and not wind_active:
		if _silence_buffer.size() != frames_available:
			_silence_buffer.resize(frames_available)
			_silence_buffer.fill(Vector2.ZERO)
		_playback.push_buffer(_silence_buffer)
		return

	if _frame_buffer.size() != frames_available:
		_frame_buffer.resize(frames_available)

	var voice_count: int = _voices.size()
	var peak_tail: float = 0.0

	for i in range(frames_available):
		var dry_l: float = 0.0
		var dry_r: float = 0.0

		# Continuous procedural flight wind bed (velvety 2-pole LPF breeze + subtle harmonic resonance)
		if wind_active:
			_wind_current_level += (_wind_target_level - _wind_current_level) * 0.00024
			_wind_speed_smooth += (_wind_speed_ratio - _wind_speed_smooth) * 0.00022
			if _wind_current_level > 0.0002:
				var lp_alpha: float = lerpf(0.032, 0.086, _wind_speed_smooth)
				var raw_l: float = _fast_noise()
				var raw_r: float = _fast_noise()
				_wind_lp1_l += (raw_l - _wind_lp1_l) * lp_alpha
				_wind_lp2_l += (_wind_lp1_l - _wind_lp2_l) * lp_alpha
				_wind_hp_l += (_wind_lp2_l - _wind_hp_l) * 0.004
				var air_l: float = _wind_lp2_l - _wind_hp_l

				_wind_lp1_r += (raw_r - _wind_lp1_r) * lp_alpha
				_wind_lp2_r += (_wind_lp1_r - _wind_lp2_r) * lp_alpha
				_wind_hp_r += (_wind_lp2_r - _wind_hp_r) * 0.004
				var air_r: float = _wind_lp2_r - _wind_hp_r

				# Gentle organic breathing LFO + whisper-soft D4/A4 breeze resonance
				_wind_lfo_phase += TAU * (0.30 + _wind_speed_smooth * 0.22) * INV_SAMPLE_RATE
				if _wind_lfo_phase > TAU:
					_wind_lfo_phase -= TAU
				var breath: float = 0.86 + 0.14 * sin(_wind_lfo_phase)

				var tone_f1: float = lerpf(277.18, 329.63, _wind_speed_smooth)
				var tone_f2: float = tone_f1 * 1.498
				_wind_tone_phase1 += TAU * tone_f1 * INV_SAMPLE_RATE
				_wind_tone_phase2 += TAU * tone_f2 * INV_SAMPLE_RATE
				if _wind_tone_phase1 > TAU:
					_wind_tone_phase1 -= TAU
				if _wind_tone_phase2 > TAU:
					_wind_tone_phase2 -= TAU

				var breeze_harm_l: float = 0.045 * sin(_wind_tone_phase1) + 0.025 * sin(_wind_tone_phase2)
				var breeze_harm_r: float = 0.045 * sin(_wind_tone_phase1 + 0.7) + 0.025 * sin(_wind_tone_phase2 + 1.1)

				var wind_gain: float = _wind_current_level * breath * 0.24
				dry_l += (air_l * 1.35 + breeze_harm_l) * wind_gain
				dry_r += (air_r * 1.35 + breeze_harm_r) * wind_gain

		for v_idx in range(voice_count):
			var v: Dictionary = _voices[v_idx]
			var age: float = v["age"]
			var delay: float = v["delay"]
			var duration: float = v["duration"]

			if age >= delay + duration:
				continue

			v["age"] = age + INV_SAMPLE_RATE
			if age < delay:
				continue

			var t: float = age - delay
			var v_type: int = v["type"]
			var amp: float = v["amp"]
			var pan: float = v["pan"]
			var pan_l: float = 0.7071 * (1.0 - pan * 0.5)
			var pan_r: float = 0.7071 * (1.0 + pan * 0.5)

			if v_type == VOICE_CHIME:
				var freq: float = v["freq"]
				var attack: float = v["attack"]
				var decay: float = v["decay"]
				var env_a: float = clampf(t / attack, 0.0, 1.0)
				var env_d: float = exp(-t / decay)
				var env: float = env_a * env_d

				var p1: float = v["phase"] + TAU * freq * INV_SAMPLE_RATE
				var p2: float = v["phase2"] + TAU * (freq * 2.0) * INV_SAMPLE_RATE
				var p3: float = v["phase3"] + TAU * (freq * 3.0) * INV_SAMPLE_RATE
				if p1 > TAU:
					p1 -= TAU
				if p2 > TAU:
					p2 -= TAU
				if p3 > TAU:
					p3 -= TAU
				v["phase"] = p1
				v["phase2"] = p2
				v["phase3"] = p3

				var h2_decay: float = exp(-t / (decay * 0.42))
				var h3_decay: float = exp(-t / (decay * 0.22))
				var sig: float = (sin(p1) + 0.28 * sin(p2) * h2_decay + 0.09 * sin(p3) * h3_decay) * env * amp
				dry_l += sig * pan_l
				dry_r += sig * pan_r

			elif v_type == VOICE_PAD:
				var freq: float = v["freq"]
				var attack: float = v["attack"]
				var decay: float = v["decay"]
				var env_a: float = clampf(t / attack, 0.0, 1.0)
				env_a = env_a * env_a * (3.0 - 2.0 * env_a)
				var env_d: float = exp(-t / decay)
				var env: float = env_a * env_d

				# Slight stereo detune for warm celestial chorus
				var p1: float = v["phase"] + TAU * (freq * 0.9985) * INV_SAMPLE_RATE
				var p2: float = v["phase2"] + TAU * (freq * 1.0015) * INV_SAMPLE_RATE
				var p3: float = v["phase3"] + TAU * (freq * 2.0) * INV_SAMPLE_RATE
				if p1 > TAU:
					p1 -= TAU
				if p2 > TAU:
					p2 -= TAU
				if p3 > TAU:
					p3 -= TAU
				v["phase"] = p1
				v["phase2"] = p2
				v["phase3"] = p3

				var overtone: float = 0.16 * sin(p3) * exp(-t / (decay * 0.55))
				var sig_l: float = (sin(p1) + overtone) * env * amp
				var sig_r: float = (sin(p2) + overtone) * env * amp
				dry_l += sig_l * pan_l
				dry_r += sig_r * pan_r

			elif v_type == VOICE_FLAP:
				var progress: float = clampf(t / duration, 0.0, 1.0)
				var smooth_p: float = progress * progress * (3.0 - 2.0 * progress)
				var cur_freq: float = lerpf(v["freq"], v["freq_end"], smooth_p)
				var env: float = sin(PI * progress)
				env = env * env

				var p1: float = v["phase"] + TAU * cur_freq * INV_SAMPLE_RATE
				var p2: float = v["phase2"] + TAU * (cur_freq * 1.5) * INV_SAMPLE_RATE
				if p1 > TAU:
					p1 -= TAU
				if p2 > TAU:
					p2 -= TAU
				v["phase"] = p1
				v["phase2"] = p2

				# Soft lowpass-filtered airy breath noise
				var white: float = _fast_noise()
				var lp: float = lerpf(v["lp"], white, 0.13)
				v["lp"] = lp

				var shimmer: float = 0.52 * sin(p1) + 0.22 * sin(p2) + 0.55 * lp
				var sig: float = shimmer * env * amp
				dry_l += sig * pan_l
				dry_r += sig * pan_r

		# Lightweight cross-fed stereo celestial delay shimmer
		var d_l: float = _delay_l[_delay_idx_l]
		var d_r: float = _delay_r[_delay_idx_r]
		_delay_l[_delay_idx_l] = dry_l + d_r * 0.28
		_delay_r[_delay_idx_r] = dry_r + d_l * 0.28

		_delay_idx_l += 1
		if _delay_idx_l >= DELAY_LEN_L:
			_delay_idx_l = 0
		_delay_idx_r += 1
		if _delay_idx_r >= DELAY_LEN_R:
			_delay_idx_r = 0

		var out_l: float = (dry_l + d_l * 0.36) * master_volume
		var out_r: float = (dry_r + d_r * 0.36) * master_volume

		var tail_mag: float = maxf(absf(d_l), absf(d_r))
		if tail_mag > peak_tail:
			peak_tail = tail_mag

		# Gentle soft saturation prevents any digital clipping
		out_l = out_l / (1.0 + absf(out_l))
		out_r = out_r / (1.0 + absf(out_r))

		_frame_buffer[i] = Vector2(out_l, out_r)

	# Prune finished voices
	for idx in range(_voices.size() - 1, -1, -1):
		var v: Dictionary = _voices[idx]
		if v["age"] >= v["delay"] + v["duration"]:
			_voices.remove_at(idx)

	_delay_energy = lerpf(_delay_energy, peak_tail, 0.25)
	_playback.push_buffer(_frame_buffer)


## Fast deterministic xorshift32 noise in [-1.0, 1.0] for airy wing shimmer.
func _fast_noise() -> float:
	var x: int = _noise_state
	x = (x ^ ((x << 13) & 0xFFFFFFFF)) & 0xFFFFFFFF
	x = (x ^ (x >> 17)) & 0xFFFFFFFF
	x = (x ^ ((x << 5) & 0xFFFFFFFF)) & 0xFFFFFFFF
	_noise_state = x
	return (float(x & 0xFFFF) / 32767.5) - 1.0
