extends CharacterBody3D

## Stray-inspired agile 3D protagonist controller (Spark) with seamless Mac
## trackpad/mouse third-person camera, contextual ledge leap assist, intuitive
## omnidirectional "fly where you look" flight, wing flap boosts, golden forward
## surge, resonance call, shader-driven flame & cape animation, radiant wing
## flares, and dual ImmediateMesh wingtip trails.

signal soul_call_triggered(origin: Vector3)
signal wing_energy_changed(current: float, max_energy: float)
signal flight_mode_changed(is_flying: bool)

# --- Input Toggle (used by intro bridge / cutscenes) ---
@export var input_enabled: bool = true:
	set(value):
		var changed: bool = input_enabled != value
		input_enabled = value
		if not is_inside_tree():
			return
		if changed:
			if input_enabled:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# --- Ground Movement (Stray Cat Feel) ---
@export_group("Ground Movement")
@export var ground_speed: float = 12.0
@export var sprint_speed: float = 17.5
@export var ground_acceleration: float = 34.0
@export var ground_deceleration: float = 28.0
@export var ground_turn_speed: float = 16.0
@export var jump_velocity: float = 11.5
@export var gravity: float = 24.0
@export var fall_gravity_multiplier: float = 0.82
@export var coyote_time: float = 0.16

# --- Contextual Ledge / Perch Leap Assist ---
@export_group("Ledge Leap Assist")
@export var ledge_probe_min_dist: float = 3.5
@export var ledge_probe_max_dist: float = 9.5
@export var ledge_min_height: float = 0.6
@export var ledge_max_height: float = 5.0
@export var ledge_max_horiz_speed: float = 18.5

# --- Omnidirectional 3D Flight ("Fly Where You Look") ---
@export_group("Free 3D Flight")
@export var flight_cruise_speed: float = 19.0
@export var flight_sprint_speed: float = 26.0
@export var flight_strafe_speed: float = 14.5
@export var flight_back_speed: float = 9.5
@export var flight_descend_speed: float = 11.5
@export var flight_max_speed: float = 34.0
@export var flight_glide_sink: float = 0.85
@export var flight_responsiveness: float = 7.5
@export var max_bank_roll_deg: float = 34.0

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
@export var call_pulse_duration: float = 0.78

# --- Camera (Stray Third-Person Framing) ---
@export_group("Camera")
@export var base_fov: float = 58.0
@export var max_fov: float = 74.0
@export var fov_lerp_speed: float = 5.2
@export var camera_follow_speed: float = 4.2
@export var auto_center_delay: float = 1.8
@export var camera_roll_factor: float = 0.22
@export var spring_length_ground: float = 6.8
@export var spring_length_flight: float = 8.8
@export var spring_length_surge_bonus: float = 1.6
@export var spring_arm_lerp_speed: float = 5.0
@export var mouse_look_sensitivity: float = 0.0035
@export var zoom_min_offset: float = -3.0
@export var zoom_max_offset: float = 5.5
@export var zoom_step: float = 0.75
@export var zoom_lerp_speed: float = 9.0
@export var keyboard_cam_yaw_speed: float = 2.2
@export var keyboard_cam_pitch_speed: float = 1.6

# --- Trails ---
@export_group("Wingtip Trails")
@export var trail_lifetime_flight: float = 0.74
@export var trail_lifetime_ground: float = 0.28
@export var trail_base_width: float = 0.16
@export var trail_max_points: int = 56
@export var trail_min_sample_dist: float = 0.09

# --- Runtime State ---
var is_flying: bool = false
var wing_energy: float = 5.0

var facing_yaw: float = 0.0
var bank_roll: float = 0.0
var visual_pitch: float = 0.0

var cam_yaw: float = 0.0
var cam_pitch: float = -0.22
var cam_zoom_offset: float = 0.0
var _target_zoom_offset: float = 0.0
var _manual_cam_timer: float = 0.0
var _was_input_enabled: bool = false

var _coyote_timer: float = 0.0
var _ledge_leap_timer: float = 0.0
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
@onready var core_flame: MeshInstance3D = get_node_or_null("VisualPivot/CoreFlame") as MeshInstance3D
@onready var star_halo: MeshInstance3D = $VisualPivot/StarHalo
@onready var cape_left: Node3D = $VisualPivot/CapeLeft
@onready var cape_right: Node3D = $VisualPivot/CapeRight
@onready var cape_left_mesh: MeshInstance3D = get_node_or_null("VisualPivot/CapeLeft/WingMesh") as MeshInstance3D
@onready var wing_flare_left: MeshInstance3D = get_node_or_null("VisualPivot/CapeLeft/WingFlare") as MeshInstance3D
@onready var wing_flare_right: MeshInstance3D = get_node_or_null("VisualPivot/CapeRight/WingFlare") as MeshInstance3D
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

const SPARK_MODEL_PATH: String = "res://assets/models/characters/spark.glb"
const SPARK_ENERGY_SHADER_PATH: String = "res://shaders/spark_energy.gdshader"

var _base_halo_y: float = 1.18
var _base_light_energy: float = 0.52
var _call_pulse_shader_mat: ShaderMaterial = null
var _flame_shader_mat: ShaderMaterial = null
var _cape_shader_mat: ShaderMaterial = null
var _wing_flare_mat: StandardMaterial3D = null
var _spark_model_instance: Node3D = null
var _spark_halo_node: Node3D = null
var _spark_halo_base_y: float = 1.75
var _spark_energy_materials: Array[ShaderMaterial] = []


func _ready() -> void:
	wing_energy = max_wing_energy
	facing_yaw = rotation.y
	cam_yaw = facing_yaw
	_was_input_enabled = input_enabled

	if input_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if spring_arm:
		spring_arm.add_excluded_object(get_rid())
		spring_arm.spring_length = spring_length_ground

	if camera:
		camera.fov = base_fov
		camera.current = true

	if star_halo:
		_base_halo_y = star_halo.position.y

	if spark_light:
		spark_light.light_color = Color("#FFCEE4")
		spark_light.light_energy = _base_light_energy
		spark_light.omni_range = 7.5

	if core_flame and core_flame.material_override is ShaderMaterial:
		_flame_shader_mat = core_flame.material_override as ShaderMaterial

	if cape_left_mesh and cape_left_mesh.material_override is ShaderMaterial:
		_cape_shader_mat = cape_left_mesh.material_override as ShaderMaterial

	if wing_flare_left and wing_flare_left.material_override is StandardMaterial3D:
		_wing_flare_mat = (wing_flare_left.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		wing_flare_left.material_override = _wing_flare_mat
		if wing_flare_right:
			wing_flare_right.material_override = _wing_flare_mat

	if call_pulse_mesh:
		call_pulse_mesh.visible = false
		if call_pulse_mesh.material_override is ShaderMaterial:
			_call_pulse_shader_mat = (call_pulse_mesh.material_override as ShaderMaterial).duplicate() as ShaderMaterial
			call_pulse_mesh.material_override = _call_pulse_shader_mat

	_load_spark_model()
	_setup_wingtip_trails()

	wing_energy_changed.emit(wing_energy, max_wing_energy)
	flight_mode_changed.emit(is_flying)


func _load_spark_model() -> void:
	if not visual_pivot or not ResourceLoader.exists(SPARK_MODEL_PATH):
		return

	var packed: PackedScene = load(SPARK_MODEL_PATH) as PackedScene
	if packed == null:
		return

	var inst: Node = packed.instantiate()
	if not (inst is Node3D):
		inst.queue_free()
		return

	_spark_model_instance = inst as Node3D
	_spark_model_instance.name = "SparkModel"
	# VisualPivot sits at y = 0.9 while spark.glb has its base at y = 0.0
	_spark_model_instance.position = Vector3(0.0, -0.9, 0.0)
	visual_pivot.add_child(_spark_model_instance)

	_spark_halo_node = _spark_model_instance.find_child("SparkStarHalo", true, false) as Node3D
	if _spark_halo_node != null:
		_spark_halo_base_y = _spark_halo_node.position.y

	_apply_spark_energy_shader(_spark_model_instance)

	# Hide legacy procedural body/cape/halo meshes while keeping WingFlare, CallPulseMesh,
	# SparkLight, and WingTipLeft/WingTipRight (for ImmediateMesh trails) active and aligned.
	var legacy_paths: Array[String] = [
		"CoreFlame",
		"HeadCrown",
		"FlameCrest",
		"FlameTail",
		"CollarRing",
		"InnerMantle",
		"StarHalo",
		"CapeLeft/WingMesh",
		"CapeRight/WingMesh",
	]
	for rel_path: String in legacy_paths:
		var legacy_node: Node3D = visual_pivot.get_node_or_null(rel_path) as Node3D
		if legacy_node != null:
			legacy_node.visible = false


func _apply_spark_energy_shader(root: Node) -> void:
	if not ResourceLoader.exists(SPARK_ENERGY_SHADER_PATH):
		return
	var energy_shader: Shader = load(SPARK_ENERGY_SHADER_PATH) as Shader
	if energy_shader == null:
		return

	_spark_energy_materials.clear()
	_apply_spark_energy_shader_recursive(root, energy_shader)


func _apply_spark_energy_shader_recursive(node: Node, energy_shader: Shader) -> void:
	if node is MeshInstance3D:
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		var mesh_res: Mesh = mesh_inst.mesh
		if mesh_res != null:
			var node_name: String = mesh_inst.name
			var is_halo: bool = node_name == "SparkStarHalo"
			var is_wing_ribbon: bool = node_name.begins_with("SparkWingRibbon")
			var is_droplet: bool = node_name == "SparkDroplets"
			var surface_count: int = mesh_res.get_surface_count()

			if is_wing_ribbon or is_halo:
				mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

			for i: int in range(surface_count):
				var src_mat: Material = mesh_inst.get_active_material(i)
				if src_mat == null:
					src_mat = mesh_res.surface_get_material(i)

				var smat: ShaderMaterial = ShaderMaterial.new()
				smat.shader = energy_shader

				var mat_name: String = src_mat.resource_name if src_mat != null else ""

				# Default: SparkCrystalBody (pearlescent liquid-crystal glass)
				var albedo_col: Color = Color.html("#F7EEF6")
				var shadow_col: Color = Color.html("#8B5BB8")
				var emit_col: Color = Color.html("#F4A0C8")
				var rim_col: Color = Color.html("#9CEBFF")
				var irid_col: Color = Color.html("#B48AF2")
				var emit_str: float = 0.15
				var metallic_v: float = 0.12
				var roughness_v: float = 0.11
				var clearcoat_v: float = 0.95
				var alpha_v: float = 0.92
				var irid_str: float = 1.05
				var wing_flag: float = 0.0
				var droplet_flag: float = 0.0
				var sway_v: float = 1.0

				if is_wing_ribbon or mat_name.contains("WingRibbon"):
					# Gossamer iridescent sakura-orchid-aqua ribbon-wings
					albedo_col = Color.html("#F6DCFA")
					shadow_col = Color.html("#8C5CD6")
					emit_col = Color.html("#B48AF2")
					rim_col = Color.html("#9CEBFF")
					irid_col = Color.html("#F4A0C8")
					emit_str = 0.20
					metallic_v = 0.10
					roughness_v = 0.15
					clearcoat_v = 0.85
					alpha_v = 0.74
					irid_str = 1.35
					wing_flag = 1.0
					sway_v = 1.0
				elif is_droplet or mat_name.contains("Droplets"):
					# Orbiting liquid-crystal splash light-droplets
					albedo_col = Color.html("#EFFAFF")
					shadow_col = Color.html("#7A68C8")
					emit_col = Color.html("#9CEBFF")
					rim_col = Color.html("#FFFFFF")
					irid_col = Color.html("#F4A0C8")
					emit_str = 0.22
					metallic_v = 0.18
					roughness_v = 0.08
					clearcoat_v = 1.0
					alpha_v = 0.88
					irid_str = 1.25
					droplet_flag = 1.0
					sway_v = 1.0
				elif is_halo or mat_name.contains("StarHalo"):
					# Floating celestial starlight crescent & star-crystal halo
					albedo_col = Color.html("#E6F8FF")
					shadow_col = Color.html("#7A84D8")
					emit_col = Color.html("#9CEBFF")
					rim_col = Color.html("#FFF5FA")
					irid_col = Color.html("#B48AF2")
					emit_str = 0.26
					metallic_v = 0.24
					roughness_v = 0.09
					clearcoat_v = 1.0
					alpha_v = 0.95
					irid_str = 1.15
					sway_v = 0.0
				elif mat_name.contains("CrystalBody"):
					# Explicit match for SparkCrystalBodyMat (uses pearlescent crystal defaults above)
					pass
				elif src_mat is StandardMaterial3D:
					var std_mat: StandardMaterial3D = src_mat as StandardMaterial3D
					albedo_col = std_mat.albedo_color
					if std_mat.emission_enabled:
						emit_col = std_mat.emission
						emit_str = clampf(std_mat.emission_energy_multiplier * 0.14, 0.10, 0.22)
					metallic_v = clampf(std_mat.metallic, 0.08, 0.28)
					roughness_v = clampf(std_mat.roughness, 0.08, 0.18)

				# Pass Color directly so Godot converts source_color uniforms from sRGB to linear HDR
				smat.set_shader_parameter("base_albedo", albedo_col)
				smat.set_shader_parameter("shadow_tint", shadow_col)
				smat.set_shader_parameter("emission_color", emit_col)
				smat.set_shader_parameter("rim_color", rim_col)
				smat.set_shader_parameter("iridescence_tint", irid_col)
				smat.set_shader_parameter("emission_strength", emit_str)
				smat.set_shader_parameter("metallic_val", metallic_v)
				smat.set_shader_parameter("roughness_val", roughness_v)
				smat.set_shader_parameter("clearcoat_val", clearcoat_v)
				smat.set_shader_parameter("alpha_base", alpha_v)
				smat.set_shader_parameter("iridescence_strength", irid_str)
				smat.set_shader_parameter("is_wing_ribbon", wing_flag)
				smat.set_shader_parameter("is_droplet", droplet_flag)
				smat.set_shader_parameter("sway_scale", sway_v)

				mesh_inst.set_surface_override_material(i, smat)
				_spark_energy_materials.append(smat)

	for child: Node in node.get_children():
		_apply_spark_energy_shader_recursive(child, energy_shader)


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return

	if event is InputEventKey:
		var key_ev: InputEventKey = event as InputEventKey
		if key_ev.pressed and not key_ev.echo:
			if key_ev.keycode == KEY_ESCAPE or key_ev.keycode == KEY_TAB:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
					get_viewport().set_input_as_handled()
				return

	if event is InputEventMouseButton:
		var btn_ev: InputEventMouseButton = event as InputEventMouseButton
		if btn_ev.pressed:
			if btn_ev.button_index == MOUSE_BUTTON_LEFT:
				if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			elif btn_ev.button_index == MOUSE_BUTTON_WHEEL_UP:
				_target_zoom_offset = clampf(_target_zoom_offset - zoom_step, zoom_min_offset, zoom_max_offset)
			elif btn_ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_target_zoom_offset = clampf(_target_zoom_offset + zoom_step, zoom_min_offset, zoom_max_offset)

	if event is InputEventPanGesture:
		var pan_ev: InputEventPanGesture = event as InputEventPanGesture
		_target_zoom_offset = clampf(_target_zoom_offset + pan_ev.delta.y * 0.42, zoom_min_offset, zoom_max_offset)

	if event is InputEventMouseMotion:
		var is_captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		var is_dragging: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if is_captured or is_dragging:
			var motion: InputEventMouseMotion = event as InputEventMouseMotion
			cam_yaw -= motion.relative.x * mouse_look_sensitivity
			cam_pitch = clampf(cam_pitch - motion.relative.y * mouse_look_sensitivity, deg_to_rad(-68.0), deg_to_rad(52.0))
			_manual_cam_timer = auto_center_delay


func _physics_process(delta: float) -> void:
	_update_timers_and_regen(delta)

	if input_enabled != _was_input_enabled:
		_was_input_enabled = input_enabled
		if input_enabled:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if not input_enabled:
		_process_disabled_state(delta)
		return

	# Use physical WASD for Spark movement so Arrow keys cleanly orbit the camera
	var steer_x: float = (1.0 if Input.is_physical_key_pressed(KEY_D) else 0.0) - (1.0 if Input.is_physical_key_pressed(KEY_A) else 0.0)
	var move_z: float = (1.0 if Input.is_physical_key_pressed(KEY_S) else 0.0) - (1.0 if Input.is_physical_key_pressed(KEY_W) else 0.0)

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

	# Gentle Cloud-Sea Updraft Safety Cushion: catch Spark before falling into the void
	if global_position.y < -16.0:
		if not is_flying:
			_enter_flight()
		velocity.y = maxf(velocity.y, 12.0)
		_boost_velocity.y = maxf(_boost_velocity.y, 6.0)
		_energy_flare = maxf(_energy_flare, 0.85)
		recharge_wing_energy(wing_regen_rate * 4.0 * delta)

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
	_energy_flare = maxf(_energy_flare, 0.95)
	if not is_equal_approx(wing_energy, previous):
		wing_energy_changed.emit(wing_energy, max_wing_energy)


# ==============================================================================
# PHYSICS STATES
# ==============================================================================

func _update_timers_and_regen(delta: float) -> void:
	if _flight_entry_grace > 0.0:
		_flight_entry_grace = maxf(0.0, _flight_entry_grace - delta)
	if _ledge_leap_timer > 0.0:
		_ledge_leap_timer = maxf(0.0, _ledge_leap_timer - delta)
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
		_energy_flare = maxf(0.0, _energy_flare - delta * 2.1)

	# Decay boost impulse smoothly
	_boost_velocity = _boost_velocity.lerp(Vector3.ZERO, 1.0 - exp(-4.8 * delta))

	# Slow passive wing energy regeneration
	if wing_energy < max_wing_energy:
		var previous: float = wing_energy
		wing_energy = minf(max_wing_energy, wing_energy + wing_regen_rate * delta)
		if not is_equal_approx(wing_energy, previous):
			wing_energy_changed.emit(wing_energy, max_wing_energy)


func _process_disabled_state(delta: float) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_flying:
		velocity = velocity.lerp(Vector3.ZERO, 1.0 - exp(-4.0 * delta))
	else:
		var horiz: Vector3 = Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, ground_deceleration * delta)
		velocity.x = horiz.x
		velocity.z = horiz.z
		if not is_on_floor():
			velocity.y -= gravity * delta
	move_and_slide()
	if global_position.y < -16.0:
		velocity.y = maxf(velocity.y, 12.0)


func _physics_ground(delta: float, steer_x: float, move_z: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
		_ledge_leap_timer = 0.0
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	var is_sprinting: bool = Input.is_physical_key_pressed(KEY_SHIFT)
	var active_ground_speed: float = sprint_speed if is_sprinting else ground_speed

	# Camera-relative movement on marble bridges & islands
	var cam_forward: Vector3 = Vector3(-sin(cam_yaw), 0.0, -cos(cam_yaw))
	var cam_right: Vector3 = Vector3(cos(cam_yaw), 0.0, -sin(cam_yaw))
	var wish_dir: Vector3 = cam_right * steer_x - cam_forward * move_z
	var has_move_input: bool = wish_dir.length_squared() > 0.001

	var horiz_vel: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var turn_angle_diff: float = 0.0

	if has_move_input:
		wish_dir = wish_dir.normalized()
		var target_horiz: Vector3 = wish_dir * active_ground_speed
		var accel_rate: float = ground_acceleration * (0.35 if _ledge_leap_timer > 0.0 else 1.0)
		horiz_vel = horiz_vel.move_toward(target_horiz, accel_rate * delta)

		var target_yaw: float = atan2(-wish_dir.x, -wish_dir.z)
		turn_angle_diff = wrapf(target_yaw - facing_yaw, -PI, PI)
		facing_yaw = lerp_angle(facing_yaw, target_yaw, 1.0 - exp(-ground_turn_speed * delta))
	elif _ledge_leap_timer <= 0.0:
		horiz_vel = horiz_vel.move_toward(Vector3.ZERO, ground_deceleration * delta)

	# Apply Golden Forward Surge if active
	if _surge_timer > 0.0:
		var surge_horiz: Vector3 = Vector3(_surge_dir.x, 0.0, _surge_dir.z)
		if surge_horiz.length_squared() > 0.001:
			horiz_vel = surge_horiz.normalized() * surge_speed

	velocity.x = horiz_vel.x + _boost_velocity.x
	velocity.z = horiz_vel.z + _boost_velocity.z

	# Jump on ground (with Stray contextual ledge leap assist), or press Space in mid-air for Free Flight
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor() or _coyote_timer > 0.0:
			var did_ledge_leap: bool = false
			if has_move_input and move_z <= 0.1:
				did_ledge_leap = _try_contextual_ledge_leap(wish_dir)
			if not did_ledge_leap:
				velocity.y = jump_velocity
				_coyote_timer = 0.0
				_flap_anim_timer = 0.28
		else:
			_enter_flight()
			return

	# Gravity (slightly floatier on descent for graceful cat-like arc)
	if not is_on_floor():
		var g: float = gravity * (fall_gravity_multiplier if velocity.y < 0.0 else 1.0)
		velocity.y -= g * delta

	# Natural cat-like lean into turns and forward sprint pitch
	var ground_turn_lean: float = 0.0
	if has_move_input:
		ground_turn_lean = clampf(turn_angle_diff * 0.65 - steer_x * 0.14, -deg_to_rad(18.0), deg_to_rad(18.0))
	bank_roll = lerpf(bank_roll, ground_turn_lean, 1.0 - exp(-10.0 * delta))

	var target_pitch: float = 0.0
	if not is_on_floor():
		target_pitch = clampf(velocity.y * 0.025, -0.22, 0.24)
	elif has_move_input:
		target_pitch = -0.19 if is_sprinting else -0.12
	visual_pitch = lerpf(visual_pitch, target_pitch, 1.0 - exp(-9.5 * delta))


func _try_contextual_ledge_leap(move_dir: Vector3) -> bool:
	var world_3d: World3D = get_world_3d()
	if world_3d == null:
		return false
	var space_state: PhysicsDirectSpaceState3D = world_3d.direct_space_state
	if space_state == null:
		return false

	var feet_pos: Vector3 = global_position
	var exclude_rids: Array[RID] = [get_rid()]
	var probe_steps: int = 5
	var step_dist: float = (ledge_probe_max_dist - ledge_probe_min_dist) / float(probe_steps - 1)

	for i: int in range(probe_steps):
		var dist: float = ledge_probe_min_dist + step_dist * float(i)
		var probe_xz: Vector3 = feet_pos + move_dir * dist
		var ray_from: Vector3 = probe_xz + Vector3(0.0, ledge_max_height + 0.6, 0.0)
		var ray_to: Vector3 = probe_xz + Vector3(0.0, ledge_min_height - 0.2, 0.0)

		var down_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
		down_query.exclude = exclude_rids
		down_query.collide_with_areas = false
		down_query.collide_with_bodies = true

		var hit: Dictionary = space_state.intersect_ray(down_query)
		if hit.is_empty():
			continue

		var hit_pos: Vector3 = hit.get("position", Vector3.ZERO)
		var hit_normal: Vector3 = hit.get("normal", Vector3.UP)
		if hit_normal.y < 0.72:
			continue

		var dy: float = hit_pos.y - feet_pos.y
		if dy < ledge_min_height or dy > ledge_max_height:
			continue

		# Verify headroom above the landing perch
		var clearance_from: Vector3 = hit_pos + Vector3(0.0, 0.25, 0.0)
		var clearance_to: Vector3 = hit_pos + Vector3(0.0, 1.75, 0.0)
		var clear_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(clearance_from, clearance_to)
		clear_query.exclude = exclude_rids
		clear_query.collide_with_areas = false
		clear_query.collide_with_bodies = true
		if not space_state.intersect_ray(clear_query).is_empty():
			continue

		# Compute smooth ballistic arc velocity onto the perch
		var apex_height: float = maxf(dy + 1.15, 1.8)
		var vy: float = sqrt(2.0 * gravity * apex_height)
		var t_up: float = vy / maxf(gravity, 0.01)
		var drop_h: float = maxf(apex_height - dy, 0.15)
		var fall_g: float = maxf(gravity * fall_gravity_multiplier, 0.01)
		var t_down: float = sqrt(2.0 * drop_h / fall_g)
		var total_time: float = maxf(t_up + t_down, 0.28)

		var target_pos: Vector3 = hit_pos + Vector3(0.0, 0.15, 0.0)
		var horiz_delta: Vector3 = Vector3(target_pos.x - feet_pos.x, 0.0, target_pos.z - feet_pos.z)
		var leap_horiz_vel: Vector3 = horiz_delta / total_time
		if leap_horiz_vel.length() > ledge_max_horiz_speed:
			leap_horiz_vel = leap_horiz_vel.normalized() * ledge_max_horiz_speed

		velocity.x = leap_horiz_vel.x
		velocity.z = leap_horiz_vel.z
		velocity.y = vy
		facing_yaw = atan2(-move_dir.x, -move_dir.z)
		_coyote_timer = 0.0
		_ledge_leap_timer = minf(total_time * 0.65, 0.42)
		_flap_anim_timer = 0.36
		_energy_flare = maxf(_energy_flare, 0.55)
		return true

	return false


func _physics_flight(delta: float, steer_x: float, move_z: float) -> void:
	# Wing Flap Boost [Space]
	if Input.is_action_just_pressed("ui_accept"):
		_perform_wing_flap_boost()

	var cam_forward_3d: Vector3 = _get_camera_forward_3d()
	var cam_right_horiz: Vector3 = Vector3(cos(cam_yaw), 0.0, -sin(cam_yaw))
	var forward_input: float = -move_z
	var is_sprinting: bool = Input.is_physical_key_pressed(KEY_SHIFT)
	var is_descending: bool = Input.is_physical_key_pressed(KEY_CTRL) or Input.is_physical_key_pressed(KEY_C)

	var target_velocity: Vector3 = Vector3.ZERO

	# W flies directly along the 3D camera look vector (look up to climb, look down to dive)
	if forward_input > 0.01:
		var fwd_speed: float = flight_sprint_speed if is_sprinting else flight_cruise_speed
		if cam_forward_3d.y < -0.15:
			fwd_speed += (-cam_forward_3d.y) * 5.0
		target_velocity += cam_forward_3d * (forward_input * fwd_speed)
	elif forward_input < -0.01:
		# S gently brakes / glides backward
		target_velocity += cam_forward_3d * (forward_input * flight_back_speed)

	# A/D smoothly strafes left and right relative to camera horizontal right
	if absf(steer_x) > 0.01:
		target_velocity += cam_right_horiz * (steer_x * flight_strafe_speed)

	# Ctrl / C descends gracefully
	if is_descending:
		target_velocity.y -= flight_descend_speed
	elif forward_input <= 0.01:
		target_velocity.y -= flight_glide_sink
	else:
		target_velocity.y -= flight_glide_sink * 0.25

	target_velocity += _boost_velocity

	if _surge_timer > 0.0:
		target_velocity = _surge_dir * surge_speed
	elif target_velocity.length() > flight_max_speed:
		target_velocity = target_velocity.normalized() * flight_max_speed

	velocity = velocity.lerp(target_velocity, 1.0 - exp(-flight_responsiveness * delta))

	# Smoothly orient Spark's visual body toward her 3D velocity with natural banking
	var horiz_vel: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var horiz_speed: float = horiz_vel.length()
	if horiz_speed > 0.9:
		var vel_yaw: float = atan2(-horiz_vel.x, -horiz_vel.z)
		var yaw_diff: float = wrapf(vel_yaw - facing_yaw, -PI, PI)
		facing_yaw = lerp_angle(facing_yaw, vel_yaw, 1.0 - exp(-9.5 * delta))

		var max_bank_rad: float = deg_to_rad(max_bank_roll_deg)
		var target_bank: float = clampf(yaw_diff * 1.15 - steer_x * 0.42, -max_bank_rad, max_bank_rad)
		bank_roll = lerpf(bank_roll, target_bank, 1.0 - exp(-8.5 * delta))

		var target_pitch: float = clampf(atan2(velocity.y, maxf(horiz_speed, 4.0)), deg_to_rad(-44.0), deg_to_rad(44.0))
		visual_pitch = lerpf(visual_pitch, target_pitch, 1.0 - exp(-8.5 * delta))
	else:
		facing_yaw = lerp_angle(facing_yaw, cam_yaw, 1.0 - exp(-5.0 * delta))
		bank_roll = lerpf(bank_roll, -steer_x * deg_to_rad(14.0), 1.0 - exp(-7.0 * delta))
		visual_pitch = lerpf(visual_pitch, clampf(velocity.y * 0.04, -0.35, 0.35), 1.0 - exp(-7.0 * delta))


func _enter_flight() -> void:
	if is_flying:
		return
	is_flying = true
	_flight_entry_grace = 0.25
	_ledge_leap_timer = 0.0

	velocity.y = maxf(velocity.y, 5.5)
	_flap_anim_timer = 0.45
	_energy_flare = maxf(_energy_flare, 0.72)
	flight_mode_changed.emit(true)


func _exit_flight() -> void:
	if not is_flying:
		return
	is_flying = false
	_boost_velocity = Vector3.ZERO
	flight_mode_changed.emit(false)


func _perform_wing_flap_boost() -> void:
	if wing_energy < flap_energy_cost:
		return

	wing_energy = maxf(0.0, wing_energy - flap_energy_cost)
	wing_energy_changed.emit(wing_energy, max_wing_energy)

	var cam_forward_3d: Vector3 = _get_camera_forward_3d()
	velocity.y = maxf(velocity.y + flap_upward_boost * 0.65, flap_upward_boost)
	_boost_velocity += Vector3.UP * (flap_upward_boost * 0.6) + cam_forward_3d * (flap_forward_boost * 0.45)
	_flap_anim_timer = 0.55
	_energy_flare = 1.15


func _trigger_golden_surge(steer_x: float, move_z: float) -> void:
	_surge_timer = surge_duration
	_surge_cooldown_timer = surge_cooldown
	_flap_anim_timer = maxf(_flap_anim_timer, 0.35)
	_energy_flare = 1.3

	if is_flying:
		_surge_dir = _get_camera_forward_3d()
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
	_energy_flare = 1.4
	soul_call_triggered.emit(global_position)


func _get_camera_forward_3d() -> Vector3:
	var cam_basis: Basis = Basis.from_euler(Vector3(cam_pitch, cam_yaw, 0.0))
	return (cam_basis * Vector3.FORWARD).normalized()


# ==============================================================================
# VISUAL POLISH: SHADER-DRIVEN FLAME & CAPE, WING FLARES, HALO, CAMERA, TRAILS
# ==============================================================================

func _update_visual_rig(delta: float) -> void:
	if not visual_pivot:
		return

	# Orient VisualPivot with smooth yaw, pitch, and banking roll
	var target_basis: Basis = Basis.from_euler(Vector3(visual_pitch, facing_yaw, bank_roll))
	visual_pivot.basis = visual_pivot.basis.slerp(target_basis, 1.0 - exp(-12.0 * delta))

	# Gentle breathing float on VisualPivot when flying or idling
	var hover_bob: float = sin(_anim_time * (3.2 if is_flying else 2.4)) * (0.07 if is_flying else 0.032)
	visual_pivot.position.y = 0.9 + hover_bob

	# Orbiting celestial star-halo ring above Spark's head
	if star_halo and star_halo.visible:
		var halo_spin: float = 1.5 + (_energy_flare * 4.2) + (1.1 if is_flying else 0.0)
		star_halo.rotate_z(halo_spin * delta)
		star_halo.position.y = _base_halo_y + sin(_anim_time * 3.4) * 0.045
		var halo_scale: float = 1.0 + _energy_flare * 0.2
		star_halo.scale = Vector3.ONE * halo_scale

	if _spark_halo_node != null:
		var model_halo_spin: float = 0.85 + (_energy_flare * 3.2) + (0.75 if is_flying else 0.0)
		_spark_halo_node.rotate_object_local(Vector3.FORWARD, model_halo_spin * delta)
		_spark_halo_node.position.y = _spark_halo_base_y + sin(_anim_time * 3.2) * 0.032
		var model_halo_scale: float = 1.0 + _energy_flare * 0.16
		_spark_halo_node.scale = Vector3.ONE * model_halo_scale

	var speed_ratio: float = clampf(velocity.length() / maxf(flight_max_speed, 1.0), 0.0, 1.25)

	# Drive Spark's living flame core shader & flowing wind-wave cape shader
	var flap_burst: float = 0.0
	if _flap_anim_timer > 0.0:
		var ft: float = 1.0 - clampf(_flap_anim_timer / 0.55, 0.0, 1.0)
		flap_burst = sin(ft * PI)
	if _surge_timer > 0.0:
		flap_burst = maxf(flap_burst, 0.9)

	if _flame_shader_mat:
		_flame_shader_mat.set_shader_parameter("flare_intensity", _energy_flare)

	if _cape_shader_mat:
		var wind_val: float = lerpf(2.4, 10.5, speed_ratio)
		_cape_shader_mat.set_shader_parameter("wind_speed", wind_val)
		_cape_shader_mat.set_shader_parameter("flap_burst", flap_burst)

	if not _spark_energy_materials.is_empty():
		var current_speed: float = velocity.length()
		var combined_flare: float = _energy_flare + flap_burst * 0.65
		for smat: ShaderMaterial in _spark_energy_materials:
			smat.set_shader_parameter("flight_speed", current_speed)
			smat.set_shader_parameter("energy_flare", combined_flare)

	# Procedural billowing animation on left & right 3D cape wings + radiant light-wing flares
	if cape_left and cape_right:
		var billow_freq: float = lerpf(3.2, 13.5, speed_ratio)
		var billow_amp: float = lerpf(0.07, 0.24, speed_ratio)
		var wave_l: float = sin(_anim_time * billow_freq) * billow_amp
		var wave_r: float = sin(_anim_time * billow_freq + 0.55) * billow_amp

		var flap_stroke: float = flap_burst * 0.88
		var spread_angle: float = 0.10 if is_flying else -0.52
		var sweep_back: float = lerpf(0.18, 0.54, speed_ratio) if is_flying else lerpf(0.12, 0.42, speed_ratio)

		cape_left.rotation = Vector3(
			0.12 + wave_l * 0.5,
			sweep_back + wave_l * 0.35,
			-(spread_angle - flap_stroke + wave_l)
		)
		cape_right.rotation = Vector3(
			0.12 + wave_r * 0.5,
			-(sweep_back + wave_r * 0.35),
			spread_angle - flap_stroke + wave_r
		)

	# Radiant additive light-wing flares bloom open on wing flaps, surge, or fast flight
	var flare_vis: float = clampf(flap_burst * 0.85 + (_energy_flare * 0.35) + (0.14 if is_flying else 0.0), 0.0, 1.0)
	if _wing_flare_mat:
		_wing_flare_mat.albedo_color = Color(1.0, 0.72, 0.88, flare_vis * 0.72)
	var flare_scale: Vector3 = Vector3(lerpf(0.65, 1.45, flare_vis), lerpf(0.55, 1.35, flare_vis), 1.0)
	if wing_flare_left:
		wing_flare_left.visible = flare_vis > 0.02
		wing_flare_left.scale = flare_scale
	if wing_flare_right:
		wing_flare_right.visible = flare_vis > 0.02
		wing_flare_right.scale = flare_scale

	# Warm OmniLight3D intensity modulation on abilities & speed (kept soft to avoid floor hotspots)
	if spark_light:
		var target_energy: float = _base_light_energy + (_energy_flare * 0.42) + (0.14 if is_flying else 0.0)
		spark_light.light_energy = lerpf(spark_light.light_energy, target_energy, 1.0 - exp(-10.0 * delta))


func _update_camera(delta: float) -> void:
	if not camera_rig or not camera:
		return

	# Keyboard Arrow-key smooth camera orbit (WASD moves Spark; Arrows orbit camera)
	if input_enabled:
		var key_cam_x: float = (1.0 if Input.is_key_pressed(KEY_RIGHT) else 0.0) - (1.0 if Input.is_key_pressed(KEY_LEFT) else 0.0)
		var key_cam_y: float = (1.0 if Input.is_key_pressed(KEY_UP) else 0.0) - (1.0 if Input.is_key_pressed(KEY_DOWN) else 0.0)
		if absf(key_cam_x) > 0.01 or absf(key_cam_y) > 0.01:
			cam_yaw -= key_cam_x * keyboard_cam_yaw_speed * delta
			cam_pitch = clampf(cam_pitch + key_cam_y * keyboard_cam_pitch_speed * delta, deg_to_rad(-68.0), deg_to_rad(52.0))
			_manual_cam_timer = auto_center_delay

	# Gentle Stray-style auto-centering behind Spark's travel direction after 1.8s of no manual input
	if input_enabled and _manual_cam_timer <= 0.0:
		var horiz_vel: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
		var horiz_speed: float = horiz_vel.length()
		if horiz_speed > 1.5:
			var travel_yaw: float = atan2(-horiz_vel.x, -horiz_vel.z)
			var follow_rate: float = camera_follow_speed * (0.65 if is_flying else 0.45)
			cam_yaw = lerp_angle(cam_yaw, travel_yaw, 1.0 - exp(-follow_rate * delta))
			if not is_flying:
				cam_pitch = lerpf(cam_pitch, -0.22, 1.0 - exp(-follow_rate * 0.4 * delta))

	camera_rig.rotation = Vector3(cam_pitch, cam_yaw, 0.0)

	# Smoothly interpolate zoom offset from wheel / Mac trackpad pan gesture
	cam_zoom_offset = lerpf(cam_zoom_offset, _target_zoom_offset, 1.0 - exp(-zoom_lerp_speed * delta))

	# Dynamic FOV expansion during fast movement, flight, wing flap boost, or golden surge
	var speed_factor: float = clampf((velocity.length() - 10.0) / maxf(flight_max_speed - 10.0, 1.0), 0.0, 1.0)
	var boost_fov: float = 0.0
	if _surge_timer > 0.0:
		boost_fov += 6.5
	if _flap_anim_timer > 0.0:
		boost_fov += 3.8 * clampf(_flap_anim_timer / 0.55, 0.0, 1.0)

	var target_fov: float = clampf(lerpf(base_fov, max_fov - 4.0, speed_factor) + boost_fov, base_fov, max_fov)
	camera.fov = lerpf(camera.fov, target_fov, 1.0 - exp(-fov_lerp_speed * delta))

	# Silky SpringArm3D distance easing + player mouse-wheel / trackpad zoom offset
	if spring_arm:
		var target_arm: float = lerpf(spring_length_ground, spring_length_flight, 1.0 if is_flying else 0.0)
		if is_flying:
			target_arm += speed_factor * 1.1
		if _surge_timer > 0.0:
			target_arm += spring_length_surge_bonus
		target_arm = clampf(target_arm + cam_zoom_offset, 2.5, 18.0)
		spring_arm.spring_length = lerpf(spring_arm.spring_length, target_arm, 1.0 - exp(-spring_arm_lerp_speed * delta))

	# Subtle cinematic camera roll following banking angle in flight
	var target_cam_roll: float = bank_roll * camera_roll_factor if is_flying else 0.0
	camera.rotation.z = lerpf(camera.rotation.z, target_cam_roll, 1.0 - exp(-6.2 * delta))


func _update_call_pulse(delta: float) -> void:
	if not call_pulse_mesh:
		return

	if _call_pulse_timer > 0.0:
		_call_pulse_timer = maxf(0.0, _call_pulse_timer - delta)
		var progress: float = 1.0 - (_call_pulse_timer / maxf(call_pulse_duration, 0.01))
		var eased: float = 1.0 - pow(1.0 - progress, 3.0)
		call_pulse_mesh.visible = true
		var radius: float = lerpf(0.45, 9.8, eased)
		call_pulse_mesh.scale = Vector3.ONE * radius
		if _call_pulse_shader_mat:
			var alpha: float = clampf(1.0 - progress, 0.0, 1.0)
			_call_pulse_shader_mat.set_shader_parameter("alpha_fade", alpha)
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
	trail_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	trail_mat.vertex_color_use_as_albedo = true
	trail_mat.albedo_color = Color(0.86, 0.94, 1.0, 1.0)

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

	var width_mult: float = 1.0 + (0.62 if is_flying else 0.0) + (_energy_flare * 0.48)
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
		var taper: float = smoothstep(0.0, 1.0, life_t * index_t)
		var half_w: float = base_width * 0.5 * (0.15 + 0.85 * taper)

		# Luminous iridescent sky-aqua & blush-pearl core fading smoothly into sakura-orchid tail
		var col: Color = Color(
			lerpf(0.76, 1.38, taper),
			lerpf(0.46, 1.24, taper),
			lerpf(0.96, 1.62, taper),
			taper * taper * (0.94 if is_flying else 0.52)
		)

		imm_mesh.surface_set_color(col)
		imm_mesh.surface_add_vertex(p + side * half_w)
		imm_mesh.surface_set_color(col)
		imm_mesh.surface_add_vertex(p - side * half_w)

	imm_mesh.surface_end()
