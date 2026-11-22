extends CharacterBody3D

## Sky: Children of the Light-inspired 3D protagonist controller (Spark).
## Supports smooth ground movement, mid-air flight entry, free 3D flight with
## banking/diving/climbing, wing flap boosts, golden forward surge, resonance call,
## procedural cape/halo animation, dual ImmediateMesh wingtip trails, and dynamic camera.

signal soul_call_triggered(origin: Vector3)
signal wing_energy_changed(current: float, max_energy: float)
signal flight_mode_changed(is_flying: bool)

# --- Input Toggle (used by intro bridge / cutscenes) ---
@export var input_enabled: bool = true

# --- Ground Movement ---
@export_group("Ground Movement")
@export var ground_speed: float = 11.5
@export var ground_acceleration: float = 28.0
@export var ground_deceleration: float = 22.0
@export var ground_turn_speed: float = 10.0
@export var jump_velocity: float = 10.8
@export var gravity: float = 24.0
@export var fall_gravity_multiplier: float = 0.82
@export var coyote_time: float = 0.14

# --- Free 3D Flight ---
@export_group("Free 3D Flight")
@export var flight_cruise_speed: float = 17.5
@export var flight_min_speed: float = 10.5
@export var flight_max_speed: float = 34.0
@export var flight_yaw_speed: float = 2.05
@export var flight_pitch_speed: float = 1.65
@export var flight_min_pitch_deg: float = -62.0
@export var flight_max_pitch_deg: float = 56.0
@export var flight_dive_acceleration: float = 18.0
@export var flight_climb_deceleration: float = 12.0
@export var flight_speed_relax_rate: float = 1.4
@export var flight_glide_sink: float = 1.35
@export var flight_responsiveness: float = 6.5
@export var max_bank_roll_deg: float = 36.0

# --- Wing Energy & Abilities ---
@export_group("Wing Energy & Abilities")
@export var max_wing_energy: float = 5.0
@export var wing_regen_rate: float = 0.35
@export var flap_energy_cost: float = 1.0
@export var flap_upward_boost: float = 10.5
@export var flap_forward_boost: float = 8.5
@export var surge_speed: float = 31.0
@export var surge_duration: float = 0.34
@export var surge_cooldown: float = 1.6
@export var call_cooldown: float = 1.4
@export var call_pulse_duration: float = 0.75

# --- Camera ---
@export_group("Camera")
@export var base_fov: float = 60.0
@export var max_fov: float = 80.0
@export var fov_lerp_speed: float = 5.5
@export var camera_follow_speed: float = 6.0
@export var camera_roll_factor: float = 0.22
@export var mouse_look_sensitivity: float = 0.0035

# --- Trails ---
@export_group("Wingtip Trails")
@export var trail_lifetime_flight: float = 0.62
@export var trail_lifetime_ground: float = 0.26
@export var trail_base_width: float = 0.14
@export var trail_max_points: int = 44
@export var trail_min_sample_dist: float = 0.12

# --- Runtime State ---
var is_flying: bool = false
var wing_energy: float = 5.0

var facing_yaw: float = 0.0
var flight_yaw: float = 0.0
var flight_pitch: float = 0.0
var flight_speed: float = 17.5
var bank_roll: float = 0.0
var visual_pitch: float = 0.0

var cam_yaw: float = 0.0
var cam_pitch: float = -0.24
var _manual_cam_timer: float = 0.0

var _coyote_timer: float = 0.0
var _flight_entry_grace: float = 0.0
var _boost_velocity: Vector3 = Vector3.ZERO
var _surge_timer: float = 0.0
var _surge_cooldown_timer: float = 0.0
var _surge_dir: Vector3 = Vector3.FORWARD
var _call_cooldown_timer: float = 0.0
var _call_pulse_timer: float = 0.0
var _flap_anim_timer: float = 0.0
var _energy_flare: float = 0.0
var _anim_time: float = 0.0

# --- Node References ---
@onready var visual_pivot: Node3D = $VisualPivot
@onready var star_halo: MeshInstance3D = $VisualPivot/StarHalo
@onready var cape_left: Node3D = $VisualPivot/CapeLeft
@onready var cape_right: Node3D = $VisualPivot/CapeRight
@onready var wing_tip_left: Marker3D = get_node_or_null("VisualPivot/CapeLeft/WingTipLeft") as Marker3D
@onready var wing_tip_right: Marker3D = get_node_or_null("VisualPivot/CapeRight/WingTipRight") as Marker3D
@onready var spark_light: OmniLight3D = $VisualPivot/SparkLight
@onready var call_pulse_mesh: MeshInstance3D = get_node_or_null("VisualPivot/CallPulseMesh") as MeshInstance3D

@onready var camera_rig: Node3D = $CameraRig
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm3D
@onready var camera: Camera3D = $CameraRig/SpringArm3D/Camera3D

# --- Wingtip Ribbon Trail Data ---
var _trail_left_node: MeshInstance3D = null
var _trail_right_node: MeshInstance3D = null
var _trail_left_mesh: ImmediateMesh = null
var _trail_right_mesh: ImmediateMesh = null
var _trail_left_points: Array[Vector3] = []
var _trail_left_ages: Array[float] = []
var _trail_right_points: Array[Vector3] = []
var _trail_right_ages: Array[float] = []

var _base_halo_y: float = 1.02
var _base_light_energy: float = 2.2
var _call_pulse_mat: StandardMaterial3D = null


func _ready() -> void:
	wing_energy = max_wing_energy
	facing_yaw = rotation.y
	flight_yaw = facing_yaw
	cam_yaw = facing_yaw

	if spring_arm:
		spring_arm.add_excluded_object(get_rid())

	if camera:
		camera.fov = base_fov
		camera.current = true

	if star_halo:
		_base_halo_y = star_halo.position.y

	if spark_light:
		_base_light_energy = spark_light.light_energy

	if call_pulse_mesh:
		call_pulse_mesh.visible = false
		if call_pulse_mesh.material_override is StandardMaterial3D:
			_call_pulse_mat = (call_pulse_mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			call_pulse_mesh.material_override = _call_pulse_mat

	_setup_wingtip_trails()

	wing_energy_changed.emit(wing_energy, max_wing_energy)
	flight_mode_changed.emit(is_flying)


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		cam_yaw -= motion.relative.x * mouse_look_sensitivity
		cam_pitch = clampf(cam_pitch - motion.relative.y * mouse_look_sensitivity, deg_to_rad(-65.0), deg_to_rad(40.0))
		_manual_cam_timer = 1.2


func _physics_process(delta: float) -> void:
	_update_timers_and_regen(delta)

	if not input_enabled:
		_process_disabled_state(delta)
		return

	var steer_x: float = Input.get_axis("move_left", "move_right")
	var move_z: float = Input.get_axis("move_forward", "move_back")

	# Golden Resonance Call [Q]
	if Input.is_action_just_pressed("soul_spark") and _call_cooldown_timer <= 0.0:
		_trigger_soul_call()

	# Golden Forward Surge [E]
	if Input.is_action_just_pressed("blink") and _surge_cooldown_timer <= 0.0:
		_trigger_golden_surge(steer_x, move_z)

	if is_flying:
		_physics_flight(delta, steer_x, move_z)
	else:
		_physics_ground(delta, steer_x, move_z)

	move_and_slide()

	# Auto-exit flight upon touching solid temple stone / island surface
	if is_flying and _flight_entry_grace <= 0.0 and is_on_floor():
		_exit_flight()


func _process(delta: float) -> void:
	_anim_time += delta
	_update_visual_rig(delta)
	_update_camera(delta)
	_update_call_pulse(delta)
	_update_wingtip_trails(delta)


## Public API: Recharges Spark's wing energy (called by lanterns, clouds, birds, or updrafts).
func recharge_wing_energy(amount: float) -> void:
	if amount <= 0.0:
		return
	var previous: float = wing_energy
	wing_energy = clampf(wing_energy + amount, 0.0, max_wing_energy)
	_energy_flare = maxf(_energy_flare, 0.9)
	if not is_equal_approx(wing_energy, previous):
		wing_energy_changed.emit(wing_energy, max_wing_energy)


# ==============================================================================
# PHYSICS STATES
# ==============================================================================

func _update_timers_and_regen(delta: float) -> void:
	if _flight_entry_grace > 0.0:
		_flight_entry_grace = maxf(0.0, _flight_entry_grace - delta)
	if _surge_timer > 0.0:
		_surge_timer = maxf(0.0, _surge_timer - delta)
	if _surge_cooldown_timer > 0.0:
		_surge_cooldown_timer = maxf(0.0, _surge_cooldown_timer - delta)
	if _call_cooldown_timer > 0.0:
		_call_cooldown_timer = maxf(0.0, _call_cooldown_timer - delta)
	if _flap_anim_timer > 0.0:
		_flap_anim_timer = maxf(0.0, _flap_anim_timer - delta)
	if _manual_cam_timer > 0.0:
		_manual_cam_timer = maxf(0.0, _manual_cam_timer - delta)
	if _energy_flare > 0.0:
		_energy_flare = maxf(0.0, _energy_flare - delta * 2.2)

	# Decay boost impulse smoothly
	_boost_velocity = _boost_velocity.lerp(Vector3.ZERO, 1.0 - exp(-4.8 * delta))

	# Slow passive wing energy regeneration
	if wing_energy < max_wing_energy:
		var previous: float = wing_energy
		wing_energy = minf(max_wing_energy, wing_energy + wing_regen_rate * delta)
		if not is_equal_approx(wing_energy, previous):
			wing_energy_changed.emit(wing_energy, max_wing_energy)


func _process_disabled_state(delta: float) -> void:
	if is_flying:
		velocity = velocity.lerp(Vector3.ZERO, 1.0 - exp(-4.0 * delta))
	else:
		var horiz: Vector3 = Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, ground_deceleration * delta)
		velocity.x = horiz.x
		velocity.z = horiz.z
		if not is_on_floor():
			velocity.y -= gravity * delta
	move_and_slide()


func _physics_ground(delta: float, steer_x: float, move_z: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	# Camera-relative movement on marble bridges & islands
	var cam_forward: Vector3 = Vector3(-sin(cam_yaw), 0.0, -cos(cam_yaw))
	var cam_right: Vector3 = Vector3(cos(cam_yaw), 0.0, -sin(cam_yaw))
	var wish_dir: Vector3 = cam_right * steer_x - cam_forward * move_z

	var horiz_vel: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if wish_dir.length_squared() > 0.001:
		wish_dir = wish_dir.normalized()
		var target_horiz: Vector3 = wish_dir * ground_speed
		horiz_vel = horiz_vel.move_toward(target_horiz, ground_acceleration * delta)

		var target_yaw: float = atan2(-wish_dir.x, -wish_dir.z)
		facing_yaw = lerp_angle(facing_yaw, target_yaw, 1.0 - exp(-ground_turn_speed * delta))

		# Gently steer camera behind curving ground movement when not mouse-orbiting
		if _manual_cam_timer <= 0.0 and absf(steer_x) > 0.05:
			cam_yaw = lerp_angle(cam_yaw, facing_yaw, 1.0 - exp(-1.6 * delta))
	else:
		horiz_vel = horiz_vel.move_toward(Vector3.ZERO, ground_deceleration * delta)

	# Apply Golden Forward Surge if active
	if _surge_timer > 0.0:
		var surge_horiz: Vector3 = Vector3(_surge_dir.x, 0.0, _surge_dir.z)
		if surge_horiz.length_squared() > 0.001:
			horiz_vel = surge_horiz.normalized() * surge_speed

	velocity.x = horiz_vel.x + _boost_velocity.x
	velocity.z = horiz_vel.z + _boost_velocity.z

	# Jump on ground, or press Space again in mid-air to enter Free 3D Flight
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor() or _coyote_timer > 0.0:
			velocity.y = jump_velocity
			_coyote_timer = 0.0
			_flap_anim_timer = 0.28
		else:
			_enter_flight()
			return

	# Gravity (slightly floatier on descent for ethereal feel)
	if not is_on_floor():
		var g: float = gravity * (fall_gravity_multiplier if velocity.y < 0.0 else 1.0)
		velocity.y -= g * delta

	# Smoothly relax banking roll on ground
	var ground_turn_lean: float = -steer_x * deg_to_rad(10.0) if wish_dir.length_squared() > 0.01 else 0.0
	bank_roll = lerpf(bank_roll, ground_turn_lean, 1.0 - exp(-8.0 * delta))
	visual_pitch = lerpf(visual_pitch, -0.14 if wish_dir.length_squared() > 0.01 else 0.0, 1.0 - exp(-8.0 * delta))


func _physics_flight(delta: float, steer_x: float, move_z: float) -> void:
	# Steer yaw & bank roll with A/D (move_left / move_right)
	flight_yaw -= steer_x * flight_yaw_speed * delta
	facing_yaw = flight_yaw

	var target_bank: float = -steer_x * deg_to_rad(max_bank_roll_deg)
	bank_roll = lerpf(bank_roll, target_bank, 1.0 - exp(-7.5 * delta))

	# Pitch down (W / move_forward -> dive for speed) / Pitch up (S / move_back -> climb)
	if absf(move_z) > 0.01:
		flight_pitch += move_z * flight_pitch_speed * delta
	else:
		# Gently settle toward a graceful slight glide angle
		flight_pitch = lerpf(flight_pitch, deg_to_rad(-3.5), 1.0 - exp(-1.5 * delta))

	flight_pitch = clampf(flight_pitch, deg_to_rad(flight_min_pitch_deg), deg_to_rad(flight_max_pitch_deg))
	visual_pitch = lerpf(visual_pitch, flight_pitch, 1.0 - exp(-9.0 * delta))

	# Wing Flap Boost [Space]
	if Input.is_action_just_pressed("ui_accept"):
		_perform_wing_flap_boost()

	# Aerodynamic speed dynamics: diving builds speed, climbing trades speed for altitude
	var pitch_sin: float = sin(flight_pitch)
	if pitch_sin < 0.0:
		flight_speed += (-pitch_sin) * flight_dive_acceleration * delta
	elif pitch_sin > 0.0:
		flight_speed -= pitch_sin * flight_climb_deceleration * delta

	flight_speed = lerpf(flight_speed, flight_cruise_speed, 1.0 - exp(-flight_speed_relax_rate * delta))
	flight_speed = clampf(flight_speed, flight_min_speed, flight_max_speed)

	var forward_dir: Vector3 = _get_flight_forward()
	var target_velocity: Vector3 = forward_dir * flight_speed + Vector3(0.0, -flight_glide_sink, 0.0) + _boost_velocity

	if _surge_timer > 0.0:
		target_velocity = _surge_dir * surge_speed

	velocity = velocity.lerp(target_velocity, 1.0 - exp(-flight_responsiveness * delta))


func _enter_flight() -> void:
	if is_flying:
		return
	is_flying = true
	_flight_entry_grace = 0.25
	flight_yaw = facing_yaw
	flight_pitch = deg_to_rad(8.0)

	var horiz_speed: float = Vector2(velocity.x, velocity.z).length()
	flight_speed = maxf(horiz_speed, flight_cruise_speed)
	velocity.y = maxf(velocity.y, 5.0)
	_flap_anim_timer = 0.45
	_energy_flare = maxf(_energy_flare, 0.65)
	flight_mode_changed.emit(true)


func _exit_flight() -> void:
	if not is_flying:
		return
	is_flying = false
	flight_pitch = 0.0
	_boost_velocity = Vector3.ZERO
	flight_mode_changed.emit(false)


func _perform_wing_flap_boost() -> void:
	if wing_energy < flap_energy_cost:
		return

	wing_energy = maxf(0.0, wing_energy - flap_energy_cost)
	wing_energy_changed.emit(wing_energy, max_wing_energy)

	var forward_dir: Vector3 = _get_flight_forward()
	flight_speed = minf(flight_speed + flap_forward_boost, flight_max_speed + 5.0)
	_boost_velocity += Vector3.UP * flap_upward_boost + forward_dir * (flap_forward_boost * 0.55)
	flight_pitch = maxf(flight_pitch, deg_to_rad(14.0))
	_flap_anim_timer = 0.55
	_energy_flare = 1.1


func _trigger_golden_surge(steer_x: float, move_z: float) -> void:
	_surge_timer = surge_duration
	_surge_cooldown_timer = surge_cooldown
	_flap_anim_timer = maxf(_flap_anim_timer, 0.35)
	_energy_flare = 1.25

	if is_flying:
		_surge_dir = _get_flight_forward()
		flight_speed = maxf(flight_speed, flight_max_speed * 0.92)
		_boost_velocity += _surge_dir * 7.0
	else:
		var cam_forward: Vector3 = Vector3(-sin(cam_yaw), 0.0, -cos(cam_yaw))
		var cam_right: Vector3 = Vector3(cos(cam_yaw), 0.0, -sin(cam_yaw))
		var wish: Vector3 = cam_right * steer_x - cam_forward * move_z
		if wish.length_squared() > 0.01:
			_surge_dir = wish.normalized()
			facing_yaw = atan2(-_surge_dir.x, -_surge_dir.z)
		else:
			_surge_dir = Vector3(-sin(facing_yaw), 0.0, -cos(facing_yaw))


func _trigger_soul_call() -> void:
	_call_cooldown_timer = call_cooldown
	_call_pulse_timer = call_pulse_duration
	_energy_flare = 1.35
	soul_call_triggered.emit(global_position)


func _get_flight_forward() -> Vector3:
	var basis_flight: Basis = Basis.from_euler(Vector3(flight_pitch, flight_yaw, 0.0))
	return (basis_flight * Vector3.FORWARD).normalized()


# ==============================================================================
# VISUAL POLISH: CAPE BILLOWING, HALO, LIGHT, CALL PULSE, CAMERA, RIBBON TRAILS
# ==============================================================================

func _update_visual_rig(delta: float) -> void:
	if not visual_pivot:
		return

	# Orient VisualPivot with smooth yaw, pitch, and banking roll
	var target_basis: Basis = Basis.from_euler(Vector3(visual_pitch, facing_yaw, bank_roll))
	visual_pivot.basis = visual_pivot.basis.slerp(target_basis, 1.0 - exp(-12.0 * delta))

	# Gentle breathing float on VisualPivot when flying or idling
	var hover_bob: float = sin(_anim_time * (3.2 if is_flying else 2.4)) * (0.07 if is_flying else 0.03)
	visual_pivot.position.y = 0.9 + hover_bob

	# Rotating golden star halo above Spark's head
	if star_halo:
		var halo_spin: float = 1.6 + (_energy_flare * 4.5) + (1.2 if is_flying else 0.0)
		star_halo.rotate_y(halo_spin * delta)
		star_halo.position.y = _base_halo_y + sin(_anim_time * 3.6) * 0.045
		var halo_scale: float = 1.0 + _energy_flare * 0.18
		star_halo.scale = Vector3.ONE * halo_scale

	# Procedural billowing animation on left & right 3D cape wings
	if cape_left and cape_right:
		var speed_ratio: float = clampf(velocity.length() / flight_max_speed, 0.0, 1.2)
		var billow_freq: float = lerpf(3.2, 13.5, speed_ratio)
		var billow_amp: float = lerpf(0.07, 0.24, speed_ratio)
		var wave_l: float = sin(_anim_time * billow_freq) * billow_amp
		var wave_r: float = sin(_anim_time * billow_freq + 0.55) * billow_amp

		# Dramatic downward wing flap stroke when boosting
		var flap_stroke: float = 0.0
		if _flap_anim_timer > 0.0:
			var t: float = 1.0 - clampf(_flap_anim_timer / 0.55, 0.0, 1.0)
			flap_stroke = sin(t * PI) * 0.85

		var spread_angle: float = 0.08 if is_flying else -0.52
		var sweep_back: float = lerpf(0.18, 0.52, speed_ratio) if is_flying else lerpf(0.12, 0.42, speed_ratio)

		# Left wing (extends toward -X): positive Z rotation lifts outer tip down, negative lifts up
		cape_left.rotation = Vector3(
			0.12 + wave_l * 0.5,
			sweep_back + wave_l * 0.35,
			-(spread_angle - flap_stroke + wave_l)
		)
		# Right wing (extends toward +X): mirrored symmetrically
		cape_right.rotation = Vector3(
			0.12 + wave_r * 0.5,
			-(sweep_back + wave_r * 0.35),
			spread_angle - flap_stroke + wave_r
		)

	# Warm OmniLight3D intensity modulation on abilities & speed
	if spark_light:
		var target_energy: float = _base_light_energy + (_energy_flare * 2.4) + (0.45 if is_flying else 0.0)
		spark_light.light_energy = lerpf(spark_light.light_energy, target_energy, 1.0 - exp(-10.0 * delta))


func _update_camera(delta: float) -> void:
	if not camera_rig or not camera:
		return

	# Chase yaw & pitch smoothly behind Spark
	if _manual_cam_timer <= 0.0:
		if is_flying:
			cam_yaw = lerp_angle(cam_yaw, flight_yaw, 1.0 - exp(-camera_follow_speed * delta))
			var target_cam_pitch: float = clampf(flight_pitch * 0.65 - deg_to_rad(6.0), deg_to_rad(-48.0), deg_to_rad(28.0))
			cam_pitch = lerpf(cam_pitch, target_cam_pitch, 1.0 - exp(-camera_follow_speed * 0.85 * delta))
		else:
			cam_pitch = lerpf(cam_pitch, deg_to_rad(-14.0), 1.0 - exp(-4.0 * delta))

	camera_rig.rotation = Vector3(cam_pitch, cam_yaw, 0.0)

	# Dynamic FOV expansion during fast flight, wing flap boost, or golden surge
	var speed_factor: float = clampf((velocity.length() - 10.0) / (flight_max_speed - 10.0), 0.0, 1.0)
	var boost_fov: float = 0.0
	if _surge_timer > 0.0:
		boost_fov += 8.0
	if _flap_anim_timer > 0.0:
		boost_fov += 4.5 * clampf(_flap_anim_timer / 0.55, 0.0, 1.0)

	var target_fov: float = clampf(lerpf(base_fov, max_fov - 5.0, speed_factor) + boost_fov, base_fov, max_fov)
	camera.fov = lerpf(camera.fov, target_fov, 1.0 - exp(-fov_lerp_speed * delta))

	# Subtle camera roll following banking angle in flight
	var target_cam_roll: float = bank_roll * camera_roll_factor if is_flying else 0.0
	camera.rotation.z = lerpf(camera.rotation.z, target_cam_roll, 1.0 - exp(-6.5 * delta))


func _update_call_pulse(delta: float) -> void:
	if not call_pulse_mesh:
		return

	if _call_pulse_timer > 0.0:
		_call_pulse_timer = maxf(0.0, _call_pulse_timer - delta)
		var progress: float = 1.0 - (_call_pulse_timer / call_pulse_duration)
		var eased: float = 1.0 - pow(1.0 - progress, 3.0)
		call_pulse_mesh.visible = true
		var radius: float = lerpf(0.35, 9.5, eased)
		call_pulse_mesh.scale = Vector3.ONE * radius
		if _call_pulse_mat:
			var alpha: float = (1.0 - progress) * 0.42
			_call_pulse_mat.albedo_color = Color(1.0, 0.86, 0.42, alpha)
	else:
		call_pulse_mesh.visible = false


# ==============================================================================
# DUAL LUMINOUS GOLDEN 3D WINGTIP RIBBON TRAILS (ImmediateMesh, top_level = true)
# ==============================================================================

func _setup_wingtip_trails() -> void:
	var trail_mat: StandardMaterial3D = StandardMaterial3D.new()
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	trail_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	trail_mat.vertex_color_use_as_albedo = true
	trail_mat.albedo_color = Color(1.0, 0.9, 0.55, 1.0)

	_trail_left_mesh = ImmediateMesh.new()
	_trail_left_node = MeshInstance3D.new()
	_trail_left_node.name = "WingtipTrailLeft"
	_trail_left_node.mesh = _trail_left_mesh
	_trail_left_node.material_override = trail_mat
	_trail_left_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_trail_left_node.top_level = true
	add_child(_trail_left_node)
	_trail_left_node.global_transform = Transform3D.IDENTITY

	_trail_right_mesh = ImmediateMesh.new()
	_trail_right_node = MeshInstance3D.new()
	_trail_right_node.name = "WingtipTrailRight"
	_trail_right_node.mesh = _trail_right_mesh
	_trail_right_node.material_override = trail_mat
	_trail_right_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_trail_right_node.top_level = true
	add_child(_trail_right_node)
	_trail_right_node.global_transform = Transform3D.IDENTITY


func _update_wingtip_trails(delta: float) -> void:
	var lifetime: float = trail_lifetime_flight if (is_flying or _surge_timer > 0.0) else trail_lifetime_ground
	var left_pos: Vector3 = wing_tip_left.global_position if wing_tip_left else (global_position + Vector3(-1.0, 1.0, 0.0))
	var right_pos: Vector3 = wing_tip_right.global_position if wing_tip_right else (global_position + Vector3(1.0, 1.0, 0.0))

	_sample_trail_points(_trail_left_points, _trail_left_ages, left_pos, delta, lifetime)
	_sample_trail_points(_trail_right_points, _trail_right_ages, right_pos, delta, lifetime)

	var width_mult: float = 1.0 + (0.55 if is_flying else 0.0) + (_energy_flare * 0.45)
	_rebuild_ribbon_mesh(_trail_left_mesh, _trail_left_points, _trail_left_ages, lifetime, trail_base_width * width_mult)
	_rebuild_ribbon_mesh(_trail_right_mesh, _trail_right_points, _trail_right_ages, lifetime, trail_base_width * width_mult)


func _sample_trail_points(points: Array[Vector3], ages: Array[float], new_pos: Vector3, delta: float, lifetime: float) -> void:
	# Age existing points and prune expired ones from the tail (index 0 is oldest)
	var write_idx: int = 0
	for i: int in range(ages.size()):
		var next_age: float = ages[i] + delta
		if next_age < lifetime:
			points[write_idx] = points[i]
			ages[write_idx] = next_age
			write_idx += 1
	points.resize(write_idx)
	ages.resize(write_idx)

	# Append new wingtip point when moved enough to avoid degenerate segments
	var should_append: bool = points.is_empty()
	if not should_append:
		var last_pt: Vector3 = points[points.size() - 1]
		if last_pt.distance_squared_to(new_pos) >= trail_min_sample_dist * trail_min_sample_dist:
			should_append = true

	if should_append:
		if points.size() >= trail_max_points:
			points.remove_at(0)
			ages.remove_at(0)
		points.append(new_pos)
		ages.append(0.0)


func _rebuild_ribbon_mesh(
	imm_mesh: ImmediateMesh,
	points: Array[Vector3],
	ages: Array[float],
	lifetime: float,
	base_width: float
) -> void:
	if imm_mesh == null:
		return

	imm_mesh.clear_surfaces()
	var count: int = points.size()
	if count < 2:
		return

	var cam_pos: Vector3 = camera.global_position if camera else (global_position + Vector3(0.0, 4.0, 10.0))

	imm_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i: int in range(count):
		var p: Vector3 = points[i]
		var tangent: Vector3
		if i == 0:
			tangent = points[1] - p
		elif i == count - 1:
			tangent = p - points[i - 1]
		else:
			tangent = points[i + 1] - points[i - 1]

		if tangent.length_squared() < 0.00001:
			tangent = Vector3.FORWARD
		else:
			tangent = tangent.normalized()

		var to_cam: Vector3 = (cam_pos - p).normalized()
		var side: Vector3 = tangent.cross(to_cam)
		if side.length_squared() < 0.0001:
			side = tangent.cross(Vector3.UP)
		if side.length_squared() < 0.0001:
			side = Vector3.RIGHT
		else:
			side = side.normalized()

		var life_t: float = clampf(1.0 - (ages[i] / maxf(lifetime, 0.01)), 0.0, 1.0)
		var index_t: float = float(i) / float(count - 1)
		var taper: float = life_t * index_t
		var half_w: float = base_width * 0.5 * taper

		# HDR golden glow fading smoothly toward transparent amber at the tail
		var col: Color = Color(
			lerpf(1.0, 1.6, taper),
			lerpf(0.62, 1.15, taper),
			lerpf(0.18, 0.48, taper),
			taper * (0.92 if is_flying else 0.55)
		)

		imm_mesh.surface_set_color(col)
		imm_mesh.surface_add_vertex(p + side * half_w)
		imm_mesh.surface_set_color(col)
		imm_mesh.surface_add_vertex(p - side * half_w)

	imm_mesh.surface_end()
