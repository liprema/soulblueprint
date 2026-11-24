extends CanvasLayer

## Global scene transition, cinematic veil, epilogue overlay, and cutscene video manager
## for SoulBlueprint (Godot 4.3). Registered as Autoload `SceneFlowManager` (no class_name).

const INTRO_VIDEO_SCENE_PATH: String = "res://scenes/intro_video.tscn"
const WORLD_3D_SCENE_PATH: String = "res://scenes/world_3d.tscn"
const LESSON1_EARTH_SCENE_PATH: String = "res://scenes/lesson1/earth_life_lesson1.tscn"

const COLOR_INDIGO: Color = Color(0.027451, 0.078431, 0.180392, 1.0) # #07142E
const COLOR_INDIGO_BACKDROP: Color = Color(0.027451, 0.078431, 0.180392, 0.78)
const COLOR_INDIGO_CARD: Color = Color(0.027451, 0.078431, 0.180392, 0.95)
const COLOR_SUNSET_BACKDROP: Color = Color(0.090196, 0.054902, 0.078431, 0.76)
const COLOR_SUNSET_CARD: Color = Color(0.082353, 0.058824, 0.105882, 0.95)
const COLOR_GOLD: Color = Color(0.964706, 0.827451, 0.419608, 1.0) # #F6D36B
const COLOR_GOLD_SOFT: Color = Color(0.964706, 0.827451, 0.419608, 0.65)
const COLOR_GOLD_WARM: Color = Color(0.988235, 0.866667, 0.545098, 1.0) # #FCDD8B
const COLOR_IVORY: Color = Color(1.0, 0.964706, 0.8, 1.0) # #FFF6CC
const COLOR_IVORY_SOFT: Color = Color(1.0, 0.964706, 0.8, 0.92)
const COLOR_KRONOS_TEASER: Color = Color(0.901961, 0.784314, 0.541176, 0.86) # #E6C88A

const GOLD_VEIL_PEAK_ALPHA: float = 0.18

var pending_world_mode: String = ""

var _epilogue_overlay: Control = null
var _epilogue_divider: Control = null
var _epilogue_stats_label: Label = null
var _btn_continue: Button = null
var _btn_return_menu: Button = null

var _lesson1_epilogue_overlay: Control = null
var _lesson1_epilogue_divider: Control = null
var _lesson1_btn_continue: Button = null
var _lesson1_btn_return_menu: Button = null
var _lesson1_epilogue_tween: Tween = null
var _lesson1_on_continue_callback: Callable = Callable()
var _lesson1_on_return_menu_callback: Callable = Callable()

var _fade_veil: ColorRect = null
var _gold_veil: ColorRect = null

var _veil_tween: Tween = null
var _epilogue_tween: Tween = null
var _is_transitioning: bool = false

var _on_continue_callback: Callable = Callable()
var _on_return_menu_callback: Callable = Callable()

# Programmatic fallback video overlay state (used only if intro_video.tscn is unavailable)
var _fallback_video_root: Control = null
var _fallback_video_player: VideoStreamPlayer = null
var _fallback_video_callback: Callable = Callable()
var _fallback_video_active: bool = false


func _ready() -> void:
	layer = 100
	_build_epilogue_overlay()
	_build_lesson1_epilogue_overlay()
	_build_veils()


func _input(event: InputEvent) -> void:
	if not _fallback_video_active:
		return
	var is_skip: bool = event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")
	if not is_skip and event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			is_skip = (
				key_event.keycode == KEY_SPACE
				or key_event.keycode == KEY_ENTER
				or key_event.keycode == KEY_KP_ENTER
				or key_event.keycode == KEY_ESCAPE
			)
	if is_skip:
		get_viewport().set_input_as_handled()
		_finish_fallback_video()


func fade_to_veil(duration: float = 1.0, use_gold_veil: bool = true) -> void:
	if _veil_tween != null and _veil_tween.is_valid():
		_veil_tween.kill()

	_fade_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	var target_gold: float = GOLD_VEIL_PEAK_ALPHA if use_gold_veil else 0.0
	var safe_duration: float = maxf(0.0, duration)

	if safe_duration <= 0.0:
		_fade_veil.modulate.a = 1.0
		_gold_veil.modulate.a = target_gold
		return

	_veil_tween = create_tween()
	_veil_tween.set_parallel(true)
	_veil_tween.tween_property(_fade_veil, "modulate:a", 1.0, safe_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_veil_tween.tween_property(_gold_veil, "modulate:a", target_gold, safe_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _veil_tween.finished


func fade_from_veil(duration: float = 1.1) -> void:
	if _veil_tween != null and _veil_tween.is_valid():
		_veil_tween.kill()

	var safe_duration: float = maxf(0.0, duration)
	if safe_duration <= 0.0:
		_fade_veil.modulate.a = 0.0
		_gold_veil.modulate.a = 0.0
		_fade_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	_veil_tween = create_tween()
	_veil_tween.set_parallel(true)
	_veil_tween.tween_property(_fade_veil, "modulate:a", 0.0, safe_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_veil_tween.tween_property(_gold_veil, "modulate:a", 0.0, safe_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await _veil_tween.finished
	_fade_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE


func transition_to_scene(scene_path: String, use_gold_veil: bool = true) -> void:
	if _is_transitioning:
		return
	if scene_path.is_empty():
		push_warning("SceneFlowManager: transition_to_scene called with empty scene_path.")
		return

	_is_transitioning = true
	await fade_to_veil(0.85, use_gold_veil)
	_hide_epilogue_immediate()

	var change_err: Error = get_tree().change_scene_to_file(scene_path)
	if change_err != OK:
		push_warning("SceneFlowManager: failed to change scene to '%s' (err %d)." % [scene_path, change_err])

	await get_tree().process_frame
	await fade_from_veil(1.0)
	_is_transitioning = false


func show_prologue_epilogue(
	awakened_count: int,
	total_lanterns: int,
	on_continue_exploring: Callable,
	on_return_menu: Callable
) -> void:
	_on_continue_callback = on_continue_exploring
	_on_return_menu_callback = on_return_menu

	var safe_total: int = maxi(1, total_lanterns)
	var safe_awakened: int = clampi(awakened_count, 0, safe_total)
	_epilogue_stats_label.text = "Пробуждено фонарей света: %d из %d" % [safe_awakened, safe_total]

	if _epilogue_tween != null and _epilogue_tween.is_valid():
		_epilogue_tween.kill()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_epilogue_overlay.visible = true
	_epilogue_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_epilogue_overlay.modulate.a = 0.0
	_epilogue_divider.queue_redraw()

	_epilogue_tween = create_tween()
	_epilogue_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_epilogue_tween.tween_property(_epilogue_overlay, "modulate:a", 1.0, 0.85)


func hide_prologue_epilogue() -> void:
	if not _epilogue_overlay.visible:
		return

	if _epilogue_tween != null and _epilogue_tween.is_valid():
		_epilogue_tween.kill()

	_epilogue_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_epilogue_tween = create_tween()
	_epilogue_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_epilogue_tween.tween_property(_epilogue_overlay, "modulate:a", 0.0, 0.45)
	_epilogue_tween.tween_callback(func() -> void:
		_epilogue_overlay.visible = false
	)


func show_lesson1_epilogue(
	on_continue_exploring: Callable,
	on_return_menu: Callable
) -> void:
	_lesson1_on_continue_callback = on_continue_exploring
	_lesson1_on_return_menu_callback = on_return_menu

	if _lesson1_epilogue_tween != null and _lesson1_epilogue_tween.is_valid():
		_lesson1_epilogue_tween.kill()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_lesson1_epilogue_overlay.visible = true
	_lesson1_epilogue_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_lesson1_epilogue_overlay.modulate.a = 0.0
	_lesson1_epilogue_divider.queue_redraw()

	_lesson1_epilogue_tween = create_tween()
	_lesson1_epilogue_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_lesson1_epilogue_tween.tween_property(_lesson1_epilogue_overlay, "modulate:a", 1.0, 0.9)


func hide_lesson1_epilogue() -> void:
	if not _lesson1_epilogue_overlay.visible:
		return

	if _lesson1_epilogue_tween != null and _lesson1_epilogue_tween.is_valid():
		_lesson1_epilogue_tween.kill()

	_lesson1_epilogue_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lesson1_epilogue_tween = create_tween()
	_lesson1_epilogue_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_lesson1_epilogue_tween.tween_property(_lesson1_epilogue_overlay, "modulate:a", 0.0, 0.45)
	_lesson1_epilogue_tween.tween_callback(func() -> void:
		_lesson1_epilogue_overlay.visible = false
	)


func play_cutscene_video(video_path: String, on_finished: Callable) -> void:
	var loaded_stream: VideoStream = null
	if not video_path.is_empty():
		if not ResourceLoader.exists(video_path):
			push_warning("SceneFlowManager: cutscene video not found at '%s'." % video_path)
			_invoke_callable(on_finished)
			return
		var res: Resource = load(video_path)
		if res is VideoStream:
			loaded_stream = res as VideoStream
		else:
			push_warning("SceneFlowManager: resource at '%s' is not a VideoStream." % video_path)
			_invoke_callable(on_finished)
			return

	if ResourceLoader.exists(INTRO_VIDEO_SCENE_PATH):
		var packed_res: Resource = load(INTRO_VIDEO_SCENE_PATH)
		if packed_res is PackedScene:
			var packed: PackedScene = packed_res as PackedScene
			var instance: Node = packed.instantiate()
			if loaded_stream != null:
				var vp: VideoStreamPlayer = instance.get_node_or_null("VideoStreamPlayer") as VideoStreamPlayer
				if vp != null:
					vp.stream = loaded_stream
			if instance is CanvasLayer:
				var video_layer: CanvasLayer = instance as CanvasLayer
				video_layer.layer = 95
			if instance.has_signal("intro_completed"):
				instance.connect("intro_completed", func() -> void:
					_invoke_callable(on_finished)
				, CONNECT_ONE_SHOT)
			else:
				push_warning("SceneFlowManager: intro_video scene has no 'intro_completed' signal.")
				_invoke_callable(on_finished)
			add_child(instance)
			return

	if loaded_stream == null:
		push_warning("SceneFlowManager: cannot play cutscene video without a valid VideoStream.")
		_invoke_callable(on_finished)
		return

	_play_fallback_video_overlay(loaded_stream, on_finished)


func _build_veils() -> void:
	_fade_veil = ColorRect.new()
	_fade_veil.name = "FadeVeil"
	_fade_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_veil.color = COLOR_INDIGO
	_fade_veil.modulate.a = 0.0
	_fade_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_veil)

	_gold_veil = ColorRect.new()
	_gold_veil.name = "GoldVeil"
	_gold_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_gold_veil.color = COLOR_GOLD
	_gold_veil.modulate.a = 0.0
	_gold_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gold_veil)


func _build_epilogue_overlay() -> void:
	_epilogue_overlay = Control.new()
	_epilogue_overlay.name = "PrologueEpilogueOverlay"
	_epilogue_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_epilogue_overlay.visible = false
	_epilogue_overlay.modulate.a = 0.0
	_epilogue_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_epilogue_overlay)

	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "IndigoBackdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = COLOR_INDIGO_BACKDROP
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_epilogue_overlay.add_child(backdrop)

	var center: CenterContainer = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_epilogue_overlay.add_child(center)

	var card: PanelContainer = PanelContainer.new()
	card.name = "ArtDecoCard"
	card.custom_minimum_size = Vector2(680.0, 0.0)
	card.add_theme_stylebox_override("panel", _create_card_stylebox())
	center.add_child(card)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	card.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var subtitle_label: Label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.text = "П Р О Л О Г   З А В Е Р Ш Ё Н"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_color_override("font_color", COLOR_GOLD)
	subtitle_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(subtitle_label)

	var title_label: Label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Первый Контракт Заключён"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", COLOR_IVORY)
	title_label.add_theme_font_size_override("font_size", 34)
	vbox.add_child(title_label)

	_epilogue_divider = Control.new()
	_epilogue_divider.name = "ArtDecoDivider"
	_epilogue_divider.custom_minimum_size = Vector2(0.0, 18.0)
	_epilogue_divider.draw.connect(_draw_epilogue_divider)
	vbox.add_child(_epilogue_divider)

	var body_label: Label = Label.new()
	body_label.name = "BodyLabel"
	body_label.text = "«Впереди — семь весен, полных смеха, тепла и безусловной любви.\nТвой свет запомнит этот путь навсегда.»"
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_color_override("font_color", COLOR_IVORY_SOFT)
	body_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(body_label)

	_epilogue_stats_label = Label.new()
	_epilogue_stats_label.name = "StatsLabel"
	_epilogue_stats_label.text = "Пробуждено фонарей света: 0 из 9"
	_epilogue_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_epilogue_stats_label.add_theme_color_override("font_color", COLOR_GOLD)
	_epilogue_stats_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_epilogue_stats_label)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 8.0)
	vbox.add_child(spacer)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 20)
	vbox.add_child(button_row)

	_btn_continue = _create_art_deco_button("Продолжить полёт по Хроникам")
	_btn_continue.pressed.connect(_on_continue_pressed)
	button_row.add_child(_btn_continue)

	_btn_return_menu = _create_art_deco_button("Вернуться в главное меню")
	_btn_return_menu.pressed.connect(_on_return_menu_pressed)
	button_row.add_child(_btn_return_menu)


func _create_card_stylebox() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = COLOR_INDIGO_CARD
	box.border_color = COLOR_GOLD
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 4
	box.corner_radius_top_right = 4
	box.corner_radius_bottom_left = 4
	box.corner_radius_bottom_right = 4
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	box.shadow_size = 24
	return box


func _create_art_deco_button(label_text: String) -> Button:
	var btn: Button = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(265.0, 46.0)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", COLOR_IVORY)
	btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
	btn.add_theme_color_override("font_pressed_color", COLOR_INDIGO)
	btn.add_theme_color_override("font_focus_color", COLOR_GOLD)

	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.047059, 0.109804, 0.239216, 0.92)
	normal_style.border_color = COLOR_GOLD_SOFT
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(3)
	normal_style.content_margin_left = 18.0
	normal_style.content_margin_right = 18.0
	normal_style.content_margin_top = 10.0
	normal_style.content_margin_bottom = 10.0

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.098039, 0.172549, 0.321569, 0.96)
	hover_style.border_color = COLOR_GOLD
	hover_style.set_border_width_all(2)

	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = COLOR_GOLD
	pressed_style.border_color = COLOR_IVORY
	pressed_style.set_border_width_all(2)

	var focus_style: StyleBoxFlat = hover_style.duplicate() as StyleBoxFlat

	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("focus", focus_style)
	return btn


func _draw_epilogue_divider() -> void:
	var rect_size: Vector2 = _epilogue_divider.size
	var mid_y: float = rect_size.y * 0.5
	var center_x: float = rect_size.x * 0.5
	var half_span: float = minf(rect_size.x * 0.42, 220.0)
	var diamond_r: float = 5.0

	_epilogue_divider.draw_line(
		Vector2(center_x - half_span, mid_y),
		Vector2(center_x - diamond_r - 8.0, mid_y),
		COLOR_GOLD_SOFT,
		1.5,
		true
	)
	_epilogue_divider.draw_line(
		Vector2(center_x + diamond_r + 8.0, mid_y),
		Vector2(center_x + half_span, mid_y),
		COLOR_GOLD_SOFT,
		1.5,
		true
	)

	var diamond_points: PackedVector2Array = PackedVector2Array([
		Vector2(center_x, mid_y - diamond_r),
		Vector2(center_x + diamond_r, mid_y),
		Vector2(center_x, mid_y + diamond_r),
		Vector2(center_x - diamond_r, mid_y),
	])
	_epilogue_divider.draw_colored_polygon(diamond_points, COLOR_GOLD)


func _build_lesson1_epilogue_overlay() -> void:
	_lesson1_epilogue_overlay = Control.new()
	_lesson1_epilogue_overlay.name = "Lesson1EpilogueOverlay"
	_lesson1_epilogue_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lesson1_epilogue_overlay.visible = false
	_lesson1_epilogue_overlay.modulate.a = 0.0
	_lesson1_epilogue_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lesson1_epilogue_overlay)

	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "SunsetBackdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = COLOR_SUNSET_BACKDROP
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_lesson1_epilogue_overlay.add_child(backdrop)

	var center: CenterContainer = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lesson1_epilogue_overlay.add_child(center)

	var card: PanelContainer = PanelContainer.new()
	card.name = "Lesson1GoldCard"
	card.custom_minimum_size = Vector2(700.0, 0.0)
	card.add_theme_stylebox_override("panel", _create_sunset_card_stylebox())
	center.add_child(card)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 52)
	margin.add_theme_constant_override("margin_right", 52)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_bottom", 44)
	card.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var subtitle_label: Label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.text = "У Р О К   1   З А В Е Р Ш Ё Н"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_color_override("font_color", COLOR_GOLD_WARM)
	subtitle_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(subtitle_label)

	var title_label: Label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Опыт Безусловной Любви"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", COLOR_IVORY)
	title_label.add_theme_font_size_override("font_size", 34)
	vbox.add_child(title_label)

	_lesson1_epilogue_divider = Control.new()
	_lesson1_epilogue_divider.name = "Lesson1GoldDivider"
	_lesson1_epilogue_divider.custom_minimum_size = Vector2(0.0, 18.0)
	_lesson1_epilogue_divider.draw.connect(_draw_lesson1_epilogue_divider)
	vbox.add_child(_lesson1_epilogue_divider)

	var quote_label: Label = Label.new()
	quote_label.name = "QuoteLabel"
	quote_label.text = "«У тебя было всё, кроме времени — и этого хватило,\nчтобы чья-то долгая зима навсегда сменилась весной.»"
	quote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote_label.add_theme_color_override("font_color", COLOR_IVORY_SOFT)
	quote_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(quote_label)

	var teaser_label: Label = Label.new()
	teaser_label.name = "KronosTeaserLabel"
	teaser_label.text = "Вдали за северной колоннадой слышен мерный шаг Кроноса.\nВторой контракт уже ждёт своего часа…"
	teaser_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teaser_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teaser_label.add_theme_color_override("font_color", COLOR_KRONOS_TEASER)
	teaser_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(teaser_label)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 10.0)
	vbox.add_child(spacer)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 20)
	vbox.add_child(button_row)

	_lesson1_btn_continue = _create_art_deco_button("Продолжить полёт на закате")
	_lesson1_btn_continue.pressed.connect(_on_lesson1_continue_pressed)
	button_row.add_child(_lesson1_btn_continue)

	_lesson1_btn_return_menu = _create_art_deco_button("Вернуться в главное меню")
	_lesson1_btn_return_menu.pressed.connect(_on_lesson1_return_menu_pressed)
	button_row.add_child(_lesson1_btn_return_menu)


func _create_sunset_card_stylebox() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = COLOR_SUNSET_CARD
	box.border_color = COLOR_GOLD_WARM
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 4
	box.corner_radius_top_right = 4
	box.corner_radius_bottom_left = 4
	box.corner_radius_bottom_right = 4
	box.shadow_color = Color(0.964706, 0.827451, 0.419608, 0.16)
	box.shadow_size = 28
	return box


func _draw_lesson1_epilogue_divider() -> void:
	var rect_size: Vector2 = _lesson1_epilogue_divider.size
	var mid_y: float = rect_size.y * 0.5
	var center_x: float = rect_size.x * 0.5
	var half_span: float = minf(rect_size.x * 0.42, 230.0)
	var diamond_r: float = 5.5

	_lesson1_epilogue_divider.draw_line(
		Vector2(center_x - half_span, mid_y),
		Vector2(center_x - diamond_r - 8.0, mid_y),
		COLOR_GOLD_SOFT,
		1.5,
		true
	)
	_lesson1_epilogue_divider.draw_line(
		Vector2(center_x + diamond_r + 8.0, mid_y),
		Vector2(center_x + half_span, mid_y),
		COLOR_GOLD_SOFT,
		1.5,
		true
	)

	var diamond_points: PackedVector2Array = PackedVector2Array([
		Vector2(center_x, mid_y - diamond_r),
		Vector2(center_x + diamond_r, mid_y),
		Vector2(center_x, mid_y + diamond_r),
		Vector2(center_x - diamond_r, mid_y),
	])
	_lesson1_epilogue_divider.draw_colored_polygon(diamond_points, COLOR_GOLD_WARM)


func _on_continue_pressed() -> void:
	hide_prologue_epilogue()
	_invoke_callable(_on_continue_callback)


func _on_return_menu_pressed() -> void:
	hide_prologue_epilogue()
	_invoke_callable(_on_return_menu_callback)


func _on_lesson1_continue_pressed() -> void:
	hide_lesson1_epilogue()
	_invoke_callable(_lesson1_on_continue_callback)


func _on_lesson1_return_menu_pressed() -> void:
	hide_lesson1_epilogue()
	_invoke_callable(_lesson1_on_return_menu_callback)


func _hide_epilogue_immediate() -> void:
	if _epilogue_tween != null and _epilogue_tween.is_valid():
		_epilogue_tween.kill()
	if _epilogue_overlay != null:
		_epilogue_overlay.visible = false
		_epilogue_overlay.modulate.a = 0.0
		_epilogue_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _lesson1_epilogue_tween != null and _lesson1_epilogue_tween.is_valid():
		_lesson1_epilogue_tween.kill()
	if _lesson1_epilogue_overlay != null:
		_lesson1_epilogue_overlay.visible = false
		_lesson1_epilogue_overlay.modulate.a = 0.0
		_lesson1_epilogue_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _play_fallback_video_overlay(stream: VideoStream, on_finished: Callable) -> void:
	if _fallback_video_root != null:
		_fallback_video_root.queue_free()
		_fallback_video_root = null

	_fallback_video_callback = on_finished
	_fallback_video_active = true

	_fallback_video_root = Control.new()
	_fallback_video_root.name = "CutsceneVideoOverlay"
	_fallback_video_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fallback_video_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fallback_video_root)

	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = COLOR_INDIGO
	_fallback_video_root.add_child(bg)

	_fallback_video_player = VideoStreamPlayer.new()
	_fallback_video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fallback_video_player.expand = true
	_fallback_video_player.stream = stream
	_fallback_video_player.finished.connect(_finish_fallback_video, CONNECT_ONE_SHOT)
	_fallback_video_root.add_child(_fallback_video_player)

	var hint: Label = Label.new()
	hint.text = "[Space / Enter / Esc] Пропустить"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_left = -280.0
	hint.offset_top = -45.0
	hint.offset_right = -20.0
	hint.offset_bottom = -15.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_color_override("font_color", COLOR_GOLD_SOFT)
	hint.add_theme_font_size_override("font_size", 14)
	_fallback_video_root.add_child(hint)

	_fallback_video_player.play()


func _finish_fallback_video() -> void:
	if not _fallback_video_active:
		return
	_fallback_video_active = false

	if _fallback_video_player != null:
		_fallback_video_player.stop()
		_fallback_video_player = null

	if _fallback_video_root != null:
		_fallback_video_root.queue_free()
		_fallback_video_root = null

	var cb: Callable = _fallback_video_callback
	_fallback_video_callback = Callable()
	_invoke_callable(cb)


func _invoke_callable(cb: Callable) -> void:
	if cb.is_valid():
		cb.call()
