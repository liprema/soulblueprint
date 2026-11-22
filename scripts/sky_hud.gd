class_name SkyHUD
extends CanvasLayer

## Ultra-minimalist Sky: Children of the Light HUD & Art Deco Mentor Dialogue
## for SoulBlueprint (Godot 4.3).

const COLOR_GOLD := Color(0.964706, 0.827451, 0.419608, 1.0) # #F6D36B
const COLOR_IVORY := Color(1.0, 0.964706, 0.8, 1.0) # #FFF6CC
const COLOR_INDIGO := Color(0.027451, 0.078431, 0.180392, 0.86) # #07142E
const PIP_COUNT := 5

@export var auto_show_prologue: bool = true
@export var default_subtitle: String = "П Р О Л О Г"
@export var default_title: String = "Обитель Хроник Акаши"
@export var typewriter_chars_per_sec: float = 42.0

@onready var _wing_emblem: Control = $RootControl/WingEmblem
@onready var _chapter_container: Control = $RootControl/ChapterTitleContainer
@onready var _chapter_subtitle: Label = $RootControl/ChapterTitleContainer/VBox/SubtitleLabel
@onready var _chapter_divider: Control = $RootControl/ChapterTitleContainer/VBox/DividerControl
@onready var _chapter_title: Label = $RootControl/ChapterTitleContainer/VBox/TitleLabel
@onready var _dialogue_panel: PanelContainer = $RootControl/DialoguePanel
@onready var _dialogue_overlay: Control = $RootControl/DialoguePanel/ArtDecoOverlay
@onready var _speaker_label: Label = $RootControl/DialoguePanel/Margin/VBox/SpeakerLabel
@onready var _dialogue_divider: Control = $RootControl/DialoguePanel/Margin/VBox/DialogueDivider
@onready var _dialogue_text: Label = $RootControl/DialoguePanel/Margin/VBox/DialogueText
@onready var _flight_hint: Label = $RootControl/FlightHint

var _time: float = 0.0
var _current_energy: float = 5.0
var _max_energy: float = 5.0
var _target_pips: float = 5.0
var _displayed_pips: float = 5.0
var _recharge_flash: float = 0.0
var _flight_hint_dismissed: bool = false

var _chapter_tween: Tween
var _dialogue_tween: Tween
var _typewriter_tween: Tween
var _hint_tween: Tween


func _ready() -> void:
	_wing_emblem.draw.connect(_draw_wing_emblem)
	_chapter_divider.draw.connect(_draw_chapter_divider)
	_dialogue_overlay.draw.connect(_draw_dialogue_overlay)
	_dialogue_divider.draw.connect(_draw_dialogue_divider)

	# Dialogue panel starts hidden by default
	_dialogue_panel.visible = false
	_dialogue_panel.modulate.a = 0.0

	# Chapter title starts transparent before fading in
	_chapter_container.visible = false
	_chapter_container.modulate.a = 0.0

	# Subtle flight hint starts gently visible
	_flight_hint.modulate.a = 0.0
	var hint_in := create_tween()
	hint_in.tween_interval(1.2)
	hint_in.tween_property(_flight_hint, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if auto_show_prologue:
		show_chapter_title(default_subtitle, default_title)

	_wing_emblem.queue_redraw()
	_chapter_divider.queue_redraw()
	_dialogue_overlay.queue_redraw()
	_dialogue_divider.queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_displayed_pips = lerpf(_displayed_pips, _target_pips, clampf(delta * 8.5, 0.0, 1.0))
	if _recharge_flash > 0.0:
		_recharge_flash = maxf(0.0, _recharge_flash - delta * 2.2)
	_wing_emblem.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _flight_hint_dismissed:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE:
			hide_flight_hint()


## Updates the top-center winged star emblem and 5 golden diamond pips.
func update_wing_energy(current: float, max_energy: float) -> void:
	var safe_max: float = maxf(max_energy, 0.001)
	var ratio: float = clampf(current / safe_max, 0.0, 1.0)
	var new_pips: float = ratio * float(PIP_COUNT)

	if new_pips > _target_pips + 0.05:
		_recharge_flash = 1.0
	elif new_pips < _target_pips - 0.05:
		hide_flight_hint()

	_current_energy = clampf(current, 0.0, safe_max)
	_max_energy = safe_max
	_target_pips = new_pips


## Displays the ethereal upper-third chapter title with a graceful fade-in and fade-out.
func show_chapter_title(subtitle: String, title: String, hold_duration: float = 4.5) -> void:
	if _chapter_tween and _chapter_tween.is_valid():
		_chapter_tween.kill()

	_chapter_subtitle.text = subtitle
	_chapter_title.text = title
	_chapter_container.visible = true
	_chapter_container.modulate.a = 0.0
	_chapter_divider.queue_redraw()

	var fade_in_time: float = 1.1
	var fade_out_time: float = 1.1
	var visible_hold: float = maxf(0.5, hold_duration - fade_in_time)

	_chapter_tween = create_tween()
	_chapter_tween.tween_property(_chapter_container, "modulate:a", 1.0, fade_in_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_chapter_tween.tween_interval(visible_hold)
	_chapter_tween.tween_property(_chapter_container, "modulate:a", 0.0, fade_out_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_chapter_tween.tween_callback(func() -> void: _chapter_container.visible = false)


## Shows the Art Deco mentor dialogue panel at bottom-center with smooth typewriter reveal.
func show_dialogue(speaker: String, line: String) -> void:
	if _dialogue_tween and _dialogue_tween.is_valid():
		_dialogue_tween.kill()
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	_speaker_label.text = speaker
	_dialogue_text.text = line
	_dialogue_text.visible_characters = 0

	_dialogue_panel.visible = true
	_dialogue_overlay.queue_redraw()
	_dialogue_divider.queue_redraw()

	_dialogue_tween = create_tween()
	_dialogue_tween.tween_property(_dialogue_panel, "modulate:a", 1.0, 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var char_count: int = line.length()
	if char_count > 0:
		var reveal_duration: float = clampf(float(char_count) / maxf(typewriter_chars_per_sec, 1.0), 0.35, 6.0)
		_typewriter_tween = create_tween()
		_typewriter_tween.tween_property(_dialogue_text, "visible_characters", char_count, reveal_duration) \
			.set_trans(Tween.TRANS_LINEAR)


## Smoothly fades out and hides the mentor dialogue panel.
func hide_dialogue() -> void:
	if _dialogue_tween and _dialogue_tween.is_valid():
		_dialogue_tween.kill()
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	if not _dialogue_panel.visible:
		return

	_dialogue_tween = create_tween()
	_dialogue_tween.tween_property(_dialogue_panel, "modulate:a", 0.0, 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_dialogue_tween.tween_callback(func() -> void: _dialogue_panel.visible = false)


## Explicitly dismisses the bottom-left flight hint once the player begins flying.
func hide_flight_hint() -> void:
	if _flight_hint_dismissed:
		return
	_flight_hint_dismissed = true

	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()

	_hint_tween = create_tween()
	_hint_tween.tween_property(_flight_hint, "modulate:a", 0.0, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_hint_tween.tween_callback(func() -> void: _flight_hint.visible = false)


# ---------------------------------------------------------------------------
# Custom Vector Art Drawing (Sky Emblem & Art Deco Filigree)
# ---------------------------------------------------------------------------

func _draw_wing_emblem() -> void:
	var size: Vector2 = _wing_emblem.size
	var cx: float = size.x * 0.5
	var star_center := Vector2(cx, 26.0)
	var energy_ratio: float = clampf(_displayed_pips / float(PIP_COUNT), 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(_time * 2.4)
	var glow_boost: float = (0.35 + 0.65 * energy_ratio) + _recharge_flash * 0.45

	# Soft celestial halo behind the winged star
	var halo_outer := Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, clampf(0.10 * glow_boost + 0.04 * pulse, 0.0, 0.35))
	var halo_inner := Color(COLOR_IVORY.r, COLOR_IVORY.g, COLOR_IVORY.b, clampf(0.16 * glow_boost + 0.05 * pulse, 0.0, 0.45))
	_wing_emblem.draw_circle(star_center, 24.0 + pulse * 2.0, halo_outer)
	_wing_emblem.draw_circle(star_center, 12.0 + pulse * 1.0, halo_inner)

	# Symmetrical stylized golden wings (3 feathered blades each side)
	var wing_fill := COLOR_GOLD.lerp(COLOR_IVORY, 0.25 * energy_ratio + 0.35 * _recharge_flash)
	wing_fill.a = lerpf(0.32, 0.94, energy_ratio)
	var wing_edge := Color(COLOR_IVORY.r, COLOR_IVORY.g, COLOR_IVORY.b, lerpf(0.22, 0.85, energy_ratio))

	for side in [-1.0, 1.0]:
		# Upper primary wing feather
		var feather_top := PackedVector2Array([
			star_center + Vector2(side * 9.0, 0.0),
			star_center + Vector2(side * 24.0, -9.5),
			star_center + Vector2(side * 42.0, -11.5),
			star_center + Vector2(side * 30.0, -2.5),
			star_center + Vector2(side * 12.0, 2.5),
		])
		_wing_emblem.draw_colored_polygon(feather_top, wing_fill)
		_wing_emblem.draw_polyline(feather_top, wing_edge, 1.0, true)

		# Middle wing feather
		var feather_mid := PackedVector2Array([
			star_center + Vector2(side * 10.0, 3.0),
			star_center + Vector2(side * 24.0, -1.0),
			star_center + Vector2(side * 35.0, -1.0),
			star_center + Vector2(side * 23.0, 5.0),
			star_center + Vector2(side * 11.0, 5.5),
		])
		var mid_col := wing_fill
		mid_col.a *= 0.85
		_wing_emblem.draw_colored_polygon(feather_mid, mid_col)

		# Lower accent feather
		var feather_low := PackedVector2Array([
			star_center + Vector2(side * 9.0, 6.0),
			star_center + Vector2(side * 19.0, 5.5),
			star_center + Vector2(side * 26.0, 7.5),
			star_center + Vector2(side * 15.0, 9.5),
		])
		var low_col := wing_fill
		low_col.a *= 0.68
		_wing_emblem.draw_colored_polygon(feather_low, low_col)

	# Central 4-point celestial star
	var star_outer := _make_four_point_star(star_center, 11.5 + _recharge_flash * 1.5, 3.2)
	var star_inner := _make_four_point_star(star_center, 6.5, 2.0)
	var star_col := COLOR_GOLD.lerp(COLOR_IVORY, 0.45 * energy_ratio + 0.4 * _recharge_flash)
	star_col.a = lerpf(0.45, 1.0, energy_ratio)
	_wing_emblem.draw_colored_polygon(star_outer, star_col)
	_wing_emblem.draw_colored_polygon(star_inner, Color(COLOR_IVORY.r, COLOR_IVORY.g, COLOR_IVORY.b, lerpf(0.45, 1.0, energy_ratio)))

	# 5 Golden Diamond Pips below the winged star
	var pip_y: float = 56.0
	var pip_spacing: float = 24.0
	var start_x: float = cx - pip_spacing * float(PIP_COUNT - 1) * 0.5

	# Delicate connecting hairline behind pips
	var line_col := Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.25)
	_wing_emblem.draw_line(
		Vector2(start_x - 10.0, pip_y),
		Vector2(start_x + pip_spacing * float(PIP_COUNT - 1) + 10.0, pip_y),
		line_col,
		1.0,
		true
	)

	for i in range(PIP_COUNT):
		var pip_pos := Vector2(start_x + float(i) * pip_spacing, pip_y)
		var fill: float = clampf(_displayed_pips - float(i), 0.0, 1.0)

		# Outer diamond socket
		var socket_pts := _make_diamond(pip_pos, 6.5, 8.2)
		var socket_fill := Color(COLOR_INDIGO.r, COLOR_INDIGO.g, COLOR_INDIGO.b, 0.55)
		_wing_emblem.draw_colored_polygon(socket_pts, socket_fill)

		var border_col := Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, lerpf(0.30, 0.95, fill))
		var closed_socket := socket_pts.duplicate()
		closed_socket.append(socket_pts[0])
		_wing_emblem.draw_polyline(closed_socket, border_col, 1.2, true)

		# Lit diamond core with smooth glow transition
		if fill > 0.01:
			var pip_glow := Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.22 * fill + 0.08 * pulse * fill)
			_wing_emblem.draw_circle(pip_pos, 10.5 * fill, pip_glow)

			var core_scale: float = lerpf(0.35, 1.0, fill)
			var gold_diamond := _make_diamond(pip_pos, 5.2 * core_scale, 6.6 * core_scale)
			var gold_col := COLOR_GOLD.lerp(COLOR_IVORY, 0.35 * fill + 0.3 * _recharge_flash)
			gold_col.a = fill
			_wing_emblem.draw_colored_polygon(gold_diamond, gold_col)

			var bright_core := _make_diamond(pip_pos, 2.5 * core_scale, 3.4 * core_scale)
			_wing_emblem.draw_colored_polygon(bright_core, Color(COLOR_IVORY.r, COLOR_IVORY.g, COLOR_IVORY.b, fill))


func _draw_chapter_divider() -> void:
	var size: Vector2 = _chapter_divider.size
	var cy: float = size.y * 0.5
	var cx: float = size.x * 0.5
	var half_w: float = minf(size.x * 0.46, 175.0)

	# Segmented tapering golden hairline
	var segments: int = 12
	for s in range(segments):
		var t0: float = float(s) / float(segments)
		var t1: float = float(s + 1) / float(segments)
		var alpha: float = (1.0 - (t0 + t1) * 0.5) * 0.85
		var seg_col := Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, alpha)
		var x0_r: float = cx + 8.0 + t0 * (half_w - 8.0)
		var x1_r: float = cx + 8.0 + t1 * (half_w - 8.0)
		var x0_l: float = cx - 8.0 - t0 * (half_w - 8.0)
		var x1_l: float = cx - 8.0 - t1 * (half_w - 8.0)
		_chapter_divider.draw_line(Vector2(x0_r, cy), Vector2(x1_r, cy), seg_col, 1.2, true)
		_chapter_divider.draw_line(Vector2(x0_l, cy), Vector2(x1_l, cy), seg_col, 1.2, true)

	# Center Art Deco diamond ornament
	var center_diamond := _make_diamond(Vector2(cx, cy), 4.5, 4.5)
	_chapter_divider.draw_colored_polygon(center_diamond, COLOR_IVORY)


func _draw_dialogue_divider() -> void:
	var size: Vector2 = _dialogue_divider.size
	var cy: float = size.y * 0.5
	var col := Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.38)
	_dialogue_divider.draw_line(Vector2(0.0, cy), Vector2(size.x * 0.45, cy), col, 1.0, true)
	var tip := _make_diamond(Vector2(size.x * 0.45 + 4.0, cy), 2.5, 2.5)
	_dialogue_divider.draw_colored_polygon(tip, Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.7))


func _draw_dialogue_overlay() -> void:
	var rect_size: Vector2 = _dialogue_overlay.size
	if rect_size.x < 24.0 or rect_size.y < 24.0:
		return

	var inset: float = 6.0
	var corner_len: float = 14.0
	var line_col := Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.55)

	# Four inner Art Deco corner brackets
	# Top-left
	_dialogue_overlay.draw_polyline(PackedVector2Array([
		Vector2(inset, inset + corner_len),
		Vector2(inset, inset),
		Vector2(inset + corner_len, inset),
	]), line_col, 1.2, true)
	# Top-right
	_dialogue_overlay.draw_polyline(PackedVector2Array([
		Vector2(rect_size.x - inset - corner_len, inset),
		Vector2(rect_size.x - inset, inset),
		Vector2(rect_size.x - inset, inset + corner_len),
	]), line_col, 1.2, true)
	# Bottom-left
	_dialogue_overlay.draw_polyline(PackedVector2Array([
		Vector2(inset, rect_size.y - inset - corner_len),
		Vector2(inset, rect_size.y - inset),
		Vector2(inset + corner_len, rect_size.y - inset),
	]), line_col, 1.2, true)
	# Bottom-right
	_dialogue_overlay.draw_polyline(PackedVector2Array([
		Vector2(rect_size.x - inset - corner_len, rect_size.y - inset),
		Vector2(rect_size.x - inset, rect_size.y - inset),
		Vector2(rect_size.x - inset, rect_size.y - inset - corner_len),
	]), line_col, 1.2, true)

	# Top-center Art Deco diamond crest
	var crest_pos := Vector2(rect_size.x * 0.5, 1.0)
	var crest := _make_diamond(crest_pos, 5.0, 5.0)
	_dialogue_overlay.draw_colored_polygon(crest, COLOR_GOLD)
	var crest_core := _make_diamond(crest_pos, 2.2, 2.2)
	_dialogue_overlay.draw_colored_polygon(crest_core, COLOR_IVORY)


func _make_diamond(center: Vector2, half_w: float, half_h: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -half_h),
		center + Vector2(half_w, 0.0),
		center + Vector2(0.0, half_h),
		center + Vector2(-half_w, 0.0),
	])


func _make_four_point_star(center: Vector2, outer_r: float, inner_r: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -outer_r),
		center + Vector2(inner_r, -inner_r),
		center + Vector2(outer_r, 0.0),
		center + Vector2(inner_r, inner_r),
		center + Vector2(0.0, outer_r),
		center + Vector2(-inner_r, inner_r),
		center + Vector2(-outer_r, 0.0),
		center + Vector2(-inner_r, -inner_r),
	])
