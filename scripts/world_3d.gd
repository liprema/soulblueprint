extends Node3D

## Root orchestrator for the SoulBlueprint 3D Sky-style Playable Prologue (Vertical Slice).
## Coordinates MainMenu + TitleCameraRig, seamless intro.ogv playback via SceneFlowManager,
## SaveManager persistence, StoneLantern3D awakening, multi-step Alatea & Mira First Contract
## dialogue (JSON), SanctuaryMentors3D, EarthMirror3D awakening, and Prologue Epilogue.

const STONE_LANTERN_SCENE: PackedScene = preload("res://scenes/interactables/stone_lantern_3d.tscn")
const INTRO_VIDEO_PATH: String = "res://assets/videos/intro.ogv"
const UPDRAFTS_SCRIPT_PATH: String = "res://scripts/akasha_updrafts_3d.gd"
const START_PLAYER_POS: Vector3 = Vector3(0.0, 1.3, 36.0)
const DAIS_RETURN_POS: Vector3 = Vector3(0.0, 9.2, -268.0)

const DIALOGUE_CAM_FOV: float = 44.0
const DIALOGUE_CAM_SMOOTH_RATE: float = 4.5
const DIALOGUE_CAM_RETURN_DURATION: float = 0.45
const DIALOGUE_CAM_IDLE: int = 0
const DIALOGUE_CAM_ACTIVE: int = 1
const DIALOGUE_CAM_RETURNING: int = 2

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
var _updrafts: Node3D = null

var _dialogue_camera: Camera3D = null
var _dialogue_cam_state: int = DIALOGUE_CAM_IDLE
var _dialogue_cam_time: float = 0.0
var _dialogue_return_elapsed: float = 0.0
var _dialogue_return_start_xform: Transform3D = Transform3D.IDENTITY
var _dialogue_return_start_fov: float = DIALOGUE_CAM_FOV
var _dialogue_target_pos: Vector3 = Vector3.ZERO
var _dialogue_target_look: Vector3 = Vector3.ZERO
var _dialogue_current_look: Vector3 = Vector3.ZERO
var _dialogue_context_kind: String = ""
var _dialogue_context_id: String = ""
var _dialogue_context_node: Node3D = null
var _dialogue_context_pos: Vector3 = Vector3.ZERO
var _dialogue_context_eye_height: float = 2.0
var _dialogue_context_distance: float = 6.0
var _dialogue_side_sign: float = 1.0

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
	_setup_akasha_updrafts()
	_setup_dialogue_camera()
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
			var anchor_pos: Vector3 = anchors[idx] as Vector3
			lantern.position = Vector3(anchor_pos.x, anchor_pos.y - 0.02, anchor_pos.z)
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


func _setup_akasha_updrafts() -> void:
	if _updrafts != null and is_instance_valid(_updrafts):
		_updrafts.queue_free()
	_updrafts = null

	if not ResourceLoader.exists(UPDRAFTS_SCRIPT_PATH):
		return

	var updrafts_script: Script = load(UPDRAFTS_SCRIPT_PATH) as Script
	if updrafts_script == null:
		return

	var inst: Variant = updrafts_script.new()
	if inst is Node3D:
		_updrafts = inst as Node3D
		_updrafts.name = "AkashaUpdrafts3D"
		add_child(_updrafts)
		if _updrafts.has_method("setup") and player != null:
			_updrafts.call("setup", player, audio_manager)


func _setup_dialogue_camera() -> void:
	if _dialogue_camera != null and is_instance_valid(_dialogue_camera):
		_dialogue_camera.queue_free()

	_dialogue_camera = Camera3D.new()
	_dialogue_camera.name = "DialogueCamera"
	_dialogue_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_dialogue_camera.near = 0.2
	_dialogue_camera.far = 1600.0
	_dialogue_camera.fov = DIALOGUE_CAM_FOV
	_dialogue_camera.current = false
	add_child(_dialogue_camera)


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
	particles.amount = 36
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
	proc_mat.scale_min = 0.35
	proc_mat.scale_max = 0.80

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
	quad_mat.albedo_color = Color(1.0, 0.95, 0.93, 0.42)
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
	petals.amount = 40
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
	proc_mat.scale_min = 0.55
	proc_mat.scale_max = 1.05

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
		Color(1.0, 1.0, 1.0, 0.86),
		Color(1.0, 1.0, 1.0, 0.78),
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
	petal_mat.albedo_color = Color(1.0, 0.97, 0.98, 0.80)
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
	_cancel_dialogue_camera()
	if audio_manager != null and audio_manager.has_method("update_flight_wind"):
		audio_manager.call("update_flight_wind", 0.0, false)
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


func _get_player_camera() -> Camera3D:
	if player == null:
		return null
	return player.get_node_or_null("CameraRig/SpringArm3D/Camera3D") as Camera3D


func _set_player_camera_current(is_current: bool) -> void:
	var cam: Camera3D = _get_player_camera()
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
				var mentor_pos: Vector3 = sanctuary_mentors.global_position
				_set_dialogue_context("mentor", "first_contract", sanctuary_mentors, mentor_pos, 4.35, 6.8)
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

	var relic_pos: Vector3 = player.global_position + Vector3(0.0, 0.0, -4.0) if player != null else Vector3.ZERO
	var relic_eye: float = 1.9
	var relic_dist: float = 6.0
	if relic_id == CastleInteractables3D.RELIC_FOUNTAIN:
		relic_pos = CastleInteractables3D.FOUNTAIN_POS
		relic_eye = 1.95
		relic_dist = 6.2
	elif relic_id == CastleInteractables3D.RELIC_BOOK:
		relic_pos = CastleInteractables3D.BOOK_POS
		relic_eye = 1.85
		relic_dist = 5.5
	elif relic_id == CastleInteractables3D.RELIC_ASTROLABE:
		relic_pos = CastleInteractables3D.ASTROLABE_POS
		relic_eye = 2.25
		relic_dist = 6.6
	_set_dialogue_context("relic", relic_id, null, relic_pos, relic_eye, relic_dist)

	if not dialogue_sequence_id.is_empty():
		_start_dialogue_sequence(dialogue_sequence_id)


func _on_akasha_npc_interacted(npc_id: String, dialogue_sequence_id: String) -> void:
	if dialogue_manager and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		return

	if audio_manager and audio_manager.has_method("play_lantern_chime"):
		audio_manager.call("play_lantern_chime", posmod(npc_id.hash(), 5))

	var npc_node: Node3D = null
	var npc_pos: Vector3 = player.global_position + Vector3(0.0, 0.0, -4.0) if player != null else Vector3.ZERO
	if _akasha_npcs != null and is_instance_valid(_akasha_npcs):
		npc_node = _akasha_npcs.get_node_or_null("NPC_%s" % npc_id) as Node3D
		if npc_node != null:
			npc_pos = npc_node.global_position

	var is_archangel: bool = npc_id.begins_with("archangel_")
	var npc_eye: float = 2.65 if is_archangel else 0.95
	var npc_dist: float = 6.4 if is_archangel else 5.0
	_set_dialogue_context("npc", npc_id, npc_node, npc_pos, npc_eye, npc_dist)

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
# Dialogue Orchestration & Cinematic Dialogue Camera
# ---------------------------------------------------------------------------

func _set_dialogue_context(
	kind: String,
	context_id: String,
	context_node: Node3D,
	world_pos: Vector3,
	eye_height: float,
	distance: float
) -> void:
	_dialogue_context_kind = kind
	_dialogue_context_id = context_id
	_dialogue_context_node = context_node
	_dialogue_context_pos = world_pos
	_dialogue_context_eye_height = eye_height
	_dialogue_context_distance = distance

	# Pick side sign matching the player camera's current side for an effortless glide
	_dialogue_side_sign = 1.0
	var player_cam: Camera3D = _get_player_camera()
	if player != null and player_cam != null:
		var to_player_flat: Vector3 = Vector3(
			player.global_position.x - world_pos.x,
			0.0,
			player.global_position.z - world_pos.z
		)
		if to_player_flat.length_squared() > 0.04:
			var front_dir: Vector3 = to_player_flat.normalized()
			var right_dir: Vector3 = Vector3.UP.cross(front_dir).normalized()
			var cam_offset: Vector3 = player_cam.global_position - world_pos
			if cam_offset.dot(right_dir) < 0.0:
				_dialogue_side_sign = -1.0


func _resolve_dialogue_focus(speaker_id: String) -> Dictionary:
	var normalized: String = speaker_id.strip_edges().to_lower()

	if _dialogue_context_kind == "relic":
		var nudge: float = 0.0
		if normalized == "alatea":
			nudge = -0.55
		elif normalized == "mira" or normalized == "orion":
			nudge = 0.55
		return {
			"base_pos": _dialogue_context_pos,
			"eye_height": _dialogue_context_eye_height,
			"distance": _dialogue_context_distance,
			"speaker_nudge": nudge,
		}

	if _dialogue_context_kind == "npc":
		var live_pos: Vector3 = _dialogue_context_pos
		if _dialogue_context_node != null and is_instance_valid(_dialogue_context_node):
			live_pos = _dialogue_context_node.global_position
		return {
			"base_pos": live_pos,
			"eye_height": _dialogue_context_eye_height,
			"distance": _dialogue_context_distance,
			"speaker_nudge": 0.0,
		}

	# Mentors (Alatea & Mira) or fallback speaker focus
	if sanctuary_mentors != null and is_instance_valid(sanctuary_mentors):
		if normalized == "alatea":
			var alatea_node: Node3D = sanctuary_mentors.get_node_or_null("Alatea") as Node3D
			if alatea_node != null:
				return {
					"base_pos": alatea_node.global_position,
					"eye_height": 4.35,
					"distance": 6.8,
					"speaker_nudge": -0.45,
				}
		elif normalized == "mira":
			var mira_node: Node3D = sanctuary_mentors.get_node_or_null("Mira") as Node3D
			if mira_node != null:
				return {
					"base_pos": mira_node.global_position,
					"eye_height": 4.35,
					"distance": 6.8,
					"speaker_nudge": 0.45,
				}
		return {
			"base_pos": sanctuary_mentors.global_position + Vector3(0.0, 0.0, -7.5),
			"eye_height": 4.2,
			"distance": 7.0,
			"speaker_nudge": 0.0,
		}

	var fallback_pos: Vector3 = player.global_position + Vector3(0.0, 0.0, -5.0) if player != null else Vector3.ZERO
	return {
		"base_pos": fallback_pos,
		"eye_height": 1.6,
		"distance": 5.5,
		"speaker_nudge": 0.0,
	}


func _guard_dialogue_camera_against_walls(focus_pos: Vector3, desired_pos: Vector3) -> Vector3:
	var world_3d: World3D = get_world_3d()
	if world_3d == null:
		return desired_pos
	var space_state: PhysicsDirectSpaceState3D = world_3d.direct_space_state
	if space_state == null:
		return desired_pos

	var seg: Vector3 = desired_pos - focus_pos
	var seg_len: float = seg.length()
	if seg_len <= 0.25:
		return desired_pos

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(focus_pos, desired_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if player != null:
		query.exclude = [player.get_rid()]

	var hit: Dictionary = space_state.intersect_ray(query)
	if not hit.is_empty():
		var hit_pos: Vector3 = hit["position"] as Vector3
		var hit_dist: float = focus_pos.distance_to(hit_pos)
		var safe_dist: float = clampf(hit_dist - 0.85, 2.2, seg_len)
		return focus_pos + (seg / seg_len) * safe_dist

	return desired_pos


func _compute_dialogue_camera_pose(speaker_id: String) -> void:
	var focus: Dictionary = _resolve_dialogue_focus(speaker_id)
	var base_pos: Vector3 = focus.get("base_pos", Vector3.ZERO) as Vector3
	var eye_height: float = float(focus.get("eye_height", 2.0))
	var dist: float = float(focus.get("distance", 6.0))
	var speaker_nudge: float = float(focus.get("speaker_nudge", 0.0))

	var player_pos: Vector3 = player.global_position if player != null else base_pos + Vector3(0.0, 0.0, 6.0)
	var to_player_flat: Vector3 = Vector3(player_pos.x - base_pos.x, 0.0, player_pos.z - base_pos.z)
	var front_dir: Vector3 = Vector3(0.0, 0.0, 1.0)
	if to_player_flat.length_squared() > 0.04:
		front_dir = to_player_flat.normalized()

	var right_dir: Vector3 = Vector3.UP.cross(front_dir).normalized()
	var side_offset: float = clampf(dist * 0.30, 1.35, 2.2) * _dialogue_side_sign + speaker_nudge
	var target_eye_y: float = base_pos.y + eye_height
	var floor_guard_y: float = minf(player_pos.y, base_pos.y) + 1.25
	var cam_y: float = maxf(lerpf(player_pos.y + 1.35, target_eye_y, 0.68), floor_guard_y)

	var speaker_focus: Vector3 = Vector3(base_pos.x, target_eye_y, base_pos.z)
	var raw_cam_pos: Vector3 = Vector3(base_pos.x, 0.0, base_pos.z) + front_dir * dist + right_dir * side_offset + Vector3(0.0, cam_y, 0.0)
	_dialogue_target_pos = _guard_dialogue_camera_against_walls(speaker_focus, raw_cam_pos)

	if player != null and player_pos.distance_to(base_pos) <= 14.0:
		var spark_focus: Vector3 = player_pos + Vector3(0.0, 1.05, 0.0)
		_dialogue_target_look = speaker_focus.lerp(spark_focus, 0.14)
	else:
		_dialogue_target_look = speaker_focus


func _begin_dialogue_camera() -> void:
	if _dialogue_camera == null or not is_instance_valid(_dialogue_camera):
		return
	var player_cam: Camera3D = _get_player_camera()
	if player_cam == null:
		return

	if _dialogue_cam_state == DIALOGUE_CAM_IDLE:
		_dialogue_camera.global_transform = player_cam.global_transform
		_dialogue_camera.fov = player_cam.fov
		_dialogue_current_look = player_cam.global_position - player_cam.global_transform.basis.z * 6.0

	_dialogue_cam_time = 0.0
	_dialogue_cam_state = DIALOGUE_CAM_ACTIVE
	_dialogue_camera.current = true


func _end_dialogue_camera() -> void:
	if _dialogue_camera == null or not is_instance_valid(_dialogue_camera):
		_dialogue_cam_state = DIALOGUE_CAM_IDLE
		return
	if _dialogue_cam_state != DIALOGUE_CAM_ACTIVE:
		return

	var player_cam: Camera3D = _get_player_camera()
	if player_cam == null:
		_cancel_dialogue_camera()
		return

	_dialogue_return_start_xform = _dialogue_camera.global_transform
	_dialogue_return_start_fov = _dialogue_camera.fov
	_dialogue_return_elapsed = 0.0
	_dialogue_cam_state = DIALOGUE_CAM_RETURNING


func _cancel_dialogue_camera() -> void:
	_dialogue_cam_state = DIALOGUE_CAM_IDLE
	_dialogue_context_kind = ""
	_dialogue_context_id = ""
	_dialogue_context_node = null
	if _dialogue_camera != null and is_instance_valid(_dialogue_camera):
		_dialogue_camera.current = false


func _update_dialogue_camera(delta: float) -> void:
	if _dialogue_cam_state == DIALOGUE_CAM_IDLE:
		return
	if _dialogue_camera == null or not is_instance_valid(_dialogue_camera):
		_dialogue_cam_state = DIALOGUE_CAM_IDLE
		return

	if _dialogue_cam_state == DIALOGUE_CAM_ACTIVE:
		_dialogue_cam_time += delta
		var smooth_w: float = 1.0 - exp(-DIALOGUE_CAM_SMOOTH_RATE * delta)
		var drift: Vector3 = Vector3(
			sin(_dialogue_cam_time * 0.72) * 0.08,
			sin(_dialogue_cam_time * 0.54 + 1.1) * 0.06,
			cos(_dialogue_cam_time * 0.61 + 0.4) * 0.05
		)
		_dialogue_camera.global_position = _dialogue_camera.global_position.lerp(_dialogue_target_pos + drift, smooth_w)
		_dialogue_current_look = _dialogue_current_look.lerp(_dialogue_target_look, smooth_w)
		_dialogue_camera.fov = lerpf(_dialogue_camera.fov, DIALOGUE_CAM_FOV, smooth_w)

		var to_look: Vector3 = _dialogue_current_look - _dialogue_camera.global_position
		if to_look.length_squared() > 0.01 and absf(to_look.normalized().dot(Vector3.UP)) < 0.995:
			_dialogue_camera.look_at(_dialogue_current_look, Vector3.UP)

	elif _dialogue_cam_state == DIALOGUE_CAM_RETURNING:
		var player_cam: Camera3D = _get_player_camera()
		if player_cam == null:
			_cancel_dialogue_camera()
			return

		_dialogue_return_elapsed += delta
		var raw_t: float = clampf(_dialogue_return_elapsed / DIALOGUE_CAM_RETURN_DURATION, 0.0, 1.0)
		var smooth_t: float = raw_t * raw_t * (3.0 - 2.0 * raw_t)

		var start_q: Quaternion = _dialogue_return_start_xform.basis.get_rotation_quaternion()
		var target_q: Quaternion = player_cam.global_transform.basis.get_rotation_quaternion()
		var blended_q: Quaternion = start_q.slerp(target_q, smooth_t)
		var blended_pos: Vector3 = _dialogue_return_start_xform.origin.lerp(player_cam.global_position, smooth_t)
		var rot_basis: Basis = Basis(blended_q)
		_dialogue_camera.global_transform = Transform3D(rot_basis, blended_pos)
		_dialogue_camera.fov = lerpf(_dialogue_return_start_fov, player_cam.fov, smooth_t)

		if raw_t >= 1.0:
			_dialogue_cam_state = DIALOGUE_CAM_IDLE
			_dialogue_camera.current = false
			player_cam.current = true


func _start_dialogue_sequence(sequence_id: String) -> void:
	if not dialogue_manager or not dialogue_manager.has_method("start_sequence"):
		return
	if dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		return
	dialogue_manager.call("start_sequence", sequence_id)


func _on_dialogue_started(_sequence_id: String) -> void:
	_set_player_control(false)
	_update_prompt("")
	_compute_dialogue_camera_pose("")
	_begin_dialogue_camera()


func _on_dialogue_line_presented(
	speaker_id: String,
	speaker_title: String,
	accent_color: Color,
	text: String,
	choices: Array
) -> void:
	_compute_dialogue_camera_pose(speaker_id)
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

	_end_dialogue_camera()
	_dialogue_context_kind = ""
	_dialogue_context_id = ""
	_dialogue_context_node = null
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
	_cancel_dialogue_camera()
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

	_update_dialogue_camera(delta)

	var is_talking: bool = dialogue_manager != null and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active"))

	if audio_manager != null and audio_manager.has_method("update_flight_wind"):
		if _is_in_gameplay and not _is_transitioning and not is_talking and player != null:
			var is_flying_now: bool = bool(player.get("is_flying"))
			var player_speed: float = player.velocity.length()
			var speed_ratio: float = clampf(player_speed / 24.0, 0.0, 1.0)
			audio_manager.call("update_flight_wind", speed_ratio, is_flying_now)
		else:
			audio_manager.call("update_flight_wind", 0.0, false)

	if not _is_in_gameplay or _is_transitioning or not player:
		return

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
		var arrival_pos: Vector3 = sanctuary_mentors.global_position if sanctuary_mentors != null else p_pos + Vector3(0.0, 0.0, -8.0)
		_set_dialogue_context("mentor", "cathedral_arrival", sanctuary_mentors, arrival_pos, 4.35, 6.8)
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
