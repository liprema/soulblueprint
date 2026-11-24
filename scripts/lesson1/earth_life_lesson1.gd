extends Control

## Interactive playable vignette for Lesson 1 Part 1: "Было всё, кроме времени".
## Aesthetic: GRIS + Spiritfarer + Makoto Shinkai (1280x720 canvas_items, 60 FPS).
## Includes automatic Google Flow .ogv video slots before each of the 4 chapters.

const VIDEO_SLOTS: Array[String] = [
	"res://assets/videos/lesson1/01_winter_home.ogv",
	"res://assets/videos/lesson1/02_seven_springs.ogv",
	"res://assets/videos/lesson1/03_eighth_winter.ogv",
	"res://assets/videos/lesson1/04_two_hands_darkness.ogv",
]

const COLOR_INDIGO: Color = Color(0.027451, 0.078431, 0.180392, 1.0)
const COLOR_INDIGO_CARD: Color = Color(0.027451, 0.078431, 0.180392, 0.94)
const COLOR_GOLD: Color = Color(0.964706, 0.827451, 0.419608, 1.0)
const COLOR_GOLD_SOFT: Color = Color(0.964706, 0.827451, 0.419608, 0.72)
const COLOR_IVORY: Color = Color(1.0, 0.964706, 0.84, 1.0)

const STAGE_CH1_WINTER: int = 0
const STAGE_CH2_BUBBLES: int = 1
const STAGE_CH2_WALLPAPER: int = 2
const STAGE_CH2_SEA: int = 3
const STAGE_CH3_EIGHTH_WINTER: int = 4
const STAGE_CH4_TWO_HANDS: int = 5
const STAGE_FINISHED: int = 6

const BUBBLE_LINES: Array[String] = [
	"Первый смех в доме — звонкий, как весенняя капель после долгой зимы.",
	"Она кружит тебя в залитом солнцем саду, боясь расплескать хотя бы миг.",
	"Мыльные пузыри ловят небо и тихо тают на тёплых ладонях.",
	"В её глазах больше нет холода — только бесконечный, светлый апрель.",
	"Ты смеёшься, и старый сад кажется шире целого мира.",
	"Мама шепчет в твои волосы: «Останься со мной подольше…»",
]

@onready var audio: Node = $Audio
@onready var bg_rect: ColorRect = $BgShaderRect
@onready var stage_canvas: Control = $StageCanvas
@onready var chapter_roman_label: Label = $UILayer/ChapterHeader/ChapterRomanLabel
@onready var chapter_title_label: Label = $UILayer/ChapterHeader/ChapterTitleLabel
@onready var narration_panel: PanelContainer = $UILayer/NarrationAnchor/NarrationPanel
@onready var poetic_label: Label = $UILayer/NarrationAnchor/NarrationPanel/NarrationMargin/NarrationVBox/PoeticLabel
@onready var sub_poetic_label: Label = $UILayer/NarrationAnchor/NarrationPanel/NarrationMargin/NarrationVBox/SubPoeticLabel
@onready var choice_container: VBoxContainer = $UILayer/ChoiceContainer
@onready var controls_hint_label: Label = $UILayer/ControlsHintLabel
@onready var esc_hint_label: Label = $UILayer/EscHintLabel
@onready var video_overlay: Control = $VideoOverlay
@onready var video_player: VideoStreamPlayer = $VideoOverlay/VideoPlayer
@onready var video_fade_rect: ColorRect = $VideoOverlay/VideoFadeRect
@onready var transition_veil: ColorRect = $TransitionVeil
@onready var pause_overlay: Control = $PauseOverlay
@onready var pause_card: PanelContainer = $PauseOverlay/PauseCenter/PauseCard
@onready var btn_resume: Button = $PauseOverlay/PauseCenter/PauseCard/PauseMargin/PauseVBox/BtnResume
@onready var btn_mute: Button = $PauseOverlay/PauseCenter/PauseCard/PauseMargin/PauseVBox/BtnMute
@onready var btn_main_menu: Button = $PauseOverlay/PauseCenter/PauseCard/PauseMargin/PauseVBox/BtnMainMenu

var _bg_mat: ShaderMaterial = null
var _stage: int = STAGE_CH1_WINTER
var _stage_time: float = 0.0
var _global_time: float = 0.0
var _is_paused: bool = false
var _is_transitioning: bool = false
var _stage_completing: bool = false

# Video slot playback state
var _video_active: bool = false
var _video_skipping: bool = false
var _video_next_callable: Callable = Callable()

# Smoothly interpolated shader mood parameters
var _cur_sky_top: Color = Color(0.055, 0.086, 0.165, 1.0)
var _cur_sky_mid: Color = Color(0.118, 0.165, 0.255, 1.0)
var _cur_sky_bottom: Color = Color(0.188, 0.231, 0.318, 1.0)
var _cur_ray_color: Color = Color(0.75, 0.86, 1.0, 1.0)
var _cur_warmth: float = 0.0
var _cur_sun_pos: Vector2 = Vector2(0.36, 0.30)
var _cur_ray_strength: float = 0.18
var _cur_vignette: float = 0.42
var _cur_bokeh: float = 0.0

var _tgt_sky_top: Color = Color(0.055, 0.086, 0.165, 1.0)
var _tgt_sky_mid: Color = Color(0.118, 0.165, 0.255, 1.0)
var _tgt_sky_bottom: Color = Color(0.188, 0.231, 0.318, 1.0)
var _tgt_ray_color: Color = Color(0.75, 0.86, 1.0, 1.0)
var _tgt_warmth: float = 0.0
var _tgt_sun_pos: Vector2 = Vector2(0.36, 0.30)
var _tgt_ray_strength: float = 0.18
var _tgt_vignette: float = 0.42
var _tgt_bokeh: float = 0.0

# Player spark / cursor state (supports both Mouse and WASD seamlessly)
var _spark_pos: Vector2 = Vector2(640.0, 360.0)
var _spark_target: Vector2 = Vector2(640.0, 360.0)
var _using_keyboard_cursor: bool = false
var _spark_trail: Array[Vector2] = []

# Shared particles & ripples
var _snowflakes: Array[Dictionary] = []
var _petals: Array[Dictionary] = []
var _ripples: Array[Dictionary] = []
var _motes: Array[Dictionary] = []

# Chapter 1 — Winter Home state
var _cold_points: Array[Dictionary] = []
var _ch1_warmed_count: int = 0
var _ch1_warmth_anim: float = 0.0

# Chapter 2A — Soap Bubbles state
var _bubbles: Array[Dictionary] = []
var _bubbles_popped: int = 0
var _bubble_spawn_timer: float = 0.0

# Chapter 2B — Sun on Wallpaper state
var _wall_strokes: Array[PackedVector2Array] = []
var _wall_is_drawing: bool = false
var _wall_sectors: Array[bool] = []
var _wall_arc_length: float = 0.0
var _wall_sun_progress: float = 0.0
var _wall_father_sit: float = 0.0
var _wall_sun_complete: bool = false
var _wall_mid_line_shown: bool = false

# Chapter 2C — Evening by the Sea state
var _sea_choice_made: bool = false

# Chapter 3 — Eighth Winter state
var _ch3_holding: bool = false
var _ch3_transfer: float = 0.0
var _ch3_heartbeat_timer: float = 0.6
var _ch3_heartbeat_pulse: float = 0.0
var _ch3_stage_line: int = 0
var _ch3_final_sequence: bool = false
var _ch3_ember_rise: float = 0.0
var _ch3_stream_particles: Array[Dictionary] = []

# Chapter 4 — Two Hands in Darkness state
var _ch4_united: bool = false
var _ch4_unite_anim: float = 0.0
var _ch4_vortex_petals: Array[Dictionary] = []
var _ch4_vortex_timer: float = 0.0

var _narration_tween: Tween = null


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_bg_mat = bg_rect.material as ShaderMaterial
	stage_canvas.draw.connect(_on_stage_draw)

	_style_ui_elements()
	_connect_pause_buttons()

	video_overlay.visible = false
	pause_overlay.visible = false
	choice_container.visible = false
	transition_veil.color = COLOR_INDIGO
	transition_veil.modulate.a = 1.0

	var vp_size: Vector2 = _get_vp_size()
	_spark_pos = vp_size * 0.5
	_spark_target = _spark_pos
	_init_snowflakes(vp_size)
	_init_petals(vp_size)
	_init_motes(vp_size)

	_apply_shader_immediate()
	_begin_chapter_with_video_slot(0, _start_chapter_1)


func _process(delta: float) -> void:
	if _is_paused:
		return

	var dt: float = minf(delta, 0.05)
	_global_time += dt

	if _video_active:
		return

	_stage_time += dt
	var vp_size: Vector2 = _get_vp_size()

	_update_shader_params(dt)
	_update_spark_movement(dt, vp_size)
	_update_ripples(dt)

	match _stage:
		STAGE_CH1_WINTER:
			_update_ch1_winter(dt, vp_size)
		STAGE_CH2_BUBBLES:
			_update_ch2_bubbles(dt, vp_size)
		STAGE_CH2_WALLPAPER:
			_update_ch2_wallpaper(dt, vp_size)
		STAGE_CH2_SEA:
			_update_ch2_sea(dt, vp_size)
		STAGE_CH3_EIGHTH_WINTER:
			_update_ch3_eighth_winter(dt, vp_size)
		STAGE_CH4_TWO_HANDS, STAGE_FINISHED:
			_update_ch4_two_hands(dt, vp_size)

	stage_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	# Video skip handling
	if _video_active:
		if _video_skipping:
			return
		var is_skip: bool = false
		if event is InputEventKey:
			var ke: InputEventKey = event as InputEventKey
			if ke.pressed and not ke.echo:
				is_skip = (
					ke.keycode == KEY_SPACE
					or ke.keycode == KEY_ENTER
					or ke.keycode == KEY_KP_ENTER
					or ke.keycode == KEY_ESCAPE
				)
		if is_skip:
			get_viewport().set_input_as_handled()
			_skip_current_video()
		return

	# Pause toggle via Esc
	if event is InputEventKey:
		var key_ev: InputEventKey = event as InputEventKey
		if key_ev.pressed and not key_ev.echo and key_ev.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_toggle_pause()
			return

	if _is_paused or _is_transitioning:
		return

	# Mouse movement switches cursor cleanly back to mouse-follow
	if event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		_using_keyboard_cursor = false
		_spark_target = mm.position
		if _stage == STAGE_CH2_WALLPAPER and _wall_is_drawing and not _wall_sun_complete:
			_append_wallpaper_point(mm.position)

	# Mouse click / release
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_using_keyboard_cursor = false
				_spark_target = mb.position
				_handle_primary_press(mb.position)
			else:
				_handle_primary_release()

	# Keyboard action press / release (Space / E)
	if event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		if not k.echo:
			var is_action_key: bool = (k.keycode == KEY_SPACE or k.keycode == KEY_E)
			if is_action_key:
				if k.pressed:
					_handle_primary_press(_spark_pos)
				else:
					_handle_primary_release()


func _handle_primary_press(pos: Vector2) -> void:
	if _stage_completing:
		return
	match _stage:
		STAGE_CH1_WINTER:
			_try_warm_cold_point(pos)
		STAGE_CH2_BUBBLES:
			_try_pop_bubble_at(pos, 48.0)
		STAGE_CH2_WALLPAPER:
			if not _wall_sun_complete:
				_wall_is_drawing = true
				var stroke: PackedVector2Array = PackedVector2Array()
				stroke.append(pos)
				_wall_strokes.append(stroke)
		STAGE_CH3_EIGHTH_WINTER:
			if not _ch3_final_sequence:
				_ch3_holding = true
		STAGE_CH4_TWO_HANDS:
			if not _ch4_united and _stage_time > 1.1:
				_trigger_ch4_unite()


func _handle_primary_release() -> void:
	_wall_is_drawing = false
	_ch3_holding = false
	if audio != null and audio.has_method("set_warmth_transfer_active"):
		audio.call("set_warmth_transfer_active", false, _ch3_transfer)


# =============================================================================
# AUTOMATIC GOOGLE FLOW VIDEO SLOTS
# =============================================================================

func _begin_chapter_with_video_slot(slot_index: int, on_ready_callback: Callable) -> void:
	if slot_index < 0 or slot_index >= VIDEO_SLOTS.size():
		if on_ready_callback.is_valid():
			on_ready_callback.call()
		return

	var path: String = VIDEO_SLOTS[slot_index]
	var exists: bool = ResourceLoader.exists(path)
	if not exists:
		# Seamless instant launch with zero warnings when .ogv slot is empty
		if on_ready_callback.is_valid():
			on_ready_callback.call()
		return

	var res: Resource = ResourceLoader.load(path)
	if not (res is VideoStream):
		if on_ready_callback.is_valid():
			on_ready_callback.call()
		return

	_play_slot_video(res as VideoStream, on_ready_callback)


func _play_slot_video(stream: VideoStream, on_finished: Callable) -> void:
	_video_active = true
	_video_skipping = false
	_video_next_callable = on_finished

	if audio != null and audio.has_method("set_master_fade"):
		audio.call("set_master_fade", 0.0)

	video_overlay.visible = true
	video_fade_rect.modulate.a = 1.0
	video_player.stream = stream
	video_player.volume_db = 0.0
	if video_player.finished.is_connected(_on_slot_video_finished):
		video_player.finished.disconnect(_on_slot_video_finished)
	video_player.finished.connect(_on_slot_video_finished, CONNECT_ONE_SHOT)
	video_player.play()

	var tw: Tween = create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(video_fade_rect, "modulate:a", 0.0, 0.75)


func _skip_current_video() -> void:
	if _video_skipping or not _video_active:
		return
	_video_skipping = true
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(video_fade_rect, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(video_player, "volume_db", -42.0, 0.45).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_callback(_finish_slot_video)


func _on_slot_video_finished() -> void:
	if _video_skipping or not _video_active:
		return
	_video_skipping = true
	var tw: Tween = create_tween()
	tw.tween_property(video_fade_rect, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_finish_slot_video)


func _finish_slot_video() -> void:
	video_player.stop()
	video_overlay.visible = false
	_video_active = false
	_video_skipping = false
	if audio != null and audio.has_method("set_master_fade"):
		audio.call("set_master_fade", 1.0)
	var cb: Callable = _video_next_callable
	_video_next_callable = Callable()
	if cb.is_valid():
		cb.call()


# =============================================================================
# CHAPTER 1 — «ЗИМА В ДОМЕ»
# =============================================================================

func _start_chapter_1() -> void:
	_stage = STAGE_CH1_WINTER
	_stage_time = 0.0
	_stage_completing = false
	_ch1_warmed_count = 0
	_ch1_warmth_anim = 0.0
	choice_container.visible = false
	_ripples.clear()

	_set_header("Г Л А В А   I", "Зима в доме")
	_set_controls_hint("[Мышь / WASD] Вести искру   ·   [ЛКМ / Space / E] Коснуться холода")
	_set_narration(
		"Они живут под одной крышей, но между ними — целая зима.",
		"Коснись трёх точек холода, чтобы принести в этот дом первое тепло."
	)

	_set_mood_target(
		Color(0.055, 0.086, 0.165, 1.0),
		Color(0.118, 0.165, 0.255, 1.0),
		Color(0.188, 0.231, 0.318, 1.0),
		Color(0.75, 0.86, 1.0, 1.0),
		0.0,
		Vector2(0.36, 0.30),
		0.18,
		0.42,
		0.0
	)
	if audio != null and audio.has_method("set_mood"):
		audio.call("set_mood", "winter")

	var vp: Vector2 = _get_vp_size()
	_cold_points = [
		{
			"id": "mother",
			"pos": Vector2(vp.x * 0.34, vp.y * 0.56),
			"warmed": false,
			"glow": 0.0,
			"line": "Она накрывает на стол в молчании, пряча озябшие пальцы в рукавах…",
			"sub": "Твоё тепло касается её плеча — и лёд впервые трескается.",
		},
		{
			"id": "father",
			"pos": Vector2(vp.x * 0.66, vp.y * 0.56),
			"warmed": false,
			"glow": 0.0,
			"line": "Он прячет горе в работе, чтобы не слышать тишину пустой квартиры…",
			"sub": "Твоя искра ложится на его ладонь — и он наконец поднимает взгляд.",
		},
		{
			"id": "table",
			"pos": Vector2(vp.x * 0.50, vp.y * 0.64),
			"warmed": false,
			"glow": 0.0,
			"line": "Когда в этом пустом доме раздаются твои крошечные шаги — всё меняется.",
			"sub": "Впервые за долгие годы за этим столом снова горит тёплый свет.",
		},
	]
	_fade_in_from_veil(1.1)


func _update_ch1_winter(dt: float, vp: Vector2) -> void:
	var target_w: float = float(_ch1_warmed_count) / 3.0
	_ch1_warmth_anim = lerpf(_ch1_warmth_anim, target_w, minf(1.0, dt * 1.4))

	# Update cold points positions smoothly with viewport size
	if _cold_points.size() == 3:
		_cold_points[0]["pos"] = Vector2(vp.x * 0.34, vp.y * 0.56)
		_cold_points[1]["pos"] = Vector2(vp.x * 0.66, vp.y * 0.56)
		_cold_points[2]["pos"] = Vector2(vp.x * 0.50, vp.y * 0.64)
		for pt: Dictionary in _cold_points:
			var tgt_g: float = 1.0 if bool(pt["warmed"]) else 0.0
			pt["glow"] = lerpf(float(pt["glow"]), tgt_g, minf(1.0, dt * 2.5))

	# Snow drifting outside the arched window
	for flake: Dictionary in _snowflakes:
		var p: Vector2 = flake["pos"] as Vector2
		var spd: float = float(flake["speed"])
		p.y += spd * dt
		p.x += (sin(_global_time * 0.9 + float(flake["phase"])) * 14.0 - 12.0) * dt
		if p.y > vp.y * 0.72:
			p.y = vp.y * 0.08
			p.x = vp.x * (0.28 + randf() * 0.44)
		flake["pos"] = p


func _try_warm_cold_point(pos: Vector2) -> void:
	var best_idx: int = -1
	var best_dist: float = 115.0
	for i: int in range(_cold_points.size()):
		var pt: Dictionary = _cold_points[i]
		if bool(pt["warmed"]):
			continue
		var p: Vector2 = pt["pos"] as Vector2
		var d: float = pos.distance_to(p)
		if d < best_dist:
			best_dist = d
			best_idx = i

	if best_idx == -1:
		return

	var chosen: Dictionary = _cold_points[best_idx]
	chosen["warmed"] = true
	_ch1_warmed_count += 1
	var chosen_pos: Vector2 = chosen["pos"] as Vector2
	_spawn_ripple(chosen_pos, COLOR_GOLD, 290.0)
	_spawn_ripple(chosen_pos, Color(1.0, 0.84, 0.52, 0.85), 170.0)

	if audio != null and audio.has_method("play_warmth_touch"):
		audio.call("play_warmth_touch", _ch1_warmed_count)

	_set_narration(str(chosen["line"]), str(chosen["sub"]))

	var ratio: float = float(_ch1_warmed_count) / 3.0
	_set_mood_target(
		Color(0.055, 0.086, 0.165, 1.0).lerp(Color(0.14, 0.12, 0.21, 1.0), ratio),
		Color(0.118, 0.165, 0.255, 1.0).lerp(Color(0.36, 0.24, 0.22, 1.0), ratio),
		Color(0.188, 0.231, 0.318, 1.0).lerp(Color(0.76, 0.50, 0.29, 1.0), ratio),
		Color(0.75, 0.86, 1.0, 1.0).lerp(Color(1.0, 0.86, 0.56, 1.0), ratio),
		ratio * 0.85,
		Vector2(lerpf(0.36, 0.50, ratio), lerpf(0.30, 0.52, ratio)),
		lerpf(0.18, 0.78, ratio),
		lerpf(0.42, 0.28, ratio),
		ratio * 0.18
	)

	if _ch1_warmed_count >= 3:
		_stage_completing = true
		_finish_chapter_1_async()


func _finish_chapter_1_async() -> void:
	await get_tree().create_timer(3.2).timeout
	if not is_inside_tree():
		return
	await _fade_to_veil(1.1)
	if not is_inside_tree():
		return
	_begin_chapter_with_video_slot(1, _start_chapter_2_bubbles)


# =============================================================================
# CHAPTER 2A — ВЕСНА 1: МЫЛЬНЫЕ ПУЗЫРИ В САДУ
# =============================================================================

func _start_chapter_2_bubbles() -> void:
	_stage = STAGE_CH2_BUBBLES
	_stage_time = 0.0
	_stage_completing = false
	_bubbles_popped = 0
	_bubbles.clear()
	_ripples.clear()
	choice_container.visible = false

	_set_header("Г Л А В А   I I   ·   В Е С Н А   1", "Мыльные пузыри в саду")
	_set_controls_hint("[Мышь / WASD] Коснуться мыльных пузырей (0 / 6)")
	_set_narration(
		"Семь коротких вёсен начинаются с солнца в старом саду.",
		"Поймай шесть мыльных пузырей — в каждом из них живёт смех матери."
	)

	_set_mood_target(
		Color(0.35, 0.58, 0.78, 1.0),
		Color(0.62, 0.80, 0.74, 1.0),
		Color(0.96, 0.88, 0.68, 1.0),
		Color(1.0, 0.94, 0.74, 1.0),
		0.72,
		Vector2(0.74, 0.22),
		0.88,
		0.20,
		0.78
	)
	if audio != null and audio.has_method("set_mood"):
		audio.call("set_mood", "spring")

	var vp: Vector2 = _get_vp_size()
	for i: int in range(6):
		_spawn_soap_bubble(vp, vp.y * (0.45 + float(i) * 0.08))

	_fade_in_from_veil(1.0)


func _spawn_soap_bubble(vp: Vector2, start_y: float = -1.0) -> void:
	var y_val: float = start_y if start_y > 0.0 else vp.y * 0.88
	var b: Dictionary = {
		"pos": Vector2(vp.x * (0.18 + randf() * 0.64), y_val),
		"radius": 24.0 + randf() * 18.0,
		"speed": 34.0 + randf() * 24.0,
		"sway_amp": 18.0 + randf() * 22.0,
		"sway_spd": 0.9 + randf() * 0.8,
		"phase": randf() * TAU,
		"hue_shift": randf(),
		"alpha": 0.0,
	}
	_bubbles.append(b)


func _update_ch2_bubbles(dt: float, vp: Vector2) -> void:
	_bubble_spawn_timer -= dt
	if not _stage_completing and _bubbles.size() < 7 and _bubble_spawn_timer <= 0.0:
		_spawn_soap_bubble(vp)
		_bubble_spawn_timer = 0.75

	# Drift spring petals
	for p_item: Dictionary in _petals:
		var pos: Vector2 = p_item["pos"] as Vector2
		pos.x += (28.0 + sin(_global_time + float(p_item["phase"])) * 16.0) * dt
		pos.y += (20.0 + float(p_item["speed"]) * 0.35) * dt
		if pos.y > vp.y + 20.0 or pos.x > vp.x + 20.0:
			pos = Vector2(randf() * vp.x * 0.8, -15.0)
		p_item["pos"] = pos
		p_item["rot"] = float(p_item["rot"]) + dt * float(p_item["rot_spd"])

	# Rise bubbles and allow gentle touch-popping by moving spark into them
	var i: int = _bubbles.size() - 1
	while i >= 0:
		var b: Dictionary = _bubbles[i]
		var b_pos: Vector2 = b["pos"] as Vector2
		var b_rad: float = float(b["radius"])
		b_pos.y -= float(b["speed"]) * dt
		b_pos.x += sin(_global_time * float(b["sway_spd"]) + float(b["phase"])) * float(b["sway_amp"]) * dt
		b["pos"] = b_pos
		b["alpha"] = minf(1.0, float(b["alpha"]) + dt * 1.8)

		if not _stage_completing and _spark_pos.distance_to(b_pos) < b_rad + 14.0:
			_pop_bubble_index(i)
			i -= 1
			continue

		if b_pos.y < -60.0:
			_bubbles.remove_at(i)
		i -= 1


func _try_pop_bubble_at(pos: Vector2, extra_margin: float) -> void:
	for i: int in range(_bubbles.size() - 1, -1, -1):
		var b: Dictionary = _bubbles[i]
		var b_pos: Vector2 = b["pos"] as Vector2
		var b_rad: float = float(b["radius"])
		if pos.distance_to(b_pos) <= b_rad + extra_margin:
			_pop_bubble_index(i)
			return


func _pop_bubble_index(idx: int) -> void:
	if idx < 0 or idx >= _bubbles.size():
		return
	var b: Dictionary = _bubbles[idx]
	var b_pos: Vector2 = b["pos"] as Vector2
	var b_rad: float = float(b["radius"])
	_bubbles.remove_at(idx)

	_spawn_ripple(b_pos, Color(0.96, 0.92, 0.78, 0.9), b_rad * 2.8)
	_spawn_ripple(b_pos, Color(0.72, 0.94, 0.98, 0.75), b_rad * 2.0)

	if audio != null and audio.has_method("play_bubble_pop"):
		audio.call("play_bubble_pop", _bubbles_popped)

	var line_idx: int = mini(_bubbles_popped, BUBBLE_LINES.size() - 1)
	_bubbles_popped += 1
	_set_narration(BUBBLE_LINES[line_idx], "")
	_set_controls_hint("[Мышь / WASD] Коснуться мыльных пузырей (%d / 6)" % mini(_bubbles_popped, 6))

	if _bubbles_popped >= 6 and not _stage_completing:
		_stage_completing = true
		_finish_ch2_bubbles_async()


func _finish_ch2_bubbles_async() -> void:
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return
	await _fade_to_veil(0.95)
	if not is_inside_tree():
		return
	_start_chapter_2_wallpaper()


# =============================================================================
# CHAPTER 2B — ВЕСНА 4: СОЛНЦЕ НА ОБОЯХ
# =============================================================================

func _start_chapter_2_wallpaper() -> void:
	_stage = STAGE_CH2_WALLPAPER
	_stage_time = 0.0
	_stage_completing = false
	_wall_strokes.clear()
	_wall_is_drawing = false
	_wall_arc_length = 0.0
	_wall_sun_progress = 0.0
	_wall_father_sit = 0.0
	_wall_sun_complete = false
	_wall_mid_line_shown = false
	_wall_sectors.clear()
	for _s: int in range(16):
		_wall_sectors.append(false)
	_ripples.clear()

	_set_header("Г Л А В А   I I   ·   В Е С Н А   4", "Солнце на обоях")
	_set_controls_hint("[Удерживать ЛКМ] или [Space + WASD] Нарисовать золотое солнце на стене")
	_set_narration(
		"Вечерний свет ложится на тёплые обои гостиной.",
		"Нарисуй на стене золотое солнце — прямо поверх строгих правил взрослого мира."
	)

	_set_mood_target(
		Color(0.42, 0.29, 0.23, 1.0),
		Color(0.67, 0.46, 0.32, 1.0),
		Color(0.89, 0.70, 0.48, 1.0),
		Color(1.0, 0.89, 0.62, 1.0),
		0.82,
		Vector2(0.24, 0.24),
		0.62,
		0.28,
		0.14
	)
	if audio != null and audio.has_method("set_mood"):
		audio.call("set_mood", "room")

	_fade_in_from_veil(0.95)


func _get_wallpaper_sun_center(vp: Vector2) -> Vector2:
	return Vector2(vp.x * 0.44, vp.y * 0.46)


func _update_ch2_wallpaper(dt: float, vp: Vector2) -> void:
	if _wall_is_drawing and not _wall_sun_complete and _using_keyboard_cursor:
		_append_wallpaper_point(_spark_pos)

	var target_sit: float = clampf(_wall_sun_progress * 1.15, 0.0, 1.0)
	_wall_father_sit = lerpf(_wall_father_sit, target_sit, minf(1.0, dt * 1.8))

	if _wall_sun_complete:
		_tgt_sun_pos = Vector2(0.44, 0.46)
		_tgt_ray_strength = 1.05


func _append_wallpaper_point(pos: Vector2) -> void:
	if _wall_strokes.is_empty():
		var first: PackedVector2Array = PackedVector2Array()
		first.append(pos)
		_wall_strokes.append(first)
		return

	var current: PackedVector2Array = _wall_strokes[_wall_strokes.size() - 1]
	if current.size() > 0:
		var last_p: Vector2 = current[current.size() - 1]
		var seg_len: float = last_p.distance_to(pos)
		if seg_len < 4.5:
			return
		current.append(pos)
		_wall_strokes[_wall_strokes.size() - 1] = current

		var vp: Vector2 = _get_vp_size()
		var center: Vector2 = _get_wallpaper_sun_center(vp)
		var d: float = pos.distance_to(center)
		if d > 28.0 and d < 175.0:
			_wall_arc_length += seg_len
			var ang: float = atan2(pos.y - center.y, pos.x - center.x)
			if ang < 0.0:
				ang += TAU
			var sec_idx: int = clampi(int(ang / TAU * 16.0), 0, 15)
			_wall_sectors[sec_idx] = true
			if audio != null and audio.has_method("play_crayon_stroke"):
				audio.call("play_crayon_stroke", ang / TAU)

		var covered: int = 0
		for flag: bool in _wall_sectors:
			if flag:
				covered += 1

		var sector_ratio: float = float(covered) / 11.0
		var arc_ratio: float = _wall_arc_length / 520.0
		_wall_sun_progress = clampf(maxf(sector_ratio, arc_ratio * 0.85), 0.0, 1.0)

		if not _wall_mid_line_shown and _wall_sun_progress >= 0.48 and _wall_sun_progress < 0.99:
			_wall_mid_line_shown = true
			_set_narration(
				"Отец останавливается в дверях и тихо опускает портфель на пол.",
				"Ещё немного — замкни солнечный круг."
			)

		if _wall_sun_progress >= 1.0 and not _wall_sun_complete:
			_wall_sun_complete = true
			_wall_is_drawing = false
			_stage_completing = true
			_spawn_ripple(center, COLOR_GOLD, 320.0)
			if audio != null and audio.has_method("play_sun_complete"):
				audio.call("play_sun_complete")
			_set_narration(
				"Он садится рядом с тобой прямо на пол, забыв о звонках и бумагах.",
				"«Ни одно дело в мире не важнее твоего солнца на стене.»"
			)
			_finish_ch2_wallpaper_async()


func _finish_ch2_wallpaper_async() -> void:
	await get_tree().create_timer(3.6).timeout
	if not is_inside_tree():
		return
	await _fade_to_veil(1.0)
	if not is_inside_tree():
		return
	_start_chapter_2_sea()


# =============================================================================
# CHAPTER 2C — ВЕСНА 7: ВЕЧЕР У МОРЯ
# =============================================================================

func _start_chapter_2_sea() -> void:
	_stage = STAGE_CH2_SEA
	_stage_time = 0.0
	_stage_completing = false
	_sea_choice_made = false
	_ripples.clear()

	_set_header("Г Л А В А   I I   ·   В Е С Н А   7", "Вечер у моря")
	_set_controls_hint("Выбери, какое воспоминание сердце сохранит навсегда")
	_set_narration(
		"Седьмое лето пахнет солью, тёплым ветром и закатом.",
		"Время уже начинает истончаться, как морская пена у ног. Что запомнит твоё сердце?"
	)

	_set_mood_target(
		Color(0.118, 0.141, 0.322, 1.0),
		Color(0.620, 0.298, 0.416, 1.0),
		Color(0.957, 0.612, 0.384, 1.0),
		Color(1.0, 0.84, 0.56, 1.0),
		0.88,
		Vector2(0.50, 0.54),
		1.08,
		0.26,
		0.0
	)
	if audio != null and audio.has_method("set_mood"):
		audio.call("set_mood", "sea")

	_build_sea_choices()
	_fade_in_from_veil(1.05)


func _build_sea_choices() -> void:
	for child: Node in choice_container.get_children():
		child.queue_free()

	var options: Array[Dictionary] = [
		{
			"id": "mothers_laughter",
			"label": "Смех матери в залитом солнцем саду",
			"reply": "«Её смех будет звучать во мне даже там, где нет ни времени, ни слов.»",
		},
		{
			"id": "fathers_hand",
			"label": "Тёплую ладонь отца на закатном берегу",
			"reply": "«Он больше не прячет своё сердце. Я запомню тепло его пальцев навсегда.»",
		},
		{
			"id": "parents_together",
			"label": "Тихий свет их любви, когда они снова рядом",
			"reply": "«Мы стоим у моря втроём — и ради этого мгновения стоило прийти на Землю.»",
		},
	]

	for opt: Dictionary in options:
		var btn: Button = _create_art_deco_button(str(opt["label"]), 560.0)
		var choice_id: String = str(opt["id"])
		var reply_text: String = str(opt["reply"])
		btn.pressed.connect(func() -> void:
			_on_sea_choice_selected(choice_id, reply_text)
		)
		choice_container.add_child(btn)

	choice_container.visible = true
	choice_container.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(choice_container, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)


func _on_sea_choice_selected(choice_id: String, reply_text: String) -> void:
	if _sea_choice_made:
		return
	_sea_choice_made = true
	_stage_completing = true

	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr != null and save_mgr.has_method("record_choice"):
		save_mgr.call("record_choice", "lesson1_earth_memory", choice_id)

	if audio != null and audio.has_method("play_choice_chime"):
		audio.call("play_choice_chime")

	var vp: Vector2 = _get_vp_size()
	_spawn_ripple(Vector2(vp.x * 0.5, vp.y * 0.68), COLOR_GOLD, 300.0)

	var tw: Tween = create_tween()
	tw.tween_property(choice_container, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func() -> void:
		choice_container.visible = false
	)

	_set_narration(reply_text, "Закат медленно уходит за горизонт. Приближается восьмая зима.")
	_set_controls_hint("")

	# Dim sunset softly into twilight
	_set_mood_target(
		Color(0.05, 0.07, 0.16, 1.0),
		Color(0.22, 0.16, 0.28, 1.0),
		Color(0.45, 0.28, 0.30, 1.0),
		Color(0.92, 0.76, 0.56, 1.0),
		0.35,
		Vector2(0.50, 0.62),
		0.50,
		0.46,
		0.0
	)
	_finish_ch2_sea_async()


func _finish_ch2_sea_async() -> void:
	await get_tree().create_timer(3.8).timeout
	if not is_inside_tree():
		return
	await _fade_to_veil(1.3)
	if not is_inside_tree():
		return
	_begin_chapter_with_video_slot(2, _start_chapter_3_eighth_winter)


func _update_ch2_sea(_dt: float, _vp: Vector2) -> void:
	pass


# =============================================================================
# CHAPTER 3 — «ВОСЬМАЯ ЗИМА» (КУЛЬМИНАЦИЯ)
# =============================================================================

func _start_chapter_3_eighth_winter() -> void:
	_stage = STAGE_CH3_EIGHTH_WINTER
	_stage_time = 0.0
	_stage_completing = false
	_ch3_holding = false
	_ch3_transfer = 0.0
	_ch3_heartbeat_timer = 0.8
	_ch3_heartbeat_pulse = 0.0
	_ch3_stage_line = 0
	_ch3_final_sequence = false
	_ch3_ember_rise = 0.0
	_ch3_stream_particles.clear()
	_ripples.clear()
	choice_container.visible = false

	_set_header("Г Л А В А   I I I", "Восьмая зима")
	_set_controls_hint("[Удерживать ЛКМ / Space] Отдать последнее тепло в ладони родителей")
	_set_narration(
		"Тихая лунная комната. За окном падает снег, а время замедляется почти до шёпота.",
		"Удерживай ЛКМ или Space, чтобы отдать им всё тепло, собранное за семь вёсен."
	)

	_set_mood_target(
		Color(0.027, 0.051, 0.114, 1.0),
		Color(0.059, 0.106, 0.200, 1.0),
		Color(0.094, 0.153, 0.259, 1.0),
		Color(0.76, 0.85, 0.98, 1.0),
		0.14,
		Vector2(0.78, 0.16),
		0.45,
		0.56,
		0.0
	)
	if audio != null and audio.has_method("set_mood"):
		audio.call("set_mood", "farewell")

	_fade_in_from_veil(1.35)


func _update_ch3_eighth_winter(dt: float, vp: Vector2) -> void:
	# Drift quiet moonbeam dust motes
	for m: Dictionary in _motes:
		var mp: Vector2 = m["pos"] as Vector2
		mp.y -= float(m["speed"]) * dt
		mp.x += sin(_global_time * 0.5 + float(m["phase"])) * 6.0 * dt
		if mp.y < -10.0:
			mp = Vector2(randf() * vp.x, vp.y + 10.0)
		m["pos"] = mp

	# Slowing heartbeat as child gives away warmth
	_ch3_heartbeat_pulse = maxf(0.0, _ch3_heartbeat_pulse - dt * 2.4)
	if not _ch3_final_sequence:
		_ch3_heartbeat_timer -= dt
		if _ch3_heartbeat_timer <= 0.0:
			var strength: float = lerpf(0.95, 0.28, _ch3_transfer)
			_ch3_heartbeat_pulse = 1.0
			if audio != null and audio.has_method("play_heartbeat"):
				audio.call("play_heartbeat", strength)
			_ch3_heartbeat_timer = lerpf(1.18, 1.95, _ch3_transfer)

	# Warmth transfer mechanic
	if _ch3_holding and not _ch3_final_sequence:
		_ch3_transfer = clampf(_ch3_transfer + dt * 0.155, 0.0, 1.0)
		if audio != null and audio.has_method("set_warmth_transfer_active"):
			audio.call("set_warmth_transfer_active", true, _ch3_transfer)

		# Spawn golden stream motes from center heart to left & right palms
		if randf() < dt * 28.0:
			var side: float = -1.0 if randf() < 0.5 else 1.0
			_ch3_stream_particles.append({
				"t": 0.0,
				"speed": 0.65 + randf() * 0.45,
				"side": side,
				"arc": (randf() - 0.5) * 90.0,
				"size": 2.4 + randf() * 2.8,
			})

		# Update shader warmth subtly as parents' palms warm up
		_tgt_warmth = lerpf(0.14, 0.42, _ch3_transfer)
		_tgt_ray_color = Color(0.76, 0.85, 0.98, 1.0).lerp(Color(1.0, 0.86, 0.62, 1.0), _ch3_transfer * 0.65)

		# Quiet poetic milestones
		if _ch3_transfer >= 0.20 and _ch3_stage_line < 1:
			_ch3_stage_line = 1
			_set_narration("Я отдам вам всё тепло, которое успела собрать за семь вёсен…", "")
		elif _ch3_transfer >= 0.55 and _ch3_stage_line < 2:
			_ch3_stage_line = 2
			_set_narration("Пусть оно останется в ваших ладонях, когда наступит ночь…", "")
		elif _ch3_transfer >= 0.85 and _ch3_stage_line < 3:
			_ch3_stage_line = 3
			_set_narration("Вы больше не замёрзнете. Никогда.", "")

		if _ch3_transfer >= 1.0:
			_ch3_final_sequence = true
			_ch3_holding = false
			_stage_completing = true
			if audio != null and audio.has_method("set_warmth_transfer_active"):
				audio.call("set_warmth_transfer_active", false, 1.0)
			_play_ch3_final_sequence_async()

	# Advance stream particles
	var i: int = _ch3_stream_particles.size() - 1
	while i >= 0:
		var sp: Dictionary = _ch3_stream_particles[i]
		sp["t"] = float(sp["t"]) + float(sp["speed"]) * dt
		if float(sp["t"]) >= 1.0:
			_ch3_stream_particles.remove_at(i)
		i -= 1

	if _ch3_final_sequence:
		_ch3_ember_rise += dt * 14.0


func _play_ch3_final_sequence_async() -> void:
	_set_controls_hint("")
	if audio != null and audio.has_method("set_mood"):
		audio.call("set_mood", "silent")

	# Hold a beat of sacred silence
	_set_narration("", "")
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return

	_set_narration("«Мамочка, папочка, не плачьте…»", "")
	await get_tree().create_timer(2.4).timeout
	if not is_inside_tree():
		return

	_set_narration(
		"«Мамочка, папочка, не плачьте…»",
		"«…мне уже совсем не больно.»"
	)
	await get_tree().create_timer(3.6).timeout
	if not is_inside_tree():
		return

	await _fade_to_veil(1.6)
	if not is_inside_tree():
		return
	_begin_chapter_with_video_slot(3, _start_chapter_4_two_hands)


# =============================================================================
# CHAPTER 4 — «РАЗЛОМ И ДВЕ РУКИ В ТЕМНОТЕ»
# =============================================================================

func _start_chapter_4_two_hands() -> void:
	_stage = STAGE_CH4_TWO_HANDS
	_stage_time = 0.0
	_stage_completing = false
	_ch4_united = false
	_ch4_unite_anim = 0.0
	_ch4_vortex_petals.clear()
	_ch4_vortex_timer = 0.0
	_ripples.clear()
	choice_container.visible = false

	_set_header("Г Л А В А   I V", "Разлом и две руки в темноте")
	_set_controls_hint("[ЛКМ / Space] Помочь их рукам найти друг друга")
	_set_narration(
		"В эту ночь их мир раскололся надвое.",
		"Но в самой глубокой темноте осталось тепло, которое ты оставила в их ладонях."
	)

	_set_mood_target(
		Color(0.016, 0.027, 0.067, 1.0),
		Color(0.031, 0.055, 0.118, 1.0),
		Color(0.047, 0.082, 0.165, 1.0),
		Color(0.88, 0.78, 0.56, 1.0),
		0.0,
		Vector2(0.50, 0.52),
		0.08,
		0.68,
		0.0
	)
	if audio != null and audio.has_method("set_mood"):
		audio.call("set_mood", "ascension")

	_fade_in_from_veil(1.25)


func _trigger_ch4_unite() -> void:
	_ch4_united = true
	_stage_completing = true
	_set_controls_hint("")

	var vp: Vector2 = _get_vp_size()
	_spawn_ripple(Vector2(vp.x * 0.5, vp.y * 0.54), COLOR_GOLD, 380.0)
	_spawn_ripple(Vector2(vp.x * 0.5, vp.y * 0.54), COLOR_IVORY, 220.0)

	if audio != null and audio.has_method("play_hands_unite"):
		audio.call("play_hands_unite")

	_set_narration(
		"В ту ночь он впервые за долгие годы нашёл в темноте её дрожащую руку —",
		"и уже не отпустил."
	)

	_set_mood_target(
		Color(0.11, 0.15, 0.30, 1.0),
		Color(0.52, 0.38, 0.30, 1.0),
		Color(0.95, 0.79, 0.47, 1.0),
		Color(1.0, 0.90, 0.62, 1.0),
		1.0,
		Vector2(0.50, 0.46),
		1.35,
		0.18,
		0.45
	)
	_finish_chapter_4_async()


func _update_ch4_two_hands(dt: float, vp: Vector2) -> void:
	if not _ch4_united:
		return

	_ch4_unite_anim = minf(1.0, _ch4_unite_anim + dt * 0.52)

	# Spawn ascending golden petal vortex from center of joined hands
	_ch4_vortex_timer -= dt
	if _ch4_vortex_timer <= 0.0 and _ch4_vortex_petals.size() < 95:
		_ch4_vortex_timer = 0.032
		_ch4_vortex_petals.append({
			"angle": randf() * TAU,
			"radius": 6.0 + randf() * 24.0,
			"y_off": 0.0,
			"rise_spd": 95.0 + randf() * 110.0,
			"spin_spd": (1.6 + randf() * 1.8) * (1.0 if randf() < 0.5 else -1.0),
			"size": 4.0 + randf() * 6.5,
			"alpha": 0.95,
		})

	var i: int = _ch4_vortex_petals.size() - 1
	while i >= 0:
		var pt: Dictionary = _ch4_vortex_petals[i]
		pt["y_off"] = float(pt["y_off"]) + float(pt["rise_spd"]) * dt
		pt["angle"] = float(pt["angle"]) + float(pt["spin_spd"]) * dt
		pt["radius"] = float(pt["radius"]) + dt * 36.0
		if float(pt["y_off"]) > vp.y * 0.75:
			pt["alpha"] = maxf(0.0, float(pt["alpha"]) - dt * 1.6)
		if float(pt["alpha"]) <= 0.01:
			_ch4_vortex_petals.remove_at(i)
		i -= 1


func _finish_chapter_4_async() -> void:
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return
	if audio != null and audio.has_method("play_ascension_chord"):
		audio.call("play_ascension_chord")

	await get_tree().create_timer(3.6).timeout
	if not is_inside_tree():
		return

	_stage = STAGE_FINISHED
	_complete_earth_life_and_return_to_akasha()


func _complete_earth_life_and_return_to_akasha() -> void:
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr != null and save_mgr.has_method("set_lesson1_stage"):
		save_mgr.call("set_lesson1_stage", "sunset_return")

	var flow_mgr: Node = get_node_or_null("/root/SceneFlowManager")
	if flow_mgr != null:
		_set_object_property_safe(flow_mgr, "pending_world_mode", "lesson1_sunset_return")
		if flow_mgr.has_method("transition_to_scene"):
			flow_mgr.call("transition_to_scene", "res://scenes/world_3d.tscn", true)
			return

	get_tree().change_scene_to_file("res://scenes/world_3d.tscn")


# =============================================================================
# CUSTOM PAINTERLY _draw() — GRIS + SPIRITFARER + MAKOTO SHINKAI
# =============================================================================

func _on_stage_draw() -> void:
	var vp: Vector2 = _get_vp_size()
	match _stage:
		STAGE_CH1_WINTER:
			_draw_ch1_winter(vp)
		STAGE_CH2_BUBBLES:
			_draw_ch2_bubbles(vp)
		STAGE_CH2_WALLPAPER:
			_draw_ch2_wallpaper(vp)
		STAGE_CH2_SEA:
			_draw_ch2_sea(vp)
		STAGE_CH3_EIGHTH_WINTER:
			_draw_ch3_eighth_winter(vp)
		STAGE_CH4_TWO_HANDS, STAGE_FINISHED:
			_draw_ch4_two_hands(vp)

	_draw_ripples()

	# Draw the warm guiding child spark in interactive cursor chapters
	if _stage == STAGE_CH1_WINTER or _stage == STAGE_CH2_BUBBLES or _stage == STAGE_CH2_WALLPAPER:
		_draw_child_spark()


func _draw_ch1_winter(vp: Vector2) -> void:
	var w: float = _ch1_warmth_anim
	var cx: float = vp.x * 0.5

	# 1. Tall arched winter window in background
	var win_w: float = vp.x * 0.28
	var win_h: float = vp.y * 0.56
	var win_x: float = cx - win_w * 0.5
	var win_y: float = vp.y * 0.14
	var win_bg: Color = Color(0.11, 0.17, 0.29, 0.72).lerp(Color(0.26, 0.22, 0.28, 0.62), w)
	stage_canvas.draw_rect(Rect2(win_x, win_y + 52.0, win_w, win_h - 52.0), win_bg, true)
	stage_canvas.draw_circle(Vector2(cx, win_y + 56.0), win_w * 0.5, win_bg)

	# Falling snowflakes inside window silhouette
	for flake: Dictionary in _snowflakes:
		var fp: Vector2 = flake["pos"] as Vector2
		if fp.x > win_x + 8.0 and fp.x < win_x + win_w - 8.0 and fp.y > win_y + 12.0 and fp.y < win_y + win_h - 6.0:
			var snow_a: float = lerpf(0.65, 0.22, w)
			stage_canvas.draw_circle(fp, float(flake["size"]), Color(0.86, 0.92, 1.0, snow_a))

	# Delicate GRIS window mullions & arch frame
	var frame_col: Color = Color(0.28, 0.36, 0.50, 0.75).lerp(Color(0.76, 0.58, 0.38, 0.72), w)
	stage_canvas.draw_line(Vector2(cx, win_y), Vector2(cx, win_y + win_h), frame_col, 2.0, true)
	stage_canvas.draw_line(Vector2(win_x, win_y + win_h * 0.44), Vector2(win_x + win_w, win_y + win_h * 0.44), frame_col, 2.0, true)
	stage_canvas.draw_line(Vector2(win_x, win_y + win_h), Vector2(win_x + win_w, win_y + win_h), frame_col, 3.0, true)
	stage_canvas.draw_arc(Vector2(cx, win_y + 56.0), win_w * 0.5, PI, TAU, 36, frame_col, 2.2, true)
	stage_canvas.draw_line(Vector2(win_x, win_y + 56.0), Vector2(win_x, win_y + win_h), frame_col, 2.2, true)
	stage_canvas.draw_line(Vector2(win_x + win_w, win_y + 56.0), Vector2(win_x + win_w, win_y + win_h), frame_col, 2.2, true)

	# Warm hearth glow over the center of the table as warmth grows
	if w > 0.01:
		var hearth_center: Vector2 = Vector2(cx, vp.y * 0.62)
		_draw_soft_glow(hearth_center, 260.0 * w, Color(1.0, 0.78, 0.40, 0.28 * w))

	# 2. Mother (left) and Father (right) silhouettes gently drawing closer with warmth
	var lean_in: float = w * 46.0
	var sil_col: Color = Color(0.06, 0.09, 0.16, 0.95).lerp(Color(0.14, 0.10, 0.12, 0.94), w)
	var rim_col: Color = Color(0.55, 0.70, 0.90, 0.35).lerp(Color(1.0, 0.82, 0.48, 0.68), w)

	var mother_base: Vector2 = Vector2(vp.x * 0.31 + lean_in, vp.y * 0.72)
	_draw_parent_silhouette(mother_base, sil_col, rim_col, true, w)

	var father_base: Vector2 = Vector2(vp.x * 0.69 - lean_in, vp.y * 0.72)
	_draw_parent_silhouette(father_base, sil_col, rim_col, false, w)

	# 3. Minimalist dining table & floor plane
	var table_y: float = vp.y * 0.70
	var table_w: float = vp.x * 0.44
	stage_canvas.draw_rect(Rect2(cx - table_w * 0.5, table_y, table_w, 9.0), sil_col, true)
	stage_canvas.draw_line(Vector2(cx - table_w * 0.5, table_y), Vector2(cx + table_w * 0.5, table_y), rim_col, 1.5, true)
	stage_canvas.draw_rect(Rect2(cx - table_w * 0.42, table_y + 9.0, 8.0, vp.y * 0.22), sil_col, true)
	stage_canvas.draw_rect(Rect2(cx + table_w * 0.42 - 8.0, table_y + 9.0, 8.0, vp.y * 0.22), sil_col, true)
	stage_canvas.draw_rect(Rect2(0.0, vp.y * 0.88, vp.x, vp.y * 0.14), Color(0.04, 0.06, 0.11, 0.95), true)

	# 4. Three interactive cold points -> blooming golden embers
	for pt: Dictionary in _cold_points:
		var p: Vector2 = pt["pos"] as Vector2
		var g: float = float(pt["glow"])
		var pulse: float = 0.5 + 0.5 * sin(_global_time * 2.6 + p.x * 0.01)
		if g < 0.95:
			var ice_col: Color = Color(0.62, 0.82, 0.98, (1.0 - g) * (0.45 + 0.35 * pulse))
			stage_canvas.draw_arc(p, 24.0 + pulse * 10.0, 0.0, TAU, 32, ice_col, 1.6, true)
			stage_canvas.draw_arc(p, 13.0, 0.0, TAU, 24, ice_col, 1.2, true)
			# Small frost star
			for a_i: int in range(6):
				var ang: float = float(a_i) * PI / 3.0 + _global_time * 0.25
				var dir: Vector2 = Vector2(cos(ang), sin(ang))
				stage_canvas.draw_line(p - dir * 8.0, p + dir * 8.0, ice_col, 1.2, true)
		if g > 0.02:
			_draw_soft_glow(p, 56.0 * g, Color(1.0, 0.82, 0.44, 0.48 * g))
			stage_canvas.draw_circle(p, 5.5 * g, COLOR_IVORY)


func _draw_parent_silhouette(base_pos: Vector2, fill_col: Color, rim_col: Color, is_mother: bool, warmth_amt: float) -> void:
	var dir_sign: float = 1.0 if is_mother else -1.0
	var head_lift: float = warmth_amt * 14.0
	var lean_x: float = dir_sign * warmth_amt * 18.0

	# Torso & cloak/shoulders polygon
	var shoulder_w: float = 34.0 if is_mother else 42.0
	var torso_h: float = 112.0 if is_mother else 124.0
	var torso: PackedVector2Array = PackedVector2Array([
		base_pos + Vector2(-shoulder_w * 0.9, 10.0),
		base_pos + Vector2(-shoulder_w * 0.72 + lean_x * 0.4, -torso_h * 0.78),
		base_pos + Vector2(lean_x * 0.7, -torso_h),
		base_pos + Vector2(shoulder_w * 0.72 + lean_x * 0.5, -torso_h * 0.76),
		base_pos + Vector2(shoulder_w * 0.88, 10.0),
	])
	stage_canvas.draw_colored_polygon(torso, fill_col)

	# Head
	var head_pos: Vector2 = base_pos + Vector2(lean_x + dir_sign * 4.0, -torso_h - 24.0 - head_lift * 0.35)
	stage_canvas.draw_circle(head_pos, 21.0 if is_mother else 22.5, fill_col)

	# Hair bun for mother / collar line for father
	if is_mother:
		stage_canvas.draw_circle(head_pos + Vector2(-dir_sign * 17.0, -6.0), 11.0, fill_col)

	# Soft inner rim highlight facing the center light
	stage_canvas.draw_arc(
		head_pos,
		21.5 if is_mother else 23.0,
		(-0.6 if is_mother else PI - 0.6),
		(0.75 if is_mother else PI + 0.75),
		16,
		rim_col,
		2.0,
		true
	)


func _draw_ch2_bubbles(vp: Vector2) -> void:
	# 1. Soft painterly garden hills & sunlit meadow along the bottom
	var hill_back: PackedVector2Array = PackedVector2Array()
	hill_back.append(Vector2(0.0, vp.y))
	for i: int in range(17):
		var t: float = float(i) / 16.0
		var hx: float = t * vp.x
		var hy: float = vp.y * 0.80 - sin(t * PI) * 42.0 - cos(t * PI * 2.2) * 14.0
		hill_back.append(Vector2(hx, hy))
	hill_back.append(Vector2(vp.x, vp.y))
	stage_canvas.draw_colored_polygon(hill_back, Color(0.24, 0.43, 0.36, 0.55))

	var hill_front: PackedVector2Array = PackedVector2Array()
	hill_front.append(Vector2(0.0, vp.y))
	for i: int in range(17):
		var t: float = float(i) / 16.0
		var hx: float = t * vp.x
		var hy: float = vp.y * 0.86 - sin(t * PI * 1.3 + 0.4) * 26.0
		hill_front.append(Vector2(hx, hy))
	hill_front.append(Vector2(vp.x, vp.y))
	stage_canvas.draw_colored_polygon(hill_front, Color(0.15, 0.30, 0.25, 0.82))

	# Gentle swaying blades of grass
	for g_i: int in range(36):
		var gx: float = (float(g_i) / 35.0) * vp.x
		var sway: float = sin(_global_time * 1.6 + float(g_i) * 0.5) * 9.0
		var base_y: float = vp.y * 0.89 + sin(float(g_i) * 0.8) * 14.0
		stage_canvas.draw_line(
			Vector2(gx, base_y + 24.0),
			Vector2(gx + sway, base_y - 18.0 - float(g_i % 3) * 8.0),
			Color(0.22, 0.42, 0.31, 0.55),
			2.0,
			true
		)

	# 2. Silhouette of Mother spinning joyfully with the small child in lower-left garden
	var m_pos: Vector2 = Vector2(vp.x * 0.22, vp.y * 0.84)
	var spin_sway: float = sin(_global_time * 1.5) * 8.0
	var garden_sil: Color = Color(0.13, 0.21, 0.22, 0.88)
	var dress: PackedVector2Array = PackedVector2Array([
		m_pos + Vector2(-46.0 - spin_sway * 0.5, 18.0),
		m_pos + Vector2(-14.0, -76.0),
		m_pos + Vector2(14.0, -76.0),
		m_pos + Vector2(48.0 + spin_sway * 0.5, 18.0),
	])
	stage_canvas.draw_colored_polygon(dress, garden_sil)
	stage_canvas.draw_circle(m_pos + Vector2(spin_sway * 0.2, -96.0), 16.0, garden_sil)
	# Child held out in her arms
	var c_pos: Vector2 = m_pos + Vector2(54.0 + spin_sway * 0.6, -54.0 + cos(_global_time * 1.5) * 6.0)
	stage_canvas.draw_line(m_pos + Vector2(10.0, -68.0), c_pos + Vector2(-10.0, -4.0), garden_sil, 5.0, true)
	stage_canvas.draw_circle(c_pos + Vector2(0.0, -16.0), 10.5, garden_sil)
	stage_canvas.draw_circle(c_pos + Vector2(0.0, 2.0), 12.0, garden_sil)

	# 3. Drifting spring petals
	for p_item: Dictionary in _petals:
		var pp: Vector2 = p_item["pos"] as Vector2
		var p_sz: float = float(p_item["size"])
		stage_canvas.draw_circle(pp, p_sz, Color(1.0, 0.92, 0.90, 0.55))

	# 4. Iridescent soap bubbles
	for b: Dictionary in _bubbles:
		var bp: Vector2 = b["pos"] as Vector2
		var br: float = float(b["radius"])
		var ba: float = float(b["alpha"])
		var shift: float = float(b["hue_shift"])
		var fill_c: Color = Color(0.92, 0.97, 1.0, 0.14 * ba)
		var rim_a: Color = Color(0.75, 0.95, 1.0, 0.62 * ba)
		var rim_b: Color = Color(1.0, 0.84, 0.90, 0.58 * ba)
		var rim_c: Color = Color(1.0, 0.94, 0.68, 0.55 * ba)
		stage_canvas.draw_circle(bp, br, fill_c)
		stage_canvas.draw_arc(bp, br, shift * TAU, shift * TAU + PI * 0.85, 24, rim_a, 2.2, true)
		stage_canvas.draw_arc(bp, br, shift * TAU + PI * 0.85, shift * TAU + PI * 1.55, 24, rim_b, 2.0, true)
		stage_canvas.draw_arc(bp, br, shift * TAU + PI * 1.55, shift * TAU + TAU, 24, rim_c, 1.8, true)
		# Specular highlight crescent
		stage_canvas.draw_circle(bp + Vector2(-br * 0.34, -br * 0.34), br * 0.18, Color(1.0, 1.0, 1.0, 0.72 * ba))
		stage_canvas.draw_circle(bp + Vector2(br * 0.32, br * 0.28), br * 0.08, Color(1.0, 0.96, 0.82, 0.45 * ba))


func _draw_ch2_wallpaper(vp: Vector2) -> void:
	# 1. Subtle warm vertical wallpaper stripes & wainscoting baseboard
	var stripe_col: Color = Color(1.0, 0.92, 0.76, 0.06)
	var stripe_step: float = 54.0
	var x_pos: float = 0.0
	while x_pos < vp.x:
		stage_canvas.draw_rect(Rect2(x_pos, 0.0, 18.0, vp.y * 0.82), stripe_col, true)
		x_pos += stripe_step

	stage_canvas.draw_rect(Rect2(0.0, vp.y * 0.82, vp.x, vp.y * 0.18), Color(0.24, 0.15, 0.11, 0.92), true)
	stage_canvas.draw_line(Vector2(0.0, vp.y * 0.82), Vector2(vp.x, vp.y * 0.82), Color(0.95, 0.76, 0.48, 0.32), 2.0, true)

	# Diagonal warm window light shaft
	var shaft: PackedVector2Array = PackedVector2Array([
		Vector2(vp.x * 0.04, 0.0),
		Vector2(vp.x * 0.34, 0.0),
		Vector2(vp.x * 0.68, vp.y * 0.82),
		Vector2(vp.x * 0.22, vp.y * 0.82),
	])
	stage_canvas.draw_colored_polygon(shaft, Color(1.0, 0.90, 0.64, 0.09))

	# 2. Dotted golden sun guide circle on the wall
	var center: Vector2 = _get_wallpaper_sun_center(vp)
	var guide_r: float = 104.0
	if not _wall_sun_complete:
		var pulse: float = 0.5 + 0.5 * sin(_global_time * 2.2)
		for i: int in range(28):
			var a0: float = float(i) / 28.0 * TAU
			var a1: float = a0 + 0.10
			stage_canvas.draw_arc(center, guide_r, a0, a1, 4, Color(1.0, 0.88, 0.55, 0.30 + 0.22 * pulse), 2.2, true)

	# Glowing inner sun warmth growing with drawing progress
	if _wall_sun_progress > 0.02:
		_draw_soft_glow(center, 185.0 * _wall_sun_progress, Color(1.0, 0.84, 0.42, 0.38 * _wall_sun_progress))

	# Hand-drawn chalk/pastel golden rays when completed
	if _wall_sun_complete:
		for r_i: int in range(12):
			var ang: float = float(r_i) / 12.0 * TAU + _global_time * 0.08
			var dir: Vector2 = Vector2(cos(ang), sin(ang))
			var inner: Vector2 = center + dir * (guide_r + 18.0)
			var outer: Vector2 = center + dir * (guide_r + 56.0 + sin(_global_time * 2.0 + float(r_i)) * 8.0)
			stage_canvas.draw_line(inner, outer, Color(1.0, 0.90, 0.54, 0.78), 4.5, true)

	# 3. Player's drawn golden chalk strokes
	for stroke: PackedVector2Array in _wall_strokes:
		if stroke.size() < 2:
			continue
		stage_canvas.draw_polyline(stroke, Color(1.0, 0.84, 0.40, 0.32), 14.0, true)
		stage_canvas.draw_polyline(stroke, Color(1.0, 0.93, 0.64, 0.92), 6.0, true)

	# 4. Father silhouette (right) transitioning from standing with briefcase to sitting beside the child
	var sit_t: float = _wall_father_sit
	var father_x: float = lerpf(vp.x * 0.77, vp.x * 0.67, sit_t)
	var father_y: float = lerpf(vp.y * 0.82, vp.y * 0.85, sit_t)
	var f_col: Color = Color(0.16, 0.10, 0.09, 0.94)
	var body_h: float = lerpf(185.0, 118.0, sit_t)

	var f_body: PackedVector2Array = PackedVector2Array([
		Vector2(father_x - 36.0 - sit_t * 14.0, father_y),
		Vector2(father_x - 28.0, father_y - body_h),
		Vector2(father_x + 28.0, father_y - body_h),
		Vector2(father_x + 34.0 + sit_t * 8.0, father_y),
	])
	stage_canvas.draw_colored_polygon(f_body, f_col)
	stage_canvas.draw_circle(Vector2(father_x - sit_t * 6.0, father_y - body_h - 24.0), 21.0, f_col)

	# Briefcase: held in hand initially, then set down gently on the floor to his right
	var case_pos: Vector2 = Vector2(
		lerpf(father_x + 36.0, vp.x * 0.82, sit_t),
		lerpf(father_y - 72.0, vp.y * 0.79, sit_t)
	)
	stage_canvas.draw_rect(Rect2(case_pos.x - 22.0, case_pos.y - 16.0, 44.0, 30.0), Color(0.12, 0.08, 0.07, 0.95), true)
	stage_canvas.draw_arc(case_pos + Vector2(0.0, -16.0), 8.0, PI, TAU, 12, Color(0.12, 0.08, 0.07, 0.95), 2.5, true)


func _draw_ch2_sea(vp: Vector2) -> void:
	var horizon_y: float = vp.y * 0.56
	var cx: float = vp.x * 0.5

	# 1. Makoto Shinkai low sunset disc & horizon shimmer
	var sun_y: float = horizon_y - 24.0 if not _sea_choice_made else horizon_y + 6.0
	_draw_soft_glow(Vector2(cx, sun_y), 170.0, Color(1.0, 0.76, 0.44, 0.36))
	stage_canvas.draw_circle(Vector2(cx, sun_y), 38.0, Color(1.0, 0.93, 0.74, 0.90))

	# 2. Sea base
	stage_canvas.draw_rect(Rect2(0.0, horizon_y, vp.x, vp.y - horizon_y), Color(0.18, 0.16, 0.32, 0.92), true)

	# Shimmering vertical sunset reflection bars on the water
	for r_i: int in range(18):
		var t: float = float(r_i) / 17.0
		var ry: float = lerpf(horizon_y + 6.0, vp.y * 0.82, t)
		var bar_w: float = lerpf(78.0, 18.0, t) + sin(_global_time * 2.1 + float(r_i) * 0.9) * 14.0
		var rx: float = cx + sin(_global_time * 1.4 + float(r_i) * 1.3) * (6.0 + t * 14.0)
		stage_canvas.draw_line(
			Vector2(rx - bar_w * 0.5, ry),
			Vector2(rx + bar_w * 0.5, ry),
			Color(1.0, 0.82, 0.52, lerpf(0.62, 0.18, t)),
			lerpf(2.5, 4.5, t),
			true
		)

	# 3. Five animated parallax ocean wave ribbons
	for layer_i: int in range(5):
		var lt: float = float(layer_i) / 4.0
		var base_y: float = lerpf(horizon_y + 18.0, vp.y * 0.84, lt)
		var amp: float = lerpf(3.5, 9.5, lt)
		var wave_col: Color = Color(0.24, 0.19, 0.36, 0.55).lerp(Color(0.08, 0.08, 0.18, 0.92), lt)
		var crest_col: Color = Color(1.0, 0.76, 0.54, lerpf(0.45, 0.18, lt))
		var poly: PackedVector2Array = PackedVector2Array()
		var crest: PackedVector2Array = PackedVector2Array()
		poly.append(Vector2(0.0, vp.y))
		for seg: int in range(33):
			var st: float = float(seg) / 32.0
			var wx: float = st * vp.x
			var wy: float = base_y + sin(st * TAU * (2.5 + lt) + _global_time * (0.8 + lt * 0.35) + float(layer_i)) * amp
			poly.append(Vector2(wx, wy))
			crest.append(Vector2(wx, wy))
		poly.append(Vector2(vp.x, vp.y))
		stage_canvas.draw_colored_polygon(poly, wave_col)
		stage_canvas.draw_polyline(crest, crest_col, 1.5, true)

	# 4. Dark foreground shore & 3 silhouettes holding hands (Mother - Child - Father)
	var shore_y: float = vp.y * 0.85
	stage_canvas.draw_rect(Rect2(0.0, shore_y, vp.x, vp.y - shore_y), Color(0.05, 0.05, 0.11, 0.98), true)

	var sil: Color = Color(0.04, 0.04, 0.09, 0.98)
	var m_x: float = cx - 64.0
	var c_x: float = cx
	var f_x: float = cx + 64.0

	# Mother
	_draw_standing_silhouette(Vector2(m_x, shore_y + 8.0), 118.0, 22.0, sil, true)
	# Child (7 years old, center)
	_draw_standing_silhouette(Vector2(c_x, shore_y + 8.0), 68.0, 14.0, sil, false)
	# Father
	_draw_standing_silhouette(Vector2(f_x, shore_y + 8.0), 132.0, 25.0, sil, false)

	# Joined hands between Mother-Child and Child-Father
	stage_canvas.draw_line(Vector2(m_x + 12.0, shore_y - 54.0), Vector2(c_x - 10.0, shore_y - 36.0), sil, 5.0, true)
	stage_canvas.draw_line(Vector2(c_x + 10.0, shore_y - 36.0), Vector2(f_x - 14.0, shore_y - 58.0), sil, 5.0, true)
	# Gentle warm light around the joined hands
	_draw_soft_glow(Vector2(c_x, shore_y - 40.0), 54.0, Color(1.0, 0.82, 0.48, 0.24))


func _draw_standing_silhouette(foot_pos: Vector2, height: float, half_w: float, col: Color, has_dress: bool) -> void:
	var skirt_extra: float = 12.0 if has_dress else 0.0
	var body: PackedVector2Array = PackedVector2Array([
		foot_pos + Vector2(-half_w - skirt_extra, 0.0),
		foot_pos + Vector2(-half_w * 0.72, -height),
		foot_pos + Vector2(half_w * 0.72, -height),
		foot_pos + Vector2(half_w + skirt_extra, 0.0),
	])
	stage_canvas.draw_colored_polygon(body, col)
	var head_r: float = half_w * 0.68
	stage_canvas.draw_circle(foot_pos + Vector2(0.0, -height - head_r * 1.1), head_r, col)


func _draw_ch3_eighth_winter(vp: Vector2) -> void:
	var center: Vector2 = Vector2(vp.x * 0.5, vp.y * 0.50)
	var left_palm: Vector2 = Vector2(vp.x * 0.28, vp.y * 0.52)
	var right_palm: Vector2 = Vector2(vp.x * 0.72, vp.y * 0.52)

	# 1. Diagonal silver moonbeam from upper-right window
	var moonbeam: PackedVector2Array = PackedVector2Array([
		Vector2(vp.x * 0.68, 0.0),
		Vector2(vp.x * 0.96, 0.0),
		Vector2(vp.x * 0.54, vp.y),
		Vector2(vp.x * 0.24, vp.y),
	])
	stage_canvas.draw_colored_polygon(moonbeam, Color(0.76, 0.86, 1.0, 0.055))

	# Floating dust motes in moonlight
	for m: Dictionary in _motes:
		var mp: Vector2 = m["pos"] as Vector2
		stage_canvas.draw_circle(mp, float(m["size"]), Color(0.84, 0.90, 1.0, 0.24))

	# 2. Parents' warm cupped hands on left & right (glowing brighter as transfer progresses)
	var palm_glow: float = 0.16 + _ch3_transfer * 0.84
	_draw_soft_glow(left_palm, 95.0 + 70.0 * _ch3_transfer, Color(1.0, 0.80, 0.44, 0.34 * palm_glow))
	_draw_soft_glow(right_palm, 95.0 + 70.0 * _ch3_transfer, Color(1.0, 0.80, 0.44, 0.34 * palm_glow))
	_draw_cupped_hand(left_palm, 1.0, palm_glow)
	_draw_cupped_hand(right_palm, -1.0, palm_glow)

	# 3. Delicate golden transfer threads & particles flowing from child's heart to parents' palms
	if _ch3_holding and not _ch3_final_sequence:
		var thread_col: Color = Color(1.0, 0.88, 0.56, 0.38)
		_draw_curved_thread(center, left_palm, -26.0, thread_col)
		_draw_curved_thread(center, left_palm, 22.0, thread_col)
		_draw_curved_thread(center, right_palm, -26.0, thread_col)
		_draw_curved_thread(center, right_palm, 22.0, thread_col)

	for sp: Dictionary in _ch3_stream_particles:
		var t: float = float(sp["t"])
		var side: float = float(sp["side"])
		var target_p: Vector2 = right_palm if side > 0.0 else left_palm
		var mid_p: Vector2 = (center + target_p) * 0.5 + Vector2(0.0, float(sp["arc"]))
		var q0: Vector2 = center.lerp(mid_p, t)
		var q1: Vector2 = mid_p.lerp(target_p, t)
		var pos: Vector2 = q0.lerp(q1, t)
		var a: float = sin(t * PI)
		stage_canvas.draw_circle(pos, float(sp["size"]), Color(1.0, 0.91, 0.62, a * 0.90))

	# 4. Child's luminous heart-light in center (becomes softer, smaller & weightless as warmth is given)
	var heart_pos: Vector2 = center + Vector2(0.0, -_ch3_ember_rise - _ch3_transfer * 18.0)
	var remaining: float = clampf(1.0 - _ch3_transfer * 0.78, 0.16, 1.0)
	var beat_scale: float = 1.0 + _ch3_heartbeat_pulse * 0.16 * remaining
	var base_r: float = lerpf(42.0, 14.0, _ch3_transfer) * beat_scale
	var fade_final: float = clampf(1.0 - _ch3_ember_rise * 0.012, 0.0, 1.0)

	_draw_soft_glow(heart_pos, base_r * 3.8, Color(1.0, 0.84, 0.48, 0.36 * remaining * fade_final))
	stage_canvas.draw_circle(heart_pos, base_r * 0.58, Color(1.0, 0.94, 0.74, 0.85 * remaining * fade_final))
	stage_canvas.draw_circle(heart_pos, base_r * 0.28, Color(1.0, 0.99, 0.92, 0.95 * fade_final))

	# Quiet circular progress arc around the heart while holding
	if not _ch3_final_sequence and _ch3_transfer > 0.01:
		stage_canvas.draw_arc(
			heart_pos,
			64.0,
			-PI * 0.5,
			-PI * 0.5 + TAU * _ch3_transfer,
			48,
			Color(1.0, 0.88, 0.56, 0.55),
			2.0,
			true
		)


func _draw_cupped_hand(palm_pos: Vector2, facing_dir: float, warmth_glow: float) -> void:
	# Stylized GRIS luminous cupped palm & wrist silhouette
	var line_col: Color = Color(0.66, 0.76, 0.92, 0.48).lerp(Color(1.0, 0.88, 0.58, 0.92), warmth_glow)
	var fill_col: Color = Color(0.10, 0.15, 0.26, 0.75).lerp(Color(0.32, 0.22, 0.16, 0.72), warmth_glow)

	var wrist: Vector2 = palm_pos + Vector2(-facing_dir * 125.0, 54.0)
	var heel: Vector2 = palm_pos + Vector2(-facing_dir * 42.0, 32.0)
	var tip_low: Vector2 = palm_pos + Vector2(facing_dir * 48.0, 18.0)
	var tip_mid: Vector2 = palm_pos + Vector2(facing_dir * 54.0, -8.0)
	var thumb_tip: Vector2 = palm_pos + Vector2(facing_dir * 18.0, -34.0)
	var wrist_top: Vector2 = palm_pos + Vector2(-facing_dir * 118.0, 16.0)

	var hand_poly: PackedVector2Array = PackedVector2Array([
		wrist, heel, tip_low, tip_mid, thumb_tip, wrist_top
	])
	stage_canvas.draw_colored_polygon(hand_poly, fill_col)
	stage_canvas.draw_polyline(
		PackedVector2Array([wrist_top, thumb_tip, tip_mid, tip_low, heel, wrist]),
		line_col,
		2.2,
		true
	)


func _draw_curved_thread(a: Vector2, b: Vector2, bend_y: float, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var mid: Vector2 = (a + b) * 0.5 + Vector2(0.0, bend_y + sin(_global_time * 3.0) * 6.0)
	for i: int in range(17):
		var t: float = float(i) / 16.0
		var p: Vector2 = a.lerp(mid, t).lerp(mid.lerp(b, t), t)
		pts.append(p)
	stage_canvas.draw_polyline(pts, col, 1.8, true)


func _draw_ch4_two_hands(vp: Vector2) -> void:
	var cy: float = vp.y * 0.54
	var cx: float = vp.x * 0.5
	var u: float = _ch4_unite_anim
	var ease_u: float = u * u * (3.0 - 2.0 * u)

	# Gap between the two trembling lines closes from 140px to 0px
	var half_gap: float = lerpf(88.0, 0.0, ease_u)
	var tremble: float = lerpf(5.5, 0.4, ease_u)

	var left_pts: PackedVector2Array = PackedVector2Array()
	var right_pts: PackedVector2Array = PackedVector2Array()
	var segs: int = 24
	for i: int in range(segs + 1):
		var t: float = float(i) / float(segs)
		var lx: float = lerpf(vp.x * 0.08, cx - half_gap, t)
		var ly: float = cy + sin(t * 9.0 + _global_time * 4.5) * tremble * t
		left_pts.append(Vector2(lx, ly))

		var rx: float = lerpf(vp.x * 0.92, cx + half_gap, t)
		var ry: float = cy + cos(t * 9.5 + _global_time * 4.1) * tremble * t
		right_pts.append(Vector2(rx, ry))

	var mother_col: Color = Color(0.95, 0.78, 0.72, 0.78).lerp(COLOR_GOLD, ease_u)
	var father_col: Color = Color(0.76, 0.84, 0.98, 0.78).lerp(COLOR_GOLD, ease_u)

	# Outer soft aura along both lines
	stage_canvas.draw_polyline(left_pts, Color(mother_col.r, mother_col.g, mother_col.b, 0.22), 10.0, true)
	stage_canvas.draw_polyline(right_pts, Color(father_col.r, father_col.g, father_col.b, 0.22), 10.0, true)
	# Crisp luminous threads
	stage_canvas.draw_polyline(left_pts, mother_col, 2.8, true)
	stage_canvas.draw_polyline(right_pts, father_col, 2.8, true)

	# Glowing fingertips at the ends of the two lines
	var left_tip: Vector2 = left_pts[left_pts.size() - 1]
	var right_tip: Vector2 = right_pts[right_pts.size() - 1]
	_draw_soft_glow(left_tip, 36.0 + 30.0 * ease_u, Color(mother_col.r, mother_col.g, mother_col.b, 0.45))
	_draw_soft_glow(right_tip, 36.0 + 30.0 * ease_u, Color(father_col.r, father_col.g, father_col.b, 0.45))
	stage_canvas.draw_circle(left_tip, 4.5, COLOR_IVORY)
	stage_canvas.draw_circle(right_tip, 4.5, COLOR_IVORY)

	# Central golden bloom & ascending vortex of petals once united
	if _ch4_united:
		_draw_soft_glow(Vector2(cx, cy), 190.0 * ease_u, Color(1.0, 0.87, 0.52, 0.48 * ease_u))
		for pt: Dictionary in _ch4_vortex_petals:
			var ang: float = float(pt["angle"])
			var rad: float = float(pt["radius"])
			var y_off: float = float(pt["y_off"])
			var sz: float = float(pt["size"])
			var a: float = float(pt["alpha"])
			var px: float = cx + cos(ang) * rad
			var py: float = cy - y_off + sin(ang) * rad * 0.25
			var p_col: Color = Color(1.0, 0.89, 0.56, a * 0.92)
			var dir: Vector2 = Vector2(cos(ang), sin(ang))
			var perp: Vector2 = Vector2(-dir.y, dir.x)
			var petal_poly: PackedVector2Array = PackedVector2Array([
				Vector2(px, py) + dir * sz * 1.4,
				Vector2(px, py) + perp * sz * 0.55,
				Vector2(px, py) - dir * sz * 1.1,
				Vector2(px, py) - perp * sz * 0.55,
			])
			stage_canvas.draw_colored_polygon(petal_poly, p_col)


func _draw_child_spark() -> void:
	# Graceful luminous ribbon trail
	var n: int = _spark_trail.size()
	for i: int in range(n):
		var t: float = float(i) / maxf(float(n), 1.0)
		stage_canvas.draw_circle(_spark_trail[i], 2.0 + t * 5.5, Color(1.0, 0.88, 0.54, t * 0.34))

	var pulse: float = 1.0 + 0.12 * sin(_global_time * 4.2)
	_draw_soft_glow(_spark_pos, 34.0 * pulse, Color(1.0, 0.85, 0.48, 0.38))
	stage_canvas.draw_circle(_spark_pos, 7.5 * pulse, Color(1.0, 0.93, 0.68, 0.92))
	stage_canvas.draw_circle(_spark_pos, 3.8, Color(1.0, 0.99, 0.94, 1.0))


func _draw_soft_glow(pos: Vector2, radius: float, col: Color) -> void:
	if radius <= 1.0 or col.a <= 0.005:
		return
	var steps: int = 4
	for i: int in range(steps):
		var frac: float = 1.0 - float(i) / float(steps)
		var r: float = radius * frac
		var a: float = col.a * (0.28 + 0.22 * (1.0 - frac))
		stage_canvas.draw_circle(pos, r, Color(col.r, col.g, col.b, a))


func _spawn_ripple(pos: Vector2, col: Color, max_r: float) -> void:
	_ripples.append({
		"pos": pos,
		"radius": 10.0,
		"max_radius": max_r,
		"color": col,
		"alpha": 0.9,
	})


func _update_ripples(dt: float) -> void:
	var i: int = _ripples.size() - 1
	while i >= 0:
		var r: Dictionary = _ripples[i]
		var max_r: float = float(r["max_radius"])
		var cur_r: float = float(r["radius"]) + max_r * dt * 1.15
		r["radius"] = cur_r
		r["alpha"] = clampf(1.0 - cur_r / maxf(max_r, 1.0), 0.0, 1.0)
		if float(r["alpha"]) <= 0.01:
			_ripples.remove_at(i)
		i -= 1


func _draw_ripples() -> void:
	for r: Dictionary in _ripples:
		var c: Color = r["color"] as Color
		var a: float = float(r["alpha"])
		stage_canvas.draw_arc(
			r["pos"] as Vector2,
			float(r["radius"]),
			0.0,
			TAU,
			48,
			Color(c.r, c.g, c.b, c.a * a),
			2.4 * a + 0.6,
			true
		)


# =============================================================================
# SHARED HELPERS, SHADER MORPHING, INPUT & PAUSE MENU
# =============================================================================

func _update_spark_movement(dt: float, vp: Vector2) -> void:
	var kb_dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		kb_dir.x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		kb_dir.x += 1.0
	if Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		kb_dir.y -= 1.0
	if Input.is_action_pressed("move_back") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		kb_dir.y += 1.0

	if kb_dir.length_squared() > 0.01:
		_using_keyboard_cursor = true
		var move_v: Vector2 = kb_dir.normalized() * 340.0 * dt
		_spark_target = Vector2(
			clampf(_spark_target.x + move_v.x, 24.0, vp.x - 24.0),
			clampf(_spark_target.y + move_v.y, 24.0, vp.y - 24.0)
		)

	_spark_pos = _spark_pos.lerp(_spark_target, minf(1.0, dt * 14.0))
	_spark_trail.append(_spark_pos)
	if _spark_trail.size() > 14:
		_spark_trail.remove_at(0)


func _set_mood_target(
	sky_top: Color,
	sky_mid: Color,
	sky_bottom: Color,
	ray_col: Color,
	warmth_val: float,
	sun_p: Vector2,
	ray_str: float,
	vig_str: float,
	bokeh_str: float
) -> void:
	_tgt_sky_top = sky_top
	_tgt_sky_mid = sky_mid
	_tgt_sky_bottom = sky_bottom
	_tgt_ray_color = ray_col
	_tgt_warmth = warmth_val
	_tgt_sun_pos = sun_p
	_tgt_ray_strength = ray_str
	_tgt_vignette = vig_str
	_tgt_bokeh = bokeh_str


func _update_shader_params(dt: float) -> void:
	if _bg_mat == null:
		return
	var k: float = minf(1.0, dt * 1.45)
	_cur_sky_top = _cur_sky_top.lerp(_tgt_sky_top, k)
	_cur_sky_mid = _cur_sky_mid.lerp(_tgt_sky_mid, k)
	_cur_sky_bottom = _cur_sky_bottom.lerp(_tgt_sky_bottom, k)
	_cur_ray_color = _cur_ray_color.lerp(_tgt_ray_color, k)
	_cur_warmth = lerpf(_cur_warmth, _tgt_warmth, k)
	_cur_sun_pos = _cur_sun_pos.lerp(_tgt_sun_pos, k)
	_cur_ray_strength = lerpf(_cur_ray_strength, _tgt_ray_strength, k)
	_cur_vignette = lerpf(_cur_vignette, _tgt_vignette, k)
	_cur_bokeh = lerpf(_cur_bokeh, _tgt_bokeh, k)
	_apply_shader_immediate()


func _apply_shader_immediate() -> void:
	if _bg_mat == null:
		return
	_bg_mat.set_shader_parameter("sky_top", _cur_sky_top)
	_bg_mat.set_shader_parameter("sky_mid", _cur_sky_mid)
	_bg_mat.set_shader_parameter("sky_bottom", _cur_sky_bottom)
	_bg_mat.set_shader_parameter("ray_color", _cur_ray_color)
	_bg_mat.set_shader_parameter("warmth", _cur_warmth)
	_bg_mat.set_shader_parameter("sun_pos", _cur_sun_pos)
	_bg_mat.set_shader_parameter("ray_strength", _cur_ray_strength)
	_bg_mat.set_shader_parameter("vignette_strength", _cur_vignette)
	_bg_mat.set_shader_parameter("bokeh_strength", _cur_bokeh)


func _set_header(roman_text: String, title_text: String) -> void:
	chapter_roman_label.text = roman_text
	chapter_title_label.text = title_text


func _set_controls_hint(hint_text: String) -> void:
	controls_hint_label.text = hint_text


func _set_narration(main_line: String, sub_line: String) -> void:
	if _narration_tween != null and _narration_tween.is_valid():
		_narration_tween.kill()

	var is_empty: bool = main_line.is_empty() and sub_line.is_empty()
	_narration_tween = create_tween()
	_narration_tween.tween_property(narration_panel, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	_narration_tween.tween_callback(func() -> void:
		poetic_label.text = main_line
		sub_poetic_label.text = sub_line
		sub_poetic_label.visible = not sub_line.is_empty()
		narration_panel.visible = not is_empty
	)
	if not is_empty:
		_narration_tween.tween_property(narration_panel, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)


func _fade_to_veil(duration: float) -> void:
	_is_transitioning = true
	var tw: Tween = create_tween()
	tw.tween_property(transition_veil, "modulate:a", 1.0, maxf(0.05, duration)).set_trans(Tween.TRANS_SINE)
	await tw.finished


func _fade_in_from_veil(duration: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(transition_veil, "modulate:a", 0.0, maxf(0.05, duration)).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_is_transitioning = false


func _init_snowflakes(vp: Vector2) -> void:
	_snowflakes.clear()
	for _i: int in range(42):
		_snowflakes.append({
			"pos": Vector2(vp.x * (0.34 + randf() * 0.32), vp.y * (0.14 + randf() * 0.56)),
			"speed": 18.0 + randf() * 26.0,
			"size": 1.6 + randf() * 2.2,
			"phase": randf() * TAU,
		})


func _init_petals(vp: Vector2) -> void:
	_petals.clear()
	for _i: int in range(28):
		_petals.append({
			"pos": Vector2(randf() * vp.x, randf() * vp.y),
			"speed": 22.0 + randf() * 32.0,
			"size": 2.4 + randf() * 2.8,
			"phase": randf() * TAU,
			"rot": randf() * TAU,
			"rot_spd": 0.8 + randf() * 1.2,
		})


func _init_motes(vp: Vector2) -> void:
	_motes.clear()
	for _i: int in range(32):
		_motes.append({
			"pos": Vector2(randf() * vp.x, randf() * vp.y),
			"speed": 6.0 + randf() * 12.0,
			"size": 1.4 + randf() * 2.2,
			"phase": randf() * TAU,
		})


func _get_vp_size() -> Vector2:
	var s: Vector2 = size
	if s.x < 10.0 or s.y < 10.0:
		return Vector2(1280.0, 720.0)
	return s


func _toggle_pause() -> void:
	_is_paused = not _is_paused
	if _is_paused:
		_handle_primary_release()
	pause_overlay.visible = _is_paused
	_update_mute_button_label()
	if audio != null and audio.has_method("play_ui_click"):
		audio.call("play_ui_click")


func _connect_pause_buttons() -> void:
	btn_resume.pressed.connect(func() -> void:
		_toggle_pause()
	)
	btn_mute.pressed.connect(_on_toggle_mute_pressed)
	btn_main_menu.pressed.connect(_on_return_main_menu_pressed)
	_update_mute_button_label()


func _on_toggle_mute_pressed() -> void:
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	var current_muted: bool = false
	if save_mgr != null:
		var m_val: Variant = save_mgr.get("audio_muted")
		if m_val is bool:
			current_muted = m_val as bool
		if save_mgr.has_method("set_audio_muted"):
			save_mgr.call("set_audio_muted", not current_muted)
	elif AudioServer.bus_count > 0:
		current_muted = AudioServer.is_bus_mute(0)
		AudioServer.set_bus_mute(0, not current_muted)
	_update_mute_button_label()


func _update_mute_button_label() -> void:
	var is_muted: bool = false
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr != null:
		var m_val: Variant = save_mgr.get("audio_muted")
		if m_val is bool:
			is_muted = m_val as bool
	elif AudioServer.bus_count > 0:
		is_muted = AudioServer.is_bus_mute(0)
	btn_mute.text = "Звук: Выкл" if is_muted else "Звук: Вкл"


func _on_return_main_menu_pressed() -> void:
	_is_paused = false
	pause_overlay.visible = false
	var flow_mgr: Node = get_node_or_null("/root/SceneFlowManager")
	if flow_mgr != null:
		_set_object_property_safe(flow_mgr, "pending_world_mode", "")
		if flow_mgr.has_method("transition_to_scene"):
			flow_mgr.call("transition_to_scene", "res://scenes/world_3d.tscn", true)
			return
	get_tree().change_scene_to_file("res://scenes/world_3d.tscn")


func _style_ui_elements() -> void:
	# Soft dark translucent scrim behind poetic narration for guaranteed legibility
	var narr_box: StyleBoxFlat = StyleBoxFlat.new()
	narr_box.bg_color = Color(0.025, 0.055, 0.125, 0.56)
	narr_box.border_color = Color(0.964706, 0.827451, 0.419608, 0.28)
	narr_box.border_width_top = 1
	narr_box.border_width_bottom = 1
	narr_box.set_corner_radius_all(6)
	narration_panel.add_theme_stylebox_override("panel", narr_box)

	# Art Deco pause card
	var p_box: StyleBoxFlat = StyleBoxFlat.new()
	p_box.bg_color = COLOR_INDIGO_CARD
	p_box.border_color = COLOR_GOLD
	p_box.set_border_width_all(2)
	p_box.set_corner_radius_all(4)
	p_box.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	p_box.shadow_size = 24
	pause_card.add_theme_stylebox_override("panel", p_box)

	_apply_art_deco_button_theme(btn_resume)
	_apply_art_deco_button_theme(btn_mute)
	_apply_art_deco_button_theme(btn_main_menu)


func _create_art_deco_button(label_text: String, min_width: float) -> Button:
	var btn: Button = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(min_width, 44.0)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_art_deco_button_theme(btn)
	return btn


func _apply_art_deco_button_theme(btn: Button) -> void:
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", COLOR_IVORY)
	btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
	btn.add_theme_color_override("font_pressed_color", COLOR_INDIGO)
	btn.add_theme_color_override("font_focus_color", COLOR_GOLD)

	var normal_s: StyleBoxFlat = StyleBoxFlat.new()
	normal_s.bg_color = Color(0.047, 0.110, 0.239, 0.88)
	normal_s.border_color = COLOR_GOLD_SOFT
	normal_s.set_border_width_all(1)
	normal_s.set_corner_radius_all(3)
	normal_s.content_margin_left = 20.0
	normal_s.content_margin_right = 20.0
	normal_s.content_margin_top = 10.0
	normal_s.content_margin_bottom = 10.0

	var hover_s: StyleBoxFlat = normal_s.duplicate() as StyleBoxFlat
	hover_s.bg_color = Color(0.10, 0.18, 0.34, 0.96)
	hover_s.border_color = COLOR_GOLD
	hover_s.set_border_width_all(2)

	var pressed_s: StyleBoxFlat = normal_s.duplicate() as StyleBoxFlat
	pressed_s.bg_color = COLOR_GOLD
	pressed_s.border_color = COLOR_IVORY
	pressed_s.set_border_width_all(2)

	btn.add_theme_stylebox_override("normal", normal_s)
	btn.add_theme_stylebox_override("hover", hover_s)
	btn.add_theme_stylebox_override("pressed", pressed_s)
	btn.add_theme_stylebox_override("focus", hover_s.duplicate() as StyleBoxFlat)


func _set_object_property_safe(obj: Object, prop_name: String, val: Variant) -> void:
	if obj == null:
		return
	for prop_info: Dictionary in obj.get_property_list():
		if str(prop_info.get("name", "")) == prop_name:
			obj.set(prop_name, val)
			return
