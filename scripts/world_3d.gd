extends Node3D

## Root orchestrator for the SoulBlueprint 3D Sky-style Playable Prologue (Vertical Slice).
## Coordinates MainMenu + TitleCameraRig, seamless intro.ogv playback via SceneFlowManager,
## SaveManager persistence, StoneLantern3D awakening, multi-step Alatea & Mira First Contract
## dialogue (JSON), SanctuaryMentors3D, EarthMirror3D awakening, and Prologue Epilogue.

const STONE_LANTERN_SCENE: PackedScene = preload("res://scenes/interactables/stone_lantern_3d.tscn")
const INTRO_VIDEO_PATH: String = "res://assets/videos/intro.ogv"
const START_PLAYER_POS: Vector3 = Vector3(0.0, 1.3, 36.0)
const DAIS_RETURN_POS: Vector3 = Vector3(0.0, 9.4, -260.0)

@onready var architecture: Node3D = $AkashaArchitecture
@onready var player: CharacterBody3D = $Player3D
@onready var soul_call: Node3D = $SoulCall3D
@onready var sky_hud: CanvasLayer = $SkyHUD
@onready var main_menu: CanvasLayer = $MainMenu
@onready var title_camera_rig: Node3D = $TitleCameraRig
@onready var dialogue_manager: Node = $DialogueManager
@onready var audio_manager: Node = $AkashaAudioManager
@onready var sanctuary_mentors: Node3D = $SanctuaryMentors3D
@onready var earth_mirror: Node3D = $EarthMirror3D

var _prev_wing_energy: float = 5.0
var _lantern_container: Node3D
var _lantern_nodes: Array[Node3D] = []
var _total_lanterns: int = 9

var _is_in_gameplay: bool = false
var _is_transitioning: bool = false
var _arrival_greeting_shown: bool = false
var _epilogue_triggered: bool = false
var _active_prompt_text: String = ""
var _checkpoint_timer: float = 0.0


func _ready() -> void:
	_spawn_lanterns()
	_connect_signals()
	_apply_audio_setting()
	_enter_main_menu_immediate()


func _spawn_lanterns() -> void:
	if _lantern_container != null and is_instance_valid(_lantern_container):
		_lantern_container.queue_free()
	_lantern_nodes.clear()

	_lantern_container = Node3D.new()
	_lantern_container.name = "StoneLanterns"
	add_child(_lantern_container)

	if architecture and architecture.has_method("get_lantern_anchor_positions"):
		var anchors: Array = architecture.call("get_lantern_anchor_positions")
		_total_lanterns = anchors.size()
		for idx: int in range(anchors.size()):
			var lantern: Node3D = STONE_LANTERN_SCENE.instantiate() as Node3D
			lantern.name = "StoneLantern_%02d" % idx
			lantern.position = anchors[idx]
			if SaveManager != null and SaveManager.is_lantern_awakened(idx):
				lantern.set("start_awakened", true)
			_lantern_container.add_child(lantern)
			if lantern.has_signal("awakened"):
				lantern.connect("awakened", _on_lantern_awakened.bind(idx))
			_lantern_nodes.append(lantern)


func _connect_signals() -> void:
	if player:
		if player.has_signal("soul_call_triggered"):
			player.connect("soul_call_triggered", _on_player_soul_call)
		if player.has_signal("wing_energy_changed"):
			player.connect("wing_energy_changed", _on_player_wing_energy_changed)
		if player.has_signal("flight_mode_changed"):
			player.connect("flight_mode_changed", _on_player_flight_mode_changed)

	if main_menu:
		if main_menu.has_signal("start_new_game_requested"):
			main_menu.connect("start_new_game_requested", _on_start_new_game_requested)
		if main_menu.has_signal("continue_game_requested"):
			main_menu.connect("continue_game_requested", _on_continue_game_requested)
		if main_menu.has_signal("audio_toggled"):
			main_menu.connect("audio_toggled", _on_audio_toggled)
		if main_menu.has_signal("quit_requested"):
			main_menu.connect("quit_requested", _on_quit_requested)

	if dialogue_manager:
		if dialogue_manager.has_signal("dialogue_started"):
			dialogue_manager.connect("dialogue_started", _on_dialogue_started)
		if dialogue_manager.has_signal("line_presented"):
			dialogue_manager.connect("line_presented", _on_dialogue_line_presented)
		if dialogue_manager.has_signal("choice_recorded"):
			dialogue_manager.connect("choice_recorded", _on_dialogue_choice_recorded)
		if dialogue_manager.has_signal("dialogue_ended"):
			dialogue_manager.connect("dialogue_ended", _on_dialogue_ended)

	if sky_hud:
		if sky_hud.has_signal("dialogue_advance_requested"):
			sky_hud.connect("dialogue_advance_requested", _on_hud_dialogue_advance)
		if sky_hud.has_signal("dialogue_choice_selected"):
			sky_hud.connect("dialogue_choice_selected", _on_hud_dialogue_choice)

	if earth_mirror:
		if earth_mirror.has_signal("mirror_awakened"):
			earth_mirror.connect("mirror_awakened", _on_mirror_awakened)
		if earth_mirror.has_signal("player_entered_portal"):
			earth_mirror.connect("player_entered_portal", _on_player_entered_portal)


func _apply_audio_setting() -> void:
	if audio_manager and audio_manager.has_method("set_muted") and SaveManager != null:
		audio_manager.call("set_muted", SaveManager.audio_muted)


# ---------------------------------------------------------------------------
# Main Menu & Session Lifecycle
# ---------------------------------------------------------------------------

func _enter_main_menu_immediate() -> void:
	_is_in_gameplay = false
	_set_player_control(false)
	_set_player_camera_current(false)
	if title_camera_rig and title_camera_rig.has_method("activate"):
		title_camera_rig.call("activate")
	if sky_hud and sky_hud.has_method("set_hud_visible"):
		sky_hud.call("set_hud_visible", false)
	if sky_hud and sky_hud.has_method("hide_interaction_prompt"):
		sky_hud.call("hide_interaction_prompt")
	_active_prompt_text = ""

	var has_save: bool = SaveManager != null and SaveManager.has_save_data()
	var is_muted: bool = SaveManager != null and SaveManager.audio_muted
	if main_menu and main_menu.has_method("show_menu"):
		main_menu.call("show_menu", has_save, is_muted)


func _on_start_new_game_requested() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if main_menu and main_menu.has_method("hide_menu"):
		main_menu.call("hide_menu")

	if SaveManager != null:
		SaveManager.reset_save()

	_arrival_greeting_shown = false
	_epilogue_triggered = false
	_reset_world_for_new_game()

	# Switch behind-the-scenes camera to Player3D so the intro video dissolves right into Spark
	if title_camera_rig and title_camera_rig.has_method("deactivate"):
		title_camera_rig.call("deactivate")
	_set_player_camera_current(true)

	if SceneFlowManager != null:
		SceneFlowManager.play_cutscene_video(INTRO_VIDEO_PATH, _on_intro_completed)
	else:
		_on_intro_completed()


func _on_continue_game_requested() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if main_menu and main_menu.has_method("hide_menu"):
		main_menu.call("hide_menu")

	if SceneFlowManager != null:
		await SceneFlowManager.fade_to_veil(0.65, true)

	_restore_world_from_save()

	if title_camera_rig and title_camera_rig.has_method("deactivate"):
		title_camera_rig.call("deactivate")
	_set_player_camera_current(true)

	_begin_gameplay(false)

	if SceneFlowManager != null:
		await SceneFlowManager.fade_from_veil(0.9)

	_is_transitioning = false


func _on_intro_completed() -> void:
	if SaveManager != null:
		SaveManager.set_prologue_stage("exploring")
	_begin_gameplay(true)
	_is_transitioning = false


func _begin_gameplay(show_title: bool) -> void:
	_is_in_gameplay = true
	if sky_hud and sky_hud.has_method("set_hud_visible"):
		sky_hud.call("set_hud_visible", true)
	_set_player_control(true)

	if show_title and sky_hud and sky_hud.has_method("show_chapter_title"):
		sky_hud.call("show_chapter_title", "П Р О Л О Г", "Обитель Хроник Акаши", 4.5)

	if SaveManager != null:
		var awakened_count: int = SaveManager.get_awakened_lantern_count()
		if awakened_count > 0 and sky_hud and sky_hud.has_method("show_lantern_progress"):
			sky_hud.call("show_lantern_progress", awakened_count, _total_lanterns)


func _reset_world_for_new_game() -> void:
	_spawn_lanterns()
	if player:
		player.global_position = START_PLAYER_POS
		player.velocity = Vector3.ZERO
	if earth_mirror and earth_mirror.has_method("reset_to_dormant"):
		earth_mirror.call("reset_to_dormant")
	if sanctuary_mentors and sanctuary_mentors.has_method("highlight_speaker"):
		sanctuary_mentors.call("highlight_speaker", "")


func _restore_world_from_save() -> void:
	_spawn_lanterns()
	if SaveManager == null:
		return

	var stage: String = SaveManager.prologue_stage
	_epilogue_triggered = false
	_arrival_greeting_shown = stage != "intro" and stage != "exploring"

	if player:
		if SaveManager.has_custom_player_pos:
			player.global_position = SaveManager.last_player_pos
		else:
			player.global_position = START_PLAYER_POS
		player.velocity = Vector3.ZERO

	if earth_mirror:
		if stage == "contract_spoken":
			if earth_mirror.has_method("set_ready_for_call"):
				earth_mirror.call("set_ready_for_call")
		elif stage == "mirror_awakened" or stage == "prologue_complete":
			if earth_mirror.has_method("awaken_mirror"):
				earth_mirror.call("awaken_mirror")


func _return_to_main_menu() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if SaveManager != null and player != null and _is_in_gameplay:
		SaveManager.save_player_checkpoint(player.global_position)

	if SceneFlowManager != null:
		await SceneFlowManager.fade_to_veil(0.65, true)

	_enter_main_menu_immediate()

	if SceneFlowManager != null:
		await SceneFlowManager.fade_from_veil(0.85)

	_is_transitioning = false


func _on_audio_toggled(muted: bool) -> void:
	if SaveManager != null:
		SaveManager.set_audio_muted(muted)
	if audio_manager and audio_manager.has_method("set_muted"):
		audio_manager.call("set_muted", muted)


func _on_quit_requested() -> void:
	get_tree().quit()


# ---------------------------------------------------------------------------
# Player, Camera & Input Helpers
# ---------------------------------------------------------------------------

func _set_player_control(enabled: bool) -> void:
	if player and "input_enabled" in player:
		player.set("input_enabled", enabled)
	if not enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _set_player_camera_current(is_current: bool) -> void:
	if not player:
		return
	var cam: Camera3D = player.get_node_or_null("CameraRig/SpringArm3D/Camera3D") as Camera3D
	if cam != null:
		cam.current = is_current


func _unhandled_input(event: InputEvent) -> void:
	if not _is_in_gameplay or _is_transitioning:
		return
	if dialogue_manager and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		return

	if event is InputEventKey:
		var key_ev: InputEventKey = event as InputEventKey
		if key_ev.pressed and not key_ev.echo and key_ev.keycode == KEY_ESCAPE:
			# If mouse is already released (not captured by 3D look), Escape opens the Main Menu
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				get_viewport().set_input_as_handled()
				_return_to_main_menu()


# ---------------------------------------------------------------------------
# Gameplay Signals (Soul Call, Lanterns, Mentors, Earth Mirror)
# ---------------------------------------------------------------------------

func _on_player_soul_call(origin: Vector3) -> void:
	if soul_call and soul_call.has_method("trigger"):
		soul_call.call("trigger", origin)
	if audio_manager and audio_manager.has_method("play_soul_call"):
		audio_manager.call("play_soul_call")

	# 1. Check if Earth Mirror is ready for awakening via Soul Call [Q]
	if earth_mirror and earth_mirror.has_method("respond_to_soul_call"):
		var mirror_awakened_now: bool = bool(earth_mirror.call("respond_to_soul_call", origin))
		if mirror_awakened_now:
			return

	# 2. Check if player is calling to Alatea & Mira on the Cathedral dais
	if sanctuary_mentors and sanctuary_mentors.has_method("respond_to_soul_call"):
		var mentors_responded: bool = bool(sanctuary_mentors.call("respond_to_soul_call", origin))
		if mentors_responded:
			var stage: String = SaveManager.prologue_stage if SaveManager != null else "exploring"
			if stage == "exploring" or stage == "intro":
				_start_dialogue_sequence("first_contract")


func _on_player_wing_energy_changed(current: float, max_energy: float) -> void:
	if current < _prev_wing_energy - 0.5:
		if audio_manager and audio_manager.has_method("play_wing_flap"):
			audio_manager.call("play_wing_flap")
	_prev_wing_energy = current

	if sky_hud and sky_hud.has_method("update_wing_energy"):
		sky_hud.call("update_wing_energy", current, max_energy)


func _on_player_flight_mode_changed(is_flying: bool) -> void:
	if is_flying and sky_hud and sky_hud.has_method("hide_flight_hint"):
		sky_hud.call("hide_flight_hint")


func _on_lantern_awakened(_lantern: Node, index: int) -> void:
	if audio_manager and audio_manager.has_method("play_lantern_chime"):
		audio_manager.call("play_lantern_chime", index)
	if SaveManager != null:
		SaveManager.mark_lantern_awakened(index)
		var count: int = SaveManager.get_awakened_lantern_count()
		if sky_hud and sky_hud.has_method("show_lantern_progress"):
			sky_hud.call("show_lantern_progress", count, _total_lanterns)


# ---------------------------------------------------------------------------
# Dialogue Orchestration (Alatea & Mira)
# ---------------------------------------------------------------------------

func _start_dialogue_sequence(sequence_id: String) -> void:
	if not dialogue_manager or not dialogue_manager.has_method("start_sequence"):
		return
	if dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		return
	dialogue_manager.call("start_sequence", sequence_id)


func _on_dialogue_started(_sequence_id: String) -> void:
	_set_player_control(false)
	_update_prompt("")


func _on_dialogue_line_presented(
	speaker_id: String,
	speaker_title: String,
	accent_color: Color,
	text: String,
	choices: Array
) -> void:
	if sanctuary_mentors and sanctuary_mentors.has_method("highlight_speaker"):
		sanctuary_mentors.call("highlight_speaker", speaker_id)
	if audio_manager and audio_manager.has_method("play_mentor_chord"):
		audio_manager.call("play_mentor_chord", speaker_id)
	if sky_hud and sky_hud.has_method("show_dialogue_step"):
		sky_hud.call("show_dialogue_step", speaker_title, text, accent_color, choices)


func _on_dialogue_choice_recorded(choice_key: String, choice_id: String) -> void:
	if audio_manager and audio_manager.has_method("play_choice_chime"):
		audio_manager.call("play_choice_chime")
	if SaveManager != null:
		SaveManager.record_choice(choice_key, choice_id)


func _on_hud_dialogue_advance() -> void:
	if dialogue_manager and dialogue_manager.has_method("advance"):
		dialogue_manager.call("advance")


func _on_hud_dialogue_choice(choice_index: int) -> void:
	if dialogue_manager and dialogue_manager.has_method("select_choice"):
		dialogue_manager.call("select_choice", choice_index)


func _on_dialogue_ended(sequence_id: String) -> void:
	if sky_hud and sky_hud.has_method("hide_dialogue"):
		sky_hud.call("hide_dialogue")
	if sanctuary_mentors and sanctuary_mentors.has_method("highlight_speaker"):
		sanctuary_mentors.call("highlight_speaker", "")

	if sequence_id == "first_contract":
		if SaveManager != null:
			SaveManager.set_prologue_stage("contract_spoken")
		if earth_mirror and earth_mirror.has_method("set_ready_for_call"):
			earth_mirror.call("set_ready_for_call")

	_set_player_control(true)


# ---------------------------------------------------------------------------
# Earth Mirror & Prologue Completion
# ---------------------------------------------------------------------------

func _on_mirror_awakened() -> void:
	if audio_manager and audio_manager.has_method("play_mirror_awakening"):
		audio_manager.call("play_mirror_awakening")
	if SaveManager != null and SaveManager.prologue_stage != "prologue_complete":
		SaveManager.set_prologue_stage("mirror_awakened")


func _on_player_entered_portal() -> void:
	if _epilogue_triggered or _is_transitioning or not _is_in_gameplay:
		return
	_trigger_prologue_completion()


func _trigger_prologue_completion() -> void:
	_epilogue_triggered = true
	_is_transitioning = true
	_set_player_control(false)
	_update_prompt("")

	if audio_manager and audio_manager.has_method("play_mirror_awakening"):
		audio_manager.call("play_mirror_awakening")
	if SaveManager != null:
		SaveManager.set_prologue_stage("prologue_complete")
		SaveManager.save_player_checkpoint(DAIS_RETURN_POS)

	if SceneFlowManager != null:
		await SceneFlowManager.fade_to_veil(1.25, true)
		var awakened_count: int = SaveManager.get_awakened_lantern_count() if SaveManager != null else 0
		SceneFlowManager.show_prologue_epilogue(
			awakened_count,
			_total_lanterns,
			_on_epilogue_continue_exploring,
			_on_epilogue_return_menu
		)

	_is_transitioning = false


func _on_epilogue_continue_exploring() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if SceneFlowManager != null:
		SceneFlowManager.hide_prologue_epilogue()

	if player:
		player.global_position = DAIS_RETURN_POS
		player.velocity = Vector3.ZERO

	if SceneFlowManager != null:
		await SceneFlowManager.fade_from_veil(1.0)

	_epilogue_triggered = false
	if earth_mirror and earth_mirror.has_method("reset_portal_trigger"):
		earth_mirror.call("reset_portal_trigger")
	_set_player_control(true)
	_is_transitioning = false


func _on_epilogue_return_menu() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if SceneFlowManager != null:
		SceneFlowManager.hide_prologue_epilogue()

	_enter_main_menu_immediate()

	if SceneFlowManager != null:
		await SceneFlowManager.fade_from_veil(0.95)

	_epilogue_triggered = false
	_is_transitioning = false


# ---------------------------------------------------------------------------
# Per-Frame Contextual Prompts, Triggers & Autosave Checkpoints
# ---------------------------------------------------------------------------

func _update_prompt(new_text: String) -> void:
	if new_text == _active_prompt_text:
		return
	_active_prompt_text = new_text
	if not sky_hud:
		return
	if new_text.is_empty():
		if sky_hud.has_method("hide_interaction_prompt"):
			sky_hud.call("hide_interaction_prompt")
	else:
		if sky_hud.has_method("show_interaction_prompt"):
			sky_hud.call("show_interaction_prompt", new_text)


func _process(delta: float) -> void:
	if not _is_in_gameplay or _is_transitioning or not player:
		return

	var is_talking: bool = dialogue_manager != null and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active"))
	if is_talking:
		return

	# Periodic safe checkpoint autosave while grounded
	_checkpoint_timer += delta
	if _checkpoint_timer >= 8.0 and player.is_on_floor():
		_checkpoint_timer = 0.0
		if SaveManager != null:
			SaveManager.save_player_checkpoint(player.global_position)

	var p_pos: Vector3 = player.global_position
	var stage: String = SaveManager.prologue_stage if SaveManager != null else "exploring"

	# 1. Warm arrival greeting when approaching the Cathedral grand stairs
	if not _arrival_greeting_shown and stage == "exploring" and p_pos.z < -210.0:
		_arrival_greeting_shown = true
		_start_dialogue_sequence("cathedral_arrival")
		return

	# 2. Check portal step-in when Earth Mirror is awakened
	if earth_mirror and earth_mirror.has_method("is_player_in_portal_zone"):
		if bool(earth_mirror.call("is_player_in_portal_zone", p_pos)):
			_trigger_prologue_completion()
			return

	# 3. Contextual gentle Sky-style interaction prompts
	var prompt: String = ""
	if stage == "exploring" or stage == "intro":
		if sanctuary_mentors and sanctuary_mentors.has_method("is_player_in_talk_range"):
			if bool(sanctuary_mentors.call("is_player_in_talk_range", p_pos)):
				prompt = "✦  [Q]  Откликнуться Наставникам"
	elif stage == "contract_spoken":
		if earth_mirror and earth_mirror.has_method("is_player_near_call_zone"):
			if bool(earth_mirror.call("is_player_near_call_zone", p_pos)):
				prompt = "✦  [Q]  Пробудить Зеркало Земли"
	elif stage == "mirror_awakened" or stage == "prologue_complete":
		if earth_mirror and earth_mirror.has_method("is_player_near_call_zone"):
			if bool(earth_mirror.call("is_player_near_call_zone", p_pos)):
				prompt = "✦  Шагните в Зеркало Земли"

	_update_prompt(prompt)
