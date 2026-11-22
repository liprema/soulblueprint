extends Node3D
class_name StoneLantern3D

## Awakenable dark-indigo Stone Lantern shrine that radiates golden light
## and gently recharges nearby players' wing energy.

signal awakened(lantern: StoneLantern3D)

@export var dormant_light_energy: float = 0.35
@export var dormant_light_range: float = 5.5
@export var dormant_emission_energy: float = 0.45

@export var awakened_light_energy: float = 3.8
@export var awakened_light_range: float = 17.0
@export var awakened_emission_energy: float = 4.6

@export var awaken_duration: float = 0.95
@export var wing_recharge_rate: float = 0.35
@export var start_awakened: bool = false

@onready var core_orb: MeshInstance3D = $CoreOrb
@onready var lantern_light: OmniLight3D = $LanternLight
@onready var golden_embers: GPUParticles3D = $GoldenEmbers
@onready var awaken_burst: GPUParticles3D = $AwakenBurst
@onready var proximity_area: Area3D = $ProximityArea

var _is_awakened: bool = false
var _orb_material: StandardMaterial3D
var _tween: Tween
var _nearby_bodies: Array[Node] = []
var _pulse_time: float = 0.0
var _base_orb_y: float = 2.48


func _ready() -> void:
	add_to_group("stone_lanterns")

	if core_orb:
		_base_orb_y = core_orb.position.y
		var mat := core_orb.get_active_material(0)
		if mat is StandardMaterial3D:
			_orb_material = mat.duplicate() as StandardMaterial3D
			core_orb.set_surface_override_material(0, _orb_material)

	if proximity_area:
		proximity_area.body_entered.connect(_on_proximity_body_entered)
		proximity_area.body_exited.connect(_on_proximity_body_exited)

	if start_awakened:
		_apply_awakened_immediate()
	else:
		_apply_dormant_immediate()


func _process(delta: float) -> void:
	if not _is_awakened:
		return

	_pulse_time += delta
	if core_orb:
		core_orb.position.y = _base_orb_y + sin(_pulse_time * 2.1) * 0.045
	if lantern_light and (not _tween or not _tween.is_valid()):
		lantern_light.light_energy = awakened_light_energy + sin(_pulse_time * 3.0) * 0.25


func _physics_process(delta: float) -> void:
	if _nearby_bodies.is_empty():
		return

	var valid_bodies: Array[Node] = []
	for body in _nearby_bodies:
		if is_instance_valid(body) and body.has_method("recharge_wing_energy"):
			body.call("recharge_wing_energy", wing_recharge_rate * delta)
			valid_bodies.append(body)
	_nearby_bodies = valid_bodies


## Smoothly awakens the lantern into bright golden radiance and bursts golden embers.
func awaken() -> void:
	var first_time := not _is_awakened
	_is_awakened = true

	if golden_embers:
		golden_embers.emitting = true

	if awaken_burst:
		awaken_burst.restart()
		awaken_burst.emitting = true

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(true)

	if lantern_light:
		if first_time:
			_tween.tween_property(
				lantern_light, "light_energy", awakened_light_energy, awaken_duration
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_tween.tween_property(
				lantern_light, "omni_range", awakened_light_range, awaken_duration
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			# Subtle radiant flare when re-resonated by another Soul Call.
			lantern_light.light_energy = awakened_light_energy * 1.35
			_tween.tween_property(
				lantern_light, "light_energy", awakened_light_energy, 0.75
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if _orb_material:
		_tween.tween_property(
			_orb_material, "albedo_color", Color(1.0, 0.965, 0.8, 1.0), awaken_duration * 0.7
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(
			_orb_material, "emission", Color(1.0, 0.875, 0.45, 1.0), awaken_duration * 0.7
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if first_time:
			_tween.tween_property(
				_orb_material, "emission_energy_multiplier", awakened_emission_energy, awaken_duration
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			_orb_material.emission_energy_multiplier = awakened_emission_energy * 1.4
			_tween.tween_property(
				_orb_material, "emission_energy_multiplier", awakened_emission_energy, 0.75
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if core_orb:
		core_orb.scale = Vector3.ONE * 1.18
		_tween.tween_property(
			core_orb, "scale", Vector3.ONE, 0.65
		).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	if first_time:
		awakened.emit(self)


func is_awakened() -> bool:
	return _is_awakened


func _apply_dormant_immediate() -> void:
	_is_awakened = false
	if lantern_light:
		lantern_light.light_energy = dormant_light_energy
		lantern_light.omni_range = dormant_light_range
	if _orb_material:
		_orb_material.albedo_color = Color(0.55, 0.47, 0.30, 1.0)
		_orb_material.emission = Color(0.85, 0.68, 0.32, 1.0)
		_orb_material.emission_energy_multiplier = dormant_emission_energy
	if golden_embers:
		golden_embers.emitting = false
	if awaken_burst:
		awaken_burst.emitting = false


func _apply_awakened_immediate() -> void:
	_is_awakened = true
	if lantern_light:
		lantern_light.light_energy = awakened_light_energy
		lantern_light.omni_range = awakened_light_range
	if _orb_material:
		_orb_material.albedo_color = Color(1.0, 0.965, 0.8, 1.0)
		_orb_material.emission = Color(1.0, 0.875, 0.45, 1.0)
		_orb_material.emission_energy_multiplier = awakened_emission_energy
	if golden_embers:
		golden_embers.emitting = true
	if awaken_burst:
		awaken_burst.emitting = false


func _on_proximity_body_entered(body: Node3D) -> void:
	if body != null and body.has_method("recharge_wing_energy"):
		if not _nearby_bodies.has(body):
			_nearby_bodies.append(body)
		if not _is_awakened:
			awaken()


func _on_proximity_body_exited(body: Node3D) -> void:
	_nearby_bodies.erase(body)
