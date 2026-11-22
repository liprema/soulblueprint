extends Node3D
class_name LightBirdsFlock

## Flock of 48 glowing golden Light-Birds orbiting gracefully along the cloud canyon
## (z = -15..-220, y = -4..26) and wheeling in response to the Soul Resonance Call.

@export var bird_count: int = 48
@export var canyon_z_min: float = -220.0
@export var canyon_z_max: float = -15.0
@export var canyon_y_min: float = -4.0
@export var canyon_y_max: float = 26.0
@export var canyon_x_half_width: float = 34.0

@export var base_cruise_speed: float = 7.5
@export var call_speed_multiplier: float = 1.9
@export var call_boost_duration: float = 3.2
@export var call_attract_radius: float = 95.0

@onready var birds_multimesh: MultiMeshInstance3D = $BirdsMultiMesh

var _multimesh: MultiMesh
var _rng := RandomNumberGenerator.new()

# Per-bird state arrays (kept flat for fast per-frame updates).
var _positions: PackedVector3Array = PackedVector3Array()
var _velocities: PackedVector3Array = PackedVector3Array()
var _orbit_centers: PackedVector3Array = PackedVector3Array()
var _orbit_radii: PackedVector3Array = PackedVector3Array()
var _orbit_angles: PackedFloat32Array = PackedFloat32Array()
var _orbit_speeds: PackedFloat32Array = PackedFloat32Array()
var _bird_scales: PackedFloat32Array = PackedFloat32Array()
var _flap_phases: PackedFloat32Array = PackedFloat32Array()
var _call_weights: PackedFloat32Array = PackedFloat32Array()

var _call_origin_local: Vector3 = Vector3.ZERO
var _call_timer: float = 0.0
var _elapsed: float = 0.0


func _ready() -> void:
	add_to_group("light_birds")
	_rng.seed = 42073

	_setup_multimesh()
	_init_flock()
	_update_multimesh_transforms()


func _process(delta: float) -> void:
	if _multimesh == null or bird_count <= 0:
		return

	_elapsed += delta
	var boost_factor := 0.0
	if _call_timer > 0.0:
		_call_timer = maxf(0.0, _call_timer - delta)
		boost_factor = ease(_call_timer / maxf(call_boost_duration, 0.01), 0.6)

	var speed_mult := lerpf(1.0, call_speed_multiplier, boost_factor)

	for i in range(bird_count):
		_orbit_angles[i] += _orbit_speeds[i] * speed_mult * delta
		var ang := _orbit_angles[i]
		var center := _orbit_centers[i]
		var rad := _orbit_radii[i]

		# Graceful figure-8 / elliptical canyon glide path clamped within canyon bounds.
		var target := Vector3(
			center.x + cos(ang) * rad.x,
			clampf(center.y + sin(ang * 1.7 + _flap_phases[i]) * rad.y, canyon_y_min, canyon_y_max),
			clampf(center.z + sin(ang) * rad.z, canyon_z_min, canyon_z_max)
		)

		# Nearby birds wheel gracefully in a swirling arc toward the Soul Call wave.
		var w := _call_weights[i] * boost_factor
		if w > 0.01:
			var to_call := _call_origin_local - _positions[i]
			var dist := to_call.length()
			if dist > 0.5:
				var dir_to_call := to_call / dist
				# Add a tangential swirl around the resonance wave so birds wheel rather than collide.
				var tangent := Vector3(-dir_to_call.z, 0.22, dir_to_call.x).normalized()
				var wheel_point := _call_origin_local - dir_to_call * minf(dist, 14.0) + tangent * 10.0
				wheel_point.y = clampf(wheel_point.y + 4.5, canyon_y_min, canyon_y_max)
				target = target.lerp(wheel_point, clampf(w * 0.85, 0.0, 0.88))

		var desired_dir := target - _positions[i]
		var desired_dist := desired_dir.length()
		var desired_vel := _velocities[i]
		if desired_dist > 0.001:
			var target_speed := base_cruise_speed * speed_mult * (0.85 + 0.3 * _bird_scales[i])
			desired_vel = (desired_dir / desired_dist) * target_speed

		var steer_rate := lerpf(2.2, 4.4, w)
		_velocities[i] = _velocities[i].lerp(desired_vel, clampf(steer_rate * delta, 0.0, 1.0))
		_positions[i] += _velocities[i] * delta

		# Keep birds softly within canyon envelope.
		_positions[i].y = clampf(_positions[i].y, canyon_y_min, canyon_y_max)
		_positions[i].z = clampf(_positions[i].z, canyon_z_min, canyon_z_max)

	_update_multimesh_transforms(boost_factor)


## Briefly boosts flock speed and draws nearby light-birds to wheel toward the resonance wave.
func on_soul_call(origin: Vector3) -> void:
	_call_origin_local = to_local(origin)
	_call_timer = call_boost_duration

	for i in range(bird_count):
		var dist := _positions[i].distance_to(_call_origin_local)
		if dist <= call_attract_radius:
			var proximity := 1.0 - (dist / call_attract_radius)
			_call_weights[i] = clampf(0.35 + proximity * 0.65, 0.0, 1.0)
		else:
			_call_weights[i] = 0.0


func _setup_multimesh() -> void:
	var bird_mesh := _build_stylized_bird_mesh()

	var mat := StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(1.0, 0.941176, 0.721569, 1.0) # #FFF0B8
	mat.roughness = 0.25
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.941176, 0.721569, 1.0) # #FFF0B8 HDR bloom
	mat.emission_energy_multiplier = 2.8
	mat.vertex_color_use_as_albedo = true
	bird_mesh.surface_set_material(0, mat)

	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = bird_count
	_multimesh.mesh = bird_mesh

	birds_multimesh.multimesh = _multimesh
	birds_multimesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _init_flock() -> void:
	_positions.resize(bird_count)
	_velocities.resize(bird_count)
	_orbit_centers.resize(bird_count)
	_orbit_radii.resize(bird_count)
	_orbit_angles.resize(bird_count)
	_orbit_speeds.resize(bird_count)
	_bird_scales.resize(bird_count)
	_flap_phases.resize(bird_count)
	_call_weights.resize(bird_count)

	# Distribute birds across graceful clusters along the cloud canyon.
	var cluster_count := 6
	for i in range(bird_count):
		var cluster_idx := i % cluster_count
		var t := (float(cluster_idx) + 0.5) / float(cluster_count)
		var base_z := lerpf(canyon_z_max - 12.0, canyon_z_min + 14.0, t)
		var base_y := lerpf(canyon_y_min + 5.5, canyon_y_max - 5.0, _rng.randf())
		var base_x := _rng.randf_range(-canyon_x_half_width * 0.55, canyon_x_half_width * 0.55)

		var center := Vector3(
			base_x + _rng.randf_range(-4.0, 4.0),
			base_y,
			clampf(base_z + _rng.randf_range(-10.0, 10.0), canyon_z_min + 10.0, canyon_z_max - 10.0)
		)
		var rad := Vector3(
			_rng.randf_range(9.0, 20.0),
			_rng.randf_range(1.8, 4.5),
			_rng.randf_range(10.0, 22.0)
		)
		var angle := _rng.randf_range(0.0, TAU)
		var speed := _rng.randf_range(0.32, 0.58) * (1.0 if (i % 2 == 0) else -1.0)
		var sc := _rng.randf_range(0.75, 1.32)
		var phase := _rng.randf_range(0.0, TAU)

		_orbit_centers[i] = center
		_orbit_radii[i] = rad
		_orbit_angles[i] = angle
		_orbit_speeds[i] = speed
		_bird_scales[i] = sc
		_flap_phases[i] = phase
		_call_weights[i] = 0.0

		var start_pos := Vector3(
			center.x + cos(angle) * rad.x,
			clampf(center.y + sin(angle * 1.7 + phase) * rad.y, canyon_y_min, canyon_y_max),
			clampf(center.z + sin(angle) * rad.z, canyon_z_min, canyon_z_max)
		)
		_positions[i] = start_pos

		var tangent := Vector3(-sin(angle) * rad.x, 0.0, cos(angle) * rad.z).normalized()
		if speed < 0.0:
			tangent = -tangent
		_velocities[i] = tangent * base_cruise_speed

		_multimesh.set_instance_color(i, Color(1.0, 0.96, 0.82, 1.0))


func _update_multimesh_transforms(boost_factor: float = 0.0) -> void:
	for i in range(bird_count):
		var vel := _velocities[i]
		var forward := vel.normalized() if vel.length_squared() > 0.0001 else Vector3.FORWARD
		var up := Vector3.UP
		if absf(forward.dot(up)) > 0.96:
			up = Vector3.RIGHT

		var basis := Basis.looking_at(forward, up)

		# Gentle wing-rock & banking roll for organic Sky-style gliding motion.
		var flap_speed := lerpf(4.8, 8.2, boost_factor)
		var wing_rock := sin(_elapsed * flap_speed + _flap_phases[i]) * 0.24
		basis = basis.rotated(forward, wing_rock)

		var sc := _bird_scales[i] * (1.0 + _call_weights[i] * boost_factor * 0.14)
		# Subtle vertical flap stretch on Y to evoke graceful wingbeats.
		var flap_y := 1.0 + sin(_elapsed * flap_speed + _flap_phases[i]) * 0.35
		basis = basis.scaled(Vector3(sc, sc * flap_y, sc))

		_multimesh.set_instance_transform(i, Transform3D(basis, _positions[i]))


func _build_stylized_bird_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Origami / Sky-style light-bird silhouette pointing along -Z.
	var nose := Vector3(0.0, 0.0, -0.78)
	var spine := Vector3(0.0, 0.08, -0.04)
	var tail_c := Vector3(0.0, 0.02, 0.50)
	var tail_l := Vector3(-0.24, 0.05, 0.84)
	var tail_r := Vector3(0.24, 0.05, 0.84)

	var wing_mid_l := Vector3(-0.56, 0.15, -0.06)
	var wing_mid_r := Vector3(0.56, 0.15, -0.06)
	var wing_tip_l := Vector3(-1.22, 0.28, 0.30)
	var wing_tip_r := Vector3(1.22, 0.28, 0.30)
	var wing_back_l := Vector3(-0.32, 0.05, 0.22)
	var wing_back_r := Vector3(0.32, 0.05, 0.22)

	var tris: Array[Vector3] = [
		# Left wing
		nose, spine, wing_mid_l,
		spine, wing_back_l, wing_mid_l,
		wing_mid_l, wing_back_l, wing_tip_l,
		# Right wing
		nose, wing_mid_r, spine,
		spine, wing_mid_r, wing_back_r,
		wing_mid_r, wing_tip_r, wing_back_r,
		# Body & forked tail
		spine, tail_c, wing_back_l,
		spine, wing_back_r, tail_c,
		wing_back_l, tail_c, tail_l,
		wing_back_r, tail_r, tail_c,
	]

	for v in tris:
		st.add_vertex(v)

	st.generate_normals()
	return st.commit()
