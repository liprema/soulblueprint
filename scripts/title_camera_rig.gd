class_name TitleCameraRig
extends Node3D

## Cinematic Sky-inspired Title Camera Rig for SoulBlueprint (Godot 4.3).
## Slowly orbits around the Akashic sanctuary overlooking the golden viaduct,
## floating islands, cloud sea, and Colossal Astrolabe Cathedral.

@export var look_target: Vector3 = Vector3(0.0, 26.0, -210.0)
@export var start_position: Vector3 = Vector3(32.0, 24.0, -40.0)
@export var end_position: Vector3 = Vector3(-32.0, 32.0, -80.0)
@export var orbit_speed: float = 0.085
@export var arc_depth: float = 8.0
@export var vertical_bob_amplitude: float = 1.5
@export var vertical_bob_speed: float = 0.21
@export var look_sway_amplitude: float = 2.4
@export var camera_fov: float = 52.0
@export var camera_near: float = 0.25
@export var camera_far: float = 1600.0

var _camera: Camera3D = null
var _active: bool = false
var _orbit_time: float = 0.0


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.name = "TitleCamera"
	_camera.fov = camera_fov
	_camera.near = camera_near
	_camera.far = camera_far
	_camera.current = _active
	add_child(_camera)

	_update_camera_transform()
	set_process(_active)


func _process(delta: float) -> void:
	if not _active:
		return
	_orbit_time += delta
	_update_camera_transform()


## Makes the title Camera3D current and enables the meditative orbit animation.
func activate() -> void:
	_active = true
	set_process(true)
	if _camera != null:
		_update_camera_transform()
		_camera.current = true


## Disables the orbit animation and releases current status from the title Camera3D.
func deactivate() -> void:
	_active = false
	set_process(false)
	if _camera != null:
		_camera.current = false


## Returns true while the title camera rig is active.
func is_active() -> bool:
	return _active


func _update_camera_transform() -> void:
	if _camera == null or not _camera.is_inside_tree():
		return

	# Smooth cosine ping-pong between start_position and end_position
	var sweep_t: float = 0.5 - 0.5 * cos(_orbit_time * orbit_speed)
	var bob_y: float = sin(_orbit_time * vertical_bob_speed) * vertical_bob_amplitude
	var arc_z: float = sin(sweep_t * PI) * arc_depth

	var cam_pos := Vector3(
		lerpf(start_position.x, end_position.x, sweep_t),
		lerpf(start_position.y, end_position.y, sweep_t) + bob_y,
		lerpf(start_position.z, end_position.z, sweep_t) + arc_z
	)

	var target := Vector3(
		look_target.x + sin(_orbit_time * 0.13) * look_sway_amplitude,
		look_target.y + cos(_orbit_time * 0.17) * 1.1,
		look_target.z
	)

	_camera.global_position = cam_pos
	if cam_pos.distance_squared_to(target) > 0.001:
		_camera.look_at(target, Vector3.UP)
