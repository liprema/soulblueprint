class_name MainMenu
extends CanvasLayer

## Luminous light fairytale Baroque Main Menu overlay for SoulBlueprint (Godot 4.3).
## Floats airily over the live 3D sunlit Akashic Palace with pearl-ivory, sky-azure,
## and antique-gold typography plus delicate custom-drawn Baroque filigree.

signal start_new_game_requested
signal continue_game_requested
signal audio_toggled(muted: bool)
signal quit_requested

const COLOR_GOLD := Color(0.87451, 0.72549, 0.376471, 1.0) # #DFB960 antique gold
const COLOR_GOLD_BRIGHT := Color(0.909804, 0.768627, 0.407843, 1.0) # #E8C468 bright gold
const COLOR_BRONZE_GOLD := Color(0.619608, 0.454902, 0.156863, 1.0) # #9E7428 bronze gold
const COLOR_PEARL := Color(0.985, 0.99, 1.0, 1.0) # luminous cloud-pearl
const COLOR_SAPPHIRE := Color(0.101961, 0.180392, 0.321569, 1.0) # #1A2E52 sapphire ink

const LABEL_START_NEW: String = "Начать путь"
const LABEL_RESTART: String = "Начать заново"
const LABEL_AUDIO_ON: String = "Звук: Вкл"
const LABEL_AUDIO_OFF: String = "Звук: Выкл"

@onready var _root: Control = $RootControl
@onready var _frame_overlay: Control = $RootControl/ArtDecoFrame
@onready var _title_divider: Control = $RootControl/TitleBlock/VBox/TitleDivider
@onready var _continue_button: Button = $RootControl/MenuButtons/ContinueButton
@onready var _start_button: Button = $RootControl/MenuButtons/StartButton
@onready var _quit_button: Button = $RootControl/MenuButtons/QuitButton
@onready var _audio_button: Button = $RootControl/AudioButton

var _is_open: bool = false
var _has_save: bool = false
var _audio_muted: bool = false
var _time: float = 0.0
var _fade_tween: Tween


func _ready() -> void:
	layer = 50

	_frame_overlay.draw.connect(_draw_frame_overlay)
	_title_divider.draw.connect(_draw_title_divider)

	_continue_button.pressed.connect(_on_continue_pressed)
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_audio_button.pressed.connect(_on_audio_pressed)

	var buttons: Array[Button] = [_continue_button, _start_button, _quit_button, _audio_button]
	for btn: Button in buttons:
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.focus_entered.connect(_on_button_hover.bind(btn))

	_root.modulate.a = 0.0
	if _is_open:
		_apply_open_state()
	else:
		_root.visible = false
		_set_buttons_interactive(false)

	_frame_overlay.queue_redraw()
	_title_divider.queue_redraw()


func _process(delta: float) -> void:
	if not _root.visible:
		return
	_time += delta
	_title_divider.queue_redraw()


## Shows the main menu overlay, updates save/audio state, releases the mouse cursor,
## and smoothly fades in over the live 3D sanctuary.
func show_menu(has_save: bool, audio_muted: bool = false) -> void:
	_has_save = has_save
	_audio_muted = audio_muted
	_is_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if not is_node_ready():
		return

	_apply_open_state()


## Smoothly fades out the main menu overlay and immediately disables mouse interaction.
func hide_menu() -> void:
	_is_open = false

	if not is_node_ready():
		return

	_set_buttons_interactive(false)

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	if not _root.visible:
		return

	_fade_tween = create_tween()
	_fade_tween.tween_property(_root, "modulate:a", 0.0, 0.45) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_fade_tween.tween_callback(_on_hide_finished)


## Returns true while the main menu is open.
func is_menu_open() -> bool:
	return _is_open


func _apply_open_state() -> void:
	_continue_button.visible = _has_save
	_start_button.text = LABEL_RESTART if _has_save else LABEL_START_NEW
	_update_audio_button_label()
	_set_buttons_interactive(true)

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_root.visible = true
	_frame_overlay.queue_redraw()
	_title_divider.queue_redraw()

	_fade_tween = create_tween()
	_fade_tween.tween_property(_root, "modulate:a", 1.0, 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_hide_finished() -> void:
	if not _is_open:
		_root.visible = false


func _set_buttons_interactive(enabled: bool) -> void:
	var filter: Control.MouseFilter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	var focus: Control.FocusMode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	var buttons: Array[Button] = [_continue_button, _start_button, _quit_button, _audio_button]
	for btn: Button in buttons:
		btn.disabled = not enabled
		btn.mouse_filter = filter
		btn.focus_mode = focus


func _update_audio_button_label() -> void:
	_audio_button.text = LABEL_AUDIO_OFF if _audio_muted else LABEL_AUDIO_ON


func _on_button_hover(btn: Button) -> void:
	if not _is_open or btn.disabled or not btn.visible:
		return
	_play_ui_audio("play_ui_hover")


func _on_continue_pressed() -> void:
	if not _is_open:
		return
	_play_ui_audio("play_ui_click")
	continue_game_requested.emit()


func _on_start_pressed() -> void:
	if not _is_open:
		return
	_play_ui_audio("play_ui_click")
	start_new_game_requested.emit()


func _on_quit_pressed() -> void:
	if not _is_open:
		return
	_play_ui_audio("play_ui_click")
	quit_requested.emit()


func _on_audio_pressed() -> void:
	if not _is_open:
		return
	_play_ui_audio("play_ui_click")
	_audio_muted = not _audio_muted
	_update_audio_button_label()
	audio_toggled.emit(_audio_muted)


func _play_ui_audio(method_name: String) -> void:
	var audio_node: Node = get_node_or_null("/root/AkashaAudioManager")
	if audio_node == null and get_parent() != null:
		audio_node = get_parent().get_node_or_null("AkashaAudioManager")
	if audio_node == null and get_tree() != null:
		audio_node = get_tree().get_first_node_in_group("akasha_audio")
	if audio_node != null and audio_node.has_method(method_name):
		audio_node.call(method_name)


# ---------------------------------------------------------------------------
# Custom Baroque Pearl-Gold Filigree Drawing (matching SkyHUD visual language)
# ---------------------------------------------------------------------------

func _draw_title_divider() -> void:
	var size: Vector2 = _title_divider.size
	var cx: float = size.x * 0.5
	var cy: float = size.y * 0.5
	var half_w: float = minf(size.x * 0.48, 210.0)
	var pulse: float = 0.5 + 0.5 * sin(_time * 2.0)

	# Segmented tapering antique-gold hairline with pearl glint radiating from the central crest
	var segments: int = 16
	var inner_gap: float = 14.0
	for s in range(segments):
		var t0: float = float(s) / float(segments)
		var t1: float = float(s + 1) / float(segments)
		var alpha: float = (1.0 - (t0 + t1) * 0.5) * 0.9
		var shadow_col := Color(COLOR_SAPPHIRE.r, COLOR_SAPPHIRE.g, COLOR_SAPPHIRE.b, alpha * 0.22)
		var seg_col := Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, alpha)
		var x0_r: float = cx + inner_gap + t0 * (half_w - inner_gap)
		var x1_r: float = cx + inner_gap + t1 * (half_w - inner_gap)
		var x0_l: float = cx - inner_gap - t0 * (half_w - inner_gap)
		var x1_l: float = cx - inner_gap - t1 * (half_w - inner_gap)
		_title_divider.draw_line(Vector2(x0_r, cy + 1.0), Vector2(x1_r, cy + 1.0), shadow_col, 1.8, true)
		_title_divider.draw_line(Vector2(x0_l, cy + 1.0), Vector2(x1_l, cy + 1.0), shadow_col, 1.8, true)
		_title_divider.draw_line(Vector2(x0_r, cy), Vector2(x1_r, cy), seg_col, 1.6, true)
		_title_divider.draw_line(Vector2(x0_l, cy), Vector2(x1_l, cy), seg_col, 1.6, true)

	# Flanking miniature baroque accent diamonds
	var accent_col := Color(COLOR_GOLD_BRIGHT.r, COLOR_GOLD_BRIGHT.g, COLOR_GOLD_BRIGHT.b, 0.92)
	var accent_offset: float = minf(half_w * 0.34, 66.0)
	for side: float in [-1.0, 1.0]:
		var accent_pos := Vector2(cx + side * accent_offset, cy)
		var accent_pts := _make_diamond(accent_pos, 3.6, 3.6)
		_title_divider.draw_colored_polygon(accent_pts, accent_col)
		var inner_accent := _make_diamond(accent_pos, 1.6, 1.6)
		_title_divider.draw_colored_polygon(inner_accent, COLOR_PEARL)

	# Soft warm ivory-gold halo behind the central Baroque diamond crest
	var crest_center := Vector2(cx, cy)
	var halo_col := Color(COLOR_PEARL.r, COLOR_PEARL.g, COLOR_PEARL.b, 0.24 + 0.12 * pulse)
	_title_divider.draw_circle(crest_center, 12.0 + pulse * 1.8, halo_col)

	# Outer antique-gold diamond crest + luminous pearl core
	var crest_outer := _make_diamond(crest_center, 7.5, 7.5)
	_title_divider.draw_colored_polygon(crest_outer, COLOR_BRONZE_GOLD)
	var crest_mid := _make_diamond(crest_center, 5.8, 5.8)
	_title_divider.draw_colored_polygon(crest_mid, COLOR_GOLD_BRIGHT)
	var crest_inner := _make_diamond(crest_center, 3.0, 3.0)
	_title_divider.draw_colored_polygon(crest_inner, COLOR_PEARL)


func _draw_frame_overlay() -> void:
	var rect_size: Vector2 = _frame_overlay.size
	if rect_size.x < 120.0 or rect_size.y < 120.0:
		return

	var inset: float = 18.0
	var corner_len: float = 24.0
	var line_col := Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.56)
	var pearl_col := Color(COLOR_PEARL.r, COLOR_PEARL.g, COLOR_PEARL.b, 0.65)
	var diamond_col := Color(COLOR_GOLD_BRIGHT.r, COLOR_GOLD_BRIGHT.g, COLOR_GOLD_BRIGHT.b, 0.85)

	# Delicate Baroque viewport corner brackets
	# Top-left
	_frame_overlay.draw_polyline(PackedVector2Array([
		Vector2(inset, inset + corner_len),
		Vector2(inset, inset),
		Vector2(inset + corner_len, inset),
	]), line_col, 1.5, true)
	# Top-right
	_frame_overlay.draw_polyline(PackedVector2Array([
		Vector2(rect_size.x - inset - corner_len, inset),
		Vector2(rect_size.x - inset, inset),
		Vector2(rect_size.x - inset, inset + corner_len),
	]), line_col, 1.5, true)
	# Bottom-left
	_frame_overlay.draw_polyline(PackedVector2Array([
		Vector2(inset, rect_size.y - inset - corner_len),
		Vector2(inset, rect_size.y - inset),
		Vector2(inset + corner_len, rect_size.y - inset),
	]), line_col, 1.5, true)
	# Bottom-right
	_frame_overlay.draw_polyline(PackedVector2Array([
		Vector2(rect_size.x - inset - corner_len, rect_size.y - inset),
		Vector2(rect_size.x - inset, rect_size.y - inset),
		Vector2(rect_size.x - inset, rect_size.y - inset - corner_len),
	]), line_col, 1.5, true)

	# Tiny golden & pearl corner diamonds
	var corners: Array[Vector2] = [
		Vector2(inset, inset),
		Vector2(rect_size.x - inset, inset),
		Vector2(inset, rect_size.y - inset),
		Vector2(rect_size.x - inset, rect_size.y - inset),
	]
	for corner: Vector2 in corners:
		_frame_overlay.draw_colored_polygon(_make_diamond(corner, 3.2, 3.2), diamond_col)
		_frame_overlay.draw_colored_polygon(_make_diamond(corner, 1.4, 1.4), pearl_col)


func _make_diamond(center: Vector2, half_w: float, half_h: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -half_h),
		center + Vector2(half_w, 0.0),
		center + Vector2(0.0, half_h),
		center + Vector2(-half_w, 0.0),
	])
