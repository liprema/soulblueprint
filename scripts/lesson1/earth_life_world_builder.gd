class_name EarthLifeWorldBuilder
extends Node3D

## Continuous 3D Interactive World Builder for Chapter 1 («Было всё, кроме времени»).
## Constructs the full Earth Life sequence along the Z-axis:
## 1. Family Courtyard (Z ~ +42m to +16m): House, garden, birthday table with gifts, grandparents.
## 2. Megapolis Avenue (Z ~ +16m to -24m): Asphalt avenue, curbs, sidewalks, skyscrapers, cars, Mom & Dad.
## 3. Avenue Pocket Park (Z ~ -4m to -20m, West): Cozy brick park, blossom trees, benches, tea & pie.
## 4. Coastal Slope & Beach (Z ~ -24m to -40m): Promenade stairs, sandy dunes, beach pebbles.
## 5. The Sea & Pier (Z ~ -34m to -80m): 180x180m ocean with Gerstner shader, wooden pier, lighthouse, whole family.
## Watertight collisions, Apple Silicon Metal compliant materials, and GLB loading with procedural fallback.

signal memory_zone_entered(zone_id: String, zone_data: Dictionary)
signal memory_zone_exited(zone_id: String)

const OCEAN_SHADER: Shader = preload("res://shaders/earth_ocean_water.gdshader")

# Color Palette (Pixar & Golden Sunset aesthetic)
const COLOR_GOLD := Color(0.965, 0.827, 0.42, 1.0) # #F6D36B
const COLOR_GOLD_WARM := Color(0.988, 0.867, 0.545, 1.0) # #FCDD8B
const COLOR_AMBER := Color(0.95, 0.65, 0.22, 1.0)
const COLOR_TERRACOTTA := Color(0.78, 0.42, 0.28, 1.0)
const COLOR_ROOF_RED := Color(0.68, 0.24, 0.20, 1.0)
const COLOR_CREAM_WALL := Color(0.95, 0.92, 0.85, 1.0)
const COLOR_WINDOW_WARM := Color(1.0, 0.88, 0.62, 1.0)
const COLOR_ASPHALT := Color(0.18, 0.20, 0.24, 1.0)
const COLOR_CURB := Color(0.62, 0.64, 0.66, 1.0)
const COLOR_SIDEWALK := Color(0.72, 0.70, 0.68, 1.0)
const COLOR_GRASS := Color(0.32, 0.56, 0.28, 1.0)
const COLOR_SAND := Color(0.92, 0.82, 0.64, 1.0)
const COLOR_WOOD_DECK := Color(0.48, 0.35, 0.24, 1.0)
const COLOR_WOOD_DARK := Color(0.32, 0.22, 0.15, 1.0)
const COLOR_SKYSCRAPER_GLASS := Color(0.18, 0.32, 0.46, 1.0)
const COLOR_SKYSCRAPER_STONE := Color(0.38, 0.40, 0.45, 1.0)

# Memory Zone metadata & world locations
const MEMORY_ZONES: Dictionary = {
	"memory_birthday": {
		"id": "memory_birthday",
		"title": "День рождения среди подарков",
		"zone_title": "Семейный дом  ·  Зимний двор",
		"pos": Vector3(3.2, 0.05, 27.5),
		"radius": 3.4,
		"accent": Color(0.988, 0.867, 0.545),
	},
	"memory_office": {
		"id": "memory_office",
		"title": "Стеклянные башни и спешка",
		"zone_title": "Деловой квартал  ·  Авеню Мегаполиса",
		"pos": Vector3(12.5, 0.05, -4.5),
		"radius": 3.6,
		"accent": Color(0.45, 0.72, 1.0),
	},
	"memory_relatives": {
		"id": "memory_relatives",
		"title": "Яблочный пирог и сказки о море",
		"zone_title": "Уютный сквер  ·  Бабушка и Дедушка",
		"pos": Vector3(-13.5, 0.05, -12.0),
		"radius": 3.4,
		"accent": Color(0.98, 0.69, 0.63),
	},
	"memory_sea": {
		"id": "memory_sea",
		"title": "Морской причал на закате",
		"zone_title": "Морской пирс  ·  Закат над волнами",
		"pos": Vector3(0.0, -1.55, -66.0),
		"radius": 3.8,
		"accent": Color(0.965, 0.827, 0.42),
	},
}

# Runtime collections
var _memory_rings: Dictionary = {}
var _memory_particles: Dictionary = {}
var _lighthouse_beam: Node3D = null
var _ocean_mesh_instance: MeshInstance3D = null

# Materials cache
var _mat_grass: StandardMaterial3D
var _mat_asphalt: StandardMaterial3D
var _mat_sidewalk: StandardMaterial3D
var _mat_curb: StandardMaterial3D
var _mat_sand: StandardMaterial3D
var _mat_wood_deck: StandardMaterial3D
var _mat_wood_pylon: StandardMaterial3D
var _mat_house_wall: StandardMaterial3D
var _mat_house_roof: StandardMaterial3D
var _mat_window_glow: StandardMaterial3D
var _mat_skyscraper_wall: StandardMaterial3D
var _mat_skyscraper_glass: StandardMaterial3D
var _mat_gold_ring: StandardMaterial3D
var _mat_gold_ring_completed: StandardMaterial3D
var _mat_lantern_glow: StandardMaterial3D


func _ready() -> void:
	_init_materials()
	build_world()


func _process(delta: float) -> void:
	_animate_memory_rings(delta)
	_animate_lighthouse(delta)


# ---------------------------------------------------------------------------
# Material Initialization
# ---------------------------------------------------------------------------

func _init_materials() -> void:
	_mat_grass = StandardMaterial3D.new()
	_mat_grass.albedo_color = COLOR_GRASS
	_mat_grass.roughness = 0.85

	_mat_asphalt = StandardMaterial3D.new()
	_mat_asphalt.albedo_color = COLOR_ASPHALT
	_mat_asphalt.roughness = 0.92

	_mat_sidewalk = StandardMaterial3D.new()
	_mat_sidewalk.albedo_color = COLOR_SIDEWALK
	_mat_sidewalk.roughness = 0.75

	_mat_curb = StandardMaterial3D.new()
	_mat_curb.albedo_color = COLOR_CURB
	_mat_curb.roughness = 0.65

	_mat_sand = StandardMaterial3D.new()
	_mat_sand.albedo_color = COLOR_SAND
	_mat_sand.roughness = 0.90

	_mat_wood_deck = StandardMaterial3D.new()
	_mat_wood_deck.albedo_color = COLOR_WOOD_DECK
	_mat_wood_deck.roughness = 0.82

	_mat_wood_pylon = StandardMaterial3D.new()
	_mat_wood_pylon.albedo_color = COLOR_WOOD_DARK
	_mat_wood_pylon.roughness = 0.90

	_mat_house_wall = StandardMaterial3D.new()
	_mat_house_wall.albedo_color = COLOR_CREAM_WALL
	_mat_house_wall.roughness = 0.70

	_mat_house_roof = StandardMaterial3D.new()
	_mat_house_roof.albedo_color = COLOR_ROOF_RED
	_mat_house_roof.roughness = 0.60

	_mat_window_glow = StandardMaterial3D.new()
	_mat_window_glow.albedo_color = COLOR_WINDOW_WARM
	_mat_window_glow.emission_enabled = true
	_mat_window_glow.emission = COLOR_WINDOW_WARM
	_mat_window_glow.emission_energy_multiplier = 1.45

	_mat_skyscraper_wall = StandardMaterial3D.new()
	_mat_skyscraper_wall.albedo_color = COLOR_SKYSCRAPER_STONE
	_mat_skyscraper_wall.roughness = 0.50

	_mat_skyscraper_glass = StandardMaterial3D.new()
	_mat_skyscraper_glass.albedo_color = COLOR_SKYSCRAPER_GLASS
	_mat_skyscraper_glass.metallic = 0.65
	_mat_skyscraper_glass.roughness = 0.15
	_mat_skyscraper_glass.emission_enabled = true
	_mat_skyscraper_glass.emission = Color(0.9, 0.85, 0.65)
	_mat_skyscraper_glass.emission_energy_multiplier = 0.35

	_mat_gold_ring = StandardMaterial3D.new()
	_mat_gold_ring.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_gold_ring.albedo_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.85)
	_mat_gold_ring.emission_enabled = true
	_mat_gold_ring.emission = COLOR_GOLD
	_mat_gold_ring.emission_energy_multiplier = 1.65
	_mat_gold_ring.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_gold_ring_completed = StandardMaterial3D.new()
	_mat_gold_ring_completed.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_gold_ring_completed.albedo_color = Color(COLOR_GOLD_WARM.r, COLOR_GOLD_WARM.g, COLOR_GOLD_WARM.b, 0.40)
	_mat_gold_ring_completed.emission_enabled = true
	_mat_gold_ring_completed.emission = COLOR_GOLD_WARM
	_mat_gold_ring_completed.emission_energy_multiplier = 0.55
	_mat_gold_ring_completed.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_lantern_glow = StandardMaterial3D.new()
	_mat_lantern_glow.albedo_color = COLOR_AMBER
	_mat_lantern_glow.emission_enabled = true
	_mat_lantern_glow.emission = COLOR_AMBER
	_mat_lantern_glow.emission_energy_multiplier = 2.2


# ---------------------------------------------------------------------------
# World Assembly
# ---------------------------------------------------------------------------

func build_world() -> void:
	# Clear previous geometry if re-building
	for child: Node in get_children():
		child.queue_free()

	_build_terrain_and_roads()
	_build_family_courtyard()
	_build_megapolis_avenue()
	_build_pocket_park()
	_build_beach_and_ocean()
	_build_wooden_pier()
	_build_memory_trigger_zones()
	_build_perimeter_walls()


# ---------------------------------------------------------------------------
# 1. Terrain & Road Geometry
# ---------------------------------------------------------------------------

func _build_terrain_and_roads() -> void:
	var terrain_root := Node3D.new()
	terrain_root.name = "TerrainRoot"
	add_child(terrain_root)

	# Courtyard lawn slab (Z: 15 to 45, X: -28 to 28, Y = 0)
	_create_static_box(
		terrain_root,
		Vector3(0.0, -0.5, 30.0),
		Vector3(56.0, 1.0, 30.0),
		_mat_grass,
		"CourtyardGround"
	)

	# Megapolis avenue asphalt (Z: -25 to 15, X: -6.5 to 6.5, Y = 0)
	_create_static_box(
		terrain_root,
		Vector3(0.0, -0.5, -5.0),
		Vector3(13.0, 1.0, 40.0),
		_mat_asphalt,
		"AvenueAsphalt"
	)

	# Road painted center stripes
	for z_pos: float in range(-23, 14, 4):
		var stripe := MeshInstance3D.new()
		var pmesh := PlaneMesh.new()
		pmesh.size = Vector2(0.24, 2.0)
		stripe.mesh = pmesh
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(1.0, 0.95, 0.8)
		stripe.material_override = smat
		stripe.transform.origin = Vector3(0.0, 0.015, float(z_pos))
		terrain_root.add_child(stripe)

	# Sidewalks (East & West)
	_create_static_box(
		terrain_root,
		Vector3(-15.5, -0.4, -5.0),
		Vector3(18.0, 1.0, 40.0),
		_mat_sidewalk,
		"WestSidewalk"
	)
	_create_static_box(
		terrain_root,
		Vector3(15.5, -0.4, -5.0),
		Vector3(18.0, 1.0, 40.0),
		_mat_sidewalk,
		"EastSidewalk"
	)

	# Curbs (height 0.18m along road edge)
	_create_static_box(terrain_root, Vector3(-6.65, 0.09, -5.0), Vector3(0.3, 0.18, 40.0), _mat_curb, "CurbWest")
	_create_static_box(terrain_root, Vector3(6.65, 0.09, -5.0), Vector3(0.3, 0.18, 40.0), _mat_curb, "CurbEast")

	# Coastal slope / ramp connecting avenue to beach (Z: -25 to -34, Y: 0 to -1.8)
	var ramp_body := StaticBody3D.new()
	ramp_body.name = "CoastalRamp"
	var ramp_mesh := MeshInstance3D.new()
	var box_m := BoxMesh.new()
	box_m.size = Vector3(48.0, 1.0, 10.0)
	ramp_mesh.mesh = box_m
	ramp_mesh.material_override = _mat_sand
	ramp_body.add_child(ramp_mesh)
	var col := CollisionShape3D.new()
	var b_shape := BoxShape3D.new()
	b_shape.size = Vector3(48.0, 1.0, 10.0)
	col.shape = b_shape
	ramp_body.add_child(col)
	ramp_body.transform.origin = Vector3(0.0, -0.9, -29.5)
	ramp_body.rotation_degrees.x = 10.2
	terrain_root.add_child(ramp_body)


# ---------------------------------------------------------------------------
# 2. Family Courtyard (Z ~ +42 to +16)
# ---------------------------------------------------------------------------

func _build_family_courtyard() -> void:
	var yard_root := Node3D.new()
	yard_root.name = "FamilyCourtyard"
	add_child(yard_root)

	# Family House (Try GLB override, else procedural Pixar cottage)
	var house_placed: bool = _try_load_glb("mega_family_house.glb", yard_root, Vector3(-11.0, 0.0, 32.0), Vector3(1.2, 1.2, 1.2), 0.0, Vector3(10.5, 7.5, 8.5), Vector3(0.0, 3.75, 0.0))
	if not house_placed:
		_build_procedural_house(yard_root, Vector3(-11.0, 0.0, 32.0))

	# Cobblestone garden path leading toward courtyard gate (Z = 16)
	for i in range(12):
		var step_z: float = 34.0 - float(i) * 1.5
		var step_x: float = -2.0 + sin(float(i) * 0.45) * 1.2
		var p_mesh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.65
		cyl.bottom_radius = 0.70
		cyl.height = 0.08
		p_mesh.mesh = cyl
		p_mesh.material_override = _mat_curb
		p_mesh.transform.origin = Vector3(step_x, 0.04, step_z)
		yard_root.add_child(p_mesh)

	# Birthday Table with piled gifts & cake
	var table_placed: bool = _try_load_glb("prop_birthday_table.glb", yard_root, Vector3(3.2, 0.0, 27.5), Vector3(1.0, 1.0, 1.0), 15.0, Vector3(3.4, 1.6, 2.0), Vector3(0.2, 0.8, 0.0))
	if not table_placed:
		_build_procedural_birthday_table(yard_root, Vector3(3.2, 0.0, 27.5))

	# Grandparents Figurines near garden bench
	var grandma_placed: bool = _try_load_glb("char_grandma.glb", yard_root, Vector3(5.2, 0.0, 31.0), Vector3(1.0, 1.0, 1.0), -45.0)
	var grandpa_placed: bool = _try_load_glb("char_grandpa.glb", yard_root, Vector3(6.4, 0.0, 30.5), Vector3(1.0, 1.0, 1.0), -60.0)
	if not grandma_placed or not grandpa_placed:
		_build_procedural_grandparents(yard_root, Vector3(5.8, 0.0, 30.8))

	# Courtyard Boundary Fences & Lush Trees
	_build_courtyard_fences(yard_root)
	_build_garden_foliage(yard_root)


func _build_procedural_house(parent: Node3D, pos: Vector3) -> void:
	var house := StaticBody3D.new()
	house.name = "FamilyHouseProcedural"
	house.transform.origin = pos

	# Main Body
	var body_m := MeshInstance3D.new()
	var b_mesh := BoxMesh.new()
	b_mesh.size = Vector3(10.0, 6.0, 8.0)
	body_m.mesh = b_mesh
	body_m.material_override = _mat_house_wall
	body_m.transform.origin = Vector3(0.0, 3.0, 0.0)
	house.add_child(body_m)

	# Pitched Roof
	var roof_m := MeshInstance3D.new()
	var p_mesh := PrismMesh.new()
	p_mesh.size = Vector3(11.2, 3.5, 8.8)
	roof_m.mesh = p_mesh
	roof_m.material_override = _mat_house_roof
	roof_m.transform.origin = Vector3(0.0, 7.75, 0.0)
	roof_m.rotation_degrees.y = 90.0
	house.add_child(roof_m)

	# Porch & Door
	var porch_m := MeshInstance3D.new()
	var porch_mesh := BoxMesh.new()
	porch_mesh.size = Vector3(3.0, 0.4, 2.0)
	porch_m.mesh = porch_mesh
	porch_m.material_override = _mat_wood_deck
	porch_m.transform.origin = Vector3(2.5, 0.2, -4.5)
	house.add_child(porch_m)

	# Glowing Warm Windows
	var win_positions := [
		Vector3(-2.8, 2.6, -4.05),
		Vector3(2.5, 4.8, -4.05),
		Vector3(-2.8, 4.8, -4.05),
		Vector3(5.05, 3.2, 0.0)
	]
	for wp: Vector3 in win_positions:
		var win := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = Vector3(1.4, 1.6, 0.15) if abs(wp.x) < 5.0 else Vector3(0.15, 1.6, 1.4)
		win.mesh = wm
		win.material_override = _mat_window_glow
		win.transform.origin = wp
		house.add_child(win)

	# Chimney with soft warm smoke plume
	var chimney := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(1.1, 3.2, 1.1)
	chimney.mesh = cm
	chimney.material_override = _mat_curb
	chimney.transform.origin = Vector3(-3.2, 8.2, 1.5)
	house.add_child(chimney)

	# Collision
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(10.5, 7.5, 8.5)
	col.shape = cs
	col.transform.origin = Vector3(0.0, 3.75, 0.0)
	house.add_child(col)

	parent.add_child(house)


func _build_procedural_birthday_table(parent: Node3D, pos: Vector3) -> void:
	var table_root := StaticBody3D.new()
	table_root.name = "BirthdayTable"
	table_root.transform.origin = pos

	# Table surface
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(3.2, 0.12, 1.8)
	top.mesh = tm
	var mat_tablecloth := StandardMaterial3D.new()
	mat_tablecloth.albedo_color = Color(0.96, 0.94, 0.90)
	mat_tablecloth.roughness = 0.55
	top.material_override = mat_tablecloth
	top.transform.origin = Vector3(0.0, 0.88, 0.0)
	table_root.add_child(top)

	# 4 Table Legs
	for x_leg: float in [-1.4, 1.4]:
		for z_leg: float in [-0.75, 0.75]:
			var leg := MeshInstance3D.new()
			var lm := CylinderMesh.new()
			lm.top_radius = 0.05
			lm.bottom_radius = 0.05
			lm.height = 0.88
			leg.mesh = lm
			leg.material_override = _mat_wood_pylon
			leg.transform.origin = Vector3(x_leg, 0.44, z_leg)
			table_root.add_child(leg)

	# Birthday Cake with glowing candles
	var cake := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.35
	cm.bottom_radius = 0.38
	cm.height = 0.28
	cake.mesh = cm
	var cake_mat := StandardMaterial3D.new()
	cake_mat.albedo_color = Color(1.0, 0.88, 0.78)
	cake.material_override = cake_mat
	cake.transform.origin = Vector3(-0.6, 1.08, 0.0)
	table_root.add_child(cake)

	# 7 tiny glowing candles
	for c_idx in range(7):
		var angle: float = float(c_idx) * (TAU / 7.0)
		var candle := MeshInstance3D.new()
		var can_m := CylinderMesh.new()
		can_m.top_radius = 0.012
		can_m.bottom_radius = 0.012
		can_m.height = 0.14
		candle.mesh = can_m
		candle.material_override = _mat_lantern_glow
		candle.transform.origin = Vector3(
			-0.6 + cos(angle) * 0.22,
			1.28,
			sin(angle) * 0.22
		)
		table_root.add_child(candle)

	# Piles of Wrapped Gift Boxes (Sapphire, Coral, Ruby, Gold)
	var gift_colors: Array[Color] = [
		Color(0.24, 0.52, 0.88), # Sapphire
		Color(0.92, 0.42, 0.32), # Coral
		Color(0.85, 0.20, 0.28), # Ruby
		Color(0.96, 0.78, 0.30), # Gold
		Color(0.32, 0.75, 0.55), # Emerald
	]
	var gift_specs: Array[Dictionary] = [
		{"pos": Vector3(0.5, 1.05, -0.2), "size": Vector3(0.65, 0.50, 0.55), "rot": 12.0, "col": 0},
		{"pos": Vector3(0.4, 1.40, -0.2), "size": Vector3(0.42, 0.35, 0.40), "rot": -18.0, "col": 1},
		{"pos": Vector3(1.1, 1.02, 0.2), "size": Vector3(0.55, 0.45, 0.50), "rot": 45.0, "col": 2},
		{"pos": Vector3(-0.1, 0.25, 0.9), "size": Vector3(0.70, 0.50, 0.65), "rot": 5.0, "col": 3},
		{"pos": Vector3(0.7, 0.20, 0.95), "size": Vector3(0.60, 0.40, 0.55), "rot": -10.0, "col": 4},
	]

	for g_data: Dictionary in gift_specs:
		var g_mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = g_data["size"]
		g_mesh.mesh = bm
		var g_mat := StandardMaterial3D.new()
		g_mat.albedo_color = gift_colors[int(g_data["col"])]
		g_mat.roughness = 0.45
		g_mesh.material_override = g_mat
		g_mesh.transform.origin = g_data["pos"]
		g_mesh.rotation_degrees.y = float(g_data["rot"])
		table_root.add_child(g_mesh)

	# Collision
	var t_col := CollisionShape3D.new()
	var t_shape := BoxShape3D.new()
	t_shape.size = Vector3(3.4, 1.6, 2.0)
	t_col.shape = t_shape
	t_col.transform.origin = Vector3(0.2, 0.8, 0.0)
	table_root.add_child(t_col)

	parent.add_child(table_root)


func _build_procedural_grandparents(parent: Node3D, pos: Vector3) -> void:
	var gp_root := Node3D.new()
	gp_root.name = "GrandparentsFigurines"
	gp_root.transform.origin = pos

	# Garden Bench
	var bench := StaticBody3D.new()
	var seat := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(2.4, 0.1, 0.6)
	seat.mesh = sm
	seat.material_override = _mat_wood_deck
	seat.transform.origin = Vector3(0.0, 0.45, 0.0)
	bench.add_child(seat)
	gp_root.add_child(bench)

	# Grandma Figurine (Cozy woolen lilac shawl)
	var grandma := _create_stylized_character_mesh(Color(0.76, 0.68, 0.82), Color(0.96, 0.86, 0.78), 1.55)
	grandma.name = "GrandmaFigurine"
	grandma.transform.origin = Vector3(-0.55, 0.0, 0.0)
	grandma.rotation_degrees.y = -35.0
	gp_root.add_child(grandma)

	# Grandpa Figurine (Warm tweed vest & spectacles)
	var grandpa := _create_stylized_character_mesh(Color(0.48, 0.42, 0.36), Color(0.94, 0.84, 0.76), 1.68)
	grandpa.name = "GrandpaFigurine"
	grandpa.transform.origin = Vector3(0.55, 0.0, 0.0)
	grandpa.rotation_degrees.y = -50.0
	gp_root.add_child(grandpa)

	# Steaming tea kettle & cups on a tiny stool
	var stool := MeshInstance3D.new()
	var st_m := CylinderMesh.new()
	st_m.top_radius = 0.28
	st_m.bottom_radius = 0.30
	st_m.height = 0.42
	stool.mesh = st_m
	stool.material_override = _mat_wood_deck
	stool.transform.origin = Vector3(1.3, 0.21, 0.1)
	gp_root.add_child(stool)

	parent.add_child(gp_root)


func _build_courtyard_fences(parent: Node3D) -> void:
	# White wooden picket fence along North courtyard boundary
	var fence_root := StaticBody3D.new()
	fence_root.name = "CourtyardFences"

	for z_side: float in [44.0]:
		for x_pos: float in range(-24, 25, 2):
			var post := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.12, 1.2, 0.12)
			post.mesh = pm
			post.material_override = _mat_house_wall
			post.transform.origin = Vector3(float(x_pos), 0.6, z_side)
			fence_root.add_child(post)

	# Fence rails
	var rail := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(49.0, 0.1, 0.08)
	rail.mesh = rm
	rail.material_override = _mat_house_wall
	rail.transform.origin = Vector3(0.0, 0.85, 44.0)
	fence_root.add_child(rail)

	var f_col := CollisionShape3D.new()
	var f_shape := BoxShape3D.new()
	f_shape.size = Vector3(50.0, 1.8, 0.6)
	f_col.shape = f_shape
	f_col.transform.origin = Vector3(0.0, 0.9, 44.0)
	fence_root.add_child(f_col)

	parent.add_child(fence_root)


func _build_garden_foliage(parent: Node3D) -> void:
	var foliage_coords := [
		Vector3(-18.0, 0.0, 38.0),
		Vector3(-19.0, 0.0, 26.0),
		Vector3(16.0, 0.0, 36.0),
		Vector3(18.0, 0.0, 24.0),
		Vector3(8.0, 0.0, 40.0)
	]
	for coord: Vector3 in foliage_coords:
		_create_stylized_garden_tree(parent, coord, 1.1)


# ---------------------------------------------------------------------------
# 3. Megapolis Avenue (Z ~ +16 to -24)
# ---------------------------------------------------------------------------

func _build_megapolis_avenue() -> void:
	var ave_root := Node3D.new()
	ave_root.name = "MegapolisAvenue"
	add_child(ave_root)

	# East Skyscrapers (Towers A & B)
	var tower_a_placed: bool = _try_load_glb("mega_skyscraper_a.glb", ave_root, Vector3(25.0, 0.0, 2.0), Vector3(1.0, 1.0, 1.0), 0.0, Vector3(14.0, 52.0, 16.0), Vector3(0.0, 26.0, 0.0))
	if not tower_a_placed:
		_build_procedural_skyscraper(ave_root, Vector3(25.0, 0.0, 2.0), Vector3(14.0, 52.0, 16.0))

	var tower_b_placed: bool = _try_load_glb("mega_skyscraper_b.glb", ave_root, Vector3(26.0, 0.0, -18.0), Vector3(1.0, 1.0, 1.0), 0.0, Vector3(16.0, 64.0, 18.0), Vector3(0.0, 32.0, 0.0))
	if not tower_b_placed:
		_build_procedural_skyscraper(ave_root, Vector3(26.0, 0.0, -18.0), Vector3(16.0, 64.0, 18.0))

	# West Skyscraper
	var tower_west_placed: bool = _try_load_glb("mega_skyscraper_a.glb", ave_root, Vector3(-27.0, 0.0, 4.0), Vector3(1.1, 1.2, 1.1), 180.0, Vector3(15.0, 58.0, 18.0), Vector3(0.0, 29.0, 0.0))
	if not tower_west_placed:
		_build_procedural_skyscraper(ave_root, Vector3(-27.0, 0.0, 4.0), Vector3(15.0, 58.0, 18.0))

	# Corporate Plaza at East Sidewalk (Z ~ -4.5m)
	_build_corporate_plaza(ave_root)

	# Mom and Dad Figurines near Corporate entrance
	var mom_placed: bool = _try_load_glb("char_mom.glb", ave_root, Vector3(12.0, 0.0, -4.0), Vector3(1.0, 1.0, 1.0), -90.0)
	var dad_placed: bool = _try_load_glb("char_dad.glb", ave_root, Vector3(13.2, 0.0, -4.8), Vector3(1.0, 1.0, 1.0), -110.0)
	if not mom_placed or not dad_placed:
		_build_procedural_parents(ave_root, Vector3(12.6, 0.0, -4.4))

	# Parked City Cars along the East curb
	var car_z_positions := [8.0, -12.0]
	for cz: float in car_z_positions:
		var car_placed: bool = _try_load_glb("prop_city_car.glb", ave_root, Vector3(5.2, 0.0, cz), Vector3(1.0, 1.0, 1.0), 0.0, Vector3(2.0, 1.4, 4.4), Vector3(0.0, 0.7, 0.0))
		if not car_placed:
			_build_procedural_car(ave_root, Vector3(5.2, 0.0, cz), Color(0.22, 0.35, 0.58) if cz > 0 else Color(0.72, 0.28, 0.25))

	# Street Lamps along the sidewalks
	for sz: float in [-18.0, -6.0, 6.0]:
		_create_street_lamp(ave_root, Vector3(-7.2, 0.0, sz), true)
		_create_street_lamp(ave_root, Vector3(7.2, 0.0, sz), false)


func _build_procedural_skyscraper(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var tower := StaticBody3D.new()
	tower.name = "SkyscraperProcedural"
	tower.transform.origin = pos

	# Main monolith
	var mesh_inst := MeshInstance3D.new()
	var b_mesh := BoxMesh.new()
	b_mesh.size = size
	mesh_inst.mesh = b_mesh
	mesh_inst.material_override = _mat_skyscraper_wall
	mesh_inst.transform.origin = Vector3(0.0, size.y * 0.5, 0.0)
	tower.add_child(mesh_inst)

	# Stepped crown
	var crown := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(size.x * 0.75, 6.0, size.z * 0.75)
	crown.mesh = cm
	crown.material_override = _mat_skyscraper_glass
	crown.transform.origin = Vector3(0.0, size.y + 3.0, 0.0)
	tower.add_child(crown)

	# Glowing office window strips
	var floors: int = int(size.y / 3.2)
	for f in range(2, floors):
		var win := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = Vector3(size.x * 0.88, 1.2, size.z + 0.15)
		win.mesh = wm
		win.material_override = _mat_skyscraper_glass
		win.transform.origin = Vector3(0.0, float(f) * 3.2, 0.0)
		tower.add_child(win)

	# Collision
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = size
	col.shape = cs
	col.transform.origin = Vector3(0.0, size.y * 0.5, 0.0)
	tower.add_child(col)

	parent.add_child(tower)


func _build_corporate_plaza(parent: Node3D) -> void:
	var plaza := Node3D.new()
	plaza.name = "CorporatePlaza"
	plaza.transform.origin = Vector3(14.0, 0.0, -4.5)

	# Polished granite plaza tiles
	var floor_m := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(8.0, 0.1, 8.0)
	floor_m.mesh = fm
	floor_m.material_override = _mat_curb
	floor_m.transform.origin = Vector3(0.0, 0.05, 0.0)
	plaza.add_child(floor_m)

	# Glass Entrance Canopy
	var canopy := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(6.5, 0.15, 3.5)
	canopy.mesh = cm
	canopy.material_override = _mat_skyscraper_glass
	canopy.transform.origin = Vector3(3.0, 3.8, 0.0)
	plaza.add_child(canopy)

	# Steel pillars for canopy
	for cp_z: float in [-1.4, 1.4]:
		var pil := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.08
		pm.bottom_radius = 0.08
		pm.height = 3.8
		pil.mesh = pm
		pil.material_override = _mat_curb
		pil.transform.origin = Vector3(0.5, 1.9, cp_z)
		plaza.add_child(pil)

	parent.add_child(plaza)


func _build_procedural_parents(parent: Node3D, pos: Vector3) -> void:
	var parents_root := Node3D.new()
	parents_root.name = "ParentsFigurines"
	parents_root.transform.origin = pos

	# Mom Figurine (Elegant business coat, checking watch)
	var mom := _create_stylized_character_mesh(Color(0.28, 0.32, 0.45), Color(0.96, 0.86, 0.78), 1.68)
	mom.name = "MomFigurine"
	mom.transform.origin = Vector3(-0.6, 0.0, 0.0)
	mom.rotation_degrees.y = -80.0
	parents_root.add_child(mom)

	# Dad Figurine (Tailored overcoat, briefcase, smartphone)
	var dad := _create_stylized_character_mesh(Color(0.18, 0.22, 0.30), Color(0.95, 0.84, 0.75), 1.80)
	dad.name = "DadFigurine"
	dad.transform.origin = Vector3(0.6, 0.0, -0.4)
	dad.rotation_degrees.y = -105.0
	parents_root.add_child(dad)

	# Leather Briefcase on the pavement
	var case := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.48, 0.36, 0.16)
	case.mesh = cm
	var case_mat := StandardMaterial3D.new()
	case_mat.albedo_color = Color(0.22, 0.14, 0.10)
	case.material_override = case_mat
	case.transform.origin = Vector3(1.1, 0.18, -0.3)
	parents_root.add_child(case)

	parent.add_child(parents_root)


func _build_procedural_car(parent: Node3D, pos: Vector3, car_color: Color) -> void:
	var car := StaticBody3D.new()
	car.name = "ParkedCityCar"
	car.transform.origin = pos

	# Lower body
	var body_m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.85, 0.65, 4.2)
	body_m.mesh = bm
	var c_mat := StandardMaterial3D.new()
	c_mat.albedo_color = car_color
	c_mat.metallic = 0.55
	c_mat.roughness = 0.25
	body_m.material_override = c_mat
	body_m.transform.origin = Vector3(0.0, 0.55, 0.0)
	car.add_child(body_m)

	# Cabin & glass roof
	var cabin := MeshInstance3D.new()
	var cab_m := BoxMesh.new()
	cab_m.size = Vector3(1.55, 0.55, 2.2)
	cabin.mesh = cab_m
	cabin.material_override = _mat_skyscraper_glass
	cabin.transform.origin = Vector3(0.0, 1.10, -0.2)
	car.add_child(cabin)

	# Wheels
	var wheel_mat := StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.12, 0.12, 0.14)
	for wx: float in [-0.95, 0.95]:
		for wz: float in [-1.3, 1.3]:
			var wh := MeshInstance3D.new()
			var wm := CylinderMesh.new()
			wm.top_radius = 0.32
			wm.bottom_radius = 0.32
			wm.height = 0.22
			wh.mesh = wm
			wh.material_override = wheel_mat
			wh.transform.origin = Vector3(wx, 0.32, wz)
			wh.rotation_degrees.z = 90.0
			car.add_child(wh)

	# Collision
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(2.0, 1.4, 4.4)
	col.shape = cs
	col.transform.origin = Vector3(0.0, 0.7, 0.0)
	car.add_child(col)

	parent.add_child(car)


func _create_street_lamp(parent: Node3D, pos: Vector3, face_right: bool) -> void:
	var lamp := Node3D.new()
	lamp.name = "StreetLamp"
	lamp.transform.origin = pos

	# Pole
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.06
	pm.bottom_radius = 0.10
	pm.height = 4.2
	pole.mesh = pm
	pole.material_override = _mat_curb
	pole.transform.origin = Vector3(0.0, 2.1, 0.0)
	lamp.add_child(pole)

	# Curved arm
	var arm := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(1.2, 0.08, 0.08)
	arm.mesh = am
	arm.material_override = _mat_curb
	var arm_offset_x: float = 0.55 if face_right else -0.55
	arm.transform.origin = Vector3(arm_offset_x, 4.15, 0.0)
	lamp.add_child(arm)

	# Glowing Lantern Globe
	var globe := MeshInstance3D.new()
	var gm := SphereMesh.new()
	gm.radius = 0.22
	gm.height = 0.44
	globe.mesh = gm
	globe.material_override = _mat_lantern_glow
	var globe_x: float = 1.05 if face_right else -1.05
	globe.transform.origin = Vector3(globe_x, 3.95, 0.0)
	lamp.add_child(globe)

	# Warm OmniLight
	var light := OmniLight3D.new()
	light.light_color = COLOR_AMBER
	light.light_energy = 0.85
	light.omni_range = 8.5
	light.omni_attenuation = 1.6
	light.transform.origin = Vector3(globe_x, 3.85, 0.0)
	lamp.add_child(light)

	parent.add_child(lamp)


# ---------------------------------------------------------------------------
# 4. Avenue Pocket Park (Z ~ -4 to -20, West side)
# ---------------------------------------------------------------------------

func _build_pocket_park() -> void:
	var park_root := Node3D.new()
	park_root.name = "AvenuePocketPark"
	add_child(park_root)

	# Park green lawn (X: -24 to -8, Z: -22 to -3)
	_create_static_box(
		park_root,
		Vector3(-15.5, 0.05, -12.0),
		Vector3(14.0, 0.15, 17.0),
		_mat_grass,
		"ParkLawn"
	)

	# Circular brick plaza in park center
	var plaza_ring := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 4.0
	cyl.bottom_radius = 4.1
	cyl.height = 0.12
	plaza_ring.mesh = cyl
	plaza_ring.material_override = _mat_curb
	plaza_ring.transform.origin = Vector3(-13.5, 0.14, -12.0)
	park_root.add_child(plaza_ring)

	# Park Benches
	var bench_placed: bool = _try_load_glb("prop_city_bench.glb", park_root, Vector3(-11.5, 0.2, -12.0), Vector3(1.0, 1.0, 1.0), 90.0)
	if not bench_placed:
		_build_park_bench(park_root, Vector3(-11.5, 0.2, -12.0), 90.0)

	# Grandparents resting in park with apple pie & tea
	var gp_park_placed: bool = _try_load_glb("char_grandma.glb", park_root, Vector3(-13.5, 0.2, -12.0), Vector3(1.0, 1.0, 1.0), 30.0)
	if not gp_park_placed:
		_build_procedural_grandparents(park_root, Vector3(-13.5, 0.2, -12.0))

	# Apple pie prop on the small table
	var pie_table := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.40
	pm.bottom_radius = 0.42
	pm.height = 0.52
	pie_table.mesh = pm
	pie_table.material_override = _mat_wood_deck
	pie_table.transform.origin = Vector3(-12.4, 0.46, -11.2)
	park_root.add_child(pie_table)

	var pie := MeshInstance3D.new()
	var pie_m := CylinderMesh.new()
	pie_m.top_radius = 0.22
	pie_m.bottom_radius = 0.20
	pie_m.height = 0.08
	pie.mesh = pie_m
	var pie_mat := StandardMaterial3D.new()
	pie_mat.albedo_color = Color(0.92, 0.72, 0.38) # Golden baked crust
	pie.material_override = pie_mat
	pie.transform.origin = Vector3(-12.4, 0.76, -11.2)
	park_root.add_child(pie)

	# Blooming Blossom Trees
	_create_stylized_garden_tree(park_root, Vector3(-18.5, 0.2, -8.0), 1.25)
	_create_stylized_garden_tree(park_root, Vector3(-18.5, 0.2, -16.0), 1.15)
	_create_stylized_garden_tree(park_root, Vector3(-9.5, 0.2, -18.0), 0.95)


func _build_park_bench(parent: Node3D, pos: Vector3, rot_y: float) -> void:
	var bench := StaticBody3D.new()
	bench.name = "ParkBench"
	bench.transform.origin = pos
	bench.rotation_degrees.y = rot_y

	# Wooden slats
	var seat := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(2.2, 0.08, 0.55)
	seat.mesh = sm
	seat.material_override = _mat_wood_deck
	seat.transform.origin = Vector3(0.0, 0.42, 0.0)
	bench.add_child(seat)

	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.2, 0.45, 0.08)
	back.mesh = bm
	back.material_override = _mat_wood_deck
	back.transform.origin = Vector3(0.0, 0.75, -0.25)
	bench.add_child(back)

	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(2.4, 0.9, 0.8)
	col.shape = cs
	col.transform.origin = Vector3(0.0, 0.45, 0.0)
	bench.add_child(col)

	parent.add_child(bench)


# ---------------------------------------------------------------------------
# 5. Coastal Beach & Ocean (Z ~ -30 to -90)
# ---------------------------------------------------------------------------

func _build_beach_and_ocean() -> void:
	var sea_root := Node3D.new()
	sea_root.name = "SeaAndBeach"
	add_child(sea_root)

	# Sandy Beach Floor (Z: -32 to -52, X: -60 to 60, Y: -2.0)
	_create_static_box(
		sea_root,
		Vector3(0.0, -2.5, -42.0),
		Vector3(120.0, 1.0, 24.0),
		_mat_sand,
		"SandyBeachFloor"
	)

	# Dunes & Beach mounds
	var dune_positions := [
		Vector3(-24.0, -1.6, -35.0),
		Vector3(26.0, -1.5, -36.0),
		Vector3(-38.0, -1.4, -38.0),
		Vector3(36.0, -1.3, -40.0)
	]
	for dp: Vector3 in dune_positions:
		var dune := MeshInstance3D.new()
		var dm := SphereMesh.new()
		dm.radius = 6.0
		dm.height = 3.2
		dune.mesh = dm
		dune.material_override = _mat_sand
		dune.transform.origin = dp
		dune.scale = Vector3(1.8, 0.35, 1.2)
		sea_root.add_child(dune)

	# Ocean Water Plane (180x180m, Y = -2.5, centered at Z = -70m)
	_ocean_mesh_instance = MeshInstance3D.new()
	_ocean_mesh_instance.name = "EarthOceanWaterPlane"
	var plane := PlaneMesh.new()
	plane.size = Vector2(180.0, 180.0)
	plane.subdivide_width = 84
	plane.subdivide_depth = 84
	_ocean_mesh_instance.mesh = plane

	var ocean_mat := ShaderMaterial.new()
	ocean_mat.shader = OCEAN_SHADER
	_ocean_mesh_instance.material_override = ocean_mat
	_ocean_mesh_instance.transform.origin = Vector3(0.0, -2.5, -70.0)
	sea_root.add_child(_ocean_mesh_instance)

	# Coastal Lighthouse on East rocky bluff (X = 34, Z = -62)
	_build_coastal_lighthouse(sea_root, Vector3(34.0, -2.0, -62.0))


func _build_coastal_lighthouse(parent: Node3D, pos: Vector3) -> void:
	var lh_placed: bool = _try_load_glb("mega_lighthouse.glb", parent, pos, Vector3(1.2, 1.2, 1.2), -45.0, Vector3(8.0, 34.0, 8.0), Vector3(0.0, 17.0, 0.0))
	if lh_placed:
		return

	var lighthouse := StaticBody3D.new()
	lighthouse.name = "CoastalLighthouse"
	lighthouse.transform.origin = pos

	# Rocky foundation bluff
	var bluff := MeshInstance3D.new()
	var b_mesh := CylinderMesh.new()
	b_mesh.top_radius = 6.5
	b_mesh.bottom_radius = 8.0
	b_mesh.height = 4.5
	bluff.mesh = b_mesh
	bluff.material_override = _mat_curb
	bluff.transform.origin = Vector3(0.0, 2.25, 0.0)
	lighthouse.add_child(bluff)

	# Lighthouse conical tower (White & Crimson stripes)
	var tower := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 2.0
	tm.bottom_radius = 3.6
	tm.height = 24.0
	tower.mesh = tm
	tower.material_override = _mat_house_wall
	tower.transform.origin = Vector3(0.0, 16.5, 0.0)
	lighthouse.add_child(tower)

	# Lantern room
	var lantern_room := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 2.4
	lm.bottom_radius = 2.4
	lm.height = 4.0
	lantern_room.mesh = lm
	lantern_room.material_override = _mat_skyscraper_glass
	lantern_room.transform.origin = Vector3(0.0, 30.5, 0.0)
	lighthouse.add_child(lantern_room)

	# Dome cap
	var dome := MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 2.6
	dm.height = 3.2
	dome.mesh = dm
	dome.material_override = _mat_house_roof
	dome.transform.origin = Vector3(0.0, 33.2, 0.0)
	lighthouse.add_child(dome)

	# Rotating warm beacon beam rig
	_lighthouse_beam = Node3D.new()
	_lighthouse_beam.name = "BeaconRig"
	_lighthouse_beam.transform.origin = Vector3(0.0, 30.5, 0.0)

	var spot := SpotLight3D.new()
	spot.light_color = Color(1.0, 0.92, 0.72)
	spot.light_energy = 3.8
	spot.spot_range = 95.0
	spot.spot_angle = 22.0
	spot.spot_attenuation = 0.9
	spot.transform.origin = Vector3(0.0, 0.0, 1.5)
	_lighthouse_beam.add_child(spot)
	lighthouse.add_child(_lighthouse_beam)

	# Collision
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 4.5
	cs.height = 34.0
	col.shape = cs
	col.transform.origin = Vector3(0.0, 17.0, 0.0)
	lighthouse.add_child(col)

	parent.add_child(lighthouse)


# ---------------------------------------------------------------------------
# 6. Wooden Pier & Sunset Family Gathering
# ---------------------------------------------------------------------------

func _build_wooden_pier() -> void:
	var pier_root := Node3D.new()
	pier_root.name = "WoodenPierRoot"
	add_child(pier_root)

	# Pier Main Walkway Deck (Z: -34 to -64, width 5.2m, Y = -1.6m)
	_create_static_box(
		pier_root,
		Vector3(0.0, -1.75, -49.0),
		Vector3(5.2, 0.35, 30.0),
		_mat_wood_deck,
		"PierDeckMain"
	)

	# Pierhead Observation Platform (Z: -64 to -76, width 13.0m, length 12.0m)
	_create_static_box(
		pier_root,
		Vector3(0.0, -1.75, -70.0),
		Vector3(13.0, 0.35, 12.0),
		_mat_wood_deck,
		"PierheadPlatform"
	)

	# Pier Pylons / Pilings into the ocean water
	for z_pylon: float in range(-36, -74, 5):
		for x_side: float in [-2.4, 2.4]:
			_create_pylon(pier_root, Vector3(x_side, -3.2, float(z_pylon)), 3.8)

	# Pierhead corner pylons
	for p_corner: Vector3 in [
		Vector3(-6.2, -3.2, -64.0), Vector3(6.2, -3.2, -64.0),
		Vector3(-6.2, -3.2, -75.5), Vector3(6.2, -3.2, -75.5)
	]:
		_create_pylon(pier_root, p_corner, 3.8)

	# Pier Railings (Box colliders & wooden posts along walkway)
	_build_pier_railings(pier_root)

	# Marine Bronze Lanterns on pier posts
	for l_z: float in [-40.0, -52.0, -64.0]:
		_create_pier_lantern(pier_root, Vector3(-2.6, -0.6, l_z))
		_create_pier_lantern(pier_root, Vector3(2.6, -0.6, l_z))

	# WHOLE FAMILY GATHERING AT PIER'S END (Z = -70m, X = 0)
	_build_pier_family_gathering(pier_root, Vector3(0.0, -1.55, -70.5))


func _create_pylon(parent: Node3D, pos: Vector3, height: float) -> void:
	var pylon := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.22
	pm.bottom_radius = 0.25
	pm.height = height
	pylon.mesh = pm
	pylon.material_override = _mat_wood_pylon
	pylon.transform.origin = pos
	parent.add_child(pylon)


func _build_pier_railings(parent: Node3D) -> void:
	var railings := StaticBody3D.new()
	railings.name = "PierRailings"

	# West & East railings along walkway (Z: -34 to -64)
	for x_side: float in [-2.6, 2.6]:
		var r_mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.12, 0.95, 30.0)
		r_mesh.mesh = bm
		r_mesh.material_override = _mat_wood_deck
		r_mesh.transform.origin = Vector3(x_side, -1.1, -49.0)
		railings.add_child(r_mesh)

		var col := CollisionShape3D.new()
		var cs := BoxShape3D.new()
		cs.size = Vector3(0.25, 1.2, 30.0)
		col.shape = cs
		col.transform.origin = Vector3(x_side, -1.0, -49.0)
		railings.add_child(col)

	# Pierhead perimeter railings (West, East, North end)
	var head_railings: Array[Dictionary] = [
		{"pos": Vector3(-6.4, -1.1, -70.0), "size": Vector3(0.12, 0.95, 12.0), "col_size": Vector3(0.25, 1.2, 12.0)},
		{"pos": Vector3(6.4, -1.1, -70.0), "size": Vector3(0.12, 0.95, 12.0), "col_size": Vector3(0.25, 1.2, 12.0)},
		{"pos": Vector3(0.0, -1.1, -76.1), "size": Vector3(13.0, 0.95, 0.12), "col_size": Vector3(13.0, 1.2, 0.25)},
	]
	for hr: Dictionary in head_railings:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = hr["size"]
		m.mesh = bm
		m.material_override = _mat_wood_deck
		m.transform.origin = hr["pos"]
		railings.add_child(m)

		var col := CollisionShape3D.new()
		var cs := BoxShape3D.new()
		cs.size = hr["col_size"]
		col.shape = cs
		col.transform.origin = hr["pos"]
		railings.add_child(col)

	parent.add_child(railings)


func _create_pier_lantern(parent: Node3D, pos: Vector3) -> void:
	var lantern := Node3D.new()
	lantern.name = "PierLantern"
	lantern.transform.origin = pos

	var post := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.14, 0.85, 0.14)
	post.mesh = pm
	post.material_override = _mat_wood_pylon
	post.transform.origin = Vector3(0.0, 0.42, 0.0)
	lantern.add_child(post)

	var globe := MeshInstance3D.new()
	var gm := SphereMesh.new()
	gm.radius = 0.15
	gm.height = 0.30
	globe.mesh = gm
	globe.material_override = _mat_lantern_glow
	globe.transform.origin = Vector3(0.0, 0.95, 0.0)
	lantern.add_child(globe)

	var light := OmniLight3D.new()
	light.light_color = COLOR_AMBER
	light.light_energy = 0.65
	light.omni_range = 5.5
	light.transform.origin = Vector3(0.0, 0.95, 0.0)
	lantern.add_child(light)

	parent.add_child(lantern)


func _build_pier_family_gathering(parent: Node3D, pos: Vector3) -> void:
	var family_root := Node3D.new()
	family_root.name = "PierFamilyGathering"
	family_root.transform.origin = pos

	# Try loading GLBs for Girl, Mom, Dad, Grandparents
	var girl_placed: bool = _try_load_glb("char_girl.glb", family_root, Vector3(0.0, 0.0, 0.0), Vector3(0.9, 0.9, 0.9), 180.0)
	var mom_placed: bool = _try_load_glb("char_mom.glb", family_root, Vector3(-0.95, 0.0, 0.2), Vector3(1.0, 1.0, 1.0), 165.0)
	var dad_placed: bool = _try_load_glb("char_dad.glb", family_root, Vector3(0.95, 0.0, 0.2), Vector3(1.0, 1.0, 1.0), -165.0)
	var gm_placed: bool = _try_load_glb("char_grandma.glb", family_root, Vector3(-2.1, 0.0, 0.8), Vector3(0.95, 0.95, 0.95), 150.0)
	var gp_placed: bool = _try_load_glb("char_grandpa.glb", family_root, Vector3(2.1, 0.0, 0.8), Vector3(0.98, 0.98, 0.98), -150.0)

	# If any are missing, build stylized figurines
	if not girl_placed:
		var girl := _create_stylized_character_mesh(Color(1.0, 0.88, 0.45), Color(0.98, 0.88, 0.80), 1.20)
		girl.name = "GirlFigurine"
		girl.rotation_degrees.y = 180.0
		family_root.add_child(girl)

	if not mom_placed:
		var mom := _create_stylized_character_mesh(Color(0.85, 0.48, 0.52), Color(0.96, 0.86, 0.78), 1.68)
		mom.name = "MomFigurine"
		mom.transform.origin = Vector3(-0.95, 0.0, 0.2)
		mom.rotation_degrees.y = 165.0
		family_root.add_child(mom)

	if not dad_placed:
		var dad := _create_stylized_character_mesh(Color(0.24, 0.42, 0.62), Color(0.95, 0.84, 0.75), 1.80)
		dad.name = "DadFigurine"
		dad.transform.origin = Vector3(0.95, 0.0, 0.2)
		dad.rotation_degrees.y = -165.0
		family_root.add_child(dad)

	if not gm_placed:
		var gm := _create_stylized_character_mesh(Color(0.72, 0.65, 0.78), Color(0.96, 0.86, 0.78), 1.55)
		gm.name = "GrandmaFigurine"
		gm.transform.origin = Vector3(-2.1, 0.0, 0.8)
		gm.rotation_degrees.y = 150.0
		family_root.add_child(gm)

	if not gp_placed:
		var gp := _create_stylized_character_mesh(Color(0.44, 0.40, 0.38), Color(0.94, 0.84, 0.76), 1.68)
		gp.name = "GrandpaFigurine"
		gp.transform.origin = Vector3(2.1, 0.0, 0.8)
		gp.rotation_degrees.y = -150.0
		family_root.add_child(gp)

	# Golden Sunset Rim Light accentuating the family silhouette
	var rim := DirectionalLight3D.new()
	rim.name = "SunsetSilhouetteRimLight"
	rim.light_color = COLOR_GOLD_WARM
	rim.light_energy = 0.75
	rim.transform.basis = Basis(Vector3.UP, deg_to_rad(180.0)) * Basis(Vector3.RIGHT, deg_to_rad(-15.0))
	family_root.add_child(rim)

	parent.add_child(family_root)


# ---------------------------------------------------------------------------
# 7. Memory Pedestals & Soft Golden Ground Rings
# ---------------------------------------------------------------------------

func _build_memory_trigger_zones() -> void:
	var zones_root := Node3D.new()
	zones_root.name = "MemoryTriggerZones"
	add_child(zones_root)

	for zone_key: String in MEMORY_ZONES.keys():
		var z_data: Dictionary = MEMORY_ZONES[zone_key] as Dictionary
		var z_pos: Vector3 = z_data["pos"] as Vector3
		var z_rad: float = float(z_data["radius"])

		var trigger_node := Area3D.new()
		trigger_node.name = "Trigger_" + zone_key
		trigger_node.transform.origin = z_pos
		trigger_node.collision_layer = 0
		trigger_node.collision_mask = 2 # Player layer

		var col := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = z_rad
		cs.height = 2.4
		col.shape = cs
		col.transform.origin = Vector3(0.0, 1.2, 0.0)
		trigger_node.add_child(col)

		# Floating soft golden ground ring (NO Sims plumbob!)
		var ring_mesh := MeshInstance3D.new()
		ring_mesh.name = "GoldenGroundRing"
		var torus := TorusMesh.new()
		torus.inner_radius = z_rad * 0.75
		torus.outer_radius = z_rad * 0.85
		torus.rings = 36
		torus.ring_segments = 12
		ring_mesh.mesh = torus
		ring_mesh.material_override = _mat_gold_ring
		ring_mesh.transform.origin = Vector3(0.0, 0.04, 0.0)
		trigger_node.add_child(ring_mesh)

		# Inner subtle constellation disc
		var inner_disc := MeshInstance3D.new()
		inner_disc.name = "InnerSealDisc"
		var cyl_m := CylinderMesh.new()
		cyl_m.top_radius = z_rad * 0.35
		cyl_m.bottom_radius = z_rad * 0.36
		cyl_m.height = 0.02
		inner_disc.mesh = cyl_m
		var disc_mat := StandardMaterial3D.new()
		disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		disc_mat.albedo_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.22)
		disc_mat.emission_enabled = true
		disc_mat.emission = COLOR_GOLD
		disc_mat.emission_energy_multiplier = 0.8
		inner_disc.material_override = disc_mat
		inner_disc.transform.origin = Vector3(0.0, 0.02, 0.0)
		trigger_node.add_child(inner_disc)

		# Connect signals
		trigger_node.body_entered.connect(_on_zone_entered.bind(zone_key, z_data))
		trigger_node.body_exited.connect(_on_zone_exited.bind(zone_key))

		zones_root.add_child(trigger_node)
		_memory_rings[zone_key] = ring_mesh


func _on_zone_entered(body: Node, zone_id: String, zone_data: Dictionary) -> void:
	if body is CharacterBody3D or body.name == "Player3D":
		memory_zone_entered.emit(zone_id, zone_data)


func _on_zone_exited(body: Node, zone_id: String) -> void:
	if body is CharacterBody3D or body.name == "Player3D":
		memory_zone_exited.emit(zone_id)


## Called by gameplay manager when memory has been read and collected
func mark_memory_completed(zone_id: String) -> void:
	if _memory_rings.has(zone_id):
		var ring: MeshInstance3D = _memory_rings[zone_id] as MeshInstance3D
		if is_instance_valid(ring):
			ring.material_override = _mat_gold_ring_completed
			var t := create_tween()
			t.tween_property(ring, "scale", Vector3(1.15, 1.0, 1.15), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_property(ring, "scale", Vector3(1.0, 1.0, 1.0), 0.4)


# ---------------------------------------------------------------------------
# 8. Watertight Boundary Colliders
# ---------------------------------------------------------------------------

func _build_perimeter_walls() -> void:
	var walls := StaticBody3D.new()
	walls.name = "PerimeterColliders"

	var wall_specs: Array[Dictionary] = [
		{"pos": Vector3(0.0, 5.0, 46.0), "size": Vector3(80.0, 16.0, 2.0)},   # South boundary
		{"pos": Vector3(0.0, 5.0, -82.0), "size": Vector3(140.0, 16.0, 2.0)}, # North ocean boundary
		{"pos": Vector3(-42.0, 5.0, -15.0), "size": Vector3(2.0, 16.0, 140.0)}, # West boundary
		{"pos": Vector3(42.0, 5.0, -15.0), "size": Vector3(2.0, 16.0, 140.0)},  # East boundary
	]

	for w: Dictionary in wall_specs:
		var col := CollisionShape3D.new()
		var cs := BoxShape3D.new()
		cs.size = w["size"]
		col.shape = cs
		col.transform.origin = w["pos"]
		walls.add_child(col)

	add_child(walls)


# ---------------------------------------------------------------------------
# Helper Sculpting & GLB Overrides
# ---------------------------------------------------------------------------

func _try_load_glb(
	filename: String,
	parent: Node3D,
	pos: Vector3,
	sc: Vector3,
	rot_y_deg: float,
	collision_size: Vector3 = Vector3.ZERO,
	collision_offset: Vector3 = Vector3.ZERO
) -> bool:
	var candidate_paths: Array[String] = [
		"res://assets/models/lesson1/" + filename,
		"res://assets/models/lesson1/characters/" + filename,
		"res://assets/models/lesson1/props/" + filename,
		"res://assets/models/lesson1/architecture/" + filename,
		"res://assets/models/characters/" + filename,
		"res://assets/models/props/" + filename,
		"res://assets/models/city/" + filename,
		"res://assets/models/city/props/" + filename,
		"res://assets/models/city/pixar/" + filename,
		"res://assets/models/city/landmarks/" + filename,
		"res://assets/models/city/venues/" + filename,
	]

	for path: String in candidate_paths:
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			var res: Resource = ResourceLoader.load(path)
			if res is PackedScene:
				var inst: Node = (res as PackedScene).instantiate()
				if inst is Node3D:
					var n3d := inst as Node3D
					if collision_size != Vector3.ZERO:
						var body := StaticBody3D.new()
						body.name = "Collider_" + filename.get_basename()
						body.transform.origin = pos
						n3d.scale = sc
						n3d.rotation_degrees.y = rot_y_deg
						body.add_child(n3d)
						var col := CollisionShape3D.new()
						var cs := BoxShape3D.new()
						cs.size = collision_size
						col.shape = cs
						col.transform.origin = collision_offset
						body.add_child(col)
						parent.add_child(body)
					else:
						n3d.transform.origin = pos
						n3d.scale = sc
						n3d.rotation_degrees.y = rot_y_deg
						parent.add_child(n3d)
					return true
	return false


func _create_static_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, node_name: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.transform.origin = pos

	var mesh_inst := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh_inst.mesh = bm
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = size
	col.shape = cs
	body.add_child(col)

	parent.add_child(body)
	return body


func _create_stylized_character_mesh(clothes_color: Color, skin_color: Color, height_scale: float) -> Node3D:
	var root := Node3D.new()

	# Torso / Coat
	var torso := MeshInstance3D.new()
	var tm := CapsuleMesh.new()
	tm.radius = 0.28
	tm.height = 0.85 * height_scale
	torso.mesh = tm
	var mat_clothes := StandardMaterial3D.new()
	mat_clothes.albedo_color = clothes_color
	mat_clothes.roughness = 0.65
	torso.material_override = mat_clothes
	torso.transform.origin = Vector3(0.0, 0.75 * height_scale, 0.0)
	root.add_child(torso)

	# Head
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.22
	hm.height = 0.44
	head.mesh = hm
	var mat_skin := StandardMaterial3D.new()
	mat_skin.albedo_color = skin_color
	mat_skin.roughness = 0.50
	head.material_override = mat_skin
	head.transform.origin = Vector3(0.0, 1.35 * height_scale, 0.0)
	root.add_child(head)

	# Soft warm eye sparkle
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.15, 0.12, 0.10)
	for ex: float in [-0.08, 0.08]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.03
		em.height = 0.06
		eye.mesh = em
		eye.material_override = eye_mat
		eye.transform.origin = Vector3(ex, 1.38 * height_scale, 0.19)
		root.add_child(eye)

	return root


func _create_stylized_garden_tree(parent: Node3D, pos: Vector3, sc: float) -> void:
	var tree := StaticBody3D.new()
	tree.name = "GardenTree"
	tree.transform.origin = pos

	# Trunk
	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.20 * sc
	tm.bottom_radius = 0.35 * sc
	tm.height = 2.4 * sc
	trunk.mesh = tm
	trunk.material_override = _mat_wood_pylon
	trunk.transform.origin = Vector3(0.0, 1.2 * sc, 0.0)
	tree.add_child(trunk)

	# Foliage Canopy (Double puffy spheres)
	var foliage_mat := StandardMaterial3D.new()
	foliage_mat.albedo_color = Color(0.28, 0.52, 0.26)
	foliage_mat.roughness = 0.75

	var canopy1 := MeshInstance3D.new()
	var sm1 := SphereMesh.new()
	sm1.radius = 1.6 * sc
	sm1.height = 2.8 * sc
	canopy1.mesh = sm1
	canopy1.material_override = foliage_mat
	canopy1.transform.origin = Vector3(0.0, 3.2 * sc, 0.0)
	tree.add_child(canopy1)

	var canopy2 := MeshInstance3D.new()
	var sm2 := SphereMesh.new()
	sm2.radius = 1.2 * sc
	sm2.height = 2.2 * sc
	canopy2.mesh = sm2
	canopy2.material_override = foliage_mat
	canopy2.transform.origin = Vector3(0.3 * sc, 4.4 * sc, -0.2 * sc)
	tree.add_child(canopy2)

	# Collision
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.45 * sc
	cs.height = 2.5 * sc
	col.shape = cs
	col.transform.origin = Vector3(0.0, 1.25 * sc, 0.0)
	tree.add_child(col)

	parent.add_child(tree)


# ---------------------------------------------------------------------------
# Animations
# ---------------------------------------------------------------------------

func _animate_memory_rings(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	for zone_id: String in _memory_rings.keys():
		var ring: MeshInstance3D = _memory_rings[zone_id] as MeshInstance3D
		if is_instance_valid(ring):
			var pulse: float = 1.0 + sin(t * 2.2 + float(zone_id.hash() % 10)) * 0.06
			ring.scale = Vector3(pulse, 1.0, pulse)
			ring.rotation.y = t * 0.25


func _animate_lighthouse(delta: float) -> void:
	if is_instance_valid(_lighthouse_beam):
		_lighthouse_beam.rotate_y(delta * 0.65)
