class_name AkashaNPCs3D
extends Node3D

## Living, friendly Akashic Spirit NPCs & Six-Winged Seraph Archangels across the Prologue world.
## Spawns 5 Fellow Cute Baby-Soul Spirits (spark.glb with deeply saturated jewel-pastel palettes)
## and 2 majestic ~4.2m tall Six-Winged Seraph Archangels (archangel_solaris.glb & archangel_aether.glb)
## guarding the Castle Sanctuary.
## All NPCs gently hover/sway, turn smoothly to face Spark within 12.0m, and respond to
## Soul Call [Q] within 16.0m with a joyful excited hop/elevation and warm golden-aqua light pulse.

signal npc_interacted(npc_id: String, dialogue_sequence_id: String)

const SPARK_MODEL_PATH: String = "res://assets/models/characters/spark.glb"
const ARCHANGEL_SOLARIS_PATH: String = "res://assets/models/characters/archangel_solaris.glb"
const ARCHANGEL_AETHER_PATH: String = "res://assets/models/characters/archangel_aether.glb"
const SPARK_ENERGY_SHADER_PATH: String = "res://shaders/spark_energy.gdshader"

const INTERACT_RANGE: float = 6.2
const ARCHANGEL_INTERACT_RANGE: float = 7.4
const FACE_PLAYER_RANGE: float = 12.0
const SOUL_CALL_RANGE: float = 16.0

const PULSE_COLOR_WARM_GOLD: Color = Color("#FFE090")
const PULSE_COLOR_AQUA_GOLD: Color = Color("#6CEAD8")

var _spark_packed: PackedScene = null
var _solaris_packed: PackedScene = null
var _aether_packed: PackedScene = null
var _spark_shader: Shader = null

var _npcs: Array[Dictionary] = []
var _npc_by_id: Dictionary = {}

var _player_pos: Vector3 = Vector3.ZERO
var _has_player_pos: bool = false
var _anim_time: float = 0.0


func _ready() -> void:
	add_to_group("akasha_npcs")
	_load_shared_resources()
	_spawn_all_npcs()


func _load_shared_resources() -> void:
	if ResourceLoader.exists(SPARK_MODEL_PATH):
		_spark_packed = load(SPARK_MODEL_PATH) as PackedScene
	if ResourceLoader.exists(ARCHANGEL_SOLARIS_PATH):
		_solaris_packed = load(ARCHANGEL_SOLARIS_PATH) as PackedScene
	if ResourceLoader.exists(ARCHANGEL_AETHER_PATH):
		_aether_packed = load(ARCHANGEL_AETHER_PATH) as PackedScene
	if ResourceLoader.exists(SPARK_ENERGY_SHADER_PATH):
		_spark_shader = load(SPARK_ENERGY_SHADER_PATH) as Shader


func _spawn_all_npcs() -> void:
	# 1-5: Fellow Cute Baby-Soul Spirits (spark.glb with rich, deeply saturated jewel-pastel palettes
	# tuned to stay vivid and non-whitish under ACES Filmic tone mapping)
	_spawn_baby_spirit(
		"spirit_plaza",
		"Искра Рассвета",
		Vector3(-4.2, 0.65, 30.5),
		Color("#E84D8A"),
		Color("#8A1B4E"),
		Color("#F2629C"),
		Color("#FF88BA"),
		Color("#B82266"),
		"npc_plaza_spirit",
		0.45,
		0.32,
		0.98,
		0.4
	)

	_spawn_baby_spirit(
		"spirit_central_island",
		"Искра Тишины",
		Vector3(4.2, 7.15, -104.5),
		Color("#1EC896"),
		Color("#0B624B"),
		Color("#34DCAA"),
		Color("#68F0C8"),
		Color("#0E7A5C"),
		"npc_lake_spirit",
		-0.65,
		0.92,
		0.96,
		1.7
	)

	# Grounded over verified CastleIslandGrass West-South Meadow (Y_grass = 0.81 at (-30, -248))
	_spawn_baby_spirit(
		"spirit_west_lake",
		"Искра Росы",
		Vector3(-30.0, 1.45, -248.0),
		Color("#E6A224"),
		Color("#8C520A"),
		Color("#F5B83B"),
		Color("#FFD26B"),
		Color("#B86E10"),
		"npc_lake_spirit",
		-0.55,
		0.48,
		1.0,
		2.9
	)

	# Grounded over verified CastleIslandGrass East-South Meadow knoll (Y_grass = 2.03 at (+30, -248))
	_spawn_baby_spirit(
		"spirit_east_lake",
		"Искра Звёзд",
		Vector3(30.0, 2.65, -248.0),
		Color("#8E54E8"),
		Color("#461C8F"),
		Color("#A672F5"),
		Color("#C49EFF"),
		Color("#5E2AB8"),
		"npc_lake_spirit",
		0.55,
		0.46,
		0.97,
		4.1
	)

	# Grounded over the Baroque Palace North Cloud Terrace (Y = 8.0, clear of Kronos Astrolabe at (0, 8, -304))
	_spawn_baby_spirit(
		"spirit_balcony",
		"Искра Облаков",
		Vector3(-7.5, 8.65, -302.0),
		Color("#2F8EF0"),
		Color("#144894"),
		Color("#4CA6FF"),
		Color("#7CC2FF"),
		Color("#1A5EC4"),
		"npc_plaza_spirit",
		0.35,
		0.42,
		0.99,
		5.3
	)

	# 6-7: Two Majestic Six-Winged Seraph Archangels firmly grounded on the Baroque Palace
	# Formal Arrival Court marble (Y = 0.06, X[-13.5..+13.5], Z[-244..-228]); GLB feet sit at local Y = +0.18
	_spawn_seraph_archangel(
		"archangel_solaris",
		"Архангел Соларис · Хранитель Свитков",
		Vector3(9.2, -0.12, -236.0),
		_solaris_packed,
		"npc_chronicler_rotunda",
		-0.52,
		0.8,
		Color("#FFE096")
	)

	_spawn_seraph_archangel(
		"archangel_aether",
		"Архангел Эфир · Созерцатель Горизонта",
		Vector3(-9.2, -0.12, -236.0),
		_aether_packed,
		"npc_sky_watcher",
		0.52,
		2.6,
		Color("#CFE4FF")
	)


# ---------------------------------------------------------------------------
# Fellow Cute Baby-Soul Spirit Builder (spark.glb)
# ---------------------------------------------------------------------------

func _spawn_baby_spirit(
	npc_id: String,
	display_name: String,
	home_pos: Vector3,
	albedo_col: Color,
	shadow_col: Color,
	emit_col: Color,
	rim_col: Color,
	iris_col: Color,
	dialogue_seq: String,
	default_yaw: float,
	orbit_radius: float,
	spirit_scale: float,
	phase: float
) -> void:
	var root: Node3D = Node3D.new()
	root.name = "NPC_%s" % npc_id
	root.position = home_pos
	root.rotation.y = default_yaw
	add_child(root)

	var visual_pivot: Node3D = Node3D.new()
	visual_pivot.name = "VisualPivot"
	root.add_child(visual_pivot)

	var energy_mats: Array[ShaderMaterial] = []
	var fallback_mat: StandardMaterial3D = null
	var halo_node: Node3D = null

	if _spark_packed != null:
		var inst: Node = _spark_packed.instantiate()
		if inst is Node3D:
			var model_node: Node3D = inst as Node3D
			model_node.name = "SparkModel"
			model_node.scale = Vector3(spirit_scale, spirit_scale, spirit_scale)
			visual_pivot.add_child(model_node)

			halo_node = model_node.find_child("SparkStarHalo", true, false) as Node3D
			if _spark_shader != null:
				_apply_spirit_palette_recursive(
					model_node,
					albedo_col,
					shadow_col,
					emit_col,
					rim_col,
					iris_col,
					energy_mats
				)
			else:
				fallback_mat = _build_fallback_spirit_mat(albedo_col, emit_col)
				_apply_fallback_material_recursive(model_node, fallback_mat)
		else:
			inst.queue_free()
			fallback_mat = _build_procedural_spirit_fallback(visual_pivot, albedo_col, emit_col)
	else:
		fallback_mat = _build_procedural_spirit_fallback(visual_pivot, albedo_col, emit_col)

	var light: OmniLight3D = OmniLight3D.new()
	light.name = "SpiritGlowLight"
	light.position = Vector3(0.0, 0.95, 0.0)
	light.light_color = emit_col.lerp(Color.WHITE, 0.12)
	light.light_energy = 0.65
	light.omni_range = 6.8
	light.omni_attenuation = 1.45
	light.shadow_enabled = false
	visual_pivot.add_child(light)

	var entry: Dictionary = {
		"id": npc_id,
		"name": display_name,
		"kind": "spirit",
		"dialogue_seq": dialogue_seq,
		"root": root,
		"visual_pivot": visual_pivot,
		"home_pos": home_pos,
		"default_yaw": default_yaw,
		"current_yaw": default_yaw,
		"orbit_radius": orbit_radius,
		"orbit_speed": 0.48 if orbit_radius > 0.6 else 0.34,
		"bob_speed": 2.05 + fmod(phase, 0.55),
		"bob_amp": 0.16,
		"phase": phase,
		"light": light,
		"base_light_color": light.light_color,
		"base_light_energy": 0.65,
		"energy_mats": energy_mats,
		"fallback_mat": fallback_mat,
		"halo_node": halo_node,
		"halo_base_y": halo_node.position.y if halo_node != null else 1.75,
		"hop_progress": 0.0,
		"hop_active": false,
		"pulse_level": 0.0,
	}
	_npcs.append(entry)
	_npc_by_id[npc_id] = entry


func _apply_spirit_palette_recursive(
	node: Node,
	albedo_col: Color,
	shadow_col: Color,
	emit_col: Color,
	rim_col: Color,
	iris_col: Color,
	out_energy_mats: Array[ShaderMaterial]
) -> void:
	if node is MeshInstance3D:
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		var mesh_res: Mesh = mesh_inst.mesh
		if mesh_res != null:
			var node_name: String = mesh_inst.name
			var surface_count: int = mesh_res.get_surface_count()

			if node_name == "SparkHeartCore":
				mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var heart_mat: StandardMaterial3D = StandardMaterial3D.new()
				heart_mat.albedo_color = Color("#FFD468")
				heart_mat.roughness = 0.14
				heart_mat.emission_enabled = true
				heart_mat.emission = Color("#FFC848")
				heart_mat.emission_energy_multiplier = 1.05
				for i: int in range(surface_count):
					mesh_inst.set_surface_override_material(i, heart_mat)
			elif node_name == "SparkEyeSclera":
				mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var sclera_mat: StandardMaterial3D = StandardMaterial3D.new()
				sclera_mat.albedo_color = Color("#F4F8FC")
				sclera_mat.roughness = 0.08
				sclera_mat.emission_enabled = true
				sclera_mat.emission = Color("#E8F2FC")
				sclera_mat.emission_energy_multiplier = 0.14
				for i: int in range(surface_count):
					mesh_inst.set_surface_override_material(i, sclera_mat)
			elif node_name == "SparkEyeIris":
				mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var iris_mat: StandardMaterial3D = StandardMaterial3D.new()
				iris_mat.albedo_color = iris_col
				iris_mat.roughness = 0.05
				iris_mat.clearcoat_enabled = true
				iris_mat.clearcoat = 1.0
				iris_mat.clearcoat_roughness = 0.05
				iris_mat.emission_enabled = true
				iris_mat.emission = iris_col.lerp(emit_col, 0.35)
				iris_mat.emission_energy_multiplier = 0.45
				for i: int in range(surface_count):
					mesh_inst.set_surface_override_material(i, iris_mat)
			elif node_name == "SparkEyeHighlight":
				mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var hl_mat: StandardMaterial3D = StandardMaterial3D.new()
				hl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				hl_mat.albedo_color = Color.WHITE
				hl_mat.emission_enabled = true
				hl_mat.emission = Color.WHITE
				hl_mat.emission_energy_multiplier = 1.15
				for i: int in range(surface_count):
					mesh_inst.set_surface_override_material(i, hl_mat)
			elif node_name == "SparkEyeRim":
				mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var rim_mat: StandardMaterial3D = StandardMaterial3D.new()
				rim_mat.albedo_color = Color("#2A2F58")
				rim_mat.roughness = 0.30
				for i: int in range(surface_count):
					mesh_inst.set_surface_override_material(i, rim_mat)
			elif node_name == "SparkCheeks":
				mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var cheek_mat: StandardMaterial3D = StandardMaterial3D.new()
				cheek_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				cheek_mat.albedo_color = Color(0.96, 0.46, 0.58, 0.80)
				cheek_mat.roughness = 0.35
				cheek_mat.emission_enabled = true
				cheek_mat.emission = Color("#F56888")
				cheek_mat.emission_energy_multiplier = 0.38
				for i: int in range(surface_count):
					mesh_inst.set_surface_override_material(i, cheek_mat)
			else:
				var is_mini_wing: bool = node_name.begins_with("SparkMiniWing") or node_name.begins_with("SparkWingRibbon")
				var is_droplet: bool = node_name == "SparkFlameDrops" or node_name == "SparkDroplets"
				if is_mini_wing or is_droplet:
					mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

				for i: int in range(surface_count):
					var smat: ShaderMaterial = ShaderMaterial.new()
					smat.shader = _spark_shader

					var use_albedo: Color = albedo_col
					var use_shadow: Color = shadow_col
					var use_emit: Color = emit_col
					var use_rim: Color = rim_col
					var use_irid: Color = emit_col
					var emit_str: float = 0.26
					var belly_str: float = 0.65
					var wing_flag: float = 0.0
					var droplet_flag: float = 0.0

					if is_mini_wing:
						use_albedo = albedo_col.lerp(rim_col, 0.35)
						use_emit = rim_col
						emit_str = 0.30
						belly_str = 0.0
						wing_flag = 1.0
					elif is_droplet:
						use_albedo = albedo_col.lerp(emit_col, 0.28)
						use_emit = rim_col
						emit_str = 0.32
						belly_str = 0.0
						droplet_flag = 1.0

					smat.set_shader_parameter("base_albedo", use_albedo)
					smat.set_shader_parameter("shadow_tint", use_shadow)
					smat.set_shader_parameter("emission_color", use_emit)
					smat.set_shader_parameter("rim_color", use_rim)
					smat.set_shader_parameter("iridescence_tint", use_irid)
					smat.set_shader_parameter("belly_glow_color", Color("#FFCE6B"))
					smat.set_shader_parameter("emission_strength", emit_str)
					smat.set_shader_parameter("belly_glow_strength", belly_str)
					smat.set_shader_parameter("metallic_val", 0.10)
					smat.set_shader_parameter("roughness_val", 0.14)
					smat.set_shader_parameter("clearcoat_val", 0.92)
					smat.set_shader_parameter("alpha_base", 0.92)
					smat.set_shader_parameter("iridescence_strength", 0.68)
					smat.set_shader_parameter("is_wing_ribbon", wing_flag)
					smat.set_shader_parameter("is_droplet", droplet_flag)
					smat.set_shader_parameter("flight_speed", 0.0)
					smat.set_shader_parameter("energy_flare", 0.0)
					smat.set_shader_parameter("sway_scale", 1.0)

					mesh_inst.set_surface_override_material(i, smat)
					out_energy_mats.append(smat)

	for child: Node in node.get_children():
		_apply_spirit_palette_recursive(
			child,
			albedo_col,
			shadow_col,
			emit_col,
			rim_col,
			iris_col,
			out_energy_mats
		)


func _build_fallback_spirit_mat(albedo_col: Color, emit_col: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = albedo_col
	mat.roughness = 0.16
	mat.emission_enabled = true
	mat.emission = emit_col
	mat.emission_energy_multiplier = 0.42
	return mat


func _apply_fallback_material_recursive(node: Node, mat: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		if not mesh_inst.name.begins_with("SparkEye") and mesh_inst.name != "SparkCheeks":
			mesh_inst.material_override = mat
	for child: Node in node.get_children():
		_apply_fallback_material_recursive(child, mat)


func _build_procedural_spirit_fallback(parent: Node3D, albedo_col: Color, emit_col: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = _build_fallback_spirit_mat(albedo_col, emit_col)
	var body: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.36
	sphere.height = 0.84
	body.mesh = sphere
	body.position = Vector3(0.0, 0.65, 0.0)
	body.material_override = mat
	parent.add_child(body)
	return mat


# ---------------------------------------------------------------------------
# Six-Winged Seraph Archangel Builder (archangel_solaris.glb & archangel_aether.glb)
# ---------------------------------------------------------------------------

func _create_archangel_pbr_materials() -> Dictionary:
	var mats: Dictionary = {}

	# ArchSkin: Classical warm ivory-peach skin with subtle subsurface scattering
	var skin_mat: StandardMaterial3D = StandardMaterial3D.new()
	skin_mat.albedo_color = Color("#EFC6AE")
	skin_mat.roughness = 0.40
	skin_mat.subsurf_scatter_enabled = true
	skin_mat.subsurf_scatter_strength = 0.35
	skin_mat.subsurf_scatter_skin_mode = true
	skin_mat.emission_enabled = true
	skin_mat.emission = Color("#F5D0B8")
	skin_mat.emission_energy_multiplier = 0.04
	mats["ArchSkin"] = skin_mat

	# ArchLips: Soft serene rose lips
	var lips_mat: StandardMaterial3D = StandardMaterial3D.new()
	lips_mat.albedo_color = Color("#C26E6E")
	lips_mat.roughness = 0.30
	lips_mat.subsurf_scatter_enabled = true
	lips_mat.subsurf_scatter_strength = 0.22
	mats["ArchLips"] = lips_mat

	# ArchEyeSclera: Clear pearl-white eye sclera
	var sclera_mat: StandardMaterial3D = StandardMaterial3D.new()
	sclera_mat.albedo_color = Color("#F5F7FC")
	sclera_mat.roughness = 0.08
	sclera_mat.clearcoat_enabled = true
	sclera_mat.clearcoat = 0.90
	sclera_mat.clearcoat_roughness = 0.06
	mats["ArchEyeSclera"] = sclera_mat

	# ArchEyeIris: Warm luminous golden-amber iris
	var iris_mat: StandardMaterial3D = StandardMaterial3D.new()
	iris_mat.albedo_color = Color("#8C5A22")
	iris_mat.roughness = 0.06
	iris_mat.clearcoat_enabled = true
	iris_mat.clearcoat = 1.0
	iris_mat.clearcoat_roughness = 0.04
	iris_mat.emission_enabled = true
	iris_mat.emission = Color("#D89A3C")
	iris_mat.emission_energy_multiplier = 0.32
	mats["ArchEyeIris"] = iris_mat

	# ArchHairGold: Flowing sunlit golden-blonde hair (Solaris)
	var hair_gold_mat: StandardMaterial3D = StandardMaterial3D.new()
	hair_gold_mat.albedo_color = Color("#E4B95E")
	hair_gold_mat.metallic = 0.14
	hair_gold_mat.roughness = 0.32
	hair_gold_mat.clearcoat_enabled = true
	hair_gold_mat.clearcoat = 0.35
	hair_gold_mat.clearcoat_roughness = 0.25
	hair_gold_mat.emission_enabled = true
	hair_gold_mat.emission = Color("#F2CB74")
	hair_gold_mat.emission_energy_multiplier = 0.06
	mats["ArchHairGold"] = hair_gold_mat

	# ArchHairSilver: Windswept celestial silver-platinum hair (Aether)
	var hair_silver_mat: StandardMaterial3D = StandardMaterial3D.new()
	hair_silver_mat.albedo_color = Color("#CCD4E4")
	hair_silver_mat.metallic = 0.22
	hair_silver_mat.roughness = 0.28
	hair_silver_mat.clearcoat_enabled = true
	hair_silver_mat.clearcoat = 0.42
	hair_silver_mat.clearcoat_roughness = 0.22
	hair_silver_mat.emission_enabled = true
	hair_silver_mat.emission = Color("#DCE6F8")
	hair_silver_mat.emission_energy_multiplier = 0.06
	mats["ArchHairSilver"] = hair_silver_mat

	# ArchGoldArmor: Satin champagne-gold celestial armor & starburst staff/bow
	var gold_armor_mat: StandardMaterial3D = StandardMaterial3D.new()
	gold_armor_mat.albedo_color = Color("#DDB25C")
	gold_armor_mat.metallic = 0.86
	gold_armor_mat.roughness = 0.22
	gold_armor_mat.clearcoat_enabled = true
	gold_armor_mat.clearcoat = 0.35
	gold_armor_mat.clearcoat_roughness = 0.16
	gold_armor_mat.emission_enabled = true
	gold_armor_mat.emission = Color("#F2CB74")
	gold_armor_mat.emission_energy_multiplier = 0.10
	mats["ArchGoldArmor"] = gold_armor_mat

	# ArchSilverArmor: Rose-platinum champagne-silver armor (Aether)
	var silver_armor_mat: StandardMaterial3D = StandardMaterial3D.new()
	silver_armor_mat.albedo_color = Color("#D8C6CE")
	silver_armor_mat.metallic = 0.86
	silver_armor_mat.roughness = 0.20
	silver_armor_mat.clearcoat_enabled = true
	silver_armor_mat.clearcoat = 0.42
	silver_armor_mat.clearcoat_roughness = 0.15
	silver_armor_mat.emission_enabled = true
	silver_armor_mat.emission = Color("#EAE0E6")
	silver_armor_mat.emission_energy_multiplier = 0.09
	mats["ArchSilverArmor"] = silver_armor_mat

	# ArchWhiteTunic: Woven ivory-white celestial silk tunic & pleated skirt
	var tunic_mat: StandardMaterial3D = StandardMaterial3D.new()
	tunic_mat.albedo_color = Color("#EDE6DA")
	tunic_mat.roughness = 0.48
	tunic_mat.clearcoat_enabled = true
	tunic_mat.clearcoat = 0.10
	tunic_mat.clearcoat_roughness = 0.42
	tunic_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tunic_mat.emission_enabled = true
	tunic_mat.emission = Color("#F6EFE2")
	tunic_mat.emission_energy_multiplier = 0.04
	mats["ArchWhiteTunic"] = tunic_mat

	# ArchStarCloak: Deep royal starry indigo-sapphire constellation cloak & tabard
	var cloak_mat: StandardMaterial3D = StandardMaterial3D.new()
	cloak_mat.albedo_color = Color("#1B2A6B")
	cloak_mat.metallic = 0.20
	cloak_mat.roughness = 0.34
	cloak_mat.clearcoat_enabled = true
	cloak_mat.clearcoat = 0.25
	cloak_mat.clearcoat_roughness = 0.24
	cloak_mat.rim_enabled = true
	cloak_mat.rim = 0.42
	cloak_mat.rim_tint = 0.65
	cloak_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloak_mat.emission_enabled = true
	cloak_mat.emission = Color("#465CC4")
	cloak_mat.emission_energy_multiplier = 0.24
	mats["ArchStarCloak"] = cloak_mat

	# ArchWingFeathers: Pearl-ivory seraphim feathers with gentle celestial iridescence
	var wing_mat: StandardMaterial3D = StandardMaterial3D.new()
	wing_mat.albedo_color = Color("#F0EAE0")
	wing_mat.metallic = 0.05
	wing_mat.roughness = 0.30
	wing_mat.clearcoat_enabled = true
	wing_mat.clearcoat = 0.38
	wing_mat.clearcoat_roughness = 0.22
	wing_mat.rim_enabled = true
	wing_mat.rim = 0.58
	wing_mat.rim_tint = 0.42
	wing_mat.emission_enabled = true
	wing_mat.emission = Color("#FAF0DC")
	wing_mat.emission_energy_multiplier = 0.10
	mats["ArchWingFeathers"] = wing_mat

	# ArchWingGoldQuills: Gilded feather rachis / leading quills
	var quill_mat: StandardMaterial3D = StandardMaterial3D.new()
	quill_mat.albedo_color = Color("#DFBC6C")
	quill_mat.metallic = 0.72
	quill_mat.roughness = 0.24
	quill_mat.emission_enabled = true
	quill_mat.emission = Color("#F5D282")
	quill_mat.emission_energy_multiplier = 0.16
	mats["ArchWingGoldQuills"] = quill_mat

	# ArchStarCore: Warm radiant golden starlight core (staff, bow, halo gems, blessing orb)
	var core_mat: StandardMaterial3D = StandardMaterial3D.new()
	core_mat.albedo_color = Color("#FFF0B8")
	core_mat.roughness = 0.10
	core_mat.emission_enabled = true
	core_mat.emission = Color("#FFDC82")
	core_mat.emission_energy_multiplier = 1.65
	mats["ArchStarCore"] = core_mat

	return mats


func _apply_archangel_materials_recursive(node: Node, mats: Dictionary) -> void:
	if node is MeshInstance3D:
		var mesh_inst: MeshInstance3D = node as MeshInstance3D
		var mesh_res: Mesh = mesh_inst.mesh
		if mesh_res != null:
			var surface_count: int = mesh_res.get_surface_count()
			for i: int in range(surface_count):
				var orig_mat: Material = mesh_res.surface_get_material(i)
				var mat_name: String = ""
				if orig_mat != null:
					mat_name = orig_mat.resource_name

				# Strip any Blender numeric suffix like ".001"
				var dot_idx: int = mat_name.find(".")
				if dot_idx > 0:
					mat_name = mat_name.substr(0, dot_idx)

				if mats.has(mat_name):
					mesh_inst.set_surface_override_material(i, mats[mat_name] as StandardMaterial3D)
					if mat_name == "ArchStarCore":
						mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for child: Node in node.get_children():
		_apply_archangel_materials_recursive(child, mats)


func _spawn_seraph_archangel(
	npc_id: String,
	display_name: String,
	home_pos: Vector3,
	packed_scene: PackedScene,
	dialogue_seq: String,
	default_yaw: float,
	phase: float,
	presence_tint: Color
) -> void:
	var root: Node3D = Node3D.new()
	root.name = "NPC_%s" % npc_id
	root.position = home_pos
	root.rotation.y = default_yaw
	add_child(root)

	var visual_pivot: Node3D = Node3D.new()
	visual_pivot.name = "VisualPivot"
	root.add_child(visual_pivot)

	var arch_mats: Dictionary = _create_archangel_pbr_materials()
	var halo_pivot: Node3D = null

	if packed_scene != null:
		var inst: Node = packed_scene.instantiate()
		if inst is Node3D:
			var model_node: Node3D = inst as Node3D
			model_node.name = "SeraphModel"
			visual_pivot.add_child(model_node)
			_apply_archangel_materials_recursive(model_node, arch_mats)
			halo_pivot = model_node.find_child("ArchHaloPivot", true, false) as Node3D
		else:
			inst.queue_free()

	# Warm celestial presence OmniLight3D illuminating armor, wings & sanctuary floor
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "ArchangelPresenceLight"
	light.position = Vector3(0.0, 2.75, 0.85)
	light.light_color = presence_tint
	light.light_energy = 1.15
	light.omni_range = 11.5
	light.omni_attenuation = 1.35
	light.shadow_enabled = false
	visual_pivot.add_child(light)

	var star_core_mat: StandardMaterial3D = arch_mats.get("ArchStarCore", null) as StandardMaterial3D
	var cloak_mat: StandardMaterial3D = arch_mats.get("ArchStarCloak", null) as StandardMaterial3D

	var entry: Dictionary = {
		"id": npc_id,
		"name": display_name,
		"kind": "archangel",
		"dialogue_seq": dialogue_seq,
		"root": root,
		"visual_pivot": visual_pivot,
		"home_pos": home_pos,
		"default_yaw": default_yaw,
		"current_yaw": default_yaw,
		"orbit_radius": 0.0,
		"orbit_speed": 0.0,
		"bob_speed": 0.92,
		"bob_amp": 0.0,
		"phase": phase,
		"light": light,
		"base_light_color": light.light_color,
		"base_light_energy": 1.15,
		"halo_pivot": halo_pivot,
		"star_core_mat": star_core_mat,
		"cloak_mat": cloak_mat,
		"hop_progress": 0.0,
		"hop_active": false,
		"pulse_level": 0.0,
	}
	_npcs.append(entry)
	_npc_by_id[npc_id] = entry


# ---------------------------------------------------------------------------
# Per-Frame Alive Animation & Responsive Behavior
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_anim_time += delta
	var yaw_blend: float = 1.0 - exp(-4.8 * delta)

	for entry: Dictionary in _npcs:
		var root: Node3D = entry["root"] as Node3D
		var visual_pivot: Node3D = entry["visual_pivot"] as Node3D
		if root == null or visual_pivot == null:
			continue

		var is_spirit: bool = str(entry["kind"]) == "spirit"
		var home_pos: Vector3 = entry["home_pos"] as Vector3
		var phase: float = float(entry["phase"])
		var bob_speed: float = float(entry["bob_speed"])
		var bob_amp: float = float(entry["bob_amp"])
		var orbit_radius: float = float(entry["orbit_radius"])
		var orbit_speed: float = float(entry["orbit_speed"])

		# 1. Gentle organic XZ drift / playful orbit (spirits)
		var drift_x: float = 0.0
		var drift_z: float = 0.0
		if orbit_radius > 0.001:
			var angle: float = _anim_time * orbit_speed + phase
			drift_x = cos(angle) * orbit_radius
			drift_z = sin(angle * 0.85) * orbit_radius * 0.82

		# 2. Excited hop / regal blessing elevation (from Soul Call [Q] or greeting)
		var hop_y: float = 0.0
		var hop_spin: float = 0.0
		if bool(entry["hop_active"]):
			var hop_speed: float = 1.65 if is_spirit else 1.10
			var progress: float = float(entry["hop_progress"]) + delta * hop_speed
			if progress >= 1.0:
				entry["hop_progress"] = 0.0
				entry["hop_active"] = false
			else:
				entry["hop_progress"] = progress
				var arc: float = sin(progress * PI)
				hop_y = arc * (0.68 if is_spirit else 0.36)
				if is_spirit:
					hop_spin = arc * 0.42

		# 3. Light pulse decay
		var pulse: float = float(entry["pulse_level"])
		if pulse > 0.001:
			pulse = maxf(0.0, pulse - delta * 0.82)
			entry["pulse_level"] = pulse

		# Apply gentle hover + hop to root position
		var bob_y: float = sin(_anim_time * bob_speed + phase) * bob_amp
		root.position = Vector3(
			home_pos.x + drift_x,
			home_pos.y + bob_y + hop_y,
			home_pos.z + drift_z
		)

		# 4. Smoothly turn to face player within 12.0m, else gently sway around default facing
		var target_yaw: float = float(entry["default_yaw"]) + sin(_anim_time * 0.46 + phase) * (0.14 if is_spirit else 0.06)
		if _has_player_pos:
			var to_player: Vector3 = _player_pos - root.global_position
			var dist_sq: float = to_player.length_squared()
			if dist_sq <= FACE_PLAYER_RANGE * FACE_PLAYER_RANGE and dist_sq > 0.04:
				if is_spirit:
					# spark.glb faces -Z forward
					target_yaw = atan2(-to_player.x, -to_player.z)
				else:
					# Six-Winged Seraph Archangel GLBs face +Z forward
					target_yaw = atan2(to_player.x, to_player.z)

		var current_yaw: float = lerp_angle(float(entry["current_yaw"]), target_yaw, yaw_blend)
		entry["current_yaw"] = current_yaw
		root.rotation.y = current_yaw + hop_spin

		# 5. Archetype-specific organic animations
		if is_spirit:
			visual_pivot.rotation.z = sin(_anim_time * 1.65 + phase) * 0.08
			visual_pivot.rotation.x = sin(_anim_time * 1.25 + phase * 1.3) * 0.05

			var halo_node: Node3D = entry["halo_node"] as Node3D
			if halo_node != null:
				halo_node.rotation.y += delta * (0.75 + pulse * 2.2)
				halo_node.position.y = float(entry["halo_base_y"]) + sin(_anim_time * 2.8 + phase) * 0.03

			var energy_mats: Array = entry["energy_mats"] as Array
			for mat_var: Variant in energy_mats:
				var smat: ShaderMaterial = mat_var as ShaderMaterial
				if smat != null:
					smat.set_shader_parameter("energy_flare", pulse * 1.35)

			var fallback_mat: StandardMaterial3D = entry["fallback_mat"] as StandardMaterial3D
			if fallback_mat != null:
				fallback_mat.emission_energy_multiplier = 0.42 + pulse * 1.10
		else:
			# Regal gentle celestial sway + slow rotation of the Golden Runic Celestial Halo
			visual_pivot.rotation.z = sin(_anim_time * 0.65 + phase) * 0.018
			visual_pivot.rotation.x = sin(_anim_time * 0.48 + phase * 1.2) * 0.014

			var halo_pivot: Node3D = entry["halo_pivot"] as Node3D
			if halo_pivot != null:
				halo_pivot.rotation.z += delta * (0.30 + pulse * 1.25)

			var star_core_mat: StandardMaterial3D = entry["star_core_mat"] as StandardMaterial3D
			if star_core_mat != null:
				var star_shimmer: float = sin(_anim_time * 2.4 + phase) * 0.16
				star_core_mat.emission_energy_multiplier = 1.65 + star_shimmer + pulse * 1.85

			var cloak_mat: StandardMaterial3D = entry["cloak_mat"] as StandardMaterial3D
			if cloak_mat != null:
				var cloak_shimmer: float = sin(_anim_time * 1.6 + phase) * 0.05
				cloak_mat.emission_energy_multiplier = 0.24 + cloak_shimmer + pulse * 0.35

		# 6. Warm golden-aqua light pulse on OmniLight3D
		var light: OmniLight3D = entry["light"] as OmniLight3D
		if light != null:
			var base_col: Color = entry["base_light_color"] as Color
			var base_energy: float = float(entry["base_light_energy"])
			var pulse_tint: Color = PULSE_COLOR_AQUA_GOLD if is_spirit else PULSE_COLOR_WARM_GOLD
			light.light_color = base_col.lerp(pulse_tint, clampf(pulse * 0.72, 0.0, 1.0))
			light.light_energy = base_energy + sin(_anim_time * 2.1 + phase) * 0.07 + pulse * 1.95
			light.omni_range = (6.8 if is_spirit else 11.5) + pulse * 4.5


# ---------------------------------------------------------------------------
# Public API (matching CastleInteractables3D conventions)
# ---------------------------------------------------------------------------

## Updates the cached player position so nearby NPCs gently turn to face Spark.
func update_player_position(player_pos: Vector3) -> void:
	_player_pos = player_pos
	_has_player_pos = true


## Returns the npc_id of the nearest NPC within interaction range, or "" if none.
func get_nearest_npc_in_range(player_pos: Vector3) -> String:
	var best_id: String = ""
	var best_dist: float = ARCHANGEL_INTERACT_RANGE

	for entry: Dictionary in _npcs:
		var root: Node3D = entry["root"] as Node3D
		if root == null:
			continue
		var is_archangel: bool = str(entry["kind"]) == "archangel"
		var max_range: float = ARCHANGEL_INTERACT_RANGE if is_archangel else INTERACT_RANGE
		var dist: float = player_pos.distance_to(root.global_position)
		if dist <= max_range and dist <= best_dist:
			best_dist = dist
			best_id = str(entry["id"])

	return best_id


## Returns a localized HUD prompt for the given npc_id (e.g. "✦  [E]  Поговорить: Архангел Соларис · Хранитель Свитков").
func get_interaction_prompt(npc_id: String) -> String:
	if npc_id.is_empty() or not _npc_by_id.has(npc_id):
		return ""
	var entry: Dictionary = _npc_by_id[npc_id] as Dictionary
	var display_name: String = str(entry.get("name", ""))
	if display_name.is_empty():
		return ""
	return "✦  [E]  Поговорить: %s" % display_name


## Interacts with the nearest NPC within range. Triggers a warm greeting response and emits `npc_interacted`.
func interact_nearest(player_pos: Vector3) -> bool:
	var npc_id: String = get_nearest_npc_in_range(player_pos)
	if npc_id.is_empty() or not _npc_by_id.has(npc_id):
		return false

	var entry: Dictionary = _npc_by_id[npc_id] as Dictionary
	entry["hop_active"] = true
	entry["hop_progress"] = 0.0
	entry["pulse_level"] = 1.0

	var dialogue_seq: String = str(entry.get("dialogue_seq", ""))
	npc_interacted.emit(npc_id, dialogue_seq)
	return true


## Responds to Spark's Soul Call [Q]: all NPCs within 16.0m do a joyful excited hop/elevation + warm golden-aqua light pulse.
func respond_to_soul_call(origin: Vector3) -> bool:
	var responded: bool = false
	for entry: Dictionary in _npcs:
		var root: Node3D = entry["root"] as Node3D
		if root == null:
			continue
		if origin.distance_to(root.global_position) <= SOUL_CALL_RANGE:
			entry["hop_active"] = true
			entry["hop_progress"] = 0.0
			entry["pulse_level"] = 1.0
			responded = true
	return responded
