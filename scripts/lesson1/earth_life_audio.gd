extends Node

## Procedural fragile music-box, felt-piano, and ambient synthesizer for Lesson 1
## ("Было всё, кроме времени"). Uses AudioStreamGenerator at 22050 Hz (zero external files).
## Respects SaveManager.audio_muted safely.

const SAMPLE_RATE: float = 22050.0
const INV_SAMPLE_RATE: float = 1.0 / SAMPLE_RATE
const MAX_VOICES: int = 28

const VOICE_PIANO: int = 0
const VOICE_PAD: int = 1
const VOICE_BUBBLE: int = 2
const VOICE_CRAYON: int = 3
const VOICE_HEART: int = 4

const DELAY_LEN_L: int = 4410 # ~200 ms at 22050 Hz
const DELAY_LEN_R: int = 5954 # ~270 ms at 22050 Hz

# Musical scales per emotional state (Hz)
const SCALE_WINTER: Array[float] = [293.66, 349.23, 440.00, 523.25, 587.33, 659.25, 698.46, 880.00]
const SCALE_SPRING: Array[float] = [349.23, 392.00, 440.00, 523.25, 587.33, 698.46, 783.99, 880.00]
const SCALE_ROOM: Array[float] = [261.63, 329.63, 392.00, 493.88, 587.33, 659.25, 783.99]
const SCALE_SEA: Array[float] = [329.63, 392.00, 493.88, 587.33, 739.99, 783.99, 987.77]
const SCALE_FAREWELL: Array[float] = [220.00, 261.63, 329.63, 392.00, 440.00, 493.88, 523.25, 659.25]
const SCALE_ASCENSION: Array[float] = [293.66, 440.00, 587.33, 739.99, 880.00, 1108.73, 1318.51]

@export_range(0.0, 1.5, 0.01) var master_volume: float = 0.72
@export var enabled: bool = true

var _player: AudioStreamPlayer = null
var _playback: AudioStreamGeneratorPlayback = null
var _voices: Array[Dictionary] = []

var _delay_l: PackedFloat32Array = PackedFloat32Array()
var _delay_r: PackedFloat32Array = PackedFloat32Array()
var _delay_idx_l: int = 0
var _delay_idx_r: int = 0

var _frame_buffer: PackedVector2Array = PackedVector2Array()
var _silence_buffer: PackedVector2Array = PackedVector2Array()
var _noise_state: int = 198407135

# Mood & continuous ambient bed state
var _mood: String = "winter"
var _wind_level: float = 0.0
var _wind_target: float = 0.0
var _sea_level: float = 0.0
var _sea_target: float = 0.0
var _warmth_hum_level: float = 0.0
var _warmth_hum_target: float = 0.0
var _warmth_hum_progress: float = 0.0

var _bed_lp1_l: float = 0.0
var _bed_lp2_l: float = 0.0
var _bed_lp1_r: float = 0.0
var _bed_lp2_r: float = 0.0
var _bed_lfo_phase: float = 0.0
var _hum_phase1: float = 0.0
var _hum_phase2: float = 0.0

var _auto_note_timer: float = 1.6
var _auto_note_step: int = 0
var _crayon_cooldown: float = 0.0
var _master_fade: float = 1.0
var _master_fade_target: float = 1.0


func _ready() -> void:
	_delay_l.resize(DELAY_LEN_L)
	_delay_l.fill(0.0)
	_delay_r.resize(DELAY_LEN_R)
	_delay_r.fill(0.0)

	_player = get_node_or_null("AudioStreamPlayer") as AudioStreamPlayer
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.name = "AudioStreamPlayer"
		add_child(_player)

	var gen: AudioStreamGenerator = _player.stream as AudioStreamGenerator
	if gen == null:
		gen = AudioStreamGenerator.new()
		_player.stream = gen

	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = 0.12

	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	_fill_audio_buffer()


func _process(delta: float) -> void:
	if _crayon_cooldown > 0.0:
		_crayon_cooldown = maxf(0.0, _crayon_cooldown - delta)

	_master_fade = lerpf(_master_fade, _master_fade_target, minf(1.0, delta * 2.4))

	if not enabled or _is_globally_muted():
		_push_silence()
		return

	if _playback == null or not _player.playing:
		_player.play()
		_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
		if _playback == null:
			return

	_update_ambient_music_box(delta)
	_fill_audio_buffer()


func set_mood(mood_name: String) -> void:
	_mood = mood_name
	_auto_note_step = 0
	match mood_name:
		"winter":
			_wind_target = 0.24
			_sea_target = 0.0
			_auto_note_timer = 1.2
		"spring":
			_wind_target = 0.08
			_sea_target = 0.0
			_auto_note_timer = 1.1
		"room":
			_wind_target = 0.03
			_sea_target = 0.0
			_auto_note_timer = 1.5
		"sea":
			_wind_target = 0.05
			_sea_target = 0.34
			_auto_note_timer = 1.4
		"farewell":
			_wind_target = 0.06
			_sea_target = 0.0
			_auto_note_timer = 2.4
		"ascension":
			_wind_target = 0.04
			_sea_target = 0.0
			_auto_note_timer = 4.0
		"silent":
			_wind_target = 0.0
			_sea_target = 0.0
			_warmth_hum_target = 0.0
			_auto_note_timer = 99.0
		_:
			_wind_target = 0.06
			_sea_target = 0.0


func set_master_fade(target_level: float) -> void:
	_master_fade_target = clampf(target_level, 0.0, 1.0)


func set_warmth_transfer_active(active: bool, progress: float) -> void:
	_warmth_hum_progress = clampf(progress, 0.0, 1.0)
	_warmth_hum_target = 0.26 if active else 0.0


func play_warmth_touch(step_index: int) -> void:
	if not _can_play():
		return
	var base_idx: int = clampi(step_index, 0, 3)
	var chord_roots: Array[float] = [293.66, 349.23, 440.00, 587.33]
	var root: float = chord_roots[base_idx]
	_add_piano_voice(root, 0.28, 3.2, -0.18, 0.0)
	_add_piano_voice(root * 1.5, 0.22, 3.0, 0.16, 0.07)
	_add_piano_voice(root * 2.0, 0.16, 2.8, 0.0, 0.15)
	_add_pad_voice(root * 0.5, 0.15, 3.6, 0.0, 0.04)


func play_bubble_pop(note_index: int) -> void:
	if not _can_play():
		return
	var idx: int = note_index % SCALE_SPRING.size()
	var freq: float = SCALE_SPRING[idx]
	var pan: float = clampf((float(idx) / float(SCALE_SPRING.size() - 1) - 0.5) * 0.7, -0.45, 0.45)

	# Delicate droplet chirp
	_add_voice({
		"type": VOICE_BUBBLE,
		"freq": 560.0 + float(idx) * 65.0,
		"freq_end": 1240.0 + float(idx) * 95.0,
		"phase": 0.0,
		"phase2": 0.0,
		"age": 0.0,
		"delay": 0.0,
		"attack": 0.004,
		"decay": 0.045,
		"duration": 0.09,
		"amp": 0.16,
		"pan": pan,
		"lp": 0.0,
	})
	# Sparkling spring music-box note
	_add_piano_voice(freq, 0.24, 2.4, pan, 0.015)
	_add_piano_voice(freq * 1.5, 0.10, 1.9, -pan * 0.6, 0.06)


func play_crayon_stroke(pitch_norm: float) -> void:
	if not _can_play() or _crayon_cooldown > 0.0:
		return
	_crayon_cooldown = 0.085
	var clamped: float = clampf(pitch_norm, 0.0, 1.0)
	_add_voice({
		"type": VOICE_CRAYON,
		"freq": 480.0 + clamped * 360.0,
		"freq_end": 540.0 + clamped * 380.0,
		"phase": 0.0,
		"phase2": 0.0,
		"age": 0.0,
		"delay": 0.0,
		"attack": 0.012,
		"decay": 0.075,
		"duration": 0.12,
		"amp": 0.09,
		"pan": (clamped - 0.5) * 0.5,
		"lp": 0.0,
	})
	if _rand_signed() > 0.35:
		var idx: int = clampi(int(clamped * float(SCALE_ROOM.size() - 1)), 0, SCALE_ROOM.size() - 1)
		_add_piano_voice(SCALE_ROOM[idx], 0.08, 1.4, (clamped - 0.5) * 0.4, 0.0)


func play_sun_complete() -> void:
	if not _can_play():
		return
	var notes: Array[float] = [261.63, 329.63, 392.00, 493.88, 587.33, 783.99]
	for i: int in range(notes.size()):
		var pan: float = (float(i) / float(notes.size() - 1) - 0.5) * 0.65
		_add_piano_voice(notes[i], 0.20, 3.6, pan, float(i) * 0.085)
	_add_pad_voice(261.63, 0.18, 4.2, 0.0, 0.1)


func play_choice_chime() -> void:
	if not _can_play():
		return
	_add_pad_voice(196.00, 0.16, 4.0, 0.0, 0.0)
	_add_piano_voice(392.00, 0.22, 3.4, -0.22, 0.02)
	_add_piano_voice(493.88, 0.20, 3.4, 0.0, 0.12)
	_add_piano_voice(739.99, 0.18, 3.6, 0.24, 0.24)


func play_heartbeat(strength: float = 1.0) -> void:
	if not _can_play():
		return
	var amp: float = clampf(strength, 0.15, 1.0) * 0.24
	# Lub
	_add_voice({
		"type": VOICE_HEART,
		"freq": 56.0,
		"freq_end": 36.0,
		"phase": 0.0,
		"phase2": 0.0,
		"age": 0.0,
		"delay": 0.0,
		"attack": 0.018,
		"decay": 0.14,
		"duration": 0.24,
		"amp": amp,
		"pan": 0.0,
		"lp": 0.0,
	})
	# Dub
	_add_voice({
		"type": VOICE_HEART,
		"freq": 48.0,
		"freq_end": 32.0,
		"phase": 0.0,
		"phase2": 0.0,
		"age": 0.0,
		"delay": 0.23,
		"attack": 0.016,
		"decay": 0.12,
		"duration": 0.21,
		"amp": amp * 0.72,
		"pan": 0.0,
		"lp": 0.0,
	})


func play_hands_unite() -> void:
	if not _can_play():
		return
	_add_pad_voice(220.00, 0.20, 4.5, 0.0, 0.0)
	_add_piano_voice(293.66, 0.24, 3.8, -0.25, 0.0)
	_add_piano_voice(440.00, 0.24, 3.8, 0.25, 0.06)
	_add_piano_voice(587.33, 0.20, 4.0, 0.0, 0.16)


func play_ascension_chord() -> void:
	if not _can_play():
		return
	_add_pad_voice(146.83, 0.22, 5.2, 0.0, 0.0)
	_add_pad_voice(293.66, 0.18, 5.0, -0.15, 0.08)
	_add_pad_voice(440.00, 0.16, 4.8, 0.15, 0.16)
	for i: int in range(SCALE_ASCENSION.size()):
		var pan: float = (float(i) / float(SCALE_ASCENSION.size() - 1) - 0.5) * 0.75
		_add_piano_voice(SCALE_ASCENSION[i], 0.21, 4.2, pan, float(i) * 0.14)


func play_ui_click() -> void:
	if not _can_play():
		return
	_add_piano_voice(587.33, 0.12, 1.1, 0.0, 0.0)


func _can_play() -> bool:
	return enabled and not _is_globally_muted()


func _is_globally_muted() -> bool:
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr != null:
		var muted_val: Variant = save_mgr.get("audio_muted")
		if muted_val is bool and (muted_val as bool):
			return true
	if AudioServer.bus_count > 0 and AudioServer.is_bus_mute(0):
		return true
	return false


func _update_ambient_music_box(delta: float) -> void:
	if _mood == "silent" or _mood == "ascension":
		return
	_auto_note_timer -= delta
	if _auto_note_timer > 0.0:
		return

	var scale: Array[float] = SCALE_WINTER
	var interval: float = 2.6
	var amp: float = 0.095
	match _mood:
		"winter":
			scale = SCALE_WINTER
			interval = 2.8
			amp = 0.09
		"spring":
			scale = SCALE_SPRING
			interval = 1.85
			amp = 0.105
		"room":
			scale = SCALE_ROOM
			interval = 2.15
			amp = 0.095
		"sea":
			scale = SCALE_SEA
			interval = 2.35
			amp = 0.10
		"farewell":
			scale = SCALE_FAREWELL
			interval = 3.2
			amp = 0.075

	var pattern: Array[int] = [0, 2, 4, 3, 1, 5, 4, 2]
	var pat_idx: int = pattern[_auto_note_step % pattern.size()]
	var note_idx: int = pat_idx % scale.size()
	var pan: float = sin(float(_auto_note_step) * 0.9) * 0.32
	_add_piano_voice(scale[note_idx], amp, 2.9, pan, 0.0)
	_auto_note_step += 1
	_auto_note_timer = interval + (_rand_signed() * 0.35)


func _add_piano_voice(freq: float, amp: float, duration: float, pan: float, delay_sec: float) -> void:
	_add_voice({
		"type": VOICE_PIANO,
		"freq": freq,
		"freq_end": freq,
		"phase": 0.0,
		"phase2": 0.0,
		"age": 0.0,
		"delay": delay_sec,
		"attack": 0.012,
		"decay": duration * 0.36,
		"duration": duration,
		"amp": amp,
		"pan": pan,
		"lp": 0.0,
	})


func _add_pad_voice(freq: float, amp: float, duration: float, pan: float, delay_sec: float) -> void:
	_add_voice({
		"type": VOICE_PAD,
		"freq": freq,
		"freq_end": freq,
		"phase": 0.0,
		"phase2": 0.0,
		"age": 0.0,
		"delay": delay_sec,
		"attack": 0.28,
		"decay": duration * 0.45,
		"duration": duration,
		"amp": amp,
		"pan": pan,
		"lp": 0.0,
	})


func _add_voice(voice: Dictionary) -> void:
	if _voices.size() >= MAX_VOICES:
		_voices.remove_at(0)
	_voices.append(voice)


func _push_silence() -> void:
	if _playback == null:
		return
	var frames: int = _playback.get_frames_available()
	if frames <= 0:
		return
	if _silence_buffer.size() != frames:
		_silence_buffer.resize(frames)
		_silence_buffer.fill(Vector2.ZERO)
	_playback.push_buffer(_silence_buffer)


func _fill_audio_buffer() -> void:
	if _playback == null:
		return
	var frames: int = _playback.get_frames_available()
	if frames <= 0:
		return

	if _frame_buffer.size() != frames:
		_frame_buffer.resize(frames)

	var tau_inv_sr: float = TAU * INV_SAMPLE_RATE
	var smooth_rate: float = 0.00035
	var vol: float = master_volume * _master_fade

	for i: int in range(frames):
		_wind_level = lerpf(_wind_level, _wind_target, smooth_rate)
		_sea_level = lerpf(_sea_level, _sea_target, smooth_rate)
		_warmth_hum_level = lerpf(_warmth_hum_level, _warmth_hum_target, smooth_rate * 2.5)

		var dry_l: float = 0.0
		var dry_r: float = 0.0

		# Continuous ambient bed (winter breeze / ocean surf)
		if _wind_level > 0.0005 or _sea_level > 0.0005:
			_bed_lfo_phase += 0.14 * tau_inv_sr
			if _bed_lfo_phase > TAU:
				_bed_lfo_phase -= TAU
			var wave_swell: float = 0.55 + 0.45 * sin(_bed_lfo_phase)
			var n_l: float = _rand_signed()
			var n_r: float = _rand_signed()
			var cutoff: float = 0.032 + _sea_level * 0.055 * wave_swell
			_bed_lp1_l += cutoff * (n_l - _bed_lp1_l)
			_bed_lp2_l += cutoff * (_bed_lp1_l - _bed_lp2_l)
			_bed_lp1_r += cutoff * (n_r - _bed_lp1_r)
			_bed_lp2_r += cutoff * (_bed_lp1_r - _bed_lp2_r)

			var bed_gain: float = _wind_level * (0.45 + 0.25 * wave_swell) + _sea_level * (0.28 + 0.72 * wave_swell)
			dry_l += _bed_lp2_l * bed_gain * 0.45
			dry_r += _bed_lp2_r * bed_gain * 0.45

		# Chapter 3 continuous warmth transfer harmonic hum
		if _warmth_hum_level > 0.0005:
			var base_f: float = lerpf(220.0, 293.66, _warmth_hum_progress)
			_hum_phase1 += base_f * tau_inv_sr
			_hum_phase2 += (base_f * 1.5) * tau_inv_sr
			if _hum_phase1 > TAU:
				_hum_phase1 -= TAU
			if _hum_phase2 > TAU:
				_hum_phase2 -= TAU
			var hum_sig: float = (sin(_hum_phase1) * 0.65 + sin(_hum_phase2) * 0.35) * _warmth_hum_level * 0.32
			dry_l += hum_sig * 0.96
			dry_r += hum_sig * 1.04

		# Active synthesis voices
		var v_idx: int = _voices.size() - 1
		while v_idx >= 0:
			var v: Dictionary = _voices[v_idx]
			var v_delay: float = float(v["delay"])
			if v_delay > 0.0:
				v["delay"] = v_delay - INV_SAMPLE_RATE
				v_idx -= 1
				continue

			var age: float = float(v["age"])
			var dur: float = float(v["duration"])
			if age >= dur:
				_voices.remove_at(v_idx)
				v_idx -= 1
				continue

			var t_norm: float = clampf(age / maxf(dur, 0.001), 0.0, 1.0)
			var attack: float = maxf(float(v["attack"]), 0.001)
			var decay: float = maxf(float(v["decay"]), 0.01)
			var env: float = 1.0
			if age < attack:
				env = age / attack
			else:
				env = exp(-(age - attack) / decay)
			var tail_fade: float = clampf((dur - age) / minf(0.08, dur * 0.25), 0.0, 1.0)
			env *= tail_fade

			var v_type: int = int(v["type"])
			var freq: float = lerpf(float(v["freq"]), float(v["freq_end"]), t_norm)
			var phase: float = float(v["phase"]) + freq * tau_inv_sr
			if phase > TAU:
				phase -= TAU
			v["phase"] = phase

			var sample_val: float = 0.0
			if v_type == VOICE_PIANO:
				var p2: float = float(v["phase2"]) + (freq * 2.002) * tau_inv_sr
				if p2 > TAU:
					p2 -= TAU
				v["phase2"] = p2
				var bell: float = exp(-age * 9.5) * 0.22
				sample_val = (sin(phase) * 0.72 + sin(p2) * (0.20 + bell) + sin(phase * 3.0) * bell * 0.55)
			elif v_type == VOICE_PAD:
				var p2: float = float(v["phase2"]) + (freq * 1.0035) * tau_inv_sr
				if p2 > TAU:
					p2 -= TAU
				v["phase2"] = p2
				sample_val = (sin(phase) * 0.55 + sin(p2) * 0.45) * 0.85
			elif v_type == VOICE_BUBBLE:
				sample_val = sin(phase) * 0.9
			elif v_type == VOICE_CRAYON:
				var lp: float = float(v["lp"])
				lp += 0.14 * (_rand_signed() - lp)
				v["lp"] = lp
				sample_val = lp * 0.65 + sin(phase) * 0.18
			elif v_type == VOICE_HEART:
				sample_val = sin(phase) * 0.95 + sin(phase * 2.0) * 0.15

			var amp: float = float(v["amp"]) * env
			var pan: float = float(v["pan"])
			var gain_l: float = clampf(0.5 - pan * 0.5, 0.1, 0.9) * 1.4
			var gain_r: float = clampf(0.5 + pan * 0.5, 0.1, 0.9) * 1.4
			dry_l += sample_val * amp * gain_l
			dry_r += sample_val * amp * gain_r

			v["age"] = age + INV_SAMPLE_RATE
			v_idx -= 1

		# Stereo ping-pong reverb delay
		var wet_l: float = _delay_l[_delay_idx_l]
		var wet_r: float = _delay_r[_delay_idx_r]
		_delay_l[_delay_idx_l] = clampf(dry_l + wet_r * 0.36, -1.2, 1.2)
		_delay_r[_delay_idx_r] = clampf(dry_r + wet_l * 0.34, -1.2, 1.2)
		_delay_idx_l = (_delay_idx_l + 1) % DELAY_LEN_L
		_delay_idx_r = (_delay_idx_r + 1) % DELAY_LEN_R

		var out_l: float = tanh((dry_l * 0.80 + wet_l * 0.34) * vol)
		var out_r: float = tanh((dry_r * 0.80 + wet_r * 0.34) * vol)
		_frame_buffer[i] = Vector2(out_l, out_r)

	_playback.push_buffer(_frame_buffer)


func _rand_signed() -> float:
	_noise_state = ((_noise_state * 1664525) + 1013904223) & 0x7FFFFFFF
	return (float(_noise_state) / 1073741823.5) - 1.0
