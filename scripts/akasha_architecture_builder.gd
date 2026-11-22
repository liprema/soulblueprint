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
	Vector3(-26.0, 6.0, -32.0),
	Vector3(22.0, 10.0, -88.0),
	Vector3(-32.0, 14.0, -148.0),
	Vector3(18.0, 4.0, -195.0),
	Vector3(-16.0, -2.0, -105.0),
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

var _mat_indigo_stone: Material
var _mat_dark_obsidian: Material
var _mat_polished_marble: Material
var _mat_cobalt_trim: Material
var _mat_gold_filigree: StandardMaterial3D
var _mat_gold_brass: StandardMaterial3D
var _mat_gold_glow_accent: StandardMaterial3D
var _mat_gold_thread: StandardMaterial3D
var _mat_light_core: StandardMaterial3D
var _mat_mentor_body: Material
var _mat_mentor_halo: StandardMaterial3D
var _mat_god_rays: ShaderMaterial
var _mat_island_rays: ShaderMaterial

var _astrolabe_rings: Array[Node3D] = []
var _mentor_nodes: Array[Node3D] = []
var _mentor_base_y: Array[float] = []
var _mentor_halos: Array[Node3D] = []
var _elapsed_time: float = 0.0
var _is_built: bool = false


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
	_build_golden_threads_of_destiny()
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
	block_scale_val: float = 1.0
) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = MARBLE_SHADER
	mat.set_shader_parameter("stone_base_color", base_col)
	mat.set_shader_parameter("stone_highlight_color", highlight_col)
	mat.set_shader_parameter("stone_pore_color", pore_col)
	mat.set_shader_parameter("base_roughness", roughness_val)
	mat.set_shader_parameter("surface_specular", 0.42)
	mat.set_shader_parameter("surface_metallic", 0.02)
	mat.set_shader_parameter("fresnel_lift_strength", fresnel_strength)
	mat.set_shader_parameter("wetness_strength", wetness_val)
	mat.set_shader_parameter("block_scale", block_scale_val)
	return mat


func _init_materials() -> void:
	# Stray-inspired noble, desaturated twilight basalt & wet dark slate stonework
	# (lets warm amber lanterns, cyan mentors, and volumetric lighting carry the color!)
	_mat_dark_obsidian = _create_velvet_stone_material(
		Color("#11151E"), Color("#1B2230"), Color("#090C12"), 0.76, 0.08, 0.72, 0.90
	)
	_mat_indigo_stone = _create_velvet_stone_material(
		Color("#1A202C"), Color("#273042"), Color("#10141D"), 0.74, 0.10, 0.82, 1.00
	)
	_mat_polished_marble = _create_velvet_stone_material(
		Color("#242B38"), Color("#353F52"), Color("#161B25"), 0.66, 0.12, 0.95, 1.05
	)
	_mat_cobalt_trim = _create_velvet_stone_material(
		Color("#1B283A"), Color("#283A52"), Color("#111A26"), 0.68, 0.10, 0.78, 1.25
	)

	# Brushed antique satin gold & warm temple brass (smooth satin sheen, zero sub-pixel shimmer)
	var aged_gold_color: Color = Color("#CFA354")
	var temple_brass_color: Color = Color("#B28742")
	var warm_amber_emission: Color = Color("#D69B42")

	_mat_gold_filigree = StandardMaterial3D.new()
	_mat_gold_filigree.albedo_color = aged_gold_color
	_mat_gold_filigree.roughness = 0.40
	_mat_gold_filigree.metallic = 0.80
	_mat_gold_filigree.emission_enabled = true
	_mat_gold_filigree.emission = warm_amber_emission
	_mat_gold_filigree.emission_energy_multiplier = 0.14

	_mat_gold_brass = StandardMaterial3D.new()
	_mat_gold_brass.albedo_color = temple_brass_color
	_mat_gold_brass.roughness = 0.46
	_mat_gold_brass.metallic = 0.78
	_mat_gold_brass.emission_enabled = true
	_mat_gold_brass.emission = warm_amber_emission
	_mat_gold_brass.emission_energy_multiplier = 0.08

	_mat_gold_glow_accent = StandardMaterial3D.new()
	_mat_gold_glow_accent.albedo_color = Color("#E6BC6A")
	_mat_gold_glow_accent.roughness = 0.42
	_mat_gold_glow_accent.metallic = 0.58
	_mat_gold_glow_accent.emission_enabled = true
	_mat_gold_glow_accent.emission = warm_amber_emission
	_mat_gold_glow_accent.emission_energy_multiplier = 0.32

	_mat_gold_thread = StandardMaterial3D.new()
	_mat_gold_thread.albedo_color = aged_gold_color
	_mat_gold_thread.roughness = 0.38
	_mat_gold_thread.metallic = 0.55
	_mat_gold_thread.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_gold_thread.emission_enabled = true
	_mat_gold_thread.emission = warm_amber_emission
	_mat_gold_thread.emission_energy_multiplier = 0.65

	_mat_light_core = StandardMaterial3D.new()
	_mat_light_core.albedo_color = Color("#FFF6D4")
	_mat_light_core.roughness = 0.16
	_mat_light_core.emission_enabled = true
	_mat_light_core.emission = aged_gold_color
	_mat_light_core.emission_energy_multiplier = 1.65

	var mentor_mat: ShaderMaterial = ShaderMaterial.new()
	mentor_mat.shader = MENTOR_SHADER
	_mat_mentor_body = mentor_mat

	_mat_mentor_halo = StandardMaterial3D.new()
	_mat_mentor_halo.albedo_color = Color(COLOR_MENTOR_CYAN.r, COLOR_MENTOR_CYAN.g, COLOR_MENTOR_CYAN.b, 0.56)
	_mat_mentor_halo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_mentor_halo.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat_mentor_halo.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_mentor_halo.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_mat_mentor_halo.emission_enabled = true
	_mat_mentor_halo.emission = Color("#8CE0FF")
	_mat_mentor_halo.emission_energy_multiplier = 1.15

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


# ---------------------------------------------------------------------------
# a) Starting Monolith Plaza (z = 24..46, y = 0)
# ---------------------------------------------------------------------------

func _add_plaza_colliders(root: Node3D) -> void:
	# Main walkable deck collider (top strictly at y = 0.0, covers z = 23.5..46.5)
	_add_box_collider(root, "PlazaSurfaceCollider", Vector3(16.0, 2.4, 23.0), Vector3(0.0, -1.2, 35.0))
	# Forward ceremonial prow collider (top strictly at y = 0.0, covers down to z = 19.25)
	_add_box_collider(root, "PlazaProwCollider", Vector3(11.0, 2.4, 5.5), Vector3(0.0, -1.2, 22.0))
	# Low balustrade guard colliders along x = -7.0 and x = +7.0 (z = 24..46)
	_add_box_collider(root, "PlazaBalustradeCollider_L", Vector3(0.9, 1.6, 22.0), Vector3(-7.0, 0.8, 35.0))
	_add_box_collider(root, "PlazaBalustradeCollider_R", Vector3(0.9, 1.6, 22.0), Vector3(7.0, 0.8, 35.0))


func _build_starting_monolith_plaza() -> void:
	var root := Node3D.new()
	root.name = "StartingMonolithPlaza"
	add_child(root)

	if _try_instantiate_override(plaza_model_path, root, Vector3(0.0, 0.0, 35.0)):
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

	# Inlaid glowing golden astrolabe rings on the plaza floor (y = 0.015 to avoid z-fighting)
	var floor_y := 0.015
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
			Vector3(0.0, floor_y, plaza_center.z),
			_mat_gold_filigree
		)
		ring.scale = Vector3(1.0, 0.08, 1.0)

	# 8 radial golden compass spokes inlaid into the plaza floor
	for i in range(4):
		var spoke := _add_box_mesh(
			root, "FloorCompassSpoke_%d" % i,
			Vector3(0.14, 0.025, 11.6),
			Vector3(0.0, floor_y, plaza_center.z),
			_mat_gold_filigree
		)
		spoke.rotation.y = deg_to_rad(float(i) * 45.0)

	# Center glowing compass disc & forward directional runway stripe
	_add_cylinder_mesh(root, "FloorMedallion", 0.65, 0.65, 0.03, 24, Vector3(0.0, floor_y, plaza_center.z), _mat_gold_filigree)
	_add_box_mesh(root, "RunwayStrip", Vector3(0.28, 0.025, 14.0), Vector3(0.0, floor_y, 27.5), _mat_gold_filigree)

	# Monumental tapered monolith undercroft descending into the cloud sea
	_add_box_mesh(root, "UndercroftTier1", Vector3(14.0, 6.0, 19.5), Vector3(0.0, -5.4, plaza_center.z), _mat_indigo_stone)
	_add_cylinder_mesh(root, "UndercroftMonolith", 8.8, 3.2, 34.0, 8, Vector3(0.0, -25.0, plaza_center.z), _mat_dark_obsidian)
	_add_box_mesh(root, "UndercroftGoldRib_L", Vector3(0.3, 28.0, 0.5), Vector3(-5.8, -19.0, plaza_center.z), _mat_gold_filigree)
	_add_box_mesh(root, "UndercroftGoldRib_R", Vector3(0.3, 28.0, 0.5), Vector3(5.8, -19.0, plaza_center.z), _mat_gold_filigree)


# ---------------------------------------------------------------------------
# b) Sweeping 12-Arch Indigo Viaduct (x = 28..38, z = 20..-240)
# ---------------------------------------------------------------------------

func _build_indigo_viaduct() -> void:
	var root := Node3D.new()
	root.name = "IndigoViaduct"
	add_child(root)

	var arch_count := 12
	var z_start := 20.0
	var z_end := -240.0
	var total_length := z_start - z_end # 260.0 m
	var bay_span := total_length / float(arch_count) # ~21.667 m
	var viaduct_x := 33.0 # spans x = 28..38 (width 10m)
	var deck_width := 10.0
	var deck_collider_width := 10.5
	var deck_top_y := 14.0
	var deck_thickness := 2.2
	var pier_bottom_y := -66.0
	var deck_center_z := (z_start + z_end) * 0.5

	# Continuous solid walkable roadway collider along the full viaduct (top strictly at y = deck_top_y)
	_add_box_collider(
		root, "ViaductDeckCollider",
		Vector3(deck_collider_width, deck_thickness, total_length + 4.0),
		Vector3(viaduct_x, deck_top_y - deck_thickness * 0.5, deck_center_z)
	)

	# If viaduct_arch.glb exists, each bay already includes its own deck, parapets, and piers.
	# Instantiate the 12 .glb bays directly without spawning duplicate procedural piers/decks.
	if not viaduct_arch_model_path.is_empty() and ResourceLoader.exists(viaduct_arch_model_path):
		var loaded_any: bool = false
		for i: int in range(arch_count):
			var bay_z: float = z_start - (float(i) + 0.5) * bay_span
			if _try_instantiate_override(viaduct_arch_model_path, root, Vector3(viaduct_x, deck_top_y, bay_z)):
				loaded_any = true
		if loaded_any:
			return

	# Procedural fallback when viaduct_arch.glb is absent
	_add_box_mesh(
		root, "ViaductDeck",
		Vector3(deck_width, deck_thickness, total_length + 4.0),
		Vector3(viaduct_x, deck_top_y - deck_thickness * 0.5, deck_center_z),
		_mat_indigo_stone
	)

	# Continuous golden cornice rails along both sides of the viaduct
	for side: float in [-1.0, 1.0]:
		var rail_x: float = viaduct_x + side * (deck_width * 0.5 + 0.15)
		_add_box_mesh(
			root, "ViaductGoldCornice_%s" % ("L" if side < 0 else "R"),
			Vector3(0.38, 0.36, total_length + 4.4),
			Vector3(rail_x, deck_top_y - 0.15, deck_center_z),
			_mat_gold_filigree
		)
		_add_box_mesh(
			root, "ViaductParapet_%s" % ("L" if side < 0 else "R"),
			Vector3(0.7, 1.25, total_length + 4.0),
			Vector3(viaduct_x + side * (deck_width * 0.5 - 0.35), deck_top_y + 0.625, deck_center_z),
			_mat_dark_obsidian
		)

	# 13 monumental piers with golden vertical filigree trim
	var pier_height := (deck_top_y - deck_thickness) - pier_bottom_y
	var pier_center_y := pier_bottom_y + pier_height * 0.5

	for i in range(arch_count + 1):
		var pz := z_start - float(i) * bay_span
		var pier := Node3D.new()
		pier.name = "ViaductPier_%02d" % i
		pier.position = Vector3(viaduct_x, 0.0, pz)
		root.add_child(pier)

		# Core tapered stone pier
		_add_box_mesh(pier, "PierCore", Vector3(deck_width - 1.2, pier_height, 4.2), Vector3(0.0, pier_center_y, 0.0), _mat_indigo_stone)
		# Art Deco stepped capital
		_add_box_mesh(pier, "PierCapital", Vector3(deck_width + 0.6, 2.2, 5.2), Vector3(0.0, deck_top_y - deck_thickness - 1.1, 0.0), _mat_dark_obsidian)
		# Vertical golden filigree strips on the canyon-facing (-X) and outer (+X) sides
		for side: float in [-1.0, 1.0]:
			_add_box_mesh(
				pier, "GoldFiligree_%s" % ("In" if side < 0 else "Out"),
				Vector3(0.28, pier_height - 4.0, 0.55),
				Vector3(side * (deck_width * 0.5 - 0.45), pier_center_y, 0.0),
				_mat_gold_filigree
			)
		# Parapet obelisk finial on top of each pier
		_add_box_mesh(pier, "FinialBase", Vector3(1.1, 2.4, 1.1), Vector3(-deck_width * 0.5 + 0.35, deck_top_y + 2.2, 0.0), _mat_dark_obsidian)
		_add_cylinder_mesh(pier, "FinialTip", 0.05, 0.42, 1.4, 4, Vector3(-deck_width * 0.5 + 0.35, deck_top_y + 4.1, 0.0), _mat_gold_filigree)

	# 12 majestic arched spans between consecutive piers
	for i in range(arch_count):
		var bay_z := z_start - (float(i) + 0.5) * bay_span
		_build_viaduct_arch_bay(root, i, viaduct_x, deck_top_y - deck_thickness, bay_z, bay_span, deck_width)


func _build_viaduct_arch_bay(
	parent: Node3D,
	index: int,
	center_x: float,
	spring_top_y: float,
	center_z: float,
	span: float,
	width: float
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

		# Glowing golden inner arch trim on the canyon-facing side (-X)
		var trim := _add_box_mesh(
			bay, "ArchGoldTrim_%d" % s,
			Vector3(0.32, 0.34, seg_len + 0.1),
			Vector3(-(width * 0.5 - 0.65), local_y - 0.65 * sin(angle), local_z - 0.65 * cos(angle)),
			_mat_gold_filigree
		)
		trim.rotation.x = angle - PI * 0.5

	# Art Deco golden spandrel medallions above the arch shoulders
	for side_z: float in [-1.0, 1.0]:
		var med := _add_torus_mesh(
			bay, "SpandrelRing_%s" % ("F" if side_z < 0 else "B"),
			0.95, 1.22, 20, 8,
			Vector3(-(width * 0.5 - 0.55), -2.4, side_z * (arch_radius * 0.72)),
			_mat_gold_filigree
		)
		med.rotation_degrees.z = 90.0


# ---------------------------------------------------------------------------
# c) 5 Floating Carved Indigo Temple Islands
# ---------------------------------------------------------------------------

func _build_floating_temple_islands() -> void:
	var root := Node3D.new()
	root.name = "FloatingTempleIslands"
	add_child(root)

	for i in range(ISLAND_COORDS.size()):
		var pos: Vector3 = ISLAND_COORDS[i]
		var island := Node3D.new()
		island.name = "TempleIsland_%02d" % (i + 1)
		island.position = pos
		root.add_child(island)

		# Subtle scale variation across the 5 islands for organic monumentality
		var radius_scale := 1.0 + float(i % 3 - 1) * 0.08
		var slab_radius := 8.4 * radius_scale
		var slab_height := 1.4
		var collider_radius := 8.4
		var collider_height := 2.6

		if _try_instantiate_override(temple_island_model_path, island, Vector3.ZERO):
			_add_cylinder_collider(island, "IslandSlabCollider", collider_radius, collider_height, Vector3(0.0, -collider_height * 0.5, 0.0))
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

		# Inlaid golden sanctuary floor circle
		var floor_ring := _add_torus_mesh(
			island, "FloorSanctuaryRing",
			2.6, 2.82, 32, 8,
			Vector3(0.0, 0.015, 0.0),
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

func _add_cathedral_colliders(root: Node3D) -> void:
	# Lower podium platform (y = 0..4, size = 88x4x62, pos = (0, 2, 2))
	_add_box_collider(root, "CathedralLowerPodiumCollider", Vector3(88.0, 4.0, 62.0), Vector3(0.0, 2.0, 2.0))
	# Upper sanctuary dais (y = 4..8, size = 72x4x48, pos = (0, 6, 2))
	_add_box_collider(root, "CathedralUpperDaisCollider", Vector3(72.0, 4.0, 48.0), Vector3(0.0, 6.0, 2.0))

	# Smooth sloped front ceremonial stairs ramp connecting y = 0 (z = 38) up to y = 8 (z = 25)
	var stair_dz: float = 13.0
	var stair_dy: float = 8.0
	var ramp_angle: float = atan2(stair_dy, stair_dz)
	var ramp_len: float = sqrt(stair_dz * stair_dz + stair_dy * stair_dy) + 0.8
	var ramp_thickness: float = 2.4
	var ramp_center := Vector3(
		0.0,
		4.0 - cos(ramp_angle) * (ramp_thickness * 0.5),
		31.5 - sin(ramp_angle) * (ramp_thickness * 0.5)
	)
	var stairs_ramp: StaticBody3D = _add_box_collider(
		root, "CathedralFrontStairsRampCollider",
		Vector3(32.0, ramp_thickness, ramp_len),
		ramp_center
	)
	stairs_ramp.rotation.x = ramp_angle


func _build_colossal_cathedral() -> void:
	var root := Node3D.new()
	root.name = "AkashaAstrolabeCathedral"
	root.position = CATHEDRAL_POSITION
	add_child(root)

	if _try_instantiate_override(cathedral_model_path, root, Vector3.ZERO):
		_add_cathedral_colliders(root)
		_build_cathedral_astrolabe_rings(root, Vector3(0.0, 62.0, 8.0))
		return

	# Grand stepped obsidian-indigo sanctuary dais & deep foundation
	_add_box_mesh(root, "CathedralFoundation", Vector3(92.0, 82.0, 64.0), Vector3(0.0, -41.0, 0.0), _mat_dark_obsidian)
	_add_box_mesh(root, "CathedralDaisStep1", Vector3(84.0, 4.0, 56.0), Vector3(0.0, 2.0, 2.0), _mat_indigo_stone)
	_add_box_mesh(root, "CathedralDaisStep2", Vector3(68.0, 4.0, 44.0), Vector3(0.0, 6.0, 4.0), _mat_polished_marble)
	_add_cathedral_colliders(root)

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

	# Cubic Bezier curves sweeping gracefully through the sky canyon toward the Cathedral
	var threads := [
		{
			"name": "PrimaryDestinyThread",
			"p0": Vector3(0.0, 3.2, 22.0),
			"p1": Vector3(-14.0, 14.0, -60.0),
			"p2": Vector3(12.0, 26.0, -175.0),
			"p3": Vector3(0.0, 48.0, -266.0),
			"radius": 0.24,
		},
		{
			"name": "WestIslandRibbon",
			"p0": Vector3(-7.0, 6.0, 26.0),
			"p1": Vector3(-34.0, 18.0, -45.0),
			"p2": Vector3(-38.0, 28.0, -160.0),
			"p3": Vector3(-12.0, 62.0, -268.0),
			"radius": 0.16,
		},
		{
			"name": "EastViaductRibbon",
			"p0": Vector3(8.0, 7.5, 25.0),
			"p1": Vector3(36.0, 24.0, -70.0),
			"p2": Vector3(26.0, 16.0, -190.0),
			"p3": Vector3(10.0, 56.0, -268.0),
			"radius": 0.16,
		},
		{
			"name": "HighCelestialArcLeft",
			"p0": Vector3(-42.0, 26.0, -10.0),
			"p1": Vector3(-18.0, 48.0, -105.0),
			"p2": Vector3(22.0, 54.0, -195.0),
			"p3": Vector3(0.0, 76.0, -268.0),
			"radius": 0.14,
		},
		{
			"name": "HighCelestialArcRight",
			"p0": Vector3(38.0, 22.0, 5.0),
			"p1": Vector3(14.0, 42.0, -95.0),
			"p2": Vector3(-24.0, 46.0, -185.0),
			"p3": Vector3(0.0, 68.0, -268.0),
			"radius": 0.13,
		},
		{
			"name": "DeepCanyonThread",
			"p0": Vector3(-4.0, 1.5, 20.0),
			"p1": Vector3(-22.0, 2.0, -95.0),
			"p2": Vector3(20.0, 10.0, -192.0),
			"p3": Vector3(0.0, 32.0, -268.0),
			"radius": 0.12,
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

func _try_instantiate_override(res_path: String, parent: Node3D, local_pos: Vector3) -> bool:
	if res_path.is_empty() or not ResourceLoader.exists(res_path):
		return false
	var loaded: Resource = ResourceLoader.load(res_path)
	if loaded is PackedScene:
		var inst: Node = (loaded as PackedScene).instantiate()
		if inst is Node3D:
			(inst as Node3D).position = local_pos
		parent.add_child(inst)
		_refine_glb_materials(inst)
		return true
	return false


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
		if albedo.b > 0.22:
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
