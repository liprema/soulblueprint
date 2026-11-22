class_name AkashaGardenDecorator
extends Node3D

## Lush botanical and ornamental world decorator for the Akashic Chronicles Prologue.
## Populates the Starting Monolith Plaza, all 5 Floating Temple Islands, and the
## Colossal Cathedral Podium & Sanctuary with Sakura trees, carved blooming marble
## planters, celestial silk-and-crystal garden ornaments, and cascading emerald ivy
## & sakura-blossom vine garlands.

const SAKURA_TREE_PATH: String = "res://assets/models/props/sakura_tree.glb"
const GARDEN_PLANTER_PATH: String = "res://assets/models/props/garden_planter.glb"
const CELESTIAL_ORNAMENT_PATH: String = "res://assets/models/props/celestial_ornament.glb"
const LUSH_BUSH_PATH: String = "res://assets/models/props/lush_bush_hedge.glb"

const ORNAMENT_SWAY_MAX_RAD: float = 0.02617994 # 1.5 degrees in radians

var _sakura_tree_scene: PackedScene = null
var _garden_planter_scene: PackedScene = null
var _celestial_ornament_scene: PackedScene = null
var _lush_bush_scene: PackedScene = null

# Shared lightweight materials for cascading vines, verdant tree variants & procedural fallbacks
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
var _mat_gold_trim: StandardMaterial3D = null
var _mat_crystal: StandardMaterial3D = null
var _mat_silk: StandardMaterial3D = null

# Shared lightweight meshes for instanced foliage & vine clusters
var _mesh_vine_stem: BoxMesh = null
var _mesh_leaf_cluster: BoxMesh = null
var _mesh_blossom_cluster: SphereMesh = null
var _mesh_blossom_small: SphereMesh = null

# Animated celestial ornaments for gentle wind breathing
var _sway_ornaments: Array[Node3D] = []
var _sway_base_rot: Array[Vector3] = []
var _sway_phases: Array[float] = []
var _elapsed_time: float = 0.0
var _is_populated: bool = false


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_elapsed_time += delta
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


## Populates the entire Prologue world with Sakura & verdant palace trees, lush rose-and-emerald
## bush hedges, blooming planters, celestial ornaments, and thick cascading emerald ivy garlands.
func populate_garden(architecture: Node3D = null) -> void:
	if _is_populated:
		return
	_is_populated = true

	_load_prop_scenes()
	_init_shared_resources()

	_decorate_starting_plaza()
	_decorate_twin_viaducts()
	_decorate_floating_islands(architecture)
	_decorate_cathedral_sanctuary()


func _load_prop_scenes() -> void:
	_sakura_tree_scene = _safe_load_scene(SAKURA_TREE_PATH)
	_garden_planter_scene = _safe_load_scene(GARDEN_PLANTER_PATH)
	_celestial_ornament_scene = _safe_load_scene(CELESTIAL_ORNAMENT_PATH)
	_lush_bush_scene = _safe_load_scene(LUSH_BUSH_PATH)


func _safe_load_scene(res_path: String) -> PackedScene:
	if not ResourceLoader.exists(res_path):
		return null
	var loaded: Resource = load(res_path)
	if loaded is PackedScene:
		return loaded as PackedScene
	return null


func _init_shared_resources() -> void:
	# Foliage & blossom palette
	_mat_leaf_spring = _create_botanical_material(Color("#449656"), 0.62, 0.0, Color(0.0, 0.0, 0.0), 0.0)
	_mat_leaf_emerald = _create_botanical_material(Color("#2B6E40"), 0.66, 0.0, Color(0.0, 0.0, 0.0), 0.0)
	_mat_leaf_mint = _create_botanical_material(Color("#6EC274"), 0.56, 0.0, Color(0.0, 0.0, 0.0), 0.0)

	# Double-sided sunlit emerald canopy materials for lush green palace tree variants
	_mat_canopy_emerald_deep = _create_botanical_material(Color("#3E9250"), 0.58, 0.0, Color(0.0, 0.0, 0.0), 0.0)
	_mat_canopy_emerald_deep.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_canopy_emerald_sunlit = _create_botanical_material(Color("#58B064"), 0.54, 0.0, Color(0.0, 0.0, 0.0), 0.0)
	_mat_canopy_emerald_sunlit.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_canopy_flower_accent = _create_botanical_material(Color("#FFF0F5"), 0.48, 0.0, Color("#FFE6EE"), 0.08)
	_mat_canopy_flower_accent.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_blossom_pink = _create_botanical_material(Color("#F78EB0"), 0.58, 0.0, Color("#F78EB0"), 0.14)
	_mat_blossom_blush = _create_botanical_material(Color("#FFC8D8"), 0.55, 0.0, Color("#FFD6E4"), 0.18)
	_mat_blossom_lilac = _create_botanical_material(Color("#C89EEB"), 0.56, 0.0, Color("#D6B6F5"), 0.16)

	# Fallback prop materials (harmonized with Akasha sunlit alabaster & champagne gold)
	_mat_bark = _create_botanical_material(Color("#6E534B"), 0.85, 0.0, Color(0.0, 0.0, 0.0), 0.0)
	_mat_marble = _create_botanical_material(Color("#EDE6DC"), 0.42, 0.04, Color(0.0, 0.0, 0.0), 0.0)
	_mat_gold_trim = _create_botanical_material(Color("#DFC48E"), 0.36, 0.75, Color("#EDD29A"), 0.12)
	_mat_crystal = _create_botanical_material(Color("#C6E8FF"), 0.18, 0.10, Color("#B8E6FF"), 0.55)
	_mat_silk = _create_botanical_material(Color("#F9D8E6"), 0.52, 0.05, Color("#FFE2EE"), 0.14)

	# Shared lightweight meshes for vine garlands
	_mesh_vine_stem = BoxMesh.new()
	_mesh_vine_stem.size = Vector3(0.08, 0.44, 0.08)

	_mesh_leaf_cluster = BoxMesh.new()
	_mesh_leaf_cluster.size = Vector3(0.36, 0.26, 0.32)

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

	# 4 trees framing the plaza: 2 pink Sakura at rear corners + 2 lush verdant green trees forward
	_place_sakura_tree(root, "PlazaSakura_L", Vector3(-6.1, 0.0, 44.2), deg_to_rad(-34.0), 0.95)
	_place_sakura_tree(root, "PlazaSakura_R", Vector3(6.1, 0.0, 44.2), deg_to_rad(34.0), 0.95)

	var plaza_green_l: Node3D = _place_verdant_tree(
		root, "PlazaVerdantTree_L", Vector3(-6.4, 0.0, 29.0), deg_to_rad(-118.0), 0.78
	)
	plaza_green_l.rotation.z = deg_to_rad(8.5)
	var plaza_green_r: Node3D = _place_verdant_tree(
		root, "PlazaVerdantTree_R", Vector3(6.4, 0.0, 29.0), deg_to_rad(118.0), 0.78
	)
	plaza_green_r.rotation.z = deg_to_rad(-8.5)

	# 10 lush rose-and-emerald bush hedges lining BOTH balustrades (z = 25..44, x = +-6.35)
	# Tucked neatly between lanterns (z = 27, 41) and planters (z = 31, 38), center walkway 100% clear
	var plaza_bush_z: Array[float] = [25.4, 33.3, 35.7, 39.6, 42.6]
	var plaza_bush_scales: Array[float] = [0.88, 0.92, 0.90, 0.86, 0.94]
	for i: int in range(plaza_bush_z.size()):
		var z_val: float = plaza_bush_z[i]
		var sc: float = plaza_bush_scales[i]
		var yaw_jitter: float = deg_to_rad(5.0 if i % 2 == 0 else -5.0)
		_place_lush_bush(
			root,
			"PlazaBush_L_%02d" % i,
			Vector3(-6.35, 0.0, z_val),
			deg_to_rad(90.0) + yaw_jitter,
			sc
		)
		_place_lush_bush(
			root,
			"PlazaBush_R_%02d" % i,
			Vector3(6.35, 0.0, z_val),
			deg_to_rad(-90.0) - yaw_jitter,
			sc
		)

	# 4 carved blooming marble planters along the balustrades (clear of lanterns at z = 41 and z = 27)
	_place_garden_planter(root, "PlazaPlanter_NW", Vector3(-6.1, 0.0, 38.0), deg_to_rad(90.0), 1.0)
	_place_garden_planter(root, "PlazaPlanter_NE", Vector3(6.1, 0.0, 38.0), deg_to_rad(-90.0), 1.0)
	_place_garden_planter(root, "PlazaPlanter_SW", Vector3(-6.1, 0.0, 31.0), deg_to_rad(90.0), 1.0)
	_place_garden_planter(root, "PlazaPlanter_SE", Vector3(6.1, 0.0, 31.0), deg_to_rad(-90.0), 1.0)

	# 2 celestial silk-and-crystal ornaments framing the forward ceremonial prow (facing inward)
	_place_celestial_ornament(root, "PlazaOrnament_L", Vector3(-4.8, 0.0, 23.2), deg_to_rad(68.0), 1.0, 0.0)
	_place_celestial_ornament(root, "PlazaOrnament_R", Vector3(4.8, 0.0, 23.2), deg_to_rad(-68.0), 1.0, 1.8)

	# Double-density cascading emerald ivy & flowering garlands along both plaza sides AND the prow
	var vine_root: Node3D = Node3D.new()
	vine_root.name = "PlazaHangingVines"
	root.add_child(vine_root)

	var z_slots: int = 18
	for side_idx: int in range(2):
		var side_sign: float = -1.0 if side_idx == 0 else 1.0
		var edge_x: float = side_sign * 8.05
		var outward_dir: Vector3 = Vector3(side_sign, 0.0, 0.0)
		for i: int in range(z_slots):
			var t: float = float(i) / float(z_slots - 1)
			var z_pos: float = lerpf(24.5, 45.0, t)
			var seed_val: float = float(side_idx * 17 + i * 7 + 3)
			var drop_len: float = 1.85 + fmod(seed_val * 0.6180339, 1.0) * 2.55 # 1.85m .. 4.40m
			_build_vine_garland(
				vine_root,
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
		var prow_drop: float = 1.9 + fmod(float(p_idx * 13 + 5) * 0.6180339, 1.0) * 2.15
		_build_vine_garland(vine_root, anchor_pt, prow_out, prow_drop, 80 + p_idx)


# ---------------------------------------------------------------------------
# 1b. Symmetrical Twin Flanking Celestial Viaducts (x = -56.0 & +56.0, y = 14.0)
# ---------------------------------------------------------------------------

func _decorate_twin_viaducts() -> void:
	var root: Node3D = Node3D.new()
	root.name = "TwinViaductsGarden"
	add_child(root)

	var vine_root: Node3D = Node3D.new()
	vine_root.name = "ViaductHangingVines"
	root.add_child(vine_root)

	var planter_zs: Array[float] = [6.0, -36.0, -80.0, -124.0, -168.0, -212.0]
	var vine_zs: Array[float] = [10.0, -14.0, -38.0, -62.0, -86.0, -110.0, -134.0, -158.0, -182.0, -206.0, -230.0]

	for side_idx: int in range(2):
		var side_sign: float = -1.0 if side_idx == 0 else 1.0
		var side_tag: String = "W" if side_sign < 0.0 else "E"
		var inward_dir: Vector3 = Vector3(-side_sign, 0.0, 0.0)
		var planter_x: float = side_sign * 52.2
		var vine_x: float = side_sign * 50.9
		var yaw_inward: float = deg_to_rad(90.0 if side_sign < 0.0 else -90.0)

		for i: int in range(planter_zs.size()):
			var pz: float = planter_zs[i]
			_place_garden_planter(
				root,
				"ViaductPlanter_%s_%02d" % [side_tag, i],
				Vector3(planter_x, 14.0, pz),
				yaw_inward,
				1.05
			)

		for j: int in range(vine_zs.size()):
			var vz: float = vine_zs[j]
			var drop_len: float = 2.6 + fmod(float(side_idx * 13 + j * 7 + 2) * 0.6180339, 1.0) * 2.4
			_build_vine_garland(
				vine_root,
				Vector3(vine_x, 13.9, vz),
				inward_dir,
				drop_len,
				300 + side_idx * 20 + j
			)


# ---------------------------------------------------------------------------
# 2. Five Floating Temple Islands
# ---------------------------------------------------------------------------

func _decorate_floating_islands(architecture: Node3D) -> void:
	var root: Node3D = Node3D.new()
	root.name = "FloatingIslandsGarden"
	add_child(root)

	var island_positions: Array[Vector3] = _resolve_island_positions(architecture)
	var sakura_angles_deg: Array[float] = [45.0, 225.0]
	var planter_angles_deg: Array[float] = [135.0, 328.0]
	# 6 outer-perimeter bush angles keeping all 4 cardinal approaches (0, 90, 180, 270) & center clear
	var bush_angles_deg: Array[float] = [26.0, 66.0, 114.0, 156.0, 204.0, 246.0]
	var bush_radii: Array[float] = [6.5, 6.4, 6.6, 6.4, 6.5, 6.6]

	for idx: int in range(island_positions.size()):
		var center: Vector3 = island_positions[idx]
		var island_node: Node3D = Node3D.new()
		island_node.name = "IslandGarden_%02d" % idx
		root.add_child(island_node)

		# 3 trees per island: 2 pink Sakura (45°, 225°) + 1 lush green palace tree (304°) at r = 5.4..5.9m
		for t_idx: int in range(sakura_angles_deg.size()):
			var angle_rad: float = deg_to_rad(sakura_angles_deg[t_idx])
			var offset: Vector3 = Vector3(cos(angle_rad) * 5.5, 0.0, sin(angle_rad) * 5.5)
			var tree_pos: Vector3 = center + offset
			var face_inward_yaw: float = atan2(-offset.x, -offset.z) + deg_to_rad(14.0 if t_idx == 0 else -14.0)
			var scale_factor: float = 0.85 + fmod(float(idx * 3 + t_idx * 5 + 1) * 0.37, 1.0) * 0.20
			_place_sakura_tree(
				island_node,
				"Island_%02d_Sakura_%d" % [idx, t_idx],
				tree_pos,
				face_inward_yaw,
				scale_factor
			)

		var green_angle: float = deg_to_rad(304.0)
		var green_offset: Vector3 = Vector3(cos(green_angle) * 5.75, 0.0, sin(green_angle) * 5.75)
		var green_yaw: float = atan2(-green_offset.x, -green_offset.z) + deg_to_rad(-16.0)
		var green_scale: float = 0.88 + fmod(float(idx * 7 + 2) * 0.41, 1.0) * 0.18
		_place_verdant_tree(
			island_node,
			"Island_%02d_VerdantTree" % idx,
			center + green_offset,
			green_yaw,
			green_scale
		)

		# 6 lush rose-and-emerald bushes ringing the outer perimeter (r = 6.2..6.8m)
		for b_idx: int in range(bush_angles_deg.size()):
			var b_angle: float = deg_to_rad(bush_angles_deg[b_idx])
			var b_rad: float = bush_radii[b_idx]
			var b_offset: Vector3 = Vector3(cos(b_angle) * b_rad, 0.0, sin(b_angle) * b_rad)
			var b_yaw: float = atan2(-b_offset.x, -b_offset.z)
			var b_scale: float = 0.82 + fmod(float(idx * 5 + b_idx * 3 + 1) * 0.29, 1.0) * 0.18
			_place_lush_bush(
				island_node,
				"Island_%02d_Bush_%d" % [idx, b_idx],
				center + b_offset,
				b_yaw,
				b_scale
			)

		# 2 blooming garden planters at diagonal bays (r = 5.5m)
		for p_idx: int in range(planter_angles_deg.size()):
			var angle_rad: float = deg_to_rad(planter_angles_deg[p_idx])
			var offset: Vector3 = Vector3(cos(angle_rad) * 5.5, 0.0, sin(angle_rad) * 5.5)
			var planter_pos: Vector3 = center + offset
			var face_inward_yaw: float = atan2(-offset.x, -offset.z)
			_place_garden_planter(
				island_node,
				"Island_%02d_Planter_%d" % [idx, p_idx],
				planter_pos,
				face_inward_yaw,
				0.96
			)

		# 1 celestial silk-and-crystal ornament at angle 128° (r = 6.3m, rotated toward center)
		var orn_angle: float = deg_to_rad(128.0)
		var orn_offset: Vector3 = Vector3(cos(orn_angle) * 6.3, 0.0, sin(orn_angle) * 6.3)
		var orn_pos: Vector3 = center + orn_offset
		var orn_yaw: float = atan2(-orn_offset.x, -orn_offset.z)
		_place_celestial_ornament(
			island_node,
			"Island_%02d_Ornament" % idx,
			orn_pos,
			orn_yaw,
			1.0,
			float(idx) * 1.35 + 0.7
		)

		# 10 dense cascading emerald ivy curtains draping down y = -0.2..-8.0m around the island rim
		var vine_group: Node3D = Node3D.new()
		vine_group.name = "Island_%02d_HangingVines" % idx
		island_node.add_child(vine_group)

		var phase_deg: float = float(idx) * 18.0
		for v_idx: int in range(10):
			var v_angle: float = deg_to_rad(float(v_idx) * 36.0 + phase_deg)
			var out_dir: Vector3 = Vector3(cos(v_angle), 0.0, sin(v_angle))
			var anchor: Vector3 = center + Vector3(out_dir.x * 8.2, -0.2, out_dir.z * 8.2)
			var drop_seed: float = float(idx * 11 + v_idx * 5 + 2)
			var main_drop: float = 4.0 + fmod(drop_seed * 0.6180339, 1.0) * 3.8 # y = -0.2 .. -8.0m
			_build_vine_garland(vine_group, anchor, out_dir, main_drop, idx * 41 + v_idx * 3)

			# Secondary side tendril for thick overflowing emerald curtain
			var tangent: Vector3 = Vector3(-out_dir.z, 0.0, out_dir.x)
			var side_anchor: Vector3 = anchor + tangent * 0.62
			var side_drop: float = clampf(main_drop * 0.68, 2.2, 5.4)
			_build_vine_garland(vine_group, side_anchor, out_dir, side_drop, idx * 41 + v_idx * 3 + 1)


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
# 3. Walkable Fairytale Castle Outer Terraces, Grand Staircase & Panoramic Galleries (z = -280)
# ---------------------------------------------------------------------------

func _decorate_cathedral_sanctuary() -> void:
	var root: Node3D = Node3D.new()
	root.name = "CathedralSanctuaryGarden"
	add_child(root)

	# 12 majestic Castle Trees (6 pink Sakura + 6 lush verdant emerald palace trees, scale 1.15..1.44)
	# Strictly on the outer lower castle garden terraces (y = 4.0, x = +-21..+-42, z = -250..-294)
	# keeping the Rotunda interior, front stairs, panoramic galleries, and all 3 relic spots 100% clear!
	_place_sakura_tree(root, "CathedralSakura_LowerL", Vector3(-21.5, 4.0, -251.5), deg_to_rad(28.0), 1.20)
	_place_sakura_tree(root, "CathedralSakura_LowerR", Vector3(21.5, 4.0, -251.5), deg_to_rad(-28.0), 1.20)
	_place_verdant_tree(root, "CathedralVerdant_MidL", Vector3(-28.5, 4.0, -250.5), deg_to_rad(42.0), 1.28)
	_place_verdant_tree(root, "CathedralVerdant_MidR", Vector3(28.5, 4.0, -250.5), deg_to_rad(-42.0), 1.28)
	_place_sakura_tree(root, "CathedralSakura_OuterFrontL", Vector3(-36.5, 4.0, -252.5), deg_to_rad(52.0), 1.34)
	_place_sakura_tree(root, "CathedralSakura_OuterFrontR", Vector3(36.5, 4.0, -252.5), deg_to_rad(-52.0), 1.34)
	_place_verdant_tree(root, "CathedralVerdant_FlankFrontL", Vector3(-41.5, 4.0, -264.0), deg_to_rad(64.0), 1.40)
	_place_verdant_tree(root, "CathedralVerdant_FlankFrontR", Vector3(41.5, 4.0, -264.0), deg_to_rad(-64.0), 1.40)
	_place_sakura_tree(root, "CathedralSakura_FlankMidL", Vector3(-41.5, 4.0, -278.0), deg_to_rad(78.0), 1.32)
	_place_sakura_tree(root, "CathedralSakura_FlankMidR", Vector3(41.5, 4.0, -278.0), deg_to_rad(-78.0), 1.32)
	_place_verdant_tree(root, "CathedralVerdant_FlankRearL", Vector3(-41.0, 4.0, -292.0), deg_to_rad(106.0), 1.36)
	_place_verdant_tree(root, "CathedralVerdant_FlankRearR", Vector3(41.0, 4.0, -292.0), deg_to_rad(-106.0), 1.36)

	# 12 lush rose-and-emerald hedges framing the staircase cheek walls & lower terrace edges
	# (Zero obstruction of the x = -13..+13 grand staircase or x = -12..+12 portal doorway)
	_place_lush_bush(root, "CathedralHedge_StairBaseL", Vector3(-16.8, 0.0, -242.5), deg_to_rad(90.0), 1.10)
	_place_lush_bush(root, "CathedralHedge_StairBaseR", Vector3(16.8, 0.0, -242.5), deg_to_rad(-90.0), 1.10)
	_place_lush_bush(root, "CathedralHedge_StairMidL", Vector3(-16.8, 4.0, -248.8), deg_to_rad(90.0), 1.12)
	_place_lush_bush(root, "CathedralHedge_StairMidR", Vector3(16.8, 4.0, -248.8), deg_to_rad(-90.0), 1.12)
	_place_lush_bush(root, "CathedralHedge_StairTopL", Vector3(-17.4, 8.0, -256.8), deg_to_rad(90.0), 1.05)
	_place_lush_bush(root, "CathedralHedge_StairTopR", Vector3(17.4, 8.0, -256.8), deg_to_rad(-90.0), 1.05)
	# Front edges of lower terrace (y = 4.0)
	_place_lush_bush(root, "CathedralHedge_LowerFrontInL", Vector3(-22.5, 4.0, -248.4), deg_to_rad(4.0), 1.18)
	_place_lush_bush(root, "CathedralHedge_LowerFrontInR", Vector3(22.5, 4.0, -248.4), deg_to_rad(-4.0), 1.18)
	_place_lush_bush(root, "CathedralHedge_LowerFrontOutL", Vector3(-31.5, 4.0, -248.4), deg_to_rad(-6.0), 1.22)
	_place_lush_bush(root, "CathedralHedge_LowerFrontOutR", Vector3(31.5, 4.0, -248.4), deg_to_rad(6.0), 1.22)
	# Outer front corners of the panoramic side galleries (y = 8.0, well clear of (-24,8,-276) & (+24,8,-276))
	_place_lush_bush(root, "CathedralHedge_GalleryFrontL", Vector3(-34.8, 8.0, -261.6), deg_to_rad(18.0), 1.02)
	_place_lush_bush(root, "CathedralHedge_GalleryFrontR", Vector3(34.8, 8.0, -261.6), deg_to_rad(-18.0), 1.02)

	# 10 blooming marble planters (scale 1.08..1.15) lining staircase cheek walls, gallery corners & North Terrace entrance
	# Completely clear of Mentors (0,8,-267), Earth Mirror (0,8,-278), Fountain (-24,8,-276), Book (+24,8,-276), Astrolabe (0,8,-304)
	_place_garden_planter(root, "CathedralPlanter_BaseL", Vector3(-15.5, 0.0, -242.0), deg_to_rad(90.0), 1.15)
	_place_garden_planter(root, "CathedralPlanter_BaseR", Vector3(15.5, 0.0, -242.0), deg_to_rad(-90.0), 1.15)
	_place_garden_planter(root, "CathedralPlanter_MidL", Vector3(-15.5, 4.0, -248.8), deg_to_rad(90.0), 1.15)
	_place_garden_planter(root, "CathedralPlanter_MidR", Vector3(15.5, 4.0, -248.8), deg_to_rad(-90.0), 1.15)
	_place_garden_planter(root, "CathedralPlanter_TopL", Vector3(-15.6, 8.0, -255.8), deg_to_rad(90.0), 1.12)
	_place_garden_planter(root, "CathedralPlanter_TopR", Vector3(15.6, 8.0, -255.8), deg_to_rad(-90.0), 1.12)
	_place_garden_planter(root, "CathedralPlanter_GalleryRearL", Vector3(-35.2, 8.0, -295.8), deg_to_rad(135.0), 1.08)
	_place_garden_planter(root, "CathedralPlanter_GalleryRearR", Vector3(35.2, 8.0, -295.8), deg_to_rad(-135.0), 1.08)
	_place_garden_planter(root, "CathedralPlanter_NorthTerraceL", Vector3(-13.8, 8.0, -300.2), deg_to_rad(90.0), 1.08)
	_place_garden_planter(root, "CathedralPlanter_NorthTerraceR", Vector3(13.8, 8.0, -300.2), deg_to_rad(-90.0), 1.08)

	# 4 celestial silk-and-crystal ornaments framing the Rotunda diagonal bays (all 4 cardinal archways 100% open!)
	_place_celestial_ornament(root, "SanctuaryOrnament_SouthDiagL", Vector3(-14.2, 8.0, -264.8), deg_to_rad(64.0), 1.12, 0.5)
	_place_celestial_ornament(root, "SanctuaryOrnament_SouthDiagR", Vector3(14.2, 8.0, -264.8), deg_to_rad(-64.0), 1.12, 2.2)
	_place_celestial_ornament(root, "SanctuaryOrnament_NorthDiagL", Vector3(-14.2, 8.0, -294.2), deg_to_rad(118.0), 1.12, 3.6)
	_place_celestial_ornament(root, "SanctuaryOrnament_NorthDiagR", Vector3(14.2, 8.0, -294.2), deg_to_rad(-118.0), 1.12, 5.1)

	# Dense cascading emerald ivy walls along the castle lower terrace parapets
	var vine_root: Node3D = Node3D.new()
	vine_root.name = "CathedralHangingVines"
	root.add_child(vine_root)

	var forward_dir: Vector3 = Vector3(0.0, 0.0, 1.0)
	var lower_x_coords: Array[float] = [
		-42.0, -39.0, -36.0, -33.0, -30.0, -27.0, -24.0, -21.0, -18.0,
		18.0, 21.0, 24.0, 27.0, 30.0, 33.0, 36.0, 39.0, 42.0,
	]
	for i: int in range(lower_x_coords.size()):
		var x_val: float = lower_x_coords[i]
		var drop_len: float = 2.4 + fmod(float(i * 7 + 5) * 0.6180339, 1.0) * 1.95 # 2.4m .. 4.35m
		_build_vine_garland(
			vine_root,
			Vector3(x_val, 3.9, -247.8),
			forward_dir,
			drop_len,
			100 + i
		)

	# Outer lower terrace side parapet ivy curtains (x = +-43.9, z = -252..-296)
	var side_z_coords: Array[float] = [-252.0, -258.0, -264.0, -270.0, -276.0, -282.0, -288.0, -294.0]
	for side_idx: int in range(2):
		var s_sign: float = -1.0 if side_idx == 0 else 1.0
		var s_dir: Vector3 = Vector3(s_sign, 0.0, 0.0)
		for j: int in range(side_z_coords.size()):
			var drop_len: float = 2.6 + fmod(float(side_idx * 9 + j * 5 + 1) * 0.6180339, 1.0) * 1.9
			_build_vine_garland(
				vine_root,
				Vector3(s_sign * 43.9, 3.9, side_z_coords[j]),
				s_dir,
				drop_len,
				200 + side_idx * 10 + j
			)


# ---------------------------------------------------------------------------
# Prop Placement Helpers (GLB with Graceful Procedural Fallbacks)
# ---------------------------------------------------------------------------

func _place_sakura_tree(parent: Node3D, node_name: String, pos: Vector3, yaw_rad: float, scale_factor: float) -> Node3D:
	var prop: Node3D = null
	if _sakura_tree_scene != null:
		var inst: Node = _sakura_tree_scene.instantiate()
		if inst is Node3D:
			prop = inst as Node3D
		else:
			inst.queue_free()
	if prop == null:
		prop = _create_fallback_sakura_tree(false)

	prop.name = node_name
	prop.position = pos
	prop.rotation = Vector3(0.0, yaw_rad, 0.0)
	prop.scale = Vector3(scale_factor, scale_factor, scale_factor)
	parent.add_child(prop)
	return prop


## Spawns a lush emerald-green palace garden tree by overriding sakura blossom surfaces
## with rich sunlit emerald & spring green foliage plus small cream-pink flower accents.
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
	for child: Node in node.get_children():
		_apply_verdant_tree_materials(child)


func _place_lush_bush(parent: Node3D, node_name: String, pos: Vector3, yaw_rad: float, scale_factor: float) -> Node3D:
	var prop: Node3D = null
	if _lush_bush_scene != null:
		var inst: Node = _lush_bush_scene.instantiate()
		if inst is Node3D:
			prop = inst as Node3D
		else:
			inst.queue_free()
	if prop == null:
		prop = _create_fallback_lush_bush()

	prop.name = node_name
	prop.position = pos
	prop.rotation = Vector3(0.0, yaw_rad, 0.0)
	prop.scale = Vector3(scale_factor, scale_factor, scale_factor)
	parent.add_child(prop)
	return prop


func _place_garden_planter(parent: Node3D, node_name: String, pos: Vector3, yaw_rad: float, scale_factor: float) -> Node3D:
	var prop: Node3D = null
	if _garden_planter_scene != null:
		var inst: Node = _garden_planter_scene.instantiate()
		if inst is Node3D:
			prop = inst as Node3D
		else:
			inst.queue_free()
	if prop == null:
		prop = _create_fallback_garden_planter()

	prop.name = node_name
	prop.position = pos
	prop.rotation = Vector3(0.0, yaw_rad, 0.0)
	prop.scale = Vector3(scale_factor, scale_factor, scale_factor)
	parent.add_child(prop)
	return prop


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


# ---------------------------------------------------------------------------
# Procedural Cascading Emerald Ivy & Sakura-Blossom Vine Garlands
# ---------------------------------------------------------------------------

func _build_vine_garland(
	parent: Node3D,
	anchor_pos: Vector3,
	outward_dir: Vector3,
	drop_length: float,
	seed_index: int
) -> void:
	var strand: Node3D = Node3D.new()
	strand.name = "VineGarland_%03d" % seed_index
	strand.position = anchor_pos
	parent.add_child(strand)

	var tangent: Vector3 = Vector3(-outward_dir.z, 0.0, outward_dir.x)
	var seg_step: float = 0.44
	var seg_count: int = maxi(3, int(roundf(drop_length / seg_step)))
	var leaf_mats: Array[StandardMaterial3D] = [
		_mat_leaf_emerald,
		_mat_leaf_spring,
		_mat_leaf_mint,
	]
	var blossom_mats: Array[StandardMaterial3D] = [
		_mat_blossom_pink,
		_mat_blossom_blush,
		_mat_blossom_lilac,
	]

	for s: int in range(seg_count):
		var frac: float = float(s) / float(maxi(1, seg_count - 1))
		var y_off: float = -float(s) * seg_step
		var sway_wave: float = sin(frac * PI * 1.6 + float(seed_index) * 0.9) * 0.16
		var out_curve: float = 0.12 + sin(frac * PI * 0.85) * 0.18
		var local_pos: Vector3 = outward_dir * out_curve + tangent * sway_wave + Vector3(0.0, y_off, 0.0)

		# Slender emerald stem link
		var stem: MeshInstance3D = MeshInstance3D.new()
		stem.mesh = _mesh_vine_stem
		stem.material_override = _mat_leaf_emerald
		stem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		stem.position = local_pos
		stem.rotation = Vector3(0.0, float(seed_index + s) * 0.5, sway_wave * 0.6)
		strand.add_child(stem)

		# Lush tapered 3-tone emerald/spring/mint ivy foliage cluster
		var taper: float = lerpf(1.26, 0.56, frac)
		var leaf: MeshInstance3D = MeshInstance3D.new()
		leaf.mesh = _mesh_leaf_cluster
		leaf.material_override = leaf_mats[(s + seed_index) % leaf_mats.size()]
		leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		leaf.position = local_pos + outward_dir * 0.08
		leaf.rotation = Vector3(0.25 * float((s % 3) - 1), float(seed_index + s) * 0.85, 0.22 * sway_wave)
		leaf.scale = Vector3(taper, taper * 0.90, taper)
		strand.add_child(leaf)

		# Flowering sakura / rose blossom accents nestled into the cascading emerald ivy
		if s == 0 or s == seg_count - 1 or (s + seed_index) % 3 == 0:
			var blossom: MeshInstance3D = MeshInstance3D.new()
			blossom.mesh = _mesh_blossom_cluster if s < seg_count - 1 else _mesh_blossom_small
			var mat_idx: int = (seed_index + s) % blossom_mats.size()
			blossom.material_override = blossom_mats[mat_idx]
			blossom.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var side_nudge: float = 0.15 if s % 2 == 0 else -0.15
			blossom.position = local_pos + outward_dir * 0.16 + tangent * side_nudge
			var b_scale: float = lerpf(1.04, 0.58, frac)
			blossom.scale = Vector3(b_scale, b_scale * 0.92, b_scale)
			strand.add_child(blossom)


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
