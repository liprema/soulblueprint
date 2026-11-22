class_name CloudSea
extends Node3D

## Procedurally populates a photorealistic, multi-tiered 3D cumulus cloudscape using a
## sculpted 5-lobe organic cumulus ArrayMesh (~772 tris) and cloud_puff.gdshader:
## billowing cloud sea floor, under-viaduct arch billows, flanking cumulus canyon towers,
## Cathedral cloud amphitheater, and high celestial wisps, keeping a crystal-clear central
## flight corridor along -Z (z=50 to z=-320).

@export var cloud_shader: Shader = preload("res://shaders/cloud_puff.gdshader")
@export var seed_value: int = 4242

@export_group("Flight Corridor")
@export var corridor_z_start: float = 50.0
@export var corridor_z_end: float = -320.0
@export var corridor_half_width: float = 64.0

@export_group("Cloud Sea Floor")
@export var sea_floor_y: float = -44.0
@export var floor_cluster_count: int = 13
@export var floor_x_extent: float = 215.0

@export_group("Under-Viaduct Billows")
@export var viaduct_x_offset: float = 56.0
@export var viaduct_billows_per_side: int = 4
@export var viaduct_billow_min_y: float = -38.0
@export var viaduct_billow_max_y: float = -26.0

@export_group("Flanking Cloud Canyon")
@export var canyon_clusters_per_side: int = 8
@export var canyon_inner_x: float = 76.0
@export var canyon_outer_x: float = 166.0
@export var canyon_min_y: float = -22.0
@export var canyon_max_y: float = 24.0

@export_group("Cathedral Cloud Amphitheater")
@export var cathedral_cloud_count: int = 6

@export_group("High Celestial Wisps")
@export var high_wisp_count: int = 5

@export_group("Animation")
@export var bob_amplitude_scale: float = 1.0
@export var bob_speed_scale: float = 1.0
@export var drift_amplitude_scale: float = 1.0

var _shared_mesh: ArrayMesh
var _shared_material: ShaderMaterial
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _clusters: Array[Node3D] = []
var _base_positions: PackedVector3Array = PackedVector3Array()
var _bob_amplitudes: PackedFloat32Array = PackedFloat32Array()
var _bob_speeds: PackedFloat32Array = PackedFloat32Array()
var _bob_phases: PackedFloat32Array = PackedFloat32Array()
var _sway_amplitudes: PackedFloat32Array = PackedFloat32Array()
var _drift_z_amplitudes: PackedFloat32Array = PackedFloat32Array()
var _drift_speeds: PackedFloat32Array = PackedFloat32Array()
var _elapsed_time: float = 0.0
var _total_puff_count: int = 0


func _ready() -> void:
	_setup_shared_resources()
	_populate_cloudscape()


func _setup_shared_resources() -> void:
	_shared_mesh = _build_sculpted_cumulus_mesh()

	_shared_material = ShaderMaterial.new()
	_shared_material.shader = cloud_shader


func _build_sculpted_cumulus_mesh() -> ArrayMesh:
	## Procedurally fuses 5 overlapping bumpy noise-displaced organic cloud lobes into a
	## single clean smooth ArrayMesh (~772 triangles total):
	##   1 broad flat-bottomed cumulus base + 3 rising cauliflower side-domes + 1 billowing crown dome.
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.fractal_lacunarity = 2.1
	noise.fractal_gain = 0.48
	noise.frequency = 1.15
	noise.seed = 1337

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Lobe 0: Broad flat-bottomed cumulus condensation base (14x8 -> 196 tris)
	_append_sculpted_lobe(
		st,
		noise,
		Vector3(0.0, -0.18, 0.0),
		Vector3(1.18, 0.56, 1.12),
		14,
		8,
		0.36,
		1.0
	)
	# Lobe 1: Rising cauliflower side-dome (front-left shoulder, 12x7 -> 144 tris)
	_append_sculpted_lobe(
		st,
		noise,
		Vector3(-0.62, 0.16, 0.24),
		Vector3(0.64, 0.62, 0.60),
		12,
		7,
		0.55,
		1.08
	)
	# Lobe 2: Rising cauliflower side-dome (front-right shoulder, 12x7 -> 144 tris)
	_append_sculpted_lobe(
		st,
		noise,
		Vector3(0.58, 0.22, 0.34),
		Vector3(0.58, 0.68, 0.56),
		12,
		7,
		0.55,
		1.12
	)
	# Lobe 3: Rising cauliflower side-dome (rear shoulder, 12x7 -> 144 tris)
	_append_sculpted_lobe(
		st,
		noise,
		Vector3(0.08, 0.14, -0.60),
		Vector3(0.62, 0.58, 0.64),
		12,
		7,
		0.52,
		1.05
	)
	# Lobe 4: Billowing crown dome crowning the sunlit summit (12x7 -> 144 tris)
	_append_sculpted_lobe(
		st,
		noise,
		Vector3(-0.04, 0.54, 0.04),
		Vector3(0.56, 0.66, 0.54),
		12,
		7,
		0.70,
		1.15
	)

	st.index()
	return st.commit()


func _append_sculpted_lobe(
	st: SurfaceTool,
	noise: FastNoiseLite,
	center: Vector3,
	radii: Vector3,
	sectors: int,
	rings: int,
	flat_bottom_scale: float,
	bump_strength: float
) -> void:
	var cols: int = sectors + 1
	var rows: int = rings + 1
	var vert_count: int = cols * rows

	var positions: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var smooth_normals: PackedVector3Array = PackedVector3Array()
	positions.resize(vert_count)
	uvs.resize(vert_count)
	smooth_normals.resize(vert_count)

	for r: int in range(rows):
		var v_frac: float = float(r) / float(rings)
		var theta: float = v_frac * PI
		var sin_t: float = sin(theta)
		var cos_t: float = cos(theta)

		for s: int in range(cols):
			var u_frac: float = float(s) / float(sectors)
			var phi: float = u_frac * TAU
			var dir: Vector3 = Vector3(sin_t * cos(phi), cos_t, sin_t * sin(phi))

			var local_p: Vector3 = Vector3(dir.x * radii.x, dir.y * radii.y, dir.z * radii.z)
			if local_p.y < 0.0:
				local_p.y *= flat_bottom_scale

			var p: Vector3 = center + local_p
			var n_primary: float = noise.get_noise_3dv(p * 1.45)
			var n_detail: float = noise.get_noise_3dv(p * 2.85 + Vector3(7.3, -4.1, 5.7))
			var up_factor: float = clampf((dir.y + 0.35) * 0.85, 0.22, 1.0)
			var disp: float = (n_primary * 0.19 + n_detail * 0.08) * bump_strength * up_factor
			p += dir * disp

			# Shared meteorological condensation level so fused lobes share a natural flat underside
			if p.y < -0.42:
				p.y = -0.42 + (p.y + 0.42) * 0.32

			var idx: int = r * cols + s
			positions[idx] = p
			uvs[idx] = Vector2(u_frac, v_frac)
			smooth_normals[idx] = Vector3.ZERO

	# Collect triangle indices (skipping degenerate pole caps) and accumulate outward face normals
	var tri_indices: PackedInt32Array = PackedInt32Array()
	for r: int in range(rings):
		for s: int in range(sectors):
			var i00: int = r * cols + s
			var i01: int = r * cols + (s + 1)
			var i10: int = (r + 1) * cols + s
			var i11: int = (r + 1) * cols + (s + 1)

			if r == 0:
				_accumulate_tri(tri_indices, positions, smooth_normals, i00, i10, i11, center)
			elif r == rings - 1:
				_accumulate_tri(tri_indices, positions, smooth_normals, i00, i10, i01, center)
			else:
				_accumulate_tri(tri_indices, positions, smooth_normals, i00, i10, i01, center)
				_accumulate_tri(tri_indices, positions, smooth_normals, i10, i11, i01, center)

	# Weld seam normals along longitude u = 0 and u = 1 so there is zero lighting crease
	for r: int in range(rows):
		var left_idx: int = r * cols
		var right_idx: int = r * cols + sectors
		var welded: Vector3 = smooth_normals[left_idx] + smooth_normals[right_idx]
		smooth_normals[left_idx] = welded
		smooth_normals[right_idx] = welded

	# Blend geometric lobe normal with macro cumulus radial normal for unified volumetric shading
	var macro_center: Vector3 = Vector3(0.0, -0.14, 0.0)
	for i: int in range(vert_count):
		var geo_n: Vector3 = smooth_normals[i]
		var macro_n: Vector3 = (positions[i] - macro_center).normalized()
		if geo_n.length_squared() < 0.0001:
			geo_n = macro_n
		else:
			geo_n = geo_n.normalized()
		smooth_normals[i] = geo_n.lerp(macro_n, 0.28).normalized()

	var tri_count: int = tri_indices.size()
	for k: int in range(tri_count):
		var v_idx: int = tri_indices[k]
		st.set_normal(smooth_normals[v_idx])
		st.set_uv(uvs[v_idx])
		st.add_vertex(positions[v_idx])


func _accumulate_tri(
	tri_indices: PackedInt32Array,
	positions: PackedVector3Array,
	smooth_normals: PackedVector3Array,
	ia: int,
	ib: int,
	ic: int,
	lobe_center: Vector3
) -> void:
	var pa: Vector3 = positions[ia]
	var pb: Vector3 = positions[ib]
	var pc: Vector3 = positions[ic]
	var face_n: Vector3 = (pc - pa).cross(pb - pa)
	var centroid_dir: Vector3 = ((pa + pb + pc) * 0.3333333) - lobe_center
	if face_n.dot(centroid_dir) < 0.0:
		face_n = -face_n
	smooth_normals[ia] += face_n
	smooth_normals[ib] += face_n
	smooth_normals[ic] += face_n
	tri_indices.append(ia)
	tri_indices.append(ib)
	tri_indices.append(ic)


func _populate_cloudscape() -> void:
	_rng.seed = seed_value
	_clusters.clear()
	_base_positions.clear()
	_bob_amplitudes.clear()
	_bob_speeds.clear()
	_bob_phases.clear()
	_sway_amplitudes.clear()
	_drift_z_amplitudes.clear()
	_drift_speeds.clear()
	_total_puff_count = 0

	_generate_sea_floor()
	_generate_viaduct_billows(-1.0)
	_generate_viaduct_billows(1.0)
	_generate_canyon_wall(-1.0)
	_generate_canyon_wall(1.0)
	_generate_cathedral_amphitheater()
	_generate_high_wisps()


func _generate_sea_floor() -> void:
	var z_front: float = corridor_z_start + 36.0
	var z_back: float = corridor_z_end - 65.0

	for i: int in range(floor_cluster_count):
		var t: float = float(i) / maxf(float(floor_cluster_count - 1), 1.0)
		var z_pos: float = lerpf(z_front, z_back, t) + _rng.randf_range(-16.0, 16.0)
		var x_pos: float = _rng.randf_range(-floor_x_extent, floor_x_extent)
		var y_pos: float = sea_floor_y + _rng.randf_range(-10.0, 4.0)

		# Keep sea floor tucked well below the central flight corridor for zero whiteout/haze
		if absf(x_pos) < corridor_half_width:
			y_pos -= _rng.randf_range(5.0, 11.0)

		var base_scale: Vector3 = Vector3(
			_rng.randf_range(21.0, 38.0),
			_rng.randf_range(8.5, 14.5),
			_rng.randf_range(21.0, 37.0)
		)
		var puff_count: int = 3
		_spawn_cumulus_tower(
			"SeaFloor_%02d" % i,
			Vector3(x_pos, y_pos, z_pos),
			base_scale,
			puff_count,
			0.52,
			0.75,
			1.65,
			0.07,
			0.18
		)


func _generate_viaduct_billows(side_sign: float) -> void:
	# Gentle lower cloud billows drifting softly beneath the twin viaduct arches (x = +/-56, y = -26..-38)
	var side_label: String = "Left" if side_sign < 0.0 else "Right"
	var z_start: float = 24.0
	var z_end: float = -215.0

	for i: int in range(viaduct_billows_per_side):
		var t: float = float(i) / maxf(float(viaduct_billows_per_side - 1), 1.0)
		var z_pos: float = lerpf(z_start, z_end, t) + _rng.randf_range(-12.0, 12.0)
		var x_mag: float = viaduct_x_offset + _rng.randf_range(-6.0, 9.0)
		var x_pos: float = side_sign * x_mag
		var y_pos: float = _rng.randf_range(viaduct_billow_min_y, viaduct_billow_max_y)

		var base_scale: Vector3 = Vector3(
			_rng.randf_range(12.5, 19.5),
			_rng.randf_range(4.8, 7.8),
			_rng.randf_range(13.5, 21.5)
		)
		var puff_count: int = 2
		_spawn_stratified_cloud(
			"ViaductBillow_%s_%02d" % [side_label, i],
			Vector3(x_pos, y_pos, z_pos),
			base_scale,
			puff_count,
			0.65,
			1.35,
			0.14,
			0.28
		)


func _generate_canyon_wall(side_sign: float) -> void:
	# Dramatic multi-tiered cumulus towers flanking outside the twin viaducts
	var side_label: String = "Left" if side_sign < 0.0 else "Right"
	var safe_inner_x: float = maxf(corridor_half_width + 12.0, canyon_inner_x)

	for i: int in range(canyon_clusters_per_side):
		var t: float = float(i) / maxf(float(canyon_clusters_per_side - 1), 1.0)
		var z_pos: float = lerpf(corridor_z_start + 10.0, corridor_z_end - 12.0, t) + _rng.randf_range(-9.0, 9.0)

		# Widen the canyon gracefully as the player approaches the Castle / Cathedral near z = -280
		var cathedral_flare: float = smoothstep(0.65, 1.0, t) * 34.0
		var tier_ratio: float = _rng.randf()
		var inner_margin: float = safe_inner_x + cathedral_flare
		var x_mag: float = lerpf(inner_margin, canyon_outer_x + cathedral_flare, tier_ratio)
		var x_pos: float = side_sign * x_mag

		# Higher billowing cumulus ridges further from the corridor center for grand aerial framing
		var y_pos: float = lerpf(canyon_min_y, canyon_max_y, pow(tier_ratio, 0.74)) + _rng.randf_range(-6.0, 8.0)

		var base_scale: Vector3 = Vector3(
			_rng.randf_range(18.5, 31.5),
			_rng.randf_range(11.0, 19.0),
			_rng.randf_range(19.5, 32.5)
		)
		var puff_count: int = _rng.randi_range(3, 4)
		_spawn_cumulus_tower(
			"Canyon_%s_%02d" % [side_label, i],
			Vector3(x_pos, y_pos, z_pos),
			base_scale,
			puff_count,
			1.02,
			0.95,
			2.15,
			0.10,
			0.26
		)


func _generate_cathedral_amphitheater() -> void:
	# Sweeping sunlit cumulus towers embracing the lower base & flanks of the Castle at z = -280
	# Radius 104..164m frames the Floating Castle Island, lakes, and waterfalls cleanly with zero clipping
	for i: int in range(cathedral_cloud_count):
		var t: float = float(i) / maxf(float(cathedral_cloud_count - 1), 1.0)
		var angle: float = lerpf(-0.84 * PI, -0.16 * PI, t)
		var radius: float = _rng.randf_range(104.0, 164.0)
		var x_pos: float = cos(angle) * radius
		var z_pos: float = -280.0 + sin(angle) * (radius * 0.54)
		var y_pos: float = lerpf(-22.0, 26.0, absf(cos(angle))) + _rng.randf_range(-7.0, 10.0)

		var base_scale: Vector3 = Vector3(
			_rng.randf_range(24.0, 40.0),
			_rng.randf_range(13.0, 22.0),
			_rng.randf_range(22.0, 36.0)
		)
		var puff_count: int = _rng.randi_range(3, 4)
		_spawn_cumulus_tower(
			"CathedralBank_%02d" % i,
			Vector3(x_pos, y_pos, z_pos),
			base_scale,
			puff_count,
			1.12,
			0.85,
			1.75,
			0.05,
			0.14
		)


func _generate_high_wisps() -> void:
	var safe_inner_x: float = maxf(corridor_half_width + 10.0, canyon_inner_x)

	for i: int in range(high_wisp_count):
		var side_sign: float = -1.0 if (i % 2 == 0) else 1.0
		var t: float = float(i) / maxf(float(high_wisp_count - 1), 1.0)
		var z_pos: float = lerpf(corridor_z_start, corridor_z_end - 40.0, t) + _rng.randf_range(-16.0, 16.0)
		var x_pos: float = side_sign * _rng.randf_range(safe_inner_x, canyon_outer_x + 34.0)
		var y_pos: float = _rng.randf_range(62.0, 98.0)

		var base_scale: Vector3 = Vector3(
			_rng.randf_range(22.0, 38.0),
			_rng.randf_range(4.4, 8.2),
			_rng.randf_range(17.0, 28.0)
		)
		var puff_count: int = 2
		_spawn_stratified_cloud(
			"HighWisp_%02d" % i,
			Vector3(x_pos, y_pos, z_pos),
			base_scale,
			puff_count,
			1.3,
			2.6,
			0.18,
			0.40
		)


func _spawn_cumulus_tower(
	cluster_name: String,
	origin: Vector3,
	base_scale: Vector3,
	puff_count: int,
	tower_height_factor: float,
	bob_min: float,
	bob_max: float,
	drift_speed_min: float,
	drift_speed_max: float
) -> void:
	## Builds a towering multi-tiered cumulus formation from 3-4 sculpted 5-lobe cumulus instances
	## (15-20 organic lobes per tower with minimal transparent overdraw):
	## Tier 1: Wide flat-bottomed cumulus deck.
	## Tier 2: Rising billowing shoulder formation.
	## Tier 3: Sunlit cumulus congestus summit crown.
	var cluster: Node3D = Node3D.new()
	cluster.name = cluster_name
	cluster.position = origin
	add_child(cluster)

	var clamped_count: int = maxi(puff_count, 3)
	var base_lobes: int = 2 if clamped_count >= 4 else 1
	var remaining: int = clamped_count - base_lobes
	var crown_turrets: int = maxi(1, int(floor(float(remaining) * 0.5)))
	var mid_domes: int = maxi(1, remaining - crown_turrets)

	var base_angle_offset: float = _rng.randf_range(0.0, TAU)

	# Tier 1: Flat-bottomed wide base formations
	for b: int in range(base_lobes):
		var pos: Vector3 = Vector3.ZERO
		var scl: Vector3 = base_scale
		if b == 0:
			scl = Vector3(base_scale.x * 1.06, base_scale.y * 0.88, base_scale.z * 1.04)
		else:
			var angle: float = base_angle_offset + (float(b - 1) / maxf(float(base_lobes - 1), 1.0)) * TAU + _rng.randf_range(-0.45, 0.45)
			var dist: float = _rng.randf_range(0.54, 0.86)
			pos = Vector3(
				cos(angle) * base_scale.x * dist,
				_rng.randf_range(-0.12, 0.08) * base_scale.y,
				sin(angle) * base_scale.z * dist
			)
			var factor: float = _rng.randf_range(0.72, 0.92)
			scl = Vector3(
				base_scale.x * factor * _rng.randf_range(0.92, 1.15),
				base_scale.y * factor * _rng.randf_range(0.74, 0.94),
				base_scale.z * factor * _rng.randf_range(0.92, 1.15)
			)
		_add_puff_mesh(cluster, pos, scl, 0.10)

	# Tier 2: Rising rounded billowing mid-formation
	var mid_angle_offset: float = base_angle_offset + _rng.randf_range(0.5, 1.6)
	for m: int in range(mid_domes):
		var angle: float = mid_angle_offset + (float(m) / maxf(float(mid_domes), 1.0)) * TAU + _rng.randf_range(-0.4, 0.4)
		var dist: float = _rng.randf_range(0.24, 0.56) if mid_domes > 1 else _rng.randf_range(0.10, 0.28)
		var pos: Vector3 = Vector3(
			cos(angle) * base_scale.x * dist,
			_rng.randf_range(0.30, 0.56) * base_scale.y * tower_height_factor,
			sin(angle) * base_scale.z * dist
		)
		var factor: float = _rng.randf_range(0.62, 0.82)
		var scl: Vector3 = Vector3(
			base_scale.x * factor * _rng.randf_range(0.88, 1.08),
			base_scale.y * factor * _rng.randf_range(0.96, 1.22) * tower_height_factor,
			base_scale.z * factor * _rng.randf_range(0.88, 1.08)
		)
		_add_puff_mesh(cluster, pos, scl, 0.14)

	# Tier 3: Sunlit summit crown formation
	var crown_angle_offset: float = mid_angle_offset + _rng.randf_range(0.4, 1.4)
	for c: int in range(crown_turrets):
		var angle: float = crown_angle_offset + (float(c) / maxf(float(crown_turrets), 1.0)) * TAU + _rng.randf_range(-0.35, 0.35)
		var dist: float = _rng.randf_range(0.08, 0.30) if crown_turrets > 1 else _rng.randf_range(0.0, 0.16)
		var pos: Vector3 = Vector3(
			cos(angle) * base_scale.x * dist,
			_rng.randf_range(0.60, 0.90) * base_scale.y * tower_height_factor,
			sin(angle) * base_scale.z * dist
		)
		var factor: float = _rng.randf_range(0.44, 0.62)
		var scl: Vector3 = Vector3(
			base_scale.x * factor * _rng.randf_range(0.84, 1.06),
			base_scale.y * factor * _rng.randf_range(1.02, 1.32) * tower_height_factor,
			base_scale.z * factor * _rng.randf_range(0.84, 1.06)
		)
		_add_puff_mesh(cluster, pos, scl, 0.18)

	_register_cluster(cluster, origin, bob_min, bob_max, drift_speed_min, drift_speed_max)


func _spawn_stratified_cloud(
	cluster_name: String,
	origin: Vector3,
	base_scale: Vector3,
	puff_count: int,
	bob_min: float,
	bob_max: float,
	drift_speed_min: float,
	drift_speed_max: float
) -> void:
	## Builds a softer horizontal cloud bank / wisp cluster (for under-viaduct billows & high celestial wisps).
	var cluster: Node3D = Node3D.new()
	cluster.name = cluster_name
	cluster.position = origin
	add_child(cluster)

	var angle_offset: float = _rng.randf_range(0.0, TAU)
	for p: int in range(puff_count):
		var pos: Vector3 = Vector3.ZERO
		var scl: Vector3 = base_scale
		if p > 0:
			var angle: float = angle_offset + (float(p - 1) / maxf(float(puff_count - 1), 1.0)) * TAU + _rng.randf_range(-0.4, 0.4)
			var dist: float = _rng.randf_range(0.52, 0.88)
			pos = Vector3(
				cos(angle) * base_scale.x * dist,
				_rng.randf_range(-0.16, 0.24) * base_scale.y,
				sin(angle) * base_scale.z * dist
			)
			var factor: float = _rng.randf_range(0.58, 0.86)
			scl = Vector3(
				base_scale.x * factor * _rng.randf_range(0.90, 1.18),
				base_scale.y * factor * _rng.randf_range(0.76, 1.06),
				base_scale.z * factor * _rng.randf_range(0.90, 1.18)
			)
		_add_puff_mesh(cluster, pos, scl, 0.12)

	_register_cluster(cluster, origin, bob_min, bob_max, drift_speed_min, drift_speed_max)


func _add_puff_mesh(cluster: Node3D, local_pos: Vector3, local_scale: Vector3, tilt_max: float) -> void:
	var puff: MeshInstance3D = MeshInstance3D.new()
	puff.mesh = _shared_mesh
	puff.material_override = _shared_material
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	puff.position = local_pos
	puff.scale = local_scale
	puff.rotation = Vector3(
		_rng.randf_range(-tilt_max, tilt_max),
		_rng.randf_range(0.0, TAU),
		_rng.randf_range(-tilt_max, tilt_max)
	)
	cluster.add_child(puff)
	_total_puff_count += 1


func _register_cluster(
	cluster: Node3D,
	origin: Vector3,
	bob_min: float,
	bob_max: float,
	drift_speed_min: float,
	drift_speed_max: float
) -> void:
	_clusters.append(cluster)
	_base_positions.append(origin)
	_bob_amplitudes.append(_rng.randf_range(bob_min, bob_max))
	_bob_speeds.append(_rng.randf_range(0.18, 0.48))
	_bob_phases.append(_rng.randf_range(0.0, TAU))
	_sway_amplitudes.append(_rng.randf_range(0.9, 3.0))
	_drift_z_amplitudes.append(_rng.randf_range(0.6, 2.2))
	_drift_speeds.append(_rng.randf_range(drift_speed_min, drift_speed_max))


func _process(delta: float) -> void:
	_elapsed_time += delta * bob_speed_scale
	var count: int = _clusters.size()

	for i: int in range(count):
		var phase: float = _bob_phases[i]
		var speed: float = _bob_speeds[i]
		var d_speed: float = _drift_speeds[i]
		var base_pos: Vector3 = _base_positions[i]
		var bob_y: float = sin(_elapsed_time * speed + phase) * _bob_amplitudes[i] * bob_amplitude_scale
		var sway_x: float = cos(_elapsed_time * d_speed + phase) * _sway_amplitudes[i] * drift_amplitude_scale
		var drift_z: float = sin(_elapsed_time * (d_speed * 0.72) + phase * 1.3) * _drift_z_amplitudes[i] * drift_amplitude_scale
		_clusters[i].position = Vector3(base_pos.x + sway_x, base_pos.y + bob_y, base_pos.z + drift_z)
