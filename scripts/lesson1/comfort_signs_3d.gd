class_name ComfortSigns3D
extends Node3D

## Manages the 3 Comfort Signs (Знаки Утешения) for Lesson 1 and the Parents'
## Thread of Pain (Нить боли родителей) arching from the Earth Mirror into the
## Akasha Palace Ballroom.

const SIGN_GARDEN: String = "garden"
const SIGN_FOUNTAIN: String = "fountain"
const SIGN_BOAT: String = "boat"

const MODEL_GARDEN_PATH: String = "res://assets/models/props/comfort_sign_garden.glb"
const MODEL_FOUNTAIN_PATH: String = "res://assets/models/props/comfort_sign_fountain.glb"
const MODEL_BOAT_PATH: String = "res://assets/models/props/comfort_sign_boat.glb"

## Verified collision-free world positions (offset >11m from Prologue relics & >5m from walls)
const POS_GARDEN: Vector3 = Vector3(-6.5, 0.06, -236.5)    # Formal Arrival Court sunlit garden terrace (floor Y = 0.06)
const POS_FOUNTAIN: Vector3 = Vector3(-27.5, 8.0, -287.0)  # West Fountain Salon (floor Y = 8.0)
const POS_BOAT: Vector3 = Vector3(27.5, 8.0, -287.0)       # East Library Salon (floor Y = 8.0)

const INTERACTION_RADIUS: float = 4.6
const MIRROR_CENTER_HEIGHT: float = 4.6

const THREAD_COLOR_0: Color = Color("#7AA8E8")  # Anxious silver-blue
const THREAD_COLOR_1: Color = Color("#D9B2A8")  # Warmer peach-silver
const THREAD_COLOR_2: Color = Color("#F2C488")  # Warm amber rose-gold
const THREAD_COLOR_3: Color = Color("#FFD878")  # Pure radiant Unconditional Love gold

const THREAD_SEGMENTS: int = 44

var _lesson1_active: bool = false
var _is_built: bool = false
var _mirror_pos: Vector3 = Vector3(0.0, 8.0, -278.0)
var _sent_count: int = 0
var _anim_time: float = 0.0

# Per-sign state dictionaries keyed by sign_id
var _sign_defs: Array[Dictionary] = []
var _sign_nodes: Dictionary = {}       # sign_id -> Dictionary of Node3D / OmniLight3D / GPUParticles3D
var _collected_map: Dictionary = {}    # sign_id -> bool
var _collect_blend: Dictionary = {}    # sign_id -> float (0.0 uncollected -> 1.0 collected serene)

# Parents' Thread of Pain (ImmediateMesh ribbon + companion harmonic spiral)
var _thread_root: Node3D = null
var _thread_mesh_inst: MeshInstance3D = null
var _thread_imm_mesh: ImmediateMesh = null
var _thread_mat: StandardMaterial3D = null
var _thread_current_color: Color = THREAD_COLOR_0
var _thread_target_color: Color = THREAD_COLOR_0
var _thread_tremor_current: float = 1.0
var _thread_tremor_target: float = 1.0
var _thread_pulse_progress: float = -1.0  # < 0.0 means inactive; 0.0..1.0 traveling wave


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_init_sign_definitions()
	visible = false
	set_process(false)


## Initializes the 3 Comfort Sign shrines and the Parents' Thread of Pain anchored to the Earth Mirror.
func setup(mirror_pos: Vector3) -> void:
	_mirror_pos = mirror_pos
	if _sign_defs.is_empty():
		_init_sign_definitions()
	if not _is_built:
		_build_all_signs()
		_build_mirror_thread()
		_is_built = true
	_update_thread_targets()
	visible = _lesson1_active
	set_process(_lesson1_active)


## Activates or deactivates Lesson 1 3D signs and the Parents' Thread of Pain.
func set_lesson1_active(active: bool) -> void:
	_lesson1_active = active
	if active and not _is_built:
		setup(_mirror_pos)
	visible = _lesson1_active
	set_process(_lesson1_active)
	for def_dict: Dictionary in _sign_defs:
		var s_id: String = str(def_dict.get("id", ""))
		var refs: Dictionary = _sign_nodes.get(s_id, {}) as Dictionary
		var particles: GPUParticles3D = refs.get("particles", null) as GPUParticles3D
		if particles != null:
			var is_found: bool = bool(_collected_map.get(s_id, false))
			particles.emitting = _lesson1_active and not is_found


## Synchronizes collected sign states and sent count (e.g., on save load or lesson restart).
func sync_progress(found_ids: Array[String], sent_count: int) -> void:
	for def_dict: Dictionary in _sign_defs:
		var s_id: String = str(def_dict.get("id", ""))
		var is_found: bool = found_ids.has(s_id)
		_collected_map[s_id] = is_found
		_collect_blend[s_id] = 1.0 if is_found else 0.0
		_apply_sign_visual_state(s_id, is_found)
	set_sent_count(sent_count)
	_thread_current_color = _thread_target_color
	_thread_tremor_current = _thread_tremor_target


## Returns the localized HUD interaction prompt for the nearest uncollected Comfort Sign in range, or "".
func get_interaction_prompt(player_pos: Vector3) -> String:
	if not _lesson1_active:
		return ""
	var nearest_id: String = get_nearest_uncollected_sign_id(player_pos)
	if nearest_id.is_empty():
		return ""
	for def_dict: Dictionary in _sign_defs:
		if str(def_dict.get("id", "")) == nearest_id:
			return str(def_dict.get("prompt", ""))
	return ""


## Returns the sign_id of the nearest uncollected Comfort Sign within INTERACTION_RADIUS, or "".
func get_nearest_uncollected_sign_id(player_pos: Vector3) -> String:
	if not _lesson1_active:
		return ""
	var best_id: String = ""
	var best_dist: float = INTERACTION_RADIUS
	for def_dict: Dictionary in _sign_defs:
		var s_id: String = str(def_dict.get("id", ""))
		if bool(_collected_map.get(s_id, false)):
			continue
		var s_pos: Vector3 = def_dict.get("position", Vector3.ZERO) as Vector3
		var dist: float = player_pos.distance_to(s_pos + Vector3(0.0, 1.0, 0.0))
		if dist <= best_dist:
			best_dist = dist
			best_id = s_id
	return best_id


## Returns the world-space position of a Comfort Sign shrine by ID (or Vector3.ZERO if unknown).
func get_sign_world_position(sign_id: String) -> Vector3:
	for def_dict: Dictionary in _sign_defs:
		if str(def_dict.get("id", "")) == sign_id:
			return def_dict.get("position", Vector3.ZERO) as Vector3
	return Vector3.ZERO


## Marks a sign as collected, transitioning its shrine into a calm, serene luminous state.
func mark_sign_collected(sign_id: String) -> void:
	if sign_id.is_empty():
		return
	_collected_map[sign_id] = true
	_apply_sign_visual_state(sign_id, true)


## Updates the count of Comfort Signs sent through the Earth Mirror (0..3), warming the Thread of Pain.
func set_sent_count(count: int) -> void:
	_sent_count = clampi(count, 0, 3)
	_update_thread_targets()


## Plays a luminous golden traveling pulse wave along the Parents' Thread toward the Earth Mirror.
func pulse_mirror_thread() -> void:
	_thread_pulse_progress = 0.0


# ---------------------------------------------------------------------------
# Frame Animation
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _lesson1_active:
		return
	_anim_time += delta
	var blend_step: float = clampf(delta * 2.6, 0.0, 1.0)

	# 1. Animate each Comfort Sign shrine
	for i: int in range(_sign_defs.size()):
		var def_dict: Dictionary = _sign_defs[i]
		var s_id: String = str(def_dict.get("id", ""))
		var refs: Dictionary = _sign_nodes.get(s_id, {}) as Dictionary
		if refs.is_empty():
			continue

		var is_found: bool = bool(_collected_map.get(s_id, false))
		var cur_blend: float = float(_collect_blend.get(s_id, 0.0))
		var target_blend: float = 1.0 if is_found else 0.0
		cur_blend = lerpf(cur_blend, target_blend, blend_step)
		_collect_blend[s_id] = cur_blend

		var phase: float = float(i) * 2.094395
		var pivot: Node3D = refs.get("pivot", null) as Node3D
		if pivot != null:
			var hover_amp: float = lerpf(0.11, 0.035, cur_blend)
			var hover_speed: float = lerpf(1.75, 1.05, cur_blend)
			var base_y: float = lerpf(1.22, 1.06, cur_blend)
			pivot.position.y = base_y + sin(_anim_time * hover_speed + phase) * hover_amp
			var spin_speed: float = lerpf(0.42, 0.14, cur_blend)
			pivot.rotation.y += delta * spin_speed
			pivot.rotation.z = sin(_anim_time * 1.1 + phase) * lerpf(0.055, 0.015, cur_blend)

		var light_node: OmniLight3D = refs.get("light", null) as OmniLight3D
		if light_node != null:
			var base_energy: float = lerpf(1.65, 0.42, cur_blend)
			var pulse_amp: float = lerpf(0.24, 0.05, cur_blend)
			light_node.light_energy = base_energy + sin(_anim_time * 2.2 + phase) * pulse_amp
			light_node.omni_range = lerpf(8.5, 4.5, cur_blend)

		var halo_ring: MeshInstance3D = refs.get("halo_ring", null) as MeshInstance3D
		if halo_ring != null:
			halo_ring.rotation.y -= delta * lerpf(0.55, 0.18, cur_blend)

	# 2. Animate Parents' Thread of Pain
	_thread_current_color = _thread_current_color.lerp(_thread_target_color, clampf(delta * 2.0, 0.0, 1.0))
	_thread_tremor_current = lerpf(_thread_tremor_current, _thread_tremor_target, clampf(delta * 2.2, 0.0, 1.0))

	if _thread_pulse_progress >= 0.0:
		_thread_pulse_progress += delta * 0.72
		if _thread_pulse_progress > 1.35:
			_thread_pulse_progress = -1.0

	_rebuild_mirror_thread_mesh()


# ---------------------------------------------------------------------------
# Internal Setup & Builders
# ---------------------------------------------------------------------------

func _init_sign_definitions() -> void:
	_sign_defs = [
		{
			"id": SIGN_GARDEN,
			"title": "Эхо смеха в саду",
			"prompt": "✦  [E]  Коснуться Знака: Эхо смеха в саду",
			"position": POS_GARDEN,
			"model_path": MODEL_GARDEN_PATH,
			"light_color": Color("#B8E8FF"),
			"scale": 1.08,
		},
		{
			"id": SIGN_FOUNTAIN,
			"title": "Тёплая ладонь в темноте",
			"prompt": "✦  [E]  Коснуться Знака: Тёплая ладонь в темноте",
			"position": POS_FOUNTAIN,
			"model_path": MODEL_FOUNTAIN_PATH,
			"light_color": Color("#FFD286"),
			"scale": 1.08,
		},
		{
			"id": SIGN_BOAT,
			"title": "Белый кораблик памяти",
			"prompt": "✦  [E]  Коснуться Знака: Белый кораблик памяти",
			"position": POS_BOAT,
			"model_path": MODEL_BOAT_PATH,
			"light_color": Color("#FFF0C4"),
			"scale": 1.10,
		},
	]
	for def_dict: Dictionary in _sign_defs:
		var s_id: String = str(def_dict.get("id", ""))
		_collected_map[s_id] = false
		_collect_blend[s_id] = 0.0


func _build_all_signs() -> void:
	var gold_mat: StandardMaterial3D = StandardMaterial3D.new()
	gold_mat.albedo_color = Color("#E6C47A")
	gold_mat.metallic = 0.85
	gold_mat.roughness = 0.28
	gold_mat.emission_enabled = true
	gold_mat.emission = Color("#FFD988")
	gold_mat.emission_energy_multiplier = 0.25

	var marble_mat: StandardMaterial3D = StandardMaterial3D.new()
	marble_mat.albedo_color = Color("#F5F2EC")
	marble_mat.roughness = 0.34
	marble_mat.metallic = 0.04

	var mote_tex: GradientTexture2D = _create_radial_mote_texture()

	for def_dict: Dictionary in _sign_defs:
		var s_id: String = str(def_dict.get("id", ""))
		var world_pos: Vector3 = def_dict.get("position", Vector3.ZERO) as Vector3
		var model_path: String = str(def_dict.get("model_path", ""))
		var light_col: Color = def_dict.get("light_color", Color("#FFE0A0")) as Color
		var model_scale: float = float(def_dict.get("scale", 1.0))

		var shrine_root: Node3D = Node3D.new()
		shrine_root.name = "ComfortSign_%s" % s_id
		shrine_root.position = world_pos
		shrine_root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(shrine_root)

		# Subtle low marble & gold floor medallion anchoring the floating sign (seated -0.02m to prevent Z-fighting)
		var base_cyl: CylinderMesh = CylinderMesh.new()
		base_cyl.top_radius = 0.72
		base_cyl.bottom_radius = 0.84
		base_cyl.height = 0.12
		base_cyl.radial_segments = 24
		var base_mesh: MeshInstance3D = MeshInstance3D.new()
		base_mesh.name = "ShrineMedallion"
		base_mesh.mesh = base_cyl
		base_mesh.material_override = marble_mat
		base_mesh.position = Vector3(0.0, 0.04, 0.0)
		shrine_root.add_child(base_mesh)

		var ring_torus: TorusMesh = TorusMesh.new()
		ring_torus.inner_radius = 0.68
		ring_torus.outer_radius = 0.76
		ring_torus.rings = 32
		ring_torus.ring_segments = 10
		var halo_ring: MeshInstance3D = MeshInstance3D.new()
		halo_ring.name = "ShrineGoldRing"
		halo_ring.mesh = ring_torus
		halo_ring.material_override = gold_mat
		halo_ring.position = Vector3(0.0, 0.11, 0.0)
		halo_ring.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		shrine_root.add_child(halo_ring)

		# Floating animated pivot holding the sculpted baroque GLB
		var pivot: Node3D = Node3D.new()
		pivot.name = "FloatingSignPivot"
		pivot.position = Vector3(0.0, 1.22, 0.0)
		pivot.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		shrine_root.add_child(pivot)

		var loaded_model: Node3D = _load_sign_model(model_path, light_col, gold_mat)
		loaded_model.scale = Vector3.ONE * model_scale
		# Center model vertically around pivot (GLB base is at Y=0, height ~1.0m)
		loaded_model.position = Vector3(0.0, -0.48 * model_scale, 0.0)
		pivot.add_child(loaded_model)

		# Local shadowless OmniLight3D (60 FPS friendly)
		var sign_light: OmniLight3D = OmniLight3D.new()
		sign_light.name = "SignAuraLight"
		sign_light.position = Vector3(0.0, 1.45, 0.0)
		sign_light.light_color = light_col
		sign_light.light_energy = 1.65
		sign_light.omni_range = 8.5
		sign_light.omni_attenuation = 1.45
		sign_light.shadow_enabled = false
		shrine_root.add_child(sign_light)

		# Delicate rising golden motes (active only while uncollected)
		var proc_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
		proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		proc_mat.emission_sphere_radius = 0.65
		proc_mat.direction = Vector3(0.0, 1.0, 0.0)
		proc_mat.spread = 22.0
		proc_mat.initial_velocity_min = 0.25
		proc_mat.initial_velocity_max = 0.65
		proc_mat.gravity = Vector3(0.0, 0.18, 0.0)
		proc_mat.scale_min = 0.45
		proc_mat.scale_max = 1.15
		proc_mat.color = Color("#FFE294")

		var mote_mat: StandardMaterial3D = StandardMaterial3D.new()
		mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mote_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mote_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mote_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		mote_mat.albedo_texture = mote_tex
		mote_mat.albedo_color = Color("#FFE8A6")
		mote_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

		var mote_quad: QuadMesh = QuadMesh.new()
		mote_quad.size = Vector2(0.11, 0.11)
		mote_quad.material = mote_mat

		var particles: GPUParticles3D = GPUParticles3D.new()
		particles.name = "GoldenRisingMotes"
		particles.position = Vector3(0.0, 1.10, 0.0)
		particles.amount = 28
		particles.lifetime = 2.8
		particles.preprocess = 1.2
		particles.emitting = false
		particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		particles.process_material = proc_mat
		particles.draw_pass_1 = mote_quad
		shrine_root.add_child(particles)

		_sign_nodes[s_id] = {
			"root": shrine_root,
			"pivot": pivot,
			"halo_ring": halo_ring,
			"light": sign_light,
			"particles": particles,
		}


func _load_sign_model(model_path: String, fallback_color: Color, gold_mat: StandardMaterial3D) -> Node3D:
	if ResourceLoader.exists(model_path):
		var packed: PackedScene = load(model_path) as PackedScene
		if packed != null:
			var inst: Node = packed.instantiate()
			if inst is Node3D:
				return inst as Node3D
			inst.queue_free()

	# Clean procedural fallback if GLB is unavailable
	var fallback_root: Node3D = Node3D.new()
	fallback_root.name = "FallbackSignModel"
	var orb_mesh: SphereMesh = SphereMesh.new()
	orb_mesh.radius = 0.28
	orb_mesh.height = 0.56
	var orb_mat: StandardMaterial3D = StandardMaterial3D.new()
	orb_mat.albedo_color = fallback_color
	orb_mat.roughness = 0.14
	orb_mat.emission_enabled = true
	orb_mat.emission = fallback_color
	orb_mat.emission_energy_multiplier = 0.85
	var orb: MeshInstance3D = MeshInstance3D.new()
	orb.mesh = orb_mesh
	orb.material_override = orb_mat
	orb.position = Vector3(0.0, 0.5, 0.0)
	fallback_root.add_child(orb)

	var ring_mesh: TorusMesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.34
	ring_mesh.outer_radius = 0.39
	var ring: MeshInstance3D = MeshInstance3D.new()
	ring.mesh = ring_mesh
	ring.material_override = gold_mat
	ring.position = Vector3(0.0, 0.5, 0.0)
	ring.rotation_degrees.x = 90.0
	fallback_root.add_child(ring)
	return fallback_root


func _apply_sign_visual_state(sign_id: String, is_collected: bool) -> void:
	var refs: Dictionary = _sign_nodes.get(sign_id, {}) as Dictionary
	if refs.is_empty():
		return
	var particles: GPUParticles3D = refs.get("particles", null) as GPUParticles3D
	if particles != null:
		particles.emitting = _lesson1_active and not is_collected


# ---------------------------------------------------------------------------
# Parents' Thread of Pain (Нить боли родителей)
# ---------------------------------------------------------------------------

func _build_mirror_thread() -> void:
	_thread_root = Node3D.new()
	_thread_root.name = "ParentsThreadOfPain"
	_thread_root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_thread_root)

	_thread_mat = StandardMaterial3D.new()
	_thread_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_thread_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_thread_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_thread_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_thread_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_thread_mat.vertex_color_use_as_albedo = true
	_thread_mat.albedo_color = Color.WHITE

	_thread_imm_mesh = ImmediateMesh.new()
	_thread_mesh_inst = MeshInstance3D.new()
	_thread_mesh_inst.name = "ThreadRibbonMesh"
	_thread_mesh_inst.mesh = _thread_imm_mesh
	_thread_mesh_inst.material_override = _thread_mat
	_thread_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_thread_mesh_inst.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_thread_root.add_child(_thread_mesh_inst)


func _update_thread_targets() -> void:
	if _sent_count <= 0:
		_thread_target_color = THREAD_COLOR_0
		_thread_tremor_target = 1.0
	elif _sent_count == 1:
		_thread_target_color = THREAD_COLOR_1
		_thread_tremor_target = 0.58
	elif _sent_count == 2:
		_thread_target_color = THREAD_COLOR_2
		_thread_tremor_target = 0.25
	else:
		_thread_target_color = THREAD_COLOR_3
		_thread_tremor_target = 0.04


func _rebuild_mirror_thread_mesh() -> void:
	if _thread_imm_mesh == null:
		return
	_thread_imm_mesh.clear_surfaces()

	var start_pos: Vector3 = _mirror_pos + Vector3(0.0, MIRROR_CENTER_HEIGHT, 0.35)
	var ctrl_a: Vector3 = _mirror_pos + Vector3(1.8, MIRROR_CENTER_HEIGHT - 0.8, 3.6)
	var ctrl_b: Vector3 = _mirror_pos + Vector3(-1.4, 2.5, 6.8)
	var end_pos: Vector3 = _mirror_pos + Vector3(0.0, 1.55, 9.6)

	var cam: Camera3D = get_viewport().get_camera_3d()
	var cam_pos: Vector3 = cam.global_position if cam != null else (_mirror_pos + Vector3(0.0, 5.0, 16.0))

	# Draw primary luminous ribbon + thinner intertwined companion filament
	_append_thread_strand(start_pos, ctrl_a, ctrl_b, end_pos, cam_pos, 0.085, 0.0, 1.0)
	_append_thread_strand(start_pos, ctrl_a, ctrl_b, end_pos, cam_pos, 0.042, 2.2, 0.65)


func _append_thread_strand(
	p0: Vector3,
	p1: Vector3,
	p2: Vector3,
	p3: Vector3,
	cam_pos: Vector3,
	base_width: float,
	phase_offset: float,
	alpha_scale: float
) -> void:
	var pts: Array[Vector3] = []
	pts.resize(THREAD_SEGMENTS + 1)

	for i: int in range(THREAD_SEGMENTS + 1):
		var t: float = float(i) / float(THREAD_SEGMENTS)
		var omt: float = 1.0 - t
		var bez: Vector3 = (
			p0 * (omt * omt * omt)
			+ p1 * (3.0 * omt * omt * t)
			+ p2 * (3.0 * omt * t * t)
			+ p3 * (t * t * t)
		)

		# Gentle helical spiral & emotion-driven tremor (anxious at 0 -> calm & steady at 3)
		var env: float = sin(t * PI)
		var spiral_ang: float = t * TAU * 2.2 - _anim_time * 1.15 + phase_offset
		var spiral_r: float = (0.14 + 0.08 * _thread_tremor_current) * env
		var tremor_x: float = sin(_anim_time * 9.5 + t * 24.0 + phase_offset) * 0.055 * _thread_tremor_current * env
		var tremor_y: float = cos(_anim_time * 8.2 + t * 19.0 + phase_offset) * 0.045 * _thread_tremor_current * env

		bez.x += cos(spiral_ang) * spiral_r + tremor_x
		bez.y += sin(spiral_ang) * spiral_r * 0.72 + tremor_y
		pts[i] = bez

	_thread_imm_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i: int in range(THREAD_SEGMENTS + 1):
		var t: float = float(i) / float(THREAD_SEGMENTS)
		var pos: Vector3 = pts[i]
		var tangent: Vector3
		if i == 0:
			tangent = pts[1] - pos
		elif i == THREAD_SEGMENTS:
			tangent = pos - pts[i - 1]
		else:
			tangent = pts[i + 1] - pts[i - 1]
		if tangent.length_squared() < 0.00001:
			tangent = Vector3.FORWARD
		else:
			tangent = tangent.normalized()

		var to_cam: Vector3 = cam_pos - pos
		if to_cam.length_squared() < 0.00001:
			to_cam = Vector3.BACK
		else:
			to_cam = to_cam.normalized()

		var side: Vector3 = tangent.cross(to_cam)
		if side.length_squared() < 0.0001:
			side = Vector3.RIGHT
		else:
			side = side.normalized()

		# Traveling golden wave pulse from hall (t=1) into the Earth Mirror (t=0)
		var pulse_boost: float = 0.0
		if _thread_pulse_progress >= 0.0:
			var wave_pos: float = 1.0 - _thread_pulse_progress
			var dist_wave: float = absf(t - wave_pos)
			pulse_boost = maxf(0.0, 1.0 - dist_wave / 0.22)
			pulse_boost = pulse_boost * pulse_boost

		var taper: float = smoothstep(0.0, 0.14, t) * smoothstep(1.0, 0.78, t)
		var half_w: float = base_width * (0.45 + 0.55 * taper + pulse_boost * 0.95)

		var col_base: Color = _thread_current_color.lerp(Color("#FFF2B8"), pulse_boost * 0.85)
		var brightness: float = 1.15 + pulse_boost * 1.45
		var vert_col: Color = Color(
			col_base.r * brightness,
			col_base.g * brightness,
			col_base.b * brightness,
			clampf(taper * alpha_scale * (0.78 + pulse_boost * 0.22), 0.0, 1.0)
		)

		_thread_imm_mesh.surface_set_color(vert_col)
		_thread_imm_mesh.surface_add_vertex(pos + side * half_w)
		_thread_imm_mesh.surface_set_color(vert_col)
		_thread_imm_mesh.surface_add_vertex(pos - side * half_w)

	_thread_imm_mesh.surface_end()


func _create_radial_mote_texture() -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.38, 0.78, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.65),
		Color(1.0, 1.0, 1.0, 0.16),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.width = 48
	tex.height = 48
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.gradient = grad
	return tex
