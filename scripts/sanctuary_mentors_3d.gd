extends Node3D
class_name SanctuaryMentors3D

## Ethereal Sanctuary Mentor presences (Alatea & Mira) on the Cathedral upper dais.
## Positioned in front of the Earth Mirror to welcome Spark and guide the dialogue.

const MENTOR_SHADER_PATH: String = "res://shaders/ethereal_mentor.gdshader"

const TALK_RANGE_RADIUS: float = 20.0
const SOUL_CALL_RADIUS: float = 24.0

const COLOR_ALATEA_BODY: Color = Color(0.16, 0.56, 0.92, 1.0)
const COLOR_ALATEA_RIM: Color = Color("#58C4FF")
const COLOR_ALATEA_LIGHT: Color = Color(0.45, 0.80, 1.0, 1.0)

const COLOR_MIRA_BODY: Color = Color(0.42, 0.72, 0.94, 1.0)
const COLOR_MIRA_RIM: Color = Color("#A8E0FF")
const COLOR_MIRA_HALO: Color = Color("#F6D36B")
const COLOR_MIRA_LIGHT: Color = Color(0.86, 0.88, 0.74, 1.0)

const COLOR_SATIN_GOLD: Color = Color("#EBC86A")
const COLOR_BRIGHT_GOLD: Color = Color("#F6D36B")

const BASE_LIGHT_ENERGY: float = 1.45
const HIGHLIGHT_LIGHT_ENERGY: float = 2.45
const DIMMED_LIGHT_ENERGY: float = 1.05

const BASE_EMISSION_STRENGTH: float = 1.45
const HIGHLIGHT_EMISSION_STRENGTH: float = 2.15
const DIMMED_EMISSION_STRENGTH: float = 1.15

var _alatea_root: Node3D = null
var _mira_root: Node3D = null

var _alatea_body_mat: ShaderMaterial = null
var _mira_body_mat: ShaderMaterial = null
var _alatea_halo_mat: StandardMaterial3D = null
var _mira_halo_mat: StandardMaterial3D = null
var _fate_orb_mat: StandardMaterial3D = null

var _alatea_outer_halo: Node3D = null
var _alatea_inner_halo: Node3D = null
var _alatea_fate_orb: Node3D = null
var _alatea_orb_ring: Node3D = null
var _mira_sunburst_halo: Node3D = null

var _alatea_light: OmniLight3D = null
var _mira_light: OmniLight3D = null

var _active_speaker: String = ""
var _anim_time: float = 0.0

var _alatea_target_energy: float = BASE_LIGHT_ENERGY
var _mira_target_energy: float = BASE_LIGHT_ENERGY
var _alatea_current_energy: float = BASE_LIGHT_ENERGY
var _mira_current_energy: float = BASE_LIGHT_ENERGY

var _alatea_target_emission: float = BASE_EMISSION_STRENGTH
var _mira_target_emission: float = BASE_EMISSION_STRENGTH
var _alatea_current_emission: float = BASE_EMISSION_STRENGTH
var _mira_current_emission: float = BASE_EMISSION_STRENGTH

var _alatea_halo_speed: float = 0.24
var _mira_halo_speed: float = 0.18
var _alatea_target_halo_speed: float = 0.24
var _mira_target_halo_speed: float = 0.18

var _soul_call_pulse: float = 0.0
var _pulse_tween: Tween = null


func _ready() -> void:
	add_to_group("sanctuary_mentors")
	_init_materials()
	_build_alatea()
	_build_mira()


func _process(delta: float) -> void:
	_anim_time += delta

	var blend_weight: float = clampf(delta * 4.2, 0.0, 1.0)
	_alatea_current_energy = lerpf(_alatea_current_energy, _alatea_target_energy, blend_weight)
	_mira_current_energy = lerpf(_mira_current_energy, _mira_target_energy, blend_weight)
	_alatea_current_emission = lerpf(_alatea_current_emission, _alatea_target_emission, blend_weight)
	_mira_current_emission = lerpf(_mira_current_emission, _mira_target_emission, blend_weight)
	_alatea_halo_speed = lerpf(_alatea_halo_speed, _alatea_target_halo_speed, blend_weight)
	_mira_halo_speed = lerpf(_mira_halo_speed, _mira_target_halo_speed, blend_weight)

	# Gentle floating bobbing animation with organic phase offset
	if _alatea_root != null:
		_alatea_root.position.y = 0.22 + sin(_anim_time * 1.15) * 0.18
	if _mira_root != null:
		_mira_root.position.y = 0.22 + sin(_anim_time * 1.08 + 1.85) * 0.18

	# Slow orbital Art Deco double halo rotation for Alatea
	if _alatea_outer_halo != null:
		_alatea_outer_halo.rotation.z += delta * _alatea_halo_speed
	if _alatea_inner_halo != null:
		_alatea_inner_halo.rotation.z -= delta * (_alatea_halo_speed * 1.45)

	# Floating golden fate-orb in front of Alatea's palms
	if _alatea_fate_orb != null:
		_alatea_fate_orb.position.y = 4.68 + sin(_anim_time * 2.15) * 0.09
	if _alatea_orb_ring != null:
		_alatea_orb_ring.rotation.y += delta * 0.85
		_alatea_orb_ring.rotation.x += delta * 0.42

	# Radiant sunburst crown halo slow rotation for Mira
	if _mira_sunburst_halo != null:
		_mira_sunburst_halo.rotation.z -= delta * _mira_halo_speed

	# Apply smooth aura brightness & warm Soul Call pulse
	var pulse_light_add: float = _soul_call_pulse * 1.65
	var pulse_emission_add: float = _soul_call_pulse * 0.75

	if _alatea_light != null:
		_alatea_light.light_energy = _alatea_current_energy + sin(_anim_time * 1.9) * 0.08 + pulse_light_add
	if _mira_light != null:
		_mira_light.light_energy = _mira_current_energy + sin(_anim_time * 1.7 + 1.2) * 0.08 + pulse_light_add

	if _alatea_body_mat != null:
		_alatea_body_mat.set_shader_parameter("emission_strength", _alatea_current_emission + pulse_emission_add)
	if _mira_body_mat != null:
		_mira_body_mat.set_shader_parameter("emission_strength", _mira_current_emission + pulse_emission_add)

	if _fate_orb_mat != null:
		var orb_boost: float = 1.45 + pulse_emission_add * 0.8
		if _active_speaker == "alatea":
			orb_boost += 0.45
		_fate_orb_mat.emission_energy_multiplier = orb_boost


## Highlights the currently speaking mentor ("alatea", "mira", or "" for neutral).
## Gently brightens the speaker's aura and accelerates their halo rotation.
func highlight_speaker(mentor_id: String) -> void:
	var normalized: String = mentor_id.strip_edges().to_lower()
	_active_speaker = normalized

	if normalized == "alatea":
		_alatea_target_energy = HIGHLIGHT_LIGHT_ENERGY
		_alatea_target_emission = HIGHLIGHT_EMISSION_STRENGTH
		_alatea_target_halo_speed = 0.56

		_mira_target_energy = DIMMED_LIGHT_ENERGY
		_mira_target_emission = DIMMED_EMISSION_STRENGTH
		_mira_target_halo_speed = 0.12
	elif normalized == "mira":
		_alatea_target_energy = DIMMED_LIGHT_ENERGY
		_alatea_target_emission = DIMMED_EMISSION_STRENGTH
		_alatea_target_halo_speed = 0.14

		_mira_target_energy = HIGHLIGHT_LIGHT_ENERGY
		_mira_target_emission = HIGHLIGHT_EMISSION_STRENGTH
		_mira_target_halo_speed = 0.46
	else:
		_active_speaker = ""
		_alatea_target_energy = BASE_LIGHT_ENERGY
		_alatea_target_emission = BASE_EMISSION_STRENGTH
		_alatea_target_halo_speed = 0.24

		_mira_target_energy = BASE_LIGHT_ENERGY
		_mira_target_emission = BASE_EMISSION_STRENGTH
		_mira_target_halo_speed = 0.18


## Responds to Spark's Soul Call if within 24.0m of the sanctuary dais center.
## Triggers a warm luminous pulse on both mentors and returns true.
func respond_to_soul_call(origin: Vector3) -> bool:
	var dist: float = origin.distance_to(global_position)
	if dist > SOUL_CALL_RADIUS:
		return false

	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()

	_pulse_tween = create_tween()
	_pulse_tween.tween_method(
		_set_soul_call_pulse, _soul_call_pulse, 1.0, 0.28
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_method(
		_set_soul_call_pulse, 1.0, 0.0, 1.05
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return true


## Returns true if the player is within 20.0m of the sanctuary mentors' dais position.
func is_player_in_talk_range(player_pos: Vector3) -> bool:
	var dist: float = player_pos.distance_to(global_position)
	return dist <= TALK_RANGE_RADIUS


func _set_soul_call_pulse(value: float) -> void:
	_soul_call_pulse = clampf(value, 0.0, 1.0)


func _init_materials() -> void:
	var mentor_shader: Shader = null
	if ResourceLoader.exists(MENTOR_SHADER_PATH):
		mentor_shader = load(MENTOR_SHADER_PATH) as Shader

	_alatea_body_mat = ShaderMaterial.new()
	if mentor_shader != null:
		_alatea_body_mat.shader = mentor_shader
	_alatea_body_mat.set_shader_parameter("body_color", COLOR_ALATEA_BODY)
	_alatea_body_mat.set_shader_parameter("rim_color", COLOR_ALATEA_RIM)
	_alatea_body_mat.set_shader_parameter("base_opacity", 0.26)
	_alatea_body_mat.set_shader_parameter("fresnel_power", 2.0)
	_alatea_body_mat.set_shader_parameter("emission_strength", BASE_EMISSION_STRENGTH)
	_alatea_body_mat.set_shader_parameter("shimmer_speed", 0.9)

	_mira_body_mat = ShaderMaterial.new()
	if mentor_shader != null:
		_mira_body_mat.shader = mentor_shader
	_mira_body_mat.set_shader_parameter("body_color", COLOR_MIRA_BODY)
	_mira_body_mat.set_shader_parameter("rim_color", COLOR_MIRA_RIM)
	_mira_body_mat.set_shader_parameter("base_opacity", 0.26)
	_mira_body_mat.set_shader_parameter("fresnel_power", 1.95)
	_mira_body_mat.set_shader_parameter("emission_strength", BASE_EMISSION_STRENGTH)
	_mira_body_mat.set_shader_parameter("shimmer_speed", 0.78)

	_alatea_halo_mat = StandardMaterial3D.new()
	_alatea_halo_mat.albedo_color = Color(COLOR_ALATEA_RIM.r, COLOR_ALATEA_RIM.g, COLOR_ALATEA_RIM.b, 0.72)
	_alatea_halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_alatea_halo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_alatea_halo_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_alatea_halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_mira_halo_mat = StandardMaterial3D.new()
	_mira_halo_mat.albedo_color = Color(COLOR_MIRA_HALO.r, COLOR_MIRA_HALO.g, COLOR_MIRA_HALO.b, 0.76)
	_mira_halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mira_halo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mira_halo_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mira_halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_fate_orb_mat = StandardMaterial3D.new()
	_fate_orb_mat.albedo_color = Color("#FFF4CE")
	_fate_orb_mat.roughness = 0.18
	_fate_orb_mat.metallic = 0.25
	_fate_orb_mat.emission_enabled = true
	_fate_orb_mat.emission = COLOR_BRIGHT_GOLD
	_fate_orb_mat.emission_energy_multiplier = 1.45


func _build_alatea() -> void:
	_alatea_root = Node3D.new()
	_alatea_root.name = "Alatea"
	_alatea_root.position = Vector3(-7.5, 0.22, 0.0)
	_alatea_root.rotation_degrees.y = 24.0
	add_child(_alatea_root)

	_build_mentor_body(_alatea_root, _alatea_body_mat, _alatea_halo_mat, false)

	# Orbital Art Deco double halo rings behind Alatea's head
	var halo_anchor: Node3D = Node3D.new()
	halo_anchor.name = "OrbitalDoubleHalo"
	halo_anchor.position = Vector3(0.0, 6.42, -0.42)
	_alatea_root.add_child(halo_anchor)

	_alatea_outer_halo = Node3D.new()
	_alatea_outer_halo.name = "OuterHaloPivot"
	halo_anchor.add_child(_alatea_outer_halo)

	var outer_ring: MeshInstance3D = _add_torus(
		_alatea_outer_halo, "OuterHaloRing", 1.18, 1.25, 36, 10, Vector3.ZERO, _alatea_halo_mat
	)
	outer_ring.rotation_degrees.x = 90.0

	# 4 delicate Art Deco cardinal ticks on Alatea's outer halo
	for i: int in range(4):
		var angle_rad: float = float(i) * (PI * 0.5)
		var tick: MeshInstance3D = _add_box(
			_alatea_outer_halo,
			"HaloTick_%d" % i,
			Vector3(0.06, 0.24, 0.04),
			Vector3(cos(angle_rad) * 1.32, sin(angle_rad) * 1.32, 0.0),
			_mira_halo_mat
		)
		tick.rotation.z = angle_rad - PI * 0.5

	_alatea_inner_halo = Node3D.new()
	_alatea_inner_halo.name = "InnerHaloPivot"
	_alatea_inner_halo.rotation_degrees = Vector3(12.0, -10.0, 0.0)
	halo_anchor.add_child(_alatea_inner_halo)

	var inner_ring: MeshInstance3D = _add_torus(
		_alatea_inner_halo, "InnerHaloRing", 0.78, 0.83, 28, 8, Vector3.ZERO, _mira_halo_mat
	)
	inner_ring.rotation_degrees.x = 90.0

	# Glowing golden fate-orb floating in front of Alatea's palms
	_alatea_fate_orb = Node3D.new()
	_alatea_fate_orb.name = "GoldenFateOrb"
	_alatea_fate_orb.position = Vector3(0.0, 4.68, 1.18)
	_alatea_root.add_child(_alatea_fate_orb)

	_add_sphere(_alatea_fate_orb, "OrbCore", 0.22, 16, 12, Vector3.ZERO, _fate_orb_mat)

	_alatea_orb_ring = Node3D.new()
	_alatea_orb_ring.name = "OrbFiligreeRingPivot"
	_alatea_fate_orb.add_child(_alatea_orb_ring)
	_add_torus(_alatea_orb_ring, "OrbEquatorialRing", 0.34, 0.37, 24, 8, Vector3.ZERO, _mira_halo_mat)

	# Soft cyan-gold aura OmniLight3D for Alatea
	_alatea_light = OmniLight3D.new()
	_alatea_light.name = "AlateaAuraLight"
	_alatea_light.position = Vector3(0.0, 4.8, 0.9)
	_alatea_light.light_color = COLOR_ALATEA_LIGHT
	_alatea_light.light_energy = BASE_LIGHT_ENERGY
	_alatea_light.omni_range = 14.5
	_alatea_light.omni_attenuation = 1.5
	_alatea_light.shadow_enabled = false
	_alatea_root.add_child(_alatea_light)


func _build_mira() -> void:
	_mira_root = Node3D.new()
	_mira_root.name = "Mira"
	_mira_root.position = Vector3(7.5, 0.22, 0.0)
	_mira_root.rotation_degrees.y = -24.0
	add_child(_mira_root)

	_build_mentor_body(_mira_root, _mira_body_mat, _mira_halo_mat, true)

	# Radiant sunburst crown halo behind Mira's head
	_mira_sunburst_halo = Node3D.new()
	_mira_sunburst_halo.name = "SunburstCrownHalo"
	_mira_sunburst_halo.position = Vector3(0.0, 6.46, -0.40)
	_mira_root.add_child(_mira_sunburst_halo)

	var crown_ring: MeshInstance3D = _add_torus(
		_mira_sunburst_halo, "CrownRing", 0.86, 0.93, 32, 10, Vector3.ZERO, _mira_halo_mat
	)
	crown_ring.rotation_degrees.x = 90.0

	var ray_count: int = 12
	for i: int in range(ray_count):
		var angle_rad: float = float(i) * (TAU / float(ray_count))
		var is_major: bool = (i % 2 == 0)
		var ray_len: float = 0.62 if is_major else 0.38
		var ray_width: float = 0.055 if is_major else 0.036
		var radial_offset: float = 0.95 + ray_len * 0.5

		var ray: MeshInstance3D = _add_cylinder(
			_mira_sunburst_halo,
			"SunburstRay_%d" % i,
			0.006,
			ray_width,
			ray_len,
			4,
			Vector3(cos(angle_rad) * radial_offset, sin(angle_rad) * radial_offset, 0.0),
			_mira_halo_mat
		)
		ray.rotation.z = angle_rad - PI * 0.5

	# Soft warm gold-cyan aura OmniLight3D for Mira
	_mira_light = OmniLight3D.new()
	_mira_light.name = "MiraAuraLight"
	_mira_light.position = Vector3(0.0, 4.8, 0.9)
	_mira_light.light_color = COLOR_MIRA_LIGHT
	_mira_light.light_energy = BASE_LIGHT_ENERGY
	_mira_light.omni_range = 14.5
	_mira_light.omni_attenuation = 1.5
	_mira_light.shadow_enabled = false
	_mira_root.add_child(_mira_light)


func _build_mentor_body(
	parent: Node3D,
	body_mat: Material,
	accent_mat: Material,
	open_welcome_arms: bool
) -> void:
	# Flowing lower robe silhouette (base ~0.15m -> y = 3.95m)
	_add_cylinder(parent, "LowerRobe", 0.52, 1.26, 3.8, 16, Vector3(0.0, 2.05, 0.0), body_mat)

	# Slender upper torso (y = 3.90m -> y = 5.75m)
	_add_cylinder(parent, "UpperTorso", 0.68, 0.48, 1.85, 14, Vector3(0.0, 4.82, 0.0), body_mat)

	# Draped luminous mantle / shoulder cape
	var mantle: MeshInstance3D = _add_cylinder(
		parent, "MantleCape", 0.34, 1.14, 1.45, 14, Vector3(0.0, 5.34, -0.14), body_mat
	)
	mantle.scale = Vector3(1.32, 1.0, 0.72)

	# Graceful welcoming arms
	for side_val: float in [-1.0, 1.0]:
		var arm_name: String = "EtherealArm_%s" % ("L" if side_val < 0.0 else "R")
		if open_welcome_arms:
			# Mira: softly outstretched welcoming gesture
			var arm_m: MeshInstance3D = _add_cylinder(
				parent,
				arm_name,
				0.11,
				0.21,
				1.75,
				10,
				Vector3(side_val * 0.88, 5.05, 0.34),
				body_mat
			)
			arm_m.rotation_degrees = Vector3(26.0, 0.0, side_val * 44.0)
		else:
			# Alatea: arms angled gently forward toward her floating golden fate-orb
			var arm_a: MeshInstance3D = _add_cylinder(
				parent,
				arm_name,
				0.11,
				0.21,
				1.68,
				10,
				Vector3(side_val * 0.68, 4.92, 0.54),
				body_mat
			)
			arm_a.rotation_degrees = Vector3(52.0, side_val * -18.0, side_val * 24.0)

	# Luminous hooded head (top ~6.82m; with halo reaches ~7.5m-7.8m)
	_add_sphere(parent, "Head", 0.44, 18, 12, Vector3(0.0, 6.38, 0.05), body_mat)

	# Soft inner heart starlight core
	_add_sphere(parent, "HeartStar", 0.21, 14, 10, Vector3(0.0, 5.15, 0.34), accent_mat)


func _add_cylinder(
	parent: Node3D,
	node_name: String,
	top_r: float,
	bottom_r: float,
	height_val: float,
	radial_segs: int,
	local_pos: Vector3,
	mat: Material
) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height_val
	mesh.radial_segments = radial_segs
	mesh.rings = 1

	var inst: MeshInstance3D = MeshInstance3D.new()
	inst.name = node_name
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = local_pos
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


func _add_sphere(
	parent: Node3D,
	node_name: String,
	radius_val: float,
	radial_segs: int,
	rings_val: int,
	local_pos: Vector3,
	mat: Material
) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius_val
	mesh.height = radius_val * 2.0
	mesh.radial_segments = radial_segs
	mesh.rings = rings_val

	var inst: MeshInstance3D = MeshInstance3D.new()
	inst.name = node_name
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = local_pos
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


func _add_torus(
	parent: Node3D,
	node_name: String,
	inner_r: float,
	outer_r: float,
	rings_val: int,
	ring_segs: int,
	local_pos: Vector3,
	mat: Material
) -> MeshInstance3D:
	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = inner_r
	mesh.outer_radius = outer_r
	mesh.rings = rings_val
	mesh.ring_segments = ring_segs

	var inst: MeshInstance3D = MeshInstance3D.new()
	inst.name = node_name
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = local_pos
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


func _add_box(
	parent: Node3D,
	node_name: String,
	size_val: Vector3,
	local_pos: Vector3,
	mat: Material
) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size_val

	var inst: MeshInstance3D = MeshInstance3D.new()
	inst.name = node_name
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = local_pos
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst
