extends Node3D
class_name StoneLantern3D

## Awakenable dark-indigo Stone Lantern shrine that radiates golden light
## and gently recharges nearby players' wing energy.

signal awakened(lantern: StoneLantern3D)

@export var dormant_light_energy: float = 0.55
@export var dormant_light_range: float = 7.0
@export var dormant_light_volumetric_fog_energy: float = 1.2
@export var dormant_light_color: Color = Color("#B8D4E8")
@export var dormant_emission_energy: float = 0.55

@export var awakened_light_energy: float = 3.2
@export var awakened_light_range: float = 22.0
@export var awakened_light_volumetric_fog_energy: float = 2.6
@export var awakened_light_color: Color = Color("#FFD494")
@export var awakened_emission_energy: float = 2.6

@export var lantern_omni_attenuation: float = 1.55
@export var awaken_duration: float = 0.95
@export var wing_recharge_rate: float = 0.35
@export var start_awakened: bool = false

@onready var core_orb: MeshInstance3D = $CoreOrb
@onready var lantern_light: OmniLight3D = $LanternLight
@onready var golden_embers: GPUParticles3D = $GoldenEmbers
@onready var awaken_burst: GPUParticles3D = $AwakenBurst
@onready var proximity_area: Area3D = $ProximityArea

const LANTERN_MODEL_PATH: String = "res://assets/models/props/stone_lantern.glb"
const MARBLE_SHADER: Shader = preload("res://shaders/akasha_marble.gdshader")

const COLOR_AGED_GOLD: Color = Color("#DFC48E")
const COLOR_AGED_BRASS: Color = Color("#C9AC74")
const COLOR_WARM_BRASS_EMISSION: Color = Color("#EDD29A")

const GOLD_EMISSION_DORMANT: float = 0.06
const GOLD_EMISSION_AWAKENED: float = 0.28
const BRASS_EMISSION_DORMANT: float = 0.03
const BRASS_EMISSION_AWAKENED: float = 0.18

var _is_awakened: bool = false
var _orb_material: StandardMaterial3D
var _tween: Tween
var _nearby_bodies: Array[Node] = []
var _pulse_time: float = 0.0
var _base_orb_y: float = 2.48
var _lantern_model_instance: Node3D = null

var _mat_obsidian_dark: ShaderMaterial = null
var _mat_indigo_stone: ShaderMaterial = null
var _mat_cobalt_trim: ShaderMaterial = null
var _mat_artdeco_gold: StandardMaterial3D = null
var _mat_artdeco_brass: StandardMaterial3D = null


func _ready() -> void:
	add_to_group("stone_lanterns")
	_init_lantern_materials()
	_load_lantern_model()

	if core_orb:
		_base_orb_y = core_orb.position.y
		var mat: Material = core_orb.get_active_material(0)
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


func _create_wet_basalt_material(
	base_col: Color,
	highlight_col: Color,
	pore_col: Color,
	roughness_val: float,
	fresnel_strength: float,
	wetness_val: float,
	block_scale_val: float,
	seam_strength_val: float
) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = MARBLE_SHADER
	mat.set_shader_parameter("stone_base_color", base_col)
	mat.set_shader_parameter("stone_highlight_color", highlight_col)
	mat.set_shader_parameter("stone_pore_color", pore_col)
	mat.set_shader_parameter("horizon_tint_color", Color("#E4F0FA"))
	mat.set_shader_parameter("base_roughness", roughness_val)
	mat.set_shader_parameter("surface_specular", 0.42)
	mat.set_shader_parameter("surface_metallic", 0.02)
	mat.set_shader_parameter("fresnel_lift_strength", fresnel_strength)
	mat.set_shader_parameter("wetness_strength", wetness_val)
	mat.set_shader_parameter("block_scale", block_scale_val)
	mat.set_shader_parameter("seam_strength", seam_strength_val)
	return mat


func _init_lantern_materials() -> void:
	# Carved Warm Alabaster, Pearl Ivory & Pale Celestial Ice-Blue stonework
	_mat_obsidian_dark = _create_wet_basalt_material(
		Color("#C4BDB3"), Color("#D8D2C8"), Color("#9C948A"), 0.58, 0.10, 0.38, 1.65, 0.32
	)
	_mat_indigo_stone = _create_wet_basalt_material(
		Color("#E2DCD2"), Color("#F4EFE7"), Color("#BDB4A6"), 0.52, 0.12, 0.48, 1.85, 0.28
	)
	_mat_cobalt_trim = _create_wet_basalt_material(
		Color("#C6DCED"), Color("#E0EEF8"), Color("#96B4CC"), 0.40, 0.16, 0.70, 2.00, 0.24
	)

	# Brushed satin champagne gold & warm temple brass (per-instance so each lantern awakens independently)
	_mat_artdeco_gold = StandardMaterial3D.new()
	_mat_artdeco_gold.albedo_color = COLOR_AGED_GOLD
	_mat_artdeco_gold.metallic = 0.78
	_mat_artdeco_gold.roughness = 0.40
	_mat_artdeco_gold.emission_enabled = true
	_mat_artdeco_gold.emission = COLOR_WARM_BRASS_EMISSION
	_mat_artdeco_gold.emission_energy_multiplier = GOLD_EMISSION_DORMANT

	_mat_artdeco_brass = StandardMaterial3D.new()
	_mat_artdeco_brass.albedo_color = COLOR_AGED_BRASS
	_mat_artdeco_brass.metallic = 0.78
	_mat_artdeco_brass.roughness = 0.44
	_mat_artdeco_brass.emission_enabled = true
	_mat_artdeco_brass.emission = COLOR_WARM_BRASS_EMISSION
	_mat_artdeco_brass.emission_energy_multiplier = BRASS_EMISSION_DORMANT


func _load_lantern_model() -> void:
	if not ResourceLoader.exists(LANTERN_MODEL_PATH):
		return

	var packed: PackedScene = load(LANTERN_MODEL_PATH) as PackedScene
	if packed == null:
		return

	var inst: Node = packed.instantiate()
	if not (inst is Node3D):
		inst.queue_free()
		return

	_lantern_model_instance = inst as Node3D
	_lantern_model_instance.name = "StoneLanternModel"
	add_child(_lantern_model_instance)
	_apply_lantern_materials_recursive(_lantern_model_instance)

	# Hide legacy procedural stone mesh nodes while keeping CoreOrb, LanternLight,
	# GoldenEmbers, AwakenBurst, and ProximityArea intact.
	var legacy_nodes: Array[String] = [
		"PedestalBase",
		"PedestalColumn",
		"LanternDeck",
		"PillarNW",
		"PillarNE",
		"PillarSW",
		"PillarSE",
		"LanternCap",
		"CapFinial",
	]
	for node_name: String in legacy_nodes:
		var legacy_node: Node3D = get_node_or_null(node_name) as Node3D
		if legacy_node != null:
			legacy_node.visible = false


func _apply_lantern_materials_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mesh_inst.mesh
		if mesh != null:
			var surface_count: int = mesh.get_surface_count()
			for surface_idx: int in range(surface_count):
				var surf_mat: Material = mesh.surface_get_material(surface_idx)
				var mat_name: String = surf_mat.resource_name if surf_mat != null else ""
				var override_mat: Material = _resolve_lantern_material(mat_name, mesh_inst.name)
				if override_mat != null:
					mesh_inst.set_surface_override_material(surface_idx, override_mat)

	for child: Node in node.get_children():
		_apply_lantern_materials_recursive(child)


func _resolve_lantern_material(mat_name: String, node_name: String) -> Material:
	match mat_name:
		"Lantern_Obsidian_Dark":
			return _mat_obsidian_dark
		"Lantern_IndigoStone_Mid":
			return _mat_indigo_stone
		"Lantern_Cobalt_Trim":
			return _mat_cobalt_trim
		"Lantern_ArtDeco_Gold":
			return _mat_artdeco_gold
		"Lantern_ArtDeco_Brass":
			return _mat_artdeco_brass

	var key: String = (mat_name + " " + node_name).to_lower()
	if key.contains("gold"):
		return _mat_artdeco_gold
	if key.contains("brass"):
		return _mat_artdeco_brass
	if key.contains("obsidian"):
		return _mat_obsidian_dark
	if key.contains("cobalt"):
		return _mat_cobalt_trim
	return _mat_indigo_stone


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
	for body: Node in _nearby_bodies:
		if is_instance_valid(body) and body.has_method("recharge_wing_energy"):
			body.call("recharge_wing_energy", wing_recharge_rate * delta)
			valid_bodies.append(body)
	_nearby_bodies = valid_bodies


## Smoothly awakens the lantern into warm amber-honey volumetric radiance and bursts golden embers.
func awaken() -> void:
	var first_time: bool = not _is_awakened
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
		lantern_light.omni_attenuation = lantern_omni_attenuation
		if first_time:
			_tween.tween_property(
				lantern_light, "light_color", awakened_light_color, awaken_duration * 0.7
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_tween.tween_property(
				lantern_light, "light_energy", awakened_light_energy, awaken_duration
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_tween.tween_property(
				lantern_light, "omni_range", awakened_light_range, awaken_duration
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_tween.tween_property(
				lantern_light,
				"light_volumetric_fog_energy",
				awakened_light_volumetric_fog_energy,
				awaken_duration
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			# Subtle radiant flare when re-resonated by another Soul Call.
			lantern_light.light_color = awakened_light_color
			lantern_light.light_volumetric_fog_energy = awakened_light_volumetric_fog_energy
			lantern_light.light_energy = awakened_light_energy * 1.35
			_tween.tween_property(
				lantern_light, "light_energy", awakened_light_energy, 0.75
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if _orb_material:
		_tween.tween_property(
			_orb_material, "albedo_color", Color(1.0, 0.92, 0.72, 1.0), awaken_duration * 0.7
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(
			_orb_material, "emission", awakened_light_color, awaken_duration * 0.7
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

	# Subtle warm aged-brass & gold emission boost when the lantern awakens
	if _mat_artdeco_gold != null:
		if first_time:
			_tween.tween_property(
				_mat_artdeco_gold, "emission_energy_multiplier", GOLD_EMISSION_AWAKENED, awaken_duration
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			_mat_artdeco_gold.emission_energy_multiplier = GOLD_EMISSION_AWAKENED * 1.35
			_tween.tween_property(
				_mat_artdeco_gold, "emission_energy_multiplier", GOLD_EMISSION_AWAKENED, 0.75
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if _mat_artdeco_brass != null:
		if first_time:
			_tween.tween_property(
				_mat_artdeco_brass, "emission_energy_multiplier", BRASS_EMISSION_AWAKENED, awaken_duration
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			_mat_artdeco_brass.emission_energy_multiplier = BRASS_EMISSION_AWAKENED * 1.35
			_tween.tween_property(
				_mat_artdeco_brass, "emission_energy_multiplier", BRASS_EMISSION_AWAKENED, 0.75
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
		lantern_light.light_color = dormant_light_color
		lantern_light.light_energy = dormant_light_energy
		lantern_light.omni_range = dormant_light_range
		lantern_light.omni_attenuation = lantern_omni_attenuation
		lantern_light.light_volumetric_fog_energy = dormant_light_volumetric_fog_energy
	if _orb_material:
		_orb_material.albedo_color = Color(0.76, 0.85, 0.92, 1.0)
		_orb_material.emission = dormant_light_color
		_orb_material.emission_energy_multiplier = dormant_emission_energy
	if _mat_artdeco_gold != null:
		_mat_artdeco_gold.emission_energy_multiplier = GOLD_EMISSION_DORMANT
	if _mat_artdeco_brass != null:
		_mat_artdeco_brass.emission_energy_multiplier = BRASS_EMISSION_DORMANT
	if golden_embers:
		golden_embers.emitting = false
	if awaken_burst:
		awaken_burst.emitting = false


func _apply_awakened_immediate() -> void:
	_is_awakened = true
	if lantern_light:
		lantern_light.light_color = awakened_light_color
		lantern_light.light_energy = awakened_light_energy
		lantern_light.omni_range = awakened_light_range
		lantern_light.omni_attenuation = lantern_omni_attenuation
		lantern_light.light_volumetric_fog_energy = awakened_light_volumetric_fog_energy
	if _orb_material:
		_orb_material.albedo_color = Color(1.0, 0.92, 0.72, 1.0)
		_orb_material.emission = awakened_light_color
		_orb_material.emission_energy_multiplier = awakened_emission_energy
	if _mat_artdeco_gold != null:
		_mat_artdeco_gold.emission_energy_multiplier = GOLD_EMISSION_AWAKENED
	if _mat_artdeco_brass != null:
		_mat_artdeco_brass.emission_energy_multiplier = BRASS_EMISSION_AWAKENED
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
