class_name AkashaGardenDecorator
extends Node3D

## Eden Garden, Reflecting Lakes & Waterfalls Artist for the Akashic Chronicles Prologue.
## Transforms the Starting Monolith Plaza, Twin Flanking Viaducts, 5 Floating Temple Islands,
## and the Colossal Fairytale Castle Sanctuary into a lush sunlit Heavenly Garden Paradise
## while staying locked at 60 FPS on macOS Retina via GPU-instanced MultiMeshInstance3D
## batches (grass tufts, 4-color flowerbeds, lily pads, lotus flowers, cascading ivy vines,
## and fluttering luminous butterflies).

const SAKURA_TREE_PATH: String = "res://assets/models/props/sakura_tree.glb"
const GARDEN_PLANTER_PATH: String = "res://assets/models/props/garden_planter.glb"
const CELESTIAL_ORNAMENT_PATH: String = "res://assets/models/props/celestial_ornament.glb"
const LUSH_BUSH_PATH: String = "res://assets/models/props/lush_bush_hedge.glb"
const BOTANICAL_GRASS_PATH: String = "res://assets/models/props/botanical_grass_clump.glb"
const WATER_SHADER_PATH: String = "res://shaders/akasha_water.gdshader"
const FOLIAGE_SHADER_PATH: String = "res://shaders/akasha_foliage.gdshader"

const ORNAMENT_SWAY_MAX_RAD: float = 0.02617994 # 1.5 degrees in radians

var _sakura_tree_scene: PackedScene = null
var _garden_planter_scene: PackedScene = null
var _celestial_ornament_scene: PackedScene = null
var _lush_bush_scene: PackedScene = null
var _botanical_grass_scene: PackedScene = null
var _water_shader: Shader = null
var _foliage_shader: Shader = null

# Shared lightweight materials
var _mat_leaf_spring: StandardMaterial3D = null
var _mat_leaf_emerald: StandardMaterial3D = null
var _mat_leaf_mint: StandardMaterial3D = null
var _mat_canopy_emerald_deep: StandardMaterial3D = null
var _mat_canopy_emerald_sunlit: StandardMaterial3D = null
var _mat_canopy_flower_accent: StandardMaterial3D = null
var _mat_blossom_pink: StandardMaterial3D = null
var _mat_blossom_blush: StandardMaterial3D = null
var _mat_blossom_lilac: StandardMaterial3D = null
var _mat_bark: StandardMaterial3D = null
var _mat_marble: StandardMaterial3D = null
var _mat_marble_curb: StandardMaterial3D = null
var _mat_moss_border: StandardMaterial3D = null
var _mat_lakebed: StandardMaterial3D = null
var _mat_gold_trim: StandardMaterial3D = null
var _mat_crystal: StandardMaterial3D = null
var _mat_silk: StandardMaterial3D = null
var _mat_water_oval: ShaderMaterial = null
var _mat_water_ring: ShaderMaterial = null
var _mat_grass_mm: Material = null
var _mat_flower_mm: Material = null
var _mat_lily_mm: StandardMaterial3D = null
var _mat_lotus_mm: StandardMaterial3D = null
var _mat_vine_leaf_mm: Material = null
var _mat_vine_blossom_mm: Material = null
var _mat_butterfly_mm: StandardMaterial3D = null
var _enhanced_glb_mats: Dictionary = {}

# Shared lightweight meshes
var _mesh_vine_stem: CylinderMesh = null
var _mesh_leaf_cluster: BoxMesh = null
var _mesh_ivy_leaf_pair: ArrayMesh = null
var _mesh_vine_blossom: ArrayMesh = null
var _mesh_blossom_cluster: SphereMesh = null
var _mesh_blossom_small: SphereMesh = null
var _mesh_grass_tuft: Mesh = null
var _mesh_flower_cluster: ArrayMesh = null
var _mesh_lily_pad: ArrayMesh = null
var _mesh_lotus_flower: ArrayMesh = null
var _mesh_butterfly: ArrayMesh = null

# Batched GPU-instanced transform/color collectors (flushed to MultiMeshInstance3D at end)
var _vine_stem_xforms: Array[Transform3D] = []
var _vine_leaf_xforms: Array[Transform3D] = []
var _vine_leaf_colors: Array[Color] = []
var _vine_blossom_xforms: Array[Transform3D] = []
var _vine_blossom_colors: Array[Color] = []

var _grass_xforms: Array[Transform3D] = []
var _grass_colors: Array[Color] = []
var _flower_xforms: Array[Transform3D] = []
var _flower_colors: Array[Color] = []

var _lily_xforms: Array[Transform3D] = []
var _lily_colors: Array[Color] = []
var _lotus_xforms: Array[Transform3D] = []
var _lotus_colors: Array[Color] = []

# Animated celestial ornaments for gentle wind breathing
var _sway_ornaments: Array[Node3D] = []
var _sway_base_rot: Array[Vector3] = []
var _sway_phases: Array[float] = []

# Animated GPU-instanced butterflies
var _butterfly_mmi: MultiMeshInstance3D = null
var _butterfly_centers: Array[Vector3] = []
var _butterfly_radii: Array[Vector2] = []
var _butterfly_speeds: Array[float] = []
var _butterfly_phases: Array[float] = []
var _butterfly_scales: Array[float] = []

var _elapsed_time: float = 0.0
var _is_populated: bool = false

# Runtime CastleIslandGrass terrain heightfield spatial index (4m x 4m XZ grid)
const MEADOW_GRID_CELL_SIZE: float = 4.0
var _meadow_has_mesh: bool = false
var _meadow_v0: PackedVector3Array = PackedVector3Array()
var _meadow_v1: PackedVector3Array = PackedVector3Array()
var _meadow_v2: PackedVector3Array = PackedVector3Array()
var _meadow_normals: PackedVector3Array = PackedVector3Array()
var _meadow_grid: Dictionary = {}

# Verified grounded Castle lakes (populated at runtime after terrain validation)
var _active_castle_lakes: Array[Dictionary] = []


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_elapsed_time += delta

	# Gentle wind breathing on celestial silk-and-crystal ornaments
	var ornament_count: int = _sway_ornaments.size()
	for i: int in range(ornament_count):
		var ornament: Node3D = _sway_ornaments[i]
		if ornament == null or not is_instance_valid(ornament):
			continue
		var base_rot: Vector3 = _sway_base_rot[i]
		var phase: float = _sway_phases[i]
		var sway_z: float = sin(_elapsed_time * 1.15 + phase) * ORNAMENT_SWAY_MAX_RAD
		var sway_x: float = cos(_elapsed_time * 0.85 + phase * 1.37) * (ORNAMENT_SWAY_MAX_RAD * 0.65)
		ornament.rotation = Vector3(base_rot.x + sway_x, base_rot.y, base_rot.z + sway_z)

	# Smooth fluttering flight for luminous butterflies (single MultiMeshInstance3D draw call)
	if _butterfly_mmi != null and _butterfly_mmi.multimesh != null:
		var mm: MultiMesh = _butterfly_mmi.multimesh
		var b_count: int = _butterfly_centers.size()
		for i: int in range(b_count):
			var center: Vector3 = _butterfly_centers[i]
			var rad: Vector2 = _butterfly_radii[i]
			var spd: float = _butterfly_speeds[i]
			var ph: float = _butterfly_phases[i]
			var sc: float = _butterfly_scales[i]

			var t: float = _elapsed_time * spd + ph
			var px: float = center.x + sin(t) * rad.x
			var pz: float = center.z + sin(t * 2.0 + 0.6) * rad.y * 0.55 + cos(t * 0.7) * rad.y * 0.45
			var py: float = center.y + sin(t * 2.7 + ph * 1.3) * 0.34 + cos(t * 1.4) * 0.14

			# Tangent velocity for natural forward heading
			var vx: float = cos(t) * rad.x * spd
			var vz: float = (cos(t * 2.0 + 0.6) * 2.0 * 0.55 - sin(t * 0.7) * 0.7 * 0.45) * rad.y * spd
			var yaw: float = atan2(vx, vz)

			# Subtle wing-flap squash along X/Y so wings flutter organically
			var flap: float = sin(_elapsed_time * (11.5 + spd * 4.0) + ph * 3.1)
			var wing_x: float = sc * (0.76 + 0.34 * absf(flap))
			var wing_y: float = sc * (0.65 + 0.45 * flap)
			var bank: float = clampf(sin(t) * 0.28, -0.35, 0.35)

			var b_basis: Basis = Basis(Vector3.UP, yaw) * Basis(Vector3.FORWARD, bank)
			b_basis = b_basis.scaled(Vector3(wing_x, maxf(0.28, absf(wing_y)), sc))
			mm.set_instance_transform(i, Transform3D(b_basis, Vector3(px, py, pz)))


## Populates the entire Prologue world with terrain-grounded reflecting turquoise lakes,
## lily pads, lotuses, subtle waterfall mist plumes, verdant & sakura groves, Rotunda potted urns,
## GPU-instanced grass & 4-color flowerbeds, cascading ivy curtains, and serene butterflies.
func populate_garden(architecture: Node3D = null) -> void:
	if _is_populated:
		return
	_is_populated = true

	_load_prop_scenes()
	_init_shared_resources()
	_build_castle_meadow_index(architecture)

	var island_positions: Array[Vector3] = _resolve_island_positions(architecture)

	_decorate_starting_plaza()
	_decorate_twin_viaducts()
	_decorate_floating_islands(island_positions)
	_build_reflecting_lakes_and_ponds(island_positions)
	_decorate_cathedral_sanctuary()
	_build_waterfall_mist_plumes()
	_populate_meadow_grass_and_flowerbeds(architecture)
	_flush_multimesh_batches()
	_build_fluttering_butterflies(island_positions)


func _load_prop_scenes() -> void:
	_sakura_tree_scene = _safe_load_scene(SAKURA_TREE_PATH)
	_garden_planter_scene = _safe_load_scene(GARDEN_PLANTER_PATH)
	_celestial_ornament_scene = _safe_load_scene(CELESTIAL_ORNAMENT_PATH)
	_lush_bush_scene = _safe_load_scene(LUSH_BUSH_PATH)
	_botanical_grass_scene = _safe_load_scene(BOTANICAL_GRASS_PATH)
	if ResourceLoader.exists(WATER_SHADER_PATH):
		var loaded_shader: Resource = load(WATER_SHADER_PATH)
		if loaded_shader is Shader:
			_water_shader = loaded_shader as Shader
	if ResourceLoader.exists(FOLIAGE_SHADER_PATH):
		var loaded_foliage: Resource = load(FOLIAGE_SHADER_PATH)
		if loaded_foliage is Shader:
			_foliage_shader = loaded_foliage as Shader


func _safe_load_scene(res_path: String) -> PackedScene:
	if not ResourceLoader.exists(res_path):
		return null
	var loaded: Resource = load(res_path)
	if loaded is PackedScene:
		return loaded as PackedScene
	return null


func _init_shared_resources() -> void:
	var green_backlight: Color = Color("#68A848")
	var pink_backlight: Color = Color("#FFADC8")

	# Foliage & blossom palette (with soft sunlit subsurface backlight translucency)
	_mat_leaf_spring = _create_botanical_material(Color("#449656"), 0.62, 0.0, Color(0.0, 0.0, 0.0), 0.0)
	_mat_leaf_spring.backlight_enabled = true
	_mat_leaf_spring.backlight = green_backlight
	_mat_leaf_emerald = _create_botanical_material(Color("#2B6E40"), 0.66, 0.0, Color(0.0, 0.0, 0.0), 0.0)
	_mat_leaf_emerald.backlight_enabled = true
	_mat_leaf_emerald.backlight = green_backlight
	_mat_leaf_mint = _create_botanical_material(Color("#6EC274"), 0.56, 0.0, Color(0.0, 0.0, 0.0), 0.0)
	_mat_leaf_mint.backlight_enabled = true
	_mat_leaf_mint.backlight = green_backlight

	# Double-sided sunlit emerald canopy materials for lush green palace tree variants
	_mat_canopy_emerald_deep = _create_botanical_material(Color("#348A49"), 0.58, 0.0, Color(0.0, 0.0, 0.0), 0.0)
	_mat_canopy_emerald_deep.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_canopy_emerald_deep.backlight_enabled = true
	_mat_canopy_emerald_deep.backlight = green_backlight

	_mat_canopy_emerald_sunlit = _create_botanical_material(Color("#54B262"), 0.54, 0.0, Color(0.0, 0.0, 0.0), 0.0)
	_mat_canopy_emerald_sunlit.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_canopy_emerald_sunlit.backlight_enabled = true
	_mat_canopy_emerald_sunlit.backlight = green_backlight

	_mat_canopy_flower_accent = _create_botanical_material(Color("#FFF0F5"), 0.48, 0.0, Color("#FFE6EE"), 0.08)
	_mat_canopy_flower_accent.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_canopy_flower_accent.backlight_enabled = true
	_mat_canopy_flower_accent.backlight = pink_backlight

	_mat_blossom_pink = _create_botanical_material(Color("#F78EB0"), 0.58, 0.0, Color("#F78EB0"), 0.14)
	_mat_blossom_pink.backlight_enabled = true
	_mat_blossom_pink.backlight = pink_backlight
	_mat_blossom_blush = _create_botanical_material(Color("#FFC8D8"), 0.55, 0.0, Color("#FFD6E4"), 0.18)
	_mat_blossom_blush.backlight_enabled = true
	_mat_blossom_blush.backlight = pink_backlight
	_mat_blossom_lilac = _create_botanical_material(Color("#C89EEB"), 0.56, 0.0, Color("#D6B6F5"), 0.16)
	_mat_blossom_lilac.backlight_enabled = true
	_mat_blossom_lilac.backlight = pink_backlight

	# Architectural garden stone, moss, and lakebed materials
	_mat_bark = _create_botanical_material(Color("#6E534B"), 0.85, 0.0, Color(0.0, 0.0, 0.0), 0.0)
	_mat_marble = _create_botanical_material(Color("#EDE6DC"), 0.42, 0.04, Color(0.0, 0.0, 0.0), 0.0)
	_mat_marble_curb = _create_botanical_material(Color("#F5F1EA"), 0.36, 0.04, Color("#FFFDF8"), 0.04)
	_mat_moss_border = _create_botanical_material(Color("#3C8D4E"), 0.82, 0.0, Color(0.0, 0.0, 0.0), 0.0)
	_mat_lakebed = _create_botanical_material(Color("#1A5F78"), 0.65, 0.05, Color("#248FA8"), 0.14)
	_mat_gold_trim = _create_botanical_material(Color("#DFC48E"), 0.36, 0.75, Color("#EDD29A"), 0.12)
	_mat_crystal = _create_botanical_material(Color("#C6E8FF"), 0.18, 0.10, Color("#B8E6FF"), 0.55)
	_mat_silk = _create_botanical_material(Color("#F9D8E6"), 0.52, 0.05, Color("#FFE2EE"), 0.14)

	# Turquoise-Crystal Lake & Pond ShaderMaterials
	_mat_water_oval = _create_water_material(0.0, 0.68, 0.14)
	_mat_water_ring = _create_water_material(1.0, 0.95, 0.22)

	# GPU-instanced MultiMesh botanical ShaderMaterials (wind sway, root-to-tip gradient, upward soft normals, backlight)
	_mat_grass_mm = _create_foliage_material(
		0.085, 0.95, 0.56, 1.24,
		Color(0.78, 0.96, 0.76), Color(1.10, 1.14, 0.82),
		Color(0.58, 0.76, 0.24), 0.74, 0.58,
		0.0, Color(0.0, 0.0, 0.0), 0.0,
		1.0, 0.12, 1.18, 0.18, Color(0.88, 0.98, 0.54)
	)
	_mat_flower_mm = _create_foliage_material(
		0.078, 0.94, 0.55, 1.16,
		Color(0.84, 0.94, 0.84), Color(1.03, 1.02, 1.02),
		Color(0.72, 0.44, 0.52), 0.52, 0.48,
		1.0, Color("#FFE8F4"), 0.09
	)

	_mat_lily_mm = _create_botanical_material(Color(1.0, 1.0, 1.0), 0.44, 0.02, Color(0.0, 0.0, 0.0), 0.0)
	_mat_lily_mm.vertex_color_use_as_albedo = true
	_mat_lily_mm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_lily_mm.backlight_enabled = true
	_mat_lily_mm.backlight = Color("#5AA048")

	_mat_lotus_mm = _create_botanical_material(Color(1.0, 1.0, 1.0), 0.42, 0.0, Color("#FFEBF4"), 0.22)
	_mat_lotus_mm.vertex_color_use_as_albedo = true
	_mat_lotus_mm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_lotus_mm.backlight_enabled = true
	_mat_lotus_mm.backlight = Color("#FFBFD4")

	_mat_vine_leaf_mm = _create_foliage_material(
		0.115, 1.12, 0.60, 1.16,
		Color(0.80, 0.94, 0.82), Color(1.05, 1.08, 0.88),
		Color(0.38, 0.52, 0.22), 0.58, 0.42,
		0.0, Color(0.0, 0.0, 0.0), 0.0
	)
	_mat_vine_blossom_mm = _create_foliage_material(
		0.105, 1.10, 0.78, 1.16,
		Color(0.94, 0.92, 0.95), Color(1.04, 1.02, 1.04),
		pink_backlight, 0.50, 0.46,
		0.0, Color("#FFD8EC"), 0.14
	)

	_mat_butterfly_mm = _create_botanical_material(Color(1.0, 1.0, 1.0), 0.25, 0.05, Color("#FFF4D4"), 0.72)
	_mat_butterfly_mm.vertex_color_use_as_albedo = true
	_mat_butterfly_mm.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Shared lightweight meshes
	_mesh_vine_stem = CylinderMesh.new()
	_mesh_vine_stem.top_radius = 0.026
	_mesh_vine_stem.bottom_radius = 0.018
	_mesh_vine_stem.height = 0.48
	_mesh_vine_stem.radial_segments = 5
	_mesh_vine_stem.rings = 1

	_mesh_leaf_cluster = BoxMesh.new()
	_mesh_leaf_cluster.size = Vector3(0.38, 0.28, 0.34)

	_mesh_blossom_cluster = SphereMesh.new()
	_mesh_blossom_cluster.radius = 0.16
	_mesh_blossom_cluster.height = 0.28
	_mesh_blossom_cluster.radial_segments = 8
	_mesh_blossom_cluster.rings = 5

	_mesh_blossom_small = SphereMesh.new()
	_mesh_blossom_small.radius = 0.11
	_mesh_blossom_small.height = 0.20
	_mesh_blossom_small.radial_segments = 7
	_mesh_blossom_small.rings = 4

	_mesh_grass_tuft = _create_grass_tuft_mesh()
	_mesh_flower_cluster = _create_flower_cluster_mesh()
	_mesh_ivy_leaf_pair = _create_ivy_mesh()
	_mesh_vine_blossom = _create_vine_blossom_mesh()
	_mesh_lily_pad = _create_lily_pad_mesh()
	_mesh_lotus_flower = _create_lotus_flower_mesh()
	_mesh_butterfly = _create_butterfly_mesh()


func _create_foliage_material(
	wind_str: float,
	wind_spd: float,
	base_sh: float,
	tip_br: float,
	base_t: Color,
	tip_t: Color,
	backlight_col: Color,
	rough_v: float,
	norm_up: float,
	stem_mask: float,
	emit_col: Color,
	emit_str: float,
	meadow_daisy_mask: float = 0.0,
	spec_v: float = 0.16,
	backlight_str: float = 1.05,
	velvet_rim: float = 0.12,
	velvet_col: Color = Color(0.84, 0.96, 0.54)
) -> Material:
	if _foliage_shader != null:
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = _foliage_shader
		mat.set_shader_parameter("wind_strength", wind_str)
		mat.set_shader_parameter("wind_speed", wind_spd)
		mat.set_shader_parameter("wind_gust_strength", 0.032)
		mat.set_shader_parameter("sway_root_power", 2.0)
		mat.set_shader_parameter("use_vertex_y_fallback", 0.0)
		mat.set_shader_parameter("base_shade", base_sh)
		mat.set_shader_parameter("tip_bright", tip_br)
		mat.set_shader_parameter("base_tint", base_t)
		mat.set_shader_parameter("tip_tint", tip_t)
		mat.set_shader_parameter("backlight_color", backlight_col)
		mat.set_shader_parameter("backlight_strength", backlight_str)
		mat.set_shader_parameter("roughness_val", rough_v)
		mat.set_shader_parameter("specular_val", spec_v)
		mat.set_shader_parameter("normal_up_blend", norm_up)
		mat.set_shader_parameter("velvet_rim_strength", velvet_rim)
		mat.set_shader_parameter("velvet_rim_color", velvet_col)
		mat.set_shader_parameter("emission_color", emit_col)
		mat.set_shader_parameter("emission_strength", emit_str)
		mat.set_shader_parameter("stem_mask_enabled", stem_mask)
		mat.set_shader_parameter("meadow_daisy_mask_enabled", meadow_daisy_mask)
		mat.set_shader_parameter("stem_base_color", Color("#28743A"))
		mat.set_shader_parameter("stem_tip_color", Color("#58B85E"))
		mat.set_shader_parameter("pollen_color", Color("#FFDC52"))
		return mat

	var fallback: StandardMaterial3D = _create_botanical_material(Color(1.0, 1.0, 1.0), rough_v, 0.0, emit_col, emit_str)
	fallback.vertex_color_use_as_albedo = true
	fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
	fallback.backlight_enabled = true
	fallback.backlight = backlight_col
	return fallback


func _create_water_material(ring_mode_val: float, wave_scale_val: float, foam_w: float) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	if _water_shader != null:
		mat.shader = _water_shader
		mat.set_shader_parameter("shallow_color", Color("#7CE8F0"))
		mat.set_shader_parameter("mid_color", Color("#2AA8B8"))
		mat.set_shader_parameter("deep_color", Color("#1E7A96"))
		mat.set_shader_parameter("sky_reflect_color", Color("#D8F2FF"))
		mat.set_shader_parameter("foam_color", Color("#F2FCFF"))
		mat.set_shader_parameter("caustic_color", Color("#9EF5FA"))
		mat.set_shader_parameter("water_alpha", 0.84)
		mat.set_shader_parameter("wave_speed", 0.42)
		mat.set_shader_parameter("wave_scale", wave_scale_val)
		mat.set_shader_parameter("normal_strength", 0.14)
		mat.set_shader_parameter("fresnel_power", 3.2)
		mat.set_shader_parameter("fresnel_strength", 0.62)
		mat.set_shader_parameter("sparkle_strength", 0.90)
		mat.set_shader_parameter("caustic_strength", 0.26)
		mat.set_shader_parameter("foam_width", foam_w)
		mat.set_shader_parameter("ring_mode", ring_mode_val)
	return mat


func _create_botanical_material(
	albedo: Color,
	roughness_val: float,
	metallic_val: float,
	emission_col: Color,
	emission_strength: float
) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = roughness_val
	mat.metallic = metallic_val
	if emission_strength > 0.0:
		mat.emission_enabled = true
		mat.emission = emission_col
		mat.emission_energy_multiplier = emission_strength
	return mat


# ---------------------------------------------------------------------------
# 1. Starting Monolith Plaza (z = 24..46, deck at y = 0.0)
# ---------------------------------------------------------------------------

func _decorate_starting_plaza() -> void:
	var root: Node3D = Node3D.new()
	root.name = "PlazaGarden"
	add_child(root)

	# 6 lush trees framing the plaza: 2 pink Sakura at rear corners, 2 verdant mid-flanks, 2 leaning forward emerald trees
	# Base embedded 4cm into the y = 0.0 stone deck and inset inside X = +-7.0 balustrades
	_place_sakura_tree(root, "PlazaSakura_L", Vector3(-6.0, -0.04, 44.4), deg_to_rad(-34.0), 1.02)
	_place_sakura_tree(root, "PlazaSakura_R", Vector3(6.0, -0.04, 44.4), deg_to_rad(34.0), 1.02)

	_place_verdant_tree(root, "PlazaVerdantMid_L", Vector3(-6.2, -0.04, 36.4), deg_to_rad(-72.0), 0.90)
	_place_verdant_tree(root, "PlazaVerdantMid_R", Vector3(6.2, -0.04, 36.4), deg_to_rad(72.0), 0.90)

	var plaza_green_l: Node3D = _place_verdant_tree(
		root, "PlazaVerdantTree_L", Vector3(-6.1, -0.04, 28.8), deg_to_rad(-118.0), 0.84
	)
	plaza_green_l.rotation.z = deg_to_rad(9.0)
	var plaza_green_r: Node3D = _place_verdant_tree(
		root, "PlazaVerdantTree_R", Vector3(6.1, -0.04, 28.8), deg_to_rad(118.0), 0.84
	)
	plaza_green_r.rotation.z = deg_to_rad(-9.0)

	# 16 lush rose-and-emerald bush hedges lining BOTH balustrades (center walkway 100% clear)
	var plaza_bush_z: Array[float] = [25.2, 28.2, 32.5, 34.8, 37.0, 39.4, 42.2, 44.8]
	var plaza_bush_scales: Array[float] = [0.92, 0.86, 0.94, 0.96, 0.90, 0.88, 0.96, 0.92]
	for i: int in range(plaza_bush_z.size()):
		var z_val: float = plaza_bush_z[i]
		var sc: float = plaza_bush_scales[i]
		var yaw_jitter: float = deg_to_rad(6.0 if i % 2 == 0 else -6.0)
		_place_lush_bush(
			root,
			"PlazaBush_L_%02d" % i,
			Vector3(-6.25, -0.02, z_val),
			deg_to_rad(90.0) + yaw_jitter,
			sc
		)
		_place_lush_bush(
			root,
			"PlazaBush_R_%02d" % i,
			Vector3(6.25, -0.02, z_val),
			deg_to_rad(-90.0) - yaw_jitter,
			sc
		)

	# 6 carved blooming marble planters along the balustrades (clear of lanterns at z = 41 and z = 27)
	_place_garden_planter(root, "PlazaPlanter_NW", Vector3(-6.0, -0.03, 38.2), deg_to_rad(90.0), 1.04)
	_place_garden_planter(root, "PlazaPlanter_NE", Vector3(6.0, -0.03, 38.2), deg_to_rad(-90.0), 1.04)
	_place_garden_planter(root, "PlazaPlanter_MidW", Vector3(-6.0, -0.03, 34.0), deg_to_rad(90.0), 0.98)
	_place_garden_planter(root, "PlazaPlanter_MidE", Vector3(6.0, -0.03, 34.0), deg_to_rad(-90.0), 0.98)
	_place_garden_planter(root, "PlazaPlanter_SW", Vector3(-6.0, -0.03, 30.6), deg_to_rad(90.0), 1.04)
	_place_garden_planter(root, "PlazaPlanter_SE", Vector3(6.0, -0.03, 30.6), deg_to_rad(-90.0), 1.04)

	# 4 celestial silk-and-crystal floral archways framing both the rear arrival & forward ceremonial prow
	_place_celestial_ornament(root, "PlazaOrnament_ProwL", Vector3(-4.8, -0.03, 23.2), deg_to_rad(68.0), 1.04, 0.0)
	_place_celestial_ornament(root, "PlazaOrnament_ProwR", Vector3(4.8, -0.03, 23.2), deg_to_rad(-68.0), 1.04, 1.8)
	_place_celestial_ornament(root, "PlazaOrnament_RearL", Vector3(-5.2, -0.03, 44.8), deg_to_rad(118.0), 0.96, 3.1)
	_place_celestial_ornament(root, "PlazaOrnament_RearR", Vector3(5.2, -0.03, 44.8), deg_to_rad(-118.0), 0.96, 4.7)

	# Lush cascading emerald ivy & flowering garlands along both plaza sides AND the prow (GPU-instanced)
	var z_slots: int = 24
	for side_idx: int in range(2):
		var side_sign: float = -1.0 if side_idx == 0 else 1.0
		var edge_x: float = side_sign * 8.0
		var outward_dir: Vector3 = Vector3(side_sign, 0.0, 0.0)
		for i: int in range(z_slots):
			var t: float = float(i) / float(z_slots - 1)
			var z_pos: float = lerpf(24.2, 45.4, t)
			var seed_val: float = float(side_idx * 17 + i * 7 + 3)
			var drop_len: float = 2.1 + fmod(seed_val * 0.6180339, 1.0) * 2.9
			_append_vine_garland(
				Vector3(edge_x, -0.1, z_pos),
				outward_dir,
				drop_len,
				side_idx * 40 + i
			)

	# Cascading ivy & blossom garlands draping off both flanks of the forward ceremonial prow
	var prow_anchors: Array[Vector3] = [
		Vector3(-7.4, -0.1, 24.0),
		Vector3(-6.3, -0.1, 23.6),
		Vector3(-5.2, -0.1, 23.2),
		Vector3(-4.0, -0.1, 22.9),
		Vector3(4.0, -0.1, 22.9),
		Vector3(5.2, -0.1, 23.2),
		Vector3(6.3, -0.1, 23.6),
		Vector3(7.4, -0.1, 24.0),
	]
	for p_idx: int in range(prow_anchors.size()):
		var anchor_pt: Vector3 = prow_anchors[p_idx]
		var side_x: float = -0.35 if anchor_pt.x < 0.0 else 0.35
		var prow_out: Vector3 = Vector3(side_x, 0.0, -1.0).normalized()
		var prow_drop: float = 2.0 + fmod(float(p_idx * 13 + 5) * 0.6180339, 1.0) * 2.4
		_append_vine_garland(anchor_pt, prow_out, prow_drop, 80 + p_idx)


# ---------------------------------------------------------------------------
# 1b. Symmetrical Twin Flanking Celestial Viaducts (x = -56.0 & +56.0, deck y = 13.95)
# ---------------------------------------------------------------------------

func _decorate_twin_viaducts() -> void:
	var root: Node3D = Node3D.new()
	root.name = "TwinViaductsGarden"
	add_child(root)

	# Verified viaduct_arch.glb roadway top surface is Y = 13.95; embed bases 2cm at 13.93 for zero gap
	var deck_y: float = 13.93
	var planter_zs: Array[float] = [8.0, -24.0, -56.0, -88.0, -120.0, -152.0, -184.0, -216.0]
	var tree_zs: Array[float] = [-8.0, -48.0, -96.0, -144.0, -192.0, -226.0]
	var bush_zs: Array[float] = [2.0, -16.0, -36.0, -68.0, -108.0, -136.0, -168.0, -204.0]
	var ornament_zs: Array[float] = [-28.0, -106.0, -180.0]

	for side_idx: int in range(2):
		var side_sign: float = -1.0 if side_idx == 0 else 1.0
		var side_tag: String = "W" if side_sign < 0.0 else "E"
		var inward_dir: Vector3 = Vector3(-side_sign, 0.0, 0.0)
		var planter_x: float = side_sign * 52.4
		var tree_x: float = side_sign * 54.4
		var bush_x: float = side_sign * 52.8
		var vine_x: float = side_sign * 50.85
		var yaw_inward: float = deg_to_rad(90.0 if side_sign < 0.0 else -90.0)

		for i: int in range(planter_zs.size()):
			var pz: float = planter_zs[i]
			_place_garden_planter(
				root,
				"ViaductPlanter_%s_%02d" % [side_tag, i],
				Vector3(planter_x, deck_y, pz),
				yaw_inward,
				1.08
			)

		for t_idx: int in range(tree_zs.size()):
			var tz: float = tree_zs[t_idx]
			var t_scale: float = 0.96 + fmod(float(side_idx * 5 + t_idx * 3 + 1) * 0.37, 1.0) * 0.24
			if t_idx % 2 == 0:
				_place_verdant_tree(
					root,
					"ViaductVerdant_%s_%02d" % [side_tag, t_idx],
					Vector3(tree_x, deck_y, tz),
					yaw_inward + deg_to_rad(18.0 if t_idx % 3 == 0 else -18.0),
					t_scale
				)
			else:
				_place_sakura_tree(
					root,
					"ViaductSakura_%s_%02d" % [side_tag, t_idx],
					Vector3(tree_x, deck_y, tz),
					yaw_inward + deg_to_rad(-16.0),
					t_scale
				)

		for b_idx: int in range(bush_zs.size()):
			_place_lush_bush(
				root,
				"ViaductBush_%s_%02d" % [side_tag, b_idx],
				Vector3(bush_x, deck_y, bush_zs[b_idx]),
				yaw_inward,
				1.02
			)

		for o_idx: int in range(ornament_zs.size()):
			_place_celestial_ornament(
				root,
				"ViaductOrnament_%s_%02d" % [side_tag, o_idx],
				Vector3(side_sign * 52.0, deck_y, ornament_zs[o_idx]),
				yaw_inward,
				1.05,
				float(side_idx * 3 + o_idx) * 1.4
			)

		# Dense cascading emerald ivy curtains along the full 240m viaduct inner ledge
		var vine_count: int = 20
		for j: int in range(vine_count):
			var frac: float = float(j) / float(vine_count - 1)
			var vz: float = lerpf(12.0, -234.0, frac)
			var drop_len: float = 2.8 + fmod(float(side_idx * 13 + j * 7 + 2) * 0.6180339, 1.0) * 3.0
			_append_vine_garland(
				Vector3(vine_x, 13.85, vz),
				inward_dir,
				drop_len,
				300 + side_idx * 30 + j
			)


# ---------------------------------------------------------------------------
# 2. Five Floating Temple Islands (Strictly grounded inside temple_island.glb R = 7.71m deck!)
# ---------------------------------------------------------------------------

func _decorate_floating_islands(island_positions: Array[Vector3]) -> void:
	var root: Node3D = Node3D.new()
	root.name = "FloatingIslandsGarden"
	add_child(root)

	# 5 trees per island (2 pink Sakura + 3 lush emerald park trees) keeping all 4 cardinal approaches clear
	# Verified temple_island.glb flat deck radius = 7.71m (outer terraced rim = 8.18m) for ALL 5 islands!
	var sakura_angles_deg: Array[float] = [44.0, 224.0]
	var verdant_angles_deg: Array[float] = [134.0, 306.0, 326.0]
	var planter_angles_deg: Array[float] = [116.0, 206.0, 294.0]
	var bush_angles_deg: Array[float] = [24.0, 64.0, 112.0, 154.0, 202.0, 246.0, 290.0, 338.0]
	var bush_radii: Array[float] = [6.25, 6.20, 6.30, 6.20, 6.25, 6.30, 6.20, 6.25]

	for idx: int in range(island_positions.size()):
		var center: Vector3 = island_positions[idx]
		var island_node: Node3D = Node3D.new()
		island_node.name = "IslandGarden_%02d" % idx
		root.add_child(island_node)

		for t_idx: int in range(sakura_angles_deg.size()):
			var angle_rad: float = deg_to_rad(sakura_angles_deg[t_idx])
			var r_tree: float = 5.65
			var offset: Vector3 = Vector3(cos(angle_rad) * r_tree, -0.04, sin(angle_rad) * r_tree)
			var face_inward_yaw: float = atan2(-offset.x, -offset.z) + deg_to_rad(14.0 if t_idx == 0 else -14.0)
			var scale_factor: float = 0.90 + fmod(float(idx * 3 + t_idx * 5 + 1) * 0.37, 1.0) * 0.22
			_place_sakura_tree(
				island_node,
				"Island_%02d_Sakura_%d" % [idx, t_idx],
				center + offset,
				face_inward_yaw,
				scale_factor
			)

		for g_idx: int in range(verdant_angles_deg.size()):
			var green_angle: float = deg_to_rad(verdant_angles_deg[g_idx])
			var r_green: float = 5.85 if g_idx < 2 else 6.15
			var green_offset: Vector3 = Vector3(cos(green_angle) * r_green, -0.04, sin(green_angle) * r_green)
			var green_yaw: float = atan2(-green_offset.x, -green_offset.z) + deg_to_rad(-16.0 + float(g_idx) * 14.0)
			var green_scale: float = 0.86 + fmod(float(idx * 7 + g_idx * 4 + 2) * 0.41, 1.0) * 0.22
			_place_verdant_tree(
				island_node,
				"Island_%02d_VerdantTree_%d" % [idx, g_idx],
				center + green_offset,
				green_yaw,
				green_scale
			)

		# 8 lush rose-and-emerald bushes ringing the outer perimeter (strictly inside R = 7.71m stone deck)
		for b_idx: int in range(bush_angles_deg.size()):
			var b_angle: float = deg_to_rad(bush_angles_deg[b_idx])
			var b_rad: float = bush_radii[b_idx]
			var b_offset: Vector3 = Vector3(cos(b_angle) * b_rad, -0.02, sin(b_angle) * b_rad)
			var b_yaw: float = atan2(-b_offset.x, -b_offset.z)
			var b_scale: float = 0.86 + fmod(float(idx * 5 + b_idx * 3 + 1) * 0.29, 1.0) * 0.20
			_place_lush_bush(
				island_node,
				"Island_%02d_Bush_%d" % [idx, b_idx],
				center + b_offset,
				b_yaw,
				b_scale
			)

		# 3 blooming marble garden planters at diagonal bays
		for p_idx: int in range(planter_angles_deg.size()):
			var angle_rad: float = deg_to_rad(planter_angles_deg[p_idx])
			var p_rad: float = 5.55
			var offset: Vector3 = Vector3(cos(angle_rad) * p_rad, -0.03, sin(angle_rad) * p_rad)
			var face_inward_yaw: float = atan2(-offset.x, -offset.z)
			_place_garden_planter(
				island_node,
				"Island_%02d_Planter_%d" % [idx, p_idx],
				center + offset,
				face_inward_yaw,
				0.98
			)

		# 2 celestial silk-and-crystal floral archways on opposite diagonal rims
		var orn_angles: Array[float] = [128.0, 308.0]
		for o_idx: int in range(orn_angles.size()):
			var orn_angle: float = deg_to_rad(orn_angles[o_idx])
			var orn_rad: float = 6.15
			var orn_offset: Vector3 = Vector3(cos(orn_angle) * orn_rad, -0.03, sin(orn_angle) * orn_rad)
			var orn_yaw: float = atan2(-orn_offset.x, -orn_offset.z)
			_place_celestial_ornament(
				island_node,
				"Island_%02d_Ornament_%d" % [idx, o_idx],
				center + orn_offset,
				orn_yaw,
				1.02,
				float(idx * 2 + o_idx) * 1.35 + 0.7
			)

		# 14 dense cascading emerald ivy curtains hugging the actual R = 8.18m island stone rim
		var phase_deg: float = float(idx) * 18.0
		var rim_r: float = 8.05
		for v_idx: int in range(14):
			var v_angle: float = deg_to_rad(float(v_idx) * (360.0 / 14.0) + phase_deg)
			var out_dir: Vector3 = Vector3(cos(v_angle), 0.0, sin(v_angle))
			var anchor: Vector3 = center + Vector3(out_dir.x * rim_r, -0.2, out_dir.z * rim_r)
			var drop_seed: float = float(idx * 11 + v_idx * 5 + 2)
			var main_drop: float = 4.2 + fmod(drop_seed * 0.6180339, 1.0) * 4.0
			_append_vine_garland(anchor, out_dir, main_drop, idx * 51 + v_idx * 3)

			var tangent: Vector3 = Vector3(-out_dir.z, 0.0, out_dir.x)
			var side_anchor: Vector3 = anchor + tangent * 0.62
			var side_drop: float = clampf(main_drop * 0.68, 2.3, 5.6)
			_append_vine_garland(side_anchor, out_dir, side_drop, idx * 51 + v_idx * 3 + 1)


func _resolve_island_positions(architecture: Node3D) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	if architecture != null and architecture.has_method("get_island_positions"):
		var raw_positions: Variant = architecture.call("get_island_positions")
		if raw_positions is Array:
			var arr: Array = raw_positions as Array
			for item: Variant in arr:
				if item is Vector3:
					positions.append(item as Vector3)
	if positions.is_empty():
		positions = _get_default_island_positions()
	return positions


func _get_default_island_positions() -> Array[Vector3]:
	var defaults: Array[Vector3] = [
		Vector3(-28.0, 3.5, -36.0),
		Vector3(28.0, 3.5, -36.0),
		Vector3(0.0, 6.5, -106.0),
		Vector3(-34.0, 9.5, -176.0),
		Vector3(34.0, 9.5, -176.0),
	]
	return defaults


# ---------------------------------------------------------------------------
# 2b. Exact Runtime CastleIslandGrass Heightfield Spatial Index & Validators
# ---------------------------------------------------------------------------

func _build_castle_meadow_index(architecture: Node3D) -> void:
	_meadow_has_mesh = false
	_meadow_v0 = PackedVector3Array()
	_meadow_v1 = PackedVector3Array()
	_meadow_v2 = PackedVector3Array()
	_meadow_normals = PackedVector3Array()
	_meadow_grid.clear()

	var grass_mi: MeshInstance3D = _find_castle_island_grass_mesh(architecture)
	if grass_mi == null or grass_mi.mesh == null:
		return

	var faces: PackedVector3Array = grass_mi.mesh.get_faces()
	var tri_count: int = int(floorf(float(faces.size()) / 3.0))
	if tri_count <= 0:
		return

	var xform: Transform3D = grass_mi.global_transform
	var cell_inv: float = 1.0 / MEADOW_GRID_CELL_SIZE

	for t_idx: int in range(tri_count):
		var base_i: int = t_idx * 3
		var w0: Vector3 = xform * faces[base_i]
		var w1: Vector3 = xform * faces[base_i + 1]
		var w2: Vector3 = xform * faces[base_i + 2]
		var e1: Vector3 = w1 - w0
		var e2: Vector3 = w2 - w0
		var cross_v: Vector3 = e1.cross(e2)
		var area2: float = cross_v.length()
		if area2 < 0.0005:
			continue
		var n: Vector3 = cross_v / area2
		if n.y < 0.0:
			n = -n

		var stored_idx: int = _meadow_v0.size()
		_meadow_v0.append(w0)
		_meadow_v1.append(w1)
		_meadow_v2.append(w2)
		_meadow_normals.append(n)

		var min_x: float = minf(w0.x, minf(w1.x, w2.x))
		var max_x: float = maxf(w0.x, maxf(w1.x, w2.x))
		var min_z: float = minf(w0.z, minf(w1.z, w2.z))
		var max_z: float = maxf(w0.z, maxf(w1.z, w2.z))

		var cx0: int = int(floorf(min_x * cell_inv))
		var cx1: int = int(floorf(max_x * cell_inv))
		var cz0: int = int(floorf(min_z * cell_inv))
		var cz1: int = int(floorf(max_z * cell_inv))

		for gx: int in range(cx0, cx1 + 1):
			for gz: int in range(cz0, cz1 + 1):
				var key: Vector2i = Vector2i(gx, gz)
				if not _meadow_grid.has(key):
					var bucket: PackedInt32Array = PackedInt32Array()
					bucket.append(stored_idx)
					_meadow_grid[key] = bucket
				else:
					var existing: PackedInt32Array = _meadow_grid[key] as PackedInt32Array
					existing.append(stored_idx)
					_meadow_grid[key] = existing

	_meadow_has_mesh = (_meadow_v0.size() > 0)


func _sample_castle_meadow_height(wx: float, wz: float) -> Dictionary:
	if not _meadow_has_mesh:
		return {"valid": false, "y": 0.0, "normal": Vector3.UP}

	var gx: int = int(floorf(wx / MEADOW_GRID_CELL_SIZE))
	var gz: int = int(floorf(wz / MEADOW_GRID_CELL_SIZE))
	var key: Vector2i = Vector2i(gx, gz)
	if not _meadow_grid.has(key):
		return {"valid": false, "y": 0.0, "normal": Vector3.UP}

	var bucket: PackedInt32Array = _meadow_grid[key] as PackedInt32Array
	var found: bool = false
	var best_y: float = -10000.0
	var best_n: Vector3 = Vector3.UP

	for k: int in range(bucket.size()):
		var ti: int = bucket[k]
		var v0: Vector3 = _meadow_v0[ti]
		var v1: Vector3 = _meadow_v1[ti]
		var v2: Vector3 = _meadow_v2[ti]

		var denom: float = (v1.z - v2.z) * (v0.x - v2.x) + (v2.x - v1.x) * (v0.z - v2.z)
		if absf(denom) < 0.000001:
			continue
		var inv_d: float = 1.0 / denom
		var w0: float = ((v1.z - v2.z) * (wx - v2.x) + (v2.x - v1.x) * (wz - v2.z)) * inv_d
		var w1: float = ((v2.z - v0.z) * (wx - v2.x) + (v0.x - v2.x) * (wz - v2.z)) * inv_d
		var w2: float = 1.0 - w0 - w1
		if w0 >= -0.0002 and w1 >= -0.0002 and w2 >= -0.0002:
			var hit_y: float = w0 * v0.y + w1 * v1.y + w2 * v2.y
			if not found or hit_y > best_y:
				found = true
				best_y = hit_y
				best_n = _meadow_normals[ti]

	return {"valid": found, "y": best_y, "normal": best_n}


func _is_inside_palace_stone_footprint(wx: float, wz: float, pad: float = 0.0) -> bool:
	# Arrival Court (X[-14.5..+14.5], Z[-240..-224])
	if absf(wx) <= 14.5 + pad and wz >= -240.0 - pad and wz <= -224.0 + pad:
		return true
	# South Grand Imperial Staircase (X[-14..+14], Z[-260..-240])
	if absf(wx) <= 14.0 + pad and wz >= -260.0 - pad and wz <= -240.0 + pad:
		return true
	# Main Baroque Palace, Ballroom & East/West Wings (X[-36.8..+36.8], Z[-297.5..-260])
	if absf(wx) <= 36.8 + pad and wz >= -297.5 - pad and wz <= -260.0 + pad:
		return true
	# North Cloud Terrace rectangular neck (X[-15..+15], Z[-305..-296])
	if absf(wx) <= 15.0 + pad and wz >= -305.0 - pad and wz <= -296.0 + pad:
		return true
	# North Cloud Terrace semicircular apse (center (0, -304), R = 11.2m)
	if wz <= -304.0:
		var dz_apse: float = wz + 304.0
		var dist_apse: float = sqrt(wx * wx + dz_apse * dz_apse)
		if dist_apse <= 11.2 + pad:
			return true
	return false


func _has_safe_meadow_margin(wx: float, wz: float, margin_r: float, min_normal_y: float = 0.78) -> Dictionary:
	if not _meadow_has_mesh:
		return {"valid": false, "y": 0.0, "normal": Vector3.UP}
	if _is_inside_palace_stone_footprint(wx, wz, 1.0):
		return {"valid": false, "y": 0.0, "normal": Vector3.UP}

	var center_hit: Dictionary = _sample_castle_meadow_height(wx, wz)
	if not bool(center_hit["valid"]):
		return {"valid": false, "y": 0.0, "normal": Vector3.UP}
	var c_n: Vector3 = center_hit["normal"] as Vector3
	var c_y: float = float(center_hit["y"])
	if c_n.y < min_normal_y or c_y < -0.95:
		return {"valid": false, "y": 0.0, "normal": Vector3.UP}

	for k: int in range(8):
		var a: float = (TAU / 8.0) * float(k)
		var rx: float = wx + cos(a) * margin_r
		var rz: float = wz + sin(a) * margin_r
		var r_hit: Dictionary = _sample_castle_meadow_height(rx, rz)
		if not bool(r_hit["valid"]):
			return {"valid": false, "y": 0.0, "normal": Vector3.UP}
		var r_n: Vector3 = r_hit["normal"] as Vector3
		var r_y: float = float(r_hit["y"])
		if r_n.y < min_normal_y or r_y < -1.08:
			return {"valid": false, "y": 0.0, "normal": Vector3.UP}

	return center_hit


func _validate_castle_lake(cx: float, cz: float, rx: float, rz: float, margin_r: float = 3.0) -> Dictionary:
	if not _meadow_has_mesh:
		return {"valid": false}
	if _is_inside_palace_stone_footprint(cx, cz, 0.5):
		return {"valid": false}

	var c_hit: Dictionary = _sample_castle_meadow_height(cx, cz)
	if not bool(c_hit["valid"]):
		return {"valid": false}
	var c_n: Vector3 = c_hit["normal"] as Vector3
	if c_n.y < 0.78:
		return {"valid": false}

	var min_y: float = float(c_hit["y"])
	var max_y: float = min_y

	# Sample interior, curb rim (+1.2m), and outer meadow cliff margin (+margin_r)
	var ring_offsets: Array[float] = [0.0, 1.2, margin_r]
	for r_idx: int in range(ring_offsets.size()):
		var pad: float = ring_offsets[r_idx]
		for k: int in range(24):
			var a: float = (TAU / 24.0) * float(k)
			var lobe: float = _oval_lobe_factor(a)
			var px: float = cx + cos(a) * (rx * lobe + pad)
			var pz: float = cz + sin(a) * (rz * lobe + pad)
			if pad <= 1.2 and _is_inside_palace_stone_footprint(px, pz, 0.35):
				return {"valid": false}
			var h: Dictionary = _sample_castle_meadow_height(px, pz)
			if not bool(h["valid"]):
				return {"valid": false}
			var hn: Vector3 = h["normal"] as Vector3
			if hn.y < 0.78:
				return {"valid": false}
			var hy: float = float(h["y"])
			if pad <= 1.2:
				min_y = minf(min_y, hy)
				max_y = maxf(max_y, hy)

	var span: float = max_y - min_y
	if span > 1.35:
		return {"valid": false}

	return {
		"valid": true,
		"water_y": max_y + 0.06,
		"min_y": min_y,
		"max_y": max_y,
		"skirt_depth": maxf(0.85, span + 0.65),
	}


# ---------------------------------------------------------------------------
# 3. Walkable Fairytale Castle Eden Grove, Rotunda Urns & Verified Terrace Props (z = -280)
# ---------------------------------------------------------------------------

func _decorate_cathedral_sanctuary() -> void:
	var root: Node3D = Node3D.new()
	root.name = "CathedralSanctuaryGarden"
	add_child(root)

	# -----------------------------------------------------------------------
	# 3a. Terrain-Grounded Botanical Grove around the Palace & Reflecting Lakes
	# EVERY tree is validated against CastleIslandGrass with >= 4.0m cliff margin
	# and its roots are embedded 12cm into exact terrain Y (zero floating!).
	# -----------------------------------------------------------------------
	var castle_trees: Array[Dictionary] = [
		# Front courtyard meadows flanking the two Lotus Pools & Arrival Court
		{"x": -16.8, "z": -249.0, "yaw": 26.0, "sc": 1.16, "sakura": true},
		{"x": 16.8, "z": -249.0, "yaw": -26.0, "sc": 1.16, "sakura": true},
		{"x": -32.2, "z": -249.5, "yaw": 44.0, "sc": 1.28, "sakura": false},
		{"x": 31.8, "z": -250.5, "yaw": -44.0, "sc": 1.28, "sakura": false},
		{"x": -38.0, "z": -254.0, "yaw": 54.0, "sc": 1.34, "sakura": true},
		{"x": 37.8, "z": -254.5, "yaw": -54.0, "sc": 1.34, "sakura": true},
		{"x": -42.6, "z": -258.5, "yaw": 62.0, "sc": 1.38, "sakura": false},
		{"x": 43.2, "z": -258.5, "yaw": -62.0, "sc": 1.38, "sakura": false},
		# Flanking West & East Castle Garden Lakes (pulled cleanly inside cliff rim >= 4.0m margin)
		{"x": -41.5, "z": -262.8, "yaw": 68.0, "sc": 1.36, "sakura": false},
		{"x": 41.8, "z": -264.0, "yaw": -68.0, "sc": 1.36, "sakura": false},
		{"x": 52.8, "z": -271.5, "yaw": -84.0, "sc": 1.32, "sakura": true},
		{"x": 53.5, "z": -280.0, "yaw": -92.0, "sc": 1.40, "sakura": false},
		{"x": 52.2, "z": -289.2, "yaw": -108.0, "sc": 1.34, "sakura": true},
		{"x": -44.5, "z": -288.5, "yaw": 106.0, "sc": 1.34, "sakura": true},
		{"x": -42.5, "z": -295.8, "yaw": 118.0, "sc": 1.38, "sakura": false},
		{"x": 42.5, "z": -295.8, "yaw": -118.0, "sc": 1.38, "sakura": false},
		{"x": -36.2, "z": -299.6, "yaw": 132.0, "sc": 1.32, "sakura": true},
		{"x": 36.2, "z": -299.6, "yaw": -132.0, "sc": 1.32, "sakura": true},
		# Rear North-Flank Botanical Grove framing the North Cloud Horizon Terrace (verified solid meadow)
		{"x": -28.5, "z": -302.5, "yaw": 146.0, "sc": 1.34, "sakura": false},
		{"x": 28.5, "z": -302.5, "yaw": -146.0, "sc": 1.34, "sakura": false},
		{"x": -21.5, "z": -306.5, "yaw": 158.0, "sc": 1.26, "sakura": true},
		{"x": 21.5, "z": -306.5, "yaw": -158.0, "sc": 1.26, "sakura": true},
		{"x": -28.0, "z": -314.0, "yaw": 162.0, "sc": 1.28, "sakura": false},
		{"x": 27.0, "z": -314.0, "yaw": -162.0, "sc": 1.28, "sakura": false},
		# Front Arrival Meadow flanking the base of the grand staircase
		{"x": -20.4, "z": -242.5, "yaw": 24.0, "sc": 1.20, "sakura": false},
		{"x": 20.4, "z": -242.5, "yaw": -24.0, "sc": 1.20, "sakura": false},
		{"x": -28.5, "z": -243.5, "yaw": 36.0, "sc": 1.24, "sakura": true},
		{"x": 28.5, "z": -244.5, "yaw": -36.0, "sc": 1.24, "sakura": true},
		{"x": -34.5, "z": -246.5, "yaw": 48.0, "sc": 1.26, "sakura": false},
		{"x": 34.5, "z": -248.5, "yaw": -48.0, "sc": 1.26, "sakura": false},
	]
	for i: int in range(castle_trees.size()):
		var spec: Dictionary = castle_trees[i]
		var wx: float = float(spec["x"])
		var wz: float = float(spec["z"])
		if _is_inside_any_castle_lake(wx, wz, 2.2):
			continue
		var ground: Dictionary = _has_safe_meadow_margin(wx, wz, 4.0, 0.78)
		if not bool(ground["valid"]):
			continue
		var grounded_pos: Vector3 = Vector3(wx, float(ground["y"]) - 0.12, wz)
		var yaw: float = deg_to_rad(float(spec["yaw"]))
		var sc: float = float(spec["sc"])
		var is_sakura: bool = bool(spec["sakura"])
		if is_sakura:
			_place_sakura_tree(root, "CastleGroveSakura_%02d" % i, grounded_pos, yaw, sc)
		else:
			_place_verdant_tree(root, "CastleGroveVerdant_%02d" % i, grounded_pos, yaw, sc)

	# -----------------------------------------------------------------------
	# 3b. Terrain-Grounded Meadow Hedges + Verified Stone Terrace Hedges
	# -----------------------------------------------------------------------
	var meadow_hedges: Array[Dictionary] = [
		# Flanking arrival court & lower meadow around Lotus Pools
		{"x": -16.8, "z": -242.5, "yaw": 90.0, "sc": 1.10},
		{"x": 16.8, "z": -242.5, "yaw": -90.0, "sc": 1.10},
		{"x": -17.2, "z": -248.0, "yaw": 90.0, "sc": 1.10},
		{"x": 17.2, "z": -248.0, "yaw": -90.0, "sc": 1.10},
		{"x": -19.2, "z": -245.5, "yaw": 6.0, "sc": 1.14},
		{"x": 19.2, "z": -245.5, "yaw": -6.0, "sc": 1.14},
		{"x": -30.0, "z": -246.2, "yaw": -5.0, "sc": 1.16},
		{"x": 30.0, "z": -246.8, "yaw": 5.0, "sc": 1.16},
		{"x": -35.5, "z": -250.2, "yaw": 18.0, "sc": 1.16},
		{"x": 35.5, "z": -250.2, "yaw": -18.0, "sc": 1.16},
		# Flanking West & East Castle Garden Lakeshores
		{"x": -40.2, "z": -261.2, "yaw": 34.0, "sc": 1.18},
		{"x": 40.2, "z": -261.2, "yaw": -34.0, "sc": 1.18},
		{"x": 52.0, "z": -275.5, "yaw": -88.0, "sc": 1.18},
		{"x": 52.0, "z": -284.8, "yaw": -92.0, "sc": 1.18},
		{"x": -40.0, "z": -294.0, "yaw": 136.0, "sc": 1.18},
		{"x": 40.0, "z": -294.0, "yaw": -136.0, "sc": 1.18},
	]
	for h_idx: int in range(meadow_hedges.size()):
		var h_spec: Dictionary = meadow_hedges[h_idx]
		var hx: float = float(h_spec["x"])
		var hz: float = float(h_spec["z"])
		if _is_inside_any_castle_lake(hx, hz, 1.5):
			continue
		var h_ground: Dictionary = _has_safe_meadow_margin(hx, hz, 3.0, 0.78)
		if not bool(h_ground["valid"]):
			continue
		_place_lush_bush(
			root,
			"CathedralMeadowHedge_%02d" % h_idx,
			Vector3(hx, float(h_ground["y"]) - 0.10, hz),
			deg_to_rad(float(h_spec["yaw"])),
			float(h_spec["sc"])
		)

	# Verified solid Y = 8.0 North Cloud Terrace flank hedges (well clear of balustrades)
	_place_lush_bush(root, "NorthTerraceHedge_W", Vector3(-11.8, 8.0, -301.2), deg_to_rad(90.0), 0.98)
	_place_lush_bush(root, "NorthTerraceHedge_E", Vector3(11.8, 8.0, -301.2), deg_to_rad(-90.0), 0.98)

	# -----------------------------------------------------------------------
	# 3c. Rotunda Interior Potted Greenery & Marble Urns (beside the 16 marble columns!)
	# All coordinates verified on solid Y = 8.0 Ballroom floor & > 1.1m clear of walls/jambs.
	# -----------------------------------------------------------------------
	var rotunda_root: Node3D = Node3D.new()
	rotunda_root.name = "RotundaInteriorGreenery"
	root.add_child(rotunda_root)

	var rotunda_center: Vector3 = Vector3(0.0, 8.0, -280.0)
	var rotunda_urn_angles_deg: Array[float] = [
		22.5, 45.0, 67.5,
		112.5, 135.0, 157.5,
		202.5, 225.0, 247.5,
		292.5, 315.0, 337.5,
	]
	for u_idx: int in range(rotunda_urn_angles_deg.size()):
		var ang_rad: float = deg_to_rad(rotunda_urn_angles_deg[u_idx])
		var r_urn: float = 15.4 if (u_idx % 3 == 1) else 14.0
		var u_pos: Vector3 = rotunda_center + Vector3(cos(ang_rad) * r_urn, -0.02, sin(ang_rad) * r_urn)
		var face_center: float = atan2(-cos(ang_rad), -sin(ang_rad))
		if u_idx % 2 == 0:
			_place_rotunda_potted_urn(rotunda_root, "RotundaFernUrn_%02d" % u_idx, u_pos, face_center, 1.08)
		else:
			_place_garden_planter(rotunda_root, "RotundaMarblePlanter_%02d" % u_idx, u_pos, face_center, 0.96)

	# -----------------------------------------------------------------------
	# 3d. Blooming Marble Planters & Urns (Verified Meadow Ground + Verified Y = 8.0 Stone Terrace)
	# -----------------------------------------------------------------------
	var meadow_planters: Array[Dictionary] = [
		{"x": -16.2, "z": -238.5, "yaw": 90.0, "sc": 1.12},
		{"x": 16.2, "z": -238.5, "yaw": -90.0, "sc": 1.12},
		{"x": -16.5, "z": -245.0, "yaw": 90.0, "sc": 1.12},
		{"x": 16.5, "z": -245.0, "yaw": -90.0, "sc": 1.12},
	]
	for mp_idx: int in range(meadow_planters.size()):
		var mp: Dictionary = meadow_planters[mp_idx]
		var mpx: float = float(mp["x"])
		var mpz: float = float(mp["z"])
		var mp_ground: Dictionary = _has_safe_meadow_margin(mpx, mpz, 2.5, 0.78)
		if not bool(mp_ground["valid"]):
			continue
		_place_garden_planter(
			root,
			"CathedralMeadowPlanter_%02d" % mp_idx,
			Vector3(mpx, float(mp_ground["y"]) - 0.12, mpz),
			deg_to_rad(float(mp["yaw"])),
			float(mp["sc"])
		)

	# Verified solid Y = 8.0 North Cloud Terrace stone planters & urns (strictly clear of balustrades)
	var terrace_planters: Array[Dictionary] = [
		{"pos": Vector3(-12.0, 7.98, -299.5), "yaw": 90.0, "sc": 1.06},
		{"pos": Vector3(12.0, 7.98, -299.5), "yaw": -90.0, "sc": 1.06},
		{"pos": Vector3(-11.6, 7.98, -302.6), "yaw": 105.0, "sc": 1.04},
		{"pos": Vector3(11.6, 7.98, -302.6), "yaw": -105.0, "sc": 1.04},
		{"pos": Vector3(-6.8, 7.98, -307.8), "yaw": 135.0, "sc": 1.02},
		{"pos": Vector3(6.8, 7.98, -307.8), "yaw": -135.0, "sc": 1.02},
		{"pos": Vector3(-4.0, 7.98, -311.0), "yaw": 160.0, "sc": 1.00},
		{"pos": Vector3(4.0, 7.98, -311.0), "yaw": -160.0, "sc": 1.00},
	]
	for tp_idx: int in range(terrace_planters.size()):
		var tp: Dictionary = terrace_planters[tp_idx]
		var tp_pos: Vector3 = tp["pos"] as Vector3
		var tp_yaw: float = deg_to_rad(float(tp["yaw"]))
		var tp_sc: float = float(tp["sc"])
		if tp_idx % 2 == 0:
			_place_rotunda_potted_urn(root, "TerraceBloomUrn_%02d" % tp_idx, tp_pos, tp_yaw, tp_sc)
		else:
			_place_garden_planter(root, "TerracePlanter_%02d" % tp_idx, tp_pos, tp_yaw, tp_sc)

	# 6 celestial silk-and-crystal floral archways — ALL verified on solid Y = 8.0 stone & clear of walls
	_place_celestial_ornament(root, "SanctuaryOrnament_SouthDiagL", Vector3(-13.2, 7.98, -266.6), deg_to_rad(64.0), 1.12, 0.5)
	_place_celestial_ornament(root, "SanctuaryOrnament_SouthDiagR", Vector3(13.2, 7.98, -266.6), deg_to_rad(-64.0), 1.12, 2.2)
	_place_celestial_ornament(root, "SanctuaryOrnament_NorthDiagL", Vector3(-13.2, 7.98, -293.4), deg_to_rad(118.0), 1.12, 3.6)
	_place_celestial_ornament(root, "SanctuaryOrnament_NorthDiagR", Vector3(13.2, 7.98, -293.4), deg_to_rad(-118.0), 1.12, 5.1)
	_place_celestial_ornament(root, "NorthTerraceOrnament_L", Vector3(-8.2, 7.98, -305.5), deg_to_rad(145.0), 1.04, 1.4)
	_place_celestial_ornament(root, "NorthTerraceOrnament_R", Vector3(8.2, 7.98, -305.5), deg_to_rad(-145.0), 1.04, 4.2)


# ---------------------------------------------------------------------------
# 4. Terrain-Validated Reflecting Lakes, Lotus Pools & Central Sky-Island Pond Ring
# ---------------------------------------------------------------------------

func _build_reflecting_lakes_and_ponds(island_positions: Array[Vector3]) -> void:
	var root: Node3D = Node3D.new()
	root.name = "ReflectingLakesAndPonds"
	add_child(root)

	_active_castle_lakes.clear()

	# Candidate Castle Meadow Lakes — EVERY lake is verified at runtime against CastleIslandGrass
	# with >= 3.0m solid meadow margin around its ENTIRE perimeter and seated at exact terrain height!
	var lake_candidates: Array[Dictionary] = [
		{"name": "WestCastleGardenLake", "cx": -43.8, "cz": -274.0, "rx": 5.0, "rz": 7.8, "lilies": 22, "lotuses": 9, "seed": 101},
		{"name": "EastCastleGardenLake", "cx": 44.5, "cz": -277.0, "rx": 5.4, "rz": 7.8, "lilies": 22, "lotuses": 9, "seed": 202},
		{"name": "WestCourtyardLotusPool", "cx": -24.5, "cz": -251.0, "rx": 4.6, "rz": 4.0, "lilies": 14, "lotuses": 6, "seed": 303},
		{"name": "EastCourtyardLotusPool", "cx": 22.8, "cz": -253.5, "rx": 4.2, "rz": 3.6, "lilies": 14, "lotuses": 6, "seed": 404},
	]

	for cand: Dictionary in lake_candidates:
		var cx: float = float(cand["cx"])
		var cz: float = float(cand["cz"])
		var rx: float = float(cand["rx"])
		var rz: float = float(cand["rz"])
		var check: Dictionary = _validate_castle_lake(cx, cz, rx, rz, 3.0)
		if not bool(check["valid"]):
			continue
		var water_y: float = float(check["water_y"])
		var skirt_depth: float = float(check["skirt_depth"])
		_create_sculpted_oval_lake(
			root,
			String(cand["name"]),
			Vector3(cx, water_y, cz),
			rx,
			rz,
			int(cand["lilies"]),
			int(cand["lotuses"]),
			int(cand["seed"]),
			skirt_depth
		)
		_active_castle_lakes.append({
			"name": String(cand["name"]),
			"cx": cx,
			"cz": cz,
			"y": water_y,
			"rx": rx,
			"rz": rz,
		})

	# Central Sky-Island Sanctuary Pond Ring on the Central Axial Island (0.0, 6.53, -106.0)
	var central_island: Vector3 = Vector3(0.0, 6.5, -106.0)
	if island_positions.size() >= 3:
		central_island = island_positions[2]
	_create_sanctuary_pond_ring(
		root,
		"CentralIslandPondRing",
		Vector3(central_island.x, central_island.y + 0.03, central_island.z),
		3.45,
		5.15,
		22,
		9
	)


func _create_sculpted_oval_lake(
	parent: Node3D,
	lake_name: String,
	center: Vector3,
	rx: float,
	rz: float,
	lily_count: int,
	lotus_count: int,
	seed_offset: int,
	skirt_depth: float = 1.2
) -> void:
	var lake: Node3D = Node3D.new()
	lake.name = lake_name
	lake.position = center
	parent.add_child(lake)

	# Grounded teal-marble lakebed slightly beneath water surface
	var bed_inst: MeshInstance3D = MeshInstance3D.new()
	bed_inst.name = "Lakebed"
	bed_inst.mesh = _create_oval_water_mesh(rx * 1.01, rz * 1.01, 44, 4)
	bed_inst.material_override = _mat_lakebed
	bed_inst.position = Vector3(0.0, -0.14, 0.0)
	bed_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lake.add_child(bed_inst)

	# Shimmering Turquoise-Crystal water surface
	var water_inst: MeshInstance3D = MeshInstance3D.new()
	water_inst.name = "WaterSurface"
	water_inst.mesh = _create_oval_water_mesh(rx, rz, 48, 8)
	water_inst.material_override = _mat_water_oval
	water_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lake.add_child(water_inst)

	# Carved white-marble curb ring with deep retaining skirt extending cleanly into the meadow soil
	var curb_inst: MeshInstance3D = MeshInstance3D.new()
	curb_inst.name = "MarbleCurbRing"
	curb_inst.mesh = _create_oval_curb_mesh(rx, rz, 0.56, 0.24, 48, skirt_depth)
	curb_inst.material_override = _mat_marble_curb
	curb_inst.position = Vector3(0.0, -0.04, 0.0)
	lake.add_child(curb_inst)

	# Lush emerald moss outer rim hugging the marble curb and anchoring into the meadow slope
	var moss_inst: MeshInstance3D = MeshInstance3D.new()
	moss_inst.name = "MossBorderRing"
	moss_inst.mesh = _create_oval_curb_mesh(rx + 0.52, rz + 0.52, 0.78, 0.12, 48, skirt_depth)
	moss_inst.material_override = _mat_moss_border
	moss_inst.position = Vector3(0.0, -0.06, 0.0)
	moss_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lake.add_child(moss_inst)

	# Populate floating emerald lily pads & blooming pink/pearl lotuses (batched to MultiMesh)
	var lily_palette: Array[Color] = [
		Color("#2F8A4E"),
		Color("#3FA258"),
		Color("#267542"),
		Color("#52B466"),
	]
	var lotus_palette: Array[Color] = [
		Color("#FF9CC2"), # Soft rose-pink lotus
		Color("#FFF8FC"), # Pearl-white lotus
		Color("#FFC4DC"), # Blush sakura lotus
		Color("#FFEAF4"), # Creamy pearl lotus
	]

	for i: int in range(lily_count):
		var a: float = float(i) * 2.3999632 + float(seed_offset) * 0.37 # Golden angle spiral
		var r_frac: float = sqrt((float(i) + 0.5) / float(lily_count)) * 0.80
		var lobe: float = _oval_lobe_factor(a)
		var lx: float = cos(a) * rx * r_frac * lobe
		var lz: float = sin(a) * rz * r_frac * lobe
		var pad_scale: float = 0.72 + _hash01(seed_offset * 31 + i * 13) * 0.78
		var pad_yaw: float = _hash01(seed_offset * 19 + i * 7) * TAU
		var pad_basis: Basis = Basis(Vector3.UP, pad_yaw).scaled(Vector3(pad_scale, 1.0, pad_scale))
		_lily_xforms.append(Transform3D(pad_basis, center + Vector3(lx, 0.032, lz)))
		_lily_colors.append(lily_palette[(i + seed_offset) % lily_palette.size()])

		# Place blooming lotus flowers on selected lily pads so they float naturally
		if i < lotus_count:
			var l_scale: float = 0.78 + _hash01(seed_offset * 47 + i * 17) * 0.52
			var l_yaw: float = _hash01(seed_offset * 29 + i * 11) * TAU
			var l_basis: Basis = Basis(Vector3.UP, l_yaw).scaled(Vector3(l_scale, l_scale, l_scale))
			_lotus_xforms.append(Transform3D(l_basis, center + Vector3(lx, 0.055, lz)))
			_lotus_colors.append(lotus_palette[(i + seed_offset) % lotus_palette.size()])

	# Ultra-gentle, sparse sunlit surface sparkles right above the water (zero sky clutter)
	_add_water_sparkle_mist(lake, Vector3(rx * 0.58, 0.08, rz * 0.58), 5 if rx > 4.8 else 4)


func _create_sanctuary_pond_ring(
	parent: Node3D,
	ring_name: String,
	center: Vector3,
	r_inner: float,
	r_outer: float,
	lily_count: int,
	lotus_count: int
) -> void:
	var pond: Node3D = Node3D.new()
	pond.name = ring_name
	pond.position = center
	parent.add_child(pond)

	var bed_inst: MeshInstance3D = MeshInstance3D.new()
	bed_inst.name = "RingLakebed"
	bed_inst.mesh = _create_ring_water_mesh(r_inner - 0.05, r_outer + 0.05, 48, 2)
	bed_inst.material_override = _mat_lakebed
	bed_inst.position = Vector3(0.0, -0.04, 0.0)
	bed_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pond.add_child(bed_inst)

	var water_inst: MeshInstance3D = MeshInstance3D.new()
	water_inst.name = "RingWaterSurface"
	water_inst.mesh = _create_ring_water_mesh(r_inner, r_outer, 56, 5)
	water_inst.material_override = _mat_water_ring
	water_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pond.add_child(water_inst)

	# Inner and outer carved marble curb rings
	var inner_curb: MeshInstance3D = MeshInstance3D.new()
	inner_curb.name = "InnerMarbleCurb"
	inner_curb.mesh = _create_ring_curb_mesh(r_inner - 0.14, 0.28, 0.16, 48)
	inner_curb.material_override = _mat_marble_curb
	inner_curb.position = Vector3(0.0, -0.02, 0.0)
	pond.add_child(inner_curb)

	var outer_curb: MeshInstance3D = MeshInstance3D.new()
	outer_curb.name = "OuterMarbleCurb"
	outer_curb.mesh = _create_ring_curb_mesh(r_outer + 0.16, 0.32, 0.18, 48)
	outer_curb.material_override = _mat_marble_curb
	outer_curb.position = Vector3(0.0, -0.02, 0.0)
	pond.add_child(outer_curb)

	var lily_palette: Array[Color] = [Color("#349452"), Color("#48B064"), Color("#2A7E46")]
	var lotus_palette: Array[Color] = [Color("#FFA4C8"), Color("#FFF9FD"), Color("#FFD0E4")]
	for i: int in range(lily_count):
		var a: float = (TAU / float(lily_count)) * float(i) + _hash01(501 + i) * 0.22
		var r_pos: float = lerpf(r_inner + 0.38, r_outer - 0.38, _hash01(601 + i * 7))
		var lx: float = cos(a) * r_pos
		var lz: float = sin(a) * r_pos
		var pad_scale: float = 0.62 + _hash01(701 + i * 11) * 0.45
		var pad_basis: Basis = Basis(Vector3.UP, a * 1.7).scaled(Vector3(pad_scale, 1.0, pad_scale))
		_lily_xforms.append(Transform3D(pad_basis, center + Vector3(lx, 0.028, lz)))
		_lily_colors.append(lily_palette[i % lily_palette.size()])

		var lotus_idx: int = int(floorf(float(i) * 0.5))
		if i % 2 == 0 and lotus_idx < lotus_count:
			var l_scale: float = 0.70 + _hash01(801 + i * 13) * 0.38
			var l_basis: Basis = Basis(Vector3.UP, a).scaled(Vector3(l_scale, l_scale, l_scale))
			_lotus_xforms.append(Transform3D(l_basis, center + Vector3(lx, 0.048, lz)))
			_lotus_colors.append(lotus_palette[lotus_idx % lotus_palette.size()])

	_add_water_sparkle_mist(pond, Vector3(r_outer * 0.68, 0.08, r_outer * 0.68), 4)


func _add_water_sparkle_mist(parent: Node3D, box_extents: Vector3, amount: int) -> void:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "WaterSparkleMist"
	particles.amount = amount
	particles.lifetime = 3.2
	particles.preprocess = 1.2
	particles.position = Vector3(0.0, 0.10, 0.0)
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var proc: ParticleProcessMaterial = ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc.emission_box_extents = box_extents
	proc.direction = Vector3(0.0, 1.0, 0.0)
	proc.spread = 16.0
	proc.initial_velocity_min = 0.06
	proc.initial_velocity_max = 0.14
	proc.gravity = Vector3(0.0, 0.01, 0.0)
	proc.scale_min = 0.45
	proc.scale_max = 0.85
	proc.color = Color(0.92, 0.98, 1.0, 0.38)
	particles.process_material = proc

	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.14, 0.14)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_color = Color(0.86, 0.96, 1.0, 0.24)
	mat.albedo_texture = _create_soft_radial_texture(32)
	quad.material = mat

	particles.draw_pass_1 = quad
	parent.add_child(particles)


# ---------------------------------------------------------------------------
# 5. Subtle Waterfall Mist Plumes (Aligned to Actual Palace_CastleWaterfall Lips)
# ---------------------------------------------------------------------------

func _build_waterfall_mist_plumes() -> void:
	var root: Node3D = Node3D.new()
	root.name = "WaterfallMistPlumes"
	add_child(root)

	var mist_tex: ImageTexture = _create_soft_radial_texture(64)
	var mist_mat: StandardMaterial3D = StandardMaterial3D.new()
	mist_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mist_mat.albedo_color = Color(0.88, 0.97, 1.0, 0.20)
	mist_mat.albedo_texture = mist_tex
	mist_mat.vertex_color_use_as_albedo = true

	var mist_quad: QuadMesh = QuadMesh.new()
	mist_quad.size = Vector2(2.8, 2.8)
	mist_quad.material = mist_mat

	# Verified world coordinates of the 4 actual Palace_CastleWaterfall cliff lips in akasha_cathedral.glb
	var waterfall_coords: Array[Vector3] = [
		Vector3(-48.5, -0.8, -240.5),
		Vector3(43.8, -0.8, -244.0),
		Vector3(-44.0, -0.8, -323.5),
		Vector3(40.5, -0.8, -319.0),
	]

	for idx: int in range(waterfall_coords.size()):
		var plume: GPUParticles3D = GPUParticles3D.new()
		plume.name = "WaterfallMistPlume_%02d" % idx
		plume.position = waterfall_coords[idx]
		plume.amount = 10
		plume.lifetime = 3.6
		plume.preprocess = 1.5
		plume.visibility_aabb = AABB(Vector3(-8.0, -8.0, -8.0), Vector3(16.0, 14.0, 16.0))
		plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var proc: ParticleProcessMaterial = ParticleProcessMaterial.new()
		proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		proc.emission_sphere_radius = 1.8
		proc.direction = Vector3(0.0, 0.55, 0.25 if idx < 2 else -0.35).normalized()
		proc.spread = 38.0
		proc.initial_velocity_min = 0.40
		proc.initial_velocity_max = 0.95
		proc.gravity = Vector3(0.0, -0.22, 0.0)
		proc.damping_min = 0.30
		proc.damping_max = 0.55
		proc.scale_min = 0.70
		proc.scale_max = 1.45

		var grad: Gradient = Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.28, 0.72, 1.0])
		grad.colors = PackedColorArray([
			Color(0.84, 0.98, 1.0, 0.0),
			Color(0.88, 0.98, 1.0, 0.42),
			Color(0.82, 0.96, 1.0, 0.24),
			Color(0.92, 0.99, 1.0, 0.0),
		])
		var grad_tex: GradientTexture1D = GradientTexture1D.new()
		grad_tex.gradient = grad
		proc.color_ramp = grad_tex

		plume.process_material = proc
		plume.draw_pass_1 = mist_quad
		root.add_child(plume)


# ---------------------------------------------------------------------------
# 6. GPU-Instanced Velvety Meadow Grass & Daisies (STRICTLY on CastleIslandGrass!)
#    Zero grass on solid stone (Plaza, Viaducts, 5 Floating Islands, Marble Apron,
#    Grand Staircase, or Baroque Palace interior marble floors) and ZERO floating grass!
# ---------------------------------------------------------------------------

func _find_castle_island_grass_mesh(node: Node) -> MeshInstance3D:
	if node == null:
		return null
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.name.contains("CastleIslandGrass"):
			return mi
		if mi.mesh != null:
			var sc: int = mi.mesh.get_surface_count()
			for s: int in range(sc):
				var mat: Material = mi.mesh.surface_get_material(s)
				if mat != null and mat.resource_name.contains("CastleIslandGrass"):
					return mi
	for child: Node in node.get_children():
		var found: MeshInstance3D = _find_castle_island_grass_mesh(child)
		if found != null:
			return found
	return null


func _is_excluded_from_castle_meadow(wx: float, wy: float, wz: float) -> bool:
	if _is_inside_palace_stone_footprint(wx, wz, 0.4):
		return true
	if wy < -0.95 or wy > 3.2:
		return true
	if _is_inside_any_castle_lake(wx, wz, 1.25):
		return true
	return false


func _basis_aligned_to_normal(up_dir: Vector3, yaw: float) -> Basis:
	var n: Vector3 = up_dir.normalized()
	var fwd_ref: Vector3 = Vector3(sin(yaw), 0.0, cos(yaw))
	var right: Vector3 = n.cross(fwd_ref)
	if right.length_squared() < 0.0001:
		right = n.cross(Vector3.RIGHT)
	right = right.normalized()
	var fwd: Vector3 = right.cross(n).normalized()
	return Basis(right, n, fwd)


func _populate_meadow_grass_and_flowerbeds(architecture: Node3D = null) -> void:
	# Subtle sunlit daylight variations so baked deep-emerald-to-lime-gold grass blades shimmer
	# organically across rolling hills while tiny white/periwinkle daisies stay pure & luminous!
	var grass_palette: Array[Color] = [
		Color(0.94, 1.00, 0.92), # Lush sunlit emerald-meadow
		Color(1.00, 1.02, 0.95), # Pure sunlit daylight patch
		Color(1.05, 1.04, 0.90), # Warm golden-sunlit hilltop
		Color(0.90, 0.98, 0.93), # Cool velvet shaded meadow
		Color(0.98, 1.04, 0.93), # Fresh bright spring carpet
	]
	var meadow_wind_yaw: float = 0.28

	# 4-Color Heavenly Flowerbed Palette: Sakura-Pink, Lavender, Sky-Blue Hydrangea, Creamy Jasmine & Buttercup
	var flower_palette: Array[Color] = [
		Color("#F98EB6"), # Blush sakura-pink rose
		Color("#FFB8D4"), # Soft petal pink
		Color("#BC94F2"), # Soft lavender
		Color("#D2B6FA"), # Pale lilac-lavender
		Color("#74C6FA"), # Sky-blue hydrangea
		Color("#A4DEFF"), # Celestial baby-blue
		Color("#FFF8E8"), # Creamy white jasmine
		Color("#FFE074"), # Sunlit golden buttercup
	]

	var seed_id: int = 1000
	var grass_mi: MeshInstance3D = _find_castle_island_grass_mesh(architecture)

	# A. Primary Path: Sample dense velvety sunlit grass carpet directly onto CastleIslandGrass rolling hills
	if grass_mi != null and grass_mi.mesh != null:
		var faces: PackedVector3Array = grass_mi.mesh.get_faces()
		var tri_count: int = int(floorf(float(faces.size()) / 3.0))
		var xform: Transform3D = grass_mi.global_transform
		var tri_v0: Array[Vector3] = []
		var tri_v1: Array[Vector3] = []
		var tri_v2: Array[Vector3] = []
		var tri_norms: Array[Vector3] = []
		var cum_areas: Array[float] = []
		var total_area: float = 0.0

		for t_idx: int in range(tri_count):
			var base_i: int = t_idx * 3
			var w0: Vector3 = xform * faces[base_i]
			var w1: Vector3 = xform * faces[base_i + 1]
			var w2: Vector3 = xform * faces[base_i + 2]
			var e1: Vector3 = w1 - w0
			var e2: Vector3 = w2 - w0
			var cross_v: Vector3 = e1.cross(e2)
			var area2: float = cross_v.length()
			if area2 < 0.02:
				continue
			var n: Vector3 = cross_v / area2
			if n.y < 0.0:
				n = -n
			# Only upward-facing rolling green meadow hills (skip sheer cliffs & rim lips)
			if n.y < 0.72:
				continue
			var centroid: Vector3 = (w0 + w1 + w2) / 3.0
			if centroid.y < -0.95 or centroid.y > 3.2:
				continue
			if _is_excluded_from_castle_meadow(centroid.x, centroid.y, centroid.z):
				continue

			total_area += area2 * 0.5
			tri_v0.append(w0)
			tri_v1.append(w1)
			tri_v2.append(w2)
			tri_norms.append(n)
			cum_areas.append(total_area)

		var valid_tris: int = cum_areas.size()
		if valid_tris > 0 and total_area > 1.0:
			var target_tufts: int = 2450
			for i: int in range(target_tufts):
				seed_id += 1
				var target_a: float = _hash01(seed_id * 17 + 3) * total_area
				var lo: int = 0
				var hi: int = valid_tris - 1
				while lo < hi:
					var mid: int = int(floorf(float(lo + hi) * 0.5))
					if cum_areas[mid] < target_a:
						lo = mid + 1
					else:
						hi = mid

				var r1: float = sqrt(_hash01(seed_id * 29 + 7))
				var r2: float = _hash01(seed_id * 37 + 11)
				var u_bary: float = 1.0 - r1
				var v_bary: float = r1 * (1.0 - r2)
				var w_bary: float = r1 * r2
				var pt: Vector3 = tri_v0[lo] * u_bary + tri_v1[lo] * v_bary + tri_v2[lo] * w_bary

				if _is_excluded_from_castle_meadow(pt.x, pt.y, pt.z):
					continue

				var hill_n: Vector3 = tri_norms[lo]
				var soft_up: Vector3 = Vector3.UP.lerp(hill_n, 0.42).normalized()
				var yaw: float = meadow_wind_yaw + (_hash01(seed_id * 13) - 0.5) * 0.92
				var sc: float = 1.05 + _hash01(seed_id * 41) * 0.58
				var sy: float = sc * (0.84 + _hash01(seed_id * 43) * 0.34)
				var g_basis_m: Basis = _basis_aligned_to_normal(soft_up, yaw).scaled(Vector3(sc, sy, sc))
				# Embed root 4cm into green turf so tufts never float on curved slopes
				_grass_xforms.append(Transform3D(g_basis_m, pt - Vector3(0.0, 0.04, 0.0)))
				_grass_colors.append(grass_palette[seed_id % grass_palette.size()])

				# Plant colorful formal garden flowerbeds on flatter sunlit meadow zones
				if hill_n.y >= 0.84 and pt.y >= -0.35 and _hash01(seed_id * 53 + 11) < 0.24:
					var f_sc: float = 0.78 + _hash01(seed_id * 71) * 0.64
					var f_basis: Basis = _basis_aligned_to_normal(soft_up, yaw + 0.9).scaled(Vector3(f_sc, f_sc, f_sc))
					var zone_idx: int = int(absf(floorf(pt.x * 0.18) + floorf(pt.z * 0.16))) % 4
					var col_idx: int = zone_idx * 2 + (seed_id % 2)
					_flower_xforms.append(Transform3D(f_basis, pt - Vector3(0.0, 0.02, 0.0)))
					_flower_colors.append(flower_palette[col_idx])

	# B. Dedicated Terrain-Grounded Lakeshore Rings around all verified active Castle Lakes
	for l_idx: int in range(_active_castle_lakes.size()):
		var ls: Dictionary = _active_castle_lakes[l_idx]
		var cx: float = float(ls["cx"])
		var cz: float = float(ls["cz"])
		var rx: float = float(ls["rx"])
		var rz: float = float(ls["rz"])
		var cnt: int = 84 if rx > 4.8 else 64
		for k: int in range(cnt):
			seed_id += 1
			var ang: float = (TAU / float(cnt)) * float(k) + _hash01(seed_id * 11) * 0.08
			var lobe: float = _oval_lobe_factor(ang)
			var shore_pad: float = 1.45 + _hash01(seed_id * 19) * 1.45
			var sx: float = cx + cos(ang) * (rx * lobe + shore_pad)
			var sz: float = cz + sin(ang) * (rz * lobe + shore_pad)

			var shore_hit: Dictionary = _sample_castle_meadow_height(sx, sz)
			if not bool(shore_hit["valid"]):
				continue
			var shore_n: Vector3 = shore_hit["normal"] as Vector3
			var shore_y: float = float(shore_hit["y"])
			if shore_n.y < 0.78 or _is_excluded_from_castle_meadow(sx, shore_y, sz):
				continue

			var shore_up: Vector3 = Vector3.UP.lerp(shore_n, 0.42).normalized()
			var g_yaw: float = meadow_wind_yaw + (_hash01(seed_id * 17) - 0.5) * 0.90
			var sc: float = 0.98 + _hash01(seed_id * 23) * 0.48
			var g_basis: Basis = _basis_aligned_to_normal(shore_up, g_yaw).scaled(Vector3(sc, sc * 0.96, sc))
			_grass_xforms.append(Transform3D(g_basis, Vector3(sx, shore_y - 0.04, sz)))
			_grass_colors.append(grass_palette[seed_id % grass_palette.size()])

			var f_sc: float = 0.78 + _hash01(seed_id * 31) * 0.60
			var f_basis: Basis = _basis_aligned_to_normal(shore_up, ang * 1.4 + 0.5).scaled(Vector3(f_sc, f_sc, f_sc))
			var shore_col_idx: int = (int(floorf(float(k) / 3.0)) + l_idx * 2) % flower_palette.size()
			_flower_xforms.append(Transform3D(f_basis, Vector3(sx, shore_y - 0.02, sz)))
			_flower_colors.append(flower_palette[shore_col_idx])


func _is_inside_any_castle_lake(x: float, z: float, margin: float) -> bool:
	for lake_info: Dictionary in _active_castle_lakes:
		var cx: float = float(lake_info["cx"])
		var cz: float = float(lake_info["cz"])
		var rx: float = float(lake_info["rx"]) + margin
		var rz: float = float(lake_info["rz"]) + margin
		var dx: float = (x - cx) / maxf(0.1, rx)
		var dz: float = (z - cz) / maxf(0.1, rz)
		if dx * dx + dz * dz < 1.0:
			return true
	return false


func _flush_multimesh_batches() -> void:
	var root: Node3D = Node3D.new()
	root.name = "InstancedBotanicalBatches"
	add_child(root)

	_create_multimesh_batch(root, "MeadowGrassTuftsMM", _mesh_grass_tuft, _mat_grass_mm, _grass_xforms, _grass_colors)
	_create_multimesh_batch(root, "FourColorFlowerbedsMM", _mesh_flower_cluster, _mat_flower_mm, _flower_xforms, _flower_colors)
	_create_multimesh_batch(root, "FloatingLilyPadsMM", _mesh_lily_pad, _mat_lily_mm, _lily_xforms, _lily_colors)
	_create_multimesh_batch(root, "BloomingLotusesMM", _mesh_lotus_flower, _mat_lotus_mm, _lotus_xforms, _lotus_colors)
	_create_multimesh_batch(root, "CascadingVineStemsMM", _mesh_vine_stem, _mat_leaf_emerald, _vine_stem_xforms, [])
	_create_multimesh_batch(root, "CascadingVineLeavesMM", _mesh_ivy_leaf_pair, _mat_vine_leaf_mm, _vine_leaf_xforms, _vine_leaf_colors)
	_create_multimesh_batch(root, "CascadingVineBlossomsMM", _mesh_vine_blossom, _mat_vine_blossom_mm, _vine_blossom_xforms, _vine_blossom_colors)


func _create_multimesh_batch(
	parent: Node3D,
	batch_name: String,
	mesh_res: Mesh,
	mat_res: Material,
	xforms: Array[Transform3D],
	colors: Array[Color]
) -> MultiMeshInstance3D:
	if xforms.is_empty():
		return null
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var has_colors: bool = (colors.size() == xforms.size())
	mm.use_colors = has_colors
	mm.mesh = mesh_res
	mm.instance_count = xforms.size()

	for i: int in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])
		if has_colors:
			mm.set_instance_color(i, colors[i])

	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = batch_name
	mmi.multimesh = mm
	mmi.material_override = mat_res
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi


# ---------------------------------------------------------------------------
# 7. Serene Low-Clutter Butterflies (Hovering Gently Right Above Verified Lakes)
# ---------------------------------------------------------------------------

func _build_fluttering_butterflies(_island_positions: Array[Vector3]) -> void:
	# Sparse, serene butterflies hovering just 0.85m above verified grounded lakes (zero sky clutter)
	if _active_castle_lakes.is_empty():
		return

	var butterfly_palette: Array[Color] = [
		Color("#FFE896"), # Pastel sunlight gold
		Color("#A6F4FF"), # Aqua-pearl shimmer
		Color("#FFD2EA"), # Soft sakura blush
		Color("#E2D4FF"), # Ethereal lavender-pearl
	]
	var b_colors: Array[Color] = []
	var b_seed: int = 9000

	for l_idx: int in range(_active_castle_lakes.size()):
		var lake_info: Dictionary = _active_castle_lakes[l_idx]
		var zc: Vector3 = Vector3(float(lake_info["cx"]), float(lake_info["y"]) + 0.85, float(lake_info["cz"]))
		var zrx: float = float(lake_info["rx"]) * 0.65
		var zrz: float = float(lake_info["rz"]) * 0.65
		var zcnt: int = 2 if l_idx < 2 else 1
		for k: int in range(zcnt):
			b_seed += 1
			var offset_x: float = (_hash01(b_seed * 17) - 0.5) * zrx * 0.6
			var offset_z: float = (_hash01(b_seed * 23) - 0.5) * zrz * 0.6
			var offset_y: float = (_hash01(b_seed * 29) - 0.5) * 0.35
			_butterfly_centers.append(zc + Vector3(offset_x, offset_y, offset_z))
			_butterfly_radii.append(Vector2(1.1 + _hash01(b_seed * 31) * 1.4, 1.1 + _hash01(b_seed * 37) * 1.4))
			_butterfly_speeds.append(0.32 + _hash01(b_seed * 41) * 0.24)
			_butterfly_phases.append(_hash01(b_seed * 43) * TAU)
			_butterfly_scales.append(0.70 + _hash01(b_seed * 47) * 0.35)
			b_colors.append(butterfly_palette[b_seed % butterfly_palette.size()])

	var total_b: int = _butterfly_centers.size()
	if total_b == 0:
		return

	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _mesh_butterfly
	mm.instance_count = total_b

	for i: int in range(total_b):
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, _butterfly_centers[i]))
		mm.set_instance_color(i, b_colors[i])

	_butterfly_mmi = MultiMeshInstance3D.new()
	_butterfly_mmi.name = "LuminousButterfliesMM"
	_butterfly_mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_butterfly_mmi.multimesh = mm
	_butterfly_mmi.material_override = _mat_butterfly_mm
	_butterfly_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_butterfly_mmi)


# ---------------------------------------------------------------------------
# Prop Placement Helpers (GLB with Graceful Procedural Fallbacks)
# ---------------------------------------------------------------------------

func _place_sakura_tree(parent: Node3D, node_name: String, pos: Vector3, yaw_rad: float, scale_factor: float) -> Node3D:
	var prop: Node3D = null
	var is_glb: bool = false
	if _sakura_tree_scene != null:
		var inst: Node = _sakura_tree_scene.instantiate()
		if inst is Node3D:
			prop = inst as Node3D
			is_glb = true
		else:
			inst.queue_free()
	if prop == null:
		prop = _create_fallback_sakura_tree(false)

	prop.name = node_name
	prop.position = pos
	prop.rotation = Vector3(0.0, yaw_rad, 0.0)
	prop.scale = Vector3(scale_factor, scale_factor, scale_factor)
	parent.add_child(prop)

	if is_glb:
		_enhance_sakura_tree_materials(prop)
	return prop


func _place_verdant_tree(parent: Node3D, node_name: String, pos: Vector3, yaw_rad: float, scale_factor: float) -> Node3D:
	var prop: Node3D = null
	var is_glb: bool = false
	if _sakura_tree_scene != null:
		var inst: Node = _sakura_tree_scene.instantiate()
		if inst is Node3D:
			prop = inst as Node3D
			is_glb = true
		else:
			inst.queue_free()
	if prop == null:
		prop = _create_fallback_sakura_tree(true)

	prop.name = node_name
	prop.position = pos
	prop.rotation = Vector3(0.0, yaw_rad, 0.0)
	prop.scale = Vector3(scale_factor, scale_factor, scale_factor)
	parent.add_child(prop)

	if is_glb:
		_apply_verdant_tree_materials(prop)
	return prop


func _get_enhanced_backlight_material(
	cache_key: String,
	base_mat: Material,
	backlight_col: Color,
	double_sided: bool
) -> Material:
	if _enhanced_glb_mats.has(cache_key):
		return _enhanced_glb_mats[cache_key] as Material
	if base_mat is StandardMaterial3D:
		var dup: StandardMaterial3D = (base_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
		dup.backlight_enabled = true
		dup.backlight = backlight_col
		if double_sided:
			dup.cull_mode = BaseMaterial3D.CULL_DISABLED
		_enhanced_glb_mats[cache_key] = dup
		return dup
	return base_mat


func _enhance_sakura_tree_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		var mesh_res: Mesh = mesh_inst.mesh
		if mesh_res != null:
			var surf_count: int = mesh_res.get_surface_count()
			for surf_idx: int in range(surf_count):
				var base_mat: Material = mesh_res.surface_get_material(surf_idx)
				if base_mat == null:
					continue
				var mat_name: String = base_mat.resource_name
				if mat_name == "Mat_SakuraBlossomDeep" or mat_name == "Mat_SakuraBlossomSoft" or mat_name == "Mat_SakuraBlossomCream":
					var pink_mat: Material = _get_enhanced_backlight_material(
						"sakura_" + mat_name, base_mat, Color("#FFADC8"), true
					)
					mesh_inst.set_surface_override_material(surf_idx, pink_mat)
				elif mat_name == "Mat_SpringLeaf":
					var leaf_mat: Material = _get_enhanced_backlight_material(
						"sakura_" + mat_name, base_mat, Color("#68A848"), true
					)
					mesh_inst.set_surface_override_material(surf_idx, leaf_mat)
	for child: Node in node.get_children():
		_enhance_sakura_tree_materials(child)


func _apply_verdant_tree_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		var mesh_res: Mesh = mesh_inst.mesh
		if mesh_res != null:
			var surf_count: int = mesh_res.get_surface_count()
			for surf_idx: int in range(surf_count):
				var base_mat: Material = mesh_res.surface_get_material(surf_idx)
				if base_mat == null:
					continue
				var mat_name: String = base_mat.resource_name
				if mat_name == "Mat_SakuraBlossomDeep":
					mesh_inst.set_surface_override_material(surf_idx, _mat_canopy_emerald_deep)
				elif mat_name == "Mat_SakuraBlossomSoft":
					mesh_inst.set_surface_override_material(surf_idx, _mat_canopy_emerald_sunlit)
				elif mat_name == "Mat_SakuraBlossomCream":
					mesh_inst.set_surface_override_material(surf_idx, _mat_canopy_flower_accent)
				elif mat_name == "Mat_SpringLeaf":
					var leaf_mat: Material = _get_enhanced_backlight_material(
						"verdant_" + mat_name, base_mat, Color("#68A848"), true
					)
					mesh_inst.set_surface_override_material(surf_idx, leaf_mat)
	for child: Node in node.get_children():
		_apply_verdant_tree_materials(child)


func _place_lush_bush(parent: Node3D, node_name: String, pos: Vector3, yaw_rad: float, scale_factor: float) -> Node3D:
	var prop: Node3D = null
	var is_glb: bool = false
	if _lush_bush_scene != null:
		var inst: Node = _lush_bush_scene.instantiate()
		if inst is Node3D:
			prop = inst as Node3D
			is_glb = true
		else:
			inst.queue_free()
	if prop == null:
		prop = _create_fallback_lush_bush()

	prop.name = node_name
	# Embed base 2cm into ground/stone so sculpted bush skirt & bark roots sit firmly grounded
	prop.position = Vector3(pos.x, pos.y - 0.02, pos.z)
	prop.rotation = Vector3(0.0, yaw_rad, 0.0)
	prop.scale = Vector3(scale_factor, scale_factor, scale_factor)
	parent.add_child(prop)

	if is_glb:
		_enhance_lush_bush_materials(prop)
	return prop


func _get_cached_bush_material(
	cache_key: String,
	albedo: Color,
	roughness_val: float,
	enable_backlight: bool,
	backlight_col: Color,
	double_sided: bool,
	use_vcol: bool = false
) -> StandardMaterial3D:
	if _enhanced_glb_mats.has(cache_key):
		return _enhanced_glb_mats[cache_key] as StandardMaterial3D
	var mat: StandardMaterial3D = _create_botanical_material(albedo, roughness_val, 0.0, Color(0.0, 0.0, 0.0), 0.0)
	if use_vcol:
		mat.vertex_color_use_as_albedo = true
	if enable_backlight:
		mat.backlight_enabled = true
		mat.backlight = backlight_col
	if double_sided:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_enhanced_glb_mats[cache_key] = mat
	return mat


func _get_cached_sculpted_bush_shader_mat(
	cache_key: String,
	base_sh: float,
	tip_br: float,
	base_t: Color,
	tip_t: Color,
	backlight_col: Color,
	rough_v: float,
	norm_up: float,
	velvet_rim: float,
	velvet_col: Color
) -> Material:
	if _enhanced_glb_mats.has(cache_key):
		return _enhanced_glb_mats[cache_key] as Material
	var mat: Material = _create_foliage_material(
		0.024, 0.92, base_sh, tip_br,
		base_t, tip_t, backlight_col,
		rough_v, norm_up, 0.0,
		Color(0.0, 0.0, 0.0), 0.0,
		0.0, 0.16, 1.05, velvet_rim, velvet_col
	)
	_enhanced_glb_mats[cache_key] = mat
	return mat


func _enhance_lush_bush_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		var mesh_res: Mesh = mesh_inst.mesh
		if mesh_res != null:
			var surf_count: int = mesh_res.get_surface_count()
			for surf_idx: int in range(surf_count):
				var base_mat: Material = mesh_res.surface_get_material(surf_idx)
				if base_mat == null:
					continue
				var mat_name: String = base_mat.resource_name
				if mat_name == "BushBarkTwigs":
					var bark_mat: StandardMaterial3D = _get_cached_bush_material(
						"bush_bark_twigs", Color(1.0, 1.0, 1.0), 0.88, false, Color(0.0, 0.0, 0.0), false, true
					)
					mesh_inst.set_surface_override_material(surf_idx, bark_mat)
				elif mat_name == "BushSculptedLeaves":
					var leaf_shader_mat: Material = _get_cached_sculpted_bush_shader_mat(
						"bush_sculpted_leaves",
						0.74, 1.16,
						Color(0.90, 0.96, 0.88), Color(1.06, 1.08, 0.90),
						Color(0.46, 0.68, 0.22),
						0.58, 0.14, 0.10, Color(0.76, 0.94, 0.48)
					)
					mesh_inst.set_surface_override_material(surf_idx, leaf_shader_mat)
				elif mat_name == "BushGardenBlossoms":
					var blossom_shader_mat: Material = _get_cached_sculpted_bush_shader_mat(
						"bush_garden_blossoms",
						0.90, 1.12,
						Color(0.98, 0.96, 0.97), Color(1.03, 1.02, 1.03),
						Color(0.88, 0.68, 0.76),
						0.50, 0.20, 0.08, Color(1.0, 0.94, 0.96)
					)
					mesh_inst.set_surface_override_material(surf_idx, blossom_shader_mat)
				elif mat_name == "BushInnerFoliage":
					var inner_mat: StandardMaterial3D = _get_cached_bush_material(
						"bush_inner_foliage", Color("#1F5E34"), 0.78, false, Color(0.0, 0.0, 0.0), false
					)
					mesh_inst.set_surface_override_material(surf_idx, inner_mat)
				elif mat_name == "BushOuterLeaves":
					var outer_mat: StandardMaterial3D = _get_cached_bush_material(
						"bush_outer_leaves", Color("#3CA44E"), 0.56, true, Color("#74C254"), true
					)
					mesh_inst.set_surface_override_material(surf_idx, outer_mat)
				elif mat_name == "BushGardenRoses":
					var rose_mat: StandardMaterial3D = _get_cached_bush_material(
						"bush_garden_roses", Color("#F48AB0"), 0.48, true, Color("#FFC0D8"), true
					)
					mesh_inst.set_surface_override_material(surf_idx, rose_mat)
				elif mat_name == "Mat_DeepEmeraldLeaf" or mat_name == "Mat_SpringGreenLeaf" or mat_name == "Mat_SunlitMintLeaf":
					var hedge_leaf: Material = _get_enhanced_backlight_material(
						"hedge_" + mat_name, base_mat, Color("#68A848"), true
					)
					mesh_inst.set_surface_override_material(surf_idx, hedge_leaf)
				elif mat_name == "Mat_GardenRosePink" or mat_name == "Mat_GardenRoseCream":
					var hedge_rose: Material = _get_enhanced_backlight_material(
						"hedge_" + mat_name, base_mat, Color("#FFADC8"), false
					)
					mesh_inst.set_surface_override_material(surf_idx, hedge_rose)
	for child: Node in node.get_children():
		_enhance_lush_bush_materials(child)


func _place_garden_planter(parent: Node3D, node_name: String, pos: Vector3, yaw_rad: float, scale_factor: float) -> Node3D:
	var prop: Node3D = null
	var is_glb: bool = false
	if _garden_planter_scene != null:
		var inst: Node = _garden_planter_scene.instantiate()
		if inst is Node3D:
			prop = inst as Node3D
			is_glb = true
		else:
			inst.queue_free()
	if prop == null:
		prop = _create_fallback_garden_planter()

	prop.name = node_name
	prop.position = pos
	prop.rotation = Vector3(0.0, yaw_rad, 0.0)
	prop.scale = Vector3(scale_factor, scale_factor, scale_factor)
	parent.add_child(prop)

	if is_glb:
		_enhance_garden_planter_materials(prop)
	return prop


func _enhance_garden_planter_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		var mesh_res: Mesh = mesh_inst.mesh
		if mesh_res != null:
			var surf_count: int = mesh_res.get_surface_count()
			for surf_idx: int in range(surf_count):
				var base_mat: Material = mesh_res.surface_get_material(surf_idx)
				if base_mat == null:
					continue
				var mat_name: String = base_mat.resource_name
				if mat_name == "PlanterLeaves":
					var leaf_mat: Material = _get_cached_sculpted_bush_shader_mat(
						"planter_sculpted_leaves",
						0.72, 1.18,
						Color(0.88, 0.96, 0.86), Color(1.08, 1.10, 0.86),
						Color(0.48, 0.72, 0.22),
						0.62, 0.16, 0.11, Color(0.78, 0.96, 0.48)
					)
					mesh_inst.set_surface_override_material(surf_idx, leaf_mat)
				elif mat_name == "PlanterBlossoms":
					var blossom_mat: Material = _get_cached_sculpted_bush_shader_mat(
						"planter_sculpted_blossoms",
						0.90, 1.14,
						Color(0.98, 0.96, 0.97), Color(1.04, 1.03, 1.03),
						Color(0.90, 0.72, 0.78),
						0.50, 0.22, 0.09, Color(1.0, 0.95, 0.96)
					)
					mesh_inst.set_surface_override_material(surf_idx, blossom_mat)
				elif mat_name == "PlanterMarble":
					var marble_mat: StandardMaterial3D = _get_cached_bush_material(
						"planter_baroque_marble", Color(1.0, 1.0, 1.0), 0.28, false, Color(0.0, 0.0, 0.0), false, true
					)
					marble_mat.metallic = 0.02
					mesh_inst.set_surface_override_material(surf_idx, marble_mat)
				elif mat_name == "PlanterGold":
					var gold_mat: StandardMaterial3D = _get_cached_bush_material(
						"planter_baroque_gold", Color("#E6C26E"), 0.26, false, Color(0.0, 0.0, 0.0), false, false
					)
					gold_mat.metallic = 0.88
					mesh_inst.set_surface_override_material(surf_idx, gold_mat)
				elif mat_name == "PlanterSoil":
					var soil_mat: StandardMaterial3D = _get_cached_bush_material(
						"planter_dark_soil", Color("#261911"), 0.94, false, Color(0.0, 0.0, 0.0), false, false
					)
					mesh_inst.set_surface_override_material(surf_idx, soil_mat)
	for child: Node in node.get_children():
		_enhance_garden_planter_materials(child)


func _place_celestial_ornament(
	parent: Node3D,
	node_name: String,
	pos: Vector3,
	yaw_rad: float,
	scale_factor: float,
	sway_phase: float
) -> Node3D:
	var prop: Node3D = null
	if _celestial_ornament_scene != null:
		var inst: Node = _celestial_ornament_scene.instantiate()
		if inst is Node3D:
			prop = inst as Node3D
		else:
			inst.queue_free()
	if prop == null:
		prop = _create_fallback_celestial_ornament()

	prop.name = node_name
	prop.position = pos
	prop.rotation = Vector3(0.0, yaw_rad, 0.0)
	prop.scale = Vector3(scale_factor, scale_factor, scale_factor)
	parent.add_child(prop)

	_sway_ornaments.append(prop)
	_sway_base_rot.append(prop.rotation)
	_sway_phases.append(sway_phase)
	return prop


## Classical carved white-marble Baroque urn overflowing with leaf-by-leaf botanical foliage & roses
## (for the sunlit Rotunda interior beside the 16 marble columns and panoramic terraces).
func _place_rotunda_potted_urn(parent: Node3D, node_name: String, pos: Vector3, yaw_rad: float, scale_factor: float) -> Node3D:
	if _garden_planter_scene != null:
		var sculpted: Node3D = _place_garden_planter(parent, node_name, pos, yaw_rad, scale_factor)
		sculpted.scale = Vector3(scale_factor * 0.92, scale_factor * 1.12, scale_factor * 0.92)
		return sculpted

	var urn: Node3D = Node3D.new()
	urn.name = node_name
	urn.position = pos
	urn.rotation = Vector3(0.0, yaw_rad, 0.0)
	urn.scale = Vector3(scale_factor, scale_factor, scale_factor)
	parent.add_child(urn)

	# Carved marble pedestal base
	var foot_mesh: CylinderMesh = CylinderMesh.new()
	foot_mesh.top_radius = 0.28
	foot_mesh.bottom_radius = 0.44
	foot_mesh.height = 0.34
	foot_mesh.radial_segments = 12
	var foot: MeshInstance3D = MeshInstance3D.new()
	foot.mesh = foot_mesh
	foot.material_override = _mat_marble_curb
	foot.position = Vector3(0.0, 0.17, 0.0)
	urn.add_child(foot)

	# Fluted white-marble urn bowl
	var bowl_mesh: CylinderMesh = CylinderMesh.new()
	bowl_mesh.top_radius = 0.56
	bowl_mesh.bottom_radius = 0.28
	bowl_mesh.height = 0.88
	bowl_mesh.radial_segments = 14
	var bowl: MeshInstance3D = MeshInstance3D.new()
	bowl.mesh = bowl_mesh
	bowl.material_override = _mat_marble_curb
	bowl.position = Vector3(0.0, 0.76, 0.0)
	urn.add_child(bowl)

	# Champagne gold rim
	var rim_mesh: TorusMesh = TorusMesh.new()
	rim_mesh.inner_radius = 0.48
	rim_mesh.outer_radius = 0.60
	rim_mesh.rings = 16
	rim_mesh.ring_segments = 8
	var rim: MeshInstance3D = MeshInstance3D.new()
	rim.mesh = rim_mesh
	rim.material_override = _mat_gold_trim
	rim.position = Vector3(0.0, 1.20, 0.0)
	rim.scale = Vector3(1.0, 0.55, 1.0)
	urn.add_child(rim)

	# Lush overflowing emerald foliage & fern fronds
	var leaf_mats: Array[StandardMaterial3D] = [
		_mat_leaf_emerald,
		_mat_leaf_spring,
		_mat_leaf_mint,
	]
	var foliage_offsets: Array[Vector3] = [
		Vector3(0.0, 1.62, 0.0),
		Vector3(-0.36, 1.48, 0.22),
		Vector3(0.38, 1.46, -0.18),
		Vector3(0.18, 1.54, 0.36),
		Vector3(-0.24, 1.50, -0.34),
		Vector3(0.04, 2.02, -0.04),
	]
	var foliage_scales: Array[Vector3] = [
		Vector3(2.1, 2.4, 2.1),
		Vector3(1.8, 1.9, 1.8),
		Vector3(1.8, 1.8, 1.8),
		Vector3(1.7, 1.8, 1.7),
		Vector3(1.7, 1.8, 1.7),
		Vector3(1.5, 2.2, 1.5),
	]
	for i: int in range(foliage_offsets.size()):
		var bush: MeshInstance3D = MeshInstance3D.new()
		bush.mesh = _mesh_leaf_cluster
		bush.material_override = leaf_mats[i % leaf_mats.size()]
		bush.position = foliage_offsets[i]
		bush.scale = foliage_scales[i]
		bush.rotation = Vector3(0.22 * float((i % 3) - 1), float(i) * 0.95, 0.16 * float((i % 2) * 2 - 1))
		urn.add_child(bush)

	# Delicate blush & cream-pink blossom accents tucked into the emerald foliage
	var bloom_offsets: Array[Vector3] = [
		Vector3(-0.32, 1.78, 0.26),
		Vector3(0.34, 1.74, 0.18),
		Vector3(0.0, 2.22, 0.12),
		Vector3(-0.16, 1.86, -0.32),
		Vector3(0.22, 1.92, -0.22),
	]
	var bloom_mats: Array[StandardMaterial3D] = [
		_mat_blossom_blush,
		_mat_blossom_pink,
		_mat_canopy_flower_accent,
		_mat_blossom_lilac,
		_mat_blossom_blush,
	]
	for b_idx: int in range(bloom_offsets.size()):
		var bloom: MeshInstance3D = MeshInstance3D.new()
		bloom.mesh = _mesh_blossom_cluster
		bloom.material_override = bloom_mats[b_idx]
		bloom.position = bloom_offsets[b_idx]
		bloom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		urn.add_child(bloom)

	return urn


# ---------------------------------------------------------------------------
# GPU-Instanced Cascading Emerald Ivy & Sakura-Blossom Vine Garlands
# ---------------------------------------------------------------------------

func _append_vine_garland(
	anchor_pos: Vector3,
	outward_dir: Vector3,
	drop_length: float,
	seed_index: int
) -> void:
	var tangent: Vector3 = Vector3(-outward_dir.z, 0.0, outward_dir.x)
	var seg_step: float = 0.44
	var seg_count: int = maxi(3, int(roundf(drop_length / seg_step)))
	var leaf_cols: Array[Color] = [
		Color("#2B6E40"),
		Color("#449656"),
		Color("#6EC274"),
	]
	var blossom_cols: Array[Color] = [
		Color("#F78EB0"),
		Color("#FFC8D8"),
		Color("#C89EEB"),
		Color("#A6DEFF"),
	]

	for s: int in range(seg_count):
		var frac: float = float(s) / float(maxi(1, seg_count - 1))
		var y_off: float = -float(s) * seg_step
		var sway_wave: float = sin(frac * PI * 1.6 + float(seed_index) * 0.9) * 0.16
		var out_curve: float = 0.12 + sin(frac * PI * 0.85) * 0.18
		var world_pos: Vector3 = anchor_pos + outward_dir * out_curve + tangent * sway_wave + Vector3(0.0, y_off, 0.0)

		# Stem transform
		var stem_basis: Basis = Basis.from_euler(Vector3(0.0, float(seed_index + s) * 0.5, sway_wave * 0.6))
		_vine_stem_xforms.append(Transform3D(stem_basis, world_pos))

		# Tapered 3-tone emerald/spring/mint ivy foliage cluster
		var taper: float = lerpf(1.28, 0.58, frac)
		var leaf_basis: Basis = Basis.from_euler(
			Vector3(0.25 * float((s % 3) - 1), float(seed_index + s) * 0.85, 0.22 * sway_wave)
		).scaled(Vector3(taper, taper * 0.90, taper))
		_vine_leaf_xforms.append(Transform3D(leaf_basis, world_pos + outward_dir * 0.08))
		_vine_leaf_colors.append(leaf_cols[(s + seed_index) % leaf_cols.size()])

		# Flowering blossom accents nestled into the cascading emerald ivy
		if s == 0 or s == seg_count - 1 or (s + seed_index) % 3 == 0:
			var side_nudge: float = 0.15 if s % 2 == 0 else -0.15
			var b_scale: float = lerpf(1.06, 0.60, frac)
			var b_basis: Basis = Basis.IDENTITY.scaled(Vector3(b_scale, b_scale * 0.92, b_scale))
			_vine_blossom_xforms.append(Transform3D(b_basis, world_pos + outward_dir * 0.16 + tangent * side_nudge))
			_vine_blossom_colors.append(blossom_cols[(seed_index + s) % blossom_cols.size()])


# ---------------------------------------------------------------------------
# Procedural Botanical & Lake ArrayMesh Builders (Lightweight, 60 FPS)
# ---------------------------------------------------------------------------

func _oval_lobe_factor(angle_rad: float) -> float:
	return 1.0 + 0.042 * sin(angle_rad * 3.0) + 0.024 * cos(angle_rad * 5.0)


func _create_oval_water_mesh(rx: float, rz: float, radial_segs: int, ring_segs: int) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for r_idx: int in range(ring_segs):
		var r0: float = float(r_idx) / float(ring_segs)
		var r1: float = float(r_idx + 1) / float(ring_segs)
		for a_idx: int in range(radial_segs):
			var a0: float = (TAU / float(radial_segs)) * float(a_idx)
			var a1: float = (TAU / float(radial_segs)) * float(a_idx + 1)

			var l0: float = _oval_lobe_factor(a0)
			var l1: float = _oval_lobe_factor(a1)

			var p00: Vector3 = Vector3(cos(a0) * rx * r0 * l0, 0.0, sin(a0) * rz * r0 * l0)
			var p10: Vector3 = Vector3(cos(a0) * rx * r1 * l0, 0.0, sin(a0) * rz * r1 * l0)
			var p11: Vector3 = Vector3(cos(a1) * rx * r1 * l1, 0.0, sin(a1) * rz * r1 * l1)
			var p01: Vector3 = Vector3(cos(a1) * rx * r0 * l1, 0.0, sin(a1) * rz * r0 * l1)

			var uv00: Vector2 = Vector2(0.5 + 0.5 * r0 * cos(a0), 0.5 + 0.5 * r0 * sin(a0))
			var uv10: Vector2 = Vector2(0.5 + 0.5 * r1 * cos(a0), 0.5 + 0.5 * r1 * sin(a0))
			var uv11: Vector2 = Vector2(0.5 + 0.5 * r1 * cos(a1), 0.5 + 0.5 * r1 * sin(a1))
			var uv01: Vector2 = Vector2(0.5 + 0.5 * r0 * cos(a1), 0.5 + 0.5 * r0 * sin(a1))

			st.set_normal(Vector3.UP)
			if r_idx > 0:
				st.set_uv(uv00)
				st.add_vertex(p00)
				st.set_uv(uv10)
				st.add_vertex(p10)
				st.set_uv(uv11)
				st.add_vertex(p11)

			st.set_uv(uv00)
			st.add_vertex(p00)
			st.set_uv(uv11)
			st.add_vertex(p11)
			st.set_uv(uv01)
			st.add_vertex(p01)

	return st.commit()


func _create_oval_curb_mesh(
	rx: float,
	rz: float,
	curb_width: float,
	curb_height: float,
	segs: int,
	skirt_depth: float = 0.0
) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var bot_y: float = -maxf(0.0, skirt_depth)
	for i: int in range(segs):
		var a0: float = (TAU / float(segs)) * float(i)
		var a1: float = (TAU / float(segs)) * float(i + 1)
		var l0: float = _oval_lobe_factor(a0)
		var l1: float = _oval_lobe_factor(a1)

		var in0_b: Vector3 = Vector3(cos(a0) * rx * l0, bot_y, sin(a0) * rz * l0)
		var in1_b: Vector3 = Vector3(cos(a1) * rx * l1, bot_y, sin(a1) * rz * l1)
		var out0_b: Vector3 = Vector3(cos(a0) * (rx * l0 + curb_width), bot_y, sin(a0) * (rz * l0 + curb_width))
		var out1_b: Vector3 = Vector3(cos(a1) * (rx * l1 + curb_width), bot_y, sin(a1) * (rz * l1 + curb_width))

		var in0_t: Vector3 = Vector3(in0_b.x, curb_height, in0_b.z)
		var in1_t: Vector3 = Vector3(in1_b.x, curb_height, in1_b.z)
		var out0_t: Vector3 = Vector3(out0_b.x, curb_height, out0_b.z)
		var out1_t: Vector3 = Vector3(out1_b.x, curb_height, out1_b.z)

		# Top face
		_add_quad(st, in0_t, out0_t, out1_t, in1_t)
		# Outer retaining wall extending down into meadow soil
		_add_quad(st, out0_b, out1_b, out1_t, out0_t)
		# Inner basin wall
		_add_quad(st, in1_b, in0_b, in0_t, in1_t)

	st.generate_normals()
	return st.commit()


func _create_ring_water_mesh(r_inner: float, r_outer: float, radial_segs: int, ring_segs: int) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for r_idx: int in range(ring_segs):
		var t0: float = float(r_idx) / float(ring_segs)
		var t1: float = float(r_idx + 1) / float(ring_segs)
		var rad0: float = lerpf(r_inner, r_outer, t0)
		var rad1: float = lerpf(r_inner, r_outer, t1)

		for a_idx: int in range(radial_segs):
			var u0: float = float(a_idx) / float(radial_segs)
			var u1: float = float(a_idx + 1) / float(radial_segs)
			var a0: float = u0 * TAU
			var a1: float = u1 * TAU

			var p00: Vector3 = Vector3(cos(a0) * rad0, 0.0, sin(a0) * rad0)
			var p10: Vector3 = Vector3(cos(a0) * rad1, 0.0, sin(a0) * rad1)
			var p11: Vector3 = Vector3(cos(a1) * rad1, 0.0, sin(a1) * rad1)
			var p01: Vector3 = Vector3(cos(a1) * rad0, 0.0, sin(a1) * rad0)

			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(u0, t0))
			st.add_vertex(p00)
			st.set_uv(Vector2(u0, t1))
			st.add_vertex(p10)
			st.set_uv(Vector2(u1, t1))
			st.add_vertex(p11)

			st.set_uv(Vector2(u0, t0))
			st.add_vertex(p00)
			st.set_uv(Vector2(u1, t1))
			st.add_vertex(p11)
			st.set_uv(Vector2(u1, t0))
			st.add_vertex(p01)

	return st.commit()


func _create_ring_curb_mesh(radius: float, curb_width: float, curb_height: float, segs: int) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r_in: float = radius - curb_width * 0.5
	var r_out: float = radius + curb_width * 0.5
	var h_vec: Vector3 = Vector3(0.0, curb_height, 0.0)

	for i: int in range(segs):
		var a0: float = (TAU / float(segs)) * float(i)
		var a1: float = (TAU / float(segs)) * float(i + 1)
		var in0: Vector3 = Vector3(cos(a0) * r_in, 0.0, sin(a0) * r_in)
		var in1: Vector3 = Vector3(cos(a1) * r_in, 0.0, sin(a1) * r_in)
		var out0: Vector3 = Vector3(cos(a0) * r_out, 0.0, sin(a0) * r_out)
		var out1: Vector3 = Vector3(cos(a1) * r_out, 0.0, sin(a1) * r_out)

		_add_quad(st, in0 + h_vec, out0 + h_vec, out1 + h_vec, in1 + h_vec)
		_add_quad(st, out0, out1, out1 + h_vec, out0 + h_vec)
		_add_quad(st, in1, in0, in0 + h_vec, in1 + h_vec)

	st.generate_normals()
	return st.commit()


func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)


func _create_lily_pad_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs: int = 12
	var radius: float = 0.44
	var start_a: float = 0.24
	var end_a: float = TAU - 0.24
	var center_pt: Vector3 = Vector3(0.0, 0.0, 0.0)

	for i: int in range(segs):
		var a0: float = lerpf(start_a, end_a, float(i) / float(segs))
		var a1: float = lerpf(start_a, end_a, float(i + 1) / float(segs))
		var p0: Vector3 = Vector3(cos(a0) * radius, 0.025, sin(a0) * radius)
		var p1: Vector3 = Vector3(cos(a1) * radius, 0.025, sin(a1) * radius)

		st.set_color(Color(0.76, 0.88, 0.78))
		st.set_normal(Vector3.UP)
		st.add_vertex(center_pt)
		st.set_color(Color(1.0, 1.0, 1.0))
		st.set_normal(Vector3.UP)
		st.add_vertex(p0)
		st.set_color(Color(1.0, 1.0, 1.0))
		st.set_normal(Vector3.UP)
		st.add_vertex(p1)

	return st.commit()


func _create_lotus_flower_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Outer 6 petals + inner 6 raised petals
	for tier: int in range(2):
		var petal_count: int = 6
		var phase: float = 0.0 if tier == 0 else (PI / float(petal_count))
		var p_len: float = 0.26 if tier == 0 else 0.18
		var p_w: float = 0.095 if tier == 0 else 0.072
		var tip_y: float = 0.11 if tier == 0 else 0.17
		var mid_y: float = 0.055 if tier == 0 else 0.095

		for k: int in range(petal_count):
			var a: float = (TAU / float(petal_count)) * float(k) + phase
			var dir: Vector3 = Vector3(cos(a), 0.0, sin(a))
			var side: Vector3 = Vector3(-sin(a), 0.0, cos(a))

			var v_base: Vector3 = dir * 0.03 + Vector3(0.0, 0.01, 0.0)
			var v_l: Vector3 = dir * (p_len * 0.56) + side * p_w + Vector3(0.0, mid_y, 0.0)
			var v_r: Vector3 = dir * (p_len * 0.56) - side * p_w + Vector3(0.0, mid_y, 0.0)
			var v_tip: Vector3 = dir * p_len + Vector3(0.0, tip_y, 0.0)

			st.set_color(Color(0.95, 0.92, 0.96))
			st.add_vertex(v_base)
			st.set_color(Color(1.0, 1.0, 1.0))
			st.add_vertex(v_l)
			st.set_color(Color(1.0, 1.0, 1.0))
			st.add_vertex(v_tip)

			st.set_color(Color(0.95, 0.92, 0.96))
			st.add_vertex(v_base)
			st.set_color(Color(1.0, 1.0, 1.0))
			st.add_vertex(v_tip)
			st.set_color(Color(1.0, 1.0, 1.0))
			st.add_vertex(v_r)

	# Warm golden stamen center crown
	var core_r: float = 0.055
	var core_top: Vector3 = Vector3(0.0, 0.12, 0.0)
	var gold_col: Color = Color(1.0, 0.88, 0.36)
	for c: int in range(6):
		var a0: float = (TAU / 6.0) * float(c)
		var a1: float = (TAU / 6.0) * float(c + 1)
		st.set_color(gold_col)
		st.add_vertex(core_top)
		st.set_color(gold_col)
		st.add_vertex(Vector3(cos(a0) * core_r, 0.04, sin(a0) * core_r))
		st.set_color(gold_col)
		st.add_vertex(Vector3(cos(a1) * core_r, 0.04, sin(a1) * core_r))

	st.generate_normals()
	return st.commit()


func _add_botanical_tri(
	st: SurfaceTool,
	p0: Vector3, uv0: Vector2, c0: Color,
	p1: Vector3, uv1: Vector2, c1: Color,
	p2: Vector3, uv2: Vector2, c2: Color
) -> void:
	st.set_uv(uv0)
	st.set_color(c0)
	st.add_vertex(p0)
	st.set_uv(uv1)
	st.set_color(c1)
	st.add_vertex(p1)
	st.set_uv(uv2)
	st.set_color(c2)
	st.add_vertex(p2)


func _extract_first_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh != null:
			return mi.mesh
	for child: Node in node.get_children():
		var found: Mesh = _extract_first_mesh(child)
		if found != null:
			return found
	return null


func _create_grass_tuft_mesh() -> Mesh:
	if _botanical_grass_scene != null:
		var inst: Node = _botanical_grass_scene.instantiate()
		if inst != null:
			var sculpted_mesh: Mesh = _extract_first_mesh(inst)
			inst.free()
			if sculpted_mesh != null:
				return sculpted_mesh

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Fallback 9-blade curved botanical grass & fern clump (3 arched vertical segments per blade, 0.38m..0.88m)
	var blade_angles: Array[float] = [0.18, 0.88, 1.56, 2.28, 2.98, 3.66, 4.38, 5.08, 5.76]
	var blade_heights: Array[float] = [0.88, 0.56, 0.74, 0.42, 0.82, 0.48, 0.68, 0.38, 0.62]
	var blade_leans: Array[float] = [0.22, 0.30, 0.26, 0.34, 0.24, 0.32, 0.28, 0.31, 0.27]
	var blade_widths: Array[float] = [0.068, 0.062, 0.064, 0.072, 0.066, 0.064, 0.060, 0.070, 0.062]
	var blade_radii: Array[float] = [0.03, 0.09, 0.05, 0.11, 0.04, 0.10, 0.06, 0.12, 0.07]
	var blade_shades: Array[float] = [1.02, 0.94, 0.98, 0.90, 1.04, 0.92, 0.97, 0.88, 0.96]

	var t1: float = 0.36
	var t2: float = 0.72

	for b: int in range(blade_angles.size()):
		var ang: float = blade_angles[b]
		var h: float = blade_heights[b]
		var lean: float = blade_leans[b]
		var w0: float = blade_widths[b]
		var w1: float = w0 * 0.76
		var w2: float = w0 * 0.42
		var dir: Vector3 = Vector3(cos(ang), 0.0, sin(ang))
		var side: Vector3 = Vector3(-sin(ang), 0.0, cos(ang))
		var twist_sign: float = 1.0 if (b % 2 == 0) else -1.0
		var side_mid: Vector3 = (side + dir * (0.14 * twist_sign)).normalized()
		var side_top: Vector3 = (side + dir * (0.26 * twist_sign)).normalized()

		var base_c: Vector3 = dir * blade_radii[b]
		var c1: Vector3 = base_c + dir * (lean * t1 * t1 * 1.15) + Vector3(0.0, h * (t1 - 0.04 * t1 * t1), 0.0)
		var c2: Vector3 = base_c + dir * (lean * t2 * t2 * 1.25) + Vector3(0.0, h * (t2 - 0.07 * t2 * t2), 0.0)
		var tip: Vector3 = base_c + dir * (lean * 1.32) + Vector3(0.0, h * 0.91, 0.0)

		var p0l: Vector3 = base_c - side * w0
		var p0r: Vector3 = base_c + side * w0
		var p1l: Vector3 = c1 - side_mid * w1
		var p1r: Vector3 = c1 + side_mid * w1
		var p2l: Vector3 = c2 - side_top * w2
		var p2r: Vector3 = c2 + side_top * w2

		var sh: float = blade_shades[b]
		var col0: Color = Color(sh * 0.92, sh * 0.96, sh * 0.92)
		var col1: Color = Color(sh * 0.96, sh * 0.99, sh * 0.96)
		var col2: Color = Color(sh, sh, sh)
		var col_tip: Color = Color(minf(1.05, sh * 1.03), minf(1.05, sh * 1.04), minf(1.05, sh * 1.01))

		# Segment 1 (root -> lower arch, UV.y: 0.0 -> 0.36)
		_add_botanical_tri(st, p0l, Vector2(0.0, 0.0), col0, p0r, Vector2(1.0, 0.0), col0, p1r, Vector2(1.0, t1), col1)
		_add_botanical_tri(st, p0l, Vector2(0.0, 0.0), col0, p1r, Vector2(1.0, t1), col1, p1l, Vector2(0.0, t1), col1)

		# Segment 2 (lower arch -> upper arch, UV.y: 0.36 -> 0.72)
		_add_botanical_tri(st, p1l, Vector2(0.0, t1), col1, p1r, Vector2(1.0, t1), col1, p2r, Vector2(1.0, t2), col2)
		_add_botanical_tri(st, p1l, Vector2(0.0, t1), col1, p2r, Vector2(1.0, t2), col2, p2l, Vector2(0.0, t2), col2)

		# Segment 3 (upper arch -> fine pointed tip, UV.y: 0.72 -> 1.0)
		_add_botanical_tri(st, p2l, Vector2(0.0, t2), col2, p2r, Vector2(1.0, t2), col2, tip, Vector2(0.5, 1.0), col_tip)

	st.generate_normals()
	return st.commit()


func _create_flower_cluster_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Botanical blooming flower bush: 4 arched leafy stems crowned by 5-petal cupped blossoms + golden pollen centers
	# UV.x encodes botanical part for akasha_foliage.gdshader (stem_mask_enabled = 1.0):
	#   UV.x = 0.0 -> lush green stems & leaves | UV.x = 0.5 -> per-instance blossom petals | UV.x = 1.0 -> golden pollen
	var stem_angles: Array[float] = [0.32, 1.88, 3.46, 5.02]
	var stem_heights: Array[float] = [0.48, 0.40, 0.36, 0.44]
	var stem_leans: Array[float] = [0.11, 0.16, 0.15, 0.14]
	var blossom_radii: Array[float] = [0.135, 0.118, 0.112, 0.124]
	var white_col: Color = Color(1.0, 1.0, 1.0)
	var throat_col: Color = Color(0.84, 0.84, 0.86)

	for s_idx: int in range(stem_angles.size()):
		var ang: float = stem_angles[s_idx]
		var h: float = stem_heights[s_idx]
		var lean: float = stem_leans[s_idx]
		var dir: Vector3 = Vector3(cos(ang), 0.0, sin(ang))
		var side: Vector3 = Vector3(-sin(ang), 0.0, cos(ang))

		var p_root: Vector3 = dir * 0.03
		var p_mid: Vector3 = p_root + dir * (lean * 0.42) + Vector3(0.0, h * 0.50, 0.0)
		var p_top: Vector3 = p_root + dir * lean + Vector3(0.0, h, 0.0)

		# Arched green stem (2 slender tapered segments, UV.x = 0.0)
		var sw0: float = 0.017
		var sw1: float = 0.013
		var sw2: float = 0.009
		_add_botanical_tri(
			st,
			p_root - side * sw0, Vector2(0.0, 0.0), white_col,
			p_root + side * sw0, Vector2(0.0, 0.0), white_col,
			p_mid + side * sw1, Vector2(0.0, 0.48), white_col
		)
		_add_botanical_tri(
			st,
			p_root - side * sw0, Vector2(0.0, 0.0), white_col,
			p_mid + side * sw1, Vector2(0.0, 0.48), white_col,
			p_mid - side * sw1, Vector2(0.0, 0.48), white_col
		)
		_add_botanical_tri(
			st,
			p_mid - side * sw1, Vector2(0.0, 0.48), white_col,
			p_mid + side * sw1, Vector2(0.0, 0.48), white_col,
			p_top + side * sw2, Vector2(0.0, 0.86), white_col
		)
		_add_botanical_tri(
			st,
			p_mid - side * sw1, Vector2(0.0, 0.48), white_col,
			p_top + side * sw2, Vector2(0.0, 0.86), white_col,
			p_top - side * sw2, Vector2(0.0, 0.86), white_col
		)

		# 2 arched pointed botanical leaves sprouting from the mid-stem (UV.x = 0.0)
		for l_idx: int in range(2):
			var l_sign: float = 1.0 if l_idx == 0 else -1.0
			var l_frac: float = 0.34 if l_idx == 0 else 0.56
			var l_base: Vector3 = p_root.lerp(p_top, l_frac)
			var l_dir: Vector3 = (dir * 0.58 + side * (0.72 * l_sign) + Vector3(0.0, 0.34, 0.0)).normalized()
			var l_perp: Vector3 = l_dir.cross(Vector3.UP).normalized()
			var l_len: float = 0.16 if l_idx == 0 else 0.135
			var l_w: float = 0.044 if l_idx == 0 else 0.038
			var l_mid_pt: Vector3 = l_base + l_dir * (l_len * 0.48) + Vector3(0.0, 0.015, 0.0)
			var l_tip: Vector3 = l_base + l_dir * l_len - Vector3(0.0, 0.018, 0.0)
			var uv_b: Vector2 = Vector2(0.0, l_frac)
			var uv_m: Vector2 = Vector2(0.0, minf(0.92, l_frac + 0.14))
			var uv_t: Vector2 = Vector2(0.0, minf(0.96, l_frac + 0.24))

			_add_botanical_tri(st, l_base, uv_b, white_col, l_mid_pt + l_perp * l_w, uv_m, white_col, l_tip, uv_t, white_col)
			_add_botanical_tri(st, l_base, uv_b, white_col, l_tip, uv_t, white_col, l_mid_pt - l_perp * l_w, uv_m, white_col)

		# Tilted blossom frame so each 5-petal flower cups gracefully toward the sky & viewer
		var tilt_rad: float = 0.26 + float(s_idx) * 0.035
		var blossom_up: Vector3 = (Vector3.UP * cos(tilt_rad) + dir * sin(tilt_rad)).normalized()
		var blossom_right: Vector3 = side
		var blossom_fwd: Vector3 = blossom_right.cross(blossom_up).normalized()
		var p_rad: float = blossom_radii[s_idx]
		var petal_count: int = 5
		var phase: float = float(s_idx) * 0.62

		# Detailed 5-petal cupped blossom (UV.x = 0.5 -> per-instance vibrant rose/lavender/hydrangea/jasmine color)
		for p: int in range(petal_count):
			var pa: float = (TAU / float(petal_count)) * float(p) + phase
			var p_dir: Vector3 = blossom_fwd * cos(pa) + blossom_right * sin(pa)
			var p_side: Vector3 = blossom_fwd * (-sin(pa)) + blossom_right * cos(pa)

			var v_center: Vector3 = p_top + p_dir * 0.012
			var v_left: Vector3 = p_top + p_dir * (p_rad * 0.58) + p_side * (p_rad * 0.44) + blossom_up * (p_rad * 0.26)
			var v_right: Vector3 = p_top + p_dir * (p_rad * 0.58) - p_side * (p_rad * 0.44) + blossom_up * (p_rad * 0.26)
			var v_tip: Vector3 = p_top + p_dir * p_rad + blossom_up * (p_rad * 0.42)

			var uv_c: Vector2 = Vector2(0.5, 0.88)
			var uv_m: Vector2 = Vector2(0.5, 0.95)
			var uv_t: Vector2 = Vector2(0.5, 1.0)

			_add_botanical_tri(st, v_center, uv_c, throat_col, v_left, uv_m, white_col, v_tip, uv_t, white_col)
			_add_botanical_tri(st, v_center, uv_c, throat_col, v_tip, uv_t, white_col, v_right, uv_m, white_col)

		# Raised 5-sided golden pollen stamen center (UV.x = 1.0 -> warm sunlit gold)
		var core_r: float = p_rad * 0.28
		var core_peak: Vector3 = p_top + blossom_up * (p_rad * 0.34)
		var core_base_off: Vector3 = blossom_up * (p_rad * 0.12)
		for c: int in range(5):
			var ca0: float = (TAU / 5.0) * float(c)
			var ca1: float = (TAU / 5.0) * float(c + 1)
			var cp0: Vector3 = p_top + (blossom_fwd * cos(ca0) + blossom_right * sin(ca0)) * core_r + core_base_off
			var cp1: Vector3 = p_top + (blossom_fwd * cos(ca1) + blossom_right * sin(ca1)) * core_r + core_base_off
			_add_botanical_tri(
				st,
				core_peak, Vector2(1.0, 1.0), white_col,
				cp0, Vector2(1.0, 0.94), white_col,
				cp1, Vector2(1.0, 0.94), white_col
			)

	st.generate_normals()
	return st.commit()


func _create_ivy_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Cascading ivy foliage segment: 2 alternating angled pairs of heart-shaped botanical leaves
	# Clean UV.y = 0.16 at petiole attachment -> 1.0 at drooping leaf apex for sky-breeze sway!
	var pair_y: Array[float] = [0.12, -0.14]
	var pair_yaw: Array[float] = [0.0, 1.18]
	var leaf_len: float = 0.26
	var leaf_w: float = 0.155

	var col_petiole: Color = Color(0.84, 0.92, 0.84)
	var col_mid: Color = Color(0.96, 1.0, 0.96)
	var col_tip: Color = Color(1.0, 1.0, 1.0)

	for p_idx: int in range(2):
		var py: float = pair_y[p_idx]
		var base_yaw: float = pair_yaw[p_idx]
		for side_idx: int in range(2):
			var yaw: float = base_yaw + (0.0 if side_idx == 0 else PI) + (0.22 if p_idx == 0 else -0.22)
			var out_h: Vector3 = Vector3(cos(yaw), 0.0, sin(yaw))
			var lat: Vector3 = Vector3(-sin(yaw), 0.0, cos(yaw))
			# Droop gracefully outward & downward along the cascading vine
			var fwd: Vector3 = (out_h * 0.78 + Vector3(0.0, -0.62, 0.0)).normalized()
			var up_n: Vector3 = lat.cross(fwd).normalized()

			var root_pt: Vector3 = Vector3(0.0, py, 0.0) + out_h * 0.03
			var lobe_l: Vector3 = root_pt - fwd * (leaf_len * 0.10) + lat * (leaf_w * 0.56) + up_n * 0.022
			var lobe_r: Vector3 = root_pt - fwd * (leaf_len * 0.10) - lat * (leaf_w * 0.56) + up_n * 0.022
			var cheek_l: Vector3 = root_pt + fwd * (leaf_len * 0.42) + lat * leaf_w + up_n * 0.026
			var cheek_r: Vector3 = root_pt + fwd * (leaf_len * 0.42) - lat * leaf_w + up_n * 0.026
			var mid_rib: Vector3 = root_pt + fwd * (leaf_len * 0.46) - up_n * 0.012
			var apex: Vector3 = root_pt + fwd * leaf_len - up_n * 0.024

			var uv_root: Vector2 = Vector2(0.5, 0.18)
			var uv_lobe: Vector2 = Vector2(0.15, 0.28)
			var uv_cheek: Vector2 = Vector2(0.0, 0.62)
			var uv_mid: Vector2 = Vector2(0.5, 0.62)
			var uv_apex: Vector2 = Vector2(0.5, 1.0)

			# Left heart lobe & blade half
			_add_botanical_tri(st, root_pt, uv_root, col_petiole, lobe_l, uv_lobe, col_mid, cheek_l, uv_cheek, col_mid)
			_add_botanical_tri(st, root_pt, uv_root, col_petiole, cheek_l, uv_cheek, col_mid, mid_rib, uv_mid, col_mid)
			_add_botanical_tri(st, mid_rib, uv_mid, col_mid, cheek_l, uv_cheek, col_mid, apex, uv_apex, col_tip)

			# Right heart lobe & blade half
			_add_botanical_tri(st, root_pt, uv_root, col_petiole, cheek_r, uv_cheek, col_mid, lobe_r, uv_lobe, col_mid)
			_add_botanical_tri(st, root_pt, uv_root, col_petiole, mid_rib, uv_mid, col_mid, cheek_r, uv_cheek, col_mid)
			_add_botanical_tri(st, mid_rib, uv_mid, col_mid, apex, uv_apex, col_tip, cheek_r, uv_cheek, col_mid)

	st.generate_normals()
	return st.commit()


func _create_vine_blossom_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Delicate 5-petal cupped blossom nestled into cascading ivy curtains (sways gently via UV.y = 0.55..1.0)
	var p_rad: float = 0.145
	var throat_col: Color = Color(0.86, 0.84, 0.88)
	var white_col: Color = Color(1.0, 1.0, 1.0)
	var gold_col: Color = Color(1.0, 0.90, 0.42)

	for p: int in range(5):
		var pa: float = (TAU / 5.0) * float(p)
		var dir: Vector3 = Vector3(cos(pa), 0.0, sin(pa))
		var side: Vector3 = Vector3(-sin(pa), 0.0, cos(pa))

		var v_c: Vector3 = dir * 0.015
		var v_l: Vector3 = dir * (p_rad * 0.58) + side * (p_rad * 0.46) + Vector3(0.0, p_rad * 0.28, 0.0)
		var v_r: Vector3 = dir * (p_rad * 0.58) - side * (p_rad * 0.46) + Vector3(0.0, p_rad * 0.28, 0.0)
		var v_t: Vector3 = dir * p_rad + Vector3(0.0, p_rad * 0.44, 0.0)

		_add_botanical_tri(st, v_c, Vector2(0.5, 0.58), throat_col, v_l, Vector2(0.2, 0.82), white_col, v_t, Vector2(0.5, 1.0), white_col)
		_add_botanical_tri(st, v_c, Vector2(0.5, 0.58), throat_col, v_t, Vector2(0.5, 1.0), white_col, v_r, Vector2(0.8, 0.82), white_col)

	var core_r: float = 0.042
	var core_peak: Vector3 = Vector3(0.0, 0.052, 0.0)
	for c: int in range(5):
		var a0: float = (TAU / 5.0) * float(c)
		var a1: float = (TAU / 5.0) * float(c + 1)
		_add_botanical_tri(
			st,
			core_peak, Vector2(0.5, 0.72), gold_col,
			Vector3(cos(a0) * core_r, 0.018, sin(a0) * core_r), Vector2(0.5, 0.64), gold_col,
			Vector3(cos(a1) * core_r, 0.018, sin(a1) * core_r), Vector2(0.5, 0.64), gold_col
		)

	st.generate_normals()
	return st.commit()


func _create_butterfly_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Delicate 4-wing luminous butterfly silhouette (forewings + hindwings, angled gently upward)
	var body_f: Vector3 = Vector3(0.0, 0.0, 0.08)
	var body_b: Vector3 = Vector3(0.0, 0.0, -0.09)
	var body_c: Vector3 = Vector3(0.0, 0.0, 0.0)

	for side_s: float in [-1.0, 1.0]:
		var fw_tip: Vector3 = Vector3(side_s * 0.26, 0.14, 0.13)
		var fw_mid: Vector3 = Vector3(side_s * 0.22, 0.11, -0.02)
		var hw_tip: Vector3 = Vector3(side_s * 0.17, 0.09, -0.16)

		# Forewing
		st.set_color(Color(0.95, 0.95, 1.0))
		st.add_vertex(body_f)
		st.set_color(Color(1.0, 1.0, 1.0))
		st.add_vertex(fw_tip)
		st.set_color(Color(1.0, 1.0, 1.0))
		st.add_vertex(fw_mid)

		st.set_color(Color(0.95, 0.95, 1.0))
		st.add_vertex(body_f)
		st.set_color(Color(1.0, 1.0, 1.0))
		st.add_vertex(fw_mid)
		st.set_color(Color(0.92, 0.92, 0.98))
		st.add_vertex(body_c)

		# Hindwing
		st.set_color(Color(0.92, 0.92, 0.98))
		st.add_vertex(body_c)
		st.set_color(Color(1.0, 1.0, 1.0))
		st.add_vertex(fw_mid)
		st.set_color(Color(1.0, 1.0, 1.0))
		st.add_vertex(hw_tip)

		st.set_color(Color(0.92, 0.92, 0.98))
		st.add_vertex(body_c)
		st.set_color(Color(1.0, 1.0, 1.0))
		st.add_vertex(hw_tip)
		st.set_color(Color(0.90, 0.90, 0.96))
		st.add_vertex(body_b)

	st.generate_normals()
	return st.commit()


func _create_soft_radial_texture(size_px: int) -> ImageTexture:
	var img: Image = Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	var half: float = float(size_px - 1) * 0.5
	for y: int in range(size_px):
		for x: int in range(size_px):
			var dx: float = (float(x) - half) / maxf(1.0, half)
			var dy: float = (float(y) - half) / maxf(1.0, half)
			var dist: float = sqrt(dx * dx + dy * dy)
			var alpha_val: float = clampf(1.0 - dist, 0.0, 1.0)
			alpha_val = alpha_val * alpha_val * (3.0 - 2.0 * alpha_val)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha_val))
	return ImageTexture.create_from_image(img)


func _hash01(n: int) -> float:
	var s: float = sin(float(n) * 12.9898 + 78.233) * 43758.5453
	return s - floorf(s)


# ---------------------------------------------------------------------------
# Graceful Procedural Fallbacks (used only if a .glb is not yet imported)
# ---------------------------------------------------------------------------

func _create_fallback_sakura_tree(verdant_green: bool = false) -> Node3D:
	var tree: Node3D = Node3D.new()

	var trunk_mesh: CylinderMesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.20
	trunk_mesh.bottom_radius = 0.36
	trunk_mesh.height = 3.2
	trunk_mesh.radial_segments = 10

	var trunk: MeshInstance3D = MeshInstance3D.new()
	trunk.mesh = trunk_mesh
	trunk.material_override = _mat_bark
	trunk.position = Vector3(0.0, 1.55, 0.0)
	trunk.rotation = Vector3(0.0, 0.0, deg_to_rad(5.0))
	tree.add_child(trunk)

	var canopy_offsets: Array[Vector3] = [
		Vector3(0.0, 3.6, 0.0),
		Vector3(-1.1, 3.3, 0.55),
		Vector3(1.15, 3.45, -0.4),
		Vector3(0.35, 4.15, 0.45),
		Vector3(-0.55, 3.9, -0.75),
	]
	var canopy_radii: Array[float] = [1.55, 1.25, 1.30, 1.15, 1.10]
	var canopy_mats: Array[StandardMaterial3D] = [
		_mat_canopy_emerald_deep if verdant_green else _mat_blossom_pink,
		_mat_canopy_emerald_sunlit if verdant_green else _mat_blossom_blush,
		_mat_canopy_emerald_deep if verdant_green else _mat_blossom_pink,
		_mat_leaf_mint if verdant_green else _mat_blossom_blush,
		_mat_canopy_emerald_sunlit if verdant_green else _mat_blossom_lilac,
	]

	for i: int in range(canopy_offsets.size()):
		var puff_mesh: SphereMesh = SphereMesh.new()
		puff_mesh.radius = canopy_radii[i]
		puff_mesh.height = canopy_radii[i] * 1.35
		puff_mesh.radial_segments = 12
		puff_mesh.rings = 8

		var puff: MeshInstance3D = MeshInstance3D.new()
		puff.mesh = puff_mesh
		puff.material_override = canopy_mats[i]
		puff.position = canopy_offsets[i]
		tree.add_child(puff)

	return tree


func _create_fallback_lush_bush() -> Node3D:
	var bush: Node3D = Node3D.new()
	var leaf_mats: Array[StandardMaterial3D] = [
		_mat_leaf_emerald,
		_mat_leaf_spring,
		_mat_leaf_mint,
	]
	var cluster_offsets: Array[Vector3] = [
		Vector3(-0.72, 0.48, 0.0),
		Vector3(0.0, 0.62, 0.0),
		Vector3(0.72, 0.48, 0.0),
		Vector3(-0.36, 0.72, 0.24),
		Vector3(0.36, 0.72, -0.24),
	]
	for i: int in range(cluster_offsets.size()):
		var clump: MeshInstance3D = MeshInstance3D.new()
		clump.mesh = _mesh_leaf_cluster
		clump.material_override = leaf_mats[i % leaf_mats.size()]
		clump.position = cluster_offsets[i]
		clump.scale = Vector3(2.4, 2.2, 2.2)
		clump.rotation = Vector3(0.15 * float(i - 2), float(i) * 0.7, 0.1 * float(i - 2))
		bush.add_child(clump)

	var rose_offsets: Array[Vector3] = [
		Vector3(-0.62, 0.86, 0.26),
		Vector3(0.0, 1.05, 0.18),
		Vector3(0.62, 0.84, -0.22),
	]
	for j: int in range(rose_offsets.size()):
		var rose: MeshInstance3D = MeshInstance3D.new()
		rose.mesh = _mesh_blossom_small
		rose.material_override = _mat_blossom_pink if j % 2 == 0 else _mat_blossom_blush
		rose.position = rose_offsets[j]
		bush.add_child(rose)

	return bush


func _create_fallback_garden_planter() -> Node3D:
	var planter: Node3D = Node3D.new()

	var basin_mesh: BoxMesh = BoxMesh.new()
	basin_mesh.size = Vector3(1.25, 0.62, 0.95)
	var basin: MeshInstance3D = MeshInstance3D.new()
	basin.mesh = basin_mesh
	basin.material_override = _mat_marble
	basin.position = Vector3(0.0, 0.31, 0.0)
	planter.add_child(basin)

	var rim_mesh: BoxMesh = BoxMesh.new()
	rim_mesh.size = Vector3(1.36, 0.10, 1.06)
	var rim: MeshInstance3D = MeshInstance3D.new()
	rim.mesh = rim_mesh
	rim.material_override = _mat_gold_trim
	rim.position = Vector3(0.0, 0.64, 0.0)
	planter.add_child(rim)

	var foliage_mesh: SphereMesh = SphereMesh.new()
	foliage_mesh.radius = 0.42
	foliage_mesh.height = 0.52
	foliage_mesh.radial_segments = 10
	foliage_mesh.rings = 6

	var foliage_positions: Array[Vector3] = [
		Vector3(-0.28, 0.78, 0.0),
		Vector3(0.28, 0.78, 0.0),
		Vector3(0.0, 0.86, 0.0),
	]
	for i: int in range(foliage_positions.size()):
		var bush: MeshInstance3D = MeshInstance3D.new()
		bush.mesh = foliage_mesh
		bush.material_override = _mat_leaf_spring if i != 1 else _mat_leaf_emerald
		bush.position = foliage_positions[i]
		planter.add_child(bush)

	var bloom_positions: Array[Vector3] = [
		Vector3(-0.34, 1.00, 0.14),
		Vector3(0.02, 1.08, -0.10),
		Vector3(0.32, 0.98, 0.12),
		Vector3(-0.08, 1.02, 0.22),
	]
	var bloom_mats: Array[StandardMaterial3D] = [
		_mat_blossom_pink,
		_mat_blossom_blush,
		_mat_blossom_lilac,
		_mat_blossom_pink,
	]
	for i: int in range(bloom_positions.size()):
		var bloom: MeshInstance3D = MeshInstance3D.new()
		bloom.mesh = _mesh_blossom_cluster
		bloom.material_override = bloom_mats[i]
		bloom.position = bloom_positions[i]
		planter.add_child(bloom)

	return planter


func _create_fallback_celestial_ornament() -> Node3D:
	var ornament: Node3D = Node3D.new()

	var plinth_mesh: CylinderMesh = CylinderMesh.new()
	plinth_mesh.top_radius = 0.34
	plinth_mesh.bottom_radius = 0.44
	plinth_mesh.height = 0.48
	plinth_mesh.radial_segments = 10
	var plinth: MeshInstance3D = MeshInstance3D.new()
	plinth.mesh = plinth_mesh
	plinth.material_override = _mat_marble
	plinth.position = Vector3(0.0, 0.24, 0.0)
	ornament.add_child(plinth)

	var pole_mesh: CylinderMesh = CylinderMesh.new()
	pole_mesh.top_radius = 0.05
	pole_mesh.bottom_radius = 0.08
	pole_mesh.height = 2.75
	pole_mesh.radial_segments = 8
	var pole: MeshInstance3D = MeshInstance3D.new()
	pole.mesh = pole_mesh
	pole.material_override = _mat_gold_trim
	pole.position = Vector3(0.0, 1.75, 0.0)
	ornament.add_child(pole)

	var crystal_mesh: SphereMesh = SphereMesh.new()
	crystal_mesh.radius = 0.20
	crystal_mesh.height = 0.52
	crystal_mesh.radial_segments = 6
	crystal_mesh.rings = 4
	var crystal: MeshInstance3D = MeshInstance3D.new()
	crystal.mesh = crystal_mesh
	crystal.material_override = _mat_crystal
	crystal.position = Vector3(0.0, 3.25, 0.0)
	ornament.add_child(crystal)

	var banner_mesh: BoxMesh = BoxMesh.new()
	banner_mesh.size = Vector3(0.46, 1.45, 0.04)
	var banner: MeshInstance3D = MeshInstance3D.new()
	banner.mesh = banner_mesh
	banner.material_override = _mat_silk
	banner.position = Vector3(0.26, 2.25, 0.0)
	ornament.add_child(banner)

	return ornament
