class_name EarthLifeLesson1
extends Node3D

## Continuous 3D Interactive Controller for Chapter 1: "Было всё, кроме времени".
## Replaces the legacy 2D vignette with full 3D gameplay matching the Prologue aesthetic:
## - 3D Player exploration with third-person orbit camera
## - Golden Sunset environment & directional lighting with 4-cascade shadows
## - Continuous world with Family Courtyard, Megapolis Avenue, Pocket Park, Beach, and Sea Pier
## - 4 Interactive Memory Triggers loaded from lesson1_memories.json
## - Beautiful Pixar memory card UI with emotional poetry and branches
## - Memory Progress HUD Tracker ("Воспоминания: X / 4")
## - Emotional climax & return transition to Akasha Sanctuary (sunset_return)
## - ESC Pause Menu with Resume, Mute, and Main Menu options.

signal memory_activated(memory_id: String)
signal all_memories_completed

const MEMORIES_DATA_PATH: String = "res://data/dialogues/lesson1_memories.json"
const WORLD_3D_SCENE_PATH: String = "res://scenes/world_3d.tscn"

# Color Palette
const COLOR_INDIGO := Color(0.027, 0.078, 0.180, 1.0)
const COLOR_INDIGO_CARD := Color(0.027, 0.078, 0.180, 0.94)
const COLOR_GOLD := Color(0.965, 0.827, 0.420, 1.0) # #F6D36B
const COLOR_GOLD_WARM := Color(0.988, 0.867, 0.545, 1.0) # #FCDD8B
const COLOR_GOLD_MUTED := Color(0.55, 0.48, 0.32, 0.60)
const COLOR_IVORY := Color(1.0, 0.965, 0.85, 1.0)
const COLOR_IVORY_MUTED := Color(0.85, 0.82, 0.74, 0.85)

const TOTAL_MEMORIES: int = 4
const MEMORY_SEQUENCE_KEYS: Array[String] = [
	"memory_birthday",
	"memory_office",
	"memory_relatives",
	"memory_sea",
]

# Scene Node References
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var world_builder: EarthLifeWorldBuilder = $EarthLifeWorldBuilder
@onready var player: CharacterBody3D = $Player3D
@onready var audio_controller: Node = $EarthLifeAudio

# UI Node References
@onready var ui_layer: CanvasLayer = $UILayer
@onready var tracker_label: Label = $UILayer/HUD/TrackerContainer/TrackerHBox/TrackerLabel
@onready var tracker_dots_container: HBoxContainer = $UILayer/HUD/TrackerContainer/TrackerHBox/DotsContainer

@onready var prompt_anchor: Control = $UILayer/PromptAnchor
@onready var prompt_panel: PanelContainer = $UILayer/PromptAnchor/PromptPanel
@onready var prompt_label: Label = $UILayer/PromptAnchor/PromptPanel/PromptMargin/PromptLabel

@onready var memory_card_overlay: Control = $UILayer/MemoryCardOverlay
@onready var memory_card_panel: PanelContainer = $UILayer/MemoryCardOverlay/CenterAnchor/MemoryCardPanel
@onready var card_header_label: Label = $UILayer/MemoryCardOverlay/CenterAnchor/MemoryCardPanel/CardMargin/CardVBox/HeaderLabel
@onready var card_speaker_label: Label = $UILayer/MemoryCardOverlay/CenterAnchor/MemoryCardPanel/CardMargin/CardVBox/SpeakerLabel
@onready var card_body_label: Label = $UILayer/MemoryCardOverlay/CenterAnchor/MemoryCardPanel/CardMargin/CardVBox/BodyLabel
@onready var card_choices_vbox: VBoxContainer = $UILayer/MemoryCardOverlay/CenterAnchor/MemoryCardPanel/CardMargin/CardVBox/ChoicesVBox

@onready var climax_overlay: Control = $UILayer/ClimaxOverlay
@onready var climax_veil: ColorRect = $UILayer/ClimaxOverlay/ClimaxVeil
@onready var climax_text_label: Label = $UILayer/ClimaxOverlay/ClimaxCenter/ClimaxTextLabel

@onready var pause_overlay: Control = $UILayer/PauseOverlay
@onready var btn_resume: Button = $UILayer/PauseOverlay/PauseCenter/PauseCard/PauseMargin/PauseVBox/BtnResume
@onready var btn_mute: Button = $UILayer/PauseOverlay/PauseCenter/PauseCard/PauseMargin/PauseVBox/BtnMute
@onready var btn_main_menu: Button = $UILayer/PauseOverlay/PauseCenter/PauseCard/PauseMargin/PauseVBox/BtnMainMenu

# State
var _dialogue_data: Dictionary = {}
var _collected_memories: Array[String] = []
var _current_active_zone: String = ""
var _is_reading_memory: bool = false
var _is_paused: bool = false
var _is_climax_active: bool = false

# Dialogue sequence playback state
var _active_sequence_id: String = ""
var _active_nodes: Dictionary = {}
var _current_node_id: String = ""
var _tracker_dot_labels: Array[Label] = []


func _ready() -> void:
	_load_dialogue_data()
	_setup_ui_styles()
	_setup_audio_state()
	_connect_events()
	_update_tracker_hud()

	# Hide popups initially
	prompt_anchor.visible = false
	memory_card_overlay.visible = false
	climax_overlay.visible = false
	pause_overlay.visible = false

	# Position player at initial Courtyard spawn point if player exists
	if player != null:
		player.transform.origin = Vector3(0.0, 0.5, 34.0)
		player.input_enabled = true


func _unhandled_input(event: InputEvent) -> void:
	if _is_climax_active:
		return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		if _is_reading_memory:
			_close_memory_card()
		else:
			_toggle_pause_menu()
		return

	# Handle [E] key for interaction
	if event is InputEventKey:
		var k_ev := event as InputEventKey
		if k_ev.pressed and not k_ev.echo and (k_ev.keycode == KEY_E or k_ev.physical_keycode == KEY_E):
			if not _is_reading_memory and not _current_active_zone.is_empty() and not _is_paused:
				get_viewport().set_input_as_handled()
				_start_memory_dialogue(_current_active_zone)


# ---------------------------------------------------------------------------
# Setup & Event Connections
# ---------------------------------------------------------------------------

func _connect_events() -> void:
	if world_builder != null:
		world_builder.memory_zone_entered.connect(_on_memory_zone_entered)
		world_builder.memory_zone_exited.connect(_on_memory_zone_exited)

	if btn_resume != null:
		btn_resume.pressed.connect(_on_resume_pressed)
	if btn_mute != null:
		btn_mute.pressed.connect(_on_mute_pressed)
	if btn_main_menu != null:
		btn_main_menu.pressed.connect(_on_main_menu_pressed)


func _load_dialogue_data() -> void:
	if not FileAccess.file_exists(MEMORIES_DATA_PATH):
		push_warning("EarthLifeLesson1: Dialogue file not found at " + MEMORIES_DATA_PATH)
		return

	var file := FileAccess.open(MEMORIES_DATA_PATH, FileAccess.READ)
	if file != null:
		var content := file.get_as_text()
		file.close()
		var parsed: Variant = JSON.parse_string(content)
		if parsed is Dictionary:
			_dialogue_data = parsed as Dictionary


func _setup_audio_state() -> void:
	if audio_controller != null and audio_controller.has_method("set_mood"):
		audio_controller.call("set_mood", "winter")


# ---------------------------------------------------------------------------
# Memory Zone Triggers
# ---------------------------------------------------------------------------

func _on_memory_zone_entered(zone_id: String, _zone_data: Dictionary) -> void:
	if _is_climax_active:
		return

	_current_active_zone = zone_id

	# Only show interaction prompt if memory is not yet collected
	if not _collected_memories.has(zone_id):
		prompt_anchor.visible = true
		_play_prompt_pulse()
	else:
		prompt_anchor.visible = false

	# Gently adjust audio mood according to the zone
	if audio_controller != null and audio_controller.has_method("set_mood"):
		match zone_id:
			"memory_birthday":
				audio_controller.call("set_mood", "winter")
			"memory_office":
				audio_controller.call("set_mood", "spring")
			"memory_relatives":
				audio_controller.call("set_mood", "room")
			"memory_sea":
				audio_controller.call("set_mood", "sea")


func _on_memory_zone_exited(zone_id: String) -> void:
	if _current_active_zone == zone_id:
		_current_active_zone = ""
		prompt_anchor.visible = false


func _play_prompt_pulse() -> void:
	prompt_panel.scale = Vector2(0.9, 0.9)
	var t := create_tween()
	t.tween_property(prompt_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------------------
# Memory Reader UI Card & Branching Dialogue
# ---------------------------------------------------------------------------

func _start_memory_dialogue(memory_id: String) -> void:
	var sequences: Dictionary = _dialogue_data.get("sequences", {}) as Dictionary
	if not sequences.has(memory_id):
		push_warning("EarthLifeLesson1: No sequence data found for " + memory_id)
		return

	var seq_data: Dictionary = sequences[memory_id] as Dictionary
	_active_sequence_id = memory_id
	_active_nodes = seq_data.get("nodes", {}) as Dictionary
	_current_node_id = str(seq_data.get("start", ""))

	_is_reading_memory = true
	prompt_anchor.visible = false
	memory_card_overlay.visible = true

	# Release mouse and pause player movement
	if player != null:
		player.input_enabled = false

	if audio_controller != null and audio_controller.has_method("play_bubble_pop"):
		audio_controller.call("play_bubble_pop", 2)

	_present_current_node()


func _present_current_node() -> void:
	if not _active_nodes.has(_current_node_id):
		_finish_active_memory()
		return

	var node_data: Dictionary = _active_nodes[_current_node_id] as Dictionary
	var speaker_id: String = str(node_data.get("speaker", "soul_echo"))
	var text: String = str(node_data.get("text", ""))
	var next_id: String = str(node_data.get("next", ""))
	var choices: Array = node_data.get("choices", []) as Array

	# Header title: e.g. "ВОСПОМИНАНИЕ I: ДЕНЬ РОЖДЕНИЯ СРЕДИ ПОДАРКОВ"
	var seq_index: int = MEMORY_SEQUENCE_KEYS.find(_active_sequence_id) + 1
	var seq_title: String = _get_sequence_title(_active_sequence_id)
	card_header_label.text = "ВОСПОМИНАНИЕ %s  ·  %s" % [_to_roman(seq_index), seq_title.to_upper()]

	# Speaker info
	var speakers: Dictionary = _dialogue_data.get("speakers", {}) as Dictionary
	var spk_data: Dictionary = speakers.get(speaker_id, {}) as Dictionary
	var spk_title: String = str(spk_data.get("title", "ЭХО ДУШИ"))
	var spk_accent_str: String = str(spk_data.get("accent", "#F6D36B"))
	var spk_color := Color(spk_accent_str)

	card_speaker_label.text = spk_title
	card_speaker_label.modulate = spk_color

	# Set dialogue text
	card_body_label.text = text

	# Clear previous choice buttons
	for child: Node in card_choices_vbox.get_children():
		child.queue_free()

	# If branching choices exist, instantiate choice buttons
	if not choices.is_empty():
		for ch_raw in choices:
			var ch: Dictionary = ch_raw as Dictionary
			var ch_btn := Button.new()
			ch_btn.text = str(ch.get("text", ""))
			ch_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			ch_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_style_choice_button(ch_btn)
			var next_target: String = str(ch.get("next", ""))
			ch_btn.pressed.connect(_on_choice_selected.bind(next_target))
			card_choices_vbox.add_child(ch_btn)
	else:
		# Single Continue / Finish button
		var cont_btn := Button.new()
		if next_id.is_empty():
			cont_btn.text = "Запечатлеть воспоминание ✦"
			cont_btn.pressed.connect(_finish_active_memory)
		else:
			cont_btn.text = "Продолжить..."
			cont_btn.pressed.connect(_on_continue_pressed.bind(next_id))
		_style_choice_button(cont_btn)
		card_choices_vbox.add_child(cont_btn)

	# Gentle card entrance tween
	memory_card_panel.modulate.a = 0.0
	memory_card_panel.scale = Vector2(0.96, 0.96)
	var t := create_tween()
	t.tween_property(memory_card_panel, "modulate:a", 1.0, 0.22)
	t.parallel().tween_property(memory_card_panel, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_SINE)


func _on_continue_pressed(next_id: String) -> void:
	if audio_controller != null and audio_controller.has_method("play_ui_click"):
		audio_controller.call("play_ui_click")
	_current_node_id = next_id
	_present_current_node()


func _on_choice_selected(next_id: String) -> void:
	if audio_controller != null and audio_controller.has_method("play_choice_chime"):
		audio_controller.call("play_choice_chime")
	_current_node_id = next_id
	_present_current_node()


func _finish_active_memory() -> void:
	if not _collected_memories.has(_active_sequence_id):
		_collected_memories.append(_active_sequence_id)
		if world_builder != null:
			world_builder.mark_memory_completed(_active_sequence_id)
		memory_activated.emit(_active_sequence_id)

	if audio_controller != null and audio_controller.has_method("play_sun_complete"):
		audio_controller.call("play_sun_complete")

	_close_memory_card()
	_update_tracker_hud()

	# Check if all 4 memories are completed
	if _collected_memories.size() >= TOTAL_MEMORIES:
		_trigger_emotional_climax()


func _close_memory_card() -> void:
	_is_reading_memory = false
	memory_card_overlay.visible = false

	# Restore player control
	if player != null and not _is_climax_active and not _is_paused:
		player.input_enabled = true


# ---------------------------------------------------------------------------
# HUD Progress Tracker
# ---------------------------------------------------------------------------

func _update_tracker_hud() -> void:
	var count: int = _collected_memories.size()
	tracker_label.text = "ВОСПОМИНАНИЯ: %d / %d" % [count, TOTAL_MEMORIES]

	for i in range(TOTAL_MEMORIES):
		if i < _tracker_dot_labels.size():
			var dot: Label = _tracker_dot_labels[i]
			if i < count:
				dot.modulate = COLOR_GOLD
				dot.text = "✦"
			else:
				dot.modulate = COLOR_GOLD_MUTED
				dot.text = "✧"


# ---------------------------------------------------------------------------
# Emotional Climax & Scene Flow Transition
# ---------------------------------------------------------------------------

func _trigger_emotional_climax() -> void:
	_is_climax_active = true
	all_memories_completed.emit()

	if player != null:
		player.input_enabled = false

	prompt_anchor.visible = false
	climax_overlay.visible = true

	if audio_controller != null and audio_controller.has_method("play_ascension_chord"):
		audio_controller.call("play_ascension_chord")

	climax_text_label.modulate.a = 0.0
	climax_veil.modulate.a = 0.0

	var t := create_tween()
	# Warm golden veil fades in over 2.4s
	t.tween_property(climax_veil, "modulate:a", 0.95, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(climax_text_label, "modulate:a", 1.0, 1.8)
	t.tween_interval(3.5)
	t.tween_callback(_complete_and_transition_to_sanctuary)


func _complete_and_transition_to_sanctuary() -> void:
	# Update SaveManager lesson1 stage to sunset_return
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr != null:
		if save_mgr.has_method("set_lesson1_stage"):
			save_mgr.call("set_lesson1_stage", "sunset_return")
		elif "lesson1_stage" in save_mgr:
			save_mgr.set("lesson1_stage", "sunset_return")
		if save_mgr.has_method("save_game"):
			save_mgr.call("save_game")

	# Set SceneFlowManager pending mode and trigger transition
	var flow_mgr: Node = get_node_or_null("/root/SceneFlowManager")
	if flow_mgr != null:
		flow_mgr.set("pending_world_mode", "lesson1_sunset_return")
		if flow_mgr.has_method("transition_to_scene"):
			flow_mgr.call("transition_to_scene", WORLD_3D_SCENE_PATH, true)
			return

	# Fallback direct scene tree transition
	get_tree().change_scene_to_file(WORLD_3D_SCENE_PATH)


# ---------------------------------------------------------------------------
# Pause Menu
# ---------------------------------------------------------------------------

func _toggle_pause_menu() -> void:
	_is_paused = not _is_paused
	pause_overlay.visible = _is_paused

	if player != null:
		player.input_enabled = not _is_paused

	if _is_paused:
		_update_mute_button_label()


func _on_resume_pressed() -> void:
	if audio_controller != null and audio_controller.has_method("play_ui_click"):
		audio_controller.call("play_ui_click")
	_toggle_pause_menu()


func _on_mute_pressed() -> void:
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr != null and "audio_muted" in save_mgr:
		var current_mute: bool = bool(save_mgr.get("audio_muted"))
		save_mgr.set("audio_muted", not current_mute)
	_update_mute_button_label()


func _update_mute_button_label() -> void:
	var is_muted: bool = false
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr != null and "audio_muted" in save_mgr:
		is_muted = bool(save_mgr.get("audio_muted"))
	btn_mute.text = "ЗВУК: " + ("ВЫКЛ" if is_muted else "ВКЛ")


func _on_main_menu_pressed() -> void:
	_complete_and_transition_to_sanctuary()


# ---------------------------------------------------------------------------
# UI Styling Helpers
# ---------------------------------------------------------------------------

func _setup_ui_styles() -> void:
	# Card panel style
	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = COLOR_INDIGO_CARD
	card_sb.border_color = COLOR_GOLD
	card_sb.set_border_width_all(2)
	card_sb.set_corner_radius_all(14)
	card_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	card_sb.shadow_size = 18
	memory_card_panel.add_theme_stylebox_override("panel", card_sb)

	# Prompt panel style
	var prompt_sb := StyleBoxFlat.new()
	prompt_sb.bg_color = Color(0.027, 0.078, 0.180, 0.90)
	prompt_sb.border_color = COLOR_GOLD_WARM
	prompt_sb.set_border_width_all(1)
	prompt_sb.set_corner_radius_all(8)
	prompt_panel.add_theme_stylebox_override("panel", prompt_sb)

	# Tracker panel style
	var tracker_sb := StyleBoxFlat.new()
	tracker_sb.bg_color = Color(0.027, 0.078, 0.180, 0.85)
	tracker_sb.border_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.5)
	tracker_sb.set_border_width_all(1)
	tracker_sb.set_corner_radius_all(10)
	var tracker_container: PanelContainer = $UILayer/HUD/TrackerContainer
	tracker_container.add_theme_stylebox_override("panel", tracker_sb)

	# Setup 4 tracker dot labels
	_tracker_dot_labels.clear()
	for child: Node in tracker_dots_container.get_children():
		child.queue_free()

	for i in range(TOTAL_MEMORIES):
		var dot := Label.new()
		dot.text = "✧"
		dot.modulate = COLOR_GOLD_MUTED
		tracker_dots_container.add_child(dot)
		_tracker_dot_labels.append(dot)


func _style_choice_button(btn: Button) -> void:
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.08, 0.16, 0.32, 0.88)
	sb_normal.border_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.65)
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(8)
	sb_normal.content_margin_left = 16.0
	sb_normal.content_margin_right = 16.0
	sb_normal.content_margin_top = 10.0
	sb_normal.content_margin_bottom = 10.0

	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.14, 0.25, 0.48, 0.96)
	sb_hover.border_color = COLOR_GOLD_WARM
	sb_hover.set_border_width_all(2)
	sb_hover.set_corner_radius_all(8)
	sb_hover.content_margin_left = 16.0
	sb_hover.content_margin_right = 16.0
	sb_hover.content_margin_top = 10.0
	sb_hover.content_margin_bottom = 10.0

	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_stylebox_override("focus", sb_hover)
	btn.add_theme_color_override("font_color", COLOR_IVORY)
	btn.add_theme_color_override("font_hover_color", COLOR_GOLD_WARM)


func _get_sequence_title(seq_id: String) -> String:
	var sequences: Dictionary = _dialogue_data.get("sequences", {}) as Dictionary
	if sequences.has(seq_id):
		var s_data: Dictionary = sequences[seq_id] as Dictionary
		return str(s_data.get("title", seq_id))
	return seq_id


func _to_roman(n: int) -> String:
	match n:
		1: return "I"
		2: return "II"
		3: return "III"
		4: return "IV"
		_: return str(n)
