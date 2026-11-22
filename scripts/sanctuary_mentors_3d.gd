extends Node3D
class_name SanctuaryMentors3D

## Ethereal Sanctuary Mentor presences (Alatea & Mira) on the Cathedral upper dais.
## Positioned in front of the Earth Mirror to welcome Spark and guide the dialogue.

const MENTOR_SHADER_PATH: String = "res://shaders/ethereal_mentor.gdshader"
const ALATEA_GLB_PATH: String = "res://assets/models/characters/mentor_alatea.glb"
const MIRA_GLB_PATH: String = "res://assets/models/characters/mentor_mira.glb"

const TALK_RANGE_RADIUS: float = 20.0
const SOUL_CALL_RADIUS: float = 24.0

const COLOR_ALATEA_BODY: Color = Color("#2C94E8")
const COLOR_ALATEA_RIM: Color = Color("#7EEAFF")
const COLOR_ALATEA_RIM_HI: Color = Color("#BCEEFF")
const COLOR_ALATEA_LIGHT: Color = Color(0.56, 0.88, 1.0, 1.0)

const COLOR_MIRA_BODY: Color = Color("#E45C98")
const COLOR_MIRA_RIM: Color = Color("#FFB8D4")
const COLOR_MIRA_RIM_HI: Color = Color("#FFD8E8")
const COLOR_MIRA_HALO: Color = Color("#F2BA86")
const COLOR_MIRA_LIGHT: Color = Color(1.0, 0.78, 0.88, 1.0)

const COLOR_SATIN_GOLD: Color = Color("#F0B286")
const COLOR_BRIGHT_GOLD: Color = Color("#F6C8A2")

const BASE_LIGHT_ENERGY: float = 1.10
const HIGHLIGHT_LIGHT_ENERGY: float = 1.65
const DIMMED_LIGHT_ENERGY: float = 0.78

const BASE_EMISSION_STRENGTH: float = 0.65
const HIGHLIGHT_EMISSION_STRENGTH: float = 0.95
const DIMMED_EMISSION_STRENGTH: float = 0.48

const BASE_GOLD_EMISSION: float = 0.28
const BASE_CRYSTAL_EMISSION: float = 0.62
const BASE_STAR_EMISSION: float = 1.35


class MentorMaterialSet:
	var skin: StandardMaterial3D = null
	var hair: StandardMaterial3D = null
	var robe: ShaderMaterial = null
	var silk_veil: StandardMaterial3D = null
	var wing_ivory: StandardMaterial3D = null
	var wing_gold_tip: StandardMaterial3D = null
	var gold: StandardMaterial3D = null
	var crystal: StandardMaterial3D = null
	var star: StandardMaterial3D = null


var _alatea_root: Node3D = null
var _mira_root: Node3D = null

var _alatea_body_mat: ShaderMaterial = null
var _mira_body_mat: ShaderMaterial = null
var _alatea_mats: MentorMaterialSet = null
var _mira_mats: MentorMaterialSet = null
var _gold_mat: StandardMaterial3D = null
var _alatea_halo_mat: StandardMaterial3D = null
var _mira_halo_mat: StandardMaterial3D = null
var _fate_orb_mat: StandardMaterial3D = null

var _alatea_halo_pivot: Node3D = null
var _alatea_outer_halo: Node3D = null
var _alatea_inner_halo: Node3D = null
var _alatea_fate_orb: Node3D = null
var _alatea_orb_ring: Node3D = null
var _alatea_orb_base_y: float = 4.75
var _mira_halo_pivot: Node3D = null
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

	# Sculpted GLB halo rotation for Alatea (spins cleanly in local ring plane)
	if _alatea_halo_pivot != null:
		_alatea_halo_pivot.rotate_object_local(Vector3.UP, delta * _alatea_halo_speed)

	# Fallback procedural halo rotation for Alatea
	if _alatea_outer_halo != null:
		_alatea_outer_halo.rotation.z += delta * _alatea_halo_speed
	if _alatea_inner_halo != null:
		_alatea_inner_halo.rotation.z -= delta * (_alatea_halo_speed * 1.45)

	# Floating golden fate-orb in front of Alatea's cupped palms
	if _alatea_fate_orb != null:
		_alatea_fate_orb.position.y = _alatea_orb_base_y + sin(_anim_time * 2.15) * 0.09
		if _alatea_orb_ring == null:
			_alatea_fate_orb.rotation.y += delta * (0.55 + _alatea_halo_speed * 0.85)
	if _alatea_orb_ring != null:
		_alatea_orb_ring.rotation.y += delta * 0.85
		_alatea_orb_ring.rotation.x += delta * 0.42

	# Sculpted GLB sunburst solar halo rotation for Mira
	if _mira_halo_pivot != null:
		_mira_halo_pivot.rotate_object_local(Vector3.UP, -delta * _mira_halo_speed)

	# Fallback procedural sunburst halo rotation for Mira
	if _mira_sunburst_halo != null:
		_mira_sunburst_halo.rotation.z -= delta * _mira_halo_speed

	# Apply smooth aura brightness & warm Soul Call pulse
	var pulse_light_add: float = _soul_call_pulse * 0.95
	var pulse_emission_add: float = _soul_call_pulse * 0.35

	if _alatea_light != null:
		_alatea_light.light_energy = _alatea_current_energy + sin(_anim_time * 1.9) * 0.08 + pulse_light_add
	if _mira_light != null:
		_mira_light.light_energy = _mira_current_energy + sin(_anim_time * 1.7 + 1.2) * 0.08 + pulse_light_add

	if _alatea_body_mat != null:
		_alatea_body_mat.set_shader_parameter("emission_strength", _alatea_current_emission + pulse_emission_add)
	if _mira_body_mat != null:
		_mira_body_mat.set_shader_parameter("emission_strength", _mira_current_emission + pulse_emission_add)

	var alatea_speak_delta: float = _alatea_current_emission - BASE_EMISSION_STRENGTH
	var mira_speak_delta: float = _mira_current_emission - BASE_EMISSION_STRENGTH

	if _alatea_mats != null:
		if _alatea_mats.gold != null:
			_alatea_mats.gold.emission_energy_multiplier = BASE_GOLD_EMISSION + clampf(alatea_speak_delta * 0.60, -0.08, 0.20) + pulse_emission_add * 0.45
		if _alatea_mats.crystal != null:
			_alatea_mats.crystal.emission_energy_multiplier = BASE_CRYSTAL_EMISSION + clampf(alatea_speak_delta * 0.70, -0.12, 0.25) + pulse_emission_add * 0.45
		if _alatea_mats.star != null:
			_alatea_mats.star.emission_energy_multiplier = BASE_STAR_EMISSION + clampf(alatea_speak_delta * 1.15, -0.15, 0.35) + pulse_emission_add * 0.55

	if _mira_mats != null:
		if _mira_mats.gold != null:
			_mira_mats.gold.emission_energy_multiplier = BASE_GOLD_EMISSION + clampf(mira_speak_delta * 0.60, -0.08, 0.20) + pulse_emission_add * 0.45
		if _mira_mats.crystal != null:
			_mira_mats.crystal.emission_energy_multiplier = BASE_CRYSTAL_EMISSION + clampf(mira_speak_delta * 0.70, -0.12, 0.25) + pulse_emission_add * 0.45
		if _mira_mats.star != null:
			_mira_mats.star.emission_energy_multiplier = BASE_STAR_EMISSION + clampf(mira_speak_delta * 1.15, -0.15, 0.35) + pulse_emission_add * 0.55


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
	_alatea_body_mat.set_shader_parameter("rim_highlight_color", COLOR_ALATEA_RIM_HI)
	_alatea_body_mat.set_shader_parameter("base_opacity", 0.90)
	_alatea_body_mat.set_shader_parameter("fresnel_power", 2.35)
	_alatea_body_mat.set_shader_parameter("emission_strength", BASE_EMISSION_STRENGTH)
	_alatea_body_mat.set_shader_parameter("shimmer_speed", 0.88)
	_alatea_body_mat.set_shader_parameter("stardust_intensity", 0.32)
	_alatea_body_mat.set_shader_parameter("hem_fade_start", 0.0)
	_alatea_body_mat.set_shader_parameter("hem_fade_end", 1.05)

	_mira_body_mat = ShaderMaterial.new()
	if mentor_shader != null:
		_mira_body_mat.shader = mentor_shader
	_mira_body_mat.set_shader_parameter("body_color", COLOR_MIRA_BODY)
	_mira_body_mat.set_shader_parameter("rim_color", COLOR_MIRA_RIM)
	_mira_body_mat.set_shader_parameter("rim_highlight_color", COLOR_MIRA_RIM_HI)
	_mira_body_mat.set_shader_parameter("base_opacity", 0.90)
	_mira_body_mat.set_shader_parameter("fresnel_power", 2.25)
	_mira_body_mat.set_shader_parameter("emission_strength", BASE_EMISSION_STRENGTH)
	_mira_body_mat.set_shader_parameter("shimmer_speed", 0.76)
	_mira_body_mat.set_shader_parameter("stardust_intensity", 0.32)
	_mira_body_mat.set_shader_parameter("hem_fade_start", 0.0)
	_mira_body_mat.set_shader_parameter("hem_fade_end", 1.05)

	# Per-mentor celestial wing materials (saturated sky-blue feathers for Alatea, sakura-pink for Mira)
	var alatea_wing_mat: StandardMaterial3D = StandardMaterial3D.new()
	alatea_wing_mat.albedo_color = Color("#74C6FA")
	alatea_wing_mat.roughness = 0.42
	alatea_wing_mat.metallic = 0.06
	alatea_wing_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	alatea_wing_mat.emission_enabled = true
	alatea_wing_mat.emission = Color("#9ED8FF")
	alatea_wing_mat.emission_energy_multiplier = 0.14

	var alatea_wing_tip_mat: StandardMaterial3D = StandardMaterial3D.new()
	alatea_wing_tip_mat.albedo_color = Color("#F0B286")
	alatea_wing_tip_mat.metallic = 0.78
	alatea_wing_tip_mat.roughness = 0.36
	alatea_wing_tip_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	alatea_wing_tip_mat.emission_enabled = true
	alatea_wing_tip_mat.emission = Color("#F6C8A2")
	alatea_wing_tip_mat.emission_energy_multiplier = 0.14

	var mira_wing_mat: StandardMaterial3D = StandardMaterial3D.new()
	mira_wing_mat.albedo_color = Color("#FA9CC0")
	mira_wing_mat.roughness = 0.42
	mira_wing_mat.metallic = 0.06
	mira_wing_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mira_wing_mat.emission_enabled = true
	mira_wing_mat.emission = Color("#FFC0D8")
	mira_wing_mat.emission_energy_multiplier = 0.14

	var mira_wing_tip_mat: StandardMaterial3D = StandardMaterial3D.new()
	mira_wing_tip_mat.albedo_color = Color("#F2BA86")
	mira_wing_tip_mat.metallic = 0.78
	mira_wing_tip_mat.roughness = 0.36
	mira_wing_tip_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mira_wing_tip_mat.emission_enabled = true
	mira_wing_tip_mat.emission = Color("#FAD0A6")
	mira_wing_tip_mat.emission_energy_multiplier = 0.14

	# Alatea: Sapphire, Turquoise & Twilight-Violet Goddess
	_alatea_mats = _create_mentor_material_set(
		_alatea_body_mat,
		Color("#FAD4C6"),
		Color("#6C6AE6"),
		Color("#8C8AFF"),
		Color(0.36, 0.84, 1.0, 0.56),
		Color("#78E4FF"),
		Color("#3CE0FF"),
		Color("#74EEFF"),
		alatea_wing_mat,
		alatea_wing_tip_mat
	)

	# Mira: Sakura-Rose, Coral-Peach & Amethyst Goddess
	_mira_mats = _create_mentor_material_set(
		_mira_body_mat,
		Color("#FCD6C8"),
		Color("#E076B2"),
		Color("#FF96CE"),
		Color(1.0, 0.62, 0.80, 0.56),
		Color("#FF98C2"),
		Color("#F568B8"),
		Color("#FF9ED4"),
		mira_wing_mat,
		mira_wing_tip_mat
	)

	# Keep legacy references bound to Alatea's gold & starlight materials for procedural fallbacks
	_gold_mat = _alatea_mats.gold
	_fate_orb_mat = _alatea_mats.star

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


func _create_mentor_material_set(
	robe_mat: ShaderMaterial,
	skin_albedo: Color,
	hair_albedo: Color,
	hair_emission: Color,
	veil_albedo: Color,
	veil_emission: Color,
	crystal_albedo: Color,
	crystal_emission: Color,
	wing_ivory_mat: StandardMaterial3D,
	wing_gold_tip_mat: StandardMaterial3D
) -> MentorMaterialSet:
	var mat_set: MentorMaterialSet = MentorMaterialSet.new()
	mat_set.robe = robe_mat
	mat_set.wing_ivory = wing_ivory_mat
	mat_set.wing_gold_tip = wing_gold_tip_mat

	# 1. Mat_MentorSkin: warm living blush-peach porcelain goddess skin (never grey)
	var skin_mat: StandardMaterial3D = StandardMaterial3D.new()
	skin_mat.albedo_color = skin_albedo
	skin_mat.roughness = 0.34
	skin_mat.metallic = 0.02
	skin_mat.emission_enabled = true
	skin_mat.emission = Color("#FFD8C8")
	skin_mat.emission_energy_multiplier = 0.16
	mat_set.skin = skin_mat

	# 2. Mat_MentorHair: lush luminous jewel-pastel flowing hair
	var hair_mat: StandardMaterial3D = StandardMaterial3D.new()
	hair_mat.albedo_color = hair_albedo
	hair_mat.roughness = 0.32
	hair_mat.metallic = 0.18
	hair_mat.emission_enabled = true
	hair_mat.emission = hair_emission
	hair_mat.emission_energy_multiplier = 0.16
	mat_set.hair = hair_mat

	# 4. Mat_MentorSilkVeil: sheer luminous celestial organza
	var veil_mat: StandardMaterial3D = StandardMaterial3D.new()
	veil_mat.albedo_color = veil_albedo
	veil_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	veil_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	veil_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	veil_mat.roughness = 0.28
	veil_mat.metallic = 0.04
	veil_mat.emission_enabled = true
	veil_mat.emission = veil_emission
	veil_mat.emission_energy_multiplier = 0.24
	mat_set.silk_veil = veil_mat

	# 7. Mat_MentorGold: ornate brushed rose-champagne gold filigree
	var gold_mat: StandardMaterial3D = StandardMaterial3D.new()
	gold_mat.albedo_color = COLOR_SATIN_GOLD
	gold_mat.metallic = 0.80
	gold_mat.roughness = 0.36
	gold_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	gold_mat.emission_enabled = true
	gold_mat.emission = COLOR_BRIGHT_GOLD
	gold_mat.emission_energy_multiplier = BASE_GOLD_EMISSION
	mat_set.gold = gold_mat

	# 8. Mat_MentorCrystal: vivid faceted celestial crystal teardrops & tiara gems
	var crystal_mat: StandardMaterial3D = StandardMaterial3D.new()
	crystal_mat.albedo_color = crystal_albedo
	crystal_mat.roughness = 0.14
	crystal_mat.metallic = 0.15
	crystal_mat.emission_enabled = true
	crystal_mat.emission = crystal_emission
	crystal_mat.emission_energy_multiplier = BASE_CRYSTAL_EMISSION
	mat_set.crystal = crystal_mat

	# 9. Mat_MentorStar: serene radiant starlight heart & Fate Orb core
	var star_mat: StandardMaterial3D = StandardMaterial3D.new()
	star_mat.albedo_color = Color("#FFF4F8")
	star_mat.roughness = 0.18
	star_mat.metallic = 0.15
	star_mat.emission_enabled = true
	star_mat.emission = Color("#FFD6EA")
	star_mat.emission_energy_multiplier = BASE_STAR_EMISSION
	mat_set.star = star_mat

	return mat_set


func _try_instantiate_mentor_glb(
	glb_path: String,
	parent: Node3D,
	mat_set: MentorMaterialSet
) -> Node3D:
	if not ResourceLoader.exists(glb_path):
		return null
	var packed: PackedScene = load(glb_path) as PackedScene
	if packed == null:
		return null
	var instance: Node3D = packed.instantiate() as Node3D
	if instance == null:
		return null
	parent.add_child(instance)
	_apply_mentor_materials_recursive(instance, mat_set)
	return instance


func _apply_mentor_materials_recursive(node: Node, mat_set: MentorMaterialSet) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mesh: Mesh = mi.mesh
		if mesh != null:
			var surf_count: int = mesh.get_surface_count()
			var node_name_lower: String = mi.name.to_lower()
			for s_idx: int in range(surf_count):
				var surf_mat: Material = mesh.surface_get_material(s_idx)
				var mat_name: String = ""
				if surf_mat != null:
					mat_name = surf_mat.resource_name
				var chosen_mat: Material = _resolve_mentor_surface_material(
					mat_name, node_name_lower, mat_set
				)
				mi.set_surface_override_material(s_idx, chosen_mat)

	for child: Node in node.get_children():
		_apply_mentor_materials_recursive(child, mat_set)


func _resolve_mentor_surface_material(
	mat_name: String,
	node_name_lower: String,
	mat_set: MentorMaterialSet
) -> Material:
	# Explicit semantic material names first (order prevents substring collisions like WingGoldTip vs Gold)
	if mat_name.contains("Mat_MentorSkin"):
		return mat_set.skin
	if mat_name.contains("Mat_MentorHair"):
		return mat_set.hair
	if mat_name.contains("Mat_MentorSilkVeil"):
		return mat_set.silk_veil
	if mat_name.contains("Mat_WingGoldTip"):
		return mat_set.wing_gold_tip
	if mat_name.contains("Mat_WingIvory"):
		return mat_set.wing_ivory
	if mat_name.contains("Mat_MentorCrystal"):
		return mat_set.crystal
	if mat_name.contains("Mat_MentorGold"):
		return mat_set.gold
	if mat_name.contains("Mat_MentorStar"):
		return mat_set.star
	if mat_name.contains("Mat_MentorRobe") or mat_name.contains("Mat_MentorBody"):
		return mat_set.robe

	# Legacy / heuristic surface & node name fallbacks
	if mat_name.contains("WingGold") or node_name_lower.contains("winggold") or node_name_lower.contains("wing_gold"):
		return mat_set.wing_gold_tip
	if mat_name.contains("Wing") or node_name_lower.contains("wing") or node_name_lower.contains("feather"):
		return mat_set.wing_ivory
	if mat_name.contains("Silk") or mat_name.contains("Veil") or node_name_lower.contains("veil") or node_name_lower.contains("silk"):
		return mat_set.silk_veil
	if mat_name.contains("Crystal") or mat_name.contains("Gem") or node_name_lower.contains("crystal") or node_name_lower.contains("gem"):
		return mat_set.crystal
	if mat_name.contains("Skin") or node_name_lower.contains("skin") or node_name_lower.contains("face"):
		return mat_set.skin
	if mat_name.contains("Hair") or node_name_lower.contains("hair"):
		return mat_set.hair
	if mat_name.contains("Gold") or node_name_lower.contains("gold") or node_name_lower.contains("halo") or node_name_lower.contains("astrolabe") or node_name_lower.contains("crown"):
		return mat_set.gold
	if mat_name.contains("Star") or node_name_lower.contains("star") or node_name_lower.contains("orb_core"):
		return mat_set.star

	return mat_set.robe


func _build_alatea() -> void:
	_alatea_root = Node3D.new()
	_alatea_root.name = "Alatea"
	_alatea_root.position = Vector3(-7.5, 0.22, 0.0)
	_alatea_root.rotation_degrees.y = 24.0
	add_child(_alatea_root)

	var model_root: Node3D = _try_instantiate_mentor_glb(ALATEA_GLB_PATH, _alatea_root, _alatea_mats)
	if model_root != null:
		model_root.name = "AlateaModel"
		_alatea_halo_pivot = model_root.find_child("AlateaHaloPivot", true, false) as Node3D
		_alatea_fate_orb = model_root.find_child("AlateaFateOrbPivot", true, false) as Node3D
		if _alatea_fate_orb != null:
			_alatea_orb_base_y = _alatea_fate_orb.position.y
	else:
		_build_alatea_fallback()

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

	var model_root: Node3D = _try_instantiate_mentor_glb(MIRA_GLB_PATH, _mira_root, _mira_mats)
	if model_root != null:
		model_root.name = "MiraModel"
		_mira_halo_pivot = model_root.find_child("MiraHaloPivot", true, false) as Node3D
	else:
		_build_mira_fallback()

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


func _build_alatea_fallback() -> void:
	_build_mentor_body(_alatea_root, _alatea_body_mat, _alatea_halo_mat, false)

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

	_alatea_fate_orb = Node3D.new()
	_alatea_fate_orb.name = "GoldenFateOrb"
	_alatea_fate_orb.position = Vector3(0.0, 4.68, 1.18)
	_alatea_orb_base_y = 4.68
	_alatea_root.add_child(_alatea_fate_orb)

	_add_sphere(_alatea_fate_orb, "OrbCore", 0.22, 16, 12, Vector3.ZERO, _fate_orb_mat)

	_alatea_orb_ring = Node3D.new()
	_alatea_orb_ring.name = "OrbFiligreeRingPivot"
	_alatea_fate_orb.add_child(_alatea_orb_ring)
	_add_torus(_alatea_orb_ring, "OrbEquatorialRing", 0.34, 0.37, 24, 8, Vector3.ZERO, _mira_halo_mat)


func _build_mira_fallback() -> void:
	_build_mentor_body(_mira_root, _mira_body_mat, _mira_halo_mat, true)

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


func _build_mentor_body(
	parent: Node3D,
	body_mat: Material,
	accent_mat: Material,
	open_welcome_arms: bool
) -> void:
	_add_cylinder(parent, "LowerRobe", 0.52, 1.26, 3.8, 16, Vector3(0.0, 2.05, 0.0), body_mat)
	_add_cylinder(parent, "UpperTorso", 0.68, 0.48, 1.85, 14, Vector3(0.0, 4.82, 0.0), body_mat)

	var mantle: MeshInstance3D = _add_cylinder(
		parent, "MantleCape", 0.34, 1.14, 1.45, 14, Vector3(0.0, 5.34, -0.14), body_mat
	)
	mantle.scale = Vector3(1.32, 1.0, 0.72)

	for side_val: float in [-1.0, 1.0]:
		var arm_name: String = "EtherealArm_%s" % ("L" if side_val < 0.0 else "R")
		if open_welcome_arms:
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

	_add_sphere(parent, "Head", 0.44, 18, 12, Vector3(0.0, 6.38, 0.05), body_mat)
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
