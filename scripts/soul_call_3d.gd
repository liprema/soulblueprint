extends Node3D
class_name SoulCall3D

## Expanding 3D Golden Resonance Call [Q] VFX & world pulse broadcaster.

@export var start_radius: float = 1.0
@export var max_radius: float = 48.0
@export var duration: float = 1.8
@export var lantern_awaken_radius: float = 55.0
@export var ring_spin_speed: float = 0.85

@onready var call_sphere: MeshInstance3D = $CallSphere
@onready var runic_ring: MeshInstance3D = $RunicRing
@onready var call_light: OmniLight3D = $CallLight

var _sphere_material: ShaderMaterial
var _ring_material: StandardMaterial3D
var _tween: Tween
var _active: bool = false


func _ready() -> void:
	var sphere_mat := call_sphere.get_active_material(0)
	if sphere_mat is ShaderMaterial:
		_sphere_material = sphere_mat.duplicate() as ShaderMaterial
		call_sphere.set_surface_override_material(0, _sphere_material)

	var ring_mat := runic_ring.get_active_material(0)
	if ring_mat is StandardMaterial3D:
		_ring_material = ring_mat.duplicate() as StandardMaterial3D
		runic_ring.set_surface_override_material(0, _ring_material)

	visible = false
	_active = false


func _process(delta: float) -> void:
	if _active and runic_ring:
		runic_ring.rotate_y(ring_spin_speed * delta)


## Triggers the golden resonance wave from `origin`, awakening nearby stone lanterns
## and signaling light-bird flocks.
func trigger(origin: Vector3) -> void:
	global_position = origin
	visible = true
	_active = true

	if _tween and _tween.is_valid():
		_tween.kill()

	# Reset visual state to start_radius.
	call_sphere.scale = Vector3.ONE * start_radius
	runic_ring.scale = Vector3(start_radius, 0.28, start_radius)
	runic_ring.rotation = Vector3.ZERO

	if _sphere_material:
		_sphere_material.set_shader_parameter("alpha_fade", 1.0)

	if _ring_material:
		var c := _ring_material.albedo_color
		c.a = 0.95
		_ring_material.albedo_color = c

	if call_light:
		call_light.light_energy = 4.8
		call_light.omni_range = 14.0

	# Expand smoothly from radius 1.0 to 48.0 over 1.8s with ease-out fade.
	_tween = create_tween()
	_tween.set_parallel(true)

	_tween.tween_property(
		call_sphere, "scale", Vector3.ONE * max_radius, duration
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	_tween.tween_property(
		runic_ring, "scale", Vector3(max_radius * 1.04, 0.14, max_radius * 1.04), duration
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	if _sphere_material:
		_tween.tween_method(
			_set_sphere_alpha, 1.0, 0.0, duration
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if _ring_material:
		_tween.tween_property(
			_ring_material, "albedo_color:a", 0.0, duration * 0.92
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if call_light:
		_tween.tween_property(
			call_light, "light_energy", 0.0, duration * 0.85
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(
			call_light, "omni_range", max_radius * 0.9, duration * 0.85
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	_tween.chain().tween_callback(_on_wave_finished)

	# Broadcast resonance to world interactables & light-birds.
	_notify_world(origin)


func _set_sphere_alpha(value: float) -> void:
	if _sphere_material:
		_sphere_material.set_shader_parameter("alpha_fade", value)


func _notify_world(origin: Vector3) -> void:
	var tree := get_tree()
	if tree == null:
		return

	for lantern in tree.get_nodes_in_group("stone_lanterns"):
		if lantern is Node3D and lantern.has_method("awaken"):
			if origin.distance_to(lantern.global_position) <= lantern_awaken_radius:
				lantern.call("awaken")

	for flock in tree.get_nodes_in_group("light_birds"):
		if flock != null and flock.has_method("on_soul_call"):
			flock.call("on_soul_call", origin)


func _on_wave_finished() -> void:
	_active = false
	visible = false
