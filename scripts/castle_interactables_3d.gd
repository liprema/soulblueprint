class_name CastleInteractables3D
extends Node3D

## Interactive sacred relics for the Akasha Castle (Rotunda Galleries & Cloud Balcony).
## Procedurally sculpts and animates:
## 1. Фонтан Тишины (Fountain of Silence) — West Gallery Alcove (-24, 8, -276)
## 2. Книга Хроник Акаши (Book of Akashic Chronicles) — East Gallery Alcove (24, 8, -276)
## 3. Астролябия Кроноса (Kronos Astrolabe) — North Panoramic Balcony (0, 8, -304)

signal relic_interacted(relic_id: String, dialogue_sequence_id: String)

const MARBLE_SHADER_PATH: String = "res://shaders/akasha_marble.gdshader"

const RELIC_FOUNTAIN: String = "fountain_of_silence"
const RELIC_BOOK: String = "chronicle_book"
const RELIC_ASTROLABE: String = "kronos_astrolabe"

const FOUNTAIN_POS: Vector3 = Vector3(-24.0, 8.0, -276.0)
const BOOK_POS: Vector3 = Vector3(24.0, 8.0, -276.0)
const ASTROLABE_POS: Vector3 = Vector3(0.0, 8.0, -304.0)

const FOUNTAIN_RADIUS: float = 7.0
const BOOK_RADIUS: float = 7.0
const ASTROLABE_RADIUS: float = 7.5

const COLOR_WHITE_MARBLE: Color = Color("#F2F4F8")
const COLOR_SATIN_GOLD: Color = Color("#DFC07A")
const COLOR_BRIGHT_GOLD: Color = Color("#F6DC9E")
const COLOR_AQUA_WATER: Color = Color("#7AD6F0")
const COLOR_AQUA_GLOW: Color = Color("#9CF0FF")
const COLOR_PEARL_PAGE: Color = Color("#FFF9EE")
const COLOR_SOLAR_CORE: Color = Color("#FFE49A")

var _relic_defs: Array[Dictionary] = []
var _awakened_map: Dictionary = {}
var _pulse_values: Dictionary = {}
var _pulse_tweens: Dictionary = {}

# Shared materials
var _marble_mat: Material = null
var _gold_mat: StandardMaterial3D = null

# Fountain animated references
var _fountain_water_mat: StandardMaterial3D = null
var _fountain_jet_mat: StandardMaterial3D = null
var _fountain_lower_water: MeshInstance3D = null
var _fountain_upper_water: MeshInstance3D = null
var _fountain_mist: GPUParticles3D = null
var _fountain_droplets: GPUParticles3D = null
var _fountain_light: OmniLight3D = null
var _fountain_glow_level: float = 0.0

# Chronicle Book animated references
var _book_float_pivot: Node3D = null
var _book_page_mat: StandardMaterial3D = null
var _book_rune_mat: StandardMaterial3D = null
var _book_halo: MeshInstance3D = null
var _book_motes: GPUParticles3D = null
var _book_light: OmniLight3D = null
var _book_glow_level: float = 0.0

# Kronos Astrolabe animated references
var _astro_outer_ring: Node3D = null
var _astro_middle_ring: Node3D = null
var _astro_inner_ring: Node3D = null
var _astro_core_mat: StandardMaterial3D = null
var _astro_corona_mat: StandardMaterial3D = null
var _astro_motes: GPUParticles3D = null
var _astro_light: OmniLight3D = null
var _astro_glow_level: float = 0.0

var _anim_time: float = 0.0


func _ready() -> void:
	add_to_group("castle_interactables")
	_init_relic_definitions()
	_init_shared_materials()
	_build_fountain_of_silence()
	_build_chronicle_book()
	_build_kronos_astrolabe()


func _process(delta: float) -> void:
	_anim_time += delta
	var blend: float = clampf(delta * 3.5, 0.0, 1.0)

	# 1. Animate Fountain of Silence
	var fountain_target: float = 1.0 if bool(_awakened_map.get(RELIC_FOUNTAIN, false)) else 0.0
	_fountain_glow_level = lerpf(_fountain_glow_level, fountain_target, blend)
	var fountain_pulse: float = float(_pulse_values.get(RELIC_FOUNTAIN, 0.0))

	if _fountain_lower_water != null:
		_fountain_lower_water.position.y = 1.08 + sin(_anim_time * 2.1) * 0.025
		_fountain_lower_water.rotation.y += delta * (0.14 + _fountain_glow_level * 0.22)
	if _fountain_upper_water != null:
		_fountain_upper_water.position.y = 2.48 + sin(_anim_time * 2.7 + 1.1) * 0.02
		_fountain_upper_water.rotation.y -= delta * (0.20 + _fountain_glow_level * 0.28)
	if _fountain_water_mat != null:
		var shimmer: float = 0.35 + _fountain_glow_level * 0.72 + fountain_pulse * 0.85 + sin(_anim_time * 2.4) * 0.08
		_fountain_water_mat.emission_energy_multiplier = shimmer
	if _fountain_jet_mat != null:
		_fountain_jet_mat.emission_energy_multiplier = 0.42 + _fountain_glow_level * 0.65 + fountain_pulse * 0.7
	if _fountain_light != null:
		_fountain_light.light_energy = 1.35 + _fountain_glow_level * 1.45 + fountain_pulse * 1.4 + sin(_anim_time * 1.8) * 0.12
		_fountain_light.omni_range = lerpf(11.0, 16.5, _fountain_glow_level)

	# 2. Animate Book of Akashic Chronicles
	var book_target: float = 1.0 if bool(_awakened_map.get(RELIC_BOOK, false)) else 0.0
	_book_glow_level = lerpf(_book_glow_level, book_target, blend)
	var book_pulse: float = float(_pulse_values.get(RELIC_BOOK, 0.0))

	if _book_float_pivot != null:
		var lift: float = _book_glow_level * 0.16
		_book_float_pivot.position.y = 1.86 + lift + sin(_anim_time * 1.65) * 0.075
		_book_float_pivot.rotation.y = sin(_anim_time * 0.55) * 0.12
	if _book_halo != null:
		_book_halo.rotation.z += delta * (0.26 + _book_glow_level * 0.42)
	if _book_page_mat != null:
		_book_page_mat.emission_energy_multiplier = 0.48 + _book_glow_level * 0.68 + book_pulse * 0.85 + sin(_anim_time * 2.0) * 0.07
	if _book_rune_mat != null:
		_book_rune_mat.emission_energy_multiplier = 0.85 + _book_glow_level * 0.95 + book_pulse * 1.0
	if _book_light != null:
		_book_light.light_energy = 1.25 + _book_glow_level * 1.35 + book_pulse * 1.3 + sin(_anim_time * 1.6 + 0.8) * 0.1
		_book_light.omni_range = lerpf(10.5, 16.0, _book_glow_level)

	# 3. Animate Kronos Astrolabe
	var astro_target: float = 1.0 if bool(_awakened_map.get(RELIC_ASTROLABE, false)) else 0.0
	_astro_glow_level = lerpf(_astro_glow_level, astro_target, blend)
	var astro_pulse: float = float(_pulse_values.get(RELIC_ASTROLABE, 0.0))
	var spin_mult: float = 1.0 + _astro_glow_level * 1.15 + astro_pulse * 1.6

	if _astro_outer_ring != null:
		_astro_outer_ring.rotation.y += delta * 0.24 * spin_mult
	if _astro_middle_ring != null:
		_astro_middle_ring.rotation.x += delta * 0.34 * spin_mult
		_astro_middle_ring.rotation.z += delta * 0.18 * spin_mult
	if _astro_inner_ring != null:
		_astro_inner_ring.rotation.y -= delta * 0.48 * spin_mult
		_astro_inner_ring.rotation.x += delta * 0.26 * spin_mult
	if _astro_core_mat != null:
		_astro_core_mat.emission_energy_multiplier = 1.15 + _astro_glow_level * 0.95 + astro_pulse * 1.1 + sin(_anim_time * 2.3) * 0.12
	if _astro_corona_mat != null:
		_astro_corona_mat.emission_energy_multiplier = 0.55 + _astro_glow_level * 0.7 + astro_pulse * 0.75
	if _astro_light != null:
		_astro_light.light_energy = 1.55 + _astro_glow_level * 1.5 + astro_pulse * 1.5 + sin(_anim_time * 1.9 + 1.4) * 0.14
		_astro_light.omni_range = lerpf(12.5, 18.5, _astro_glow_level)


# ---------------------------------------------------------------------------
# Public Interaction API
# ---------------------------------------------------------------------------

## Returns info dictionary for the nearest Castle relic within its interaction radius, or {}.
func get_nearest_relic_in_range(player_pos: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var best_dist: float = 1000000.0

	for def_dict: Dictionary in _relic_defs:
		var relic_pos: Vector3 = def_dict.get("position", Vector3.ZERO) as Vector3
		var radius: float = float(def_dict.get("radius", 7.0))
		var dist: float = player_pos.distance_to(relic_pos)
		if dist <= radius and dist < best_dist:
			best_dist = dist
			best = def_dict.duplicate()
			best["distance"] = dist

	return best


## Returns the localized HUD interaction prompt for the nearest relic in range, or "".
func get_interaction_prompt(player_pos: Vector3) -> String:
	var nearest: Dictionary = get_nearest_relic_in_range(player_pos)
	if nearest.is_empty():
		return ""
	return str(nearest.get("prompt", ""))


## Interacts with the nearest relic in range (e.g. via [E]).
## Awakens the relic, emits `relic_interacted`, and returns its dialogue sequence ID (or "").
func interact_nearest(player_pos: Vector3) -> String:
	var nearest: Dictionary = get_nearest_relic_in_range(player_pos)
	if nearest.is_empty():
		return ""

	var relic_id: String = str(nearest.get("id", ""))
	var seq_id: String = str(nearest.get("sequence_id", ""))
	awaken_relic(relic_id)
	relic_interacted.emit(relic_id, seq_id)
	return seq_id


## Responds to a player Soul Call [Q] from `origin`.
## If within a relic's interaction range, awakens it, emits `relic_interacted`, and returns its sequence ID.
func respond_to_soul_call(origin: Vector3) -> String:
	return interact_nearest(origin)


## Marks a relic as awakened and plays a luminous resonance pulse on it.
func awaken_relic(relic_id: String) -> void:
	if relic_id.is_empty():
		return
	_awakened_map[relic_id] = true
	_trigger_relic_pulse(relic_id, 1.0, 1.35)

	if relic_id == RELIC_FOUNTAIN:
		if _fountain_mist != null:
			_fountain_mist.amount_ratio = 1.0
		if _fountain_droplets != null:
			_fountain_droplets.amount_ratio = 1.0
	elif relic_id == RELIC_BOOK:
		if _book_motes != null:
			_book_motes.amount_ratio = 1.0
	elif relic_id == RELIC_ASTROLABE:
		if _astro_motes != null:
			_astro_motes.amount_ratio = 1.0


## Resets all relics back to their serene dormant glow (used on New Game).
func reset_all_relics() -> void:
	for relic_id: String in [RELIC_FOUNTAIN, RELIC_BOOK, RELIC_ASTROLABE]:
		_awakened_map[relic_id] = false
		_pulse_values[relic_id] = 0.0
		if _pulse_tweens.has(relic_id):
			var tw: Tween = _pulse_tweens[relic_id] as Tween
			if tw != null and tw.is_valid():
				tw.kill()

	_fountain_glow_level = 0.0
	_book_glow_level = 0.0
	_astro_glow_level = 0.0

	if _fountain_mist != null:
		_fountain_mist.amount_ratio = 0.52
	if _fountain_droplets != null:
		_fountain_droplets.amount_ratio = 0.65
	if _book_motes != null:
		_book_motes.amount_ratio = 0.48
	if _astro_motes != null:
		_astro_motes.amount_ratio = 0.48


## Returns the pentatonic chime index associated with a relic ID.
func get_chime_index_for_relic(relic_id: String) -> int:
	if relic_id == RELIC_FOUNTAIN:
		return 0
	if relic_id == RELIC_BOOK:
		return 2
	if relic_id == RELIC_ASTROLABE:
		return 4
	return 1


# ---------------------------------------------------------------------------
# Internal Setup & Pulse Helper
# ---------------------------------------------------------------------------

func _init_relic_definitions() -> void:
	_relic_defs = [
		{
			"id": RELIC_FOUNTAIN,
			"sequence_id": "castle_fountain",
			"position": FOUNTAIN_POS,
			"radius": FOUNTAIN_RADIUS,
			"prompt": "✦  [E] Прислушаться к Фонтану Тишины  ·  [Q] Отклик",
		},
		{
			"id": RELIC_BOOK,
			"sequence_id": "castle_chronicle_book",
			"position": BOOK_POS,
			"radius": BOOK_RADIUS,
			"prompt": "✦  [E] Открыть Книгу Хроник Акаши  ·  [Q] Отклик",
		},
		{
			"id": RELIC_ASTROLABE,
			"sequence_id": "castle_kronos_balcony",
			"position": ASTROLABE_POS,
			"radius": ASTROLABE_RADIUS,
			"prompt": "✦  [E] Коснуться Астролябии Кроноса  ·  [Q] Отклик",
		},
	]
	for def_dict: Dictionary in _relic_defs:
		var r_id: String = str(def_dict.get("id", ""))
		_awakened_map[r_id] = false
		_pulse_values[r_id] = 0.0


func _init_shared_materials() -> void:
	if ResourceLoader.exists(MARBLE_SHADER_PATH):
		var marble_shader: Shader = load(MARBLE_SHADER_PATH) as Shader
		if marble_shader != null:
			var shader_mat: ShaderMaterial = ShaderMaterial.new()
			shader_mat.shader = marble_shader
			shader_mat.set_shader_parameter("stone_base_color", COLOR_WHITE_MARBLE)
			shader_mat.set_shader_parameter("stone_highlight_color", Color("#FFFFFF"))
			shader_mat.set_shader_parameter("stone_pore_color", Color("#C6D1E2"))
			shader_mat.set_shader_parameter("horizon_tint_color", Color("#C2DCF8"))
			shader_mat.set_shader_parameter("base_roughness", 0.52)
			shader_mat.set_shader_parameter("surface_specular", 0.44)
			shader_mat.set_shader_parameter("surface_metallic", 0.02)
			shader_mat.set_shader_parameter("fresnel_lift_strength", 0.14)
			shader_mat.set_shader_parameter("wetness_strength", 0.22)
			shader_mat.set_shader_parameter("block_scale", 1.15)
			_marble_mat = shader_mat

	if _marble_mat == null:
		var fallback: StandardMaterial3D = StandardMaterial3D.new()
		fallback.albedo_color = COLOR_WHITE_MARBLE
		fallback.roughness = 0.50
		fallback.metallic = 0.02
		_marble_mat = fallback

	_gold_mat = StandardMaterial3D.new()
	_gold_mat.albedo_color = COLOR_SATIN_GOLD
	_gold_mat.roughness = 0.36
	_gold_mat.metallic = 0.80
	_gold_mat.emission_enabled = true
	_gold_mat.emission = COLOR_BRIGHT_GOLD
	_gold_mat.emission_energy_multiplier = 0.20


func _trigger_relic_pulse(relic_id: String, peak: float, duration: float) -> void:
	if _pulse_tweens.has(relic_id):
		var prev_tw: Tween = _pulse_tweens[relic_id] as Tween
		if prev_tw != null and prev_tw.is_valid():
			prev_tw.kill()

	var clamped_peak: float = clampf(peak, 0.0, 1.2)
	var current_val: float = float(_pulse_values.get(relic_id, 0.0))
	var tw: Tween = create_tween()
	tw.tween_method(
		func(val: float) -> void: _pulse_values[relic_id] = val,
		current_val,
		clamped_peak,
		duration * 0.26
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_method(
		func(val: float) -> void: _pulse_values[relic_id] = val,
		clamped_peak,
		0.0,
		duration * 0.74
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tweens[relic_id] = tw


func _create_radial_mote_texture() -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.38, 0.78, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.62),
		Color(1.0, 1.0, 1.0, 0.14),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.width = 48
	tex.height = 48
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.gradient = grad
	return tex


func _add_cylinder_collider(parent: Node3D, radius: float, height: float) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "RelicCollider"
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var cyl: CylinderShape3D = CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape_node.shape = cyl
	shape_node.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(shape_node)
	parent.add_child(body)


# ---------------------------------------------------------------------------
# 1. Фонтан Тишины (Fountain of Silence) — West Castle Gallery Alcove
# ---------------------------------------------------------------------------

func _build_fountain_of_silence() -> void:
	var root: Node3D = Node3D.new()
	root.name = "FountainOfSilence"
	root.position = FOUNTAIN_POS
	add_child(root)

	_add_cylinder_collider(root, 2.75, 1.45)

	# Stepped octagonal marble plinth
	var plinth_mesh: CylinderMesh = CylinderMesh.new()
	plinth_mesh.top_radius = 2.95
	plinth_mesh.bottom_radius = 3.18
	plinth_mesh.height = 0.34
	plinth_mesh.radial_segments = 8
	var plinth: MeshInstance3D = MeshInstance3D.new()
	plinth.name = "MarblePlinth"
	plinth.mesh = plinth_mesh
	plinth.material_override = _marble_mat
	plinth.position = Vector3(0.0, 0.17, 0.0)
	plinth.rotation_degrees.y = 22.5
	root.add_child(plinth)

	# Lower carved octagonal basin wall
	var basin_outer_mesh: CylinderMesh = CylinderMesh.new()
	basin_outer_mesh.top_radius = 2.65
	basin_outer_mesh.bottom_radius = 2.38
	basin_outer_mesh.height = 0.86
	basin_outer_mesh.radial_segments = 16
	var basin_outer: MeshInstance3D = MeshInstance3D.new()
	basin_outer.name = "LowerBasin"
	basin_outer.mesh = basin_outer_mesh
	basin_outer.material_override = _marble_mat
	basin_outer.position = Vector3(0.0, 0.74, 0.0)
	root.add_child(basin_outer)

	# Champagne gold rim torus crowning the lower basin
	var lower_rim_mesh: TorusMesh = TorusMesh.new()
	lower_rim_mesh.inner_radius = 2.46
	lower_rim_mesh.outer_radius = 2.72
	lower_rim_mesh.rings = 32
	lower_rim_mesh.ring_segments = 12
	var lower_rim: MeshInstance3D = MeshInstance3D.new()
	lower_rim.name = "LowerBasinGoldRim"
	lower_rim.mesh = lower_rim_mesh
	lower_rim.material_override = _gold_mat
	lower_rim.position = Vector3(0.0, 1.18, 0.0)
	root.add_child(lower_rim)

	# Shimmering animated water material
	_fountain_water_mat = StandardMaterial3D.new()
	_fountain_water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fountain_water_mat.albedo_color = Color(COLOR_AQUA_WATER.r, COLOR_AQUA_WATER.g, COLOR_AQUA_WATER.b, 0.84)
	_fountain_water_mat.roughness = 0.12
	_fountain_water_mat.metallic = 0.15
	_fountain_water_mat.emission_enabled = true
	_fountain_water_mat.emission = COLOR_AQUA_GLOW
	_fountain_water_mat.emission_energy_multiplier = 0.35

	var lower_water_mesh: CylinderMesh = CylinderMesh.new()
	lower_water_mesh.top_radius = 2.48
	lower_water_mesh.bottom_radius = 2.48
	lower_water_mesh.height = 0.08
	lower_water_mesh.radial_segments = 32
	_fountain_lower_water = MeshInstance3D.new()
	_fountain_lower_water.name = "LowerWaterSurface"
	_fountain_lower_water.mesh = lower_water_mesh
	_fountain_lower_water.material_override = _fountain_water_mat
	_fountain_lower_water.position = Vector3(0.0, 1.08, 0.0)
	_fountain_lower_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(_fountain_lower_water)

	# Central fluted marble column
	var col_mesh: CylinderMesh = CylinderMesh.new()
	col_mesh.top_radius = 0.38
	col_mesh.bottom_radius = 0.56
	col_mesh.height = 1.65
	col_mesh.radial_segments = 12
	var col_inst: MeshInstance3D = MeshInstance3D.new()
	col_inst.name = "CentralColumn"
	col_inst.mesh = col_mesh
	col_inst.material_override = _marble_mat
	col_inst.position = Vector3(0.0, 1.72, 0.0)
	root.add_child(col_inst)

	# Golden collar around column
	var collar_mesh: TorusMesh = TorusMesh.new()
	collar_mesh.inner_radius = 0.40
	collar_mesh.outer_radius = 0.54
	collar_mesh.rings = 24
	collar_mesh.ring_segments = 10
	var collar: MeshInstance3D = MeshInstance3D.new()
	collar.name = "ColumnGoldCollar"
	collar.mesh = collar_mesh
	collar.material_override = _gold_mat
	collar.position = Vector3(0.0, 1.92, 0.0)
	root.add_child(collar)

	# Upper tier chalice basin
	var upper_basin_mesh: CylinderMesh = CylinderMesh.new()
	upper_basin_mesh.top_radius = 1.32
	upper_basin_mesh.bottom_radius = 0.44
	upper_basin_mesh.height = 0.52
	upper_basin_mesh.radial_segments = 16
	var upper_basin: MeshInstance3D = MeshInstance3D.new()
	upper_basin.name = "UpperTierBasin"
	upper_basin.mesh = upper_basin_mesh
	upper_basin.material_override = _marble_mat
	upper_basin.position = Vector3(0.0, 2.34, 0.0)
	root.add_child(upper_basin)

	var upper_rim_mesh: TorusMesh = TorusMesh.new()
	upper_rim_mesh.inner_radius = 1.20
	upper_rim_mesh.outer_radius = 1.36
	upper_rim_mesh.rings = 28
	upper_rim_mesh.ring_segments = 10
	var upper_rim: MeshInstance3D = MeshInstance3D.new()
	upper_rim.name = "UpperTierGoldRim"
	upper_rim.mesh = upper_rim_mesh
	upper_rim.material_override = _gold_mat
	upper_rim.position = Vector3(0.0, 2.58, 0.0)
	root.add_child(upper_rim)

	var upper_water_mesh: CylinderMesh = CylinderMesh.new()
	upper_water_mesh.top_radius = 1.22
	upper_water_mesh.bottom_radius = 1.22
	upper_water_mesh.height = 0.06
	upper_water_mesh.radial_segments = 24
	_fountain_upper_water = MeshInstance3D.new()
	_fountain_upper_water.name = "UpperWaterSurface"
	_fountain_upper_water.mesh = upper_water_mesh
	_fountain_upper_water.material_override = _fountain_water_mat
	_fountain_upper_water.position = Vector3(0.0, 2.48, 0.0)
	_fountain_upper_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(_fountain_upper_water)

	# Crowning golden lotus finial spire
	var finial_stem_mesh: CylinderMesh = CylinderMesh.new()
	finial_stem_mesh.top_radius = 0.08
	finial_stem_mesh.bottom_radius = 0.24
	finial_stem_mesh.height = 0.88
	finial_stem_mesh.radial_segments = 8
	var finial_stem: MeshInstance3D = MeshInstance3D.new()
	finial_stem.name = "GoldenFinialSpout"
	finial_stem.mesh = finial_stem_mesh
	finial_stem.material_override = _gold_mat
	finial_stem.position = Vector3(0.0, 2.94, 0.0)
	root.add_child(finial_stem)

	var finial_orb_mesh: SphereMesh = SphereMesh.new()
	finial_orb_mesh.radius = 0.16
	finial_orb_mesh.height = 0.32
	var finial_orb: MeshInstance3D = MeshInstance3D.new()
	finial_orb.name = "FinialCrystalOrb"
	finial_orb.mesh = finial_orb_mesh
	finial_orb.material_override = _fountain_water_mat
	finial_orb.position = Vector3(0.0, 3.46, 0.0)
	root.add_child(finial_orb)

	# 8 Crystal falling water jets from upper basin rim to lower pool
	_fountain_jet_mat = StandardMaterial3D.new()
	_fountain_jet_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fountain_jet_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_fountain_jet_mat.albedo_color = Color(0.75, 0.94, 1.0, 0.58)
	_fountain_jet_mat.emission_enabled = true
	_fountain_jet_mat.emission = COLOR_AQUA_GLOW
	_fountain_jet_mat.emission_energy_multiplier = 0.42

	var jet_mesh: CylinderMesh = CylinderMesh.new()
	jet_mesh.top_radius = 0.025
	jet_mesh.bottom_radius = 0.055
	jet_mesh.height = 1.48
	jet_mesh.radial_segments = 8

	for i: int in range(8):
		var angle: float = float(i) * (TAU / 8.0)
		var jet: MeshInstance3D = MeshInstance3D.new()
		jet.name = "WaterJet_%d" % i
		jet.mesh = jet_mesh
		jet.material_override = _fountain_jet_mat
		jet.position = Vector3(cos(angle) * 1.44, 1.82, sin(angle) * 1.44)
		jet.rotation.y = -angle
		jet.rotation.z = -0.22
		jet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(jet)

	# Falling crystal droplets GPUParticles3D
	var drop_proc: ParticleProcessMaterial = ParticleProcessMaterial.new()
	drop_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	drop_proc.emission_ring_radius = 1.24
	drop_proc.emission_ring_inner_radius = 1.10
	drop_proc.emission_ring_height = 0.1
	drop_proc.emission_ring_axis = Vector3(0.0, 1.0, 0.0)
	drop_proc.direction = Vector3(0.0, -1.0, 0.0)
	drop_proc.spread = 18.0
	drop_proc.initial_velocity_min = 0.35
	drop_proc.initial_velocity_max = 0.85
	drop_proc.gravity = Vector3(0.0, -3.2, 0.0)
	drop_proc.scale_min = 0.45
	drop_proc.scale_max = 0.95
	drop_proc.color = Color(0.78, 0.96, 1.0, 0.82)

	var drop_mat: StandardMaterial3D = StandardMaterial3D.new()
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	drop_mat.albedo_texture = _create_radial_mote_texture()
	drop_mat.albedo_color = Color(0.84, 0.97, 1.0, 0.9)
	drop_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	var drop_quad: QuadMesh = QuadMesh.new()
	drop_quad.size = Vector2(0.10, 0.16)
	drop_quad.material = drop_mat

	_fountain_droplets = GPUParticles3D.new()
	_fountain_droplets.name = "FallingWaterDroplets"
	_fountain_droplets.position = Vector3(0.0, 2.52, 0.0)
	_fountain_droplets.amount = 64
	_fountain_droplets.lifetime = 0.92
	_fountain_droplets.preprocess = 0.6
	_fountain_droplets.amount_ratio = 0.65
	_fountain_droplets.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fountain_droplets.process_material = drop_proc
	_fountain_droplets.draw_pass_1 = drop_quad
	root.add_child(_fountain_droplets)

	# Rising luminous golden-aqua mist droplets GPUParticles3D
	var mist_proc: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mist_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mist_proc.emission_sphere_radius = 1.95
	mist_proc.direction = Vector3(0.0, 1.0, 0.0)
	mist_proc.spread = 28.0
	mist_proc.initial_velocity_min = 0.28
	mist_proc.initial_velocity_max = 0.72
	mist_proc.gravity = Vector3(0.0, 0.14, 0.0)
	mist_proc.scale_min = 0.55
	mist_proc.scale_max = 1.35
	mist_proc.color = Color(0.88, 0.96, 0.98, 0.78)

	var mist_mat: StandardMaterial3D = StandardMaterial3D.new()
	mist_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mist_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mist_mat.albedo_texture = _create_radial_mote_texture()
	mist_mat.albedo_color = Color(0.92, 0.97, 0.86, 0.84)
	mist_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	var mist_quad: QuadMesh = QuadMesh.new()
	mist_quad.size = Vector2(0.14, 0.14)
	mist_quad.material = mist_mat

	_fountain_mist = GPUParticles3D.new()
	_fountain_mist.name = "LuminousMistParticles"
	_fountain_mist.position = Vector3(0.0, 1.35, 0.0)
	_fountain_mist.amount = 54
	_fountain_mist.lifetime = 3.6
	_fountain_mist.preprocess = 1.5
	_fountain_mist.amount_ratio = 0.52
	_fountain_mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fountain_mist.process_material = mist_proc
	_fountain_mist.draw_pass_1 = mist_quad
	root.add_child(_fountain_mist)

	# Aqua-gold aura light
	_fountain_light = OmniLight3D.new()
	_fountain_light.name = "FountainAuraLight"
	_fountain_light.position = Vector3(0.0, 2.3, 0.0)
	_fountain_light.light_color = Color("#9CE8FA")
	_fountain_light.light_energy = 1.35
	_fountain_light.omni_range = 11.0
	_fountain_light.omni_attenuation = 1.4
	_fountain_light.shadow_enabled = false
	root.add_child(_fountain_light)


# ---------------------------------------------------------------------------
# 2. Книга Хроник Акаши (Book of Akashic Chronicles) — East Gallery Alcove
# ---------------------------------------------------------------------------

func _build_chronicle_book() -> void:
	var root: Node3D = Node3D.new()
	root.name = "BookOfAkashicChronicles"
	root.position = BOOK_POS
	# Face slightly inward toward the Rotunda center (-X)
	root.rotation_degrees.y = -90.0
	add_child(root)

	_add_cylinder_collider(root, 1.05, 1.5)

	# Stepped octagonal marble lectern base
	var base_mesh: CylinderMesh = CylinderMesh.new()
	base_mesh.top_radius = 0.92
	base_mesh.bottom_radius = 1.14
	base_mesh.height = 0.28
	base_mesh.radial_segments = 8
	var base_inst: MeshInstance3D = MeshInstance3D.new()
	base_inst.name = "LecternBase"
	base_inst.mesh = base_mesh
	base_inst.material_override = _marble_mat
	base_inst.position = Vector3(0.0, 0.14, 0.0)
	base_inst.rotation_degrees.y = 22.5
	root.add_child(base_inst)

	# Gold base trim ring
	var base_rim_mesh: TorusMesh = TorusMesh.new()
	base_rim_mesh.inner_radius = 0.86
	base_rim_mesh.outer_radius = 0.96
	base_rim_mesh.rings = 16
	base_rim_mesh.ring_segments = 10
	var base_rim: MeshInstance3D = MeshInstance3D.new()
	base_rim.name = "LecternBaseGoldRim"
	base_rim.mesh = base_rim_mesh
	base_rim.material_override = _gold_mat
	base_rim.position = Vector3(0.0, 0.29, 0.0)
	root.add_child(base_rim)

	# Fluted marble lectern pedestal column
	var ped_mesh: CylinderMesh = CylinderMesh.new()
	ped_mesh.top_radius = 0.28
	ped_mesh.bottom_radius = 0.42
	ped_mesh.height = 1.12
	ped_mesh.radial_segments = 12
	var ped_inst: MeshInstance3D = MeshInstance3D.new()
	ped_inst.name = "LecternColumn"
	ped_inst.mesh = ped_mesh
	ped_inst.material_override = _marble_mat
	ped_inst.position = Vector3(0.0, 0.84, 0.0)
	root.add_child(ped_inst)

	# Ornate angled golden lectern cradle
	var cradle_mesh: BoxMesh = BoxMesh.new()
	cradle_mesh.size = Vector3(1.18, 0.09, 0.78)
	var cradle: MeshInstance3D = MeshInstance3D.new()
	cradle.name = "GoldenLecternDesk"
	cradle.mesh = cradle_mesh
	cradle.material_override = _gold_mat
	cradle.position = Vector3(0.0, 1.44, 0.0)
	cradle.rotation_degrees.x = 20.0
	root.add_child(cradle)

	# Floating open Book of Destiny pivot
	_book_float_pivot = Node3D.new()
	_book_float_pivot.name = "FloatingBookPivot"
	_book_float_pivot.position = Vector3(0.0, 1.86, 0.0)
	_book_float_pivot.rotation_degrees.x = 22.0
	root.add_child(_book_float_pivot)

	_book_page_mat = StandardMaterial3D.new()
	_book_page_mat.albedo_color = COLOR_PEARL_PAGE
	_book_page_mat.roughness = 0.35
	_book_page_mat.emission_enabled = true
	_book_page_mat.emission = Color("#FFECC4")
	_book_page_mat.emission_energy_multiplier = 0.48

	_book_rune_mat = StandardMaterial3D.new()
	_book_rune_mat.albedo_color = COLOR_BRIGHT_GOLD
	_book_rune_mat.roughness = 0.25
	_book_rune_mat.metallic = 0.65
	_book_rune_mat.emission_enabled = true
	_book_rune_mat.emission = Color("#FFD984")
	_book_rune_mat.emission_energy_multiplier = 0.85

	# Golden spine
	var spine_mesh: CylinderMesh = CylinderMesh.new()
	spine_mesh.top_radius = 0.055
	spine_mesh.bottom_radius = 0.055
	spine_mesh.height = 0.72
	spine_mesh.radial_segments = 10
	var spine: MeshInstance3D = MeshInstance3D.new()
	spine.name = "BookSpine"
	spine.mesh = spine_mesh
	spine.material_override = _gold_mat
	spine.rotation_degrees.x = 90.0
	_book_float_pivot.add_child(spine)

	# Left & Right open covers + glowing pearl pages + luminous rune bands
	var cover_mesh: BoxMesh = BoxMesh.new()
	cover_mesh.size = Vector3(0.56, 0.045, 0.74)
	var page_mesh: BoxMesh = BoxMesh.new()
	page_mesh.size = Vector3(0.51, 0.055, 0.68)
	var rune_bar_mesh: BoxMesh = BoxMesh.new()
	rune_bar_mesh.size = Vector3(0.34, 0.012, 0.035)

	for side_val: float in [-1.0, 1.0]:
		var wing: Node3D = Node3D.new()
		wing.name = "BookWing_%s" % ("L" if side_val < 0.0 else "R")
		wing.rotation_degrees.z = side_val * 24.0
		_book_float_pivot.add_child(wing)

		var cover: MeshInstance3D = MeshInstance3D.new()
		cover.mesh = cover_mesh
		cover.material_override = _gold_mat
		cover.position = Vector3(side_val * 0.29, -0.02, 0.0)
		wing.add_child(cover)

		var pages: MeshInstance3D = MeshInstance3D.new()
		pages.mesh = page_mesh
		pages.material_override = _book_page_mat
		pages.position = Vector3(side_val * 0.28, 0.03, 0.0)
		wing.add_child(pages)

		# 3 delicate glowing golden rune lines on each open page
		for line_idx: int in range(3):
			var rune_line: MeshInstance3D = MeshInstance3D.new()
			rune_line.mesh = rune_bar_mesh
			rune_line.material_override = _book_rune_mat
			var z_off: float = -0.18 + float(line_idx) * 0.18
			rune_line.position = Vector3(side_val * 0.28, 0.062, z_off)
			wing.add_child(rune_line)

	# Hovering delicate golden halo ring behind the book
	var halo_mesh: TorusMesh = TorusMesh.new()
	halo_mesh.inner_radius = 0.74
	halo_mesh.outer_radius = 0.79
	halo_mesh.rings = 36
	halo_mesh.ring_segments = 10
	_book_halo = MeshInstance3D.new()
	_book_halo.name = "BookHaloRing"
	_book_halo.mesh = halo_mesh
	_book_halo.material_override = _book_rune_mat
	_book_halo.position = Vector3(0.0, 0.14, -0.18)
	_book_halo.rotation_degrees.x = 72.0
	_book_float_pivot.add_child(_book_halo)

	# Hovering golden runes / light motes rising from the open pages
	var mote_proc: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mote_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mote_proc.emission_box_extents = Vector3(0.55, 0.15, 0.40)
	mote_proc.direction = Vector3(0.0, 1.0, 0.0)
	mote_proc.spread = 24.0
	mote_proc.initial_velocity_min = 0.22
	mote_proc.initial_velocity_max = 0.62
	mote_proc.gravity = Vector3(0.0, 0.12, 0.0)
	mote_proc.scale_min = 0.50
	mote_proc.scale_max = 1.25
	mote_proc.color = Color(1.0, 0.90, 0.58, 0.90)

	var mote_mat: StandardMaterial3D = StandardMaterial3D.new()
	mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mote_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mote_mat.albedo_texture = _create_radial_mote_texture()
	mote_mat.albedo_color = Color(1.0, 0.92, 0.66, 0.92)
	mote_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	var mote_quad: QuadMesh = QuadMesh.new()
	mote_quad.size = Vector2(0.11, 0.11)
	mote_quad.material = mote_mat

	_book_motes = GPUParticles3D.new()
	_book_motes.name = "ChronicleRuneMotes"
	_book_motes.position = Vector3(0.0, 1.95, 0.0)
	_book_motes.amount = 44
	_book_motes.lifetime = 3.4
	_book_motes.preprocess = 1.4
	_book_motes.amount_ratio = 0.48
	_book_motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_book_motes.process_material = mote_proc
	_book_motes.draw_pass_1 = mote_quad
	root.add_child(_book_motes)

	# Warm pearl-gold aura light
	_book_light = OmniLight3D.new()
	_book_light.name = "ChronicleBookLight"
	_book_light.position = Vector3(0.0, 2.25, 0.25)
	_book_light.light_color = Color("#FFE6AC")
	_book_light.light_energy = 1.25
	_book_light.omni_range = 10.5
	_book_light.omni_attenuation = 1.4
	_book_light.shadow_enabled = false
	root.add_child(_book_light)


# ---------------------------------------------------------------------------
# 3. Астролябия Кроноса (Kronos Astrolabe) — North Panoramic Cloud Balcony
# ---------------------------------------------------------------------------

func _build_kronos_astrolabe() -> void:
	var root: Node3D = Node3D.new()
	root.name = "KronosAstrolabe"
	root.position = ASTROLABE_POS
	add_child(root)

	_add_cylinder_collider(root, 1.15, 1.6)

	# Stepped octagonal marble pedestal base
	var base_mesh: CylinderMesh = CylinderMesh.new()
	base_mesh.top_radius = 1.12
	base_mesh.bottom_radius = 1.38
	base_mesh.height = 0.34
	base_mesh.radial_segments = 8
	var base_inst: MeshInstance3D = MeshInstance3D.new()
	base_inst.name = "AstrolabeBase"
	base_inst.mesh = base_mesh
	base_inst.material_override = _marble_mat
	base_inst.position = Vector3(0.0, 0.17, 0.0)
	base_inst.rotation_degrees.y = 22.5
	root.add_child(base_inst)

	# Fluted marble pedestal shaft
	var shaft_mesh: CylinderMesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.44
	shaft_mesh.bottom_radius = 0.58
	shaft_mesh.height = 1.05
	shaft_mesh.radial_segments = 12
	var shaft: MeshInstance3D = MeshInstance3D.new()
	shaft.name = "AstrolabePedestalShaft"
	shaft.mesh = shaft_mesh
	shaft.material_override = _marble_mat
	shaft.position = Vector3(0.0, 0.85, 0.0)
	root.add_child(shaft)

	# Golden capital disc & compass ring
	var cap_mesh: CylinderMesh = CylinderMesh.new()
	cap_mesh.top_radius = 0.72
	cap_mesh.bottom_radius = 0.50
	cap_mesh.height = 0.18
	cap_mesh.radial_segments = 16
	var cap: MeshInstance3D = MeshInstance3D.new()
	cap.name = "AstrolabeCapital"
	cap.mesh = cap_mesh
	cap.material_override = _gold_mat
	cap.position = Vector3(0.0, 1.44, 0.0)
	root.add_child(cap)

	# Support meridian cradle stem
	var stem_mesh: CylinderMesh = CylinderMesh.new()
	stem_mesh.top_radius = 0.08
	stem_mesh.bottom_radius = 0.14
	stem_mesh.height = 0.48
	stem_mesh.radial_segments = 10
	var stem: MeshInstance3D = MeshInstance3D.new()
	stem.name = "AstrolabeCradleStem"
	stem.mesh = stem_mesh
	stem.material_override = _gold_mat
	stem.position = Vector3(0.0, 1.72, 0.0)
	root.add_child(stem)

	# Center of the armillary sphere
	var sphere_center: Node3D = Node3D.new()
	sphere_center.name = "ArmillarySphereCenter"
	sphere_center.position = Vector3(0.0, 2.75, 0.0)
	root.add_child(sphere_center)

	# Outer ecliptic ring
	_astro_outer_ring = Node3D.new()
	_astro_outer_ring.name = "OuterEclipticRing"
	sphere_center.add_child(_astro_outer_ring)

	var outer_torus_mesh: TorusMesh = TorusMesh.new()
	outer_torus_mesh.inner_radius = 0.96
	outer_torus_mesh.outer_radius = 1.06
	outer_torus_mesh.rings = 48
	outer_torus_mesh.ring_segments = 14
	var outer_torus: MeshInstance3D = MeshInstance3D.new()
	outer_torus.mesh = outer_torus_mesh
	outer_torus.material_override = _gold_mat
	outer_torus.rotation_degrees.x = 90.0
	_astro_outer_ring.add_child(outer_torus)

	var eq_torus_mesh: TorusMesh = TorusMesh.new()
	eq_torus_mesh.inner_radius = 0.94
	eq_torus_mesh.outer_radius = 1.02
	eq_torus_mesh.rings = 44
	eq_torus_mesh.ring_segments = 12
	var eq_torus: MeshInstance3D = MeshInstance3D.new()
	eq_torus.mesh = eq_torus_mesh
	eq_torus.material_override = _gold_mat
	eq_torus.rotation_degrees.z = 23.5
	_astro_outer_ring.add_child(eq_torus)

	# 4 delicate cardinal star pips on the outer ring
	var pip_mesh: SphereMesh = SphereMesh.new()
	pip_mesh.radius = 0.075
	pip_mesh.height = 0.15
	for i: int in range(4):
		var angle: float = float(i) * (TAU / 4.0)
		var pip: MeshInstance3D = MeshInstance3D.new()
		pip.mesh = pip_mesh
		pip.material_override = _gold_mat
		pip.position = Vector3(cos(angle) * 1.04, sin(angle) * 1.04, 0.0)
		_astro_outer_ring.add_child(pip)

	# Middle meridian ring
	_astro_middle_ring = Node3D.new()
	_astro_middle_ring.name = "MiddleMeridianRing"
	sphere_center.add_child(_astro_middle_ring)

	var mid_torus_mesh: TorusMesh = TorusMesh.new()
	mid_torus_mesh.inner_radius = 0.72
	mid_torus_mesh.outer_radius = 0.80
	mid_torus_mesh.rings = 40
	mid_torus_mesh.ring_segments = 12
	var mid_torus: MeshInstance3D = MeshInstance3D.new()
	mid_torus.mesh = mid_torus_mesh
	mid_torus.material_override = _gold_mat
	mid_torus.rotation_degrees.x = 58.0
	_astro_middle_ring.add_child(mid_torus)

	# Inner zodiac ring + meridian axis rod
	_astro_inner_ring = Node3D.new()
	_astro_inner_ring.name = "InnerZodiacRing"
	sphere_center.add_child(_astro_inner_ring)

	var inner_torus_mesh: TorusMesh = TorusMesh.new()
	inner_torus_mesh.inner_radius = 0.48
	inner_torus_mesh.outer_radius = 0.55
	inner_torus_mesh.rings = 32
	inner_torus_mesh.ring_segments = 10
	var inner_torus: MeshInstance3D = MeshInstance3D.new()
	inner_torus.mesh = inner_torus_mesh
	inner_torus.material_override = _gold_mat
	inner_torus.rotation_degrees.z = 42.0
	_astro_inner_ring.add_child(inner_torus)

	var axis_mesh: CylinderMesh = CylinderMesh.new()
	axis_mesh.top_radius = 0.022
	axis_mesh.bottom_radius = 0.022
	axis_mesh.height = 1.92
	axis_mesh.radial_segments = 8
	var axis_rod: MeshInstance3D = MeshInstance3D.new()
	axis_rod.name = "MeridianAxisRod"
	axis_rod.mesh = axis_mesh
	axis_rod.material_override = _gold_mat
	axis_rod.rotation_degrees.z = 23.5
	_astro_outer_ring.add_child(axis_rod)

	# Warm sunlight core + soft outer corona
	_astro_core_mat = StandardMaterial3D.new()
	_astro_core_mat.albedo_color = COLOR_SOLAR_CORE
	_astro_core_mat.roughness = 0.15
	_astro_core_mat.emission_enabled = true
	_astro_core_mat.emission = Color("#FFD978")
	_astro_core_mat.emission_energy_multiplier = 1.15

	var core_mesh: SphereMesh = SphereMesh.new()
	core_mesh.radius = 0.24
	core_mesh.height = 0.48
	core_mesh.radial_segments = 16
	core_mesh.rings = 12
	var core_inst: MeshInstance3D = MeshInstance3D.new()
	core_inst.name = "SunlightCore"
	core_inst.mesh = core_mesh
	core_inst.material_override = _astro_core_mat
	core_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sphere_center.add_child(core_inst)

	_astro_corona_mat = StandardMaterial3D.new()
	_astro_corona_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_astro_corona_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_astro_corona_mat.albedo_color = Color(1.0, 0.88, 0.56, 0.34)
	_astro_corona_mat.emission_enabled = true
	_astro_corona_mat.emission = Color("#FFE294")
	_astro_corona_mat.emission_energy_multiplier = 0.55

	var corona_mesh: SphereMesh = SphereMesh.new()
	corona_mesh.radius = 0.38
	corona_mesh.height = 0.76
	corona_mesh.radial_segments = 16
	corona_mesh.rings = 12
	var corona_inst: MeshInstance3D = MeshInstance3D.new()
	corona_inst.name = "SunlightCorona"
	corona_inst.mesh = corona_mesh
	corona_inst.material_override = _astro_corona_mat
	corona_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sphere_center.add_child(corona_inst)

	# Warm sunlit golden motes drifting around the astrolabe
	var sun_proc: ParticleProcessMaterial = ParticleProcessMaterial.new()
	sun_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	sun_proc.emission_sphere_radius = 1.15
	sun_proc.direction = Vector3(0.0, 1.0, 0.0)
	sun_proc.spread = 35.0
	sun_proc.initial_velocity_min = 0.20
	sun_proc.initial_velocity_max = 0.58
	sun_proc.gravity = Vector3(0.0, 0.10, 0.0)
	sun_proc.scale_min = 0.50
	sun_proc.scale_max = 1.30
	sun_proc.color = Color(1.0, 0.90, 0.62, 0.88)

	var sun_mat: StandardMaterial3D = StandardMaterial3D.new()
	sun_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sun_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sun_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sun_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	sun_mat.albedo_texture = _create_radial_mote_texture()
	sun_mat.albedo_color = Color(1.0, 0.91, 0.64, 0.90)
	sun_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

	var sun_quad: QuadMesh = QuadMesh.new()
	sun_quad.size = Vector2(0.12, 0.12)
	sun_quad.material = sun_mat

	_astro_motes = GPUParticles3D.new()
	_astro_motes.name = "AstrolabeSunMotes"
	_astro_motes.position = Vector3(0.0, 2.75, 0.0)
	_astro_motes.amount = 48
	_astro_motes.lifetime = 3.8
	_astro_motes.preprocess = 1.5
	_astro_motes.amount_ratio = 0.48
	_astro_motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_astro_motes.process_material = sun_proc
	_astro_motes.draw_pass_1 = sun_quad
	root.add_child(_astro_motes)

	# Warm sunlit gold aura light
	_astro_light = OmniLight3D.new()
	_astro_light.name = "AstrolabeAuraLight"
	_astro_light.position = Vector3(0.0, 2.85, 0.0)
	_astro_light.light_color = Color("#FFE2A0")
	_astro_light.light_energy = 1.55
	_astro_light.omni_range = 12.5
	_astro_light.omni_attenuation = 1.35
	_astro_light.shadow_enabled = false
	root.add_child(_astro_light)
