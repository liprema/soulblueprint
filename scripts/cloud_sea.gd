class_name CloudSea
extends Node3D

## Procedurally populates a hyper-detailed, multi-tiered 3D cumulus cloudscape:
## billowing cloud sea floor, under-viaduct arch billows, flanking cumulus canyon towers,
## Cathedral cloud amphitheater, and high celestial wisps using cloud_puff.gdshader,
## keeping a crystal-clear central flight corridor along -Z (z=50 to z=-320).

@export var cloud_shader: Shader = preload("res://shaders/cloud_puff.gdshader")
@export var seed_value: int = 4242

@export_group("Flight Corridor")
@export var corridor_z_start: float = 50.0
@export var corridor_z_end: float = -320.0
@export var corridor_half_width: float = 62.0

@export_group("Cloud Sea Floor")
@export var sea_floor_y: float = -42.0
@export var floor_cluster_count: int = 16
@export var floor_x_extent: float = 215.0

@export_group("Under-Viaduct Billows")
@export var viaduct_x_offset: float = 56.0
@export var viaduct_billows_per_side: int = 5
@export var viaduct_billow_min_y: float = -38.0
@export var viaduct_billow_max_y: float = -26.0

@export_group("Flanking Cloud Canyon")
@export var canyon_clusters_per_side: int = 9
@export var canyon_inner_x: float = 74.0
@export var canyon_outer_x: float = 162.0
@export var canyon_min_y: float = -22.0
@export var canyon_max_y: float = 24.0

@export_group("Cathedral Cloud Amphitheater")
@export var cathedral_cloud_count: int = 5

@export_group("High Celestial Wisps")
@export var high_wisp_count: int = 4

@export_group("Animation")
@export var bob_amplitude_scale: float = 1.0
@export var bob_speed_scale: float = 1.0
@export var drift_amplitude_scale: float = 1.0

var _shared_mesh: SphereMesh
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
	_shared_mesh = SphereMesh.new()
	_shared_mesh.radius = 1.0
	_shared_mesh.height = 2.0
	_shared_mesh.radial_segments = 28
	_shared_mesh.rings = 16

	_shared_material = ShaderMaterial.new()
	_shared_material.shader = cloud_shader


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
			_rng.randf_range(18.0, 35.0),
			_rng.randf_range(7.0, 13.0),
			_rng.randf_range(18.0, 34.0)
		)
		var puff_count: int = _rng.randi_range(5, 6)
		_spawn_cumulus_tower(
			"SeaFloor_%02d" % i,
			Vector3(x_pos, y_pos, z_pos),
			base_scale,
			puff_count,
			0.55,
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
			_rng.randf_range(11.0, 18.0),
			_rng.randf_range(4.2, 7.2),
			_rng.randf_range(12.0, 20.0)
		)
		var puff_count: int = _rng.randi_range(3, 4)
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
	# Dramatic multi-tiered cumulus towers flanking outside the twin viaducts (x >= +/-74)
	var side_label: String = "Left" if side_sign < 0.0 else "Right"
	var safe_inner_x: float = maxf(corridor_half_width + 12.0, canyon_inner_x)

	for i: int in range(canyon_clusters_per_side):
		var t: float = float(i) / maxf(float(canyon_clusters_per_side - 1), 1.0)
		var z_pos: float = lerpf(corridor_z_start + 10.0, corridor_z_end - 12.0, t) + _rng.randf_range(-9.0, 9.0)

		# Widen the canyon gracefully as the player approaches the Castle / Cathedral near z = -280
		var cathedral_flare: float = smoothstep(0.65, 1.0, t) * 32.0
		var tier_ratio: float = _rng.randf()
		var inner_margin: float = safe_inner_x + cathedral_flare
		var x_mag: float = lerpf(inner_margin, canyon_outer_x + cathedral_flare, tier_ratio)
		var x_pos: float = side_sign * x_mag

		# Higher billowing cumulus ridges further from the corridor center for grand aerial framing
		var y_pos: float = lerpf(canyon_min_y, canyon_max_y, pow(tier_ratio, 0.74)) + _rng.randf_range(-6.0, 8.0)

		var base_scale: Vector3 = Vector3(
			_rng.randf_range(16.0, 29.0),
			_rng.randf_range(9.5, 17.5),
			_rng.randf_range(17.0, 30.0)
		)
		var puff_count: int = _rng.randi_range(6, 8)
		_spawn_cumulus_tower(
			"Canyon_%s_%02d" % [side_label, i],
			Vector3(x_pos, y_pos, z_pos),
			base_scale,
			puff_count,
			1.05,
			0.95,
			2.15,
			0.10,
			0.26
		)


func _generate_cathedral_amphitheater() -> void:
	# Sweeping sunlit cumulus towers embracing the lower base & flanks of the Castle at z = -280
	for i: int in range(cathedral_cloud_count):
		var t: float = float(i) / maxf(float(cathedral_cloud_count - 1), 1.0)
		var angle: float = lerpf(-0.84 * PI, -0.16 * PI, t)
		var radius: float = _rng.randf_range(92.0, 152.0)
		var x_pos: float = cos(angle) * radius
		var z_pos: float = -280.0 + sin(angle) * (radius * 0.54)
		var y_pos: float = lerpf(-22.0, 26.0, absf(cos(angle))) + _rng.randf_range(-7.0, 10.0)

		var base_scale: Vector3 = Vector3(
			_rng.randf_range(22.0, 38.0),
			_rng.randf_range(11.5, 20.5),
			_rng.randf_range(20.0, 34.0)
		)
		var puff_count: int = _rng.randi_range(7, 9)
		_spawn_cumulus_tower(
			"CathedralBank_%02d" % i,
			Vector3(x_pos, y_pos, z_pos),
			base_scale,
			puff_count,
			1.15,
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
			_rng.randf_range(20.0, 36.0),
			_rng.randf_range(4.0, 7.8),
			_rng.randf_range(15.0, 26.0)
		)
		var puff_count: int = _rng.randi_range(3, 4)
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
	## Builds a sculpted 3-tier fairytale cumulus tower:
	## Tier 1: Wide flat-bottomed base lobes forming a grounded cloud deck.
	## Tier 2: Rising rounded mid-domes billowing upward into shoulders.
	## Tier 3: Smaller crisp cauliflower crown turrets crowning the sunlit summit.
	var cluster: Node3D = Node3D.new()
	cluster.name = cluster_name
	cluster.position = origin
	add_child(cluster)

	var clamped_count: int = maxi(puff_count, 4)
	var base_lobes: int = 3 if clamped_count >= 6 else 2
	var remaining: int = clamped_count - base_lobes
	var mid_domes: int = maxi(1, int(ceil(float(remaining) * 0.55)))
	var crown_turrets: int = maxi(1, remaining - mid_domes)

	var base_angle_offset: float = _rng.randf_range(0.0, TAU)

	# Tier 1: Flat-bottomed wide base lobes
	for b: int in range(base_lobes):
		var pos: Vector3 = Vector3.ZERO
		var scl: Vector3 = base_scale
		if b == 0:
			scl = Vector3(base_scale.x * 1.06, base_scale.y * 0.84, base_scale.z * 1.04)
		else:
			var angle: float = base_angle_offset + (float(b - 1) / maxf(float(base_lobes - 1), 1.0)) * TAU + _rng.randf_range(-0.45, 0.45)
			var dist: float = _rng.randf_range(0.46, 0.78)
			pos = Vector3(
				cos(angle) * base_scale.x * dist,
				_rng.randf_range(-0.14, 0.08) * base_scale.y,
				sin(angle) * base_scale.z * dist
			)
			var factor: float = _rng.randf_range(0.68, 0.90)
			scl = Vector3(
				base_scale.x * factor * _rng.randf_range(0.92, 1.15),
				base_scale.y * factor * _rng.randf_range(0.72, 0.92),
				base_scale.z * factor * _rng.randf_range(0.92, 1.15)
			)
		_add_puff_mesh(cluster, pos, scl, 0.12)

	# Tier 2: Rising rounded billowing mid-domes
	var mid_angle_offset: float = base_angle_offset + _rng.randf_range(0.5, 1.6)
	for m: int in range(mid_domes):
		var angle: float = mid_angle_offset + (float(m) / maxf(float(mid_domes), 1.0)) * TAU + _rng.randf_range(-0.4, 0.4)
		var dist: float = _rng.randf_range(0.18, 0.52)
		var pos: Vector3 = Vector3(
			cos(angle) * base_scale.x * dist,
			_rng.randf_range(0.28, 0.54) * base_scale.y * tower_height_factor,
			sin(angle) * base_scale.z * dist
		)
		var factor: float = _rng.randf_range(0.56, 0.78)
		var scl: Vector3 = Vector3(
			base_scale.x * factor * _rng.randf_range(0.86, 1.08),
			base_scale.y * factor * _rng.randf_range(0.96, 1.24) * tower_height_factor,
			base_scale.z * factor * _rng.randf_range(0.86, 1.08)
		)
		_add_puff_mesh(cluster, pos, scl, 0.16)

	# Tier 3: Crisp smaller cauliflower crown turrets perched at the sunlit summit
	var crown_angle_offset: float = mid_angle_offset + _rng.randf_range(0.4, 1.4)
	for c: int in range(crown_turrets):
		var angle: float = crown_angle_offset + (float(c) / maxf(float(crown_turrets), 1.0)) * TAU + _rng.randf_range(-0.35, 0.35)
		var dist: float = _rng.randf_range(0.05, 0.30) if crown_turrets > 1 else _rng.randf_range(0.0, 0.14)
		var pos: Vector3 = Vector3(
			cos(angle) * base_scale.x * dist,
			_rng.randf_range(0.58, 0.90) * base_scale.y * tower_height_factor,
			sin(angle) * base_scale.z * dist
		)
		var factor: float = _rng.randf_range(0.36, 0.56)
		var scl: Vector3 = Vector3(
			base_scale.x * factor * _rng.randf_range(0.82, 1.05),
			base_scale.y * factor * _rng.randf_range(1.05, 1.38) * tower_height_factor,
			base_scale.z * factor * _rng.randf_range(0.82, 1.05)
		)
		_add_puff_mesh(cluster, pos, scl, 0.20)

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
	## Builds a softer horizontal pillow / wisp cluster (for under-viaduct billows & high celestial wisps).
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
			var dist: float = _rng.randf_range(0.42, 0.84)
			pos = Vector3(
				cos(angle) * base_scale.x * dist,
				_rng.randf_range(-0.18, 0.26) * base_scale.y,
				sin(angle) * base_scale.z * dist
			)
			var factor: float = _rng.randf_range(0.52, 0.84)
			scl = Vector3(
				base_scale.x * factor * _rng.randf_range(0.88, 1.18),
				base_scale.y * factor * _rng.randf_range(0.76, 1.08),
				base_scale.z * factor * _rng.randf_range(0.88, 1.18)
			)
		_add_puff_mesh(cluster, pos, scl, 0.14)

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
