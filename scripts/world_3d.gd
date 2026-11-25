extends Node3D

## Root orchestrator for the SoulBlueprint 3D Sky-style Playable Prologue (Vertical Slice).
## Coordinates MainMenu + TitleCameraRig, seamless intro.ogv playback via SceneFlowManager,
## SaveManager persistence, StoneLantern3D awakening, multi-step Alatea & Mira First Contract
## dialogue (JSON), SanctuaryMentors3D, EarthMirror3D awakening, and Prologue Epilogue.

const STONE_LANTERN_SCENE: PackedScene = preload("res://scenes/interactables/stone_lantern_3d.tscn")
const INTRO_VIDEO_PATH: String = "res://assets/videos/intro.ogv"
const UPDRAFTS_SCRIPT_PATH: String = "res://scripts/akasha_updrafts_3d.gd"
const START_PLAYER_POS: Vector3 = Vector3(0.0, 0.25, 52.0)
const DAIS_RETURN_POS: Vector3 = Vector3(0.0, 9.2, -268.0)

const CITY_NPC_INTERACT_RANGE: float = 4.8
const CITY_MEMORY_DROP_POS: Vector3 = Vector3(42.0, 0.0, 10.0)
const CITY_LUMI_MODEL_PATH: String = "res://assets/models/characters/spark.glb"
const CITY_ALATEA_MODEL_PATH: String = "res://assets/models/characters/mentor_alatea.glb"
const CITY_ORION_MODEL_PATH: String = "res://assets/models/characters/archangel_aether.glb"
const CITY_KRONOS_MODEL_PATH: String = "res://assets/models/characters/archangel_solaris.glb"

const DIALOGUE_CAM_FOV: float = 44.0
const DIALOGUE_CAM_SMOOTH_RATE: float = 4.5
const DIALOGUE_CAM_RETURN_DURATION: float = 0.45
const DIALOGUE_CAM_IDLE: int = 0
const DIALOGUE_CAM_ACTIVE: int = 1
const DIALOGUE_CAM_RETURNING: int = 2

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var cloud_sea: Node3D = $CloudSea
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
var _sunset_controller: SunsetAtmosphereController = null
var _comfort_signs: ComfortSigns3D = null
var _city_builder: AkashaCityBuilder = null
var _city_map_ui: CityMapUI = null
var _city_quest_npcs_root: Node3D = null
var _city_quest_npcs: Dictionary = {}
var _current_district_id: String = ""
var _city_npc_anim_time: float = 0.0

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
	if cloud_sea != null:
		cloud_sea.position.y = -45.0
	_hide_legacy_floating_islands()
	_setup_city_builder()
	_setup_city_map_ui()
	_setup_city_quest_npcs()
	_spawn_lanterns()
	_setup_garden_decorator()
	_setup_castle_interactables()
	_setup_akasha_npcs()
	_setup_sunset_controller()
	_setup_comfort_signs()
	_setup_dialogue_camera()
	_ensure_vista_camera_clip_planes()
	_setup_atmospheric_dust_motes()
	_setup_sakura_petals()
	_connect_signals()
	_apply_audio_setting()

	if SceneFlowManager != null and SceneFlowManager.pending_world_mode == "lesson1_sunset_return":
		SceneFlowManager.pending_world_mode = ""
		_enter_lesson1_sunset_return()
	else:
		_enter_main_menu_immediate()


func _hide_legacy_floating_islands() -> void:
	if architecture == null:
		return
	var legacy_names: Array[String] = [
		"StartingMonolithPlaza",
		"IndigoViaduct",
		"FloatingTempleIslands",
	]
	for node_name: String in legacy_names:
		var legacy_node: Node = architecture.get_node_or_null(node_name)
		if legacy_node != null:
			if legacy_node is Node3D:
				(legacy_node as Node3D).visible = false
			_disable_collisions_recursive(legacy_node)


func _disable_collisions_recursive(node: Node) -> void:
	if node is CollisionShape3D:
		(node as CollisionShape3D).disabled = true
	for child: Node in node.get_children():
		_disable_collisions_recursive(child)


func _setup_city_builder() -> void:
	if _city_builder != null and is_instance_valid(_city_builder):
		_city_builder.queue_free()

	_city_builder = AkashaCityBuilder.new()
	_city_builder.name = "AkashaCityBuilder"
	add_child(_city_builder)
	_city_builder.build_city()


func _setup_city_map_ui() -> void:
	if _city_map_ui != null and is_instance_valid(_city_map_ui):
		_city_map_ui.queue_free()

	_city_map_ui = CityMapUI.new()
	_city_map_ui.name = "CityMapUI"
	add_child(_city_map_ui)


func _setup_city_quest_npcs() -> void:
	if _city_quest_npcs_root != null and is_instance_valid(_city_quest_npcs_root):
		_city_quest_npcs_root.queue_free()
	_city_quest_npcs.clear()

	_city_quest_npcs_root = Node3D.new()
	_city_quest_npcs_root.name = "CityQuestNPCs"
	add_child(_city_quest_npcs_root)

	# 1. Lumi at Awakening Plaza (0, 0, 42) facing south (+Z) toward starting player
	_spawn_city_quest_npc(
		"city_lumi",
		"Люми",
		Vector3(0.0, 0.0, 42.0),
		0.0,
		CITY_LUMI_MODEL_PATH,
		1.0,
		0.65,
		Color("#A8E4FF"),
		1.15,
		4.6,
		0.08,
		0.0
	)

	# 2. Alatea at School of Young Souls (-36, 3.2, 8) facing east (+X) toward plaza
	_spawn_city_quest_npc(
		"city_alatea",
		"Алатея",
		Vector3(-36.0, 3.2, 8.0),
		PI * 0.5,
		CITY_ALATEA_MODEL_PATH,
		0.62,
		0.0,
		Color("#CBE8FF"),
		2.35,
		5.4,
		0.04,
		1.2
	)

	# 3. Orion at Library of Orion (-42, 3.2, -78) facing east (+X)
	_spawn_city_quest_npc(
		"city_orion",
		"Орион",
		Vector3(-42.0, 3.2, -78.0),
		PI * 0.5,
		CITY_ORION_MODEL_PATH,
		0.75,
		-0.10,
		Color("#B8DCFF"),
		2.50,
		5.8,
		0.05,
		2.4
	)

	# 4. Kronos at Tower of Time (42, 3.2, -78) facing west (-X)
	_spawn_city_quest_npc(
		"city_kronos",
		"Кронос",
		Vector3(42.0, 3.2, -78.0),
		-PI * 0.5,
		CITY_KRONOS_MODEL_PATH,
		0.75,
		-0.10,
		Color("#FFE096"),
		2.50,
		5.8,
		0.05,
		3.6
	)


func _spawn_city_quest_npc(
	npc_id: String,
	display_name: String,
	world_pos: Vector3,
	rot_y: float,
	model_path: String,
	model_scale: float,
	y_offset: float,
	light_color: Color,
	eye_height: float,
	cam_dist: float,
	bob_amp: float,
	phase: float
) -> void:
	var root: Node3D = Node3D.new()
	root.name = "CityNPC_%s" % npc_id
	root.position = world_pos
	root.rotation.y = rot_y
	_city_quest_npcs_root.add_child(root)

	var visual_pivot: Node3D = Node3D.new()
	visual_pivot.name = "VisualPivot"
	visual_pivot.position = Vector3(0.0, y_offset, 0.0)
	root.add_child(visual_pivot)

	var loaded_model: bool = false
	if ResourceLoader.exists(model_path):
		var res: Resource = load(model_path)
		if res is PackedScene:
			var inst: Node = (res as PackedScene).instantiate()
			if inst is Node3D:
				var model_node: Node3D = inst as Node3D
				model_node.scale = Vector3(model_scale, model_scale, model_scale)
				visual_pivot.add_child(model_node)
				_enforce_opaque_character_materials(model_node)
				loaded_model = true

	if not loaded_model:
		_build_fallback_city_spirit(visual_pivot, light_color, eye_height)

	var aura_light: OmniLight3D = OmniLight3D.new()
	aura_light.name = "AuraLight"
	aura_light.position = Vector3(0.0, maxf(1.2, eye_height * 0.8), 0.0)
	aura_light.light_color = light_color
	aura_light.light_energy = 1.05
	aura_light.omni_range = 7.5
	aura_light.shadow_enabled = false
	root.add_child(aura_light)

	_city_quest_npcs[npc_id] = {
		"id": npc_id,
		"name": display_name,
		"node": root,
		"visual": visual_pivot,
		"pos": world_pos,
		"base_y": y_offset,
		"eye_height": eye_height,
		"cam_dist": cam_dist,
		"bob_amp": bob_amp,
		"phase": phase,
	}


func _enforce_opaque_character_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var mesh_ref: Mesh = mi.mesh
		if mesh_ref != null:
			var surf_count: int = mesh_ref.get_surface_count()
			for s_idx: int in range(surf_count):
				var mat: Material = mi.get_surface_override_material(s_idx)
				if mat == null:
					mat = mesh_ref.surface_get_material(s_idx)
				if mat is BaseMaterial3D:
					var base_mat: BaseMaterial3D = (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
					base_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					base_mat.subsurf_scatter_enabled = false
					base_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
					mi.set_surface_override_material(s_idx, base_mat)
	for child: Node in node.get_children():
		_enforce_opaque_character_materials(child)


func _build_fallback_city_spirit(parent: Node3D, tint: Color, height_hint: float) -> void:
	var body_mat: StandardMaterial3D = StandardMaterial3D.new()
	body_mat.albedo_color = tint.lerp(Color("#FFF8EE"), 0.35)
	body_mat.roughness = 0.42
	body_mat.metallic = 0.08
	body_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	body_mat.subsurf_scatter_enabled = false
	body_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	body_mat.emission_enabled = true
	body_mat.emission = tint
	body_mat.emission_energy_multiplier = 0.35

	var body_h: float = clampf(height_hint * 0.72, 0.9, 1.9)
	var body_mesh: CapsuleMesh = CapsuleMesh.new()
	body_mesh.radius = 0.34
	body_mesh.height = body_h
	var body_inst: MeshInstance3D = MeshInstance3D.new()
	body_inst.mesh = body_mesh
	body_inst.position = Vector3(0.0, body_h * 0.55, 0.0)
	body_inst.material_override = body_mat
	parent.add_child(body_inst)

	var head_mesh: SphereMesh = SphereMesh.new()
	head_mesh.radius = 0.28
	head_mesh.height = 0.56
	var head_inst: MeshInstance3D = MeshInstance3D.new()
	head_inst.mesh = head_mesh
	head_inst.position = Vector3(0.0, body_h + 0.22, 0.0)
	head_inst.material_override = body_mat
	parent.add_child(head_inst)

	var halo_mat: StandardMaterial3D = StandardMaterial3D.new()
	halo_mat.albedo_color = Color("#E8C468")
	halo_mat.metallic = 0.75
	halo_mat.roughness = 0.25
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	halo_mat.subsurf_scatter_enabled = false
	halo_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	halo_mat.emission_enabled = true
	halo_mat.emission = Color("#FFE08A")
	halo_mat.emission_energy_multiplier = 0.65

	var halo_mesh: TorusMesh = TorusMesh.new()
	halo_mesh.inner_radius = 0.32
	halo_mesh.outer_radius = 0.39
	var halo_inst: MeshInstance3D = MeshInstance3D.new()
	halo_inst.mesh = halo_mesh
	halo_inst.position = Vector3(0.0, body_h + 0.62, 0.0)
	halo_inst.material_override = halo_mat
	parent.add_child(halo_inst)


func _spawn_lanterns() -> void:
	if _lantern_container != null and is_instance_valid(_lantern_container):
		_lantern_container.queue_free()
	_lantern_nodes.clear()

	_lantern_container = Node3D.new()
	_lantern_container.name = "StoneLanterns"
	add_child(_lantern_container)

	if architecture and architecture.has_method("get_lantern_anchor_positions"):
		var anchors: Array = architecture.call("get_lantern_anchor_positions")
		for idx: int in range(anchors.size()):
			var anchor_pos: Vector3 = anchors[idx] as Vector3
			if anchor_pos.y > 0.5:
				continue
			var lantern: Node3D = STONE_LANTERN_SCENE.instantiate() as Node3D
			lantern.name = "StoneLantern_%02d" % idx
			lantern.position = Vector3(anchor_pos.x, anchor_pos.y - 0.02, anchor_pos.z)
			if SaveManager != null and SaveManager.is_lantern_awakened(idx):
				lantern.set("start_awakened", true)
			_lantern_container.add_child(lantern)
			if lantern.has_signal("awakened"):
				lantern.connect("awakened", _on_lantern_awakened.bind(idx))
			_lantern_nodes.append(lantern)
		_total_lanterns = _lantern_nodes.size()


func _setup_garden_decorator() -> void:
	if _garden_decorator != null and is_instance_valid(_garden_decorator):
		_garden_decorator.queue_free()

	_garden_decorator = AkashaGardenDecorator.new()
	_garden_decorator.name = "AkashaGardenDecorator"
	add_child(_garden_decorator)
	_garden_decorator.populate_garden(architecture, true)


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

	# Remove legacy floating-island & duplicate plaza spirits (replaced by City of Souls Lumi)
	var legacy_npc_ids: Array[String] = ["spirit_central_island", "spirit_plaza"]
	for legacy_id: String in legacy_npc_ids:
		if _akasha_npcs._npc_by_id.has(legacy_id):
			_akasha_npcs._npc_by_id.erase(legacy_id)
		for i: int in range(_akasha_npcs._npcs.size() - 1, -1, -1):
			var npc_entry: Dictionary = _akasha_npcs._npcs[i]
			if str(npc_entry.get("id", "")) == legacy_id:
				_akasha_npcs._npcs.remove_at(i)
		var legacy_node: Node = _akasha_npcs.get_node_or_null("NPC_%s" % legacy_id)
		if legacy_node != null:
			if legacy_node is Node3D:
				(legacy_node as Node3D).visible = false
			legacy_node.queue_free()


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


func _setup_sunset_controller() -> void:
	if _sunset_controller != null and is_instance_valid(_sunset_controller):
		_sunset_controller.queue_free()

	_sunset_controller = SunsetAtmosphereController.new()
	_sunset_controller.name = "SunsetAtmosphereController"
	add_child(_sunset_controller)
	_sunset_controller.setup(world_env, sun_light, cloud_sea)


func _setup_comfort_signs() -> void:
	if _comfort_signs != null and is_instance_valid(_comfort_signs):
		_comfort_signs.queue_free()

	_comfort_signs = ComfortSigns3D.new()
	_comfort_signs.name = "ComfortSigns3D"
	add_child(_comfort_signs)
	var mirror_pos: Vector3 = earth_mirror.global_position if earth_mirror != null else Vector3(0.0, 8.0, -278.0)
	_comfort_signs.setup(mirror_pos)
	_comfort_signs.set_lesson1_active(false)


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
		if main_menu.has_signal("start_lesson1_requested"):
			main_menu.connect("start_lesson1_requested", _on_start_lesson1_requested)
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

	if _city_map_ui != null and is_instance_valid(_city_map_ui):
		if _city_map_ui.has_signal("map_closed"):
			_city_map_ui.connect("map_closed", _on_city_map_closed)

	var qm: Node = _get_quest_manager()
	if qm != null and qm.has_signal("quest_changed"):
		if not qm.is_connected("quest_changed", _on_quest_changed):
			qm.connect("quest_changed", _on_quest_changed)


func _get_quest_manager() -> Node:
	return get_node_or_null("/root/QuestManager")


func _on_quest_changed(quest_id: String, title: String, objective: String, target_pos: Vector3) -> void:
	if _is_in_gameplay and sky_hud != null and sky_hud.has_method("update_quest_tracker"):
		sky_hud.call("update_quest_tracker", title, objective)
	if _city_builder != null and is_instance_valid(_city_builder):
		_city_builder.set_quest_beacon(target_pos, quest_id != "q8_complete")


func _sync_quest_ui_and_world() -> void:
	var qm: Node = _get_quest_manager()
	if qm == null:
		return
	var quest_id: String = str(qm.call("get_current_quest_id"))
	var title: String = str(qm.call("get_current_quest_title"))
	var objective: String = str(qm.call("get_current_objective"))
	var target_pos_var: Variant = qm.call("get_current_target_pos")
	var target_pos: Vector3 = target_pos_var as Vector3 if target_pos_var is Vector3 else START_PLAYER_POS

	if _is_in_gameplay and sky_hud != null and sky_hud.has_method("update_quest_tracker"):
		sky_hud.call("update_quest_tracker", title, objective)
	if _city_builder != null and is_instance_valid(_city_builder):
		_city_builder.set_quest_beacon(target_pos, quest_id != "q8_complete")
		var piece_ids: Array[String] = ["memory_drop", "blank_page", "seven_springs_sand"]
		for piece_id: String in piece_ids:
			var collected: bool = bool(qm.call("is_blueprint_piece_collected", piece_id))
			_city_builder.set_quest_item_visible(piece_id, not collected)


func _on_city_map_closed() -> void:
	if not _is_in_gameplay or _is_transitioning or _epilogue_triggered:
		return
	var is_talking: bool = dialogue_manager != null and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active"))
	if not is_talking:
		_set_player_control(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _apply_audio_setting() -> void:
	if audio_manager and audio_manager.has_method("set_muted") and SaveManager != null:
		audio_manager.call("set_muted", SaveManager.audio_muted)


func _get_lesson1_stage() -> String:
	if SaveManager == null:
		return "not_started"
	return SaveManager.lesson1_stage


func _is_lesson1_sunset_mode() -> bool:
	var l1_stage: String = _get_lesson1_stage()
	return l1_stage == "sunset_return" or l1_stage == "collecting_signs" or l1_stage == "complete"


func _is_lesson1_collecting() -> bool:
	return _get_lesson1_stage() == "collecting_signs"


# ---------------------------------------------------------------------------
# Main Menu & Session Lifecycle
# ---------------------------------------------------------------------------

func _enter_main_menu_immediate() -> void:
	_is_in_gameplay = false
	_epilogue_triggered = false
	_current_district_id = ""
	if _city_map_ui != null and is_instance_valid(_city_map_ui) and _city_map_ui.is_map_open():
		_city_map_ui.close_map()
	_cancel_dialogue_camera()
	if SceneFlowManager != null:
		SceneFlowManager.hide_prologue_epilogue()
		SceneFlowManager.hide_lesson1_epilogue()
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
	if sky_hud and sky_hud.has_method("hide_comfort_signs_counter"):
		sky_hud.call("hide_comfort_signs_counter")
	if sky_hud and sky_hud.has_method("hide_quest_tracker"):
		sky_hud.call("hide_quest_tracker")
	_active_prompt_text = ""

	var has_save: bool = SaveManager != null and SaveManager.has_save_data()
	var is_muted: bool = SaveManager != null and SaveManager.audio_muted
	if main_menu and main_menu.has_method("show_menu"):
		main_menu.call("show_menu", has_save, is_muted)


func _enter_lesson1_sunset_return() -> void:
	_arrival_greeting_shown = true
	_epilogue_triggered = false
	_is_transitioning = false

	if main_menu and main_menu.has_method("hide_menu"):
		main_menu.call("hide_menu")

	if SaveManager != null:
		if SaveManager.lesson1_stage != "sunset_return":
			SaveManager.set_lesson1_stage("sunset_return")
		SaveManager.save_player_checkpoint(DAIS_RETURN_POS)

	if _sunset_controller != null and is_instance_valid(_sunset_controller):
		_sunset_controller.apply_golden_sunset_preset(true)

	if _comfort_signs != null and is_instance_valid(_comfort_signs):
		_comfort_signs.set_lesson1_active(true)
		if SaveManager != null:
			_comfort_signs.sync_progress(SaveManager.lesson1_signs_found, SaveManager.get_lesson1_signs_sent_count())
		else:
			var empty_ids: Array[String] = []
			_comfort_signs.sync_progress(empty_ids, 0)

	if player != null:
		if player.has_method("teleport_to"):
			player.call("teleport_to", DAIS_RETURN_POS, 0.0)
		else:
			player.global_position = DAIS_RETURN_POS
			player.velocity = Vector3.ZERO
			player.rotation.y = 0.0
		if player.has_method("set_gold_love_evolution"):
			var evo_level: float = 1.0 if (SaveManager != null and SaveManager.spark_evolution_level >= 2) else 0.0
			player.call("set_gold_love_evolution", evo_level, false)

	if earth_mirror != null and earth_mirror.has_method("awaken_mirror"):
		earth_mirror.call("awaken_mirror")

	if title_camera_rig and title_camera_rig.has_method("deactivate"):
		title_camera_rig.call("deactivate")
	_set_player_camera_current(true)

	_is_in_gameplay = true
	if sky_hud and sky_hud.has_method("set_hud_visible"):
		sky_hud.call("set_hud_visible", true)
	if sky_hud and sky_hud.has_method("hide_comfort_signs_counter"):
		sky_hud.call("hide_comfort_signs_counter")
	var qm: Node = _get_quest_manager()
	if qm != null:
		qm.call("set_quest", "q7_sunset_comfort")
		var found_cnt: int = SaveManager.get_lesson1_signs_found_count() if SaveManager != null else 0
		var sent_cnt: int = SaveManager.get_lesson1_signs_sent_count() if SaveManager != null else 0
		if qm.has_method("update_sunset_comfort_progress"):
			qm.call("update_sunset_comfort_progress", found_cnt, sent_cnt)
	_sync_quest_ui_and_world()
	_set_player_control(true)

	if audio_manager and audio_manager.has_method("play_sunset_return_chord"):
		audio_manager.call("play_sunset_return_chord")
	if sky_hud and sky_hud.has_method("show_chapter_title"):
		sky_hud.call("show_chapter_title", "У Р О К  1  ·  В О З В Р А Щ Е Н И Е", "Золотой закат Хроник", 4.5)

	_schedule_lesson1_mira_welcome(1.4)


func _schedule_lesson1_mira_welcome(delay_sec: float) -> void:
	await get_tree().create_timer(delay_sec).timeout
	if not is_inside_tree() or not _is_in_gameplay or _is_transitioning:
		return
	if dialogue_manager and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		return
	if _get_lesson1_stage() != "sunset_return":
		return
	var mira_focus_pos: Vector3 = sanctuary_mentors.global_position if sanctuary_mentors != null else DAIS_RETURN_POS + Vector3(0.0, 0.0, -6.0)
	_set_dialogue_context("mentor", "lesson1_mira_welcome", sanctuary_mentors, mira_focus_pos, 4.35, 6.8)
	_start_dialogue_sequence("lesson1_mira_welcome")


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


func _on_start_lesson1_requested() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if main_menu and main_menu.has_method("hide_menu"):
		main_menu.call("hide_menu")

	if SaveManager != null:
		SaveManager.reset_lesson1_progress()
		SaveManager.set_lesson1_stage("earth_life")

	if SceneFlowManager != null:
		SceneFlowManager.pending_world_mode = ""
		SceneFlowManager.transition_to_scene(SceneFlowManager.LESSON1_EARTH_SCENE_PATH, true)
	else:
		_is_transitioning = false


func _on_continue_game_requested() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if main_menu and main_menu.has_method("hide_menu"):
		main_menu.call("hide_menu")

	if SaveManager != null and SaveManager.lesson1_stage == "earth_life":
		if SceneFlowManager != null:
			SceneFlowManager.pending_world_mode = ""
			SceneFlowManager.transition_to_scene(SceneFlowManager.LESSON1_EARTH_SCENE_PATH, true)
			return

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

	if _get_lesson1_stage() == "sunset_return":
		_schedule_lesson1_mira_welcome(0.6)
	elif _get_lesson1_stage() == "collecting_signs" and SaveManager != null and SaveManager.get_lesson1_signs_sent_count() >= 3:
		var mentor_pos: Vector3 = sanctuary_mentors.global_position if sanctuary_mentors != null else DAIS_RETURN_POS
		_set_dialogue_context("mentor", "lesson1_finale_awakening", sanctuary_mentors, mentor_pos, 4.35, 6.8)
		_start_dialogue_sequence("lesson1_finale_awakening")


func _on_intro_completed() -> void:
	if SaveManager != null:
		SaveManager.set_prologue_stage("exploring")
	_begin_gameplay(true)
	_is_transitioning = false


func _begin_gameplay(show_title: bool) -> void:
	_is_in_gameplay = true
	if sky_hud and sky_hud.has_method("set_hud_visible"):
		sky_hud.call("set_hud_visible", true)
	_sync_quest_ui_and_world()
	_set_player_control(true)

	if show_title and sky_hud and sky_hud.has_method("show_chapter_title"):
		sky_hud.call("show_chapter_title", "П Р О Л О Г", "Обитель Хроник Акаши", 4.5)

	if SaveManager != null:
		var awakened_count: int = SaveManager.get_awakened_lantern_count()
		if awakened_count > 0 and sky_hud and sky_hud.has_method("show_lantern_progress"):
			sky_hud.call("show_lantern_progress", awakened_count, _total_lanterns)


func _reset_world_for_new_game() -> void:
	_spawn_lanterns()
	_current_district_id = ""
	if _sunset_controller != null and is_instance_valid(_sunset_controller):
		_sunset_controller.apply_dawn_preset(true)
	if _comfort_signs != null and is_instance_valid(_comfort_signs):
		var empty_ids: Array[String] = []
		_comfort_signs.sync_progress(empty_ids, 0)
		_comfort_signs.set_lesson1_active(false)
	if sky_hud and sky_hud.has_method("hide_comfort_signs_counter"):
		sky_hud.call("hide_comfort_signs_counter")
	if player:
		if player.has_method("teleport_to"):
			player.call("teleport_to", START_PLAYER_POS, 0.0)
		else:
			player.global_position = START_PLAYER_POS
			player.velocity = Vector3.ZERO
		if player.has_method("set_gold_love_evolution"):
			player.call("set_gold_love_evolution", 0.0, false)
	if earth_mirror and earth_mirror.has_method("reset_to_dormant"):
		earth_mirror.call("reset_to_dormant")
	if sanctuary_mentors and sanctuary_mentors.has_method("highlight_speaker"):
		sanctuary_mentors.call("highlight_speaker", "")
	if _castle_interactables != null and is_instance_valid(_castle_interactables):
		_castle_interactables.reset_all_relics()

	var qm: Node = _get_quest_manager()
	if qm != null and qm.has_method("reset_all"):
		qm.call("reset_all")
	if _city_builder != null and is_instance_valid(_city_builder):
		_city_builder.set_quest_item_visible("memory_drop", true)
		_city_builder.set_quest_item_visible("blank_page", true)
		_city_builder.set_quest_item_visible("seven_springs_sand", true)
	if SaveManager != null:
		SaveManager.save_game()


func _restore_world_from_save() -> void:
	_spawn_lanterns()
	_current_district_id = ""
	if SaveManager == null:
		return

	var qm: Node = _get_quest_manager()
	if qm != null and qm.has_method("import_state"):
		qm.call("import_state", SaveManager.quest_state)

	var stage: String = SaveManager.prologue_stage
	var l1_stage: String = SaveManager.lesson1_stage
	var is_l1_sunset: bool = (
		l1_stage == "sunset_return"
		or l1_stage == "collecting_signs"
		or l1_stage == "complete"
	)

	_epilogue_triggered = false
	_arrival_greeting_shown = is_l1_sunset or (stage != "intro" and stage != "exploring")

	if player:
		var target_pos: Vector3 = START_PLAYER_POS
		if SaveManager.has_custom_player_pos:
			target_pos = SaveManager.last_player_pos
		elif is_l1_sunset:
			target_pos = DAIS_RETURN_POS
		if player.has_method("teleport_to"):
			player.call("teleport_to", target_pos, 0.0)
		else:
			player.global_position = target_pos
			player.velocity = Vector3.ZERO

	if is_l1_sunset:
		if _sunset_controller != null and is_instance_valid(_sunset_controller):
			_sunset_controller.apply_golden_sunset_preset(true)
		if _comfort_signs != null and is_instance_valid(_comfort_signs):
			_comfort_signs.set_lesson1_active(true)
			_comfort_signs.sync_progress(SaveManager.lesson1_signs_found, SaveManager.get_lesson1_signs_sent_count())
		if sky_hud:
			if l1_stage == "collecting_signs" and sky_hud.has_method("update_comfort_signs_counter"):
				sky_hud.call(
					"update_comfort_signs_counter",
					SaveManager.get_lesson1_signs_found_count(),
					SaveManager.get_lesson1_signs_sent_count(),
					3
				)
			elif sky_hud.has_method("hide_comfort_signs_counter"):
				sky_hud.call("hide_comfort_signs_counter")
		if player and player.has_method("set_gold_love_evolution"):
			var evo_level: float = 1.0 if SaveManager.spark_evolution_level >= 2 else 0.0
			player.call("set_gold_love_evolution", evo_level, false)
		if earth_mirror and earth_mirror.has_method("awaken_mirror"):
			earth_mirror.call("awaken_mirror")
	else:
		if _sunset_controller != null and is_instance_valid(_sunset_controller):
			_sunset_controller.apply_dawn_preset(true)
		if _comfort_signs != null and is_instance_valid(_comfort_signs):
			_comfort_signs.set_lesson1_active(false)
		if sky_hud and sky_hud.has_method("hide_comfort_signs_counter"):
			sky_hud.call("hide_comfort_signs_counter")
		if player and player.has_method("set_gold_love_evolution"):
			player.call("set_gold_love_evolution", 0.0, false)
		if earth_mirror:
			if stage == "contract_spoken":
				if earth_mirror.has_method("set_ready_for_call"):
					earth_mirror.call("set_ready_for_call")
			elif stage == "mirror_awakened" or stage == "prologue_complete":
				if earth_mirror.has_method("awaken_mirror"):
					earth_mirror.call("awaken_mirror")

	_sync_quest_ui_and_world()


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
	if not _is_in_gameplay or _is_transitioning or _epilogue_triggered:
		return
	if dialogue_manager and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		return
	if _city_map_ui != null and is_instance_valid(_city_map_ui) and _city_map_ui.is_map_open():
		return

	var pressed_interact: bool = false
	if InputMap.has_action("interact") and event.is_action_pressed("interact"):
		pressed_interact = true
	elif event is InputEventKey:
		var key_ev: InputEventKey = event as InputEventKey
		if key_ev.pressed and not key_ev.echo:
			if key_ev.keycode == KEY_M or key_ev.physical_keycode == KEY_M:
				if _city_map_ui != null and is_instance_valid(_city_map_ui):
					_set_player_control(false)
					_update_prompt("")
					var p_pos_map: Vector3 = player.global_position if player != null else START_PLAYER_POS
					var p_yaw_map: float = 0.0
					if player != null:
						var cam_yaw_val: Variant = player.get("cam_yaw")
						if cam_yaw_val is float:
							p_yaw_map = cam_yaw_val as float
						else:
							var facing_yaw_val: Variant = player.get("facing_yaw")
							if facing_yaw_val is float:
								p_yaw_map = facing_yaw_val as float
							else:
								p_yaw_map = player.rotation.y
					_city_map_ui.open_map(p_pos_map, p_yaw_map)
					get_viewport().set_input_as_handled()
				return
			if key_ev.keycode == KEY_ESCAPE:
				# If mouse is already released (not captured by 3D look), Escape opens the Main Menu
				if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
					get_viewport().set_input_as_handled()
					_return_to_main_menu()
				return
			if key_ev.keycode == KEY_E or key_ev.physical_keycode == KEY_E:
				pressed_interact = true

	if pressed_interact and player != null:
		if _is_lesson1_collecting() and _comfort_signs != null and is_instance_valid(_comfort_signs):
			var nearest_sign_id: String = _comfort_signs.get_nearest_uncollected_sign_id(player.global_position)
			if not nearest_sign_id.is_empty():
				_collect_comfort_sign(nearest_sign_id)
				get_viewport().set_input_as_handled()
				return
		if _try_interact_city_quest_target(player.global_position):
			get_viewport().set_input_as_handled()
			return
		if _try_interact_city_venue(player.global_position):
			get_viewport().set_input_as_handled()
			return
		if _castle_interactables != null and is_instance_valid(_castle_interactables):
			var relic_seq: String = _castle_interactables.interact_nearest(player.global_position)
			if not relic_seq.is_empty():
				get_viewport().set_input_as_handled()
				return
		if _akasha_npcs != null and is_instance_valid(_akasha_npcs):
			if _akasha_npcs.interact_nearest(player.global_position):
				get_viewport().set_input_as_handled()


func _try_interact_city_quest_target(p_pos: Vector3) -> bool:
	var qm: Node = _get_quest_manager()
	var q_id: String = str(qm.call("get_current_quest_id")) if qm != null else "q1_meet_lumi"
	var has_all_pieces: bool = bool(qm.call("has_all_blueprint_pieces")) if qm != null else false

	var best_id: String = ""
	var best_seq: String = ""
	var best_dist: float = CITY_NPC_INTERACT_RANGE
	var best_node: Node3D = null
	var best_pos: Vector3 = Vector3.ZERO
	var best_eye: float = 1.6
	var best_cam_dist: float = 5.2

	# 1. Check the 4 City Mentors
	for npc_id_var: Variant in _city_quest_npcs.keys():
		var npc_id: String = str(npc_id_var)
		var entry: Dictionary = _city_quest_npcs[npc_id] as Dictionary
		var npc_pos: Vector3 = entry["pos"] as Vector3
		var dx: float = p_pos.x - npc_pos.x
		var dz: float = p_pos.z - npc_pos.z
		var dist: float = sqrt(dx * dx + dz * dz)
		if dist > best_dist:
			continue

		var seq_id: String = ""
		if npc_id == "city_lumi":
			seq_id = "city_lumi_intro"
		elif npc_id == "city_alatea":
			if q_id == "q1_meet_lumi" or q_id == "q2_find_school":
				seq_id = "city_school_alatea_assign"
			elif q_id == "q3_gather_blueprint":
				if has_all_pieces:
					seq_id = "city_school_alatea_complete"
				else:
					seq_id = "city_school_alatea_waiting"
			elif q_id == "q4_return_to_school":
				seq_id = "city_school_alatea_complete"
		elif npc_id == "city_orion":
			var has_page: bool = bool(qm.call("is_blueprint_piece_collected", "blank_page")) if qm != null else false
			if not has_page and q_id == "q3_gather_blueprint":
				seq_id = "city_library_orion"
		elif npc_id == "city_kronos":
			var has_sand: bool = bool(qm.call("is_blueprint_piece_collected", "seven_springs_sand")) if qm != null else false
			if not has_sand and q_id == "q3_gather_blueprint":
				seq_id = "city_tower_kronos"

		if not seq_id.is_empty():
			best_dist = dist
			best_id = npc_id
			best_seq = seq_id
			best_node = entry["node"] as Node3D
			best_pos = npc_pos
			best_eye = float(entry["eye_height"])
			best_cam_dist = float(entry["cam_dist"])

	# 2. Check Lake of Silence Memory Drop point (42, 0, 10)
	var has_drop: bool = bool(qm.call("is_blueprint_piece_collected", "memory_drop")) if qm != null else false
	if not has_drop and q_id == "q3_gather_blueprint":
		var ldx: float = p_pos.x - CITY_MEMORY_DROP_POS.x
		var ldz: float = p_pos.z - CITY_MEMORY_DROP_POS.z
		var ldist: float = sqrt(ldx * ldx + ldz * ldz)
		if ldist <= best_dist:
			best_dist = ldist
			best_id = "city_memory_drop"
			best_seq = "city_park_memory_drop"
			best_node = null
			best_pos = CITY_MEMORY_DROP_POS
			best_eye = 1.25
			best_cam_dist = 4.8

	if best_seq.is_empty():
		return false

	if audio_manager and audio_manager.has_method("play_lantern_chime"):
		audio_manager.call("play_lantern_chime", posmod(best_id.hash(), 5))

	_set_dialogue_context("npc", best_id, best_node, best_pos, best_eye, best_cam_dist)
	_start_dialogue_sequence(best_seq)
	return true


func _get_city_quest_prompt(p_pos: Vector3) -> String:
	var qm: Node = _get_quest_manager()
	var q_id: String = str(qm.call("get_current_quest_id")) if qm != null else "q1_meet_lumi"
	var has_all_pieces: bool = bool(qm.call("has_all_blueprint_pieces")) if qm != null else false

	var best_prompt: String = ""
	var best_dist: float = CITY_NPC_INTERACT_RANGE

	for npc_id_var: Variant in _city_quest_npcs.keys():
		var npc_id: String = str(npc_id_var)
		var entry: Dictionary = _city_quest_npcs[npc_id] as Dictionary
		var npc_pos: Vector3 = entry["pos"] as Vector3
		var dx: float = p_pos.x - npc_pos.x
		var dz: float = p_pos.z - npc_pos.z
		var dist: float = sqrt(dx * dx + dz * dz)
		if dist > best_dist:
			continue

		var prompt_text: String = ""
		if npc_id == "city_lumi":
			prompt_text = "✦  [E]  Поговорить с Люми"
		elif npc_id == "city_alatea":
			if q_id == "q4_return_to_school" or (q_id == "q3_gather_blueprint" and has_all_pieces):
				prompt_text = "✦  [E]  Передать основы Чертежа Алатее"
			elif q_id == "q1_meet_lumi" or q_id == "q2_find_school" or q_id == "q3_gather_blueprint":
				prompt_text = "✦  [E]  Поговорить с Алатеей (Школа Юных Душ)"
		elif npc_id == "city_orion":
			var has_page: bool = bool(qm.call("is_blueprint_piece_collected", "blank_page")) if qm != null else false
			if not has_page and q_id == "q3_gather_blueprint":
				prompt_text = "✦  [E]  Поговорить с Орионом (Библиотека)"
		elif npc_id == "city_kronos":
			var has_sand: bool = bool(qm.call("is_blueprint_piece_collected", "seven_springs_sand")) if qm != null else false
			if not has_sand and q_id == "q3_gather_blueprint":
				prompt_text = "✦  [E]  Поговорить с Кроносом (Башня Времени)"

		if not prompt_text.is_empty():
			best_dist = dist
			best_prompt = prompt_text

	var has_drop: bool = bool(qm.call("is_blueprint_piece_collected", "memory_drop")) if qm != null else false
	if not has_drop and q_id == "q3_gather_blueprint":
		var ldx: float = p_pos.x - CITY_MEMORY_DROP_POS.x
		var ldz: float = p_pos.z - CITY_MEMORY_DROP_POS.z
		var ldist: float = sqrt(ldx * ldx + ldz * ldz)
		if ldist <= best_dist:
			best_prompt = "✦  [E]  Собрать Каплю Памяти (Парк Тишины)"

	return best_prompt


func _try_interact_city_venue(p_pos: Vector3) -> bool:
	if _city_builder == null or not is_instance_valid(_city_builder):
		return false
	if not _city_builder.has_method("get_nearest_venue_in_range"):
		return false
	var venue_var: Variant = _city_builder.call("get_nearest_venue_in_range", p_pos, 6.0)
	if not (venue_var is Dictionary):
		return false
	var venue: Dictionary = venue_var as Dictionary
	if venue.is_empty():
		return false
	var dialogue_id: String = str(venue.get("dialogue_id", ""))
	if dialogue_id.is_empty():
		return false

	var venue_pos_var: Variant = venue.get("pos", p_pos)
	var venue_pos: Vector3 = venue_pos_var as Vector3 if venue_pos_var is Vector3 else p_pos
	var venue_id: String = str(venue.get("id", dialogue_id))

	if audio_manager and audio_manager.has_method("play_lantern_chime"):
		audio_manager.call("play_lantern_chime", posmod(venue_id.hash(), 5))

	_set_dialogue_context("npc", venue_id, null, venue_pos, 1.85, 5.8)
	_start_dialogue_sequence(dialogue_id)
	return true


func _get_city_venue_prompt(p_pos: Vector3) -> String:
	if _city_builder == null or not is_instance_valid(_city_builder):
		return ""
	if not _city_builder.has_method("get_nearest_venue_in_range"):
		return ""
	var venue_var: Variant = _city_builder.call("get_nearest_venue_in_range", p_pos, 6.0)
	if not (venue_var is Dictionary):
		return ""
	var venue: Dictionary = venue_var as Dictionary
	if venue.is_empty():
		return ""
	return str(venue.get("prompt", ""))


# ---------------------------------------------------------------------------
# Gameplay Signals (Soul Call, Lanterns, Mentors, Earth Mirror, Castle Relics, NPCs)
# ---------------------------------------------------------------------------

func _collect_comfort_sign(sign_id: String) -> void:
	if sign_id.is_empty():
		return
	if dialogue_manager and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		return

	if _comfort_signs != null and is_instance_valid(_comfort_signs):
		_comfort_signs.mark_sign_collected(sign_id)

	if SaveManager != null:
		SaveManager.mark_lesson1_sign_found(sign_id)

	if audio_manager and audio_manager.has_method("play_comfort_sign_found"):
		audio_manager.call("play_comfort_sign_found")

	var found_count: int = SaveManager.get_lesson1_signs_found_count() if SaveManager != null else 1
	var sent_count: int = SaveManager.get_lesson1_signs_sent_count() if SaveManager != null else 0
	if sky_hud and sky_hud.has_method("update_comfort_signs_counter"):
		sky_hud.call("update_comfort_signs_counter", found_count, sent_count, 3)
	var qm: Node = _get_quest_manager()
	if qm != null and qm.has_method("update_sunset_comfort_progress"):
		qm.call("update_sunset_comfort_progress", found_count, sent_count)

	var sign_pos: Vector3 = player.global_position + Vector3(0.0, 0.0, -4.0) if player != null else Vector3.ZERO
	if _comfort_signs != null and is_instance_valid(_comfort_signs):
		sign_pos = _comfort_signs.get_sign_world_position(sign_id)
	_set_dialogue_context("comfort_sign", sign_id, null, sign_pos, 1.45, 5.2)

	var seq_id: String = ""
	if sign_id == ComfortSigns3D.SIGN_GARDEN:
		seq_id = "lesson1_sign_garden"
	elif sign_id == ComfortSigns3D.SIGN_FOUNTAIN:
		seq_id = "lesson1_sign_fountain"
	elif sign_id == ComfortSigns3D.SIGN_BOAT:
		seq_id = "lesson1_sign_boat"

	if not seq_id.is_empty():
		_start_dialogue_sequence(seq_id)


func _try_send_comfort_sign_through_mirror(origin: Vector3) -> bool:
	if not _is_lesson1_collecting() or SaveManager == null:
		return false
	if earth_mirror == null or not earth_mirror.has_method("is_player_near_call_zone"):
		return false
	if not bool(earth_mirror.call("is_player_near_call_zone", origin)):
		return false

	var found_count: int = SaveManager.get_lesson1_signs_found_count()
	var sent_count: int = SaveManager.get_lesson1_signs_sent_count()
	if found_count <= sent_count:
		return false

	var next_sign_id: String = ""
	for sid: String in SaveManager.lesson1_signs_found:
		if not SaveManager.has_lesson1_sign_sent(sid):
			next_sign_id = sid
			break
	if next_sign_id.is_empty():
		return false

	SaveManager.mark_lesson1_sign_sent(next_sign_id)
	var new_sent: int = SaveManager.get_lesson1_signs_sent_count()

	if _comfort_signs != null and is_instance_valid(_comfort_signs):
		_comfort_signs.set_sent_count(new_sent)
		_comfort_signs.pulse_mirror_thread()

	if audio_manager and audio_manager.has_method("play_comfort_sign_sent"):
		audio_manager.call("play_comfort_sign_sent")

	if sky_hud and sky_hud.has_method("update_comfort_signs_counter"):
		sky_hud.call("update_comfort_signs_counter", found_count, new_sent, 3)
	var qm: Node = _get_quest_manager()
	if qm != null and qm.has_method("update_sunset_comfort_progress"):
		qm.call("update_sunset_comfort_progress", found_count, new_sent)

	_update_prompt("")
	var clamped_step: int = clampi(new_sent, 1, 3)
	var send_seq: String = "lesson1_mirror_send_%d" % clamped_step
	_set_dialogue_context("mirror", send_seq, earth_mirror, earth_mirror.global_position, 3.6, 7.8)
	_start_dialogue_sequence(send_seq)
	return true


func _on_player_soul_call(origin: Vector3) -> void:
	if soul_call and soul_call.has_method("trigger"):
		soul_call.call("trigger", origin)
	if audio_manager and audio_manager.has_method("play_soul_call"):
		audio_manager.call("play_soul_call")

	if dialogue_manager and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		return

	# 0. Lesson 1: Send a collected Comfort Sign through the Earth Mirror via Soul Call [Q]
	if _try_send_comfort_sign_through_mirror(origin):
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
			if not _is_lesson1_sunset_mode() and (stage == "exploring" or stage == "intro"):
				var mentor_pos: Vector3 = sanctuary_mentors.global_position
				_set_dialogue_context("mentor", "first_contract", sanctuary_mentors, mentor_pos, 4.35, 6.8)
				_start_dialogue_sequence("first_contract")
				return
			elif _get_lesson1_stage() == "sunset_return" and sanctuary_mentors.has_method("is_player_in_talk_range") and bool(sanctuary_mentors.call("is_player_in_talk_range", origin)):
				var mira_pos: Vector3 = sanctuary_mentors.global_position
				_set_dialogue_context("mentor", "lesson1_mira_welcome", sanctuary_mentors, mira_pos, 4.35, 6.8)
				_start_dialogue_sequence("lesson1_mira_welcome")
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

	var effective_seq: String = dialogue_sequence_id
	if _is_lesson1_sunset_mode():
		if npc_id == "lumi" or npc_id == "spirit_plaza" or npc_id == "spirit_balcony" or dialogue_sequence_id == "npc_plaza_spirit":
			effective_seq = "lesson1_lumi_sunset"

	if not effective_seq.is_empty():
		_start_dialogue_sequence(effective_seq)


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

	if _dialogue_context_kind == "comfort_sign":
		var sign_nudge: float = 0.45 if normalized == "mira" else 0.0
		return {
			"base_pos": _dialogue_context_pos,
			"eye_height": _dialogue_context_eye_height,
			"distance": _dialogue_context_distance,
			"speaker_nudge": sign_nudge,
		}

	if _dialogue_context_kind == "mirror":
		if normalized == "mira" and sanctuary_mentors != null and is_instance_valid(sanctuary_mentors):
			var mira_ref: Node3D = sanctuary_mentors.get_node_or_null("Mira") as Node3D
			if mira_ref != null:
				return {
					"base_pos": mira_ref.global_position,
					"eye_height": 4.35,
					"distance": 6.8,
					"speaker_nudge": 0.45,
				}
		var mirror_focus: Vector3 = earth_mirror.global_position if earth_mirror != null else _dialogue_context_pos
		return {
			"base_pos": mirror_focus,
			"eye_height": _dialogue_context_eye_height,
			"distance": _dialogue_context_distance,
			"speaker_nudge": 0.0,
		}

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

	if normalized == "earth_mirror" and earth_mirror != null and is_instance_valid(earth_mirror):
		return {
			"base_pos": earth_mirror.global_position,
			"eye_height": 3.6,
			"distance": 7.8,
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

	var qm: Node = _get_quest_manager()
	var current_q: String = str(qm.call("get_current_quest_id")) if qm != null else ""

	if sequence_id == "city_lumi_intro":
		if qm != null and current_q == "q1_meet_lumi":
			qm.call("set_quest", "q2_find_school")
			if SaveManager != null:
				SaveManager.save_game()
	elif sequence_id == "city_school_alatea_assign":
		if qm != null and (current_q == "q1_meet_lumi" or current_q == "q2_find_school"):
			qm.call("set_quest", "q3_gather_blueprint")
			if SaveManager != null:
				SaveManager.save_game()
	elif sequence_id == "city_park_memory_drop":
		if qm != null:
			qm.call("mark_blueprint_piece_collected", "memory_drop")
		if _city_builder != null and is_instance_valid(_city_builder):
			_city_builder.set_quest_item_visible("memory_drop", false)
		if SaveManager != null:
			SaveManager.save_game()
	elif sequence_id == "city_library_orion":
		if qm != null:
			qm.call("mark_blueprint_piece_collected", "blank_page")
		if _city_builder != null and is_instance_valid(_city_builder):
			_city_builder.set_quest_item_visible("blank_page", false)
		if SaveManager != null:
			SaveManager.save_game()
	elif sequence_id == "city_tower_kronos":
		if qm != null:
			qm.call("mark_blueprint_piece_collected", "seven_springs_sand")
		if _city_builder != null and is_instance_valid(_city_builder):
			_city_builder.set_quest_item_visible("seven_springs_sand", false)
		if SaveManager != null:
			SaveManager.save_game()
	elif sequence_id == "city_school_alatea_complete":
		if qm != null and (current_q == "q4_return_to_school" or current_q == "q3_gather_blueprint"):
			qm.call("consume_blueprint_pieces")
			if SaveManager != null:
				SaveManager.save_game()
	elif sequence_id == "city_venue_cafe":
		if player != null:
			if player.has_method("recharge_wing_energy"):
				player.call("recharge_wing_energy", 5.0)
			else:
				player.set("wing_energy", 5.0)
		if qm != null and qm.has_method("add_item"):
			qm.call(
				"add_item",
				"starlight_cocoa",
				"Чашка звёздного какао",
				"Тёплое эхо из Кафе «Тёплая Чашка» — пахнет корицей и домом."
			)
		if audio_manager and audio_manager.has_method("play_comfort_sign_found"):
			audio_manager.call("play_comfort_sign_found")
		if SaveManager != null:
			SaveManager.save_game()
	elif sequence_id == "city_venue_shop":
		if qm != null and qm.has_method("add_item"):
			qm.call(
				"add_item",
				"glass_marble_charm",
				"Стеклянный талисман",
				"Подарок из Лавки Воспоминаний — хранит солнечный блик."
			)
		if audio_manager and audio_manager.has_method("play_comfort_sign_found"):
			audio_manager.call("play_comfort_sign_found")
		if SaveManager != null:
			SaveManager.save_game()
	elif sequence_id == "city_venue_gym":
		if player != null:
			if player.has_method("recharge_wing_energy"):
				player.call("recharge_wing_energy", 5.0)
			else:
				player.set("wing_energy", 5.0)
		if audio_manager:
			if audio_manager.has_method("play_wind_ring_note"):
				audio_manager.call("play_wind_ring_note", 4)
			elif audio_manager.has_method("play_soul_call"):
				audio_manager.call("play_soul_call")
	elif sequence_id == "city_venue_mall":
		if qm != null and qm.has_method("add_item"):
			qm.call(
				"add_item",
				"gallery_melody",
				"Пластинка Галереи Миров",
				"Тихая мелодия из Торгового Пассажа, которую напевают души разных эпох."
			)
		if audio_manager and audio_manager.has_method("play_comfort_sign_found"):
			audio_manager.call("play_comfort_sign_found")
		if SaveManager != null:
			SaveManager.save_game()
	elif sequence_id == "first_contract":
		if qm != null:
			qm.call("set_quest", "q6_awaken_mirror")
		if SaveManager != null:
			SaveManager.set_prologue_stage("contract_spoken")
		if earth_mirror and earth_mirror.has_method("set_ready_for_call"):
			earth_mirror.call("set_ready_for_call")
	elif sequence_id == "lesson1_mira_welcome":
		if qm != null:
			qm.call("set_quest", "q7_sunset_comfort")
		if SaveManager != null:
			SaveManager.set_lesson1_stage("collecting_signs")
			var found_cnt: int = SaveManager.get_lesson1_signs_found_count()
			var sent_cnt: int = SaveManager.get_lesson1_signs_sent_count()
			if qm != null and qm.has_method("update_sunset_comfort_progress"):
				qm.call("update_sunset_comfort_progress", found_cnt, sent_cnt)
			if sky_hud and sky_hud.has_method("update_comfort_signs_counter"):
				sky_hud.call("update_comfort_signs_counter", found_cnt, sent_cnt, 3)
	elif sequence_id == "lesson1_mirror_send_3":
		var mentor_pos: Vector3 = sanctuary_mentors.global_position if sanctuary_mentors != null else DAIS_RETURN_POS
		_set_dialogue_context("mentor", "lesson1_finale_awakening", sanctuary_mentors, mentor_pos, 4.35, 6.8)
		_start_dialogue_sequence("lesson1_finale_awakening")
		return
	elif sequence_id == "lesson1_finale_awakening":
		if qm != null:
			qm.call("set_quest", "q8_complete")
		_end_dialogue_camera()
		_dialogue_context_kind = ""
		_dialogue_context_id = ""
		_dialogue_context_node = null
		_trigger_lesson1_completion()
		return

	_end_dialogue_camera()
	_dialogue_context_kind = ""
	_dialogue_context_id = ""
	_dialogue_context_node = null
	_set_player_control(true)


func _trigger_lesson1_completion() -> void:
	if _epilogue_triggered or _is_transitioning:
		return
	_epilogue_triggered = true
	_is_transitioning = true
	_set_player_control(false)
	_update_prompt("")

	if SaveManager != null:
		SaveManager.set_lesson1_stage("complete")
	if player != null and player.has_method("set_gold_love_evolution"):
		player.call("set_gold_love_evolution", 1.0, true)
	if audio_manager and audio_manager.has_method("play_unconditional_love_awakening"):
		audio_manager.call("play_unconditional_love_awakening")
	if sky_hud and sky_hud.has_method("hide_comfort_signs_counter"):
		sky_hud.call("hide_comfort_signs_counter")

	await get_tree().create_timer(1.8).timeout
	_is_transitioning = false
	if not is_inside_tree() or not _is_in_gameplay:
		_epilogue_triggered = false
		return

	if SceneFlowManager != null:
		SceneFlowManager.show_lesson1_epilogue(
			_on_lesson1_epilogue_continue,
			_on_epilogue_return_menu
		)
	else:
		_epilogue_triggered = false
		_set_player_control(true)


func _on_lesson1_epilogue_continue() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if SceneFlowManager != null:
		SceneFlowManager.hide_lesson1_epilogue()

	_epilogue_triggered = false
	_set_player_control(true)
	_is_transitioning = false


# ---------------------------------------------------------------------------
# Earth Mirror & Prologue Completion
# ---------------------------------------------------------------------------

func _on_mirror_awakened() -> void:
	if _is_lesson1_sunset_mode():
		return
	if audio_manager and audio_manager.has_method("play_mirror_awakening"):
		audio_manager.call("play_mirror_awakening")
	if SaveManager != null and SaveManager.prologue_stage != "prologue_complete":
		SaveManager.set_prologue_stage("mirror_awakened")


func _on_player_entered_portal() -> void:
	if _epilogue_triggered or _is_transitioning or not _is_in_gameplay:
		return
	if _get_lesson1_stage() != "not_started":
		return
	_trigger_prologue_completion()


func _trigger_prologue_completion() -> void:
	if _get_lesson1_stage() != "not_started":
		return

	_epilogue_triggered = true
	_is_transitioning = true
	_cancel_dialogue_camera()
	_set_player_control(false)
	_update_prompt("")

	if audio_manager and audio_manager.has_method("play_mirror_awakening"):
		audio_manager.call("play_mirror_awakening")
	if SaveManager != null:
		SaveManager.set_prologue_stage("prologue_complete")
		SaveManager.set_lesson1_stage("earth_life")
		SaveManager.save_player_checkpoint(DAIS_RETURN_POS)

	if SceneFlowManager != null:
		SceneFlowManager.pending_world_mode = ""
		SceneFlowManager.transition_to_scene(SceneFlowManager.LESSON1_EARTH_SCENE_PATH, true)
		return

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
		SceneFlowManager.hide_lesson1_epilogue()
		await SceneFlowManager.fade_to_veil(0.65, true)

	_enter_main_menu_immediate()

	if SceneFlowManager != null:
		await SceneFlowManager.fade_from_veil(0.95)

	_epilogue_triggered = false
	_is_transitioning = false


# ---------------------------------------------------------------------------
# Per-Frame Contextual Prompts, Triggers & Autosave Checkpoints
# ---------------------------------------------------------------------------

func _update_prompt(new_text: String) -> void:
	var cleaned: String = new_text.strip_edges()
	if not cleaned.is_empty() and dialogue_manager != null and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		cleaned = ""
	if cleaned == _active_prompt_text:
		return
	_active_prompt_text = cleaned
	if not sky_hud:
		return
	if cleaned.is_empty():
		if sky_hud.has_method("hide_interaction_prompt"):
			sky_hud.call("hide_interaction_prompt")
	else:
		if sky_hud.has_method("show_interaction_prompt"):
			sky_hud.call("show_interaction_prompt", cleaned)


func _process(delta: float) -> void:
	_city_npc_anim_time += delta
	for npc_id_var: Variant in _city_quest_npcs.keys():
		var entry: Dictionary = _city_quest_npcs[npc_id_var] as Dictionary
		var vis: Node3D = entry["visual"] as Node3D
		if vis != null and is_instance_valid(vis):
			var base_y: float = float(entry["base_y"])
			var amp: float = float(entry["bob_amp"])
			var ph: float = float(entry["phase"])
			vis.position.y = base_y + sin(_city_npc_anim_time * 1.45 + ph) * amp

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

	if not _is_in_gameplay or _is_transitioning or _epilogue_triggered or not player:
		return

	if is_talking:
		if not _active_prompt_text.is_empty():
			_update_prompt("")
		return

	# Periodic safe checkpoint autosave while grounded
	_checkpoint_timer += delta
	if _checkpoint_timer >= 8.0 and player.is_on_floor():
		_checkpoint_timer = 0.0
		if SaveManager != null:
			SaveManager.save_player_checkpoint(player.global_position)

	var p_pos: Vector3 = player.global_position
	var stage: String = SaveManager.prologue_stage if SaveManager != null else "exploring"

	# 0. District entrance banner tracking across the 9 districts of the City of Souls
	if _city_builder != null and is_instance_valid(_city_builder):
		var d_info: Dictionary = _city_builder.get_district_info_at(p_pos)
		if not d_info.is_empty():
			var d_id: String = str(d_info.get("id", ""))
			var d_name: String = str(d_info.get("name", ""))
			if not d_id.is_empty() and d_id != _current_district_id:
				_current_district_id = d_id
				if sky_hud != null and sky_hud.has_method("show_district_banner"):
					sky_hud.call("show_district_banner", d_name)

	# 1. Warm arrival greeting when approaching the Cathedral grand stairs
	if not _arrival_greeting_shown and not _is_lesson1_sunset_mode() and stage == "exploring" and p_pos.z < -210.0:
		_arrival_greeting_shown = true
		var arrival_pos: Vector3 = sanctuary_mentors.global_position if sanctuary_mentors != null else p_pos + Vector3(0.0, 0.0, -8.0)
		_set_dialogue_context("mentor", "cathedral_arrival", sanctuary_mentors, arrival_pos, 4.35, 6.8)
		_start_dialogue_sequence("cathedral_arrival")
		return

	# 2. Check portal step-in when Earth Mirror is awakened (Prologue -> Lesson 1 only)
	if _get_lesson1_stage() == "not_started" and earth_mirror and earth_mirror.has_method("is_player_in_portal_zone"):
		if bool(earth_mirror.call("is_player_in_portal_zone", p_pos)):
			_trigger_prologue_completion()
			return

	# 3. Contextual gentle Sky-style interaction prompts
	_update_interaction_prompt(p_pos, stage)


func _update_interaction_prompt(p_pos: Vector3, stage: String) -> void:
	if dialogue_manager != null and dialogue_manager.has_method("is_active") and bool(dialogue_manager.call("is_active")):
		_update_prompt("")
		return
	var city_prompt: String = _get_city_quest_prompt(p_pos)
	var venue_prompt: String = _get_city_venue_prompt(p_pos)

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

	var l1_stage: String = _get_lesson1_stage()
	var prompt: String = ""

	if l1_stage == "collecting_signs":
		var found_count: int = SaveManager.get_lesson1_signs_found_count() if SaveManager != null else 0
		var sent_count: int = SaveManager.get_lesson1_signs_sent_count() if SaveManager != null else 0
		var sign_prompt: String = ""
		if _comfort_signs != null and is_instance_valid(_comfort_signs):
			sign_prompt = _comfort_signs.get_interaction_prompt(p_pos)

		if near_mirror_zone and found_count > sent_count:
			prompt = "✦  [Q]  Послать Знак Утешения сквозь Зеркало"
		elif not sign_prompt.is_empty():
			prompt = sign_prompt
		elif not city_prompt.is_empty():
			prompt = city_prompt
		elif not venue_prompt.is_empty():
			prompt = venue_prompt
		elif not npc_prompt.is_empty():
			prompt = npc_prompt
		elif not relic_prompt.is_empty():
			prompt = relic_prompt
		_update_prompt(prompt)
		return

	if l1_stage == "sunset_return" or l1_stage == "complete":
		if l1_stage == "sunset_return" and sanctuary_mentors and sanctuary_mentors.has_method("is_player_in_talk_range"):
			if bool(sanctuary_mentors.call("is_player_in_talk_range", p_pos)):
				prompt = "✦  [Q]  Поговорить с Мирой"
		if prompt.is_empty() and not city_prompt.is_empty():
			prompt = city_prompt
		elif prompt.is_empty() and not venue_prompt.is_empty():
			prompt = venue_prompt
		elif prompt.is_empty() and not npc_prompt.is_empty():
			prompt = npc_prompt
		elif prompt.is_empty() and not relic_prompt.is_empty():
			prompt = relic_prompt
		_update_prompt(prompt)
		return

	if not city_prompt.is_empty():
		_update_prompt(city_prompt)
		return

	if not venue_prompt.is_empty():
		_update_prompt(venue_prompt)
		return

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
