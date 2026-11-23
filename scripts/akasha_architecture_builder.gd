class_name AkashaArchitectureBuilder
extends Node3D
## Procedural 3D World & Cathedral Architect for the Akashic Chronicles Prologue.
## Builds the monumental sanctuary space along the -Z axis (z = 46 down to z = -280)
## inspired by Sky: Children of the Light and the Art Deco celestial palette
## (#0A1F44, #122D6B, #1E4B9A, #F6D36B), with optional .glb asset override slots.

const COLOR_DEEP_NAVY := Color("#0A1F44")
const COLOR_INDIGO_STONE := Color("#0E234D")
const COLOR_MID_INDIGO := Color("#122D6B")
const COLOR_COBALT_ACCENT := Color("#1E4B9A")
const COLOR_GOLD_FILIGREE := Color("#F6D36B")
const COLOR_GOLD_BRASS := Color("#D8AE48")
const COLOR_MENTOR_CYAN := Color("#58C4FF")

const CATHEDRAL_POSITION := Vector3(0.0, 0.0, -280.0)

const ISLAND_COORDS := [
	Vector3(-28.0, 3.5, -36.0),   # Gate of Awakening — West Twin Island
	Vector3(28.0, 3.5, -36.0),    # Gate of Awakening — East Twin Island
	Vector3(0.0, 6.5, -106.0),    # Heart of the Sky — Central Axial Sanctuary Island
	Vector3(-34.0, 9.5, -176.0),  # Pillars of Memory — West Grand Twin Island
	Vector3(34.0, 9.5, -176.0),   # Pillars of Memory — East Grand Twin Island
]

const PLAZA_LANTERN_COORDS := [
	Vector3(-5.6, 0.0, 41.0),
	Vector3(5.6, 0.0, 41.0),
	Vector3(-5.6, 0.0, 27.0),
	Vector3(5.6, 0.0, 27.0),
]

## Optional .glb override paths (see docs/ASSET_PIPELINE_3D.md).
## When a valid .glb/.gltf/.tscn exists at the path, it replaces the procedural module.
@export_group("3D Asset Overrides (.glb)")
@export var plaza_model_path: String = "res://assets/models/architecture/monolith_plaza.glb"
@export var viaduct_arch_model_path: String = "res://assets/models/architecture/viaduct_arch.glb"
@export var temple_island_model_path: String = "res://assets/models/architecture/temple_island.glb"
@export var cathedral_model_path: String = "res://assets/models/architecture/akasha_cathedral.glb"

@export_group("Animation")
@export var astrolabe_speed_scale: float = 1.0
@export var mentor_bob_amplitude: float = 0.85
@export var mentor_bob_speed: float = 0.55

const MARBLE_SHADER: Shader = preload("res://shaders/akasha_marble.gdshader")
const GOD_RAYS_SHADER: Shader = preload("res://shaders/god_rays.gdshader")
const MENTOR_SHADER: Shader = preload("res://shaders/ethereal_mentor.gdshader")
const MEADOW_GROUND_SHADER_PATH := "res://shaders/akasha_meadow_ground.gdshader"

var _mat_indigo_stone: Material
var _mat_dark_obsidian: Material
var _mat_polished_marble: Material
var _mat_cobalt_trim: Material
var _mat_castle_white_stone: Material
var _mat_castle_floor_marble: Material
var _mat_castle_blue_roof: StandardMaterial3D
var _mat_gold_filigree: StandardMaterial3D
var _mat_gold_brass: StandardMaterial3D
var _mat_gold_glow_accent: StandardMaterial3D
var _mat_gold_thread: StandardMaterial3D
var _mat_light_core: StandardMaterial3D
var _mat_glass_skylight: StandardMaterial3D
var _mat_warm_window: StandardMaterial3D
var _mat_island_grass: Material
var _mat_island_rock: Material
var _mat_waterfall: StandardMaterial3D
var _mat_island_vine: StandardMaterial3D
var _mat_mentor_body: Material
var _mat_mentor_halo: StandardMaterial3D
var _mat_god_rays: ShaderMaterial
var _mat_island_rays: ShaderMaterial
var _mat_skylight_ray: ShaderMaterial

var _astrolabe_rings: Array[Node3D] = []
var _mentor_nodes: Array[Node3D] = []
var _mentor_base_y: Array[float] = []
var _mentor_halos: Array[Node3D] = []
var _elapsed_time: float = 0.0
var _is_built: bool = false
var _sanitized_mesh_cache: Dictionary = {}


func _ready() -> void:
	if not _is_built:
		build_architecture()


func _process(delta: float) -> void:
	_elapsed_time += delta

	# Counter-rotating golden 3D Astrolabe Rings at the Colossal Cathedral
	if _astrolabe_rings.size() >= 3:
		var spd := astrolabe_speed_scale
		_astrolabe_rings[0].rotate_y(delta * 0.14 * spd)
		_astrolabe_rings[0].rotate_z(delta * 0.05 * spd)

		_astrolabe_rings[1].rotate_x(-delta * 0.22 * spd)
		_astrolabe_rings[1].rotate_y(-delta * 0.11 * spd)

		_astrolabe_rings[2].rotate_z(delta * 0.34 * spd)
		_astrolabe_rings[2].rotate_x(delta * 0.16 * spd)

	# Subtle ethereal breathing & halo drift for the two colossal Mentor silhouettes
	for i in range(_mentor_nodes.size()):
		var mentor := _mentor_nodes[i]
		var phase := float(i) * 1.9
		mentor.position.y = _mentor_base_y[i] + sin(_elapsed_time * mentor_bob_speed + phase) * mentor_bob_amplitude

	for i in range(_mentor_halos.size()):
		var dir := 1.0 if i % 2 == 0 else -1.0
		_mentor_halos[i].rotate_z(delta * 0.18 * dir)


## Builds the complete Prologue architectural space.
func build_architecture() -> void:
	if _is_built:
		return
	_is_built = true

	_init_materials()
	_build_starting_monolith_plaza()
	_build_indigo_viaduct()
	_build_floating_temple_islands()
	_build_colossal_cathedral()
	_build_ethereal_mentor_silhouettes()


## Returns the exact world coordinates on the starting bridge & floating islands
## where Sprint 2's interactive Stone Lanterns should be placed.
func get_lantern_anchor_positions() -> Array[Vector3]:
	var anchors: Array[Vector3] = []
	for p in PLAZA_LANTERN_COORDS:
		var v: Vector3 = p
		anchors.append(to_global(v) if is_inside_tree() else v)
	for p in ISLAND_COORDS:
		var v: Vector3 = p
		anchors.append(to_global(v) if is_inside_tree() else v)
	return anchors


## Returns the world positions of the 5 floating temple island centers.
func get_island_positions() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for p in ISLAND_COORDS:
		var v: Vector3 = p
		result.append(to_global(v) if is_inside_tree() else v)
	return result


## Returns the world position of the Colossal Akashic Astrolabe Cathedral.
func get_cathedral_position() -> Vector3:
	return to_global(CATHEDRAL_POSITION) if is_inside_tree() else CATHEDRAL_POSITION


# ---------------------------------------------------------------------------
# Materials
# ---------------------------------------------------------------------------

func _create_velvet_stone_material(
	base_col: Color,
	highlight_col: Color,
	pore_col: Color,
	roughness_val: float,
	fresnel_strength: float,
	wetness_val: float = 0.85,
	block_scale_val: float = 1.0,
	seam_strength_val: float = 0.12
) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = MARBLE_SHADER
	mat.set_shader_parameter("stone_base_color", base_col)
	mat.set_shader_parameter("stone_highlight_color", highlight_col)
	mat.set_shader_parameter("stone_pore_color", pore_col)
	mat.set_shader_parameter("horizon_tint_color", Color("#B8D8F8"))
	mat.set_shader_parameter("base_roughness", roughness_val)
	mat.set_shader_parameter("surface_specular", 0.42)
	mat.set_shader_parameter("surface_metallic", 0.02)
	mat.set_shader_parameter("fresnel_lift_strength", fresnel_strength)
	mat.set_shader_parameter("wetness_strength", wetness_val)
	mat.set_shader_parameter("block_scale", block_scale_val)
	mat.set_shader_parameter("seam_strength", seam_strength_val)
	return mat


func _init_materials() -> void:
	# Crisp Fairytale White & Celestial Sky-Blue Castle Palette (low/zero seam_strength to avoid primitive stripes)
	_mat_dark_obsidian = _create_velvet_stone_material(
		Color("#7E96B8"), Color("#9BB2D2"), Color("#5A7090"), 0.60, 0.10, 0.25, 0.90, 0.10
	)
	_mat_indigo_stone = _create_velvet_stone_material(
		Color("#F2EEE6"), Color("#FFFDF8"), Color("#CFC8BA"), 0.56, 0.12, 0.20, 0.95, 0.0
	)
	_mat_polished_marble = _create_velvet_stone_material(
		Color("#EFE9DD"), Color("#FCF9F2"), Color("#C6BBA8"), 0.48, 0.10, 0.28, 0.95, 0.12
	)
	_mat_cobalt_trim = _create_velvet_stone_material(
		Color("#3A74BE"), Color("#68A2E8"), Color("#244E8C"), 0.42, 0.16, 0.35, 1.15, 0.0
	)

	# Warm Creamy Pearl-Ivory Baroque Palace Marble (zero seams on walls, subtle 0.12 seams on floors)
	_mat_castle_white_stone = _create_velvet_stone_material(
		Color("#F4EFE5"), Color("#FFFDF7"), Color("#D4CBB9"), 0.54, 0.14, 0.18, 0.90, 0.0
	)
	_mat_castle_floor_marble = _create_velvet_stone_material(
		Color("#EFE8DA"), Color("#FDF9F0"), Color("#C8BCA6"), 0.48, 0.12, 0.24, 0.85, 0.12
	)

	# Rich Celestial Baroque Royal-Blue Satin Roof Finish (#2E6BB8)
	_mat_castle_blue_roof = StandardMaterial3D.new()
	_mat_castle_blue_roof.albedo_color = Color("#2E6BB8")
	_mat_castle_blue_roof.metallic = 0.14
	_mat_castle_blue_roof.roughness = 0.32

	# Satin Champagne Gold & Temple Brass (calm satin sheen, zero sub-pixel shimmer)
	var aged_gold_color: Color = Color("#DFC07A")
	var temple_brass_color: Color = Color("#C6A462")
	var warm_amber_emission: Color = Color("#F0D294")

	_mat_gold_filigree = StandardMaterial3D.new()
	_mat_gold_filigree.albedo_color = aged_gold_color
	_mat_gold_filigree.roughness = 0.40
	_mat_gold_filigree.metallic = 0.78
	_mat_gold_filigree.emission_enabled = true
	_mat_gold_filigree.emission = warm_amber_emission
	_mat_gold_filigree.emission_energy_multiplier = 0.10

	_mat_gold_brass = StandardMaterial3D.new()
	_mat_gold_brass.albedo_color = temple_brass_color
	_mat_gold_brass.roughness = 0.44
	_mat_gold_brass.metallic = 0.78
	_mat_gold_brass.emission_enabled = true
	_mat_gold_brass.emission = warm_amber_emission
	_mat_gold_brass.emission_energy_multiplier = 0.06

	_mat_gold_glow_accent = StandardMaterial3D.new()
	_mat_gold_glow_accent.albedo_color = Color("#F2DFB4")
	_mat_gold_glow_accent.roughness = 0.40
	_mat_gold_glow_accent.metallic = 0.55
	_mat_gold_glow_accent.emission_enabled = true
	_mat_gold_glow_accent.emission = warm_amber_emission
	_mat_gold_glow_accent.emission_energy_multiplier = 0.24

	_mat_gold_thread = StandardMaterial3D.new()
	_mat_gold_thread.albedo_color = Color("#EFE0BA")
	_mat_gold_thread.roughness = 0.38
	_mat_gold_thread.metallic = 0.55
	_mat_gold_thread.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_gold_thread.emission_enabled = true
	_mat_gold_thread.emission = warm_amber_emission
	_mat_gold_thread.emission_energy_multiplier = 0.50

	_mat_light_core = StandardMaterial3D.new()
	_mat_light_core.albedo_color = Color("#FFF6D4")
	_mat_light_core.roughness = 0.16
	_mat_light_core.emission_enabled = true
	_mat_light_core.emission = aged_gold_color
	_mat_light_core.emission_energy_multiplier = 1.65

	# Luminous stained-glass / pearl palace window & skylight dome sheen
	_mat_glass_skylight = StandardMaterial3D.new()
	_mat_glass_skylight.albedo_color = Color(0.76, 0.90, 1.0, 0.48)
	_mat_glass_skylight.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_glass_skylight.roughness = 0.12
	_mat_glass_skylight.metallic = 0.12
	_mat_glass_skylight.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_glass_skylight.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	_mat_glass_skylight.emission_enabled = true
	_mat_glass_skylight.emission = Color("#D6EEFF")
	_mat_glass_skylight.emission_energy_multiplier = 0.42

	# Warm glowing gothic-baroque windows on Castle towers & clerestory
	_mat_warm_window = StandardMaterial3D.new()
	_mat_warm_window.albedo_color = Color("#FFF0C8")
	_mat_warm_window.roughness = 0.26
	_mat_warm_window.metallic = 0.02
	_mat_warm_window.emission_enabled = true
	_mat_warm_window.emission = Color("#FFE2A0")
	_mat_warm_window.emission_energy_multiplier = 1.35

	# Velvety sunlit meadow ground shader for CastleIslandGrass (with safe matte vertex-colored fallback)
	var meadow_shader: Shader = null
	if ResourceLoader.exists(MEADOW_GROUND_SHADER_PATH):
		meadow_shader = load(MEADOW_GROUND_SHADER_PATH) as Shader
	if meadow_shader != null:
		var meadow_mat: ShaderMaterial = ShaderMaterial.new()
		meadow_mat.shader = meadow_shader
		_mat_island_grass = meadow_mat
	else:
		var grass_fallback: StandardMaterial3D = StandardMaterial3D.new()
		grass_fallback.albedo_color = Color("#56AA52")
		grass_fallback.vertex_color_use_as_albedo = true
		grass_fallback.roughness = 0.88
		grass_fallback.metallic = 0.0
		_mat_island_grass = grass_fallback

	_mat_island_rock = _create_velvet_stone_material(
		Color("#C8C4BC"), Color("#E2DED4"), Color("#8A92A0"), 0.78, 0.12, 0.18, 0.45, 0.0
	)

	_mat_waterfall = StandardMaterial3D.new()
	_mat_waterfall.albedo_color = Color(0.408, 0.863, 0.910, 0.76)
	_mat_waterfall.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_waterfall.roughness = 0.16
	_mat_waterfall.metallic = 0.02
	_mat_waterfall.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_waterfall.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	_mat_waterfall.emission_enabled = true
	_mat_waterfall.emission = Color("#A8F4FF")
	_mat_waterfall.emission_energy_multiplier = 0.35

	_mat_island_vine = StandardMaterial3D.new()
	_mat_island_vine.albedo_color = Color("#2E7D44")
	_mat_island_vine.roughness = 0.72
	_mat_island_vine.metallic = 0.0
	_mat_island_vine.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mentor_mat: ShaderMaterial = ShaderMaterial.new()
	mentor_mat.shader = MENTOR_SHADER
	_mat_mentor_body = mentor_mat

	_mat_mentor_halo = StandardMaterial3D.new()
	_mat_mentor_halo.albedo_color = Color(0.86, 0.94, 1.0, 0.48)
	_mat_mentor_halo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_mentor_halo.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat_mentor_halo.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_mentor_halo.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_mat_mentor_halo.emission_enabled = true
	_mat_mentor_halo.emission = Color("#D8F0FF")
	_mat_mentor_halo.emission_energy_multiplier = 0.75

	_mat_god_rays = ShaderMaterial.new()
	_mat_god_rays.shader = GOD_RAYS_SHADER
	_mat_god_rays.set_shader_parameter("intensity", 0.42)
	_mat_god_rays.set_shader_parameter("edge_falloff", 2.0)
	_mat_god_rays.set_shader_parameter("shimmer_strength", 0.30)
	_mat_god_rays.set_shader_parameter("near_fade_min", 6.0)
	_mat_god_rays.set_shader_parameter("near_fade_max", 24.0)

	_mat_island_rays = ShaderMaterial.new()
	_mat_island_rays.shader = GOD_RAYS_SHADER
	_mat_island_rays.set_shader_parameter("intensity", 0.24)
	_mat_island_rays.set_shader_parameter("edge_falloff", 2.35)
	_mat_island_rays.set_shader_parameter("shimmer_strength", 0.24)
	_mat_island_rays.set_shader_parameter("near_fade_min", 3.0)
	_mat_island_rays.set_shader_parameter("near_fade_max", 14.0)

	_mat_skylight_ray = ShaderMaterial.new()
	_mat_skylight_ray.shader = GOD_RAYS_SHADER
	_mat_skylight_ray.set_shader_parameter("intensity", 0.28)
	_mat_skylight_ray.set_shader_parameter("edge_falloff", 2.4)
	_mat_skylight_ray.set_shader_parameter("shimmer_strength", 0.20)
	_mat_skylight_ray.set_shader_parameter("near_fade_min", 2.0)
	_mat_skylight_ray.set_shader_parameter("near_fade_max", 9.0)


# ---------------------------------------------------------------------------
# a) Starting Monolith Plaza (z = 24..46, y = 0)
# ---------------------------------------------------------------------------

func _add_plaza_colliders(root: Node3D) -> void:
	# Main walkable deck collider (top strictly at y = 0.0, covers z = 23.5..46.5)
	_add_box_collider(root, "PlazaSurfaceCollider", Vector3(16.0, 2.4, 23.0), Vector3(0.0, -1.2, 35.0))
	# Forward ceremonial prow collider (top strictly at y = 0.0, covers down to z = 19.25)
	_add_box_collider(root, "PlazaProwCollider", Vector3(11.0, 2.4, 5.5), Vector3(0.0, -1.2, 22.0))
	# Watertight invisible balustrade guard colliders along x = -7.0 and x = +7.0 (z = 23.75..46.75) + rear parapet at z = 46.2
	# (H = 3.0 m with overlapping rear corners; forward prow at z = 20..24 stays 100% open to walk/glide toward the floating islands)
	_add_box_collider(root, "PlazaBalustradeCollider_L", Vector3(1.0, 3.0, 23.0), Vector3(-7.0, 1.5, 35.25))
	_add_box_collider(root, "PlazaBalustradeCollider_R", Vector3(1.0, 3.0, 23.0), Vector3(7.0, 1.5, 35.25))
	_add_box_collider(root, "PlazaBalustradeCollider_Back", Vector3(15.2, 3.0, 1.0), Vector3(0.0, 1.5, 46.2))


func _build_starting_monolith_plaza() -> void:
	var root := Node3D.new()
	root.name = "StartingMonolithPlaza"
	add_child(root)

	if _try_instantiate_override(plaza_model_path, root, Vector3(0.0, 0.0, 35.0), "plaza"):
		_add_plaza_colliders(root)
		return

	var plaza_center := Vector3(0.0, 0.0, 35.0)
	var width := 16.0
	var length := 22.0
	var deck_thickness := 2.4

	# Main polished dark-indigo bridge deck (top surface strictly at y = 0.0)
	_add_box_mesh(
		root, "PlazaDeck",
		Vector3(width, deck_thickness, length),
		Vector3(0.0, -deck_thickness * 0.5, plaza_center.z),
		_mat_dark_obsidian
	)
	_add_plaza_colliders(root)

	# Forward ceremonial cantilevered prow (z = 24..20.5, top surface at y = 0.0)
	_add_box_mesh(
		root, "PlazaProw",
		Vector3(9.6, 1.8, 3.6),
		Vector3(0.0, -0.9, 22.2),
		_mat_polished_marble
	)

	# Stepped Art Deco beveled golden edges along sides and ends
	for side: float in [-1.0, 1.0]:
		var x_outer: float = side * (width * 0.5 + 0.18)
		_add_box_mesh(
			root, "GoldBevelTop_%s" % ("L" if side < 0 else "R"),
			Vector3(0.45, 0.24, length + 0.4),
			Vector3(x_outer, -0.08, plaza_center.z),
			_mat_gold_filigree
		)
		_add_box_mesh(
			root, "IndigoCurb_%s" % ("L" if side < 0 else "R"),
			Vector3(0.75, 0.55, length),
			Vector3(side * (width * 0.5 - 0.35), 0.275, plaza_center.z),
			_mat_indigo_stone
		)
		_add_box_mesh(
			root, "CurbGoldTrim_%s" % ("L" if side < 0 else "R"),
			Vector3(0.14, 0.12, length - 0.4),
			Vector3(side * (width * 0.5 - 0.72), 0.56, plaza_center.z),
			_mat_gold_filigree
		)

	# Front & back beveled golden edge trim
	_add_box_mesh(root, "GoldEdgeBack", Vector3(width + 0.6, 0.26, 0.45), Vector3(0.0, -0.08, 46.1), _mat_gold_filigree)
	_add_box_mesh(root, "GoldEdgeFront", Vector3(width + 0.6, 0.26, 0.45), Vector3(0.0, -0.08, 23.9), _mat_gold_filigree)
	_add_box_mesh(root, "GoldEdgeProw", Vector3(10.0, 0.22, 0.35), Vector3(0.0, -0.06, 20.4), _mat_gold_filigree)

	# 4 Art Deco corner obelisk pylons framing the starting bridge
	var pylon_coords := [
		Vector3(-7.4, 0.0, 44.8),
		Vector3(7.4, 0.0, 44.8),
		Vector3(-7.4, 0.0, 25.2),
		Vector3(7.4, 0.0, 25.2),
	]
	for i in range(pylon_coords.size()):
		var p: Vector3 = pylon_coords[i]
		var pylon := Node3D.new()
		pylon.name = "PlazaPylon_%d" % i
		pylon.position = p
		root.add_child(pylon)

		_add_box_mesh(pylon, "Base", Vector3(1.5, 1.2, 1.5), Vector3(0.0, 0.6, 0.0), _mat_indigo_stone)
		_add_box_mesh(pylon, "Shaft", Vector3(1.0, 4.6, 1.0), Vector3(0.0, 3.5, 0.0), _mat_dark_obsidian)
		_add_box_mesh(pylon, "GoldBand", Vector3(1.16, 0.22, 1.16), Vector3(0.0, 5.2, 0.0), _mat_gold_filigree)
		_add_cylinder_mesh(pylon, "SpireCap", 0.08, 0.55, 1.8, 4, Vector3(0.0, 6.7, 0.0), _mat_gold_brass)

	# Inlaid glowing golden astrolabe rings on the plaza floor (clean >= 0.04m separation from deck & each other)
	var ring_y: float = 0.042
	var spoke_y: float = 0.056
	var runway_y: float = 0.068
	var medallion_y: float = 0.082
	var ring_radii := [
		Vector2(5.6, 5.95),
		Vector2(3.8, 4.02),
		Vector2(1.85, 2.02),
	]
	for i in range(ring_radii.size()):
		var r: Vector2 = ring_radii[i]
		var ring := _add_torus_mesh(
			root, "FloorAstrolabeRing_%d" % i,
			r.x, r.y, 48, 12,
			Vector3(0.0, ring_y, plaza_center.z),
			_mat_gold_filigree
		)
		ring.scale = Vector3(1.0, 0.08, 1.0)

	# 8 radial golden compass spokes inlaid into the plaza floor
	for i in range(4):
		var spoke := _add_box_mesh(
			root, "FloorCompassSpoke_%d" % i,
			Vector3(0.14, 0.025, 11.6),
			Vector3(0.0, spoke_y + float(i) * 0.004, plaza_center.z),
			_mat_gold_filigree
		)
		spoke.rotation.y = deg_to_rad(float(i) * 45.0)

	# Center glowing compass disc & forward directional runway stripe
	_add_cylinder_mesh(root, "FloorMedallion", 0.65, 0.65, 0.03, 24, Vector3(0.0, medallion_y, plaza_center.z), _mat_gold_filigree)
	_add_box_mesh(root, "RunwayStrip", Vector3(0.28, 0.025, 14.0), Vector3(0.0, runway_y, 27.5), _mat_gold_filigree)

	# Monumental tapered monolith undercroft descending into the cloud sea
	_add_box_mesh(root, "UndercroftTier1", Vector3(14.0, 6.0, 19.5), Vector3(0.0, -5.4, plaza_center.z), _mat_indigo_stone)
	_add_cylinder_mesh(root, "UndercroftMonolith", 8.8, 3.2, 34.0, 8, Vector3(0.0, -25.0, plaza_center.z), _mat_dark_obsidian)
	_add_box_mesh(root, "UndercroftGoldRib_L", Vector3(0.3, 28.0, 0.5), Vector3(-5.8, -19.0, plaza_center.z), _mat_gold_filigree)
	_add_box_mesh(root, "UndercroftGoldRib_R", Vector3(0.3, 28.0, 0.5), Vector3(5.8, -19.0, plaza_center.z), _mat_gold_filigree)


# ---------------------------------------------------------------------------
# b) Symmetrical Twin Flanking Celestial Viaducts (x = -56.0 & x = +56.0, z = 20..-240)
# ---------------------------------------------------------------------------

func _build_indigo_viaduct() -> void:
	var root := Node3D.new()
	root.name = "IndigoViaduct"
	add_child(root)

	var arch_count: int = 12
	var z_start: float = 20.0
	var z_end: float = -240.0
	var total_length: float = z_start - z_end # 260.0 m
	var bay_span: float = total_length / float(arch_count) # ~21.667 m
	var deck_width: float = 10.0
	var deck_collider_width: float = 10.5
	var deck_top_y: float = 14.0
	var deck_thickness: float = 2.2
	var pier_bottom_y: float = -66.0
	var deck_center_z: float = (z_start + z_end) * 0.5

	var has_glb: bool = not viaduct_arch_model_path.is_empty() and ResourceLoader.exists(viaduct_arch_model_path)
	var viaduct_sides: Array[float] = [-1.0, 1.0]

	for side_sign: float in viaduct_sides:
		var side_tag: String = "W" if side_sign < 0.0 else "E"
		var viaduct_x: float = side_sign * 56.0
		var wing_root: Node3D = Node3D.new()
		wing_root.name = "CelestialViaduct_%s" % side_tag
		root.add_child(wing_root)

		# Continuous solid walkable roadway collider along EACH viaduct (top strictly at y = deck_top_y)
		_add_box_collider(
			wing_root, "ViaductDeckCollider_%s" % side_tag,
			Vector3(deck_collider_width, deck_thickness, total_length + 4.0),
			Vector3(viaduct_x, deck_top_y - deck_thickness * 0.5, deck_center_z)
		)
		# Watertight invisible parapet/railing guard colliders along both edges of each viaduct (H = 2.8 m, 8.4 m clear roadway inside)
		_add_box_collider(
			wing_root, "ViaductParapetCollider_%s_L" % side_tag,
			Vector3(1.1, 2.8, total_length + 4.0),
			Vector3(viaduct_x - 4.75, deck_top_y + 1.4, deck_center_z)
		)
		_add_box_collider(
			wing_root, "ViaductParapetCollider_%s_R" % side_tag,
			Vector3(1.1, 2.8, total_length + 4.0),
			Vector3(viaduct_x + 4.75, deck_top_y + 1.4, deck_center_z)
		)

		if has_glb:
			var loaded_any: bool = false
			# Each viaduct_arch.glb bay spans Z[-10.85, +10.85] (21.70m) while bay_span is 21.667m;
			# scale Z slightly so adjacent bays butt cleanly with zero coplanar seam overlap.
			var bay_z_scale: float = (bay_span - 0.006) / 21.70
			for i: int in range(arch_count):
				var bay_z: float = z_start - (float(i) + 0.5) * bay_span
				var prev_count: int = wing_root.get_child_count()
				if _try_instantiate_override(viaduct_arch_model_path, wing_root, Vector3(viaduct_x, deck_top_y, bay_z), "viaduct"):
					loaded_any = true
					if wing_root.get_child_count() > prev_count:
						var bay_node: Node = wing_root.get_child(wing_root.get_child_count() - 1)
						if bay_node is Node3D:
							var bay_3d: Node3D = bay_node as Node3D
							bay_3d.scale.z = bay_z_scale
							if side_sign < 0.0:
								bay_3d.rotation_degrees.y = 180.0
			if loaded_any:
				continue

		# Procedural fallback when viaduct_arch.glb is absent
		_add_box_mesh(
			wing_root, "ViaductDeck_%s" % side_tag,
			Vector3(deck_width, deck_thickness, total_length + 4.0),
			Vector3(viaduct_x, deck_top_y - deck_thickness * 0.5, deck_center_z),
			_mat_indigo_stone
		)

		for edge_side: float in [-1.0, 1.0]:
			var rail_x: float = viaduct_x + edge_side * (deck_width * 0.5 + 0.15)
			_add_box_mesh(
				wing_root, "ViaductGoldCornice_%s_%s" % [side_tag, "L" if edge_side < 0.0 else "R"],
				Vector3(0.38, 0.36, total_length + 4.4),
				Vector3(rail_x, deck_top_y - 0.15, deck_center_z),
				_mat_gold_filigree
			)
			_add_box_mesh(
				wing_root, "ViaductParapet_%s_%s" % [side_tag, "L" if edge_side < 0.0 else "R"],
				Vector3(0.7, 1.25, total_length + 4.0),
				Vector3(viaduct_x + edge_side * (deck_width * 0.5 - 0.35), deck_top_y + 0.625, deck_center_z),
				_mat_dark_obsidian
			)

		var pier_height: float = (deck_top_y - deck_thickness) - pier_bottom_y
		var pier_center_y: float = pier_bottom_y + pier_height * 0.5
		var inner_dir: float = -side_sign

		for i: int in range(arch_count + 1):
			var pz: float = z_start - float(i) * bay_span
			var pier: Node3D = Node3D.new()
			pier.name = "ViaductPier_%s_%02d" % [side_tag, i]
			pier.position = Vector3(viaduct_x, 0.0, pz)
			wing_root.add_child(pier)

			_add_box_mesh(pier, "PierCore", Vector3(deck_width - 1.2, pier_height, 4.2), Vector3(0.0, pier_center_y, 0.0), _mat_indigo_stone)
			_add_box_mesh(pier, "PierCapital", Vector3(deck_width + 0.6, 2.2, 5.2), Vector3(0.0, deck_top_y - deck_thickness - 1.1, 0.0), _mat_dark_obsidian)
			for edge_side: float in [-1.0, 1.0]:
				_add_box_mesh(
					pier, "GoldFiligree_%s" % ("In" if edge_side < 0.0 else "Out"),
					Vector3(0.28, pier_height - 4.0, 0.55),
					Vector3(edge_side * (deck_width * 0.5 - 0.45), pier_center_y, 0.0),
					_mat_gold_filigree
				)
			_add_box_mesh(pier, "FinialBase", Vector3(1.1, 2.4, 1.1), Vector3(inner_dir * (deck_width * 0.5 - 0.35), deck_top_y + 2.2, 0.0), _mat_dark_obsidian)
			_add_cylinder_mesh(pier, "FinialTip", 0.05, 0.42, 1.4, 4, Vector3(inner_dir * (deck_width * 0.5 - 0.35), deck_top_y + 4.1, 0.0), _mat_gold_filigree)

		for i: int in range(arch_count):
			var bay_z: float = z_start - (float(i) + 0.5) * bay_span
			_build_viaduct_arch_bay(wing_root, i, viaduct_x, deck_top_y - deck_thickness, bay_z, bay_span, deck_width, inner_dir)


func _build_viaduct_arch_bay(
	parent: Node3D,
	index: int,
	center_x: float,
	spring_top_y: float,
	center_z: float,
	span: float,
	width: float,
	inward_x_sign: float = -1.0
) -> void:
	var bay := Node3D.new()
	bay.name = "ViaductArch_%02d" % index
	bay.position = Vector3(center_x, spring_top_y, center_z)
	parent.add_child(bay)

	var arch_radius := (span - 4.0) * 0.5 # ~8.83 m clear half-span
	var arch_center_y := -arch_radius - 1.2
	var segments := 9

	# Curved stone arch voussoirs + golden inner arch filigree
	for s in range(segments):
		var t0 := float(s) / float(segments)
		var t1 := float(s + 1) / float(segments)
		var angle: float = lerpf(0.08 * PI, 0.92 * PI, (t0 + t1) * 0.5)
		var seg_len := (PI * 0.84 * arch_radius) / float(segments) + 0.45

		var local_z := cos(angle) * arch_radius
		var local_y := arch_center_y + sin(angle) * arch_radius

		var stone := _add_box_mesh(
			bay, "Voussoir_%d" % s,
			Vector3(width - 1.5, 1.6, seg_len),
			Vector3(0.0, local_y, local_z),
			_mat_polished_marble
		)
		stone.rotation.x = angle - PI * 0.5

		# Glowing golden inner arch trim on the avenue-facing side
		var trim := _add_box_mesh(
			bay, "ArchGoldTrim_%d" % s,
			Vector3(0.32, 0.34, seg_len + 0.1),
			Vector3(inward_x_sign * (width * 0.5 - 0.65), local_y - 0.65 * sin(angle), local_z - 0.65 * cos(angle)),
			_mat_gold_filigree
		)
		trim.rotation.x = angle - PI * 0.5

	# Art Deco golden spandrel medallions above the arch shoulders
	for side_z: float in [-1.0, 1.0]:
		var med := _add_torus_mesh(
			bay, "SpandrelRing_%s" % ("F" if side_z < 0 else "B"),
			0.95, 1.22, 20, 8,
			Vector3(inward_x_sign * (width * 0.5 - 0.55), -2.4, side_z * (arch_radius * 0.72)),
			_mat_gold_filigree
		)
		med.rotation_degrees.z = 90.0


# ---------------------------------------------------------------------------
# c) 5 Floating Carved Indigo Temple Islands (Sacred-Geometry Avenue)
# ---------------------------------------------------------------------------

func _build_floating_temple_islands() -> void:
	var root := Node3D.new()
	root.name = "FloatingTempleIslands"
	add_child(root)

	var sym_scales: Array[float] = [0.96, 0.96, 1.12, 1.04, 1.04]
	for i in range(ISLAND_COORDS.size()):
		var pos: Vector3 = ISLAND_COORDS[i]
		var island := Node3D.new()
		island.name = "TempleIsland_%02d" % (i + 1)
		island.position = pos
		root.add_child(island)

		# Symmetrical sacred-geometry scale rhythm (Twin Gates, Grand Central Heart, Twin Pillars of Memory)
		var radius_scale: float = sym_scales[i] if i < sym_scales.size() else 1.0
		var slab_radius: float = 8.4 * radius_scale
		var slab_height: float = 1.4
		var collider_radius: float = 8.4
		var collider_height: float = 2.6

		if _try_instantiate_override(temple_island_model_path, island, Vector3.ZERO, "island"):
			_add_cylinder_collider(island, "IslandSlabCollider", collider_radius, collider_height, Vector3(0.0, -collider_height * 0.5, 0.0))
			# 8 octagonal colonnade column colliders matching temple_island.glb (5.56m clear cardinal passages)
			var glb_col_coords: Array[Vector2] = [
				Vector2(-6.0, -3.5), Vector2(-6.0, 3.5),
				Vector2(-3.5, -6.0), Vector2(-3.5, 6.0),
				Vector2(3.5, -6.0), Vector2(3.5, 6.0),
				Vector2(6.0, -3.5), Vector2(6.0, 3.5),
			]
			for ci: int in range(glb_col_coords.size()):
				var cc: Vector2 = glb_col_coords[ci]
				_add_cylinder_collider(island, "IslandColumnCollider_%d" % ci, 0.72, 12.0, Vector3(cc.x, 6.0, cc.y))
			continue

		# Top polished marble slab (top surface strictly at local y = 0.0)
		_add_cylinder_mesh(
			island, "MarbleSlab",
			slab_radius, slab_radius * 0.96, slab_height, 12,
			Vector3(0.0, -slab_height * 0.5, 0.0),
			_mat_polished_marble
		)
		_add_cylinder_collider(
			island, "IslandSlabCollider",
			collider_radius, collider_height,
			Vector3(0.0, -collider_height * 0.5, 0.0)
		)

		# Beveled golden rim around the top marble slab
		var rim := _add_torus_mesh(
			island, "SlabGoldRim",
			slab_radius - 0.12, slab_radius + 0.16, 36, 10,
			Vector3(0.0, -0.05, 0.0),
			_mat_gold_filigree
		)
		rim.scale = Vector3(1.0, 0.35, 1.0)

		# Inlaid golden sanctuary floor circle (raised to y = 0.045 to eliminate Z-fighting)
		var floor_ring := _add_torus_mesh(
			island, "FloorSanctuaryRing",
			2.6, 2.82, 32, 8,
			Vector3(0.0, 0.045, 0.0),
			_mat_gold_filigree
		)
		floor_ring.scale = Vector3(1.0, 0.08, 1.0)

		# Tapered floating carved indigo rock base underneath
		_add_cylinder_mesh(
			island, "CarvedRockUpper",
			slab_radius * 0.92, slab_radius * 0.62, 5.2, 8,
			Vector3(0.0, -slab_height - 2.6, 0.0),
			_mat_indigo_stone
		)
		_add_cylinder_mesh(
			island, "CarvedRockMid",
			slab_radius * 0.58, slab_radius * 0.28, 7.6, 8,
			Vector3(0.0, -slab_height - 9.0, 0.0),
			_mat_dark_obsidian
		)
		_add_cylinder_mesh(
			island, "CarvedRockSpire",
			slab_radius * 0.26, 0.25, 8.5, 6,
			Vector3(0.0, -slab_height - 17.0, 0.0),
			_mat_indigo_stone
		)
		# Golden Art Deco binding band around the floating rock belly
		var belly_band := _add_torus_mesh(
			island, "RockGoldBand",
			slab_radius * 0.62, slab_radius * 0.66, 24, 8,
			Vector3(0.0, -slab_height - 5.1, 0.0),
			_mat_gold_brass
		)
		belly_band.scale = Vector3(1.0, 0.5, 1.0)

		# 4 Art Deco temple columns arranged symmetrically around the sanctuary
		var col_offset := slab_radius * 0.58
		var col_height := 9.2
		var col_positions := [
			Vector3(-col_offset, 0.0, -col_offset),
			Vector3(col_offset, 0.0, -col_offset),
			Vector3(-col_offset, 0.0, col_offset),
			Vector3(col_offset, 0.0, col_offset),
		]
		for c in range(col_positions.size()):
			var cp: Vector3 = col_positions[c]
			var col := Node3D.new()
			col.name = "TempleColumn_%d" % c
			col.position = cp
			island.add_child(col)

			_add_box_mesh(col, "Plinth", Vector3(1.5, 0.8, 1.5), Vector3(0.0, 0.4, 0.0), _mat_dark_obsidian)
			_add_cylinder_mesh(col, "Shaft", 0.46, 0.58, col_height, 8, Vector3(0.0, 0.8 + col_height * 0.5, 0.0), _mat_indigo_stone)
			_add_box_mesh(col, "Capital", Vector3(1.65, 0.75, 1.65), Vector3(0.0, col_height + 1.1, 0.0), _mat_dark_obsidian)
			_add_box_mesh(col, "GoldCollar", Vector3(1.75, 0.22, 1.75), Vector3(0.0, col_height + 0.68, 0.0), _mat_gold_filigree)
			_add_box_mesh(col, "GoldFlute", Vector3(0.14, col_height - 0.8, 1.08), Vector3(0.0, 0.8 + col_height * 0.5, 0.0), _mat_gold_filigree)

		# Open-air Art Deco temple entablature & golden roof trim
		var roof_y := col_height + 1.9
		var beam_span := col_offset * 2.0 + 2.2
		var beam_thickness := 1.25

		_add_box_mesh(island, "RoofBeamN", Vector3(beam_span, beam_thickness, 1.4), Vector3(0.0, roof_y, -col_offset), _mat_dark_obsidian)
		_add_box_mesh(island, "RoofBeamS", Vector3(beam_span, beam_thickness, 1.4), Vector3(0.0, roof_y, col_offset), _mat_dark_obsidian)
		_add_box_mesh(island, "RoofBeamW", Vector3(1.4, beam_thickness, beam_span), Vector3(-col_offset, roof_y, 0.0), _mat_dark_obsidian)
		_add_box_mesh(island, "RoofBeamE", Vector3(1.4, beam_thickness, beam_span), Vector3(col_offset, roof_y, 0.0), _mat_dark_obsidian)

		# Glowing golden roof trim & floating celestial crown ring
		_add_box_mesh(island, "GoldRoofTrimN", Vector3(beam_span + 0.5, 0.26, 0.28), Vector3(0.0, roof_y + 0.58, -col_offset - 0.68), _mat_gold_filigree)
		_add_box_mesh(island, "GoldRoofTrimS", Vector3(beam_span + 0.5, 0.26, 0.28), Vector3(0.0, roof_y + 0.58, col_offset + 0.68), _mat_gold_filigree)
		_add_box_mesh(island, "GoldRoofTrimW", Vector3(0.28, 0.26, beam_span + 0.5), Vector3(-col_offset - 0.68, roof_y + 0.58, 0.0), _mat_gold_filigree)
		_add_box_mesh(island, "GoldRoofTrimE", Vector3(0.28, 0.26, beam_span + 0.5), Vector3(col_offset + 0.68, roof_y + 0.58, 0.0), _mat_gold_filigree)

		var crown: MeshInstance3D = _add_torus_mesh(
			island, "TempleCrownRing",
			col_offset * 0.72, col_offset * 0.78, 32, 10,
			Vector3(0.0, roof_y + 1.5, 0.0),
			_mat_gold_filigree
		)
		crown.scale = Vector3(1.0, 0.45, 1.0)

		# Ethereal upward golden god-ray shaft marking each floating sanctuary from afar
		_add_cylinder_mesh(
			island, "IslandGodRayShaft",
			4.6 * radius_scale, 2.2 * radius_scale, 34.0, 16,
			Vector3(0.0, roof_y + 14.0, 0.0),
			_mat_island_rays, false
		)


# ---------------------------------------------------------------------------
# d) Colossal Akashic Astrolabe Cathedral (z = -280)
# ---------------------------------------------------------------------------

func _attach_cathedral_trimesh_colliders(node: Node) -> int:
	var attached: int = 0
	if node is MeshInstance3D:
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		var lower_name: String = mesh_inst.name.to_lower()
		if (lower_name.contains("castleislandgrass") or lower_name.contains("castleislandrock")) and mesh_inst.mesh != null:
			mesh_inst.create_trimesh_collision()
			attached += 1
	for child: Node in node.get_children():
		attached += _attach_cathedral_trimesh_colliders(child)
	return attached


func _add_curved_side_stair_colliders(root: Node3D) -> void:
	# Twin Curved Garden Side-Staircases flanking the West & East wings:
	# smooth walkable curved ramp segments + flanking watertight balustrade walls (H = 2.8 m)
	for side_sign: float in [-1.0, 1.0]:
		var s_tag: String = "W" if side_sign < 0.0 else "E"
		var stair_pts: Array[Vector3] = [
			Vector3(side_sign * 22.00, 8.00, 16.00),
			Vector3(side_sign * 22.14, 6.80, 18.20),
			Vector3(side_sign * 22.42, 5.60, 20.53),
			Vector3(side_sign * 22.93, 4.40, 22.65),
			Vector3(side_sign * 23.61, 3.20, 24.49),
			Vector3(side_sign * 24.43, 2.00, 25.98),
			Vector3(side_sign * 25.85, 0.35, 27.60),
		]
		for si: int in range(stair_pts.size() - 1):
			var p_a: Vector3 = stair_pts[si]
			var p_b: Vector3 = stair_pts[si + 1]
			var seg_vec: Vector3 = p_b - p_a
			var seg_len: float = seg_vec.length()
			if seg_len < 0.05:
				continue
			var seg_mid: Vector3 = (p_a + p_b) * 0.5
			var fwd_dir: Vector3 = seg_vec.normalized()
			var right_dir: Vector3 = fwd_dir.cross(Vector3.UP).normalized()
			var up_dir: Vector3 = right_dir.cross(fwd_dir).normalized()
			var seg_orient: Basis = Basis(right_dir, up_dir, -fwd_dir)

			var ramp_body: StaticBody3D = _add_box_collider(
				root, "SideStairRamp_%s_%d" % [s_tag, si],
				Vector3(4.2, 1.4, seg_len + 0.55),
				seg_mid - up_dir * 0.7
			)
			ramp_body.transform.basis = seg_orient

			for rail_side: float in [-1.0, 1.0]:
				var r_tag: String = "A" if rail_side < 0.0 else "B"
				var rail_body: StaticBody3D = _add_box_collider(
					root, "SideStairRail_%s_%s_%d" % [s_tag, r_tag, si],
					Vector3(0.8, 2.8, seg_len + 0.85),
					seg_mid + right_dir * (rail_side * 2.25) + up_dir * 1.3
				)
				rail_body.transform.basis = seg_orient


func _add_cathedral_colliders(root: Node3D, has_trimesh_meadow: bool = false) -> void:
	# When the GLB is loaded, CastleIslandGrass & CastleIslandRock provide exact trimesh terrain collision;
	# only add a fallback flat cylinder collider if running without the GLB mesh.
	if not has_trimesh_meadow:
		_add_cylinder_collider(root, "PalaceMeadowGroundCollider", 54.0, 4.0, Vector3(0.0, -2.0, 0.0))

	# Formal Arrival Court solid marble floor slab (top strictly at Y = 0.06, X[-13.5..+13.5], Z[+35.5..+52.2])
	_add_box_collider(root, "PalaceArrivalCourtFloorCollider", Vector3(27.0, 0.5, 16.7), Vector3(0.0, -0.19, 43.85))

	# Formal Arrival Court flanking garden balustrades at X = +-13.5, Z[+35.6..+52.4] (H = 2.8 m, Y = 0.0..2.8)
	_add_box_collider(root, "ArrivalCourtBalustrade_W", Vector3(1.0, 2.8, 16.8), Vector3(-13.5, 1.4, 44.0))
	_add_box_collider(root, "ArrivalCourtBalustrade_E", Vector3(1.0, 2.8, 16.8), Vector3(13.5, 1.4, 44.0))

	# Central Baroque Ballroom & West/East Wings floor slab (top strictly at Y = 8.0, X[-34.5..+34.5], Z[-16.5..+16.5])
	_add_box_collider(root, "PalaceMainFloorCollider", Vector3(69.0, 4.0, 33.0), Vector3(0.0, 6.0, 0.0))

	# North Cloud Terrace floor slab (top strictly at Y = 8.0, X[-14.5..+14.5], Z[-35.0..-16.0])
	_add_box_collider(root, "PalaceNorthTerraceFloorCollider", Vector3(29.0, 4.0, 19.0), Vector3(0.0, 6.0, -25.5))

	# Central Baroque Ballroom Walls (Y = 8.0..24.0 -> height 16.0, center Y = 16.0, thickness 1.8 m)
	# Verified 100% OPEN archway clearances:
	# - South Grand Entrance Archway: X[-7.2..+7.2] = 14.4 m open
	# - North Cloud Terrace Archway:  X[-6.7..+6.7] = 13.4 m open
	# - West & East Salon Archways:   Z[-6.2..+6.2] = 12.4 m open
	_add_box_collider(root, "BallroomWall_South_L", Vector3(9.3, 16.0, 1.8), Vector3(-11.85, 16.0, 16.0))
	_add_box_collider(root, "BallroomWall_South_R", Vector3(9.3, 16.0, 1.8), Vector3(11.85, 16.0, 16.0))
	_add_box_collider(root, "BallroomWall_North_L", Vector3(9.8, 16.0, 1.8), Vector3(-11.6, 16.0, -16.0))
	_add_box_collider(root, "BallroomWall_North_R", Vector3(9.8, 16.0, 1.8), Vector3(11.6, 16.0, -16.0))
	_add_box_collider(root, "BallroomWall_West_N", Vector3(1.8, 16.0, 10.3), Vector3(-16.0, 16.0, -11.35))
	_add_box_collider(root, "BallroomWall_West_S", Vector3(1.8, 16.0, 10.3), Vector3(-16.0, 16.0, 11.35))
	_add_box_collider(root, "BallroomWall_East_N", Vector3(1.8, 16.0, 10.3), Vector3(16.0, 16.0, -11.35))
	_add_box_collider(root, "BallroomWall_East_S", Vector3(1.8, 16.0, 10.3), Vector3(16.0, 16.0, 11.35))

	# West Wing Salon outer solid walls (X[-34..-16], Z[-13..+13], Y = 8.0..21.0 -> height 13.0, center Y = 14.5, thickness 1.6 m)
	_add_box_collider(root, "WestSalonWall_Outer", Vector3(1.6, 13.0, 27.0), Vector3(-34.0, 14.5, 0.0))
	_add_box_collider(root, "WestSalonWall_North", Vector3(18.5, 13.0, 1.6), Vector3(-25.25, 14.5, -13.0))
	_add_box_collider(root, "WestSalonWall_South", Vector3(18.5, 13.0, 1.6), Vector3(-25.25, 14.5, 13.0))

	# East Wing Salon outer solid walls (X[+16..+34], Z[-13..+13], Y = 8.0..21.0 -> height 13.0, center Y = 14.5, thickness 1.6 m)
	_add_box_collider(root, "EastSalonWall_Outer", Vector3(1.6, 13.0, 27.0), Vector3(34.0, 14.5, 0.0))
	_add_box_collider(root, "EastSalonWall_North", Vector3(18.5, 13.0, 1.6), Vector3(25.25, 14.5, -13.0))
	_add_box_collider(root, "EastSalonWall_South", Vector3(18.5, 13.0, 1.6), Vector3(25.25, 14.5, 13.0))

	# South Grand Imperial Staircase: smooth walkable ramp from Z=+36.0, Y=0.0 to Z=+16.0, Y=8.0 (width 23.0 m)
	var stair_dz: float = 20.0
	var stair_dy: float = 8.0
	var ramp_angle: float = atan2(stair_dy, stair_dz)
	var ramp_len: float = sqrt(stair_dz * stair_dz + stair_dy * stair_dy) + 0.6
	var ramp_thickness: float = 2.4
	var ramp_center: Vector3 = Vector3(
		0.0,
		4.0 - cos(ramp_angle) * (ramp_thickness * 0.5),
		26.0 - sin(ramp_angle) * (ramp_thickness * 0.5)
	)
	var stairs_ramp: StaticBody3D = _add_box_collider(
		root, "PalaceImperialStairsRampCollider",
		Vector3(23.0, ramp_thickness, ramp_len),
		ramp_center
	)
	stairs_ramp.rotation.x = ramp_angle

	# Watertight sloped side balustrade colliders flanking the Grand Imperial Staircase at X = +-11.8 (H = 3.0 m)
	# plus solid bottom & top filler walls connecting seamlessly to the Arrival Court balustrades and Ballroom South wall
	for side_sign: float in [-1.0, 1.0]:
		var s_tag: String = "W" if side_sign < 0.0 else "E"
		var rail_center: Vector3 = Vector3(
			side_sign * 11.8,
			4.0 + cos(ramp_angle) * 1.5,
			26.0 + sin(ramp_angle) * 1.5
		)
		var stair_rail: StaticBody3D = _add_box_collider(
			root, "StairBalustradeCollider_%s" % s_tag,
			Vector3(1.2, 3.0, ramp_len + 1.4),
			rail_center
		)
		stair_rail.rotation.x = ramp_angle

		# Bottom filler wall bridging X = +-11.8 stair rail to X = +-13.5 Arrival Court balustrade at Z = +36.0
		_add_box_collider(
			root, "StairBottomFillerWall_%s" % s_tag,
			Vector3(2.8, 3.0, 1.2),
			Vector3(side_sign * 12.6, 1.5, 36.0)
		)
		# Top abutment filler wall sealing the sloped rail into BallroomWall_South_L/R at Z = +16.0
		_add_box_collider(
			root, "StairTopFillerWall_%s" % s_tag,
			Vector3(1.4, 3.4, 1.8),
			Vector3(side_sign * 11.8, 9.5, 16.4)
		)

	# Twin Curved Garden Side-Staircases (smooth curved ramps + flanking balustrade walls)
	_add_curved_side_stair_colliders(root)

	# North Cloud Terrace Balustrades — 100% watertight perimeter (H = 3.0 m, Y = 8.0..11.0 -> center Y = 9.5, thickness = 1.0 m)
	_add_box_collider(root, "NorthTerraceBalustrade_W", Vector3(1.0, 3.0, 10.2), Vector3(-14.0, 9.5, -20.6))
	_add_box_collider(root, "NorthTerraceBalustrade_E", Vector3(1.0, 3.0, 10.2), Vector3(14.0, 9.5, -20.6))
	_add_box_collider(root, "NorthTerraceShoulder_W", Vector3(4.8, 3.0, 1.0), Vector3(-12.25, 9.5, -24.5))
	_add_box_collider(root, "NorthTerraceShoulder_E", Vector3(4.8, 3.0, 1.0), Vector3(12.25, 9.5, -24.5))

	# 9-segment semicircular railing arc around (0, 8.0, -24.0), radius 10.5 m (H = 3.0 m, thickness = 1.0 m, overlapping joins)
	var apse_center_z: float = -24.0
	var apse_radius: float = 10.5
	var arc_segments: int = 9
	var arc_half_span: float = deg_to_rad(90.0)
	for ai: int in range(arc_segments):
		var frac: float = (float(ai) + 0.5) / float(arc_segments)
		var theta: float = lerpf(-arc_half_span, arc_half_span, frac)
		var seg_x: float = sin(theta) * apse_radius
		var seg_z: float = apse_center_z - cos(theta) * apse_radius
		var seg_len: float = (2.0 * arc_half_span * apse_radius) / float(arc_segments) + 1.1
		var seg_body: StaticBody3D = _add_box_collider(
			root, "NorthTerraceApseRail_%d" % ai,
			Vector3(seg_len, 3.0, 1.0),
			Vector3(seg_x, 9.5, seg_z)
		)
		seg_body.rotation.y = -theta

	# 4 Ballroom Corner Baroque Pavilion Towers at (+-16.5, 24.0, +-16.5), R = 3.2 m
	var ballroom_towers: Array[Vector2] = [
		Vector2(-16.5, 16.5), Vector2(16.5, 16.5),
		Vector2(-16.5, -16.5), Vector2(16.5, -16.5),
	]
	for ti: int in range(ballroom_towers.size()):
		var tp: Vector2 = ballroom_towers[ti]
		_add_cylinder_collider(root, "PalaceCornerTowerCollider_%d" % ti, 3.2, 48.0, Vector3(tp.x, 24.0, tp.y))

	# 4 Outer Wing Corner Turrets at (+-34.0, 18.0, +-13.0), R = 2.4 m
	var wing_turrets: Array[Vector2] = [
		Vector2(-34.0, 13.0), Vector2(34.0, 13.0),
		Vector2(-34.0, -13.0), Vector2(34.0, -13.0),
	]
	for wi: int in range(wing_turrets.size()):
		var wp: Vector2 = wing_turrets[wi]
		_add_cylinder_collider(root, "PalaceWingTurretCollider_%d" % wi, 2.4, 36.0, Vector3(wp.x, 18.0, wp.y))


func _build_rotunda_skylight_sunbeam(root: Node3D) -> void:
	# Soft vertical Skylight Sunbeam God-Ray descending from the Castle glass dome (y = 46 down to y = 8)
	_add_cylinder_mesh(
		root, "RotundaSkylightSunbeam",
		6.8, 10.5, 38.0, 24,
		Vector3(0.0, 27.0, 0.0),
		_mat_skylight_ray, false
	)
	# Warm sunlit fill illuminating the Rotunda marble floor, fluted columns, Mentors, and Earth Mirror
	var rotunda_light: OmniLight3D = OmniLight3D.new()
	rotunda_light.name = "RotundaSkylightFill"
	rotunda_light.position = Vector3(0.0, 26.0, 2.0)
	rotunda_light.light_color = Color("#FFF4DC")
	rotunda_light.light_energy = 2.2
	rotunda_light.omni_range = 48.0
	rotunda_light.omni_attenuation = 1.15
	root.add_child(rotunda_light)


func _build_colossal_cathedral() -> void:
	var root := Node3D.new()
	root.name = "AkashaAstrolabeCathedral"
	root.position = CATHEDRAL_POSITION
	add_child(root)

	if _try_instantiate_override(cathedral_model_path, root, Vector3.ZERO, "cathedral"):
		var has_trimesh_meadow: bool = _attach_cathedral_trimesh_colliders(root) > 0
		_add_cathedral_colliders(root, has_trimesh_meadow)
		_build_rotunda_skylight_sunbeam(root)
		_build_cathedral_astrolabe_rings(root, Vector3(0.0, 92.0, 0.0))
		return

	# Grand stepped obsidian-indigo sanctuary dais & deep foundation
	_add_box_mesh(root, "CathedralFoundation", Vector3(92.0, 82.0, 64.0), Vector3(0.0, -41.0, 0.0), _mat_dark_obsidian)
	_add_box_mesh(root, "CathedralDaisStep1", Vector3(84.0, 4.0, 56.0), Vector3(0.0, 2.0, 2.0), _mat_indigo_stone)
	_add_box_mesh(root, "CathedralDaisStep2", Vector3(68.0, 4.0, 44.0), Vector3(0.0, 6.0, 4.0), _mat_polished_marble)
	_add_cathedral_colliders(root, false)

	# Golden dais edge steps
	_add_box_mesh(root, "DaisGoldEdge1", Vector3(84.6, 0.45, 0.6), Vector3(0.0, 3.9, 30.1), _mat_gold_filigree)
	_add_box_mesh(root, "DaisGoldEdge2", Vector3(68.6, 0.45, 0.6), Vector3(0.0, 7.9, 26.1), _mat_gold_filigree)

	# Main cathedral nave walls framing the grand archway (left and right massive piers)
	for side: float in [-1.0, 1.0]:
		var s_name: String = "L" if side < 0 else "R"
		_add_box_mesh(root, "NavePier_%s" % s_name, Vector3(14.0, 74.0, 28.0), Vector3(side * 19.0, 45.0, 0.0), _mat_dark_obsidian)
		_add_box_mesh(root, "NaveButtress_%s" % s_name, Vector3(6.5, 62.0, 32.0), Vector3(side * 25.0, 39.0, 2.0), _mat_indigo_stone)
		# Vertical golden filigree ribs
		_add_box_mesh(root, "NaveGoldRibFront_%s" % s_name, Vector3(0.9, 72.0, 0.9), Vector3(side * 13.5, 44.0, 14.2), _mat_gold_filigree)
		_add_box_mesh(root, "NaveGoldRibOuter_%s" % s_name, Vector3(0.7, 58.0, 0.9), Vector3(side * 24.5, 37.0, 18.2), _mat_gold_filigree)

	# Upper cathedral entablature & towering central Art Deco stepped spire (reaches y = 148m)
	_add_box_mesh(root, "UpperBridge", Vector3(52.0, 18.0, 24.0), Vector3(0.0, 82.0, -2.0), _mat_dark_obsidian)
	_add_box_mesh(root, "SpireTier1", Vector3(32.0, 26.0, 20.0), Vector3(0.0, 102.0, -2.0), _mat_indigo_stone)
	_add_box_mesh(root, "SpireTier2", Vector3(18.0, 24.0, 14.0), Vector3(0.0, 124.0, -2.0), _mat_dark_obsidian)
	_add_cylinder_mesh(root, "CentralNeedleSpire", 0.35, 6.2, 34.0, 8, Vector3(0.0, 151.0, -2.0), _mat_indigo_stone)
	_add_cylinder_mesh(root, "SpireGoldCrown", 0.25, 1.8, 12.0, 8, Vector3(0.0, 170.0, -2.0), _mat_gold_filigree)

	# Golden Art Deco chevrons on central spire facade
	_add_box_mesh(root, "SpireGoldBand1", Vector3(33.2, 0.85, 21.0), Vector3(0.0, 91.5, -2.0), _mat_gold_filigree)
	_add_box_mesh(root, "SpireGoldBand2", Vector3(19.0, 0.75, 15.0), Vector3(0.0, 114.5, -2.0), _mat_gold_filigree)
	_add_box_mesh(root, "SpireGoldCenterLine", Vector3(0.95, 58.0, 0.8), Vector3(0.0, 116.0, 8.2), _mat_gold_filigree)

	# Grand Archway (colossal luminous portal opening at front facade z = +13)
	var arch_radius := 13.0
	var arch_center_y := 48.0
	var arch_segments := 12
	for s in range(arch_segments):
		var angle: float = lerpf(0.04 * PI, 0.96 * PI, (float(s) + 0.5) / float(arch_segments))
		var seg_len := (PI * 0.92 * arch_radius) / float(arch_segments) + 0.6
		var ax := cos(angle) * arch_radius
		var ay := arch_center_y + sin(angle) * arch_radius

		var arch_stone := _add_box_mesh(
			root, "GrandArchStone_%d" % s,
			Vector3(seg_len, 2.8, 6.5),
			Vector3(ax, ay, 11.5),
			_mat_cobalt_trim
		)
		arch_stone.rotation.z = angle - PI * 0.5

		var arch_gold := _add_box_mesh(
			root, "GrandArchGold_%d" % s,
			Vector3(seg_len + 0.2, 0.75, 1.2),
			Vector3(cos(angle) * (arch_radius - 1.3), arch_center_y + sin(angle) * (arch_radius - 1.3), 14.6),
			_mat_gold_filigree
		)
		arch_gold.rotation.z = angle - PI * 0.5

	# Luminous Golden Light Core rising inside the Grand Archway
	_add_cylinder_mesh(root, "LightCoreBeam", 2.4, 4.2, 68.0, 16, Vector3(0.0, 42.0, 0.0), _mat_light_core)
	_add_sphere_mesh(root, "LightCoreSun", 5.8, 24, 16, Vector3(0.0, 52.0, 4.0), _mat_light_core)

	var core_light := OmniLight3D.new()
	core_light.name = "CathedralCoreLight"
	core_light.position = Vector3(0.0, 50.0, 14.0)
	core_light.light_color = Color("#F5D88A")
	core_light.light_energy = 3.5
	core_light.omni_range = 110.0
	core_light.omni_attenuation = 1.2
	root.add_child(core_light)

	# Symmetrical Flanking Spires (inner & outer pairs)
	var spire_specs := [
		{"x": -34.0, "z": 2.0, "h": 92.0, "w": 11.0},
		{"x": 34.0, "z": 2.0, "h": 92.0, "w": 11.0},
		{"x": -52.0, "z": 10.0, "h": 68.0, "w": 8.5},
		{"x": 52.0, "z": 10.0, "h": 68.0, "w": 8.5},
	]
	for i in range(spire_specs.size()):
		var spec: Dictionary = spire_specs[i]
		var sx: float = spec["x"]
		var sz: float = spec["z"]
		var sh: float = spec["h"]
		var sw: float = spec["w"]

		var flank := Node3D.new()
		flank.name = "FlankingSpire_%d" % i
		flank.position = Vector3(sx, 0.0, sz)
		root.add_child(flank)

		_add_box_mesh(flank, "TowerBase", Vector3(sw, sh, sw), Vector3(0.0, sh * 0.5, 0.0), _mat_dark_obsidian)
		_add_box_mesh(flank, "TowerMid", Vector3(sw * 0.72, sh * 0.35, sw * 0.72), Vector3(0.0, sh + sh * 0.14, 0.0), _mat_indigo_stone)
		_add_cylinder_mesh(flank, "TowerTip", 0.2, sw * 0.38, 22.0, 6, Vector3(0.0, sh + sh * 0.32 + 10.0, 0.0), _mat_gold_brass)
		_add_box_mesh(flank, "TowerGoldStripe", Vector3(0.65, sh * 0.9, 0.65), Vector3(0.0, sh * 0.5, sw * 0.5 + 0.15), _mat_gold_filigree)
		_add_box_mesh(flank, "TowerGoldCollar", Vector3(sw + 0.8, 0.7, sw + 0.8), Vector3(0.0, sh - 2.0, 0.0), _mat_gold_filigree)

	# 3 Giant Counter-Rotating Golden 3D Astrolabe Rings + 8-Point Compass Starburst
	_build_cathedral_astrolabe_rings(root, Vector3(0.0, 62.0, 12.0))

	# Dramatic fanned-out golden volumetric god-ray shafts radiating from the Cathedral core
	_build_cathedral_god_rays(root, Vector3(0.0, 66.0, 6.0))


func _build_cathedral_astrolabe_rings(parent: Node3D, center: Vector3) -> void:
	var astrolabe_root: Node3D = Node3D.new()
	astrolabe_root.name = "AstrolabeRings"
	astrolabe_root.position = center
	parent.add_child(astrolabe_root)

	# Iconic 8-point Art Deco Compass Starburst behind the counter-rotating rings
	var compass_root: Node3D = Node3D.new()
	compass_root.name = "CompassStarburst"
	astrolabe_root.add_child(compass_root)
	for ray_idx: int in range(4):
		var is_cardinal: bool = (ray_idx % 2 == 0)
		var ray_len: float = 54.0 if is_cardinal else 36.0
		var ray_thick: float = 1.05 if is_cardinal else 0.65
		var spoke: MeshInstance3D = _add_box_mesh(
			compass_root, "CompassRay_%d" % ray_idx,
			Vector3(ray_thick, ray_len, 0.75),
			Vector3.ZERO,
			_mat_gold_filigree, false
		)
		spoke.rotation.z = deg_to_rad(float(ray_idx) * 45.0)
	_add_sphere_mesh(compass_root, "CompassHeart", 3.6, 20, 14, Vector3.ZERO, _mat_light_core, false)

	var ring_configs: Array[Dictionary] = [
		{"name": "OuterAstrolabeRing", "inner": 33.2, "outer": 35.0, "rot": Vector3(78.0, 0.0, 12.0), "nodes": 8},
		{"name": "MiddleAstrolabeRing", "inner": 25.0, "outer": 26.5, "rot": Vector3(54.0, 32.0, -24.0), "nodes": 6},
		{"name": "InnerAstrolabeRing", "inner": 17.5, "outer": 18.8, "rot": Vector3(112.0, -26.0, 42.0), "nodes": 4},
	]

	for cfg: Dictionary in ring_configs:
		var pivot: Node3D = Node3D.new()
		pivot.name = String(cfg["name"])
		pivot.rotation_degrees = cfg["rot"] as Vector3
		astrolabe_root.add_child(pivot)

		var inner_r: float = float(cfg["inner"])
		var outer_r: float = float(cfg["outer"])
		var mid_r: float = (inner_r + outer_r) * 0.5

		_add_torus_mesh(pivot, "MainRing", inner_r, outer_r, 64, 16, Vector3.ZERO, _mat_gold_filigree)
		# Delicate secondary parallel filigree wire
		_add_torus_mesh(pivot, "InnerWire", inner_r - 1.4, inner_r - 1.05, 48, 10, Vector3.ZERO, _mat_gold_brass)

		# Art Deco celestial cardinal markers around each ring
		var count: int = int(cfg["nodes"])
		for k: int in range(count):
			var a: float = (TAU / float(count)) * float(k)
			var marker: MeshInstance3D = _add_box_mesh(
				pivot, "CardinalNode_%d" % k,
				Vector3(1.6, 1.6, 3.6),
				Vector3(cos(a) * mid_r, 0.0, sin(a) * mid_r),
				_mat_gold_filigree
			)
			marker.rotation.y = -a

		_astrolabe_rings.append(pivot)


func _build_cathedral_god_rays(parent: Node3D, origin: Vector3) -> void:
	var rays_root: Node3D = Node3D.new()
	rays_root.name = "CathedralGodRays"
	rays_root.position = origin
	parent.add_child(rays_root)

	# 7 fanned-out volumetric golden light shafts matching the AAA flight & sanctuary references
	var shaft_angles_deg: Array[float] = [-46.0, -30.0, -15.0, 0.0, 15.0, 30.0, 46.0]
	for idx: int in range(shaft_angles_deg.size()):
		var deg: float = shaft_angles_deg[idx]
		var is_center: bool = absf(deg) < 1.0
		var shaft_len: float = 210.0 if is_center else lerpf(195.0, 155.0, absf(deg) / 46.0)
		var top_r: float = 24.0 if is_center else 18.0
		var bot_r: float = 6.5 if is_center else 4.2

		var pivot: Node3D = Node3D.new()
		pivot.name = "GodRayFan_%d" % idx
		pivot.rotation_degrees = Vector3(14.0, 0.0, deg)
		rays_root.add_child(pivot)

		_add_cylinder_mesh(
			pivot, "ShaftMesh",
			top_r, bot_r, shaft_len, 18,
			Vector3(0.0, shaft_len * 0.42, 0.0),
			_mat_god_rays, false
		)


# ---------------------------------------------------------------------------
# e) Sweeping 3D Golden Threads of Destiny
# ---------------------------------------------------------------------------

func _build_golden_threads_of_destiny() -> void:
	var root := Node3D.new()
	root.name = "GoldenThreadsOfDestiny"
	add_child(root)

	# Symmetrical Sacred-Geometry luminous golden ley-line web connecting:
	# Plaza (0,0,22) -> Twin Gate Islands (+-28, 3.5, -36) -> Central Heart (0, 6.5, -106)
	# -> Twin Memory Islands (+-34, 9.5, -176) -> Castle Rotunda Portal & Skylight Dome (0, 28..56, -256)
	var threads := [
		# Central Axial Spine linking Plaza -> Heart of the Sky -> Castle Rotunda Skylight
		{
			"name": "AxialDestinySpine",
			"p0": Vector3(0.0, 2.8, 22.0),
			"p1": Vector3(0.0, 14.5, -68.0),
			"p2": Vector3(0.0, 22.0, -176.0),
			"p3": Vector3(0.0, 44.0, -256.0),
			"radius": 0.22,
		},
		# First Sacred Diamond: Plaza -> Gate of Awakening (West & East) -> Heart of the Sky
		{
			"name": "GateDiamond_West",
			"p0": Vector3(-5.0, 2.6, 22.5),
			"p1": Vector3(-28.0, 13.5, -18.0),
			"p2": Vector3(-28.0, 14.5, -56.0),
			"p3": Vector3(0.0, 16.0, -106.0),
			"radius": 0.16,
		},
		{
			"name": "GateDiamond_East",
			"p0": Vector3(5.0, 2.6, 22.5),
			"p1": Vector3(28.0, 13.5, -18.0),
			"p2": Vector3(28.0, 14.5, -56.0),
			"p3": Vector3(0.0, 16.0, -106.0),
			"radius": 0.16,
		},
		# Second Sacred Diamond: Heart of the Sky -> Pillars of Memory (West & East) -> Castle Rotunda Archway
		{
			"name": "MemoryDiamond_West",
			"p0": Vector3(0.0, 16.0, -106.0),
			"p1": Vector3(-34.0, 20.5, -152.0),
			"p2": Vector3(-34.0, 22.0, -198.0),
			"p3": Vector3(-8.0, 28.0, -256.0),
			"radius": 0.16,
		},
		{
			"name": "MemoryDiamond_East",
			"p0": Vector3(0.0, 16.0, -106.0),
			"p1": Vector3(34.0, 20.5, -152.0),
			"p2": Vector3(34.0, 22.0, -198.0),
			"p3": Vector3(8.0, 28.0, -256.0),
			"radius": 0.16,
		},
		# Outer Twin Celestial Flank Ribbons linking Gate Islands -> Memory Islands -> Castle Crown
		{
			"name": "OuterCelestialRibbon_West",
			"p0": Vector3(-28.0, 14.0, -36.0),
			"p1": Vector3(-44.0, 26.0, -106.0),
			"p2": Vector3(-38.0, 32.0, -186.0),
			"p3": Vector3(-16.0, 58.0, -264.0),
			"radius": 0.14,
		},
		{
			"name": "OuterCelestialRibbon_East",
			"p0": Vector3(28.0, 14.0, -36.0),
			"p1": Vector3(44.0, 26.0, -106.0),
			"p2": Vector3(38.0, 32.0, -186.0),
			"p3": Vector3(16.0, 58.0, -264.0),
			"radius": 0.14,
		},
		# High Symmetrical Canopy Arcs framing the Twin Viaducts up to the Castle Astrolabe
		{
			"name": "HighViaductArc_West",
			"p0": Vector3(-52.0, 26.0, -12.0),
			"p1": Vector3(-36.0, 48.0, -106.0),
			"p2": Vector3(-18.0, 62.0, -195.0),
			"p3": Vector3(0.0, 78.0, -268.0),
			"radius": 0.13,
		},
		{
			"name": "HighViaductArc_East",
			"p0": Vector3(52.0, 26.0, -12.0),
			"p1": Vector3(36.0, 48.0, -106.0),
			"p2": Vector3(18.0, 62.0, -195.0),
			"p3": Vector3(0.0, 78.0, -268.0),
			"radius": 0.13,
		},
	]

	for t in threads:
		var mesh := _create_bezier_tube_mesh(
			t["p0"], t["p1"], t["p2"], t["p3"],
			t["radius"], 56, 6
		)
		var inst := MeshInstance3D.new()
		inst.name = t["name"]
		inst.mesh = mesh
		inst.material_override = _mat_gold_thread
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(inst)


func _create_bezier_tube_mesh(
	p0: Vector3,
	p1: Vector3,
	p2: Vector3,
	p3: Vector3,
	radius: float,
	segments: int,
	sides: int
) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rings: Array[PackedVector3Array] = []
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var pos := _cubic_bezier(p0, p1, p2, p3, t)
		var tangent := _cubic_bezier_tangent(p0, p1, p2, p3, t).normalized()
		if tangent.length_squared() < 0.0001:
			tangent = Vector3.FORWARD

		var up_ref := Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		var right := tangent.cross(up_ref).normalized()
		var up := right.cross(tangent).normalized()

		# Gently taper the ends of each golden thread
		var taper := sin(t * PI) * 0.55 + 0.45
		var r := radius * taper

		var ring := PackedVector3Array()
		for s in range(sides):
			var angle := (TAU / float(sides)) * float(s)
			var offset := (right * cos(angle) + up * sin(angle)) * r
			ring.append(pos + offset)
		rings.append(ring)

	for i in range(segments):
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		for s in range(sides):
			var sn: int = (s + 1) % sides
			var v00: Vector3 = r0[s]
			var v01: Vector3 = r0[sn]
			var v10: Vector3 = r1[s]
			var v11: Vector3 = r1[sn]

			st.add_vertex(v00)
			st.add_vertex(v10)
			st.add_vertex(v11)

			st.add_vertex(v00)
			st.add_vertex(v11)
			st.add_vertex(v01)

	st.generate_normals()
	return st.commit()


func _cubic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var u := 1.0 - t
	return (
		(u * u * u) * p0
		+ (3.0 * u * u * t) * p1
		+ (3.0 * u * t * t) * p2
		+ (t * t * t) * p3
	)


func _cubic_bezier_tangent(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var u := 1.0 - t
	return (
		(3.0 * u * u) * (p1 - p0)
		+ (6.0 * u * t) * (p2 - p1)
		+ (3.0 * t * t) * (p3 - p2)
	)


# ---------------------------------------------------------------------------
# f) Colossal Ethereal Mentor Silhouettes (#58C4FF)
# ---------------------------------------------------------------------------

func _build_ethereal_mentor_silhouettes() -> void:
	var root: Node3D = Node3D.new()
	root.name = "EtherealMentorSilhouettes"
	add_child(root)

	var specs: Array = [
		{
			"name": "CelestialMentorLeft",
			"pos": Vector3(-62.0, -10.0, -236.0),
			"yaw": 26.0,
			"scale": 1.05,
			"glb": "res://assets/models/characters/mentor_alatea.glb",
			"halo_node": "AlateaHaloPivot",
		},
		{
			"name": "CelestialMentorRight",
			"pos": Vector3(64.0, -8.0, -242.0),
			"yaw": -28.0,
			"scale": 1.0,
			"glb": "res://assets/models/characters/mentor_mira.glb",
			"halo_node": "MiraHaloPivot",
		},
	]

	for spec in specs:
		var mentor: Node3D = Node3D.new()
		mentor.name = spec["name"]
		mentor.position = spec["pos"]
		mentor.rotation_degrees.y = spec["yaw"]
		var sc: float = spec["scale"]
		mentor.scale = Vector3(sc, sc, sc)
		root.add_child(mentor)

		var glb_path: String = spec["glb"]
		var loaded_sculpt: bool = false
		if ResourceLoader.exists(glb_path):
			var packed: PackedScene = load(glb_path) as PackedScene
			if packed != null:
				var inst: Node = packed.instantiate()
				if inst is Node3D:
					var model_node: Node3D = inst as Node3D
					model_node.name = "ColossalSculpt"
					# Base mentor models are ~6.8m tall; scale 8.4x -> ~57m-65m colossal horizon presence
					model_node.scale = Vector3(8.4, 8.4, 8.4)
					mentor.add_child(model_node)
					_apply_colossal_mentor_materials(model_node)

					var halo_name: String = spec["halo_node"]
					var halo_pivot: Node3D = model_node.find_child(halo_name, true, false) as Node3D
					if halo_pivot != null:
						_mentor_halos.append(halo_pivot)
					loaded_sculpt = true
				else:
					inst.queue_free()

		if not loaded_sculpt:
			# Fallback procedural silhouette (~62m tall)
			_add_cylinder_mesh(mentor, "LowerRobe", 4.6, 11.5, 34.0, 16, Vector3(0.0, 17.0, 0.0), _mat_mentor_body, false)
			_add_cylinder_mesh(mentor, "UpperTorso", 5.8, 4.4, 16.0, 14, Vector3(0.0, 41.0, 0.0), _mat_mentor_body, false)
			var mantle: MeshInstance3D = _add_cylinder_mesh(mentor, "MantleCape", 2.8, 9.8, 12.0, 14, Vector3(0.0, 45.0, -1.2), _mat_mentor_body, false)
			mantle.scale = Vector3(1.35, 1.0, 0.72)
			for side: float in [-1.0, 1.0]:
				var arm: MeshInstance3D = _add_cylinder_mesh(
					mentor, "EtherealArm_%s" % ("L" if side < 0.0 else "R"),
					0.9, 1.8, 14.5, 10,
					Vector3(side * 6.8, 43.5, 2.4),
					_mat_mentor_body, false,
				)
				arm.rotation_degrees = Vector3(24.0, 0.0, side * 38.0)
			_add_sphere_mesh(mentor, "Head", 3.4, 18, 12, Vector3(0.0, 53.5, 0.4), _mat_mentor_body, false)
			_add_sphere_mesh(mentor, "HeartStar", 1.8, 14, 10, Vector3(0.0, 44.0, 2.6), _mat_mentor_halo, false)
			var halo_pivot_fb: Node3D = Node3D.new()
			halo_pivot_fb.name = "CelestialHalo"
			halo_pivot_fb.position = Vector3(0.0, 54.5, -2.6)
			mentor.add_child(halo_pivot_fb)
			var outer_halo: MeshInstance3D = _add_torus_mesh(halo_pivot_fb, "OuterHaloRing", 7.8, 8.4, 36, 10, Vector3.ZERO, _mat_mentor_halo, false)
			outer_halo.rotation_degrees.x = 90.0
			var inner_halo: MeshInstance3D = _add_torus_mesh(halo_pivot_fb, "InnerHaloRing", 5.2, 5.5, 28, 8, Vector3.ZERO, _mat_mentor_halo, false)
			inner_halo.rotation_degrees.x = 90.0
			_mentor_halos.append(halo_pivot_fb)

		_mentor_nodes.append(mentor)
		_mentor_base_y.append(mentor.position.y)


func _apply_colossal_mentor_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mesh: Mesh = mesh_inst.mesh
		if mesh != null:
			var surface_count: int = mesh.get_surface_count()
			for surface_idx: int in range(surface_count):
				var src_mat: Material = mesh_inst.get_active_material(surface_idx)
				var mat_name: String = src_mat.resource_name if src_mat != null else ""
				if mat_name.findn("Gold") >= 0:
					mesh_inst.set_surface_override_material(surface_idx, _mat_gold_thread)
				elif mat_name.findn("Star") >= 0:
					mesh_inst.set_surface_override_material(surface_idx, _mat_light_core)
				else:
					mesh_inst.set_surface_override_material(surface_idx, _mat_mentor_body)
	for child: Node in node.get_children():
		_apply_colossal_mentor_materials(child)



# ---------------------------------------------------------------------------
# .glb Override Pipeline & Geometry Helpers
# ---------------------------------------------------------------------------

func _try_instantiate_override(res_path: String, parent: Node3D, local_pos: Vector3, glb_kind: String = "") -> bool:
	if res_path.is_empty() or not ResourceLoader.exists(res_path):
		return false
	var loaded: Resource = ResourceLoader.load(res_path)
	if loaded is PackedScene:
		var inst: Node = (loaded as PackedScene).instantiate()
		if inst is Node3D:
			(inst as Node3D).position = local_pos
		parent.add_child(inst)
		if not glb_kind.is_empty():
			_sanitize_glb_zfighting(inst, glb_kind)
		_refine_glb_materials(inst)
		return true
	return false


func _sanitize_glb_zfighting(node: Node, glb_kind: String) -> void:
	if node is MeshInstance3D:
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		var src_mesh: Mesh = mesh_inst.mesh
		if src_mesh != null:
			var cache_key: String = "%s:%d" % [glb_kind, src_mesh.get_instance_id()]
			if _sanitized_mesh_cache.has(cache_key):
				mesh_inst.mesh = _sanitized_mesh_cache[cache_key] as Mesh
			else:
				var cleaned: Mesh = _sanitize_glb_mesh_surfaces(src_mesh, node.name.to_lower(), glb_kind)
				_sanitized_mesh_cache[cache_key] = cleaned
				mesh_inst.mesh = cleaned
	for child: Node in node.get_children():
		_sanitize_glb_zfighting(child, glb_kind)


func _sanitize_glb_mesh_surfaces(src_mesh: Mesh, node_name: String, glb_kind: String) -> Mesh:
	var surface_count: int = src_mesh.get_surface_count()
	if surface_count <= 0:
		return src_mesh

	var new_mesh: ArrayMesh = ArrayMesh.new()
	var any_modified: bool = false

	for s_idx: int in range(surface_count):
		var arrays: Array = src_mesh.surface_get_arrays(s_idx)
		var prim_type: Mesh.PrimitiveType = src_mesh.surface_get_primitive_type(s_idx)
		var s_mat: Material = src_mesh.surface_get_material(s_idx)
		var mat_name: String = s_mat.resource_name.to_lower() if s_mat != null else ""

		var verts_var: Variant = arrays[Mesh.ARRAY_VERTEX]
		if verts_var is PackedVector3Array:
			var verts: PackedVector3Array = verts_var as PackedVector3Array
			var normals_var: Variant = arrays[Mesh.ARRAY_NORMAL]
			var has_normals: bool = normals_var is PackedVector3Array and (normals_var as PackedVector3Array).size() == verts.size()
			var normals: PackedVector3Array = (normals_var as PackedVector3Array) if has_normals else PackedVector3Array()
			var surface_changed: bool = _offset_coplanar_surface_verts(verts, normals, has_normals, node_name, mat_name, glb_kind)
			if surface_changed:
				arrays[Mesh.ARRAY_VERTEX] = verts
				any_modified = true

		new_mesh.add_surface_from_arrays(prim_type, arrays)
		var s_name: String = src_mesh.surface_get_name(s_idx)
		if not s_name.is_empty():
			new_mesh.surface_set_name(s_idx, s_name)
		if s_mat != null:
			new_mesh.surface_set_material(s_idx, s_mat)

	return new_mesh if any_modified else src_mesh


func _offset_coplanar_surface_verts(
	verts: PackedVector3Array,
	normals: PackedVector3Array,
	has_normals: bool,
	node_name: String,
	mat_name: String,
	glb_kind: String
) -> bool:
	var changed: bool = false
	var count: int = verts.size()

	if glb_kind == "cathedral":
		# The Baroque Palace GLB has clean, non-overlapping floor & meadow geometry; leave vertices untouched.
		return false

	elif glb_kind == "plaza":
		for vi: int in range(count):
			var ny: float = normals[vi].y if has_normals else 1.0
			if ny <= 0.90:
				continue
			var v: Vector3 = verts[vi]
			if mat_name.contains("obsidian"):
				if v.y >= -0.055 and v.y <= 0.005:
					v.y -= 0.090
					verts[vi] = v
					changed = true
				elif v.y >= 0.014 and v.y <= 0.019:
					v.y += 0.026
					verts[vi] = v
					changed = true
			elif mat_name.contains("cobalt"):
				if v.y >= 0.012 and v.y <= 0.018:
					v.y += 0.022
					verts[vi] = v
					changed = true
			elif mat_name.contains("goldbrass"):
				if v.y >= -0.015 and v.y <= -0.005:
					v.y -= 0.050
					verts[vi] = v
					changed = true
				elif v.y >= 0.018 and v.y <= 0.034:
					v.y = 0.046 + (v.y - 0.018) * 0.8
					verts[vi] = v
					changed = true
			elif mat_name.contains("goldfiligree"):
				if v.y >= 0.018 and v.y <= 0.034:
					v.y = 0.064 + (v.y - 0.018) * 0.8
					verts[vi] = v
					changed = true
			elif mat_name.contains("goldenglow"):
				if v.y >= 0.018 and v.y <= 0.034:
					v.y = 0.082 + (v.y - 0.018) * 0.8
					verts[vi] = v
					changed = true

	elif glb_kind == "island":
		if node_name.contains("terraceddeck"):
			for vi: int in range(count):
				var ny: float = normals[vi].y if has_normals else 1.0
				if ny <= 0.90:
					continue
				var v: Vector3 = verts[vi]
				if mat_name.contains("deepmarble") and v.y >= 0.003 and v.y <= 0.007:
					v.y = 0.038
					verts[vi] = v
					changed = true
				elif mat_name.contains("indigostone") and v.y >= 0.003 and v.y <= 0.007:
					v.y = 0.046
					verts[vi] = v
					changed = true
				elif mat_name.contains("obsidian") and v.y >= 0.006 and v.y <= 0.010:
					v.y = 0.052
					verts[vi] = v
					changed = true
				elif mat_name.contains("cobalt") and v.y >= 0.003 and v.y <= 0.010:
					v.y = 0.060
					verts[vi] = v
					changed = true
				elif mat_name.contains("goldbrass"):
					if v.y >= -0.025 and v.y <= -0.015:
						v.y = -0.060
						verts[vi] = v
						changed = true
					elif v.y >= 0.011 and v.y <= 0.017:
						v.y = 0.072
						verts[vi] = v
						changed = true
				elif mat_name.contains("goldfiligree") and v.y >= 0.011 and v.y <= 0.017:
					v.y = 0.086
					verts[vi] = v
					changed = true
				elif mat_name.contains("goldenglow") and v.y >= 0.011 and v.y <= 0.017:
					v.y = 0.100
					verts[vi] = v
					changed = true

	elif glb_kind == "viaduct":
		for vi: int in range(count):
			var ny: float = normals[vi].y if has_normals else 1.0
			if ny <= 0.90:
				continue
			var v: Vector3 = verts[vi]
			if mat_name.contains("obsidian") and v.y >= -0.055 and v.y <= -0.045:
				v.y = -0.100
				verts[vi] = v
				changed = true
			elif mat_name.contains("goldbrass"):
				if v.y >= -0.015 and v.y <= -0.005:
					v.y = -0.055
					verts[vi] = v
					changed = true
				elif v.y >= 0.016 and v.y <= 0.028:
					v.y = 0.046
					verts[vi] = v
					changed = true
			elif mat_name.contains("goldfiligree") and v.y >= 0.016 and v.y <= 0.028:
				v.y = 0.062
				verts[vi] = v
				changed = true
			elif mat_name.contains("goldenglow") and v.y >= 0.016 and v.y <= 0.028:
				v.y = 0.078
				verts[vi] = v
				changed = true

	return changed


func _refine_glb_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mesh_inst.mesh
		if mesh != null:
			var surface_count: int = mesh.get_surface_count()
			for surface_idx: int in range(surface_count):
				var src_mat: Material = mesh_inst.get_active_material(surface_idx)
				var replacement: Material = _classify_glb_surface_material(src_mat)
				mesh_inst.set_surface_override_material(surface_idx, replacement)
	for child: Node in node.get_children():
		_refine_glb_materials(child)


func _classify_glb_surface_material(src_mat: Material) -> Material:
	var mat_name: String = ""
	var is_gold: bool = false
	var albedo: Color = COLOR_INDIGO_STONE
	var has_pbr: bool = false

	if src_mat != null:
		mat_name = src_mat.resource_name.to_lower()
		# Explicit Walkable Fairytale Castle & Floating Island material mappings (zero shimmer, crisp identity)
		if mat_name.contains("islandgrass") or mat_name.contains("island_grass"):
			return _mat_island_grass
		if mat_name.contains("islandrock") or mat_name.contains("island_rock"):
			return _mat_island_rock
		if mat_name.contains("waterfall"):
			return _mat_waterfall
		if mat_name.contains("islandvine") or mat_name.contains("island_vine") or mat_name.contains("vine"):
			return _mat_island_vine
		if mat_name.contains("glass") or mat_name.contains("skylight"):
			return _mat_glass_skylight
		if mat_name.contains("window"):
			return _mat_warm_window
		if mat_name.contains("blueroof") or mat_name.contains("blue_roof"):
			return _mat_castle_blue_roof
		if mat_name.contains("floormarble") or mat_name.contains("floor_marble"):
			return _mat_castle_floor_marble
		if mat_name.contains("whitestone") or mat_name.contains("white_stone"):
			return _mat_castle_white_stone
		if mat_name.contains("gold") or mat_name.contains("brass"):
			is_gold = true
		if src_mat is BaseMaterial3D:
			var base_mat: BaseMaterial3D = src_mat as BaseMaterial3D
			albedo = base_mat.albedo_color
			has_pbr = true
			if base_mat.metallic >= 0.55:
				is_gold = true
			elif albedo.r > 0.55 and albedo.g > 0.35 and albedo.r > albedo.b * 1.8:
				is_gold = true

	if is_gold:
		if mat_name.contains("glow"):
			return _mat_gold_glow_accent
		if mat_name.contains("brass"):
			return _mat_gold_brass
		return _mat_gold_filigree

	# Preserve subtle brightness differentiation across stone surfaces for architectural depth
	if mat_name.contains("cobalt") or mat_name.contains("trim") or mat_name.contains("facet"):
		return _mat_cobalt_trim
	if mat_name.contains("obsidian") or mat_name.contains("dark") or mat_name.contains("deep"):
		return _mat_dark_obsidian
	if mat_name.contains("marble") or mat_name.contains("cosmic"):
		return _mat_polished_marble

	if has_pbr:
		if albedo.b > 0.22 and albedo.b > albedo.r * 1.15:
			return _mat_cobalt_trim
		if albedo.b < 0.04:
			return _mat_dark_obsidian

	return _mat_indigo_stone



func _add_box_mesh(
	parent: Node3D,
	node_name: String,
	size: Vector3,
	pos: Vector3,
	mat: Material,
	casts_shadow: bool = true
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.name = node_name
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = mat
	if not casts_shadow:
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


func _add_cylinder_mesh(
	parent: Node3D,
	node_name: String,
	top_radius: float,
	bottom_radius: float,
	height: float,
	radial_segments: int,
	pos: Vector3,
	mat: Material,
	casts_shadow: bool = true
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	var inst := MeshInstance3D.new()
	inst.name = node_name
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = mat
	if not casts_shadow:
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


func _add_torus_mesh(
	parent: Node3D,
	node_name: String,
	inner_radius: float,
	outer_radius: float,
	rings: int,
	ring_segments: int,
	pos: Vector3,
	mat: Material,
	casts_shadow: bool = true
) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = rings
	mesh.ring_segments = ring_segments
	var inst := MeshInstance3D.new()
	inst.name = node_name
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = mat
	if not casts_shadow:
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


func _add_sphere_mesh(
	parent: Node3D,
	node_name: String,
	radius: float,
	radial_segments: int,
	rings: int,
	pos: Vector3,
	mat: Material,
	casts_shadow: bool = true
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = radial_segments
	mesh.rings = rings
	var inst := MeshInstance3D.new()
	inst.name = node_name
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = mat
	if not casts_shadow:
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


func _add_box_collider(parent: Node3D, node_name: String, size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body


func _add_cylinder_collider(parent: Node3D, node_name: String, radius: float, height: float, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body
