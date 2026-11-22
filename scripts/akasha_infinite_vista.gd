class_name AkashaInfiniteVista
extends Node3D

## Infinite 360-degree Celestial Archipelago vista surrounding the playable Akasha Prologue valley.
## Populates 144 distant floating sky-islands across 3 elevation layers (Deep Lower Archipelago,
## Mid-Horizon Panorama Ring, Soaring High Celestial Citadels) with fairytale white-blue spire
## towers, classical archways, emerald & sakura tree crowns, cascading turquoise waterfalls, and
## orbiting rock shards. Strictly excludes the playable valley volume and runs at 60 FPS on
## macOS Retina using GPU-instanced MultiMeshInstance3D batches with zero shadow casting.

const VALLEY_CENTER: Vector3 = Vector3(0.0, 10.0, -135.0)

# Generous exclusion volume around playable valley (x in [-82,82], z in [-352,78], y in [-16,88])
const EXCLUSION_HALF_X: float = 118.0
const EXCLUSION_MIN_Z: float = -395.0
const EXCLUSION_MAX_Z: float = 115.0
const EXCLUSION_MIN_Y: float = -34.0
const EXCLUSION_MAX_Y: float = 102.0

const LOW_ISLAND_COUNT: int = 38
const MID_ISLAND_COUNT: int = 64
const HIGH_ISLAND_COUNT: int = 42

const TARGET_TOWER_COUNT: int = 58
const TARGET_ARCH_COUNT: int = 26
const TARGET_TREE_COUNT: int = 260
const TARGET_WATERFALL_COUNT: int = 36
const TARGET_SHARD_COUNT: int = 180

const SKY_HAZE_COLOR: Color = Color(0.78, 0.88, 0.98, 1.0)
const VISTA_CUSTOM_AABB: AABB = AABB(Vector3(-960.0, -280.0, -1100.0), Vector3(1920.0, 640.0, 1920.0))

var _layer_low: Node3D = null
var _layer_mid: Node3D = null
var _layer_high: Node3D = null

var _elapsed_time: float = 0.0

# 7 shared procedural meshes & materials
var _mesh_rock: ArrayMesh = null
var _mesh_meadow: ArrayMesh = null
var _mesh_tower: ArrayMesh = null
var _mesh_arch: ArrayMesh = null
var _mesh_tree: ArrayMesh = null
var _mesh_waterfall: ArrayMesh = null
var _mesh_shard: ArrayMesh = null

var _mat_rock: StandardMaterial3D = null
var _mat_meadow: StandardMaterial3D = null
var _mat_tower: StandardMaterial3D = null
var _mat_arch: StandardMaterial3D = null
var _mat_tree: StandardMaterial3D = null
var _mat_waterfall: StandardMaterial3D = null
var _mat_shard: StandardMaterial3D = null


func _ready() -> void:
	_build_shared_materials()
	_build_shared_meshes()
	_create_elevation_layers()
	_populate_archipelago()
	set_process(true)


func _process(delta: float) -> void:
	_elapsed_time += delta

	# Gentle, dreamy slow vertical bob on only 3 parent nodes (zero per-frame MultiMesh overhead)
	if _layer_low != null:
		_layer_low.position.y = sin(_elapsed_time * 0.17) * 1.15
	if _layer_mid != null:
		_layer_mid.position.y = sin(_elapsed_time * 0.21 + 2.094) * 0.85
	if _layer_high != null:
		_layer_high.position.y = sin(_elapsed_time * 0.14 + 4.188) * 1.45


# ---------------------------------------------------------------------------
# Layer Setup & Archipelago Generation
# ---------------------------------------------------------------------------

func _create_elevation_layers() -> void:
	_layer_low = Node3D.new()
	_layer_low.name = "VistaLayerLow"
	add_child(_layer_low)

	_layer_mid = Node3D.new()
	_layer_mid.name = "VistaLayerMid"
	add_child(_layer_mid)

	_layer_high = Node3D.new()
	_layer_high.name = "VistaLayerHigh"
	add_child(_layer_high)


func _populate_archipelago() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261122

	var islands: Array[Dictionary] = []

	# 1. Deep Lower Archipelago (y = -115..-38, 38 islands, distances 140m..680m)
	_generate_layer_islands(rng, islands, 0, LOW_ISLAND_COUNT, -115.0, -38.0, 140.0, 680.0)

	# 2. Mid-Horizon Panorama Ring (y = -25..+55, 64 islands, distances 145m..780m)
	_generate_layer_islands(rng, islands, 1, MID_ISLAND_COUNT, -25.0, 55.0, 145.0, 780.0)

	# 3. Soaring High Celestial Citadels (y = +70..+205, 42 islands, distances 165m..760m)
	_generate_layer_islands(rng, islands, 2, HIGH_ISLAND_COUNT, 70.0, 205.0, 165.0, 760.0)

	# Prepare 3 per-layer bucket maps for the 7 MultiMesh categories
	var buckets: Array[Dictionary] = []
	for _l: int in range(3):
		buckets.append({
			"rock_x": [],
			"rock_c": [],
			"meadow_x": [],
			"meadow_c": [],
			"tower_x": [],
			"tower_c": [],
			"arch_x": [],
			"arch_c": [],
			"tree_x": [],
			"tree_c": [],
			"waterfall_x": [],
			"waterfall_c": [],
			"shard_x": [],
			"shard_c": [],
		})

	var rock_palette: Array[Color] = [
		Color("#D2CFC8"),
		Color("#D9D5CD"),
		Color("#CBC8C0"),
		Color("#DDD9D0"),
	]
	var meadow_palette: Array[Color] = [
		Color("#4EA85A"),
		Color("#5CB866"),
		Color("#54B060"),
		Color("#64BE6C"),
		Color("#489E56"),
	]
	var emerald_tree_palette: Array[Color] = [
		Color("#3C944C"),
		Color("#46A054"),
		Color("#358644"),
		Color("#4EA85C"),
	]
	var sakura_tree_palette: Array[Color] = [
		Color("#F4A6C0"),
		Color("#F8BCD0"),
		Color("#EE96B4"),
	]

	# Populate Cliff Rocks & Meadow Caps for every island (144 each)
	var island_count: int = islands.size()
	for i: int in range(island_count):
		var isl: Dictionary = islands[i]
		var pos: Vector3 = isl["pos"]
		var radius: float = float(isl["radius"])
		var stretch_z: float = float(isl["stretch_z"])
		var depth: float = float(isl["depth"])
		var yaw: float = float(isl["yaw"])
		var layer_idx: int = int(isl["layer"])
		var dist: float = float(isl["dist"])

		var xform_basis: Basis = Basis(Vector3.UP, yaw)
		var rock_scale: Vector3 = Vector3(radius, depth * 0.62, radius * stretch_z)
		var rock_xform: Transform3D = Transform3D(xform_basis.scaled(rock_scale), pos)

		var meadow_scale: Vector3 = Vector3(radius, radius * 0.42, radius * stretch_z)
		var meadow_xform: Transform3D = Transform3D(xform_basis.scaled(meadow_scale), pos + Vector3(0.0, 0.15, 0.0))

		var bkt: Dictionary = buckets[layer_idx]
		var base_rock_col: Color = rock_palette[rng.randi() % rock_palette.size()]
		var base_meadow_col: Color = meadow_palette[rng.randi() % meadow_palette.size()]

		var rock_x_arr: Array = bkt["rock_x"]
		var rock_c_arr: Array = bkt["rock_c"]
		rock_x_arr.append(rock_xform)
		rock_c_arr.append(_apply_aerial_haze(base_rock_col, dist))

		var meadow_x_arr: Array = bkt["meadow_x"]
		var meadow_c_arr: Array = bkt["meadow_c"]
		meadow_x_arr.append(meadow_xform)
		meadow_c_arr.append(_apply_aerial_haze(base_meadow_col, dist))

	# Select 58 largest / most prominent islands for Fairytale White-Blue Spire Towers
	var tower_candidates: Array[int] = []
	for i: int in range(island_count):
		tower_candidates.append(i)
	tower_candidates.sort_custom(func(a_idx: int, b_idx: int) -> bool:
		var isl_a: Dictionary = islands[a_idx]
		var isl_b: Dictionary = islands[b_idx]
		var score_a: float = float(isl_a["radius"]) + (8.0 if int(isl_a["layer"]) >= 1 else 0.0)
		var score_b: float = float(isl_b["radius"]) + (8.0 if int(isl_b["layer"]) >= 1 else 0.0)
		return score_a > score_b
	)

	var towers_placed: int = 0
	for idx: int in tower_candidates:
		if towers_placed >= TARGET_TOWER_COUNT:
			break
		var isl: Dictionary = islands[idx]
		var pos: Vector3 = isl["pos"]
		var radius: float = float(isl["radius"])
		var layer_idx: int = int(isl["layer"])
		var dist: float = float(isl["dist"])

		var tower_scale: float = clampf(radius * rng.randf_range(0.24, 0.34), 3.4, 15.5)
		var dome_top_y: float = pos.y + radius * 0.42 * 0.22
		var tower_pos: Vector3 = Vector3(
			pos.x + rng.randf_range(-radius * 0.14, radius * 0.14),
			dome_top_y,
			pos.z + rng.randf_range(-radius * 0.14, radius * 0.14)
		)
		if not _is_clear_of_playable_zone(tower_pos, tower_scale * 1.4, tower_scale * 5.4, 1.0):
			continue

		var to_valley: Vector3 = VALLEY_CENTER - tower_pos
		var face_yaw: float = atan2(to_valley.x, to_valley.z) + rng.randf_range(-0.45, 0.45)
		var t_basis: Basis = Basis(Vector3.UP, face_yaw).scaled(Vector3(tower_scale, tower_scale, tower_scale))
		var bkt: Dictionary = buckets[layer_idx]
		var tower_x_arr: Array = bkt["tower_x"]
		var tower_c_arr: Array = bkt["tower_c"]
		tower_x_arr.append(Transform3D(t_basis, tower_pos))
		tower_c_arr.append(_apply_aerial_haze(Color(1.0, 1.0, 1.0, 1.0), dist))
		isl["has_tower"] = true
		towers_placed += 1

	# Select 26 Mid & High islands for Classical Archways & Sky-Bridges
	var arch_candidates: Array[int] = []
	for i: int in range(island_count):
		var layer_idx: int = int(islands[i]["layer"])
		if layer_idx >= 1:
			arch_candidates.append(i)
	# Shuffle deterministically using rng
	for i: int in range(arch_candidates.size() - 1, 0, -1):
		var swap_idx: int = rng.randi() % (i + 1)
		var tmp: int = arch_candidates[i]
		arch_candidates[i] = arch_candidates[swap_idx]
		arch_candidates[swap_idx] = tmp

	var arches_placed: int = 0
	for idx: int in arch_candidates:
		if arches_placed >= TARGET_ARCH_COUNT:
			break
		var isl: Dictionary = islands[idx]
		var pos: Vector3 = isl["pos"]
		var radius: float = float(isl["radius"])
		var layer_idx: int = int(isl["layer"])
		var dist: float = float(isl["dist"])
		var has_tower: bool = bool(isl["has_tower"])

		var arch_scale: float = clampf(radius * rng.randf_range(0.22, 0.30), 3.0, 11.5)
		var to_valley: Vector3 = VALLEY_CENTER - pos
		var flat_dir: Vector3 = Vector3(to_valley.x, 0.0, to_valley.z).normalized()
		var offset_mag: float = radius * (0.42 if has_tower else 0.18)
		var arch_pos: Vector3 = Vector3(
			pos.x + flat_dir.x * offset_mag,
			pos.y + radius * 0.42 * (0.14 if has_tower else 0.21),
			pos.z + flat_dir.z * offset_mag
		)
		if not _is_clear_of_playable_zone(arch_pos, arch_scale * 2.0, arch_scale * 4.2, 1.0):
			continue

		var arch_yaw: float = atan2(flat_dir.x, flat_dir.z) + rng.randf_range(-0.35, 0.35)
		var a_basis: Basis = Basis(Vector3.UP, arch_yaw).scaled(Vector3(arch_scale, arch_scale, arch_scale))
		var bkt: Dictionary = buckets[layer_idx]
		var arch_x_arr: Array = bkt["arch_x"]
		var arch_c_arr: Array = bkt["arch_c"]
		arch_x_arr.append(Transform3D(a_basis, arch_pos))
		arch_c_arr.append(_apply_aerial_haze(Color(1.0, 1.0, 1.0, 1.0), dist))
		isl["has_arch"] = true
		arches_placed += 1

	# Distribute 260 Lush Tree Crowns (emerald + sakura-blush) across all 144 islands
	var trees_placed: int = 0
	var tree_pass: int = 0
	while trees_placed < TARGET_TREE_COUNT and tree_pass < 6:
		for i: int in range(island_count):
			if trees_placed >= TARGET_TREE_COUNT:
				break
			var isl: Dictionary = islands[i]
			var radius: float = float(isl["radius"])
			if tree_pass >= 2 and radius < 20.0:
				continue
			if tree_pass >= 4 and radius < 30.0:
				continue

			var pos: Vector3 = isl["pos"]
			var stretch_z: float = float(isl["stretch_z"])
			var yaw: float = float(isl["yaw"])
			var layer_idx: int = int(isl["layer"])
			var dist: float = float(isl["dist"])
			var has_tower: bool = bool(isl["has_tower"])

			var ang: float = rng.randf_range(0.0, TAU)
			var min_r: float = 0.34 if has_tower else 0.08
			var rad_frac: float = rng.randf_range(min_r, 0.78)
			var local_pt: Vector3 = Vector3(cos(ang) * radius * rad_frac, 0.0, sin(ang) * radius * stretch_z * rad_frac)
			var rot_pt: Vector3 = Basis(Vector3.UP, yaw) * local_pt
			var dome_y: float = radius * 0.42 * lerpf(0.24, 0.08, rad_frac)
			var tree_pos: Vector3 = pos + Vector3(rot_pt.x, dome_y, rot_pt.z)

			var tree_scale: float = clampf(radius * rng.randf_range(0.14, 0.24), 2.2, 9.2)
			var tree_h_scale: float = tree_scale * rng.randf_range(0.92, 1.24)
			var t_basis: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(tree_scale, tree_h_scale, tree_scale))

			var is_sakura: bool = rng.randf() < 0.28
			var tree_col: Color = (
				sakura_tree_palette[rng.randi() % sakura_tree_palette.size()]
				if is_sakura
				else emerald_tree_palette[rng.randi() % emerald_tree_palette.size()]
			)

			var bkt: Dictionary = buckets[layer_idx]
			var tree_x_arr: Array = bkt["tree_x"]
			var tree_c_arr: Array = bkt["tree_c"]
			tree_x_arr.append(Transform3D(t_basis, tree_pos))
			tree_c_arr.append(_apply_aerial_haze(tree_col, dist))
			trees_placed += 1
		tree_pass += 1

	# Distribute 36 Cascading Turquoise Waterfalls off High & Mid islands facing the valley
	var wf_candidates: Array[int] = []
	for i: int in range(island_count):
		var layer_idx: int = int(islands[i]["layer"])
		if layer_idx >= 1:
			wf_candidates.append(i)
	for i: int in range(wf_candidates.size() - 1, 0, -1):
		var swap_idx: int = rng.randi() % (i + 1)
		var tmp: int = wf_candidates[i]
		wf_candidates[i] = wf_candidates[swap_idx]
		wf_candidates[swap_idx] = tmp

	var wf_placed: int = 0
	for idx: int in wf_candidates:
		if wf_placed >= TARGET_WATERFALL_COUNT:
			break
		var isl: Dictionary = islands[idx]
		var pos: Vector3 = isl["pos"]
		var radius: float = float(isl["radius"])
		var stretch_z: float = float(isl["stretch_z"])
		var layer_idx: int = int(isl["layer"])
		var dist: float = float(isl["dist"])

		var to_valley: Vector3 = VALLEY_CENTER - pos
		var flat_dir: Vector3 = Vector3(to_valley.x, 0.0, to_valley.z)
		if flat_dir.length_squared() < 0.001:
			flat_dir = Vector3.FORWARD
		else:
			flat_dir = flat_dir.normalized()

		var rim_r: float = radius * minf(1.0, stretch_z) * 0.94
		var wf_pos: Vector3 = Vector3(
			pos.x + flat_dir.x * rim_r,
			pos.y + 0.15,
			pos.z + flat_dir.z * rim_r
		)
		var wf_width: float = clampf(radius * rng.randf_range(0.18, 0.30), 2.8, 12.0)
		var wf_height: float = rng.randf_range(44.0, 96.0) if layer_idx == 2 else rng.randf_range(34.0, 72.0)
		if not _is_clear_of_playable_zone(wf_pos, wf_width, 2.0, wf_height):
			continue

		var wf_yaw: float = atan2(flat_dir.x, flat_dir.z)
		var wf_basis: Basis = Basis(Vector3.UP, wf_yaw).scaled(Vector3(wf_width, wf_height, wf_width * 0.65))
		var bkt: Dictionary = buckets[layer_idx]
		var wf_x_arr: Array = bkt["waterfall_x"]
		var wf_c_arr: Array = bkt["waterfall_c"]
		wf_x_arr.append(Transform3D(wf_basis, wf_pos))
		var wf_tint: Color = Color(
			rng.randf_range(0.90, 1.0),
			rng.randf_range(0.96, 1.0),
			1.0,
			1.0
		)
		wf_c_arr.append(_apply_aerial_haze(wf_tint, dist * 0.65))
		wf_placed += 1

	# Distribute 180 Floating Satellite Rock Shards orbiting beneath and beside distant islands
	var shards_placed: int = 0
	var shard_attempt: int = 0
	while shards_placed < TARGET_SHARD_COUNT and shard_attempt < TARGET_SHARD_COUNT * 4:
		shard_attempt += 1
		var isl: Dictionary = islands[shards_placed % island_count]
		var pos: Vector3 = isl["pos"]
		var radius: float = float(isl["radius"])
		var depth: float = float(isl["depth"])
		var layer_idx: int = int(isl["layer"])
		var dist: float = float(isl["dist"])

		var orbit_ang: float = rng.randf_range(0.0, TAU)
		var orbit_dist: float = radius * rng.randf_range(1.18, 2.15) + rng.randf_range(4.0, 18.0)
		var y_offset: float = rng.randf_range(-depth * 0.85, radius * 0.45)
		var shard_pos: Vector3 = pos + Vector3(cos(orbit_ang) * orbit_dist, y_offset, sin(orbit_ang) * orbit_dist)

		var shard_scale_xz: float = clampf(radius * rng.randf_range(0.11, 0.24), 1.8, 9.5)
		var shard_scale_y: float = shard_scale_xz * rng.randf_range(1.15, 2.10)
		if not _is_clear_of_playable_zone(shard_pos, shard_scale_xz * 1.4, shard_scale_y, shard_scale_y * 1.2):
			continue

		var s_basis: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		s_basis = s_basis.rotated(Vector3.RIGHT, rng.randf_range(-0.22, 0.22))
		s_basis = s_basis.rotated(Vector3.FORWARD, rng.randf_range(-0.22, 0.22))
		s_basis = s_basis.scaled(Vector3(shard_scale_xz, shard_scale_y, shard_scale_xz * rng.randf_range(0.75, 1.25)))

		var bkt: Dictionary = buckets[layer_idx]
		var base_shard_col: Color = rock_palette[rng.randi() % rock_palette.size()]
		var shard_x_arr: Array = bkt["shard_x"]
		var shard_c_arr: Array = bkt["shard_c"]
		shard_x_arr.append(Transform3D(s_basis, shard_pos))
		shard_c_arr.append(_apply_aerial_haze(base_shard_col, dist))
		shards_placed += 1

	# Commit each elevation layer's MultiMeshInstance3D batches
	var layer_nodes: Array[Node3D] = [_layer_low, _layer_mid, _layer_high]
	for layer_idx: int in range(3):
		var parent_node: Node3D = layer_nodes[layer_idx]
		var bkt: Dictionary = buckets[layer_idx]
		_create_multimesh_batch(parent_node, "CliffRocks", _mesh_rock, _mat_rock, bkt["rock_x"], bkt["rock_c"])
		_create_multimesh_batch(parent_node, "MeadowCaps", _mesh_meadow, _mat_meadow, bkt["meadow_x"], bkt["meadow_c"])
		_create_multimesh_batch(parent_node, "SpireTowers", _mesh_tower, _mat_tower, bkt["tower_x"], bkt["tower_c"])
		_create_multimesh_batch(parent_node, "ClassicalArches", _mesh_arch, _mat_arch, bkt["arch_x"], bkt["arch_c"])
		_create_multimesh_batch(parent_node, "TreeCrowns", _mesh_tree, _mat_tree, bkt["tree_x"], bkt["tree_c"])
		_create_multimesh_batch(parent_node, "Waterfalls", _mesh_waterfall, _mat_waterfall, bkt["waterfall_x"], bkt["waterfall_c"])
		_create_multimesh_batch(parent_node, "RockShards", _mesh_shard, _mat_shard, bkt["shard_x"], bkt["shard_c"])


func _generate_layer_islands(
	rng: RandomNumberGenerator,
	islands: Array[Dictionary],
	layer_idx: int,
	count: int,
	min_y: float,
	max_y: float,
	min_dist: float,
	max_dist: float
) -> void:
	for idx: int in range(count):
		# Stratified 360-degree azimuth so North, South, East, and West are all richly populated
		var sector_base: float = (float(idx) / float(count)) * TAU
		var sector_span: float = TAU / float(count)

		var placed: bool = false
		for attempt: int in range(40):
			var angle: float = sector_base + rng.randf_range(0.08, 0.92) * sector_span
			if attempt >= 16:
				angle = rng.randf_range(0.0, TAU)

			# Stratified radial band (mix of near-horizon, mid-distance, and far-horizon islands)
			var band_t: float = clampf((float(idx % 5) + rng.randf_range(0.05, 0.95)) * 0.2, 0.0, 1.0)
			if attempt >= 10:
				band_t = rng.randf()
			var dist: float = lerpf(min_dist, max_dist, pow(band_t, 0.92))

			# Slight Z-elongation matching the north-south valley silhouette
			var x_pos: float = VALLEY_CENTER.x + cos(angle) * dist
			var z_pos: float = VALLEY_CENTER.z + sin(angle) * dist * 1.12
			var y_pos: float = rng.randf_range(min_y, max_y)

			# Scale island size gracefully with distance so far-horizon islands remain majestic
			var dist_norm: float = clampf((dist - min_dist) / maxf(max_dist - min_dist, 1.0), 0.0, 1.0)
			var radius: float = lerpf(12.0, 44.0, dist_norm) * rng.randf_range(0.78, 1.28)
			if layer_idx == 2:
				radius *= rng.randf_range(0.85, 1.15)
			var stretch_z: float = rng.randf_range(0.82, 1.18)
			var depth: float = radius * rng.randf_range(1.25, 1.85)
			var pos: Vector3 = Vector3(x_pos, y_pos, z_pos)

			var max_horiz_r: float = radius * maxf(1.0, stretch_z)
			var est_top_h: float = radius * 0.55 + 14.0
			var est_bot_d: float = depth * 1.15

			if not _is_clear_of_playable_zone(pos, max_horiz_r, est_top_h, est_bot_d):
				continue

			# Keep comfortable spacing from already-placed vista islands
			var too_close: bool = false
			for existing: Dictionary in islands:
				var e_pos: Vector3 = existing["pos"]
				var e_rad: float = float(existing["radius"])
				var min_gap: float = (max_horiz_r + e_rad) * 1.18 + 14.0
				var dy: float = absf(pos.y - e_pos.y)
				if dy < (radius + e_rad) * 1.25:
					var dx: float = pos.x - e_pos.x
					var dz: float = pos.z - e_pos.z
					if (dx * dx + dz * dz) < (min_gap * min_gap):
						too_close = true
						break
			if too_close:
				continue

			islands.append({
				"pos": pos,
				"radius": radius,
				"stretch_z": stretch_z,
				"depth": depth,
				"yaw": rng.randf_range(0.0, TAU),
				"layer": layer_idx,
				"dist": pos.distance_to(VALLEY_CENTER),
				"has_tower": false,
				"has_arch": false,
			})
			placed = true
			break

		# Deterministic outer-rim fallback if crowded so we always hit the exact island count
		if not placed:
			var fb_angle: float = sector_base + sector_span * 0.5
			var fb_dist: float = lerpf(max_dist * 0.65, max_dist, rng.randf())
			var fb_pos: Vector3 = Vector3(
				VALLEY_CENTER.x + cos(fb_angle) * fb_dist,
				rng.randf_range(min_y, max_y),
				VALLEY_CENTER.z + sin(fb_angle) * fb_dist * 1.15
			)
			var fb_radius: float = rng.randf_range(22.0, 38.0)
			islands.append({
				"pos": fb_pos,
				"radius": fb_radius,
				"stretch_z": rng.randf_range(0.85, 1.15),
				"depth": fb_radius * 1.45,
				"yaw": rng.randf_range(0.0, TAU),
				"layer": layer_idx,
				"dist": fb_pos.distance_to(VALLEY_CENTER),
				"has_tower": false,
				"has_arch": false,
			})


func _is_clear_of_playable_zone(
	pos: Vector3,
	horiz_radius: float,
	top_height: float,
	bottom_depth: float
) -> bool:
	var pad: float = horiz_radius + 12.0
	var inside_x: bool = absf(pos.x) < (EXCLUSION_HALF_X + pad)
	var inside_z: bool = pos.z > (EXCLUSION_MIN_Z - pad) and pos.z < (EXCLUSION_MAX_Z + pad)
	var inside_y: bool = (pos.y + top_height) > EXCLUSION_MIN_Y and (pos.y - bottom_depth) < EXCLUSION_MAX_Y
	return not (inside_x and inside_z and inside_y)


func _apply_aerial_haze(base_col: Color, dist: float) -> Color:
	var haze_t: float = clampf((dist - 240.0) / 640.0, 0.0, 0.42)
	return base_col.lerp(SKY_HAZE_COLOR, haze_t)


func _create_multimesh_batch(
	parent_node: Node3D,
	batch_name: String,
	mesh: ArrayMesh,
	mat: StandardMaterial3D,
	xforms: Array,
	colors: Array
) -> void:
	var count: int = xforms.size()
	if count <= 0:
		return

	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count

	for i: int in range(count):
		var xf: Transform3D = xforms[i]
		var col: Color = colors[i]
		mm.set_instance_transform(i, xf)
		mm.set_instance_color(i, col)

	var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi.name = batch_name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = VISTA_CUSTOM_AABB
	parent_node.add_child(mmi)


# ---------------------------------------------------------------------------
# Shared Materials (7 lightweight PBR materials)
# ---------------------------------------------------------------------------

func _build_shared_materials() -> void:
	_mat_rock = StandardMaterial3D.new()
	_mat_rock.vertex_color_use_as_albedo = true
	_mat_rock.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	_mat_rock.roughness = 0.88
	_mat_rock.metallic = 0.0

	_mat_meadow = StandardMaterial3D.new()
	_mat_meadow.vertex_color_use_as_albedo = true
	_mat_meadow.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	_mat_meadow.roughness = 0.86
	_mat_meadow.metallic = 0.0

	_mat_tower = StandardMaterial3D.new()
	_mat_tower.vertex_color_use_as_albedo = true
	_mat_tower.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	_mat_tower.roughness = 0.62
	_mat_tower.metallic = 0.08

	_mat_arch = StandardMaterial3D.new()
	_mat_arch.vertex_color_use_as_albedo = true
	_mat_arch.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	_mat_arch.roughness = 0.58
	_mat_arch.metallic = 0.05

	_mat_tree = StandardMaterial3D.new()
	_mat_tree.vertex_color_use_as_albedo = true
	_mat_tree.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	_mat_tree.roughness = 0.82
	_mat_tree.metallic = 0.0

	_mat_waterfall = StandardMaterial3D.new()
	_mat_waterfall.vertex_color_use_as_albedo = true
	_mat_waterfall.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_waterfall.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_waterfall.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_mat_waterfall.albedo_color = Color(0.68, 0.96, 1.0, 0.86)
	_mat_waterfall.roughness = 0.22
	_mat_waterfall.emission_enabled = true
	_mat_waterfall.emission = Color("#7CE8F4")
	_mat_waterfall.emission_energy_multiplier = 0.55

	_mat_shard = StandardMaterial3D.new()
	_mat_shard.vertex_color_use_as_albedo = true
	_mat_shard.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	_mat_shard.roughness = 0.88
	_mat_shard.metallic = 0.0


# ---------------------------------------------------------------------------
# Shared Procedural ArrayMeshes (7 sculptural archetypes)
# ---------------------------------------------------------------------------

func _build_shared_meshes() -> void:
	_mesh_rock = _build_island_rock_mesh()
	_mesh_meadow = _build_meadow_cap_mesh()
	_mesh_tower = _build_spire_tower_mesh()
	_mesh_arch = _build_archway_mesh()
	_mesh_tree = _build_tree_crown_mesh()
	_mesh_waterfall = _build_waterfall_mesh()
	_mesh_shard = _build_rock_shard_mesh()


func _rock_rim_factor(angle: float, ring_idx: int) -> float:
	var rf: float = float(ring_idx)
	var wave1: float = sin(angle * 3.0 + rf * 0.65) * 0.13
	var wave2: float = cos(angle * 5.0 - rf * 0.95) * 0.07
	var wave3: float = sin(angle * 2.0 + 0.8) * 0.06
	return 1.0 + wave1 + wave2 + wave3


func _build_island_rock_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var segs: int = 10
	var ring_y: Array[float] = [0.0, -0.14, -0.42, -0.78, -1.18, -1.56]
	var ring_r: Array[float] = [0.98, 1.08, 0.88, 0.58, 0.30, 0.11]
	var ring_col: Array[Color] = [
		Color("#EBE7DF"),
		Color("#DDD9D0"),
		Color("#CFCBC2"),
		Color("#C0BEC0"),
		Color("#B2B5BF"),
		Color("#A6ACBA"),
	]

	var rings: Array[Array] = []
	for r_idx: int in range(ring_y.size()):
		var pts: Array[Vector3] = []
		var y_val: float = ring_y[r_idx]
		var base_r: float = ring_r[r_idx]
		for s: int in range(segs):
			var ang: float = (float(s) / float(segs)) * TAU
			var mod_r: float = base_r * _rock_rim_factor(ang, r_idx)
			var y_jit: float = sin(ang * 3.0 + float(r_idx) * 1.1) * 0.035 if r_idx > 0 else 0.0
			pts.append(Vector3(cos(ang) * mod_r, y_val + y_jit, sin(ang) * mod_r))
		rings.append(pts)

	# Side cliff facets between rings
	for r_idx: int in range(rings.size() - 1):
		var upper: Array = rings[r_idx]
		var lower: Array = rings[r_idx + 1]
		var col: Color = ring_col[r_idx]
		for s: int in range(segs):
			var next_s: int = (s + 1) % segs
			var u0: Vector3 = upper[s] as Vector3
			var u1: Vector3 = upper[next_s] as Vector3
			var l0: Vector3 = lower[s] as Vector3
			var l1: Vector3 = lower[next_s] as Vector3
			var center_out: Vector3 = ((u0 + u1 + l0 + l1) * 0.25)
			var out_hint: Vector3 = Vector3(center_out.x, -0.25, center_out.z)
			_add_quad(st, u0, u1, l1, l0, out_hint, col)

	# Bottom tapered crag tip
	var apex: Vector3 = Vector3(0.04, -1.80, -0.03)
	var bot_ring: Array = rings[rings.size() - 1]
	var bot_col: Color = ring_col[ring_col.size() - 1]
	for s: int in range(segs):
		var next_s: int = (s + 1) % segs
		var b0: Vector3 = bot_ring[s] as Vector3
		var b1: Vector3 = bot_ring[next_s] as Vector3
		var out_hint: Vector3 = Vector3((b0.x + b1.x) * 0.5, -0.65, (b0.z + b1.z) * 0.5)
		_add_tri(st, b0, b1, apex, out_hint, bot_col)

	# Top cap under grass
	var top_center: Vector3 = Vector3(0.0, 0.02, 0.0)
	var top_ring: Array = rings[0]
	for s: int in range(segs):
		var next_s: int = (s + 1) % segs
		var t0: Vector3 = top_ring[s] as Vector3
		var t1: Vector3 = top_ring[next_s] as Vector3
		_add_tri(st, top_center, t0, t1, Vector3.UP, ring_col[0])

	return st.commit()


func _build_meadow_cap_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var segs: int = 10
	var ring_y: Array[float] = [-0.06, 0.08, 0.20]
	var ring_r: Array[float] = [1.05, 0.88, 0.46]
	var ring_col: Array[Color] = [
		Color("#D6E6D6"),
		Color("#ECF6EC"),
		Color("#FFFFFF"),
	]

	var rings: Array[Array] = []
	for r_idx: int in range(ring_y.size()):
		var pts: Array[Vector3] = []
		var y_val: float = ring_y[r_idx]
		var base_r: float = ring_r[r_idx]
		for s: int in range(segs):
			var ang: float = (float(s) / float(segs)) * TAU
			var rim_blend: float = lerpf(1.0, _rock_rim_factor(ang, 0), 1.0 - float(r_idx) * 0.35)
			var mod_r: float = base_r * rim_blend
			pts.append(Vector3(cos(ang) * mod_r, y_val, sin(ang) * mod_r))
		rings.append(pts)

	# Skirt & shoulder bands
	for r_idx: int in range(rings.size() - 1):
		var outer: Array = rings[r_idx]
		var inner: Array = rings[r_idx + 1]
		var col: Color = ring_col[r_idx]
		for s: int in range(segs):
			var next_s: int = (s + 1) % segs
			var o0: Vector3 = outer[s] as Vector3
			var o1: Vector3 = outer[next_s] as Vector3
			var i0: Vector3 = inner[s] as Vector3
			var i1: Vector3 = inner[next_s] as Vector3
			var mid: Vector3 = (o0 + o1 + i0 + i1) * 0.25
			var out_hint: Vector3 = Vector3(mid.x * 0.4, 1.0, mid.z * 0.4)
			_add_quad(st, o0, i0, i1, o1, out_hint, col)

	# Central lush dome peak
	var peak: Vector3 = Vector3(0.0, 0.27, 0.0)
	var inner_ring: Array = rings[rings.size() - 1]
	for s: int in range(segs):
		var next_s: int = (s + 1) % segs
		var p0: Vector3 = inner_ring[s] as Vector3
		var p1: Vector3 = inner_ring[next_s] as Vector3
		_add_tri(st, peak, p0, p1, Vector3.UP, Color("#FFFFFF"))

	return st.commit()


func _build_spire_tower_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var col_limestone: Color = Color("#F2EFE8")
	var col_plinth: Color = Color("#E5E0D6")
	var col_roof_base: Color = Color("#447DC4")
	var col_roof_tip: Color = Color("#5A94DC")
	var col_gold: Color = Color("#F2C95A")

	# Central fairytale keep plinth, shaft, cantilevered gallery, royal blue spire, gold finial
	_add_frustum(st, -0.18, 0.86, 0.55, 0.72, 8, Vector3.ZERO, col_plinth, false, true)
	_add_frustum(st, 0.55, 0.62, 2.42, 0.54, 8, Vector3.ZERO, col_limestone, false, false)
	_add_frustum(st, 2.40, 0.56, 2.66, 0.80, 8, Vector3.ZERO, col_limestone, false, true)
	_add_frustum(st, 2.64, 0.82, 2.74, 0.82, 8, Vector3.ZERO, col_gold, false, false)
	_add_frustum(st, 2.72, 0.80, 3.85, 0.34, 8, Vector3.ZERO, col_roof_base, false, false)
	_add_frustum(st, 3.85, 0.34, 4.78, 0.04, 8, Vector3.ZERO, col_roof_tip, false, true)
	_add_frustum(st, 4.74, 0.08, 5.42, 0.01, 6, Vector3.ZERO, col_gold, false, true)

	# Twin flanking fairy-tale side turrets
	var side_offsets: Array[Vector3] = [Vector3(-0.78, 0.0, 0.08), Vector3(0.78, 0.0, -0.06)]
	for offset: Vector3 in side_offsets:
		_add_frustum(st, -0.15, 0.36, 1.62, 0.30, 6, offset, col_limestone, false, true)
		_add_frustum(st, 1.60, 0.38, 1.68, 0.38, 6, offset, col_gold, false, false)
		_add_frustum(st, 1.66, 0.37, 2.65, 0.03, 6, offset, col_roof_base, false, true)
		_add_frustum(st, 2.62, 0.05, 2.98, 0.01, 5, offset, col_gold, false, true)

	return st.commit()


func _build_archway_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var col_marble: Color = Color("#F3F0E8")
	var col_base: Color = Color("#E4E0D6")
	var col_gold: Color = Color("#ECC45A")

	# Left & Right pedestals, pillars, and gold capitals
	var pillar_xs: Array[float] = [-1.25, 1.25]
	for px: float in pillar_xs:
		_add_box(st, Vector3(px, 0.08, 0.0), Vector3(0.78, 0.56, 0.78), col_base)
		_add_box(st, Vector3(px, 1.40, 0.0), Vector3(0.54, 2.12, 0.54), col_marble)
		_add_box(st, Vector3(px, 2.54, 0.0), Vector3(0.68, 0.18, 0.68), col_gold)

	# 7-segment semicircular arch span
	var arch_segs: int = 7
	var inner_r: float = 0.96
	var outer_r: float = 1.48
	var half_z: float = 0.28
	var center_y: float = 2.55

	for s: int in range(arch_segs):
		var a0: float = PI * (float(s) / float(arch_segs))
		var a1: float = PI * (float(s + 1) / float(arch_segs))
		var c0: float = cos(a0)
		var s0: float = sin(a0)
		var c1: float = cos(a1)
		var s1: float = sin(a1)

		var seg_col: Color = col_gold if s == 3 else col_marble

		var fi0: Vector3 = Vector3(c0 * inner_r, center_y + s0 * inner_r, half_z)
		var fo0: Vector3 = Vector3(c0 * outer_r, center_y + s0 * outer_r, half_z)
		var fi1: Vector3 = Vector3(c1 * inner_r, center_y + s1 * inner_r, half_z)
		var fo1: Vector3 = Vector3(c1 * outer_r, center_y + s1 * outer_r, half_z)

		var bi0: Vector3 = Vector3(c0 * inner_r, center_y + s0 * inner_r, -half_z)
		var bo0: Vector3 = Vector3(c0 * outer_r, center_y + s0 * outer_r, -half_z)
		var bi1: Vector3 = Vector3(c1 * inner_r, center_y + s1 * inner_r, -half_z)
		var bo1: Vector3 = Vector3(c1 * outer_r, center_y + s1 * outer_r, -half_z)

		# Front & back faces
		_add_quad(st, fi0, fo0, fo1, fi1, Vector3(0.0, 0.0, 1.0), seg_col)
		_add_quad(st, bi0, bi1, bo1, bo0, Vector3(0.0, 0.0, -1.0), seg_col)
		# Outer & inner soffit faces
		var mid_rad: Vector3 = Vector3((c0 + c1) * 0.5, (s0 + s1) * 0.5, 0.0)
		_add_quad(st, fo0, bo0, bo1, fo1, mid_rad, seg_col)
		_add_quad(st, fi0, fi1, bi1, bi0, -mid_rad, seg_col)

	# Classical stepped entablature cornice crowning the arch
	_add_box(st, Vector3(0.0, 3.92, 0.0), Vector3(3.30, 0.24, 0.72), col_marble)
	_add_box(st, Vector3(0.0, 4.10, 0.0), Vector3(3.52, 0.14, 0.84), col_gold)

	return st.commit()


func _build_tree_crown_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Slender trunk (neutral shaded base)
	_add_frustum(st, -0.15, 0.14, 0.88, 0.09, 5, Vector3.ZERO, Color("#9C948A"), false, false)

	# 3 overlapping stylized organic foliage puffs (vertex-shaded top-to-bottom)
	_add_foliage_lobe(st, Vector3(0.0, 1.56, 0.0), Vector3(0.92, 0.78, 0.92))
	_add_foliage_lobe(st, Vector3(0.46, 1.32, 0.28), Vector3(0.66, 0.56, 0.66))
	_add_foliage_lobe(st, Vector3(-0.44, 1.36, -0.26), Vector3(0.62, 0.54, 0.62))

	return st.commit()


func _build_waterfall_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var v_steps: int = 10
	for s: int in range(v_steps):
		var t0: float = float(s) / float(v_steps)
		var t1: float = float(s + 1) / float(v_steps)

		var y0: float = -t0
		var y1: float = -t1

		# Smooth curved lip at the top crest, then gentle curtain ripple down into the clouds
		var z0: float = 0.16 * (1.0 - exp(-t0 * 14.0)) + sin(t0 * PI * 3.0) * 0.02
		var z1: float = 0.16 * (1.0 - exp(-t1 * 14.0)) + sin(t1 * PI * 3.0) * 0.02

		var hw0: float = lerpf(0.28, 0.44, t0) + sin(t0 * PI * 4.0) * 0.025
		var hw1: float = lerpf(0.28, 0.44, t1) + sin(t1 * PI * 4.0) * 0.025

		var a0: float = clampf(1.0 - pow(t0, 1.75), 0.0, 1.0)
		var a1: float = clampf(1.0 - pow(t1, 1.75), 0.0, 1.0)
		var c0: Color = Color(lerpf(0.96, 0.72, t0), 1.0, 1.0, a0)
		var c1: Color = Color(lerpf(0.96, 0.72, t1), 1.0, 1.0, a1)

		var p_l0: Vector3 = Vector3(-hw0, y0, z0)
		var p_r0: Vector3 = Vector3(hw0, y0, z0)
		var p_l1: Vector3 = Vector3(-hw1, y1, z1)
		var p_r1: Vector3 = Vector3(hw1, y1, z1)

		var nrm: Vector3 = Vector3(0.0, 0.12, 1.0).normalized()
		# Triangle 1
		st.set_normal(nrm)
		st.set_color(c0)
		st.add_vertex(p_l0)
		st.set_normal(nrm)
		st.set_color(c0)
		st.add_vertex(p_r0)
		st.set_normal(nrm)
		st.set_color(c1)
		st.add_vertex(p_r1)

		# Triangle 2
		st.set_normal(nrm)
		st.set_color(c0)
		st.add_vertex(p_l0)
		st.set_normal(nrm)
		st.set_color(c1)
		st.add_vertex(p_r1)
		st.set_normal(nrm)
		st.set_color(c1)
		st.add_vertex(p_l1)

	return st.commit()


func _build_rock_shard_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var segs: int = 6
	var top_pt: Vector3 = Vector3(0.05, 0.56, -0.04)
	var bot_pt: Vector3 = Vector3(-0.04, -1.18, 0.05)

	var belt: Array[Vector3] = []
	for s: int in range(segs):
		var ang: float = (float(s) / float(segs)) * TAU
		var rad: float = 0.72 + sin(ang * 2.0 + 0.5) * 0.16
		var y_val: float = 0.08 + cos(ang * 3.0) * 0.10
		belt.append(Vector3(cos(ang) * rad, y_val, sin(ang) * rad))

	for s: int in range(segs):
		var next_s: int = (s + 1) % segs
		var b0: Vector3 = belt[s]
		var b1: Vector3 = belt[next_s]
		var mid_xz: Vector3 = Vector3((b0.x + b1.x) * 0.5, 0.0, (b0.z + b1.z) * 0.5)
		_add_tri(st, top_pt, b0, b1, mid_xz + Vector3(0.0, 0.55, 0.0), Color("#E8E4DC"))
		_add_tri(st, b0, b1, bot_pt, mid_xz + Vector3(0.0, -0.45, 0.0), Color("#B8BDC8"))

	return st.commit()


# ---------------------------------------------------------------------------
# SurfaceTool Geometry Helpers (Verified Outward Winding)
# ---------------------------------------------------------------------------

func _add_tri(
	st: SurfaceTool,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	outward_hint: Vector3,
	col: Color
) -> void:
	var n: Vector3 = (c - a).cross(b - a)
	var v1: Vector3 = b
	var v2: Vector3 = c
	if n.dot(outward_hint) < 0.0:
		v1 = c
		v2 = b
		n = -n
	var n_len_sq: float = n.length_squared()
	var unit_n: Vector3 = n / sqrt(n_len_sq) if n_len_sq > 0.000001 else Vector3.UP

	st.set_normal(unit_n)
	st.set_color(col)
	st.add_vertex(a)

	st.set_normal(unit_n)
	st.set_color(col)
	st.add_vertex(v1)

	st.set_normal(unit_n)
	st.set_color(col)
	st.add_vertex(v2)


func _add_quad(
	st: SurfaceTool,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	d: Vector3,
	outward_hint: Vector3,
	col: Color
) -> void:
	_add_tri(st, a, b, c, outward_hint, col)
	_add_tri(st, a, c, d, outward_hint, col)


func _add_frustum(
	st: SurfaceTool,
	y0: float,
	r0: float,
	y1: float,
	r1: float,
	segs: int,
	offset: Vector3,
	col: Color,
	cap_bottom: bool,
	cap_top: bool
) -> void:
	var bot_pts: Array[Vector3] = []
	var top_pts: Array[Vector3] = []
	for s: int in range(segs):
		var ang: float = (float(s) / float(segs)) * TAU
		var ca: float = cos(ang)
		var sa: float = sin(ang)
		bot_pts.append(offset + Vector3(ca * r0, y0, sa * r0))
		top_pts.append(offset + Vector3(ca * r1, y1, sa * r1))

	for s: int in range(segs):
		var next_s: int = (s + 1) % segs
		var b0: Vector3 = bot_pts[s]
		var b1: Vector3 = bot_pts[next_s]
		var t0: Vector3 = top_pts[s]
		var t1: Vector3 = top_pts[next_s]
		var mid: Vector3 = (b0 + b1 + t0 + t1) * 0.25 - offset
		var out_hint: Vector3 = Vector3(mid.x, 0.0, mid.z)
		_add_quad(st, b0, b1, t1, t0, out_hint, col)

	if cap_bottom:
		var bc: Vector3 = offset + Vector3(0.0, y0, 0.0)
		for s: int in range(segs):
			var next_s: int = (s + 1) % segs
			_add_tri(st, bc, bot_pts[s], bot_pts[next_s], Vector3.DOWN, col)

	if cap_top:
		var tc: Vector3 = offset + Vector3(0.0, y1, 0.0)
		for s: int in range(segs):
			var next_s: int = (s + 1) % segs
			_add_tri(st, tc, top_pts[s], top_pts[next_s], Vector3.UP, col)


func _add_box(st: SurfaceTool, center: Vector3, size: Vector3, col: Color) -> void:
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5

	var p000: Vector3 = center + Vector3(-hx, -hy, -hz)
	var p100: Vector3 = center + Vector3(hx, -hy, -hz)
	var p110: Vector3 = center + Vector3(hx, hy, -hz)
	var p010: Vector3 = center + Vector3(-hx, hy, -hz)
	var p001: Vector3 = center + Vector3(-hx, -hy, hz)
	var p101: Vector3 = center + Vector3(hx, -hy, hz)
	var p111: Vector3 = center + Vector3(hx, hy, hz)
	var p011: Vector3 = center + Vector3(-hx, hy, hz)

	_add_quad(st, p001, p101, p111, p011, Vector3(0.0, 0.0, 1.0), col)
	_add_quad(st, p100, p000, p010, p110, Vector3(0.0, 0.0, -1.0), col)
	_add_quad(st, p101, p100, p110, p111, Vector3(1.0, 0.0, 0.0), col)
	_add_quad(st, p000, p001, p011, p010, Vector3(-1.0, 0.0, 0.0), col)
	_add_quad(st, p011, p111, p110, p010, Vector3(0.0, 1.0, 0.0), col)
	_add_quad(st, p000, p100, p101, p001, Vector3(0.0, -1.0, 0.0), col)


func _add_foliage_lobe(st: SurfaceTool, center: Vector3, radii: Vector3) -> void:
	var segs: int = 7
	var rings_count: int = 4
	var ring_pts: Array[Array] = []

	for r: int in range(1, rings_count):
		var phi: float = PI * (float(r) / float(rings_count))
		var sy: float = cos(phi)
		var sr: float = sin(phi)
		var pts: Array[Vector3] = []
		for s: int in range(segs):
			var theta: float = (float(s) / float(segs)) * TAU
			var pt: Vector3 = center + Vector3(cos(theta) * sr * radii.x, sy * radii.y, sin(theta) * sr * radii.z)
			pts.append(pt)
		ring_pts.append(pts)

	var north_pole: Vector3 = center + Vector3(0.0, radii.y, 0.0)
	var south_pole: Vector3 = center + Vector3(0.0, -radii.y, 0.0)

	# Top cap
	var top_ring: Array = ring_pts[0]
	for s: int in range(segs):
		var next_s: int = (s + 1) % segs
		var p0: Vector3 = top_ring[s] as Vector3
		var p1: Vector3 = top_ring[next_s] as Vector3
		var out_hint: Vector3 = ((north_pole + p0 + p1) * 0.333333) - center
		_add_tri(st, north_pole, p0, p1, out_hint, Color("#FFFFFF"))

	# Middle bands
	for r: int in range(ring_pts.size() - 1):
		var upper: Array = ring_pts[r]
		var lower: Array = ring_pts[r + 1]
		var shade: float = lerpf(0.95, 0.78, float(r) / float(maxf(float(ring_pts.size() - 1), 1.0)))
		var band_col: Color = Color(shade, shade + 0.02, shade + 0.03, 1.0)
		for s: int in range(segs):
			var next_s: int = (s + 1) % segs
			var u0: Vector3 = upper[s] as Vector3
			var u1: Vector3 = upper[next_s] as Vector3
			var l0: Vector3 = lower[s] as Vector3
			var l1: Vector3 = lower[next_s] as Vector3
			var out_hint: Vector3 = ((u0 + u1 + l0 + l1) * 0.25) - center
			_add_quad(st, u0, u1, l1, l0, out_hint, band_col)

	# Bottom cap
	var bot_ring: Array = ring_pts[ring_pts.size() - 1]
	for s: int in range(segs):
		var next_s: int = (s + 1) % segs
		var b0: Vector3 = bot_ring[s] as Vector3
		var b1: Vector3 = bot_ring[next_s] as Vector3
		var out_hint: Vector3 = ((south_pole + b0 + b1) * 0.333333) - center
		_add_tri(st, b0, b1, south_pole, out_hint, Color("#B6C0C6"))
