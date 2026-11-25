class_name AkashaCityBuilder
extends Node3D

## AkashaCityBuilder — Grand Pixar Terraced River-City Generator (Godot 4.3+).
## Builds the seamless 460x560m sunlit meadow valley, enriched emerald/azure
## mountain horizon ring, Shining Canal with embankment balustrades, 4 animated
## cascading waterfalls, 6 bobbing painted boats, Lake of Silence, ornate radial
## plazas & sunlit avenues with welcome stone arches, Bridge of Memory,
## 9 City of Souls districts, 4 landmark buildings, 28 dense colorful street-level
## Pixar houses, a 4-tier cascading "Endless City" amphitheater (96+ terraced
## houses/spires, 64+ cliffs, 96+ lush green & golden trees via MultiMeshInstance3D),
## living botanical props, 3 Blueprint quest artifacts, and the 3D QuestBeacon.

const MEADOW_SHADER_PATH: String = "res://shaders/akasha_meadow_ground.gdshader"
const MARBLE_SHADER_PATH: String = "res://shaders/akasha_marble.gdshader"
const WATER_SHADER_PATH: String = "res://shaders/akasha_water.gdshader"
const PIXAR_TERRACE_PLAZA_SHADER_PATH: String = "res://shaders/pixar_terrace_plaza.gdshader"
const PIXAR_WATERFALL_SHADER_PATH: String = "res://shaders/pixar_waterfall.gdshader"

const MODEL_SCHOOL_PATH: String = "res://assets/models/city/school_of_souls.glb"
const MODEL_LIBRARY_PATH: String = "res://assets/models/city/orion_library.glb"
const MODEL_CLOCKTOWER_PATH: String = "res://assets/models/city/kronos_clocktower.glb"
const MODEL_SANCTUARY_PATH: String = "res://assets/models/city/mira_sanctuary.glb"
const MODEL_BRIDGE_PATH: String = "res://assets/models/city/city_bridge.glb"
const MODEL_PAVILION_PATH: String = "res://assets/models/city/city_pavilion.glb"

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

const ROAD_TOP_Y: float = 0.03
const PLAZA_TOP_Y: float = 0.04
const BRIDGE_DECK_Y: float = 1.35

const DISTRICT_QUERY_RADIUS: float = 28.0

# Shared materials (reused across meshes for 60 FPS on macOS Retina)
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
var _mat_terrace_stone: StandardMaterial3D = null
var _mat_cliff_rock: StandardMaterial3D = null
var _mat_foliage_green: StandardMaterial3D = null
var _mat_foliage_gold: StandardMaterial3D = null
var _mat_foliage_sakura: StandardMaterial3D = null
var _mat_trunk_wood: StandardMaterial3D = null
var _mat_wall_cream: StandardMaterial3D = null
var _mat_wall_ochre: StandardMaterial3D = null
var _mat_wall_peach: StandardMaterial3D = null
var _mat_roof_red: StandardMaterial3D = null
var _mat_roof_terracotta: StandardMaterial3D = null
var _mat_roof_ochre: StandardMaterial3D = null
var _mat_boat_hull: StandardMaterial3D = null
var _mat_boat_trim: StandardMaterial3D = null

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

# District registry (contract with all tracks)
var _districts: Array[Dictionary] = []
var _district_spawns: Dictionary = {}

# Quest items, beacon & animated boats references
var _quest_items: Dictionary = {}
var _quest_item_floaters: Array[Dictionary] = []
var _boat_floaters: Array[Dictionary] = []
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

	_build_unified_ground_and_valley()
	_build_mountain_horizon_ring()
	_build_canal_and_lake()
	_build_waterfalls_and_boats()
	_build_roads_and_plazas()
	_build_city_buildings()
	_build_terraced_endless_city()
	_build_city_props_and_flora()
	_build_lantern_garden_particles()
	_build_quest_artifacts()
	_build_quest_beacon()


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
	return Vector3(0.0, 0.1, 48.0)


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
			"world_pos": Vector3(0.0, 0.0, 48.0),
		},
		{
			"id": "school_of_souls",
			"name": "Школа Юных Душ",
			"subtitle": "Первые уроки света",
			"world_pos": Vector3(-42.0, 0.0, 8.0),
		},
		{
			"id": "quiet_lakes_park",
			"name": "Озёрный Парк Тишины",
			"subtitle": "Зеркало спокойных вод",
			"world_pos": Vector3(44.0, 0.0, 10.0),
		},
		{
			"id": "central_boulevard",
			"name": "Центральный Бульвар и Мост Памяти",
			"subtitle": "Переправа через Сияющий Канал",
			"world_pos": Vector3(0.0, 0.0, -32.0),
		},
		{
			"id": "orion_library",
			"name": "Библиотека Звёздных Свитков",
			"subtitle": "Хранилище вечных историй",
			"world_pos": Vector3(-48.0, 0.0, -78.0),
		},
		{
			"id": "kronos_tower",
			"name": "Площадь и Башня Времени",
			"subtitle": "Ритм семи вёсен",
			"world_pos": Vector3(48.0, 0.0, -78.0),
		},
		{
			"id": "lantern_garden",
			"name": "Сад Небесных Фонариков",
			"subtitle": "Аллея парящих огней",
			"world_pos": Vector3(-34.0, 0.0, -138.0),
		},
		{
			"id": "mira_sanctuary",
			"name": "Дом Утешения Миры",
			"subtitle": "Тёплый приют сердца",
			"world_pos": Vector3(34.0, 0.0, -138.0),
		},
		{
			"id": "earth_mirror_temple",
			"name": "Верхний Храм Зеркала Земли",
			"subtitle": "Барочный Дворец Хроник",
			"world_pos": Vector3(0.0, 0.0, -280.0),
		},
	]

	_district_spawns = {
		"awakening_plaza": Vector3(0.0, 0.1, 48.0),
		"school_of_souls": Vector3(-36.0, 0.1, 8.0),
		"quiet_lakes_park": Vector3(32.0, 0.1, 10.0),
		"central_boulevard": Vector3(0.0, 0.1, -18.0),
		"orion_library": Vector3(-36.0, 0.1, -78.0),
		"kronos_tower": Vector3(36.0, 0.1, -78.0),
		"lantern_garden": Vector3(-30.0, 0.1, -138.0),
		"mira_sanctuary": Vector3(28.0, 0.1, -138.0),
		"earth_mirror_temple": Vector3(0.0, 0.1, -226.0),
	}


func _init_materials() -> void:
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
		meadow_fb.albedo_color = Color("#54A848")
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
		_mat_marble_road = road_mat

		var plaza_mat: ShaderMaterial = ShaderMaterial.new()
		plaza_mat.shader = terrace_shader
		plaza_mat.set_shader_parameter("radial_mode", 1.0)
		_mat_marble_plaza = plaza_mat
	else:
		# Warm sunlit terracotta-cream StandardMaterial3D fallback
		var road_fb: StandardMaterial3D = StandardMaterial3D.new()
		road_fb.albedo_color = Color("#EEDAC0")
		road_fb.roughness = 0.56
		road_fb.metallic = 0.02
		_mat_marble_road = road_fb

		var plaza_fb: StandardMaterial3D = StandardMaterial3D.new()
		plaza_fb.albedo_color = Color("#F5E5CE")
		plaza_fb.roughness = 0.50
		plaza_fb.metallic = 0.03
		_mat_marble_plaza = plaza_fb

	# Marble building wall / arch / balustrade material
	var marble_shader: Shader = null
	if ResourceLoader.exists(MARBLE_SHADER_PATH):
		var m_res: Resource = load(MARBLE_SHADER_PATH)
		if m_res is Shader:
			marble_shader = m_res as Shader

	if marble_shader != null:
		_mat_marble_wall = _create_marble_shader_mat(
			marble_shader,
			Color("#F6EFE2"),
			Color("#FFFDF7"),
			Color("#D8CCB8"),
			0.54,
			0.0,
			0.95
		)
	else:
		var wall_fb: StandardMaterial3D = StandardMaterial3D.new()
		wall_fb.albedo_color = Color("#F5EFE4")
		wall_fb.roughness = 0.58
		_mat_marble_wall = wall_fb

	# Champagne Gold Trim
	_mat_gold_trim = StandardMaterial3D.new()
	_mat_gold_trim.albedo_color = Color("#E4C170")
	_mat_gold_trim.metallic = 0.78
	_mat_gold_trim.roughness = 0.34
	_mat_gold_trim.emission_enabled = true
	_mat_gold_trim.emission = Color("#F4D484")
	_mat_gold_trim.emission_energy_multiplier = 0.16

	# Royal Celestial Blue Roof
	_mat_blue_roof = StandardMaterial3D.new()
	_mat_blue_roof.albedo_color = Color("#2C6CB8")
	_mat_blue_roof.metallic = 0.14
	_mat_blue_roof.roughness = 0.34

	# Warm Glowing Windows
	_mat_warm_window = StandardMaterial3D.new()
	_mat_warm_window.albedo_color = Color("#FFF0C8")
	_mat_warm_window.roughness = 0.24
	_mat_warm_window.emission_enabled = true
	_mat_warm_window.emission = Color("#FFDF94")
	_mat_warm_window.emission_energy_multiplier = 1.35

	# Stone Quay / Curbs (warm honey-travertine)
	_mat_stone_quay = StandardMaterial3D.new()
	_mat_stone_quay.albedo_color = Color("#DDD2C0")
	_mat_stone_quay.roughness = 0.70
	_mat_stone_quay.metallic = 0.02

	# Warm Terrace Retaining Wall Stone
	_mat_terrace_stone = StandardMaterial3D.new()
	_mat_terrace_stone.albedo_color = Color("#E4D2B4")
	_mat_terrace_stone.roughness = 0.78
	_mat_terrace_stone.metallic = 0.02

	# Sculpted Cliff Rock Fallback
	_mat_cliff_rock = StandardMaterial3D.new()
	_mat_cliff_rock.albedo_color = Color("#B89878")
	_mat_cliff_rock.roughness = 0.88
	_mat_cliff_rock.metallic = 0.0

	# Lush Green, Golden Autumn & Sakura Foliage
	_mat_foliage_green = StandardMaterial3D.new()
	_mat_foliage_green.albedo_color = Color("#3F9A48")
	_mat_foliage_green.roughness = 0.72
	_mat_foliage_green.metallic = 0.0

	_mat_foliage_gold = StandardMaterial3D.new()
	_mat_foliage_gold.albedo_color = Color("#E8A634")
	_mat_foliage_gold.roughness = 0.68
	_mat_foliage_gold.metallic = 0.0
	_mat_foliage_gold.emission_enabled = true
	_mat_foliage_gold.emission = Color("#D88E24")
	_mat_foliage_gold.emission_energy_multiplier = 0.08

	_mat_foliage_sakura = StandardMaterial3D.new()
	_mat_foliage_sakura.albedo_color = Color("#F5B7CA")
	_mat_foliage_sakura.roughness = 0.72

	_mat_trunk_wood = StandardMaterial3D.new()
	_mat_trunk_wood.albedo_color = Color("#6E4C36")
	_mat_trunk_wood.roughness = 0.88

	# Pixar House Fallback Palette
	_mat_wall_cream = StandardMaterial3D.new()
	_mat_wall_cream.albedo_color = Color("#FAF1E0")
	_mat_wall_cream.roughness = 0.62

	_mat_wall_ochre = StandardMaterial3D.new()
	_mat_wall_ochre.albedo_color = Color("#F2D28E")
	_mat_wall_ochre.roughness = 0.64

	_mat_wall_peach = StandardMaterial3D.new()
	_mat_wall_peach.albedo_color = Color("#F5CEB2")
	_mat_wall_peach.roughness = 0.64

	_mat_roof_red = StandardMaterial3D.new()
	_mat_roof_red.albedo_color = Color("#C84438")
	_mat_roof_red.roughness = 0.44

	_mat_roof_terracotta = StandardMaterial3D.new()
	_mat_roof_terracotta.albedo_color = Color("#D46B42")
	_mat_roof_terracotta.roughness = 0.48

	_mat_roof_ochre = StandardMaterial3D.new()
	_mat_roof_ochre.albedo_color = Color("#C88A32")
	_mat_roof_ochre.roughness = 0.46

	_mat_boat_hull = StandardMaterial3D.new()
	_mat_boat_hull.albedo_color = Color("#C4543A")
	_mat_boat_hull.roughness = 0.52

	_mat_boat_trim = StandardMaterial3D.new()
	_mat_boat_trim.albedo_color = Color("#F4D47A")
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


func _safe_load_scene(res_path: String) -> PackedScene:
	if not ResourceLoader.exists(res_path):
		return null
	var loaded: Resource = load(res_path)
	if loaded is PackedScene:
		return loaded as PackedScene
	return null


# ===========================================================================
# 2. UNIFIED GROUND & VALLEY (460x560m, Y = 0.0, 0 holes, carve_palace = true)
# ===========================================================================

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

	# South Valley Meadow (Z from -25 to +180) with carved basin for Lake of Silence
	var south_mesh: ArrayMesh = _build_meadow_grid_mesh(
		-half_w, half_w, canal_z_south, z_max, 56, 36, true, false
	)
	var south_inst: MeshInstance3D = MeshInstance3D.new()
	south_inst.name = "MeadowSouthValley"
	south_inst.mesh = south_mesh
	south_inst.material_override = _mat_meadow
	south_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground_root.add_child(south_inst)

	# North Valley Meadow (Z from -380 to -39) with smooth depression beneath Palace hill (0, -280)
	var north_mesh: ArrayMesh = _build_meadow_grid_mesh(
		-half_w, half_w, z_min, canal_z_north, 56, 48, false, true
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
			if carve_lake:
				var ldx: float = vx - LAKE_CENTER.x
				var ldz: float = vz - LAKE_CENTER.z
				var ldist: float = sqrt(ldx * ldx + ldz * ldz)
				if ldist < LAKE_RADIUS:
					var t: float = clampf(1.0 - ldist / LAKE_RADIUS, 0.0, 1.0)
					var smooth_t: float = t * t * (3.0 - 2.0 * t)
					vy = -0.95 * smooth_t
			if carve_palace:
				var pdx: float = vx
				var pdz: float = vz + 280.0
				var pdist: float = sqrt(pdx * pdx + pdz * pdz)
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
# 5. ROADS, ORNATE CIRCULAR PLAZAS & WELCOME STONE ARCHES
# ===========================================================================

func _build_roads_and_plazas() -> void:
	var net_root: Node3D = Node3D.new()
	net_root.name = "RoadsAndPlazas"
	add_child(net_root)

	# Main Boulevard along X = 0 (Z = 56 down to Z = -228, split around Bridge Z = -21..-43)
	_add_marble_road(net_root, "MainBoulevard_South", Vector3(0.0, 0.0, 56.0), Vector3(0.0, 0.0, -21.0), 10.0)
	_add_marble_road(net_root, "MainBoulevard_North", Vector3(0.0, 0.0, -43.0), Vector3(0.0, 0.0, -138.0), 10.0)
	# Wide Imperial Alley leading to the Baroque Palace Arrival Court (Z = -138 to Z = -228)
	_add_marble_road(net_root, "ImperialAlley", Vector3(0.0, 0.0, -138.0), Vector3(0.0, 0.0, -228.0), 14.0)

	# Cross streets to all 6 side districts
	_add_marble_road(net_root, "Street_SchoolOfSouls", Vector3(0.0, 0.0, 8.0), Vector3(-42.0, 0.0, 8.0), 7.0)
	_add_marble_road(net_root, "Street_QuietLakesPark", Vector3(0.0, 0.0, 10.0), Vector3(44.0, 0.0, 10.0), 7.0)
	_add_marble_road(net_root, "Street_OrionLibrary", Vector3(0.0, 0.0, -78.0), Vector3(-48.0, 0.0, -78.0), 7.0)
	_add_marble_road(net_root, "Street_KronosTower", Vector3(0.0, 0.0, -78.0), Vector3(48.0, 0.0, -78.0), 7.0)
	_add_marble_road(net_root, "Street_LanternGarden", Vector3(0.0, 0.0, -138.0), Vector3(-34.0, 0.0, -138.0), 7.0)
	_add_marble_road(net_root, "Street_MiraSanctuary", Vector3(0.0, 0.0, -138.0), Vector3(34.0, 0.0, -138.0), 7.0)

	# Circular ornate plazas with golden rims at all city districts + Imperial Forecourt
	_add_marble_plaza(net_root, "Plaza_Awakening", Vector3(0.0, 0.0, 48.0), 12.0)
	_add_marble_plaza(net_root, "Plaza_SchoolOfSouls", Vector3(-36.0, 0.0, 8.0), 9.0)
	_add_marble_plaza(net_root, "Plaza_QuietLakesPier", Vector3(42.0, 0.0, 10.0), 6.2)
	_add_marble_plaza(net_root, "Plaza_QuietLakesEntry", Vector3(30.0, 0.0, 10.0), 6.0)
	_add_marble_plaza(net_root, "Plaza_BridgeSouth", Vector3(0.0, 0.0, -17.0), 7.2)
	_add_marble_plaza(net_root, "Plaza_BridgeNorth", Vector3(0.0, 0.0, -47.0), 7.2)
	_add_marble_plaza(net_root, "Plaza_OrionLibrary", Vector3(-42.0, 0.0, -78.0), 9.5)
	_add_marble_plaza(net_root, "Plaza_KronosTower", Vector3(42.0, 0.0, -78.0), 9.5)
	_add_marble_plaza(net_root, "Plaza_LanternGarden", Vector3(-34.0, 0.0, -138.0), 10.5)
	_add_marble_plaza(net_root, "Plaza_MiraSanctuary", Vector3(30.0, 0.0, -138.0), 8.5)
	_add_marble_plaza(net_root, "Plaza_ImperialForecourt", Vector3(0.0, 0.0, -217.5), 10.5)

	# 7 Welcome Stone Arches with Golden Keystones at avenue & district entrances
	_add_welcome_arch(net_root, "Arch_AwakeningGateway", Vector3(0.0, 0.0, 34.5), 0.0, 11.2, 6.8)
	_add_welcome_arch(net_root, "Arch_BridgeNorthGate", Vector3(0.0, 0.0, -55.0), 0.0, 11.2, 6.8)
	_add_welcome_arch(net_root, "Arch_ImperialTriumph", Vector3(0.0, 0.0, -148.5), 0.0, 15.2, 8.2)
	_add_welcome_arch(net_root, "Arch_SchoolDistrict", Vector3(-19.5, 0.0, 8.0), PI * 0.5, 8.2, 5.8)
	_add_welcome_arch(net_root, "Arch_QuietLakesDistrict", Vector3(19.5, 0.0, 10.0), PI * 0.5, 8.2, 5.8)
	_add_welcome_arch(net_root, "Arch_OrionLibraryDistrict", Vector3(-20.5, 0.0, -78.0), PI * 0.5, 8.2, 5.8)
	_add_welcome_arch(net_root, "Arch_KronosTowerDistrict", Vector3(20.5, 0.0, -78.0), PI * 0.5, 8.2, 5.8)


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
	holder.position = Vector3(mid.x, 0.0, mid.z)
	holder.rotation.y = yaw
	parent.add_child(holder)

	# Road slab: height 0.04, centered at Y = 0.01 -> top face strictly at Y = 0.03
	var slab: MeshInstance3D = MeshInstance3D.new()
	var slab_box: BoxMesh = BoxMesh.new()
	slab_box.size = Vector3(width, 0.04, length)
	slab.mesh = slab_box
	slab.position = Vector3(0.0, ROAD_TOP_Y - 0.02, 0.0)
	slab.material_override = _mat_marble_road
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(slab)

	# Golden edge curbs on both sides (top at Y = 0.036, zero Z-fighting)
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
	holder.position = Vector3(center.x, 0.0, center.z)
	parent.add_child(holder)

	# Plaza disc with exact centered planar UVs (0.5, 0.5) -> top face strictly at Y = PLAZA_TOP_Y
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
	holder.position = Vector3(center.x, 0.0, center.z)
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
# 6. LANDMARKS, BRIDGE OF MEMORY & 28 DENSE COLORFUL PIXAR STREET HOUSES
# ===========================================================================

func _build_city_buildings() -> void:
	var bld_root: Node3D = Node3D.new()
	bld_root.name = "CityBuildings"
	add_child(bld_root)

	# 1. School of Souls at (-48.0, 0.0, 8.0), facade facing +X
	_place_landmark_building(
		bld_root,
		"SchoolOfSoulsBuilding",
		MODEL_SCHOOL_PATH,
		Vector3(-48.0, 0.0, 8.0),
		PI * 0.5,
		Vector3(14.0, 9.0, 16.0),
		"school"
	)

	# 2. Orion Library at (-54.0, 0.0, -78.0), facade facing +X
	_place_landmark_building(
		bld_root,
		"OrionLibraryBuilding",
		MODEL_LIBRARY_PATH,
		Vector3(-54.0, 0.0, -78.0),
		PI * 0.5,
		Vector3(15.0, 12.0, 18.0),
		"library"
	)

	# 3. Kronos Clocktower at (54.0, 0.0, -78.0), facade facing -X
	_place_landmark_building(
		bld_root,
		"KronosClocktowerBuilding",
		MODEL_CLOCKTOWER_PATH,
		Vector3(54.0, 0.0, -78.0),
		-PI * 0.5,
		Vector3(10.0, 22.0, 10.0),
		"clocktower"
	)

	# 4. Mira's Sanctuary at (40.0, 0.0, -138.0), facade facing -X
	_place_landmark_building(
		bld_root,
		"MiraSanctuaryBuilding",
		MODEL_SANCTUARY_PATH,
		Vector3(40.0, 0.0, -138.0),
		-PI * 0.5,
		Vector3(11.0, 8.0, 12.0),
		"sanctuary"
	)

	# 5. Bridge of Memory at (0.0, 0.0, -32.0) + walkable ramp/deck collision
	_build_bridge_of_memory(bld_root)

	# 6. 28 Dense, Cozy, Colorful Pixar Street Houses along both Canal banks,
	#    Awakening Plaza, Main Boulevard, and side quarters (guaranteed >= 1.5m clearance!)
	var street_house_specs: Array[Dictionary] = [
		# South Boulevard & Awakening Plaza Ring (8)
		{"pos": Vector3(-14.5, 0.0, 36.0), "yaw": PI * 0.5, "kind": "red_gable"},
		{"pos": Vector3(14.5, 0.0, 36.0), "yaw": -PI * 0.5, "kind": "ochre_timber"},
		{"pos": Vector3(-14.5, 0.0, 24.0), "yaw": PI * 0.5, "kind": "blue_balcony"},
		{"pos": Vector3(14.5, 0.0, 24.0), "yaw": -PI * 0.5, "kind": "terracotta_terrace"},
		{"pos": Vector3(-20.0, 0.0, 50.0), "yaw": PI * 0.38, "kind": "cream_spire"},
		{"pos": Vector3(20.0, 0.0, 50.0), "yaw": -PI * 0.38, "kind": "red_gable"},
		{"pos": Vector3(-16.0, 0.0, 62.5), "yaw": PI * 0.18, "kind": "terracotta_terrace"},
		{"pos": Vector3(16.0, 0.0, 62.5), "yaw": -PI * 0.18, "kind": "blue_balcony"},

		# South Canal Waterfront & School / Quiet Lakes Quarters (8)
		{"pos": Vector3(-14.5, 0.0, -6.0), "yaw": PI * 0.5, "kind": "terracotta_terrace"},
		{"pos": Vector3(14.5, 0.0, -6.0), "yaw": -PI * 0.5, "kind": "red_gable"},
		{"pos": Vector3(-24.0, 0.0, -17.5), "yaw": PI, "kind": "blue_balcony"},
		{"pos": Vector3(-36.0, 0.0, -17.5), "yaw": PI, "kind": "ochre_timber"},
		{"pos": Vector3(24.0, 0.0, -17.5), "yaw": PI, "kind": "cream_spire"},
		{"pos": Vector3(36.0, 0.0, -17.5), "yaw": PI, "kind": "terracotta_terrace"},
		{"pos": Vector3(-24.0, 0.0, 20.0), "yaw": PI, "kind": "red_gable"},
		{"pos": Vector3(22.0, 0.0, 23.0), "yaw": PI, "kind": "pavilion"},

		# North Canal Waterfront & Library / Clocktower Quarters (8)
		{"pos": Vector3(-24.0, 0.0, -46.5), "yaw": 0.0, "kind": "ochre_timber"},
		{"pos": Vector3(-36.0, 0.0, -46.5), "yaw": 0.0, "kind": "red_gable"},
		{"pos": Vector3(24.0, 0.0, -46.5), "yaw": 0.0, "kind": "blue_balcony"},
		{"pos": Vector3(36.0, 0.0, -46.5), "yaw": 0.0, "kind": "cream_spire"},
		{"pos": Vector3(-14.5, 0.0, -60.0), "yaw": PI * 0.5, "kind": "blue_balcony"},
		{"pos": Vector3(14.5, 0.0, -60.0), "yaw": -PI * 0.5, "kind": "terracotta_terrace"},
		{"pos": Vector3(-24.0, 0.0, -91.0), "yaw": 0.0, "kind": "cream_spire"},
		{"pos": Vector3(24.0, 0.0, -91.0), "yaw": 0.0, "kind": "ochre_timber"},

		# Upper Boulevard, Lantern Garden & Mira's Sanctuary Approach (4)
		{"pos": Vector3(-15.0, 0.0, -112.0), "yaw": PI * 0.5, "kind": "red_gable"},
		{"pos": Vector3(15.0, 0.0, -112.0), "yaw": -PI * 0.5, "kind": "blue_balcony"},
		{"pos": Vector3(-22.0, 0.0, -155.0), "yaw": 0.0, "kind": "pavilion"},
		{"pos": Vector3(22.0, 0.0, -155.0), "yaw": 0.0, "kind": "terracotta_terrace"},
	]

	for i in range(street_house_specs.size()):
		var spec: Dictionary = street_house_specs[i]
		var h_pos: Vector3 = spec["pos"] as Vector3
		var h_yaw: float = float(spec["yaw"])
		var h_kind: String = String(spec["kind"])
		_place_pixar_street_house(bld_root, "PixarStreetHouse_%02d_%s" % [i + 1, h_kind], h_pos, h_yaw, h_kind)


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
	holder.position = Vector3(pos.x, 0.0, pos.z)
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
# 7. MULTI-TIER "ENDLESS CITY" ON CLIFFS & TERRACES (MultiMeshInstance3D)
#    4 Cascading Amphitheater Tiers: Y = 3.5, 9.0, 15.5, 23.0
#    96+ Houses/Spires, 64+ Cliffs, 96+ Lush Green & Golden Trees -> 60 FPS!
# ===========================================================================

func _build_terraced_endless_city() -> void:
	var tier_root: Node3D = Node3D.new()
	tier_root.name = "EndlessTerracedCity"
	add_child(tier_root)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 202611

	var house_batches: Dictionary = {
		"red_gable": [] as Array[Transform3D],
		"blue_balcony": [] as Array[Transform3D],
		"ochre_timber": [] as Array[Transform3D],
		"terracotta_terrace": [] as Array[Transform3D],
		"cream_spire": [] as Array[Transform3D],
	}
	var cliff_xforms: Array[Transform3D] = []
	var wall_xforms: Array[Transform3D] = []
	var pier_xforms: Array[Transform3D] = []
	var tree_green_xforms: Array[Transform3D] = []
	var tree_gold_xforms: Array[Transform3D] = []
	var tree_sakura_xforms: Array[Transform3D] = []

	var tier_heights: Array[float] = [3.5, 9.0, 15.5, 23.0]
	var tier_x_bases: Array[float] = [74.0, 95.0, 118.0, 142.0]
	var tier_z_south: Array[float] = [78.0, 94.0, 110.0, 125.0]
	var lower_kinds: Array[String] = ["red_gable", "blue_balcony", "ochre_timber", "terracotta_terrace"]
	var upper_kinds: Array[String] = ["cream_spire", "red_gable", "blue_balcony", "terracotta_terrace", "cream_spire", "ochre_timber"]

	# --- A. WEST & EAST AMPHITHEATER SLOPES (4 Cascading Tiers, X = +/-68..+/-150) ---
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		for t_idx in range(4):
			var ty: float = tier_heights[t_idx]
			var bx: float = tier_x_bases[t_idx]
			var z_min: float = -176.0 - float(t_idx) * 4.0
			var z_max: float = 64.0 + float(t_idx) * 8.0
			var z_step: float = 21.0 if t_idx < 2 else 23.5

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

				var x_pos: float = side * (bx + north_flare + lake_flare + rng.randf_range(-2.6, 2.6))
				var z_pos: float = z_cur + rng.randf_range(-2.4, 2.4)

				# Safety check: keep clear of Baroque Palace hill (0, -280), R >= 84m
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

				# Retaining wall slab + decorative buttress pier anchoring the terrace below the house
				# Bottom at Y = -1.5, top strictly flush at Y = ty!
				var wall_h: float = ty + 1.5
				var wall_yaw: float = PI * 0.5
				wall_xforms.append(Transform3D(
					Basis.from_euler(Vector3(0.0, wall_yaw, 0.0)).scaled(Vector3(18.0, wall_h, 8.6)),
					Vector3(x_pos, wall_h * 0.5 - 1.5, z_pos)
				))
				pier_xforms.append(Transform3D(
					Basis.from_euler(Vector3(0.0, 0.0, 0.0)).scaled(Vector3(1.8, wall_h + 0.3, 1.8)),
					Vector3(x_pos - side * 4.2, wall_h * 0.5 - 1.35, z_pos + 7.2)
				))

				# Sculptural cliff rock grounded at Y = -0.5, flat top strictly flush at Y = ty
				if (slot_idx + t_idx) % 2 == 0:
					var cliff_sy: float = (ty + 0.5) / 6.0
					var rock_sc: Vector3 = Vector3(
						rng.randf_range(1.15, 1.65),
						cliff_sy,
						rng.randf_range(1.15, 1.65)
					)
					cliff_xforms.append(Transform3D(
						Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(rock_sc),
						Vector3(x_pos - side * 4.5, -0.5, z_pos + rng.randf_range(-3.0, 3.0))
					))

				# House placement facing inward toward the sunlit valley
				var h_kind: String = ""
				if t_idx >= 2:
					h_kind = upper_kinds[(slot_idx + t_idx * 2) % upper_kinds.size()]
				else:
					h_kind = lower_kinds[(slot_idx + t_idx) % lower_kinds.size()]

				var face_yaw: float = (-PI * 0.5 if side > 0.0 else PI * 0.5) + rng.randf_range(-0.18, 0.18)
				var h_sc: float = rng.randf_range(1.02, 1.24) + float(t_idx) * 0.06
				var h_arr: Array[Transform3D] = house_batches[h_kind] as Array[Transform3D]
				h_arr.append(Transform3D(
					Basis.from_euler(Vector3(0.0, face_yaw, 0.0)).scaled(Vector3(h_sc, h_sc, h_sc)),
					Vector3(x_pos, ty, z_pos)
				))

				# Lush green or golden Pixar tree strictly inside the retaining wall footprint
				var tree_x: float = x_pos - side * rng.randf_range(1.0, 2.5)
				var tree_z: float = z_pos + rng.randf_range(5.0, 7.2)
				var tree_sc: float = rng.randf_range(0.95, 1.38)
				var tree_xf: Transform3D = Transform3D(
					Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(tree_sc, tree_sc, tree_sc)),
					Vector3(tree_x, ty, tree_z)
				)
				if (slot_idx + t_idx) % 5 == 0:
					tree_sakura_xforms.append(tree_xf)
				elif (slot_idx + t_idx) % 3 == 0:
					tree_gold_xforms.append(tree_xf)
				else:
					tree_green_xforms.append(tree_xf)

				z_cur += z_step

	# --- B. SOUTH AMPHITHEATER SLOPE BEHIND AWAKENING PLAZA (Z = +74..+126) ---
	for t_idx in range(4):
		var ty: float = tier_heights[t_idx]
		var bz: float = tier_z_south[t_idx]
		var x_span: float = 56.0 + float(t_idx) * 18.0
		var x_step: float = 22.0
		var x_cur: float = -x_span
		var s_idx: int = 0
		while x_cur <= x_span:
			s_idx += 1
			var x_pos: float = x_cur + rng.randf_range(-2.2, 2.2)
			var z_pos: float = bz + rng.randf_range(-2.2, 2.2)

			# Bottom at Y = -1.5, top strictly flush at Y = ty!
			var wall_h: float = ty + 1.5
			wall_xforms.append(Transform3D(
				Basis.from_scale(Vector3(18.5, wall_h, 8.4)),
				Vector3(x_pos, wall_h * 0.5 - 1.5, z_pos)
			))

			if (s_idx + t_idx) % 2 == 0:
				var cliff_sy_b: float = (ty + 0.5) / 6.0
				var r_sc: Vector3 = Vector3(rng.randf_range(1.2, 1.6), cliff_sy_b, rng.randf_range(1.2, 1.6))
				cliff_xforms.append(Transform3D(
					Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(r_sc),
					Vector3(x_pos, -0.5, z_pos - 4.2)
				))

			var h_kind: String = upper_kinds[(s_idx + t_idx) % upper_kinds.size()] if t_idx >= 2 else lower_kinds[(s_idx + t_idx) % lower_kinds.size()]
			var h_sc: float = rng.randf_range(1.04, 1.26) + float(t_idx) * 0.05
			var h_arr: Array[Transform3D] = house_batches[h_kind] as Array[Transform3D]
			h_arr.append(Transform3D(
				Basis.from_euler(Vector3(0.0, PI + rng.randf_range(-0.22, 0.22), 0.0)).scaled(Vector3(h_sc, h_sc, h_sc)),
				Vector3(x_pos, ty, z_pos)
			))

			var tr_sc: float = rng.randf_range(0.95, 1.35)
			var tr_xf: Transform3D = Transform3D(
				Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(tr_sc, tr_sc, tr_sc)),
				Vector3(x_pos + 7.2, ty, z_pos - 2.4)
			)
			if s_idx % 3 == 0:
				tree_gold_xforms.append(tr_xf)
			else:
				tree_green_xforms.append(tr_xf)

			x_cur += x_step

	# --- C. DISTANT RIVERFRONT QUARTERS ALONG CANAL TOWARD HORIZON (X = +/-95..+/-165) ---
	for side_val in [-1.0, 1.0]:
		var side: float = float(side_val)
		for bank_val in [-1.0, 1.0]:
			var bank: float = float(bank_val) # -1 = North bank (Z = -48), +1 = South bank (Z = -16)
			var z_base: float = -48.5 if bank < 0.0 else -15.5
			var dist_xs: Array[float] = [98.0, 118.0, 138.0, 158.0]
			for d_idx in range(dist_xs.size()):
				var x_pos: float = side * dist_xs[d_idx]
				var ty: float = 3.5 + float(d_idx) * 3.8
				var z_pos: float = z_base + bank * float(d_idx) * 2.2

				# Retaining wall supporting both the riverfront house and its flanking tree (top strictly at Y = ty)
				var wall_h_c: float = ty + 1.5
				wall_xforms.append(Transform3D(
					Basis.from_scale(Vector3(18.5, wall_h_c, 8.6)),
					Vector3(x_pos + side * 2.5, wall_h_c * 0.5 - 1.5, z_pos)
				))

				# Grounded cliff rock at river edge (bottom Y = -0.5, top strictly at Y = ty)
				var cliff_sy_c: float = (ty + 0.5) / 6.0
				cliff_xforms.append(Transform3D(
					Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(1.5, cliff_sy_c, 1.4)),
					Vector3(x_pos, -0.5, z_pos - bank * 3.0)
				))

				var h_kind: String = "cream_spire" if d_idx >= 2 else lower_kinds[d_idx % lower_kinds.size()]
				var face_yaw: float = 0.0 if bank < 0.0 else PI
				var h_sc: float = 1.08 + float(d_idx) * 0.08
				var h_arr: Array[Transform3D] = house_batches[h_kind] as Array[Transform3D]
				h_arr.append(Transform3D(
					Basis.from_euler(Vector3(0.0, face_yaw, 0.0)).scaled(Vector3(h_sc, h_sc, h_sc)),
					Vector3(x_pos, ty, z_pos)
				))

				var t_xf: Transform3D = Transform3D(
					Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(1.15, 1.15, 1.15)),
					Vector3(x_pos + side * 6.5, ty, z_pos + bank * 2.0)
				)
				if d_idx % 2 == 0:
					tree_green_xforms.append(t_xf)
				else:
					tree_gold_xforms.append(t_xf)

	# --- D. VALLEY-FLOOR LUSH GREEN & GOLDEN TREES (Framing residential streets & water) ---
	var valley_tree_spots: Array[Dictionary] = [
		{"pos": Vector3(-28.0, 0.0, 42.0), "gold": false, "sc": 1.12},
		{"pos": Vector3(28.0, 0.0, 42.0), "gold": true, "sc": 1.08},
		{"pos": Vector3(-30.0, 0.0, 56.0), "gold": true, "sc": 1.16},
		{"pos": Vector3(30.0, 0.0, 56.0), "gold": false, "sc": 1.14},
		{"pos": Vector3(-48.0, 0.0, -16.0), "gold": false, "sc": 1.18},
		{"pos": Vector3(48.0, 0.0, -16.0), "gold": true, "sc": 1.15},
		{"pos": Vector3(-48.0, 0.0, -48.0), "gold": true, "sc": 1.12},
		{"pos": Vector3(48.0, 0.0, -48.0), "gold": false, "sc": 1.15},
		{"pos": Vector3(-30.0, 0.0, -60.0), "gold": false, "sc": 1.05},
		{"pos": Vector3(30.0, 0.0, -60.0), "gold": true, "sc": 1.08},
		{"pos": Vector3(-34.0, 0.0, -108.0), "gold": true, "sc": 1.14},
		{"pos": Vector3(34.0, 0.0, -108.0), "gold": false, "sc": 1.12},
		{"pos": Vector3(-52.0, 0.0, -124.0), "gold": false, "sc": 1.22},
		{"pos": Vector3(52.0, 0.0, -124.0), "gold": true, "sc": 1.20},
		{"pos": Vector3(-34.0, 0.0, -172.0), "gold": false, "sc": 1.18},
		{"pos": Vector3(34.0, 0.0, -172.0), "gold": true, "sc": 1.16},
	]
	for vt in valley_tree_spots:
		var vpos: Vector3 = vt["pos"] as Vector3
		var vsc: float = float(vt["sc"])
		var vxf: Transform3D = Transform3D(
			Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0)).scaled(Vector3(vsc, vsc, vsc)),
			vpos
		)
		if bool(vt["gold"]):
			tree_gold_xforms.append(vxf)
		else:
			tree_green_xforms.append(vxf)

	# --- E. COMMIT ALL BATCHES TO MultiMeshInstance3D (Ultra-low draw calls, 60 FPS!) ---
	# 1. Terraced retaining walls & piers (2 draw calls)
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
		null
	)

	# 3. All 5 Colorful Pixar House Types on Terraces (preserving all roof/wall/window colors!)
	var house_kinds: Array[String] = ["red_gable", "blue_balcony", "ochre_timber", "terracotta_terrace", "cream_spire"]
	for h_kind in house_kinds:
		var xforms: Array[Transform3D] = house_batches[h_kind] as Array[Transform3D]
		var h_scene: PackedScene = _get_pixar_house_scene(h_kind)
		_spawn_scene_multimesh_batch(
			tier_root,
			"TerraceHouses_%s_MM" % h_kind,
			h_scene,
			xforms,
			_create_fallback_house_parts(h_kind),
			null
		)

	# 4. Lush Green & Golden-Autumn Pixar Trees + Terrace Sakura Trees
	_spawn_scene_multimesh_batch(
		tier_root,
		"TerraceTreesGreenMM",
		_scene_tree_lush,
		tree_green_xforms,
		_create_fallback_tree_parts(_mat_foliage_green),
		null
	)
	_spawn_scene_multimesh_batch(
		tier_root,
		"TerraceTreesGoldMM",
		_scene_tree_lush,
		tree_gold_xforms,
		_create_fallback_tree_parts(_mat_foliage_gold),
		_mat_foliage_gold
	)
	_spawn_scene_multimesh_batch(
		tier_root,
		"TerraceTreesSakuraMM",
		_scene_sakura,
		tree_sakura_xforms,
		_create_fallback_tree_parts(_mat_foliage_sakura),
		null
	)


# ===========================================================================
# 8. LIVING STREET PROPS & BOTANICAL FLORA (strictly Y = 0.0)
# ===========================================================================

func _build_city_props_and_flora() -> void:
	var props_root: Node3D = Node3D.new()
	props_root.name = "CityPropsAndFlora"
	add_child(props_root)

	# Sakura trees along Main Boulevard, Imperial Alley, Quiet Lakes Park, Lantern Garden, School
	var sakura_spots: Array[Vector3] = [
		Vector3(-12.5, 0.0, 44.0), Vector3(12.5, 0.0, 44.0),
		Vector3(-9.5, 0.0, 17.5), Vector3(9.5, 0.0, 17.5),
		Vector3(-9.5, 0.0, -52.0), Vector3(9.5, 0.0, -52.0),
		Vector3(-9.5, 0.0, -96.0), Vector3(9.5, 0.0, -96.0),
		Vector3(-9.5, 0.0, -124.0), Vector3(9.5, 0.0, -124.0),
		# Imperial Alley grand tree-lined promenade
		Vector3(-12.5, 0.0, -158.0), Vector3(12.5, 0.0, -158.0),
		Vector3(-12.5, 0.0, -178.0), Vector3(12.5, 0.0, -178.0),
		Vector3(-12.5, 0.0, -198.0), Vector3(12.5, 0.0, -198.0),
		Vector3(-12.5, 0.0, -216.0), Vector3(12.5, 0.0, -216.0),
		# Quiet Lakes Park shoreline trees (outside Lake radius 13m from (54, 12))
		Vector3(36.0, 0.0, 24.0), Vector3(54.0, 0.0, 29.0),
		Vector3(52.0, 0.0, -5.0),
		# Lantern Garden grove
		Vector3(-44.0, 0.0, -128.0), Vector3(-44.0, 0.0, -148.0),
		Vector3(-24.0, 0.0, -149.0), Vector3(-24.0, 0.0, -127.0),
		# School courtyard
		Vector3(-34.0, 0.0, 20.0), Vector3(-34.0, 0.0, -4.0),
	]
	for i in range(sakura_spots.size()):
		var pos: Vector3 = sakura_spots[i]
		var yaw: float = float(i) * 1.15
		var sc: float = 0.92 + float(i % 4) * 0.08
		_place_prop_scene(props_root, _scene_sakura, "CitySakura_%02d" % i, pos, yaw, sc, "tree")

	# Lush bushes framing plazas, Mira's Sanctuary, and Park
	var bush_spots: Array[Vector3] = [
		Vector3(-11.0, 0.0, 54.0), Vector3(11.0, 0.0, 54.0),
		Vector3(-28.0, 0.0, 14.0), Vector3(-28.0, 0.0, 2.0),
		Vector3(28.0, 0.0, 16.0), Vector3(28.0, 0.0, 4.0),
		Vector3(-32.0, 0.0, -72.0), Vector3(-32.0, 0.0, -84.0),
		Vector3(32.0, 0.0, -72.0), Vector3(32.0, 0.0, -84.0),
		Vector3(28.0, 0.0, -130.0), Vector3(28.0, 0.0, -146.0),
		Vector3(-26.0, 0.0, -132.0), Vector3(-26.0, 0.0, -144.0),
	]
	for i in range(bush_spots.size()):
		_place_prop_scene(props_root, _scene_bush, "CityBush_%02d" % i, bush_spots[i], float(i) * 0.9, 1.0, "bush")

	# Baroque Garden Planters flanking entrances and Imperial Alley
	var planter_spots: Array[Vector3] = [
		Vector3(-6.2, 0.0, 36.0), Vector3(6.2, 0.0, 36.0),
		Vector3(-6.2, 0.0, -14.0), Vector3(6.2, 0.0, -14.0),
		Vector3(-6.2, 0.0, -49.0), Vector3(6.2, 0.0, -49.0),
		Vector3(-8.4, 0.0, -152.0), Vector3(8.4, 0.0, -152.0),
		Vector3(-8.4, 0.0, -184.0), Vector3(8.4, 0.0, -184.0),
		Vector3(-8.4, 0.0, -214.0), Vector3(8.4, 0.0, -214.0),
	]
	for i in range(planter_spots.size()):
		_place_prop_scene(props_root, _scene_planter, "CityPlanter_%02d" % i, planter_spots[i], 0.0, 1.0, "planter")

	# Stone Lanterns along Main Boulevard, Imperial Alley, and Lantern Garden
	var lantern_spots: Array[Vector3] = [
		Vector3(-6.4, 0.0, 44.0), Vector3(6.4, 0.0, 44.0),
		Vector3(-6.4, 0.0, 16.0), Vector3(6.4, 0.0, 16.0),
		Vector3(-6.4, 0.0, -68.0), Vector3(6.4, 0.0, -68.0),
		Vector3(-6.4, 0.0, -110.0), Vector3(6.4, 0.0, -110.0),
		Vector3(-8.5, 0.0, -166.0), Vector3(8.5, 0.0, -166.0),
		Vector3(-8.5, 0.0, -200.0), Vector3(8.5, 0.0, -200.0),
		# Lantern Garden ring of stone lanterns
		Vector3(-42.0, 0.0, -138.0), Vector3(-26.0, 0.0, -133.5),
		Vector3(-34.0, 0.0, -130.0), Vector3(-34.0, 0.0, -146.0),
		# Quiet Lakes Park & School
		Vector3(34.0, 0.0, 14.0), Vector3(34.0, 0.0, 6.0),
		Vector3(-30.0, 0.0, 13.0), Vector3(-30.0, 0.0, 3.0),
	]
	for i in range(lantern_spots.size()):
		_place_prop_scene(props_root, _scene_lantern, "CityLantern_%02d" % i, lantern_spots[i], 0.0, 1.0, "lantern")


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
	prop.position = Vector3(pos.x, 0.0, pos.z)
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
# 9. LANTERN GARDEN FLOATING SKY LANTERNS (GPUParticles3D, 24 particles)
# ===========================================================================

func _build_lantern_garden_particles() -> void:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "LanternGardenSkyLanterns"
	particles.position = Vector3(-34.0, 1.8, -138.0)
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
# 10. 3D INTERACTIVE QUEST ARTIFACTS (3 Blueprint Foundations)
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
		Vector3(42.0, 0.0, 10.0),
		Color("#7CECF8"),
		Color("#4AD8F0"),
		0.0,
		"drop"
	)

	# 2. "blank_page" — Чистая Страница at Orion Library (-42.0, 0.0, -78.0)
	_create_quest_artifact(
		quest_root,
		"blank_page",
		"QuestItem_BlankPage",
		Vector3(-42.0, 0.0, -78.0),
		Color("#FFF8E6"),
		Color("#FFE090"),
		2.1,
		"page"
	)

	# 3. "seven_springs_sand" — Песок Семи Вёсен at Kronos Tower (42.0, 0.0, -78.0)
	_create_quest_artifact(
		quest_root,
		"seven_springs_sand",
		"QuestItem_SevenSpringsSand",
		Vector3(42.0, 0.0, -78.0),
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
	item_root.position = Vector3(pos.x, PLAZA_TOP_Y, pos.z)
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
## all transforms via MultiMeshInstance3D per sub-mesh, preserving all roof/wall/window
## colors at 60 FPS! Falls back cleanly to multi-part procedural MultiMesh if scene is null.
func _spawn_scene_multimesh_batch(
	parent: Node3D,
	batch_name: String,
	scene: PackedScene,
	xforms: Array[Transform3D],
	fallback_parts: Array[Dictionary],
	canopy_tint_override: Material
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
			_collect_submesh_parts(temp_root, ground_xf, sub_parts, canopy_tint_override)
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
	canopy_tint_override: Material
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

			var needs_dup: bool = has_surface_override or (canopy_tint_override != null and surf_count > 1)
			if needs_dup:
				var dup_res: Resource = mi.mesh.duplicate()
				if dup_res is Mesh:
					var dup_mesh: Mesh = dup_res as Mesh
					for s_idx in range(surf_count):
						var ov_mat: Material = mi.get_surface_override_material(s_idx)
						if ov_mat != null:
							dup_mesh.surface_set_material(s_idx, ov_mat)
						var eff_mat: Material = ov_mat if ov_mat != null else dup_mesh.surface_get_material(s_idx)
						if canopy_tint_override != null and surf_count > 1:
							var s_name: String = ""
							if eff_mat != null:
								s_name = eff_mat.resource_name.to_lower()
							var is_trunk: bool = s_name.contains("trunk") or s_name.contains("bark") or s_name.contains("wood")
							var is_canopy: bool = s_name.contains("canopy") or s_name.contains("leaf") or s_name.contains("crown") or s_name.contains("foliage")
							if not is_trunk and (is_canopy or s_idx > 0):
								dup_mesh.surface_set_material(s_idx, canopy_tint_override)
					final_mesh = dup_mesh

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
		_collect_submesh_parts(child, cur_xf, out_parts, canopy_tint_override)


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
	rock_cyl.height = 6.5
	rock_cyl.radial_segments = 7
	return [{
		"mesh": rock_cyl,
		"xform": Transform3D(Basis.IDENTITY, Vector3(0.0, 3.25, 0.0)),
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
