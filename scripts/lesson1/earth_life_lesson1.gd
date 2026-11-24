extends Control

## Interactive playable vignette for Lesson 1 Part 1: "Было всё, кроме времени".
## Aesthetic: Pixar & Disney (Soul, Up, Coco, Tangled, Inside Out) — 1280x720 canvas_items, 60 FPS.
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
	_update_ambient_motes(dt, vp_size)

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


func _update_ch3_eighth_winter(dt: float, _vp: Vector2) -> void:
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

	# Spawn ascending Tangled-style golden lanterns & petal vortex from joined hands
	_ch4_vortex_timer -= dt
	if _ch4_vortex_timer <= 0.0 and _ch4_vortex_petals.size() < 110:
		_ch4_vortex_timer = 0.028
		var is_lantern: bool = randf() < 0.30
		_ch4_vortex_petals.append({
			"angle": randf() * TAU,
			"radius": (10.0 + randf() * 34.0) if is_lantern else (6.0 + randf() * 24.0),
			"y_off": 0.0,
			"rise_spd": (62.0 + randf() * 58.0) if is_lantern else (98.0 + randf() * 110.0),
			"spin_spd": ((0.55 + randf() * 0.65) if is_lantern else (1.5 + randf() * 1.8)) * (1.0 if randf() < 0.5 else -1.0),
			"size": (8.5 + randf() * 6.5) if is_lantern else (4.2 + randf() * 6.0),
			"alpha": 0.96,
			"is_lantern": is_lantern,
			"bob_phase": randf() * TAU,
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
# CUSTOM PIXAR / DISNEY CINEMATIC _draw() — SOUL · UP · COCO · TANGLED
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

	_draw_ambient_golden_dust(vp)
	_draw_ripples()

	# Draw the warm guiding child spark in interactive cursor chapters
	if _stage == STAGE_CH1_WINTER or _stage == STAGE_CH2_BUBBLES or _stage == STAGE_CH2_WALLPAPER:
		_draw_child_spark()

	_draw_cinema_letterbox(vp)


func _update_ambient_motes(dt: float, vp: Vector2) -> void:
	for m: Dictionary in _motes:
		var mp: Vector2 = m["pos"] as Vector2
		var spd: float = float(m["speed"])
		var ph: float = float(m["phase"])
		mp.y -= spd * dt
		mp.x += sin(_global_time * 0.55 + ph) * 9.5 * dt
		if mp.y < -12.0:
			mp = Vector2(randf() * vp.x, vp.y + 12.0)
		elif mp.x < -12.0:
			mp.x = vp.x + 12.0
		elif mp.x > vp.x + 12.0:
			mp.x = -12.0
		m["pos"] = mp


func _draw_ambient_golden_dust(vp: Vector2) -> void:
	var dust_col: Color = Color(1.0, 0.90, 0.62, 0.34)
	match _stage:
		STAGE_CH1_WINTER:
			dust_col = Color(0.76, 0.88, 1.0, 0.22).lerp(Color(1.0, 0.86, 0.48, 0.44), _ch1_warmth_anim)
		STAGE_CH2_BUBBLES:
			dust_col = Color(1.0, 0.96, 0.76, 0.42)
		STAGE_CH2_WALLPAPER:
			dust_col = Color(1.0, 0.89, 0.56, 0.44)
		STAGE_CH2_SEA:
			dust_col = Color(1.0, 0.84, 0.56, 0.38)
		STAGE_CH3_EIGHTH_WINTER:
			dust_col = Color(0.84, 0.91, 1.0, 0.30).lerp(Color(1.0, 0.88, 0.58, 0.38), _ch3_transfer * 0.65)
		STAGE_CH4_TWO_HANDS, STAGE_FINISHED:
			dust_col = Color(0.80, 0.84, 1.0, 0.20).lerp(Color(1.0, 0.90, 0.56, 0.48), _ch4_unite_anim)

	for m: Dictionary in _motes:
		var mp: Vector2 = m["pos"] as Vector2
		if mp.y < 24.0 or mp.y > vp.y - 24.0:
			continue
		var ph: float = float(m["phase"])
		var sz: float = float(m["size"])
		var twinkle: float = 0.45 + 0.55 * sin(_global_time * 1.9 + ph)
		var a: float = dust_col.a * twinkle
		stage_canvas.draw_circle(mp, sz * 2.1, Color(dust_col.r, dust_col.g, dust_col.b, a * 0.24))
		stage_canvas.draw_circle(mp, sz * 0.95, Color(1.0, 0.98, 0.90, a))


func _draw_cinema_letterbox(vp: Vector2) -> void:
	# Subtle Pixar/Disney widescreen cinema bars (drawn below UILayer, never blocks UI)
	var bar_h: float = 24.0
	var bar_col: Color = Color(0.016, 0.022, 0.055, 0.84)
	var fade_col: Color = Color(0.016, 0.022, 0.055, 0.28)
	var trim_col: Color = Color(0.98, 0.85, 0.52, 0.16)

	stage_canvas.draw_rect(Rect2(0.0, 0.0, vp.x, bar_h), bar_col, true)
	stage_canvas.draw_rect(Rect2(0.0, bar_h, vp.x, 7.0), fade_col, true)
	stage_canvas.draw_line(Vector2(0.0, bar_h), Vector2(vp.x, bar_h), trim_col, 1.0, true)

	stage_canvas.draw_rect(Rect2(0.0, vp.y - bar_h, vp.x, bar_h), bar_col, true)
	stage_canvas.draw_rect(Rect2(0.0, vp.y - bar_h - 7.0, vp.x, 7.0), fade_col, true)
	stage_canvas.draw_line(Vector2(0.0, vp.y - bar_h), Vector2(vp.x, vp.y - bar_h), trim_col, 1.0, true)


func _draw_ellipse_poly(center: Vector2, rx: float, ry: float, col: Color, segs: int = 24, rot: float = 0.0) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var c_rot: float = cos(rot)
	var s_rot: float = sin(rot)
	for i: int in range(segs):
		var a: float = float(i) / float(segs) * TAU
		var lx: float = cos(a) * rx
		var ly: float = sin(a) * ry
		var wx: float = center.x + lx * c_rot - ly * s_rot
		var wy: float = center.y + lx * s_rot + ly * c_rot
		pts.append(Vector2(wx, wy))
	stage_canvas.draw_colored_polygon(pts, col)


# =============================================================================
# CHAPTER 1 — «ЗИМА В ДОМЕ» (PIXAR "UP" COZY INTERIOR)
# =============================================================================

func _draw_ch1_winter(vp: Vector2) -> void:
	var w: float = _ch1_warmth_anim
	var cx: float = vp.x * 0.5

	# 1. Warm interior wallpaper wash & wainscoting
	var wall_tint: Color = Color(0.06, 0.09, 0.16, 0.42).lerp(Color(0.28, 0.17, 0.12, 0.36), w)
	stage_canvas.draw_rect(Rect2(0.0, 0.0, vp.x, vp.y * 0.84), wall_tint, true)
	var stripe_col: Color = Color(0.20, 0.28, 0.42, 0.06).lerp(Color(0.96, 0.74, 0.44, 0.08), w)
	var sx: float = 0.0
	while sx < vp.x:
		stage_canvas.draw_rect(Rect2(sx, 0.0, 22.0, vp.y * 0.84), stripe_col, true)
		sx += 68.0

	# Wooden wainscoting & warm floor plane
	var wood_wall: Color = Color(0.07, 0.09, 0.15, 0.90).lerp(Color(0.22, 0.13, 0.09, 0.92), w)
	stage_canvas.draw_rect(Rect2(0.0, vp.y * 0.74, vp.x, vp.y * 0.12), wood_wall, true)
	stage_canvas.draw_line(
		Vector2(0.0, vp.y * 0.74),
		Vector2(vp.x, vp.y * 0.74),
		Color(0.24, 0.31, 0.44, 0.45).lerp(Color(0.84, 0.62, 0.38, 0.55), w),
		2.0,
		true
	)

	# 2. Cozy wooden bookshelf in dim left corner (Up-inspired home detail)
	_draw_ch1_bookshelf(vp, w)

	# 3. Sideboard & framed family silhouette in right corner
	_draw_ch1_sideboard(vp, w)

	# 4. Grand arched winter window with frosted curls & snowy pine silhouettes outside
	var win_w: float = vp.x * 0.29
	var win_h: float = vp.y * 0.54
	var win_x: float = cx - win_w * 0.5
	var win_y: float = vp.y * 0.13
	var arch_r: float = win_w * 0.5
	var arch_cy: float = win_y + arch_r * 0.42

	var win_glass_top: Color = Color(0.09, 0.16, 0.30, 0.88).lerp(Color(0.18, 0.20, 0.32, 0.82), w)
	var win_glass_bot: Color = Color(0.18, 0.28, 0.44, 0.78).lerp(Color(0.32, 0.26, 0.32, 0.72), w)
	stage_canvas.draw_rect(Rect2(win_x, arch_cy, win_w, win_y + win_h - arch_cy), win_glass_top, true)
	stage_canvas.draw_rect(Rect2(win_x, win_y + win_h * 0.56, win_w, win_h * 0.44), win_glass_bot, true)
	stage_canvas.draw_circle(Vector2(cx, arch_cy), arch_r, win_glass_top)

	# Distant snowy hill & pine trees outside the window
	var pine_col: Color = Color(0.07, 0.12, 0.22, 0.85).lerp(Color(0.14, 0.15, 0.24, 0.75), w)
	var sill_y: float = win_y + win_h
	for p_i: int in range(5):
		var px: float = win_x + win_w * (0.14 + float(p_i) * 0.18)
		var ph: float = 34.0 + float((p_i * 19) % 24)
		var pine: PackedVector2Array = PackedVector2Array([
			Vector2(px, sill_y - ph),
			Vector2(px - 18.0, sill_y),
			Vector2(px + 18.0, sill_y),
		])
		stage_canvas.draw_colored_polygon(pine, pine_col)

	# Softly drifting snowflakes inside window glass
	for flake: Dictionary in _snowflakes:
		var fp: Vector2 = flake["pos"] as Vector2
		if fp.x > win_x + 10.0 and fp.x < win_x + win_w - 10.0 and fp.y > win_y + 14.0 and fp.y < sill_y - 6.0:
			var snow_a: float = lerpf(0.72, 0.28, w)
			stage_canvas.draw_circle(fp, float(flake["size"]), Color(0.90, 0.95, 1.0, snow_a))

	# Delicate frost curls on the window corners (gently melt away as warmth grows)
	var frost_a: float = clampf(1.0 - w * 1.15, 0.0, 1.0)
	if frost_a > 0.02:
		var frost_c: Color = Color(0.78, 0.90, 1.0, 0.42 * frost_a)
		stage_canvas.draw_arc(Vector2(win_x + 16.0, sill_y - 16.0), 28.0, -PI * 0.5, 0.0, 14, frost_c, 2.0, true)
		stage_canvas.draw_arc(Vector2(win_x + 28.0, sill_y - 26.0), 16.0, -PI * 0.65, 0.2, 12, frost_c, 1.5, true)
		stage_canvas.draw_arc(Vector2(win_x + win_w - 16.0, sill_y - 16.0), 28.0, PI, PI * 1.5, 14, frost_c, 2.0, true)
		stage_canvas.draw_arc(Vector2(win_x + win_w - 28.0, sill_y - 26.0), 16.0, PI - 0.2, PI * 1.65, 12, frost_c, 1.5, true)
		stage_canvas.draw_arc(Vector2(cx, arch_cy), arch_r - 10.0, PI + 0.15, TAU - 0.15, 28, Color(0.80, 0.92, 1.0, 0.25 * frost_a), 2.5, true)

	# Carved wooden window mullions & warm sill
	var frame_col: Color = Color(0.22, 0.30, 0.44, 0.92).lerp(Color(0.58, 0.38, 0.24, 0.95), w)
	var frame_hi: Color = Color(0.46, 0.60, 0.80, 0.48).lerp(Color(1.0, 0.82, 0.52, 0.65), w)
	stage_canvas.draw_line(Vector2(cx, win_y - 2.0), Vector2(cx, sill_y), frame_col, 4.0, true)
	stage_canvas.draw_line(Vector2(win_x, win_y + win_h * 0.46), Vector2(win_x + win_w, win_y + win_h * 0.46), frame_col, 4.0, true)
	stage_canvas.draw_arc(Vector2(cx, arch_cy), arch_r, PI, TAU, 36, frame_col, 6.0, true)
	stage_canvas.draw_line(Vector2(win_x, arch_cy), Vector2(win_x, sill_y), frame_col, 6.0, true)
	stage_canvas.draw_line(Vector2(win_x + win_w, arch_cy), Vector2(win_x + win_w, sill_y), frame_col, 6.0, true)
	stage_canvas.draw_rect(Rect2(win_x - 14.0, sill_y - 2.0, win_w + 28.0, 10.0), frame_col, true)
	stage_canvas.draw_line(Vector2(win_x - 14.0, sill_y - 2.0), Vector2(win_x + win_w + 14.0, sill_y - 2.0), frame_hi, 1.8, true)

	# 5. Soft draped curtains flanking the arched window
	var curt_col: Color = Color(0.11, 0.16, 0.26, 0.92).lerp(Color(0.44, 0.24, 0.20, 0.94), w)
	var curt_fold: Color = Color(0.18, 0.25, 0.38, 0.65).lerp(Color(0.68, 0.42, 0.30, 0.68), w)
	var sway_c: float = sin(_global_time * 0.8) * 3.0
	var left_curtain: PackedVector2Array = PackedVector2Array([
		Vector2(win_x - 36.0, win_y + 18.0),
		Vector2(win_x + 26.0, win_y + 18.0),
		Vector2(win_x + 4.0 + sway_c, win_y + win_h * 0.56),
		Vector2(win_x + 20.0 + sway_c * 0.6, sill_y + 42.0),
		Vector2(win_x - 42.0, sill_y + 42.0),
	])
	stage_canvas.draw_colored_polygon(left_curtain, curt_col)
	stage_canvas.draw_line(Vector2(win_x + 8.0, win_y + 22.0), Vector2(win_x - 4.0 + sway_c, win_y + win_h * 0.56), curt_fold, 3.0, true)

	var right_curtain: PackedVector2Array = PackedVector2Array([
		Vector2(win_x + win_w - 26.0, win_y + 18.0),
		Vector2(win_x + win_w + 36.0, win_y + 18.0),
		Vector2(win_x + win_w + 42.0, sill_y + 42.0),
		Vector2(win_x + win_w - 20.0 - sway_c * 0.6, sill_y + 42.0),
		Vector2(win_x + win_w - 4.0 - sway_c, win_y + win_h * 0.56),
	])
	stage_canvas.draw_colored_polygon(right_curtain, curt_col)
	stage_canvas.draw_line(Vector2(win_x + win_w - 8.0, win_y + 22.0), Vector2(win_x + win_w + 4.0 - sway_c, win_y + win_h * 0.56), curt_fold, 3.0, true)

	# Curtain rod
	stage_canvas.draw_line(Vector2(win_x - 48.0, win_y + 16.0), Vector2(win_x + win_w + 48.0, win_y + 16.0), frame_col, 4.0, true)
	stage_canvas.draw_circle(Vector2(win_x - 48.0, win_y + 16.0), 5.0, frame_hi)
	stage_canvas.draw_circle(Vector2(win_x + win_w + 48.0, win_y + 16.0), 5.0, frame_hi)

	# 6. Overhead hanging lampshade that blooms into a honey cone of light as warmth grows
	var lamp_y: float = vp.y * 0.29
	var lamp_sway: float = sin(_global_time * 0.9) * 2.5
	var lamp_c: Vector2 = Vector2(cx + lamp_sway, lamp_y)
	stage_canvas.draw_line(Vector2(cx, 24.0), lamp_c + Vector2(0.0, -18.0), Color(0.14, 0.16, 0.24, 0.85), 2.5, true)

	# Honey volumetric light cone descending onto the table & parents
	if w > 0.01:
		var cone_outer: PackedVector2Array = PackedVector2Array([
			lamp_c + Vector2(-34.0, 12.0),
			lamp_c + Vector2(34.0, 12.0),
			Vector2(cx + vp.x * 0.30, vp.y * 0.86),
			Vector2(cx - vp.x * 0.30, vp.y * 0.86),
		])
		stage_canvas.draw_colored_polygon(cone_outer, Color(1.0, 0.80, 0.40, 0.11 * w))
		var cone_inner: PackedVector2Array = PackedVector2Array([
			lamp_c + Vector2(-22.0, 12.0),
			lamp_c + Vector2(22.0, 12.0),
			Vector2(cx + vp.x * 0.18, vp.y * 0.78),
			Vector2(cx - vp.x * 0.18, vp.y * 0.78),
		])
		stage_canvas.draw_colored_polygon(cone_inner, Color(1.0, 0.88, 0.54, 0.14 * w))
		_draw_soft_glow(lamp_c + Vector2(0.0, 14.0), 140.0 * w, Color(1.0, 0.82, 0.44, 0.38 * w))

	# Lampshade dome
	var shade_col: Color = Color(0.18, 0.23, 0.34, 0.95).lerp(Color(0.92, 0.66, 0.32, 0.96), w)
	var shade_rim: Color = Color(0.45, 0.56, 0.72, 0.55).lerp(Color(1.0, 0.94, 0.72, 0.95), w)
	var shade_poly: PackedVector2Array = PackedVector2Array([
		lamp_c + Vector2(-18.0, -18.0),
		lamp_c + Vector2(18.0, -18.0),
		lamp_c + Vector2(44.0, 14.0),
		lamp_c + Vector2(-44.0, 14.0),
	])
	stage_canvas.draw_colored_polygon(shade_poly, shade_col)
	stage_canvas.draw_line(lamp_c + Vector2(-44.0, 14.0), lamp_c + Vector2(44.0, 14.0), shade_rim, 2.5, true)
	# Warm glowing bulb tucked under shade
	var bulb_col: Color = Color(0.45, 0.54, 0.68, 0.5).lerp(Color(1.0, 0.97, 0.84, 1.0), w)
	stage_canvas.draw_circle(lamp_c + Vector2(0.0, 14.0), 7.5 + w * 3.0, bulb_col)

	# Hearth glow blooming over the center of the table
	if w > 0.01:
		_draw_soft_glow(Vector2(cx, vp.y * 0.63), 255.0 * w, Color(1.0, 0.78, 0.38, 0.28 * w))

	# 7. Pixar-proportioned Mother (left) and Father (right) turning & leaning toward the child's light
	var lean_in: float = w * 50.0
	var mother_base: Vector2 = Vector2(vp.x * 0.31 + lean_in, vp.y * 0.72)
	_draw_pixar_parent_ch1(mother_base, true, w)

	var father_base: Vector2 = Vector2(vp.x * 0.69 - lean_in, vp.y * 0.72)
	_draw_pixar_parent_ch1(father_base, false, w)

	# 8. Dining table, two cozy mugs with rising steam, & warm floor
	var table_y: float = vp.y * 0.70
	var table_w: float = vp.x * 0.45
	var table_col: Color = Color(0.08, 0.11, 0.18, 0.96).lerp(Color(0.28, 0.16, 0.10, 0.98), w)
	var table_top_hi: Color = Color(0.42, 0.56, 0.76, 0.42).lerp(Color(1.0, 0.84, 0.50, 0.85), w)

	# Two mugs on the table (cream for mother, indigo-sage for father)
	_draw_ch1_mug(Vector2(cx - table_w * 0.22, table_y - 1.0), Color(0.62, 0.68, 0.78, 0.88).lerp(Color(0.96, 0.86, 0.74, 0.96), w), true, w)
	_draw_ch1_mug(Vector2(cx + table_w * 0.22, table_y - 1.0), Color(0.28, 0.38, 0.52, 0.88).lerp(Color(0.36, 0.52, 0.56, 0.96), w), false, w)

	# Table top & legs
	stage_canvas.draw_rect(Rect2(cx - table_w * 0.5, table_y, table_w, 12.0), table_col, true)
	stage_canvas.draw_line(Vector2(cx - table_w * 0.5, table_y), Vector2(cx + table_w * 0.5, table_y), table_top_hi, 2.2, true)
	stage_canvas.draw_rect(Rect2(cx - table_w * 0.42, table_y + 12.0, 10.0, vp.y * 0.20), table_col, true)
	stage_canvas.draw_rect(Rect2(cx + table_w * 0.42 - 10.0, table_y + 12.0, 10.0, vp.y * 0.20), table_col, true)

	# Warm floor with amber pool reflection
	var floor_col: Color = Color(0.04, 0.06, 0.11, 0.96).lerp(Color(0.14, 0.08, 0.06, 0.96), w)
	stage_canvas.draw_rect(Rect2(0.0, vp.y * 0.86, vp.x, vp.y * 0.16), floor_col, true)
	if w > 0.05:
		_draw_ellipse_poly(Vector2(cx, vp.y * 0.90), table_w * 0.48, 22.0, Color(1.0, 0.76, 0.36, 0.14 * w), 28)

	# 9. Three interactive frost stars -> blooming golden hearth embers
	for pt: Dictionary in _cold_points:
		var p: Vector2 = pt["pos"] as Vector2
		var g: float = float(pt["glow"])
		var pulse: float = 0.5 + 0.5 * sin(_global_time * 2.6 + p.x * 0.01)
		if g < 0.95:
			var ice_a: float = (1.0 - g) * (0.50 + 0.38 * pulse)
			var ice_col: Color = Color(0.68, 0.88, 1.0, ice_a)
			_draw_soft_glow(p, 38.0 + pulse * 10.0, Color(0.55, 0.82, 1.0, 0.18 * (1.0 - g)))
			stage_canvas.draw_arc(p, 24.0 + pulse * 9.0, 0.0, TAU, 32, ice_col, 1.8, true)
			stage_canvas.draw_arc(p, 13.0, 0.0, TAU, 24, ice_col, 1.3, true)
			for a_i: int in range(6):
				var ang: float = float(a_i) * PI / 3.0 + _global_time * 0.28
				var dir: Vector2 = Vector2(cos(ang), sin(ang))
				stage_canvas.draw_line(p - dir * 9.0, p + dir * 9.0, ice_col, 1.4, true)
		if g > 0.02:
			_draw_soft_glow(p, 64.0 * g, Color(1.0, 0.82, 0.42, 0.52 * g))
			stage_canvas.draw_circle(p, 6.2 * g, COLOR_IVORY)


func _draw_ch1_bookshelf(vp: Vector2, w: float) -> void:
	var bx: float = vp.x * 0.06
	var by: float = vp.y * 0.28
	var bw: float = vp.x * 0.13
	var bh: float = vp.y * 0.46
	var wood: Color = Color(0.06, 0.09, 0.15, 0.92).lerp(Color(0.20, 0.12, 0.09, 0.94), w)
	var rim: Color = Color(0.32, 0.44, 0.62, 0.22).lerp(Color(1.0, 0.78, 0.44, 0.48), w)
	stage_canvas.draw_rect(Rect2(bx, by, bw, bh), wood, true)
	stage_canvas.draw_line(Vector2(bx + bw, by), Vector2(bx + bw, by + bh), rim, 2.0, true)

	# Three shelves with softly colored books
	var book_palette: Array[Color] = [
		Color(0.45, 0.22, 0.22, 0.85),
		Color(0.24, 0.36, 0.46, 0.85),
		Color(0.56, 0.42, 0.24, 0.85),
		Color(0.30, 0.42, 0.34, 0.85),
	]
	for sh_i: int in range(3):
		var sy: float = by + bh * (0.28 + float(sh_i) * 0.26)
		stage_canvas.draw_rect(Rect2(bx + 6.0, sy, bw - 12.0, 6.0), wood.lightened(0.08), true)
		var cur_x: float = bx + 12.0
		for b_i: int in range(6):
			var bk_w: float = 10.0 + float((sh_i * 7 + b_i * 5) % 8)
			var bk_h: float = 26.0 + float((sh_i * 11 + b_i * 9) % 18)
			if cur_x + bk_w > bx + bw - 12.0:
				break
			var base_bk: Color = book_palette[(sh_i + b_i) % book_palette.size()]
			var bk_col: Color = Color(0.09, 0.13, 0.22, 0.90).lerp(base_bk, 0.28 + w * 0.72)
			stage_canvas.draw_rect(Rect2(cur_x, sy - bk_h, bk_w, bk_h), bk_col, true)
			cur_x += bk_w + 3.0


func _draw_ch1_sideboard(vp: Vector2, w: float) -> void:
	var sx: float = vp.x * 0.82
	var sy: float = vp.y * 0.56
	var sw: float = vp.x * 0.12
	var sh: float = vp.y * 0.28
	var wood: Color = Color(0.06, 0.09, 0.15, 0.90).lerp(Color(0.21, 0.12, 0.09, 0.92), w)
	var rim: Color = Color(0.32, 0.44, 0.62, 0.22).lerp(Color(1.0, 0.78, 0.44, 0.46), w)
	stage_canvas.draw_rect(Rect2(sx, sy, sw, sh), wood, true)
	stage_canvas.draw_line(Vector2(sx, sy), Vector2(sx + sw, sy), rim, 2.0, true)
	# Small framed picture & ceramic vase on top
	var frame_x: float = sx + sw * 0.22
	stage_canvas.draw_rect(Rect2(frame_x, sy - 34.0, 26.0, 32.0), wood.lightened(0.14), true)
	stage_canvas.draw_rect(Rect2(frame_x + 3.0, sy - 31.0, 20.0, 26.0), Color(0.22, 0.28, 0.40, 0.7).lerp(Color(0.92, 0.76, 0.52, 0.72), w), true)
	_draw_ellipse_poly(Vector2(sx + sw * 0.70, sy - 14.0), 10.0, 14.0, Color(0.18, 0.26, 0.38, 0.85).lerp(Color(0.76, 0.48, 0.36, 0.88), w), 16)


func _draw_ch1_mug(base_pos: Vector2, mug_col: Color, handle_left: bool, w: float) -> void:
	# Saucer
	_draw_ellipse_poly(base_pos, 18.0, 4.0, mug_col.darkened(0.22), 18)
	# Mug body
	stage_canvas.draw_rect(Rect2(base_pos.x - 11.0, base_pos.y - 20.0, 22.0, 19.0), mug_col, true)
	_draw_ellipse_poly(base_pos + Vector2(0.0, -20.0), 11.0, 3.2, mug_col.lightened(0.15), 16)
	# Handle
	var h_dir: float = -1.0 if handle_left else 1.0
	var arc_start: float = PI * 0.5 if handle_left else -PI * 0.5
	var arc_end: float = PI * 1.5 if handle_left else PI * 0.5
	stage_canvas.draw_arc(base_pos + Vector2(h_dir * 11.0, -10.5), 6.0, arc_start, arc_end, 12, mug_col, 2.5, true)
	# Rising warm steam ribbons once house begins warming
	if w > 0.14:
		var steam_a: float = clampf((w - 0.14) / 0.86, 0.0, 1.0) * 0.52
		for s_i: int in range(2):
			var pts: PackedVector2Array = PackedVector2Array()
			var x_off: float = -4.0 + float(s_i) * 8.0
			for k: int in range(10):
				var t: float = float(k) / 9.0
				var sy: float = base_pos.y - 25.0 - t * (34.0 + w * 20.0)
				var sx: float = base_pos.x + x_off + sin(_global_time * 2.2 + t * 4.5 + float(s_i) * 1.8) * (4.0 + t * 5.0)
				pts.append(Vector2(sx, sy))
			stage_canvas.draw_polyline(pts, Color(1.0, 0.94, 0.82, steam_a), 2.0, true)


func _draw_pixar_parent_ch1(base_pos: Vector2, is_mother: bool, w: float) -> void:
	# Soft breathing & turning gently toward the warm light in the center
	var dir_sign: float = 1.0 if is_mother else -1.0
	var breath: float = sin(_global_time * 1.45 + (0.0 if is_mother else 1.6)) * 2.2
	var lean_x: float = dir_sign * w * 22.0
	var head_lift: float = w * 13.0

	# Pixar color-script clothing: terracotta-cream for mother, deep indigo-sage for father
	var cold_cloth: Color = Color(0.11, 0.15, 0.25, 0.96) if is_mother else Color(0.08, 0.12, 0.21, 0.96)
	var warm_cloth: Color = Color(0.68, 0.36, 0.30, 0.98) if is_mother else Color(0.19, 0.31, 0.38, 0.98)
	var cloth_col: Color = cold_cloth.lerp(warm_cloth, 0.24 + w * 0.76)
	var collar_col: Color = Color(0.26, 0.34, 0.48, 0.92).lerp(
		Color(0.95, 0.86, 0.72, 0.95) if is_mother else Color(0.58, 0.70, 0.68, 0.95),
		0.22 + w * 0.78
	)
	var skin_col: Color = Color(0.24, 0.27, 0.38, 0.96).lerp(Color(0.90, 0.72, 0.58, 0.98), 0.20 + w * 0.80)
	var hair_col: Color = Color(0.08, 0.10, 0.17, 0.98).lerp(
		Color(0.32, 0.18, 0.14, 0.98) if is_mother else Color(0.16, 0.14, 0.15, 0.98),
		0.25 + w * 0.75
	)
	var rim_col: Color = Color(0.62, 0.78, 0.98, 0.36).lerp(Color(1.0, 0.88, 0.52, 0.88), w)

	# Rounded Pixar torso & shoulders
	var sh_w: float = 38.0 if is_mother else 46.0
	var torso_h: float = (108.0 if is_mother else 120.0) + breath
	var shoulder_c: Vector2 = base_pos + Vector2(lean_x * 0.65, -torso_h * 0.84)

	var torso: PackedVector2Array = PackedVector2Array([
		base_pos + Vector2(-sh_w * 0.95, 14.0),
		base_pos + Vector2(-sh_w * 0.86 + lean_x * 0.45, -torso_h * 0.74),
		shoulder_c + Vector2(0.0, -14.0),
		base_pos + Vector2(sh_w * 0.86 + lean_x * 0.55, -torso_h * 0.74),
		base_pos + Vector2(sh_w * 0.95, 14.0),
	])
	stage_canvas.draw_colored_polygon(torso, cloth_col)
	_draw_ellipse_poly(shoulder_c, sh_w * 0.84, 24.0, cloth_col, 24)

	# Cozy cardigan shawl / shirt collar
	_draw_ellipse_poly(shoulder_c + Vector2(dir_sign * 4.0, -10.0), 17.0 if is_mother else 20.0, 10.0, collar_col, 18)

	# Soft reaching arm toward the table / child's warmth
	var arm_start: Vector2 = shoulder_c + Vector2(dir_sign * sh_w * 0.52, 8.0)
	var arm_end: Vector2 = base_pos + Vector2(dir_sign * (sh_w * 0.95 + w * 26.0), -12.0 - w * 6.0)
	stage_canvas.draw_line(arm_start, arm_end, cloth_col.lightened(0.06), 14.0 if is_mother else 16.0, true)
	stage_canvas.draw_circle(arm_end, 7.5, skin_col)

	# Expressive rounded Pixar head
	var head_r: float = 22.5 if is_mother else 24.0
	var head_pos: Vector2 = base_pos + Vector2(lean_x + dir_sign * 6.0, -torso_h - 24.0 - head_lift * 0.30 + breath)
	# Neck
	stage_canvas.draw_line(shoulder_c + Vector2(dir_sign * 3.0, -8.0), head_pos + Vector2(0.0, 14.0), skin_col.darkened(0.12), 11.0, true)
	# Face sphere
	stage_canvas.draw_circle(head_pos, head_r, skin_col)

	# Warm rosy cheek & gentle eye/smile hint facing center light
	if w > 0.25:
		var cheek_a: float = clampf((w - 0.25) / 0.75, 0.0, 1.0)
		stage_canvas.draw_circle(head_pos + Vector2(dir_sign * 10.0, 4.0), 5.5, Color(0.95, 0.54, 0.46, 0.26 * cheek_a))
		stage_canvas.draw_arc(
			head_pos + Vector2(dir_sign * 9.0, 9.0),
			6.0,
			0.2 if is_mother else PI - 1.2,
			1.2 if is_mother else PI - 0.2,
			10,
			Color(0.42, 0.22, 0.18, 0.55 * cheek_a),
			1.6,
			true
		)

	# Hair silhouette (soft bun for mother, warm tousled hair for father)
	if is_mother:
		stage_canvas.draw_arc(head_pos + Vector2(-dir_sign * 2.0, -2.0), head_r + 1.5, PI * 0.75, TAU - 0.35, 22, hair_col, 9.0, true)
		stage_canvas.draw_circle(head_pos + Vector2(-dir_sign * 21.0, -7.0), 12.0, hair_col)
		stage_canvas.draw_arc(head_pos + Vector2(-dir_sign * 21.0, -7.0), 12.0, -0.8, 0.6, 12, rim_col, 1.8, true)
	else:
		stage_canvas.draw_arc(head_pos + Vector2(dir_sign * 1.0, -3.0), head_r + 1.5, PI + 0.30, TAU - 0.75, 22, hair_col, 9.5, true)
		_draw_ellipse_poly(head_pos + Vector2(-dir_sign * 4.0, -head_r + 3.0), 18.0, 8.0, hair_col, 16)

	# Golden Pixar rim light along head & shoulder facing the center hearth
	stage_canvas.draw_arc(
		head_pos,
		head_r + 1.0,
		(-0.75 if is_mother else PI - 0.75),
		(0.85 if is_mother else PI + 0.85),
		18,
		rim_col,
		2.6,
		true
	)
	stage_canvas.draw_arc(
		shoulder_c,
		sh_w * 0.82,
		(-0.95 if is_mother else PI - 0.35),
		(0.35 if is_mother else PI + 0.95),
		16,
		Color(rim_col.r, rim_col.g, rim_col.b, rim_col.a * 0.78),
		2.6,
		true
	)


# =============================================================================
# CHAPTER 2A — ВЕСНА 1: «САД И МЫЛЬНЫЕ ПУЗЫРИ» (PIXAR / TANGLED SUNLIT GARDEN)
# =============================================================================

func _draw_ch2_bubbles(vp: Vector2) -> void:
	# 1. Lush sunlit Tangled tree canopies framing upper-left & upper-right with dappled light
	_draw_tangled_tree_canopy(vp, true)
	_draw_tangled_tree_canopy(vp, false)

	# 2. Multi-layered sunlit rolling hills
	var hill_far: PackedVector2Array = PackedVector2Array()
	hill_far.append(Vector2(0.0, vp.y))
	for i: int in range(19):
		var t: float = float(i) / 18.0
		var hx: float = t * vp.x
		var hy: float = vp.y * 0.76 - sin(t * PI * 1.1) * 48.0 - cos(t * PI * 2.4) * 14.0
		hill_far.append(Vector2(hx, hy))
	hill_far.append(Vector2(vp.x, vp.y))
	stage_canvas.draw_colored_polygon(hill_far, Color(0.32, 0.56, 0.44, 0.58))

	var hill_mid: PackedVector2Array = PackedVector2Array()
	hill_mid.append(Vector2(0.0, vp.y))
	for i: int in range(19):
		var t: float = float(i) / 18.0
		var hx: float = t * vp.x
		var hy: float = vp.y * 0.83 - sin(t * PI * 1.35 + 0.5) * 32.0
		hill_mid.append(Vector2(hx, hy))
	hill_mid.append(Vector2(vp.x, vp.y))
	stage_canvas.draw_colored_polygon(hill_mid, Color(0.23, 0.46, 0.33, 0.84))

	var hill_front: PackedVector2Array = PackedVector2Array()
	hill_front.append(Vector2(0.0, vp.y))
	for i: int in range(19):
		var t: float = float(i) / 18.0
		var hx: float = t * vp.x
		var hy: float = vp.y * 0.89 - sin(t * PI * 1.6 + 1.2) * 16.0
		hill_front.append(Vector2(hx, hy))
	hill_front.append(Vector2(vp.x, vp.y))
	stage_canvas.draw_colored_polygon(hill_front, Color(0.16, 0.34, 0.25, 0.94))

	# 3. Flowering garden bush on the lower-right with pink-cream blossoms
	_draw_flowering_bush(Vector2(vp.x * 0.84, vp.y * 0.84))

	# 4. Swaying meadow grass & tiny spring wildflowers
	for g_i: int in range(44):
		var gx: float = (float(g_i) / 43.0) * vp.x
		var sway: float = sin(_global_time * 1.7 + float(g_i) * 0.45) * 10.0
		var base_y: float = vp.y * 0.89 + sin(float(g_i) * 0.85) * 13.0
		var tip: Vector2 = Vector2(gx + sway, base_y - 20.0 - float(g_i % 3) * 8.0)
		stage_canvas.draw_line(
			Vector2(gx, base_y + 24.0),
			tip,
			Color(0.28, 0.54, 0.34, 0.65),
			2.2,
			true
		)
		if g_i % 5 == 2:
			var f_col: Color = Color(1.0, 0.92, 0.62, 0.85) if (g_i % 2 == 0) else Color(1.0, 0.84, 0.88, 0.85)
			stage_canvas.draw_circle(tip, 3.6, f_col)

	# 5. Mother spinning joyfully with the small child in warm golden rim light
	_draw_garden_mother_and_child(Vector2(vp.x * 0.23, vp.y * 0.84))

	# 6. Twirling spring petals (soft rotated ellipses)
	for p_item: Dictionary in _petals:
		var pp: Vector2 = p_item["pos"] as Vector2
		var p_sz: float = float(p_item["size"])
		var p_rot: float = float(p_item["rot"])
		_draw_ellipse_poly(pp, p_sz * 1.5, p_sz * 0.72, Color(1.0, 0.90, 0.90, 0.72), 10, p_rot)
		stage_canvas.draw_circle(pp, p_sz * 0.35, Color(1.0, 0.98, 0.94, 0.65))

	# 7. Pixar iridescent soap bubbles with pastel rainbow shimmer & two crisp glossy highlights
	for b: Dictionary in _bubbles:
		_draw_pixar_soap_bubble(b)


func _draw_tangled_tree_canopy(vp: Vector2, is_left: bool) -> void:
	var sign_x: float = 1.0 if is_left else -1.0
	var trunk_x: float = vp.x * 0.05 if is_left else vp.x * 0.95
	var trunk_col: Color = Color(0.24, 0.17, 0.14, 0.82)
	var trunk_poly: PackedVector2Array = PackedVector2Array([
		Vector2(trunk_x - 28.0, vp.y * 0.86),
		Vector2(trunk_x - 16.0, vp.y * 0.22),
		Vector2(trunk_x + 18.0, vp.y * 0.22),
		Vector2(trunk_x + 34.0, vp.y * 0.86),
	])
	stage_canvas.draw_colored_polygon(trunk_poly, trunk_col)

	var sway: float = sin(_global_time * 0.9 + (0.0 if is_left else 2.1)) * 5.0
	var base_cx: float = vp.x * 0.10 if is_left else vp.x * 0.90
	var deep_leaf: Color = Color(0.15, 0.35, 0.26, 0.78)
	var mid_leaf: Color = Color(0.24, 0.49, 0.31, 0.72)
	var sunlit_leaf: Color = Color(0.56, 0.74, 0.38, 0.56)

	# Back deep foliage puffs
	stage_canvas.draw_circle(Vector2(base_cx + sway * 0.5, vp.y * 0.12), 118.0, deep_leaf)
	stage_canvas.draw_circle(Vector2(base_cx + sign_x * 96.0 + sway, vp.y * 0.16), 88.0, deep_leaf)
	stage_canvas.draw_circle(Vector2(base_cx + sign_x * 38.0 + sway * 0.7, vp.y * 0.26), 82.0, deep_leaf)
	# Mid lush puffs
	stage_canvas.draw_circle(Vector2(base_cx + sign_x * 54.0 + sway, vp.y * 0.14), 76.0, mid_leaf)
	stage_canvas.draw_circle(Vector2(base_cx + sign_x * 136.0 + sway * 1.1, vp.y * 0.20), 62.0, mid_leaf)
	# Warm sunlit leaf highlights & dappled sun openings
	stage_canvas.draw_circle(Vector2(base_cx + sign_x * 92.0 + sway, vp.y * 0.19), 44.0, sunlit_leaf)
	stage_canvas.draw_circle(Vector2(base_cx + sign_x * 148.0 + sway * 1.2, vp.y * 0.24), 32.0, sunlit_leaf)
	_draw_soft_glow(Vector2(base_cx + sign_x * 116.0, vp.y * 0.21), 54.0, Color(1.0, 0.96, 0.74, 0.24))


func _draw_flowering_bush(pos: Vector2) -> void:
	var sway: float = sin(_global_time * 1.3) * 3.0
	stage_canvas.draw_circle(pos + Vector2(-42.0, 12.0), 48.0, Color(0.14, 0.32, 0.23, 0.92))
	stage_canvas.draw_circle(pos + Vector2(18.0, 6.0), 56.0, Color(0.18, 0.38, 0.26, 0.94))
	stage_canvas.draw_circle(pos + Vector2(68.0, 18.0), 44.0, Color(0.15, 0.34, 0.24, 0.92))
	stage_canvas.draw_circle(pos + Vector2(-6.0 + sway, -12.0), 42.0, Color(0.25, 0.48, 0.32, 0.88))

	var flower_offsets: Array[Vector2] = [
		Vector2(-38.0, -4.0),
		Vector2(-12.0, -24.0),
		Vector2(18.0, -18.0),
		Vector2(44.0, -6.0),
		Vector2(6.0, 4.0),
		Vector2(-24.0, 14.0),
		Vector2(34.0, 14.0),
		Vector2(64.0, 4.0),
	]
	for idx: int in range(flower_offsets.size()):
		var fp: Vector2 = pos + flower_offsets[idx] + Vector2(sway * 0.6, 0.0)
		var petal_c: Color = Color(1.0, 0.82, 0.86, 0.94) if (idx % 2 == 0) else Color(1.0, 0.92, 0.78, 0.94)
		stage_canvas.draw_circle(fp, 7.5, petal_c)
		stage_canvas.draw_circle(fp, 3.0, Color(1.0, 0.84, 0.42, 0.96))


func _draw_garden_mother_and_child(m_pos: Vector2) -> void:
	var spin_sway: float = sin(_global_time * 1.55) * 9.0
	var breath: float = sin(_global_time * 1.8) * 2.0

	# Mother in flowing terracotta-cream sundress with sunny golden rim light
	var dress_col: Color = Color(0.76, 0.42, 0.34, 0.95)
	var dress_hi: Color = Color(0.96, 0.74, 0.56, 0.65)
	var skin_col: Color = Color(0.94, 0.76, 0.62, 0.98)
	var hair_col: Color = Color(0.34, 0.20, 0.14, 0.98)
	var sun_rim: Color = Color(1.0, 0.95, 0.72, 0.92)

	var dress: PackedVector2Array = PackedVector2Array([
		m_pos + Vector2(-54.0 - spin_sway * 0.6, 20.0),
		m_pos + Vector2(-17.0, -76.0 + breath),
		m_pos + Vector2(17.0, -76.0 + breath),
		m_pos + Vector2(56.0 + spin_sway * 0.6, 20.0),
	])
	stage_canvas.draw_colored_polygon(dress, dress_col)
	# Sunlit skirt fold
	stage_canvas.draw_line(m_pos + Vector2(12.0, -72.0), m_pos + Vector2(44.0 + spin_sway * 0.5, 18.0), dress_hi, 5.0, true)

	var m_head: Vector2 = m_pos + Vector2(spin_sway * 0.22, -96.0 + breath)
	stage_canvas.draw_circle(m_head, 17.5, skin_col)
	stage_canvas.draw_arc(m_head + Vector2(-2.0, -2.0), 18.0, PI * 0.70, TAU - 0.25, 20, hair_col, 8.0, true)
	stage_canvas.draw_circle(m_head + Vector2(-16.0, -5.0), 10.0, hair_col)
	# Warm sun rim light on mother
	stage_canvas.draw_arc(m_head, 18.5, -1.1, 0.55, 16, sun_rim, 2.5, true)

	# Joyful small child in amber-gold sweater lifted in her arms
	var c_pos: Vector2 = m_pos + Vector2(56.0 + spin_sway * 0.65, -56.0 + cos(_global_time * 1.55) * 7.0)
	_draw_soft_glow(c_pos + Vector2(0.0, -6.0), 42.0, Color(1.0, 0.88, 0.48, 0.34))
	stage_canvas.draw_line(m_pos + Vector2(11.0, -68.0), c_pos + Vector2(-8.0, -2.0), skin_col, 7.0, true)
	_draw_ellipse_poly(c_pos + Vector2(0.0, 2.0), 13.0, 14.0, Color(0.95, 0.72, 0.28, 0.96), 18)
	stage_canvas.draw_circle(c_pos + Vector2(0.0, -16.0), 11.5, skin_col)
	stage_canvas.draw_arc(c_pos + Vector2(0.0, -17.0), 12.0, PI + 0.2, TAU - 0.2, 14, Color(0.42, 0.25, 0.16, 0.95), 5.5, true)
	stage_canvas.draw_arc(c_pos + Vector2(0.0, -16.0), 12.5, -1.0, 0.6, 14, sun_rim, 2.2, true)


func _draw_pixar_soap_bubble(b: Dictionary) -> void:
	var bp: Vector2 = b["pos"] as Vector2
	var br: float = float(b["radius"])
	var ba: float = float(b["alpha"])
	var shift: float = float(b["hue_shift"]) + _global_time * 0.12

	# Translucent soap film interior + soft pastel depth
	stage_canvas.draw_circle(bp, br, Color(0.94, 0.98, 1.0, 0.14 * ba))
	stage_canvas.draw_circle(bp + Vector2(br * 0.12, br * 0.14), br * 0.72, Color(0.84, 0.95, 1.0, 0.08 * ba))

	# Pastel rainbow iridescent rim (4 smoothly shifting arcs)
	var a0: float = shift * TAU
	stage_canvas.draw_arc(bp, br, a0, a0 + PI * 0.58, 20, Color(0.68, 0.94, 1.0, 0.78 * ba), 2.8, true)
	stage_canvas.draw_arc(bp, br, a0 + PI * 0.55, a0 + PI * 1.12, 20, Color(0.86, 0.76, 1.0, 0.74 * ba), 2.6, true)
	stage_canvas.draw_arc(bp, br, a0 + PI * 1.08, a0 + PI * 1.62, 20, Color(1.0, 0.80, 0.88, 0.76 * ba), 2.6, true)
	stage_canvas.draw_arc(bp, br, a0 + PI * 1.58, a0 + TAU + 0.05, 20, Color(1.0, 0.95, 0.66, 0.74 * ba), 2.4, true)

	# Inner iridescent whisper
	stage_canvas.draw_arc(bp, br * 0.86, a0 + 0.4, a0 + 1.9, 16, Color(1.0, 0.88, 0.94, 0.34 * ba), 2.0, true)

	# Two crisp white glossy Pixar highlights + warm lower bounce reflection
	_draw_ellipse_poly(bp + Vector2(-br * 0.36, -br * 0.36), br * 0.22, br * 0.12, Color(1.0, 1.0, 1.0, 0.90 * ba), 14, -0.75)
	stage_canvas.draw_circle(bp + Vector2(-br * 0.12, -br * 0.52), br * 0.08, Color(1.0, 1.0, 1.0, 0.84 * ba))
	stage_canvas.draw_arc(bp, br * 0.82, 0.35, 1.25, 12, Color(1.0, 0.95, 0.78, 0.52 * ba), 2.0, true)


# =============================================================================
# CHAPTER 2B — ВЕСНА 4: «СОЛНЦЕ НА ОБОЯХ» (UP / INSIDE OUT GOLDEN EVENING)
# =============================================================================

func _draw_ch2_wallpaper(vp: Vector2) -> void:
	# 1. Warm storybook wallpaper with stripes, delicate diamond motif & baseboard
	var stripe_col: Color = Color(1.0, 0.92, 0.76, 0.08)
	var x_pos: float = 0.0
	while x_pos < vp.x:
		stage_canvas.draw_rect(Rect2(x_pos, 0.0, 20.0, vp.y * 0.82), stripe_col, true)
		x_pos += 58.0

	# Subtle warm wood baseboard & floor
	stage_canvas.draw_rect(Rect2(0.0, vp.y * 0.82, vp.x, vp.y * 0.18), Color(0.24, 0.14, 0.10, 0.95), true)
	stage_canvas.draw_rect(Rect2(0.0, vp.y * 0.80, vp.x, 14.0), Color(0.32, 0.19, 0.13, 0.95), true)
	stage_canvas.draw_line(Vector2(0.0, vp.y * 0.80), Vector2(vp.x, vp.y * 0.80), Color(1.0, 0.82, 0.52, 0.45), 2.2, true)

	# 2. Slanted golden evening sunbeam window-square cast onto the wallpaper!
	var win_quad: PackedVector2Array = PackedVector2Array([
		Vector2(vp.x * 0.10, vp.y * 0.14),
		Vector2(vp.x * 0.36, vp.y * 0.22),
		Vector2(vp.x * 0.30, vp.y * 0.66),
		Vector2(vp.x * 0.05, vp.y * 0.58),
	])
	stage_canvas.draw_colored_polygon(win_quad, Color(1.0, 0.90, 0.60, 0.18))
	# Window mullion shadow cross inside the sunlit square
	var mullion_col: Color = Color(0.48, 0.30, 0.22, 0.22)
	stage_canvas.draw_line(Vector2(vp.x * 0.23, vp.y * 0.18), Vector2(vp.x * 0.175, vp.y * 0.62), mullion_col, 7.0, true)
	stage_canvas.draw_line(Vector2(vp.x * 0.075, vp.y * 0.36), Vector2(vp.x * 0.33, vp.y * 0.44), mullion_col, 7.0, true)

	# 3. Cozy side table & warm glowing table lamp on the left
	_draw_ch2_table_lamp(vp)

	# 4. Toy shelf in upper-right with teddy bear, colorful blocks & picture books
	_draw_ch2_toy_shelf(vp)

	# 5. Dotted golden sun guide circle on the wall
	var center: Vector2 = _get_wallpaper_sun_center(vp)
	var guide_r: float = 104.0
	if not _wall_sun_complete:
		var pulse: float = 0.5 + 0.5 * sin(_global_time * 2.2)
		for i: int in range(28):
			var a0: float = float(i) / 28.0 * TAU
			var a1: float = a0 + 0.10
			stage_canvas.draw_arc(center, guide_r, a0, a1, 4, Color(1.0, 0.88, 0.55, 0.34 + 0.24 * pulse), 2.4, true)

	# Warm child crayon doodles softly emerging around the sun as player draws!
	if _wall_sun_progress > 0.12:
		var doodle_a: float = clampf((_wall_sun_progress - 0.12) / 0.78, 0.0, 1.0)
		_draw_wallpaper_child_doodles(center, doodle_a)

	# Glowing inner sun warmth growing with drawing progress
	if _wall_sun_progress > 0.02:
		_draw_soft_glow(center, 195.0 * _wall_sun_progress, Color(1.0, 0.84, 0.40, 0.40 * _wall_sun_progress))

	# Hand-drawn chalk/pastel golden rays when completed
	if _wall_sun_complete:
		for r_i: int in range(12):
			var ang: float = float(r_i) / 12.0 * TAU + _global_time * 0.08
			var dir: Vector2 = Vector2(cos(ang), sin(ang))
			var inner: Vector2 = center + dir * (guide_r + 18.0)
			var outer: Vector2 = center + dir * (guide_r + 58.0 + sin(_global_time * 2.0 + float(r_i)) * 8.0)
			stage_canvas.draw_line(inner, outer, Color(1.0, 0.92, 0.56, 0.82), 5.0, true)

	# 6. Player's drawn golden pastel strokes
	for stroke: PackedVector2Array in _wall_strokes:
		if stroke.size() < 2:
			continue
		stage_canvas.draw_polyline(stroke, Color(1.0, 0.82, 0.36, 0.35), 16.0, true)
		stage_canvas.draw_polyline(stroke, Color(1.0, 0.94, 0.66, 0.95), 6.5, true)

	# 7. Pixar Father (right) setting down his briefcase and sitting down with a warm smile
	_draw_wallpaper_father(vp, _wall_father_sit)


func _draw_ch2_table_lamp(vp: Vector2) -> void:
	var tx: float = vp.x * 0.13
	var ty: float = vp.y * 0.66
	var wood: Color = Color(0.28, 0.16, 0.11, 0.95)
	stage_canvas.draw_rect(Rect2(tx - 44.0, ty, 88.0, 10.0), wood, true)
	stage_canvas.draw_rect(Rect2(tx - 34.0, ty + 10.0, 8.0, vp.y * 0.16), wood, true)
	stage_canvas.draw_rect(Rect2(tx + 26.0, ty + 10.0, 8.0, vp.y * 0.16), wood, true)

	# Ceramic lamp base & warm glowing shade
	_draw_ellipse_poly(Vector2(tx, ty - 14.0), 12.0, 15.0, Color(0.42, 0.56, 0.54, 0.95), 16)
	var shade_c: Vector2 = Vector2(tx, ty - 48.0)
	_draw_soft_glow(shade_c + Vector2(0.0, 6.0), 96.0, Color(1.0, 0.84, 0.46, 0.30))
	var shade: PackedVector2Array = PackedVector2Array([
		shade_c + Vector2(-16.0, -18.0),
		shade_c + Vector2(16.0, -18.0),
		shade_c + Vector2(30.0, 16.0),
		shade_c + Vector2(-30.0, 16.0),
	])
	stage_canvas.draw_colored_polygon(shade, Color(0.98, 0.84, 0.56, 0.94))
	stage_canvas.draw_line(shade_c + Vector2(-30.0, 16.0), shade_c + Vector2(30.0, 16.0), Color(1.0, 0.95, 0.78, 0.95), 2.2, true)


func _draw_ch2_toy_shelf(vp: Vector2) -> void:
	var sx: float = vp.x * 0.72
	var sy: float = vp.y * 0.24
	var sw: float = vp.x * 0.20
	var wood: Color = Color(0.32, 0.19, 0.13, 0.94)
	stage_canvas.draw_rect(Rect2(sx, sy, sw, 10.0), wood, true)
	stage_canvas.draw_line(Vector2(sx, sy), Vector2(sx + sw, sy), Color(0.96, 0.78, 0.52, 0.45), 1.8, true)

	# Plush teddy bear silhouette on the left of the shelf
	var bear_p: Vector2 = Vector2(sx + 38.0, sy - 16.0)
	var bear_c: Color = Color(0.56, 0.35, 0.22, 0.94)
	_draw_ellipse_poly(bear_p, 14.0, 16.0, bear_c, 16)
	stage_canvas.draw_circle(bear_p + Vector2(0.0, -20.0), 11.5, bear_c)
	stage_canvas.draw_circle(bear_p + Vector2(-9.0, -29.0), 4.5, bear_c)
	stage_canvas.draw_circle(bear_p + Vector2(9.0, -29.0), 4.5, bear_c)
	stage_canvas.draw_circle(bear_p + Vector2(0.0, -18.0), 4.2, Color(0.84, 0.66, 0.48, 0.92))

	# Colorful wooden toy blocks in the middle
	stage_canvas.draw_rect(Rect2(sx + 84.0, sy - 20.0, 20.0, 20.0), Color(0.84, 0.42, 0.34, 0.92), true)
	stage_canvas.draw_rect(Rect2(sx + 107.0, sy - 20.0, 20.0, 20.0), Color(0.36, 0.58, 0.66, 0.92), true)
	stage_canvas.draw_rect(Rect2(sx + 95.0, sy - 40.0, 20.0, 20.0), Color(0.94, 0.76, 0.34, 0.92), true)

	# Small leaning storybook stack on the right
	stage_canvas.draw_rect(Rect2(sx + 150.0, sy - 34.0, 12.0, 34.0), Color(0.32, 0.48, 0.38, 0.92), true)
	stage_canvas.draw_rect(Rect2(sx + 165.0, sy - 28.0, 11.0, 28.0), Color(0.76, 0.48, 0.36, 0.92), true)
	stage_canvas.draw_rect(Rect2(sx + 179.0, sy - 38.0, 12.0, 38.0), Color(0.30, 0.38, 0.56, 0.92), true)


func _draw_wallpaper_child_doodles(sun_center: Vector2, alpha: float) -> void:
	# Warm pastel crayon drawings emerging around the sun: little house, tree, and 3 holding hands
	var chalk_warm: Color = Color(1.0, 0.89, 0.62, 0.56 * alpha)
	var chalk_terra: Color = Color(0.98, 0.72, 0.54, 0.52 * alpha)
	var chalk_leaf: Color = Color(0.74, 0.90, 0.64, 0.50 * alpha)

	# 1. Little cozy house to the lower-left of the sun
	var h_pos: Vector2 = sun_center + Vector2(-175.0, 128.0)
	stage_canvas.draw_polyline(PackedVector2Array([
		h_pos + Vector2(-26.0, 24.0),
		h_pos + Vector2(-26.0, -8.0),
		h_pos + Vector2(26.0, -8.0),
		h_pos + Vector2(26.0, 24.0),
		h_pos + Vector2(-26.0, 24.0),
	]), chalk_warm, 2.6, true)
	stage_canvas.draw_polyline(PackedVector2Array([
		h_pos + Vector2(-32.0, -8.0),
		h_pos + Vector2(0.0, -34.0),
		h_pos + Vector2(32.0, -8.0),
	]), chalk_terra, 2.8, true)
	# Little glowing window & chimney puff
	stage_canvas.draw_rect(Rect2(h_pos.x - 8.0, h_pos.y + 1.0, 16.0, 14.0), Color(1.0, 0.90, 0.58, 0.34 * alpha), true)
	stage_canvas.draw_arc(h_pos + Vector2(18.0, -40.0), 6.0, 0.0, TAU, 10, chalk_warm, 1.8, true)
	stage_canvas.draw_arc(h_pos + Vector2(24.0, -52.0), 8.0, 0.0, TAU, 10, chalk_warm, 1.6, true)

	# 2. Fluffy child-drawn tree to the lower-right of the sun
	var t_pos: Vector2 = sun_center + Vector2(158.0, 132.0)
	stage_canvas.draw_line(t_pos + Vector2(0.0, 20.0), t_pos + Vector2(0.0, -14.0), chalk_terra, 4.0, true)
	stage_canvas.draw_arc(t_pos + Vector2(0.0, -28.0), 20.0, 0.0, TAU, 18, chalk_leaf, 2.6, true)
	stage_canvas.draw_arc(t_pos + Vector2(-14.0, -20.0), 14.0, 0.0, TAU, 14, chalk_leaf, 2.2, true)
	stage_canvas.draw_arc(t_pos + Vector2(14.0, -20.0), 14.0, 0.0, TAU, 14, chalk_leaf, 2.2, true)

	# 3. Three tiny stick-figure family holding hands right below the sun + little heart
	var f_y: float = sun_center.y + 150.0
	var f_xs: Array[float] = [sun_center.x - 36.0, sun_center.x, sun_center.x + 36.0]
	var f_hs: Array[float] = [28.0, 19.0, 31.0]
	for i: int in range(3):
		var fx: float = f_xs[i]
		var fh: float = f_hs[i]
		var head_r: float = 7.0 if i != 1 else 5.8
		stage_canvas.draw_arc(Vector2(fx, f_y - fh - head_r), head_r, 0.0, TAU, 12, chalk_warm, 2.2, true)
		stage_canvas.draw_line(Vector2(fx, f_y - fh), Vector2(fx, f_y - 8.0), chalk_warm, 2.4, true)
		stage_canvas.draw_line(Vector2(fx, f_y - 8.0), Vector2(fx - 7.0, f_y + 4.0), chalk_warm, 2.2, true)
		stage_canvas.draw_line(Vector2(fx, f_y - 8.0), Vector2(fx + 7.0, f_y + 4.0), chalk_warm, 2.2, true)
	# Holding hands line
	stage_canvas.draw_line(Vector2(f_xs[0], f_y - 20.0), Vector2(f_xs[1], f_y - 14.0), chalk_warm, 2.2, true)
	stage_canvas.draw_line(Vector2(f_xs[1], f_y - 14.0), Vector2(f_xs[2], f_y - 22.0), chalk_warm, 2.2, true)
	# Tiny warm heart above the child
	var heart_c: Vector2 = Vector2(sun_center.x, f_y - 44.0)
	stage_canvas.draw_circle(heart_c + Vector2(-3.2, 0.0), 3.6, chalk_terra)
	stage_canvas.draw_circle(heart_c + Vector2(3.2, 0.0), 3.6, chalk_terra)
	stage_canvas.draw_colored_polygon(PackedVector2Array([
		heart_c + Vector2(-6.6, 1.0),
		heart_c + Vector2(6.6, 1.0),
		heart_c + Vector2(0.0, 8.5),
	]), chalk_terra)


func _draw_wallpaper_father(vp: Vector2, sit_t: float) -> void:
	var breath: float = sin(_global_time * 1.4) * 2.0
	var father_x: float = lerpf(vp.x * 0.78, vp.x * 0.68, sit_t)
	var father_y: float = lerpf(vp.y * 0.82, vp.y * 0.85, sit_t)
	var body_h: float = lerpf(182.0, 114.0, sit_t) + breath

	var jacket_col: Color = Color(0.18, 0.27, 0.36, 0.96)
	var shirt_col: Color = Color(0.92, 0.88, 0.80, 0.95)
	var skin_col: Color = Color(0.90, 0.72, 0.58, 0.98)
	var hair_col: Color = Color(0.18, 0.14, 0.13, 0.98)
	var sun_rim: Color = Color(1.0, 0.88, 0.52, 0.45 + sit_t * 0.45)

	var sh_c: Vector2 = Vector2(father_x - sit_t * 6.0, father_y - body_h)
	var f_body: PackedVector2Array = PackedVector2Array([
		Vector2(father_x - 38.0 - sit_t * 18.0, father_y),
		Vector2(father_x - 32.0 - sit_t * 6.0, father_y - body_h),
		Vector2(father_x + 32.0, father_y - body_h),
		Vector2(father_x + 36.0 + sit_t * 10.0, father_y),
	])
	stage_canvas.draw_colored_polygon(f_body, jacket_col)
	_draw_ellipse_poly(sh_c, 36.0, 20.0, jacket_col, 22)
	_draw_ellipse_poly(sh_c + Vector2(-4.0, -8.0), 15.0, 9.0, shirt_col, 16)

	# Head turning toward the child's sun with a gentle smile as he sits
	var head_p: Vector2 = Vector2(father_x - sit_t * 10.0, father_y - body_h - 24.0)
	stage_canvas.draw_circle(head_p, 22.5, skin_col)
	stage_canvas.draw_arc(head_p + Vector2(2.0, -2.0), 23.0, PI + 0.35, TAU - 0.55, 20, hair_col, 9.0, true)
	_draw_ellipse_poly(head_p + Vector2(4.0, -19.0), 17.0, 7.5, hair_col, 16)

	# Warm smile & relaxed eyes appearing as sit_t increases
	if sit_t > 0.25:
		var sm_a: float = clampf((sit_t - 0.25) / 0.75, 0.0, 1.0)
		stage_canvas.draw_arc(head_p + Vector2(-9.0, 6.0), 7.5, 0.25, 1.45, 12, Color(0.40, 0.22, 0.16, 0.78 * sm_a), 2.0, true)
		stage_canvas.draw_arc(head_p + Vector2(-10.0, -4.0), 4.2, PI + 0.3, TAU - 0.3, 10, Color(0.28, 0.16, 0.12, 0.72 * sm_a), 1.8, true)

	# Warm golden rim light from the sun on the wallpaper
	stage_canvas.draw_arc(head_p, 23.5, PI - 0.75, PI + 0.85, 18, sun_rim, 2.6, true)
	stage_canvas.draw_arc(sh_c, 36.0, PI - 0.45, PI + 0.85, 14, Color(sun_rim.r, sun_rim.g, sun_rim.b, sun_rim.a * 0.78), 2.6, true)

	# Leather briefcase gently set down on the floor to his right
	var case_pos: Vector2 = Vector2(
		lerpf(father_x + 38.0, vp.x * 0.83, sit_t),
		lerpf(father_y - 72.0, vp.y * 0.79, sit_t)
	)
	stage_canvas.draw_rect(Rect2(case_pos.x - 23.0, case_pos.y - 16.0, 46.0, 32.0), Color(0.26, 0.15, 0.10, 0.96), true)
	stage_canvas.draw_rect(Rect2(case_pos.x - 23.0, case_pos.y - 4.0, 46.0, 3.0), Color(0.86, 0.68, 0.36, 0.65), true)
	stage_canvas.draw_arc(case_pos + Vector2(0.0, -16.0), 8.5, PI, TAU, 12, Color(0.26, 0.15, 0.10, 0.96), 2.8, true)


# =============================================================================
# CHAPTER 2C — ВЕСНА 7: «ВЕЧЕР У МОРЯ» (PIXAR GOLDEN SUNSET COAST)
# =============================================================================

func _draw_ch2_sea(vp: Vector2) -> void:
	var horizon_y: float = vp.y * 0.56
	var cx: float = vp.x * 0.5

	# 1. Fluffy Pixar sunset clouds (plum-rose shadow beneath + luminous coral-gold tops)
	_draw_sunset_cloud(Vector2(vp.x * 0.22 + sin(_global_time * 0.08) * 14.0, vp.y * 0.24), 1.05)
	_draw_sunset_cloud(Vector2(vp.x * 0.76 + cos(_global_time * 0.07) * 16.0, vp.y * 0.21), 1.20)
	_draw_sunset_cloud(Vector2(vp.x * 0.52 + sin(_global_time * 0.06 + 1.5) * 12.0, vp.y * 0.33), 0.82)

	# 2. Distant gliding seagulls
	for b_i: int in range(5):
		var bx: float = fmod(vp.x * (0.18 + float(b_i) * 0.16) + _global_time * (14.0 + float(b_i) * 2.5), vp.x + 80.0) - 40.0
		var by: float = vp.y * (0.28 + float(b_i % 3) * 0.065) + sin(_global_time * 2.0 + float(b_i) * 1.4) * 5.0
		var flap: float = sin(_global_time * 4.2 + float(b_i) * 1.7) * 4.5
		var span: float = 10.0 - float(b_i % 3) * 2.0
		var gull_col: Color = Color(0.26, 0.16, 0.24, 0.72)
		stage_canvas.draw_polyline(PackedVector2Array([
			Vector2(bx - span, by - flap),
			Vector2(bx, by + 2.0),
			Vector2(bx + span, by - flap),
		]), gull_col, 1.8, true)

	# 3. Radiant low sunset disc & layered peach-gold halo
	var sun_y: float = horizon_y - 24.0 if not _sea_choice_made else horizon_y + 4.0
	_draw_soft_glow(Vector2(cx, sun_y), 210.0, Color(1.0, 0.72, 0.42, 0.36))
	_draw_soft_glow(Vector2(cx, sun_y), 110.0, Color(1.0, 0.88, 0.58, 0.45))
	stage_canvas.draw_circle(Vector2(cx, sun_y), 42.0, Color(1.0, 0.95, 0.78, 0.95))

	# 4. Deep ocean base
	stage_canvas.draw_rect(Rect2(0.0, horizon_y, vp.x, vp.y - horizon_y), Color(0.22, 0.17, 0.34, 0.94), true)

	# 5. Six soft animated parallax ocean wave layers + shimmering golden sun path woven across them
	for layer_i: int in range(6):
		var lt: float = float(layer_i) / 5.0
		var base_y: float = lerpf(horizon_y + 12.0, vp.y * 0.84, lt)
		var amp: float = lerpf(3.0, 9.5, lt)
		var wave_col: Color = Color(0.32, 0.22, 0.40, 0.62).lerp(Color(0.08, 0.09, 0.20, 0.94), lt)
		var crest_col: Color = Color(1.0, 0.80, 0.52, lerpf(0.54, 0.22, lt))
		var poly: PackedVector2Array = PackedVector2Array()
		var crest: PackedVector2Array = PackedVector2Array()
		poly.append(Vector2(0.0, vp.y))
		for seg: int in range(37):
			var st: float = float(seg) / 36.0
			var wx: float = st * vp.x
			var wy: float = base_y + sin(st * TAU * (2.4 + lt * 1.1) + _global_time * (0.75 + lt * 0.32) + float(layer_i) * 1.2) * amp
			poly.append(Vector2(wx, wy))
			crest.append(Vector2(wx, wy))
		poly.append(Vector2(vp.x, vp.y))
		stage_canvas.draw_colored_polygon(poly, wave_col)
		stage_canvas.draw_polyline(crest, crest_col, 1.8, true)

		# Reflected golden sun shimmer bars between waves
		for s_k: int in range(3):
			var rt: float = clampf((float(layer_i * 3 + s_k)) / 17.0, 0.0, 1.0)
			var ry: float = lerpf(horizon_y + 7.0, vp.y * 0.83, rt)
			var bar_w: float = lerpf(104.0, 22.0, rt) + sin(_global_time * 2.3 + float(layer_i * 3 + s_k) * 0.9) * 16.0
			var rx: float = cx + sin(_global_time * 1.4 + float(layer_i * 3 + s_k) * 1.3) * (6.0 + rt * 15.0)
			stage_canvas.draw_line(
				Vector2(rx - bar_w * 0.5, ry),
				Vector2(rx + bar_w * 0.5, ry),
				Color(1.0, 0.88, 0.56, lerpf(0.76, 0.24, rt)),
				lerpf(2.8, 5.0, rt),
				true
			)

	# 6. Warm foreground sunset shore & three Pixar silhouettes holding hands with golden rim light
	var shore_y: float = vp.y * 0.85
	stage_canvas.draw_rect(Rect2(0.0, shore_y, vp.x, vp.y - shore_y), Color(0.07, 0.06, 0.13, 0.98), true)
	stage_canvas.draw_line(Vector2(0.0, shore_y), Vector2(vp.x, shore_y), Color(1.0, 0.78, 0.48, 0.36), 2.0, true)

	var m_x: float = cx - 68.0
	var c_x: float = cx
	var f_x: float = cx + 68.0
	var rim_gold: Color = Color(1.0, 0.88, 0.54, 0.90)

	# Warm radiant aura around the three holding hands
	_draw_soft_glow(Vector2(c_x, shore_y - 44.0), 82.0, Color(1.0, 0.82, 0.46, 0.28))

	# Mother (left, warm terracotta-plum tone in sunset silhouette + golden rim)
	_draw_sea_pixar_figure(Vector2(m_x, shore_y + 8.0), 120.0, 23.0, Color(0.24, 0.12, 0.16, 0.98), rim_gold, true, 0.0)
	# Child (7 years old, center, warm amber glow + golden rim)
	_draw_sea_pixar_figure(Vector2(c_x, shore_y + 8.0), 70.0, 14.5, Color(0.32, 0.20, 0.14, 0.98), Color(1.0, 0.94, 0.68, 0.96), false, 1.3)
	# Father (right, deep indigo-sage tone + golden rim)
	_draw_sea_pixar_figure(Vector2(f_x, shore_y + 8.0), 134.0, 26.0, Color(0.10, 0.13, 0.22, 0.98), rim_gold, false, 2.4)

	# Joined hands between Mother-Child and Child-Father with golden highlight
	var hand_l_a: Vector2 = Vector2(m_x + 14.0, shore_y - 54.0)
	var hand_l_b: Vector2 = Vector2(c_x - 10.0, shore_y - 36.0)
	var hand_r_a: Vector2 = Vector2(c_x + 10.0, shore_y - 36.0)
	var hand_r_b: Vector2 = Vector2(f_x - 16.0, shore_y - 58.0)
	stage_canvas.draw_line(hand_l_a, hand_l_b, Color(0.16, 0.10, 0.14, 0.98), 6.0, true)
	stage_canvas.draw_line(hand_r_a, hand_r_b, Color(0.14, 0.12, 0.18, 0.98), 6.0, true)
	stage_canvas.draw_line(hand_l_a + Vector2(0.0, -2.0), hand_l_b + Vector2(0.0, -2.0), rim_gold, 1.8, true)
	stage_canvas.draw_line(hand_r_a + Vector2(0.0, -2.0), hand_r_b + Vector2(0.0, -2.0), rim_gold, 1.8, true)


func _draw_sunset_cloud(pos: Vector2, scale_f: float) -> void:
	var shadow_c: Color = Color(0.46, 0.25, 0.38, 0.44)
	var lit_c: Color = Color(1.0, 0.78, 0.56, 0.48)
	_draw_ellipse_poly(pos + Vector2(0.0, 8.0 * scale_f), 84.0 * scale_f, 22.0 * scale_f, shadow_c, 22)
	_draw_ellipse_poly(pos + Vector2(-42.0 * scale_f, 6.0 * scale_f), 46.0 * scale_f, 18.0 * scale_f, shadow_c, 18)
	_draw_ellipse_poly(pos + Vector2(46.0 * scale_f, 7.0 * scale_f), 48.0 * scale_f, 17.0 * scale_f, shadow_c, 18)
	# Sunlit coral-gold cloud crown
	_draw_ellipse_poly(pos + Vector2(-12.0 * scale_f, -6.0 * scale_f), 54.0 * scale_f, 19.0 * scale_f, lit_c, 20)
	_draw_ellipse_poly(pos + Vector2(28.0 * scale_f, -4.0 * scale_f), 42.0 * scale_f, 16.0 * scale_f, lit_c, 18)


func _draw_sea_pixar_figure(foot_pos: Vector2, height: float, half_w: float, col: Color, rim_col: Color, has_dress: bool, phase: float) -> void:
	var breath: float = sin(_global_time * 1.4 + phase) * 1.6
	var breeze: float = sin(_global_time * 1.9 + phase) * 4.0
	var skirt_extra: float = 16.0 if has_dress else 0.0
	var top_y: float = -height + breath
	var body: PackedVector2Array = PackedVector2Array([
		foot_pos + Vector2(-half_w - skirt_extra + (breeze if has_dress else 0.0), 0.0),
		foot_pos + Vector2(-half_w * 0.78, top_y),
		foot_pos + Vector2(half_w * 0.78, top_y),
		foot_pos + Vector2(half_w + skirt_extra + (breeze * 0.6 if has_dress else 0.0), 0.0),
	])
	stage_canvas.draw_colored_polygon(body, col)
	_draw_ellipse_poly(foot_pos + Vector2(0.0, top_y + 4.0), half_w * 0.84, 11.0, col, 18)
	var head_r: float = half_w * 0.70
	var head_c: Vector2 = foot_pos + Vector2(0.0, top_y - head_r * 1.15)
	stage_canvas.draw_circle(head_c, head_r, col)
	if has_dress:
		stage_canvas.draw_circle(head_c + Vector2(-head_r * 0.9, -head_r * 0.25), head_r * 0.52, col)
	# Crisp golden sunset rim light along upper head & shoulders
	stage_canvas.draw_arc(head_c, head_r + 1.0, PI + 0.15, TAU - 0.15, 18, rim_col, 2.4, true)
	stage_canvas.draw_arc(foot_pos + Vector2(0.0, top_y + 4.0), half_w * 0.84, PI + 0.20, TAU - 0.20, 14, Color(rim_col.r, rim_col.g, rim_col.b, rim_col.a * 0.78), 2.2, true)


# =============================================================================
# CHAPTER 3 — «ВОСЬМАЯ ЗИМА» (PIXAR "SOUL" / "COCO" MOONLIT BEDROOM)
# =============================================================================

func _draw_ch3_eighth_winter(vp: Vector2) -> void:
	var center: Vector2 = Vector2(vp.x * 0.5, vp.y * 0.50)
	var left_palm: Vector2 = Vector2(vp.x * 0.28, vp.y * 0.53)
	var right_palm: Vector2 = Vector2(vp.x * 0.72, vp.y * 0.53)

	# 1. Soft moonlit bedroom window in upper-right with gentle silver snow outside
	var win_rect: Rect2 = Rect2(vp.x * 0.72, vp.y * 0.08, vp.x * 0.19, vp.y * 0.30)
	stage_canvas.draw_rect(win_rect, Color(0.08, 0.14, 0.28, 0.72), true)
	# Crescent moon visible outside the bedroom window
	var moon_c: Vector2 = Vector2(win_rect.position.x + win_rect.size.x * 0.72, win_rect.position.y + win_rect.size.y * 0.30)
	_draw_soft_glow(moon_c, 42.0, Color(0.80, 0.88, 1.0, 0.28))
	stage_canvas.draw_circle(moon_c, 13.0, Color(0.94, 0.96, 1.0, 0.90))
	stage_canvas.draw_circle(moon_c + Vector2(-5.5, -3.0), 11.5, Color(0.08, 0.14, 0.28, 0.95))
	# Window frame cross
	var wf_col: Color = Color(0.24, 0.34, 0.52, 0.65)
	stage_canvas.draw_rect(win_rect, wf_col, false, 3.0)
	stage_canvas.draw_line(Vector2(win_rect.position.x + win_rect.size.x * 0.5, win_rect.position.y), Vector2(win_rect.position.x + win_rect.size.x * 0.5, win_rect.position.y + win_rect.size.y), wf_col, 2.2, true)
	stage_canvas.draw_line(Vector2(win_rect.position.x, win_rect.position.y + win_rect.size.y * 0.5), Vector2(win_rect.position.x + win_rect.size.x, win_rect.position.y + win_rect.size.y * 0.5), wf_col, 2.2, true)

	# 2. Diagonal silver moonbeam streaming from the bedroom window
	var moonbeam: PackedVector2Array = PackedVector2Array([
		Vector2(win_rect.position.x, win_rect.position.y + win_rect.size.y * 0.25),
		Vector2(win_rect.position.x + win_rect.size.x, win_rect.position.y + win_rect.size.y * 0.85),
		Vector2(vp.x * 0.54, vp.y),
		Vector2(vp.x * 0.22, vp.y),
	])
	stage_canvas.draw_colored_polygon(moonbeam, Color(0.76, 0.86, 1.0, 0.065))

	# 3. Delicate hanging starry crib/bed mobile swaying softly overhead
	_draw_ch3_star_mobile(Vector2(vp.x * 0.50, vp.y * 0.19))

	# 4. Soft silhouette of cozy bed blanket along lower edge
	var blanket: PackedVector2Array = PackedVector2Array()
	blanket.append(Vector2(0.0, vp.y))
	for bi: int in range(17):
		var bt: float = float(bi) / 16.0
		var bx: float = bt * vp.x
		var by: float = vp.y * 0.84 - sin(bt * PI) * 26.0
		blanket.append(Vector2(bx, by))
	blanket.append(Vector2(vp.x, vp.y))
	stage_canvas.draw_colored_polygon(blanket, Color(0.05, 0.08, 0.16, 0.88))

	# 5. Parents' warm volumetric cupped hands on left & right (glowing brighter as transfer progresses)
	var palm_glow: float = 0.20 + _ch3_transfer * 0.80
	_draw_soft_glow(left_palm, 108.0 + 76.0 * _ch3_transfer, Color(1.0, 0.82, 0.44, 0.38 * palm_glow))
	_draw_soft_glow(right_palm, 108.0 + 76.0 * _ch3_transfer, Color(1.0, 0.82, 0.44, 0.38 * palm_glow))
	_draw_cupped_hand(left_palm, 1.0, palm_glow)
	_draw_cupped_hand(right_palm, -1.0, palm_glow)

	# 6. Delicate golden transfer threads & particles flowing from child's heart to parents' palms
	if _ch3_holding and not _ch3_final_sequence:
		var thread_col: Color = Color(1.0, 0.89, 0.56, 0.44)
		_draw_curved_thread(center, left_palm, -28.0, thread_col)
		_draw_curved_thread(center, left_palm, 24.0, thread_col)
		_draw_curved_thread(center, right_palm, -28.0, thread_col)
		_draw_curved_thread(center, right_palm, 24.0, thread_col)

	for sp: Dictionary in _ch3_stream_particles:
		var t: float = float(sp["t"])
		var side: float = float(sp["side"])
		var target_p: Vector2 = right_palm if side > 0.0 else left_palm
		var mid_p: Vector2 = (center + target_p) * 0.5 + Vector2(0.0, float(sp["arc"]))
		var q0: Vector2 = center.lerp(mid_p, t)
		var q1: Vector2 = mid_p.lerp(target_p, t)
		var pos: Vector2 = q0.lerp(q1, t)
		var a: float = sin(t * PI)
		var psz: float = float(sp["size"])
		stage_canvas.draw_circle(pos, psz * 2.0, Color(1.0, 0.84, 0.46, a * 0.30))
		stage_canvas.draw_circle(pos, psz, Color(1.0, 0.95, 0.72, a * 0.94))

	# 7. Child's luminous heart-light in center (becomes softer, smaller & weightless as warmth is given)
	var heart_pos: Vector2 = center + Vector2(0.0, -_ch3_ember_rise - _ch3_transfer * 18.0)
	var remaining: float = clampf(1.0 - _ch3_transfer * 0.78, 0.16, 1.0)
	var beat_scale: float = 1.0 + _ch3_heartbeat_pulse * 0.16 * remaining
	var base_r: float = lerpf(44.0, 15.0, _ch3_transfer) * beat_scale
	var fade_final: float = clampf(1.0 - _ch3_ember_rise * 0.012, 0.0, 1.0)

	_draw_soft_glow(heart_pos, base_r * 4.0, Color(1.0, 0.84, 0.46, 0.40 * remaining * fade_final))
	stage_canvas.draw_circle(heart_pos, base_r * 0.62, Color(1.0, 0.94, 0.72, 0.88 * remaining * fade_final))
	stage_canvas.draw_circle(heart_pos, base_r * 0.30, Color(1.0, 0.99, 0.94, 0.98 * fade_final))

	# Quiet circular progress arc around the heart while holding
	if not _ch3_final_sequence and _ch3_transfer > 0.01:
		stage_canvas.draw_arc(
			heart_pos,
			66.0,
			-PI * 0.5,
			-PI * 0.5 + TAU * _ch3_transfer,
			48,
			Color(1.0, 0.89, 0.56, 0.62),
			2.4,
			true
		)


func _draw_ch3_star_mobile(anchor: Vector2) -> void:
	var sway: float = sin(_global_time * 0.85) * 8.0
	var string_col: Color = Color(0.76, 0.84, 0.98, 0.42)
	var gold_charm: Color = Color(1.0, 0.90, 0.60, 0.86)
	var silver_charm: Color = Color(0.84, 0.92, 1.0, 0.82)

	# Suspension thread & curved wooden mobile arch
	stage_canvas.draw_line(Vector2(anchor.x, 24.0), anchor + Vector2(sway * 0.3, 0.0), string_col, 1.5, true)
	var bar_l: Vector2 = anchor + Vector2(-78.0 + sway * 0.6, 16.0)
	var bar_r: Vector2 = anchor + Vector2(78.0 + sway * 0.6, 16.0)
	stage_canvas.draw_line(bar_l, anchor + Vector2(sway * 0.3, 0.0), Color(0.68, 0.76, 0.90, 0.55), 2.4, true)
	stage_canvas.draw_line(anchor + Vector2(sway * 0.3, 0.0), bar_r, Color(0.68, 0.76, 0.90, 0.55), 2.4, true)

	# Center crescent charm
	var c_end: Vector2 = anchor + Vector2(sway * 0.9, 58.0)
	stage_canvas.draw_line(anchor + Vector2(sway * 0.3, 0.0), c_end, string_col, 1.2, true)
	_draw_soft_glow(c_end, 20.0, Color(1.0, 0.90, 0.58, 0.24))
	stage_canvas.draw_circle(c_end, 9.0, gold_charm)
	stage_canvas.draw_circle(c_end + Vector2(4.0, -2.0), 7.8, Color(0.05, 0.09, 0.18, 0.94))

	# Four swaying twinkling stars
	var star_xs: Array[float] = [-74.0, -34.0, 34.0, 74.0]
	var star_lens: Array[float] = [44.0, 62.0, 56.0, 40.0]
	for s_i: int in range(4):
		var sx: float = star_xs[s_i]
		var top_p: Vector2 = anchor + Vector2(sx + sway * 0.5, 16.0 * (absf(sx) / 78.0))
		var bob: float = sin(_global_time * 1.4 + float(s_i) * 1.5) * 4.5
		var end_p: Vector2 = top_p + Vector2(bob, star_lens[s_i])
		stage_canvas.draw_line(top_p, end_p, string_col, 1.1, true)
		var col: Color = gold_charm if (s_i % 2 == 0) else silver_charm
		_draw_four_point_star(end_p, 6.5 if (s_i % 2 == 0) else 5.2, col)


func _draw_four_point_star(pos: Vector2, rad: float, col: Color) -> void:
	var inner: float = rad * 0.32
	var pts: PackedVector2Array = PackedVector2Array([
		pos + Vector2(0.0, -rad),
		pos + Vector2(inner, -inner),
		pos + Vector2(rad, 0.0),
		pos + Vector2(inner, inner),
		pos + Vector2(0.0, rad),
		pos + Vector2(-inner, inner),
		pos + Vector2(-rad, 0.0),
		pos + Vector2(-inner, -inner),
	])
	stage_canvas.draw_colored_polygon(pts, col)


func _draw_cupped_hand(palm_pos: Vector2, facing_dir: float, warmth_glow: float) -> void:
	# Soft volumetric Pixar-style cupped palm & rounded fingers with warm inner glow
	var rim_col: Color = Color(0.72, 0.84, 0.98, 0.62).lerp(Color(1.0, 0.90, 0.56, 0.96), warmth_glow)
	var fill_col: Color = Color(0.14, 0.20, 0.34, 0.88).lerp(Color(0.62, 0.40, 0.28, 0.90), warmth_glow)
	var inner_lit: Color = Color(0.28, 0.38, 0.54, 0.55).lerp(Color(0.98, 0.78, 0.46, 0.78), warmth_glow)

	# Forearm / wrist entering gently from screen side
	var wrist_far: Vector2 = palm_pos + Vector2(-facing_dir * 160.0, 56.0)
	var wrist_near: Vector2 = palm_pos + Vector2(-facing_dir * 42.0, 22.0)
	stage_canvas.draw_line(wrist_far, wrist_near, fill_col, 30.0, true)
	stage_canvas.draw_line(wrist_far + Vector2(0.0, -14.0), wrist_near + Vector2(0.0, -14.0), rim_col, 2.2, true)

	# Rounded palm cushion
	_draw_ellipse_poly(palm_pos + Vector2(-facing_dir * 8.0, 12.0), 42.0, 24.0, fill_col, 22, facing_dir * -0.18)
	_draw_ellipse_poly(palm_pos + Vector2(facing_dir * 4.0, 4.0), 28.0, 13.0, inner_lit, 18, facing_dir * -0.15)

	# Soft curled fingers cradling the warmth
	var f1_a: Vector2 = palm_pos + Vector2(facing_dir * 18.0, 16.0)
	var f1_b: Vector2 = palm_pos + Vector2(facing_dir * 54.0, 6.0)
	var f2_a: Vector2 = palm_pos + Vector2(facing_dir * 20.0, 4.0)
	var f2_b: Vector2 = palm_pos + Vector2(facing_dir * 58.0, -10.0)
	var th_a: Vector2 = palm_pos + Vector2(-facing_dir * 8.0, -4.0)
	var th_b: Vector2 = palm_pos + Vector2(facing_dir * 22.0, -28.0)

	stage_canvas.draw_line(f1_a, f1_b, fill_col, 13.0, true)
	stage_canvas.draw_circle(f1_b, 6.5, fill_col)
	stage_canvas.draw_line(f2_a, f2_b, fill_col.lightened(0.08), 12.0, true)
	stage_canvas.draw_circle(f2_b, 6.0, fill_col.lightened(0.08))
	stage_canvas.draw_line(th_a, th_b, fill_col.lightened(0.12), 12.0, true)
	stage_canvas.draw_circle(th_b, 6.0, fill_col.lightened(0.12))

	# Golden rim highlight along upper thumb & fingertips
	stage_canvas.draw_line(th_a + Vector2(0.0, -5.0), th_b + Vector2(0.0, -4.0), rim_col, 2.4, true)
	stage_canvas.draw_line(f2_a + Vector2(0.0, -5.0), f2_b + Vector2(0.0, -4.0), rim_col, 2.2, true)
	stage_canvas.draw_circle(f2_b, 6.4, Color(rim_col.r, rim_col.g, rim_col.b, 0.45))


func _draw_curved_thread(a: Vector2, b: Vector2, bend_y: float, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var mid: Vector2 = (a + b) * 0.5 + Vector2(0.0, bend_y + sin(_global_time * 3.0) * 6.0)
	for i: int in range(17):
		var t: float = float(i) / 16.0
		var p: Vector2 = a.lerp(mid, t).lerp(mid.lerp(b, t), t)
		pts.append(p)
	stage_canvas.draw_polyline(pts, col, 2.2, true)


# =============================================================================
# CHAPTER 4 — «РАЗЛОМ И ДВЕ РУКИ В ТЕМНОТЕ» (TANGLED LANTERNS & TWO HANDS)
# =============================================================================

func _draw_ch4_two_hands(vp: Vector2) -> void:
	var cy: float = vp.y * 0.55
	var cx: float = vp.x * 0.5
	var u: float = _ch4_unite_anim
	var ease_u: float = u * u * (3.0 - 2.0 * u)

	# 1. Velvet night stars twinkling softly in the background
	for st_i: int in range(36):
		var sx: float = fmod(float(st_i * 197 + 53), 1240.0) / 1240.0 * vp.x
		var sy: float = fmod(float(st_i * 113 + 29), 520.0) / 720.0 * vp.y + 30.0
		var tw: float = 0.35 + 0.65 * sin(_global_time * 1.8 + float(st_i) * 1.3)
		stage_canvas.draw_circle(Vector2(sx, sy), 1.4 + float(st_i % 3) * 0.6, Color(0.95, 0.94, 1.0, 0.36 * tw))

	# 2. Two warmly rendered reaching hands (Mother left, Father right) finding & clasping each other
	var half_gap: float = lerpf(92.0, -10.0, ease_u)
	var tremble: float = lerpf(4.8, 0.4, ease_u)
	var l_trem: Vector2 = Vector2(0.0, sin(_global_time * 4.4) * tremble)
	var r_trem: Vector2 = Vector2(0.0, cos(_global_time * 4.0) * tremble)

	var left_hand_p: Vector2 = Vector2(cx - half_gap - 28.0, cy) + l_trem
	var right_hand_p: Vector2 = Vector2(cx + half_gap + 28.0, cy) + r_trem

	var mother_glow: Color = Color(0.98, 0.74, 0.66, 0.85).lerp(COLOR_GOLD, ease_u)
	var father_glow: Color = Color(0.74, 0.84, 1.0, 0.85).lerp(COLOR_GOLD, ease_u)

	_draw_ch4_reaching_hand(left_hand_p, 1.0, mother_glow, ease_u, true)
	_draw_ch4_reaching_hand(right_hand_p, -1.0, father_glow, ease_u, false)

	# Warm radiant clasp glow at the fingertips / joined palms
	var clasp_c: Vector2 = Vector2(cx, cy)
	if not _ch4_united:
		_draw_soft_glow(left_hand_p + Vector2(46.0, -2.0), 42.0, Color(mother_glow.r, mother_glow.g, mother_glow.b, 0.38))
		_draw_soft_glow(right_hand_p + Vector2(-46.0, -2.0), 42.0, Color(father_glow.r, father_glow.g, father_glow.b, 0.38))
	else:
		_draw_soft_glow(clasp_c, 220.0 * ease_u, Color(1.0, 0.86, 0.48, 0.50 * ease_u))
		_draw_soft_glow(clasp_c, 92.0 * ease_u, Color(1.0, 0.96, 0.80, 0.62 * ease_u))

	# 3. Tangled-style ascending stream of golden lanterns & petals carrying the Soul upward
	if _ch4_united:
		for pt: Dictionary in _ch4_vortex_petals:
			var ang: float = float(pt["angle"])
			var rad: float = float(pt["radius"])
			var y_off: float = float(pt["y_off"])
			var sz: float = float(pt["size"])
			var a: float = float(pt["alpha"])
			var px: float = cx + cos(ang) * rad
			var py: float = cy - y_off + sin(ang) * rad * 0.24
			var is_lantern: bool = bool(pt.get("is_lantern", false))

			if is_lantern:
				var bob_x: float = sin(_global_time * 2.2 + float(pt.get("bob_phase", 0.0))) * 6.0
				_draw_tangled_lantern(Vector2(px + bob_x, py), sz, a)
			else:
				var p_col: Color = Color(1.0, 0.90, 0.56, a * 0.92)
				var dir: Vector2 = Vector2(cos(ang), sin(ang))
				var perp: Vector2 = Vector2(-dir.y, dir.x)
				var petal_poly: PackedVector2Array = PackedVector2Array([
					Vector2(px, py) + dir * sz * 1.45,
					Vector2(px, py) + perp * sz * 0.58,
					Vector2(px, py) - dir * sz * 1.15,
					Vector2(px, py) - perp * sz * 0.58,
				])
				stage_canvas.draw_colored_polygon(petal_poly, p_col)


func _draw_ch4_reaching_hand(palm_p: Vector2, dir_sign: float, glow_col: Color, unite_t: float, is_mother: bool) -> void:
	var fill_base: Color = Color(0.32, 0.20, 0.22, 0.94) if is_mother else Color(0.16, 0.22, 0.34, 0.94)
	var fill_col: Color = fill_base.lerp(Color(0.76, 0.54, 0.34, 0.96), 0.25 + unite_t * 0.75)
	var rim_col: Color = Color(glow_col.r, glow_col.g, glow_col.b, 0.92)
	var arm_thick: float = 22.0 if is_mother else 27.0

	# Soft aura behind the arm & hand
	_draw_soft_glow(palm_p + Vector2(dir_sign * 16.0, 0.0), 68.0 + 36.0 * unite_t, Color(glow_col.r, glow_col.g, glow_col.b, 0.22))

	# Arm reaching in from edge of darkness
	var arm_start: Vector2 = palm_p + Vector2(-dir_sign * 520.0, 26.0)
	var wrist_p: Vector2 = palm_p + Vector2(-dir_sign * 34.0, 6.0)
	stage_canvas.draw_line(arm_start, wrist_p, fill_col, arm_thick, true)
	stage_canvas.draw_line(arm_start + Vector2(0.0, -arm_thick * 0.45), wrist_p + Vector2(0.0, -arm_thick * 0.45), rim_col, 2.2, true)

	# Rounded palm
	_draw_ellipse_poly(palm_p, 34.0 if is_mother else 38.0, 19.0 if is_mother else 22.0, fill_col, 20)

	# Expressive reaching / intertwining fingers
	var curl: float = unite_t * 10.0
	var f_top: Vector2 = palm_p + Vector2(dir_sign * 52.0, -10.0 + curl * 0.5)
	var f_mid: Vector2 = palm_p + Vector2(dir_sign * 56.0, 2.0 + curl * 0.3)
	var f_low: Vector2 = palm_p + Vector2(dir_sign * 46.0, 14.0 - curl * 0.2)
	var thumb_p: Vector2 = palm_p + Vector2(dir_sign * 20.0, -24.0 + curl * 0.6)

	var f_w: float = 9.0 if is_mother else 11.0
	stage_canvas.draw_line(palm_p + Vector2(dir_sign * 14.0, -8.0), f_top, fill_col.lightened(0.08), f_w, true)
	stage_canvas.draw_circle(f_top, f_w * 0.5, fill_col.lightened(0.08))
	stage_canvas.draw_line(palm_p + Vector2(dir_sign * 16.0, 2.0), f_mid, fill_col.lightened(0.04), f_w, true)
	stage_canvas.draw_circle(f_mid, f_w * 0.5, fill_col.lightened(0.04))
	stage_canvas.draw_line(palm_p + Vector2(dir_sign * 12.0, 10.0), f_low, fill_col, f_w * 0.9, true)
	stage_canvas.draw_circle(f_low, f_w * 0.45, fill_col)
	stage_canvas.draw_line(palm_p + Vector2(-dir_sign * 4.0, -8.0), thumb_p, fill_col.lightened(0.10), f_w, true)
	stage_canvas.draw_circle(thumb_p, f_w * 0.5, fill_col.lightened(0.10))

	# Luminous golden rim along upper contour & fingertips
	stage_canvas.draw_line(palm_p + Vector2(-dir_sign * 4.0, -12.0), thumb_p + Vector2(0.0, -4.0), rim_col, 2.2, true)
	stage_canvas.draw_line(palm_p + Vector2(dir_sign * 14.0, -12.0), f_top + Vector2(0.0, -3.5), rim_col, 2.2, true)
	stage_canvas.draw_circle(f_mid, 3.6, Color(1.0, 0.96, 0.84, 0.85))


func _draw_tangled_lantern(pos: Vector2, sz: float, alpha: float) -> void:
	# Soft outer Tangled halo
	_draw_soft_glow(pos, sz * 3.0, Color(1.0, 0.78, 0.34, 0.30 * alpha))
	# Rounded warm paper lantern body
	var body: PackedVector2Array = PackedVector2Array([
		pos + Vector2(-sz * 0.65, -sz * 0.85),
		pos + Vector2(sz * 0.65, -sz * 0.85),
		pos + Vector2(sz * 0.48, sz * 0.80),
		pos + Vector2(-sz * 0.48, sz * 0.80),
	])
	stage_canvas.draw_colored_polygon(body, Color(0.98, 0.70, 0.28, 0.86 * alpha))
	# Bright glowing flame core at the base of the lantern
	_draw_ellipse_poly(pos + Vector2(0.0, sz * 0.18), sz * 0.42, sz * 0.50, Color(1.0, 0.95, 0.70, 0.92 * alpha), 12)
	stage_canvas.draw_circle(pos + Vector2(0.0, sz * 0.38), sz * 0.24, Color(1.0, 1.0, 0.92, 0.98 * alpha))
	# Subtle top rim
	stage_canvas.draw_line(pos + Vector2(-sz * 0.65, -sz * 0.85), pos + Vector2(sz * 0.65, -sz * 0.85), Color(0.72, 0.42, 0.18, 0.72 * alpha), 1.5, true)


func _draw_child_spark() -> void:
	# Graceful Pixar golden firefly-spark with luminous ribbon trail
	var n: int = _spark_trail.size()
	for i: int in range(n):
		var t: float = float(i) / maxf(float(n), 1.0)
		stage_canvas.draw_circle(_spark_trail[i], 2.2 + t * 5.8, Color(1.0, 0.88, 0.52, t * 0.38))

	var pulse: float = 1.0 + 0.12 * sin(_global_time * 4.2)
	_draw_soft_glow(_spark_pos, 38.0 * pulse, Color(1.0, 0.84, 0.44, 0.42))
	stage_canvas.draw_circle(_spark_pos, 8.0 * pulse, Color(1.0, 0.94, 0.68, 0.94))
	stage_canvas.draw_circle(_spark_pos, 4.0, Color(1.0, 0.99, 0.95, 1.0))


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
	# Warm velvet storytelling narration card with gentle golden Pixar glow & crisp legibility
	var narr_box: StyleBoxFlat = StyleBoxFlat.new()
	narr_box.bg_color = Color(0.055, 0.068, 0.138, 0.72)
	narr_box.border_color = Color(0.988, 0.855, 0.490, 0.48)
	narr_box.border_width_top = 1
	narr_box.border_width_bottom = 1
	narr_box.border_width_left = 1
	narr_box.border_width_right = 1
	narr_box.set_corner_radius_all(12)
	narr_box.shadow_color = Color(0.98, 0.78, 0.36, 0.14)
	narr_box.shadow_size = 14
	narration_panel.add_theme_stylebox_override("panel", narr_box)

	# Keep hint labels cleanly inside the 24px cinema letterbox frame on 1280x720
	if esc_hint_label != null:
		esc_hint_label.offset_top = 30.0
		esc_hint_label.offset_bottom = 54.0
	if controls_hint_label != null:
		controls_hint_label.offset_top = -52.0
		controls_hint_label.offset_bottom = -28.0

	# Soft warm drop shadows on header & hints so text stays crisp over bright spring/sunset skies
	var text_shadow: Color = Color(0.02, 0.03, 0.07, 0.78)
	for lbl: Label in [chapter_roman_label, chapter_title_label, poetic_label, sub_poetic_label, controls_hint_label, esc_hint_label]:
		if lbl != null:
			lbl.add_theme_color_override("font_shadow_color", text_shadow)
			lbl.add_theme_constant_override("shadow_offset_x", 0)
			lbl.add_theme_constant_override("shadow_offset_y", 2)
			lbl.add_theme_constant_override("shadow_outline_size", 4)

	# Warm cinematic pause card
	var p_box: StyleBoxFlat = StyleBoxFlat.new()
	p_box.bg_color = Color(0.048, 0.066, 0.148, 0.95)
	p_box.border_color = COLOR_GOLD
	p_box.set_border_width_all(2)
	p_box.set_corner_radius_all(12)
	p_box.shadow_color = Color(0.98, 0.80, 0.40, 0.22)
	p_box.shadow_size = 26
	pause_card.add_theme_stylebox_override("panel", p_box)

	_apply_art_deco_button_theme(btn_resume)
	_apply_art_deco_button_theme(btn_mute)
	_apply_art_deco_button_theme(btn_main_menu)


func _create_art_deco_button(label_text: String, min_width: float) -> Button:
	var btn: Button = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(min_width, 46.0)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_art_deco_button_theme(btn)
	return btn


func _apply_art_deco_button_theme(btn: Button) -> void:
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", COLOR_IVORY)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.68, 1.0))
	btn.add_theme_color_override("font_pressed_color", COLOR_INDIGO)
	btn.add_theme_color_override("font_focus_color", Color(1.0, 0.94, 0.68, 1.0))

	var normal_s: StyleBoxFlat = StyleBoxFlat.new()
	normal_s.bg_color = Color(0.075, 0.098, 0.205, 0.86)
	normal_s.border_color = Color(0.98, 0.84, 0.46, 0.68)
	normal_s.set_border_width_all(1)
	normal_s.set_corner_radius_all(10)
	normal_s.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	normal_s.shadow_size = 8
	normal_s.content_margin_left = 22.0
	normal_s.content_margin_right = 22.0
	normal_s.content_margin_top = 11.0
	normal_s.content_margin_bottom = 11.0

	var hover_s: StyleBoxFlat = normal_s.duplicate() as StyleBoxFlat
	hover_s.bg_color = Color(0.16, 0.17, 0.30, 0.95)
	hover_s.border_color = COLOR_GOLD
	hover_s.set_border_width_all(2)
	hover_s.shadow_color = Color(1.0, 0.84, 0.44, 0.28)
	hover_s.shadow_size = 14

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
