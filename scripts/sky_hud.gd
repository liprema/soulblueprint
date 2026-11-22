class_name SkyHUD
extends CanvasLayer

## Ultra-minimalist Sky: Children of the Light HUD & Art Deco Mentor Dialogue
## for SoulBlueprint (Godot 4.3).

signal dialogue_advance_requested
signal dialogue_choice_selected(choice_index: int)

const COLOR_GOLD := Color(0.964706, 0.827451, 0.419608, 1.0) # #F6D36B
const COLOR_IVORY := Color(1.0, 0.964706, 0.8, 1.0) # #FFF6CC
const COLOR_INDIGO := Color(0.027451, 0.078431, 0.180392, 0.86) # #07142E
const PIP_COUNT := 5

@export var auto_show_prologue: bool = true
@export var default_subtitle: String = "П Р О Л О Г"
@export var default_title: String = "Обитель Хроник Акаши"
@export var typewriter_chars_per_sec: float = 42.0

@onready var _root_control: Control = $RootControl
@onready var _wing_emblem: Control = $RootControl/WingEmblem
@onready var _chapter_container: Control = $RootControl/ChapterTitleContainer
@onready var _chapter_subtitle: Label = $RootControl/ChapterTitleContainer/VBox/SubtitleLabel
@onready var _chapter_divider: Control = $RootControl/ChapterTitleContainer/VBox/DividerControl
@onready var _chapter_title: Label = $RootControl/ChapterTitleContainer/VBox/TitleLabel
@onready var _dialogue_panel: PanelContainer = $RootControl/DialoguePanel
@onready var _dialogue_vbox: VBoxContainer = $RootControl/DialoguePanel/Margin/VBox
@onready var _dialogue_overlay: Control = $RootControl/DialoguePanel/ArtDecoOverlay
@onready var _speaker_label: Label = $RootControl/DialoguePanel/Margin/VBox/SpeakerLabel
@onready var _dialogue_divider: Control = $RootControl/DialoguePanel/Margin/VBox/DialogueDivider
@onready var _dialogue_text: Label = $RootControl/DialoguePanel/Margin/VBox/DialogueText
@onready var _flight_hint: Label = $RootControl/FlightHint

var _choices_container: VBoxContainer
var _continue_label: Label
var _interaction_panel: PanelContainer
var _interaction_label: Label
var _lantern_panel: PanelContainer
var _lantern_label: Label

var _time: float = 0.0
var _current_energy: float = 5.0
var _max_energy: float = 5.0
var _target_pips: float = 5.0
var _displayed_pips: float = 5.0
var _recharge_flash: float = 0.0
var _flight_hint_dismissed: bool = false

var _dialogue_active: bool = false
var _is_typewriting: bool = false
var _dialogue_accent: Color = COLOR_GOLD
var _current_choices: Array = []
var _interaction_visible: bool = false

var _chapter_tween: Tween
var _dialogue_tween: Tween
var _typewriter_tween: Tween
var _choices_tween: Tween
var _hint_tween: Tween
var _interaction_tween: Tween
var _lantern_tween: Tween


func _ready() -> void:
	_wing_emblem.draw.connect(_draw_wing_emblem)
	_chapter_divider.draw.connect(_draw_chapter_divider)
	_dialogue_overlay.draw.connect(_draw_dialogue_overlay)
	_dialogue_divider.draw.connect(_draw_dialogue_divider)
	_dialogue_panel.gui_input.connect(_on_dialogue_panel_gui_input)
	_dialogue_panel.resized.connect(_on_dialogue_panel_resized)

	_build_extended_ui()

	# Dialogue panel starts hidden by default
	_dialogue_panel.visible = false
	_dialogue_panel.modulate.a = 0.0
	_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Chapter title starts transparent before fading in
	_chapter_container.visible = false
	_chapter_container.modulate.a = 0.0

	# Subtle flight hint starts gently visible
	_flight_hint.modulate.a = 0.0
	var hint_in: Tween = create_tween()
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

	if _continue_label != null and _continue_label.visible:
		_continue_label.modulate.a = lerpf(0.52, 0.96, 0.5 + 0.5 * sin(_time * 3.2))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			var code: Key = key_event.keycode
			var phys: Key = key_event.physical_keycode

			if _dialogue_active and _root_control.visible:
				if code == KEY_SPACE or phys == KEY_SPACE or code == KEY_ENTER or phys == KEY_ENTER or code == KEY_KP_ENTER or phys == KEY_KP_ENTER:
					_handle_dialogue_continue_input()
					get_viewport().set_input_as_handled()
					return

				if not _current_choices.is_empty():
					var choice_idx: int = -1
					if code == KEY_1 or phys == KEY_1 or code == KEY_KP_1:
						choice_idx = 0
					elif code == KEY_2 or phys == KEY_2 or code == KEY_KP_2:
						choice_idx = 1
					elif code == KEY_3 or phys == KEY_3 or code == KEY_KP_3:
						choice_idx = 2

					if choice_idx >= 0 and choice_idx < _current_choices.size():
						if _is_typewriting:
							_complete_typewriter()
						_on_choice_button_pressed(choice_idx)
						get_viewport().set_input_as_handled()
						return

			if not _flight_hint_dismissed and (code == KEY_SPACE or phys == KEY_SPACE):
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
## Preserved for backward compatibility with single-line dialogue callers.
func show_dialogue(speaker: String, line: String) -> void:
	show_dialogue_step(speaker, line, COLOR_GOLD, [])


## Shows a multi-step mentor dialogue line with speaker accent color and optional Spark response choices.
func show_dialogue_step(speaker: String, line: String, accent_color: Color, choices: Array) -> void:
	if _dialogue_tween and _dialogue_tween.is_valid():
		_dialogue_tween.kill()
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	if _choices_tween and _choices_tween.is_valid():
		_choices_tween.kill()

	_dialogue_active = true
	_dialogue_accent = accent_color
	_current_choices = choices.duplicate()

	_speaker_label.text = speaker
	_speaker_label.add_theme_color_override("font_color", _dialogue_accent)
	_dialogue_text.text = line
	_dialogue_text.visible_characters = 0

	_rebuild_choice_buttons(_current_choices)
	_choices_container.visible = false
	_choices_container.modulate.a = 0.0
	_continue_label.visible = false

	# Reset panel frame to compact baseline so it expands cleanly upward if choices appear
	_dialogue_panel.offset_left = -310.0
	_dialogue_panel.offset_right = 310.0
	_dialogue_panel.offset_top = -148.0
	_dialogue_panel.offset_bottom = -28.0
	_dialogue_panel.size = Vector2(620.0, 120.0)

	_dialogue_panel.visible = true
	_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_dialogue_overlay.queue_redraw()
	_dialogue_divider.queue_redraw()

	_dialogue_tween = create_tween()
	_dialogue_tween.tween_property(_dialogue_panel, "modulate:a", 1.0, 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var char_count: int = line.length()
	if char_count > 0:
		_is_typewriting = true
		var reveal_duration: float = clampf(float(char_count) / maxf(typewriter_chars_per_sec, 1.0), 0.35, 6.0)
		_typewriter_tween = create_tween()
		_typewriter_tween.tween_property(_dialogue_text, "visible_characters", char_count, reveal_duration) \
			.set_trans(Tween.TRANS_LINEAR)
		_typewriter_tween.tween_callback(_on_typewriter_finished)
	else:
		_is_typewriting = false
		_on_typewriter_finished()


## Smoothly fades out and hides the mentor dialogue panel.
func hide_dialogue() -> void:
	if _dialogue_tween and _dialogue_tween.is_valid():
		_dialogue_tween.kill()
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	if _choices_tween and _choices_tween.is_valid():
		_choices_tween.kill()

	_dialogue_active = false
	_is_typewriting = false
	_current_choices.clear()
	_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not _dialogue_panel.visible:
		return

	_dialogue_tween = create_tween()
	_dialogue_tween.tween_property(_dialogue_panel, "modulate:a", 0.0, 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_dialogue_tween.tween_callback(func() -> void:
		_dialogue_panel.visible = false
		_choices_container.visible = false
		_continue_label.visible = false
	)


## Displays a centered contextual interaction prompt gently above the bottom edge.
func show_interaction_prompt(text: String) -> void:
	if _interaction_panel == null or _interaction_label == null:
		return
	if _interaction_visible and _interaction_label.text == text:
		return

	_interaction_visible = true
	_interaction_label.text = text
	_interaction_panel.visible = true

	if _interaction_tween and _interaction_tween.is_valid():
		_interaction_tween.kill()

	_interaction_tween = create_tween()
	_interaction_tween.tween_property(_interaction_panel, "modulate:a", 1.0, 0.28) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Smoothly fades out and hides the contextual interaction prompt.
func hide_interaction_prompt() -> void:
	if _interaction_panel == null:
		return
	if not _interaction_visible and not _interaction_panel.visible:
		return

	_interaction_visible = false
	if _interaction_tween and _interaction_tween.is_valid():
		_interaction_tween.kill()

	_interaction_tween = create_tween()
	_interaction_tween.tween_property(_interaction_panel, "modulate:a", 0.0, 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_interaction_tween.tween_callback(func() -> void: _interaction_panel.visible = false)


## Shows the minimalist top-right lantern progress badge, then settles to subtle 0.35 opacity.
func show_lantern_progress(awakened: int, total: int) -> void:
	if _lantern_panel == null or _lantern_label == null:
		return

	_lantern_label.text = "✦ %d / %d" % [awakened, total]
	_lantern_panel.visible = true

	if _lantern_tween and _lantern_tween.is_valid():
		_lantern_tween.kill()

	_lantern_tween = create_tween()
	_lantern_tween.tween_property(_lantern_panel, "modulate:a", 1.0, 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_lantern_tween.tween_interval(3.5)
	_lantern_tween.tween_property(_lantern_panel, "modulate:a", 0.35, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Cleanly toggles visibility of the entire HUD root (for Main Menu / cutscenes).
func set_hud_visible(visible_state: bool) -> void:
	if _root_control != null:
		_root_control.visible = visible_state


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
# Extended Programmatic UI Construction & Dialogue Interaction Helpers
# ---------------------------------------------------------------------------

func _build_extended_ui() -> void:
	# Choice button container inside DialoguePanel VBox
	_choices_container = VBoxContainer.new()
	_choices_container.name = "ChoicesContainer"
	_choices_container.visible = false
	_choices_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_choices_container.add_theme_constant_override("separation", 8)
	_dialogue_vbox.add_child(_choices_container)

	# Continue prompt label at bottom-right of DialoguePanel VBox
	_continue_label = Label.new()
	_continue_label.name = "ContinuePrompt"
	_continue_label.visible = false
	_continue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_label.text = "✦  [Space / Клик] Продолжить"
	_continue_label.add_theme_font_size_override("font_size", 12)
	_continue_label.add_theme_color_override("font_color", Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.85))
	_dialogue_vbox.add_child(_continue_label)

	# Contextual interaction prompt centered above bottom edge
	_interaction_panel = PanelContainer.new()
	_interaction_panel.name = "InteractionPromptPanel"
	_interaction_panel.visible = false
	_interaction_panel.modulate.a = 0.0
	_interaction_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interaction_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_interaction_panel.offset_left = -230.0
	_interaction_panel.offset_right = 230.0
	_interaction_panel.offset_top = -104.0
	_interaction_panel.offset_bottom = -64.0
	_interaction_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_interaction_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var prompt_style: StyleBoxFlat = StyleBoxFlat.new()
	prompt_style.bg_color = Color(COLOR_INDIGO.r, COLOR_INDIGO.g, COLOR_INDIGO.b, 0.78)
	prompt_style.border_width_left = 1
	prompt_style.border_width_top = 1
	prompt_style.border_width_right = 1
	prompt_style.border_width_bottom = 1
	prompt_style.border_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.55)
	prompt_style.corner_radius_top_left = 3
	prompt_style.corner_radius_top_right = 3
	prompt_style.corner_radius_bottom_right = 3
	prompt_style.corner_radius_bottom_left = 3
	prompt_style.content_margin_left = 18.0
	prompt_style.content_margin_right = 18.0
	prompt_style.content_margin_top = 8.0
	prompt_style.content_margin_bottom = 8.0
	_interaction_panel.add_theme_stylebox_override("panel", prompt_style)

	_interaction_label = Label.new()
	_interaction_label.name = "InteractionPromptLabel"
	_interaction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_interaction_label.add_theme_font_size_override("font_size", 14)
	_interaction_label.add_theme_color_override("font_color", COLOR_IVORY)
	_interaction_panel.add_child(_interaction_label)
	_root_control.add_child(_interaction_panel)

	# Minimalist top-right lantern progress badge
	_lantern_panel = PanelContainer.new()
	_lantern_panel.name = "LanternProgressBadge"
	_lantern_panel.visible = false
	_lantern_panel.modulate.a = 0.0
	_lantern_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lantern_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_lantern_panel.offset_left = -126.0
	_lantern_panel.offset_right = -22.0
	_lantern_panel.offset_top = 20.0
	_lantern_panel.offset_bottom = 52.0
	_lantern_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_lantern_panel.grow_vertical = Control.GROW_DIRECTION_END

	var lantern_style: StyleBoxFlat = StyleBoxFlat.new()
	lantern_style.bg_color = Color(COLOR_INDIGO.r, COLOR_INDIGO.g, COLOR_INDIGO.b, 0.68)
	lantern_style.border_width_left = 1
	lantern_style.border_width_top = 1
	lantern_style.border_width_right = 1
	lantern_style.border_width_bottom = 1
	lantern_style.border_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.48)
	lantern_style.corner_radius_top_left = 3
	lantern_style.corner_radius_top_right = 3
	lantern_style.corner_radius_bottom_right = 3
	lantern_style.corner_radius_bottom_left = 3
	lantern_style.content_margin_left = 12.0
	lantern_style.content_margin_right = 12.0
	lantern_style.content_margin_top = 5.0
	lantern_style.content_margin_bottom = 5.0
	_lantern_panel.add_theme_stylebox_override("panel", lantern_style)

	_lantern_label = Label.new()
	_lantern_label.name = "LanternProgressLabel"
	_lantern_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lantern_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lantern_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lantern_label.add_theme_font_size_override("font_size", 14)
	_lantern_label.add_theme_color_override("font_color", COLOR_GOLD)
	_lantern_panel.add_child(_lantern_label)
	_root_control.add_child(_lantern_panel)


func _rebuild_choice_buttons(choices: Array) -> void:
	for child: Node in _choices_container.get_children():
		child.queue_free()

	if choices.is_empty():
		return

	var normal_style: StyleBoxFlat = _make_choice_style(
		Color(0.043137, 0.109804, 0.239216, 0.80),
		Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.45)
	)
	var hover_style: StyleBoxFlat = _make_choice_style(
		Color(0.137255, 0.207843, 0.341176, 0.94),
		COLOR_GOLD
	)
	var pressed_style: StyleBoxFlat = _make_choice_style(
		Color(0.196078, 0.262745, 0.376471, 0.96),
		COLOR_IVORY
	)

	for i in range(choices.size()):
		var choice_var: Variant = choices[i]
		var choice_text: String = ""
		if choice_var is Dictionary:
			var choice_dict: Dictionary = choice_var as Dictionary
			choice_text = str(choice_dict.get("text", ""))
		else:
			choice_text = str(choice_var)

		var btn: Button = Button.new()
		btn.text = "[%d]  %s" % [i + 1, choice_text]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(0.0, 36.0)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", COLOR_IVORY)
		btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
		btn.add_theme_color_override("font_focus_color", COLOR_GOLD)
		btn.add_theme_color_override("font_pressed_color", COLOR_IVORY)
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("focus", hover_style)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.pressed.connect(_on_choice_button_pressed.bind(i))
		_choices_container.add_child(btn)


func _make_choice_style(bg_col: Color, border_col: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_col
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_col
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _complete_typewriter() -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	_dialogue_text.visible_characters = -1
	_is_typewriting = false
	_on_typewriter_finished()


func _on_typewriter_finished() -> void:
	_is_typewriting = false
	if not _dialogue_active:
		return

	if _current_choices.is_empty():
		_choices_container.visible = false
		_continue_label.visible = true
	else:
		_continue_label.visible = false
		_choices_container.visible = true
		_choices_container.modulate.a = 0.0
		if _choices_tween and _choices_tween.is_valid():
			_choices_tween.kill()
		_choices_tween = create_tween()
		_choices_tween.tween_property(_choices_container, "modulate:a", 1.0, 0.25) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_dialogue_overlay.queue_redraw()


func _handle_dialogue_continue_input() -> void:
	if not _dialogue_active:
		return
	if _is_typewriting:
		_complete_typewriter()
		return
	if _current_choices.is_empty():
		dialogue_advance_requested.emit()


func _on_dialogue_panel_gui_input(event: InputEvent) -> void:
	if not _dialogue_active:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_dialogue_continue_input()


func _on_dialogue_panel_resized() -> void:
	if _dialogue_overlay != null:
		_dialogue_overlay.queue_redraw()
	if _dialogue_divider != null:
		_dialogue_divider.queue_redraw()


func _on_choice_button_pressed(choice_index: int) -> void:
	if not _dialogue_active:
		return
	if choice_index < 0 or choice_index >= _current_choices.size():
		return
	dialogue_choice_selected.emit(choice_index)


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

	for side: float in [-1.0, 1.0]:
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
	var col: Color = Color(_dialogue_accent.r, _dialogue_accent.g, _dialogue_accent.b, 0.42)
	_dialogue_divider.draw_line(Vector2(0.0, cy), Vector2(size.x * 0.45, cy), col, 1.0, true)
	var tip: PackedVector2Array = _make_diamond(Vector2(size.x * 0.45 + 4.0, cy), 2.5, 2.5)
	_dialogue_divider.draw_colored_polygon(tip, Color(_dialogue_accent.r, _dialogue_accent.g, _dialogue_accent.b, 0.78))


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
