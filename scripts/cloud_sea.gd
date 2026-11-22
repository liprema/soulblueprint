class_name CloudSea
extends Node3D

## Procedurally populates a lush 3D billowing cloud sea floor, flanking cloud canyon,
## Cathedral cloud amphitheater, and high celestial wisps using cloud_puff.gdshader,
## keeping a clear central flight corridor along -Z (z=50 to z=-320).

@export var cloud_shader: Shader = preload("res://shaders/cloud_puff.gdshader")
@export var seed_value: int = 4242

@export_group("Flight Corridor")
@export var corridor_z_start: float = 50.0
@export var corridor_z_end: float = -320.0
@export var corridor_half_width: float = 28.0

@export_group("Cloud Sea Floor")
@export var sea_floor_y: float = -24.0
@export var floor_cluster_count: int = 72
@export var floor_x_extent: float = 205.0

@export_group("Flanking Cloud Canyon")
@export var canyon_clusters_per_side: int = 38
@export var canyon_outer_x: float = 152.0
@export var canyon_min_y: float = -12.0
@export var canyon_max_y: float = 46.0

@export_group("Cathedral Cloud Amphitheater")
@export var cathedral_cloud_count: int = 18

@export_group("High Celestial Wisps")
@export var high_wisp_count: int = 20

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


func _ready() -> void:
	_setup_shared_resources()
	_populate_cloudscape()


func _setup_shared_resources() -> void:
	_shared_mesh = SphereMesh.new()
	_shared_mesh.radius = 1.0
	_shared_mesh.height = 2.0
	_shared_mesh.radial_segments = 20
	_shared_mesh.rings = 12

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

	_generate_sea_floor()
	_generate_canyon_wall(-1.0)
	_generate_canyon_wall(1.0)
	_generate_cathedral_amphitheater()
	_generate_high_wisps()


func _generate_sea_floor() -> void:
	var z_front: float = corridor_z_start + 38.0
	var z_back: float = corridor_z_end - 65.0

	for i: int in range(floor_cluster_count):
		var t: float = float(i) / maxf(float(floor_cluster_count - 1), 1.0)
		var z_pos: float = lerpf(z_front, z_back, t) + _rng.randf_range(-18.0, 18.0)
		var x_pos: float = _rng.randf_range(-floor_x_extent, floor_x_extent)
		var y_pos: float = sea_floor_y + _rng.randf_range(-10.0, 6.0)

		# Keep floor gently nestled below the central flight corridor for sweeping aerial views
		if absf(x_pos) < corridor_half_width:
			y_pos -= _rng.randf_range(4.0, 9.5)

		var base_scale: Vector3 = Vector3(
			_rng.randf_range(17.0, 36.0),
			_rng.randf_range(7.0, 14.5),
			_rng.randf_range(17.0, 34.0)
		)
		var puff_count: int = _rng.randi_range(3, 5)
		_spawn_cloud_cluster("SeaFloor_%02d" % i, Vector3(x_pos, y_pos, z_pos), base_scale, puff_count, 0.85, 1.85, 0.08, 0.22)


func _generate_canyon_wall(side_sign: float) -> void:
	var side_label: String = "Left" if side_sign < 0.0 else "Right"

	for i: int in range(canyon_clusters_per_side):
		var t: float = float(i) / maxf(float(canyon_clusters_per_side - 1), 1.0)
		var z_pos: float = lerpf(corridor_z_start + 12.0, corridor_z_end - 12.0, t) + _rng.randf_range(-8.0, 8.0)

		# Widen the canyon gracefully as the player approaches the Astrolabe Cathedral near z=-280
		var cathedral_flare: float = smoothstep(0.68, 1.0, t) * 30.0
		var tier_ratio: float = _rng.randf()
		var inner_margin: float = corridor_half_width + 17.0 + cathedral_flare
		var x_mag: float = lerpf(inner_margin, canyon_outer_x + cathedral_flare, tier_ratio)
		var x_pos: float = side_sign * x_mag

		# Higher billowy ridges further from the corridor center for dramatic canyon framing
		var y_pos: float = lerpf(canyon_min_y, canyon_max_y, pow(tier_ratio, 0.72)) + _rng.randf_range(-6.0, 9.0)

		var base_scale: Vector3 = Vector3(
			_rng.randf_range(15.0, 30.0),
			_rng.randf_range(10.0, 21.0),
			_rng.randf_range(16.0, 32.0)
		)
		var puff_count: int = _rng.randi_range(4, 6)
		_spawn_cloud_cluster("Canyon_%s_%02d" % [side_label, i], Vector3(x_pos, y_pos, z_pos), base_scale, puff_count, 1.0, 2.3, 0.12, 0.30)


func _generate_cathedral_amphitheater() -> void:
	# Sweeping sunlit cloud banks embracing the base & flanks of the Astrolabe Cathedral (z = -280)
	for i: int in range(cathedral_cloud_count):
		var t: float = float(i) / maxf(float(cathedral_cloud_count - 1), 1.0)
		var angle: float = lerpf(-0.82 * PI, -0.18 * PI, t)
		var radius: float = _rng.randf_range(86.0, 148.0)
		var x_pos: float = cos(angle) * radius
		var z_pos: float = -278.0 + sin(angle) * (radius * 0.52)
		var y_pos: float = lerpf(-18.0, 34.0, absf(cos(angle))) + _rng.randf_range(-8.0, 12.0)

		var base_scale: Vector3 = Vector3(
			_rng.randf_range(24.0, 44.0),
			_rng.randf_range(12.0, 24.0),
			_rng.randf_range(22.0, 38.0)
		)
		var puff_count: int = _rng.randi_range(4, 6)
		_spawn_cloud_cluster("CathedralBank_%02d" % i, Vector3(x_pos, y_pos, z_pos), base_scale, puff_count, 0.9, 1.9, 0.06, 0.16)


func _generate_high_wisps() -> void:
	for i: int in range(high_wisp_count):
		var side_sign: float = -1.0 if (i % 2 == 0) else 1.0
		var t: float = float(i) / maxf(float(high_wisp_count - 1), 1.0)
		var z_pos: float = lerpf(corridor_z_start, corridor_z_end - 40.0, t) + _rng.randf_range(-16.0, 16.0)
		var x_pos: float = side_sign * _rng.randf_range(corridor_half_width + 6.0, canyon_outer_x + 32.0)
		var y_pos: float = _rng.randf_range(56.0, 96.0)

		var base_scale: Vector3 = Vector3(
			_rng.randf_range(20.0, 38.0),
			_rng.randf_range(4.2, 8.8),
			_rng.randf_range(15.0, 28.0)
		)
		var puff_count: int = _rng.randi_range(3, 4)
		_spawn_cloud_cluster("HighWisp_%02d" % i, Vector3(x_pos, y_pos, z_pos), base_scale, puff_count, 1.4, 2.8, 0.20, 0.44)


func _spawn_cloud_cluster(
	cluster_name: String,
	origin: Vector3,
	base_scale: Vector3,
	puff_count: int,
	bob_min: float,
	bob_max: float,
	drift_speed_min: float,
	drift_speed_max: float
) -> void:
	var cluster: Node3D = Node3D.new()
	cluster.name = cluster_name
	cluster.position = origin
	add_child(cluster)

	for p: int in range(puff_count):
		var puff: MeshInstance3D = MeshInstance3D.new()
		puff.mesh = _shared_mesh
		puff.material_override = _shared_material
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		if p == 0:
			puff.position = Vector3.ZERO
			puff.scale = base_scale
		else:
			var angle: float = _rng.randf_range(0.0, TAU)
			var dist_factor: float = _rng.randf_range(0.30, 0.72)
			puff.position = Vector3(
				cos(angle) * base_scale.x * dist_factor,
				_rng.randf_range(-0.20, 0.34) * base_scale.y,
				sin(angle) * base_scale.z * dist_factor
			)
			var sub_factor: float = _rng.randf_range(0.54, 0.88)
			puff.scale = Vector3(
				base_scale.x * sub_factor * _rng.randf_range(0.85, 1.16),
				base_scale.y * sub_factor * _rng.randf_range(0.80, 1.22),
				base_scale.z * sub_factor * _rng.randf_range(0.85, 1.16)
			)

		puff.rotation = Vector3(
			_rng.randf_range(-0.18, 0.18),
			_rng.randf_range(0.0, TAU),
			_rng.randf_range(-0.18, 0.18)
		)
		cluster.add_child(puff)

	_clusters.append(cluster)
	_base_positions.append(origin)
	_bob_amplitudes.append(_rng.randf_range(bob_min, bob_max))
	_bob_speeds.append(_rng.randf_range(0.20, 0.52))
	_bob_phases.append(_rng.randf_range(0.0, TAU))
	_sway_amplitudes.append(_rng.randf_range(0.9, 3.2))
	_drift_z_amplitudes.append(_rng.randf_range(0.6, 2.4))
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
