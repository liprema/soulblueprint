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
var _dust_motes: GPUParticles3D = null
var _sakura_petals: GPUParticles3D = null
var _garden_decorator: AkashaGardenDecorator = null
var _castle_interactables: CastleInteractables3D = null
var _infinite_vista: AkashaInfiniteVista = null
var _akasha_npcs: AkashaNPCs3D = null

var _is_in_gameplay: bool = false
var _is_transitioning: bool = false
var _arrival_greeting_shown: bool = false
var _epilogue_triggered: bool = false
var _active_prompt_text: String = ""
var _checkpoint_timer: float = 0.0


func _ready() -> void:
	_spawn_lanterns()
	_setup_garden_decorator()
	_setup_castle_interactables()
	_setup_infinite_vista()
	_setup_akasha_npcs()
	_ensure_vista_camera_clip_planes()
	_setup_atmospheric_dust_motes()
	_setup_sakura_petals()
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


func _setup_garden_decorator() -> void:
	if _garden_decorator != null and is_instance_valid(_garden_decorator):
		_garden_decorator.queue_free()

	_garden_decorator = AkashaGardenDecorator.new()
	_garden_decorator.name = "AkashaGardenDecorator"
	add_child(_garden_decorator)
	_garden_decorator.populate_garden(architecture)


func _setup_castle_interactables() -> void:
	if _castle_interactables != null and is_instance_valid(_castle_interactables):
		_castle_interactables.queue_free()

	_castle_interactables = CastleInteractables3D.new()
	_castle_interactables.name = "CastleInteractables3D"
	add_child(_castle_interactables)


func _setup_infinite_vista() -> void:
	if _infinite_vista != null and is_instance_valid(_infinite_vista):
		_infinite_vista.queue_free()

	_infinite_vista = AkashaInfiniteVista.new()
	_infinite_vista.name = "AkashaInfiniteVista"
	add_child(_infinite_vista)


func _setup_akasha_npcs() -> void:
	if _akasha_npcs != null and is_instance_valid(_akasha_npcs):
		_akasha_npcs.queue_free()

	_akasha_npcs = AkashaNPCs3D.new()
	_akasha_npcs.name = "AkashaNPCs3D"
	add_child(_akasha_npcs)


func _ensure_vista_camera_clip_planes() -> void:
	if player != null:
		var player_cam: Camera3D = player.get_node_or_null("CameraRig/SpringArm3D/Camera3D") as Camera3D
		if player_cam != null:
			player_cam.far = maxf(player_cam.far, 1400.0)
	if title_camera_rig != null:
		var title_cam: Camera3D = title_camera_rig.get_node_or_null("TitleCamera") as Camera3D
		if title_cam != null:
			title_cam.far = maxf(title_cam.far, 1400.0)


func _setup_atmospheric_dust_motes() -> void:
	if _dust_motes != null and is_instance_valid(_dust_motes):
		_dust_motes.queue_free()

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "AtmosphericDustMotes"
	particles.amount = 220
	particles.lifetime = 9.0
	particles.preprocess = 6.0
	particles.local_coords = false
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(Vector3(-36.0, -18.0, -36.0), Vector3(72.0, 36.0, 72.0))

	# Process material: 28x14x28 drifting volume with gentle turbulence and pastel pearl-gold / sakura-blush tint
	var proc_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc_mat.emission_box_extents = Vector3(14.0, 7.0, 14.0)
	proc_mat.gravity = Vector3(0.0, 0.04, 0.0)
	proc_mat.direction = Vector3(0.25, 0.4, 0.15)
	proc_mat.spread = 180.0
	proc_mat.initial_velocity_min = 0.06
	proc_mat.initial_velocity_max = 0.22
	proc_mat.damping_min = 0.05
	proc_mat.damping_max = 0.12
	proc_mat.turbulence_enabled = true
	proc_mat.turbulence_noise_strength = 0.35
	proc_mat.turbulence_noise_scale = 2.8
	proc_mat.turbulence_noise_speed_random = 0.35
	proc_mat.turbulence_influence_min = 0.25
	proc_mat.turbulence_influence_max = 0.65
	proc_mat.scale_min = 0.55
	proc_mat.scale_max = 1.45

	# Per-particle tint variation between soft pastel pearl-gold and sakura-blush
	var init_grad: Gradient = Gradient.new()
	init_grad.offsets = PackedFloat32Array([0.0, 0.52, 1.0])
	init_grad.colors = PackedColorArray([
		Color("#FFE6B8"),
		Color("#FFF6EC"),
		Color("#FFD1E0"),
	])
	var init_ramp: GradientTexture1D = GradientTexture1D.new()
	init_ramp.gradient = init_grad
	proc_mat.color_initial_ramp = init_ramp

	# Soft lifetime fade-in and fade-out
	var life_grad: Gradient = Gradient.new()
	life_grad.offsets = PackedFloat32Array([0.0, 0.18, 0.78, 1.0])
	life_grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.72),
		Color(1.0, 1.0, 1.0, 0.62),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var life_ramp: GradientTexture1D = GradientTexture1D.new()
	life_ramp.gradient = life_grad
	proc_mat.color_ramp = life_ramp

	particles.process_material = proc_mat

	# Soft radial-fade billboard quad mesh
	var radial_grad: Gradient = Gradient.new()
	radial_grad.offsets = PackedFloat32Array([0.0, 0.32, 0.72, 1.0])
	radial_grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.55),
		Color(1.0, 1.0, 1.0, 0.12),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var radial_tex: GradientTexture2D = GradientTexture2D.new()
	radial_tex.width = 64
	radial_tex.height = 64
	radial_tex.fill = GradientTexture2D.FILL_RADIAL
	radial_tex.fill_from = Vector2(0.5, 0.5)
	radial_tex.fill_to = Vector2(0.5, 0.0)
	radial_tex.gradient = radial_grad

	var quad_mat: StandardMaterial3D = StandardMaterial3D.new()
	quad_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	quad_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad_mat.vertex_color_use_as_albedo = true
	quad_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad_mat.billboard_keep_scale = true
	quad_mat.albedo_texture = radial_tex
	quad_mat.albedo_color = Color(1.0, 0.95, 0.93, 0.78)
	quad_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	var quad_mesh: QuadMesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.11, 0.11)
	quad_mesh.material = quad_mat
	particles.draw_pass_1 = quad_mesh

	add_child(particles)
	if player != null:
		particles.global_position = player.global_position + Vector3(0.0, 3.0, 0.0)
	else:
		particles.global_position = START_PLAYER_POS + Vector3(0.0, 3.0, 0.0)
	_dust_motes = particles


func _setup_sakura_petals() -> void:
	if _sakura_petals != null and is_instance_valid(_sakura_petals):
		_sakura_petals.queue_free()

	var petals: GPUParticles3D = GPUParticles3D.new()
	petals.name = "DriftingSakuraPetals"
	petals.amount = 140
	petals.lifetime = 11.0
	petals.preprocess = 7.0
	petals.local_coords = false
	petals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	petals.visibility_aabb = AABB(Vector3(-42.0, -24.0, -42.0), Vector3(84.0, 48.0, 84.0))

	# Gentle breeze carrying tumbling sakura petals downward and sideways around the player
	var proc_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc_mat.emission_box_extents = Vector3(18.0, 8.0, 18.0)
	proc_mat.gravity = Vector3(0.16, -0.30, 0.10)
	proc_mat.direction = Vector3(0.45, -0.25, 0.20)
	proc_mat.spread = 48.0
	proc_mat.initial_velocity_min = 0.24
	proc_mat.initial_velocity_max = 0.72
	proc_mat.angle_min = -180.0
	proc_mat.angle_max = 180.0
	proc_mat.angular_velocity_min = -55.0
	proc_mat.angular_velocity_max = 55.0
	proc_mat.damping_min = 0.08
	proc_mat.damping_max = 0.20
	proc_mat.turbulence_enabled = true
	proc_mat.turbulence_noise_strength = 0.52
	proc_mat.turbulence_noise_scale = 2.4
	proc_mat.turbulence_noise_speed_random = 0.40
	proc_mat.turbulence_influence_min = 0.28
	proc_mat.turbulence_influence_max = 0.72
	proc_mat.scale_min = 0.65
	proc_mat.scale_max = 1.35

	# Soft pink & blush-white sakura blossom petal palette
	var init_grad: Gradient = Gradient.new()
	init_grad.offsets = PackedFloat32Array([0.0, 0.52, 1.0])
	init_grad.colors = PackedColorArray([
		Color("#FF9EBB"),
		Color("#FFC8D8"),
		Color("#FFF0F5"),
	])
	var init_ramp: GradientTexture1D = GradientTexture1D.new()
	init_ramp.gradient = init_grad
	proc_mat.color_initial_ramp = init_ramp

	# Gentle fade-in and fade-out over the petal's 11-second drift
	var life_grad: Gradient = Gradient.new()
	life_grad.offsets = PackedFloat32Array([0.0, 0.14, 0.80, 1.0])
	life_grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.92),
		Color(1.0, 1.0, 1.0, 0.84),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var life_ramp: GradientTexture1D = GradientTexture1D.new()
	life_ramp.gradient = life_grad
	proc_mat.color_ramp = life_ramp

	petals.process_material = proc_mat

	# Soft oval petal texture
	var petal_grad: Gradient = Gradient.new()
	petal_grad.offsets = PackedFloat32Array([0.0, 0.55, 0.85, 1.0])
	petal_grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.92),
		Color(1.0, 1.0, 1.0, 0.35),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var petal_tex: GradientTexture2D = GradientTexture2D.new()
	petal_tex.width = 48
	petal_tex.height = 48
	petal_tex.fill = GradientTexture2D.FILL_RADIAL
	petal_tex.fill_from = Vector2(0.5, 0.5)
	petal_tex.fill_to = Vector2(0.5, 0.02)
	petal_tex.gradient = petal_grad

	var petal_mat: StandardMaterial3D = StandardMaterial3D.new()
	petal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	petal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	petal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	petal_mat.vertex_color_use_as_albedo = true
	petal_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	petal_mat.billboard_keep_scale = true
	petal_mat.albedo_texture = petal_tex
	petal_mat.albedo_color = Color(1.0, 0.97, 0.98, 0.94)
	petal_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	var petal_mesh: QuadMesh = QuadMesh.new()
	petal_mesh.size = Vector2(0.15, 0.09)
	petal_mesh.material = petal_mat
	petals.draw_pass_1 = petal_mesh

	add_child(petals)
	if player != null:
		petals.global_position = player.global_position + Vector3(0.0, 5.0, 0.0)
	else:
		petals.global_position = START_PLAYER_POS + Vector3(0.0, 5.0, 0.0)
	_sakura_petals = petals


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

	if _castle_interactables != null and is_instance_valid(_castle_interactables):
		if _castle_interactables.has_signal("relic_interacted"):
			_castle_interactables.connect("relic_interacted", _on_castle_relic_interacted)

	if _akasha_npcs != null and is_instance_valid(_akasha_npcs):
		if _akasha_npcs.has_signal("npc_interacted"):
			_akasha_npcs.connect("npc_interacted", _on_akasha_npc_interacted)


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
	if _castle_interactables != null and is_instance_valid(_castle_interactables):
		_castle_interactables.reset_all_relics()


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

	var pressed_interact: bool = false
	if InputMap.has_action("interact") and event.is_action_pressed("interact"):
		pressed_interact = true
	elif event is InputEventKey:
		var key_ev: InputEventKey = event as InputEventKey
		if key_ev.pressed and not key_ev.echo:
			if key_ev.keycode == KEY_ESCAPE:
				# If mouse is already released (not captured by 3D look), Escape opens the Main Menu
				if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
					get_viewport().set_input_as_handled()
					_return_to_main_menu()
				return
			if key_ev.keycode == KEY_E or key_ev.physical_keycode == KEY_E:
				pressed_interact = true

	if pressed_interact and player != null:
		if _castle_interactables != null and is_instance_valid(_castle_interactables):
			var relic_seq: String = _castle_interactables.interact_nearest(player.global_position)
			if not relic_seq.is_empty():
				get_viewport().set_input_as_handled()
				return
		if _akasha_npcs != null and is_instance_valid(_akasha_npcs):
			if _akasha_npcs.interact_nearest(player.global_position):
				get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Gameplay Signals (Soul Call, Lanterns, Mentors, Earth Mirror, Castle Relics, NPCs)
# ---------------------------------------------------------------------------

func _on_player_soul_call(origin: Vector3) -> void:
	if soul_call and soul_call.has_method("trigger"):
		soul_call.call("trigger", origin)
	if audio_manager and audio_manager.has_method("play_soul_call"):
		audio_manager.call("play_soul_call")

	if dialogue_manager and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		return

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
				return

	# 3. Check if player is calling to a Castle relic (Fountain, Chronicle Book, Kronos Astrolabe)
	if _castle_interactables != null and is_instance_valid(_castle_interactables):
		_castle_interactables.respond_to_soul_call(origin)

	# 4. Nearby Akashic Spirit NPCs do a joyful hop + warm golden-aqua light pulse
	if _akasha_npcs != null and is_instance_valid(_akasha_npcs):
		_akasha_npcs.respond_to_soul_call(origin)


func _on_castle_relic_interacted(relic_id: String, dialogue_sequence_id: String) -> void:
	if dialogue_manager and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		return

	if audio_manager and audio_manager.has_method("play_lantern_chime"):
		var chime_idx: int = 0
		if _castle_interactables != null and is_instance_valid(_castle_interactables):
			chime_idx = _castle_interactables.get_chime_index_for_relic(relic_id)
		audio_manager.call("play_lantern_chime", chime_idx)

	if not dialogue_sequence_id.is_empty():
		_start_dialogue_sequence(dialogue_sequence_id)


func _on_akasha_npc_interacted(npc_id: String, dialogue_sequence_id: String) -> void:
	if dialogue_manager and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		return

	if audio_manager and audio_manager.has_method("play_lantern_chime"):
		audio_manager.call("play_lantern_chime", posmod(npc_id.hash(), 5))

	if not dialogue_sequence_id.is_empty():
		_start_dialogue_sequence(dialogue_sequence_id)


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
	if player != null:
		var follow_weight: float = clampf(delta * 4.0, 0.0, 1.0)
		if _dust_motes != null and is_instance_valid(_dust_motes):
			var target_dust_pos: Vector3 = player.global_position + Vector3(0.0, 3.0, 0.0)
			if _dust_motes.global_position.distance_squared_to(target_dust_pos) > 400.0:
				_dust_motes.global_position = target_dust_pos
			else:
				_dust_motes.global_position = _dust_motes.global_position.lerp(target_dust_pos, follow_weight)

		if _sakura_petals != null and is_instance_valid(_sakura_petals):
			var target_petal_pos: Vector3 = player.global_position + Vector3(0.0, 5.0, 0.0)
			if _sakura_petals.global_position.distance_squared_to(target_petal_pos) > 400.0:
				_sakura_petals.global_position = target_petal_pos
			else:
				_sakura_petals.global_position = _sakura_petals.global_position.lerp(target_petal_pos, follow_weight)

		if _akasha_npcs != null and is_instance_valid(_akasha_npcs):
			_akasha_npcs.update_player_position(player.global_position)

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
	_update_interaction_prompt(p_pos, stage)


func _update_interaction_prompt(p_pos: Vector3, stage: String) -> void:
	var relic_prompt: String = ""
	if _castle_interactables != null and is_instance_valid(_castle_interactables):
		relic_prompt = _castle_interactables.get_interaction_prompt(p_pos)

	var npc_prompt: String = ""
	if _akasha_npcs != null and is_instance_valid(_akasha_npcs):
		var nearest_npc_id: String = _akasha_npcs.get_nearest_npc_in_range(p_pos)
		if not nearest_npc_id.is_empty():
			npc_prompt = _akasha_npcs.get_interaction_prompt(nearest_npc_id)

	var near_mirror_close: bool = earth_mirror != null and p_pos.distance_to(earth_mirror.global_position) <= 16.0
	var near_mirror_zone: bool = (
		earth_mirror != null
		and earth_mirror.has_method("is_player_near_call_zone")
		and bool(earth_mirror.call("is_player_near_call_zone", p_pos))
	)

	var prompt: String = ""
	if stage == "contract_spoken":
		if near_mirror_close:
			prompt = "✦  [Q]  Пробудить Зеркало Земли"
		elif not relic_prompt.is_empty():
			prompt = relic_prompt
		elif not npc_prompt.is_empty():
			prompt = npc_prompt
		elif near_mirror_zone:
			prompt = "✦  [Q]  Пробудить Зеркало Земли"
	elif stage == "mirror_awakened" or stage == "prologue_complete":
		if near_mirror_close:
			prompt = "✦  Шагните в Зеркало Земли"
		elif not relic_prompt.is_empty():
			prompt = relic_prompt
		elif not npc_prompt.is_empty():
			prompt = npc_prompt
		elif near_mirror_zone:
			prompt = "✦  Шагните в Зеркало Земли"
	elif stage == "exploring" or stage == "intro":
		if sanctuary_mentors and sanctuary_mentors.has_method("is_player_in_talk_range"):
			if bool(sanctuary_mentors.call("is_player_in_talk_range", p_pos)):
				prompt = "✦  [Q]  Откликнуться Наставникам"
		if prompt.is_empty() and not relic_prompt.is_empty():
			prompt = relic_prompt
		if prompt.is_empty() and not npc_prompt.is_empty():
			prompt = npc_prompt
	elif not relic_prompt.is_empty():
		prompt = relic_prompt
	elif not npc_prompt.is_empty():
		prompt = npc_prompt

	_update_prompt(prompt)
