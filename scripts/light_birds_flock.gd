extends Node3D
class_name LightBirdsFlock

## Flock of 48 glowing golden Light-Birds orbiting gracefully along the cloud canyon
## (z = -15..-220, y = -4..26) and wheeling in response to the Soul Resonance Call.

@export var bird_count: int = 0
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
	bird_count = 0
	if birds_multimesh != null:
		birds_multimesh.visible = false
		birds_multimesh.multimesh = null
	set_process(false)
	return


func _process(_delta: float) -> void:
	return


## No-op kept for clean compatibility with soul_call_3d.gd and scene references.
func on_soul_call(_origin: Vector3) -> void:
	pass


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
	birds_multimesh.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


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

		var bird_basis: Basis = Basis.looking_at(forward, up)

		# Gentle wing-rock & banking roll for organic Sky-style gliding motion.
		var flap_speed: float = lerpf(4.8, 8.2, boost_factor)
		var wing_rock: float = sin(_elapsed * flap_speed + _flap_phases[i]) * 0.24
		bird_basis = bird_basis.rotated(forward, wing_rock)

		var sc: float = _bird_scales[i] * (1.0 + _call_weights[i] * boost_factor * 0.14)
		# Subtle vertical flap stretch on Y to evoke graceful wingbeats.
		var flap_y: float = 1.0 + sin(_elapsed * flap_speed + _flap_phases[i]) * 0.35
		bird_basis = bird_basis.scaled(Vector3(sc, sc * flap_y, sc))

		_multimesh.set_instance_transform(i, Transform3D(bird_basis, _positions[i]))


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
