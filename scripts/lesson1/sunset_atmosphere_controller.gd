class_name SunsetAtmosphereController
extends Node

## Smoothly transitions Akasha's sky dome, SunLight, volumetric fog, and CloudSea
## between the Prologue Dawn preset and Lesson 1's Golden Sunset ("Золотой закат") preset.
## Strictly passes Color (never Vector3) to all source_color shader uniforms and preserves
## SunLight shadow_bias = 0.06 and shadow_normal_bias = 2.4.

const DEFAULT_TRANSITION_DURATION: float = 3.2
const SUN_SHADOW_BIAS: float = 0.06
const SUN_SHADOW_NORMAL_BIAS: float = 2.4

# Golden Sunset ("Золотой закат") palette for akasha_sky.gdshader
const SUNSET_SKY_COLORS: Dictionary = {
	"zenith_color": Color("#243E8C"),          # Deep lavender-indigo zenith
	"upper_indigo_color": Color("#5C56A8"),    # Twilight violet-indigo upper vault
	"mid_sky_color": Color("#E89A78"),         # Warm apricot-honey mid sky
	"horizon_warm_color": Color("#FF9B6A"),    # Rich golden-coral sunset horizon
	"horizon_amber_color": Color("#FFD07A"),   # Luminous honey-gold sunset glow
	"horizon_cool_color": Color("#B886B8"),    # Soft dusk rose-lavender opposite sun
	"nadir_color": Color("#967698"),           # Warm twilight rose-plum nadir
	"sun_color": Color("#FFCE7A"),             # Warm golden sunset disk & corona
	"cumulus_shadow_color": Color("#8F6A9A"),  # Mauve-violet cumulus shadow base
	"cumulus_body_color": Color("#F8C9A6"),    # Warm apricot-gold cumulus body
	"cumulus_bounce_color": Color("#FFA66E"),  # Glowing coral-gold bounce light
	"cumulus_rim_color": Color("#FFE6A8"),     # Honey-gold sunlit cumulus rim
	"cloud_shadow_color": Color("#A67EA8"),    # Dusk violet high cloud underside
	"cloud_body_color": Color("#FCD8B8"),      # Warm peach-cream overhead clouds
	"cloud_lit_color": Color("#FFC27C"),       # Golden-apricot sunlit high clouds
}

# Fallback Dawn palette matching akasha_sky.gdshader defaults (used if a uniform wasn't explicitly overridden in .tres)
const DAWN_SKY_COLOR_DEFAULTS: Dictionary = {
	"zenith_color": Color("#164EC2"),
	"upper_indigo_color": Color("#388EF2"),
	"mid_sky_color": Color("#78D2F8"),
	"horizon_warm_color": Color("#FF9EB8"),
	"horizon_amber_color": Color("#FFC294"),
	"horizon_cool_color": Color("#B8A8EA"),
	"nadir_color": Color("#829CD5"),
	"sun_color": Color("#FFF3DA"),
	"cumulus_shadow_color": Color("#909AD0"),
	"cumulus_body_color": Color("#F6ECF6"),
	"cumulus_bounce_color": Color("#FFBEBE"),
	"cumulus_rim_color": Color("#FFFAEC"),
	"cloud_shadow_color": Color("#B5C9F1"),
	"cloud_body_color": Color("#F9FBFF"),
	"cloud_lit_color": Color("#FFE8E7"),
}

const DAWN_SUN_DIR_DEFAULT: Vector3 = Vector3(0.0, 0.16, -1.0)
const SUNSET_SUN_DIR: Vector3 = Vector3(0.14, 0.085, -0.986)

const SUNSET_SUN_COLOR: Color = Color("#FFE0A8")
const SUNSET_SUN_ENERGY: float = 1.68
const SUNSET_SUN_ROT_DEG: Vector3 = Vector3(-13.5, -18.0, 0.0)

const SUNSET_AMBIENT_COLOR: Color = Color("#E6B8A8")
const SUNSET_AMBIENT_ENERGY: float = 0.74
const SUNSET_FOG_ALBEDO: Color = Color("#F8C8B2")
const SUNSET_FOG_EMISSION: Color = Color("#FFB88C")
const SUNSET_FOG_EMISSION_ENERGY: float = 0.036

var _world_env: WorldEnvironment = null
var _env: Environment = null
var _sky_mat: ShaderMaterial = null
var _sun_light: DirectionalLight3D = null
var _cloud_sea: Node3D = null

var _is_setup: bool = false
var _sunset_blend: float = 0.0
var _transition_tween: Tween = null

# Captured Dawn baseline values
var _dawn_sky_colors: Dictionary = {}
var _dawn_sun_dir: Vector3 = DAWN_SUN_DIR_DEFAULT
var _dawn_sun_color: Color = Color(1.0, 0.94, 0.84, 1.0)
var _dawn_sun_energy: float = 1.85
var _dawn_sun_rot: Vector3 = Vector3.ZERO
var _dawn_ambient_color: Color = Color(0.76, 0.82, 0.94, 1.0)
var _dawn_ambient_energy: float = 0.72
var _dawn_fog_albedo: Color = Color(0.96, 0.90, 0.95, 1.0)
var _dawn_fog_emission: Color = Color(0.98, 0.88, 0.90, 1.0)
var _dawn_fog_emission_energy: float = 0.02

# Captured CloudSea materials and their Dawn/Sunset color pairs
var _cloud_mat_entries: Array[Dictionary] = []


## Captures the initial Dawn parameters from WorldEnvironment, SunLight, and CloudSea.
func setup(
	world_env: WorldEnvironment,
	sun_light: DirectionalLight3D,
	cloud_sea: Node3D = null
) -> void:
	_world_env = world_env
	_sun_light = sun_light
	_cloud_sea = cloud_sea

	if _world_env != null and _world_env.environment != null:
		_env = _world_env.environment
		_dawn_ambient_color = _env.ambient_light_color
		_dawn_ambient_energy = _env.ambient_light_energy
		_dawn_fog_albedo = _env.volumetric_fog_albedo
		_dawn_fog_emission = _env.volumetric_fog_emission
		_dawn_fog_emission_energy = _env.volumetric_fog_emission_energy

		if _env.sky != null and _env.sky.sky_material is ShaderMaterial:
			_sky_mat = _env.sky.sky_material as ShaderMaterial
			_capture_dawn_sky_params()

	if _sun_light != null:
		_dawn_sun_color = _sun_light.light_color
		_dawn_sun_energy = _sun_light.light_energy
		_dawn_sun_rot = _sun_light.rotation
		_enforce_sun_shadow_biases()

	_capture_cloud_sea_materials()
	_sunset_blend = 0.0
	_is_setup = true


## Smoothly transitions (or snaps if immediate=true) to the Prologue Dawn preset.
func apply_dawn_preset(immediate: bool = false) -> void:
	if not _is_setup:
		return
	_transition_to(0.0, immediate)


## Smoothly transitions (or snaps if immediate=true) to the Lesson 1 Golden Sunset preset.
func apply_golden_sunset_preset(immediate: bool = false) -> void:
	if not _is_setup:
		return
	_transition_to(1.0, immediate)


## Returns current sunset blend factor (0.0 = Dawn, 1.0 = Golden Sunset).
func get_sunset_blend() -> float:
	return _sunset_blend


# ---------------------------------------------------------------------------
# Internal Capture & Blending
# ---------------------------------------------------------------------------

func _capture_dawn_sky_params() -> void:
	_dawn_sky_colors.clear()
	if _sky_mat == null:
		return

	for key: String in DAWN_SKY_COLOR_DEFAULTS.keys():
		var default_col: Color = DAWN_SKY_COLOR_DEFAULTS[key] as Color
		var raw_val: Variant = _sky_mat.get_shader_parameter(key)
		if raw_val is Color:
			_dawn_sky_colors[key] = raw_val as Color
		else:
			_dawn_sky_colors[key] = default_col

	var raw_dir: Variant = _sky_mat.get_shader_parameter("sun_direction")
	if raw_dir is Vector3 and (raw_dir as Vector3).length_squared() > 0.001:
		_dawn_sun_dir = (raw_dir as Vector3).normalized()
	else:
		_dawn_sun_dir = DAWN_SUN_DIR_DEFAULT.normalized()


func _capture_cloud_sea_materials() -> void:
	_cloud_mat_entries.clear()
	if _cloud_sea == null:
		return

	var seen_mats: Array[ShaderMaterial] = []
	_collect_cloud_materials_recursive(_cloud_sea, seen_mats)

	var cloud_param_tints: Dictionary = {
		"underside_color": Color("#946C96"),
		"shadow_color": Color("#B87E9C"),
		"mid_color": Color("#F6BE9E"),
		"sunlit_color": Color("#FFE4AC"),
		"silver_lining_color": Color("#FFD68A"),
		"horizon_bounce_color": Color("#FFA068"),
	}

	for smat: ShaderMaterial in seen_mats:
		var dawn_map: Dictionary = {}
		var sunset_map: Dictionary = {}
		for param_name: String in cloud_param_tints.keys():
			var raw_col: Variant = smat.get_shader_parameter(param_name)
			if raw_col is Color:
				var d_col: Color = raw_col as Color
				var tint_col: Color = cloud_param_tints[param_name] as Color
				dawn_map[param_name] = d_col
				# Blend original cloud material gently toward warm golden-apricot sunset tones
				sunset_map[param_name] = d_col.lerp(tint_col, 0.72)
		if not dawn_map.is_empty():
			_cloud_mat_entries.append({
				"material": smat,
				"dawn": dawn_map,
				"sunset": sunset_map,
			})


func _collect_cloud_materials_recursive(node: Node, out_mats: Array[ShaderMaterial]) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.material_override is ShaderMaterial:
			var smat: ShaderMaterial = mi.material_override as ShaderMaterial
			if not out_mats.has(smat):
				out_mats.append(smat)
	for child: Node in node.get_children():
		_collect_cloud_materials_recursive(child, out_mats)


func _transition_to(target_blend: float, immediate: bool) -> void:
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()

	var clamped_target: float = clampf(target_blend, 0.0, 1.0)
	if immediate or not is_inside_tree():
		_apply_blend(clamped_target)
		return

	_transition_tween = create_tween()
	_transition_tween.tween_method(
		_apply_blend,
		_sunset_blend,
		clamped_target,
		DEFAULT_TRANSITION_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _apply_blend(t: float) -> void:
	_sunset_blend = clampf(t, 0.0, 1.0)

	# 1. Sky shader uniforms (STRICTLY Color for all source_color uniforms!)
	if _sky_mat != null:
		for key: String in SUNSET_SKY_COLORS.keys():
			var dawn_c: Color = _dawn_sky_colors.get(key, DAWN_SKY_COLOR_DEFAULTS[key]) as Color
			var sunset_c: Color = SUNSET_SKY_COLORS[key] as Color
			_sky_mat.set_shader_parameter(key, dawn_c.lerp(sunset_c, _sunset_blend))

		var blended_sun_dir: Vector3 = _dawn_sun_dir.lerp(SUNSET_SUN_DIR.normalized(), _sunset_blend).normalized()
		_sky_mat.set_shader_parameter("sun_direction", blended_sun_dir)

	# 2. SunLight honey-gold tint & soft lower sunset angle + preserved shadow biases
	if _sun_light != null:
		_sun_light.light_color = _dawn_sun_color.lerp(SUNSET_SUN_COLOR, _sunset_blend)
		_sun_light.light_energy = lerpf(_dawn_sun_energy, SUNSET_SUN_ENERGY, _sunset_blend)
		var target_rot: Vector3 = Vector3(
			deg_to_rad(SUNSET_SUN_ROT_DEG.x),
			deg_to_rad(SUNSET_SUN_ROT_DEG.y),
			deg_to_rad(SUNSET_SUN_ROT_DEG.z)
		)
		_sun_light.rotation = Vector3(
			lerp_angle(_dawn_sun_rot.x, target_rot.x, _sunset_blend),
			lerp_angle(_dawn_sun_rot.y, target_rot.y, _sunset_blend),
			lerp_angle(_dawn_sun_rot.z, target_rot.z, _sunset_blend)
		)
		_enforce_sun_shadow_biases()

	# 3. Environment ambient & warm golden-rose volumetric fog
	if _env != null:
		_env.ambient_light_color = _dawn_ambient_color.lerp(SUNSET_AMBIENT_COLOR, _sunset_blend)
		_env.ambient_light_energy = lerpf(_dawn_ambient_energy, SUNSET_AMBIENT_ENERGY, _sunset_blend)
		_env.volumetric_fog_albedo = _dawn_fog_albedo.lerp(SUNSET_FOG_ALBEDO, _sunset_blend)
		_env.volumetric_fog_emission = _dawn_fog_emission.lerp(SUNSET_FOG_EMISSION, _sunset_blend)
		_env.volumetric_fog_emission_energy = lerpf(_dawn_fog_emission_energy, SUNSET_FOG_EMISSION_ENERGY, _sunset_blend)

	# 4. Soft sunset tint on CloudSea materials (all source_color -> Color)
	for entry: Dictionary in _cloud_mat_entries:
		var smat: ShaderMaterial = entry.get("material", null) as ShaderMaterial
		if smat == null:
			continue
		var dawn_map: Dictionary = entry.get("dawn", {}) as Dictionary
		var sunset_map: Dictionary = entry.get("sunset", {}) as Dictionary
		for param_name: String in dawn_map.keys():
			var d_col: Color = dawn_map[param_name] as Color
			var s_col: Color = sunset_map[param_name] as Color
			smat.set_shader_parameter(param_name, d_col.lerp(s_col, _sunset_blend))


func _enforce_sun_shadow_biases() -> void:
	if _sun_light != null:
		_sun_light.shadow_bias = SUN_SHADOW_BIAS
		_sun_light.shadow_normal_bias = SUN_SHADOW_NORMAL_BIAS
