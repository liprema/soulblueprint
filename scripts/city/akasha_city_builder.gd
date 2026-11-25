class_name AkashaCityBuilder
extends Node3D

## AkashaCityBuilder — Unified Ground & City of Souls Generator (Godot 4.3+).
## Builds the seamless 460x560m meadow valley, mountain/hill horizon ring,
## glowing canal & Lake of Silence, marble avenue/plaza network, Bridge of Memory,
## 9 City of Souls districts, 3D landmark buildings (with procedural fallbacks),
## living botanical props, 3 Blueprint quest artifacts, and the 3D QuestBeacon.

const MEADOW_SHADER_PATH: String = "res://shaders/akasha_meadow_ground.gdshader"
const MARBLE_SHADER_PATH: String = "res://shaders/akasha_marble.gdshader"
const WATER_SHADER_PATH: String = "res://shaders/akasha_water.gdshader"

const MODEL_SCHOOL_PATH: String = "res://assets/models/city/school_of_souls.glb"
const MODEL_LIBRARY_PATH: String = "res://assets/models/city/orion_library.glb"
const MODEL_CLOCKTOWER_PATH: String = "res://assets/models/city/kronos_clocktower.glb"
const MODEL_SANCTUARY_PATH: String = "res://assets/models/city/mira_sanctuary.glb"
const MODEL_BRIDGE_PATH: String = "res://assets/models/city/city_bridge.glb"
const MODEL_PAVILION_PATH: String = "res://assets/models/city/city_pavilion.glb"

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
var _mat_canal_bed: StandardMaterial3D = null
var _mat_beacon_beam: StandardMaterial3D = null
var _mat_beacon_crystal: StandardMaterial3D = null
var _mat_beacon_ring: StandardMaterial3D = null

# Cached PackedScenes for safe instantiation
var _scene_sakura: PackedScene = null
var _scene_bush: PackedScene = null
var _scene_planter: PackedScene = null
var _scene_lantern: PackedScene = null
var _scene_pavilion: PackedScene = null

# District registry (contract with all tracks)
var _districts: Array[Dictionary] = []
var _district_spawns: Dictionary = {}

# Quest items & beacon references
var _quest_items: Dictionary = {}
var _quest_item_floaters: Array[Dictionary] = []
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
	_build_roads_and_plazas()
	_build_city_buildings()
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
# PUBLIC API
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
	# Meadow ground shader (with safe soft StandardMaterial3D fallback)
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
		meadow_fb.albedo_color = Color("#56A646")
		meadow_fb.roughness = 0.88
		meadow_fb.metallic = 0.0
		_mat_meadow = meadow_fb

	# Marble road, plaza, and building wall materials
	var marble_shader: Shader = null
	if ResourceLoader.exists(MARBLE_SHADER_PATH):
		var m_res: Resource = load(MARBLE_SHADER_PATH)
		if m_res is Shader:
			marble_shader = m_res as Shader

	if marble_shader != null:
		_mat_marble_road = _create_marble_shader_mat(
			marble_shader,
			Color("#F3EDE0"),
			Color("#FFFDF7"),
			Color("#CFC4AE"),
			0.48,
			0.14,
			0.90
		)
		_mat_marble_plaza = _create_marble_shader_mat(
			marble_shader,
			Color("#F7F2E8"),
			Color("#FFFFFA"),
			Color("#D8CEBC"),
			0.44,
			0.16,
			0.75
		)
		_mat_marble_wall = _create_marble_shader_mat(
			marble_shader,
			Color("#F5F0E6"),
			Color("#FFFDF9"),
			Color("#D4CBB8"),
			0.54,
			0.0,
			0.95
		)
	else:
		var road_fb: StandardMaterial3D = StandardMaterial3D.new()
		road_fb.albedo_color = Color("#F2ECE0")
		road_fb.roughness = 0.52
		_mat_marble_road = road_fb

		var plaza_fb: StandardMaterial3D = StandardMaterial3D.new()
		plaza_fb.albedo_color = Color("#F7F1E5")
		plaza_fb.roughness = 0.46
		_mat_marble_plaza = plaza_fb

		var wall_fb: StandardMaterial3D = StandardMaterial3D.new()
		wall_fb.albedo_color = Color("#F5EFE4")
		wall_fb.roughness = 0.58
		_mat_marble_wall = wall_fb

	# Champagne Gold Trim
	_mat_gold_trim = StandardMaterial3D.new()
	_mat_gold_trim.albedo_color = Color("#DFC078")
	_mat_gold_trim.metallic = 0.78
	_mat_gold_trim.roughness = 0.36
	_mat_gold_trim.emission_enabled = true
	_mat_gold_trim.emission = Color("#F2D28A")
	_mat_gold_trim.emission_energy_multiplier = 0.14

	# Royal Celestial Blue Roof
	_mat_blue_roof = StandardMaterial3D.new()
	_mat_blue_roof.albedo_color = Color("#2E6BB8")
	_mat_blue_roof.metallic = 0.14
	_mat_blue_roof.roughness = 0.34

	# Warm Glowing Windows
	_mat_warm_window = StandardMaterial3D.new()
	_mat_warm_window.albedo_color = Color("#FFF0C8")
	_mat_warm_window.roughness = 0.25
	_mat_warm_window.emission_enabled = true
	_mat_warm_window.emission = Color("#FFE09A")
	_mat_warm_window.emission_energy_multiplier = 1.25

	# Stone Quay / Curbs
	_mat_stone_quay = StandardMaterial3D.new()
	_mat_stone_quay.albedo_color = Color("#D8D2C5")
	_mat_stone_quay.roughness = 0.72
	_mat_stone_quay.metallic = 0.02

	# Canal Bed
	_mat_canal_bed = StandardMaterial3D.new()
	_mat_canal_bed.albedo_color = Color("#1B5868")
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
		canal_w.set_shader_parameter("shallow_color", Color("#7CE8F0"))
		canal_w.set_shader_parameter("mid_color", Color("#2AA8B8"))
		canal_w.set_shader_parameter("deep_color", Color("#1D7894"))
		canal_w.set_shader_parameter("sky_reflect_color", Color("#D8F2FF"))
		canal_w.set_shader_parameter("foam_color", Color("#F2FCFF"))
		canal_w.set_shader_parameter("caustic_color", Color("#9EF5FA"))
		canal_w.set_shader_parameter("ring_mode", 1.0)
		canal_w.set_shader_parameter("water_alpha", 0.88)
		_mat_water_canal = canal_w

		var lake_w: ShaderMaterial = ShaderMaterial.new()
		lake_w.shader = water_shader
		lake_w.set_shader_parameter("shallow_color", Color("#86EEF5"))
		lake_w.set_shader_parameter("mid_color", Color("#32B4C2"))
		lake_w.set_shader_parameter("deep_color", Color("#1E7A96"))
		lake_w.set_shader_parameter("sky_reflect_color", Color("#DCF4FF"))
		lake_w.set_shader_parameter("foam_color", Color("#F4FDFF"))
		lake_w.set_shader_parameter("caustic_color", Color("#A4F8FC"))
		lake_w.set_shader_parameter("ring_mode", 0.0)
		lake_w.set_shader_parameter("water_alpha", 0.86)
		_mat_water_lake = lake_w
	else:
		var water_fb: StandardMaterial3D = StandardMaterial3D.new()
		water_fb.albedo_color = Color(0.24, 0.78, 0.84, 0.86)
		water_fb.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		water_fb.roughness = 0.10
		water_fb.emission_enabled = true
		water_fb.emission = Color("#3EC8D6")
		water_fb.emission_energy_multiplier = 0.25
		_mat_water_canal = water_fb
		_mat_water_lake = water_fb


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


func _safe_load_scene(res_path: String) -> PackedScene:
	if not ResourceLoader.exists(res_path):
		return null
	var loaded: Resource = load(res_path)
	if loaded is PackedScene:
		return loaded as PackedScene
	return null


# ===========================================================================
# 2. UNIFIED GROUND & VALLEY (460x560m, Y = 0.0, 0 holes)
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

	# Visual meadow terrain split cleanly around the Canal (Z in [-39, -25])
	# and sculpted with a gentle sunken basin for the Lake of Silence at (48, 12)
	# so both water bodies sit cleanly below Y = 0.0 with ZERO Z-fighting.
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
# 3. MOUNTAIN & ROLLING HILLS HORIZON RING (0 empty horizon)
# ===========================================================================

func _build_mountain_horizon_ring() -> void:
	var horizon_root: Node3D = Node3D.new()
	horizon_root.name = "HorizonMountainRing"
	add_child(horizon_root)

	# Inner Ring: soft verdant green-azure rolling hills (205..225m X, 255..275m Z)
	var hills_mesh: ArrayMesh = _create_mountain_ring_mesh(
		30,
		208.0,
		258.0,
		20.0,
		34.0,
		44.0,
		Color("#4C8E5E"),
		Color("#74B284"),
		Color("#9DC9A6"),
		101
	)
	var hills_mat: StandardMaterial3D = StandardMaterial3D.new()
	hills_mat.vertex_color_use_as_albedo = true
	hills_mat.roughness = 0.90
	hills_mat.metallic = 0.0

	var hills_inst: MeshInstance3D = MeshInstance3D.new()
	hills_inst.name = "RollingValleyHills"
	hills_inst.mesh = hills_mesh
	hills_inst.material_override = hills_mat
	hills_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	horizon_root.add_child(hills_inst)

	# Outer Ring: majestic atmospheric blue-lavender mountain peaks (235..265m X, 285..320m Z)
	var peaks_mesh: ArrayMesh = _create_mountain_ring_mesh(
		38,
		242.0,
		298.0,
		46.0,
		92.0,
		62.0,
		Color("#6C84B2"),
		Color("#92A6D2"),
		Color("#DCE6FA"),
		207
	)
	var peaks_mat: StandardMaterial3D = StandardMaterial3D.new()
	peaks_mat.vertex_color_use_as_albedo = true
	peaks_mat.roughness = 0.88
	peaks_mat.metallic = 0.0
	peaks_mat.emission_enabled = true
	peaks_mat.emission = Color("#8EA4D4")
	peaks_mat.emission_energy_multiplier = 0.08

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
# 4. CITY CANAL (Z = -32) & LAKE OF SILENCE (48, -0.18, 12)
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
		# Split around the central bridge opening (X in [-6, 6]) for clean bridge integration
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

			# Golden coping trim line along quay top
			var trim_inst: MeshInstance3D = MeshInstance3D.new()
			trim_inst.name = "CanalQuayTrim_%s_%s" % [tag, "W" if side < 0.0 else "E"]
			var trim_box: BoxMesh = BoxMesh.new()
			trim_box.size = Vector3(seg_len, 0.08, 1.04)
			trim_inst.mesh = trim_box
			trim_inst.position = Vector3(cx, 0.24, qz)
			trim_inst.material_override = _mat_marble_plaza
			trim_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			water_root.add_child(trim_inst)

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
# 5. ROADS & PLAZAS NETWORK (Roads Y = 0.03, Plazas Y = 0.04 -> 0 Z-fighting)
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

	# Circular marble plazas with golden rims at all 8 city districts + Imperial Forecourt
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
		curb_box.size = Vector3(0.26, 0.044, length)
		curb.mesh = curb_box
		curb.position = Vector3(side * (width * 0.5 + 0.10), ROAD_TOP_Y - 0.016, 0.0)
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

	# Plaza disc: height 0.06, centered at Y = 0.01 -> top face strictly at Y = 0.04
	var disc: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius + 0.25
	cyl.height = 0.06
	cyl.radial_segments = 40
	disc.mesh = cyl
	disc.position = Vector3(0.0, PLAZA_TOP_Y - 0.03, 0.0)
	disc.material_override = _mat_marble_plaza
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(disc)

	# Golden outer rim ring (strictly above plaza edge, no Z-fighting)
	var rim: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = radius - 0.16
	torus.outer_radius = radius + 0.16
	torus.rings = 40
	torus.ring_segments = 10
	rim.mesh = torus
	rim.position = Vector3(0.0, PLAZA_TOP_Y + 0.005, 0.0)
	rim.scale = Vector3(1.0, 0.22, 1.0)
	rim.material_override = _mat_gold_trim
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(rim)


# ===========================================================================
# 6. 3D CITY BUILDINGS (GLB with Protected Procedural Fallbacks + Collisions)
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

	# 6. 12 City Pavilions along Main Boulevard and side streets (clear of all roads/plazas/water)
	var pavilion_specs: Array[Dictionary] = [
		{"pos": Vector3(-14.0, 0.0, 32.0), "yaw": PI * 0.5},
		{"pos": Vector3(14.0, 0.0, 32.0), "yaw": -PI * 0.5},
		{"pos": Vector3(-14.0, 0.0, -6.0), "yaw": PI * 0.5},
		{"pos": Vector3(14.0, 0.0, -6.0), "yaw": -PI * 0.5},
		{"pos": Vector3(-22.0, 0.0, 19.0), "yaw": PI},
		{"pos": Vector3(-22.0, 0.0, -3.0), "yaw": 0.0},
		{"pos": Vector3(-14.0, 0.0, -60.0), "yaw": PI * 0.5},
		{"pos": Vector3(14.0, 0.0, -60.0), "yaw": -PI * 0.5},
		{"pos": Vector3(-22.0, 0.0, -90.0), "yaw": 0.0},
		{"pos": Vector3(22.0, 0.0, -90.0), "yaw": 0.0},
		{"pos": Vector3(-15.0, 0.0, -112.0), "yaw": PI * 0.5},
		{"pos": Vector3(15.0, 0.0, -112.0), "yaw": -PI * 0.5},
	]

	for i in range(pavilion_specs.size()):
		var spec: Dictionary = pavilion_specs[i]
		var p_pos: Vector3 = spec["pos"] as Vector3
		var p_yaw: float = float(spec["yaw"])
		_place_city_pavilion(bld_root, "CityPavilion_%02d" % (i + 1), p_pos, p_yaw)


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
		# Classical colonnade academy hall with pitched blue roof & golden crest
		_add_box_part(parent, Vector3(14.0, 0.6, 16.0), Vector3(0.0, 0.3, 0.0), _mat_stone_quay)
		_add_box_part(parent, Vector3(11.6, 6.2, 13.6), Vector3(0.0, 3.7, 0.0), _mat_marble_wall)
		_add_box_part(parent, Vector3(12.4, 0.5, 14.4), Vector3(0.0, 7.0, 0.0), _mat_gold_trim)
		_add_prism_roof(parent, Vector3(12.8, 3.4, 14.8), Vector3(0.0, 8.95, 0.0), _mat_blue_roof)
		# Front facade windows & golden doorway (local +Z faces the plaza after yaw)
		_add_box_part(parent, Vector3(2.8, 3.8, 0.3), Vector3(0.0, 2.5, 6.85), _mat_warm_window)
		for sx in [-3.8, 3.8]:
			_add_box_part(parent, Vector3(1.8, 2.6, 0.25), Vector3(sx, 3.8, 6.85), _mat_warm_window)
			_add_cylinder_part(parent, 0.42, 6.0, Vector3(sx, 3.6, 7.5), _mat_marble_plaza)
	elif kind == "library":
		# Grand circular-domed Starlight Library
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
		# Tall Baroque Kronos Clocktower with glowing golden dial & spire
		_add_box_part(parent, Vector3(10.0, 1.0, 10.0), Vector3(0.0, 0.5, 0.0), _mat_stone_quay)
		_add_box_part(parent, Vector3(7.6, 15.0, 7.6), Vector3(0.0, 8.5, 0.0), _mat_marble_wall)
		_add_box_part(parent, Vector3(8.4, 0.6, 8.4), Vector3(0.0, 16.2, 0.0), _mat_gold_trim)
		# Glowing clock face on front (+Z)
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
		# Steep blue spire
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
		# Mira's Sanctuary — warm intimate cottage-sanctuary with arched glowing windows
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
	# Canal spans Z in [-7, +7] local. Ramps span Z = +11..+4 (rise 0 -> 1.35m)
	# and Z = -4..-11 (fall 1.35m -> 0), slope ~10.9 deg for silky walking!
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

	# Deck & ramps visual slabs
	_add_box_part(parent, Vector3(10.0, 0.46, 8.4), Vector3(0.0, BRIDGE_DECK_Y - 0.23, 0.0), _mat_marble_plaza)

	var south_slab: MeshInstance3D = _add_box_part(
		parent, Vector3(10.0, 0.46, ramp_len), Vector3(0.0, BRIDGE_DECK_Y * 0.5 - 0.21, 7.6), _mat_marble_road
	)
	south_slab.rotation.x = ramp_angle

	var north_slab: MeshInstance3D = _add_box_part(
		parent, Vector3(10.0, 0.46, ramp_len), Vector3(0.0, BRIDGE_DECK_Y * 0.5 - 0.21, -7.6), _mat_marble_road
	)
	north_slab.rotation.x = -ramp_angle

	# Bridge piers resting into the canal bed
	for pz in [-4.5, 4.5]:
		_add_box_part(parent, Vector3(10.4, 2.2, 1.4), Vector3(0.0, -0.05, pz), _mat_stone_quay)

	# Marble balustrades & golden finials along both edges of the bridge
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

		# Four corner pillars with warm golden globes
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


func _place_city_pavilion(parent: Node3D, node_name: String, pos: Vector3, yaw_rad: float) -> void:
	var holder: Node3D = Node3D.new()
	holder.name = node_name
	holder.position = Vector3(pos.x, 0.0, pos.z)
	holder.rotation.y = yaw_rad
	parent.add_child(holder)

	if _scene_pavilion != null:
		var inst: Node = _scene_pavilion.instantiate()
		if inst is Node3D:
			var model_node: Node3D = inst as Node3D
			holder.add_child(model_node)
			_ground_node_to_zero(model_node)
		else:
			inst.queue_free()
			_build_procedural_pavilion(holder)
	else:
		_build_procedural_pavilion(holder)

	# Clean BoxShape3D collision
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "%s_Collision" % node_name
	body.position = Vector3(0.0, 2.6, 0.0)
	holder.add_child(body)

	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(6.6, 5.2, 6.6)
	col.shape = box
	body.add_child(col)


func _build_procedural_pavilion(parent: Node3D) -> void:
	_add_box_part(parent, Vector3(6.6, 0.36, 6.6), Vector3(0.0, 0.18, 0.0), _mat_stone_quay)
	_add_box_part(parent, Vector3(5.8, 3.8, 5.8), Vector3(0.0, 2.26, 0.0), _mat_marble_wall)
	_add_box_part(parent, Vector3(6.2, 0.24, 6.2), Vector3(0.0, 4.28, 0.0), _mat_gold_trim)
	_add_prism_roof(parent, Vector3(6.5, 2.2, 6.5), Vector3(0.0, 5.5, 0.0), _mat_blue_roof)
	_add_box_part(parent, Vector3(1.4, 2.2, 0.2), Vector3(0.0, 1.46, 2.95), _mat_warm_window)
	for sx in [-1.8, 1.8]:
		_add_box_part(parent, Vector3(0.9, 1.2, 0.18), Vector3(sx, 2.6, 2.95), _mat_warm_window)


# ===========================================================================
# 7. LIVING PROPS & BOTANICAL FLORA (strictly Y = 0.0)
# ===========================================================================

func _build_city_props_and_flora() -> void:
	var props_root: Node3D = Node3D.new()
	props_root.name = "CityPropsAndFlora"
	add_child(props_root)

	# Sakura trees along Main Boulevard, Imperial Alley, Quiet Lakes Park, Lantern Garden, School
	var sakura_spots: Array[Vector3] = [
		Vector3(-12.5, 0.0, 36.0), Vector3(12.5, 0.0, 36.0),
		Vector3(-9.5, 0.0, 22.0), Vector3(9.5, 0.0, 22.0),
		Vector3(-9.5, 0.0, -52.0), Vector3(9.5, 0.0, -52.0),
		Vector3(-9.5, 0.0, -96.0), Vector3(9.5, 0.0, -96.0),
		Vector3(-9.5, 0.0, -124.0), Vector3(9.5, 0.0, -124.0),
		# Imperial Alley grand tree-lined promenade
		Vector3(-12.5, 0.0, -154.0), Vector3(12.5, 0.0, -154.0),
		Vector3(-12.5, 0.0, -176.0), Vector3(12.5, 0.0, -176.0),
		Vector3(-12.5, 0.0, -198.0), Vector3(12.5, 0.0, -198.0),
		Vector3(-12.5, 0.0, -216.0), Vector3(12.5, 0.0, -216.0),
		# Quiet Lakes Park shoreline trees (outside Lake radius 13m from (54, 12))
		Vector3(36.0, 0.0, 24.0), Vector3(54.0, 0.0, 29.0),
		Vector3(70.0, 0.0, 14.0), Vector3(52.0, 0.0, -5.0),
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
		Vector3(-8.4, 0.0, -150.0), Vector3(8.4, 0.0, -150.0),
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
		var trunk_mat: StandardMaterial3D = StandardMaterial3D.new()
		trunk_mat.albedo_color = Color("#6B4E3D")
		trunk_mat.roughness = 0.88
		_add_cylinder_part(root, 0.28, 3.2, Vector3(0.0, 1.6, 0.0), trunk_mat)
		var crown_mat: StandardMaterial3D = StandardMaterial3D.new()
		crown_mat.albedo_color = Color("#F5B7CA")
		crown_mat.roughness = 0.72
		var crown: MeshInstance3D = MeshInstance3D.new()
		var sp: SphereMesh = SphereMesh.new()
		sp.radius = 2.1
		sp.height = 3.0
		crown.mesh = sp
		crown.position = Vector3(0.0, 3.8, 0.0)
		crown.material_override = crown_mat
		root.add_child(crown)
	elif kind == "bush":
		var leaf_mat: StandardMaterial3D = StandardMaterial3D.new()
		leaf_mat.albedo_color = Color("#468F4C")
		leaf_mat.roughness = 0.80
		var bush: MeshInstance3D = MeshInstance3D.new()
		var sp: SphereMesh = SphereMesh.new()
		sp.radius = 1.05
		sp.height = 1.35
		bush.mesh = sp
		bush.position = Vector3(0.0, 0.55, 0.0)
		bush.material_override = leaf_mat
		root.add_child(bush)
	elif kind == "planter":
		_add_cylinder_part(root, 0.65, 0.85, Vector3(0.0, 0.425, 0.0), _mat_marble_plaza)
		_add_cylinder_part(root, 0.72, 0.12, Vector3(0.0, 0.86, 0.0), _mat_gold_trim)
	else:
		# Stone lantern fallback
		_add_cylinder_part(root, 0.24, 1.6, Vector3(0.0, 0.8, 0.0), _mat_stone_quay)
		_add_box_part(root, Vector3(0.42, 0.45, 0.42), Vector3(0.0, 1.82, 0.0), _mat_warm_window)
		_add_prism_roof(root, Vector3(0.75, 0.35, 0.75), Vector3(0.0, 2.22, 0.0), _mat_stone_quay)
	return root


# ===========================================================================
# 8. LANTERN GARDEN FLOATING SKY LANTERNS (GPUParticles3D, 24 particles)
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
# 9. 3D INTERACTIVE QUEST ARTIFACTS (3 Blueprint Foundations)
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

	# Marble & gold altar pedestal grounded cleanly on the plaza
	_add_cylinder_part(item_root, 0.62, 0.16, Vector3(0.0, 0.08, 0.0), _mat_marble_plaza)
	_add_cylinder_part(item_root, 0.32, 0.88, Vector3(0.0, 0.56, 0.0), _mat_marble_wall)
	_add_cylinder_part(item_root, 0.48, 0.10, Vector3(0.0, 1.04, 0.0), _mat_gold_trim)

	# Hovering glowing artifact
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

	# Soft golden orbit halo around the artifact
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
# 10. 3D QUEST BEACON (Golden Guiding Pillar + Floating Diamond)
# ===========================================================================

func _build_quest_beacon() -> void:
	_quest_beacon_root = Node3D.new()
	_quest_beacon_root.name = "QuestBeacon"
	_quest_beacon_root.visible = false
	_quest_beacon_root.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_quest_beacon_root)

	# Translucent vertical golden light beam
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

	# Hovering golden diamond crystal
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

	# Ground halo ring at Y = 0.08
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
# GEOMETRY & GROUNDING HELPERS
# ===========================================================================

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
