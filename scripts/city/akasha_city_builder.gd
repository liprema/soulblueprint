class_name AkashaCityBuilder
extends Node3D

## AkashaCityBuilder v4 — «3-Уровневый Город Душ Хроник Акаши» (Godot 4.3+).
## Builds the 3-tier sunlit City of Souls (Tier 0 Y=0.0, Tier 1 Y=3.2, Tier 2 Y=5.6)
## with walkable stone staircases & arched retaining walls, sculpted meadow valley
## hills, Shining Canal & Bridge of Memory, 4 cascading waterfalls, 6 bobbing boats,
## Lake of Silence, 4 iconic landmarks (Grand Fountain, Cloud Balloon, Akashic Orrery,
## Triumphal Arch of Knowledge), 9 districts, ~550+ Pixar houses with procedural
## stucco/tile facade shading, 136 living souls traversing all 3 tiers, delicate
## golden star-sparks (0 floating blocks!), 3 quest artifacts, QuestBeacon, and
## airtight invisible boundary walls — tuned for 60 FPS on Apple Silicon.

const MEADOW_SHADER_PATH: String = "res://shaders/akasha_meadow_ground.gdshader"
const MARBLE_SHADER_PATH: String = "res://shaders/akasha_marble.gdshader"
const WATER_SHADER_PATH: String = "res://shaders/akasha_water.gdshader"
const PIXAR_TERRACE_PLAZA_SHADER_PATH: String = "res://shaders/pixar_terrace_plaza.gdshader"
const PIXAR_WATERFALL_SHADER_PATH: String = "res://shaders/pixar_waterfall.gdshader"
const PIXAR_BUILDING_FACADE_SHADER_PATH: String = "res://shaders/pixar_building_facade.gdshader"

const MODEL_SCHOOL_PATH: String = "res://assets/models/city/school_of_souls.glb"
const MODEL_LIBRARY_PATH: String = "res://assets/models/city/orion_library.glb"
const MODEL_CLOCKTOWER_PATH: String = "res://assets/models/city/kronos_clocktower.glb"
const MODEL_SANCTUARY_PATH: String = "res://assets/models/city/mira_sanctuary.glb"
const MODEL_BRIDGE_PATH: String = "res://assets/models/city/city_bridge.glb"
const MODEL_PAVILION_PATH: String = "res://assets/models/city/city_pavilion.glb"

const LANDMARK_FOUNTAIN_PATH: String = "res://assets/models/city/landmarks/landmark_grand_fountain.glb"
const LANDMARK_FOUNTAIN_ALT_PATH: String = "res://assets/models/city/landmark_grand_fountain.glb"
const LANDMARK_BALLOON_PATH: String = "res://assets/models/city/landmarks/landmark_cloud_balloon.glb"
const LANDMARK_BALLOON_ALT_PATH: String = "res://assets/models/city/landmark_cloud_balloon.glb"
const LANDMARK_ORRERY_PATH: String = "res://assets/models/city/landmarks/landmark_akashic_orrery.glb"
const LANDMARK_ORRERY_ALT_PATH: String = "res://assets/models/city/landmark_akashic_orrery.glb"
const LANDMARK_MEMORY_ARCH_PATH: String = "res://assets/models/city/landmarks/landmark_memory_arch.glb"
const LANDMARK_MEMORY_ARCH_ALT_PATH: String = "res://assets/models/city/landmark_memory_arch.glb"

const PIXAR_HOUSE_RED_PATH: String = "res://assets/models/city/pixar/house_red_gable.glb"
const PIXAR_HOUSE_BLUE_PATH: String = "res://assets/models/city/pixar/house_blue_balcony.glb"
const PIXAR_HOUSE_OCHRE_PATH: String = "res://assets/models/city/pixar/house_ochre_timber.glb"
const PIXAR_HOUSE_TERRACOTTA_PATH: String = "res://assets/models/city/pixar/house_terracotta_terrace.glb"
const PIXAR_HOUSE_CREAM_SPIRE_PATH: String = "res://assets/models/city/pixar/house_cream_spire.glb"
const PIXAR_CLIFF_ROCK_PATH: String = "res://assets/models/city/pixar/cliff_terrace_rock.glb"
const PIXAR_TREE_LUSH_PATH: String = "res://assets/models/city/pixar/pixar_tree_lush.glb"
const PIXAR_BOAT_PATH: String = "res://assets/models/city/pixar/pixar_boat.glb"

const PROP_SAKURA_PATH: String = "res://assets/models/props/sakura_tree.glb"
const PROP_BUSH_PATH: String = "res://assets/models/props/lush_bush_hedge.glb"
const PROP_PLANTER_PATH: String = "res://assets/models/props/garden_planter.glb"
const PROP_LANTERN_PATH: String = "res://assets/models/props/stone_lantern.glb"

const VALLEY_CENTER_Z: float = -100.0
const VALLEY_WIDTH: float = 460.0
const VALLEY_DEPTH: float = 560.0

const CANAL_Z: float = -32.0
const CANAL_LENGTH: float = 360.0
const CANAL_WIDTH: float = 14.0
const CANAL_WATER_Y: float = -0.25

const LAKE_CENTER: Vector3 = Vector3(54.0, -0.18, 12.0)
const LAKE_RADIUS: float = 13.0

const TIER_0_Y: float = 0.0
const TIER_1_Y: float = 3.2
const TIER_2_Y: float = 5.6

const ROAD_TOP_Y: float = 0.03
const PLAZA_TOP_Y: float = 0.04
const BRIDGE_DECK_Y: float = 1.35

const DISTRICT_QUERY_RADIUS: float = 28.0

# Shared materials (reused across meshes for 60 FPS on macOS Retina)
var _facade_shader: Shader = null
var _facade_mat_cache: Dictionary = {}
var _mat_meadow: Material = null
var _mat_marble_road: Material = null
var _mat_marble_plaza: Material = null
var _mat_marble_wall: Material = null
var _mat_gold_trim: StandardMaterial3D = null
var _mat_blue_roof: StandardMaterial3D = null
var _mat_warm_window: StandardMaterial3D = null
var _mat_stone_quay: StandardMaterial3D = null
var _mat_water_canal: Material = null
var _mat_water_lake: Material = null
var _mat_waterfall: Material = null
var _mat_waterfall_foam: StandardMaterial3D = null
var _mat_canal_bed: StandardMaterial3D = null
var _mat_beacon_beam: StandardMaterial3D = null
var _mat_beacon_crystal: StandardMaterial3D = null
var _mat_beacon_ring: StandardMaterial3D = null

# Pixar palette materials (terraces, cliffs, autumn/emerald trees, colorful fallbacks)
var _mat_terrace_stone: Material = null
var _mat_arch_recess: StandardMaterial3D = null
var _mat_cliff_rock: StandardMaterial3D = null
var _mat_foliage_green: StandardMaterial3D = null
var _mat_foliage_gold: StandardMaterial3D = null
var _mat_foliage_sakura: StandardMaterial3D = null
var _mat_trunk_wood: StandardMaterial3D = null
var _mat_wall_cream: Material = null
var _mat_wall_ochre: Material = null
var _mat_wall_peach: Material = null
var _mat_roof_red: Material = null
var _mat_roof_terracotta: Material = null
var _mat_roof_ochre: Material = null
var _mat_boat_hull: StandardMaterial3D = null
var _mat_boat_trim: StandardMaterial3D = null

# v4 Megapolis materials (souls, garlands, delicate star sparks, benches & pots)
var _mat_soul_body: StandardMaterial3D = null
var _mat_soul_halo: StandardMaterial3D = null
var _mat_garland_lantern: StandardMaterial3D = null
var _mat_garland_cable: StandardMaterial3D = null
var _mat_spark_star: StandardMaterial3D = null
var _mat_bench_wood: StandardMaterial3D = null
var _mat_flower_pot: StandardMaterial3D = null

# Cached PackedScenes for safe instantiation & MultiMesh sub-mesh extraction
var _scene_sakura: PackedScene = null
var _scene_bush: PackedScene = null
var _scene_planter: PackedScene = null
var _scene_lantern: PackedScene = null
var _scene_pavilion: PackedScene = null
var _scene_house_red: PackedScene = null
var _scene_house_blue: PackedScene = null
var _scene_house_ochre: PackedScene = null
var _scene_house_terracotta: PackedScene = null
var _scene_house_cream_spire: PackedScene = null
var _scene_cliff_rock: PackedScene = null
var _scene_tree_lush: PackedScene = null
var _scene_boat: PackedScene = null

# Unified 5-type Pixar house batches (inner wall-to-wall quarters + 5-tier terraces)
var _city_house_batches: Dictionary = {}
var _placed_inner_houses: Array[Vector2] = []

# District registry (contract with all tracks)
var _districts: Array[Dictionary] = []
var _district_spawns: Dictionary = {}

# Quest items, beacon, boats, landmarks, living souls & delicate golden star-sparks
var _quest_items: Dictionary = {}
var _quest_item_floaters: Array[Dictionary] = []
var _boat_floaters: Array[Dictionary] = []
var _orrery_rotator: Node3D = null
var _balloon_floater: Node3D = null
var _balloon_base_y: float = 0.0
var _souls_body_mm: MultiMesh = null
var _souls_halo_mm: MultiMesh = null
var _walking_souls: Array[Dictionary] = []
var _sky_souls: Array[Dictionary] = []
var _akasha_sparks_mm: MultiMesh = null
var _akasha_sparks_data: Array[Dictionary] = []
var _quest_beacon_root: Node3D = null
var _quest_beacon_crystal: MeshInstance3D = null
var _quest_beacon_beam: MeshInstance3D = null
var _quest_beacon_ring: MeshInstance3D = null
var _quest_beacon_active: bool = false

var _anim_time: float = 0.0
var _built: bool = false


func _ready() -> void:
	build_city()


func build_city() -> void:
	if _built:
		return
	_built = true

	_init_district_registry()
	_init_materials()
	_preload_prop_scenes()
	_init_house_batches()

	_build_unified_ground_and_valley()
	_build_mountain_horizon_ring()
	_build_canal_and_lake()
	_build_waterfalls_and_boats()
	_build_three_tier_terraces_and_stairs()
	_build_roads_and_plazas()
	_build_city_buildings()
	_build_terraced_endless_city()
	_build_city_props_and_flora()
	_build_street_life_and_akasha_magic()
	_build_living_souls_crowd()
	_build_lantern_garden_particles()
	_build_quest_artifacts()
	_build_quest_beacon()
	_build_invisible_boundary_walls()


func _process(delta: float) -> void:
	_anim_time += delta

	for entry_var in _quest_item_floaters:
		var entry: Dictionary = entry_var as Dictionary
		var root_node: Node3D = entry["root"] as Node3D
		if root_node == null or not root_node.visible:
			continue
		var floater: Node3D = entry["floater"] as Node3D
		var base_y: float = float(entry["base_y"])
		var phase: float = float(entry["phase"])
		if floater != null:
			floater.position.y = base_y + sin(_anim_time * 2.1 + phase) * 0.14
			floater.rotation.y = _anim_time * 0.9 + phase

	for boat_var in _boat_floaters:
		var b_entry: Dictionary = boat_var as Dictionary
		var b_node: Node3D = b_entry["node"] as Node3D
		if b_node == null:
			continue
		var b_base_y: float = float(b_entry["base_y"])
		var b_yaw: float = float(b_entry["base_yaw"])
		var b_phase: float = float(b_entry["phase"])
		b_node.position.y = b_base_y + sin(_anim_time * 1.45 + b_phase) * 0.055
		b_node.rotation.x = sin(_anim_time * 1.15 + b_phase * 1.3) * 0.032
		b_node.rotation.z = cos(_anim_time * 0.95 + b_phase * 0.8) * 0.042
		b_node.rotation.y = b_yaw + sin(_anim_time * 0.45 + b_phase) * 0.035

	if _orrery_rotator != null:
		_orrery_rotator.rotation.y = _anim_time * 0.28

	if _balloon_floater != null:
		_balloon_floater.position.y = _balloon_base_y + sin(_anim_time * 1.05) * 0.36
		_balloon_floater.rotation.y = sin(_anim_time * 0.38) * 0.12

	_update_living_souls()
	_update_akasha_sparks()

	if _quest_beacon_active and _quest_beacon_root != null and _quest_beacon_root.visible:
		if _quest_beacon_crystal != null:
			_quest_beacon_crystal.position.y = 3.2 + sin(_anim_time * 2.6) * 0.35
			_quest_beacon_crystal.rotation.y = _anim_time * 1.4
		if _quest_beacon_ring != null:
			var pulse: float = 1.0 + sin(_anim_time * 3.0) * 0.12
			_quest_beacon_ring.scale = Vector3(pulse, 1.0, pulse)
		if _quest_beacon_beam != null and _mat_beacon_beam != null:
			var alpha_pulse: float = 0.16 + 0.06 * sin(_anim_time * 2.2)
			_mat_beacon_beam.albedo_color.a = clampf(alpha_pulse, 0.08, 0.28)


# ===========================================================================
# PUBLIC API (100% preserved contract)
# ===========================================================================

## Positions and toggles the 3D golden QuestBeacon above the current objective.
func set_quest_beacon(target_pos: Vector3, active: bool) -> void:
	_quest_beacon_active = active
	if _quest_beacon_root == null:
		return
	_quest_beacon_root.visible = active
	if active:
		_quest_beacon_root.position = Vector3(target_pos.x, target_pos.y, target_pos.z)


## Shows or hides one of the 3 Blueprint quest artifacts:
## "memory_drop", "blank_page", "seven_springs_sand".
func set_quest_item_visible(item_id: String, is_visible: bool) -> void:
	if not _quest_items.has(item_id):
		return
	var node: Node3D = _quest_items[item_id] as Node3D
	if node != null:
		node.visible = is_visible


## Returns a safe, dry, walkable spawn position in the requested district.
func get_district_spawn_position(district_id: String) -> Vector3:
	if _district_spawns.has(district_id):
		return _district_spawns[district_id] as Vector3
	return Vector3(0.0, 0.1, 55.5)


## Returns {"id": String, "name": String} for the nearest district within 28 m,
## or an empty Dictionary if outside all districts.
func get_district_info_at(pos: Vector3) -> Dictionary:
	var best_dist_sq: float = DISTRICT_QUERY_RADIUS * DISTRICT_QUERY_RADIUS
	var best_id: String = ""
	var best_name: String = ""
	for d in _districts:
		var wpos: Vector3 = d["world_pos"] as Vector3
		var dx: float = pos.x - wpos.x
		var dz: float = pos.z - wpos.z
		var dist_sq: float = dx * dx + dz * dz
		if dist_sq <= best_dist_sq:
			best_dist_sq = dist_sq
			best_id = String(d["id"])
			best_name = String(d["name"])
	if best_id.is_empty():
		return {}
	return {
		"id": best_id,
		"name": best_name,
	}


## Returns a copy of all 9 City of Souls districts with id, name, subtitle, world_pos.
func get_all_districts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for d in _districts:
		result.append({
			"id": String(d["id"]),
			"name": String(d["name"]),
			"subtitle": String(d["subtitle"]),
			"world_pos": d["world_pos"] as Vector3,
		})
	return result


# ===========================================================================
# 1. DISTRICT REGISTRY & SHARED MATERIALS
# ===========================================================================

func _init_district_registry() -> void:
	_districts = [
		{
			"id": "awakening_plaza",
			"name": "Площадь Пробуждения",
			"subtitle": "Врата Города Душ",
			"world_pos": Vector3(0.0, TIER_0_Y, 48.0),
		},
		{
			"id": "school_of_souls",
			"name": "Школа Юных Душ",
			"subtitle": "Первые уроки света",
			"world_pos": Vector3(-42.0, TIER_1_Y, 8.0),
		},
		{
			"id": "quiet_lakes_park",
			"name": "Озёрный Парк Тишины",
			"subtitle": "Зеркало спокойных вод",
			"world_pos": Vector3(44.0, TIER_0_Y, 10.0),
		},
		{
			"id": "central_boulevard",
			"name": "Центральный Бульвар и Мост Памяти",
			"subtitle": "Переправа через Сияющий Канал",
			"world_pos": Vector3(0.0, TIER_0_Y, -32.0),
		},
		{
			"id": "orion_library",
			"name": "Библиотека Звёздных Свитков",
			"subtitle": "Хранилище вечных историй",
			"world_pos": Vector3(-48.0, TIER_1_Y, -78.0),
		},
		{
			"id": "kronos_tower",
			"name": "Площадь и Башня Времени",
			"subtitle": "Ритм семи вёсен",
			"world_pos": Vector3(48.0, TIER_1_Y, -78.0),
		},
		{
			"id": "lantern_garden",
			"name": "Сад Небесных Фонариков",
			"subtitle": "Аллея парящих огней",
			"world_pos": Vector3(-34.0, TIER_1_Y, -138.0),
		},
		{
			"id": "mira_sanctuary",
			"name": "Дом Утешения Миры",
			"subtitle": "Тёплый приют сердца",
			"world_pos": Vector3(34.0, TIER_1_Y, -138.0),
		},
		{
			"id": "earth_mirror_temple",
			"name": "Верхний Храм Зеркала Земли",
			"subtitle": "Барочный Дворец Хроник",
			"world_pos": Vector3(0.0, TIER_0_Y, -280.0),
		},
	]

	_district_spawns = {
		"awakening_plaza": Vector3(0.0, TIER_0_Y + 0.1, 55.5),
		"school_of_souls": Vector3(-36.0, TIER_1_Y + 0.1, 8.0),
		"quiet_lakes_park": Vector3(32.0, TIER_0_Y + 0.1, 10.0),
		"central_boulevard": Vector3(0.0, TIER_0_Y + 0.1, -18.0),
		"orion_library": Vector3(-36.0, TIER_1_Y + 0.1, -78.0),
		"kronos_tower": Vector3(36.0, TIER_1_Y + 0.1, -78.0),
		"lantern_garden": Vector3(-30.0, TIER_1_Y + 0.1, -138.0),
		"mira_sanctuary": Vector3(28.0, TIER_1_Y + 0.1, -138.0),
		"earth_mirror_temple": Vector3(0.0, TIER_0_Y + 0.1, -222.0),
	}


func _init_materials() -> void:
	_facade_mat_cache.clear()
	if ResourceLoader.exists(PIXAR_BUILDING_FACADE_SHADER_PATH):
		var fac_res: Resource = load(PIXAR_BUILDING_FACADE_SHADER_PATH)
		if fac_res is Shader:
			_facade_shader = fac_res as Shader

	# Meadow ground shader (with safe lush green StandardMaterial3D fallback)
	if ResourceLoader.exists(MEADOW_SHADER_PATH):
		var meadow_res: Resource = load(MEADOW_SHADER_PATH)
		if meadow_res is Shader:
			var meadow_mat: ShaderMaterial = ShaderMaterial.new()
			meadow_mat.shader = meadow_res as Shader
			meadow_mat.set_shader_parameter("vertex_color_blend", 0.0)
			meadow_mat.set_shader_parameter("daisy_density", 0.45)
			_mat_meadow = meadow_mat
	if _mat_meadow == null:
		var meadow_fb: StandardMaterial3D = StandardMaterial3D.new()
		meadow_fb.albedo_color = Color("#4E9E42")
		meadow_fb.roughness = 0.88
		meadow_fb.metallic = 0.0
		_mat_meadow = meadow_fb

	# Pixar Terrace Plaza & Paved Avenue shader (radial_mode = 1.0 for plazas, 0.0 for avenues)
	var terrace_shader: Shader = null
	if ResourceLoader.exists(PIXAR_TERRACE_PLAZA_SHADER_PATH):
		var tp_res: Resource = load(PIXAR_TERRACE_PLAZA_SHADER_PATH)
		if tp_res is Shader:
			terrace_shader = tp_res as Shader

	if terrace_shader != null:
		var road_mat: ShaderMaterial = ShaderMaterial.new()
		road_mat.shader = terrace_shader
		road_mat.set_shader_parameter("radial_mode", 0.0)
		road_mat.set_shader_parameter("stone_light", Color(0.84, 0.75, 0.62))
		road_mat.set_shader_parameter("stone_terracotta", Color(0.76, 0.48, 0.33))
		road_mat.set_shader_parameter("gold_inlay", Color(0.84, 0.64, 0.28))
		road_mat.set_shader_parameter("grout_color", Color(0.50, 0.39, 0.29))
		road_mat.set_shader_parameter("stone_roughness", 0.72)
		road_mat.set_shader_parameter("weathering_strength", 0.44)
		_mat_marble_road = road_mat

		var plaza_mat: ShaderMaterial = ShaderMaterial.new()
		plaza_mat.shader = terrace_shader
		plaza_mat.set_shader_parameter("radial_mode", 1.0)
		plaza_mat.set_shader_parameter("stone_light", Color(0.85, 0.76, 0.63))
		plaza_mat.set_shader_parameter("stone_terracotta", Color(0.77, 0.49, 0.34))
		plaza_mat.set_shader_parameter("gold_inlay", Color(0.85, 0.65, 0.29))
		plaza_mat.set_shader_parameter("grout_color", Color(0.50, 0.39, 0.29))
		plaza_mat.set_shader_parameter("stone_roughness", 0.70)
		plaza_mat.set_shader_parameter("weathering_strength", 0.42)
		_mat_marble_plaza = plaza_mat
	else:
		# Warm sunlit sandstone-terracotta StandardMaterial3D fallback
		var road_fb: StandardMaterial3D = StandardMaterial3D.new()
		road_fb.albedo_color = Color("#D6BD9C")
		road_fb.roughness = 0.70
		road_fb.metallic = 0.02
		_mat_marble_road = road_fb

		var plaza_fb: StandardMaterial3D = StandardMaterial3D.new()
		plaza_fb.albedo_color = Color("#DDC6A6")
		plaza_fb.roughness = 0.66
		plaza_fb.metallic = 0.03
		_mat_marble_plaza = plaza_fb

	# Marble building wall / arch / balustrade material (warm honey-limestone, zero glare)
	var marble_shader: Shader = null
	if ResourceLoader.exists(MARBLE_SHADER_PATH):
		var m_res: Resource = load(MARBLE_SHADER_PATH)
		if m_res is Shader:
			marble_shader = m_res as Shader

	if marble_shader != null:
		_mat_marble_wall = _create_marble_shader_mat(
			marble_shader,
			Color("#E2D4BE"),
			Color("#EFE4D2"),
			Color("#B8A58C"),
			0.62,
			0.0,
			0.95
		)
	else:
		var wall_fb: StandardMaterial3D = StandardMaterial3D.new()
		wall_fb.albedo_color = Color("#E2D4BE")
		wall_fb.roughness = 0.66
		_mat_marble_wall = wall_fb

	# Champagne Gold Trim
	_mat_gold_trim = StandardMaterial3D.new()
	_mat_gold_trim.albedo_color = Color("#D9B25E")
	_mat_gold_trim.metallic = 0.78
	_mat_gold_trim.roughness = 0.34
	_mat_gold_trim.emission_enabled = true
	_mat_gold_trim.emission = Color("#EBC672")
	_mat_gold_trim.emission_energy_multiplier = 0.15

	# Royal Celestial Blue Roof
	_mat_blue_roof = StandardMaterial3D.new()
	_mat_blue_roof.albedo_color = Color("#245DA3")
	_mat_blue_roof.metallic = 0.14
	_mat_blue_roof.roughness = 0.42

	# Warm Glowing Windows
	_mat_warm_window = StandardMaterial3D.new()
	_mat_warm_window.albedo_color = Color("#FFF0C8")
	_mat_warm_window.roughness = 0.24
	_mat_warm_window.emission_enabled = true
	_mat_warm_window.emission = Color("#FFDF94")
	_mat_warm_window.emission_energy_multiplier = 1.35

	# Stone Quay / Curbs (warm honey-travertine)
	_mat_stone_quay = StandardMaterial3D.new()
	_mat_stone_quay.albedo_color = Color("#CBB99E")
	_mat_stone_quay.roughness = 0.74
	_mat_stone_quay.metallic = 0.02

	# Warm Terrace Retaining Wall Stone (procedural stucco & masonry via pixar_building_facade.gdshader)
	_mat_terrace_stone = _create_facade_shader_mat(
		Color("#C9B08E"),
		Color("#9E805E"),
		0.78,
		0.0,
		0.56,
		0.10,
		2.2
	)

	# Deep shaded arch recess for arched terrace retaining walls
	_mat_arch_recess = StandardMaterial3D.new()
	_mat_arch_recess.albedo_color = Color("#5E4B3A")
	_mat_arch_recess.roughness = 0.92
	_mat_arch_recess.metallic = 0.0

	# Sculpted Cliff Rock Fallback
	_mat_cliff_rock = StandardMaterial3D.new()
	_mat_cliff_rock.albedo_color = Color("#A68666")
	_mat_cliff_rock.roughness = 0.88
	_mat_cliff_rock.metallic = 0.0

	# Lush Green, Golden Autumn & Sakura Foliage
	_mat_foliage_green = StandardMaterial3D.new()
	_mat_foliage_green.albedo_color = Color("#398C42")
	_mat_foliage_green.roughness = 0.72
	_mat_foliage_green.metallic = 0.0

	_mat_foliage_gold = StandardMaterial3D.new()
	_mat_foliage_gold.albedo_color = Color("#DC9A2C")
	_mat_foliage_gold.roughness = 0.68
	_mat_foliage_gold.metallic = 0.0
	_mat_foliage_gold.emission_enabled = true
	_mat_foliage_gold.emission = Color("#D88E24")
	_mat_foliage_gold.emission_energy_multiplier = 0.08

	_mat_foliage_sakura = StandardMaterial3D.new()
	_mat_foliage_sakura.albedo_color = Color("#EAA4BA")
	_mat_foliage_sakura.roughness = 0.72

	_mat_trunk_wood = StandardMaterial3D.new()
	_mat_trunk_wood.albedo_color = Color("#65432E")
	_mat_trunk_wood.roughness = 0.88

	# Pixar House Fallback Palette (deepened ~15% + procedural facade shader!)
	_mat_wall_cream = _create_facade_shader_mat(Color("#E0D0B4"), Color("#BFA988"), 0.72, 0.0, 0.48, 0.18, 1.8)
	_mat_wall_ochre = _create_facade_shader_mat(Color("#D8B064"), Color("#B48842"), 0.74, 0.0, 0.48, 0.18, 1.8)
	_mat_wall_peach = _create_facade_shader_mat(Color("#DAAC8B"), Color("#B88464"), 0.74, 0.0, 0.48, 0.18, 1.8)
	_mat_roof_red = _create_facade_shader_mat(Color("#AE342A"), Color("#86221B"), 0.54, 0.0, 0.50, 0.18, 1.4)
	_mat_roof_terracotta = _create_facade_shader_mat(Color("#BA5732"), Color("#923D20"), 0.56, 0.0, 0.50, 0.18, 1.4)
	_mat_roof_ochre = _create_facade_shader_mat(Color("#AE7424"), Color("#865416"), 0.54, 0.0, 0.50, 0.18, 1.4)

	_mat_boat_hull = StandardMaterial3D.new()
	_mat_boat_hull.albedo_color = Color("#B84830")
	_mat_boat_hull.roughness = 0.52

	_mat_boat_trim = StandardMaterial3D.new()
	_mat_boat_trim.albedo_color = Color("#E8C46A")
	_mat_boat_trim.roughness = 0.42

	# Canal Bed
	_mat_canal_bed = StandardMaterial3D.new()
	_mat_canal_bed.albedo_color = Color("#165A6E")
	_mat_canal_bed.roughness = 0.92

	# Water Materials (akasha_water.gdshader or luminous turquoise fallback)
	var water_shader: Shader = null
	if ResourceLoader.exists(WATER_SHADER_PATH):
		var w_res: Resource = load(WATER_SHADER_PATH)
		if w_res is Shader:
			water_shader = w_res as Shader

	if water_shader != null:
		var canal_w: ShaderMaterial = ShaderMaterial.new()
		canal_w.shader = water_shader
		canal_w.set_shader_parameter("shallow_color", Color("#7CECF2"))
		canal_w.set_shader_parameter("mid_color", Color("#26ACC0"))
		canal_w.set_shader_parameter("deep_color", Color("#197A98"))
		canal_w.set_shader_parameter("sky_reflect_color", Color("#D8F4FF"))
		canal_w.set_shader_parameter("foam_color", Color("#F4FDFF"))
		canal_w.set_shader_parameter("caustic_color", Color("#A4F8FC"))
		canal_w.set_shader_parameter("ring_mode", 1.0)
		canal_w.set_shader_parameter("water_alpha", 0.88)
		_mat_water_canal = canal_w

		var lake_w: ShaderMaterial = ShaderMaterial.new()
		lake_w.shader = water_shader
		lake_w.set_shader_parameter("shallow_color", Color("#88F0F6"))
		lake_w.set_shader_parameter("mid_color", Color("#30B8C8"))
		lake_w.set_shader_parameter("deep_color", Color("#1C7C98"))
		lake_w.set_shader_parameter("sky_reflect_color", Color("#DCF5FF"))
		lake_w.set_shader_parameter("foam_color", Color("#F6FEFF"))
		lake_w.set_shader_parameter("caustic_color", Color("#A8FAFC"))
		lake_w.set_shader_parameter("ring_mode", 0.0)
		lake_w.set_shader_parameter("water_alpha", 0.86)
		_mat_water_lake = lake_w
	else:
		var water_fb: StandardMaterial3D = StandardMaterial3D.new()
		water_fb.albedo_color = Color(0.22, 0.80, 0.86, 0.86)
		water_fb.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		water_fb.roughness = 0.10
		water_fb.emission_enabled = true
		water_fb.emission = Color("#3EC8D6")
		water_fb.emission_energy_multiplier = 0.25
		_mat_water_canal = water_fb
		_mat_water_lake = water_fb

	# Animated Cascade Waterfall Material (pixar_waterfall.gdshader with safe fallback)
	var wf_shader: Shader = null
	if ResourceLoader.exists(PIXAR_WATERFALL_SHADER_PATH):
		var wf_res: Resource = load(PIXAR_WATERFALL_SHADER_PATH)
		if wf_res is Shader:
			wf_shader = wf_res as Shader

	if wf_shader != null:
		var wf_mat: ShaderMaterial = ShaderMaterial.new()
		wf_mat.shader = wf_shader
		wf_mat.set_shader_parameter("water_top_color", Color(0.28, 0.88, 0.94))
		wf_mat.set_shader_parameter("water_deep_color", Color(0.12, 0.62, 0.82))
		wf_mat.set_shader_parameter("foam_color", Color(0.96, 0.99, 1.00))
		wf_mat.set_shader_parameter("flow_speed", 1.55)
		wf_mat.set_shader_parameter("stream_scale", 4.4)
		wf_mat.set_shader_parameter("foam_intensity", 1.05)
		wf_mat.set_shader_parameter("water_opacity", 0.92)
		_mat_waterfall = wf_mat
	else:
		var wf_fb: StandardMaterial3D = StandardMaterial3D.new()
		wf_fb.albedo_color = Color(0.46, 0.90, 0.96, 0.88)
		wf_fb.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wf_fb.cull_mode = BaseMaterial3D.CULL_DISABLED
		wf_fb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_waterfall = wf_fb

	_mat_waterfall_foam = StandardMaterial3D.new()
	_mat_waterfall_foam.albedo_color = Color(0.95, 0.99, 1.0, 0.68)
	_mat_waterfall_foam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_waterfall_foam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_waterfall_foam.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	# Luminous Souls (per-instance color via MultiMesh.use_colors = true)
	_mat_soul_body = StandardMaterial3D.new()
	_mat_soul_body.albedo_color = Color(1.0, 1.0, 1.0, 0.90)
	_mat_soul_body.vertex_color_use_as_albedo = true
	_mat_soul_body.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_soul_body.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_soul_body.cull_mode = BaseMaterial3D.CULL_BACK

	_mat_soul_halo = StandardMaterial3D.new()
	_mat_soul_halo.albedo_color = Color(1.0, 1.0, 1.0, 0.85)
	_mat_soul_halo.vertex_color_use_as_albedo = true
	_mat_soul_halo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_soul_halo.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat_soul_halo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_soul_halo.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	# Overhead Golden Street Lantern Garlands
	_mat_garland_lantern = StandardMaterial3D.new()
	_mat_garland_lantern.albedo_color = Color("#FFE8A6")
	_mat_garland_lantern.roughness = 0.25
	_mat_garland_lantern.emission_enabled = true
	_mat_garland_lantern.emission = Color("#FFC95C")
	_mat_garland_lantern.emission_energy_multiplier = 2.1

	_mat_garland_cable = StandardMaterial3D.new()
	_mat_garland_cable.albedo_color = Color("#4A3B30")
	_mat_garland_cable.roughness = 0.80
	_mat_garland_cable.metallic = 0.25

	# Delicate Golden Star-Sparks (replaces floating square pages — 0 floating blocks!)
	_mat_spark_star = StandardMaterial3D.new()
	_mat_spark_star.albedo_color = Color(1.0, 0.92, 0.62, 0.90)
	_mat_spark_star.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_spark_star.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat_spark_star.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_spark_star.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	# Grounded Street Benches & Terracotta Flower Pots
	_mat_bench_wood = StandardMaterial3D.new()
	_mat_bench_wood.albedo_color = Color("#7E4F30")
	_mat_bench_wood.roughness = 0.78

	_mat_flower_pot = StandardMaterial3D.new()
	_mat_flower_pot.albedo_color = Color("#BC5E3A")
	_mat_flower_pot.roughness = 0.68


func _create_facade_shader_mat(
	base_col: Color,
	accent_col: Color,
	rough_val: float,
	metal_val: float,
	grain_val: float,
	var_val: float,
	ao_h: float
) -> Material:
	if _facade_shader != null:
		var sm: ShaderMaterial = ShaderMaterial.new()
		sm.shader = _facade_shader
		sm.set_shader_parameter("base_color", base_col)
		sm.set_shader_parameter("accent_color", accent_col)
		sm.set_shader_parameter("roughness_val", rough_val)
		sm.set_shader_parameter("metallic_val", metal_val)
		sm.set_shader_parameter("grain_strength", grain_val)
		sm.set_shader_parameter("per_building_variation", var_val)
		sm.set_shader_parameter("base_ao_height", ao_h)
		return sm
	var fb: StandardMaterial3D = StandardMaterial3D.new()
	fb.albedo_color = base_col
	fb.roughness = rough_val
	fb.metallic = metal_val
	return fb


func _deepen_facade_color(col: Color) -> Color:
	var h: float = col.h
	var s: float = clampf(col.s * 1.15 + 0.03, 0.0, 0.92)
	var v: float = clampf(col.v * 0.85, 0.10, 0.86)
	return Color.from_hsv(h, s, v, 1.0)


func _upgrade_to_facade_material(orig_mat: Material) -> Material:
	if orig_mat == null:
		return _mat_wall_cream
	if orig_mat is ShaderMaterial:
		return orig_mat
	var cache_key: int = orig_mat.get_instance_id()
	if _facade_mat_cache.has(cache_key):
		return _facade_mat_cache[cache_key] as Material

	if orig_mat is BaseMaterial3D:
		var bm: BaseMaterial3D = orig_mat as BaseMaterial3D
		var mat_name: String = bm.resource_name.to_lower()
		var is_emissive_window: bool = (
			(bm.emission_enabled and bm.emission_energy_multiplier > 0.20)
			or mat_name.contains("window")
			or mat_name.contains("glass")
			or mat_name.contains("glow")
			or mat_name.contains("lamp")
			or mat_name.contains("lantern")
		)
		if is_emissive_window:
			_facade_mat_cache[cache_key] = orig_mat
			return orig_mat

		var deep_col: Color = _deepen_facade_color(bm.albedo_color)
		var accent_col: Color = deep_col.darkened(0.22)
		var rough_v: float = clampf(bm.roughness, 0.48, 0.86)
		var metal_v: float = clampf(bm.metallic, 0.0, 0.65)
		var upgraded: Material = _create_facade_shader_mat(
			deep_col,
			accent_col,
			rough_v,
			metal_v,
			0.48,
			0.18,
			1.8
		)
		_facade_mat_cache[cache_key] = upgraded
		return upgraded

	return orig_mat


func _create_marble_shader_mat(
	shader_res: Shader,
	base_col: Color,
	hi_col: Color,
	pore_col: Color,
	rough_val: float,
	seam_val: float,
	block_sc: float
) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader_res
	mat.set_shader_parameter("stone_base_color", base_col)
	mat.set_shader_parameter("stone_highlight_color", hi_col)
	mat.set_shader_parameter("stone_pore_color", pore_col)
	mat.set_shader_parameter("horizon_tint_color", Color("#B8D8F8"))
	mat.set_shader_parameter("base_roughness", rough_val)
	mat.set_shader_parameter("seam_strength", seam_val)
	mat.set_shader_parameter("block_scale", block_sc)
	mat.set_shader_parameter("wetness_strength", 0.22)
	return mat


func _preload_prop_scenes() -> void:
	_scene_sakura = _safe_load_scene(PROP_SAKURA_PATH)
	_scene_bush = _safe_load_scene(PROP_BUSH_PATH)
	_scene_planter = _safe_load_scene(PROP_PLANTER_PATH)
	_scene_lantern = _safe_load_scene(PROP_LANTERN_PATH)
	_scene_pavilion = _safe_load_scene(MODEL_PAVILION_PATH)

	_scene_house_red = _safe_load_scene(PIXAR_HOUSE_RED_PATH)
	_scene_house_blue = _safe_load_scene(PIXAR_HOUSE_BLUE_PATH)
	_scene_house_ochre = _safe_load_scene(PIXAR_HOUSE_OCHRE_PATH)
	_scene_house_terracotta = _safe_load_scene(PIXAR_HOUSE_TERRACOTTA_PATH)
	_scene_house_cream_spire = _safe_load_scene(PIXAR_HOUSE_CREAM_SPIRE_PATH)
	_scene_cliff_rock = _safe_load_scene(PIXAR_CLIFF_ROCK_PATH)
	_scene_tree_lush = _safe_load_scene(PIXAR_TREE_LUSH_PATH)
	_scene_boat = _safe_load_scene(PIXAR_BOAT_PATH)


func _init_house_batches() -> void:
	_placed_inner_houses.clear()
	_city_house_batches = {
		"red_gable": [] as Array[Transform3D],
		"blue_balcony": [] as Array[Transform3D],
		"ochre_timber": [] as Array[Transform3D],
		"terracotta_terrace": [] as Array[Transform3D],
		"cream_spire": [] as Array[Transform3D],
	}


func _safe_load_scene(res_path: String) -> PackedScene:
	if not ResourceLoader.exists(res_path):
		return null
	var loaded: Resource = load(res_path)
	if loaded is PackedScene:
		return loaded as PackedScene
	return null


func _safe_load_first_scene(path_primary: String, path_alt: String) -> PackedScene:
	var sc: PackedScene = _safe_load_scene(path_primary)
	if sc != null:
		return sc
	return _safe_load_scene(path_alt)


# ===========================================================================
# 2. 3-TIER ELEVATION HELPERS & SCULPTED UNIFIED VALLEY GROUND
# ===========================================================================

func _smooth01(t: float) -> float:
	var c: float = clampf(t, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)


## Returns the flat terrace/plateau elevation (Y) for placing buildings, plazas & props.
func _get_city_ground_y(x: float, z: float) -> float:
	# Tier 2: Upper Overlook Terrace (Y = 5.6)
	if x >= -24.0 and x <= 24.0 and z >= -198.0 and z <= -170.0:
		return TIER_2_Y
	# Tier 1: North Mid Terrace (Y = 3.2)
	if x >= -66.0 and x <= 66.0 and z >= -158.0 and z <= -52.0:
		return TIER_1_Y
	# Tier 1: West School of Souls Hill Terrace (Y = 3.2)
	if x >= -64.0 and x <= -26.0 and z >= -16.0 and z <= 32.0:
		return TIER_1_Y
	return TIER_0_Y


## Returns the exact continuous walkable surface elevation (Y) including all 3 tiers,
## Bridge of Memory, West School Staircase, Grand North Staircase, Tier 2 Ascent,
## and Imperial Descent Staircase to the Baroque Palace Forecourt.
func _get_city_walk_y(x: float, z: float) -> float:
	# 1. Bridge of Memory (Z in [-43.4, -20.6], |X| <= 5.4)
	if absf(x) <= 5.4:
		var dz_bridge: float = absf(z - CANAL_Z)
		if dz_bridge <= 4.2:
			return BRIDGE_DECK_Y
		if dz_bridge < 11.4:
			var bt: float = clampf((11.4 - dz_bridge) / 7.2, 0.0, 1.0)
			return lerpf(ROAD_TOP_Y, BRIDGE_DECK_Y, bt)

	# 2. West School Staircase Ramp (Z in [3.5, 12.5], X from -14.0 -> -26.0, Y: 0.0 -> 3.2)
	if z >= 3.5 and z <= 12.5 and x <= -14.0 and x >= -26.0:
		var wt: float = clampf((-14.0 - x) / 12.0, 0.0, 1.0)
		return lerpf(ROAD_TOP_Y, TIER_1_Y + ROAD_TOP_Y, wt)

	# 3. Grand North Staircase Ramp (|X| <= 6.2, Z from -43.0 -> -55.0, Y: 0.0 -> 3.2)
	if absf(x) <= 6.2 and z <= -43.0 and z >= -55.0:
		var nt: float = clampf((-43.0 - z) / 12.0, 0.0, 1.0)
		return lerpf(ROAD_TOP_Y, TIER_1_Y + ROAD_TOP_Y, nt)

	# 4. Tier 1 -> Tier 2 Ascent Staircase (|X| <= 7.2, Z from -158.0 -> -170.0, Y: 3.2 -> 5.6)
	if absf(x) <= 7.2 and z <= -158.0 and z >= -170.0:
		var ut: float = clampf((-158.0 - z) / 12.0, 0.0, 1.0)
		return lerpf(TIER_1_Y + ROAD_TOP_Y, TIER_2_Y + ROAD_TOP_Y, ut)

	# 5. Imperial Descent Staircase (|X| <= 7.2, Z from -198.0 -> -212.0, Y: 5.6 -> 0.06)
	if absf(x) <= 7.2 and z <= -198.0 and z >= -212.0:
		var dt: float = clampf((-198.0 - z) / 14.0, 0.0, 1.0)
		return lerpf(TIER_2_Y + ROAD_TOP_Y, 0.06, dt)

	return _get_city_ground_y(x, z) + ROAD_TOP_Y


func _build_unified_ground_and_valley() -> void:
	var ground_root: Node3D = Node3D.new()
	ground_root.name = "UnifiedValleyGround"
	add_child(ground_root)

	# Solid, continuous collision box covering the entire 460x560m valley with top at Y = 0.0
	var ground_body: StaticBody3D = StaticBody3D.new()
	ground_body.name = "ValleyGroundCollision"
	ground_body.position = Vector3(0.0, -1.0, VALLEY_CENTER_Z)
	ground_root.add_child(ground_body)

	var ground_col: CollisionShape3D = CollisionShape3D.new()
	var ground_box: BoxShape3D = BoxShape3D.new()
	ground_box.size = Vector3(VALLEY_WIDTH, 2.0, VALLEY_DEPTH)
	ground_col.shape = ground_box
	ground_body.add_child(ground_col)

	var half_w: float = VALLEY_WIDTH * 0.5
	var z_min: float = VALLEY_CENTER_Z - VALLEY_DEPTH * 0.5 # -380.0
	var z_max: float = VALLEY_CENTER_Z + VALLEY_DEPTH * 0.5 # +180.0
	var canal_z_south: float = CANAL_Z + CANAL_WIDTH * 0.5 # -25.0
	var canal_z_north: float = CANAL_Z - CANAL_WIDTH * 0.5 # -39.0
	var canal_half_len: float = CANAL_LENGTH * 0.5 # 180.0

	# South Valley Meadow (Z from -25 to +180) with carved Lake basin & sculpted West School Hill
	var south_mesh: ArrayMesh = _build_meadow_grid_mesh(
		-half_w, half_w, canal_z_south, z_max, 76, 48, true, false
	)
	var south_inst: MeshInstance3D = MeshInstance3D.new()
	south_inst.name = "MeadowSouthValley"
	south_inst.mesh = south_mesh
	south_inst.material_override = _mat_meadow
	south_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground_root.add_child(south_inst)

	# North Valley Meadow (Z from -380 to -39) with Tier 1 grassy hills & Palace depression (0, -280)
	var north_mesh: ArrayMesh = _build_meadow_grid_mesh(
		-half_w, half_w, z_min, canal_z_north, 76, 64, false, true
	)
	var north_inst: MeshInstance3D = MeshInstance3D.new()
	north_inst.name = "MeadowNorthValley"
	north_inst.mesh = north_mesh
	north_inst.material_override = _mat_meadow
	north_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground_root.add_child(north_inst)

	# West & East Meadow Wings flanking the ends of the 360m canal (|X| from 180 to 230)
	var wing_w: float = half_w - canal_half_len
	if wing_w > 0.5:
		for side in [-1.0, 1.0]:
			var wing_plane: PlaneMesh = PlaneMesh.new()
			wing_plane.size = Vector2(wing_w, CANAL_WIDTH)
			var wing_inst: MeshInstance3D = MeshInstance3D.new()
			wing_inst.name = "MeadowCanalWing_%s" % ("W" if side < 0.0 else "E")
			wing_inst.mesh = wing_plane
			wing_inst.position = Vector3(side * (canal_half_len + wing_w * 0.5), 0.0, CANAL_Z)
			wing_inst.material_override = _mat_meadow
			wing_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			ground_root.add_child(wing_inst)


func _build_meadow_grid_mesh(
	x0: float,
	x1: float,
	z0: float,
	z1: float,
	seg_x: int,
	seg_z: int,
	carve_lake: bool,
	carve_palace: bool = false
) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var dx: float = (x1 - x0) / float(seg_x)
	var dz: float = (z1 - z0) / float(seg_z)

	var verts: PackedVector3Array = PackedVector3Array()
	verts.resize((seg_x + 1) * (seg_z + 1))

	for iz in range(seg_z + 1):
		var vz: float = z0 + float(iz) * dz
		for ix in range(seg_x + 1):
			var vx: float = x0 + float(ix) * dx
			var vy: float = 0.0

			# 1. Sculpted emerald hill underneath West School Terrace (Y = 3.12 flush below 3.2 deck)
			if carve_lake:
				var wx_in: float = _smooth01((-26.0 - vx) / 4.5) * _smooth01((vx + 76.0) / 14.0)
				var wz_in: float = _smooth01((vz + 22.0) / 8.0) * _smooth01((42.0 - vz) / 12.0)
				var west_hill: float = (TIER_1_Y - 0.10) * wx_in * wz_in
				vy = maxf(vy, west_hill)

			# 2. Sculpted emerald terrace rise underneath North Mid Tier (Z in [-158..-52], Y = 3.10)
			if carve_palace:
				var nz_south: float = _smooth01((-52.5 - vz) / 3.8)
				var nz_north: float = _smooth01((vz + 174.0) / 16.0)
				var nx_span: float = _smooth01((78.0 - absf(vx)) / 14.0)
				var north_terrace_hill: float = (TIER_1_Y - 0.10) * nz_south * nz_north * nx_span
				# Keep the Grand Staircase cutout (|x| < 6.8, z > -55.5) clean below the steps
				if absf(vx) < 7.0 and vz > -55.5:
					north_terrace_hill = 0.0
				vy = maxf(vy, north_terrace_hill)

			# 3. Gentle Pixar rolling hills around the outer valley amphitheater flanks
			var flank_x: float = _smooth01((absf(vx) - 68.0) / 38.0)
			var flank_south: float = _smooth01((vz - 64.0) / 36.0)
			var flank_mask: float = maxf(flank_x, flank_south)
			if flank_mask > 0.001:
				var wave: float = 0.55 + 0.30 * sin(vx * 0.045 + vz * 0.032) + 0.15 * cos(vx * 0.09 - vz * 0.06)
				# Stay flat near the Shining Canal channel (Z in [-46, -18])
				var canal_clear: float = _smooth01((absf(vz - CANAL_Z) - 10.0) / 12.0)
				var outer_hill: float = flank_mask * canal_clear * (3.2 + 5.8 * wave)
				vy = maxf(vy, outer_hill)

			# 4. Soft organic meadow undulation ONLY in off-road grassy margins (never on roads/plazas)
			var on_road_or_plaza: bool = (
				(absf(vx) < 16.0 and vz >= -232.0 and vz <= 64.0)
				or (absf(vz - 9.0) < 12.0 and absf(vx) < 58.0)
				or (absf(vz + 78.0) < 12.0 and absf(vx) < 62.0)
				or (absf(vz + 138.0) < 12.0 and absf(vx) < 52.0)
				or (absf(vz - CANAL_Z) < 14.0)
				or (absf(vx) < 28.0 and vz >= -216.0 and vz <= -154.0)
			)
			if not on_road_or_plaza and flank_mask < 0.2:
				var gentle_ripple: float = 0.24 * sin(vx * 0.085) * cos(vz * 0.085)
				vy = maxf(vy, vy + gentle_ripple * 0.5)

			# 5. Carve Lake of Silence basin (54, 12), R = 13.0
			if carve_lake:
				var ldx: float = vx - LAKE_CENTER.x
				var ldz: float = vz - LAKE_CENTER.z
				var ldist: float = sqrt(ldx * ldx + ldz * ldz)
				if ldist < LAKE_RADIUS + 3.0:
					var shore_flat: float = _smooth01((ldist - LAKE_RADIUS) / 3.0)
					vy *= shore_flat
				if ldist < LAKE_RADIUS:
					var t: float = clampf(1.0 - ldist / LAKE_RADIUS, 0.0, 1.0)
					var smooth_t: float = t * t * (3.0 - 2.0 * t)
					vy = -0.95 * smooth_t

			# 6. Carve Baroque Palace hill depression (0, -280), R = 68.0 + flat Forecourt corridor
			if carve_palace:
				var pdx: float = vx
				var pdz: float = vz + 280.0
				var pdist: float = sqrt(pdx * pdx + pdz * pdz)
				if pdist < 78.0:
					var palace_fade: float = _smooth01((pdist - 66.0) / 12.0)
					vy *= palace_fade
				if pdist < 68.0:
					var pt: float = clampf((68.0 - pdist) / 16.0, 0.0, 1.0)
					var smooth_pt: float = pt * pt * (3.0 - 2.0 * pt)
					vy = minf(vy, -1.35 * smooth_pt)

			verts[iz * (seg_x + 1) + ix] = Vector3(vx, vy, vz)

	var stride: int = seg_x + 1
	for iz in range(seg_z):
		for ix in range(seg_x):
			var i00: int = iz * stride + ix
			var i10: int = i00 + 1
			var i01: int = i00 + stride
			var i11: int = i01 + 1

			var v00: Vector3 = verts[i00]
			var v10: Vector3 = verts[i10]
			var v01: Vector3 = verts[i01]
			var v11: Vector3 = verts[i11]

			st.set_color(Color.WHITE)
			st.set_uv(Vector2(float(ix) / float(seg_x), float(iz) / float(seg_z)))
			st.add_vertex(v00)
			st.set_uv(Vector2(float(ix + 1) / float(seg_x), float(iz) / float(seg_z)))
			st.add_vertex(v10)
			st.set_uv(Vector2(float(ix + 1) / float(seg_x), float(iz + 1) / float(seg_z)))
			st.add_vertex(v11)

			st.set_uv(Vector2(float(ix) / float(seg_x), float(iz) / float(seg_z)))
			st.add_vertex(v00)
			st.set_uv(Vector2(float(ix + 1) / float(seg_x), float(iz + 1) / float(seg_z)))
			st.add_vertex(v11)
			st.set_uv(Vector2(float(ix) / float(seg_x), float(iz + 1) / float(seg_z)))
			st.add_vertex(v01)

	st.generate_normals()
	return st.commit()


# ===========================================================================
# 3. ENRICHED PIXAR MOUNTAIN & ROLLING HILLS HORIZON RING
# ===========================================================================

func _build_mountain_horizon_ring() -> void:
	var horizon_root: Node3D = Node3D.new()
	horizon_root.name = "HorizonMountainRing"
	add_child(horizon_root)

	# Inner Ring: lush emerald-azure rolling Pixar valley hills
	var hills_mesh: ArrayMesh = _create_mountain_ring_mesh(
		34,
		206.0,
		256.0,
		24.0,
		42.0,
		46.0,
		Color("#3A8F56"),
		Color("#5BB87A"),
		Color("#96DAB0"),
		101
	)
	var hills_mat: StandardMaterial3D = StandardMaterial3D.new()
	hills_mat.vertex_color_use_as_albedo = true
	hills_mat.roughness = 0.88
	hills_mat.metallic = 0.0

	var hills_inst: MeshInstance3D = MeshInstance3D.new()
	hills_inst.name = "RollingValleyHills"
	hills_inst.mesh = hills_mesh
	hills_inst.material_override = hills_mat
	hills_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	horizon_root.add_child(hills_inst)

	# Outer Ring: luminous azure-lavender sunlit alpine peaks
	var peaks_mesh: ArrayMesh = _create_mountain_ring_mesh(
		40,
		244.0,
		302.0,
		52.0,
		102.0,
		66.0,
		Color("#5C7EC2"),
		Color("#8AAEE6"),
		Color("#E8F2FF"),
		207
	)
	var peaks_mat: StandardMaterial3D = StandardMaterial3D.new()
	peaks_mat.vertex_color_use_as_albedo = true
	peaks_mat.roughness = 0.86
	peaks_mat.metallic = 0.0
	peaks_mat.emission_enabled = true
	peaks_mat.emission = Color("#8EB2EC")
	peaks_mat.emission_energy_multiplier = 0.10

	var peaks_inst: MeshInstance3D = MeshInstance3D.new()
	peaks_inst.name = "DistantAlpinePeaks"
	peaks_inst.mesh = peaks_mesh
	peaks_inst.material_override = peaks_mat
	peaks_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	horizon_root.add_child(peaks_inst)


func _create_mountain_ring_mesh(
	peak_count: int,
	radius_x: float,
	radius_z: float,
	min_height: float,
	max_height: float,
	base_radius: float,
	base_col: Color,
	mid_col: Color,
	crest_col: Color,
	seed_val: int
) -> ArrayMesh:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var sides: int = 7
	for i in range(peak_count):
		var angle: float = (TAU * float(i)) / float(peak_count) + rng.randf_range(-0.04, 0.04)
		var radial_jitter: float = rng.randf_range(0.95, 1.07)
		var cx: float = cos(angle) * radius_x * radial_jitter
		var cz: float = VALLEY_CENTER_Z + sin(angle) * radius_z * radial_jitter
		var h: float = rng.randf_range(min_height, max_height)
		var r_base: float = base_radius * rng.randf_range(0.85, 1.25)
		var r_mid: float = r_base * 0.48
		var h_mid: float = h * 0.56
		var apex_offset: Vector3 = Vector3(rng.randf_range(-6.0, 6.0), h, rng.randf_range(-6.0, 6.0))
		var apex: Vector3 = Vector3(cx, -1.0, cz) + apex_offset

		var ring_base: Array[Vector3] = []
		var ring_mid: Array[Vector3] = []
		var rot_offset: float = rng.randf_range(0.0, TAU)
		for s in range(sides):
			var a: float = rot_offset + (TAU * float(s)) / float(sides)
			var w: float = rng.randf_range(0.84, 1.16)
			ring_base.append(Vector3(cx + cos(a) * r_base * w, -2.0, cz + sin(a) * r_base * w))
			ring_mid.append(Vector3(cx + cos(a + 0.15) * r_mid * w, h_mid, cz + sin(a + 0.15) * r_mid * w))

		for s in range(sides):
			var ns: int = (s + 1) % sides
			var b0: Vector3 = ring_base[s]
			var b1: Vector3 = ring_base[ns]
			var m0: Vector3 = ring_mid[s]
			var m1: Vector3 = ring_mid[ns]

			# Lower slope quad (2 triangles)
			st.set_color(base_col)
			st.add_vertex(b0)
			st.set_color(base_col)
			st.add_vertex(b1)
			st.set_color(mid_col)
			st.add_vertex(m1)

			st.set_color(base_col)
			st.add_vertex(b0)
			st.set_color(mid_col)
			st.add_vertex(m1)
			st.set_color(mid_col)
			st.add_vertex(m0)

			# Upper crest triangle
			st.set_color(mid_col)
			st.add_vertex(m0)
			st.set_color(mid_col)
			st.add_vertex(m1)
			st.set_color(crest_col)
			st.add_vertex(apex)

	st.generate_normals()
	return st.commit()


# ===========================================================================
# 4. SHINING CANAL (Z = -32), EMBANKMENT BALUSTRADES & LAKE OF SILENCE
# ===========================================================================

func _build_canal_and_lake() -> void:
	var water_root: Node3D = Node3D.new()
	water_root.name = "CityWaterways"
	add_child(water_root)

	# --- City Canal (Z = -32.0, length 360m along X, width 14m, water at Y = -0.25) ---
	var canal_bed: MeshInstance3D = MeshInstance3D.new()
	canal_bed.name = "CanalBed"
	var bed_mesh: PlaneMesh = PlaneMesh.new()
	bed_mesh.size = Vector2(CANAL_LENGTH, CANAL_WIDTH + 1.0)
	canal_bed.mesh = bed_mesh
	canal_bed.position = Vector3(0.0, -1.10, CANAL_Z)
	canal_bed.material_override = _mat_canal_bed
	canal_bed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water_root.add_child(canal_bed)

	var canal_water: MeshInstance3D = MeshInstance3D.new()
	canal_water.name = "CanalWater"
	var cw_mesh: PlaneMesh = PlaneMesh.new()
	cw_mesh.size = Vector2(CANAL_LENGTH, CANAL_WIDTH)
	cw_mesh.subdivide_width = 48
	cw_mesh.subdivide_depth = 8
	canal_water.mesh = cw_mesh
	canal_water.position = Vector3(0.0, CANAL_WATER_Y, CANAL_Z)
	canal_water.material_override = _mat_water_canal
	canal_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water_root.add_child(canal_water)

	# Stone quay walls on North (Z = -39) and South (Z = -25) edges of the canal
	var quay_z_positions: Array[float] = [CANAL_Z + CANAL_WIDTH * 0.5, CANAL_Z - CANAL_WIDTH * 0.5]
	var post_xforms: Array[Transform3D] = []
	var cap_xforms: Array[Transform3D] = []

	for idx in range(quay_z_positions.size()):
		var qz: float = quay_z_positions[idx]
		var tag: String = "South" if idx == 0 else "North"
		var seg_len: float = (CANAL_LENGTH * 0.5) - 6.0
		for side in [-1.0, 1.0]:
			var cx: float = side * (6.0 + seg_len * 0.5)
			var wall_inst: MeshInstance3D = MeshInstance3D.new()
			wall_inst.name = "CanalQuayWall_%s_%s" % [tag, "W" if side < 0.0 else "E"]
			var wall_box: BoxMesh = BoxMesh.new()
			wall_box.size = Vector3(seg_len, 1.45, 0.90)
			wall_inst.mesh = wall_box
			wall_inst.position = Vector3(cx, -0.50, qz)
			wall_inst.material_override = _mat_stone_quay
			wall_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			water_root.add_child(wall_inst)

			# Warm coping trim along quay top
			var trim_inst: MeshInstance3D = MeshInstance3D.new()
			trim_inst.name = "CanalQuayTrim_%s_%s" % [tag, "W" if side < 0.0 else "E"]
			var trim_box: BoxMesh = BoxMesh.new()
			trim_box.size = Vector3(seg_len, 0.08, 1.08)
			trim_inst.mesh = trim_box
			trim_inst.position = Vector3(cx, 0.24, qz)
			trim_inst.material_override = _mat_marble_wall
			trim_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			water_root.add_child(trim_inst)

			# Embankment promenade balustrade railing (|X| from 6.5 to 64.0, clear of waterfalls at +/-68)
			var rail_len: float = 57.5
			var rail_cx: float = side * (6.5 + rail_len * 0.5)
			var rail_bar: MeshInstance3D = MeshInstance3D.new()
			rail_bar.name = "CanalBalustradeRail_%s_%s" % [tag, "W" if side < 0.0 else "E"]
			var rail_box: BoxMesh = BoxMesh.new()
			rail_box.size = Vector3(rail_len, 0.12, 0.24)
			rail_bar.mesh = rail_box
			rail_bar.position = Vector3(rail_cx, 1.04, qz)
			rail_bar.material_override = _mat_marble_wall
			rail_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			water_root.add_child(rail_bar)

			# Collect balustrade post transforms for 2-draw-call MultiMesh batching
			var px: float = 7.0
			while px <= 63.5:
				var world_x: float = side * px
				var is_pillar: bool = (int(round(px)) % 12 == 7)
				var post_scale: Vector3 = Vector3(1.55, 1.08, 1.55) if is_pillar else Vector3(1.0, 1.0, 1.0)
				post_xforms.append(Transform3D(Basis.from_scale(post_scale), Vector3(world_x, 0.64, qz)))
				if is_pillar:
					cap_xforms.append(Transform3D(Basis.IDENTITY, Vector3(world_x, 1.18, qz)))
				px += 3.0

	# Batch all ~80 balustrade posts + ~20 golden finial caps into 2 MultiMeshInstance3Ds
	var post_mesh: CylinderMesh = CylinderMesh.new()
	post_mesh.top_radius = 0.10
	post_mesh.bottom_radius = 0.13
	post_mesh.height = 0.78
	post_mesh.radial_segments = 8
	_create_simple_multimesh(water_root, "CanalBalustradePostsMM", post_mesh, _mat_marble_wall, post_xforms)

	var cap_mesh: SphereMesh = SphereMesh.new()
	cap_mesh.radius = 0.16
	cap_mesh.height = 0.28
	cap_mesh.radial_segments = 10
	cap_mesh.rings = 6
	_create_simple_multimesh(water_root, "CanalBalustradeCapsMM", cap_mesh, _mat_gold_trim, cap_xforms)

	# --- Lake of Silence in Quiet Lakes Park (54.0, -0.18, 12.0), radius 13m ---
	var lake_water: MeshInstance3D = MeshInstance3D.new()
	lake_water.name = "LakeOfSilenceWater"
	var lw_mesh: PlaneMesh = PlaneMesh.new()
	lw_mesh.size = Vector2(LAKE_RADIUS * 2.0, LAKE_RADIUS * 2.0)
	lw_mesh.subdivide_width = 24
	lw_mesh.subdivide_depth = 24
	lake_water.mesh = lw_mesh
	lake_water.position = Vector3(LAKE_CENTER.x, LAKE_CENTER.y, LAKE_CENTER.z)
	lake_water.material_override = _mat_water_lake
	lake_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water_root.add_child(lake_water)

	# Stone curb ring framing the Lake of Silence (seated cleanly on Y = 0.0)
	var lake_curb: MeshInstance3D = MeshInstance3D.new()
	lake_curb.name = "LakeOfSilenceCurb"
	var curb_torus: TorusMesh = TorusMesh.new()
	curb_torus.inner_radius = LAKE_RADIUS - 0.55
	curb_torus.outer_radius = LAKE_RADIUS + 0.55
	curb_torus.rings = 48
	curb_torus.ring_segments = 12
	lake_curb.mesh = curb_torus
	lake_curb.position = Vector3(LAKE_CENTER.x, 0.05, LAKE_CENTER.z)
	lake_curb.scale = Vector3(1.0, 0.35, 1.0)
	lake_curb.material_override = _mat_stone_quay
	lake_curb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water_root.add_child(lake_curb)


# ===========================================================================
# 4B. 4 ANIMATED CASCADING WATERFALLS & 6 PAINTED PIXAR BOATS
# ===========================================================================

func _build_waterfalls_and_boats() -> void:
	var fx_root: Node3D = Node3D.new()
	fx_root.name = "WaterfallsAndBoats"
	add_child(fx_root)

	# 4 Broad Cascading Waterfalls plunging into the Shining Canal & Lake of Silence
	# Local +Z of the ribbon mesh pours outward from the cliff; yaw rotates +Z into water.
	var waterfall_specs: Array[Dictionary] = [
		{
			"name": "Waterfall_CanalWest",
			"pos": Vector3(-68.0, 0.0, -32.0),
			"yaw": PI * 0.5, # pours +X into Shining Canal
			"width": 8.6,
			"height": 11.8,
			"arch_out": 2.8,
			"water_y": CANAL_WATER_Y,
		},
		{
			"name": "Waterfall_CanalEast",
			"pos": Vector3(68.0, 0.0, -32.0),
			"yaw": -PI * 0.5, # pours -X into Shining Canal
			"width": 8.6,
			"height": 11.8,
			"arch_out": 2.8,
			"water_y": CANAL_WATER_Y,
		},
		{
			"name": "Waterfall_CanyonUpperWest",
			"pos": Vector3(-82.0, 0.0, -28.0),
			"yaw": PI * 0.38, # pours +X/+Z from higher western canyon cliff
			"width": 7.6,
			"height": 16.5,
			"arch_out": 3.4,
			"water_y": CANAL_WATER_Y,
		},
		{
			"name": "Waterfall_LakeOfSilence",
			"pos": Vector3(67.0, 0.0, 12.0),
			"yaw": -PI * 0.5, # pours -X into Lake of Silence
			"width": 6.4,
			"height": 9.8,
			"arch_out": 2.4,
			"water_y": LAKE_CENTER.y,
		},
	]

	for spec in waterfall_specs:
		_create_cascading_waterfall(
			fx_root,
			String(spec["name"]),
			spec["pos"] as Vector3,
			float(spec["yaw"]),
			float(spec["width"]),
			float(spec["height"]),
			float(spec["arch_out"]),
			float(spec["water_y"])
		)

	# 6 Painted Pixar Boats gently bobbing on the Shining Canal (4) & Lake of Silence (2)
	var boat_specs: Array[Dictionary] = [
		{"name": "PixarBoat_CanalW1", "pos": Vector3(-28.0, CANAL_WATER_Y + 0.04, -30.4), "yaw": 0.14, "phase": 0.0},
		{"name": "PixarBoat_CanalW2", "pos": Vector3(-50.0, CANAL_WATER_Y + 0.04, -33.6), "yaw": -0.10, "phase": 1.3},
		{"name": "PixarBoat_CanalE1", "pos": Vector3(26.0, CANAL_WATER_Y + 0.04, -33.2), "yaw": PI + 0.12, "phase": 2.5},
		{"name": "PixarBoat_CanalE2", "pos": Vector3(48.0, CANAL_WATER_Y + 0.04, -30.2), "yaw": PI - 0.16, "phase": 3.8},
		{"name": "PixarBoat_Lake1", "pos": Vector3(50.5, LAKE_CENTER.y + 0.04, 16.4), "yaw": 0.62, "phase": 4.9},
		{"name": "PixarBoat_Lake2", "pos": Vector3(57.8, LAKE_CENTER.y + 0.04, 8.6), "yaw": -1.18, "phase": 5.7},
	]

	for b_spec in boat_specs:
		_place_animated_boat(
			fx_root,
			String(b_spec["name"]),
			b_spec["pos"] as Vector3,
			float(b_spec["yaw"]),
			float(b_spec["phase"])
		)


func _create_cascading_waterfall(
	parent: Node3D,
	wf_name: String,
	base_pos: Vector3,
	yaw_rad: float,
	width: float,
	height: float,
	arch_out: float,
	water_y: float
) -> void:
	var holder: Node3D = Node3D.new()
	holder.name = wf_name
	holder.position = Vector3(base_pos.x, water_y, base_pos.z)
	holder.rotation.y = yaw_rad
	holder.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(holder)

	# Smoothly curved parabolic waterfall ribbon (UV.y = 0 at top crest, 1 at plunge pool)
	var ribbon_mesh: ArrayMesh = _create_waterfall_ribbon_mesh(width, height, arch_out, 14, 18)
	var ribbon_inst: MeshInstance3D = MeshInstance3D.new()
	ribbon_inst.name = "%s_Ribbon" % wf_name
	ribbon_inst.mesh = ribbon_mesh
	ribbon_inst.material_override = _mat_waterfall
	ribbon_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ribbon_inst.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	holder.add_child(ribbon_inst)

	# Rocky cliff sill behind the top crest so water pours out of natural rock
	var sill: MeshInstance3D = _add_box_part(
		holder,
		Vector3(width + 3.2, height + 0.8, 3.6),
		Vector3(0.0, height * 0.5 - 0.3, -2.0),
		_mat_cliff_rock
	)
	sill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Soft boiling foam splash disc at the plunge foot
	var splash: MeshInstance3D = MeshInstance3D.new()
	splash.name = "%s_PlungeFoam" % wf_name
	var splash_cyl: CylinderMesh = CylinderMesh.new()
	splash_cyl.top_radius = width * 0.56
	splash_cyl.bottom_radius = width * 0.64
	splash_cyl.height = 0.08
	splash_cyl.radial_segments = 20
	splash.mesh = splash_cyl
	splash.position = Vector3(0.0, 0.06, arch_out)
	splash.material_override = _mat_waterfall_foam
	splash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(splash)

	# Soft rising mist spray particles at the foot of the waterfall (60 FPS lightweight)
	var mist: GPUParticles3D = GPUParticles3D.new()
	mist.name = "%s_Mist" % wf_name
	mist.position = Vector3(0.0, 0.55, arch_out + 0.35)
	mist.amount = 16
	mist.lifetime = 2.4
	mist.preprocess = 1.2
	mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mist.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	var pmat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(width * 0.42, 0.25, 0.65)
	pmat.direction = Vector3(0.0, 0.85, 0.45)
	pmat.spread = 32.0
	pmat.gravity = Vector3(0.0, -0.35, 0.0)
	pmat.initial_velocity_min = 0.65
	pmat.initial_velocity_max = 1.35
	pmat.scale_min = 0.65
	pmat.scale_max = 1.45
	mist.process_material = pmat

	var puff_mesh: SphereMesh = SphereMesh.new()
	puff_mesh.radius = 0.52
	puff_mesh.height = 0.82
	puff_mesh.radial_segments = 8
	puff_mesh.rings = 5
	puff_mesh.material = _mat_waterfall_foam
	mist.draw_pass_1 = puff_mesh
	holder.add_child(mist)


func _create_waterfall_ribbon_mesh(
	width: float,
	height: float,
	arch_out: float,
	seg_x: int,
	seg_y: int
) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_w: float = width * 0.5
	var stride: int = seg_x + 1
	var verts: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	verts.resize((seg_x + 1) * (seg_y + 1))
	uvs.resize((seg_x + 1) * (seg_y + 1))

	for iy in range(seg_y + 1):
		var v: float = float(iy) / float(seg_y) # 0 = top crest, 1 = bottom plunge
		# Smooth gravity parabola: starts gently at cliff lip, arcs out and plunges vertically
		var y_pos: float = height * (1.0 - v * v * 0.68 - v * 0.32)
		var z_arc: float = arch_out * sqrt(v)
		for ix in range(seg_x + 1):
			var u: float = float(ix) / float(seg_x)
			var x_pos: float = lerpf(-half_w, half_w, u)
			# Subtle organic horizontal bow
			var bow_z: float = sin(u * PI) * 0.42
			var idx: int = iy * stride + ix
			verts[idx] = Vector3(x_pos, y_pos, z_arc + bow_z)
			uvs[idx] = Vector2(u, v)

	for iy in range(seg_y):
		for ix in range(seg_x):
			var i00: int = iy * stride + ix
			var i10: int = i00 + 1
			var i01: int = i00 + stride
			var i11: int = i01 + 1

			st.set_uv(uvs[i00])
			st.add_vertex(verts[i00])
			st.set_uv(uvs[i10])
			st.add_vertex(verts[i10])
			st.set_uv(uvs[i11])
			st.add_vertex(verts[i11])

			st.set_uv(uvs[i00])
			st.add_vertex(verts[i00])
			st.set_uv(uvs[i11])
			st.add_vertex(verts[i11])
			st.set_uv(uvs[i01])
			st.add_vertex(verts[i01])

	st.generate_normals()
	return st.commit()


func _place_animated_boat(
	parent: Node3D,
	boat_name: String,
	pos: Vector3,
	yaw_rad: float,
	phase: float
) -> void:
	var holder: Node3D = Node3D.new()
	holder.name = boat_name
	holder.position = pos
	holder.rotation.y = yaw_rad
	holder.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(holder)

	var placed_glb: bool = false
	if _scene_boat != null:
		var inst: Node = _scene_boat.instantiate()
		if inst is Node3D:
			var model_node: Node3D = inst as Node3D
			model_node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			_set_shadow_casting_recursive(model_node, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
			holder.add_child(model_node)
			_ground_node_to_zero(model_node)
			model_node.position.y -= 0.14
			placed_glb = true
		else:
			inst.queue_free()

	if not placed_glb:
		# Cozy Pixar painted wooden boat procedural fallback
		var hull: MeshInstance3D = _add_box_part(holder, Vector3(1.25, 0.42, 3.1), Vector3(0.0, 0.12, 0.0), _mat_boat_hull)
		hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var trim: MeshInstance3D = _add_box_part(holder, Vector3(1.36, 0.10, 3.2), Vector3(0.0, 0.34, 0.0), _mat_boat_trim)
		trim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var bench_a: MeshInstance3D = _add_box_part(holder, Vector3(1.08, 0.12, 0.34), Vector3(0.0, 0.26, 0.55), _mat_trunk_wood)
		bench_a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var bench_b: MeshInstance3D = _add_box_part(holder, Vector3(1.08, 0.12, 0.34), Vector3(0.0, 0.26, -0.55), _mat_trunk_wood)
		bench_b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var lantern_orb: MeshInstance3D = MeshInstance3D.new()
		var sp: SphereMesh = SphereMesh.new()
		sp.radius = 0.16
		sp.height = 0.32
		lantern_orb.mesh = sp
		lantern_orb.position = Vector3(0.0, 0.62, 1.38)
		lantern_orb.material_override = _mat_warm_window
		lantern_orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(lantern_orb)

	_boat_floaters.append({
		"node": holder,
		"base_y": pos.y,
		"base_yaw": yaw_rad,
		"phase": phase,
	})


func _set_shadow_casting_recursive(node: Node, mode: GeometryInstance3D.ShadowCastingSetting) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = mode
	for child in node.get_children():
		_set_shadow_casting_recursive(child, mode)


# ===========================================================================
# 4C. 3-LEVEL CITY TOPOGRAPHY: TERRACES, ARCHED RETAINING WALLS & STAIRCASES
#     Tier 0 (Y = 0.0) -> Tier 1 (Y = 3.2) -> Tier 2 (Y = 5.6) -> Palace (0.0)
# ===========================================================================

func _build_three_tier_terraces_and_stairs() -> void:
	var topo_root: Node3D = Node3D.new()
	topo_root.name = "CityThreeTierTopography"
	add_child(topo_root)

	var col_body: StaticBody3D = StaticBody3D.new()
	col_body.name = "CityTerracesCollision"
	topo_root.add_child(col_body)

	# -------------------------------------------------------------------------
	# 1. WEST SCHOOL OF SOULS TERRACE (Tier 1: Y = 3.2, X in [-64..-26], Z in [-16..+32])
	# -------------------------------------------------------------------------
	# Solid walkable floor slab (top strictly at Y = TIER_1_Y)
	_add_terrace_floor_box(col_body, "WestSchoolTerraceCol", Vector3(-45.0, TIER_1_Y, 8.0), Vector3(38.0, TIER_1_Y + 0.6, 48.0))
	var west_deck: MeshInstance3D = _add_box_part(
		topo_root,
		Vector3(38.0, 0.36, 48.0),
		Vector3(-45.0, TIER_1_Y - 0.18, 8.0),
		_mat_terrace_stone
	)
	west_deck.name = "WestSchoolTerraceDeck"
	west_deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Arched stone retaining walls framing West School Terrace (leaving 8.0m stair opening Z in [4..12])
	_add_arched_retaining_wall(topo_root, "WestSchoolWall_EastNorth", Vector3(-26.0, 0.0, -16.0), Vector3(-26.0, 0.0, 4.0), TIER_1_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "WestSchoolWall_EastSouth", Vector3(-26.0, 0.0, 12.0), Vector3(-26.0, 0.0, 32.0), TIER_1_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "WestSchoolWall_South", Vector3(-64.0, 0.0, 32.0), Vector3(-26.0, 0.0, 32.0), TIER_1_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "WestSchoolWall_North", Vector3(-26.0, 0.0, -16.0), Vector3(-64.0, 0.0, -16.0), TIER_1_Y, 1.0)

	# Scenic stone balustrades along West School Terrace drop-offs
	_add_terrace_balustrade(topo_root, "WestSchoolRail_EastNorth", Vector3(-26.2, TIER_1_Y, -15.6), Vector3(-26.2, TIER_1_Y, 3.8))
	_add_terrace_balustrade(topo_root, "WestSchoolRail_EastSouth", Vector3(-26.2, TIER_1_Y, 12.2), Vector3(-26.2, TIER_1_Y, 31.6))
	_add_terrace_balustrade(topo_root, "WestSchoolRail_South", Vector3(-63.5, TIER_1_Y, 31.6), Vector3(-26.2, TIER_1_Y, 31.6))
	_add_terrace_balustrade(topo_root, "WestSchoolRail_North", Vector3(-63.5, TIER_1_Y, -15.6), Vector3(-26.2, TIER_1_Y, -15.6))

	# West School Stone Staircase Ramp: Z = 8.0, width 8.0m, X = -14.0 (Y=0.0) -> X = -26.0 (Y=3.2)
	_build_stone_staircase_ramp(
		topo_root,
		"Staircase_WestSchool",
		Vector3(-14.0, TIER_0_Y, 8.0),
		Vector3(-26.0, TIER_1_Y, 8.0),
		8.0,
		18
	)

	# -------------------------------------------------------------------------
	# 2. NORTH MID TERRACE (Tier 1: Y = 3.2, X in [-66..+66], Z in [-158..-52])
	# -------------------------------------------------------------------------
	# 3-piece flush walkable floor collision leaving exact notch X in [-6..+6], Z in [-55..-52] for stairs
	_add_terrace_floor_box(col_body, "NorthMidTerraceCol_Main", Vector3(0.0, TIER_1_Y, -106.5), Vector3(132.0, TIER_1_Y + 0.6, 103.0))
	_add_terrace_floor_box(col_body, "NorthMidTerraceCol_SW", Vector3(-36.0, TIER_1_Y, -53.5), Vector3(60.0, TIER_1_Y + 0.6, 3.0))
	_add_terrace_floor_box(col_body, "NorthMidTerraceCol_SE", Vector3(36.0, TIER_1_Y, -53.5), Vector3(60.0, TIER_1_Y + 0.6, 3.0))

	# Visual terrace coping apron along Z = -52 edge (west & east of the Grand North Staircase)
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		var apron: MeshInstance3D = _add_box_part(
			topo_root,
			Vector3(60.0, 0.34, 4.2),
			Vector3(side * 36.0, TIER_1_Y - 0.17, -54.1),
			_mat_terrace_stone
		)
		apron.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Grand Arched Stone Retaining Wall along Z = -52.0 (facing south toward Canal & Bridge)
	_add_arched_retaining_wall(topo_root, "NorthTerraceWall_West", Vector3(-66.0, 0.0, -52.0), Vector3(-6.0, 0.0, -52.0), TIER_1_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "NorthTerraceWall_East", Vector3(6.0, 0.0, -52.0), Vector3(66.0, 0.0, -52.0), TIER_1_Y, 1.0)

	# Balustrades along North Mid Terrace South Rim (Z = -52.2) & North Rim (Z = -157.8)
	_add_terrace_balustrade(topo_root, "NorthTerraceRail_SouthW", Vector3(-62.0, TIER_1_Y, -52.2), Vector3(-6.2, TIER_1_Y, -52.2))
	_add_terrace_balustrade(topo_root, "NorthTerraceRail_SouthE", Vector3(6.2, TIER_1_Y, -52.2), Vector3(62.0, TIER_1_Y, -52.2))
	_add_terrace_balustrade(topo_root, "NorthTerraceRail_NorthW", Vector3(-62.0, TIER_1_Y, -157.8), Vector3(-7.2, TIER_1_Y, -157.8))
	_add_terrace_balustrade(topo_root, "NorthTerraceRail_NorthE", Vector3(7.2, TIER_1_Y, -157.8), Vector3(62.0, TIER_1_Y, -157.8))

	# Grand North Stone Staircase Ramp: X = 0.0, width 12.0m, Z = -43.0 (Y=0.0) -> Z = -55.0 (Y=3.2)
	_build_stone_staircase_ramp(
		topo_root,
		"Staircase_GrandNorth",
		Vector3(0.0, TIER_0_Y, -43.0),
		Vector3(0.0, TIER_1_Y, -55.0),
		12.0,
		20
	)

	# -------------------------------------------------------------------------
	# 3. UPPER OVERLOOK TERRACE (Tier 2: Y = 5.6, X in [-24..+24], Z in [-198..-170])
	#    + Ascent Staircase (Z = -158 -> -170) & Imperial Descent (Z = -198 -> -212)
	# -------------------------------------------------------------------------
	_add_terrace_floor_box(col_body, "UpperOverlookTerraceCol", Vector3(0.0, TIER_2_Y, -184.0), Vector3(48.0, TIER_2_Y + 0.8, 28.0))

	# Solid monumental masonry podium beneath the Upper Overlook Terrace
	var overlook_podium: MeshInstance3D = _add_box_part(
		topo_root,
		Vector3(48.0, TIER_2_Y + 0.4, 28.0),
		Vector3(0.0, (TIER_2_Y - 0.4) * 0.5, -184.0),
		_mat_terrace_stone
	)
	overlook_podium.name = "UpperOverlookPodium"
	overlook_podium.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Paved terrace floor top on Upper Overlook
	var overlook_floor: MeshInstance3D = _add_box_part(
		topo_root,
		Vector3(47.4, 0.08, 27.4),
		Vector3(0.0, TIER_2_Y - 0.01, -184.0),
		_mat_marble_road
	)
	overlook_floor.name = "UpperOverlookPaving"
	overlook_floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Arched stone retaining walls wrapping the Upper Overlook Terrace (South, West, East, North wings)
	_add_arched_retaining_wall(topo_root, "OverlookWall_SouthW", Vector3(-24.0, 0.0, -170.0), Vector3(-7.0, 0.0, -170.0), TIER_2_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "OverlookWall_SouthE", Vector3(7.0, 0.0, -170.0), Vector3(24.0, 0.0, -170.0), TIER_2_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "OverlookWall_West", Vector3(-24.0, 0.0, -198.0), Vector3(-24.0, 0.0, -170.0), TIER_2_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "OverlookWall_East", Vector3(24.0, 0.0, -170.0), Vector3(24.0, 0.0, -198.0), TIER_2_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "OverlookWall_NorthW", Vector3(-7.0, 0.0, -198.0), Vector3(-24.0, 0.0, -198.0), TIER_2_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "OverlookWall_NorthE", Vector3(24.0, 0.0, -198.0), Vector3(7.0, 0.0, -198.0), TIER_2_Y, 1.0)

	# Scenic golden-topped viewing balustrades around Upper Overlook Terrace
	_add_terrace_balustrade(topo_root, "OverlookRail_West", Vector3(-23.7, TIER_2_Y, -197.7), Vector3(-23.7, TIER_2_Y, -170.3))
	_add_terrace_balustrade(topo_root, "OverlookRail_East", Vector3(23.7, TIER_2_Y, -197.7), Vector3(23.7, TIER_2_Y, -170.3))
	_add_terrace_balustrade(topo_root, "OverlookRail_SouthW", Vector3(-23.7, TIER_2_Y, -170.3), Vector3(-7.2, TIER_2_Y, -170.3))
	_add_terrace_balustrade(topo_root, "OverlookRail_SouthE", Vector3(7.2, TIER_2_Y, -170.3), Vector3(23.7, TIER_2_Y, -170.3))
	_add_terrace_balustrade(topo_root, "OverlookRail_NorthW", Vector3(-23.7, TIER_2_Y, -197.7), Vector3(-7.2, TIER_2_Y, -197.7))
	_add_terrace_balustrade(topo_root, "OverlookRail_NorthE", Vector3(7.2, TIER_2_Y, -197.7), Vector3(23.7, TIER_2_Y, -197.7))

	# Tier 1 -> Tier 2 Ascent Stone Staircase (under Triumphal Arch of Knowledge)
	# Z = -158.0 (Y = 3.2) -> Z = -170.0 (Y = 5.6), width 14.0m
	_build_stone_staircase_ramp(
		topo_root,
		"Staircase_Tier2Ascent",
		Vector3(0.0, TIER_1_Y, -158.0),
		Vector3(0.0, TIER_2_Y, -170.0),
		14.0,
		16
	)

	# Imperial Descent Stone Staircase (Tier 2 Overlook -> Baroque Palace Forecourt)
	# Z = -198.0 (Y = 5.6) -> Z = -212.0 (Y = 0.06), width 14.0m
	_build_stone_staircase_ramp(
		topo_root,
		"Staircase_ImperialDescent",
		Vector3(0.0, TIER_2_Y, -198.0),
		Vector3(0.0, 0.06, -212.0),
		14.0,
		26
	)


func _add_terrace_floor_box(
	col_body: StaticBody3D,
	col_name: String,
	top_center: Vector3,
	size: Vector3
) -> void:
	var col: CollisionShape3D = CollisionShape3D.new()
	col.name = col_name
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	col.shape = box
	col.position = Vector3(top_center.x, top_center.y - size.y * 0.5, top_center.z)
	col_body.add_child(col)


func _add_arched_retaining_wall(
	parent: Node3D,
	wall_name: String,
	start_pos: Vector3,
	end_pos: Vector3,
	wall_height: float,
	thickness: float
) -> void:
	var diff: Vector3 = end_pos - start_pos
	var length: float = Vector2(diff.x, diff.z).length()
	if length < 0.5:
		return

	var mid: Vector3 = (start_pos + end_pos) * 0.5
	var yaw: float = atan2(diff.x, diff.z)

	var holder: Node3D = Node3D.new()
	holder.name = wall_name
	holder.position = Vector3(mid.x, 0.0, mid.z)
	holder.rotation.y = yaw
	parent.add_child(holder)

	# Main stone retaining wall body (grounded to Y = -0.6 so zero gaps on slopes)
	var body_h: float = wall_height + 0.6
	var body_mi: MeshInstance3D = _add_box_part(
		holder,
		Vector3(thickness, body_h, length),
		Vector3(0.0, wall_height - body_h * 0.5, 0.0),
		_mat_terrace_stone
	)
	body_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Golden-limestone top cornice coping
	var coping: MeshInstance3D = _add_box_part(
		holder,
		Vector3(thickness + 0.36, 0.24, length + 0.16),
		Vector3(0.0, wall_height - 0.08, 0.0),
		_mat_stone_quay
	)
	coping.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var gold_strip: MeshInstance3D = _add_box_part(
		holder,
		Vector3(thickness + 0.44, 0.08, length + 0.18),
		Vector3(0.0, wall_height + 0.06, 0.0),
		_mat_gold_trim
	)
	gold_strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Decorative blind stone arches & pilasters batched into 2 lightweight MultiMeshes
	var bay_width: float = 5.4
	var bay_count: int = maxi(1, int(floor(length / bay_width)))
	var actual_bay: float = length / float(bay_count)

	var pier_xforms: Array[Transform3D] = []
	var niche_xforms: Array[Transform3D] = []
	for i in range(bay_count + 1):
		var z_p: float = -length * 0.5 + float(i) * actual_bay
		pier_xforms.append(Transform3D(
			Basis.from_scale(Vector3(thickness + 0.42, wall_height + 0.3, 0.72)),
			Vector3(0.0, wall_height * 0.5 - 0.1, z_p)
		))
		if i < bay_count:
			var z_mid: float = z_p + actual_bay * 0.5
			var niche_h: float = maxf(1.2, wall_height - 0.85)
			niche_xforms.append(Transform3D(
				Basis.from_scale(Vector3(thickness + 0.14, niche_h, actual_bay * 0.56)),
				Vector3(0.0, niche_h * 0.5, z_mid)
			))

	var unit_box: BoxMesh = BoxMesh.new()
	unit_box.size = Vector3(1.0, 1.0, 1.0)
	_create_simple_multimesh(holder, "%s_PiersMM" % wall_name, unit_box, _mat_stone_quay, pier_xforms)
	_create_simple_multimesh(holder, "%s_ArchesMM" % wall_name, unit_box, _mat_arch_recess, niche_xforms)


func _add_terrace_balustrade(
	parent: Node3D,
	rail_name: String,
	start_pos: Vector3,
	end_pos: Vector3
) -> void:
	var diff: Vector3 = end_pos - start_pos
	var length: float = Vector2(diff.x, diff.z).length()
	if length < 0.5:
		return

	var mid: Vector3 = (start_pos + end_pos) * 0.5
	var yaw: float = atan2(diff.x, diff.z)

	var holder: Node3D = Node3D.new()
	holder.name = rail_name
	holder.position = mid
	holder.rotation.y = yaw
	parent.add_child(holder)

	# Top marble handrail + subtle golden trim + low stone plinth
	var top_rail: MeshInstance3D = _add_box_part(holder, Vector3(0.28, 0.14, length), Vector3(0.0, 1.02, 0.0), _mat_marble_wall)
	top_rail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var base_plinth: MeshInstance3D = _add_box_part(holder, Vector3(0.32, 0.18, length), Vector3(0.0, 0.09, 0.0), _mat_stone_quay)
	base_plinth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var post_xforms: Array[Transform3D] = []
	var cap_xforms: Array[Transform3D] = []
	var step: float = 2.6
	var count: int = maxi(2, int(floor(length / step)))
	for i in range(count + 1):
		var t: float = float(i) / float(count)
		var pz: float = lerpf(-length * 0.5, length * 0.5, t)
		var is_major: bool = (i == 0 or i == count or i % 4 == 0)
		var sx: float = 1.5 if is_major else 1.0
		post_xforms.append(Transform3D(Basis.from_scale(Vector3(sx, 1.0, sx)), Vector3(0.0, 0.56, pz)))
		if is_major:
			cap_xforms.append(Transform3D(Basis.IDENTITY, Vector3(0.0, 1.20, pz)))

	var post_mesh: CylinderMesh = CylinderMesh.new()
	post_mesh.top_radius = 0.09
	post_mesh.bottom_radius = 0.12
	post_mesh.height = 0.78
	post_mesh.radial_segments = 8
	_create_simple_multimesh(holder, "%s_PostsMM" % rail_name, post_mesh, _mat_marble_wall, post_xforms)

	var cap_mesh: SphereMesh = SphereMesh.new()
	cap_mesh.radius = 0.14
	cap_mesh.height = 0.24
	cap_mesh.radial_segments = 8
	cap_mesh.rings = 5
	_create_simple_multimesh(holder, "%s_CapsMM" % rail_name, cap_mesh, _mat_gold_trim, cap_xforms)


## Builds a grand, silky-smooth walkable Mediterranean stone staircase-ramp between
## start_pos and end_pos with crisp visual steps, golden-trimmed stone parapets,
## exact inclined BoxShape3D walkable collision, and flanking railing colliders.
func _build_stone_staircase_ramp(
	parent: Node3D,
	stair_name: String,
	start_pos: Vector3,
	end_pos: Vector3,
	width: float,
	step_count: int
) -> void:
	var dx: float = end_pos.x - start_pos.x
	var dz: float = end_pos.z - start_pos.z
	var run: float = sqrt(dx * dx + dz * dz)
	if run < 0.5:
		return

	var rise: float = end_pos.y - start_pos.y
	var slope_len: float = sqrt(run * run + rise * rise)
	var pitch: float = atan2(rise, run)
	var yaw: float = atan2(dx, dz)
	var mid: Vector3 = (start_pos + end_pos) * 0.5

	var holder: Node3D = Node3D.new()
	holder.name = stair_name
	holder.position = mid
	holder.rotation.y = yaw
	parent.add_child(holder)

	# 1. Exact smooth walkable inclined BoxShape3D ramp + side railing colliders
	var ramp_body: StaticBody3D = StaticBody3D.new()
	ramp_body.name = "%s_Collision" % stair_name
	holder.add_child(ramp_body)

	var ramp_thick: float = 0.52
	var ramp_col: CollisionShape3D = CollisionShape3D.new()
	var ramp_box: BoxShape3D = BoxShape3D.new()
	ramp_box.size = Vector3(width, ramp_thick, slope_len + 0.55)
	ramp_col.shape = ramp_box
	# Align top surface of rotated box strictly along the line from start_pos to end_pos
	ramp_col.position = Vector3(
		0.0,
		-ramp_thick * 0.5 * cos(pitch),
		ramp_thick * 0.5 * sin(pitch)
	)
	ramp_col.rotation.x = -pitch
	ramp_body.add_child(ramp_col)

	# Side railing colliders so player cannot step off the staircase sides
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		var r_col: CollisionShape3D = CollisionShape3D.new()
		var r_box: BoxShape3D = BoxShape3D.new()
		r_box.size = Vector3(0.65, 2.2, slope_len + 0.6)
		r_col.shape = r_box
		r_col.position = Vector3(side * (width * 0.5 + 0.30), 0.95, 0.0)
		r_col.rotation.x = -pitch
		ramp_body.add_child(r_col)

	# 2. Solid under-structure stone wedge/ramp so zero gaps are ever visible underneath
	var base_ramp: MeshInstance3D = _add_box_part(
		holder,
		Vector3(width + 0.8, 1.4, slope_len + 0.5),
		Vector3(0.0, -0.74 * cos(pitch), 0.74 * sin(pitch)),
		_mat_terrace_stone
	)
	base_ramp.rotation.x = -pitch
	base_ramp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# 3. Crisp visual stone steps batched in 1 MultiMeshInstance3D (60 FPS!)
	var step_xforms: Array[Transform3D] = []
	var tread_depth: float = (run / float(step_count)) + 0.14
	var tread_h: float = absf(rise / float(step_count)) + 0.12
	for s in range(step_count):
		var t_mid: float = (float(s) + 0.5) / float(step_count)
		var sz: float = lerpf(-run * 0.5, run * 0.5, t_mid)
		var sy_top: float = lerpf(-rise * 0.5, rise * 0.5, t_mid) - 0.02
		step_xforms.append(Transform3D(
			Basis.from_scale(Vector3(width, tread_h, tread_depth)),
			Vector3(0.0, sy_top - tread_h * 0.5, sz)
		))
	var step_box: BoxMesh = BoxMesh.new()
	step_box.size = Vector3(1.0, 1.0, 1.0)
	_create_simple_multimesh(holder, "%s_StepsMM" % stair_name, step_box, _mat_marble_road, step_xforms)

	# 4. Flanking sculpted stone parapets, golden handrails & glowing newel posts
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		var sx: float = side * (width * 0.5 + 0.32)

		var wall_mi: MeshInstance3D = _add_box_part(
			holder,
			Vector3(0.56, 1.05, slope_len + 0.4),
			Vector3(sx, 0.42, 0.0),
			_mat_marble_wall
		)
		wall_mi.rotation.x = -pitch
		wall_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var rail_mi: MeshInstance3D = _add_box_part(
			holder,
			Vector3(0.66, 0.14, slope_len + 0.46),
			Vector3(sx, 0.98, 0.0),
			_mat_gold_trim
		)
		rail_mi.rotation.x = -pitch
		rail_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		# Newel pillars with warm glowing lantern orbs at bottom, mid & top
		for end_t in [0.0, 0.5, 1.0]:
			var pz: float = lerpf(-run * 0.5, run * 0.5, float(end_t))
			var py: float = lerpf(-rise * 0.5, rise * 0.5, float(end_t))
			var pillar: MeshInstance3D = _add_box_part(
				holder,
				Vector3(0.76, 1.48, 0.76),
				Vector3(sx, py + 0.68, pz),
				_mat_stone_quay
			)
			pillar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var cap_orb: MeshInstance3D = MeshInstance3D.new()
			var sp: SphereMesh = SphereMesh.new()
			sp.radius = 0.22
			sp.height = 0.44
			sp.radial_segments = 10
			sp.rings = 6
			cap_orb.mesh = sp
			cap_orb.position = Vector3(sx, py + 1.62, pz)
			cap_orb.material_override = _mat_warm_window
			cap_orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(cap_orb)


# ===========================================================================
# 5. ROADS, ORNATE CIRCULAR PLAZAS & WELCOME STONE ARCHES (3-TIER ELEVATED!)
# ===========================================================================

func _build_roads_and_plazas() -> void:
	var net_root: Node3D = Node3D.new()
	net_root.name = "RoadsAndPlazas"
	add_child(net_root)

	# --- TIER 0 (Y = 0.0) ROADS ---
	_add_marble_road(net_root, "MainBoulevard_South", Vector3(0.0, TIER_0_Y, 56.0), Vector3(0.0, TIER_0_Y, -21.0), 10.0)
	_add_marble_road(net_root, "Street_SchoolApproach", Vector3(0.0, TIER_0_Y, 8.0), Vector3(-14.2, TIER_0_Y, 8.0), 8.0)
	_add_marble_road(net_root, "Street_QuietLakesPark", Vector3(0.0, TIER_0_Y, 10.0), Vector3(44.0, TIER_0_Y, 10.0), 7.0)
	_add_marble_road(net_root, "ImperialForecourtRoad", Vector3(0.0, TIER_0_Y, -211.8), Vector3(0.0, TIER_0_Y, -228.0), 14.0)

	# --- TIER 1 (Y = 3.2) ROADS ---
	_add_marble_road(net_root, "Street_SchoolUpper", Vector3(-25.8, TIER_1_Y, 8.0), Vector3(-44.0, TIER_1_Y, 8.0), 8.0)
	_add_marble_road(net_root, "MainBoulevard_North", Vector3(0.0, TIER_1_Y, -54.8), Vector3(0.0, TIER_1_Y, -158.2), 12.0)
	_add_marble_road(net_root, "Street_OrionLibrary", Vector3(0.0, TIER_1_Y, -78.0), Vector3(-48.0, TIER_1_Y, -78.0), 7.5)
	_add_marble_road(net_root, "Street_KronosTower", Vector3(0.0, TIER_1_Y, -78.0), Vector3(48.0, TIER_1_Y, -78.0), 7.5)
	_add_marble_road(net_root, "Street_LanternGarden", Vector3(0.0, TIER_1_Y, -138.0), Vector3(-34.0, TIER_1_Y, -138.0), 7.5)
	_add_marble_road(net_root, "Street_MiraSanctuary", Vector3(0.0, TIER_1_Y, -138.0), Vector3(34.0, TIER_1_Y, -138.0), 7.5)

	# --- TIER 2 (Y = 5.6) UPPER OVERLOOK PROMENADE ---
	_add_marble_road(net_root, "OverlookPromenade", Vector3(0.0, TIER_2_Y, -170.0), Vector3(0.0, TIER_2_Y, -198.0), 14.0)

	# --- CIRCULAR ORNATE PLAZAS ACROSS ALL 3 TIERS ---
	# Tier 0 Plazas
	_add_marble_plaza(net_root, "Plaza_Awakening", Vector3(0.0, TIER_0_Y, 48.0), 12.5)
	_add_marble_plaza(net_root, "Plaza_QuietLakesPier", Vector3(42.0, TIER_0_Y, 10.0), 6.2)
	_add_marble_plaza(net_root, "Plaza_QuietLakesEntry", Vector3(30.0, TIER_0_Y, 10.0), 6.0)
	_add_marble_plaza(net_root, "Plaza_BridgeSouth", Vector3(0.0, TIER_0_Y, -17.0), 7.2)
	_add_marble_plaza(net_root, "Plaza_ImperialForecourt", Vector3(0.0, TIER_0_Y, -217.5), 10.5)

	# Tier 1 Plazas (Y = 3.2)
	_add_marble_plaza(net_root, "Plaza_SchoolOfSouls", Vector3(-38.0, TIER_1_Y, 8.0), 9.5)
	_add_marble_plaza(net_root, "Plaza_AkashicOrrery", Vector3(0.0, TIER_1_Y, -78.0), 10.8)
	_add_marble_plaza(net_root, "Plaza_OrionLibrary", Vector3(-42.0, TIER_1_Y, -78.0), 9.5)
	_add_marble_plaza(net_root, "Plaza_KronosTower", Vector3(42.0, TIER_1_Y, -78.0), 9.5)
	_add_marble_plaza(net_root, "Plaza_LanternGarden", Vector3(-34.0, TIER_1_Y, -138.0), 10.5)
	_add_marble_plaza(net_root, "Plaza_MiraSanctuary", Vector3(30.0, TIER_1_Y, -138.0), 8.5)

	# Tier 2 Plaza (Y = 5.6)
	_add_marble_plaza(net_root, "Plaza_UpperOverlook", Vector3(0.0, TIER_2_Y, -184.0), 11.2)

	# Welcome Stone Arches grounded at their exact tier elevation
	_add_welcome_arch(net_root, "Arch_AwakeningGateway", Vector3(0.0, TIER_0_Y, 34.5), 0.0, 11.2, 6.8)
	_add_welcome_arch(net_root, "Arch_BridgeNorthGate", Vector3(0.0, TIER_1_Y, -56.5), 0.0, 12.6, 7.2)
	_add_welcome_arch(net_root, "Arch_QuietLakesDistrict", Vector3(19.5, TIER_0_Y, 10.0), PI * 0.5, 8.2, 5.8)
	_add_welcome_arch(net_root, "Arch_OrionLibraryDistrict", Vector3(-20.5, TIER_1_Y, -78.0), PI * 0.5, 8.4, 5.8)
	_add_welcome_arch(net_root, "Arch_KronosTowerDistrict", Vector3(20.5, TIER_1_Y, -78.0), PI * 0.5, 8.4, 5.8)


func _add_marble_road(
	parent: Node3D,
	road_name: String,
	start_pos: Vector3,
	end_pos: Vector3,
	width: float
) -> void:
	var diff: Vector3 = end_pos - start_pos
	var length: float = Vector2(diff.x, diff.z).length()
	if length < 0.1:
		return

	var mid: Vector3 = (start_pos + end_pos) * 0.5
	var yaw: float = atan2(diff.x, diff.z)

	var holder: Node3D = Node3D.new()
	holder.name = road_name
	holder.position = Vector3(mid.x, mid.y, mid.z)
	holder.rotation.y = yaw
	parent.add_child(holder)

	# Road slab: height 0.04 -> top face strictly at mid.y + ROAD_TOP_Y
	var slab: MeshInstance3D = MeshInstance3D.new()
	var slab_box: BoxMesh = BoxMesh.new()
	slab_box.size = Vector3(width, 0.04, length)
	slab.mesh = slab_box
	slab.position = Vector3(0.0, ROAD_TOP_Y - 0.02, 0.0)
	slab.material_override = _mat_marble_road
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(slab)

	# Golden edge curbs on both sides (top at mid.y + 0.036, zero Z-fighting)
	for side in [-1.0, 1.0]:
		var curb: MeshInstance3D = MeshInstance3D.new()
		var curb_box: BoxMesh = BoxMesh.new()
		curb_box.size = Vector3(0.28, 0.044, length)
		curb.mesh = curb_box
		curb.position = Vector3(side * (width * 0.5 + 0.12), ROAD_TOP_Y - 0.016, 0.0)
		curb.material_override = _mat_gold_trim
		curb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(curb)


func _add_marble_plaza(
	parent: Node3D,
	plaza_name: String,
	center: Vector3,
	radius: float
) -> void:
	var holder: Node3D = Node3D.new()
	holder.name = plaza_name
	holder.position = center
	parent.add_child(holder)

	# Plaza disc with exact centered planar UVs (0.5, 0.5) -> top face strictly at center.y + PLAZA_TOP_Y
	var disc: MeshInstance3D = MeshInstance3D.new()
	disc.mesh = _create_radial_plaza_disc_mesh(radius, 0.06, 44)
	disc.position = Vector3(0.0, PLAZA_TOP_Y - 0.06, 0.0)
	disc.material_override = _mat_marble_plaza
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(disc)

	# Golden outer rim ring (strictly above plaza edge, no Z-fighting)
	var rim: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = radius - 0.18
	torus.outer_radius = radius + 0.18
	torus.rings = 44
	torus.ring_segments = 10
	rim.mesh = torus
	rim.position = Vector3(0.0, PLAZA_TOP_Y + 0.006, 0.0)
	rim.scale = Vector3(1.0, 0.22, 1.0)
	rim.material_override = _mat_gold_trim
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(rim)


func _add_welcome_arch(
	parent: Node3D,
	arch_name: String,
	center: Vector3,
	yaw_rad: float,
	clear_span: float,
	arch_height: float
) -> void:
	var holder: Node3D = Node3D.new()
	holder.name = arch_name
	holder.position = center
	holder.rotation.y = yaw_rad
	parent.add_child(holder)

	var half_span: float = clear_span * 0.5 + 0.55
	var col_h: float = arch_height - 1.25

	# Twin sculpted stone pillars strictly outside the road width
	var col_body: StaticBody3D = StaticBody3D.new()
	col_body.name = "%s_PillarCollision" % arch_name
	holder.add_child(col_body)

	for side in [-1.0, 1.0]:
		var px: float = side * half_span
		_add_box_part(holder, Vector3(1.25, 0.55, 1.25), Vector3(px, 0.275, 0.0), _mat_stone_quay)
		_add_box_part(holder, Vector3(0.92, col_h, 0.92), Vector3(px, 0.55 + col_h * 0.5, 0.0), _mat_marble_wall)
		_add_box_part(holder, Vector3(1.18, 0.30, 1.18), Vector3(px, 0.55 + col_h + 0.15, 0.0), _mat_gold_trim)

		# Small pillar collider outside the walkable roadway
		var p_col: CollisionShape3D = CollisionShape3D.new()
		var p_box: BoxShape3D = BoxShape3D.new()
		p_box.size = Vector3(1.15, col_h + 0.6, 1.15)
		p_col.shape = p_box
		p_col.position = Vector3(px, (col_h + 0.6) * 0.5, 0.0)
		col_body.add_child(p_col)

	# Upper stone entablature lintel & golden crest cornice
	var total_w: float = clear_span + 2.4
	_add_box_part(holder, Vector3(total_w, 0.78, 1.02), Vector3(0.0, arch_height - 0.18, 0.0), _mat_marble_wall)
	_add_box_part(holder, Vector3(total_w + 0.35, 0.22, 1.24), Vector3(0.0, arch_height + 0.32, 0.0), _mat_gold_trim)

	# Stepped inner arch haunches
	for side in [-1.0, 1.0]:
		var haunch: MeshInstance3D = _add_box_part(
			holder,
			Vector3(1.5, 0.55, 0.88),
			Vector3(side * (half_span - 0.82), arch_height - 0.82, 0.0),
			_mat_terrace_stone
		)
		haunch.rotation.z = side * deg_to_rad(28.0)

	# Central glowing Golden Keystone
	var keystone: MeshInstance3D = _add_box_part(
		holder,
		Vector3(0.96, 1.18, 1.22),
		Vector3(0.0, arch_height - 0.08, 0.0),
		_mat_gold_trim
	)
	keystone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var crest_orb: MeshInstance3D = MeshInstance3D.new()
	var sp: SphereMesh = SphereMesh.new()
	sp.radius = 0.28
	sp.height = 0.56
	crest_orb.mesh = sp
	crest_orb.position = Vector3(0.0, arch_height + 0.76, 0.0)
	crest_orb.material_override = _mat_warm_window
	crest_orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(crest_orb)


# ===========================================================================
# 6. LANDMARKS, BRIDGE OF MEMORY & WALL-TO-WALL INNER QUARTERS (~240+ HOUSES)
# ===========================================================================

func _build_city_buildings() -> void:
	var bld_root: Node3D = Node3D.new()
	bld_root.name = "CityBuildings"
	add_child(bld_root)

	# 1. School of Souls on West School Terrace (-48.0, 3.2, 8.0), facade facing +X
	_place_landmark_building(
		bld_root,
		"SchoolOfSoulsBuilding",
		MODEL_SCHOOL_PATH,
		Vector3(-48.0, TIER_1_Y, 8.0),
		PI * 0.5,
		Vector3(14.0, 9.0, 16.0),
		"school"
	)

	# 2. Orion Library on North Mid Terrace (-54.0, 3.2, -78.0), facade facing +X
	_place_landmark_building(
		bld_root,
		"OrionLibraryBuilding",
		MODEL_LIBRARY_PATH,
		Vector3(-54.0, TIER_1_Y, -78.0),
		PI * 0.5,
		Vector3(15.0, 12.0, 18.0),
		"library"
	)

	# 3. Kronos Clocktower on North Mid Terrace (54.0, 3.2, -78.0), facade facing -X
	_place_landmark_building(
		bld_root,
		"KronosClocktowerBuilding",
		MODEL_CLOCKTOWER_PATH,
		Vector3(54.0, TIER_1_Y, -78.0),
		-PI * 0.5,
		Vector3(10.0, 22.0, 10.0),
		"clocktower"
	)

	# 4. Mira's Sanctuary on North Mid Terrace (40.0, 3.2, -138.0), facade facing -X
	_place_landmark_building(
		bld_root,
		"MiraSanctuaryBuilding",
		MODEL_SANCTUARY_PATH,
		Vector3(40.0, TIER_1_Y, -138.0),
		-PI * 0.5,
		Vector3(11.0, 8.0, 12.0),
		"sanctuary"
	)

	# 5. Four Iconic City Landmarks across all 3 tiers (GLB + rich procedural fallbacks)
	_build_four_iconic_landmarks(bld_root)

	# 6. Bridge of Memory at (0.0, 0.0, -32.0) + walkable ramp/deck collision
	_build_bridge_of_memory(bld_root)

	# 7. Wall-to-wall dense Pixar residential blocks filling all inner quarters
	#    (grounded to their exact tier elevation + 1 shared StaticBody3D)
	_build_wall_to_wall_inner_quarters(bld_root)


func _build_four_iconic_landmarks(parent: Node3D) -> void:
	var lm_root: Node3D = Node3D.new()
	lm_root.name = "IconicCityLandmarks"
	parent.add_child(lm_root)

	# 1. GRAND FOUNTAIN OF AWAKENING at (0.0, 0.0, 48.0) — Tier 0 Awakening Plaza centerpiece
	var f_holder: Node3D = Node3D.new()
	f_holder.name = "Landmark_GrandFountain"
	f_holder.position = Vector3(0.0, TIER_0_Y + PLAZA_TOP_Y, 48.0)
	lm_root.add_child(f_holder)

	var f_scene: PackedScene = _safe_load_first_scene(LANDMARK_FOUNTAIN_PATH, LANDMARK_FOUNTAIN_ALT_PATH)
	if f_scene != null:
		var f_inst: Node = f_scene.instantiate()
		if f_inst is Node3D:
			var f_model: Node3D = f_inst as Node3D
			f_model.scale = Vector3(0.72, 0.72, 0.72)
			f_holder.add_child(f_model)
			_ground_node_to_zero(f_model)
		else:
			f_inst.queue_free()
			_build_procedural_grand_fountain(f_holder)
	else:
		_build_procedural_grand_fountain(f_holder)

	var f_body: StaticBody3D = StaticBody3D.new()
	f_body.name = "GrandFountain_Collision"
	f_holder.add_child(f_body)
	var f_col: CollisionShape3D = CollisionShape3D.new()
	var f_cyl: CylinderShape3D = CylinderShape3D.new()
	f_cyl.radius = 3.05
	f_cyl.height = 4.2
	f_col.shape = f_cyl
	f_col.position = Vector3(0.0, 2.1, 0.0)
	f_body.add_child(f_col)

	# 2. CLOUD BALLOON MOORING TOWER at (66.0, 0.0, 26.0) — East Lake Promontory
	var b_holder: Node3D = Node3D.new()
	b_holder.name = "Landmark_CloudBalloon"
	b_holder.position = Vector3(66.0, TIER_0_Y, 26.0)
	b_holder.rotation.y = -PI * 0.25
	lm_root.add_child(b_holder)

	var b_scene: PackedScene = _safe_load_first_scene(LANDMARK_BALLOON_PATH, LANDMARK_BALLOON_ALT_PATH)
	if b_scene != null:
		var b_inst: Node = b_scene.instantiate()
		if b_inst is Node3D:
			var b_model: Node3D = b_inst as Node3D
			b_holder.add_child(b_model)
			_ground_node_to_zero(b_model)
		else:
			b_inst.queue_free()
			_build_procedural_cloud_balloon(b_holder)
	else:
		_build_procedural_cloud_balloon(b_holder)

	var b_body: StaticBody3D = StaticBody3D.new()
	b_body.name = "CloudBalloon_Collision"
	b_holder.add_child(b_body)
	var b_col: CollisionShape3D = CollisionShape3D.new()
	var b_box: BoxShape3D = BoxShape3D.new()
	b_box.size = Vector3(4.2, 7.0, 4.2)
	b_col.shape = b_box
	b_col.position = Vector3(0.0, 3.5, 0.0)
	b_body.add_child(b_col)

	# 3. GREAT AKASHIC ORRERY (ARMILLARY SPHERE) at (0.0, 3.2, -78.0) — Tier 1 Central Plaza
	var o_holder: Node3D = Node3D.new()
	o_holder.name = "Landmark_AkashicOrrery"
	o_holder.position = Vector3(0.0, TIER_1_Y + PLAZA_TOP_Y, -78.0)
	lm_root.add_child(o_holder)

	_orrery_rotator = null
	var o_scene: PackedScene = _safe_load_first_scene(LANDMARK_ORRERY_PATH, LANDMARK_ORRERY_ALT_PATH)
	if o_scene != null:
		var o_inst: Node = o_scene.instantiate()
		if o_inst is Node3D:
			var o_model: Node3D = o_inst as Node3D
			o_holder.add_child(o_model)
			_ground_node_to_zero(o_model)
		else:
			o_inst.queue_free()
			var o_rot_fb: Node3D = Node3D.new()
			o_rot_fb.name = "AkashicOrrery_Rotator"
			o_rot_fb.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			o_holder.add_child(o_rot_fb)
			_orrery_rotator = o_rot_fb
			_build_procedural_akashic_orrery(o_holder, o_rot_fb)
	else:
		var o_rot_fb2: Node3D = Node3D.new()
		o_rot_fb2.name = "AkashicOrrery_Rotator"
		o_rot_fb2.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		o_holder.add_child(o_rot_fb2)
		_orrery_rotator = o_rot_fb2
		_build_procedural_akashic_orrery(o_holder, o_rot_fb2)

	var o_body: StaticBody3D = StaticBody3D.new()
	o_body.name = "AkashicOrrery_Collision"
	o_holder.add_child(o_body)
	var o_col: CollisionShape3D = CollisionShape3D.new()
	var o_cyl: CylinderShape3D = CylinderShape3D.new()
	o_cyl.radius = 3.45
	o_cyl.height = 3.6
	o_col.shape = o_cyl
	o_col.position = Vector3(0.0, 1.8, 0.0)
	o_body.add_child(o_col)

	# 4. TRIUMPHAL ARCH OF KNOWLEDGE at (0.0, 5.6, -172.0) — Tier 2 Upper Overlook Gateway
	var a_holder: Node3D = Node3D.new()
	a_holder.name = "Landmark_MemoryArch"
	a_holder.position = Vector3(0.0, TIER_2_Y, -172.0)
	lm_root.add_child(a_holder)

	var a_scene: PackedScene = _safe_load_first_scene(LANDMARK_MEMORY_ARCH_PATH, LANDMARK_MEMORY_ARCH_ALT_PATH)
	if a_scene != null:
		var a_inst: Node = a_scene.instantiate()
		if a_inst is Node3D:
			var a_model: Node3D = a_inst as Node3D
			a_holder.add_child(a_model)
			_ground_node_to_zero(a_model)
		else:
			a_inst.queue_free()
			_build_procedural_memory_arch(a_holder)
	else:
		_build_procedural_memory_arch(a_holder)

	# Twin side pillar colliders leaving wide 10.4m walkable central passage under the Arch
	var a_body: StaticBody3D = StaticBody3D.new()
	a_body.name = "MemoryArch_PillarCollision"
	a_holder.add_child(a_body)
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		var p_col: CollisionShape3D = CollisionShape3D.new()
		var p_box: BoxShape3D = BoxShape3D.new()
		p_box.size = Vector3(2.4, 9.0, 2.8)
		p_col.shape = p_box
		p_col.position = Vector3(side * 6.4, 4.5, 0.0)
		a_body.add_child(p_col)


func _build_procedural_grand_fountain(parent: Node3D) -> void:
	# 3-Tier Baroque Fountain of Awakening with luminous turquoise water basins
	_add_cylinder_part(parent, 3.25, 0.55, Vector3(0.0, 0.275, 0.0), _mat_stone_quay)
	var b1_water: MeshInstance3D = _add_cylinder_part(parent, 2.85, 0.14, Vector3(0.0, 0.52, 0.0), _mat_water_lake)
	b1_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_cylinder_part(parent, 1.05, 1.45, Vector3(0.0, 1.15, 0.0), _mat_marble_wall)
	_add_cylinder_part(parent, 2.05, 0.34, Vector3(0.0, 1.88, 0.0), _mat_marble_wall)
	var b2_water: MeshInstance3D = _add_cylinder_part(parent, 1.80, 0.12, Vector3(0.0, 2.06, 0.0), _mat_water_lake)
	b2_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_cylinder_part(parent, 0.62, 1.25, Vector3(0.0, 2.65, 0.0), _mat_marble_wall)
	_add_cylinder_part(parent, 1.15, 0.28, Vector3(0.0, 3.30, 0.0), _mat_gold_trim)
	var top_orb: MeshInstance3D = MeshInstance3D.new()
	var sp: SphereMesh = SphereMesh.new()
	sp.radius = 0.44
	sp.height = 0.88
	top_orb.mesh = sp
	top_orb.position = Vector3(0.0, 4.05, 0.0)
	top_orb.material_override = _mat_warm_window
	top_orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(top_orb)


func _build_procedural_cloud_balloon(parent: Node3D) -> void:
	# Stone Mooring Tower
	_add_cylinder_part(parent, 2.2, 0.8, Vector3(0.0, 0.4, 0.0), _mat_stone_quay)
	_add_cylinder_part(parent, 1.55, 6.4, Vector3(0.0, 3.9, 0.0), _mat_terrace_stone)
	_add_cylinder_part(parent, 2.35, 0.42, Vector3(0.0, 7.25, 0.0), _mat_gold_trim)
	_add_cylinder_part(parent, 0.14, 2.4, Vector3(0.0, 8.5, 0.0), _mat_gold_trim)

	# Floating Cloud Balloon anchored above the tower
	var balloon_root: Node3D = Node3D.new()
	balloon_root.name = "CloudBalloon_Floater"
	balloon_root.position = Vector3(0.0, 12.6, 0.0)
	balloon_root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(balloon_root)
	_balloon_floater = balloon_root
	_balloon_base_y = 12.6

	var env_mi: MeshInstance3D = MeshInstance3D.new()
	var env_sp: SphereMesh = SphereMesh.new()
	env_sp.radius = 3.4
	env_sp.height = 7.4
	env_sp.radial_segments = 18
	env_sp.rings = 10
	env_mi.mesh = env_sp
	env_mi.position = Vector3(0.0, 2.8, 0.0)
	env_mi.material_override = _mat_roof_terracotta
	env_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	balloon_root.add_child(env_mi)

	var band_mi: MeshInstance3D = MeshInstance3D.new()
	var band_torus: TorusMesh = TorusMesh.new()
	band_torus.inner_radius = 3.25
	band_torus.outer_radius = 3.55
	band_torus.rings = 24
	band_torus.ring_segments = 8
	band_mi.mesh = band_torus
	band_mi.position = Vector3(0.0, 2.8, 0.0)
	band_mi.material_override = _mat_gold_trim
	band_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	balloon_root.add_child(band_mi)

	var basket: MeshInstance3D = _add_box_part(balloon_root, Vector3(1.5, 1.1, 1.5), Vector3(0.0, -1.6, 0.0), _mat_bench_wood)
	basket.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_procedural_akashic_orrery(pedestal_parent: Node3D, rot_parent: Node3D) -> void:
	# Static sculpted marble & gold pedestal
	_add_cylinder_part(pedestal_parent, 2.3, 0.55, Vector3(0.0, 0.275, 0.0), _mat_stone_quay)
	_add_cylinder_part(pedestal_parent, 1.65, 1.45, Vector3(0.0, 1.25, 0.0), _mat_marble_wall)
	_add_cylinder_part(pedestal_parent, 1.95, 0.28, Vector3(0.0, 2.08, 0.0), _mat_gold_trim)

	# Rotating golden celestial armillary sphere rings + glowing Akashic sun core
	var ring_radii: Array[float] = [2.65, 2.15, 1.62]
	var ring_tilts: Array[Vector3] = [
		Vector3(deg_to_rad(28.0), 0.0, deg_to_rad(14.0)),
		Vector3(deg_to_rad(-42.0), deg_to_rad(55.0), deg_to_rad(22.0)),
		Vector3(deg_to_rad(68.0), deg_to_rad(-35.0), deg_to_rad(-18.0)),
	]
	for idx in range(ring_radii.size()):
		var r_val: float = ring_radii[idx]
		var r_mi: MeshInstance3D = MeshInstance3D.new()
		var torus: TorusMesh = TorusMesh.new()
		torus.inner_radius = r_val - 0.12
		torus.outer_radius = r_val + 0.12
		torus.rings = 32
		torus.ring_segments = 10
		r_mi.mesh = torus
		r_mi.position = Vector3(0.0, 4.95, 0.0)
		r_mi.rotation = ring_tilts[idx]
		r_mi.material_override = _mat_gold_trim
		r_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rot_parent.add_child(r_mi)

	var core_orb: MeshInstance3D = MeshInstance3D.new()
	var sp: SphereMesh = SphereMesh.new()
	sp.radius = 0.68
	sp.height = 1.36
	core_orb.mesh = sp
	core_orb.position = Vector3(0.0, 4.95, 0.0)
	core_orb.material_override = _mat_warm_window
	core_orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rot_parent.add_child(core_orb)


func _build_procedural_memory_arch(parent: Node3D) -> void:
	# Monumental Baroque Triumphal Arch of Knowledge (10.4m clear central passage)
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		var px: float = side * 6.4
		_add_box_part(parent, Vector3(2.8, 0.9, 3.2), Vector3(px, 0.45, 0.0), _mat_stone_quay)
		_add_box_part(parent, Vector3(2.3, 8.2, 2.5), Vector3(px, 4.9, 0.0), _mat_marble_wall)
		_add_box_part(parent, Vector3(2.7, 0.42, 2.9), Vector3(px, 9.2, 0.0), _mat_gold_trim)
	_add_box_part(parent, Vector3(16.4, 1.65, 2.8), Vector3(0.0, 10.2, 0.0), _mat_marble_wall)
	_add_box_part(parent, Vector3(17.0, 0.36, 3.2), Vector3(0.0, 11.2, 0.0), _mat_gold_trim)
	_add_box_part(parent, Vector3(11.6, 1.4, 2.4), Vector3(0.0, 12.1, 0.0), _mat_terrace_stone)
	var finial: MeshInstance3D = MeshInstance3D.new()
	var sp: SphereMesh = SphereMesh.new()
	sp.radius = 0.55
	sp.height = 1.10
	finial.mesh = sp
	finial.position = Vector3(0.0, 13.35, 0.0)
	finial.material_override = _mat_warm_window
	finial.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(finial)


## Pure mathematical clearance validator guaranteeing ZERO overlaps with avenues,
## cross streets, canal, bridge, 4 staircases, terrace retaining walls, Upper Overlook,
## plazas, welcome arches, Lake of Silence, 8 landmarks, 9 district spawns,
## 3 quest artifacts, 4 waterfalls, and Baroque Palace.
func _is_point_clear_for_house(x: float, z: float, half_r: float) -> bool:
	# 1. Main Boulevard (|x| < 6.8 + half_r, z in [-232, +62])
	if z >= -232.0 and z <= 62.0 and absf(x) < 6.8 + half_r:
		return false

	# 2. Upper Overlook Terrace, Tier 2 Ascent & Imperial Descent (|x| < 26.2 + half_r, z in [-216, -155])
	if z >= -216.0 and z <= -155.0 and absf(x) < 26.2 + half_r:
		return false

	# 3. All 6 cross-street corridors & West School Staircase
	if x >= -54.0 and x <= 52.0 and z >= 2.8 - half_r and z <= 15.2 + half_r:
		return false
	if x >= -60.0 and x <= 60.0 and z >= -83.2 - half_r and z <= -72.8 + half_r:
		return false
	if x >= -48.0 and x <= 48.0 and z >= -143.2 - half_r and z <= -132.8 + half_r:
		return false

	# 4. Shining Canal (z in [-41.5, -22.5]), Bridge & Grand North Staircase / Retaining Wall Z = -52
	if z >= -55.0 - half_r and z <= -22.5 + half_r:
		return false

	# 5. West School Terrace retaining wall perimeter (keep houses clear of drop-off walls!)
	if x >= -29.0 - half_r and x <= -23.0 + half_r and z >= -19.0 - half_r and z <= 35.0 + half_r:
		return false
	if x >= -66.0 and x <= -24.0 and (absf(z - 32.0) < 2.8 + half_r or absf(z + 16.0) < 2.8 + half_r):
		return false

	# 6. Welcome Stone Arches along Main Boulevard
	if absf(x) < 8.0 + half_r and absf(z - 34.5) < 2.2 + half_r:
		return false
	if absf(x) < 8.5 + half_r and absf(z + 56.5) < 2.2 + half_r:
		return false

	# 7. All circular ornate plazas (radius + half_r + 1.0)
	var plazas: Array[Vector3] = [
		Vector3(0.0, 48.0, 12.8),
		Vector3(-38.0, 8.0, 9.8),
		Vector3(42.0, 10.0, 6.2),
		Vector3(30.0, 10.0, 6.0),
		Vector3(0.0, -17.0, 7.2),
		Vector3(0.0, -78.0, 11.4), # Akashic Orrery Central Plaza
		Vector3(-42.0, -78.0, 9.5),
		Vector3(42.0, -78.0, 9.5),
		Vector3(-34.0, -138.0, 10.5),
		Vector3(30.0, -138.0, 8.5),
		Vector3(0.0, -217.5, 10.5),
	]
	for p_info in plazas:
		var pdx: float = x - p_info.x
		var pdz: float = z - p_info.y
		var min_r: float = p_info.z + half_r + 1.0
		if pdx * pdx + pdz * pdz < min_r * min_r:
			return false

	# 8. Lake of Silence (54, 12), R = 15.5 + half_r & Cloud Balloon Mooring Tower (66, 26), R = 8.0
	var ldx: float = x - LAKE_CENTER.x
	var ldz: float = z - LAKE_CENTER.z
	var lake_clear: float = 15.5 + half_r
	if ldx * ldx + ldz * ldz < lake_clear * lake_clear:
		return false
	var cbdx: float = x - 66.0
	var cbdz: float = z - 26.0
	var cb_r: float = 8.0 + half_r
	if cbdx * cbdx + cbdz * cbdz < cb_r * cb_r:
		return false

	# 9. All 4 district landmark buildings (accounting for +/-PI/2 yaw + half_r + 1.2)
	if absf(x + 48.0) < 9.2 + half_r and absf(z - 8.0) < 8.2 + half_r:
		return false
	if absf(x + 54.0) < 10.2 + half_r and absf(z + 78.0) < 8.7 + half_r:
		return false
	if absf(x - 54.0) < 6.2 + half_r and absf(z + 78.0) < 6.2 + half_r:
		return false
	if absf(x - 40.0) < 7.2 + half_r and absf(z + 138.0) < 6.7 + half_r:
		return false

	# 10. All 9 district spawn points (keep >= 4.5 + half_r clear)
	for sp_key in _district_spawns.keys():
		var sp: Vector3 = _district_spawns[sp_key] as Vector3
		var sdx: float = x - sp.x
		var sdz: float = z - sp.z
		var sp_r: float = 4.5 + half_r
		if sdx * sdx + sdz * sdz < sp_r * sp_r:
			return false

	# 11. All 3 Blueprint quest artifacts
	var artifact_pts: Array[Vector2] = [
		Vector2(42.0, 10.0),
		Vector2(-42.0, -78.0),
		Vector2(42.0, -78.0),
	]
	for apt in artifact_pts:
		var adx: float = x - apt.x
		var adz: float = z - apt.y
		var a_r: float = 5.0 + half_r
		if adx * adx + adz * adz < a_r * a_r:
			return false

	# 12. All 4 cascading waterfalls
	var wf_pts: Array[Vector2] = [
		Vector2(-68.0, -32.0),
		Vector2(68.0, -32.0),
		Vector2(-82.0, -28.0),
		Vector2(67.0, 12.0),
	]
	for wpt in wf_pts:
		var wdx: float = x - wpt.x
		var wdz: float = z - wpt.y
		var w_r: float = 8.0 + half_r
		if wdx * wdx + wdz * wdz < w_r * w_r:
			return false

	# 13. Baroque Palace of Earth Mirror (0, -280), R >= 84.0
	var bdx: float = x
	var bdz: float = z + 280.0
	if bdx * bdx + bdz * bdz < 84.0 * 84.0:
		return false

	return true


func _is_near_street_or_plaza(x: float, z: float, max_dist: float) -> bool:
	if absf(x) <= max_dist and z >= -228.0 and z <= 64.0:
		return true
	if absf(z - 9.0) <= max_dist and absf(x) <= 56.0:
		return true
	if absf(z + 78.0) <= max_dist and absf(x) <= 60.0:
		return true
	if absf(z + 138.0) <= max_dist and absf(x) <= 50.0:
		return true
	if absf(z + 32.0) <= max_dist + 7.0 and absf(x) <= 66.0:
		return true
	return false


func _is_far_enough_from_inner_houses(x: float, z: float, min_dist: float) -> bool:
	var min_sq: float = min_dist * min_dist
	for pt in _placed_inner_houses:
		var dx: float = x - pt.x
		var dz: float = z - pt.y
		if dx * dx + dz * dz < min_sq:
			return false
	return true


func _try_add_inner_house(
	x: float,
	z: float,
	face_yaw: float,
	h_kind: String,
	xz_scale: float,
	y_scale: float,
	col_body: StaticBody3D,
	shared_box: BoxShape3D
) -> bool:
	var half_r: float = 3.15 * xz_scale
	if not _is_point_clear_for_house(x, z, half_r):
		return false
	if not _is_far_enough_from_inner_houses(x, z, 5.45):
		return false

	var ground_y: float = _get_city_ground_y(x, z)
	_placed_inner_houses.append(Vector2(x, z))
	var h_arr: Array[Transform3D] = _city_house_batches[h_kind] as Array[Transform3D]
	var xf: Transform3D = Transform3D(
		Basis.from_euler(Vector3(0.0, face_yaw, 0.0)).scaled(Vector3(xz_scale, y_scale, xz_scale)),
		Vector3(x, ground_y, z)
	)
	h_arr.append(xf)

	if col_body != null and _is_near_street_or_plaza(x, z, 18.0):
		var col: CollisionShape3D = CollisionShape3D.new()
		col.shape = shared_box
		col.position = Vector3(x, ground_y + 3.75, z)
		col.rotation.y = face_yaw
		col_body.add_child(col)

	return true


func _build_wall_to_wall_inner_quarters(bld_root: Node3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 202633

	# Single shared StaticBody3D for all street-adjacent inner houses (fast 60 FPS Godot Physics)
	var col_body: StaticBody3D = StaticBody3D.new()
	col_body.name = "CityHousesCollisionBody"
	bld_root.add_child(col_body)

	var shared_house_box: BoxShape3D = BoxShape3D.new()
	shared_house_box.size = Vector3(6.2, 7.5, 6.2)

	var street_kinds: Array[String] = [
		"red_gable",
		"blue_balcony",
		"ochre_timber",
		"terracotta_terrace",
		"red_gable",
		"ochre_timber",
		"blue_balcony",
		"cream_spire",
	]
	var counter: int = 0

	# --- A. STREET-FACING WALL-TO-WALL FACADE ROWS (Boulevard, Canal South Bank) ---
	# 1. Main Boulevard West & East continuous facades (Z from -146 to +54, step 6.1m)
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		var z_cur: float = -146.0
		while z_cur <= 54.0:
			var x_pos: float = side * (10.8 + rng.randf_range(-0.35, 0.45))
			var z_pos: float = z_cur + rng.randf_range(-0.3, 0.3)
			var xz_sc: float = rng.randf_range(0.92, 1.12)
			var y_sc: float = rng.randf_range(0.90, 1.28)
			var yaw: float = (-PI * 0.5 if side > 0.0 else PI * 0.5) + rng.randf_range(-0.09, 0.09)
			var kind: String = street_kinds[counter % street_kinds.size()]
			if _try_add_inner_house(x_pos, z_pos, yaw, kind, xz_sc, y_sc, col_body, shared_house_box):
				counter += 1
			z_cur += 6.1

	# 2. Shining Canal South Waterfront facades (|X| from 16.5 to 62.5, step 6.1m)
	var bz: float = -18.4
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		var x_abs: float = 16.5
		while x_abs <= 62.5:
			var x_pos: float = side * x_abs + rng.randf_range(-0.3, 0.3)
			var z_pos: float = bz + rng.randf_range(-0.3, 0.3)
			var xz_sc: float = rng.randf_range(0.92, 1.12)
			var y_sc: float = rng.randf_range(0.88, 1.28)
			var yaw: float = PI + rng.randf_range(-0.09, 0.09)
			var kind: String = street_kinds[counter % street_kinds.size()]
			if _try_add_inner_house(x_pos, z_pos, yaw, kind, xz_sc, y_sc, col_body, shared_house_box):
				counter += 1
			x_abs += 6.1

	# --- B. DENSE WALL-TO-WALL RESIDENTIAL BLOCKS IN ALL 6 INNER QUARTERS ---
	var quarter_zones: Array[Dictionary] = [
		# 1. South-West Quarter (Awakening Plaza <-> West School Hill Y=3.2 <-> Canal)
		{"x_min": -60.0, "x_max": -16.0, "z_min": -12.5, "z_max": 54.0, "step_x": 6.4, "step_z": 6.4, "spire_mod": 7},
		# 2. South-East Quarter (Awakening Plaza <-> Quiet Lakes Park <-> Canal)
		{"x_min": 16.0, "x_max": 60.0, "z_min": -12.5, "z_max": 54.0, "step_x": 6.4, "step_z": 6.4, "spire_mod": 7},
		# 3. North-West Tier 1 Quarter (Y = 3.2: Retaining Wall <-> Orion Library <-> Lantern Garden)
		{"x_min": -60.0, "x_max": -16.0, "z_min": -152.0, "z_max": -58.0, "step_x": 6.5, "step_z": 6.4, "spire_mod": 6},
		# 4. North-East Tier 1 Quarter (Y = 3.2: Retaining Wall <-> Kronos Tower <-> Mira's Sanctuary)
		{"x_min": 16.0, "x_max": 60.0, "z_min": -152.0, "z_max": -58.0, "step_x": 6.5, "step_z": 6.4, "spire_mod": 6},
		# 5. North-West Pre-Palace Quarter (flanking Upper Overlook Terrace, Z in [-205, -162])
		{"x_min": -60.0, "x_max": -30.0, "z_min": -205.0, "z_max": -162.0, "step_x": 6.6, "step_z": 6.5, "spire_mod": 5},
		# 6. North-East Pre-Palace Quarter (flanking Upper Overlook Terrace, Z in [-205, -162])
		{"x_min": 30.0, "x_max": 60.0, "z_min": -205.0, "z_max": -162.0, "step_x": 6.6, "step_z": 6.5, "spire_mod": 5},
	]

	for q_zone in quarter_zones:
		var q_xmin: float = float(q_zone["x_min"])
		var q_xmax: float = float(q_zone["x_max"])
		var q_zmin: float = float(q_zone["z_min"])
		var q_zmax: float = float(q_zone["z_max"])
		var step_x: float = float(q_zone["step_x"])
		var step_z: float = float(q_zone["step_z"])
		var spire_mod: int = int(q_zone["spire_mod"])

		var row_idx: int = 0
		var z_cur: float = q_zmin
		while z_cur <= q_zmax:
			row_idx += 1
			var col_idx: int = 0
			var row_stagger: float = 1.6 if (row_idx % 2 == 0) else 0.0
			var x_cur: float = q_xmin + row_stagger
			while x_cur <= q_xmax:
				col_idx += 1
				var is_pocket_courtyard: bool = ((row_idx % 3 == 0) and (col_idx % 3 == 2)) or ((row_idx % 5 == 0) and (col_idx % 2 == 0))
				if is_pocket_courtyard:
					x_cur += step_x
					continue

				var x_pos: float = x_cur + rng.randf_range(-0.42, 0.42)
				var z_pos: float = z_cur + rng.randf_range(-0.42, 0.42)
				var xz_sc: float = rng.randf_range(0.90, 1.16)
				var y_sc: float = rng.randf_range(0.85, 1.35)

				var base_yaw: float = 0.0
				if row_idx % 3 == 0:
					base_yaw = -PI * 0.5 if x_pos > 0.0 else PI * 0.5
				elif z_pos > 15.0:
					base_yaw = PI
				else:
					base_yaw = 0.0
				var yaw: float = base_yaw + rng.randf_range(-0.105, 0.105)

				var kind: String = street_kinds[(counter + row_idx + col_idx) % street_kinds.size()]
				if (counter % spire_mod == 0) and absf(x_pos) > 22.0:
					kind = "cream_spire"

				if _try_add_inner_house(x_pos, z_pos, yaw, kind, xz_sc, y_sc, col_body, shared_house_box):
					counter += 1
				x_cur += step_x
			z_cur += step_z


func _place_landmark_building(
	parent: Node3D,
	node_name: String,
	model_path: String,
	pos: Vector3,
	yaw_rad: float,
	col_size: Vector3,
	fallback_kind: String
) -> void:
	var holder: Node3D = Node3D.new()
	holder.name = node_name
	holder.position = pos
	holder.rotation.y = yaw_rad
	parent.add_child(holder)

	var loaded_scene: PackedScene = _safe_load_scene(model_path)
	if loaded_scene != null:
		var inst: Node = loaded_scene.instantiate()
		if inst is Node3D:
			var model_node: Node3D = inst as Node3D
			holder.add_child(model_node)
			_ground_node_to_zero(model_node)
		else:
			inst.queue_free()
			_build_procedural_landmark(holder, fallback_kind)
	else:
		_build_procedural_landmark(holder, fallback_kind)

	# Solid BoxShape3D collision so player cannot walk through the building
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "%s_Collision" % node_name
	body.position = Vector3(0.0, col_size.y * 0.5, 0.0)
	holder.add_child(body)

	var col_shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = col_size
	col_shape.shape = box
	body.add_child(col_shape)


func _build_procedural_landmark(parent: Node3D, kind: String) -> void:
	if kind == "school":
		_add_box_part(parent, Vector3(14.0, 0.6, 16.0), Vector3(0.0, 0.3, 0.0), _mat_stone_quay)
		_add_box_part(parent, Vector3(11.6, 6.2, 13.6), Vector3(0.0, 3.7, 0.0), _mat_marble_wall)
		_add_box_part(parent, Vector3(12.4, 0.5, 14.4), Vector3(0.0, 7.0, 0.0), _mat_gold_trim)
		_add_prism_roof(parent, Vector3(12.8, 3.4, 14.8), Vector3(0.0, 8.95, 0.0), _mat_blue_roof)
		_add_box_part(parent, Vector3(2.8, 3.8, 0.3), Vector3(0.0, 2.5, 6.85), _mat_warm_window)
		for sx in [-3.8, 3.8]:
			_add_box_part(parent, Vector3(1.8, 2.6, 0.25), Vector3(sx, 3.8, 6.85), _mat_warm_window)
			_add_cylinder_part(parent, 0.42, 6.0, Vector3(sx, 3.6, 7.5), _mat_marble_plaza)
	elif kind == "library":
		_add_box_part(parent, Vector3(15.0, 0.7, 17.0), Vector3(0.0, 0.35, 0.0), _mat_stone_quay)
		_add_box_part(parent, Vector3(13.0, 7.6, 15.0), Vector3(0.0, 4.5, 0.0), _mat_marble_wall)
		_add_cylinder_part(parent, 5.4, 2.2, Vector3(0.0, 9.4, 0.0), _mat_marble_plaza)
		var dome: MeshInstance3D = MeshInstance3D.new()
		var sp: SphereMesh = SphereMesh.new()
		sp.radius = 5.2
		sp.height = 6.2
		dome.mesh = sp
		dome.position = Vector3(0.0, 10.6, 0.0)
		dome.material_override = _mat_blue_roof
		parent.add_child(dome)
		_add_cylinder_part(parent, 0.25, 3.2, Vector3(0.0, 14.8, 0.0), _mat_gold_trim)
		_add_box_part(parent, Vector3(3.2, 4.4, 0.3), Vector3(0.0, 2.9, 7.55), _mat_warm_window)
		for sx in [-4.4, 4.4]:
			_add_box_part(parent, Vector3(1.8, 3.8, 0.25), Vector3(sx, 4.4, 7.55), _mat_warm_window)
	elif kind == "clocktower":
		_add_box_part(parent, Vector3(10.0, 1.0, 10.0), Vector3(0.0, 0.5, 0.0), _mat_stone_quay)
		_add_box_part(parent, Vector3(7.6, 15.0, 7.6), Vector3(0.0, 8.5, 0.0), _mat_marble_wall)
		_add_box_part(parent, Vector3(8.4, 0.6, 8.4), Vector3(0.0, 16.2, 0.0), _mat_gold_trim)
		var dial: MeshInstance3D = MeshInstance3D.new()
		var dc: CylinderMesh = CylinderMesh.new()
		dc.top_radius = 2.1
		dc.bottom_radius = 2.1
		dc.height = 0.24
		dial.mesh = dc
		dial.position = Vector3(0.0, 12.8, 3.85)
		dial.rotation.x = PI * 0.5
		dial.material_override = _mat_warm_window
		parent.add_child(dial)
		var spire: MeshInstance3D = MeshInstance3D.new()
		var cone: CylinderMesh = CylinderMesh.new()
		cone.top_radius = 0.15
		cone.bottom_radius = 4.4
		cone.height = 7.5
		cone.radial_segments = 8
		spire.mesh = cone
		spire.position = Vector3(0.0, 20.2, 0.0)
		spire.material_override = _mat_blue_roof
		parent.add_child(spire)
		_add_box_part(parent, Vector3(2.4, 3.6, 0.3), Vector3(0.0, 2.8, 3.85), _mat_warm_window)
	else:
		_add_box_part(parent, Vector3(11.0, 0.5, 11.5), Vector3(0.0, 0.25, 0.0), _mat_stone_quay)
		_add_box_part(parent, Vector3(9.4, 5.2, 9.8), Vector3(0.0, 3.1, 0.0), _mat_marble_wall)
		_add_prism_roof(parent, Vector3(10.6, 3.2, 11.0), Vector3(0.0, 7.3, 0.0), _mat_blue_roof)
		_add_box_part(parent, Vector3(2.4, 3.2, 0.3), Vector3(0.0, 2.1, 4.95), _mat_warm_window)
		for sx in [-3.1, 3.1]:
			_add_box_part(parent, Vector3(1.5, 2.0, 0.25), Vector3(sx, 3.2, 4.95), _mat_warm_window)


func _build_bridge_of_memory(parent: Node3D) -> void:
	var bridge_root: Node3D = Node3D.new()
	bridge_root.name = "BridgeOfMemory"
	bridge_root.position = Vector3(0.0, 0.0, CANAL_Z)
	parent.add_child(bridge_root)

	var bridge_scene: PackedScene = _safe_load_scene(MODEL_BRIDGE_PATH)
	if bridge_scene != null:
		var inst: Node = bridge_scene.instantiate()
		if inst is Node3D:
			var model_node: Node3D = inst as Node3D
			bridge_root.add_child(model_node)
			_ground_node_to_zero(model_node)
		else:
			inst.queue_free()
			_build_procedural_bridge_visuals(bridge_root)
	else:
		_build_procedural_bridge_visuals(bridge_root)

	# Walkable bridge collision: South ramp + Center flat deck + North ramp
	# Canal spans Z in [-7, +7] local. Ramps span Z = +11.2..+4.2 and Z = -4.2..-11.2
	var col_body: StaticBody3D = StaticBody3D.new()
	col_body.name = "BridgeWalkableCollision"
	bridge_root.add_child(col_body)

	var ramp_run: float = 7.2
	var ramp_len: float = sqrt(ramp_run * ramp_run + BRIDGE_DECK_Y * BRIDGE_DECK_Y)
	var ramp_angle: float = atan2(BRIDGE_DECK_Y, ramp_run)

	# Center flat deck (local Z in [-4.2, +4.2], top at Y = BRIDGE_DECK_Y)
	var deck_col: CollisionShape3D = CollisionShape3D.new()
	var deck_box: BoxShape3D = BoxShape3D.new()
	deck_box.size = Vector3(10.0, 0.40, 8.4)
	deck_col.shape = deck_box
	deck_col.position = Vector3(0.0, BRIDGE_DECK_Y - 0.20, 0.0)
	col_body.add_child(deck_col)

	# South ramp (+Z approaches from Awakening Plaza, going up towards -Z)
	var south_col: CollisionShape3D = CollisionShape3D.new()
	var south_box: BoxShape3D = BoxShape3D.new()
	south_box.size = Vector3(10.0, 0.40, ramp_len)
	south_col.shape = south_box
	south_col.position = Vector3(0.0, BRIDGE_DECK_Y * 0.5 - 0.18, 7.6)
	south_col.rotation.x = ramp_angle
	col_body.add_child(south_col)

	# North ramp (-Z descends towards Orion/Kronos, going down towards -Z)
	var north_col: CollisionShape3D = CollisionShape3D.new()
	var north_box: BoxShape3D = BoxShape3D.new()
	north_box.size = Vector3(10.0, 0.40, ramp_len)
	north_col.shape = north_box
	north_col.position = Vector3(0.0, BRIDGE_DECK_Y * 0.5 - 0.18, -7.6)
	north_col.rotation.x = -ramp_angle
	col_body.add_child(north_col)

	# Side railing colliders (X = +/-5.2, height 2.2, length 22.4 along Z)
	for side in [-1.0, 1.0]:
		var rail_col: CollisionShape3D = CollisionShape3D.new()
		rail_col.name = "BridgeRailingCol_%s" % ("W" if side < 0.0 else "E")
		var rail_box: BoxShape3D = BoxShape3D.new()
		rail_box.size = Vector3(0.45, 2.2, 22.4)
		rail_col.shape = rail_box
		rail_col.position = Vector3(side * 5.2, 1.65, 0.0)
		col_body.add_child(rail_col)


func _build_procedural_bridge_visuals(parent: Node3D) -> void:
	var ramp_run: float = 7.2
	var ramp_len: float = sqrt(ramp_run * ramp_run + BRIDGE_DECK_Y * BRIDGE_DECK_Y)
	var ramp_angle: float = atan2(BRIDGE_DECK_Y, ramp_run)

	_add_box_part(parent, Vector3(10.0, 0.46, 8.4), Vector3(0.0, BRIDGE_DECK_Y - 0.23, 0.0), _mat_marble_plaza)

	var south_slab: MeshInstance3D = _add_box_part(
		parent, Vector3(10.0, 0.46, ramp_len), Vector3(0.0, BRIDGE_DECK_Y * 0.5 - 0.21, 7.6), _mat_marble_road
	)
	south_slab.rotation.x = ramp_angle

	var north_slab: MeshInstance3D = _add_box_part(
		parent, Vector3(10.0, 0.46, ramp_len), Vector3(0.0, BRIDGE_DECK_Y * 0.5 - 0.21, -7.6), _mat_marble_road
	)
	north_slab.rotation.x = -ramp_angle

	for pz in [-4.5, 4.5]:
		_add_box_part(parent, Vector3(10.4, 2.2, 1.4), Vector3(0.0, -0.05, pz), _mat_stone_quay)

	for side in [-1.0, 1.0]:
		var bx: float = side * 4.85
		_add_box_part(parent, Vector3(0.36, 1.05, 8.4), Vector3(bx, BRIDGE_DECK_Y + 0.52, 0.0), _mat_marble_wall)
		_add_box_part(parent, Vector3(0.46, 0.14, 8.6), Vector3(bx, BRIDGE_DECK_Y + 1.08, 0.0), _mat_gold_trim)

		var sr: MeshInstance3D = _add_box_part(
			parent, Vector3(0.36, 0.95, ramp_len), Vector3(bx, BRIDGE_DECK_Y * 0.5 + 0.45, 7.6), _mat_marble_wall
		)
		sr.rotation.x = ramp_angle

		var nr: MeshInstance3D = _add_box_part(
			parent, Vector3(0.36, 0.95, ramp_len), Vector3(bx, BRIDGE_DECK_Y * 0.5 + 0.45, -7.6), _mat_marble_wall
		)
		nr.rotation.x = -ramp_angle

		for pz in [-10.8, -4.0, 4.0, 10.8]:
			var py: float = BRIDGE_DECK_Y if absf(pz) < 5.0 else 0.05
			_add_box_part(parent, Vector3(0.62, 1.55, 0.62), Vector3(bx, py + 0.77, pz), _mat_marble_plaza)
			var orb: MeshInstance3D = MeshInstance3D.new()
			var sp: SphereMesh = SphereMesh.new()
			sp.radius = 0.24
			sp.height = 0.48
			orb.mesh = sp
			orb.position = Vector3(bx, py + 1.75, pz)
			orb.material_override = _mat_warm_window
			orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(orb)


func _get_pixar_house_scene(kind: String) -> PackedScene:
	if kind == "red_gable":
		return _scene_house_red
	if kind == "blue_balcony":
		return _scene_house_blue
	if kind == "ochre_timber":
		return _scene_house_ochre
	if kind == "terracotta_terrace":
		return _scene_house_terracotta
	if kind == "cream_spire":
		return _scene_house_cream_spire
	return _scene_pavilion


func _place_pixar_street_house(
	parent: Node3D,
	node_name: String,
	pos: Vector3,
	yaw_rad: float,
	kind: String
) -> void:
	var holder: Node3D = Node3D.new()
	holder.name = node_name
	holder.position = Vector3(pos.x, 0.0, pos.z)
	holder.rotation.y = yaw_rad
	parent.add_child(holder)

	var scene: PackedScene = _get_pixar_house_scene(kind)
	if scene == null:
		scene = _scene_pavilion

	var placed: bool = false
	if scene != null:
		var inst: Node = scene.instantiate()
		if inst is Node3D:
			var model_node: Node3D = inst as Node3D
			holder.add_child(model_node)
			_ground_node_to_zero(model_node)
			placed = true
		else:
			inst.queue_free()

	if not placed:
		_build_procedural_pixar_house(holder, kind)

	# Clean BoxShape3D collision (guaranteed >= 1.5m clear of roads & plazas)
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "%s_Collision" % node_name
	var col_h: float = 6.4 if kind == "cream_spire" else 5.2
	var col_w: float = 5.6 if kind == "cream_spire" else 6.2
	body.position = Vector3(0.0, col_h * 0.5, 0.0)
	holder.add_child(body)

	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(col_w, col_h, col_w)
	col.shape = box
	body.add_child(col)


func _build_procedural_pixar_house(parent: Node3D, kind: String) -> void:
	var wall_mat: Material = _mat_wall_cream
	var roof_mat: Material = _mat_roof_red
	if kind == "blue_balcony":
		wall_mat = _mat_wall_cream
		roof_mat = _mat_blue_roof
	elif kind == "ochre_timber":
		wall_mat = _mat_wall_ochre
		roof_mat = _mat_roof_ochre
	elif kind == "terracotta_terrace":
		wall_mat = _mat_wall_peach
		roof_mat = _mat_roof_terracotta
	elif kind == "cream_spire":
		wall_mat = _mat_wall_cream
		roof_mat = _mat_blue_roof
	elif kind == "pavilion":
		wall_mat = _mat_marble_wall
		roof_mat = _mat_blue_roof

	_add_box_part(parent, Vector3(6.2, 0.42, 6.2), Vector3(0.0, 0.21, 0.0), _mat_stone_quay)
	if kind == "cream_spire":
		_add_cylinder_part(parent, 2.55, 6.4, Vector3(0.0, 3.62, 0.0), wall_mat)
		_add_cylinder_part(parent, 2.85, 0.28, Vector3(0.0, 6.95, 0.0), _mat_gold_trim)
		var cone_inst: MeshInstance3D = MeshInstance3D.new()
		var cone: CylinderMesh = CylinderMesh.new()
		cone.top_radius = 0.08
		cone.bottom_radius = 2.95
		cone.height = 4.6
		cone.radial_segments = 10
		cone_inst.mesh = cone
		cone_inst.position = Vector3(0.0, 9.35, 0.0)
		cone_inst.material_override = roof_mat
		parent.add_child(cone_inst)
		_add_box_part(parent, Vector3(1.1, 1.6, 0.2), Vector3(0.0, 4.6, 2.55), _mat_warm_window)
	else:
		_add_box_part(parent, Vector3(5.6, 4.2, 5.6), Vector3(0.0, 2.52, 0.0), wall_mat)
		_add_box_part(parent, Vector3(6.0, 0.24, 6.0), Vector3(0.0, 4.74, 0.0), _mat_gold_trim)
		_add_prism_roof(parent, Vector3(6.3, 2.4, 6.3), Vector3(0.0, 6.06, 0.0), roof_mat)
		_add_box_part(parent, Vector3(1.3, 2.1, 0.22), Vector3(0.0, 1.48, 2.85), _mat_warm_window)
		for sx in [-1.65, 1.65]:
			_add_box_part(parent, Vector3(0.95, 1.25, 0.18), Vector3(sx, 3.1, 2.85), _mat_warm_window)


# ===========================================================================
# 7. MULTI-TIER "ENDLESS CITY" ON CLIFFS & TERRACES (5 Unified House MultiMeshes)
#    5 Cascading Amphitheater Tiers: Y = 3.5, 9.0, 15.5, 23.0, 31.0 (step 6.8m!)
#    ~340+ Terraced Houses/Spires + ~240+ Inner Quarter Houses = ~580+ Houses in 5 MMs!
# ===========================================================================

func _build_terraced_endless_city() -> void:
	var tier_root: Node3D = Node3D.new()
	tier_root.name = "EndlessTerracedCity"
	add_child(tier_root)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 202611

	var cliff_xforms: Array[Transform3D] = []
	var wall_xforms: Array[Transform3D] = []
	var pier_xforms: Array[Transform3D] = []
	var tree_green_xforms: Array[Transform3D] = []
	var tree_gold_xforms: Array[Transform3D] = []
	var tree_sakura_xforms: Array[Transform3D] = []

	var tier_heights: Array[float] = [3.5, 9.0, 15.5, 23.0, 31.0]
	var tier_x_bases: Array[float] = [73.0, 91.0, 110.0, 130.0, 151.0]
	var tier_z_south: Array[float] = [76.0, 91.0, 106.0, 121.0, 136.0]
	var lower_kinds: Array[String] = ["red_gable", "blue_balcony", "ochre_timber", "terracotta_terrace"]
	var upper_kinds: Array[String] = ["cream_spire", "red_gable", "blue_balcony", "terracotta_terrace", "cream_spire", "ochre_timber"]
	var crown_kinds: Array[String] = ["cream_spire", "cream_spire", "blue_balcony", "cream_spire", "red_gable"]

	# --- A. WEST & EAST AMPHITHEATER SLOPES (5 Ultra-Dense Cascading Tiers, step 6.8m on near tiers) ---
	var west_east_steps: Array[float] = [6.8, 7.2, 9.0, 11.4, 13.8]
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		for t_idx in range(5):
			var ty: float = tier_heights[t_idx]
			var bx: float = tier_x_bases[t_idx]
			var z_min: float = -176.0 - float(t_idx) * 3.5
			var z_max: float = 64.0 + float(t_idx) * 7.5
			var z_step: float = west_east_steps[t_idx]

			var z_cur: float = z_min
			var slot_idx: int = 0
			while z_cur <= z_max:
				slot_idx += 1
				# Leave clean canyon river channel around Canal (Z in [-44, -20]) for Tiers 0 & 1
				if t_idx <= 1 and z_cur > -44.0 and z_cur < -20.0:
					z_cur += z_step
					continue

				# Gentle outward sweep in the north so Baroque Palace (0, -280) stays framed & clear
				var north_flare: float = 0.0
				if z_cur < -135.0:
					north_flare = (-135.0 - z_cur) * 0.28

				# Gentle outward curve around Lake of Silence on East Tier 0
				var lake_flare: float = 0.0
				if side > 0.0 and t_idx == 0 and z_cur > -6.0 and z_cur < 30.0:
					lake_flare = 7.0

				var x_pos: float = side * (bx + north_flare + lake_flare + rng.randf_range(-1.4, 1.4))
				var z_pos: float = z_cur + rng.randf_range(-0.55, 0.55)

				# Safety check: keep clear of Baroque Palace hill (0, -280), R >= 86m
				var pdx: float = x_pos
				var pdz: float = z_pos + 280.0
				if sqrt(pdx * pdx + pdz * pdz) < 86.0:
					z_cur += z_step
					continue

				# Safety check: keep clear of Lake of Silence (54, 12), R >= 17.5m
				var ldx: float = x_pos - LAKE_CENTER.x
				var ldz: float = z_pos - LAKE_CENTER.z
				if sqrt(ldx * ldx + ldz * ldz) < 17.5:
					z_cur += z_step
					continue

				# Continuous retaining wall slab every 2 slots (bottom at Y = -1.5, top strictly at Y = ty!)
				var wall_h: float = ty + 1.5
				if slot_idx % 2 == 1:
					var wall_yaw: float = PI * 0.5
					wall_xforms.append(Transform3D(
						Basis.from_euler(Vector3(0.0, wall_yaw, 0.0)).scaled(Vector3(z_step * 2.25, wall_h, 9.2)),
						Vector3(x_pos, wall_h * 0.5 - 1.5, z_pos)
					))
					if slot_idx % 4 == 1:
						pier_xforms.append(Transform3D(
							Basis.from_euler(Vector3(0.0, 0.0, 0.0)).scaled(Vector3(1.8, wall_h + 0.3, 1.8)),
							Vector3(x_pos - side * 4.4, wall_h * 0.5 - 1.35, z_pos + z_step * 0.8)
						))

				# Sculptural cliff rock grounded at Y = -0.5, flat top strictly flush at Y = ty
				if (slot_idx + t_idx) % 4 == 0:
					var cliff_sy: float = (ty + 0.5) / 6.0
					var rock_sc: Vector3 = Vector3(
						rng.randf_range(1.20, 1.70),
						cliff_sy,
						rng.randf_range(1.20, 1.70)
					)
					cliff_xforms.append(Transform3D(
						Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(rock_sc),
						Vector3(x_pos - side * 4.6, -0.5, z_pos + rng.randf_range(-2.0, 2.0))
					))

				# Wall-to-wall terrace house/spire facing inward toward the sunlit valley
				var h_kind: String = ""
				if t_idx == 4:
					h_kind = crown_kinds[(slot_idx + t_idx) % crown_kinds.size()]
				elif t_idx >= 2:
					h_kind = upper_kinds[(slot_idx + t_idx * 2) % upper_kinds.size()]
				else:
					h_kind = lower_kinds[(slot_idx + t_idx) % lower_kinds.size()]

				var face_yaw: float = (-PI * 0.5 if side > 0.0 else PI * 0.5) + rng.randf_range(-0.12, 0.12)
				var h_sc: float = rng.randf_range(0.96, 1.18) + float(t_idx) * 0.07
				var h_sy: float = h_sc * (rng.randf_range(1.20, 1.50) if (t_idx == 4 and h_kind == "cream_spire") else rng.randf_range(0.92, 1.24))
				var h_arr: Array[Transform3D] = _city_house_batches[h_kind] as Array[Transform3D]
				h_arr.append(Transform3D(
					Basis.from_euler(Vector3(0.0, face_yaw, 0.0)).scaled(Vector3(h_sc, h_sy, h_sc)),
					Vector3(x_pos, ty, z_pos)
				))

				# Lush green, golden & sakura Pixar trees tucked between terrace rooflines
				if (slot_idx + t_idx) % 3 == 0:
					var tree_x: float = x_pos - side * rng.randf_range(2.6, 4.0)
					var tree_z: float = z_pos + rng.randf_range(-2.2, 2.2)
					var tree_sc: float = rng.randf_range(0.88, 1.28)
					var tree_xf: Transform3D = Transform3D(
						Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(tree_sc, tree_sc, tree_sc)),
						Vector3(tree_x, ty, tree_z)
					)
					if (slot_idx + t_idx) % 9 == 0:
						tree_sakura_xforms.append(tree_xf)
					elif (slot_idx + t_idx) % 6 == 0:
						tree_gold_xforms.append(tree_xf)
					else:
						tree_green_xforms.append(tree_xf)

				z_cur += z_step

	# --- B. SOUTH AMPHITHEATER SLOPE BEHIND AWAKENING PLAZA (5 Dense Tiers, Z = +76..+136) ---
	var south_steps: Array[float] = [6.8, 7.6, 9.6, 12.0, 14.5]
	for t_idx in range(5):
		var ty: float = tier_heights[t_idx]
		var bz: float = tier_z_south[t_idx]
		var x_span: float = 58.0 + float(t_idx) * 16.0
		var x_step: float = south_steps[t_idx]
		var x_cur: float = -x_span
		var s_idx: int = 0
		while x_cur <= x_span:
			s_idx += 1
			var x_pos: float = x_cur + rng.randf_range(-0.6, 0.6)
			var z_pos: float = bz + rng.randf_range(-1.2, 1.2)

			# Bottom at Y = -1.5, top strictly flush at Y = ty!
			var wall_h: float = ty + 1.5
			if s_idx % 2 == 1:
				wall_xforms.append(Transform3D(
					Basis.from_scale(Vector3(x_step * 2.25, wall_h, 9.0)),
					Vector3(x_pos, wall_h * 0.5 - 1.5, z_pos)
				))

			if (s_idx + t_idx) % 4 == 0:
				var cliff_sy_b: float = (ty + 0.5) / 6.0
				var r_sc: Vector3 = Vector3(rng.randf_range(1.2, 1.6), cliff_sy_b, rng.randf_range(1.2, 1.6))
				cliff_xforms.append(Transform3D(
					Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(r_sc),
					Vector3(x_pos, -0.5, z_pos - 4.4)
				))

			var h_kind: String = ""
			if t_idx == 4:
				h_kind = crown_kinds[(s_idx + t_idx) % crown_kinds.size()]
			elif t_idx >= 2:
				h_kind = upper_kinds[(s_idx + t_idx) % upper_kinds.size()]
			else:
				h_kind = lower_kinds[(s_idx + t_idx) % lower_kinds.size()]
			var h_sc: float = rng.randf_range(0.98, 1.20) + float(t_idx) * 0.07
			var h_sy: float = h_sc * (rng.randf_range(1.20, 1.48) if (t_idx == 4 and h_kind == "cream_spire") else rng.randf_range(0.92, 1.22))
			var h_arr: Array[Transform3D] = _city_house_batches[h_kind] as Array[Transform3D]
			h_arr.append(Transform3D(
				Basis.from_euler(Vector3(0.0, PI + rng.randf_range(-0.14, 0.14), 0.0)).scaled(Vector3(h_sc, h_sy, h_sc)),
				Vector3(x_pos, ty, z_pos)
			))

			if s_idx % 3 == 0:
				var tr_sc: float = rng.randf_range(0.90, 1.28)
				var tr_xf: Transform3D = Transform3D(
					Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(tr_sc, tr_sc, tr_sc)),
					Vector3(x_pos + 3.2, ty, z_pos - 3.2)
				)
				if s_idx % 6 == 0:
					tree_gold_xforms.append(tr_xf)
				else:
					tree_green_xforms.append(tr_xf)

			x_cur += x_step

	# --- C. DISTANT RIVERFRONT QUARTERS ALONG CANAL TOWARD HORIZON (X = +/-88..+/-158, step 9.0m) ---
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		for bank_val in [-1.0, 1.0]:
			var bank: float = float(bank_val) # -1 = North bank (Z = -48.5), +1 = South bank (Z = -15.5)
			var z_base: float = -48.5 if bank < 0.0 else -15.5
			var d_idx: int = 0
			var x_abs: float = 88.0
			while x_abs <= 158.0:
				d_idx += 1
				var x_pos: float = side * x_abs
				var t_prog: float = (x_abs - 88.0) / 70.0
				var ty: float = 3.5 + t_prog * 14.0
				var z_pos: float = z_base + bank * t_prog * 7.5

				# Retaining wall supporting the riverfront terrace (top strictly at Y = ty)
				var wall_h_c: float = ty + 1.5
				if d_idx % 2 == 1:
					wall_xforms.append(Transform3D(
						Basis.from_scale(Vector3(19.0, wall_h_c, 9.0)),
						Vector3(x_pos + side * 2.5, wall_h_c * 0.5 - 1.5, z_pos)
					))

				# Grounded cliff rock at river edge (bottom Y = -0.5, top strictly at Y = ty)
				if d_idx % 3 == 1:
					var cliff_sy_c: float = (ty + 0.5) / 6.0
					cliff_xforms.append(Transform3D(
						Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(1.5, cliff_sy_c, 1.4)),
						Vector3(x_pos, -0.5, z_pos - bank * 3.4)
					))

				var h_kind: String = "cream_spire" if (d_idx >= 6 or d_idx % 4 == 0) else lower_kinds[d_idx % lower_kinds.size()]
				var face_yaw: float = 0.0 if bank < 0.0 else PI
				var h_sc: float = 1.06 + t_prog * 0.28
				var h_arr: Array[Transform3D] = _city_house_batches[h_kind] as Array[Transform3D]
				h_arr.append(Transform3D(
					Basis.from_euler(Vector3(0.0, face_yaw + rng.randf_range(-0.10, 0.10), 0.0)).scaled(Vector3(h_sc, h_sc, h_sc)),
					Vector3(x_pos, ty, z_pos)
				))

				if d_idx % 3 == 0:
					var t_xf: Transform3D = Transform3D(
						Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(1.10, 1.10, 1.10)),
						Vector3(x_pos + side * 3.2, ty, z_pos + bank * 2.8)
					)
					if d_idx % 6 == 0:
						tree_gold_xforms.append(t_xf)
					else:
						tree_green_xforms.append(t_xf)

				x_abs += 9.0

	# --- D. VALLEY-FLOOR LUSH GREEN & GOLDEN TREES (Grounded to real 3-tier heights!) ---
	var valley_tree_spots: Array[Dictionary] = [
		{"pos": Vector3(-28.0, 0.0, 42.0), "gold": false, "sc": 1.12},
		{"pos": Vector3(28.0, 0.0, 42.0), "gold": true, "sc": 1.08},
		{"pos": Vector3(-30.0, 0.0, 56.0), "gold": true, "sc": 1.16},
		{"pos": Vector3(30.0, 0.0, 56.0), "gold": false, "sc": 1.14},
		{"pos": Vector3(46.0, 0.0, 26.0), "gold": false, "sc": 1.14},
		{"pos": Vector3(62.0, 0.0, -3.0), "gold": false, "sc": 1.12},
		{"pos": Vector3(-36.0, 0.0, -2.0), "gold": true, "sc": 1.08},
		{"pos": Vector3(-42.0, 0.0, -64.0), "gold": false, "sc": 1.08},
		{"pos": Vector3(42.0, 0.0, -64.0), "gold": true, "sc": 1.08},
		{"pos": Vector3(-44.0, 0.0, -126.0), "gold": true, "sc": 1.14},
		{"pos": Vector3(-24.0, 0.0, -150.0), "gold": false, "sc": 1.12},
	]
	for vt in valley_tree_spots:
		var vpos: Vector3 = vt["pos"] as Vector3
		if not _is_far_enough_from_inner_houses(vpos.x, vpos.z, 4.2):
			continue
		var vy: float = _get_city_ground_y(vpos.x, vpos.z)
		var vsc: float = float(vt["sc"])
		var vxf: Transform3D = Transform3D(
			Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(vsc, vsc, vsc)),
			Vector3(vpos.x, vy, vpos.z)
		)
		if bool(vt["gold"]):
			tree_gold_xforms.append(vxf)
		else:
			tree_green_xforms.append(vxf)

	# --- E. COMMIT ALL BATCHES TO MultiMeshInstance3D (Ultra-low draw calls, 60 FPS!) ---
	# 1. Terraced retaining walls & piers (2 draw calls, textured via pixar_building_facade.gdshader)
	var wall_mesh: BoxMesh = BoxMesh.new()
	wall_mesh.size = Vector3(1.0, 1.0, 1.0)
	_create_simple_multimesh(tier_root, "TerraceRetainingWallsMM", wall_mesh, _mat_terrace_stone, wall_xforms)

	var pier_mesh: BoxMesh = BoxMesh.new()
	pier_mesh.size = Vector3(1.0, 1.0, 1.0)
	_create_simple_multimesh(tier_root, "TerraceButtressPiersMM", pier_mesh, _mat_stone_quay, pier_xforms)

	# 2. Sculptural cliff rocks (cliff_terrace_rock.glb or procedural rock fallback)
	_spawn_scene_multimesh_batch(
		tier_root,
		"TerraceCliffsMM",
		_scene_cliff_rock,
		cliff_xforms,
		_create_fallback_cliff_parts(),
		null,
		false
	)

	# 3. UNIFIED 5 Colorful Pixar House MultiMeshInstance3Ds with rich procedural stucco/tile facade shader!
	var house_kinds: Array[String] = ["red_gable", "blue_balcony", "ochre_timber", "terracotta_terrace", "cream_spire"]
	for h_kind in house_kinds:
		var xforms: Array[Transform3D] = _city_house_batches[h_kind] as Array[Transform3D]
		var h_scene: PackedScene = _get_pixar_house_scene(h_kind)
		_spawn_scene_multimesh_batch(
			tier_root,
			"CityHouses_%s_MM" % h_kind,
			h_scene,
			xforms,
			_create_fallback_house_parts(h_kind),
			null,
			true
		)

	# 4. Lush Green & Golden-Autumn Pixar Trees + Terrace Sakura Trees
	_spawn_scene_multimesh_batch(
		tier_root,
		"TerraceTreesGreenMM",
		_scene_tree_lush,
		tree_green_xforms,
		_create_fallback_tree_parts(_mat_foliage_green),
		null,
		false
	)
	_spawn_scene_multimesh_batch(
		tier_root,
		"TerraceTreesGoldMM",
		_scene_tree_lush,
		tree_gold_xforms,
		_create_fallback_tree_parts(_mat_foliage_gold),
		_mat_foliage_gold,
		false
	)
	_spawn_scene_multimesh_batch(
		tier_root,
		"TerraceTreesSakuraMM",
		_scene_sakura,
		tree_sakura_xforms,
		_create_fallback_tree_parts(_mat_foliage_sakura),
		null,
		false
	)


# ===========================================================================
# 8. LIVING STREET PROPS & BOTANICAL FLORA (Grounded to exact 3-tier Y!)
# ===========================================================================

func _build_city_props_and_flora() -> void:
	var props_root: Node3D = Node3D.new()
	props_root.name = "CityPropsAndFlora"
	add_child(props_root)

	# Sakura trees along Main Boulevard, Overlook Terrace, Quiet Lakes Park, Lantern Garden, School
	var sakura_spots: Array[Vector3] = [
		Vector3(-12.5, 0.0, 44.0), Vector3(12.5, 0.0, 44.0),
		Vector3(-9.5, 0.0, 17.5), Vector3(9.5, 0.0, 17.5),
		Vector3(-9.5, 0.0, -60.0), Vector3(9.5, 0.0, -60.0),
		Vector3(-9.5, 0.0, -96.0), Vector3(9.5, 0.0, -96.0),
		Vector3(-9.5, 0.0, -124.0), Vector3(9.5, 0.0, -124.0),
		# Upper Overlook Terrace scenic framing sakuras (Tier 2 Y = 5.6)
		Vector3(-18.5, 0.0, -176.0), Vector3(18.5, 0.0, -176.0),
		Vector3(-18.5, 0.0, -192.0), Vector3(18.5, 0.0, -192.0),
		# Baroque Palace Forecourt (Tier 0 Y = 0.0)
		Vector3(-12.5, 0.0, -216.0), Vector3(12.5, 0.0, -216.0),
		# Quiet Lakes Park shoreline trees (outside Lake radius 13m from (54, 12))
		Vector3(36.0, 0.0, 24.0), Vector3(54.0, 0.0, 29.0),
		Vector3(52.0, 0.0, -5.0),
		# Lantern Garden grove (Tier 1 Y = 3.2)
		Vector3(-44.0, 0.0, -128.0), Vector3(-44.0, 0.0, -148.0),
		Vector3(-24.0, 0.0, -149.0), Vector3(-24.0, 0.0, -127.0),
		# School courtyard (Tier 1 Y = 3.2)
		Vector3(-34.0, 0.0, 20.0), Vector3(-34.0, 0.0, -4.0),
	]
	for i in range(sakura_spots.size()):
		var raw_pos: Vector3 = sakura_spots[i]
		if not _is_far_enough_from_inner_houses(raw_pos.x, raw_pos.z, 3.8):
			continue
		var pos: Vector3 = Vector3(raw_pos.x, _get_city_ground_y(raw_pos.x, raw_pos.z), raw_pos.z)
		var yaw: float = float(i) * 1.15
		var sc: float = 0.92 + float(i % 4) * 0.08
		_place_prop_scene(props_root, _scene_sakura, "CitySakura_%02d" % i, pos, yaw, sc, "tree")

	# Lush bushes framing plazas, Mira's Sanctuary, and Park
	var bush_spots: Array[Vector3] = [
		Vector3(-11.0, 0.0, 54.0), Vector3(11.0, 0.0, 54.0),
		Vector3(-30.0, 0.0, 14.0), Vector3(-30.0, 0.0, 2.0),
		Vector3(28.0, 0.0, 16.0), Vector3(28.0, 0.0, 4.0),
		Vector3(-32.0, 0.0, -72.0), Vector3(-32.0, 0.0, -84.0),
		Vector3(32.0, 0.0, -72.0), Vector3(32.0, 0.0, -84.0),
		Vector3(28.0, 0.0, -130.0), Vector3(28.0, 0.0, -146.0),
		Vector3(-26.0, 0.0, -132.0), Vector3(-26.0, 0.0, -144.0),
	]
	for i in range(bush_spots.size()):
		var rb: Vector3 = bush_spots[i]
		if not _is_far_enough_from_inner_houses(rb.x, rb.z, 3.5):
			continue
		var bpos: Vector3 = Vector3(rb.x, _get_city_ground_y(rb.x, rb.z), rb.z)
		_place_prop_scene(props_root, _scene_bush, "CityBush_%02d" % i, bpos, float(i) * 0.9, 1.0, "bush")

	# Baroque Garden Planters flanking entrances and Overlook Terrace
	var planter_spots: Array[Vector3] = [
		Vector3(-6.2, 0.0, 36.0), Vector3(6.2, 0.0, 36.0),
		Vector3(-6.2, 0.0, -14.0), Vector3(6.2, 0.0, -14.0),
		Vector3(-7.4, 0.0, -58.5), Vector3(7.4, 0.0, -58.5),
		Vector3(-8.6, 0.0, -154.0), Vector3(8.6, 0.0, -154.0),
		Vector3(-12.5, 0.0, -184.0), Vector3(12.5, 0.0, -184.0),
		Vector3(-8.4, 0.0, -214.0), Vector3(8.4, 0.0, -214.0),
	]
	for i in range(planter_spots.size()):
		var rp: Vector3 = planter_spots[i]
		var ppos: Vector3 = Vector3(rp.x, _get_city_ground_y(rp.x, rp.z), rp.z)
		_place_prop_scene(props_root, _scene_planter, "CityPlanter_%02d" % i, ppos, 0.0, 1.0, "planter")

	# Stone Lanterns along Main Boulevard, Overlook Terrace, and Lantern Garden
	var lantern_spots: Array[Vector3] = [
		Vector3(-6.4, 0.0, 44.0), Vector3(6.4, 0.0, 44.0),
		Vector3(-6.4, 0.0, 16.0), Vector3(6.4, 0.0, 16.0),
		Vector3(-7.4, 0.0, -68.0), Vector3(7.4, 0.0, -68.0),
		Vector3(-7.4, 0.0, -110.0), Vector3(7.4, 0.0, -110.0),
		Vector3(-12.5, 0.0, -173.0), Vector3(12.5, 0.0, -173.0),
		Vector3(-12.5, 0.0, -195.0), Vector3(12.5, 0.0, -195.0),
		# Lantern Garden ring of stone lanterns (Tier 1 Y = 3.2)
		Vector3(-42.0, 0.0, -138.0), Vector3(-26.0, 0.0, -133.5),
		Vector3(-34.0, 0.0, -130.0), Vector3(-34.0, 0.0, -146.0),
		# Quiet Lakes Park & School
		Vector3(34.0, 0.0, 14.0), Vector3(34.0, 0.0, 6.0),
		Vector3(-30.0, 0.0, 13.0), Vector3(-30.0, 0.0, 3.0),
	]
	for i in range(lantern_spots.size()):
		var rl: Vector3 = lantern_spots[i]
		var lpos: Vector3 = Vector3(rl.x, _get_city_ground_y(rl.x, rl.z), rl.z)
		_place_prop_scene(props_root, _scene_lantern, "CityLantern_%02d" % i, lpos, 0.0, 1.0, "lantern")


func _place_prop_scene(
	parent: Node3D,
	scene: PackedScene,
	node_name: String,
	pos: Vector3,
	yaw_rad: float,
	scale_val: float,
	fallback_kind: String
) -> void:
	var prop: Node3D = null
	if scene != null:
		var inst: Node = scene.instantiate()
		if inst is Node3D:
			prop = inst as Node3D
		else:
			inst.queue_free()

	if prop == null:
		prop = _create_fallback_prop(fallback_kind)

	prop.name = node_name
	prop.position = pos
	prop.rotation.y = yaw_rad
	prop.scale = Vector3(scale_val, scale_val, scale_val)
	parent.add_child(prop)


func _create_fallback_prop(kind: String) -> Node3D:
	var root: Node3D = Node3D.new()
	if kind == "tree":
		_add_cylinder_part(root, 0.28, 3.2, Vector3(0.0, 1.6, 0.0), _mat_trunk_wood)
		var crown: MeshInstance3D = MeshInstance3D.new()
		var sp: SphereMesh = SphereMesh.new()
		sp.radius = 2.1
		sp.height = 3.0
		crown.mesh = sp
		crown.position = Vector3(0.0, 3.8, 0.0)
		crown.material_override = _mat_foliage_sakura
		root.add_child(crown)
	elif kind == "bush":
		var bush: MeshInstance3D = MeshInstance3D.new()
		var sp: SphereMesh = SphereMesh.new()
		sp.radius = 1.05
		sp.height = 1.35
		bush.mesh = sp
		bush.position = Vector3(0.0, 0.55, 0.0)
		bush.material_override = _mat_foliage_green
		root.add_child(bush)
	elif kind == "planter":
		_add_cylinder_part(root, 0.65, 0.85, Vector3(0.0, 0.425, 0.0), _mat_marble_plaza)
		_add_cylinder_part(root, 0.72, 0.12, Vector3(0.0, 0.86, 0.0), _mat_gold_trim)
	else:
		_add_cylinder_part(root, 0.24, 1.6, Vector3(0.0, 0.8, 0.0), _mat_stone_quay)
		_add_box_part(root, Vector3(0.42, 0.45, 0.42), Vector3(0.0, 1.82, 0.0), _mat_warm_window)
		_add_prism_roof(root, Vector3(0.75, 0.35, 0.75), Vector3(0.0, 2.22, 0.0), _mat_stone_quay)
	return root


# ===========================================================================
# 8B. STREET LIFE, OVERHEAD LANTERN GARLANDS & DELICATE GOLDEN STAR-SPARKS
#     (0 floating awnings, 0 floating square blocks!)
# ===========================================================================

func _build_street_life_and_akasha_magic() -> void:
	var street_root: Node3D = Node3D.new()
	street_root.name = "StreetLifeAndAkashaMagic"
	add_child(street_root)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 202688

	# --- 1. Overhead Warm Golden Lantern Garlands (elevated to exact tier Y + 7.2) ---
	var garland_spans: Array[Dictionary] = [
		# Main Boulevard South (Tier 0, Y = 0.0)
		{"a": Vector3(-6.2, TIER_0_Y + 7.2, 27.0), "b": Vector3(6.2, TIER_0_Y + 7.2, 27.0), "sag": 1.05, "count": 8},
		{"a": Vector3(-6.2, TIER_0_Y + 7.1, 17.5), "b": Vector3(6.2, TIER_0_Y + 7.1, 17.5), "sag": 1.00, "count": 8},
		{"a": Vector3(-6.2, TIER_0_Y + 7.2, -2.5), "b": Vector3(6.2, TIER_0_Y + 7.2, -2.5), "sag": 1.05, "count": 8},
		{"a": Vector3(-6.2, TIER_0_Y + 7.1, -10.5), "b": Vector3(6.2, TIER_0_Y + 7.1, -10.5), "sag": 1.00, "count": 8},
		# Main Boulevard North (Tier 1, Y = 3.2)
		{"a": Vector3(-7.2, TIER_1_Y + 7.2, -62.0), "b": Vector3(7.2, TIER_1_Y + 7.2, -62.0), "sag": 1.05, "count": 8},
		{"a": Vector3(-7.2, TIER_1_Y + 7.2, -92.0), "b": Vector3(7.2, TIER_1_Y + 7.2, -92.0), "sag": 1.05, "count": 8},
		{"a": Vector3(-7.2, TIER_1_Y + 7.2, -108.0), "b": Vector3(7.2, TIER_1_Y + 7.2, -108.0), "sag": 1.05, "count": 8},
		{"a": Vector3(-7.2, TIER_1_Y + 7.2, -124.0), "b": Vector3(7.2, TIER_1_Y + 7.2, -124.0), "sag": 1.05, "count": 8},
		# Cross Streets (Park Tier 0, Orion/Kronos Tier 1)
		{"a": Vector3(14.5, TIER_0_Y + 6.8, 5.8), "b": Vector3(14.5, TIER_0_Y + 6.8, 14.2), "sag": 0.78, "count": 7},
		{"a": Vector3(-16.0, TIER_1_Y + 6.9, -82.2), "b": Vector3(-16.0, TIER_1_Y + 6.9, -73.8), "sag": 0.80, "count": 7},
		{"a": Vector3(16.0, TIER_1_Y + 6.9, -82.2), "b": Vector3(16.0, TIER_1_Y + 6.9, -73.8), "sag": 0.80, "count": 7},
		# Shining Canal South Embankment Promenade (Tier 0)
		{"a": Vector3(-34.0, TIER_0_Y + 6.9, -23.5), "b": Vector3(-16.0, TIER_0_Y + 6.9, -23.5), "sag": 0.95, "count": 8},
		{"a": Vector3(16.0, TIER_0_Y + 6.9, -23.5), "b": Vector3(34.0, TIER_0_Y + 6.9, -23.5), "sag": 0.95, "count": 8},
	]

	var lantern_xforms: Array[Transform3D] = []
	var cable_xforms: Array[Transform3D] = []

	for span in garland_spans:
		var pa: Vector3 = span["a"] as Vector3
		var pb: Vector3 = span["b"] as Vector3
		var sag: float = float(span["sag"])
		var cnt: int = int(span["count"])
		var prev_pt: Vector3 = pa
		for k in range(1, cnt + 2):
			var t: float = float(k) / float(cnt + 1)
			var cur_pt: Vector3 = pa.lerp(pb, t)
			cur_pt.y -= sag * 4.0 * t * (1.0 - t)

			var seg_vec: Vector3 = cur_pt - prev_pt
			var seg_len: float = seg_vec.length()
			if seg_len > 0.05:
				var seg_mid: Vector3 = (prev_pt + cur_pt) * 0.5
				var seg_dir: Vector3 = seg_vec / seg_len
				var up_ref: Vector3 = Vector3.UP if absf(seg_dir.y) < 0.95 else Vector3.RIGHT
				var seg_rot: Basis = Basis.looking_at(seg_dir, up_ref)
				cable_xforms.append(Transform3D(seg_rot.scaled(Vector3(0.035, 0.035, seg_len)), seg_mid))

			if k <= cnt:
				var l_sc: float = rng.randf_range(0.88, 1.16)
				lantern_xforms.append(Transform3D(
					Basis.from_scale(Vector3(l_sc, l_sc * 1.15, l_sc)),
					cur_pt + Vector3(0.0, -0.22, 0.0)
				))
			prev_pt = cur_pt

	var garland_sphere: SphereMesh = SphereMesh.new()
	garland_sphere.radius = 0.21
	garland_sphere.height = 0.42
	garland_sphere.radial_segments = 10
	garland_sphere.rings = 6
	_create_simple_multimesh(street_root, "StreetGarlandLanterns", garland_sphere, _mat_garland_lantern, lantern_xforms)

	var cable_box: BoxMesh = BoxMesh.new()
	cable_box.size = Vector3(1.0, 1.0, 1.0)
	_create_simple_multimesh(street_root, "StreetGarlandCables", cable_box, _mat_garland_cable, cable_xforms)

	# --- 2. Delicate Golden Star-Sparks (36 tiny diamonds around Orrery, Fountain & Lantern Garden) ---
	_akasha_sparks_data.clear()
	var spark_hubs: Array[Dictionary] = [
		{"center": Vector3(0.0, TIER_1_Y + 5.8, -78.0), "r_min": 2.4, "r_max": 5.8, "y_span": 3.4, "count": 14}, # Akashic Orrery
		{"center": Vector3(0.0, TIER_0_Y + 4.4, 48.0), "r_min": 2.2, "r_max": 5.2, "y_span": 2.6, "count": 12},  # Grand Fountain
		{"center": Vector3(-34.0, TIER_1_Y + 4.8, -138.0), "r_min": 3.0, "r_max": 7.5, "y_span": 3.2, "count": 10}, # Lantern Garden
	]
	for hub in spark_hubs:
		var hc: Vector3 = hub["center"] as Vector3
		var rmin: float = float(hub["r_min"])
		var rmax: float = float(hub["r_max"])
		var yspan: float = float(hub["y_span"])
		var pcount: int = int(hub["count"])
		for idx in range(pcount):
			_akasha_sparks_data.append({
				"center": hc,
				"radius": rng.randf_range(rmin, rmax),
				"angle0": rng.randf_range(0.0, TAU),
				"ang_speed": rng.randf_range(0.24, 0.52) * (1.0 if (idx % 2 == 0) else -1.0),
				"y_off": rng.randf_range(-yspan * 0.4, yspan * 0.6),
				"bob_amp": rng.randf_range(0.25, 0.60),
				"phase": rng.randf_range(0.0, TAU),
				"scale": rng.randf_range(0.75, 1.25),
			})

	var spark_mesh: ArrayMesh = _create_diamond_mesh(0.055, 0.11)
	_akasha_sparks_mm = MultiMesh.new()
	_akasha_sparks_mm.transform_format = MultiMesh.TRANSFORM_3D
	_akasha_sparks_mm.mesh = spark_mesh
	_akasha_sparks_mm.instance_count = _akasha_sparks_data.size()

	var sparks_mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	sparks_mmi.name = "GoldenAkashaSparks"
	sparks_mmi.multimesh = _akasha_sparks_mm
	sparks_mmi.material_override = _mat_spark_star
	sparks_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sparks_mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	street_root.add_child(sparks_mmi)
	_update_akasha_sparks()

	# --- 3. Grounded Street Benches & Terracotta Flower Pots (0 floating awnings!) ---
	var bench_xforms: Array[Transform3D] = []
	var pot_xforms: Array[Transform3D] = []

	var blvd_zs: Array[float] = [26.0, 20.0, -3.0, -9.0, -61.0, -65.0, -92.0, -106.0, -120.0]
	for b_idx in range(blvd_zs.size()):
		var bz: float = blvd_zs[b_idx]
		var bx_off: float = 6.05 if bz > -30.0 else 6.85
		for side_val in [-1.0, 1.0]:
			var side: float = float(side_val)
			var face_in: float = -PI * 0.5 if side > 0.0 else PI * 0.5
			var gx: float = side * bx_off
			var gy: float = _get_city_ground_y(gx, bz)
			bench_xforms.append(Transform3D(
				Basis.from_euler(Vector3(0.0, face_in, 0.0)),
				Vector3(gx, gy + 0.28, bz)
			))
			pot_xforms.append(Transform3D(
				Basis.IDENTITY,
				Vector3(gx, gy + 0.34, bz + 1.55)
			))

	# Embankment benches & flower pots overlooking the Shining Canal (South bank Tier 0)
	var quay_xs: Array[float] = [-44.0, -30.0, -18.0, 18.0, 30.0, 44.0]
	for q_idx in range(quay_xs.size()):
		var qx: float = quay_xs[q_idx]
		var qz: float = -23.4
		bench_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, PI, 0.0)),
			Vector3(qx, TIER_0_Y + 0.28, qz)
		))
		pot_xforms.append(Transform3D(
			Basis.IDENTITY,
			Vector3(qx + 1.55, TIER_0_Y + 0.34, qz)
		))

	# Upper Overlook Terrace scenic benches (Tier 2, Y = 5.6)
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		for oz in [-179.0, -189.0]:
			var face_in: float = -PI * 0.5 if side > 0.0 else PI * 0.5
			bench_xforms.append(Transform3D(
				Basis.from_euler(Vector3(0.0, face_in, 0.0)),
				Vector3(side * 20.5, TIER_2_Y + 0.28, oz)
			))
			pot_xforms.append(Transform3D(
				Basis.IDENTITY,
				Vector3(side * 20.5, TIER_2_Y + 0.34, oz + 1.6)
			))

	var bench_mesh: BoxMesh = BoxMesh.new()
	bench_mesh.size = Vector3(1.95, 0.56, 0.62)
	_create_simple_multimesh(street_root, "StreetBenchesMM", bench_mesh, _mat_bench_wood, bench_xforms)

	var pot_mesh: CylinderMesh = CylinderMesh.new()
	pot_mesh.top_radius = 0.40
	pot_mesh.bottom_radius = 0.28
	pot_mesh.height = 0.68
	pot_mesh.radial_segments = 10
	_create_simple_multimesh(street_root, "StreetFlowerPotsMM", pot_mesh, _mat_flower_pot, pot_xforms)


func _update_akasha_sparks() -> void:
	if _akasha_sparks_mm == null or _akasha_sparks_data.is_empty():
		return
	var count: int = _akasha_sparks_data.size()
	for i in range(count):
		var p: Dictionary = _akasha_sparks_data[i]
		var hc: Vector3 = p["center"] as Vector3
		var r: float = float(p["radius"])
		var ang: float = float(p["angle0"]) + _anim_time * float(p["ang_speed"])
		var ph: float = float(p["phase"])
		var sc: float = float(p["scale"]) * (0.78 + 0.28 * sin(_anim_time * 3.4 + ph))

		var px: float = hc.x + cos(ang) * r
		var pz: float = hc.z + sin(ang) * r
		var py: float = hc.y + float(p["y_off"]) + sin(_anim_time * 1.85 + ph) * float(p["bob_amp"])

		var rot_b: Basis = Basis.from_euler(Vector3(0.0, _anim_time * 1.4 + ph, 0.0)).scaled(Vector3(sc, sc, sc))
		_akasha_sparks_mm.set_instance_transform(i, Transform3D(rot_b, Vector3(px, py, pz)))


# ===========================================================================
# 8C. LIVING SOULS CROWD (136 Luminous Souls traversing all 3 City Tiers!)
#     Rendered in just 2 ultra-light MultiMeshInstance3Ds (60 FPS on Metal!)
# ===========================================================================

func _build_living_souls_crowd() -> void:
	var souls_root: Node3D = Node3D.new()
	souls_root.name = "LivingSoulsCrowd"
	add_child(souls_root)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 202699

	_walking_souls.clear()
	_sky_souls.clear()

	# Luminous Akasha soul palette (turquoise, golden, pearl-white, lavender, peach-rose)
	var soul_palette: Array[Color] = [
		Color(0.54, 1.32, 1.44, 0.90),
		Color(1.44, 1.22, 0.58, 0.90),
		Color(1.30, 1.35, 1.42, 0.90),
		Color(1.18, 0.90, 1.46, 0.90),
		Color(1.44, 0.96, 1.08, 0.90),
	]

	# --- A. 80 STROLLING SOULS climbing & descending all 3 tiers & 4 staircases ---
	var walk_routes: Array[Dictionary] = [
		# Main Boulevard South -> Bridge of Memory -> Grand North Staircase -> Orrery Approach
		{"type": "line", "a": Vector3(-3.0, 0.0, 36.0), "b": Vector3(-3.0, 0.0, -68.0), "count": 10},
		{"type": "line", "a": Vector3(3.0, 0.0, -68.0), "b": Vector3(3.0, 0.0, 36.0), "count": 10},
		# Main Boulevard North (Tier 1) -> Tier 2 Ascent -> Overlook -> Imperial Descent -> Palace Forecourt
		{"type": "line", "a": Vector3(-3.8, 0.0, -88.0), "b": Vector3(-3.8, 0.0, -218.0), "count": 8},
		{"type": "line", "a": Vector3(3.8, 0.0, -218.0), "b": Vector3(3.8, 0.0, -88.0), "count": 8},
		# Cross Streets: West School Staircase (Y 0 -> 3.2), Quiet Lakes, Orion, Kronos, Lantern, Mira
		{"type": "line", "a": Vector3(-4.0, 0.0, 7.6), "b": Vector3(-35.0, 0.0, 7.6), "count": 5},
		{"type": "line", "a": Vector3(4.0, 0.0, 10.6), "b": Vector3(34.0, 0.0, 10.6), "count": 5},
		{"type": "line", "a": Vector3(-8.5, 0.0, -77.2), "b": Vector3(-40.0, 0.0, -77.2), "count": 5},
		{"type": "line", "a": Vector3(8.5, 0.0, -78.8), "b": Vector3(40.0, 0.0, -78.8), "count": 5},
		{"type": "line", "a": Vector3(-4.0, 0.0, -138.0), "b": Vector3(-32.0, 0.0, -138.0), "count": 4},
		{"type": "line", "a": Vector3(4.0, 0.0, -138.0), "b": Vector3(28.0, 0.0, -138.0), "count": 4},
		# Circular strolls around Grand Fountain, Akashic Orrery, Orion, Kronos & Lantern Garden
		{"type": "circle", "center": Vector3(0.0, 0.0, 48.0), "radius": 8.8, "count": 5},
		{"type": "circle", "center": Vector3(0.0, 0.0, -78.0), "radius": 6.6, "count": 4},
		{"type": "circle", "center": Vector3(-42.0, 0.0, -78.0), "radius": 6.8, "count": 2},
		{"type": "circle", "center": Vector3(42.0, 0.0, -78.0), "radius": 6.8, "count": 2},
		{"type": "circle", "center": Vector3(-34.0, 0.0, -138.0), "radius": 7.6, "count": 3},
	]

	for route in walk_routes:
		var rtype: String = String(route["type"])
		var rcnt: int = int(route["count"])
		for k in range(rcnt):
			var col: Color = soul_palette[_walking_souls.size() % soul_palette.size()]
			if rtype == "line":
				var pa: Vector3 = route["a"] as Vector3
				var pb: Vector3 = route["b"] as Vector3
				var dist_ab: float = pa.distance_to(pb)
				var speed_mps: float = rng.randf_range(1.65, 2.75)
				_walking_souls.append({
					"type": "line",
					"a": pa + Vector3(rng.randf_range(-0.55, 0.55), 0.0, rng.randf_range(-0.55, 0.55)),
					"b": pb + Vector3(rng.randf_range(-0.55, 0.55), 0.0, rng.randf_range(-0.55, 0.55)),
					"rate": speed_mps / maxf(dist_ab, 1.0),
					"offset": float(k) / float(rcnt) + rng.randf_range(0.0, 0.05),
					"phase": rng.randf_range(0.0, TAU),
					"scale": rng.randf_range(0.84, 1.14),
					"color": col,
				})
			else:
				var c_pt: Vector3 = route["center"] as Vector3
				var c_r: float = float(route["radius"]) + rng.randf_range(-0.8, 0.8)
				var dir_sign: float = 1.0 if (k % 2 == 0) else -1.0
				_walking_souls.append({
					"type": "circle",
					"center": c_pt,
					"radius": c_r,
					"ang_speed": dir_sign * rng.randf_range(0.22, 0.38),
					"angle0": (TAU * float(k)) / float(rcnt),
					"phase": rng.randf_range(0.0, TAU),
					"scale": rng.randf_range(0.84, 1.14),
					"color": col,
				})

	# --- B. 56 CELESTIAL SKY SOULS soaring in luminous arcs between landmarks & Palace ---
	var sky_arcs: Array[Dictionary] = [
		{"p0": Vector3(-54.0, 17.0, -78.0), "ctrl": Vector3(0.0, 31.0, -82.0), "p1": Vector3(54.0, 21.0, -78.0), "count": 10},
		{"p0": Vector3(-54.0, 18.0, -78.0), "ctrl": Vector3(-34.0, 34.0, -175.0), "p1": Vector3(0.0, 24.0, -250.0), "count": 10},
		{"p0": Vector3(54.0, 22.0, -78.0), "ctrl": Vector3(34.0, 35.0, -175.0), "p1": Vector3(0.0, 24.0, -250.0), "count": 10},
		{"p0": Vector3(-48.0, 16.0, 8.0), "ctrl": Vector3(0.0, 26.0, -32.0), "p1": Vector3(66.0, 18.0, 26.0), "count": 8},
		{"p0": Vector3(0.0, 14.0, 48.0), "ctrl": Vector3(-26.0, 28.0, -32.0), "p1": Vector3(-34.0, 19.0, -138.0), "count": 9},
		{"p0": Vector3(0.0, 14.0, 48.0), "ctrl": Vector3(26.0, 28.0, -32.0), "p1": Vector3(40.0, 19.0, -138.0), "count": 9},
	]

	for arc in sky_arcs:
		var p0: Vector3 = arc["p0"] as Vector3
		var ctrl: Vector3 = arc["ctrl"] as Vector3
		var p1: Vector3 = arc["p1"] as Vector3
		var acnt: int = int(arc["count"])
		for k in range(acnt):
			var col: Color = soul_palette[(k + _sky_souls.size()) % soul_palette.size()]
			_sky_souls.append({
				"p0": p0 + Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(-1.5, 2.0), rng.randf_range(-3.0, 3.0)),
				"ctrl": ctrl + Vector3(rng.randf_range(-5.0, 5.0), rng.randf_range(-2.5, 4.5), rng.randf_range(-4.0, 4.0)),
				"p1": p1 + Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(-1.5, 2.0), rng.randf_range(-3.0, 3.0)),
				"rate": rng.randf_range(0.032, 0.058),
				"offset": float(k) / float(acnt),
				"phase": rng.randf_range(0.0, TAU),
				"scale": rng.randf_range(0.95, 1.35),
				"color": col,
			})

	var total_souls: int = _walking_souls.size() + _sky_souls.size()

	# MultiMesh 1: Luminous Spirit Drop Silhouettes
	var body_mesh: ArrayMesh = _create_soul_silhouette_mesh()
	_souls_body_mm = MultiMesh.new()
	_souls_body_mm.transform_format = MultiMesh.TRANSFORM_3D
	_souls_body_mm.use_colors = true
	_souls_body_mm.mesh = body_mesh
	_souls_body_mm.instance_count = total_souls

	# MultiMesh 2: Soft Glowing Halos above every Soul
	var halo_mesh: TorusMesh = TorusMesh.new()
	halo_mesh.inner_radius = 0.21
	halo_mesh.outer_radius = 0.29
	halo_mesh.rings = 16
	halo_mesh.ring_segments = 6

	_souls_halo_mm = MultiMesh.new()
	_souls_halo_mm.transform_format = MultiMesh.TRANSFORM_3D
	_souls_halo_mm.use_colors = true
	_souls_halo_mm.mesh = halo_mesh
	_souls_halo_mm.instance_count = total_souls

	# Assign per-instance pastel-HDR soul colors
	var idx: int = 0
	for ws in _walking_souls:
		var c: Color = ws["color"] as Color
		_souls_body_mm.set_instance_color(idx, c)
		_souls_halo_mm.set_instance_color(idx, Color(c.r * 1.15, c.g * 1.15, c.b * 1.15, 0.85))
		idx += 1
	for ss in _sky_souls:
		var sc: Color = ss["color"] as Color
		_souls_body_mm.set_instance_color(idx, sc)
		_souls_halo_mm.set_instance_color(idx, Color(sc.r * 1.2, sc.g * 1.2, sc.b * 1.2, 0.90))
		idx += 1

	var body_mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	body_mmi.name = "CitySoulsBodies"
	body_mmi.multimesh = _souls_body_mm
	body_mmi.material_override = _mat_soul_body
	body_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body_mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	souls_root.add_child(body_mmi)

	var halo_mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	halo_mmi.name = "CitySoulsHalos"
	halo_mmi.multimesh = _souls_halo_mm
	halo_mmi.material_override = _mat_soul_halo
	halo_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo_mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	souls_root.add_child(halo_mmi)

	_update_living_souls()


func _update_living_souls() -> void:
	if _souls_body_mm == null or _souls_halo_mm == null:
		return

	var idx: int = 0
	# 1. Update 80 strolling ground souls (smoothly traversing all 3 tiers & 4 staircases!)
	for ws in _walking_souls:
		var pos: Vector3 = Vector3.ZERO
		var yaw: float = 0.0
		var ph: float = float(ws["phase"])
		var sc: float = float(ws["scale"])

		if String(ws["type"]) == "line":
			var pa: Vector3 = ws["a"] as Vector3
			var pb: Vector3 = ws["b"] as Vector3
			var cyc: float = fposmod(float(ws["offset"]) + _anim_time * float(ws["rate"]), 2.0)
			var t: float = cyc if cyc <= 1.0 else (2.0 - cyc)
			var forward: bool = cyc <= 1.0
			pos = pa.lerp(pb, t)
			var dir_v: Vector3 = (pb - pa) if forward else (pa - pb)
			yaw = atan2(dir_v.x, dir_v.z)
		else:
			var c_pt: Vector3 = ws["center"] as Vector3
			var c_r: float = float(ws["radius"])
			var a_spd: float = float(ws["ang_speed"])
			var ang: float = float(ws["angle0"]) + _anim_time * a_spd
			pos = Vector3(c_pt.x + cos(ang) * c_r, 0.0, c_pt.z + sin(ang) * c_r)
			var tx: float = -sin(ang) * a_spd
			var tz: float = cos(ang) * a_spd
			yaw = atan2(tx, tz)

		var ground_y: float = _get_city_walk_y(pos.x, pos.z)
		var hover_y: float = ground_y + 0.30 + sin(_anim_time * 2.5 + ph) * 0.14
		var sway_z: float = sin(_anim_time * 1.9 + ph) * 0.08
		var body_rot: Basis = Basis.from_euler(Vector3(0.06, yaw, sway_z)).scaled(Vector3(sc, sc, sc))
		_souls_body_mm.set_instance_transform(idx, Transform3D(body_rot, Vector3(pos.x, hover_y, pos.z)))

		var halo_y: float = hover_y + 1.62 * sc + cos(_anim_time * 2.5 + ph) * 0.06
		var halo_rot: Basis = Basis.from_euler(Vector3(0.18, yaw + _anim_time * 0.8, 0.0)).scaled(Vector3(sc, sc, sc))
		_souls_halo_mm.set_instance_transform(idx, Transform3D(halo_rot, Vector3(pos.x, halo_y, pos.z)))
		idx += 1

	# 2. Update 56 soaring celestial sky souls
	for ss in _sky_souls:
		var p0: Vector3 = ss["p0"] as Vector3
		var ctrl: Vector3 = ss["ctrl"] as Vector3
		var p1: Vector3 = ss["p1"] as Vector3
		var ph: float = float(ss["phase"])
		var sc: float = float(ss["scale"])

		var cyc: float = fposmod(float(ss["offset"]) + _anim_time * float(ss["rate"]), 2.0)
		var t: float = cyc if cyc <= 1.0 else (2.0 - cyc)
		var inv_t: float = 1.0 - t
		var pos: Vector3 = (inv_t * inv_t) * p0 + (2.0 * inv_t * t) * ctrl + (t * t) * p1
		pos.y += sin(_anim_time * 1.8 + ph) * 0.65

		var tang: Vector3 = 2.0 * inv_t * (ctrl - p0) + 2.0 * t * (p1 - ctrl)
		if cyc > 1.0:
			tang = -tang
		var yaw: float = atan2(tang.x, tang.z)
		var body_rot: Basis = Basis.from_euler(Vector3(0.32, yaw, sin(_anim_time * 2.0 + ph) * 0.14)).scaled(Vector3(sc, sc * 1.12, sc))
		_souls_body_mm.set_instance_transform(idx, Transform3D(body_rot, pos))

		var halo_rot: Basis = Basis.from_euler(Vector3(0.25, yaw + _anim_time * 1.2, 0.0)).scaled(Vector3(sc * 1.15, sc * 1.15, sc * 1.15))
		_souls_halo_mm.set_instance_transform(idx, Transform3D(halo_rot, pos + Vector3(0.0, 1.72 * sc, 0.0)))
		idx += 1


func _create_soul_silhouette_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Graceful luminous teardrop/robed spirit profile (height ~1.48m, 10 radial segments)
	var rings_y: Array[float] = [0.0, 0.28, 0.68, 1.04, 1.24, 1.44]
	var rings_r: Array[float] = [0.06, 0.25, 0.30, 0.20, 0.24, 0.12]
	var segs: int = 10
	var ring_cnt: int = rings_y.size()

	for r_idx in range(ring_cnt - 1):
		var y0: float = rings_y[r_idx]
		var y1: float = rings_y[r_idx + 1]
		var rad0: float = rings_r[r_idx]
		var rad1: float = rings_r[r_idx + 1]
		for s in range(segs):
			var a0: float = (TAU * float(s)) / float(segs)
			var a1: float = (TAU * float(s + 1)) / float(segs)
			var v00: Vector3 = Vector3(cos(a0) * rad0, y0, sin(a0) * rad0)
			var v10: Vector3 = Vector3(cos(a1) * rad0, y0, sin(a1) * rad0)
			var v01: Vector3 = Vector3(cos(a0) * rad1, y1, sin(a0) * rad1)
			var v11: Vector3 = Vector3(cos(a1) * rad1, y1, sin(a1) * rad1)

			st.add_vertex(v00)
			st.add_vertex(v10)
			st.add_vertex(v11)

			st.add_vertex(v00)
			st.add_vertex(v11)
			st.add_vertex(v01)

	# Soft crown cap
	var apex: Vector3 = Vector3(0.0, 1.54, 0.0)
	var top_y: float = rings_y[ring_cnt - 1]
	var top_r: float = rings_r[ring_cnt - 1]
	for s in range(segs):
		var a0: float = (TAU * float(s)) / float(segs)
		var a1: float = (TAU * float(s + 1)) / float(segs)
		st.add_vertex(Vector3(cos(a0) * top_r, top_y, sin(a0) * top_r))
		st.add_vertex(Vector3(cos(a1) * top_r, top_y, sin(a1) * top_r))
		st.add_vertex(apex)

	st.generate_normals()
	return st.commit()


func _create_colored_multimesh(
	parent: Node3D,
	mm_name: String,
	mesh_res: Mesh,
	mat_override: Material,
	xforms: Array[Transform3D],
	colors: Array[Color]
) -> void:
	if xforms.is_empty() or mesh_res == null:
		return
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh_res
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])
		if i < colors.size():
			mm.set_instance_color(i, colors[i])

	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = mm_name
	mmi.multimesh = mm
	if mat_override != null:
		mmi.material_override = mat_override
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(mmi)


# ===========================================================================
# 9. LANTERN GARDEN FLOATING SKY LANTERNS (GPUParticles3D, Tier 1 Y = 3.2)
# ===========================================================================

func _build_lantern_garden_particles() -> void:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "LanternGardenSkyLanterns"
	particles.position = Vector3(-34.0, TIER_1_Y + 1.8, -138.0)
	particles.amount = 24
	particles.lifetime = 11.0
	particles.preprocess = 5.0
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	var proc_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc_mat.emission_box_extents = Vector3(11.0, 0.6, 11.0)
	proc_mat.direction = Vector3(0.0, 1.0, 0.0)
	proc_mat.spread = 16.0
	proc_mat.gravity = Vector3(0.0, 0.06, 0.0)
	proc_mat.initial_velocity_min = 0.32
	proc_mat.initial_velocity_max = 0.65
	proc_mat.scale_min = 0.75
	proc_mat.scale_max = 1.25
	particles.process_material = proc_mat

	var lantern_mesh: CylinderMesh = CylinderMesh.new()
	lantern_mesh.top_radius = 0.18
	lantern_mesh.bottom_radius = 0.14
	lantern_mesh.height = 0.38
	lantern_mesh.radial_segments = 8

	var lantern_mat: StandardMaterial3D = StandardMaterial3D.new()
	lantern_mat.albedo_color = Color("#FFE7A0")
	lantern_mat.roughness = 0.30
	lantern_mat.emission_enabled = true
	lantern_mat.emission = Color("#FFCA62")
	lantern_mat.emission_energy_multiplier = 2.2
	lantern_mesh.material = lantern_mat

	particles.draw_pass_1 = lantern_mesh
	add_child(particles)


# ===========================================================================
# 10. 3D INTERACTIVE QUEST ARTIFACTS (3 Blueprint Foundations, 3-Tier Y!)
# ===========================================================================

func _build_quest_artifacts() -> void:
	var quest_root: Node3D = Node3D.new()
	quest_root.name = "BlueprintQuestArtifacts"
	add_child(quest_root)

	# 1. "memory_drop" — Капля Памяти in Quiet Lakes Park (42.0, 0.0, 10.0)
	_create_quest_artifact(
		quest_root,
		"memory_drop",
		"QuestItem_MemoryDrop",
		Vector3(42.0, TIER_0_Y, 10.0),
		Color("#7CECF8"),
		Color("#4AD8F0"),
		0.0,
		"drop"
	)

	# 2. "blank_page" — Чистая Страница at Orion Library (-42.0, 3.2, -78.0)
	_create_quest_artifact(
		quest_root,
		"blank_page",
		"QuestItem_BlankPage",
		Vector3(-42.0, TIER_1_Y, -78.0),
		Color("#FFF8E6"),
		Color("#FFE090"),
		2.1,
		"page"
	)

	# 3. "seven_springs_sand" — Песок Семи Вёсен at Kronos Tower (42.0, 3.2, -78.0)
	_create_quest_artifact(
		quest_root,
		"seven_springs_sand",
		"QuestItem_SevenSpringsSand",
		Vector3(42.0, TIER_1_Y, -78.0),
		Color("#FFD978"),
		Color("#F5B842"),
		4.2,
		"sand"
	)


func _create_quest_artifact(
	parent: Node3D,
	item_id: String,
	node_name: String,
	pos: Vector3,
	albedo_col: Color,
	glow_col: Color,
	phase: float,
	shape_kind: String
) -> void:
	var item_root: Node3D = Node3D.new()
	item_root.name = node_name
	item_root.position = Vector3(pos.x, pos.y + PLAZA_TOP_Y, pos.z)
	item_root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(item_root)

	_add_cylinder_part(item_root, 0.62, 0.16, Vector3(0.0, 0.08, 0.0), _mat_marble_plaza)
	_add_cylinder_part(item_root, 0.32, 0.88, Vector3(0.0, 0.56, 0.0), _mat_marble_wall)
	_add_cylinder_part(item_root, 0.48, 0.10, Vector3(0.0, 1.04, 0.0), _mat_gold_trim)

	var floater: Node3D = Node3D.new()
	floater.name = "ArtifactFloater"
	floater.position = Vector3(0.0, 1.65, 0.0)
	floater.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	item_root.add_child(floater)

	var glow_mat: StandardMaterial3D = StandardMaterial3D.new()
	glow_mat.albedo_color = albedo_col
	glow_mat.roughness = 0.15
	glow_mat.metallic = 0.12
	glow_mat.emission_enabled = true
	glow_mat.emission = glow_col
	glow_mat.emission_energy_multiplier = 2.0

	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_inst.material_override = glow_mat
	if shape_kind == "drop":
		var sp: SphereMesh = SphereMesh.new()
		sp.radius = 0.28
		sp.height = 0.72
		mesh_inst.mesh = sp
	elif shape_kind == "page":
		var pg: BoxMesh = BoxMesh.new()
		pg.size = Vector3(0.46, 0.62, 0.05)
		mesh_inst.mesh = pg
		mesh_inst.rotation.x = deg_to_rad(14.0)
	else:
		var crystal: CylinderMesh = CylinderMesh.new()
		crystal.top_radius = 0.04
		crystal.bottom_radius = 0.28
		crystal.height = 0.64
		crystal.radial_segments = 6
		mesh_inst.mesh = crystal
	floater.add_child(mesh_inst)

	var halo: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.44
	torus.outer_radius = 0.50
	torus.rings = 24
	torus.ring_segments = 8
	halo.mesh = torus
	halo.rotation.x = deg_to_rad(25.0)
	halo.material_override = _mat_gold_trim
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	floater.add_child(halo)

	# Local non-shadow-casting warm glow light (60 FPS safe)
	var omni: OmniLight3D = OmniLight3D.new()
	omni.position = Vector3(0.0, 1.75, 0.0)
	omni.light_color = glow_col
	omni.light_energy = 1.2
	omni.omni_range = 6.5
	omni.shadow_enabled = false
	item_root.add_child(omni)

	_quest_items[item_id] = item_root
	_quest_item_floaters.append({
		"root": item_root,
		"floater": floater,
		"base_y": 1.65,
		"phase": phase,
	})


# ===========================================================================
# 11. 3D QUEST BEACON (Golden Guiding Pillar + Floating Diamond)
# ===========================================================================

func _build_quest_beacon() -> void:
	_quest_beacon_root = Node3D.new()
	_quest_beacon_root.name = "QuestBeacon"
	_quest_beacon_root.visible = false
	_quest_beacon_root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_quest_beacon_root)

	_mat_beacon_beam = StandardMaterial3D.new()
	_mat_beacon_beam.albedo_color = Color(1.0, 0.88, 0.46, 0.18)
	_mat_beacon_beam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_beacon_beam.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat_beacon_beam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_beacon_beam.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_beacon_beam.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	_quest_beacon_beam = MeshInstance3D.new()
	_quest_beacon_beam.name = "BeaconBeam"
	var beam_cyl: CylinderMesh = CylinderMesh.new()
	beam_cyl.top_radius = 0.25
	beam_cyl.bottom_radius = 0.65
	beam_cyl.height = 18.0
	beam_cyl.radial_segments = 16
	_quest_beacon_beam.mesh = beam_cyl
	_quest_beacon_beam.position = Vector3(0.0, 9.0, 0.0)
	_quest_beacon_beam.material_override = _mat_beacon_beam
	_quest_beacon_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_quest_beacon_beam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_quest_beacon_root.add_child(_quest_beacon_beam)

	_mat_beacon_crystal = StandardMaterial3D.new()
	_mat_beacon_crystal.albedo_color = Color("#FFE999")
	_mat_beacon_crystal.roughness = 0.18
	_mat_beacon_crystal.metallic = 0.45
	_mat_beacon_crystal.emission_enabled = true
	_mat_beacon_crystal.emission = Color("#FFD460")
	_mat_beacon_crystal.emission_energy_multiplier = 2.4

	_quest_beacon_crystal = MeshInstance3D.new()
	_quest_beacon_crystal.name = "BeaconDiamond"
	_quest_beacon_crystal.mesh = _create_diamond_mesh(0.42, 0.95)
	_quest_beacon_crystal.position = Vector3(0.0, 3.2, 0.0)
	_quest_beacon_crystal.material_override = _mat_beacon_crystal
	_quest_beacon_crystal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_quest_beacon_crystal.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_quest_beacon_root.add_child(_quest_beacon_crystal)

	_mat_beacon_ring = StandardMaterial3D.new()
	_mat_beacon_ring.albedo_color = Color(1.0, 0.86, 0.42, 0.68)
	_mat_beacon_ring.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_beacon_ring.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_quest_beacon_ring = MeshInstance3D.new()
	_quest_beacon_ring.name = "BeaconGroundRing"
	var ring_torus: TorusMesh = TorusMesh.new()
	ring_torus.inner_radius = 1.05
	ring_torus.outer_radius = 1.28
	ring_torus.rings = 32
	ring_torus.ring_segments = 8
	_quest_beacon_ring.mesh = ring_torus
	_quest_beacon_ring.position = Vector3(0.0, 0.08, 0.0)
	_quest_beacon_ring.scale = Vector3(1.0, 0.18, 1.0)
	_quest_beacon_ring.material_override = _mat_beacon_ring
	_quest_beacon_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_quest_beacon_ring.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_quest_beacon_root.add_child(_quest_beacon_ring)


# ===========================================================================
# 11B. AIRTIGHT INVISIBLE BOUNDARY WALLS (CityInvisibleBoundaries)
#      Seals outer perimeter, Canal banks, Lake of Silence ring & Terrace edges
# ===========================================================================

func _build_invisible_boundary_walls() -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "CityInvisibleBoundaries"
	add_child(body)

	var wall_h: float = 4.5
	var tall_h: float = 9.0
	var thick: float = 0.85

	# 1. Outer City Perimeter (X = +/-62.0, Z = +62.0, North wings at Z = -226.0 for |X| > 13.5)
	_add_invisible_wall(body, "Perimeter_West", Vector3(-62.0, tall_h * 0.5, -82.0), Vector3(thick, tall_h, 288.0), 0.0)
	_add_invisible_wall(body, "Perimeter_East", Vector3(62.0, tall_h * 0.5, -82.0), Vector3(thick, tall_h, 288.0), 0.0)
	_add_invisible_wall(body, "Perimeter_South", Vector3(0.0, wall_h * 0.5, 62.0), Vector3(124.8, wall_h, thick), 0.0)
	_add_invisible_wall(body, "Perimeter_NorthWingW", Vector3(-37.75, tall_h * 0.5, -226.0), Vector3(48.5, tall_h, thick), 0.0)
	_add_invisible_wall(body, "Perimeter_NorthWingE", Vector3(37.75, tall_h * 0.5, -226.0), Vector3(48.5, tall_h, thick), 0.0)

	# 2. Both Banks of the Shining Canal (Z = -24.8 & -39.2, leaving clean Bridge opening |X| < 5.2)
	_add_invisible_wall(body, "CanalSouth_W", Vector3(-33.6, wall_h * 0.5, -24.8), Vector3(56.8, wall_h, thick), 0.0)
	_add_invisible_wall(body, "CanalSouth_E", Vector3(33.6, wall_h * 0.5, -24.8), Vector3(56.8, wall_h, thick), 0.0)
	_add_invisible_wall(body, "CanalNorth_W", Vector3(-33.6, wall_h * 0.5, -39.2), Vector3(56.8, wall_h, thick), 0.0)
	_add_invisible_wall(body, "CanalNorth_E", Vector3(33.6, wall_h * 0.5, -39.2), Vector3(56.8, wall_h, thick), 0.0)

	# 3. Lake of Silence (54, 0, 12) — 8-sided octagonal invisible wall ring at R = 13.4
	#    Shift western segment (i == 4) east to X = 43.4 (behind memory_drop at (42, 0, 10))
	var lake_r: float = 13.4
	var seg_len: float = 2.0 * lake_r * tan(PI / 8.0) + 0.65
	for i in range(8):
		var ang: float = (TAU * float(i)) / 8.0
		var wx: float = LAKE_CENTER.x + cos(ang) * lake_r
		var wz: float = LAKE_CENTER.z + sin(ang) * lake_r
		if i == 4:
			wx = 43.4
		_add_invisible_wall(
			body,
			"LakeShoreWall_%d" % i,
			Vector3(wx, wall_h * 0.5, wz),
			Vector3(thick, wall_h, seg_len),
			-ang
		)

	# 4. Open Drop-offs of Elevated Terraces (Tier 1 Y = 3.2 & Tier 2 Y = 5.6)
	# 4a. North Mid Terrace South Rim (Z = -52.0, leaving clean 12.4m opening for Grand North Staircase)
	_add_invisible_wall(body, "NorthTerraceSouth_W", Vector3(-34.1, TIER_1_Y + wall_h * 0.5, -52.0), Vector3(55.8, wall_h, thick), 0.0)
	_add_invisible_wall(body, "NorthTerraceSouth_E", Vector3(34.1, TIER_1_Y + wall_h * 0.5, -52.0), Vector3(55.8, wall_h, thick), 0.0)

	# 4b. North Mid Terrace North Rim (Z = -158.0, leaving clean 14.4m opening for Tier 2 Ascent Staircase)
	_add_invisible_wall(body, "NorthTerraceNorth_W", Vector3(-34.6, TIER_1_Y + wall_h * 0.5, -158.0), Vector3(54.8, wall_h, thick), 0.0)
	_add_invisible_wall(body, "NorthTerraceNorth_E", Vector3(34.6, TIER_1_Y + wall_h * 0.5, -158.0), Vector3(54.8, wall_h, thick), 0.0)

	# 4c. West School Terrace (X in [-62..-26], Z in [-16..+32], leaving 8.4m stair opening Z in [3.8..12.2])
	_add_invisible_wall(body, "WestSchoolEdge_North", Vector3(-44.0, TIER_1_Y + wall_h * 0.5, -16.0), Vector3(36.4, wall_h, thick), 0.0)
	_add_invisible_wall(body, "WestSchoolEdge_South", Vector3(-44.0, TIER_1_Y + wall_h * 0.5, 32.0), Vector3(36.4, wall_h, thick), 0.0)
	_add_invisible_wall(body, "WestSchoolEdge_EastN", Vector3(-26.0, TIER_1_Y + wall_h * 0.5, -6.1), Vector3(thick, wall_h, 19.8), 0.0)
	_add_invisible_wall(body, "WestSchoolEdge_EastS", Vector3(-26.0, TIER_1_Y + wall_h * 0.5, 22.1), Vector3(thick, wall_h, 19.8), 0.0)

	# 4d. Upper Overlook Terrace (Y = 5.6, X in [-24..+24], Z in [-198..-170], leaving 14.4m stair openings)
	_add_invisible_wall(body, "OverlookEdge_West", Vector3(-24.0, TIER_2_Y + wall_h * 0.5, -184.0), Vector3(thick, wall_h, 28.4), 0.0)
	_add_invisible_wall(body, "OverlookEdge_East", Vector3(24.0, TIER_2_Y + wall_h * 0.5, -184.0), Vector3(thick, wall_h, 28.4), 0.0)
	_add_invisible_wall(body, "OverlookEdge_SouthW", Vector3(-15.6, TIER_2_Y + wall_h * 0.5, -170.0), Vector3(16.8, wall_h, thick), 0.0)
	_add_invisible_wall(body, "OverlookEdge_SouthE", Vector3(15.6, TIER_2_Y + wall_h * 0.5, -170.0), Vector3(16.8, wall_h, thick), 0.0)
	_add_invisible_wall(body, "OverlookEdge_NorthW", Vector3(-15.6, TIER_2_Y + wall_h * 0.5, -198.0), Vector3(16.8, wall_h, thick), 0.0)
	_add_invisible_wall(body, "OverlookEdge_NorthE", Vector3(15.6, TIER_2_Y + wall_h * 0.5, -198.0), Vector3(16.8, wall_h, thick), 0.0)


func _add_invisible_wall(
	body: StaticBody3D,
	wall_name: String,
	pos: Vector3,
	size: Vector3,
	yaw_rad: float
) -> void:
	var col: CollisionShape3D = CollisionShape3D.new()
	col.name = wall_name
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	col.shape = box
	col.position = pos
	col.rotation.y = yaw_rad
	body.add_child(col)


func _create_diamond_mesh(radius: float, half_height: float) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var top: Vector3 = Vector3(0.0, half_height, 0.0)
	var bot: Vector3 = Vector3(0.0, -half_height, 0.0)
	var eq: Array[Vector3] = [
		Vector3(radius, 0.0, 0.0),
		Vector3(0.0, 0.0, radius),
		Vector3(-radius, 0.0, 0.0),
		Vector3(0.0, 0.0, -radius),
	]

	for i in range(4):
		var ni: int = (i + 1) % 4
		st.add_vertex(top)
		st.add_vertex(eq[i])
		st.add_vertex(eq[ni])

		st.add_vertex(bot)
		st.add_vertex(eq[ni])
		st.add_vertex(eq[i])

	st.generate_normals()
	return st.commit()


# ===========================================================================
# 12. MULTIMESH SUB-MESH EXTRACTION, PROCEDURAL FALLBACKS & GEOMETRY HELPERS
# ===========================================================================

func _create_simple_multimesh(
	parent: Node3D,
	mm_name: String,
	mesh_res: Mesh,
	mat_override: Material,
	xforms: Array[Transform3D]
) -> void:
	if xforms.is_empty() or mesh_res == null:
		return
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh_res
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])

	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = mm_name
	mmi.multimesh = mm
	if mat_override != null:
		mmi.material_override = mat_override
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(mmi)


## Extracts every sub-mesh from a PackedScene (grounded to min_y = 0) and renders
## all transforms via MultiMeshInstance3D per sub-mesh, upgrading house walls/roofs
## to pixar_building_facade.gdshader while preserving warm emissive windows at 60 FPS!
func _spawn_scene_multimesh_batch(
	parent: Node3D,
	batch_name: String,
	scene: PackedScene,
	xforms: Array[Transform3D],
	fallback_parts: Array[Dictionary],
	canopy_tint_override: Material,
	apply_facade_shader: bool = false
) -> void:
	if xforms.is_empty():
		return

	var sub_parts: Array[Dictionary] = []
	if scene != null:
		var temp_inst: Node = scene.instantiate()
		if temp_inst is Node3D:
			var temp_root: Node3D = temp_inst as Node3D
			var min_y: float = _find_min_local_y(temp_root, Transform3D.IDENTITY)
			var ground_offset_y: float = -min_y if min_y < 1.0e8 else 0.0
			var ground_xf: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0.0, ground_offset_y, 0.0))
			_collect_submesh_parts(temp_root, ground_xf, sub_parts, canopy_tint_override, apply_facade_shader)
		temp_inst.free()

	if sub_parts.is_empty():
		sub_parts = fallback_parts

	for p_idx in range(sub_parts.size()):
		var part: Dictionary = sub_parts[p_idx]
		var p_mesh: Mesh = part["mesh"] as Mesh
		if p_mesh == null:
			continue
		var p_local_xf: Transform3D = part["xform"] as Transform3D
		var p_mat: Material = part["material"] as Material

		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = p_mesh
		mm.instance_count = xforms.size()
		for i in range(xforms.size()):
			mm.set_instance_transform(i, xforms[i] * p_local_xf)

		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.name = "%s_%d" % [batch_name, p_idx]
		mmi.multimesh = mm
		if p_mat != null:
			mmi.material_override = p_mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		parent.add_child(mmi)


func _collect_submesh_parts(
	node: Node,
	parent_xf: Transform3D,
	out_parts: Array[Dictionary],
	canopy_tint_override: Material,
	apply_facade_shader: bool = false
) -> void:
	var cur_xf: Transform3D = parent_xf
	if node is Node3D:
		cur_xf = parent_xf * (node as Node3D).transform

	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh != null:
			var final_mesh: Mesh = mi.mesh
			var chosen_mat: Material = mi.material_override
			var surf_count: int = mi.mesh.get_surface_count()

			var has_surface_override: bool = false
			for s_chk in range(surf_count):
				if mi.get_surface_override_material(s_chk) != null:
					has_surface_override = true
					break

			var needs_dup: bool = has_surface_override or apply_facade_shader or (canopy_tint_override != null and surf_count > 1)
			if needs_dup:
				var dup_res: Resource = mi.mesh.duplicate()
				if dup_res is Mesh:
					var dup_mesh: Mesh = dup_res as Mesh
					for s_idx in range(surf_count):
						var ov_mat: Material = mi.get_surface_override_material(s_idx)
						if ov_mat != null:
							dup_mesh.surface_set_material(s_idx, ov_mat)
						var eff_mat: Material = ov_mat if ov_mat != null else dup_mesh.surface_get_material(s_idx)
						if apply_facade_shader and eff_mat != null:
							var upgraded_mat: Material = _upgrade_to_facade_material(eff_mat)
							dup_mesh.surface_set_material(s_idx, upgraded_mat)
						elif canopy_tint_override != null and surf_count > 1:
							var s_name: String = ""
							if eff_mat != null:
								s_name = eff_mat.resource_name.to_lower()
							var is_trunk: bool = s_name.contains("trunk") or s_name.contains("bark") or s_name.contains("wood")
							var is_canopy: bool = s_name.contains("canopy") or s_name.contains("leaf") or s_name.contains("crown") or s_name.contains("foliage")
							if not is_trunk and (is_canopy or s_idx > 0):
								dup_mesh.surface_set_material(s_idx, canopy_tint_override)
					final_mesh = dup_mesh

			if apply_facade_shader and chosen_mat != null:
				chosen_mat = _upgrade_to_facade_material(chosen_mat)

			if canopy_tint_override != null and surf_count <= 1:
				var aabb: AABB = mi.mesh.get_aabb()
				var center_y: float = (cur_xf * aabb.get_center()).y
				var lower_name: String = mi.name.to_lower()
				if center_y > 1.8 or lower_name.contains("leaf") or lower_name.contains("canopy") or lower_name.contains("crown") or lower_name.contains("foliage"):
					chosen_mat = canopy_tint_override

			out_parts.append({
				"mesh": final_mesh,
				"xform": cur_xf,
				"material": chosen_mat,
			})

	for child in node.get_children():
		_collect_submesh_parts(child, cur_xf, out_parts, canopy_tint_override, apply_facade_shader)


func _create_radial_plaza_disc_mesh(radius: float, height: float, segments: int) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var center_top: Vector3 = Vector3(0.0, height, 0.0)
	var center_uv: Vector2 = Vector2(0.5, 0.5)
	var bottom_r: float = radius + 0.25

	for i in range(segments):
		var a0: float = (TAU * float(i)) / float(segments)
		var a1: float = (TAU * float(i + 1)) / float(segments)
		var c0: float = cos(a0)
		var s0: float = sin(a0)
		var c1: float = cos(a1)
		var s1: float = sin(a1)

		var t0: Vector3 = Vector3(c0 * radius, height, s0 * radius)
		var t1: Vector3 = Vector3(c1 * radius, height, s1 * radius)
		var b0: Vector3 = Vector3(c0 * bottom_r, 0.0, s0 * bottom_r)
		var b1: Vector3 = Vector3(c1 * bottom_r, 0.0, s1 * bottom_r)

		var uv0: Vector2 = Vector2(0.5 + 0.5 * c0, 0.5 + 0.5 * s0)
		var uv1: Vector2 = Vector2(0.5 + 0.5 * c1, 0.5 + 0.5 * s1)

		# Top radial mosaic cap (upward normal +Y, centered planar UV)
		st.set_normal(Vector3.UP)
		st.set_uv(center_uv)
		st.add_vertex(center_top)
		st.set_normal(Vector3.UP)
		st.set_uv(uv0)
		st.add_vertex(t0)
		st.set_normal(Vector3.UP)
		st.set_uv(uv1)
		st.add_vertex(t1)

		# Beveled outer stone rim skirt
		var side_n: Vector3 = Vector3(c0 + c1, 0.25, s0 + s1).normalized()
		st.set_normal(side_n)
		st.set_uv(uv0)
		st.add_vertex(t0)
		st.set_normal(side_n)
		st.set_uv(uv0)
		st.add_vertex(b0)
		st.set_normal(side_n)
		st.set_uv(uv1)
		st.add_vertex(b1)

		st.set_normal(side_n)
		st.set_uv(uv0)
		st.add_vertex(t0)
		st.set_normal(side_n)
		st.set_uv(uv1)
		st.add_vertex(b1)
		st.set_normal(side_n)
		st.set_uv(uv1)
		st.add_vertex(t1)

	return st.commit()


func _create_fallback_house_parts(kind: String) -> Array[Dictionary]:
	var wall_mat: Material = _mat_wall_cream
	var roof_mat: Material = _mat_roof_red
	if kind == "blue_balcony":
		roof_mat = _mat_blue_roof
	elif kind == "ochre_timber":
		wall_mat = _mat_wall_ochre
		roof_mat = _mat_roof_ochre
	elif kind == "terracotta_terrace":
		wall_mat = _mat_wall_peach
		roof_mat = _mat_roof_terracotta
	elif kind == "cream_spire":
		roof_mat = _mat_blue_roof

	var parts: Array[Dictionary] = []
	if kind == "cream_spire":
		var tower_cyl: CylinderMesh = CylinderMesh.new()
		tower_cyl.top_radius = 2.4
		tower_cyl.bottom_radius = 2.6
		tower_cyl.height = 6.6
		tower_cyl.radial_segments = 10
		parts.append({
			"mesh": tower_cyl,
			"xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 3.3, 0.0)),
			"material": wall_mat,
		})
		var spire_cone: CylinderMesh = CylinderMesh.new()
		spire_cone.top_radius = 0.08
		spire_cone.bottom_radius = 2.95
		spire_cone.height = 4.8
		spire_cone.radial_segments = 10
		parts.append({
			"mesh": spire_cone,
			"xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 9.0, 0.0)),
			"material": roof_mat,
		})
	else:
		var body_box: BoxMesh = BoxMesh.new()
		body_box.size = Vector3(5.8, 4.4, 5.8)
		parts.append({
			"mesh": body_box,
			"xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 2.2, 0.0)),
			"material": wall_mat,
		})
		var roof_prism: PrismMesh = PrismMesh.new()
		roof_prism.size = Vector3(6.4, 2.5, 6.4)
		parts.append({
			"mesh": roof_prism,
			"xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 5.65, 0.0)),
			"material": roof_mat,
		})
	return parts


func _create_fallback_cliff_parts() -> Array[Dictionary]:
	var rock_cyl: CylinderMesh = CylinderMesh.new()
	rock_cyl.top_radius = 3.8
	rock_cyl.bottom_radius = 5.4
	rock_cyl.height = 6.0
	rock_cyl.radial_segments = 7
	return [{
		"mesh": rock_cyl,
		"xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 3.0, 0.0)),
		"material": _mat_cliff_rock,
	}]


func _create_fallback_tree_parts(foliage_mat: Material) -> Array[Dictionary]:
	var trunk: CylinderMesh = CylinderMesh.new()
	trunk.top_radius = 0.24
	trunk.bottom_radius = 0.36
	trunk.height = 3.2
	trunk.radial_segments = 7

	var crown: SphereMesh = SphereMesh.new()
	crown.radius = 2.25
	crown.height = 3.4
	crown.radial_segments = 10
	crown.rings = 6

	return [
		{
			"mesh": trunk,
			"xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 1.6, 0.0)),
			"material": _mat_trunk_wood,
		},
		{
			"mesh": crown,
			"xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 4.1, 0.0)),
			"material": foliage_mat,
		},
	]


func _ground_node_to_zero(target: Node3D) -> void:
	var min_y: float = _find_min_local_y(target, Transform3D.IDENTITY)
	if min_y < 1.0e8:
		target.position.y -= min_y


func _find_min_local_y(node: Node, parent_xform: Transform3D) -> float:
	var current_xform: Transform3D = parent_xform
	if node is Node3D:
		current_xform = parent_xform * (node as Node3D).transform

	var best_y: float = 1.0e9
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh != null:
			var aabb: AABB = mi.mesh.get_aabb()
			for corner_idx in range(8):
				var c: Vector3 = current_xform * aabb.get_endpoint(corner_idx)
				best_y = minf(best_y, c.y)

	for child in node.get_children():
		best_y = minf(best_y, _find_min_local_y(child, current_xform))
	return best_y


func _add_box_part(
	parent: Node3D,
	size: Vector3,
	pos: Vector3,
	mat: Material
) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _add_cylinder_part(
	parent: Node3D,
	radius: float,
	height: float,
	pos: Vector3,
	mat: Material
) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 16
	mi.mesh = cyl
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _add_prism_roof(
	parent: Node3D,
	size: Vector3,
	pos: Vector3,
	mat: Material
) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var prism: PrismMesh = PrismMesh.new()
	prism.size = size
	mi.mesh = prism
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi
