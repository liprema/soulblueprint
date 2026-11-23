class_name AkashaInfiniteVista
extends Node3D

## Serene, museum-grade Celestial Horizon surrounding the playable Akasha Prologue valley.
## Populates 20 widely-spaced, far-distant sanctuaries low along the mist horizon
## (Y in [-38, +14], distance 340..760 m) using 4 sculptural island archetypes,
## strictly keeping the upper sky and the sacred framing corridor directly behind
## the Baroque Palace (z < -276, |x| < 160) completely unobstructed.
## All distant silhouettes are softly veiled in periwinkle-azure atmospheric mist
## and rendered via GPU-instanced MultiMeshInstance3D batches with zero shadow casting.

const VALLEY_CENTER: Vector3 = Vector3(0.0, 10.0, -135.0)

# Generous exclusion volume around playable valley (x in [-82,82], z in [-352,78], y in [-16,88])
const EXCLUSION_HALF_X: float = 118.0
const EXCLUSION_MIN_Z: float = -395.0
const EXCLUSION_MAX_Z: float = 115.0
const EXCLUSION_MIN_Y: float = -34.0
const EXCLUSION_MAX_Y: float = 102.0

# Sacred unobstructed sky corridor behind the Baroque Palace dome (-Z vista)
const PALACE_CORRIDOR_MAX_Z: float = -276.0
const PALACE_CORRIDOR_HALF_X: float = 160.0

const ARCHETYPE_ARCH_CLIFF: int = 0
const ARCHETYPE_TERRACED_MESA: int = 1
const ARCHETYPE_TWIN_PEAK: int = 2
const ARCHETYPE_CRESCENT_CRAG: int = 3
const ARCHETYPE_COUNT: int = 4

const LOW_ISLAND_COUNT: int = 8
const MID_ISLAND_COUNT: int = 12
const HIGH_ISLAND_COUNT: int = 0

const TARGET_TOWER_COUNT: int = 6
const TARGET_ARCH_COUNT: int = 3
const TARGET_TREE_COUNT: int = 32
const TARGET_WATERFALL_COUNT: int = 4
const TARGET_SHARD_COUNT: int = 0

const SKY_HAZE_COLOR: Color = Color(0.74, 0.84, 0.98, 1.0)
const VISTA_CUSTOM_AABB: AABB = AABB(Vector3(-960.0, -280.0, -1100.0), Vector3(1920.0, 640.0, 1920.0))

var _layer_low: Node3D = null
var _layer_mid: Node3D = null
var _layer_high: Node3D = null

var _elapsed_time: float = 0.0

# 4 paired sculptural island archetype meshes (rock + terraced meadow) + 5 prop meshes
var _mesh_rocks: Array[ArrayMesh] = []
var _mesh_meadows: Array[ArrayMesh] = []
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

	# Gentle, dreamy slow vertical bob on parent layer nodes (zero per-frame MultiMesh overhead)
	if _layer_low != null:
		_layer_low.position.y = sin(_elapsed_time * 0.14) * 0.75
	if _layer_mid != null:
		_layer_mid.position.y = sin(_elapsed_time * 0.17 + 2.094) * 0.55
	if _layer_high != null:
		_layer_high.position.y = sin(_elapsed_time * 0.12 + 4.188) * 0.65


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
	rng.seed = 20261128

	var islands: Array[Dictionary] = []

	# 1. Lower Mist-Horizon Sanctuaries (y = -38..-16, 8 majestic islands, distances 360m..740m)
	_generate_layer_islands(rng, islands, 0, LOW_ISLAND_COUNT, -38.0, -16.0, 360.0, 740.0)

	# 2. Far Horizon Panorama Sanctuaries (y = -14..+14, 12 majestic islands, distances 340m..760m)
	_generate_layer_islands(rng, islands, 1, MID_ISLAND_COUNT, -14.0, 14.0, 340.0, 760.0)

	# 3. High Sky Layer intentionally empty (HIGH_ISLAND_COUNT = 0) so the upper sky stays pure & serene

	# Prepare 3 per-layer bucket maps for 4 rock + 4 meadow archetypes + 5 prop categories
	var buckets: Array[Dictionary] = []
	for _l: int in range(3):
		var rock_x_by_type: Array[Array] = []
		var rock_c_by_type: Array[Array] = []
		var meadow_x_by_type: Array[Array] = []
		var meadow_c_by_type: Array[Array] = []
		for _a: int in range(ARCHETYPE_COUNT):
			rock_x_by_type.append([])
			rock_c_by_type.append([])
			meadow_x_by_type.append([])
			meadow_c_by_type.append([])
		buckets.append({
			"rock_x": rock_x_by_type,
			"rock_c": rock_c_by_type,
			"meadow_x": meadow_x_by_type,
			"meadow_c": meadow_c_by_type,
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
		Color("#D5D1C8"),
		Color("#DDD8CE"),
		Color("#CBC8BF"),
		Color("#E1DDD4"),
		Color("#C7C9CE"),
	]
	var meadow_palette: Array[Color] = [
		Color("#4CA658"),
		Color("#5AB664"),
		Color("#52AE5E"),
		Color("#63BC6B"),
		Color("#459B54"),
	]
	var emerald_tree_palette: Array[Color] = [
		Color("#3B924B"),
		Color("#46A054"),
		Color("#348442"),
		Color("#4FA85C"),
	]
	var sakura_tree_palette: Array[Color] = [
		Color("#F4A6C0"),
		Color("#F8BCD0"),
		Color("#EE96B4"),
	]

	# Populate sculpted Cliff Rocks & paired Terraced Meadows for all 120 islands
	var island_count: int = islands.size()
	for i: int in range(island_count):
		var isl: Dictionary = islands[i]
		var archetype: int = int(isl["archetype"])
		var layer_idx: int = int(isl["layer"])
		var dist: float = float(isl["dist"])
		var isl_xform: Transform3D = isl["xform"]

		var bkt: Dictionary = buckets[layer_idx]
		var base_rock_col: Color = rock_palette[rng.randi() % rock_palette.size()]
		var base_meadow_col: Color = meadow_palette[rng.randi() % meadow_palette.size()]

		var rock_x_lists: Array = bkt["rock_x"]
		var rock_c_lists: Array = bkt["rock_c"]
		var meadow_x_lists: Array = bkt["meadow_x"]
		var meadow_c_lists: Array = bkt["meadow_c"]

		var rock_x_arr: Array = rock_x_lists[archetype]
		var rock_c_arr: Array = rock_c_lists[archetype]
		rock_x_arr.append(isl_xform)
		rock_c_arr.append(_apply_aerial_haze(base_rock_col, dist))

		var meadow_x_arr: Array = meadow_x_lists[archetype]
		var meadow_c_arr: Array = meadow_c_lists[archetype]
		meadow_x_arr.append(isl_xform)
		meadow_c_arr.append(_apply_aerial_haze(base_meadow_col, dist))

	# Select varied prominent islands for Fairytale White-Blue Spire Towers
	var tower_candidates: Array[int] = []
	for i: int in range(island_count):
		tower_candidates.append(i)
	tower_candidates.sort_custom(func(a_idx: int, b_idx: int) -> bool:
		var isl_a: Dictionary = islands[a_idx]
		var isl_b: Dictionary = islands[b_idx]
		var score_a: float = float(isl_a["radius"]) + float(isl_a["tower_affinity"])
		var score_b: float = float(isl_b["radius"]) + float(isl_b["tower_affinity"])
		return score_a > score_b
	)

	var towers_placed: int = 0
	for idx: int in tower_candidates:
		if towers_placed >= TARGET_TOWER_COUNT:
			break
		var isl: Dictionary = islands[idx]
		var radius: float = float(isl["radius"])
		var layer_idx: int = int(isl["layer"])
		var dist: float = float(isl["dist"])
		var archetype: int = int(isl["archetype"])
		var isl_xform: Transform3D = isl["xform"]

		var local_anchor: Vector3 = _get_archetype_anchor(archetype, "tower", rng)
		var tower_pos: Vector3 = isl_xform * local_anchor
		var tower_scale: float = clampf(radius * rng.randf_range(0.22, 0.31), 3.2, 14.2)
		if not _is_clear_of_playable_zone(tower_pos, tower_scale * 1.4, tower_scale * 5.4, 1.0):
			continue

		var to_valley: Vector3 = VALLEY_CENTER - tower_pos
		var face_yaw: float = atan2(to_valley.x, to_valley.z) + rng.randf_range(-0.50, 0.50)
		var t_basis: Basis = Basis(Vector3.UP, face_yaw).scaled(Vector3(tower_scale, tower_scale, tower_scale))
		var bkt: Dictionary = buckets[layer_idx]
		var tower_x_arr: Array = bkt["tower_x"]
		var tower_c_arr: Array = bkt["tower_c"]
		tower_x_arr.append(Transform3D(t_basis, tower_pos))
		tower_c_arr.append(_apply_aerial_haze(Color(1.0, 1.0, 1.0, 1.0), dist))
		isl["has_tower"] = true
		towers_placed += 1

	# Select Mid & High islands for Classical Archways (mixing islands with and without towers)
	var arch_candidates: Array[int] = []
	for i: int in range(island_count):
		var layer_idx: int = int(islands[i]["layer"])
		if layer_idx >= 1:
			arch_candidates.append(i)
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
		var radius: float = float(isl["radius"])
		var layer_idx: int = int(isl["layer"])
		var dist: float = float(isl["dist"])
		var archetype: int = int(isl["archetype"])
		var isl_xform: Transform3D = isl["xform"]

		var local_anchor: Vector3 = _get_archetype_anchor(archetype, "arch", rng)
		var arch_pos: Vector3 = isl_xform * local_anchor
		var arch_scale: float = clampf(radius * rng.randf_range(0.19, 0.27), 2.8, 10.4)
		if not _is_clear_of_playable_zone(arch_pos, arch_scale * 2.0, arch_scale * 4.2, 1.0):
			continue

		var to_valley: Vector3 = VALLEY_CENTER - arch_pos
		var flat_dir: Vector3 = Vector3(to_valley.x, 0.0, to_valley.z)
		var arch_yaw: float = atan2(flat_dir.x, flat_dir.z) + rng.randf_range(-0.42, 0.42)
		var a_basis: Basis = Basis(Vector3.UP, arch_yaw).scaled(Vector3(arch_scale, arch_scale, arch_scale))
		var bkt: Dictionary = buckets[layer_idx]
		var arch_x_arr: Array = bkt["arch_x"]
		var arch_c_arr: Array = bkt["arch_c"]
		arch_x_arr.append(Transform3D(a_basis, arch_pos))
		arch_c_arr.append(_apply_aerial_haze(Color(1.0, 1.0, 1.0, 1.0), dist))
		isl["has_arch"] = true
		arches_placed += 1

	# Distribute 240 Lush Tree Crowns (emerald + sakura-blush) onto each archetype's terraced meadows
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

			var layer_idx: int = int(isl["layer"])
			var dist: float = float(isl["dist"])
			var archetype: int = int(isl["archetype"])
			var isl_xform: Transform3D = isl["xform"]

			var local_tree: Vector3 = _get_archetype_anchor(archetype, "tree", rng)
			var tree_pos: Vector3 = isl_xform * local_tree

			var tree_scale: float = clampf(radius * rng.randf_range(0.12, 0.21), 2.0, 8.6)
			var tree_h_scale: float = tree_scale * rng.randf_range(0.90, 1.24)
			var t_basis: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(tree_scale, tree_h_scale, tree_scale))

			var is_sakura: bool = rng.randf() < 0.26
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

	# Distribute 32 Cascading Turquoise Waterfalls off High & Mid islands
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
		var layer_idx: int = int(isl["layer"])
		var dist: float = float(isl["dist"])
		var archetype: int = int(isl["archetype"])
		var isl_xform: Transform3D = isl["xform"]

		var local_wf: Vector3 = _get_archetype_anchor(archetype, "waterfall", rng)
		var wf_pos: Vector3 = isl_xform * local_wf

		var out_dir: Vector3 = Vector3(wf_pos.x - pos.x, 0.0, wf_pos.z - pos.z)
		if out_dir.length_squared() < 0.001:
			var to_v: Vector3 = VALLEY_CENTER - pos
			out_dir = Vector3(to_v.x, 0.0, to_v.z)
		if out_dir.length_squared() < 0.001:
			out_dir = Vector3.FORWARD
		else:
			out_dir = out_dir.normalized()

		var wf_width: float = clampf(radius * rng.randf_range(0.16, 0.26), 2.6, 10.5)
		var wf_height: float = rng.randf_range(44.0, 94.0) if layer_idx == 2 else rng.randf_range(34.0, 68.0)
		if not _is_clear_of_playable_zone(wf_pos, wf_width, 2.0, wf_height):
			continue

		var wf_yaw: float = atan2(out_dir.x, out_dir.z)
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

	# Distribute only 20 subtle distant rock shards far out in the archipelago so the sky stays clean & grand
	var far_islands: Array[int] = []
	for i: int in range(island_count):
		if float(islands[i]["dist"]) >= 320.0:
			far_islands.append(i)
	for i: int in range(far_islands.size() - 1, 0, -1):
		var swap_idx: int = rng.randi() % (i + 1)
		var tmp: int = far_islands[i]
		far_islands[i] = far_islands[swap_idx]
		far_islands[swap_idx] = tmp

	var shards_placed: int = 0
	var far_count: int = far_islands.size()
	if far_count > 0:
		var shard_attempt: int = 0
		while shards_placed < TARGET_SHARD_COUNT and shard_attempt < TARGET_SHARD_COUNT * 4:
			shard_attempt += 1
			var isl: Dictionary = islands[far_islands[shards_placed % far_count]]
			var pos: Vector3 = isl["pos"]
			var radius: float = float(isl["radius"])
			var scale_y: float = float(isl["scale_y"])
			var layer_idx: int = int(isl["layer"])
			var dist: float = float(isl["dist"])

			var orbit_ang: float = rng.randf_range(0.0, TAU)
			var orbit_dist: float = radius * rng.randf_range(1.25, 1.85) + rng.randf_range(6.0, 14.0)
			var y_offset: float = rng.randf_range(-scale_y * 0.95, -scale_y * 0.25)
			var shard_pos: Vector3 = pos + Vector3(cos(orbit_ang) * orbit_dist, y_offset, sin(orbit_ang) * orbit_dist)

			var shard_scale_xz: float = clampf(radius * rng.randf_range(0.09, 0.16), 2.0, 6.2)
			var shard_scale_y: float = shard_scale_xz * rng.randf_range(1.10, 1.75)
			if not _is_clear_of_playable_zone(shard_pos, shard_scale_xz * 1.4, shard_scale_y, shard_scale_y * 1.2):
				continue

			var s_basis: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU))
			s_basis = s_basis.rotated(Vector3.RIGHT, rng.randf_range(-0.18, 0.18))
			s_basis = s_basis.rotated(Vector3.FORWARD, rng.randf_range(-0.18, 0.18))
			s_basis = s_basis.scaled(Vector3(shard_scale_xz, shard_scale_y, shard_scale_xz * rng.randf_range(0.75, 1.20)))

			var bkt: Dictionary = buckets[layer_idx]
			var base_shard_col: Color = rock_palette[rng.randi() % rock_palette.size()]
			var shard_x_arr: Array = bkt["shard_x"]
			var shard_c_arr: Array = bkt["shard_c"]
			shard_x_arr.append(Transform3D(s_basis, shard_pos))
			shard_c_arr.append(_apply_aerial_haze(base_shard_col, dist))
			shards_placed += 1

	# Commit each elevation layer's GPU-instanced MultiMeshInstance3D batches
	var archetype_names: Array[String] = ["ArchCliff", "TerracedMesa", "TwinPeak", "CrescentCrag"]
	var layer_nodes: Array[Node3D] = [_layer_low, _layer_mid, _layer_high]
	for layer_idx: int in range(3):
		var parent_node: Node3D = layer_nodes[layer_idx]
		var bkt: Dictionary = buckets[layer_idx]
		var rock_x_lists: Array = bkt["rock_x"]
		var rock_c_lists: Array = bkt["rock_c"]
		var meadow_x_lists: Array = bkt["meadow_x"]
		var meadow_c_lists: Array = bkt["meadow_c"]

		for a_idx: int in range(ARCHETYPE_COUNT):
			var a_name: String = archetype_names[a_idx]
			_create_multimesh_batch(
				parent_node,
				"Rock_" + a_name,
				_mesh_rocks[a_idx],
				_mat_rock,
				rock_x_lists[a_idx],
				rock_c_lists[a_idx]
			)
			_create_multimesh_batch(
				parent_node,
				"Meadow_" + a_name,
				_mesh_meadows[a_idx],
				_mat_meadow,
				meadow_x_lists[a_idx],
				meadow_c_lists[a_idx]
			)

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
	if count <= 0:
		return

	var archetype_counts: Array[int] = [0, 0, 0, 0]

	for idx: int in range(count):
		var sector_base: float = (float(idx) / float(count)) * TAU
		var sector_span: float = TAU / float(count)

		var placed: bool = false
		for attempt: int in range(64):
			var angle: float = sector_base + rng.randf_range(0.10, 0.90) * sector_span
			if attempt >= 22:
				angle = rng.randf_range(0.0, TAU)

			var band_t: float = clampf((float(idx % 4) + rng.randf_range(0.08, 0.92)) * 0.25, 0.0, 1.0)
			if attempt >= 16:
				band_t = rng.randf()
			var dist: float = lerpf(min_dist, max_dist, pow(band_t, 0.90))

			var x_pos: float = VALLEY_CENTER.x + cos(angle) * dist
			var z_pos: float = VALLEY_CENTER.z + sin(angle) * dist * 1.08
			var y_pos: float = rng.randf_range(min_y, max_y)

			var dist_norm: float = clampf((dist - min_dist) / maxf(max_dist - min_dist, 1.0), 0.0, 1.0)
			var radius: float = lerpf(26.0, 52.0, dist_norm) * rng.randf_range(0.84, 1.20)

			var pos: Vector3 = Vector3(x_pos, y_pos, z_pos)
			var archetype: int = _pick_diverse_archetype(pos, islands, archetype_counts, rng)
			var isl_scale: Vector3 = _compute_archetype_scale(archetype, radius, rng)

			var max_horiz_r: float = maxf(isl_scale.x, isl_scale.z) * 1.16
			var est_top_h: float = isl_scale.y * 0.72 + 14.0
			var est_bot_d: float = isl_scale.y * 1.45

			if not _is_clear_of_playable_zone(pos, max_horiz_r, est_top_h, est_bot_d):
				continue

			var too_close: bool = false
			for existing: Dictionary in islands:
				var e_pos: Vector3 = existing["pos"]
				var e_rad: float = float(existing["horiz_r"])
				var min_gap: float = (max_horiz_r + e_rad) * 1.85 + 52.0
				var dx: float = pos.x - e_pos.x
				var dz: float = pos.z - e_pos.z
				if (dx * dx + dz * dz) < (min_gap * min_gap):
					too_close = true
					break
			if too_close:
				continue

			var isl_xform: Transform3D = _build_island_transform(pos, isl_scale, rng)
			archetype_counts[archetype] += 1
			islands.append({
				"pos": pos,
				"radius": radius,
				"horiz_r": max_horiz_r,
				"scale_y": isl_scale.y,
				"archetype": archetype,
				"xform": isl_xform,
				"layer": layer_idx,
				"dist": pos.distance_to(VALLEY_CENTER),
				"tower_affinity": rng.randf_range(-10.0, 14.0) + (8.0 if layer_idx >= 1 else 0.0),
				"has_tower": false,
				"has_arch": false,
			})
			placed = true
			break

		if not placed:
			for fb_try: int in range(20):
				var fb_angle: float = rng.randf_range(0.0, TAU)
				var fb_dist: float = lerpf(min_dist + 60.0, max_dist, rng.randf())
				var fb_pos: Vector3 = Vector3(
					VALLEY_CENTER.x + cos(fb_angle) * fb_dist,
					rng.randf_range(min_y, max_y),
					VALLEY_CENTER.z + sin(fb_angle) * fb_dist * 1.08
				)
				var fb_radius: float = rng.randf_range(28.0, 44.0)
				var fb_archetype: int = _pick_diverse_archetype(fb_pos, islands, archetype_counts, rng)
				var fb_scale: Vector3 = _compute_archetype_scale(fb_archetype, fb_radius, rng)
				var fb_horiz_r: float = maxf(fb_scale.x, fb_scale.z) * 1.16
				if not _is_clear_of_playable_zone(fb_pos, fb_horiz_r, fb_scale.y * 0.72 + 14.0, fb_scale.y * 1.45):
					continue
				var fb_xform: Transform3D = _build_island_transform(fb_pos, fb_scale, rng)
				archetype_counts[fb_archetype] += 1
				islands.append({
					"pos": fb_pos,
					"radius": fb_radius,
					"horiz_r": fb_horiz_r,
					"scale_y": fb_scale.y,
					"archetype": fb_archetype,
					"xform": fb_xform,
					"layer": layer_idx,
					"dist": fb_pos.distance_to(VALLEY_CENTER),
					"tower_affinity": rng.randf_range(-10.0, 14.0) + (8.0 if layer_idx >= 1 else 0.0),
					"has_tower": false,
					"has_arch": false,
				})
				break


func _pick_diverse_archetype(
	pos: Vector3,
	islands: Array[Dictionary],
	counts: Array[int],
	rng: RandomNumberGenerator
) -> int:
	# Find the closest existing island so adjacent silhouettes never repeat
	var nearest_type: int = -1
	var nearest_sq: float = 1e12
	for existing: Dictionary in islands:
		var e_pos: Vector3 = existing["pos"]
		var d_sq: float = pos.distance_squared_to(e_pos)
		if d_sq < nearest_sq:
			nearest_sq = d_sq
			nearest_type = int(existing["archetype"])

	var min_count: int = 999999
	for a: int in range(ARCHETYPE_COUNT):
		if a == nearest_type:
			continue
		if counts[a] < min_count:
			min_count = counts[a]

	var best_choices: Array[int] = []
	for a: int in range(ARCHETYPE_COUNT):
		if a == nearest_type:
			continue
		if counts[a] <= min_count + 1:
			best_choices.append(a)

	if best_choices.is_empty():
		return rng.randi() % ARCHETYPE_COUNT
	return best_choices[rng.randi() % best_choices.size()]


func _compute_archetype_scale(archetype: int, radius: float, rng: RandomNumberGenerator) -> Vector3:
	if archetype == ARCHETYPE_ARCH_CLIFF:
		var sx: float = radius * rng.randf_range(0.95, 1.28)
		var sy: float = radius * rng.randf_range(0.84, 1.16)
		var sz: float = radius * rng.randf_range(0.76, 1.06)
		return Vector3(sx, sy, sz)
	if archetype == ARCHETYPE_TERRACED_MESA:
		var sx: float = radius * rng.randf_range(1.00, 1.32)
		var sy: float = radius * rng.randf_range(0.68, 0.96)
		var sz: float = radius * rng.randf_range(0.88, 1.20)
		return Vector3(sx, sy, sz)
	if archetype == ARCHETYPE_TWIN_PEAK:
		var sx: float = radius * rng.randf_range(0.98, 1.30)
		var sy: float = radius * rng.randf_range(0.82, 1.18)
		var sz: float = radius * rng.randf_range(0.78, 1.08)
		return Vector3(sx, sy, sz)
	# ARCHETYPE_CRESCENT_CRAG
	var sx_c: float = radius * rng.randf_range(0.92, 1.24)
	var sy_c: float = radius * rng.randf_range(0.78, 1.12)
	var sz_c: float = radius * rng.randf_range(0.90, 1.24)
	return Vector3(sx_c, sy_c, sz_c)


func _build_island_transform(pos: Vector3, isl_scale: Vector3, rng: RandomNumberGenerator) -> Transform3D:
	var yaw: float = rng.randf_range(0.0, TAU)
	var pitch: float = rng.randf_range(-0.045, 0.045)
	var roll: float = rng.randf_range(-0.045, 0.045)
	var xform_basis: Basis = Basis(Vector3.UP, yaw)
	xform_basis = xform_basis.rotated(Vector3.RIGHT, pitch)
	xform_basis = xform_basis.rotated(Vector3.FORWARD, roll)
	xform_basis = xform_basis.scaled(isl_scale)
	return Transform3D(xform_basis, pos)


func _get_archetype_anchor(archetype: int, slot: String, rng: RandomNumberGenerator) -> Vector3:
	if archetype == ARCHETYPE_ARCH_CLIFF:
		if slot == "tower":
			return Vector3(rng.randf_range(-0.48, -0.18), 0.11, rng.randf_range(-0.14, 0.14))
		if slot == "arch":
			return Vector3(rng.randf_range(0.24, 0.48), 0.05, rng.randf_range(-0.12, 0.12))
		if slot == "waterfall":
			return Vector3(rng.randf_range(-0.12, 0.18), 0.05, 0.44)
		# tree
		var tx: float = rng.randf_range(-0.82, 0.72)
		var ty: float = lerpf(0.10, 0.03, clampf((tx + 0.82) / 1.54, 0.0, 1.0))
		return Vector3(tx, ty, rng.randf_range(-0.30, 0.30))

	if archetype == ARCHETYPE_TERRACED_MESA:
		if slot == "tower":
			return Vector3(-0.10 + rng.randf_range(-0.16, 0.16), 0.22, -0.06 + rng.randf_range(-0.14, 0.14))
		if slot == "arch":
			return Vector3(0.50 + rng.randf_range(-0.10, 0.12), 0.02, 0.28 + rng.randf_range(-0.10, 0.12))
		if slot == "waterfall":
			return Vector3(0.28 + rng.randf_range(-0.20, 0.20), 0.0, 0.86)
		# tree across all 3 terraced tiers
		var tier_roll: float = rng.randf()
		if tier_roll < 0.40:
			var a1: float = rng.randf_range(0.0, TAU)
			var r1: float = rng.randf_range(0.18, 0.56)
			return Vector3(-0.10 + cos(a1) * r1, 0.21, -0.06 + sin(a1) * r1 * 0.88)
		if tier_roll < 0.80:
			var a2: float = rng.randf_range(-0.85, 2.25)
			var r2: float = rng.randf_range(0.68, 0.94)
			return Vector3(0.08 + cos(a2) * r2, 0.02, 0.06 + sin(a2) * r2 * 0.84)
		return Vector3(0.52 + rng.randf_range(-0.28, 0.26), -0.23, 0.38 + rng.randf_range(-0.18, 0.20))

	if archetype == ARCHETYPE_TWIN_PEAK:
		if slot == "tower":
			return Vector3(0.60 + rng.randf_range(-0.14, 0.14), 0.07, 0.10 + rng.randf_range(-0.14, 0.14))
		if slot == "arch":
			return Vector3(0.02 + rng.randf_range(-0.08, 0.08), -0.04, 0.14)
		if slot == "waterfall":
			return Vector3(0.58 + rng.randf_range(-0.15, 0.15), 0.04, 0.56)
		# tree on East meadow, saddle, or West shoulder
		var p_roll: float = rng.randf()
		if p_roll < 0.65:
			var ap: float = rng.randf_range(0.0, TAU)
			var rp: float = rng.randf_range(0.12, 0.46)
			return Vector3(0.62 + cos(ap) * rp, 0.06, 0.10 + sin(ap) * rp * 0.86)
		if p_roll < 0.85:
			return Vector3(-0.34 + rng.randf_range(-0.12, 0.12), 0.24, 0.06 + rng.randf_range(-0.10, 0.10))
		return Vector3(rng.randf_range(-0.20, 0.24), -0.04, 0.14 + rng.randf_range(-0.08, 0.08))

	# ARCHETYPE_CRESCENT_CRAG
	if slot == "tower":
		return Vector3(0.46 + rng.randf_range(-0.08, 0.08), 0.16, -0.52 + rng.randf_range(-0.08, 0.08))
	if slot == "arch":
		return Vector3(0.76, 0.06, 0.10 + rng.randf_range(-0.10, 0.10))
	if slot == "waterfall":
		return Vector3(0.48, 0.04, 0.04)
	# tree along curved crescent ridge
	var ct: float = rng.randf_range(0.10, 0.82)
	var c_ang: float = lerpf(-1.05, 1.15, ct)
	var c_rad: float = 0.78 + rng.randf_range(-0.14, 0.14)
	var c_y: float = lerpf(0.15, -0.02, ct)
	return Vector3(cos(c_ang) * c_rad, c_y, sin(c_ang) * c_rad)


func _is_clear_of_playable_zone(
	pos: Vector3,
	horiz_radius: float,
	top_height: float,
	bottom_depth: float
) -> bool:
	# Strictly keep the sacred sky corridor behind the Baroque Palace dome unobstructed
	if _is_in_palace_framing_corridor(pos, horiz_radius):
		return false

	var pad: float = horiz_radius + 12.0
	var inside_x: bool = absf(pos.x) < (EXCLUSION_HALF_X + pad)
	var inside_z: bool = pos.z > (EXCLUSION_MIN_Z - pad) and pos.z < (EXCLUSION_MAX_Z + pad)
	var inside_y: bool = (pos.y + top_height) > EXCLUSION_MIN_Y and (pos.y - bottom_depth) < EXCLUSION_MAX_Y
	return not (inside_x and inside_z and inside_y)


func _is_in_palace_framing_corridor(pos: Vector3, horiz_radius: float) -> bool:
	var pad: float = horiz_radius + 18.0
	var behind_palace: bool = pos.z < (PALACE_CORRIDOR_MAX_Z + pad)
	var within_corridor_x: bool = absf(pos.x) < (PALACE_CORRIDOR_HALF_X + pad)
	return behind_palace and within_corridor_x


func _apply_aerial_haze(base_col: Color, dist: float) -> Color:
	# Softly veil all far sanctuaries in luminous periwinkle-azure atmospheric mist
	var haze_t: float = clampf(0.42 + (dist - 340.0) / 760.0, 0.42, 0.76)
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
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
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
	_mat_waterfall.albedo_color = Color(0.80, 0.91, 1.0, 0.48)
	_mat_waterfall.roughness = 0.30
	_mat_waterfall.emission_enabled = true
	_mat_waterfall.emission = Color("#A8D6F8")
	_mat_waterfall.emission_energy_multiplier = 0.20

	_mat_shard = StandardMaterial3D.new()
	_mat_shard.vertex_color_use_as_albedo = true
	_mat_shard.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	_mat_shard.roughness = 0.88
	_mat_shard.metallic = 0.0


# ---------------------------------------------------------------------------
# Shared Procedural ArrayMeshes (4 Distinct Island Archetypes + 5 Props)
# ---------------------------------------------------------------------------

func _build_shared_meshes() -> void:
	_mesh_rocks = [
		_build_arch_cliff_rock_mesh(),
		_build_terraced_mesa_rock_mesh(),
		_build_twin_peak_rock_mesh(),
		_build_crescent_crag_rock_mesh(),
	]
	_mesh_meadows = [
		_build_arch_cliff_meadow_mesh(),
		_build_terraced_mesa_meadow_mesh(),
		_build_twin_peak_meadow_mesh(),
		_build_crescent_crag_meadow_mesh(),
	]
	_mesh_tower = _build_spire_tower_mesh()
	_mesh_arch = _build_archway_mesh()
	_mesh_tree = _build_tree_crown_mesh()
	_mesh_waterfall = _build_waterfall_mesh()
	_mesh_shard = _build_rock_shard_mesh()


# ---------------------------------------------------------------------------
# Archetype A — Natural Arch Cliff Island
# Sweeping overhanging cliff with an open natural stone archway through its belly
# ---------------------------------------------------------------------------

func _build_arch_cliff_rock_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var col_top: Color = Color("#ECE7DD")
	var col_upper: Color = Color("#DDD8CE")
	var col_mid: Color = Color("#C9C6BE")
	var col_deep: Color = Color("#B0B5C2")
	var col_shadow: Color = Color("#9BA3B4")

	# 1. Sweeping Natural Stone Arch Span (open daylight window underneath between x = -0.40..+0.40)
	var arch_segs: int = 8
	var sections: Array[Array] = []
	var sec_centers: Array[Vector3] = []
	var sec_cols: Array[Color] = []

	for i: int in range(arch_segs + 1):
		var t: float = float(i) / float(arch_segs)
		var x_val: float = lerpf(-1.06, 0.96, t)
		# Overhanging plateau top gently canted from higher left (+0.09) to right (-0.01)
		var y_top: float = lerpf(0.09, -0.01, t) + sin(t * PI) * 0.03
		# Dramatic open arch curve underneath: deep at piers (-0.64), soaring up to -0.18 at center!
		var arch_u: float = clampf((x_val + 0.62) / 1.24, 0.0, 1.0)
		var arch_lift: float = sin(arch_u * PI)
		var y_bot: float = lerpf(-0.62, -0.17, arch_lift)
		# Taper overhangs at far left and far right wing tips
		if t < 0.18:
			var wing_l: float = t / 0.18
			y_bot = lerpf(-0.18, -0.62, wing_l)
		elif t > 0.84:
			var wing_r: float = (1.0 - t) / 0.16
			y_bot = lerpf(-0.16, -0.58, wing_r)

		var half_z_top: float = lerpf(0.42, 0.34, t) + sin(t * PI) * 0.14
		var half_z_bot: float = half_z_top * lerpf(0.76, 0.64, arch_lift)
		var z_shift: float = sin(t * PI * 1.4) * 0.06
		var y_mid: float = lerpf(y_top, y_bot, 0.45)

		# 6-point sculpted cross-section around the arch span
		var sec: Array[Vector3] = [
			Vector3(x_val, y_top, z_shift - half_z_top * 0.72),
			Vector3(x_val, y_top + 0.015, z_shift + half_z_top * 0.72),
			Vector3(x_val, y_mid, z_shift + half_z_top * 1.04),
			Vector3(x_val, y_bot, z_shift + half_z_bot * 0.70),
			Vector3(x_val, y_bot - 0.02, z_shift - half_z_bot * 0.70),
			Vector3(x_val, y_mid, z_shift - half_z_top * 1.02),
		]
		sections.append(sec)
		sec_centers.append(Vector3(x_val, (y_top + y_bot) * 0.5, z_shift))
		sec_cols.append(col_upper if arch_lift > 0.4 else col_mid)

	_add_curved_ribbon(st, sections, sec_centers, sec_cols, true, true)

	# 2. Left Swept Cliff Pier (sturdy asymmetric buttress framing the left side of the arch)
	var left_centers: Array[Vector3] = [
		Vector3(-0.66, -0.14, 0.02),
		Vector3(-0.62, -0.44, 0.01),
		Vector3(-0.56, -0.78, -0.02),
		Vector3(-0.46, -1.08, -0.05),
		Vector3(-0.36, -1.32, -0.07),
	]
	var left_radii: Array[Vector2] = [
		Vector2(0.36, 0.48),
		Vector2(0.32, 0.42),
		Vector2(0.24, 0.30),
		Vector2(0.15, 0.19),
		Vector2(0.06, 0.08),
	]
	var left_cols: Array[Color] = [col_upper, col_mid, col_deep, col_shadow, col_shadow]
	_add_sculpted_column(st, left_centers, left_radii, left_cols, 8, 0.4, false, true)

	# 3. Right Swept Cliff Pier (lighter asymmetric buttress framing the right side of the arch)
	var right_centers: Array[Vector3] = [
		Vector3(0.60, -0.16, -0.02),
		Vector3(0.56, -0.44, -0.01),
		Vector3(0.49, -0.74, 0.02),
		Vector3(0.40, -0.98, 0.04),
	]
	var right_radii: Array[Vector2] = [
		Vector2(0.30, 0.40),
		Vector2(0.26, 0.34),
		Vector2(0.18, 0.24),
		Vector2(0.07, 0.09),
	]
	var right_cols: Array[Color] = [col_upper, col_mid, col_deep, col_shadow]
	_add_sculpted_column(st, right_centers, right_radii, right_cols, 8, 1.9, false, true)

	# 4. Dramatic upper cliff brow shelf on left overhang
	var brow_centers: Array[Vector3] = [
		Vector3(-0.52, 0.10, 0.0),
		Vector3(-0.54, 0.02, 0.0),
		Vector3(-0.48, -0.14, 0.0),
	]
	var brow_radii: Array[Vector2] = [
		Vector2(0.56, 0.44),
		Vector2(0.60, 0.47),
		Vector2(0.48, 0.38),
	]
	_add_sculpted_column(st, brow_centers, brow_radii, [col_top, col_upper, col_mid], 8, 0.8, true, false)

	return st.commit()


func _build_arch_cliff_meadow_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Asymmetric mossy plateau draping over the cantilevered left-center arch crown
	_add_grass_slab(st, Vector3(-0.22, 0.09, 0.01), 0.86, 0.49, 0.08, 12, 0.3, -0.04, 0.0)
	# Secondary mossy shoulder terrace on the right wing
	_add_grass_slab(st, Vector3(0.56, 0.03, 0.0), 0.44, 0.38, 0.07, 10, 1.7, -0.02, 0.0)

	return st.commit()


# ---------------------------------------------------------------------------
# Archetype B — Wide Stepped Terraced Garden Mesa
# Broad, flat-topped 3-tier sanctuary plateau with cascading emerald terraces (no cone!)
# ---------------------------------------------------------------------------

func _build_terraced_mesa_rock_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var col_top: Color = Color("#EEEAE0")
	var col_tier1: Color = Color("#E0DBD1")
	var col_tier2: Color = Color("#D0CCC2")
	var col_tier3: Color = Color("#C0C0C2")
	var col_keel: Color = Color("#A8B0BE")

	# Tier 1: Upper Sanctuary Mesa Block
	var t1_centers: Array[Vector3] = [
		Vector3(-0.10, 0.19, -0.06),
		Vector3(-0.10, 0.14, -0.06),
		Vector3(-0.10, -0.04, -0.06),
	]
	var t1_radii: Array[Vector2] = [
		Vector2(0.68, 0.60),
		Vector2(0.73, 0.64),
		Vector2(0.76, 0.67),
	]
	_add_sculpted_column(st, t1_centers, t1_radii, [col_top, col_tier1, col_tier2], 10, 0.2, true, false)

	# Tier 2 & 3: Broad Stepped Garden Mesa & Flat-Chiseled Stratified Keel (NOT a cone!)
	var mesa_centers: Array[Vector3] = [
		Vector3(0.08, 0.00, 0.06),
		Vector3(0.08, -0.08, 0.06),
		Vector3(0.09, -0.26, 0.07),
		Vector3(0.11, -0.30, 0.08),
		Vector3(0.06, -0.52, 0.04),
		Vector3(0.02, -0.72, 0.01),
		Vector3(0.00, -0.82, 0.00),
	]
	var mesa_radii: Array[Vector2] = [
		Vector2(1.02, 0.88),
		Vector2(1.08, 0.93),
		Vector2(1.04, 0.90),
		Vector2(1.16, 0.98),
		Vector2(0.86, 0.72),
		Vector2(0.62, 0.50),
		Vector2(0.46, 0.36),
	]
	var mesa_cols: Array[Color] = [col_tier1, col_tier2, col_tier2, col_tier1, col_tier3, col_keel, col_keel]
	_add_sculpted_column(st, mesa_centers, mesa_radii, mesa_cols, 12, 1.1, true, true)

	# Small offset hanging rock shelf under front-right edge for organic asymmetry
	var shelf_centers: Array[Vector3] = [
		Vector3(0.50, -0.26, 0.36),
		Vector3(0.48, -0.46, 0.34),
		Vector3(0.42, -0.68, 0.28),
	]
	var shelf_radii: Array[Vector2] = [
		Vector2(0.54, 0.42),
		Vector2(0.44, 0.34),
		Vector2(0.24, 0.18),
	]
	_add_sculpted_column(st, shelf_centers, shelf_radii, [col_tier2, col_tier3, col_keel], 8, 2.3, true, true)

	return st.commit()


func _build_terraced_mesa_meadow_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 3 cascading emerald terraces!
	_add_grass_slab(st, Vector3(-0.10, 0.20, -0.06), 0.72, 0.63, 0.07, 10, 0.2, 0.0, 0.0)
	_add_grass_slab(st, Vector3(0.08, 0.01, 0.06), 1.07, 0.92, 0.08, 12, 1.1, 0.0, 0.0)
	_add_grass_slab(st, Vector3(0.50, -0.25, 0.36), 0.56, 0.44, 0.07, 8, 2.3, 0.0, 0.0)

	return st.commit()


# ---------------------------------------------------------------------------
# Archetype C — Asymmetric Twin-Peak Sanctuary Island
# Tall windswept rocky peak + lower meadow terrace joined by a slender curved stone ridge
# ---------------------------------------------------------------------------

func _build_twin_peak_rock_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var col_peak: Color = Color("#F0ECE3")
	var col_upper: Color = Color("#DDD8CE")
	var col_mid: Color = Color("#C9C6BE")
	var col_deep: Color = Color("#B0B6C2")
	var col_shadow: Color = Color("#9EA6B6")

	# 1. West Tall Windswept Limestone Peak (soars to y = +0.64, sweeps down to -1.16)
	var peak_centers: Array[Vector3] = [
		Vector3(-0.68, 0.64, -0.10),
		Vector3(-0.64, 0.36, -0.08),
		Vector3(-0.58, 0.08, -0.05),
		Vector3(-0.56, -0.22, -0.04),
		Vector3(-0.52, -0.60, -0.06),
		Vector3(-0.46, -0.94, -0.08),
		Vector3(-0.42, -1.16, -0.09),
	]
	var peak_radii: Array[Vector2] = [
		Vector2(0.11, 0.13),
		Vector2(0.28, 0.32),
		Vector2(0.46, 0.48),
		Vector2(0.50, 0.50),
		Vector2(0.38, 0.38),
		Vector2(0.20, 0.22),
		Vector2(0.08, 0.09),
	]
	var peak_cols: Array[Color] = [col_peak, col_upper, col_upper, col_mid, col_deep, col_shadow, col_shadow]
	_add_sculpted_column(st, peak_centers, peak_radii, peak_cols, 8, 0.7, true, true)

	# High eastern mossy shoulder step on the tall peak
	var shoulder_centers: Array[Vector3] = [
		Vector3(-0.34, 0.22, 0.06),
		Vector3(-0.34, 0.04, 0.06),
		Vector3(-0.36, -0.22, 0.04),
	]
	var shoulder_radii: Array[Vector2] = [
		Vector2(0.26, 0.24),
		Vector2(0.30, 0.28),
		Vector2(0.24, 0.22),
	]
	_add_sculpted_column(st, shoulder_centers, shoulder_radii, [col_upper, col_mid, col_deep], 7, 1.4, true, false)

	# 2. East Lower Sanctuary Meadow Buttress (flat-topped plateau at y = +0.04)
	var east_centers: Array[Vector3] = [
		Vector3(0.62, 0.04, 0.10),
		Vector3(0.62, -0.06, 0.10),
		Vector3(0.60, -0.34, 0.08),
		Vector3(0.55, -0.64, 0.05),
		Vector3(0.48, -0.86, 0.03),
	]
	var east_radii: Array[Vector2] = [
		Vector2(0.56, 0.50),
		Vector2(0.60, 0.54),
		Vector2(0.48, 0.44),
		Vector2(0.30, 0.28),
		Vector2(0.14, 0.13),
	]
	var east_cols: Array[Color] = [col_upper, col_mid, col_mid, col_deep, col_shadow]
	_add_sculpted_column(st, east_centers, east_radii, east_cols, 9, 2.2, true, true)

	# 3. Slender Curved Connecting Stone Saddle Ridge joining West Peak & East Meadow
	var ridge_segs: int = 6
	var r_sections: Array[Array] = []
	var r_centers: Array[Vector3] = []
	var r_cols: Array[Color] = []

	for i: int in range(ridge_segs + 1):
		var t: float = float(i) / float(ridge_segs)
		var x_val: float = lerpf(-0.46, 0.48, t)
		var sag: float = sin(t * PI)
		var z_curve: float = lerpf(0.0, 0.10, t) + sag * 0.14
		var y_top: float = lerpf(0.02, 0.01, t) - sag * 0.09
		var y_bot: float = lerpf(-0.44, -0.38, t) + sag * 0.16
		var hz_top: float = lerpf(0.28, 0.28, t) - sag * 0.08
		var hz_bot: float = hz_top * 0.62
		var y_mid: float = lerpf(y_top, y_bot, 0.45)

		var sec: Array[Vector3] = [
			Vector3(x_val, y_top, z_curve - hz_top * 0.72),
			Vector3(x_val, y_top, z_curve + hz_top * 0.72),
			Vector3(x_val, y_mid, z_curve + hz_top * 1.02),
			Vector3(x_val, y_bot, z_curve + hz_bot * 0.65),
			Vector3(x_val, y_bot - 0.02, z_curve - hz_bot * 0.65),
			Vector3(x_val, y_mid, z_curve - hz_top * 1.02),
		]
		r_sections.append(sec)
		r_centers.append(Vector3(x_val, (y_top + y_bot) * 0.5, z_curve))
		r_cols.append(col_mid if sag > 0.3 else col_deep)

	_add_curved_ribbon(st, r_sections, r_centers, r_cols, false, false)

	return st.commit()


func _build_twin_peak_meadow_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Main lush emerald terrace on East sanctuary plateau
	_add_grass_slab(st, Vector3(0.62, 0.05, 0.10), 0.59, 0.53, 0.07, 10, 2.2, 0.0, 0.0)
	# Curved emerald grass ribbon across the connecting saddle ridge
	_add_grass_slab(st, Vector3(0.02, -0.05, 0.14), 0.44, 0.24, 0.06, 8, 0.9, 0.0, 0.0)
	# Perched high mossy shoulder patch on the West peak
	_add_grass_slab(st, Vector3(-0.34, 0.23, 0.06), 0.28, 0.25, 0.06, 8, 1.4, 0.04, 0.0)

	return st.commit()


# ---------------------------------------------------------------------------
# Archetype D — Sweeping Wind-Carved Crescent Crag
# Curved crescent-moon plateau with stratified horizontal cliff shelves & off-center swept tail
# ---------------------------------------------------------------------------

func _build_crescent_crag_rock_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var col_top: Color = Color("#ECE8DF")
	var col_upper: Color = Color("#DCD7CD")
	var col_mid: Color = Color("#C8C6BE")
	var col_deep: Color = Color("#B0B6C4")
	var col_tail: Color = Color("#9DA6B8")

	# 1. Sweeping 9-segment curved crescent-moon cliff body with stratified outer ribs
	var segs: int = 9
	var sections: Array[Array] = []
	var sec_centers: Array[Vector3] = []
	var sec_cols: Array[Color] = []

	for i: int in range(segs + 1):
		var t: float = float(i) / float(segs)
		# Sweep a bold C-crescent arc from -1.18 rad to +1.28 rad
		var ang: float = lerpf(-1.18, 1.28, t)
		var arc_r: float = 0.78 + sin(t * PI) * 0.06
		var cx: float = cos(ang) * arc_r
		var cz: float = sin(ang) * arc_r
		var rad_dir: Vector3 = Vector3(cos(ang), 0.0, sin(ang))

		# Thick proud head near t = 0.22, tapering gracefully toward the trailing horn at t = 1.0
		var head_weight: float = exp(-pow((t - 0.24) * 2.2, 2.0))
		var horn_taper: float = clampf(1.0 - pow(t, 1.65) * 0.76, 0.16, 1.0)
		var half_w: float = (0.24 + head_weight * 0.24) * horn_taper
		if t < 0.08:
			half_w *= lerpf(0.45, 1.0, t / 0.08)

		var y_top: float = lerpf(0.16, -0.06, t) + head_weight * 0.04
		var depth_here: float = (0.36 + head_weight * 0.56) * horn_taper
		var y_bot: float = y_top - depth_here
		var y_shelf: float = lerpf(y_top, y_bot, 0.42)
		var y_under: float = lerpf(y_top, y_bot, 0.74)

		# Stratified horizontal shelf rib protruding on the outer crescent face
		var shelf_out: float = half_w * 1.18
		var inner_w: float = half_w * 0.88
		var keel_w: float = half_w * 0.42

		var p0: Vector3 = Vector3(cx, y_top, cz) - rad_dir * (inner_w * 0.82)
		var p1: Vector3 = Vector3(cx, y_top + 0.015, cz) + rad_dir * (half_w * 0.92)
		var p2: Vector3 = Vector3(cx, y_shelf, cz) + rad_dir * shelf_out
		var p3: Vector3 = Vector3(cx, y_under, cz) + rad_dir * (half_w * 0.72)
		var p4: Vector3 = Vector3(cx, y_bot, cz) + rad_dir * (keel_w * 0.35)
		var p5: Vector3 = Vector3(cx, y_under, cz) - rad_dir * (inner_w * 0.65)
		var p6: Vector3 = Vector3(cx, y_shelf, cz) - rad_dir * (inner_w * 0.95)

		sections.append([p0, p1, p2, p3, p4, p5, p6])
		sec_centers.append(Vector3(cx, (y_top + y_bot) * 0.5, cz))
		sec_cols.append(col_upper if t < 0.45 else col_mid)

	_add_curved_ribbon(st, sections, sec_centers, sec_cols, true, true)

	# 2. Off-center Wind-Carved Swept Tail beneath the thick head of the crescent (Laputa / Pandora feel)
	var tail_centers: Array[Vector3] = [
		Vector3(0.46, -0.22, -0.46),
		Vector3(0.36, -0.58, -0.42),
		Vector3(0.22, -0.94, -0.34),
		Vector3(0.06, -1.28, -0.24),
	]
	var tail_radii: Array[Vector2] = [
		Vector2(0.34, 0.36),
		Vector2(0.24, 0.26),
		Vector2(0.14, 0.16),
		Vector2(0.05, 0.06),
	]
	var tail_cols: Array[Color] = [col_mid, col_deep, col_tail, col_tail]
	_add_sculpted_column(st, tail_centers, tail_radii, tail_cols, 7, 1.5, false, true)

	# 3. Secondary stratified cliff ledge jutting off the crescent head
	var ledge_centers: Array[Vector3] = [
		Vector3(0.56, 0.04, -0.52),
		Vector3(0.58, -0.08, -0.54),
		Vector3(0.52, -0.24, -0.48),
	]
	var ledge_radii: Array[Vector2] = [
		Vector2(0.32, 0.30),
		Vector2(0.36, 0.34),
		Vector2(0.26, 0.24),
	]
	_add_sculpted_column(st, ledge_centers, ledge_radii, [col_top, col_upper, col_mid], 7, 0.6, true, false)

	return st.commit()


func _build_crescent_crag_meadow_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Continuous curved crescent emerald carpet hugging the top of the crescent ridge
	var segs: int = 9
	var sections: Array[Array] = []
	var sec_centers: Array[Vector3] = []
	var sec_cols: Array[Color] = []

	for i: int in range(segs + 1):
		var t: float = float(i) / float(segs)
		var ang: float = lerpf(-1.14, 1.22, t)
		var arc_r: float = 0.78 + sin(t * PI) * 0.06
		var cx: float = cos(ang) * arc_r
		var cz: float = sin(ang) * arc_r
		var rad_dir: Vector3 = Vector3(cos(ang), 0.0, sin(ang))

		var head_weight: float = exp(-pow((t - 0.24) * 2.2, 2.0))
		var horn_taper: float = clampf(1.0 - pow(t, 1.65) * 0.76, 0.16, 1.0)
		var half_w: float = (0.25 + head_weight * 0.25) * horn_taper
		if t < 0.08:
			half_w *= lerpf(0.45, 1.0, t / 0.08)

		var y_base: float = lerpf(0.16, -0.06, t) + head_weight * 0.04
		var y_crown: float = y_base + 0.055
		var y_skirt: float = y_base - 0.055

		var p0: Vector3 = Vector3(cx, y_crown, cz) - rad_dir * (half_w * 0.55)
		var p1: Vector3 = Vector3(cx, y_crown + 0.015, cz) + rad_dir * (half_w * 0.55)
		var p2: Vector3 = Vector3(cx, y_skirt, cz) + rad_dir * (half_w * 1.02)
		var p3: Vector3 = Vector3(cx, y_skirt, cz) - rad_dir * (half_w * 0.94)

		sections.append([p0, p1, p2, p3])
		sec_centers.append(Vector3(cx, y_base, cz))
		sec_cols.append(Color("#FFFFFF") if t < 0.5 else Color("#EAF5EA"))

	_add_curved_ribbon(st, sections, sec_centers, sec_cols, true, true)

	return st.commit()


# ---------------------------------------------------------------------------
# Architectural & Nature Prop Meshes
# ---------------------------------------------------------------------------

func _build_spire_tower_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var col_limestone: Color = Color("#F2EFE8")
	var col_plinth: Color = Color("#E5E0D6")
	var col_roof_base: Color = Color("#447DC4")
	var col_roof_tip: Color = Color("#5A94DC")
	var col_gold: Color = Color("#F2C95A")

	_add_frustum(st, -0.18, 0.86, 0.55, 0.72, 8, Vector3.ZERO, col_plinth, false, true)
	_add_frustum(st, 0.55, 0.62, 2.42, 0.54, 8, Vector3.ZERO, col_limestone, false, false)
	_add_frustum(st, 2.40, 0.56, 2.66, 0.80, 8, Vector3.ZERO, col_limestone, false, true)
	_add_frustum(st, 2.64, 0.82, 2.74, 0.82, 8, Vector3.ZERO, col_gold, false, false)
	_add_frustum(st, 2.72, 0.80, 3.85, 0.34, 8, Vector3.ZERO, col_roof_base, false, false)
	_add_frustum(st, 3.85, 0.34, 4.78, 0.04, 8, Vector3.ZERO, col_roof_tip, false, true)
	_add_frustum(st, 4.74, 0.08, 5.42, 0.01, 6, Vector3.ZERO, col_gold, false, true)

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

	var pillar_xs: Array[float] = [-1.25, 1.25]
	for px: float in pillar_xs:
		_add_box(st, Vector3(px, 0.08, 0.0), Vector3(0.78, 0.56, 0.78), col_base)
		_add_box(st, Vector3(px, 1.40, 0.0), Vector3(0.54, 2.12, 0.54), col_marble)
		_add_box(st, Vector3(px, 2.54, 0.0), Vector3(0.68, 0.18, 0.68), col_gold)

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

		_add_quad(st, fi0, fo0, fo1, fi1, Vector3(0.0, 0.0, 1.0), seg_col)
		_add_quad(st, bi0, bi1, bo1, bo0, Vector3(0.0, 0.0, -1.0), seg_col)
		var mid_rad: Vector3 = Vector3((c0 + c1) * 0.5, (s0 + s1) * 0.5, 0.0)
		_add_quad(st, fo0, bo0, bo1, fo1, mid_rad, seg_col)
		_add_quad(st, fi0, fi1, bi1, bi0, -mid_rad, seg_col)

	_add_box(st, Vector3(0.0, 3.92, 0.0), Vector3(3.30, 0.24, 0.72), col_marble)
	_add_box(st, Vector3(0.0, 4.10, 0.0), Vector3(3.52, 0.14, 0.84), col_gold)

	return st.commit()


func _build_tree_crown_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	_add_frustum(st, -0.15, 0.14, 0.88, 0.09, 5, Vector3.ZERO, Color("#9C948A"), false, false)

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
		st.set_normal(nrm)
		st.set_color(c0)
		st.add_vertex(p_l0)
		st.set_normal(nrm)
		st.set_color(c0)
		st.add_vertex(p_r0)
		st.set_normal(nrm)
		st.set_color(c1)
		st.add_vertex(p_r1)

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
# Sculptural Geometry Helpers (Verified Outward Winding)
# ---------------------------------------------------------------------------

func _organic_rim_noise(angle: float, ring_idx: int, phase: float) -> float:
	var rf: float = float(ring_idx)
	var w1: float = sin(angle * 3.0 + phase + rf * 0.55) * 0.11
	var w2: float = cos(angle * 5.0 - phase * 0.7 + rf * 0.85) * 0.055
	var w3: float = sin(angle * 2.0 + phase * 1.3) * 0.05
	return 1.0 + w1 + w2 + w3


func _add_sculpted_column(
	st: SurfaceTool,
	centers: Array[Vector3],
	radii: Array[Vector2],
	cols: Array[Color],
	segs: int,
	phase: float,
	cap_top: bool,
	cap_bottom: bool
) -> void:
	var ring_count: int = centers.size()
	var rings: Array[Array] = []

	for r_idx: int in range(ring_count):
		var c: Vector3 = centers[r_idx]
		var rad: Vector2 = radii[r_idx]
		var pts: Array[Vector3] = []
		for s: int in range(segs):
			var ang: float = (float(s) / float(segs)) * TAU
			var mod: float = _organic_rim_noise(ang, r_idx, phase)
			var y_jit: float = sin(ang * 3.0 + phase + float(r_idx)) * 0.015 if r_idx > 0 else 0.0
			pts.append(Vector3(c.x + cos(ang) * rad.x * mod, c.y + y_jit, c.z + sin(ang) * rad.y * mod))
		rings.append(pts)

	for r_idx: int in range(ring_count - 1):
		var upper: Array = rings[r_idx]
		var lower: Array = rings[r_idx + 1]
		var c_up: Vector3 = centers[r_idx]
		var c_low: Vector3 = centers[r_idx + 1]
		var mid_c: Vector3 = (c_up + c_low) * 0.5
		var dy: float = maxf(c_up.y - c_low.y, 0.02)
		var dr: float = ((radii[r_idx + 1].x + radii[r_idx + 1].y) - (radii[r_idx].x + radii[r_idx].y)) * 0.5
		var col: Color = cols[r_idx]

		for s: int in range(segs):
			var next_s: int = (s + 1) % segs
			var u0: Vector3 = upper[s] as Vector3
			var u1: Vector3 = upper[next_s] as Vector3
			var l0: Vector3 = lower[s] as Vector3
			var l1: Vector3 = lower[next_s] as Vector3
			var qmid: Vector3 = (u0 + u1 + l0 + l1) * 0.25
			var radial: Vector3 = Vector3(qmid.x - mid_c.x, 0.0, qmid.z - mid_c.z)
			var rad_dir: Vector3 = radial.normalized() if radial.length_squared() > 0.0001 else Vector3.RIGHT
			var out_hint: Vector3 = rad_dir * dy + Vector3(0.0, dr, 0.0)
			_add_quad(st, u0, u1, l1, l0, out_hint, col)

	if cap_top and ring_count > 0:
		var tc: Vector3 = centers[0]
		var top_ring: Array = rings[0]
		var t_col: Color = cols[0]
		for s: int in range(segs):
			var next_s: int = (s + 1) % segs
			_add_tri(st, tc, top_ring[s] as Vector3, top_ring[next_s] as Vector3, Vector3.UP, t_col)

	if cap_bottom and ring_count > 0:
		var last_idx: int = ring_count - 1
		var bc: Vector3 = centers[last_idx] + Vector3(0.0, -0.04, 0.0)
		var bot_ring: Array = rings[last_idx]
		var b_col: Color = cols[last_idx]
		for s: int in range(segs):
			var next_s: int = (s + 1) % segs
			_add_tri(st, bc, bot_ring[s] as Vector3, bot_ring[next_s] as Vector3, Vector3.DOWN, b_col)


func _add_curved_ribbon(
	st: SurfaceTool,
	sections: Array[Array],
	sec_centers: Array[Vector3],
	sec_cols: Array[Color],
	cap_start: bool,
	cap_end: bool
) -> void:
	var sec_count: int = sections.size()
	if sec_count < 2:
		return
	var p_count: int = (sections[0] as Array).size()

	for i: int in range(sec_count - 1):
		var s0: Array = sections[i]
		var s1: Array = sections[i + 1]
		var mid_c: Vector3 = (sec_centers[i] + sec_centers[i + 1]) * 0.5
		var col: Color = sec_cols[i]

		for p: int in range(p_count):
			var next_p: int = (p + 1) % p_count
			var a0: Vector3 = s0[p] as Vector3
			var a1: Vector3 = s0[next_p] as Vector3
			var b0: Vector3 = s1[p] as Vector3
			var b1: Vector3 = s1[next_p] as Vector3
			var qmid: Vector3 = (a0 + a1 + b1 + b0) * 0.25
			var out_hint: Vector3 = qmid - mid_c
			_add_quad(st, a0, a1, b1, b0, out_hint, col)

	if cap_start:
		var start_hint: Vector3 = (sec_centers[0] - sec_centers[1]).normalized()
		var s_first: Array = sections[0]
		for p: int in range(p_count):
			var next_p: int = (p + 1) % p_count
			_add_tri(st, sec_centers[0], s_first[p] as Vector3, s_first[next_p] as Vector3, start_hint, sec_cols[0])

	if cap_end:
		var last_i: int = sec_count - 1
		var end_hint: Vector3 = (sec_centers[last_i] - sec_centers[last_i - 1]).normalized()
		var s_last: Array = sections[last_i]
		for p: int in range(p_count):
			var next_p: int = (p + 1) % p_count
			_add_tri(st, sec_centers[last_i], s_last[p] as Vector3, s_last[next_p] as Vector3, end_hint, sec_cols[last_i])


func _add_grass_slab(
	st: SurfaceTool,
	center: Vector3,
	rx: float,
	rz: float,
	thickness: float,
	segs: int,
	phase: float,
	tilt_x: float,
	tilt_z: float
) -> void:
	var skirt_pts: Array[Vector3] = []
	var rim_pts: Array[Vector3] = []

	for s: int in range(segs):
		var ang: float = (float(s) / float(segs)) * TAU
		var mod: float = _organic_rim_noise(ang, 0, phase)
		var ox: float = cos(ang) * rx * mod
		var oz: float = sin(ang) * rz * mod
		var tilt_y: float = ox * tilt_x + oz * tilt_z
		skirt_pts.append(Vector3(center.x + ox * 1.03, center.y - thickness + tilt_y, center.z + oz * 1.03))
		rim_pts.append(Vector3(center.x + ox * 0.90, center.y + 0.025 + tilt_y, center.z + oz * 0.90))

	var top_center: Vector3 = Vector3(center.x, center.y + 0.055, center.z)
	var col_skirt: Color = Color("#CFE6D2")
	var col_top: Color = Color("#FFFFFF")

	for s: int in range(segs):
		var next_s: int = (s + 1) % segs
		var sk0: Vector3 = skirt_pts[s]
		var sk1: Vector3 = skirt_pts[next_s]
		var rm0: Vector3 = rim_pts[s]
		var rm1: Vector3 = rim_pts[next_s]
		var mid: Vector3 = (sk0 + sk1 + rm0 + rm1) * 0.25 - center
		var out_hint: Vector3 = Vector3(mid.x, 0.35, mid.z)
		_add_quad(st, sk0, rm0, rm1, sk1, out_hint, col_skirt)
		_add_tri(st, top_center, rm0, rm1, Vector3.UP, col_top)


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

	var top_ring: Array = ring_pts[0]
	for s: int in range(segs):
		var next_s: int = (s + 1) % segs
		var p0: Vector3 = top_ring[s] as Vector3
		var p1: Vector3 = top_ring[next_s] as Vector3
		var out_hint: Vector3 = ((north_pole + p0 + p1) * 0.333333) - center
		_add_tri(st, north_pole, p0, p1, out_hint, Color("#FFFFFF"))

	for r: int in range(ring_pts.size() - 1):
		var upper: Array = ring_pts[r]
		var lower: Array = ring_pts[r + 1]
		var shade: float = lerpf(0.95, 0.78, float(r) / maxf(float(ring_pts.size() - 1), 1.0))
		var band_col: Color = Color(shade, shade + 0.02, shade + 0.03, 1.0)
		for s: int in range(segs):
			var next_s: int = (s + 1) % segs
			var u0: Vector3 = upper[s] as Vector3
			var u1: Vector3 = upper[next_s] as Vector3
			var l0: Vector3 = lower[s] as Vector3
			var l1: Vector3 = lower[next_s] as Vector3
			var out_hint: Vector3 = ((u0 + u1 + l0 + l1) * 0.25) - center
			_add_quad(st, u0, u1, l1, l0, out_hint, band_col)

	var bot_ring: Array = ring_pts[ring_pts.size() - 1]
	for s: int in range(segs):
		var next_s: int = (s + 1) % segs
		var b0: Vector3 = bot_ring[s] as Vector3
		var b1: Vector3 = bot_ring[next_s] as Vector3
		var out_hint: Vector3 = ((south_pole + b0 + b1) * 0.333333) - center
		_add_tri(st, b0, b1, south_pole, out_hint, Color("#B6C0C6"))
