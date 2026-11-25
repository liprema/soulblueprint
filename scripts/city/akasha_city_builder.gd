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
const PIXAR_WINDOW_GLOW_SHADER_PATH: String = "res://shaders/pixar_window_glow.gdshader"
const STYLIZED_TREE_FOLIAGE_SHADER_PATH: String = "res://shaders/stylized_tree_foliage.gdshader"

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
const TREE_BLOSSOM_PATH: String = "res://assets/models/city/trees/akasha_tree_blossom.glb"
const TREE_WILLOW_PATH: String = "res://assets/models/city/trees/akasha_tree_willow.glb"
const TREE_BONSAI_PATH: String = "res://assets/models/city/trees/akasha_tree_bonsai.glb"
const PIXAR_BOAT_PATH: String = "res://assets/models/city/pixar/pixar_boat.glb"

const VENUE_CAFE_PATH: String = "res://assets/models/city/venues/venue_starlight_cafe.glb"
const VENUE_SHOP_PATH: String = "res://assets/models/city/venues/venue_memory_shop.glb"
const VENUE_GYM_PATH: String = "res://assets/models/city/venues/venue_soul_gym.glb"
const VENUE_MALL_PATH: String = "res://assets/models/city/venues/venue_grand_mall.glb"

const PROP_SAKURA_PATH: String = "res://assets/models/props/sakura_tree.glb"
const PROP_BUSH_PATH: String = "res://assets/models/props/lush_bush_hedge.glb"
const PROP_PLANTER_PATH: String = "res://assets/models/props/garden_planter.glb"

const PROP_CITY_BENCH_PATH: String = "res://assets/models/city/props/prop_city_bench.glb"
const PROP_CITY_SIGNPOST_PATH: String = "res://assets/models/city/props/prop_city_signpost.glb"
const PROP_STREET_LAMP_PATH: String = "res://assets/models/city/props/prop_street_lamp.glb"
const PROP_FLOWER_CART_PATH: String = "res://assets/models/city/props/prop_flower_cart.glb"
const PROP_TOWN_BULLETIN_PATH: String = "res://assets/models/city/props/prop_town_bulletin.glb"
const PROP_ORNATE_RAILING_PATH: String = "res://assets/models/city/props/prop_ornate_railing.glb"
const PROP_RAILING_PILLAR_PATH: String = "res://assets/models/city/props/prop_railing_pillar.glb"
const PROP_CAFE_BISTRO_PATH: String = "res://assets/models/city/props/prop_cafe_bistro_set.glb"
const PROP_GARDEN_URN_PATH: String = "res://assets/models/city/props/prop_garden_urn.glb"
const PROP_GRASS_DAISY_PATH: String = "res://assets/models/city/props/prop_grass_daisy_cluster.glb"
const PROP_SKY_LANTERN_PATH: String = "res://assets/models/city/props/prop_sky_lantern.glb"

const VALLEY_CENTER_Z: float = -100.0
const VALLEY_WIDTH: float = 560.0
const VALLEY_DEPTH: float = 780.0

const CANAL_Z: float = -32.0
const CANAL_LENGTH: float = 360.0
const CANAL_WIDTH: float = 14.0
const CANAL_WATER_Y: float = -0.25

const LAKE_CENTER: Vector3 = Vector3(54.0, -0.18, 12.0)
const LAKE_RADIUS: float = 13.0

const TIER_0_Y: float = 0.0
const TIER_1_Y: float = 3.2
const TIER_2_Y: float = 5.6

# Strict non-overlapping elevation ladder (0 Z-fighting at all intersections & plazas!)
const SIDE_ALLEY_TOP_Y: float = 0.015
const SIDE_STREET_TOP_Y: float = 0.025
const ROAD_TOP_Y: float = 0.055
const PLAZA_TOP_Y: float = 0.085
const PARK_LAWN_TOP_Y: float = 0.115
const BRIDGE_DECK_Y: float = 1.35

const DISTRICT_QUERY_RADIUS: float = 28.0

# Shared materials (reused across meshes for 60 FPS on macOS Retina)
var _facade_shader: Shader = null
var _window_glow_shader: Shader = null
var _tree_foliage_shader: Shader = null
var _facade_mat_cache: Dictionary = {}
var _mat_meadow: Material = null
var _mat_park_lawn: Material = null
var _mat_marble_road: Material = null
var _mat_marble_plaza: Material = null
var _mat_marble_wall: Material = null
var _mat_gold_trim: StandardMaterial3D = null
var _mat_blue_roof: StandardMaterial3D = null
var _mat_warm_window: StandardMaterial3D = null
var _mat_chaotic_window: Material = null
var _mat_stone_quay: StandardMaterial3D = null
var _mat_water_canal: Material = null
var _mat_water_lake: Material = null
var _mat_waterfall: Material = null
var _mat_waterfall_foam: StandardMaterial3D = null
var _mat_canal_bed: StandardMaterial3D = null
var _mat_beacon_ring: StandardMaterial3D = null

# Harmonized Akasha palette materials (terraces, cliffs, painterly trees, soft facades)
var _mat_terrace_stone: Material = null
var _mat_arch_recess: StandardMaterial3D = null
var _mat_cliff_rock: StandardMaterial3D = null
var _mat_foliage_green: StandardMaterial3D = null
var _mat_foliage_gold: StandardMaterial3D = null
var _mat_foliage_sakura: StandardMaterial3D = null
var _mat_tree_blossom: Material = null
var _mat_tree_willow_gold: Material = null
var _mat_tree_willow_lavender: Material = null
var _mat_tree_bonsai_azure: Material = null
var _mat_trunk_wood: StandardMaterial3D = null
var _mat_trunk_silver: StandardMaterial3D = null
var _mat_wall_cream: Material = null
var _mat_wall_ochre: Material = null
var _mat_wall_peach: Material = null
var _mat_roof_red: Material = null
var _mat_roof_terracotta: Material = null
var _mat_roof_ochre: Material = null
var _mat_boat_hull: StandardMaterial3D = null
var _mat_boat_trim: StandardMaterial3D = null

# Warm timber material (used by procedural fallbacks & Cloud Balloon basket)
var _mat_bench_wood: StandardMaterial3D = null

# Cached PackedScenes for safe instantiation & MultiMesh sub-mesh extraction
var _scene_sakura: PackedScene = null
var _scene_bush: PackedScene = null
var _scene_planter: PackedScene = null
var _scene_pavilion: PackedScene = null
var _scene_house_red: PackedScene = null
var _scene_house_blue: PackedScene = null
var _scene_house_ochre: PackedScene = null
var _scene_house_terracotta: PackedScene = null
var _scene_house_cream_spire: PackedScene = null
var _scene_cliff_rock: PackedScene = null
var _scene_tree_blossom: PackedScene = null
var _scene_tree_willow: PackedScene = null
var _scene_tree_bonsai: PackedScene = null
var _scene_boat: PackedScene = null
var _scene_prop_bench: PackedScene = null
var _scene_prop_signpost: PackedScene = null
var _scene_prop_lamp: PackedScene = null
var _scene_prop_flower_cart: PackedScene = null
var _scene_prop_bulletin: PackedScene = null
var _scene_prop_ornate_railing: PackedScene = null
var _scene_prop_railing_pillar: PackedScene = null
var _scene_prop_cafe_bistro: PackedScene = null
var _scene_prop_garden_urn: PackedScene = null
var _scene_prop_grass_daisy: PackedScene = null
var _scene_sky_lantern: PackedScene = null

# Split 5-type house batches: Inner City (cast_shadows=ON) vs Outer Hillside (cast_shadows=OFF)
var _city_inner_house_batches: Dictionary = {}
var _city_outer_house_batches: Dictionary = {}
var _placed_inner_house_records: Array[Vector3] = []
var _tree_blossom_xforms: Array[Transform3D] = []
var _tree_willow_gold_xforms: Array[Transform3D] = []
var _tree_willow_lavender_xforms: Array[Transform3D] = []
var _tree_bonsai_azure_xforms: Array[Transform3D] = []
var _park_bench_xforms: Array[Transform3D] = []
var _ornate_railing_xforms: Array[Transform3D] = []
var _railing_pillar_xforms: Array[Transform3D] = []
var _railing_pillar_positions: Array[Vector3] = []
var _sky_lantern_batches: Array[Dictionary] = []
var _sky_lantern_instances: Array[Dictionary] = []

# District & interactive venue registries (contract with all tracks)
var _districts: Array[Dictionary] = []
var _district_spawns: Dictionary = {}
var _venues: Array[Dictionary] = []

# Quest items, beacon, boats & landmarks
var _quest_items: Dictionary = {}
var _quest_item_floaters: Array[Dictionary] = []
var _boat_floaters: Array[Dictionary] = []
var _orrery_rotator: Node3D = null
var _balloon_floater: Node3D = null
var _balloon_base_y: float = 0.0
var _quest_beacon_root: Node3D = null
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
	_init_venue_registry()
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

	if _quest_beacon_active and _quest_beacon_root != null and _quest_beacon_root.visible:
		if _quest_beacon_ring != null:
			var pulse: float = 1.0 + sin(_anim_time * 2.6) * 0.09
			_quest_beacon_ring.scale = Vector3(pulse, 0.16, pulse)

	if not _sky_lantern_batches.is_empty() and not _sky_lantern_instances.is_empty():
		var min_y: float = TIER_1_Y + 2.2
		var max_y: float = TIER_1_Y + 14.0
		var y_span: float = max_y - min_y
		var l_count: int = _sky_lantern_instances.size()
		for i in range(l_count):
			var info: Dictionary = _sky_lantern_instances[i]
			var bx: float = float(info["base_x"])
			var bz: float = float(info["base_z"])
			var h0: float = float(info["start_h"])
			var rise_spd: float = float(info["rise_speed"])
			var phase: float = float(info["phase"])
			var sway_r: float = float(info["sway_r"])
			var yaw_spd: float = float(info["yaw_speed"])
			var base_sc: float = float(info["scale"])

			var cycle_h: float = fposmod(h0 + _anim_time * rise_spd, y_span)
			var cur_y: float = min_y + cycle_h + sin(_anim_time * 1.35 + phase) * 0.14
			var cur_x: float = bx + cos(_anim_time * 0.48 + phase) * sway_r
			var cur_z: float = bz + sin(_anim_time * 0.42 + phase * 1.2) * sway_r

			# Smooth scale fade-in at bottom 1.2m and fade-out at top 1.8m for seamless wrap-around
			var fade_in: float = clampf(cycle_h / 1.2, 0.0, 1.0)
			var fade_out: float = clampf((y_span - cycle_h) / 1.8, 0.0, 1.0)
			var cur_sc: float = maxf(0.001, base_sc * minf(fade_in, fade_out))

			var tilt_x: float = sin(_anim_time * 1.05 + phase) * 0.045
			var tilt_z: float = cos(_anim_time * 0.92 + phase * 1.1) * 0.045
			var cur_yaw: float = phase + _anim_time * yaw_spd
			var l_rot: Basis = Basis.from_euler(Vector3(tilt_x, cur_yaw, tilt_z)).scaled(Vector3(cur_sc, cur_sc, cur_sc))
			var l_xf: Transform3D = Transform3D(l_rot, Vector3(cur_x, cur_y, cur_z))

			for b_dict in _sky_lantern_batches:
				var mm: MultiMesh = b_dict["mm"] as MultiMesh
				var local_xf: Transform3D = b_dict["local_xf"] as Transform3D
				if mm != null and i < mm.instance_count:
					mm.set_instance_transform(i, l_xf * local_xf)


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


## Returns {"id": String, "name": String, "prompt": String, "pos": Vector3, "dialogue_id": String}
## for the nearest interactive city venue within radius (with |dy| <= 2.5), or {}.
func get_nearest_venue_in_range(player_pos: Vector3, radius: float = 6.0) -> Dictionary:
	if _venues.is_empty():
		_init_venue_registry()
	var best_dist_sq: float = radius * radius
	var best_venue: Dictionary = {}
	for v_var in _venues:
		var v: Dictionary = v_var as Dictionary
		var v_pos: Vector3 = v["pos"] as Vector3
		if absf(player_pos.y - v_pos.y) > 2.5:
			continue
		var dx: float = player_pos.x - v_pos.x
		var dz: float = player_pos.z - v_pos.z
		var dist_sq: float = dx * dx + dz * dz
		if dist_sq <= best_dist_sq:
			best_dist_sq = dist_sq
			best_venue = {
				"id": String(v["id"]),
				"name": String(v["name"]),
				"prompt": String(v["prompt"]),
				"pos": v_pos,
				"dialogue_id": String(v["dialogue_id"]),
			}
	return best_venue


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


func _init_venue_registry() -> void:
	_venues = [
		{
			"id": "cafe",
			"name": "Кафе «Тёплая Чашка»",
			"prompt": "✦  [E]  Зайти в Кафе «Тёплая Чашка»",
			"pos": Vector3(11.5, TIER_0_Y, 28.0),
			"building_pos": Vector3(17.5, TIER_0_Y, 28.0),
			"dialogue_id": "city_venue_cafe",
		},
		{
			"id": "shop",
			"name": "Лавка Воспоминаний",
			"prompt": "✦  [E]  Осмотреть Лавку Воспоминаний",
			"pos": Vector3(-11.5, TIER_0_Y, 28.0),
			"building_pos": Vector3(-17.5, TIER_0_Y, 28.0),
			"dialogue_id": "city_venue_shop",
		},
		{
			"id": "gym",
			"name": "Спортзал «Павильон Полётной Подготовки»",
			"prompt": "✦  [E]  Тренировка в Спортзале Душ",
			"pos": Vector3(13.5, TIER_1_Y, -108.0),
			"building_pos": Vector3(21.0, TIER_1_Y, -108.0),
			"dialogue_id": "city_venue_gym",
		},
		{
			"id": "mall",
			"name": "Торговый Центр «Галерея Миров»",
			"prompt": "✦  [E]  Пройтись по Галерее Миров",
			"pos": Vector3(-13.5, TIER_1_Y, -108.0),
			"building_pos": Vector3(-23.0, TIER_1_Y, -108.0),
			"dialogue_id": "city_venue_mall",
		},
	]


func _init_materials() -> void:
	_facade_mat_cache.clear()
	if ResourceLoader.exists(PIXAR_BUILDING_FACADE_SHADER_PATH):
		var fac_res: Resource = load(PIXAR_BUILDING_FACADE_SHADER_PATH)
		if fac_res is Shader:
			_facade_shader = fac_res as Shader

	_window_glow_shader = null
	if ResourceLoader.exists(PIXAR_WINDOW_GLOW_SHADER_PATH):
		var wg_res: Resource = load(PIXAR_WINDOW_GLOW_SHADER_PATH)
		if wg_res is Shader:
			_window_glow_shader = wg_res as Shader

	if ResourceLoader.exists(STYLIZED_TREE_FOLIAGE_SHADER_PATH):
		var tree_sh_res: Resource = load(STYLIZED_TREE_FOLIAGE_SHADER_PATH)
		if tree_sh_res is Shader:
			_tree_foliage_shader = tree_sh_res as Shader

	# Meadow ground shader (with safe lush green StandardMaterial3D fallback)
	var meadow_shader: Shader = null
	if ResourceLoader.exists(MEADOW_SHADER_PATH):
		var meadow_res: Resource = load(MEADOW_SHADER_PATH)
		if meadow_res is Shader:
			meadow_shader = meadow_res as Shader

	if meadow_shader != null:
		var meadow_mat: ShaderMaterial = ShaderMaterial.new()
		meadow_mat.shader = meadow_shader
		meadow_mat.set_shader_parameter("vertex_color_blend", 0.0)
		meadow_mat.set_shader_parameter("daisy_density", 0.58)
		meadow_mat.set_shader_parameter("wind_wave_speed", 0.0)
		meadow_mat.set_shader_parameter("wind_shimmer_strength", 0.0)
		_mat_meadow = meadow_mat
	if _mat_meadow == null:
		var meadow_fb: StandardMaterial3D = StandardMaterial3D.new()
		meadow_fb.albedo_color = Color("#4E9E42")
		meadow_fb.roughness = 0.88
		meadow_fb.metallic = 0.0
		_mat_meadow = meadow_fb

	# Pocket Park unified hand-painted meadow lawn (exact same vibrant grass & 5-petal daisies!)
	if meadow_shader != null:
		var park_lawn_mat: ShaderMaterial = ShaderMaterial.new()
		park_lawn_mat.shader = meadow_shader
		park_lawn_mat.set_shader_parameter("vertex_color_blend", 0.0)
		park_lawn_mat.set_shader_parameter("daisy_density", 0.62)
		park_lawn_mat.set_shader_parameter("wind_wave_speed", 0.0)
		park_lawn_mat.set_shader_parameter("wind_shimmer_strength", 0.0)
		_mat_park_lawn = park_lawn_mat
	else:
		var park_lawn_fb: StandardMaterial3D = StandardMaterial3D.new()
		park_lawn_fb.albedo_color = Color("#589E54")
		park_lawn_fb.roughness = 0.88
		park_lawn_fb.metallic = 0.0
		park_lawn_fb.metallic_specular = 0.10
		_mat_park_lawn = park_lawn_fb

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

	# Deep Slate-Blue Matte Roof (harmonized Pixar palette, zero plastic gloss)
	_mat_blue_roof = StandardMaterial3D.new()
	_mat_blue_roof.albedo_color = Color(0.30, 0.36, 0.44)
	_mat_blue_roof.metallic = 0.0
	_mat_blue_roof.roughness = 0.84
	_mat_blue_roof.metallic_specular = 0.14

	# Warm Glowing Windows (fallback when pixar_window_glow.gdshader is unavailable)
	_mat_warm_window = StandardMaterial3D.new()
	_mat_warm_window.albedo_color = Color("#FFF0C8")
	_mat_warm_window.roughness = 0.24
	_mat_warm_window.emission_enabled = true
	_mat_warm_window.emission = Color("#FFDF94")
	_mat_warm_window.emission_energy_multiplier = 1.35

	# Chaotic Per-Window/Floor Glowing Window Material (pixar_window_glow.gdshader)
	if _window_glow_shader != null:
		var wg_mat: ShaderMaterial = ShaderMaterial.new()
		wg_mat.shader = _window_glow_shader
		_mat_chaotic_window = wg_mat
	else:
		_mat_chaotic_window = _mat_warm_window

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

	# Lush Green, Golden Autumn & Sakura Foliage Fallbacks (matte painterly, zero plasticine gloss)
	_mat_foliage_green = StandardMaterial3D.new()
	_mat_foliage_green.albedo_color = Color("#398C42")
	_mat_foliage_green.roughness = 0.80
	_mat_foliage_green.metallic = 0.0
	_mat_foliage_green.metallic_specular = 0.12

	_mat_foliage_gold = StandardMaterial3D.new()
	_mat_foliage_gold.albedo_color = Color("#DC9A2C")
	_mat_foliage_gold.roughness = 0.78
	_mat_foliage_gold.metallic = 0.0
	_mat_foliage_gold.metallic_specular = 0.12

	_mat_foliage_sakura = StandardMaterial3D.new()
	_mat_foliage_sakura.albedo_color = Color("#E892A2")
	_mat_foliage_sakura.roughness = 0.78
	_mat_foliage_sakura.metallic = 0.0
	_mat_foliage_sakura.metallic_specular = 0.12

	# 4 Harmonious Painterly Fairytale Tree Canopy Materials (stylized_tree_foliage.gdshader)
	# 1. Coral-Pink Sakura Blossom (akasha_tree_blossom.glb)
	_mat_tree_blossom = _create_tree_foliage_shader_mat(
		Color(0.96, 0.58, 0.58),
		Color(0.80, 0.36, 0.44),
		Color(0.36, 0.14, 0.28),
		Color(1.00, 0.84, 0.80),
		2.0,
		8.5
	)
	# 2. Golden-Amber Weeping Willow (akasha_tree_willow.glb)
	_mat_tree_willow_gold = _create_tree_foliage_shader_mat(
		Color(0.98, 0.82, 0.36),
		Color(0.82, 0.56, 0.18),
		Color(0.42, 0.22, 0.10),
		Color(1.00, 0.94, 0.72),
		1.4,
		7.8
	)
	# 3. Rose-Lavender Weeping Willow (akasha_tree_willow.glb in Lantern Garden & Mira's Sanctuary)
	_mat_tree_willow_lavender = _create_tree_foliage_shader_mat(
		Color(0.96, 0.68, 0.82),
		Color(0.74, 0.40, 0.64),
		Color(0.30, 0.16, 0.40),
		Color(1.00, 0.88, 0.96),
		1.4,
		7.8
	)
	# 4. Azure-Turquoise Celestial Bonsai (akasha_tree_bonsai.glb at Lake of Silence & Orion Library)
	_mat_tree_bonsai_azure = _create_tree_foliage_shader_mat(
		Color(0.40, 0.82, 0.88),
		Color(0.18, 0.56, 0.72),
		Color(0.10, 0.22, 0.44),
		Color(0.76, 0.96, 1.00),
		1.8,
		7.5
	)

	# Noble light lilac-silvery matte bark (zero plasticine gloss)
	_mat_trunk_silver = StandardMaterial3D.new()
	_mat_trunk_silver.albedo_color = Color(0.76, 0.72, 0.78)
	_mat_trunk_silver.roughness = 0.88
	_mat_trunk_silver.metallic = 0.0
	_mat_trunk_silver.metallic_specular = 0.10

	_mat_trunk_wood = StandardMaterial3D.new()
	_mat_trunk_wood.albedo_color = Color("#65432E")
	_mat_trunk_wood.roughness = 0.88
	_mat_trunk_wood.metallic = 0.0
	_mat_trunk_wood.metallic_specular = 0.12

	# Cohesive Toy Story 4 / Ralph Breaks the Internet Residential Fallback Palette (matte roughness = 0.86)
	_mat_wall_cream = _create_facade_shader_mat(Color(0.90, 0.85, 0.76), Color(0.76, 0.70, 0.61), 0.86, 0.0, 0.44, 0.08, 1.8)
	_mat_wall_ochre = _create_facade_shader_mat(Color(0.86, 0.79, 0.67), Color(0.72, 0.64, 0.53), 0.86, 0.0, 0.44, 0.08, 1.8)
	_mat_wall_peach = _create_facade_shader_mat(Color(0.84, 0.66, 0.54), Color(0.70, 0.52, 0.42), 0.86, 0.0, 0.44, 0.08, 1.8)
	_mat_roof_red = _create_facade_shader_mat(Color(0.62, 0.36, 0.28), Color(0.48, 0.27, 0.21), 0.86, 0.0, 0.46, 0.08, 1.4)
	_mat_roof_terracotta = _create_facade_shader_mat(Color(0.58, 0.35, 0.27), Color(0.45, 0.26, 0.20), 0.86, 0.0, 0.46, 0.08, 1.4)
	_mat_roof_ochre = _create_facade_shader_mat(Color(0.46, 0.34, 0.27), Color(0.35, 0.25, 0.19), 0.86, 0.0, 0.46, 0.08, 1.4)

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

	# Warm timber material (for Cloud Balloon basket & procedural fallbacks)
	_mat_bench_wood = StandardMaterial3D.new()
	_mat_bench_wood.albedo_color = Color("#7E4F30")
	_mat_bench_wood.roughness = 0.78


func _create_tree_foliage_shader_mat(
	top_col: Color,
	mid_col: Color,
	bot_col: Color,
	rim_col: Color,
	min_y: float,
	max_y: float
) -> Material:
	if _tree_foliage_shader != null:
		var sm: ShaderMaterial = ShaderMaterial.new()
		sm.shader = _tree_foliage_shader
		sm.set_shader_parameter("top_sun_color", top_col)
		sm.set_shader_parameter("mid_foliage_color", mid_col)
		sm.set_shader_parameter("shadow_bottom_color", bot_col)
		sm.set_shader_parameter("rim_glow_color", rim_col)
		sm.set_shader_parameter("canopy_min_y", min_y)
		sm.set_shader_parameter("canopy_max_y", max_y)
		sm.set_shader_parameter("rim_strength", 0.30)
		sm.set_shader_parameter("leaf_texture_strength", 0.24)
		sm.set_shader_parameter("per_tree_variation", 0.10)
		return sm
	var fb: StandardMaterial3D = StandardMaterial3D.new()
	fb.albedo_color = mid_col
	fb.roughness = 0.80
	fb.metallic = 0.0
	fb.metallic_specular = 0.12
	return fb


func _create_facade_shader_mat(
	base_col: Color,
	accent_col: Color,
	rough_val: float,
	_metal_val: float,
	grain_val: float,
	var_val: float,
	ao_h: float
) -> Material:
	var matte_rough: float = maxf(rough_val, 0.82)
	if _facade_shader != null:
		var sm: ShaderMaterial = ShaderMaterial.new()
		sm.shader = _facade_shader
		sm.set_shader_parameter("base_color", base_col)
		sm.set_shader_parameter("accent_color", accent_col)
		sm.set_shader_parameter("roughness_val", matte_rough)
		sm.set_shader_parameter("metallic_val", 0.0)
		sm.set_shader_parameter("grain_strength", grain_val)
		sm.set_shader_parameter("per_building_variation", var_val)
		sm.set_shader_parameter("base_ao_height", ao_h)
		return sm
	var fb: StandardMaterial3D = StandardMaterial3D.new()
	fb.albedo_color = base_col
	fb.roughness = matte_rough
	fb.metallic = 0.0
	fb.metallic_specular = 0.14
	return fb


## Returns the cohesive Toy Story 4 / Ralph Breaks the Internet warm European-Pixar
## wall & roof palette for each of the 5 residential house variants (0 dopamine rainbow!).
func _get_house_palette(kind: String) -> Dictionary:
	if kind == "red_gable":
		return {"wall": Color(0.90, 0.85, 0.76), "roof": Color(0.62, 0.36, 0.28)}
	if kind == "blue_balcony":
		return {"wall": Color(0.62, 0.70, 0.76), "roof": Color(0.30, 0.36, 0.44)}
	if kind == "ochre_timber":
		return {"wall": Color(0.86, 0.79, 0.67), "roof": Color(0.46, 0.34, 0.27)}
	if kind == "terracotta_terrace":
		return {"wall": Color(0.84, 0.66, 0.54), "roof": Color(0.58, 0.35, 0.27)}
	if kind == "cream_spire":
		return {"wall": Color(0.82, 0.72, 0.67), "roof": Color(0.32, 0.38, 0.46)}
	return {}


## Harmonizes residential facade colors into a warm, cohesive, matte cinematic palette
## (Toy Story 4 / Ralph Breaks the Internet) when no explicit house variant palette is given.
func _deepen_facade_color(col: Color, is_roof: bool = false) -> Color:
	var warm_ivory: Color = Color(0.90, 0.85, 0.76, 1.0)
	var deep_slate_blue: Color = Color(0.30, 0.36, 0.44, 1.0)
	var muted_terracotta: Color = Color(0.62, 0.36, 0.28, 1.0)
	var warm_walnut: Color = Color(0.46, 0.34, 0.27, 1.0)

	var h: float = col.h
	var s: float = col.s
	var v: float = col.v

	if s <= 0.16 and not is_roof:
		var neutral_v: float = clampf(v * 0.94, 0.45, 0.88)
		var neutral_col: Color = Color.from_hsv(h, clampf(s, 0.04, 0.14), neutral_v, 1.0)
		return neutral_col.lerp(warm_ivory, 0.32)

	var calm_s: float = clampf(s * 0.45 + 0.06, 0.14, 0.34)
	var calm_v: float = clampf(v * 0.88, 0.32, 0.84)
	var toned: Color = Color.from_hsv(h, calm_s, calm_v, 1.0)

	var looks_like_roof: bool = is_roof or (v < 0.60 and s > 0.28)
	if looks_like_roof:
		if h >= 0.48 and h <= 0.78:
			return toned.lerp(deep_slate_blue, 0.48)
		if h < 0.11 or h > 0.86:
			return toned.lerp(muted_terracotta, 0.48)
		return toned.lerp(warm_walnut, 0.42)

	var wall_v: float = clampf(calm_v, 0.66, 0.86)
	var soft_wall: Color = Color.from_hsv(h, clampf(calm_s * 0.78, 0.12, 0.28), wall_v, 1.0)
	return soft_wall.lerp(warm_ivory, 0.38)


func _is_window_material(bm: BaseMaterial3D) -> bool:
	var mat_name: String = bm.resource_name.to_lower()
	return (
		(bm.emission_enabled and bm.emission_energy_multiplier > 0.15)
		or mat_name.contains("window")
		or mat_name.contains("glass")
		or mat_name.contains("pane")
		or mat_name.contains("glow")
		or mat_name.contains("lamp")
		or mat_name.contains("lantern")
	)


func _upgrade_to_facade_material(orig_mat: Material, house_kind: String = "") -> Material:
	if orig_mat == null:
		return _mat_wall_cream
	if orig_mat is ShaderMaterial:
		return orig_mat
	var cache_key: String = "%d_%s" % [orig_mat.get_instance_id(), house_kind]
	if _facade_mat_cache.has(cache_key):
		return _facade_mat_cache[cache_key] as Material

	if orig_mat is BaseMaterial3D:
		var bm: BaseMaterial3D = orig_mat as BaseMaterial3D
		if _is_window_material(bm):
			var win_mat: Material = _mat_chaotic_window if _mat_chaotic_window != null else orig_mat
			_facade_mat_cache[cache_key] = win_mat
			return win_mat

		var mat_name: String = bm.resource_name.to_lower()
		var is_roof: bool = (
			mat_name.contains("roof")
			or mat_name.contains("tile")
			or mat_name.contains("slate")
			or mat_name.contains("shingle")
			or mat_name.contains("spire")
			or mat_name.contains("dome")
			or mat_name.contains("gable")
		)
		var is_timber: bool = (
			mat_name.contains("wood")
			or mat_name.contains("timber")
			or mat_name.contains("beam")
			or mat_name.contains("door")
			or mat_name.contains("shutter")
			or mat_name.contains("balcony")
			or mat_name.contains("railing")
		)

		var target_col: Color = _deepen_facade_color(bm.albedo_color, is_roof)
		var palette: Dictionary = _get_house_palette(house_kind)
		if not palette.is_empty():
			var pal_wall: Color = palette["wall"] as Color
			var pal_roof: Color = palette["roof"] as Color
			var inferred_roof: bool = is_roof or (not is_timber and bm.albedo_color.v < 0.62 and bm.albedo_color.s > 0.22)
			if inferred_roof:
				target_col = target_col.lerp(pal_roof, 0.85)
			elif is_timber:
				var warm_wood: Color = Color(0.44, 0.33, 0.26)
				target_col = target_col.lerp(warm_wood, 0.72)
			else:
				target_col = target_col.lerp(pal_wall, 0.85)

		var accent_col: Color = target_col.darkened(0.18)
		var upgraded: Material = _create_facade_shader_mat(
			target_col,
			accent_col,
			0.86,
			0.0,
			0.44,
			0.08,
			1.8
		)
		_facade_mat_cache[cache_key] = upgraded
		return upgraded

	return orig_mat


## Enforces matte non-glossy PBR (roughness >= 0.82, metallic = 0.0, specular = 0.14)
## on all non-metallic architectural surfaces of Landmarks & Venues, and applies
## pixar_window_glow.gdshader to every window/glass surface for chaotic lit windows.
func _harmonize_building_materials_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.material_override is BaseMaterial3D:
			var ov_bm: BaseMaterial3D = mi.material_override as BaseMaterial3D
			if _is_window_material(ov_bm):
				if _mat_chaotic_window != null:
					mi.material_override = _mat_chaotic_window
			else:
				var ov_name: String = ov_bm.resource_name.to_lower()
				var is_metal_ov: bool = (
					ov_bm.metallic >= 0.45
					or ov_name.contains("gold")
					or ov_name.contains("brass")
					or ov_name.contains("bronze")
					or ov_name.contains("metal")
				)
				if not is_metal_ov:
					var dup_ov_res: Resource = ov_bm.duplicate()
					if dup_ov_res is BaseMaterial3D:
						var dup_ov: BaseMaterial3D = dup_ov_res as BaseMaterial3D
						dup_ov.roughness = maxf(dup_ov.roughness, 0.82)
						dup_ov.metallic = 0.0
						dup_ov.metallic_specular = 0.14
						mi.material_override = dup_ov
		elif mi.mesh != null:
			var surf_count: int = mi.mesh.get_surface_count()
			for s_idx in range(surf_count):
				var cur_mat: Material = mi.get_surface_override_material(s_idx)
				if cur_mat == null:
					cur_mat = mi.mesh.surface_get_material(s_idx)
				if cur_mat is BaseMaterial3D:
					var bm: BaseMaterial3D = cur_mat as BaseMaterial3D
					if _is_window_material(bm):
						if _mat_chaotic_window != null:
							mi.set_surface_override_material(s_idx, _mat_chaotic_window)
					else:
						var s_name: String = bm.resource_name.to_lower()
						var is_metal_s: bool = (
							bm.metallic >= 0.45
							or s_name.contains("gold")
							or s_name.contains("brass")
							or s_name.contains("bronze")
							or s_name.contains("metal")
						)
						if not is_metal_s:
							var dup_res: Resource = bm.duplicate()
							if dup_res is BaseMaterial3D:
								var dup_bm: BaseMaterial3D = dup_res as BaseMaterial3D
								dup_bm.roughness = maxf(dup_bm.roughness, 0.82)
								dup_bm.metallic = 0.0
								dup_bm.metallic_specular = 0.14
								mi.set_surface_override_material(s_idx, dup_bm)
	for child in node.get_children():
		_harmonize_building_materials_recursive(child)


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
	_scene_pavilion = _safe_load_scene(MODEL_PAVILION_PATH)

	_scene_house_red = _safe_load_scene(PIXAR_HOUSE_RED_PATH)
	_scene_house_blue = _safe_load_scene(PIXAR_HOUSE_BLUE_PATH)
	_scene_house_ochre = _safe_load_scene(PIXAR_HOUSE_OCHRE_PATH)
	_scene_house_terracotta = _safe_load_scene(PIXAR_HOUSE_TERRACOTTA_PATH)
	_scene_house_cream_spire = _safe_load_scene(PIXAR_HOUSE_CREAM_SPIRE_PATH)
	_scene_cliff_rock = _safe_load_scene(PIXAR_CLIFF_ROCK_PATH)
	_scene_tree_blossom = _safe_load_scene(TREE_BLOSSOM_PATH)
	_scene_tree_willow = _safe_load_scene(TREE_WILLOW_PATH)
	_scene_tree_bonsai = _safe_load_scene(TREE_BONSAI_PATH)
	_scene_boat = _safe_load_scene(PIXAR_BOAT_PATH)
	_scene_prop_bench = _safe_load_scene(PROP_CITY_BENCH_PATH)
	_scene_prop_signpost = _safe_load_scene(PROP_CITY_SIGNPOST_PATH)
	_scene_prop_lamp = _safe_load_scene(PROP_STREET_LAMP_PATH)
	_scene_prop_flower_cart = _safe_load_scene(PROP_FLOWER_CART_PATH)
	_scene_prop_bulletin = _safe_load_scene(PROP_TOWN_BULLETIN_PATH)
	_scene_prop_ornate_railing = _safe_load_scene(PROP_ORNATE_RAILING_PATH)
	_scene_prop_railing_pillar = _safe_load_scene(PROP_RAILING_PILLAR_PATH)
	_scene_prop_cafe_bistro = _safe_load_scene(PROP_CAFE_BISTRO_PATH)
	_scene_prop_garden_urn = _safe_load_scene(PROP_GARDEN_URN_PATH)
	_scene_prop_grass_daisy = _safe_load_scene(PROP_GRASS_DAISY_PATH)
	_scene_sky_lantern = _safe_load_scene(PROP_SKY_LANTERN_PATH)


func _init_house_batches() -> void:
	_placed_inner_house_records.clear()
	_tree_blossom_xforms.clear()
	_tree_willow_gold_xforms.clear()
	_tree_willow_lavender_xforms.clear()
	_tree_bonsai_azure_xforms.clear()
	_park_bench_xforms.clear()
	_ornate_railing_xforms.clear()
	_railing_pillar_xforms.clear()
	_railing_pillar_positions.clear()
	_sky_lantern_batches.clear()
	_sky_lantern_instances.clear()
	_city_inner_house_batches = {
		"red_gable": [] as Array[Transform3D],
		"blue_balcony": [] as Array[Transform3D],
		"ochre_timber": [] as Array[Transform3D],
		"terracotta_terrace": [] as Array[Transform3D],
		"cream_spire": [] as Array[Transform3D],
	}
	_city_outer_house_batches = {
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
	if x >= -72.0 and x <= 72.0 and z >= -158.0 and z <= -52.0:
		return TIER_1_Y
	# Tier 1: West School of Souls Hill Terrace (Y = 3.2)
	if x >= -64.0 and x <= -26.0 and z >= -16.0 and z <= 32.0:
		return TIER_1_Y
	return TIER_0_Y


## Returns the exact top surface elevation (Y) for street props (lamps, flower carts,
## bulletins, signposts) so props seated on plazas, pocket parks, or Upper Overlook
## paving are NEVER buried 8.5cm below the paving disc!
func _get_prop_surface_y(x: float, z: float) -> float:
	var base_y: float = _get_city_ground_y(x, z)

	# 1. Check all 4 circular pocket parks (inner lawn +0.115, outer promenade +0.085)
	var pocket_parks: Array[Vector3] = [
		Vector3(-36.0, 44.0, 8.5),
		Vector3(36.0, 38.0, 8.5),
		Vector3(-41.0, -108.0, 8.5),
		Vector3(38.0, -108.0, 8.5),
	]
	for pk in pocket_parks:
		var pdx: float = x - pk.x
		var pdz: float = z - pk.y
		var dist_sq: float = pdx * pdx + pdz * pdz
		var lawn_r: float = pk.z - 2.3
		if dist_sq <= lawn_r * lawn_r:
			return base_y + PARK_LAWN_TOP_Y
		if dist_sq <= pk.z * pk.z:
			return base_y + PLAZA_TOP_Y

	# 2. Check all 12 circular ornate plazas (+0.085)
	var plazas: Array[Vector3] = [
		Vector3(0.0, 48.0, 12.5),
		Vector3(42.0, 10.0, 5.7),
		Vector3(30.0, 10.0, 5.5),
		Vector3(0.0, -13.2, 6.8),
		Vector3(0.0, -217.5, 9.8),
		Vector3(-35.2, 8.0, 7.4),
		Vector3(0.0, -78.0, 10.8),
		Vector3(-39.5, -78.0, 7.4),
		Vector3(42.0, -78.0, 7.6),
		Vector3(-34.0, -138.0, 10.5),
		Vector3(34.0, -138.0, 6.6),
		Vector3(0.0, -184.0, 7.8),
	]
	for pl in plazas:
		var ldx: float = x - pl.x
		var ldz: float = z - pl.y
		if ldx * ldx + ldz * ldz <= pl.z * pl.z:
			return base_y + PLAZA_TOP_Y

	# 3. Check Upper Overlook Terrace stone paving (+0.025)
	if x >= -23.7 and x <= 23.7 and z >= -197.7 and z <= -170.3:
		return TIER_2_Y + SIDE_STREET_TOP_Y

	return base_y


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

	# 3. Grand North Staircase Ramp (|X| <= 6.2, Z from -43.4 -> -55.0, Y: 0.0 -> 3.2)
	if absf(x) <= 6.2 and z <= -43.4 and z >= -55.0:
		var nt: float = clampf((-43.4 - z) / 11.6, 0.0, 1.0)
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
		-half_w, half_w, canal_z_south, z_max, 120, 76, true, false
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

			# 1. Sculpted emerald hill underneath West School Terrace (Y = 2.85 cleanly below 3.2 deck & inside walls)
			if carve_lake:
				var wx_in: float = _smooth01((-30.8 - vx) / 4.5) * _smooth01((vx + 76.0) / 14.0)
				var wz_in: float = _smooth01((vz + 13.0) / 5.0) * _smooth01((29.0 - vz) / 3.5)
				var west_hill: float = (TIER_1_Y - 0.35) * wx_in * wz_in
				vy = maxf(vy, west_hill)

			# 2. Sculpted emerald terrace rise underneath North Mid Tier (Z in [-158..-52], flush Y = 3.20)
			if carve_palace:
				var nz_south: float = _smooth01((-52.5 - vz) / 3.8)
				var nz_north: float = _smooth01((vz + 174.0) / 16.0)
				var nx_span: float = _smooth01((86.0 - absf(vx)) / 14.0)
				var north_terrace_hill: float = TIER_1_Y * nz_south * nz_north * nx_span
				# Keep the Grand Staircase cutout (|x| < 6.8, z > -55.5) clean below the steps
				if absf(vx) < 7.0 and vz > -55.5:
					north_terrace_hill = 0.0
				vy = maxf(vy, north_terrace_hill)

			# 3. Gentle Pixar rolling hills around the outer valley amphitheater flanks
			var flank_x: float = _smooth01((absf(vx) - 68.0) / 38.0)
			var flank_south: float = _smooth01((vz - 74.0) / 36.0)
			var flank_mask: float = maxf(flank_x, flank_south)
			if flank_mask > 0.001:
				var wave: float = 0.55 + 0.30 * sin(vx * 0.045 + vz * 0.032) + 0.15 * cos(vx * 0.09 - vz * 0.06)
				# Stay flat near the Shining Canal channel (Z in [-46, -18])
				var canal_clear: float = _smooth01((absf(vz - CANAL_Z) - 10.0) / 12.0)
				var outer_hill: float = flank_mask * canal_clear * (3.2 + 5.8 * wave)
				vy = maxf(vy, outer_hill)

			# 4. Soft organic meadow undulation ONLY in off-road grassy margins (never on roads/plazas/parks)
			var on_road_or_plaza: bool = (
				(absf(vx) < 16.0 and vz >= -232.0 and vz <= 64.0)
				or (absf(vz - 9.0) < 12.0 and absf(vx) < 58.0)
				or (vx < 0.0 and absf(vz - 44.0) < 11.0 and vx > -62.0)
				or (vx > 0.0 and absf(vz - 38.0) < 11.0 and vx < 62.0)
				or (vx >= -26.0 and vx <= 0.0 and absf(vz - 18.0) < 4.5)
				or (absf(vx - 28.0) < 6.5 and vz >= 8.0 and vz <= 44.0)
				or (absf(vx + 23.55) < 8.0 and vz >= 16.0 and vz <= 46.0)
				or (vx >= -68.0 and vx <= -22.0 and vz >= -20.0 and vz <= 36.0)
				or (absf(vx) < 76.0 and vz >= -162.0 and vz <= -48.0)
				or (absf(vz + 78.0) < 12.0 and absf(vx) < 62.0)
				or (absf(vz + 138.0) < 12.0 and absf(vx) < 52.0)
				or (absf(vx + 41.0) < 11.0 and vz >= -142.0 and vz <= -74.0)
				or (absf(vx - 38.0) < 11.0 and vz >= -142.0 and vz <= -74.0)
				or (absf(vz - CANAL_Z) < 14.0)
				or (absf(vx) < 28.0 and vz >= -216.0 and vz <= -154.0)
			)
			if not on_road_or_plaza and flank_mask < 0.2:
				var gentle_ripple: float = 0.24 * sin(vx * 0.085) * cos(vz * 0.085)
				vy = maxf(vy, vy + gentle_ripple * 0.5)

			# 5. Carve Lake of Silence basin (54, 12), R = 13.0 — smooth bank plunging right under stone curb
			if carve_lake:
				var ldx: float = vx - LAKE_CENTER.x
				var ldz: float = vz - LAKE_CENTER.z
				var ldist: float = sqrt(ldx * ldx + ldz * ldz)
				if ldist < LAKE_RADIUS + 4.0:
					var shore_flat: float = _smooth01((ldist - (LAKE_RADIUS + 0.55)) / 3.45)
					vy *= shore_flat
				if ldist < LAKE_RADIUS + 0.50:
					var bank_t: float = _smooth01((LAKE_RADIUS + 0.50 - ldist) / 1.35)
					var center_t: float = clampf(1.0 - ldist / LAKE_RADIUS, 0.0, 1.0)
					vy = minf(vy, -0.78 * bank_t - 0.58 * center_t)

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

	# Center around (0.0, -90.0) and push both rings well past outermost terraces (X = +/-158..168, Z = -190..+137)
	var ring_center_z: float = -90.0
	var inner_r_min: float = 215.0
	var inner_base_r: float = 44.0
	var inner_radius_x: float = maxf(inner_r_min + inner_base_r * 1.48, 280.0)
	var inner_radius_z: float = maxf(260.0 + inner_base_r * 2.38, 365.0)

	# Inner Ring: lush emerald-azure rolling Pixar valley hills
	var hills_mesh: ArrayMesh = _create_mountain_ring_mesh(
		38,
		inner_radius_x,
		inner_radius_z,
		ring_center_z,
		24.0,
		42.0,
		inner_base_r,
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
	var outer_r_min: float = 290.0
	var outer_base_r: float = 64.0
	var outer_radius_x: float = maxf(outer_r_min + outer_base_r * 1.06, 358.0)
	var outer_radius_z: float = maxf(340.0 + outer_base_r * 1.64, 445.0)

	var peaks_mesh: ArrayMesh = _create_mountain_ring_mesh(
		44,
		outer_radius_x,
		outer_radius_z,
		ring_center_z,
		54.0,
		106.0,
		outer_base_r,
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
	center_z: float,
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
		var radial_jitter: float = rng.randf_range(0.97, 1.07)
		var cx: float = cos(angle) * radius_x * radial_jitter
		var cz: float = center_z + sin(angle) * radius_z * radial_jitter
		var h: float = rng.randf_range(min_height, max_height)
		var r_base: float = base_radius * rng.randf_range(0.85, 1.15)
		var r_mid: float = r_base * 0.48
		var h_mid: float = h * 0.56
		var apex_offset: Vector3 = Vector3(rng.randf_range(-6.0, 6.0), h, rng.randf_range(-6.0, 6.0))
		var apex: Vector3 = Vector3(cx, -1.0, cz) + apex_offset

		var ring_base: Array[Vector3] = []
		var ring_mid: Array[Vector3] = []
		var rot_offset: float = rng.randf_range(0.0, TAU)
		for s in range(sides):
			var a: float = rot_offset + (TAU * float(s)) / float(sides)
			var w: float = rng.randf_range(0.85, 1.12)
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

	for idx in range(quay_z_positions.size()):
		var qz: float = quay_z_positions[idx]
		var tag: String = "South" if idx == 0 else "North"
		var seg_len: float = (CANAL_LENGTH * 0.5) - 6.0
		for side_val in [-1.0, 1.0]:
			var side: float = float(side_val)
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

			# Warm coping trim along quay top (top surface at Y = 0.28)
			var trim_inst: MeshInstance3D = MeshInstance3D.new()
			trim_inst.name = "CanalQuayTrim_%s_%s" % [tag, "W" if side < 0.0 else "E"]
			var trim_box: BoxMesh = BoxMesh.new()
			trim_box.size = Vector3(seg_len, 0.08, 1.08)
			trim_inst.mesh = trim_box
			trim_inst.position = Vector3(cx, 0.24, qz)
			trim_inst.material_override = _mat_marble_wall
			trim_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			water_root.add_child(trim_inst)

			# Sculpted Baroque balustrade along canal embankment (|X| in [6.5..62.0], seated on quay coping)
			var rail_start_x: float = -62.0 if side < 0.0 else 6.5
			var rail_end_x: float = -6.5 if side < 0.0 else 62.0
			_append_ornate_balustrade_run(
				Vector3(rail_start_x, 0.26, qz),
				Vector3(rail_end_x, 0.26, qz)
			)

	# --- Lake of Silence in Quiet Lakes Park (54.0, -0.18, 12.0), circular radius 13m ---
	var lake_water: MeshInstance3D = MeshInstance3D.new()
	lake_water.name = "LakeOfSilenceWater"
	var lw_mesh: CylinderMesh = CylinderMesh.new()
	lw_mesh.top_radius = LAKE_RADIUS + 0.12
	lw_mesh.bottom_radius = LAKE_RADIUS + 0.12
	lw_mesh.height = 0.08
	lw_mesh.radial_segments = 64
	lw_mesh.rings = 1
	lake_water.mesh = lw_mesh
	lake_water.position = Vector3(LAKE_CENTER.x, LAKE_CENTER.y - 0.04, LAKE_CENTER.z)
	lake_water.material_override = _mat_water_lake
	lake_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water_root.add_child(lake_water)

	# Stone curb ring framing the Lake of Silence (seated cleanly on Y = 0.0)
	var lake_curb: MeshInstance3D = MeshInstance3D.new()
	lake_curb.name = "LakeOfSilenceCurb"
	var curb_torus: TorusMesh = TorusMesh.new()
	curb_torus.inner_radius = LAKE_RADIUS - 0.55
	curb_torus.outer_radius = LAKE_RADIUS + 0.55
	curb_torus.rings = 64
	curb_torus.ring_segments = 16
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
			"pos": Vector3(-82.0, 0.0, -31.0),
			"yaw": PI * 0.48, # pours +X/+Z from higher western canyon cliff
			"width": 7.6,
			"height": 16.5,
			"arch_out": 3.4,
			"water_y": CANAL_WATER_Y,
		},
		{
			"name": "Waterfall_LakeOfSilence",
			"pos": Vector3(68.0, 0.0, 12.0),
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
	splash_cyl.top_radius = width * 0.40
	splash_cyl.bottom_radius = width * 0.45
	splash_cyl.height = 0.08
	splash_cyl.radial_segments = 36
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
	puff_mesh.radial_segments = 18
	puff_mesh.rings = 12
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
			_set_shadow_casting_recursive(model_node, GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
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
		Vector3(37.9, 0.36, 47.9),
		Vector3(-45.0, TIER_1_Y - 0.18, 8.0),
		_mat_terrace_stone
	)
	west_deck.name = "WestSchoolTerraceDeck"
	west_deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Arched stone retaining walls framing West School Terrace (leaving 9.4m stair opening Z in [3.3..12.7])
	_add_arched_retaining_wall(topo_root, "WestSchoolWall_EastNorth", Vector3(-26.0, 0.0, -16.0), Vector3(-26.0, 0.0, 3.3), TIER_1_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "WestSchoolWall_EastSouth", Vector3(-26.0, 0.0, 12.7), Vector3(-26.0, 0.0, 32.0), TIER_1_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "WestSchoolWall_South", Vector3(-64.0, 0.0, 32.0), Vector3(-26.55, 0.0, 32.0), TIER_1_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "WestSchoolWall_North", Vector3(-26.55, 0.0, -16.0), Vector3(-64.0, 0.0, -16.0), TIER_1_Y, 1.0)

	# Scenic stone balustrades along West School Terrace drop-offs
	_add_terrace_balustrade(topo_root, "WestSchoolRail_EastNorth", Vector3(-26.2, TIER_1_Y, -15.6), Vector3(-26.2, TIER_1_Y, 3.3))
	_add_terrace_balustrade(topo_root, "WestSchoolRail_EastSouth", Vector3(-26.2, TIER_1_Y, 12.7), Vector3(-26.2, TIER_1_Y, 31.6))
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
	# 2. NORTH MID TERRACE (Tier 1: Y = 3.2, X in [-72..+72], Z in [-158..-52])
	# -------------------------------------------------------------------------
	# 3-piece flush walkable floor collision leaving exact notch X in [-6..+6], Z in [-55..-52] for stairs
	_add_terrace_floor_box(col_body, "NorthMidTerraceCol_Main", Vector3(0.0, TIER_1_Y, -106.5), Vector3(144.0, TIER_1_Y + 0.6, 103.0))
	_add_terrace_floor_box(col_body, "NorthMidTerraceCol_SW", Vector3(-36.0, TIER_1_Y, -53.5), Vector3(60.0, TIER_1_Y + 0.6, 3.0))
	_add_terrace_floor_box(col_body, "NorthMidTerraceCol_SE", Vector3(36.0, TIER_1_Y, -53.5), Vector3(60.0, TIER_1_Y + 0.6, 3.0))

	# Visual terrace coping apron along Z = -52 edge (west & east of the Grand North Staircase, top at TIER_1_Y + 0.015)
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		var apron: MeshInstance3D = _add_box_part(
			topo_root,
			Vector3(59.2, 0.34, 4.2),
			Vector3(side * 36.4, TIER_1_Y - 0.155, -54.1),
			_mat_terrace_stone
		)
		apron.name = "NorthApron_%s" % ("W" if side < 0.0 else "E")
		apron.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Grand Arched Stone Retaining Wall along Z = -52.0 (facing south toward Canal & Bridge)
	_add_arched_retaining_wall(topo_root, "NorthTerraceWall_West", Vector3(-72.0, 0.0, -52.0), Vector3(-6.7, 0.0, -52.0), TIER_1_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "NorthTerraceWall_East", Vector3(6.7, 0.0, -52.0), Vector3(72.0, 0.0, -52.0), TIER_1_Y, 1.0)

	# Balustrades along North Mid Terrace South Rim (Z = -52.2) & North Rim (Z = -157.8)
	_add_terrace_balustrade(topo_root, "NorthTerraceRail_SouthW", Vector3(-62.0, TIER_1_Y, -52.2), Vector3(-6.7, TIER_1_Y, -52.2))
	_add_terrace_balustrade(topo_root, "NorthTerraceRail_SouthE", Vector3(6.7, TIER_1_Y, -52.2), Vector3(62.0, TIER_1_Y, -52.2))
	_add_terrace_balustrade(topo_root, "NorthTerraceRail_NorthW", Vector3(-62.0, TIER_1_Y, -157.8), Vector3(-7.7, TIER_1_Y, -157.8))
	_add_terrace_balustrade(topo_root, "NorthTerraceRail_NorthE", Vector3(7.7, TIER_1_Y, -157.8), Vector3(62.0, TIER_1_Y, -157.8))

	# Grand North Stone Staircase Ramp: X = 0.0, width 12.0m, Z = -43.4 (Y=0.0) -> Z = -55.0 (Y=3.2)
	_build_stone_staircase_ramp(
		topo_root,
		"Staircase_GrandNorth",
		Vector3(0.0, TIER_0_Y, -43.4),
		Vector3(0.0, TIER_1_Y, -55.0),
		12.0,
		20
	)

	# -------------------------------------------------------------------------
	# 3. UPPER OVERLOOK TERRACE (Tier 2: Y = 5.6, X in [-24..+24], Z in [-198..-170])
	#    + Ascent Staircase (Z = -158 -> -170) & Imperial Descent (Z = -198 -> -212)
	# -------------------------------------------------------------------------
	_add_terrace_floor_box(col_body, "UpperOverlookTerraceCol", Vector3(0.0, TIER_2_Y, -184.0), Vector3(48.0, TIER_2_Y + 0.8, 28.0))

	# Solid monumental masonry podium beneath the Upper Overlook Terrace (inset 0.05m all sides vs wall bodies)
	var overlook_podium: MeshInstance3D = _add_box_part(
		topo_root,
		Vector3(47.9, TIER_2_Y + 0.4, 27.9),
		Vector3(0.0, (TIER_2_Y - 0.4) * 0.5, -184.0),
		_mat_terrace_stone
	)
	overlook_podium.name = "UpperOverlookPodium"
	overlook_podium.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Paved terrace floor top on Upper Overlook (top strictly at TIER_2_Y + SIDE_STREET_TOP_Y = +0.025)
	var overlook_floor: MeshInstance3D = _add_box_part(
		topo_root,
		Vector3(47.4, 0.08, 27.4),
		Vector3(0.0, TIER_2_Y + SIDE_STREET_TOP_Y - 0.04, -184.0),
		_mat_marble_road
	)
	overlook_floor.name = "UpperOverlookPaving"
	overlook_floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Arched stone retaining walls wrapping the Upper Overlook Terrace (South, West, East, North wings)
	_add_arched_retaining_wall(topo_root, "OverlookWall_SouthW", Vector3(-23.45, 0.0, -170.0), Vector3(-7.7, 0.0, -170.0), TIER_2_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "OverlookWall_SouthE", Vector3(7.7, 0.0, -170.0), Vector3(23.45, 0.0, -170.0), TIER_2_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "OverlookWall_West", Vector3(-24.0, 0.0, -198.0), Vector3(-24.0, 0.0, -170.0), TIER_2_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "OverlookWall_East", Vector3(24.0, 0.0, -170.0), Vector3(24.0, 0.0, -198.0), TIER_2_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "OverlookWall_NorthW", Vector3(-7.7, 0.0, -198.0), Vector3(-23.45, 0.0, -198.0), TIER_2_Y, 1.0)
	_add_arched_retaining_wall(topo_root, "OverlookWall_NorthE", Vector3(23.45, 0.0, -198.0), Vector3(7.7, 0.0, -198.0), TIER_2_Y, 1.0)

	# Scenic golden-topped viewing balustrades around Upper Overlook Terrace
	_add_terrace_balustrade(topo_root, "OverlookRail_West", Vector3(-23.7, TIER_2_Y, -197.7), Vector3(-23.7, TIER_2_Y, -170.3))
	_add_terrace_balustrade(topo_root, "OverlookRail_East", Vector3(23.7, TIER_2_Y, -197.7), Vector3(23.7, TIER_2_Y, -170.3))
	_add_terrace_balustrade(topo_root, "OverlookRail_SouthW", Vector3(-23.7, TIER_2_Y, -170.3), Vector3(-7.7, TIER_2_Y, -170.3))
	_add_terrace_balustrade(topo_root, "OverlookRail_SouthE", Vector3(7.7, TIER_2_Y, -170.3), Vector3(23.7, TIER_2_Y, -170.3))
	_add_terrace_balustrade(topo_root, "OverlookRail_NorthW", Vector3(-23.7, TIER_2_Y, -197.7), Vector3(-7.7, TIER_2_Y, -197.7))
	_add_terrace_balustrade(topo_root, "OverlookRail_NorthE", Vector3(7.7, TIER_2_Y, -197.7), Vector3(23.7, TIER_2_Y, -197.7))

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

	# Emit ALL sculpted Baroque railings & lantern finial pillars (Canal + 14 Terrace Runs + 4 Staircases)
	_spawn_scene_multimesh_batch(
		topo_root,
		"CityOrnateRailings_MM",
		_scene_prop_ornate_railing,
		_ornate_railing_xforms,
		_create_fallback_ornate_railing_parts(),
		null,
		false,
		true
	)
	_spawn_scene_multimesh_batch(
		topo_root,
		"CityRailingPillars_MM",
		_scene_prop_railing_pillar,
		_railing_pillar_xforms,
		_create_fallback_railing_pillar_parts(),
		null,
		false,
		true
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

	# Main stone retaining wall body (grounded to Y = -0.6, top tucked 0.02m cleanly under coping)
	var body_h: float = wall_height + 0.58
	var body_mi: MeshInstance3D = _add_box_part(
		holder,
		Vector3(thickness, body_h, length),
		Vector3(0.0, (wall_height - 0.02) - body_h * 0.5, 0.0),
		_mat_terrace_stone
	)
	body_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Tiny 5mm Y-offset on E-W walls so perpendicular corner copings/strips/piers never coplanar Z-fight
	var ew_y_off: float = -0.005 if absf(diff.x) > absf(diff.z) else 0.0

	# Golden-limestone top cornice coping
	var coping: MeshInstance3D = _add_box_part(
		holder,
		Vector3(thickness + 0.36, 0.24, length + 0.16),
		Vector3(0.0, wall_height - 0.08 + ew_y_off, 0.0),
		_mat_stone_quay
	)
	coping.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var gold_strip: MeshInstance3D = _add_box_part(
		holder,
		Vector3(thickness + 0.44, 0.08, length + 0.18),
		Vector3(0.0, wall_height + 0.06 + ew_y_off, 0.0),
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
			Vector3(0.0, wall_height * 0.5 - 0.1 + ew_y_off, z_p)
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
	_parent: Node3D,
	_rail_name: String,
	start_pos: Vector3,
	end_pos: Vector3
) -> void:
	_append_ornate_balustrade_run(start_pos, end_pos)


func _append_railing_pillar_unique(world_pos: Vector3, yaw_rad: float) -> void:
	for existing in _railing_pillar_positions:
		if existing.distance_squared_to(world_pos) < 0.2025: # 0.45m dedup radius for shared corners
			return
	_railing_pillar_positions.append(world_pos)
	_railing_pillar_xforms.append(Transform3D(
		Basis.from_euler(Vector3(0.0, yaw_rad, 0.0)),
		world_pos
	))


func _append_ornate_balustrade_run(start_pos: Vector3, end_pos: Vector3) -> void:
	var diff: Vector3 = end_pos - start_pos
	var length: float = Vector2(diff.x, diff.z).length()
	if length < 0.5:
		return

	# prop_ornate_railing.glb is 3.00m wide along local X ([-1.50..+1.50]), Y_min = 0.0
	var yaw: float = atan2(-diff.z, diff.x)
	var dir: Vector3 = Vector3(diff.x / length, 0.0, diff.z / length)

	var pillar_spans: int = maxi(1, int(round(length / 12.0)))
	var span_len: float = length / float(pillar_spans)

	for sp_idx in range(pillar_spans + 1):
		var p_pos: Vector3 = start_pos + dir * (float(sp_idx) * span_len)
		_append_railing_pillar_unique(p_pos, yaw)

	for sp_idx in range(pillar_spans):
		var span_start: Vector3 = start_pos + dir * (float(sp_idx) * span_len)
		# Tuck 5cm into each 0.64m pillar so there is zero seam or overlap
		var usable_span: float = maxf(0.4, span_len - 0.54)
		var seg_count: int = maxi(1, int(round(usable_span / 3.0)))
		var seg_len: float = usable_span / float(seg_count)
		var seg_scale_x: float = seg_len / 3.0
		var rail_rot: Basis = Basis.from_euler(Vector3(0.0, yaw, 0.0)) * Basis.from_scale(Vector3(seg_scale_x, 1.0, 1.0))
		for k in range(seg_count):
			var along: float = 0.27 + (float(k) + 0.5) * seg_len
			var r_pos: Vector3 = span_start + dir * along
			_ornate_railing_xforms.append(Transform3D(rail_rot, r_pos))


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

		# Sculpted Baroque lantern finial pillars at exact bottom & top outer corners
		var stair_rot: Basis = Basis.from_euler(Vector3(0.0, yaw, 0.0))
		for end_t_val in [0.0, 1.0]:
			var end_t: float = float(end_t_val)
			var pz: float = lerpf(-run * 0.5, run * 0.5, end_t)
			var py: float = lerpf(-rise * 0.5, rise * 0.5, end_t)
			var world_corner: Vector3 = mid + stair_rot * Vector3(sx, py, pz)
			_append_railing_pillar_unique(world_corner, yaw)


# ===========================================================================
# 5. ROADS, ORNATE CIRCULAR PLAZAS & POCKET PARKS (STRICT ELEVATION LADDER!)
#    SIDE_STREET_TOP_Y = +0.025 < ROAD_TOP_Y = +0.055 < PLAZA_TOP_Y = +0.085 < PARK_LAWN_TOP_Y = +0.115
# ===========================================================================

func _build_roads_and_plazas() -> void:
	var net_root: Node3D = Node3D.new()
	net_root.name = "RoadsAndPlazas"
	add_child(net_root)

	# --- TIER 0 (Y = 0.0) ROADS ---
	_add_marble_road(net_root, "MainBoulevard_South", Vector3(0.0, TIER_0_Y, 56.0), Vector3(0.0, TIER_0_Y, -20.75), 10.0, ROAD_TOP_Y)
	_add_marble_road(net_root, "Street_SchoolApproach", Vector3(0.0, TIER_0_Y, 8.0), Vector3(-14.2, TIER_0_Y, 8.0), 8.0, SIDE_STREET_TOP_Y)
	_add_marble_road(net_root, "Street_QuietLakesPark", Vector3(0.0, TIER_0_Y, 10.0), Vector3(44.0, TIER_0_Y, 10.0), 7.0, SIDE_STREET_TOP_Y)
	_add_marble_road(net_root, "ImperialForecourtRoad", Vector3(0.0, TIER_0_Y, -211.8), Vector3(0.0, TIER_0_Y, -227.76), 14.0, ROAD_TOP_Y)

	# --- TIER 1 (Y = 3.2) ROADS ---
	_add_marble_road(net_root, "Street_SchoolUpper", Vector3(-25.8, TIER_1_Y, 8.0), Vector3(-35.2, TIER_1_Y, 8.0), 8.0, SIDE_STREET_TOP_Y)
	_add_marble_road(net_root, "MainBoulevard_North", Vector3(0.0, TIER_1_Y, -54.8), Vector3(0.0, TIER_1_Y, -158.2), 12.0, ROAD_TOP_Y)
	_add_marble_road(net_root, "Street_OrionLibrary", Vector3(0.0, TIER_1_Y, -78.0), Vector3(-39.5, TIER_1_Y, -78.0), 7.5, SIDE_STREET_TOP_Y)
	_add_marble_road(net_root, "Street_KronosTower", Vector3(0.0, TIER_1_Y, -78.0), Vector3(42.0, TIER_1_Y, -78.0), 7.5, SIDE_STREET_TOP_Y)
	_add_marble_road(net_root, "Street_LanternGarden", Vector3(0.0, TIER_1_Y, -138.0), Vector3(-34.0, TIER_1_Y, -138.0), 7.5, SIDE_STREET_TOP_Y)
	_add_marble_road(net_root, "Street_MiraSanctuary", Vector3(0.0, TIER_1_Y, -138.0), Vector3(34.0, TIER_1_Y, -138.0), 7.5, SIDE_STREET_TOP_Y)

	# --- TIER 2 (Y = 5.6) UPPER OVERLOOK PROMENADE ---
	_add_marble_road(net_root, "OverlookPromenade", Vector3(0.0, TIER_2_Y, -170.0), Vector3(0.0, TIER_2_Y, -198.0), 14.0, ROAD_TOP_Y)

	# --- CIRCULAR ORNATE PLAZAS ACROSS ALL 3 TIERS (PLAZA_TOP_Y = +0.085) ---
	# Tier 0 Plazas
	_add_marble_plaza(net_root, "Plaza_Awakening", Vector3(0.0, TIER_0_Y, 48.0), 12.5)
	_add_marble_plaza(net_root, "Plaza_QuietLakesPier", Vector3(42.0, TIER_0_Y, 10.0), 5.7)
	_add_marble_plaza(net_root, "Plaza_QuietLakesEntry", Vector3(30.0, TIER_0_Y, 10.0), 5.5)
	_add_marble_plaza(net_root, "Plaza_BridgeSouth", Vector3(0.0, TIER_0_Y, -13.2), 6.8)
	_add_marble_plaza(net_root, "Plaza_ImperialForecourt", Vector3(0.0, TIER_0_Y, -217.5), 9.8)

	# Tier 1 Plazas (Y = 3.2 — cleanly clear of all 4 1.28x landmark footprints!)
	_add_marble_plaza(net_root, "Plaza_SchoolOfSouls", Vector3(-35.2, TIER_1_Y, 8.0), 7.4)
	_add_marble_plaza(net_root, "Plaza_AkashicOrrery", Vector3(0.0, TIER_1_Y, -78.0), 10.8)
	_add_marble_plaza(net_root, "Plaza_OrionLibrary", Vector3(-39.5, TIER_1_Y, -78.0), 7.4)
	_add_marble_plaza(net_root, "Plaza_KronosTower", Vector3(42.0, TIER_1_Y, -78.0), 7.6)
	_add_marble_plaza(net_root, "Plaza_LanternGarden", Vector3(-34.0, TIER_1_Y, -138.0), 10.5)
	_add_marble_plaza(net_root, "Plaza_MiraSanctuary", Vector3(34.0, TIER_1_Y, -138.0), 6.6)

	# Tier 2 Plaza (Y = 5.6)
	_add_marble_plaza(net_root, "Plaza_UpperOverlook", Vector3(0.0, TIER_2_Y, -184.0), 7.8)

	# --- TIER 0 (Y = 0.0) SIDE STREETS (+0.025) & ALLEYS (+0.015, zero curb Z-fighting!) ---
	_add_marble_road(net_root, "SideStreet_SouthWest", Vector3(-6.0, TIER_0_Y, 44.0), Vector3(-52.0, TIER_0_Y, 44.0), 5.4, SIDE_STREET_TOP_Y)
	_add_marble_road(net_root, "Alley_SouthWest", Vector3(-23.55, TIER_0_Y, 41.3), Vector3(-23.55, TIER_0_Y, 19.8), 3.0, SIDE_ALLEY_TOP_Y)
	_add_marble_road(net_root, "Alley_SouthWest_Cross", Vector3(-25.02, TIER_0_Y, 18.0), Vector3(-5.0, TIER_0_Y, 18.0), 3.6, SIDE_STREET_TOP_Y)
	_add_marble_road(net_root, "SideStreet_SouthEast", Vector3(6.0, TIER_0_Y, 38.0), Vector3(52.0, TIER_0_Y, 38.0), 5.4, SIDE_STREET_TOP_Y)
	_add_marble_road(net_root, "Alley_SouthEast", Vector3(28.0, TIER_0_Y, 35.3), Vector3(28.0, TIER_0_Y, 13.5), 5.4, SIDE_ALLEY_TOP_Y)

	# --- TIER 1 (Y = 3.2) QUARTER ALLEYS (SIDE_ALLEY_TOP_Y = +0.015, strictly clear of cross streets!) ---
	_add_marble_road(net_root, "Alley_NorthWest_Orion", Vector3(-41.0, TIER_1_Y, -85.6), Vector3(-41.0, TIER_1_Y, -134.0), 5.4, SIDE_ALLEY_TOP_Y)
	_add_marble_road(net_root, "Alley_NorthEast_Kronos", Vector3(37.0, TIER_1_Y, -84.0), Vector3(37.0, TIER_1_Y, -132.4), 5.4, SIDE_ALLEY_TOP_Y)

	# --- 4 CIRCULAR POCKET PARKS (R = 8.5m, paving +0.085, inner lawn +0.115, benches & fairytale trees) ---
	_add_pocket_park(net_root, "PocketPark_SakuraAlley", Vector3(-36.0, TIER_0_Y, 44.0), 8.5, "blossom")
	_add_pocket_park(net_root, "PocketPark_GoldenWillows", Vector3(36.0, TIER_0_Y, 38.0), 8.5, "willow_gold")
	_add_pocket_park(net_root, "PocketPark_OrionCourtyard", Vector3(-41.0, TIER_1_Y, -108.0), 8.5, "bonsai_azure")
	_add_pocket_park(net_root, "PocketPark_TimeCourtyard", Vector3(38.0, TIER_1_Y, -108.0), 8.5, "willow_lavender")


func _add_pocket_park(
	parent: Node3D,
	park_name: String,
	center: Vector3,
	radius: float,
	tree_theme: String
) -> void:
	var holder: Node3D = Node3D.new()
	holder.name = park_name
	holder.position = center
	parent.add_child(holder)

	# 1. Outer stone walking promenade disc (R = radius, top strictly at center.y + PLAZA_TOP_Y = +0.085)
	var walk_disc: MeshInstance3D = MeshInstance3D.new()
	walk_disc.mesh = _create_radial_plaza_disc_mesh(radius, 0.06, 64)
	walk_disc.position = Vector3(0.0, PLAZA_TOP_Y - 0.06, 0.0)
	walk_disc.material_override = _mat_marble_plaza
	walk_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(walk_disc)

	# 2. Inner lush green circular garden lawn (R = radius - 2.3m, top strictly at center.y + PARK_LAWN_TOP_Y = +0.115)
	var lawn_r: float = radius - 2.3
	var lawn_disc: MeshInstance3D = MeshInstance3D.new()
	var lawn_cyl: CylinderMesh = CylinderMesh.new()
	lawn_cyl.top_radius = lawn_r
	lawn_cyl.bottom_radius = lawn_r + 0.14
	lawn_cyl.height = 0.06
	lawn_cyl.radial_segments = 64
	lawn_disc.mesh = lawn_cyl
	lawn_disc.position = Vector3(0.0, PARK_LAWN_TOP_Y - 0.03, 0.0)
	lawn_disc.material_override = _mat_park_lawn
	lawn_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(lawn_disc)

	# 3. Golden outer curb ring (at PLAZA_TOP_Y) + delicate inner lawn curb (at PARK_LAWN_TOP_Y)
	var rim_outer: MeshInstance3D = MeshInstance3D.new()
	var torus_outer: TorusMesh = TorusMesh.new()
	torus_outer.inner_radius = radius - 0.14
	torus_outer.outer_radius = radius + 0.14
	torus_outer.rings = 64
	torus_outer.ring_segments = 16
	rim_outer.mesh = torus_outer
	rim_outer.position = Vector3(0.0, PLAZA_TOP_Y + 0.008, 0.0)
	rim_outer.scale = Vector3(1.0, 0.24, 1.0)
	rim_outer.material_override = _mat_gold_trim
	rim_outer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(rim_outer)

	var rim_inner: MeshInstance3D = MeshInstance3D.new()
	var torus_inner: TorusMesh = TorusMesh.new()
	torus_inner.inner_radius = lawn_r - 0.12
	torus_inner.outer_radius = lawn_r + 0.12
	torus_inner.rings = 64
	torus_inner.ring_segments = 16
	rim_inner.mesh = torus_inner
	rim_inner.position = Vector3(0.0, PARK_LAWN_TOP_Y + 0.006, 0.0)
	rim_inner.scale = Vector3(1.0, 0.24, 1.0)
	rim_inner.material_override = _mat_gold_trim
	rim_inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(rim_inner)

	# 4. Sculpted park benches along the lawn edge (grounded at center.y + PLAZA_TOP_Y, facing inward)
	var bench_r: float = lawn_r + 0.82
	for i in range(6):
		var ang: float = (TAU * float(i)) / 6.0 + PI / 6.0
		var bx: float = center.x + cos(ang) * bench_r
		var bz: float = center.z + sin(ang) * bench_r
		# Skip positions that overlap West School Terrace wall or Grand Mall / Soul Gym back walls
		if bx < -25.2 and bz < 33.4 and center.y < 1.0:
			continue
		if bx > -30.4 and absf(bz + 108.0) < 10.2 and center.x < 0.0 and center.y > 1.0:
			continue
		if bx < 26.8 and absf(bz + 108.0) < 7.2 and center.x > 0.0 and center.y > 1.0:
			continue
		var face_center: float = atan2(center.x - bx, center.z - bz)
		_park_bench_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, face_center, 0.0)),
			Vector3(bx, center.y + PLAZA_TOP_Y, bz)
		))

	# 5. Sculptural Fairytale Hero Trees in the circular garden lawn
	var tree_offsets: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.0),
		Vector3(-2.6, 0.0, 2.2),
		Vector3(2.8, 0.0, 1.8),
	]
	var tree_scales: Array[float] = [1.22, 0.88, 0.92]
	for t_i in range(tree_offsets.size()):
		var tx: float = center.x + tree_offsets[t_i].x
		var tz: float = center.z + tree_offsets[t_i].z
		if tx < -25.2 and tz < 33.8 and center.y < 1.0:
			continue
		if tx > -30.8 and absf(tz + 108.0) < 10.2 and center.x < 0.0 and center.y > 1.0:
			continue
		var sc: float = tree_scales[t_i]
		var xf: Transform3D = Transform3D(
			Basis.from_euler(Vector3(0.0, float(t_i) * 2.1, 0.0)).scaled(Vector3(sc, sc, sc)),
			Vector3(tx, center.y + PARK_LAWN_TOP_Y - 0.02, tz)
		)
		if tree_theme == "blossom":
			_tree_blossom_xforms.append(xf)
		elif tree_theme == "willow_gold":
			_tree_willow_gold_xforms.append(xf)
		elif tree_theme == "bonsai_azure":
			if t_i == 1:
				_tree_blossom_xforms.append(xf)
			else:
				_tree_bonsai_azure_xforms.append(xf)
		else:
			if t_i == 2:
				_tree_willow_gold_xforms.append(xf)
			else:
				_tree_willow_lavender_xforms.append(xf)


func _add_marble_road(
	parent: Node3D,
	road_name: String,
	start_pos: Vector3,
	end_pos: Vector3,
	width: float,
	top_y: float = ROAD_TOP_Y
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

	# Road slab: height 0.04 -> top face strictly at mid.y + top_y (0.025 side streets, 0.055 boulevards)
	var slab: MeshInstance3D = MeshInstance3D.new()
	var slab_box: BoxMesh = BoxMesh.new()
	slab_box.size = Vector3(width, 0.04, length)
	slab.mesh = slab_box
	slab.position = Vector3(0.0, top_y - 0.02, 0.0)
	slab.material_override = _mat_marble_road
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(slab)

	# Golden edge curbs on both sides (top at mid.y + top_y + 0.006, strictly below next tier by >= 2.4cm)
	for side in [-1.0, 1.0]:
		var curb: MeshInstance3D = MeshInstance3D.new()
		var curb_box: BoxMesh = BoxMesh.new()
		curb_box.size = Vector3(0.28, 0.044, length)
		curb.mesh = curb_box
		curb.position = Vector3(side * (width * 0.5 + 0.12), top_y - 0.016, 0.0)
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

	# Plaza disc with exact centered planar UVs (0.5, 0.5) -> top face strictly at center.y + PLAZA_TOP_Y (+0.085)
	var disc: MeshInstance3D = MeshInstance3D.new()
	disc.mesh = _create_radial_plaza_disc_mesh(radius, 0.065, 64)
	disc.position = Vector3(0.0, PLAZA_TOP_Y - 0.065, 0.0)
	disc.material_override = _mat_marble_plaza
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(disc)

	# Golden outer rim ring (strictly above plaza edge, no Z-fighting)
	var rim: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = radius - 0.18
	torus.outer_radius = radius + 0.18
	torus.rings = 64
	torus.ring_segments = 16
	rim.mesh = torus
	rim.position = Vector3(0.0, PLAZA_TOP_Y + 0.008, 0.0)
	rim.scale = Vector3(1.0, 0.22, 1.0)
	rim.material_override = _mat_gold_trim
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(rim)


# ===========================================================================
# 6. LANDMARKS, BRIDGE OF MEMORY & WALL-TO-WALL INNER QUARTERS (~240+ HOUSES)
# ===========================================================================

func _build_city_buildings() -> void:
	var bld_root: Node3D = Node3D.new()
	bld_root.name = "CityBuildings"
	add_child(bld_root)

	# 1. School of Souls on West School Terrace (-53.5, 3.2, 8.0), facade facing +X (1.28x grand scale)
	_place_landmark_building(
		bld_root,
		"SchoolOfSoulsBuilding",
		MODEL_SCHOOL_PATH,
		Vector3(-53.5, TIER_1_Y, 8.0),
		PI * 0.5,
		Vector3(19.2, 11.52, 20.4),
		"school",
		1.28
	)

	# 2. Orion Library on North Mid Terrace (-59.5, 3.2, -78.0), facade facing +X (1.28x grand scale)
	_place_landmark_building(
		bld_root,
		"OrionLibraryBuilding",
		MODEL_LIBRARY_PATH,
		Vector3(-59.5, TIER_1_Y, -78.0),
		PI * 0.5,
		Vector3(22.4, 15.36, 22.2),
		"library",
		1.28
	)

	# 3. Kronos Clocktower on North Mid Terrace (56.5, 3.2, -78.0), facade facing -X (1.28x grand scale)
	_place_landmark_building(
		bld_root,
		"KronosClocktowerBuilding",
		MODEL_CLOCKTOWER_PATH,
		Vector3(56.5, TIER_1_Y, -78.0),
		-PI * 0.5,
		Vector3(12.8, 28.16, 12.8),
		"clocktower",
		1.28
	)

	# 4. Mira's Sanctuary on North Mid Terrace (49.0, 3.2, -138.0), facade facing -X (1.28x grand scale)
	_place_landmark_building(
		bld_root,
		"MiraSanctuaryBuilding",
		MODEL_SANCTUARY_PATH,
		Vector3(49.0, TIER_1_Y, -138.0),
		-PI * 0.5,
		Vector3(15.36, 10.24, 14.08),
		"sanctuary",
		1.28
	)

	# 5. Four Iconic City Landmarks across all 3 tiers (GLB + rich procedural fallbacks)
	_build_four_iconic_landmarks(bld_root)

	# 5B. Four Interactive City Venues (Cafe, Memory Shop, Soul Gym, Grand Mall)
	_build_interactive_city_venues(bld_root)

	# 6. Bridge of Memory at (0.0, 0.0, -32.0) + walkable ramp/deck collision
	_build_bridge_of_memory(bld_root)

	# 7. Wall-to-wall dense Pixar residential blocks filling all inner quarters
	#    (grounded to their exact tier elevation + 1 shared StaticBody3D)
	_build_wall_to_wall_inner_quarters(bld_root)


func _build_interactive_city_venues(parent: Node3D) -> void:
	var venues_root: Node3D = Node3D.new()
	venues_root.name = "InteractiveCityVenues"
	parent.add_child(venues_root)

	# 1. Кафе «Тёплая Чашка» — Tier 0 (Y=0.0), right side of Boulevard, facade facing -X
	_place_landmark_building(
		venues_root,
		"VenueStarlightCafe",
		VENUE_CAFE_PATH,
		Vector3(17.5, TIER_0_Y, 28.0),
		-PI * 0.5,
		Vector3(10.8, 8.9, 9.7),
		"venue_cafe"
	)

	# 2. Лавка Воспоминаний — Tier 0 (Y=0.0), left side of Boulevard, facade facing +X
	_place_landmark_building(
		venues_root,
		"VenueMemoryShop",
		VENUE_SHOP_PATH,
		Vector3(-17.15, TIER_0_Y, 28.0),
		PI * 0.5,
		Vector3(9.8, 8.3, 8.6),
		"venue_shop"
	)

	# 3. Спортзал «Павильон Полётной Подготовки» — Tier 1 (Y=3.2), east side of North Boulevard, facade facing -X
	_place_landmark_building(
		venues_root,
		"VenueSoulGym",
		VENUE_GYM_PATH,
		Vector3(21.0, TIER_1_Y, -108.0),
		-PI * 0.5,
		Vector3(12.8, 9.6, 10.1),
		"venue_gym"
	)

	# 4. Торговый Центр «Галерея Миров» — Tier 1 (Y=3.2), west side of North Boulevard, facade facing +X
	_place_landmark_building(
		venues_root,
		"VenueGrandMall",
		VENUE_MALL_PATH,
		Vector3(-23.0, TIER_1_Y, -108.0),
		PI * 0.5,
		Vector3(18.5, 13.5, 13.1),
		"venue_mall"
	)


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

	# 4. TRIUMPHAL ARCH OF KNOWLEDGE at (0.0, 5.6 + ROAD_TOP_Y, -173.4) — Tier 2 Upper Overlook Gateway
	var a_holder: Node3D = Node3D.new()
	a_holder.name = "Landmark_MemoryArch"
	a_holder.position = Vector3(0.0, TIER_2_Y + ROAD_TOP_Y, -173.4)
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

	_set_shadow_casting_recursive(lm_root, GeometryInstance3D.SHADOW_CASTING_SETTING_ON)


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
	sp.radial_segments = 32
	sp.rings = 16
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
	env_sp.radial_segments = 36
	env_sp.rings = 20
	env_mi.mesh = env_sp
	env_mi.position = Vector3(0.0, 2.8, 0.0)
	env_mi.material_override = _mat_roof_terracotta
	env_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	balloon_root.add_child(env_mi)

	var band_mi: MeshInstance3D = MeshInstance3D.new()
	var band_torus: TorusMesh = TorusMesh.new()
	band_torus.inner_radius = 3.25
	band_torus.outer_radius = 3.55
	band_torus.rings = 48
	band_torus.ring_segments = 16
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
		torus.rings = 48
		torus.ring_segments = 16
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
	sp.radial_segments = 32
	sp.rings = 16
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
	sp.radial_segments = 32
	sp.rings = 16
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
	# 0. STRICT FOUNDATION FLATNESS CHECK (0 floating houses over any terrace drop-off!)
	var y_c: float = _get_city_ground_y(x, z)
	var y_nw: float = _get_city_ground_y(x - half_r, z - half_r)
	var y_ne: float = _get_city_ground_y(x + half_r, z - half_r)
	var y_sw: float = _get_city_ground_y(x - half_r, z + half_r)
	var y_se: float = _get_city_ground_y(x + half_r, z + half_r)
	var min_y: float = minf(y_c, minf(minf(y_nw, y_ne), minf(y_sw, y_se)))
	var max_y: float = maxf(y_c, maxf(maxf(y_nw, y_ne), maxf(y_sw, y_se)))
	if max_y - min_y > 0.28:
		return false

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

	# 7. All circular ornate plazas (radius + half_r + 1.0)
	var plazas: Array[Vector3] = [
		Vector3(0.0, 48.0, 12.8),
		Vector3(-35.2, 8.0, 7.6),
		Vector3(42.0, 10.0, 5.7),
		Vector3(30.0, 10.0, 5.5),
		Vector3(0.0, -13.2, 6.8),
		Vector3(0.0, -78.0, 11.4), # Akashic Orrery Central Plaza
		Vector3(-39.5, -78.0, 7.6),
		Vector3(42.0, -78.0, 7.8),
		Vector3(-34.0, -138.0, 10.5),
		Vector3(34.0, -138.0, 6.8),
		Vector3(0.0, -217.5, 9.8),
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

	# 9. All 4 district landmark buildings (1.28x grand scale + +/-PI/2 yaw + half_r + 1.2)
	if absf(x + 53.5) < 11.4 + half_r and absf(z - 8.0) < 10.8 + half_r:
		return false
	if absf(x + 59.5) < 12.3 + half_r and absf(z + 78.0) < 12.4 + half_r:
		return false
	if absf(x - 56.5) < 7.8 + half_r and absf(z + 78.0) < 7.8 + half_r:
		return false
	if absf(x - 49.0) < 8.4 + half_r and absf(z + 138.0) < 9.0 + half_r:
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
		Vector2(-82.0, -31.0),
		Vector2(68.0, 12.0),
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

	# 14. Four Interactive City Venues + open front courtyards to the Boulevard
	# Cafe (17.5, 28.0), footprint [13.5..21.5] x [23.5..32.5] + approach from Boulevard
	if x >= 6.5 - half_r and x <= 24.5 + half_r and absf(z - 28.0) < 7.5 + half_r:
		return false
	# Memory Shop (-17.5, 28.0), footprint [-21.5..-13.5] x [23.5..32.5] + approach from Boulevard
	if x >= -24.5 - half_r and x <= -6.5 + half_r and absf(z - 28.0) < 7.5 + half_r:
		return false
	# Soul Gym (21.0, -108.0), footprint [16.0..26.0] x [-113.5..-102.5] + approach from North Boulevard
	if x >= 6.5 - half_r and x <= 29.5 + half_r and absf(z + 108.0) < 8.5 + half_r:
		return false
	# Grand Mall (-23.0, -108.0), footprint [-29.6..-16.4] x [-117.3..-98.7] + approach from North Boulevard
	if x >= -32.5 - half_r and x <= -6.5 + half_r and absf(z + 108.0) < 12.0 + half_r:
		return false

	# 15. Paved Side Streets, 4 Quarter Alleys, SW Through-Connector & 4 Circular Pocket Parks (R = 8.5m)
	# SW Side Street Z = 44.0 (X = -6..-52), SW Alley X = -23.55 (Z = 18..44) & Cross Connector Z = 18.0 (X = -23.55..-5.0)
	if x >= -54.0 and x <= -5.0 and absf(z - 44.0) < 3.4 + half_r:
		return false
	if z >= 16.5 and z <= 46.0 and absf(x + 23.55) < 2.3 + half_r:
		return false
	if x >= -25.5 and x <= -4.5 and absf(z - 18.0) < 2.5 + half_r:
		return false
	# SE Side Street Z = 38.0 (X = 6..52) & SE Alley X = 28.0 (Z = 10..38)
	if x >= 5.0 and x <= 54.0 and absf(z - 38.0) < 3.4 + half_r:
		return false
	if z >= 9.0 and z <= 40.0 and absf(x - 28.0) < 3.4 + half_r:
		return false
	# NW Tier 1 Alley X = -41.0 (Z = -78..-138) & NE Tier 1 Alley X = 37.0 (Z = -84..-132.4)
	if z >= -140.0 and z <= -76.0 and absf(x + 41.0) < 3.4 + half_r:
		return false
	if z >= -140.0 and z <= -76.0 and absf(x - 37.0) < 3.4 + half_r:
		return false

	var pocket_parks: Array[Vector3] = [
		Vector3(-36.0, 44.0, 8.5),   # SW Pocket Park «Аллея Сакуры»
		Vector3(36.0, 38.0, 8.5),    # SE Pocket Park «Сад Золотых Ив»
		Vector3(-41.0, -108.0, 8.5), # NW Pocket Park «Тихий Дворик Ориона»
		Vector3(38.0, -108.0, 8.5),  # NE Pocket Park «Дворик Времени»
	]
	for pk in pocket_parks:
		var pk_dx: float = x - pk.x
		var pk_dz: float = z - pk.y
		var pk_min_r: float = pk.z + half_r + 1.0
		if pk_dx * pk_dx + pk_dz * pk_dz < pk_min_r * pk_min_r:
			return false

	return true


func _is_far_enough_from_inner_houses(x: float, z: float, min_dist: float) -> bool:
	var min_sq: float = min_dist * min_dist
	for rec in _placed_inner_house_records:
		var dx: float = x - rec.x
		var dz: float = z - rec.y
		if dx * dx + dz * dz < min_sq:
			return false
	return true


func _is_clear_of_inner_houses_footprint(x: float, z: float, clearance_r: float) -> bool:
	for rec in _placed_inner_house_records:
		var dx: float = x - rec.x
		var dz: float = z - rec.y
		var min_r: float = rec.z + clearance_r
		if dx * dx + dz * dz < min_r * min_r:
			return false
	return true


## Strict 100% grass-only vegetation validator: guarantees ZERO trees, bushes,
## or grass clusters ever grow on stone paving, roads, plazas, terrace decks,
## pocket park stone walkways, canal/lake, or clip into ANY house or building.
func _is_pure_grass_spot(x: float, z: float, clearance_r: float) -> bool:
	# 1. Flat meadow ground check (never straddle a terrace drop-off or cliff)
	var y_c: float = _get_city_ground_y(x, z)
	var half_g: float = maxf(0.85, clearance_r * 0.42)
	if absf(_get_city_ground_y(x - half_g, z - half_g) - y_c) > 0.1:
		return false
	if absf(_get_city_ground_y(x + half_g, z - half_g) - y_c) > 0.1:
		return false
	if absf(_get_city_ground_y(x - half_g, z + half_g) - y_c) > 0.1:
		return false
	if absf(_get_city_ground_y(x + half_g, z + half_g) - y_c) > 0.1:
		return false

	# 2. NO stone/paved terrace decks, Upper Overlook, North Terrace stone coping, or Upper Temple Forecourt
	# WestSchoolTerraceDeck: X in [-64.5..-25.5], Z in [-16.5..32.5]
	if x >= -64.5 - clearance_r and x <= -25.5 + clearance_r and z >= -16.5 - clearance_r and z <= 32.5 + clearance_r:
		return false
	# UpperOverlook stone paving: X in [-24.8..24.8], Z in [-198.8..-169.2]
	if x >= -24.8 - clearance_r and x <= 24.8 + clearance_r and z >= -198.8 - clearance_r and z <= -169.2 + clearance_r:
		return false
	# Upper Temple Forecourt & Baroque Palace: Z <= -204.0
	if z <= -204.0 + clearance_r:
		return false
	# North Mid Terrace south stone coping apron (Z in [-56.2..-52.0], |X| <= 66.0)
	if absf(x) <= 66.5 + clearance_r and z >= -56.4 - clearance_r and z <= -51.6 + clearance_r:
		return false

	# 3. NO roads, boulevards, side streets, alleys, sidewalks, or staircases (expanded by +clearance_r)
	# MainBoulevard_South (w=10.0 + curbs -> half 5.3)
	if z >= -21.5 - clearance_r and z <= 56.5 + clearance_r and absf(x) < 5.3 + clearance_r:
		return false
	# MainBoulevard_North (w=12.0 + curbs -> half 6.3)
	if z >= -158.5 - clearance_r and z <= -54.5 + clearance_r and absf(x) < 6.3 + clearance_r:
		return false
	# Street_SchoolApproach & Staircase_WestSchool (Z=8.0, w=8.0 -> half 4.4)
	if x >= -26.5 - clearance_r and x <= 0.5 + clearance_r and absf(z - 8.0) < 4.5 + clearance_r:
		return false
	# Street_QuietLakesPark (Z=10.0, X in [0..44], w=7.0 -> half 3.8)
	if x >= -0.5 - clearance_r and x <= 44.5 + clearance_r and absf(z - 10.0) < 3.8 + clearance_r:
		return false
	# Street_OrionLibrary & Street_KronosTower (Z=-78.0, X in [-40..42.5], w=7.5 -> half 4.1)
	if x >= -40.5 - clearance_r and x <= 42.5 + clearance_r and absf(z + 78.0) < 4.1 + clearance_r:
		return false
	# Street_LanternGarden & Street_MiraSanctuary (Z=-138.0, X in [-34.5..34.5], w=7.5 -> half 4.1)
	if x >= -35.0 - clearance_r and x <= 35.0 + clearance_r and absf(z + 138.0) < 4.1 + clearance_r:
		return false
	# SideStreet_SouthWest (Z=44.0, X in [-52..-6], w=5.4 -> half 3.0)
	if x >= -52.5 - clearance_r and x <= -5.5 + clearance_r and absf(z - 44.0) < 3.0 + clearance_r:
		return false
	# Alley_SouthWest (X=-23.55, Z in [18..44], w=3.0 -> half 1.9)
	if z >= 17.5 - clearance_r and z <= 44.5 + clearance_r and absf(x + 23.55) < 1.9 + clearance_r:
		return false
	# Alley_SouthWest_Cross (Z=18.0, X in [-25.5..-4.5], w=3.6 -> half 2.2)
	if x >= -25.5 - clearance_r and x <= -4.5 + clearance_r and absf(z - 18.0) < 2.2 + clearance_r:
		return false
	# SideStreet_SouthEast (Z=38.0, X in [6..52], w=5.4 -> half 3.0)
	if x >= 5.5 - clearance_r and x <= 52.5 + clearance_r and absf(z - 38.0) < 3.0 + clearance_r:
		return false
	# Alley_SouthEast (X=28.0, Z in [13..38], w=5.4 -> half 3.0)
	if z >= 13.0 - clearance_r and z <= 38.0 + clearance_r and absf(x - 28.0) < 3.0 + clearance_r:
		return false
	# Alley_NorthWest_Orion (X=-41.0, Z in [-134..-85], w=5.4 -> half 3.0)
	if z >= -134.5 - clearance_r and z <= -85.0 + clearance_r and absf(x + 41.0) < 3.0 + clearance_r:
		return false
	# Alley_NorthEast_Kronos (X=37.0, Z in [-133..-84], w=5.4 -> half 3.0)
	if z >= -133.0 - clearance_r and z <= -83.5 + clearance_r and absf(x - 37.0) < 3.0 + clearance_r:
		return false
	# Staircase_GrandNorth & Staircase_Tier2Ascent
	if absf(x) < 7.2 + clearance_r and z >= -56.0 - clearance_r and z <= -42.5 + clearance_r:
		return false
	if absf(x) < 8.5 + clearance_r and z >= -213.0 - clearance_r and z <= -157.0 + clearance_r:
		return false

	# 4. NO 12 circular stone plazas (expanded by plaza_r + clearance_r)
	var plazas: Array[Vector3] = [
		Vector3(0.0, 48.0, 12.5),
		Vector3(42.0, 10.0, 5.7),
		Vector3(30.0, 10.0, 5.5),
		Vector3(0.0, -13.2, 6.8),
		Vector3(0.0, -217.5, 9.8),
		Vector3(-35.2, 8.0, 7.4),
		Vector3(0.0, -78.0, 10.8),
		Vector3(-39.5, -78.0, 7.4),
		Vector3(42.0, -78.0, 7.6),
		Vector3(-34.0, -138.0, 10.5),
		Vector3(34.0, -138.0, 6.6),
		Vector3(0.0, -184.0, 7.8),
	]
	for pl in plazas:
		var pdx: float = x - pl.x
		var pdz: float = z - pl.y
		var min_pr: float = pl.z + 0.25 + clearance_r
		if pdx * pdx + pdz * pdz < min_pr * min_pr:
			return false

	# 5. NO outer stone walkway of the 4 pocket parks (dist in [4.8..9.2] + clearance; inner lawn <= 4.6m only)
	var pocket_parks: Array[Vector2] = [
		Vector2(-36.0, 44.0),
		Vector2(36.0, 38.0),
		Vector2(-41.0, -108.0),
		Vector2(38.0, -108.0),
	]
	for pk in pocket_parks:
		var pk_dx: float = x - pk.x
		var pk_dz: float = z - pk.y
		var pk_dist: float = sqrt(pk_dx * pk_dx + pk_dz * pk_dz)
		var outer_block: float = maxf(9.2, 8.7 + clearance_r)
		if pk_dist < outer_block:
			return false

	# 6. NO Canal (Z in [-40.5..-23.5]), Lake ((54, 12), R=14.2), Waterfalls, Cloud Balloon, or Retaining Walls
	if z >= -40.5 - clearance_r and z <= -23.5 + clearance_r:
		return false
	var ldx: float = x - LAKE_CENTER.x
	var ldz: float = z - LAKE_CENTER.z
	var lake_block: float = 14.2 + clearance_r
	if ldx * ldx + ldz * ldz < lake_block * lake_block:
		return false
	var cbdx: float = x - 66.0
	var cbdz: float = z - 26.0
	var cb_block: float = 8.0 + clearance_r
	if cbdx * cbdx + cbdz * cbdz < cb_block * cb_block:
		return false
	var wf_pts: Array[Vector2] = [
		Vector2(-68.0, -32.0),
		Vector2(68.0, -32.0),
		Vector2(-82.0, -28.0),
		Vector2(67.0, 12.0),
	]
	for wpt in wf_pts:
		var wdx: float = x - wpt.x
		var wdz: float = z - wpt.y
		var w_block: float = 7.8 + clearance_r
		if wdx * wdx + wdz * wdz < w_block * w_block:
			return false
	# Retaining walls & terrace edges
	if absf(z + 52.0) < 2.2 + clearance_r or absf(z + 158.0) < 2.2 + clearance_r:
		return false

	# 7. NO 4 landmark buildings (1.28x) or 4 interactive venues
	if absf(x + 53.5) < 11.4 + clearance_r and absf(z - 8.0) < 11.2 + clearance_r:
		return false
	if absf(x + 59.5) < 12.2 + clearance_r and absf(z + 78.0) < 12.6 + clearance_r:
		return false
	if absf(x - 56.5) < 8.0 + clearance_r and absf(z + 78.0) < 8.0 + clearance_r:
		return false
	if absf(x - 49.0) < 8.8 + clearance_r and absf(z + 138.0) < 9.4 + clearance_r:
		return false
	if x >= 12.5 - clearance_r and x <= 23.0 + clearance_r and absf(z - 28.0) < 6.2 + clearance_r:
		return false
	if x >= -23.0 - clearance_r and x <= -12.5 + clearance_r and absf(z - 28.0) < 6.2 + clearance_r:
		return false
	if x >= 15.0 - clearance_r and x <= 27.5 + clearance_r and absf(z + 108.0) < 7.2 + clearance_r:
		return false
	if x >= -30.5 - clearance_r and x <= -15.5 + clearance_r and absf(z + 108.0) < 10.6 + clearance_r:
		return false

	# 8. Strictly clear of EVERY placed inner house (rec.z = actual enlarged half_r 6.2..7.03m + clearance_r!)
	if not _is_clear_of_inner_houses_footprint(x, z, clearance_r):
		return false

	return true


func _try_add_inner_house(
	x: float,
	z: float,
	face_yaw: float,
	h_kind: String,
	xz_scale: float,
	y_scale: float,
	col_body: StaticBody3D
) -> bool:
	var half_r: float = maxf(6.2, 3.80 * xz_scale)
	if not _is_point_clear_for_house(x, z, half_r):
		return false
	if not _is_far_enough_from_inner_houses(x, z, 10.6):
		return false

	# Seat foundation at minimum of center & 4 corners minus 0.22m (0 gaps, 0 floating!)
	var y_c: float = _get_city_ground_y(x, z)
	var y_nw: float = _get_city_ground_y(x - half_r, z - half_r)
	var y_ne: float = _get_city_ground_y(x + half_r, z - half_r)
	var y_sw: float = _get_city_ground_y(x - half_r, z + half_r)
	var y_se: float = _get_city_ground_y(x + half_r, z + half_r)
	var base_y: float = minf(y_c, minf(minf(y_nw, y_ne), minf(y_sw, y_se)))
	var seated_y: float = base_y - 0.22

	_placed_inner_house_records.append(Vector3(x, z, half_r))
	var h_arr: Array[Transform3D] = _city_inner_house_batches[h_kind] as Array[Transform3D]
	var xf: Transform3D = Transform3D(
		Basis.from_euler(Vector3(0.0, face_yaw, 0.0)).scaled(Vector3(xz_scale, y_scale, xz_scale)),
		Vector3(x, seated_y, z)
	)
	h_arr.append(xf)

	# 100% COLLISION ON EVERY SINGLE INNER HOUSE (covers full wall/terrace width!)
	if col_body != null:
		var col: CollisionShape3D = CollisionShape3D.new()
		var house_box: BoxShape3D = BoxShape3D.new()
		if h_kind == "terracotta_terrace":
			house_box.size = Vector3(7.4 * xz_scale, 8.4 * y_scale, 7.1 * xz_scale)
		else:
			house_box.size = Vector3(7.2 * xz_scale, 8.2 * y_scale, 7.2 * xz_scale)
		col.shape = house_box
		col.position = Vector3(x, seated_y + house_box.size.y * 0.5, z)
		col.rotation.y = face_yaw
		col_body.add_child(col)

	return true


func _build_wall_to_wall_inner_quarters(bld_root: Node3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 202633

	# Single shared StaticBody3D with 100% exact per-house BoxShape3D colliders
	var col_body: StaticBody3D = StaticBody3D.new()
	col_body.name = "CityHousesCollisionBody"
	bld_root.add_child(col_body)

	var street_kinds: Array[String] = [
		"blue_balcony",
		"ochre_timber",
		"terracotta_terrace",
		"red_gable",
		"blue_balcony",
		"cream_spire",
		"ochre_timber",
		"terracotta_terrace",
	]
	var counter: int = 0
	var row_step: float = 12.2

	# --- A. MAIN BOULEVARD FACADE ROWS (Grand 4-6 story European-Pixar rows facing the Boulevard) ---
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		var z_cur: float = -148.0
		while z_cur <= 54.0:
			var blvd_x: float = side * (15.2 if z_cur < -45.0 else 14.6)
			var xz_sc: float = rng.randf_range(1.55, 1.85)
			var y_sc: float = rng.randf_range(2.15, 3.05)
			var yaw: float = -PI * 0.5 if side > 0.0 else PI * 0.5
			var kind: String = street_kinds[counter % street_kinds.size()]
			if _try_add_inner_house(blvd_x, z_cur, yaw, kind, xz_sc, y_sc, col_body):
				counter += 1
			z_cur += row_step

	# --- B. SHINING CANAL SOUTH WATERFRONT ROW (Strictly facing north toward the Canal) ---
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		var x_abs: float = 19.5
		while x_abs <= 58.0:
			var xz_sc: float = rng.randf_range(1.55, 1.85)
			var y_sc: float = rng.randf_range(2.15, 3.05)
			var kind: String = street_kinds[counter % street_kinds.size()]
			if _try_add_inner_house(side * x_abs, -14.8, PI, kind, xz_sc, y_sc, col_body):
				counter += 1
			x_abs += row_step

	# --- C. ORDERLY EAST-WEST STREET ROWS (Strictly facing each street/avenue, 0 random yaw) ---
	var ew_street_rows: Array[Dictionary] = [
		# SW Side Street (Z = 44.0): South side rows facing north (PI)
		{"z": 55.2, "x_min": -56.0, "x_max": -18.0, "yaw": PI},
		{"z": 67.4, "x_min": -56.0, "x_max": -18.0, "yaw": PI},
		# SE Side Street (Z = 38.0): North side faces south (0.0), South side faces north (PI)
		{"z": 27.6, "x_min": 20.0, "x_max": 54.0, "yaw": 0.0},
		{"z": 49.2, "x_min": 18.0, "x_max": 54.0, "yaw": PI},
		{"z": 61.4, "x_min": 18.0, "x_max": 54.0, "yaw": PI},
		# School & Quiet Lakes Cross Street (Z = 8.0 / 10.0)
		{"z": -5.0, "x_min": -56.0, "x_max": -32.0, "yaw": 0.0},
		{"z": 22.8, "x_min": -56.0, "x_max": -32.0, "yaw": PI},
		{"z": -4.6, "x_min": 18.0, "x_max": 42.0, "yaw": 0.0},
		{"z": 22.5, "x_min": 18.0, "x_max": 38.0, "yaw": PI},
		# North Terrace South Promenade & Orion/Kronos Cross Street (Z = -78.0)
		{"z": -63.0, "x_min": -56.0, "x_max": -18.0, "yaw": PI},
		{"z": -91.2, "x_min": -56.0, "x_max": -18.0, "yaw": 0.0},
		{"z": -63.0, "x_min": 18.0, "x_max": 56.0, "yaw": PI},
		{"z": -91.2, "x_min": 18.0, "x_max": 56.0, "yaw": 0.0},
		# Lantern Garden & Mira's Sanctuary Cross Street (Z = -138.0)
		{"z": -125.0, "x_min": -56.0, "x_max": -18.0, "yaw": PI},
		{"z": -151.0, "x_min": -56.0, "x_max": -18.0, "yaw": 0.0},
		{"z": -125.0, "x_min": 18.0, "x_max": 56.0, "yaw": PI},
		{"z": -151.0, "x_min": 18.0, "x_max": 56.0, "yaw": 0.0},
	]
	for row_spec in ew_street_rows:
		var rz: float = float(row_spec["z"])
		var r_yaw: float = float(row_spec["yaw"])
		var x_cur: float = float(row_spec["x_min"])
		var x_end: float = float(row_spec["x_max"])
		while x_cur <= x_end:
			var xz_sc: float = rng.randf_range(1.55, 1.85)
			var y_sc: float = rng.randf_range(2.15, 3.05)
			var kind: String = street_kinds[counter % street_kinds.size()]
			if (counter % 7 == 0) and absf(x_cur) > 24.0:
				kind = "cream_spire"
			if _try_add_inner_house(x_cur, rz, r_yaw, kind, xz_sc, y_sc, col_body):
				counter += 1
			x_cur += row_step

	# --- D. ORDERLY NORTH-SOUTH ALLEY & OUTER QUARTER ROWS (Strictly facing each alley/quarter) ---
	var ns_alley_rows: Array[Dictionary] = [
		# SE Alley X = 28.0 (East side faces -X)
		{"x": 39.2, "z_min": 18.0, "z_max": 30.0, "yaw": -PI * 0.5},
		# NW Tier 1 Alley X = -41.0 (West side faces +X, East side faces -X)
		{"x": -52.5, "z_min": -126.0, "z_max": -92.0, "yaw": PI * 0.5},
		{"x": -30.0, "z_min": -126.0, "z_max": -92.0, "yaw": -PI * 0.5},
		# NE Tier 1 Alley X = 38.0 (West side faces +X, East side faces -X)
		{"x": 27.0, "z_min": -126.0, "z_max": -92.0, "yaw": PI * 0.5},
		{"x": 49.5, "z_min": -126.0, "z_max": -92.0, "yaw": -PI * 0.5},
		# Outer West & East Quarter Rows (facing inward toward the city, strictly inside terrace bounds)
		{"x": -57.5, "z_min": -150.0, "z_max": 52.0, "yaw": PI * 0.5},
		{"x": 57.5, "z_min": -150.0, "z_max": 52.0, "yaw": -PI * 0.5},
		# Pre-Palace Flanking Quarters (orderly rows facing Upper Overlook Terrace)
		{"x": -37.5, "z_min": -200.0, "z_max": -166.0, "yaw": PI * 0.5},
		{"x": -50.5, "z_min": -200.0, "z_max": -166.0, "yaw": PI * 0.5},
		{"x": 37.5, "z_min": -200.0, "z_max": -166.0, "yaw": -PI * 0.5},
		{"x": 50.5, "z_min": -200.0, "z_max": -166.0, "yaw": -PI * 0.5},
	]
	for col_spec in ns_alley_rows:
		var cx: float = float(col_spec["x"])
		var c_yaw: float = float(col_spec["yaw"])
		var z_cur: float = float(col_spec["z_min"])
		var z_end: float = float(col_spec["z_max"])
		while z_cur <= z_end:
			var xz_sc: float = rng.randf_range(1.55, 1.85)
			var y_sc: float = rng.randf_range(2.15, 3.05)
			var kind: String = street_kinds[counter % street_kinds.size()]
			if (counter % 6 == 0) and absf(cx) > 28.0:
				kind = "cream_spire"
			if _try_add_inner_house(cx, z_cur, c_yaw, kind, xz_sc, y_sc, col_body):
				counter += 1
			z_cur += row_step

	# --- E. POCKET PARK PERIMETER RINGS (Grand-scale houses facing inward toward each circular park) ---
	var park_centers: Array[Vector2] = [
		Vector2(-36.0, 44.0),
		Vector2(36.0, 38.0),
		Vector2(-41.0, -108.0),
		Vector2(38.0, -108.0),
	]
	for pk_c in park_centers:
		var ring_r: float = 16.8
		var slots: int = 8
		for s_i in range(slots):
			var ang: float = (TAU * float(s_i)) / float(slots) + PI / 8.0
			var hx: float = pk_c.x + cos(ang) * ring_r
			var hz: float = pk_c.y + sin(ang) * ring_r
			var face_park: float = atan2(pk_c.x - hx, pk_c.y - hz)
			var xz_sc: float = rng.randf_range(1.55, 1.78)
			var y_sc: float = rng.randf_range(2.15, 2.85)
			var kind: String = street_kinds[counter % street_kinds.size()]
			if _try_add_inner_house(hx, hz, face_park, kind, xz_sc, y_sc, col_body):
				counter += 1


func _place_landmark_building(
	parent: Node3D,
	node_name: String,
	model_path: String,
	pos: Vector3,
	yaw_rad: float,
	col_size: Vector3,
	fallback_kind: String,
	model_scale: float = 1.0
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
			if not is_equal_approx(model_scale, 1.0):
				model_node.scale = Vector3(model_scale, model_scale, model_scale)
			holder.add_child(model_node)
			_ground_node_to_zero(model_node)
		else:
			inst.queue_free()
			var fb_root: Node3D = Node3D.new()
			fb_root.scale = Vector3(model_scale, model_scale, model_scale)
			holder.add_child(fb_root)
			_build_procedural_landmark(fb_root, fallback_kind)
	else:
		var fb_root2: Node3D = Node3D.new()
		fb_root2.scale = Vector3(model_scale, model_scale, model_scale)
		holder.add_child(fb_root2)
		_build_procedural_landmark(fb_root2, fallback_kind)

	# Matte non-glossy harmonizer + chaotic glowing windows + crisp shadows on ALL landmarks & venues
	_harmonize_building_materials_recursive(holder)
	_set_shadow_casting_recursive(holder, GeometryInstance3D.SHADOW_CASTING_SETTING_ON)

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
		dc.radial_segments = 32
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
		cone.radial_segments = 32
		spire.mesh = cone
		spire.position = Vector3(0.0, 20.2, 0.0)
		spire.material_override = _mat_blue_roof
		parent.add_child(spire)
		_add_box_part(parent, Vector3(2.4, 3.6, 0.3), Vector3(0.0, 2.8, 3.85), _mat_warm_window)
	elif kind == "venue_cafe":
		_add_box_part(parent, Vector3(9.0, 0.45, 8.0), Vector3(0.0, 0.225, 0.0), _mat_stone_quay)
		_add_box_part(parent, Vector3(8.2, 4.4, 7.2), Vector3(0.0, 2.65, 0.0), _mat_wall_cream)
		_add_prism_roof(parent, Vector3(9.0, 2.5, 8.0), Vector3(0.0, 6.1, 0.0), _mat_roof_terracotta)
		_add_box_part(parent, Vector3(6.8, 0.35, 1.8), Vector3(0.0, 3.35, 4.15), _mat_roof_red)
		_add_box_part(parent, Vector3(2.2, 2.8, 0.25), Vector3(0.0, 1.85, 3.65), _mat_warm_window)
		for sx in [-2.6, 2.6]:
			_add_box_part(parent, Vector3(1.6, 1.8, 0.25), Vector3(sx, 2.3, 3.65), _mat_warm_window)
	elif kind == "venue_shop":
		_add_box_part(parent, Vector3(9.0, 0.45, 8.0), Vector3(0.0, 0.225, 0.0), _mat_stone_quay)
		_add_box_part(parent, Vector3(8.2, 4.6, 7.2), Vector3(0.0, 2.75, 0.0), _mat_wall_ochre)
		_add_prism_roof(parent, Vector3(9.0, 2.6, 8.0), Vector3(0.0, 6.35, 0.0), _mat_blue_roof)
		_add_box_part(parent, Vector3(7.2, 0.45, 0.45), Vector3(0.0, 4.9, 3.7), _mat_gold_trim)
		_add_box_part(parent, Vector3(2.4, 2.9, 0.25), Vector3(0.0, 1.9, 3.65), _mat_warm_window)
		for sx in [-2.7, 2.7]:
			_add_box_part(parent, Vector3(1.8, 2.1, 0.25), Vector3(sx, 2.15, 3.65), _mat_warm_window)
	elif kind == "venue_gym":
		_add_box_part(parent, Vector3(11.0, 0.55, 10.0), Vector3(0.0, 0.275, 0.0), _mat_stone_quay)
		_add_box_part(parent, Vector3(10.0, 5.4, 9.0), Vector3(0.0, 3.25, 0.0), _mat_marble_wall)
		_add_box_part(parent, Vector3(10.6, 0.5, 9.6), Vector3(0.0, 6.2, 0.0), _mat_gold_trim)
		_add_prism_roof(parent, Vector3(10.8, 2.6, 9.8), Vector3(0.0, 7.75, 0.0), _mat_roof_ochre)
		_add_box_part(parent, Vector3(3.0, 3.4, 0.3), Vector3(0.0, 2.25, 4.55), _mat_warm_window)
		for sx in [-3.4, 3.4]:
			_add_cylinder_part(parent, 0.38, 5.4, Vector3(sx, 3.25, 4.85), _mat_marble_plaza)
	elif kind == "venue_mall":
		_add_box_part(parent, Vector3(14.0, 0.6, 12.0), Vector3(0.0, 0.3, 0.0), _mat_stone_quay)
		_add_box_part(parent, Vector3(12.8, 6.4, 10.8), Vector3(0.0, 3.8, 0.0), _mat_wall_peach)
		_add_box_part(parent, Vector3(13.4, 0.55, 11.4), Vector3(0.0, 7.25, 0.0), _mat_gold_trim)
		var mall_dome: MeshInstance3D = MeshInstance3D.new()
		var m_sp: SphereMesh = SphereMesh.new()
		m_sp.radius = 4.6
		m_sp.height = 5.2
		mall_dome.mesh = m_sp
		mall_dome.position = Vector3(0.0, 7.8, 0.0)
		mall_dome.material_override = _mat_blue_roof
		parent.add_child(mall_dome)
		_add_box_part(parent, Vector3(3.8, 4.0, 0.3), Vector3(0.0, 2.6, 5.45), _mat_warm_window)
		for sx in [-4.4, 4.4]:
			_add_box_part(parent, Vector3(2.2, 3.2, 0.25), Vector3(sx, 3.2, 5.45), _mat_warm_window)
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

	_set_shadow_casting_recursive(bridge_root, GeometryInstance3D.SHADOW_CASTING_SETTING_ON)

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
		cone.radial_segments = 28
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

	var tier_heights: Array[float] = [3.5, 9.0, 15.5, 23.0, 31.0]
	var tier_x_bases: Array[float] = [73.0, 91.0, 110.0, 130.0, 151.0]
	var tier_z_south: Array[float] = [84.0, 91.0, 106.0, 121.0, 136.0]
	var lower_kinds: Array[String] = ["red_gable", "blue_balcony", "ochre_timber", "terracotta_terrace"]
	var upper_kinds: Array[String] = ["cream_spire", "red_gable", "blue_balcony", "terracotta_terrace", "cream_spire", "ochre_timber"]
	var crown_kinds: Array[String] = ["cream_spire", "cream_spire", "blue_balcony", "cream_spire", "red_gable"]

	# --- A. WEST & EAST AMPHITHEATER SLOPES (5 Grand-Scale Cascading Tiers, step 10.5m on near tiers) ---
	var west_east_steps: Array[float] = [10.5, 11.2, 12.6, 14.4, 16.5]
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

				# Gentle outward curve around Lake of Silence & CloudBalloon on East Tier 0
				var lake_flare: float = 0.0
				if side > 0.0 and t_idx == 0 and z_cur > -6.0 and z_cur < 42.0:
					lake_flare = 8.0

				# Gentle outward curve around OrionLibraryBuilding on West Tiers 0 & 1
				var orion_flare: float = 8.0 if (side < 0.0 and t_idx <= 1 and z_cur > -96.0 and z_cur < -58.0) else 0.0

				var x_pos: float = side * (bx + north_flare + lake_flare + orion_flare + rng.randf_range(-0.6, 0.6))
				var z_pos: float = z_cur + rng.randf_range(-0.45, 0.45)

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

				# Continuous deep retaining wall slab anchored at unjittered tier centerline (exact butt-joint 2.0*z_step)
				var wall_h: float = ty + 1.5
				var wall_cx: float = side * (bx + north_flare + lake_flare + orion_flare)
				if slot_idx % 2 == 1:
					var wall_yaw: float = PI * 0.5
					wall_xforms.append(Transform3D(
						Basis.from_euler(Vector3(0.0, wall_yaw, 0.0)).scaled(Vector3(z_step * 2.0, wall_h, 16.8)),
						Vector3(wall_cx, wall_h * 0.5 - 1.5, z_cur + z_step * 0.45)
					))
					if slot_idx % 4 == 1:
						pier_xforms.append(Transform3D(
							Basis.from_euler(Vector3(0.0, 0.0, 0.0)).scaled(Vector3(2.0, wall_h + 0.3, 2.0)),
							Vector3(wall_cx - side * 7.8, wall_h * 0.5 - 1.35, z_cur + z_step * 0.6)
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
						Vector3(wall_cx - side * 7.4, -0.5, z_pos + rng.randf_range(-2.0, 2.0))
					))

				# Grand-scale terrace house/spire facing inward, seated firmly at ty - 0.18 (0 floating!)
				var h_kind: String = ""
				if t_idx == 4:
					h_kind = crown_kinds[(slot_idx + t_idx) % crown_kinds.size()]
				elif t_idx >= 2:
					h_kind = upper_kinds[(slot_idx + t_idx * 2) % upper_kinds.size()]
				else:
					h_kind = lower_kinds[(slot_idx + t_idx) % lower_kinds.size()]

				var face_yaw: float = (-PI * 0.5 if side > 0.0 else PI * 0.5) + rng.randf_range(-0.10, 0.10)
				var h_sc: float = rng.randf_range(1.48, 1.72)
				var h_sy: float = rng.randf_range(2.45, 3.05) if (t_idx == 4 and h_kind == "cream_spire") else rng.randf_range(2.05, 2.75)
				var h_arr: Array[Transform3D] = _city_outer_house_batches[h_kind] as Array[Transform3D]
				h_arr.append(Transform3D(
					Basis.from_euler(Vector3(0.0, face_yaw, 0.0)).scaled(Vector3(h_sc, h_sy, h_sc)),
					Vector3(x_pos, ty - 0.18, z_pos)
				))

				# Sculptural Fairytale Trees seated strictly inside the retaining wall top (ty - 0.15)
				if (slot_idx + t_idx) % 3 == 0:
					var tree_x: float = x_pos - side * rng.randf_range(2.2, 3.6)
					var tree_z: float = z_pos + rng.randf_range(-2.0, 2.0)
					var tree_sc: float = rng.randf_range(0.95, 1.32)
					var tree_xf: Transform3D = Transform3D(
						Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(tree_sc, tree_sc, tree_sc)),
						Vector3(tree_x, ty - 0.15, tree_z)
					)
					var t_mod: int = (slot_idx + t_idx) % 4
					if t_mod == 0:
						_tree_blossom_xforms.append(tree_xf)
					elif t_mod == 1:
						_tree_willow_gold_xforms.append(tree_xf)
					elif t_mod == 2:
						_tree_bonsai_azure_xforms.append(tree_xf)
					else:
						_tree_willow_lavender_xforms.append(tree_xf)

				z_cur += z_step

	# --- B. SOUTH AMPHITHEATER SLOPE BEHIND AWAKENING PLAZA (5 Grand-Scale Tiers, Z = +84..+136) ---
	var south_steps: Array[float] = [10.5, 11.4, 12.8, 14.6, 16.8]
	for t_idx in range(5):
		var ty: float = tier_heights[t_idx]
		var bz: float = tier_z_south[t_idx]
		var x_span: float = 58.0 + float(t_idx) * 16.0
		var x_step: float = south_steps[t_idx]
		var x_cur: float = -x_span
		var s_idx: int = 0
		while x_cur <= x_span:
			s_idx += 1
			var x_pos: float = x_cur + rng.randf_range(-0.45, 0.45)
			var z_pos: float = bz + rng.randf_range(-0.6, 0.6)

			# Bottom at Y = -1.5, top strictly flush at Y = ty, exact butt-joint 2.0*x_step, depth 16.8m!
			var wall_h: float = ty + 1.5
			if s_idx % 2 == 1:
				wall_xforms.append(Transform3D(
					Basis.from_scale(Vector3(x_step * 2.0, wall_h, 16.8)),
					Vector3(x_cur + x_step * 0.45, wall_h * 0.5 - 1.5, bz)
				))

			if (s_idx + t_idx) % 4 == 0:
				var cliff_sy_b: float = (ty + 0.5) / 6.0
				var r_sc: Vector3 = Vector3(rng.randf_range(1.2, 1.6), cliff_sy_b, rng.randf_range(1.2, 1.6))
				cliff_xforms.append(Transform3D(
					Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(r_sc),
					Vector3(x_pos, -0.5, bz - 7.4)
				))

			var h_kind: String = ""
			if t_idx == 4:
				h_kind = crown_kinds[(s_idx + t_idx) % crown_kinds.size()]
			elif t_idx >= 2:
				h_kind = upper_kinds[(s_idx + t_idx) % upper_kinds.size()]
			else:
				h_kind = lower_kinds[(s_idx + t_idx) % lower_kinds.size()]
			var h_sc: float = rng.randf_range(1.48, 1.72)
			var h_sy: float = rng.randf_range(2.45, 3.05) if (t_idx == 4 and h_kind == "cream_spire") else rng.randf_range(2.05, 2.75)
			var h_arr: Array[Transform3D] = _city_outer_house_batches[h_kind] as Array[Transform3D]
			h_arr.append(Transform3D(
				Basis.from_euler(Vector3(0.0, PI + rng.randf_range(-0.12, 0.12), 0.0)).scaled(Vector3(h_sc, h_sy, h_sc)),
				Vector3(x_pos, ty - 0.18, z_pos)
			))

			if s_idx % 3 == 0:
				var tr_sc: float = rng.randf_range(0.95, 1.32)
				var tr_xf: Transform3D = Transform3D(
					Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(tr_sc, tr_sc, tr_sc)),
					Vector3(x_pos + 2.8, ty - 0.15, z_pos - 3.0)
				)
				if s_idx % 9 == 0:
					_tree_blossom_xforms.append(tr_xf)
				elif s_idx % 6 == 0:
					_tree_willow_gold_xforms.append(tr_xf)
				else:
					_tree_bonsai_azure_xforms.append(tr_xf)

			x_cur += x_step

	# --- C. DISTANT RIVERFRONT QUARTERS ALONG CANAL TOWARD HORIZON (X = +/-88..+/-158, step 11.5m) ---
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

				# Retaining wall supporting each riverfront terrace house (top strictly at Y = ty, depth 16.2m)
				var wall_h_c: float = ty + 1.5
				wall_xforms.append(Transform3D(
					Basis.from_scale(Vector3(12.8, wall_h_c, 16.2)),
					Vector3(x_pos, wall_h_c * 0.5 - 1.5, z_pos)
				))

				# Grounded cliff rock at river edge (bottom Y = -0.5, top strictly at Y = ty)
				if d_idx % 3 == 1:
					var cliff_sy_c: float = (ty + 0.5) / 6.0
					cliff_xforms.append(Transform3D(
						Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(1.5, cliff_sy_c, 1.4)),
						Vector3(x_pos, -0.5, z_pos - bank * 5.4)
					))

				var h_kind: String = "cream_spire" if (d_idx >= 5 or d_idx % 4 == 0) else lower_kinds[d_idx % lower_kinds.size()]
				var face_yaw: float = 0.0 if bank < 0.0 else PI
				var h_sc: float = rng.randf_range(1.48, 1.72)
				var h_sy_c: float = rng.randf_range(2.05, 2.75)
				var h_arr: Array[Transform3D] = _city_outer_house_batches[h_kind] as Array[Transform3D]
				h_arr.append(Transform3D(
					Basis.from_euler(Vector3(0.0, face_yaw + rng.randf_range(-0.10, 0.10), 0.0)).scaled(Vector3(h_sc, h_sy_c, h_sc)),
					Vector3(x_pos, ty - 0.18, z_pos)
				))

				if d_idx % 3 == 0:
					var t_xf: Transform3D = Transform3D(
						Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(1.10, 1.10, 1.10)),
						Vector3(x_pos + side * 2.8, ty - 0.15, z_pos + bank * 2.2)
					)
					if d_idx % 6 == 0:
						_tree_willow_gold_xforms.append(t_xf)
					else:
						_tree_bonsai_azure_xforms.append(t_xf)

				x_abs += 11.5

	# --- D. COMMIT WALLS, CLIFFS & SPLIT INNER (SHADOWS ON) / OUTER (SHADOWS OFF) HOUSE MULTIMESHES ---
	# 1. Terraced retaining walls & piers (2 draw calls, textured via pixar_building_facade.gdshader)
	var wall_mesh: BoxMesh = BoxMesh.new()
	wall_mesh.size = Vector3(1.0, 1.0, 1.0)
	_create_simple_multimesh(tier_root, "TerraceRetainingWallsMM", wall_mesh, _mat_terrace_stone, wall_xforms, false)

	var pier_mesh: BoxMesh = BoxMesh.new()
	pier_mesh.size = Vector3(1.0, 1.0, 1.0)
	_create_simple_multimesh(tier_root, "TerraceButtressPiersMM", pier_mesh, _mat_stone_quay, pier_xforms, false)

	# 2. Sculptural cliff rocks (cliff_terrace_rock.glb or procedural rock fallback)
	_spawn_scene_multimesh_batch(
		tier_root,
		"TerraceCliffsMM",
		_scene_cliff_rock,
		cliff_xforms,
		_create_fallback_cliff_parts(),
		null,
		false,
		false
	)

	# 3. Inner City Houses (cast_shadows = TRUE) & Distant Outer Hillside Houses (cast_shadows = FALSE)
	var house_kinds: Array[String] = ["red_gable", "blue_balcony", "ochre_timber", "terracotta_terrace", "cream_spire"]
	for h_kind in house_kinds:
		var inner_xforms: Array[Transform3D] = _city_inner_house_batches[h_kind] as Array[Transform3D]
		var outer_xforms: Array[Transform3D] = _city_outer_house_batches[h_kind] as Array[Transform3D]
		var h_scene: PackedScene = _get_pixar_house_scene(h_kind)
		var fb_parts: Array[Dictionary] = _create_fallback_house_parts(h_kind)
		_spawn_scene_multimesh_batch(
			tier_root,
			"CityInnerHouses_%s_MM" % h_kind,
			h_scene,
			inner_xforms,
			fb_parts,
			null,
			true,
			true,
			h_kind
		)
		_spawn_scene_multimesh_batch(
			tier_root,
			"CityOuterHouses_%s_MM" % h_kind,
			h_scene,
			outer_xforms,
			fb_parts,
			null,
			true,
			false,
			h_kind
		)


# ===========================================================================
# 8. LIVING STREET PROPS & BOTANICAL FLORA (Grounded to exact 3-tier Y!)
# ===========================================================================

func _build_city_props_and_flora() -> void:
	var props_root: Node3D = Node3D.new()
	props_root.name = "CityPropsAndFlora"
	add_child(props_root)

	# --- 1. CORAL-PINK SAKURA BLOSSOM TREES (akasha_tree_blossom.glb) ---
	# 100% pure green meadow grass (ZERO on stone terraces, plazas, roads, or inside houses!)
	var blossom_spots: Array[Vector3] = [
		# Awakening Plaza outer sunny grass meadow (Tier 0 Y = 0.0)
		Vector3(-19.0, 0.0, 56.0), Vector3(19.0, 0.0, 56.0),
		Vector3(-16.0, 0.0, 64.0), Vector3(16.0, 0.0, 64.0),
		# Canal south grassy bank & Quiet Lakes Park grass meadow (Tier 0 Y = 0.0)
		Vector3(16.0, 0.0, -17.0), Vector3(28.0, 0.0, -17.5),
		Vector3(42.0, 0.0, -17.5), Vector3(36.5, 0.0, 24.0),
		Vector3(40.0, 0.0, 25.0), Vector3(32.0, 0.0, -4.0),
		Vector3(20.0, 0.0, -6.0),
		# North Terrace sunny outer green lawns (Tier 1 Y = 3.2)
		Vector3(-15.0, 0.0, -63.0), Vector3(15.0, 0.0, -63.0),
		Vector3(-42.0, 0.0, -62.5), Vector3(56.0, 0.0, -63.0),
		Vector3(-18.0, 0.0, -150.5), Vector3(18.0, 0.0, -150.5),
		Vector3(-56.0, 0.0, -150.0), Vector3(26.0, 0.0, -150.5),
	]
	for i in range(blossom_spots.size()):
		var raw_pos: Vector3 = blossom_spots[i]
		if not _is_pure_grass_spot(raw_pos.x, raw_pos.z, 3.6):
			continue
		var pos: Vector3 = Vector3(raw_pos.x, _get_city_ground_y(raw_pos.x, raw_pos.z), raw_pos.z)
		var sc: float = 0.94 + float(i % 4) * 0.07
		_tree_blossom_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, float(i) * 1.15, 0.0)).scaled(Vector3(sc, sc, sc)),
			pos
		))

	# --- 2. GOLDEN-AMBER WEEPING WILLOWS (akasha_tree_willow.glb) ---
	# Framing Awakening Plaza outer meadow, Canal grassy bank & Kronos green lawn
	var willow_gold_spots: Array[Vector3] = [
		Vector3(-30.0, 0.0, 58.0), Vector3(30.0, 0.0, 58.0),
		Vector3(-46.0, 0.0, 56.0), Vector3(46.0, 0.0, 52.0),
		Vector3(54.0, 0.0, 48.0), Vector3(42.0, 0.0, -15.0),
		Vector3(24.0, 0.0, -15.5), Vector3(58.0, 0.0, -62.0),
		Vector3(62.0, 0.0, -96.0), Vector3(62.0, 0.0, -120.0),
	]
	for i in range(willow_gold_spots.size()):
		var raw_pos: Vector3 = willow_gold_spots[i]
		if not _is_pure_grass_spot(raw_pos.x, raw_pos.z, 3.6):
			continue
		var pos: Vector3 = Vector3(raw_pos.x, _get_city_ground_y(raw_pos.x, raw_pos.z), raw_pos.z)
		var sc: float = 1.02 + float(i % 3) * 0.08
		_tree_willow_gold_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, float(i) * 1.42, 0.0)).scaled(Vector3(sc, sc, sc)),
			pos
		))

	# --- 3. ROSE-LAVENDER WEEPING WILLOWS (akasha_tree_willow.glb) ---
	# Enchanted outer grass meadow around Lantern Garden & Mira's Sanctuary (Tier 1 Y = 3.2)
	var willow_lav_spots: Array[Vector3] = [
		Vector3(-51.0, 0.0, -138.0), Vector3(-49.0, 0.0, -124.0),
		Vector3(-49.0, 0.0, -150.0), Vector3(-22.0, 0.0, -151.0),
		Vector3(-58.0, 0.0, -148.0), Vector3(22.0, 0.0, -151.0),
		Vector3(36.0, 0.0, -151.5), Vector3(62.0, 0.0, -148.0),
	]
	for i in range(willow_lav_spots.size()):
		var raw_pos: Vector3 = willow_lav_spots[i]
		if not _is_pure_grass_spot(raw_pos.x, raw_pos.z, 3.6):
			continue
		var pos: Vector3 = Vector3(raw_pos.x, _get_city_ground_y(raw_pos.x, raw_pos.z), raw_pos.z)
		var sc: float = 0.98 + float(i % 3) * 0.08
		_tree_willow_lavender_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, float(i) * 1.35, 0.0)).scaled(Vector3(sc, sc, sc)),
			pos
		))

	# --- 4. AZURE-TURQUOISE CELESTIAL BONSAI (akasha_tree_bonsai.glb) ---
	# Serene Lake of Silence grass meadow & Orion Library outer green lawn
	var bonsai_spots: Array[Vector3] = [
		Vector3(35.0, 0.0, 22.0), Vector3(48.0, 0.0, -8.5),
		Vector3(52.0, 0.0, -7.5), Vector3(62.0, 0.0, -7.0),
		Vector3(-58.0, 0.0, -61.5), Vector3(-62.0, 0.0, -96.0),
		Vector3(-62.0, 0.0, -122.0), Vector3(-54.0, 0.0, -151.0),
	]
	for i in range(bonsai_spots.size()):
		var raw_pos: Vector3 = bonsai_spots[i]
		if not _is_pure_grass_spot(raw_pos.x, raw_pos.z, 3.6):
			continue
		var pos: Vector3 = Vector3(raw_pos.x, _get_city_ground_y(raw_pos.x, raw_pos.z), raw_pos.z)
		var sc: float = 1.00 + float(i % 3) * 0.08
		_tree_bonsai_azure_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, float(i) * 1.28, 0.0)).scaled(Vector3(sc, sc, sc)),
			pos
		))

	# --- COMMIT ALL 4 UNIFIED FAIRYTALE TREE MULTIMESHES (4 draw calls, cast_shadows = ON!) ---
	_spawn_scene_multimesh_batch(
		props_root,
		"AkashaTrees_BlossomCoral_MM",
		_scene_tree_blossom,
		_tree_blossom_xforms,
		_create_fallback_tree_parts(_mat_tree_blossom),
		_mat_tree_blossom,
		false,
		true
	)
	_spawn_scene_multimesh_batch(
		props_root,
		"AkashaTrees_WillowGold_MM",
		_scene_tree_willow,
		_tree_willow_gold_xforms,
		_create_fallback_tree_parts(_mat_tree_willow_gold),
		_mat_tree_willow_gold,
		false,
		true
	)
	_spawn_scene_multimesh_batch(
		props_root,
		"AkashaTrees_WillowLavender_MM",
		_scene_tree_willow,
		_tree_willow_lavender_xforms,
		_create_fallback_tree_parts(_mat_tree_willow_lavender),
		_mat_tree_willow_lavender,
		false,
		true
	)
	_spawn_scene_multimesh_batch(
		props_root,
		"AkashaTrees_BonsaiAzure_MM",
		_scene_tree_bonsai,
		_tree_bonsai_azure_xforms,
		_create_fallback_tree_parts(_mat_tree_bonsai_azure),
		_mat_tree_bonsai_azure,
		false,
		true
	)

	# Lush bushes strictly on pure meadow grass (Awakening meadow, Quiet Lakes, Canal banks & North Terrace)
	var bush_spots: Array[Vector3] = [
		Vector3(-15.5, 0.0, 52.0), Vector3(15.5, 0.0, 52.0),
		Vector3(-24.0, 0.0, 56.0), Vector3(24.0, 0.0, 56.0),
		Vector3(22.0, 0.0, 17.0), Vector3(22.0, 0.0, 3.0),
		Vector3(36.0, 0.0, 20.0), Vector3(38.0, 0.0, -2.0),
		Vector3(48.0, 0.0, -6.0), Vector3(48.0, 0.0, 29.0),
		Vector3(-18.0, 0.0, -45.5), Vector3(18.0, 0.0, -45.5),
		Vector3(-36.0, 0.0, -45.5), Vector3(36.0, 0.0, -45.5),
		Vector3(18.0, 0.0, -17.0), Vector3(34.0, 0.0, -17.0),
		Vector3(-24.0, 0.0, -149.5), Vector3(-48.0, 0.0, -146.0),
		Vector3(-49.0, 0.0, -130.0), Vector3(24.0, 0.0, -149.5),
		Vector3(34.0, 0.0, -150.0), Vector3(62.5, 0.0, -126.0),
		Vector3(-54.0, 0.0, -63.0), Vector3(54.0, 0.0, -63.0),
		Vector3(-60.0, 0.0, -98.0), Vector3(60.0, 0.0, -98.0),
	]
	for i in range(bush_spots.size()):
		var rb: Vector3 = bush_spots[i]
		if not _is_pure_grass_spot(rb.x, rb.z, 2.4):
			continue
		var bpos: Vector3 = Vector3(rb.x, _get_city_ground_y(rb.x, rb.z), rb.z)
		_place_prop_scene(props_root, _scene_bush, "CityBush_%02d" % i, bpos, float(i) * 0.9, 1.0, "bush")

	# Sculpted Baroque Garden Urns flanking boulevard & Overlook (0 extra blocks near Upper Temple!)
	var urn_spots: Array[Vector3] = [
		Vector3(-6.2, 0.0, 38.2), Vector3(6.2, 0.0, 33.8),
		Vector3(-5.8, 0.0, -14.5), Vector3(5.8, 0.0, -14.5),
		Vector3(-7.4, 0.0, -58.5), Vector3(7.4, 0.0, -58.5),
		Vector3(-8.6, 0.0, -154.0), Vector3(8.6, 0.0, -154.0),
		Vector3(-12.5, 0.0, -184.0), Vector3(12.5, 0.0, -184.0),
	]
	var urn_xforms: Array[Transform3D] = []
	for i in range(urn_spots.size()):
		var rp: Vector3 = urn_spots[i]
		var ppos: Vector3 = Vector3(rp.x, _get_prop_surface_y(rp.x, rp.z), rp.z)
		urn_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, float(i) * 0.75, 0.0)),
			ppos
		))
	_spawn_scene_multimesh_batch(
		props_root,
		"CityGardenUrns_MM",
		_scene_prop_garden_urn,
		urn_xforms,
		_create_fallback_garden_urn_parts(),
		null,
		false,
		true
	)


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
		_add_cylinder_part(root, 0.28, 3.2, Vector3(0.0, 1.6, 0.0), _mat_trunk_silver)
		var crown: MeshInstance3D = MeshInstance3D.new()
		var sp: SphereMesh = SphereMesh.new()
		sp.radius = 2.1
		sp.height = 3.0
		crown.mesh = sp
		crown.position = Vector3(0.0, 3.8, 0.0)
		crown.material_override = _mat_tree_blossom
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
# 8B. 5 BLENDER CITY PROPS VIA MULTIMESH (60 FPS, 0 PRIMITIVE BLOCKS!)
#     1. Sculpted City Benches (prop_city_bench.glb)
#     2. 8 Intersection Signposts (prop_city_signpost.glb)
#     3. 24 Baroque Street Lamps (prop_street_lamp.glb)
#     4. 6 Festive Flower Carts (prop_flower_cart.glb)
#     5. 3 Town Bulletin Boards (prop_town_bulletin.glb)
# ===========================================================================

func _build_street_life_and_akasha_magic() -> void:
	var street_root: Node3D = Node3D.new()
	street_root.name = "StreetLifeAndAkashaMagic"
	add_child(street_root)

	# --- 1. SCULPTED CITY BENCHES (prop_city_bench.glb) ---
	var bench_xforms: Array[Transform3D] = []
	for pb in _park_bench_xforms:
		bench_xforms.append(pb)

	# Boulevard benches strictly outside road curbs & alleys, grounded at exact surface Y
	var blvd_zs: Array[float] = [21.6, -3.0, -9.0, -61.0, -65.0, -92.0, -120.0]
	for b_idx in range(blvd_zs.size()):
		var bz: float = blvd_zs[b_idx]
		var bx_off: float = 6.25 if bz > -30.0 else 7.15
		for side_val in [-1.0, 1.0]:
			var side: float = float(side_val)
			var face_in: float = -PI * 0.5 if side > 0.0 else PI * 0.5
			var gx: float = side * bx_off
			var gy: float = _get_prop_surface_y(gx, bz)
			bench_xforms.append(Transform3D(
				Basis.from_euler(Vector3(0.0, face_in, 0.0)),
				Vector3(gx, gy, bz)
			))

	# Embankment benches overlooking the Shining Canal (South bank Tier 0)
	var quay_xs: Array[float] = [-44.0, -30.0, -18.0, 18.0, 30.0, 44.0]
	for q_idx in range(quay_xs.size()):
		var qx: float = quay_xs[q_idx]
		bench_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, PI, 0.0)),
			Vector3(qx, _get_prop_surface_y(qx, -23.4), -23.4)
		))

	# Upper Overlook Terrace scenic benches (Tier 2, Y = 5.6 + SIDE_STREET_TOP_Y)
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		for oz in [-179.0, -189.0]:
			var face_in: float = -PI * 0.5 if side > 0.0 else PI * 0.5
			var ox: float = side * 20.5
			bench_xforms.append(Transform3D(
				Basis.from_euler(Vector3(0.0, face_in, 0.0)),
				Vector3(ox, _get_prop_surface_y(ox, oz), oz)
			))

	_spawn_scene_multimesh_batch(
		street_root,
		"CityBenches_MM",
		_scene_prop_bench,
		bench_xforms,
		_create_fallback_bench_parts(),
		null,
		false,
		true
	)

	# --- 2. 8 DIRECTIONAL SIGNPOSTS AT ALL MAIN INTERSECTIONS (prop_city_signpost.glb) ---
	var signpost_specs: Array[Dictionary] = [
		{"pos": Vector3(-9.2, TIER_0_Y, 37.5), "yaw": PI * 0.25},      # 1. Площадь Пробуждения
		{"pos": Vector3(-7.6, TIER_0_Y, 13.8), "yaw": -PI * 0.25},     # 2. Въезд в Школу Юных Душ
		{"pos": Vector3(7.6, TIER_0_Y, 15.2), "yaw": PI * 0.75},       # 3. Въезд в Парк Тишины
		{"pos": Vector3(-8.2, TIER_1_Y, -56.5), "yaw": PI * 0.25},     # 4. За Мостом Памяти
		{"pos": Vector3(8.8, TIER_1_Y, -70.5), "yaw": -PI * 0.75},     # 5. У Армиллярной Сферы
		{"pos": Vector3(-33.5, TIER_1_Y, -72.8), "yaw": PI * 0.25},    # 6. У Библиотеки Ориона
		{"pos": Vector3(33.5, TIER_1_Y, -72.8), "yaw": -PI * 0.25},    # 7. У Башни Кроноса
		{"pos": Vector3(-8.2, TIER_1_Y, -132.5), "yaw": PI * 0.25},    # 8. Между Садом Фонариков и Домом Миры
	]
	var signpost_xforms: Array[Transform3D] = []
	for sp_spec in signpost_specs:
		var sp_p: Vector3 = sp_spec["pos"] as Vector3
		var sp_y: float = _get_prop_surface_y(sp_p.x, sp_p.z)
		signpost_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, float(sp_spec["yaw"]), 0.0)),
			Vector3(sp_p.x, sp_y, sp_p.z)
		))
	_spawn_scene_multimesh_batch(
		street_root,
		"CitySignposts_MM",
		_scene_prop_signpost,
		signpost_xforms,
		_create_fallback_signpost_parts(),
		null,
		false,
		true
	)

	# --- 3. 24 BAROQUE STREET LAMPS (prop_street_lamp.glb, strictly clear of roads & benches!) ---
	var lamp_spots: Array[Vector3] = [
		# Main Boulevard South (6 — cleanly clear of SideStreet_SW, Alley_SW_Cross & Plaza_Awakening)
		Vector3(-6.4, 0.0, 35.2), Vector3(6.4, 0.0, 31.8),
		Vector3(-6.4, 0.0, 14.8), Vector3(6.4, 0.0, 17.5),
		Vector3(-6.4, 0.0, -12.0), Vector3(6.4, 0.0, -12.0),
		# Canal Embankment (2)
		Vector3(-22.0, 0.0, -23.6), Vector3(22.0, 0.0, -23.6),
		# Side Streets & Pocket Parks (4)
		Vector3(-27.0, 0.0, 40.5), Vector3(24.2, 0.0, 34.0),
		Vector3(-35.5, 0.0, -101.0), Vector3(32.5, 0.0, -101.0),
		# Main Boulevard North (6 — Lamp_13/14 at Z=-68.5 clear of Bench_Blvd at Z=-65.0)
		Vector3(-7.4, 0.0, -68.5), Vector3(7.4, 0.0, -68.5),
		Vector3(-7.4, 0.0, -96.0), Vector3(7.4, 0.0, -96.0),
		Vector3(-7.4, 0.0, -126.0), Vector3(7.4, 0.0, -126.0),
		# Upper Overlook Terrace (4)
		Vector3(-13.0, 0.0, -174.0), Vector3(13.0, 0.0, -174.0),
		Vector3(-13.0, 0.0, -194.0), Vector3(13.0, 0.0, -194.0),
		# Upper Temple Forecourt (2 — seated on Plaza_ImperialForecourt R=9.8 top +0.085, 0 extra blocks!)
		Vector3(-8.8, 0.0, -217.5), Vector3(8.8, 0.0, -217.5),
	]
	var lamp_xforms: Array[Transform3D] = []
	for l_idx in range(lamp_spots.size()):
		var lp: Vector3 = lamp_spots[l_idx]
		var ly: float = _get_prop_surface_y(lp.x, lp.z)
		var l_yaw: float = -PI * 0.5 if lp.x > 0.0 else PI * 0.5
		lamp_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, l_yaw, 0.0)),
			Vector3(lp.x, ly, lp.z)
		))
	_spawn_scene_multimesh_batch(
		street_root,
		"CityStreetLamps_MM",
		_scene_prop_lamp,
		lamp_xforms,
		_create_fallback_lamp_parts(),
		null,
		false,
		true
	)

	# --- 4. 6 FESTIVE FLOWER CARTS (prop_flower_cart.glb, seated cleanly on exact surface Y) ---
	var cart_specs: Array[Dictionary] = [
		{"pos": Vector3(10.8, TIER_0_Y, 23.2), "yaw": -PI * 0.35},      # 1. У Кафе «Тёплая Чашка»
		{"pos": Vector3(-10.8, TIER_0_Y, 23.2), "yaw": PI * 0.35},      # 2. У Лавки Воспоминаний
		{"pos": Vector3(-12.2, TIER_1_Y, -100.5), "yaw": PI * 0.40},    # 3. У Торгового Центра «Галерея Миров»
		{"pos": Vector3(10.2, TIER_0_Y, 45.5), "yaw": -PI * 0.65},      # 4. На Площади Пробуждения
		{"pos": Vector3(-39.7, TIER_0_Y, 50.4), "yaw": PI * 0.75},      # 5. В сквере «Аллея Сакуры» (2*PI/3, R=7.4)
		{"pos": Vector3(39.7, TIER_0_Y, 44.4), "yaw": -PI * 0.75},      # 6. В сквере «Сад Золотых Ив» (PI/3, R=7.4)
	]
	var cart_xforms: Array[Transform3D] = []
	for c_spec in cart_specs:
		var cp: Vector3 = c_spec["pos"] as Vector3
		var cy: float = _get_prop_surface_y(cp.x, cp.z)
		cart_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, float(c_spec["yaw"]), 0.0)),
			Vector3(cp.x, cy, cp.z)
		))
	_spawn_scene_multimesh_batch(
		street_root,
		"CityFlowerCarts_MM",
		_scene_prop_flower_cart,
		cart_xforms,
		_create_fallback_flower_cart_parts(),
		null,
		false,
		true
	)

	# --- 5. 3 TOWN BULLETIN BOARDS (prop_town_bulletin.glb, seated cleanly inside resized plazas) ---
	var bulletin_specs: Array[Dictionary] = [
		{"pos": Vector3(-33.2, TIER_1_Y, 13.6), "yaw": PI * 0.35},      # 1. У входа в Школу Юных Душ (inside R=7.6)
		{"pos": Vector3(-9.8, TIER_0_Y, 52.0), "yaw": PI * 0.55},       # 2. На Площади Пробуждения (clear of SW Street)
		{"pos": Vector3(-38.5, TIER_1_Y, -72.2), "yaw": PI * 0.15},     # 3. У Библиотеки Ориона (inside R=7.6)
	]
	var bulletin_xforms: Array[Transform3D] = []
	for b_spec in bulletin_specs:
		var bp: Vector3 = b_spec["pos"] as Vector3
		var by: float = _get_prop_surface_y(bp.x, bp.z)
		bulletin_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, float(b_spec["yaw"]), 0.0)),
			Vector3(bp.x, by, bp.z)
		))
	_spawn_scene_multimesh_batch(
		street_root,
		"CityTownBulletins_MM",
		_scene_prop_bulletin,
		bulletin_xforms,
		_create_fallback_bulletin_parts(),
		null,
		false,
		true
	)

	# --- 6. 8 OUTDOOR CAFE BISTRO SETS (prop_cafe_bistro_set.glb, seated cleanly on exact surface Y) ---
	var bistro_specs: Array[Dictionary] = [
		# 3 sets on sunlit courtyard outside Starlight Cafe (building X in [12.65..22.35], Z in [22.6..33.4])
		{"pos": Vector3(14.0, TIER_0_Y, 20.8), "yaw": 0.25},
		{"pos": Vector3(17.8, TIER_0_Y, 20.5), "yaw": -0.15},
		{"pos": Vector3(21.6, TIER_0_Y, 20.8), "yaw": -0.40},
		# 3 sets along scenic Canal South Promenade (clear of lamps at +/-22,-23.6, benches at -23.4 & railing at -25)
		{"pos": Vector3(-12.5, TIER_0_Y, -22.4), "yaw": 0.18},
		{"pos": Vector3(12.5, TIER_0_Y, -22.4), "yaw": -0.18},
		{"pos": Vector3(25.5, TIER_0_Y, -22.4), "yaw": 0.30},
		# 2 sets on Awakening Plaza SE edge & Grand Mall Tier 1 terrace (strictly clear of all props & spawn)
		{"pos": Vector3(8.6, TIER_0_Y, 51.2), "yaw": -0.55},
		{"pos": Vector3(-13.2, TIER_1_Y, -113.0), "yaw": 0.45},
	]
	var bistro_xforms: Array[Transform3D] = []
	for bs_spec in bistro_specs:
		var bsp: Vector3 = bs_spec["pos"] as Vector3
		var bsy: float = _get_prop_surface_y(bsp.x, bsp.z)
		bistro_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, float(bs_spec["yaw"]), 0.0)),
			Vector3(bsp.x, bsy, bsp.z)
		))
	_spawn_scene_multimesh_batch(
		street_root,
		"CityCafeBistros_MM",
		_scene_prop_cafe_bistro,
		bistro_xforms,
		_create_fallback_cafe_bistro_parts(),
		null,
		false,
		true
	)

	# --- 7. 3D STYLIZED GRASS & 5-PETAL DAISY CLUSTERS (prop_grass_daisy_cluster.glb) ---
	var grass_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	grass_rng.seed = 202608
	var grass_xforms: Array[Transform3D] = []
	var placed_grass_pts: Array[Vector2] = []

	# Zone A: Inside the 4 circular pocket park inner lawns (r in [1.85..4.55], strictly clear of trees & stone curb)
	var pk_centers: Array[Vector3] = [
		Vector3(-36.0, TIER_0_Y, 44.0),
		Vector3(36.0, TIER_0_Y, 38.0),
		Vector3(-41.0, TIER_1_Y, -108.0),
		Vector3(38.0, TIER_1_Y, -108.0),
	]
	for pk_c in pk_centers:
		var added_in_pk: int = 0
		for _attempt in range(120):
			if added_in_pk >= 15:
				break
			var ang: float = grass_rng.randf_range(0.0, TAU)
			var rad: float = sqrt(grass_rng.randf_range(1.85 * 1.85, 4.55 * 4.55))
			var gx: float = pk_c.x + cos(ang) * rad
			var gz: float = pk_c.z + sin(ang) * rad
			# Keep clear of the 2 secondary hero tree trunks at (-2.6, 2.2) and (2.8, 1.8)
			var d_t1: float = Vector2(gx - (pk_c.x - 2.6), gz - (pk_c.z + 2.2)).length()
			var d_t2: float = Vector2(gx - (pk_c.x + 2.8), gz - (pk_c.z + 1.8)).length()
			if d_t1 < 1.35 or d_t2 < 1.35:
				continue
			if gx < -25.2 and gz < 33.8 and pk_c.y < 1.0:
				continue
			if gx > -30.8 and absf(gz + 108.0) < 10.2 and pk_c.x < 0.0 and pk_c.y > 1.0:
				continue
			var too_close: bool = false
			for pt in placed_grass_pts:
				if pt.distance_squared_to(Vector2(gx, gz)) < 1.35 * 1.35:
					too_close = true
					break
			if too_close:
				continue
			var sc: float = grass_rng.randf_range(0.85, 1.25)
			var yaw: float = grass_rng.randf_range(0.0, TAU)
			placed_grass_pts.append(Vector2(gx, gz))
			grass_xforms.append(Transform3D(
				Basis.from_euler(Vector3(0.0, yaw, 0.0)) * Basis.from_scale(Vector3(sc, sc, sc)),
				Vector3(gx, pk_c.y + PARK_LAWN_TOP_Y, gz)
			))
			added_in_pk += 1

	# Zone B: Quiet Lakes Park shoreline & sunlit meadow (X in [34..62], Z in [-12..28])
	var added_lake: int = 0
	for _attempt in range(500):
		if added_lake >= 58:
			break
		var gx: float = grass_rng.randf_range(34.0, 62.0)
		var gz: float = grass_rng.randf_range(-12.0, 28.0)
		if not _is_clear_for_grass_cluster(gx, gz, placed_grass_pts):
			continue
		var sc: float = grass_rng.randf_range(0.88, 1.30)
		var yaw: float = grass_rng.randf_range(0.0, TAU)
		placed_grass_pts.append(Vector2(gx, gz))
		grass_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, yaw, 0.0)) * Basis.from_scale(Vector3(sc, sc, sc)),
			Vector3(gx, _get_prop_surface_y(gx, gz), gz)
		))
		added_lake += 1

	# Zone C1: Canal North Meadow Bank (sunny strip between Canal North Quay and North Terrace wall)
	var added_canal: int = 0
	for _attempt in range(360):
		if added_canal >= 34:
			break
		var side_sign: float = -1.0 if grass_rng.randf() < 0.5 else 1.0
		var gx: float = side_sign * grass_rng.randf_range(10.0, 58.0)
		var gz: float = grass_rng.randf_range(-49.8, -41.4)
		if not _is_clear_for_grass_cluster(gx, gz, placed_grass_pts):
			continue
		var sc: float = grass_rng.randf_range(0.85, 1.28)
		var yaw: float = grass_rng.randf_range(0.0, TAU)
		placed_grass_pts.append(Vector2(gx, gz))
		grass_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, yaw, 0.0)) * Basis.from_scale(Vector3(sc, sc, sc)),
			Vector3(gx, _get_prop_surface_y(gx, gz), gz)
		))
		added_canal += 1

	# Zone C2: West School Hill Base & SW Meadow Verges
	var added_west: int = 0
	for _attempt in range(260):
		if added_west >= 14:
			break
		var gx: float = grass_rng.randf_range(-22.0, -8.5)
		var gz: float = grass_rng.randf_range(-19.5, 2.2) if grass_rng.randf() < 0.7 else grass_rng.randf_range(33.5, 39.5)
		if not _is_clear_for_grass_cluster(gx, gz, placed_grass_pts):
			continue
		var sc: float = grass_rng.randf_range(0.85, 1.24)
		var yaw: float = grass_rng.randf_range(0.0, TAU)
		placed_grass_pts.append(Vector2(gx, gz))
		grass_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, yaw, 0.0)) * Basis.from_scale(Vector3(sc, sc, sc)),
			Vector3(gx, _get_prop_surface_y(gx, gz), gz)
		))
		added_west += 1

	# Zone C3: North Terrace Green Edges (outer east/west meadow flanks & north rim verges)
	var added_north: int = 0
	for _attempt in range(360):
		if added_north >= 20:
			break
		var side_sign: float = -1.0 if grass_rng.randf() < 0.5 else 1.0
		var gx: float = 0.0
		var gz: float = 0.0
		if grass_rng.randf() < 0.55:
			gx = side_sign * grass_rng.randf_range(49.0, 61.5)
			gz = grass_rng.randf_range(-155.0, -56.0)
		else:
			gx = side_sign * grass_rng.randf_range(11.5, 58.0)
			gz = grass_rng.randf_range(-155.2, -147.0)
		if not _is_clear_for_grass_cluster(gx, gz, placed_grass_pts):
			continue
		var sc: float = grass_rng.randf_range(0.86, 1.28)
		var yaw: float = grass_rng.randf_range(0.0, TAU)
		placed_grass_pts.append(Vector2(gx, gz))
		grass_xforms.append(Transform3D(
			Basis.from_euler(Vector3(0.0, yaw, 0.0)) * Basis.from_scale(Vector3(sc, sc, sc)),
			Vector3(gx, _get_prop_surface_y(gx, gz), gz)
		))
		added_north += 1

	_spawn_scene_multimesh_batch(
		street_root,
		"CityGrassDaisies_MM",
		_scene_prop_grass_daisy,
		grass_xforms,
		_create_fallback_grass_daisy_parts(),
		null,
		false
	)


func _is_clear_for_grass_cluster(x: float, z: float, placed_pts: Array[Vector2]) -> bool:
	# 1. Must satisfy strict 100% grass-only rule (zero stone decks, roads, plazas, canal, houses)
	if not _is_pure_grass_spot(x, z, 1.4):
		return false

	# 2. Must sit strictly on pure meadow ground (not raised plaza/park lawn discs)
	var y_c: float = _get_city_ground_y(x, z)
	if absf(_get_prop_surface_y(x, z) - y_c) > 0.005:
		return false

	# 3. Extra margin from south canal benches/lamps/bistros & Baroque Palace
	if z >= -41.0 and z <= -20.5:
		return false
	if Vector2(x, z).distance_to(Vector2(0.0, -280.0)) < 84.0:
		return false

	# 4. Minimum spacing between grass clusters
	var q_pt: Vector2 = Vector2(x, z)
	for pt in placed_pts:
		if pt.distance_squared_to(q_pt) < 1.65 * 1.65:
			return false
	return true


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
# 9. LANTERN GARDEN FLOATING PIXAR SKY LANTERNS (MultiMesh, Tier 1 Y = 3.2)
#    18 gently rising & swaying multi-material Pixar Sky Lanterns (prop_sky_lantern.glb)
# ===========================================================================

func _build_lantern_garden_particles() -> void:
	var lantern_root: Node3D = Node3D.new()
	lantern_root.name = "LanternGardenSkyLanterns"
	lantern_root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(lantern_root)

	var sub_parts: Array[Dictionary] = []
	if _scene_sky_lantern != null:
		var temp_inst: Node = _scene_sky_lantern.instantiate()
		if temp_inst is Node3D:
			var temp_root: Node3D = temp_inst as Node3D
			var min_y: float = _find_min_local_y(temp_root, Transform3D.IDENTITY)
			var ground_offset_y: float = -min_y if min_y < 1.0e8 else 0.0
			var ground_xf: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0.0, ground_offset_y, 0.0))
			_collect_submesh_parts(temp_root, ground_xf, sub_parts, null, false, "")
		temp_inst.free()

	if sub_parts.is_empty():
		sub_parts = _create_fallback_sky_lantern_parts()

	var lantern_count: int = 18
	var center_x: float = -34.0
	var center_z: float = -138.0
	var min_y_h: float = TIER_1_Y + 2.2
	var max_y_h: float = TIER_1_Y + 14.0
	var y_span: float = max_y_h - min_y_h

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 202699

	_sky_lantern_instances.clear()
	_sky_lantern_batches.clear()

	for i in range(lantern_count):
		var ang: float = (TAU * float(i)) / float(lantern_count) + rng.randf_range(-0.18, 0.18)
		var rad: float = rng.randf_range(2.6, 10.4)
		var bx: float = center_x + cos(ang) * rad
		var bz: float = center_z + sin(ang) * rad
		var start_h: float = (y_span * float(i)) / float(lantern_count) + rng.randf_range(0.0, 0.55)
		_sky_lantern_instances.append({
			"base_x": bx,
			"base_z": bz,
			"start_h": fposmod(start_h, y_span),
			"rise_speed": rng.randf_range(0.42, 0.68),
			"phase": rng.randf_range(0.0, TAU),
			"sway_r": rng.randf_range(0.32, 0.72),
			"yaw_speed": rng.randf_range(-0.35, 0.35),
			"scale": rng.randf_range(0.88, 1.22),
		})

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
		mm.instance_count = lantern_count
		for i in range(lantern_count):
			var info: Dictionary = _sky_lantern_instances[i]
			var init_y: float = min_y_h + float(info["start_h"])
			var sc: float = float(info["scale"])
			var init_xf: Transform3D = Transform3D(
				Basis.from_scale(Vector3(sc, sc, sc)),
				Vector3(float(info["base_x"]), init_y, float(info["base_z"]))
			)
			mm.set_instance_transform(i, init_xf * p_local_xf)

		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.name = "LanternGardenSkyLanterns_MM_%d" % p_idx
		mmi.multimesh = mm
		if p_mat != null:
			mmi.material_override = p_mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		lantern_root.add_child(mmi)

		_sky_lantern_batches.append({
			"mm": mm,
			"local_xf": p_local_xf,
		})


func _create_fallback_sky_lantern_parts() -> Array[Dictionary]:
	var silk_mat: StandardMaterial3D = StandardMaterial3D.new()
	silk_mat.albedo_color = Color("#FFE6A6")
	silk_mat.roughness = 0.32
	silk_mat.emission_enabled = true
	silk_mat.emission = Color("#FFBE55")
	silk_mat.emission_energy_multiplier = 2.0

	var body: SphereMesh = SphereMesh.new()
	body.radius = 0.24
	body.height = 0.56
	body.radial_segments = 28
	body.rings = 16

	var rim: TorusMesh = TorusMesh.new()
	rim.inner_radius = 0.14
	rim.outer_radius = 0.19
	rim.rings = 28
	rim.ring_segments = 12

	var cap: CylinderMesh = CylinderMesh.new()
	cap.top_radius = 0.11
	cap.bottom_radius = 0.16
	cap.height = 0.06
	cap.radial_segments = 24

	return [
		{"mesh": body, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 0.32, 0.0)), "material": silk_mat},
		{"mesh": rim, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 0.06, 0.0)), "material": _mat_gold_trim},
		{"mesh": cap, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 0.60, 0.0)), "material": _mat_gold_trim},
	]


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
		sp.radial_segments = 32
		sp.rings = 16
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
		crystal.radial_segments = 24
		mesh_inst.mesh = crystal
	floater.add_child(mesh_inst)

	var halo: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.44
	torus.outer_radius = 0.50
	torus.rings = 40
	torus.ring_segments = 16
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
# 11. 3D QUEST BEACON (Subtle Low-Profile Golden Ground Halo Ring Only)
# ===========================================================================

func _build_quest_beacon() -> void:
	_quest_beacon_root = Node3D.new()
	_quest_beacon_root.name = "QuestBeacon"
	_quest_beacon_root.visible = false
	_quest_beacon_root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_quest_beacon_root)

	_mat_beacon_ring = StandardMaterial3D.new()
	_mat_beacon_ring.albedo_color = Color(1.0, 0.86, 0.42, 0.42)
	_mat_beacon_ring.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_beacon_ring.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_quest_beacon_ring = MeshInstance3D.new()
	_quest_beacon_ring.name = "BeaconGroundRing"
	var ring_torus: TorusMesh = TorusMesh.new()
	ring_torus.inner_radius = 1.05
	ring_torus.outer_radius = 1.24
	ring_torus.rings = 48
	ring_torus.ring_segments = 16
	_quest_beacon_ring.mesh = ring_torus
	_quest_beacon_ring.position = Vector3(0.0, 0.09, 0.0)
	_quest_beacon_ring.scale = Vector3(1.0, 0.16, 1.0)
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


# ===========================================================================
# 12. MULTIMESH SUB-MESH EXTRACTION, PROCEDURAL FALLBACKS & GEOMETRY HELPERS
# ===========================================================================

func _create_simple_multimesh(
	parent: Node3D,
	mm_name: String,
	mesh_res: Mesh,
	mat_override: Material,
	xforms: Array[Transform3D],
	cast_shadows: bool = false
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
	mmi.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if cast_shadows
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(mmi)


## Extracts every sub-mesh from a PackedScene (grounded to min_y = 0) and renders
## all transforms via MultiMeshInstance3D per sub-mesh, upgrading house walls/roofs
## to pixar_building_facade.gdshader and windows to pixar_window_glow.gdshader at 60 FPS!
func _spawn_scene_multimesh_batch(
	parent: Node3D,
	batch_name: String,
	scene: PackedScene,
	xforms: Array[Transform3D],
	fallback_parts: Array[Dictionary],
	canopy_tint_override: Material,
	apply_facade_shader: bool = false,
	cast_shadows: bool = false,
	house_palette_kind: String = ""
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
			_collect_submesh_parts(
				temp_root,
				ground_xf,
				sub_parts,
				canopy_tint_override,
				apply_facade_shader,
				house_palette_kind
			)
		temp_inst.free()

	if sub_parts.is_empty():
		sub_parts = fallback_parts

	var shadow_mode: GeometryInstance3D.ShadowCastingSetting = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if cast_shadows
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)

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
		mmi.cast_shadow = shadow_mode
		mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		parent.add_child(mmi)


func _collect_submesh_parts(
	node: Node,
	parent_xf: Transform3D,
	out_parts: Array[Dictionary],
	canopy_tint_override: Material,
	apply_facade_shader: bool = false,
	house_palette_kind: String = ""
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
							var upgraded_mat: Material = _upgrade_to_facade_material(eff_mat, house_palette_kind)
							dup_mesh.surface_set_material(s_idx, upgraded_mat)
						elif canopy_tint_override != null and surf_count > 1:
							var s_name: String = ""
							if eff_mat != null:
								s_name = eff_mat.resource_name.to_lower()
							var is_trunk: bool = (
								s_name.contains("trunk")
								or s_name.contains("bark")
								or s_name.contains("wood")
								or s_name.contains("stem")
							)
							var is_canopy: bool = (
								s_name.contains("canopy")
								or s_name.contains("leaf")
								or s_name.contains("crown")
								or s_name.contains("foliage")
								or s_name.contains("blossom")
								or s_name.contains("petal")
								or s_name.contains("willow")
								or s_name.contains("frond")
							)
							if is_trunk:
								dup_mesh.surface_set_material(s_idx, _mat_trunk_silver)
							elif is_canopy or s_idx > 0:
								dup_mesh.surface_set_material(s_idx, canopy_tint_override)
					final_mesh = dup_mesh

			if apply_facade_shader and chosen_mat != null:
				chosen_mat = _upgrade_to_facade_material(chosen_mat, house_palette_kind)

			if canopy_tint_override != null and surf_count <= 1:
				var aabb: AABB = mi.mesh.get_aabb()
				var center_y: float = (cur_xf * aabb.get_center()).y
				var lower_name: String = mi.name.to_lower()
				var surf_mat_name: String = ""
				if surf_count == 1:
					var sm0: Material = mi.mesh.surface_get_material(0)
					if sm0 != null:
						surf_mat_name = sm0.resource_name.to_lower()
				var is_trunk_single: bool = (
					lower_name.contains("trunk")
					or lower_name.contains("bark")
					or lower_name.contains("wood")
					or lower_name.contains("stem")
					or surf_mat_name.contains("trunk")
					or surf_mat_name.contains("bark")
					or surf_mat_name.contains("wood")
				)
				var is_canopy_single: bool = (
					lower_name.contains("leaf")
					or lower_name.contains("canopy")
					or lower_name.contains("crown")
					or lower_name.contains("foliage")
					or lower_name.contains("blossom")
					or lower_name.contains("petal")
					or lower_name.contains("willow")
					or lower_name.contains("frond")
					or surf_mat_name.contains("canopy")
					or surf_mat_name.contains("leaf")
					or surf_mat_name.contains("foliage")
					or surf_mat_name.contains("blossom")
					or center_y > 1.8
				)
				if is_trunk_single:
					chosen_mat = _mat_trunk_silver
				elif is_canopy_single:
					chosen_mat = canopy_tint_override

			out_parts.append({
				"mesh": final_mesh,
				"xform": cur_xf,
				"material": chosen_mat,
			})

	for child in node.get_children():
		_collect_submesh_parts(child, cur_xf, out_parts, canopy_tint_override, apply_facade_shader, house_palette_kind)


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
		tower_cyl.radial_segments = 24
		parts.append({
			"mesh": tower_cyl,
			"xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 3.3, 0.0)),
			"material": wall_mat,
		})
		var spire_cone: CylinderMesh = CylinderMesh.new()
		spire_cone.top_radius = 0.08
		spire_cone.bottom_radius = 2.95
		spire_cone.height = 4.8
		spire_cone.radial_segments = 24
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
	rock_cyl.radial_segments = 24
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
	trunk.radial_segments = 24

	var crown: SphereMesh = SphereMesh.new()
	crown.radius = 2.25
	crown.height = 3.4
	crown.radial_segments = 24
	crown.rings = 14

	return [
		{
			"mesh": trunk,
			"xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 1.6, 0.0)),
			"material": _mat_trunk_silver,
		},
		{
			"mesh": crown,
			"xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 4.1, 0.0)),
			"material": foliage_mat,
		},
	]


func _create_fallback_bench_parts() -> Array[Dictionary]:
	var seat: BoxMesh = BoxMesh.new()
	seat.size = Vector3(1.9, 0.10, 0.56)
	var back: BoxMesh = BoxMesh.new()
	back.size = Vector3(1.9, 0.42, 0.08)
	var leg: BoxMesh = BoxMesh.new()
	leg.size = Vector3(0.12, 0.44, 0.52)
	return [
		{"mesh": seat, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 0.46, 0.0)), "material": _mat_bench_wood},
		{"mesh": back, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 0.78, -0.24)), "material": _mat_bench_wood},
		{"mesh": leg, "xform": Transform3D(Basis.IDENTITY, Vector3(-0.78, 0.22, 0.0)), "material": _mat_stone_quay},
		{"mesh": leg, "xform": Transform3D(Basis.IDENTITY, Vector3(0.78, 0.22, 0.0)), "material": _mat_stone_quay},
	]


func _create_fallback_signpost_parts() -> Array[Dictionary]:
	var pole: CylinderMesh = CylinderMesh.new()
	pole.top_radius = 0.08
	pole.bottom_radius = 0.11
	pole.height = 2.6
	pole.radial_segments = 24
	var arrow_a: BoxMesh = BoxMesh.new()
	arrow_a.size = Vector3(0.95, 0.24, 0.06)
	var arrow_b: BoxMesh = BoxMesh.new()
	arrow_b.size = Vector3(0.06, 0.24, 0.90)
	return [
		{"mesh": pole, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 1.3, 0.0)), "material": _mat_bench_wood},
		{"mesh": arrow_a, "xform": Transform3D(Basis.IDENTITY, Vector3(0.32, 2.25, 0.0)), "material": _mat_gold_trim},
		{"mesh": arrow_b, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 1.92, 0.28)), "material": _mat_gold_trim},
	]


func _create_fallback_lamp_parts() -> Array[Dictionary]:
	var base: CylinderMesh = CylinderMesh.new()
	base.top_radius = 0.18
	base.bottom_radius = 0.28
	base.height = 0.55
	base.radial_segments = 24
	var pole: CylinderMesh = CylinderMesh.new()
	pole.top_radius = 0.07
	pole.bottom_radius = 0.10
	pole.height = 3.2
	pole.radial_segments = 24
	var globe: SphereMesh = SphereMesh.new()
	globe.radius = 0.26
	globe.height = 0.52
	globe.radial_segments = 24
	globe.rings = 14
	return [
		{"mesh": base, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 0.275, 0.0)), "material": _mat_stone_quay},
		{"mesh": pole, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 2.0, 0.0)), "material": _mat_gold_trim},
		{"mesh": globe, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 3.72, 0.0)), "material": _mat_warm_window},
	]


func _create_fallback_flower_cart_parts() -> Array[Dictionary]:
	var body: BoxMesh = BoxMesh.new()
	body.size = Vector3(1.6, 0.58, 0.92)
	var canopy: PrismMesh = PrismMesh.new()
	canopy.size = Vector3(1.85, 0.45, 1.15)
	var blooms: SphereMesh = SphereMesh.new()
	blooms.radius = 0.42
	blooms.height = 0.50
	blooms.radial_segments = 24
	blooms.rings = 12
	return [
		{"mesh": body, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 0.62, 0.0)), "material": _mat_bench_wood},
		{"mesh": canopy, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 2.05, 0.0)), "material": _mat_roof_terracotta},
		{"mesh": blooms, "xform": Transform3D(Basis.IDENTITY, Vector3(-0.38, 1.05, 0.0)), "material": _mat_foliage_sakura},
		{"mesh": blooms, "xform": Transform3D(Basis.IDENTITY, Vector3(0.38, 1.05, 0.0)), "material": _mat_foliage_gold},
	]


func _create_fallback_bulletin_parts() -> Array[Dictionary]:
	var post: BoxMesh = BoxMesh.new()
	post.size = Vector3(0.14, 2.2, 0.14)
	var board: BoxMesh = BoxMesh.new()
	board.size = Vector3(1.85, 1.15, 0.12)
	var roof: PrismMesh = PrismMesh.new()
	roof.size = Vector3(2.15, 0.42, 0.65)
	return [
		{"mesh": post, "xform": Transform3D(Basis.IDENTITY, Vector3(-0.88, 1.1, 0.0)), "material": _mat_bench_wood},
		{"mesh": post, "xform": Transform3D(Basis.IDENTITY, Vector3(0.88, 1.1, 0.0)), "material": _mat_bench_wood},
		{"mesh": board, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 1.48, 0.0)), "material": _mat_marble_wall},
		{"mesh": roof, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 2.38, 0.0)), "material": _mat_blue_roof},
	]


func _create_fallback_ornate_railing_parts() -> Array[Dictionary]:
	var plinth: BoxMesh = BoxMesh.new()
	plinth.size = Vector3(3.0, 0.18, 0.34)
	var handrail: BoxMesh = BoxMesh.new()
	handrail.size = Vector3(3.0, 0.14, 0.30)
	var baluster: CylinderMesh = CylinderMesh.new()
	baluster.top_radius = 0.07
	baluster.bottom_radius = 0.09
	baluster.height = 0.80
	baluster.radial_segments = 24
	return [
		{"mesh": plinth, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 0.09, 0.0)), "material": _mat_stone_quay},
		{"mesh": handrail, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 1.05, 0.0)), "material": _mat_marble_wall},
		{"mesh": baluster, "xform": Transform3D(Basis.IDENTITY, Vector3(-1.0, 0.58, 0.0)), "material": _mat_marble_wall},
		{"mesh": baluster, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 0.58, 0.0)), "material": _mat_marble_wall},
		{"mesh": baluster, "xform": Transform3D(Basis.IDENTITY, Vector3(1.0, 0.58, 0.0)), "material": _mat_marble_wall},
	]


func _create_fallback_railing_pillar_parts() -> Array[Dictionary]:
	var shaft: BoxMesh = BoxMesh.new()
	shaft.size = Vector3(0.62, 1.24, 0.62)
	var finial: SphereMesh = SphereMesh.new()
	finial.radius = 0.18
	finial.height = 0.36
	finial.radial_segments = 24
	finial.rings = 14
	return [
		{"mesh": shaft, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 0.62, 0.0)), "material": _mat_stone_quay},
		{"mesh": finial, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 1.38, 0.0)), "material": _mat_gold_trim},
	]


func _create_fallback_cafe_bistro_parts() -> Array[Dictionary]:
	var table_top: CylinderMesh = CylinderMesh.new()
	table_top.top_radius = 0.55
	table_top.bottom_radius = 0.55
	table_top.height = 0.08
	table_top.radial_segments = 28
	var pole: CylinderMesh = CylinderMesh.new()
	pole.top_radius = 0.05
	pole.bottom_radius = 0.07
	pole.height = 2.35
	pole.radial_segments = 24
	var umbrella: CylinderMesh = CylinderMesh.new()
	umbrella.top_radius = 0.12
	umbrella.bottom_radius = 1.05
	umbrella.height = 0.42
	umbrella.radial_segments = 28
	return [
		{"mesh": table_top, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 0.76, 0.0)), "material": _mat_marble_plaza},
		{"mesh": pole, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 1.18, 0.0)), "material": _mat_bench_wood},
		{"mesh": umbrella, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 2.32, 0.0)), "material": _mat_roof_terracotta},
	]


func _create_fallback_garden_urn_parts() -> Array[Dictionary]:
	var ped: CylinderMesh = CylinderMesh.new()
	ped.top_radius = 0.34
	ped.bottom_radius = 0.44
	ped.height = 0.85
	ped.radial_segments = 28
	var bush: SphereMesh = SphereMesh.new()
	bush.radius = 0.46
	bush.height = 0.62
	bush.radial_segments = 24
	bush.rings = 14
	return [
		{"mesh": ped, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 0.425, 0.0)), "material": _mat_marble_plaza},
		{"mesh": bush, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 1.05, 0.0)), "material": _mat_foliage_green},
	]


func _create_fallback_grass_daisy_parts() -> Array[Dictionary]:
	var tuft: SphereMesh = SphereMesh.new()
	tuft.radius = 0.48
	tuft.height = 0.36
	tuft.radial_segments = 24
	tuft.rings = 12
	var daisy: SphereMesh = SphereMesh.new()
	daisy.radius = 0.14
	daisy.height = 0.08
	daisy.radial_segments = 24
	daisy.rings = 12
	return [
		{"mesh": tuft, "xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 0.16, 0.0)), "material": _mat_foliage_green},
		{"mesh": daisy, "xform": Transform3D(Basis.IDENTITY, Vector3(0.18, 0.34, 0.12)), "material": _mat_marble_wall},
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
	cyl.radial_segments = 32
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
