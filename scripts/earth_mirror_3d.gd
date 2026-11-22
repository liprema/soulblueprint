extends Node3D
class_name EarthMirror3D

## Art Deco Celestial Earth Mirror Portal for the Cathedral of the Astrolabe upper dais.
## Transitions from a velvety dormant indigo pool to a luminous swirling dawn portal
## when resonated by Spark's Soul Call.

enum MirrorState {
	DORMANT,
	READY_FOR_CALL,
	AWAKENED,
}

signal mirror_awakened
signal player_entered_portal

const MIRROR_SHADER_PATH: String = "res://shaders/earth_mirror.gdshader"
const MARBLE_SHADER_PATH: String = "res://shaders/akasha_marble.gdshader"

const MIRROR_CENTER_Y: float = 4.6
const CALL_RESPONSE_RADIUS: float = 28.0
const CALL_ZONE_RADIUS: float = 22.0
const PORTAL_HORIZONTAL_RADIUS: float = 4.2
const PORTAL_Y_OFFSET: float = 3.5
const PORTAL_Y_HALF_HEIGHT: float = 5.5

const LIGHT_ENERGY_DORMANT: float = 0.6
const LIGHT_ENERGY_READY: float = 2.2
const LIGHT_ENERGY_AWAKENED: float = 4.2

const COLOR_DORMANT_LIGHT: Color = Color(0.55, 0.72, 0.96, 1.0)
const COLOR_READY_LIGHT: Color = Color(0.92, 0.80, 0.48, 1.0)
const COLOR_AWAKENED_LIGHT: Color = Color(0.68, 0.88, 0.98, 1.0)

const COLOR_INDIGO_STONE: Color = Color("#122D6B")
const COLOR_SATIN_GOLD: Color = Color("#EBC86A")
const COLOR_BRIGHT_GOLD: Color = Color("#F6D36B")
const COLOR_ETHEREAL_CYAN: Color = Color("#58C4FF")

var state: MirrorState = MirrorState.DORMANT

var _mirror_shader_mat: ShaderMaterial = null
var _gold_frame_mat: StandardMaterial3D = null
var _filigree_ring_mat: StandardMaterial3D = null
var _finial_accent_mat: StandardMaterial3D = null
var _mirror_light: OmniLight3D = null
var _starlight_particles: GPUParticles3D = null
var _particle_process_mat: ParticleProcessMaterial = null
var _filigree_pivot: Node3D = null
var _portal_area: Area3D = null

var _state_tween: Tween = null
var _pulse_tween: Tween = null
var _anim_time: float = 0.0
var _base_light_energy: float = LIGHT_ENERGY_DORMANT
var _awakened_amount: float = 0.0
var _pulse_boost: float = 0.0
var _portal_entered_emitted: bool = false


func _ready() -> void:
	add_to_group("earth_mirror")
	_init_materials()
	_build_pedestal()
	_build_arch_frame()
	_build_mirror_disc()
	_build_lighting_and_particles()
	_build_portal_trigger()
	_apply_dormant_immediate()


func _process(delta: float) -> void:
	_anim_time += delta

	# Gentle rotation of the delicate inner filigree ring
	if _filigree_pivot != null:
		var rot_speed: float = 0.08
		if state == MirrorState.READY_FOR_CALL:
			rot_speed = 0.22
		elif state == MirrorState.AWAKENED:
			rot_speed = 0.48
		_filigree_pivot.rotation.z += delta * rot_speed

	# Subtle poetic light breathing (never harsh or blinding)
	if _mirror_light != null and (_state_tween == null or not _state_tween.is_valid()):
		var breath_amp: float = 0.08
		if state == MirrorState.READY_FOR_CALL:
			breath_amp = 0.18
		elif state == MirrorState.AWAKENED:
			breath_amp = 0.28
		var pulse_extra: float = _pulse_boost * 1.1
		_mirror_light.light_energy = _base_light_energy + sin(_anim_time * 1.85) * breath_amp + pulse_extra


## Resets the mirror immediately back to DORMANT state (used when starting a new game).
func reset_to_dormant() -> void:
	if _state_tween != null and _state_tween.is_valid():
		_state_tween.kill()
	state = MirrorState.DORMANT
	_portal_entered_emitted = false
	_apply_dormant_immediate()


## Re-arms the portal trigger after returning from the epilogue to free exploration.
func reset_portal_trigger() -> void:
	_portal_entered_emitted = false


## Transitions DORMANT -> READY_FOR_CALL and gently illuminates the golden rings.
func set_ready_for_call() -> void:
	if state != MirrorState.DORMANT:
		return

	state = MirrorState.READY_FOR_CALL
	_base_light_energy = LIGHT_ENERGY_READY

	if _state_tween != null and _state_tween.is_valid():
		_state_tween.kill()

	_state_tween = create_tween()
	_state_tween.set_parallel(true)

	if _mirror_light != null:
		_state_tween.tween_property(
			_mirror_light, "light_energy", LIGHT_ENERGY_READY, 1.35
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_state_tween.tween_property(
			_mirror_light, "omni_range", 20.0, 1.35
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_state_tween.tween_property(
			_mirror_light, "light_color", COLOR_READY_LIGHT, 1.35
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if _filigree_ring_mat != null:
		_state_tween.tween_property(
			_filigree_ring_mat, "emission_energy_multiplier", 1.15, 1.35
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if _finial_accent_mat != null:
		_state_tween.tween_property(
			_finial_accent_mat, "emission_energy_multiplier", 1.45, 1.35
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if _gold_frame_mat != null:
		_state_tween.tween_property(
			_gold_frame_mat, "emission_energy_multiplier", 0.62, 1.35
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if _starlight_particles != null:
		_starlight_particles.amount_ratio = 0.55

	_trigger_soft_pulse(0.45, 1.1)


## Transitions the Earth Mirror to AWAKENED with a luminous swirling dawn portal.
func awaken_mirror() -> void:
	if state == MirrorState.AWAKENED:
		_trigger_soft_pulse(0.65, 0.95)
		return

	state = MirrorState.AWAKENED
	_base_light_energy = LIGHT_ENERGY_AWAKENED
	_portal_entered_emitted = false

	if _state_tween != null and _state_tween.is_valid():
		_state_tween.kill()

	_state_tween = create_tween()
	_state_tween.set_parallel(true)

	_state_tween.tween_method(
		_set_awakened_amount, _awakened_amount, 1.0, 1.85
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if _mirror_light != null:
		_state_tween.tween_property(
			_mirror_light, "light_energy", LIGHT_ENERGY_AWAKENED, 1.85
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_state_tween.tween_property(
			_mirror_light, "omni_range", 28.0, 1.85
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_state_tween.tween_property(
			_mirror_light, "light_color", COLOR_AWAKENED_LIGHT, 1.85
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if _filigree_ring_mat != null:
		_state_tween.tween_property(
			_filigree_ring_mat, "emission_energy_multiplier", 1.85, 1.6
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if _finial_accent_mat != null:
		_state_tween.tween_property(
			_finial_accent_mat, "emission_energy_multiplier", 2.1, 1.6
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if _gold_frame_mat != null:
		_state_tween.tween_property(
			_gold_frame_mat, "emission_energy_multiplier", 0.85, 1.6
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if _starlight_particles != null:
		_starlight_particles.emitting = true
		_starlight_particles.amount_ratio = 1.0
	if _particle_process_mat != null:
		_particle_process_mat.initial_velocity_min = 0.95
		_particle_process_mat.initial_velocity_max = 2.25

	_trigger_soft_pulse(0.9, 1.4)
	mirror_awakened.emit()


## Responds to a player Soul Call from `origin`.
## Awakens the mirror if READY_FOR_CALL and within 28.0m; otherwise emits a soft pulse.
func respond_to_soul_call(origin: Vector3) -> bool:
	var dist: float = origin.distance_to(global_position)
	if state == MirrorState.READY_FOR_CALL and dist <= CALL_RESPONSE_RADIUS:
		awaken_mirror()
		return true

	if dist <= CALL_RESPONSE_RADIUS * 1.4:
		_trigger_soft_pulse(0.45, 0.85)
	return false


## Returns true if the player is within the Soul Call resonance zone (<= 22.0m).
func is_player_near_call_zone(player_pos: Vector3) -> bool:
	var dist: float = player_pos.distance_to(global_position)
	return dist <= CALL_ZONE_RADIUS


## Returns true if the mirror is AWAKENED and the player has entered the portal volume.
func is_player_in_portal_zone(player_pos: Vector3) -> bool:
	if state != MirrorState.AWAKENED:
		return false
	var dx: float = player_pos.x - global_position.x
	var dz: float = player_pos.z - global_position.z
	var horizontal_dist: float = sqrt(dx * dx + dz * dz)
	var vertical_delta: float = absf(player_pos.y - (global_position.y + PORTAL_Y_OFFSET))
	return horizontal_dist <= PORTAL_HORIZONTAL_RADIUS and vertical_delta < PORTAL_Y_HALF_HEIGHT


func _set_awakened_amount(value: float) -> void:
	_awakened_amount = clampf(value, 0.0, 1.0)
	if _mirror_shader_mat != null:
		_mirror_shader_mat.set_shader_parameter("awakened_amount", _awakened_amount)


func _set_pulse_boost(value: float) -> void:
	_pulse_boost = clampf(value, 0.0, 1.0)
	if _mirror_shader_mat != null:
		_mirror_shader_mat.set_shader_parameter("pulse_boost", _pulse_boost)


func _trigger_soft_pulse(peak: float, duration: float) -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()

	var clamped_peak: float = clampf(peak, 0.0, 1.0)
	_pulse_tween = create_tween()
	_pulse_tween.tween_method(
		_set_pulse_boost, _pulse_boost, clamped_peak, duration * 0.28
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_method(
		_set_pulse_boost, clamped_peak, 0.0, duration * 0.72
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _apply_dormant_immediate() -> void:
	state = MirrorState.DORMANT
	_base_light_energy = LIGHT_ENERGY_DORMANT
	_set_awakened_amount(0.0)
	_set_pulse_boost(0.0)

	if _mirror_light != null:
		_mirror_light.light_energy = LIGHT_ENERGY_DORMANT
		_mirror_light.omni_range = 14.0
		_mirror_light.light_color = COLOR_DORMANT_LIGHT
	if _gold_frame_mat != null:
		_gold_frame_mat.emission_energy_multiplier = 0.36
	if _filigree_ring_mat != null:
		_filigree_ring_mat.emission_energy_multiplier = 0.42
	if _finial_accent_mat != null:
		_finial_accent_mat.emission_energy_multiplier = 0.55
	if _starlight_particles != null:
		_starlight_particles.emitting = true
		_starlight_particles.amount_ratio = 0.25


func _init_materials() -> void:
	_gold_frame_mat = StandardMaterial3D.new()
	_gold_frame_mat.albedo_color = COLOR_SATIN_GOLD
	_gold_frame_mat.roughness = 0.34
	_gold_frame_mat.metallic = 0.86
	_gold_frame_mat.emission_enabled = true
	_gold_frame_mat.emission = COLOR_SATIN_GOLD
	_gold_frame_mat.emission_energy_multiplier = 0.36

	_filigree_ring_mat = StandardMaterial3D.new()
	_filigree_ring_mat.albedo_color = COLOR_BRIGHT_GOLD
	_filigree_ring_mat.roughness = 0.28
	_filigree_ring_mat.metallic = 0.78
	_filigree_ring_mat.emission_enabled = true
	_filigree_ring_mat.emission = COLOR_BRIGHT_GOLD
	_filigree_ring_mat.emission_energy_multiplier = 0.42

	_finial_accent_mat = StandardMaterial3D.new()
	_finial_accent_mat.albedo_color = Color("#FFF4CF")
	_finial_accent_mat.roughness = 0.22
	_finial_accent_mat.metallic = 0.45
	_finial_accent_mat.emission_enabled = true
	_finial_accent_mat.emission = COLOR_BRIGHT_GOLD
	_finial_accent_mat.emission_energy_multiplier = 0.55

	_mirror_shader_mat = ShaderMaterial.new()
	if ResourceLoader.exists(MIRROR_SHADER_PATH):
		var loaded_shader: Shader = load(MIRROR_SHADER_PATH) as Shader
		if loaded_shader != null:
			_mirror_shader_mat.shader = loaded_shader
	_mirror_shader_mat.set_shader_parameter("dormant_color", Color(0.05, 0.12, 0.28, 1.0))
	_mirror_shader_mat.set_shader_parameter("awakened_color", Color(0.32, 0.72, 0.98, 1.0))
	_mirror_shader_mat.set_shader_parameter("gold_rim_color", Color(0.95, 0.80, 0.42, 1.0))
	_mirror_shader_mat.set_shader_parameter("awakened_amount", 0.0)
	_mirror_shader_mat.set_shader_parameter("pulse_boost", 0.0)


func _create_pedestal_stone_material() -> Material:
	if ResourceLoader.exists(MARBLE_SHADER_PATH):
		var marble_shader: Shader = load(MARBLE_SHADER_PATH) as Shader
		if marble_shader != null:
			var shader_mat: ShaderMaterial = ShaderMaterial.new()
			shader_mat.shader = marble_shader
			shader_mat.set_shader_parameter("stone_base_color", COLOR_INDIGO_STONE)
			shader_mat.set_shader_parameter("stone_highlight_color", Color("#1C3D82"))
			shader_mat.set_shader_parameter("stone_pore_color", Color("#0C1E4A"))
			shader_mat.set_shader_parameter("base_roughness", 0.82)
			shader_mat.set_shader_parameter("surface_specular", 0.16)
			shader_mat.set_shader_parameter("surface_metallic", 0.02)
			shader_mat.set_shader_parameter("fresnel_lift_strength", 0.12)
			return shader_mat

	var fallback: StandardMaterial3D = StandardMaterial3D.new()
	fallback.albedo_color = COLOR_INDIGO_STONE
	fallback.roughness = 0.82
	fallback.metallic = 0.04
	return fallback


func _build_pedestal() -> void:
	var pedestal_root: Node3D = Node3D.new()
	pedestal_root.name = "MirrorPedestal"
	add_child(pedestal_root)

	var stone_mat: Material = _create_pedestal_stone_material()

	# Low octagonal velvety-indigo stone pedestal (radius = 4.6, height = 0.45)
	var base_mesh: CylinderMesh = CylinderMesh.new()
	base_mesh.top_radius = 4.46
	base_mesh.bottom_radius = 4.6
	base_mesh.height = 0.45
	base_mesh.radial_segments = 8
	base_mesh.rings = 1

	var base_inst: MeshInstance3D = MeshInstance3D.new()
	base_inst.name = "OctagonalBase"
	base_inst.mesh = base_mesh
	base_inst.material_override = stone_mat
	base_inst.position = Vector3(0.0, 0.225, 0.0)
	base_inst.rotation_degrees.y = 22.5
	pedestal_root.add_child(base_inst)

	# Satin gold trim ring crowning the pedestal rim
	var trim_torus: TorusMesh = TorusMesh.new()
	trim_torus.inner_radius = 4.38
	trim_torus.outer_radius = 4.54
	trim_torus.rings = 8
	trim_torus.ring_segments = 12

	var trim_inst: MeshInstance3D = MeshInstance3D.new()
	trim_inst.name = "PedestalGoldTrim"
	trim_inst.mesh = trim_torus
	trim_inst.material_override = _gold_frame_mat
	trim_inst.position = Vector3(0.0, 0.43, 0.0)
	trim_inst.rotation_degrees.y = 22.5
	pedestal_root.add_child(trim_inst)

	# Subtle recessed golden inlay ring on pedestal top
	var inner_inlay: TorusMesh = TorusMesh.new()
	inner_inlay.inner_radius = 3.28
	inner_inlay.outer_radius = 3.38
	inner_inlay.rings = 32
	inner_inlay.ring_segments = 10

	var inlay_inst: MeshInstance3D = MeshInstance3D.new()
	inlay_inst.name = "PedestalInnerInlay"
	inlay_inst.mesh = inner_inlay
	inlay_inst.material_override = _filigree_ring_mat
	inlay_inst.position = Vector3(0.0, 0.455, 0.0)
	pedestal_root.add_child(inlay_inst)


func _build_arch_frame() -> void:
	var frame_root: Node3D = Node3D.new()
	frame_root.name = "MirrorArchFrame"
	frame_root.position = Vector3(0.0, MIRROR_CENTER_Y, 0.0)
	add_child(frame_root)

	# Main freestanding Art Deco golden torus arch (radius = 4.2, centered at y = 4.6)
	var main_torus: TorusMesh = TorusMesh.new()
	main_torus.inner_radius = 4.02
	main_torus.outer_radius = 4.38
	main_torus.rings = 56
	main_torus.ring_segments = 20

	var main_ring: MeshInstance3D = MeshInstance3D.new()
	main_ring.name = "MainGoldenArch"
	main_ring.mesh = main_torus
	main_ring.material_override = _gold_frame_mat
	main_ring.rotation_degrees.x = 90.0
	frame_root.add_child(main_ring)

	# Outer stepped Art Deco bezel ring
	var outer_bezel: TorusMesh = TorusMesh.new()
	outer_bezel.inner_radius = 4.44
	outer_bezel.outer_radius = 4.54
	outer_bezel.rings = 56
	outer_bezel.ring_segments = 12

	var bezel_inst: MeshInstance3D = MeshInstance3D.new()
	bezel_inst.name = "OuterArtDecoBezel"
	bezel_inst.mesh = outer_bezel
	bezel_inst.material_override = _gold_frame_mat
	bezel_inst.rotation_degrees.x = 90.0
	frame_root.add_child(bezel_inst)

	# Grounding Art Deco cradle piers connecting lower frame cleanly to pedestal
	for side_val: float in [-1.0, 1.0]:
		var pier_mesh: BoxMesh = BoxMesh.new()
		pier_mesh.size = Vector3(0.55, 1.65, 0.72)

		var pier_inst: MeshInstance3D = MeshInstance3D.new()
		pier_inst.name = "FramePier_%s" % ("L" if side_val < 0.0 else "R")
		pier_inst.mesh = pier_mesh
		pier_inst.material_override = _gold_frame_mat
		pier_inst.position = Vector3(side_val * 2.55, -3.55, 0.0)
		pier_inst.rotation_degrees.z = side_val * -26.0
		frame_root.add_child(pier_inst)

	# Delicate rotating inner filigree ring with 8 celestial spokes
	_filigree_pivot = Node3D.new()
	_filigree_pivot.name = "InnerFiligreePivot"
	frame_root.add_child(_filigree_pivot)

	var filigree_torus: TorusMesh = TorusMesh.new()
	filigree_torus.inner_radius = 3.85
	filigree_torus.outer_radius = 3.94
	filigree_torus.rings = 48
	filigree_torus.ring_segments = 12

	var filigree_inst: MeshInstance3D = MeshInstance3D.new()
	filigree_inst.name = "InnerFiligreeRing"
	filigree_inst.mesh = filigree_torus
	filigree_inst.material_override = _filigree_ring_mat
	filigree_inst.rotation_degrees.x = 90.0
	_filigree_pivot.add_child(filigree_inst)

	var spoke_mesh: BoxMesh = BoxMesh.new()
	spoke_mesh.size = Vector3(0.065, 0.24, 0.065)
	for i: int in range(8):
		var angle_rad: float = float(i) * (TAU / 8.0)
		var spoke: MeshInstance3D = MeshInstance3D.new()
		spoke.name = "FiligreeSpoke_%d" % i
		spoke.mesh = spoke_mesh
		spoke.material_override = _filigree_ring_mat
		spoke.position = Vector3(cos(angle_rad) * 3.98, sin(angle_rad) * 3.98, 0.0)
		spoke.rotation.z = angle_rad - PI * 0.5
		_filigree_pivot.add_child(spoke)

	# 4 Compass Star Finials (North, East, South, West)
	var compass_angles: Array[float] = [PI * 0.5, 0.0, -PI * 0.5, PI]
	var compass_names: Array[String] = ["North", "East", "South", "West"]
	for idx: int in range(4):
		var a: float = compass_angles[idx]
		var radial_dist: float = 4.62
		if idx == 2:
			# Tuck South finial neatly above the pedestal rim
			radial_dist = 4.18
		var finial_pos: Vector3 = Vector3(cos(a) * radial_dist, sin(a) * radial_dist, 0.0)
		_add_compass_star_finial(frame_root, "CompassFinial_%s" % compass_names[idx], finial_pos, a)


func _add_compass_star_finial(parent: Node3D, node_name: String, local_pos: Vector3, angle_rad: float) -> void:
	var finial_root: Node3D = Node3D.new()
	finial_root.name = node_name
	finial_root.position = local_pos
	finial_root.rotation.z = angle_rad - PI * 0.5
	parent.add_child(finial_root)

	# Primary tall diamond ray pointing outward
	var outer_spike_mesh: CylinderMesh = CylinderMesh.new()
	outer_spike_mesh.top_radius = 0.01
	outer_spike_mesh.bottom_radius = 0.16
	outer_spike_mesh.height = 0.92
	outer_spike_mesh.radial_segments = 4

	var outer_spike: MeshInstance3D = MeshInstance3D.new()
	outer_spike.name = "OuterSpike"
	outer_spike.mesh = outer_spike_mesh
	outer_spike.material_override = _gold_frame_mat
	outer_spike.position = Vector3(0.0, 0.42, 0.0)
	finial_root.add_child(outer_spike)

	# Counter-spike pointing inward
	var inner_spike_mesh: CylinderMesh = CylinderMesh.new()
	inner_spike_mesh.top_radius = 0.14
	inner_spike_mesh.bottom_radius = 0.01
	inner_spike_mesh.height = 0.44
	inner_spike_mesh.radial_segments = 4

	var inner_spike: MeshInstance3D = MeshInstance3D.new()
	inner_spike.name = "InnerSpike"
	inner_spike.mesh = inner_spike_mesh
	inner_spike.material_override = _gold_frame_mat
	inner_spike.position = Vector3(0.0, -0.22, 0.0)
	finial_root.add_child(inner_spike)

	# Cross-star lateral rays
	var side_ray_mesh: BoxMesh = BoxMesh.new()
	side_ray_mesh.size = Vector3(0.66, 0.09, 0.09)

	var side_ray: MeshInstance3D = MeshInstance3D.new()
	side_ray.name = "CrossRay"
	side_ray.mesh = side_ray_mesh
	side_ray.material_override = _filigree_ring_mat
	side_ray.position = Vector3(0.0, 0.0, 0.0)
	finial_root.add_child(side_ray)

	# Luminous compass star gem center
	var gem_mesh: SphereMesh = SphereMesh.new()
	gem_mesh.radius = 0.14
	gem_mesh.height = 0.28
	gem_mesh.radial_segments = 12
	gem_mesh.rings = 8

	var gem_inst: MeshInstance3D = MeshInstance3D.new()
	gem_inst.name = "StarGem"
	gem_inst.mesh = gem_mesh
	gem_inst.material_override = _finial_accent_mat
	finial_root.add_child(gem_inst)


func _build_mirror_disc() -> void:
	# Circular mirror surface using PlaneMesh (radius = 3.85 -> 7.7 x 7.7) rotated vertically
	var disc_mesh: PlaneMesh = PlaneMesh.new()
	disc_mesh.size = Vector2(7.7, 7.7)
	disc_mesh.subdivide_width = 1
	disc_mesh.subdivide_depth = 1

	var disc_inst: MeshInstance3D = MeshInstance3D.new()
	disc_inst.name = "MirrorSurfaceDisc"
	disc_inst.mesh = disc_mesh
	disc_inst.material_override = _mirror_shader_mat
	disc_inst.position = Vector3(0.0, MIRROR_CENTER_Y, 0.0)
	disc_inst.rotation_degrees.x = 90.0
	disc_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc_inst)


func _build_lighting_and_particles() -> void:
	# Soft OmniLight3D positioned slightly in front of the mirror face
	_mirror_light = OmniLight3D.new()
	_mirror_light.name = "MirrorAuraLight"
	_mirror_light.position = Vector3(0.0, MIRROR_CENTER_Y, 1.2)
	_mirror_light.light_color = COLOR_DORMANT_LIGHT
	_mirror_light.light_energy = LIGHT_ENERGY_DORMANT
	_mirror_light.omni_range = 14.0
	_mirror_light.omni_attenuation = 1.45
	_mirror_light.shadow_enabled = false
	add_child(_mirror_light)

	# Upward drifting golden starlight particles
	_particle_process_mat = ParticleProcessMaterial.new()
	_particle_process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	_particle_process_mat.emission_sphere_radius = 3.4
	_particle_process_mat.direction = Vector3(0.0, 1.0, 0.0)
	_particle_process_mat.spread = 22.0
	_particle_process_mat.initial_velocity_min = 0.45
	_particle_process_mat.initial_velocity_max = 1.15
	_particle_process_mat.gravity = Vector3(0.0, 0.28, 0.0)
	_particle_process_mat.scale_min = 0.5
	_particle_process_mat.scale_max = 1.35
	_particle_process_mat.color = Color(1.0, 0.91, 0.60, 0.92)

	var mote_mat: StandardMaterial3D = StandardMaterial3D.new()
	mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mote_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_mat.albedo_color = Color(1.0, 0.93, 0.68, 0.85)

	var mote_mesh: SphereMesh = SphereMesh.new()
	mote_mesh.radius = 0.065
	mote_mesh.height = 0.13
	mote_mesh.radial_segments = 8
	mote_mesh.rings = 6
	mote_mesh.material = mote_mat

	_starlight_particles = GPUParticles3D.new()
	_starlight_particles.name = "GoldenStarlightParticles"
	_starlight_particles.position = Vector3(0.0, MIRROR_CENTER_Y - 0.8, 0.2)
	_starlight_particles.amount = 48
	_starlight_particles.lifetime = 3.8
	_starlight_particles.preprocess = 1.2
	_starlight_particles.emitting = true
	_starlight_particles.amount_ratio = 0.25
	_starlight_particles.process_material = _particle_process_mat
	_starlight_particles.draw_pass_1 = mote_mesh
	add_child(_starlight_particles)


func _build_portal_trigger() -> void:
	_portal_area = Area3D.new()
	_portal_area.name = "PortalTriggerArea"
	_portal_area.position = Vector3(0.0, PORTAL_Y_OFFSET, 0.0)
	_portal_area.monitoring = true
	_portal_area.monitorable = false

	var shape_node: CollisionShape3D = CollisionShape3D.new()
	shape_node.name = "PortalShape"
	var cyl_shape: CylinderShape3D = CylinderShape3D.new()
	cyl_shape.radius = PORTAL_HORIZONTAL_RADIUS
	cyl_shape.height = PORTAL_Y_HALF_HEIGHT * 2.0
	shape_node.shape = cyl_shape

	_portal_area.add_child(shape_node)
	_portal_area.body_entered.connect(_on_portal_area_body_entered)
	add_child(_portal_area)


func _on_portal_area_body_entered(body: Node3D) -> void:
	if state != MirrorState.AWAKENED or _portal_entered_emitted:
		return
	if body != null and (body.is_in_group("player") or body.has_method("recharge_wing_energy")):
		_portal_entered_emitted = true
		player_entered_portal.emit()
