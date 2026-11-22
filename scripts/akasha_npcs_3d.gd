class_name AkashaNPCs3D
extends Node3D

## Living, friendly Akashic Spirit NPCs & Serene Chroniclers across the Prologue world.
## Spawns 5 Fellow Cute Baby-Soul Spirits (spark.glb with custom pastel-jewel palettes)
## and 3 procedurally sculpted ~2.6m tall Robed Akashic Chroniclers / Garden Keepers.
## All NPCs gently bob/sway, turn smoothly to face Spark within 12.0m, and respond to
## Soul Call [Q] within 16.0m with a joyful excited hop and warm golden-aqua light pulse.

signal npc_interacted(npc_id: String, dialogue_sequence_id: String)

const SPARK_MODEL_PATH: String = "res://assets/models/characters/spark.glb"
const SPARK_ENERGY_SHADER_PATH: String = "res://shaders/spark_energy.gdshader"
const MENTOR_SHADER_PATH: String = "res://shaders/ethereal_mentor.gdshader"

const INTERACT_RANGE: float = 6.2
const FACE_PLAYER_RANGE: float = 12.0
const SOUL_CALL_RANGE: float = 16.0

const PULSE_COLOR_WARM_AQUA: Color = Color("#FFE6A8")
const PULSE_COLOR_AQUA_GOLD: Color = Color("#B8F6EE")

# Shared materials for robed chroniclers
var _gold_mat: StandardMaterial3D = null
var _bright_gold_mat: StandardMaterial3D = null
var _ivory_skin_mat: StandardMaterial3D = null
var _parchment_mat: StandardMaterial3D = null
var _lotus_pink_mat: StandardMaterial3D = null

var _spark_packed: PackedScene = null
var _spark_shader: Shader = null
var _mentor_shader: Shader = null

var _npcs: Array[Dictionary] = []
var _npc_by_id: Dictionary = {}

var _player_pos: Vector3 = Vector3.ZERO
var _has_player_pos: bool = false
var _anim_time: float = 0.0


func _ready() -> void:
	add_to_group("akasha_npcs")
	_load_shared_resources()
	_init_shared_materials()
	_spawn_all_npcs()


func _load_shared_resources() -> void:
	if ResourceLoader.exists(SPARK_MODEL_PATH):
		_spark_packed = load(SPARK_MODEL_PATH) as PackedScene
	if ResourceLoader.exists(SPARK_ENERGY_SHADER_PATH):
		_spark_shader = load(SPARK_ENERGY_SHADER_PATH) as Shader
	if ResourceLoader.exists(MENTOR_SHADER_PATH):
		_mentor_shader = load(MENTOR_SHADER_PATH) as Shader


func _init_shared_materials() -> void:
	_gold_mat = StandardMaterial3D.new()
	_gold_mat.albedo_color = Color("#DFC07A")
	_gold_mat.metallic = 0.72
	_gold_mat.roughness = 0.28
	_gold_mat.emission_enabled = true
	_gold_mat.emission = Color("#F5D890")
	_gold_mat.emission_energy_multiplier = 0.22

	_bright_gold_mat = StandardMaterial3D.new()
	_bright_gold_mat.albedo_color = Color("#FCE4A6")
	_bright_gold_mat.metallic = 0.48
	_bright_gold_mat.roughness = 0.18
	_bright_gold_mat.emission_enabled = true
	_bright_gold_mat.emission = Color("#FFE49C")
	_bright_gold_mat.emission_energy_multiplier = 0.65

	_ivory_skin_mat = StandardMaterial3D.new()
	_ivory_skin_mat.albedo_color = Color("#F8F2EA")
	_ivory_skin_mat.roughness = 0.24
	_ivory_skin_mat.emission_enabled = true
	_ivory_skin_mat.emission = Color("#FFF4E2")
	_ivory_skin_mat.emission_energy_multiplier = 0.18

	_parchment_mat = StandardMaterial3D.new()
	_parchment_mat.albedo_color = Color("#FFF8E8")
	_parchment_mat.roughness = 0.35
	_parchment_mat.emission_enabled = true
	_parchment_mat.emission = Color("#FFEAB8")
	_parchment_mat.emission_energy_multiplier = 0.45
	_parchment_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	_lotus_pink_mat = StandardMaterial3D.new()
	_lotus_pink_mat.albedo_color = Color("#FFC6DC")
	_lotus_pink_mat.roughness = 0.25
	_lotus_pink_mat.emission_enabled = true
	_lotus_pink_mat.emission = Color("#FFB0CE")
	_lotus_pink_mat.emission_energy_multiplier = 0.48
	_lotus_pink_mat.cull_mode = BaseMaterial3D.CULL_DISABLED


func _spawn_all_npcs() -> void:
	# 1-5: Fellow Cute Baby-Soul Spirits (spark.glb with distinct pastel-jewel glow)
	_spawn_baby_spirit(
		"spirit_plaza",
		"Искра Рассвета",
		Vector3(-4.2, 0.8, 30.5),
		Color("#FF9EC4"),
		Color("#C85A8E"),
		Color("#FFB8D4"),
		Color("#FFD6EA"),
		Color("#E0689C"),
		"npc_plaza_spirit",
		0.45,
		0.32,
		0.98,
		0.4
	)

	_spawn_baby_spirit(
		"spirit_central_island",
		"Искра Тишины",
		Vector3(4.2, 7.3, -104.5),
		Color("#70F0C4"),
		Color("#2A9678"),
		Color("#9CFCE0"),
		Color("#C6FFEE"),
		Color("#2EA888"),
		"npc_lake_spirit",
		-0.65,
		0.92,
		0.96,
		1.7
	)

	_spawn_baby_spirit(
		"spirit_west_lake",
		"Искра Росы",
		Vector3(-35.5, 4.9, -274.0),
		Color("#FFE082"),
		Color("#C6862C"),
		Color("#FFEEA8"),
		Color("#FFF6CE"),
		Color("#D69630"),
		"npc_lake_spirit",
		-0.85,
		0.48,
		1.0,
		2.9
	)

	_spawn_baby_spirit(
		"spirit_east_lake",
		"Искра Звёзд",
		Vector3(35.5, 4.9, -274.0),
		Color("#C89CFF"),
		Color("#7450C8"),
		Color("#DEC2FF"),
		Color("#EFE2FF"),
		Color("#8A5CE0"),
		"npc_lake_spirit",
		0.85,
		0.46,
		0.97,
		4.1
	)

	_spawn_baby_spirit(
		"spirit_balcony",
		"Искра Облаков",
		Vector3(-31.0, 8.9, -284.0),
		Color("#88C8FF"),
		Color("#4074CA"),
		Color("#B2DAFF"),
		Color("#D6EEFF"),
		Color("#488CE8"),
		"npc_plaza_spirit",
		0.35,
		0.42,
		0.99,
		5.3
	)

	# 6-8: Serene Robed Akashic Chroniclers / Garden Keepers (~2.6m tall)
	_spawn_robed_chronicler(
		"chronicler_rotunda",
		"Хранитель Свитков",
		Vector3(14.5, 8.0, -271.0),
		"scrolls",
		Color("#EFE6D6"),
		Color("#FFE29E"),
		"npc_chronicler_rotunda",
		1.15,
		0.8
	)

	_spawn_robed_chronicler(
		"keeper_garden",
		"Садовник Облаков",
		Vector3(-17.0, 4.0, -256.0),
		"lantern",
		Color("#EBF0E6"),
		Color("#D8F5E0"),
		"npc_garden_keeper",
		-0.75,
		2.4
	)

	_spawn_robed_chronicler(
		"watcher_balcony",
		"Созерцатель Горизонта",
		Vector3(31.0, 8.9, -282.0),
		"astrolabe",
		Color("#E8ECF6"),
		Color("#CFE6FF"),
		"npc_sky_watcher",
		-0.55,
		3.9
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
	light.light_color = emit_col.lerp(Color.WHITE, 0.25)
	light.light_energy = 0.68
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
		"base_light_energy": 0.68,
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
				heart_mat.albedo_color = Color("#FFE6A6")
				heart_mat.roughness = 0.14
				heart_mat.emission_enabled = true
				heart_mat.emission = Color("#FFE6A6")
				heart_mat.emission_energy_multiplier = 1.15
				for i: int in range(surface_count):
					mesh_inst.set_surface_override_material(i, heart_mat)
			elif node_name == "SparkEyeSclera":
				mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var sclera_mat: StandardMaterial3D = StandardMaterial3D.new()
				sclera_mat.albedo_color = Color("#F8FCFF")
				sclera_mat.roughness = 0.08
				sclera_mat.emission_enabled = true
				sclera_mat.emission = Color("#EEF8FF")
				sclera_mat.emission_energy_multiplier = 0.18
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
				iris_mat.emission = iris_col.lerp(Color.WHITE, 0.25)
				iris_mat.emission_energy_multiplier = 0.42
				for i: int in range(surface_count):
					mesh_inst.set_surface_override_material(i, iris_mat)
			elif node_name == "SparkEyeHighlight":
				mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var hl_mat: StandardMaterial3D = StandardMaterial3D.new()
				hl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				hl_mat.albedo_color = Color.WHITE
				hl_mat.emission_enabled = true
				hl_mat.emission = Color.WHITE
				hl_mat.emission_energy_multiplier = 1.25
				for i: int in range(surface_count):
					mesh_inst.set_surface_override_material(i, hl_mat)
			elif node_name == "SparkEyeRim":
				mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var rim_mat: StandardMaterial3D = StandardMaterial3D.new()
				rim_mat.albedo_color = Color("#343E6E")
				rim_mat.roughness = 0.30
				for i: int in range(surface_count):
					mesh_inst.set_surface_override_material(i, rim_mat)
			elif node_name == "SparkCheeks":
				mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var cheek_mat: StandardMaterial3D = StandardMaterial3D.new()
				cheek_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				cheek_mat.albedo_color = Color(1.0, 0.68, 0.72, 0.78)
				cheek_mat.roughness = 0.35
				cheek_mat.emission_enabled = true
				cheek_mat.emission = Color("#FFA4B4")
				cheek_mat.emission_energy_multiplier = 0.45
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
					var emit_str: float = 0.34
					var belly_str: float = 0.80
					var wing_flag: float = 0.0
					var droplet_flag: float = 0.0

					if is_mini_wing:
						use_albedo = albedo_col.lerp(Color.WHITE, 0.42)
						use_emit = rim_col
						emit_str = 0.40
						belly_str = 0.0
						wing_flag = 1.0
					elif is_droplet:
						use_albedo = albedo_col.lerp(Color.WHITE, 0.28)
						use_emit = rim_col
						emit_str = 0.44
						belly_str = 0.0
						droplet_flag = 1.0

					smat.set_shader_parameter("base_albedo", use_albedo)
					smat.set_shader_parameter("shadow_tint", use_shadow)
					smat.set_shader_parameter("emission_color", use_emit)
					smat.set_shader_parameter("rim_color", use_rim)
					smat.set_shader_parameter("iridescence_tint", use_irid)
					smat.set_shader_parameter("belly_glow_color", Color("#FFE8B2"))
					smat.set_shader_parameter("emission_strength", emit_str)
					smat.set_shader_parameter("belly_glow_strength", belly_str)
					smat.set_shader_parameter("metallic_val", 0.08)
					smat.set_shader_parameter("roughness_val", 0.13)
					smat.set_shader_parameter("clearcoat_val", 0.92)
					smat.set_shader_parameter("alpha_base", 0.90)
					smat.set_shader_parameter("iridescence_strength", 0.72)
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
	mat.emission_energy_multiplier = 0.55
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
# Serene Robed Akashic Chroniclers / Garden Keepers (~2.6m tall)
# ---------------------------------------------------------------------------

func _spawn_robed_chronicler(
	npc_id: String,
	display_name: String,
	home_pos: Vector3,
	prop_kind: String,
	robe_col: Color,
	accent_glow: Color,
	dialogue_seq: String,
	default_yaw: float,
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

	var robe_mat: Material = _create_robe_material(robe_col, accent_glow)

	# 1. Flowing lower robe skirt (graceful flared silhouette)
	var skirt: MeshInstance3D = MeshInstance3D.new()
	skirt.name = "RobeSkirt"
	var skirt_mesh: CylinderMesh = CylinderMesh.new()
	skirt_mesh.top_radius = 0.24
	skirt_mesh.bottom_radius = 0.56
	skirt_mesh.height = 1.48
	skirt_mesh.radial_segments = 24
	skirt.mesh = skirt_mesh
	skirt.position = Vector3(0.0, 0.78, 0.0)
	skirt.material_override = robe_mat
	visual_pivot.add_child(skirt)

	# Golden hem trim ring
	var hem_ring: MeshInstance3D = MeshInstance3D.new()
	hem_ring.name = "HemTrim"
	var hem_mesh: TorusMesh = TorusMesh.new()
	hem_mesh.inner_radius = 0.51
	hem_mesh.outer_radius = 0.57
	hem_mesh.rings = 24
	hem_mesh.ring_segments = 10
	hem_ring.mesh = hem_mesh
	hem_ring.position = Vector3(0.0, 0.08, 0.0)
	hem_ring.material_override = _gold_mat
	visual_pivot.add_child(hem_ring)

	# 2. Upper torso bodice
	var bodice: MeshInstance3D = MeshInstance3D.new()
	bodice.name = "RobeBodice"
	var bodice_mesh: CylinderMesh = CylinderMesh.new()
	bodice_mesh.top_radius = 0.28
	bodice_mesh.bottom_radius = 0.22
	bodice_mesh.height = 0.58
	bodice_mesh.radial_segments = 20
	bodice.mesh = bodice_mesh
	bodice.position = Vector3(0.0, 1.72, 0.0)
	bodice.material_override = robe_mat
	visual_pivot.add_child(bodice)

	# Flowing shoulder cape / mantle
	var mantle: MeshInstance3D = MeshInstance3D.new()
	mantle.name = "ShoulderMantle"
	var mantle_mesh: CylinderMesh = CylinderMesh.new()
	mantle_mesh.top_radius = 0.22
	mantle_mesh.bottom_radius = 0.44
	mantle_mesh.height = 0.42
	mantle_mesh.radial_segments = 24
	mantle.mesh = mantle_mesh
	mantle.position = Vector3(0.0, 1.84, 0.04)
	mantle.material_override = robe_mat
	visual_pivot.add_child(mantle)

	# Satin-gold celestial stole sash draped down the front (-Z)
	var stole: MeshInstance3D = MeshInstance3D.new()
	stole.name = "GoldStole"
	var stole_mesh: BoxMesh = BoxMesh.new()
	stole_mesh.size = Vector3(0.14, 1.38, 0.04)
	stole.mesh = stole_mesh
	stole.position = Vector3(0.0, 1.18, -0.34)
	stole.rotation.x = -0.15
	stole.material_override = _gold_mat
	visual_pivot.add_child(stole)

	# Waist gold belt ring
	var belt: MeshInstance3D = MeshInstance3D.new()
	belt.name = "WaistBelt"
	var belt_mesh: TorusMesh = TorusMesh.new()
	belt_mesh.inner_radius = 0.21
	belt_mesh.outer_radius = 0.26
	belt_mesh.rings = 20
	belt_mesh.ring_segments = 10
	belt.mesh = belt_mesh
	belt.position = Vector3(0.0, 1.48, 0.0)
	belt.material_override = _gold_mat
	visual_pivot.add_child(belt)

	# 3. Graceful sleeves angled gently forward (-Z)
	for side_sign: int in [-1, 1]:
		var sleeve: MeshInstance3D = MeshInstance3D.new()
		sleeve.name = "Sleeve_%s" % ("L" if side_sign < 0 else "R")
		var sleeve_mesh: CylinderMesh = CylinderMesh.new()
		sleeve_mesh.top_radius = 0.09
		sleeve_mesh.bottom_radius = 0.16
		sleeve_mesh.height = 0.62
		sleeve_mesh.radial_segments = 16
		sleeve.mesh = sleeve_mesh
		sleeve.position = Vector3(float(side_sign) * 0.27, 1.62, -0.16)
		sleeve.rotation = Vector3(0.72, 0.0, float(side_sign) * -0.26)
		sleeve.material_override = robe_mat
		visual_pivot.add_child(sleeve)

	# 4. Serene luminous head & flowing hood/veil
	var head: MeshInstance3D = MeshInstance3D.new()
	head.name = "Head"
	var head_mesh: SphereMesh = SphereMesh.new()
	head_mesh.radius = 0.185
	head_mesh.height = 0.40
	head_mesh.radial_segments = 20
	head_mesh.rings = 14
	head.mesh = head_mesh
	head.position = Vector3(0.0, 2.22, -0.02)
	head.material_override = _ivory_skin_mat
	visual_pivot.add_child(head)

	# Hood / celestial veil framing back and crown of head
	var hood: MeshInstance3D = MeshInstance3D.new()
	hood.name = "CelestialHood"
	var hood_mesh: SphereMesh = SphereMesh.new()
	hood_mesh.radius = 0.23
	hood_mesh.height = 0.48
	hood_mesh.radial_segments = 20
	hood_mesh.rings = 14
	hood.mesh = hood_mesh
	hood.position = Vector3(0.0, 2.24, 0.06)
	hood.material_override = robe_mat
	visual_pivot.add_child(hood)

	# Delicate golden brow circlet
	var circlet: MeshInstance3D = MeshInstance3D.new()
	circlet.name = "GoldCirclet"
	var circlet_mesh: TorusMesh = TorusMesh.new()
	circlet_mesh.inner_radius = 0.17
	circlet_mesh.outer_radius = 0.205
	circlet_mesh.rings = 24
	circlet_mesh.ring_segments = 10
	circlet.mesh = circlet_mesh
	circlet.position = Vector3(0.0, 2.31, -0.02)
	circlet.rotation.x = 0.18
	circlet.material_override = _bright_gold_mat
	visual_pivot.add_child(circlet)

	# 5. Dual concentric glowing halo rings behind head (+Z)
	var halo_outer: MeshInstance3D = MeshInstance3D.new()
	halo_outer.name = "HaloOuter"
	var outer_torus: TorusMesh = TorusMesh.new()
	outer_torus.inner_radius = 0.39
	outer_torus.outer_radius = 0.43
	outer_torus.rings = 32
	outer_torus.ring_segments = 10
	halo_outer.mesh = outer_torus
	halo_outer.position = Vector3(0.0, 2.30, 0.26)
	halo_outer.rotation.x = PI * 0.5
	halo_outer.material_override = _bright_gold_mat
	halo_outer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual_pivot.add_child(halo_outer)

	var halo_inner: MeshInstance3D = MeshInstance3D.new()
	halo_inner.name = "HaloInner"
	var inner_torus: TorusMesh = TorusMesh.new()
	inner_torus.inner_radius = 0.25
	inner_torus.outer_radius = 0.28
	inner_torus.rings = 28
	inner_torus.ring_segments = 10
	halo_inner.mesh = inner_torus
	halo_inner.position = Vector3(0.0, 2.30, 0.24)
	halo_inner.rotation.x = PI * 0.5
	halo_inner.material_override = _gold_mat
	halo_inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual_pivot.add_child(halo_inner)

	# 6. Signature floating prop in front of the Chronicler/Keeper (-Z)
	var prop_pivot: Node3D = Node3D.new()
	prop_pivot.name = "FloatingPropPivot"
	prop_pivot.position = Vector3(0.0, 1.56, -0.78)
	visual_pivot.add_child(prop_pivot)

	_build_chronicler_prop(prop_pivot, prop_kind, accent_glow)

	# 7. Warm serene presence light
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "ChroniclerLight"
	light.position = Vector3(0.0, 2.0, -0.35)
	light.light_color = accent_glow.lerp(Color("#FFF2D6"), 0.55)
	light.light_energy = 0.85
	light.omni_range = 8.2
	light.omni_attenuation = 1.4
	light.shadow_enabled = false
	visual_pivot.add_child(light)

	var entry: Dictionary = {
		"id": npc_id,
		"name": display_name,
		"kind": "chronicler",
		"dialogue_seq": dialogue_seq,
		"root": root,
		"visual_pivot": visual_pivot,
		"home_pos": home_pos,
		"default_yaw": default_yaw,
		"current_yaw": default_yaw,
		"orbit_radius": 0.0,
		"orbit_speed": 0.0,
		"bob_speed": 1.15,
		"bob_amp": 0.08,
		"phase": phase,
		"light": light,
		"base_light_color": light.light_color,
		"base_light_energy": 0.85,
		"robe_mat": robe_mat,
		"halo_outer": halo_outer,
		"halo_inner": halo_inner,
		"prop_pivot": prop_pivot,
		"prop_base_y": prop_pivot.position.y,
		"hop_progress": 0.0,
		"hop_active": false,
		"pulse_level": 0.0,
	}
	_npcs.append(entry)
	_npc_by_id[npc_id] = entry


func _create_robe_material(robe_col: Color, accent_glow: Color) -> Material:
	if _mentor_shader != null:
		var smat: ShaderMaterial = ShaderMaterial.new()
		smat.shader = _mentor_shader
		smat.set_shader_parameter("body_color", robe_col)
		smat.set_shader_parameter("rim_color", accent_glow.lerp(Color("#FFF6E6"), 0.5))
		smat.set_shader_parameter("rim_highlight_color", Color("#FFF9EE"))
		smat.set_shader_parameter("base_opacity", 1.0)
		smat.set_shader_parameter("fresnel_power", 2.5)
		smat.set_shader_parameter("emission_strength", 0.20)
		smat.set_shader_parameter("shimmer_speed", 0.55)
		smat.set_shader_parameter("stardust_intensity", 0.16)
		return smat

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = robe_col
	mat.roughness = 0.42
	mat.emission_enabled = true
	mat.emission = accent_glow
	mat.emission_energy_multiplier = 0.18
	return mat


func _build_chronicler_prop(parent: Node3D, prop_kind: String, accent_glow: Color) -> void:
	if prop_kind == "scrolls":
		# Floating open golden chronicle book + 2 orbiting luminous parchment pages
		var left_page: MeshInstance3D = MeshInstance3D.new()
		var page_mesh: BoxMesh = BoxMesh.new()
		page_mesh.size = Vector3(0.28, 0.02, 0.36)
		left_page.mesh = page_mesh
		left_page.position = Vector3(-0.13, 0.0, 0.0)
		left_page.rotation.z = 0.24
		left_page.material_override = _parchment_mat
		parent.add_child(left_page)

		var right_page: MeshInstance3D = MeshInstance3D.new()
		right_page.mesh = page_mesh
		right_page.position = Vector3(0.13, 0.0, 0.0)
		right_page.rotation.z = -0.24
		right_page.material_override = _parchment_mat
		parent.add_child(right_page)

		var spine: MeshInstance3D = MeshInstance3D.new()
		var spine_mesh: BoxMesh = BoxMesh.new()
		spine_mesh.size = Vector3(0.05, 0.035, 0.38)
		spine.mesh = spine_mesh
		spine.position = Vector3(0.0, -0.02, 0.0)
		spine.material_override = _gold_mat
		parent.add_child(spine)

		for idx: int in range(2):
			var loose_page: MeshInstance3D = MeshInstance3D.new()
			var lp_mesh: QuadMesh = QuadMesh.new()
			lp_mesh.size = Vector2(0.18, 0.24)
			loose_page.mesh = lp_mesh
			var angle: float = float(idx) * PI
			loose_page.position = Vector3(cos(angle) * 0.48, 0.22 + float(idx) * 0.14, sin(angle) * 0.36)
			loose_page.rotation = Vector3(-0.22, angle + 0.5, 0.15)
			loose_page.material_override = _parchment_mat
			loose_page.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(loose_page)

	elif prop_kind == "lantern":
		# Floating luminous Celestial Lotus Lantern
		var core_mat: StandardMaterial3D = StandardMaterial3D.new()
		core_mat.albedo_color = accent_glow.lerp(Color("#FFF6DC"), 0.5)
		core_mat.roughness = 0.14
		core_mat.emission_enabled = true
		core_mat.emission = accent_glow.lerp(Color("#FFE8B0"), 0.4)
		core_mat.emission_energy_multiplier = 1.05

		var core: MeshInstance3D = MeshInstance3D.new()
		var core_mesh: SphereMesh = SphereMesh.new()
		core_mesh.radius = 0.14
		core_mesh.height = 0.28
		core.mesh = core_mesh
		core.material_override = core_mat
		core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(core)

		var ring: MeshInstance3D = MeshInstance3D.new()
		var ring_mesh: TorusMesh = TorusMesh.new()
		ring_mesh.inner_radius = 0.21
		ring_mesh.outer_radius = 0.24
		ring.mesh = ring_mesh
		ring.material_override = _bright_gold_mat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(ring)

		for petal_i: int in range(5):
			var petal: MeshInstance3D = MeshInstance3D.new()
			var p_mesh: SphereMesh = SphereMesh.new()
			p_mesh.radius = 0.08
			p_mesh.height = 0.16
			petal.mesh = p_mesh
			var a: float = (float(petal_i) / 5.0) * TAU
			petal.position = Vector3(cos(a) * 0.16, -0.08, sin(a) * 0.16)
			petal.scale = Vector3(0.85, 0.42, 1.35)
			petal.rotation.y = -a
			petal.material_override = _lotus_pink_mat
			petal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(petal)

	else:
		# Floating Mini Celestial Astrolabe / Horizon Ring
		var orb_mat: StandardMaterial3D = StandardMaterial3D.new()
		orb_mat.albedo_color = Color("#E8F6FF")
		orb_mat.roughness = 0.10
		orb_mat.emission_enabled = true
		orb_mat.emission = accent_glow
		orb_mat.emission_energy_multiplier = 1.15

		var orb: MeshInstance3D = MeshInstance3D.new()
		var orb_mesh: SphereMesh = SphereMesh.new()
		orb_mesh.radius = 0.11
		orb_mesh.height = 0.22
		orb.mesh = orb_mesh
		orb.material_override = orb_mat
		orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(orb)

		var ring_a: MeshInstance3D = MeshInstance3D.new()
		var ra_mesh: TorusMesh = TorusMesh.new()
		ra_mesh.inner_radius = 0.22
		ra_mesh.outer_radius = 0.245
		ring_a.mesh = ra_mesh
		ring_a.rotation = Vector3(0.65, 0.2, 0.0)
		ring_a.material_override = _bright_gold_mat
		ring_a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(ring_a)

		var ring_b: MeshInstance3D = MeshInstance3D.new()
		var rb_mesh: TorusMesh = TorusMesh.new()
		rb_mesh.inner_radius = 0.30
		rb_mesh.outer_radius = 0.325
		ring_b.mesh = rb_mesh
		ring_b.rotation = Vector3(-0.45, 0.0, 0.72)
		ring_b.material_override = _gold_mat
		ring_b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(ring_b)


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

		# 1. Gentle organic XZ drift / playful orbit
		var drift_x: float = 0.0
		var drift_z: float = 0.0
		if orbit_radius > 0.001:
			var angle: float = _anim_time * orbit_speed + phase
			drift_x = cos(angle) * orbit_radius
			drift_z = sin(angle * 0.85) * orbit_radius * 0.82

		# 2. Excited hop animation (from Soul Call [Q] or greeting interaction)
		var hop_y: float = 0.0
		var hop_spin: float = 0.0
		if bool(entry["hop_active"]):
			var hop_speed: float = 1.65 if is_spirit else 1.25
			var progress: float = float(entry["hop_progress"]) + delta * hop_speed
			if progress >= 1.0:
				entry["hop_progress"] = 0.0
				entry["hop_active"] = false
			else:
				entry["hop_progress"] = progress
				var arc: float = sin(progress * PI)
				hop_y = arc * (0.68 if is_spirit else 0.30)
				if is_spirit:
					hop_spin = sin(progress * PI) * 0.42

		# 3. Light pulse decay
		var pulse: float = float(entry["pulse_level"])
		if pulse > 0.001:
			pulse = maxf(0.0, pulse - delta * 0.82)
			entry["pulse_level"] = pulse

		# Apply gentle bob + hop to root position
		var bob_y: float = sin(_anim_time * bob_speed + phase) * bob_amp
		root.position = Vector3(
			home_pos.x + drift_x,
			home_pos.y + bob_y + hop_y,
			home_pos.z + drift_z
		)

		# 4. Smoothly turn to face player within 12.0m, else gently sway around default facing
		var target_yaw: float = float(entry["default_yaw"]) + sin(_anim_time * 0.52 + phase) * 0.14
		if _has_player_pos:
			var to_player: Vector3 = _player_pos - root.global_position
			var dist_sq: float = to_player.length_squared()
			if dist_sq <= FACE_PLAYER_RANGE * FACE_PLAYER_RANGE and dist_sq > 0.04:
				target_yaw = atan2(-to_player.x, -to_player.z)

		var current_yaw: float = lerp_angle(float(entry["current_yaw"]), target_yaw, yaw_blend)
		entry["current_yaw"] = current_yaw
		root.rotation.y = current_yaw + hop_spin

		# 5. Subtle organic sway & archetype-specific animations
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
					smat.set_shader_parameter("energy_flare", pulse * 1.45)

			var fallback_mat: StandardMaterial3D = entry["fallback_mat"] as StandardMaterial3D
			if fallback_mat != null:
				fallback_mat.emission_energy_multiplier = 0.55 + pulse * 1.15
		else:
			visual_pivot.rotation.z = sin(_anim_time * 0.72 + phase) * 0.022
			var halo_outer: Node3D = entry["halo_outer"] as Node3D
			var halo_inner: Node3D = entry["halo_inner"] as Node3D
			if halo_outer != null:
				halo_outer.rotation.y += delta * (0.28 + pulse * 1.1)
			if halo_inner != null:
				halo_inner.rotation.y -= delta * (0.42 + pulse * 1.4)

			var prop_pivot: Node3D = entry["prop_pivot"] as Node3D
			if prop_pivot != null:
				prop_pivot.position.y = float(entry["prop_base_y"]) + sin(_anim_time * 1.85 + phase) * 0.075
				prop_pivot.rotation.y += delta * (0.48 + pulse * 1.35)

			var robe_mat: Material = entry["robe_mat"] as Material
			if robe_mat is ShaderMaterial:
				var smat: ShaderMaterial = robe_mat as ShaderMaterial
				smat.set_shader_parameter("emission_strength", 0.20 + pulse * 0.55)
			elif robe_mat is StandardMaterial3D:
				var stmat: StandardMaterial3D = robe_mat as StandardMaterial3D
				stmat.emission_energy_multiplier = 0.18 + pulse * 0.55

		# 6. Warm golden-aqua light pulse on OmniLight3D
		var light: OmniLight3D = entry["light"] as OmniLight3D
		if light != null:
			var base_col: Color = entry["base_light_color"] as Color
			var base_energy: float = float(entry["base_light_energy"])
			var pulse_tint: Color = PULSE_COLOR_AQUA_GOLD if is_spirit else PULSE_COLOR_WARM_AQUA
			light.light_color = base_col.lerp(pulse_tint, clampf(pulse * 0.75, 0.0, 1.0))
			light.light_energy = base_energy + sin(_anim_time * 2.1 + phase) * 0.06 + pulse * 1.85
			light.omni_range = (6.8 if is_spirit else 8.2) + pulse * 4.2


# ---------------------------------------------------------------------------
# Public API (matching CastleInteractables3D conventions)
# ---------------------------------------------------------------------------

## Updates the cached player position so nearby NPCs gently turn to face Spark.
func update_player_position(player_pos: Vector3) -> void:
	_player_pos = player_pos
	_has_player_pos = true


## Returns the npc_id of the nearest NPC within INTERACT_RANGE (6.2m), or "" if none.
func get_nearest_npc_in_range(player_pos: Vector3) -> String:
	var best_id: String = ""
	var best_dist: float = INTERACT_RANGE

	for entry: Dictionary in _npcs:
		var root: Node3D = entry["root"] as Node3D
		if root == null:
			continue
		var dist: float = player_pos.distance_to(root.global_position)
		if dist <= best_dist:
			best_dist = dist
			best_id = str(entry["id"])

	return best_id


## Returns a localized HUD prompt for the given npc_id (e.g. "✦  [E]  Поговорить: Искра Рассвета").
func get_interaction_prompt(npc_id: String) -> String:
	if npc_id.is_empty() or not _npc_by_id.has(npc_id):
		return ""
	var entry: Dictionary = _npc_by_id[npc_id] as Dictionary
	var display_name: String = str(entry.get("name", ""))
	if display_name.is_empty():
		return ""
	return "✦  [E]  Поговорить: %s" % display_name


## Interacts with the nearest NPC within 6.2m. Triggers a warm greeting response and emits `npc_interacted`.
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


## Responds to Spark's Soul Call [Q]: all NPCs within 16.0m do a joyful excited hop + warm golden-aqua light pulse.
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
