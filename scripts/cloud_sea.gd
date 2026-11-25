class_name CloudSea
extends Node3D

## Procedurally populates an ultra-soft, plush cotton-wool & pastel cotton-candy 3D cloudscape
## using a silky-smooth 6-lobe rounded cumulus ArrayMesh (~1,952 tris) and cloud_puff.gdshader:
## dreamy sakura-blush cloud sea floor, under-viaduct billows, flanking cumulus canyon towers,
## Cathedral cloud amphitheater, and plump snow-cream floating sky clouds, keeping a crystal-clear
## central flight corridor along -Z (z=50 to z=-320).

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

@export_group("High Celestial Clouds")
@export var high_wisp_count: int = 18

@export_group("Animation")
@export var bob_amplitude_scale: float = 1.0
@export var bob_speed_scale: float = 1.0
@export var drift_amplitude_scale: float = 1.0

var _shared_mesh: ArrayMesh
var _material_cotton_white: ShaderMaterial
var _material_cotton_blush: ShaderMaterial
var _material_cotton_sakura: ShaderMaterial
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
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_setup_shared_resources()
	_populate_cloudscape()


func _setup_shared_resources() -> void:
	_shared_mesh = _build_plush_cumulus_mesh()

	# 1. Plush snow-cream cotton-wool (floating sky clouds & sunlit upper crowns)
	_material_cotton_white = _create_cloud_material(
		Color(0.698, 0.745, 0.878, 1.0),  # #B2BEE0 Gentle periwinkle-lavender cushion shadow
		Color(0.812, 0.847, 0.941, 1.0),  # #CFD8F0 Airy powder-periwinkle mid-shadow
		Color(0.976, 0.933, 0.957, 1.0),  # #F9EEF4 Soft pastel blush-pearl midtone
		Color(1.000, 0.992, 0.976, 1.0),  # #FFFDF9 Warm sunlit ivory-cream crown
		Color(1.000, 0.976, 0.945, 1.0),  # #FFF9F1 Plush backlit cotton-wool velvet halo
		Color(1.000, 0.839, 0.871, 1.0)   # #FFD6DE Soft sakura-peach horizon bounce
	)

	# 2. Soft cream-to-blush transitional cumulus (mid-canyon & under-viaduct billows)
	_material_cotton_blush = _create_cloud_material(
		Color(0.784, 0.729, 0.867, 1.0),  # #C8BADD Soft lavender-rose cushion shadow
		Color(0.878, 0.816, 0.918, 1.0),  # #E0D0EA Pastel lilac-blush mid-shadow
		Color(0.992, 0.894, 0.925, 1.0),  # #FDE4EC Delicate rose-quartz pearl midtone
		Color(1.000, 0.984, 0.976, 1.0),  # #FFFBF9 Warm cream-ivory crown
		Color(1.000, 0.953, 0.949, 1.0),  # #FFF3F2 Velvety blush-cream rim halo
		Color(1.000, 0.816, 0.855, 1.0)   # #FFD0DA Warm sakura-pink horizon bounce
	)

	# 3. Dreamy pastel sakura-pink & peach cotton-candy (horizon sea & Cathedral banks)
	_material_cotton_sakura = _create_cloud_material(
		Color(0.824, 0.678, 0.812, 1.0),  # #D2ADCF Soft rose-lavender cushion shadow
		Color(0.922, 0.733, 0.835, 1.0),  # #EBBBD5 Pastel orchid-pink mid-shadow
		Color(1.000, 0.827, 0.886, 1.0),  # #FFD3E2 Dreamy cotton-candy sakura midtone
		Color(1.000, 0.957, 0.969, 1.0),  # #FFF4F7 Sunlit pastel-pink cream crown
		Color(1.000, 0.922, 0.941, 1.0),  # #FFEBF0 Plush backlit cotton-candy halo
		Color(1.000, 0.812, 0.788, 1.0)   # #FFCFCA Warm peach-blush horizon bounce
	)


func _create_cloud_material(
	underside: Color,
	shadow: Color,
	mid: Color,
	sunlit: Color,
	rim: Color,
	bounce: Color
) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = cloud_shader
	mat.set_shader_parameter("underside_color", underside)
	mat.set_shader_parameter("shadow_color", shadow)
	mat.set_shader_parameter("mid_color", mid)
	mat.set_shader_parameter("sunlit_color", sunlit)
	mat.set_shader_parameter("silver_lining_color", rim)
	mat.set_shader_parameter("horizon_bounce_color", bounce)
	return mat


func _build_plush_cumulus_mesh() -> ArrayMesh:
	## Procedurally fuses 6 silky-smooth, overlapping rounded cotton-wool cushions into a
	## single clean ArrayMesh (1,952 triangles total, zero sharp creases or faceted planes):
	##   1 broad pillowy base cushion + 4 plump rounded side cushions + 1 sunlit crown dome.
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	noise.frequency = 0.52
	noise.seed = 1337

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Lobe 0: Broad pillowy base cushion (20x12 -> 440 tris)
	_append_plush_lobe(
		st,
		noise,
		Vector3(0.0, -0.14, 0.0),
		Vector3(1.12, 0.62, 1.06),
		20,
		12,
		0.62,
		1.0
	)
	# Lobe 1: Plump left cotton cushion (16x10 -> 288 tris)
	_append_plush_lobe(
		st,
		noise,
		Vector3(-0.66, 0.08, 0.14),
		Vector3(0.64, 0.60, 0.62),
		16,
		10,
		0.72,
		1.0
	)
	# Lobe 2: Plump right cotton cushion (16x10 -> 288 tris)
	_append_plush_lobe(
		st,
		noise,
		Vector3(0.64, 0.12, 0.18),
		Vector3(0.60, 0.62, 0.58),
		16,
		10,
		0.72,
		1.0
	)
	# Lobe 3: Plump rear-left cotton cushion (16x10 -> 288 tris)
	_append_plush_lobe(
		st,
		noise,
		Vector3(-0.22, 0.10, -0.56),
		Vector3(0.60, 0.58, 0.60),
		16,
		10,
		0.72,
		1.0
	)
	# Lobe 4: Plump rear-right cotton cushion (16x10 -> 288 tris)
	_append_plush_lobe(
		st,
		noise,
		Vector3(0.30, 0.08, -0.52),
		Vector3(0.58, 0.56, 0.58),
		16,
		10,
		0.72,
		1.0
	)
	# Lobe 5: Plump sunlit summit crown dome (18x11 -> 360 tris)
	_append_plush_lobe(
		st,
		noise,
		Vector3(-0.02, 0.48, 0.02),
		Vector3(0.64, 0.64, 0.62),
		18,
		11,
		0.80,
		1.0
	)

	st.index()
	return st.commit()


func _append_plush_lobe(
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

			# Smooth C1-continuous pillow squash on underside (zero hard crease lines)
			var bottom_t: float = smoothstep(0.18, -0.82, dir.y)
			var y_scale: float = lerpf(1.0, flat_bottom_scale, bottom_t)
			var local_p: Vector3 = Vector3(dir.x * radii.x, dir.y * radii.y * y_scale, dir.z * radii.z)

			var p: Vector3 = center + local_p
			# Ultra-gentle low-frequency organic pillowing keeps silhouettes plump & silky
			var n_primary: float = noise.get_noise_3dv(p * 0.95)
			var disp: float = n_primary * 0.045 * bump_strength
			p += dir * disp

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

	# Unify pole normals at r = 0 and r = rings for completely seamless smooth crowns & bellies
	var north_sum: Vector3 = Vector3.ZERO
	var south_sum: Vector3 = Vector3.ZERO
	var south_row_offset: int = rings * cols
	for s: int in range(cols):
		north_sum += smooth_normals[s]
		south_sum += smooth_normals[south_row_offset + s]
	for s: int in range(cols):
		smooth_normals[s] = north_sum
		smooth_normals[south_row_offset + s] = south_sum

	# Blend geometric lobe normal with macro cumulus radial normal for unified plush velvet shading
	var macro_center: Vector3 = Vector3(0.0, -0.06, 0.0)
	for i: int in range(vert_count):
		var geo_n: Vector3 = smooth_normals[i]
		var radial: Vector3 = positions[i] - macro_center
		var macro_n: Vector3 = radial.normalized() if radial.length_squared() > 0.0001 else Vector3.UP
		if geo_n.length_squared() < 0.0001:
			geo_n = macro_n
		else:
			geo_n = geo_n.normalized()
		smooth_normals[i] = geo_n.lerp(macro_n, 0.38).normalized()

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
			_rng.randf_range(10.0, 16.5),
			_rng.randf_range(21.0, 37.0)
		)
		var puff_count: int = 3
		# Dreamy sakura-pink & cream-blush cotton-candy sea floor near the horizon
		var floor_mat: ShaderMaterial = _material_cotton_sakura if (i % 2 == 0) else _material_cotton_blush
		_spawn_cumulus_tower(
			"SeaFloor_%02d" % i,
			Vector3(x_pos, y_pos, z_pos),
			base_scale,
			puff_count,
			0.58,
			0.75,
			1.65,
			0.07,
			0.18,
			floor_mat,
			_material_cotton_blush
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
			_rng.randf_range(6.4, 9.8),
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
			0.28,
			_material_cotton_blush
		)


func _generate_canyon_wall(side_sign: float) -> void:
	# Plush multi-tiered cumulus towers flanking outside the twin viaducts
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
			_rng.randf_range(12.5, 20.5),
			_rng.randf_range(19.5, 32.5)
		)
		var puff_count: int = _rng.randi_range(3, 4)
		# Blend pastel sakura-blush lower canyon banks into sunlit snow-cream crowns
		var base_mat: ShaderMaterial = _material_cotton_sakura if (t > 0.45 or i % 2 == 0) else _material_cotton_blush
		var crown_mat: ShaderMaterial = _material_cotton_white if (y_pos > 2.0) else _material_cotton_blush
		_spawn_cumulus_tower(
			"Canyon_%s_%02d" % [side_label, i],
			Vector3(x_pos, y_pos, z_pos),
			base_scale,
			puff_count,
			1.02,
			0.95,
			2.15,
			0.10,
			0.26,
			base_mat,
			crown_mat
		)


func _generate_cathedral_amphitheater() -> void:
	# Sweeping cotton-candy sakura & cream cumulus banks embracing the base & flanks of the Castle at z = -280
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
			_rng.randf_range(14.5, 24.0),
			_rng.randf_range(22.0, 36.0)
		)
		var puff_count: int = _rng.randi_range(3, 4)
		_spawn_cumulus_tower(
			"CathedralBank_%02d" % i,
			Vector3(x_pos, y_pos, z_pos),
			base_scale,
			puff_count,
			1.10,
			0.85,
			1.75,
			0.05,
			0.14,
			_material_cotton_sakura,
			_material_cotton_blush
		)


func _generate_high_wisps() -> void:
	# 18 lush, multi-scale, sunlit Pixar high-altitude cumulus cloud clusters sailing
	# gracefully above the city and Baroque Palace (Y in [82..155], X in [-240..240], Z in [-340..140]).
	var count: int = maxi(high_wisp_count, 1)

	for i: int in range(count):
		var t: float = float(i) / maxf(float(count - 1), 1.0)
		var z_pos: float = clampf(lerpf(140.0, -340.0, t) + _rng.randf_range(-24.0, 24.0), -340.0, 140.0)

		# Distribute across 3 natural lanes (left flank, high central sky vault, right flank)
		var lane: int = i % 3
		var x_pos: float = 0.0
		var y_min: float = 82.0
		var y_max: float = 155.0
		if lane == 0:
			x_pos = _rng.randf_range(-240.0, -76.0)
			y_min = 82.0
			y_max = 142.0
		elif lane == 1:
			# High overhead vault sailing well above all city rooftops & Baroque Palace spires
			x_pos = _rng.randf_range(-115.0, 115.0)
			y_min = 104.0
			y_max = 155.0
		else:
			x_pos = _rng.randf_range(76.0, 240.0)
			y_min = 82.0
			y_max = 142.0

		var y_pos: float = _rng.randf_range(y_min, y_max)
		var is_hero_cumulus: bool = (i % 2 == 0)

		if is_hero_cumulus:
			var hero_scale: Vector3 = Vector3(
				_rng.randf_range(26.0, 42.0),
				_rng.randf_range(10.5, 16.5),
				_rng.randf_range(22.0, 35.0)
			)
			var hero_puffs: int = _rng.randi_range(3, 4)
			var base_mat: ShaderMaterial = _material_cotton_white if (y_pos > 112.0) else _material_cotton_blush
			_spawn_cumulus_tower(
				"HighCloud_%02d" % i,
				Vector3(x_pos, y_pos, z_pos),
				hero_scale,
				hero_puffs,
				0.62,
				1.1,
				2.3,
				0.10,
				0.26,
				base_mat,
				_material_cotton_white
			)
		else:
			var wisp_scale: Vector3 = Vector3(
				_rng.randf_range(17.0, 30.0),
				_rng.randf_range(7.5, 12.5),
				_rng.randf_range(15.0, 25.0)
			)
			var wisp_puffs: int = _rng.randi_range(2, 3)
			_spawn_stratified_cloud(
				"HighCloud_%02d" % i,
				Vector3(x_pos, y_pos, z_pos),
				wisp_scale,
				wisp_puffs,
				1.2,
				2.5,
				0.14,
				0.34,
				_material_cotton_white
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
	drift_speed_max: float,
	base_material: ShaderMaterial,
	crown_material: ShaderMaterial
) -> void:
	## Builds a plush multi-tiered cumulus formation from 3-4 silky 6-lobe cotton-wool instances:
	## Tier 1: Broad pillowy cumulus deck.
	## Tier 2: Rising rounded cotton shoulder formation.
	## Tier 3: Sunlit plush summit crown.
	var cluster: Node3D = Node3D.new()
	cluster.name = cluster_name
	cluster.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cluster.position = origin
	add_child(cluster)

	var clamped_count: int = maxi(puff_count, 3)
	var base_lobes: int = 2 if clamped_count >= 4 else 1
	var remaining: int = clamped_count - base_lobes
	var crown_turrets: int = maxi(1, int(floor(float(remaining) * 0.5)))
	var mid_domes: int = maxi(1, remaining - crown_turrets)

	var base_angle_offset: float = _rng.randf_range(0.0, TAU)

	# Tier 1: Pillowy wide base formations
	for b: int in range(base_lobes):
		var pos: Vector3 = Vector3.ZERO
		var scl: Vector3 = base_scale
		if b == 0:
			scl = Vector3(base_scale.x * 1.06, base_scale.y * 0.90, base_scale.z * 1.04)
		else:
			var angle: float = base_angle_offset + (float(b - 1) / maxf(float(base_lobes - 1), 1.0)) * TAU + _rng.randf_range(-0.45, 0.45)
			var dist: float = _rng.randf_range(0.50, 0.80)
			pos = Vector3(
				cos(angle) * base_scale.x * dist,
				_rng.randf_range(-0.10, 0.08) * base_scale.y,
				sin(angle) * base_scale.z * dist
			)
			var factor: float = _rng.randf_range(0.74, 0.92)
			scl = Vector3(
				base_scale.x * factor * _rng.randf_range(0.92, 1.12),
				base_scale.y * factor * _rng.randf_range(0.80, 0.98),
				base_scale.z * factor * _rng.randf_range(0.92, 1.12)
			)
		_add_puff_mesh(cluster, pos, scl, 0.08, base_material)

	# Tier 2: Rising rounded billowing mid-formation
	var mid_angle_offset: float = base_angle_offset + _rng.randf_range(0.5, 1.6)
	for m: int in range(mid_domes):
		var angle: float = mid_angle_offset + (float(m) / maxf(float(mid_domes), 1.0)) * TAU + _rng.randf_range(-0.4, 0.4)
		var dist: float = _rng.randf_range(0.22, 0.50) if mid_domes > 1 else _rng.randf_range(0.08, 0.24)
		var pos: Vector3 = Vector3(
			cos(angle) * base_scale.x * dist,
			_rng.randf_range(0.28, 0.52) * base_scale.y * tower_height_factor,
			sin(angle) * base_scale.z * dist
		)
		var factor: float = _rng.randf_range(0.64, 0.82)
		var scl: Vector3 = Vector3(
			base_scale.x * factor * _rng.randf_range(0.90, 1.08),
			base_scale.y * factor * _rng.randf_range(0.94, 1.16) * tower_height_factor,
			base_scale.z * factor * _rng.randf_range(0.90, 1.08)
		)
		_add_puff_mesh(cluster, pos, scl, 0.12, base_material)

	# Tier 3: Sunlit plush summit crown formation
	var crown_angle_offset: float = mid_angle_offset + _rng.randf_range(0.4, 1.4)
	for c: int in range(crown_turrets):
		var angle: float = crown_angle_offset + (float(c) / maxf(float(crown_turrets), 1.0)) * TAU + _rng.randf_range(-0.35, 0.35)
		var dist: float = _rng.randf_range(0.06, 0.26) if crown_turrets > 1 else _rng.randf_range(0.0, 0.14)
		var pos: Vector3 = Vector3(
			cos(angle) * base_scale.x * dist,
			_rng.randf_range(0.54, 0.82) * base_scale.y * tower_height_factor,
			sin(angle) * base_scale.z * dist
		)
		var factor: float = _rng.randf_range(0.48, 0.66)
		var scl: Vector3 = Vector3(
			base_scale.x * factor * _rng.randf_range(0.88, 1.06),
			base_scale.y * factor * _rng.randf_range(0.96, 1.20) * tower_height_factor,
			base_scale.z * factor * _rng.randf_range(0.88, 1.06)
		)
		_add_puff_mesh(cluster, pos, scl, 0.14, crown_material)

	_register_cluster(cluster, origin, bob_min, bob_max, drift_speed_min, drift_speed_max)


func _spawn_stratified_cloud(
	cluster_name: String,
	origin: Vector3,
	base_scale: Vector3,
	puff_count: int,
	bob_min: float,
	bob_max: float,
	drift_speed_min: float,
	drift_speed_max: float,
	cloud_material: ShaderMaterial
) -> void:
	## Builds a plump floating cotton-wool cloud bank (for under-viaduct billows & high sky clouds).
	var cluster: Node3D = Node3D.new()
	cluster.name = cluster_name
	cluster.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cluster.position = origin
	add_child(cluster)

	var angle_offset: float = _rng.randf_range(0.0, TAU)
	for p: int in range(puff_count):
		var pos: Vector3 = Vector3.ZERO
		var scl: Vector3 = base_scale
		if p > 0:
			var angle: float = angle_offset + (float(p - 1) / maxf(float(puff_count - 1), 1.0)) * TAU + _rng.randf_range(-0.4, 0.4)
			var dist: float = _rng.randf_range(0.48, 0.78)
			pos = Vector3(
				cos(angle) * base_scale.x * dist,
				_rng.randf_range(-0.12, 0.20) * base_scale.y,
				sin(angle) * base_scale.z * dist
			)
			var factor: float = _rng.randf_range(0.62, 0.86)
			scl = Vector3(
				base_scale.x * factor * _rng.randf_range(0.92, 1.14),
				base_scale.y * factor * _rng.randf_range(0.84, 1.08),
				base_scale.z * factor * _rng.randf_range(0.92, 1.14)
			)
		_add_puff_mesh(cluster, pos, scl, 0.10, cloud_material)

	_register_cluster(cluster, origin, bob_min, bob_max, drift_speed_min, drift_speed_max)


func _add_puff_mesh(
	cluster: Node3D,
	local_pos: Vector3,
	local_scale: Vector3,
	tilt_max: float,
	cloud_material: ShaderMaterial
) -> void:
	var puff: MeshInstance3D = MeshInstance3D.new()
	puff.mesh = _shared_mesh
	puff.material_override = cloud_material
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	puff.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
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
