class_name AkashaUpdrafts3D
extends Node3D

## Golden Rising Updrafts & Musical Wind Rings for the Akashic Chronicles Prologue.
## Inspired by Journey and Sky: Children of the Light — places 6 ethereal golden-aqua
## rising thermals between the ascending islands & Baroque Palace gardens, plus 12
## musical antique-gold wind rings arranged along two scenic aerial arcs from the
## Starting Plaza up to the Baroque Palace Grand Staircase.

# ---------------------------------------------------------------------------
# Updraft Constants
# ---------------------------------------------------------------------------

const UPDRAFT_RADIUS: float = 5.5
const UPDRAFT_HEIGHT: float = 24.0
const UPDRAFT_TARGET_LIFT: float = 11.5
const UPDRAFT_LIFT_RESPONSE: float = 6.2
const UPDRAFT_ENERGY_RATE: float = 1.15
const UPDRAFT_AUDIO_COOLDOWN: float = 1.8

const MOTES_PER_UPDRAFT: int = 14

const UPDRAFT_POSITIONS: Array[Vector3] = [
	# 2 flanking the climb from Start Plaza toward the first twin islands
	Vector3(-18.0, 1.5, -55.0),
	Vector3(18.0, 1.5, -55.0),
	# 2 lifting smoothly from the central island toward the upper twin islands
	Vector3(-22.0, 4.5, -140.0),
	Vector3(22.0, 4.5, -140.0),
	# 2 flanking the Baroque Palace gardens, lifting to Palace roof/terrace views
	Vector3(-38.0, 0.5, -238.0),
	Vector3(38.0, 0.5, -238.0),
]

# ---------------------------------------------------------------------------
# Musical Wind Ring Constants
# ---------------------------------------------------------------------------

const RING_OUTER_RADIUS: float = 3.4
const RING_INNER_RADIUS: float = 3.12
const RING_TRIGGER_RADIUS: float = 3.8
const RING_COOLDOWN: float = 2.5
const RING_FORWARD_IMPULSE: float = 11.0
const RING_UPWARD_LIFT: float = 2.2
const RING_IMPULSE_DURATION: float = 0.24
const RING_ENERGY_RECHARGE: float = 0.35
const RING_MAX_SPEED: float = 32.0
const RING_PULSE_DECAY_RATE: float = 1.25

const PALACE_STAIR_TARGET: Vector3 = Vector3(0.0, 11.5, -248.0)

# Two scenic aerial arcs (6 left-center, 6 right-center) climbing from Y=6 to Y=16
# along Z=-28 to Z=-218 toward the Baroque Palace Grand Staircase.
const RING_POSITIONS: Array[Vector3] = [
	# Arc A — Left-Center (indices 0..5)
	Vector3(-9.5, 6.0, -28.0),
	Vector3(-21.0, 8.2, -66.0),
	Vector3(-12.0, 10.5, -104.0),
	Vector3(-23.5, 12.6, -144.0),
	Vector3(-21.0, 14.5, -184.0),
	Vector3(-9.0, 16.0, -218.0),
	# Arc B — Right-Center (indices 6..11)
	Vector3(9.5, 6.0, -28.0),
	Vector3(21.0, 8.2, -66.0),
	Vector3(12.0, 10.5, -104.0),
	Vector3(23.5, 12.6, -144.0),
	Vector3(21.0, 14.5, -184.0),
	Vector3(9.0, 16.0, -218.0),
]

# ---------------------------------------------------------------------------
# Runtime References & State
# ---------------------------------------------------------------------------

var _player: Node3D = null
var _audio: Node = null
var _is_built: bool = false
var _elapsed_time: float = 0.0
var _discovery_retry_timer: float = 0.0

# Updraft runtime arrays
var _updraft_ribbon_nodes: Array[MeshInstance3D] = []
var _updraft_base_rings: Array[MeshInstance3D] = []
var _updraft_cooldowns: PackedFloat32Array = PackedFloat32Array()

# Shared MultiMesh for rising golden-aqua motes across all 6 updrafts
var _motes_multimesh_inst: MultiMeshInstance3D = null
var _motes_multimesh: MultiMesh = null
var _mote_updraft_idx: PackedInt32Array = PackedInt32Array()
var _mote_phases: PackedFloat32Array = PackedFloat32Array()
var _mote_speeds: PackedFloat32Array = PackedFloat32Array()
var _mote_radii: PackedFloat32Array = PackedFloat32Array()
var _mote_angle_offsets: PackedFloat32Array = PackedFloat32Array()
var _mote_base_scales: PackedFloat32Array = PackedFloat32Array()

# Wind ring runtime arrays
var _ring_roots: Array[Node3D] = []
var _ring_shimmer_nodes: Array[MeshInstance3D] = []
var _ring_outer_mats: Array[StandardMaterial3D] = []
var _ring_shimmer_mats: Array[ShaderMaterial] = []
var _ring_forwards: Array[Vector3] = []
var _ring_cooldowns: PackedFloat32Array = PackedFloat32Array()
var _ring_pulse_values: PackedFloat32Array = PackedFloat32Array()

# Smooth non-snapping ring velocity impulse state
var _ring_impulse_vec: Vector3 = Vector3.ZERO
var _ring_impulse_timer: float = 0.0


## Optional explicit wiring from world_3d.gd (also auto-discovers in _ready()).
func setup(player_node: Node3D, audio_node: Node = null) -> void:
	_player = player_node
	if audio_node != null:
		_audio = audio_node
	elif is_inside_tree() and _audio == null:
		_discover_audio()


func _ready() -> void:
	if not _is_built:
		_build_updrafts()
		_build_updraft_motes()
		_build_wind_rings()
		_is_built = true
	_discover_references()
	set_process(true)
	set_physics_process(true)


func _process(delta: float) -> void:
	_elapsed_time += delta
	_animate_updrafts(delta)
	_animate_updraft_motes()
	_animate_wind_rings(delta)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_discovery_retry_timer -= delta
		if _discovery_retry_timer <= 0.0:
			_discovery_retry_timer = 1.0
			_discover_references()
		return

	if _audio == null or not is_instance_valid(_audio):
		_discover_audio()

	# Tick cooldowns regardless of input state
	for i: int in range(_updraft_cooldowns.size()):
		if _updraft_cooldowns[i] > 0.0:
			_updraft_cooldowns[i] = maxf(0.0, _updraft_cooldowns[i] - delta)

	for i: int in range(_ring_cooldowns.size()):
		if _ring_cooldowns[i] > 0.0:
			_ring_cooldowns[i] = maxf(0.0, _ring_cooldowns[i] - delta)

	# Respect player cutscene / menu lock
	var ctrl_enabled: Variant = _player.get("input_enabled")
	if ctrl_enabled is bool and not (ctrl_enabled as bool):
		_ring_impulse_timer = 0.0
		return

	_process_updraft_gameplay(delta)
	_process_wind_ring_gameplay(delta)
	_apply_smooth_ring_impulse(delta)


# ---------------------------------------------------------------------------
# Auto-Discovery
# ---------------------------------------------------------------------------

func _discover_references() -> void:
	var parent_node: Node = get_parent()
	if _player == null or not is_instance_valid(_player):
		if parent_node != null:
			var sibling_player: Node = parent_node.get_node_or_null("Player3D")
			if sibling_player is Node3D:
				_player = sibling_player as Node3D
		if _player == null and get_tree() != null:
			var grouped_player: Node = get_tree().get_first_node_in_group("player")
			if grouped_player is Node3D:
				_player = grouped_player as Node3D
		if _player == null and get_tree() != null and get_tree().current_scene != null:
			var found_player: Node = get_tree().current_scene.find_child("Player3D", true, false)
			if found_player is Node3D:
				_player = found_player as Node3D

	if _audio == null or not is_instance_valid(_audio):
		_discover_audio()


func _discover_audio() -> void:
	var parent_node: Node = get_parent()
	if parent_node != null:
		var sibling_audio: Node = parent_node.get_node_or_null("AkashaAudioManager")
		if sibling_audio != null:
			_audio = sibling_audio
			return
	if get_tree() != null and get_tree().current_scene != null:
		var found_audio: Node = get_tree().current_scene.find_child("AkashaAudioManager", true, false)
		if found_audio != null:
			_audio = found_audio


# ---------------------------------------------------------------------------
# 1. Golden Rising Updrafts — Procedural Visuals
# ---------------------------------------------------------------------------

func _build_updrafts() -> void:
	var updrafts_root: Node3D = Node3D.new()
	updrafts_root.name = "GoldenUpdrafts"
	add_child(updrafts_root)

	var ribbon_mesh: ArrayMesh = _create_spiral_ribbon_mesh()
	var ribbon_mat: ShaderMaterial = _create_updraft_ribbon_material()

	var base_ring_mesh: TorusMesh = TorusMesh.new()
	base_ring_mesh.outer_radius = 3.2
	base_ring_mesh.inner_radius = 2.85
	base_ring_mesh.rings = 28
	base_ring_mesh.ring_segments = 8

	var base_ring_mat: StandardMaterial3D = StandardMaterial3D.new()
	base_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	base_ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	base_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	base_ring_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	base_ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	base_ring_mat.albedo_color = Color(0.96, 0.88, 0.62, 0.16)

	var updraft_count: int = UPDRAFT_POSITIONS.size()
	_updraft_cooldowns.resize(updraft_count)

	for i: int in range(updraft_count):
		_updraft_cooldowns[i] = 0.0
		var pos: Vector3 = UPDRAFT_POSITIONS[i]

		var column_root: Node3D = Node3D.new()
		column_root.name = "Updraft_%02d" % i
		column_root.position = pos
		updrafts_root.add_child(column_root)

		var ribbon_inst: MeshInstance3D = MeshInstance3D.new()
		ribbon_inst.name = "SpiralRibbons"
		ribbon_inst.mesh = ribbon_mesh
		ribbon_inst.material_override = ribbon_mat
		ribbon_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ribbon_inst.rotation.y = float(i) * 1.047
		column_root.add_child(ribbon_inst)
		_updraft_ribbon_nodes.append(ribbon_inst)

		var base_inst: MeshInstance3D = MeshInstance3D.new()
		base_inst.name = "BaseEddyHalo"
		base_inst.mesh = base_ring_mesh
		base_inst.material_override = base_ring_mat
		base_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		base_inst.position = Vector3(0.0, 0.35, 0.0)
		base_inst.scale = Vector3(1.0, 0.25, 1.0)
		column_root.add_child(base_inst)
		_updraft_base_rings.append(base_inst)


func _create_spiral_ribbon_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var strand_count: int = 3
	var vertical_steps: int = 34
	var turns: float = 2.35
	var ribbon_half_width: float = 0.42

	for s: int in range(strand_count):
		var strand_angle_offset: float = (float(s) / float(strand_count)) * TAU
		var radius_scale: float = 0.88 + float(s) * 0.11

		for step: int in range(vertical_steps):
			var t0: float = float(step) / float(vertical_steps)
			var t1: float = float(step + 1) / float(vertical_steps)

			var y0: float = t0 * UPDRAFT_HEIGHT
			var y1: float = t1 * UPDRAFT_HEIGHT

			# Gentle hourglass-to-flared wind profile
			var r0: float = lerpf(1.55, 3.35, pow(t0, 0.82)) * radius_scale
			var r1: float = lerpf(1.55, 3.35, pow(t1, 0.82)) * radius_scale

			var a0: float = strand_angle_offset + t0 * turns * TAU
			var a1: float = strand_angle_offset + t1 * turns * TAU

			var c0: Vector3 = Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var c1: Vector3 = Vector3(cos(a1) * r1, y1, sin(a1) * r1)

			# Ribbon width oriented slightly tilted outward so it reads gracefully from every angle
			var rad0: Vector3 = Vector3(cos(a0), 0.0, sin(a0))
			var rad1: Vector3 = Vector3(cos(a1), 0.0, sin(a1))
			var width_dir0: Vector3 = (Vector3.UP * 0.78 + rad0 * 0.28).normalized() * ribbon_half_width
			var width_dir1: Vector3 = (Vector3.UP * 0.78 + rad1 * 0.28).normalized() * ribbon_half_width

			var v00: Vector3 = c0 - width_dir0
			var v01: Vector3 = c0 + width_dir0
			var v10: Vector3 = c1 - width_dir1
			var v11: Vector3 = c1 + width_dir1

			var n0: Vector3 = rad0
			var n1: Vector3 = rad1

			# Triangle 1
			st.set_normal(n0)
			st.set_uv(Vector2(0.0, t0))
			st.add_vertex(v00)

			st.set_normal(n0)
			st.set_uv(Vector2(1.0, t0))
			st.add_vertex(v01)

			st.set_normal(n1)
			st.set_uv(Vector2(1.0, t1))
			st.add_vertex(v11)

			# Triangle 2
			st.set_normal(n0)
			st.set_uv(Vector2(0.0, t0))
			st.add_vertex(v00)

			st.set_normal(n1)
			st.set_uv(Vector2(1.0, t1))
			st.add_vertex(v11)

			st.set_normal(n1)
			st.set_uv(Vector2(0.0, t1))
			st.add_vertex(v10)

	return st.commit()


func _create_updraft_ribbon_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 gold_color : source_color = vec4(1.0, 0.86, 0.50, 1.0);
uniform vec4 aqua_color : source_color = vec4(0.56, 0.90, 1.0, 1.0);
uniform float base_opacity = 0.20;
uniform float scroll_speed = 1.45;

void fragment() {
	float edge_fade = sin(clamp(UV.x, 0.0, 1.0) * 3.14159265);
	edge_fade = edge_fade * edge_fade;

	float bottom_fade = smoothstep(0.0, 0.16, UV.y);
	float top_fade = 1.0 - smoothstep(0.68, 1.0, UV.y);
	float height_fade = bottom_fade * top_fade;

	float wave_a = 0.55 + 0.45 * sin(UV.y * 12.0 - TIME * scroll_speed * 2.4);
	float wave_b = 0.72 + 0.28 * sin(UV.y * 22.0 - TIME * scroll_speed * 3.6 + UV.x * 4.0);
	float shimmer = wave_a * wave_b;

	vec3 tint = mix(gold_color.rgb, aqua_color.rgb, clamp(UV.y * 0.78 + 0.12 * sin(TIME * 0.9 + UV.y * 5.0), 0.0, 1.0));
	ALBEDO = tint * (0.95 + 0.35 * shimmer);
	ALPHA = clamp(edge_fade * height_fade * shimmer * base_opacity, 0.0, 0.45);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("gold_color", Color(1.0, 0.86, 0.50, 1.0))
	mat.set_shader_parameter("aqua_color", Color(0.56, 0.90, 1.0, 1.0))
	mat.set_shader_parameter("base_opacity", 0.20)
	mat.set_shader_parameter("scroll_speed", 1.45)
	return mat


func _build_updraft_motes() -> void:
	var updraft_count: int = UPDRAFT_POSITIONS.size()
	var total_motes: int = updraft_count * MOTES_PER_UPDRAFT

	var mote_mesh: SphereMesh = SphereMesh.new()
	mote_mesh.radius = 0.11
	mote_mesh.height = 0.34
	mote_mesh.radial_segments = 6
	mote_mesh.rings = 3

	var mote_mat: StandardMaterial3D = StandardMaterial3D.new()
	mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mote_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mote_mat.vertex_color_use_as_albedo = true
	mote_mat.albedo_color = Color(1.0, 0.96, 0.86, 0.72)

	mote_mesh.material = mote_mat

	_motes_multimesh = MultiMesh.new()
	_motes_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_motes_multimesh.use_colors = true
	_motes_multimesh.mesh = mote_mesh
	_motes_multimesh.instance_count = total_motes

	_motes_multimesh_inst = MultiMeshInstance3D.new()
	_motes_multimesh_inst.name = "UpdraftRisingMotes"
	_motes_multimesh_inst.multimesh = _motes_multimesh
	_motes_multimesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_motes_multimesh_inst.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_motes_multimesh_inst.custom_aabb = AABB(Vector3(-85.0, -10.0, -300.0), Vector3(170.0, 65.0, 310.0))
	add_child(_motes_multimesh_inst)

	_mote_updraft_idx.resize(total_motes)
	_mote_phases.resize(total_motes)
	_mote_speeds.resize(total_motes)
	_mote_radii.resize(total_motes)
	_mote_angle_offsets.resize(total_motes)
	_mote_base_scales.resize(total_motes)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260719

	var gold_mote: Color = Color(1.0, 0.88, 0.56, 0.85)
	var aqua_mote: Color = Color(0.62, 0.93, 1.0, 0.80)

	var idx: int = 0
	for u: int in range(updraft_count):
		for _m: int in range(MOTES_PER_UPDRAFT):
			_mote_updraft_idx[idx] = u
			_mote_phases[idx] = rng.randf()
			_mote_speeds[idx] = rng.randf_range(0.11, 0.20)
			_mote_radii[idx] = rng.randf_range(0.85, 3.6)
			_mote_angle_offsets[idx] = rng.randf_range(0.0, TAU)
			_mote_base_scales[idx] = rng.randf_range(0.70, 1.35)

			var tint_blend: float = rng.randf()
			_motes_multimesh.set_instance_color(idx, gold_mote.lerp(aqua_mote, tint_blend))
			idx += 1

	_animate_updraft_motes()


# ---------------------------------------------------------------------------
# 2. Musical Golden Wind Rings — Procedural Visuals
# ---------------------------------------------------------------------------

func _build_wind_rings() -> void:
	var rings_root: Node3D = Node3D.new()
	rings_root.name = "MusicalWindRings"
	add_child(rings_root)

	var outer_mesh: TorusMesh = TorusMesh.new()
	outer_mesh.outer_radius = RING_OUTER_RADIUS
	outer_mesh.inner_radius = RING_INNER_RADIUS
	outer_mesh.rings = 32
	outer_mesh.ring_segments = 12

	var shimmer_mesh: TorusMesh = TorusMesh.new()
	shimmer_mesh.outer_radius = RING_INNER_RADIUS - 0.06
	shimmer_mesh.inner_radius = RING_INNER_RADIUS - 0.50
	shimmer_mesh.rings = 28
	shimmer_mesh.ring_segments = 8

	var shimmer_shader: Shader = _create_ring_shimmer_shader()

	var ring_count: int = RING_POSITIONS.size()
	_ring_cooldowns.resize(ring_count)
	_ring_pulse_values.resize(ring_count)

	for i: int in range(ring_count):
		_ring_cooldowns[i] = 0.0
		_ring_pulse_values[i] = 0.0

		var pos: Vector3 = RING_POSITIONS[i]
		var forward_dir: Vector3 = _compute_ring_forward(i)
		_ring_forwards.append(forward_dir)

		var ring_node: Node3D = Node3D.new()
		ring_node.name = "WindRing_%02d" % i
		# Orient ring in local space so its local -Z faces along forward_dir
		ring_node.transform = Transform3D(Basis.looking_at(forward_dir, Vector3.UP), pos)
		rings_root.add_child(ring_node)
		_ring_roots.append(ring_node)

		# Antique-gold sculpted outer torus (per-ring material for independent burst glow)
		var outer_mat: StandardMaterial3D = StandardMaterial3D.new()
		outer_mat.albedo_color = Color("#E8C468")
		outer_mat.metallic = 0.80
		outer_mat.roughness = 0.28
		outer_mat.emission_enabled = true
		outer_mat.emission = Color("#FFD97D")
		outer_mat.emission_energy_multiplier = 0.52

		var outer_inst: MeshInstance3D = MeshInstance3D.new()
		outer_inst.name = "GoldRingMesh"
		outer_inst.mesh = outer_mesh
		outer_inst.material_override = outer_mat
		outer_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# TorusMesh opens along Y by default; rotate 90 deg around X so opening faces +-Z
		outer_inst.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		ring_node.add_child(outer_inst)
		_ring_outer_mats.append(outer_mat)

		# Delicate inner translucent wind shimmer ring that gently rotates and breathes
		var shimmer_mat: ShaderMaterial = ShaderMaterial.new()
		shimmer_mat.shader = shimmer_shader
		shimmer_mat.set_shader_parameter("gold_tint", Color(1.0, 0.90, 0.56, 1.0))
		shimmer_mat.set_shader_parameter("aqua_tint", Color(0.62, 0.92, 1.0, 1.0))
		shimmer_mat.set_shader_parameter("pulse_boost", 0.0)
		shimmer_mat.set_shader_parameter("phase_offset", float(i) * 0.78)

		var shimmer_pivot: Node3D = Node3D.new()
		shimmer_pivot.name = "WindShimmerPivot"
		shimmer_pivot.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		ring_node.add_child(shimmer_pivot)

		var shimmer_inst: MeshInstance3D = MeshInstance3D.new()
		shimmer_inst.name = "WindShimmerRing"
		shimmer_inst.mesh = shimmer_mesh
		shimmer_inst.material_override = shimmer_mat
		shimmer_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shimmer_inst.scale = Vector3(1.0, 0.34, 1.0)
		shimmer_pivot.add_child(shimmer_inst)

		_ring_shimmer_nodes.append(shimmer_inst)
		_ring_shimmer_mats.append(shimmer_mat)


func _compute_ring_forward(ring_index: int) -> Vector3:
	var pos: Vector3 = RING_POSITIONS[ring_index]
	var next_target: Vector3 = PALACE_STAIR_TARGET
	# Arc A is 0..5, Arc B is 6..11
	if ring_index < 5 or (ring_index >= 6 and ring_index < 11):
		next_target = RING_POSITIONS[ring_index + 1]
	var dir: Vector3 = next_target - pos
	if dir.length_squared() < 0.0001:
		return Vector3.FORWARD
	return dir.normalized()


func _create_ring_shimmer_shader() -> Shader:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 gold_tint : source_color = vec4(1.0, 0.90, 0.56, 1.0);
uniform vec4 aqua_tint : source_color = vec4(0.62, 0.92, 1.0, 1.0);
uniform float pulse_boost = 0.0;
uniform float phase_offset = 0.0;

void fragment() {
	float swirl_a = 0.55 + 0.45 * sin(UV.x * 18.84955 - TIME * 2.8 + phase_offset);
	float swirl_b = 0.65 + 0.35 * sin(UV.x * 31.4159 + TIME * 1.9 - phase_offset);
	float breathe = 0.80 + 0.20 * sin(TIME * 2.1 + phase_offset);
	float band = sin(clamp(UV.y, 0.0, 1.0) * 3.14159265);

	float mix_t = clamp(0.35 + 0.35 * sin(UV.x * 6.28318 - TIME * 1.1 + phase_offset) - pulse_boost * 0.45, 0.0, 1.0);
	vec3 col = mix(gold_tint.rgb, aqua_tint.rgb, mix_t);
	float energy = (0.75 + 0.35 * swirl_a * swirl_b) * breathe + pulse_boost * 1.65;

	ALBEDO = col * energy;
	ALPHA = clamp((0.18 + 0.14 * swirl_a * band + pulse_boost * 0.48) * breathe, 0.0, 0.82);
}
"""
	return shader


# ---------------------------------------------------------------------------
# Visual Animations (_process)
# ---------------------------------------------------------------------------

func _animate_updrafts(delta: float) -> void:
	for i: int in range(_updraft_ribbon_nodes.size()):
		var ribbon: MeshInstance3D = _updraft_ribbon_nodes[i]
		var spin_dir: float = 1.0 if (i % 2 == 0) else -1.0
		ribbon.rotate_y(delta * 0.52 * spin_dir)

	for i: int in range(_updraft_base_rings.size()):
		var base_ring: MeshInstance3D = _updraft_base_rings[i]
		var breath: float = 1.0 + sin(_elapsed_time * 1.45 + float(i) * 1.1) * 0.06
		base_ring.scale = Vector3(breath, 0.25, breath)
		base_ring.rotate_y(delta * 0.35)


func _animate_updraft_motes() -> void:
	if _motes_multimesh == null:
		return

	var total_motes: int = _motes_multimesh.instance_count
	for idx: int in range(total_motes):
		var u_idx: int = _mote_updraft_idx[idx]
		var base_pos: Vector3 = UPDRAFT_POSITIONS[u_idx]
		var t: float = fposmod(_mote_phases[idx] + _elapsed_time * _mote_speeds[idx], 1.0)

		var height_y: float = t * UPDRAFT_HEIGHT
		var flare: float = lerpf(0.62, 1.18, t)
		var r: float = _mote_radii[idx] * flare
		var spin_sign: float = 1.0 if (u_idx % 2 == 0) else -1.0
		var angle: float = _mote_angle_offsets[idx] + t * 5.2 * spin_sign + _elapsed_time * 0.45 * spin_sign

		var mote_pos: Vector3 = Vector3(
			base_pos.x + cos(angle) * r,
			base_pos.y + height_y,
			base_pos.z + sin(angle) * r
		)

		# Smooth scale fade-in at bottom and fade-out at top
		var fade_in: float = clampf(t / 0.14, 0.0, 1.0)
		var fade_out: float = clampf((1.0 - t) / 0.22, 0.0, 1.0)
		var s: float = _mote_base_scales[idx] * fade_in * fade_out

		var mote_xform_basis: Basis = Basis.from_scale(Vector3(s, s, s))
		_motes_multimesh.set_instance_transform(idx, Transform3D(mote_xform_basis, mote_pos))


func _animate_wind_rings(delta: float) -> void:
	for i: int in range(_ring_roots.size()):
		var pulse: float = _ring_pulse_values[i]
		if pulse > 0.0:
			pulse = maxf(0.0, pulse - delta * RING_PULSE_DECAY_RATE)
			_ring_pulse_values[i] = pulse

		var phase: float = float(i) * 0.65
		var idle_breath: float = 1.0 + sin(_elapsed_time * 1.9 + phase) * 0.022
		# Smooth ease-out burst scale on trigger
		var burst_curve: float = sin(pulse * PI) if pulse > 0.0 else 0.0
		var target_scale: float = idle_breath + burst_curve * 0.18
		_ring_roots[i].scale = Vector3(target_scale, target_scale, target_scale)

		# Gentle rotation of the inner wind shimmer ring around the torus axis (local Y)
		var shimmer: MeshInstance3D = _ring_shimmer_nodes[i]
		var spin_dir: float = 1.0 if (i % 2 == 0) else -1.0
		var spin_speed: float = 0.55 + pulse * 2.4
		shimmer.rotate_y(delta * spin_speed * spin_dir)

		# Radiant golden burst emission on the outer ring and inner shimmer
		var outer_mat: StandardMaterial3D = _ring_outer_mats[i]
		outer_mat.emission_energy_multiplier = 0.52 + pulse * 2.35

		var shimmer_mat: ShaderMaterial = _ring_shimmer_mats[i]
		shimmer_mat.set_shader_parameter("pulse_boost", pulse)


# ---------------------------------------------------------------------------
# Gameplay Physics (_physics_process)
# ---------------------------------------------------------------------------

func _process_updraft_gameplay(delta: float) -> void:
	var player_pos: Vector3 = _player.global_position
	var radius_sq: float = UPDRAFT_RADIUS * UPDRAFT_RADIUS

	for i: int in range(UPDRAFT_POSITIONS.size()):
		var base_pos: Vector3 = to_global(UPDRAFT_POSITIONS[i])
		var rel_y: float = player_pos.y - base_pos.y
		if rel_y < -1.5 or rel_y > UPDRAFT_HEIGHT:
			continue

		var dx: float = player_pos.x - base_pos.x
		var dz: float = player_pos.z - base_pos.z
		var horiz_dist_sq: float = dx * dx + dz * dz
		if horiz_dist_sq > radius_sq:
			continue

		# Soft radial and top-cap falloff so entering/exiting feels silky
		var radial_ratio: float = sqrt(horiz_dist_sq) / UPDRAFT_RADIUS
		var radial_factor: float = clampf(1.0 - maxf(0.0, radial_ratio - 0.65) / 0.35, 0.35, 1.0)
		var top_ratio: float = clampf(rel_y / UPDRAFT_HEIGHT, 0.0, 1.0)
		var top_factor: float = clampf(1.0 - maxf(0.0, top_ratio - 0.85) / 0.15, 0.25, 1.0)

		var lift_target: float = UPDRAFT_TARGET_LIFT * radial_factor * top_factor
		var lift_t: float = 1.0 - exp(-UPDRAFT_LIFT_RESPONSE * delta)

		if _player is CharacterBody3D:
			var body: CharacterBody3D = _player as CharacterBody3D
			var cur_vel: Vector3 = body.velocity
			cur_vel.y = lerpf(cur_vel.y, maxf(cur_vel.y, lift_target), lift_t)
			body.velocity = cur_vel

		if _player.has_method("recharge_wing_energy"):
			_player.call("recharge_wing_energy", UPDRAFT_ENERGY_RATE * delta)

		if _updraft_cooldowns[i] <= 0.0:
			_updraft_cooldowns[i] = UPDRAFT_AUDIO_COOLDOWN
			if _audio != null and _audio.has_method("play_updraft_whoosh"):
				_audio.call("play_updraft_whoosh")


func _process_wind_ring_gameplay(_delta: float) -> void:
	# Sample at Spark's body center (~0.9 m above feet) for natural ring fly-through
	var player_center: Vector3 = _player.global_position + Vector3(0.0, 0.9, 0.0)
	var trigger_dist_sq: float = RING_TRIGGER_RADIUS * RING_TRIGGER_RADIUS

	for i: int in range(RING_POSITIONS.size()):
		if _ring_cooldowns[i] > 0.0:
			continue

		var ring_world_pos: Vector3 = _ring_roots[i].global_position
		if player_center.distance_squared_to(ring_world_pos) <= trigger_dist_sq:
			_trigger_wind_ring(i)


func _trigger_wind_ring(ring_index: int) -> void:
	_ring_cooldowns[ring_index] = RING_COOLDOWN
	_ring_pulse_values[ring_index] = 1.0

	# Determine forward axis along the ring (allow joyful traversal in reverse too)
	var forward_axis: Vector3 = _ring_forwards[ring_index]
	if _player is CharacterBody3D:
		var body: CharacterBody3D = _player as CharacterBody3D
		if body.velocity.dot(forward_axis) < -2.5:
			forward_axis = -forward_axis

	# Queue smooth forward speed impulse (+11.0 m/s) + gentle lift (+2.2 m/s)
	_ring_impulse_vec = forward_axis * RING_FORWARD_IMPULSE + Vector3(0.0, RING_UPWARD_LIFT, 0.0)
	_ring_impulse_timer = RING_IMPULSE_DURATION

	if _player.has_method("recharge_wing_energy"):
		_player.call("recharge_wing_energy", RING_ENERGY_RECHARGE)

	if _audio != null and _audio.has_method("play_wind_ring_note"):
		_audio.call("play_wind_ring_note", ring_index)


func _apply_smooth_ring_impulse(delta: float) -> void:
	if _ring_impulse_timer <= 0.0:
		return
	if not (_player is CharacterBody3D):
		_ring_impulse_timer = 0.0
		return

	var prev_u: float = clampf(1.0 - (_ring_impulse_timer / RING_IMPULSE_DURATION), 0.0, 1.0)
	_ring_impulse_timer = maxf(0.0, _ring_impulse_timer - delta)
	var next_u: float = clampf(1.0 - (_ring_impulse_timer / RING_IMPULSE_DURATION), 0.0, 1.0)

	# Smoothstep differential guarantees the integral sums to 1.0 with zero velocity snap
	var prev_smooth: float = prev_u * prev_u * (3.0 - 2.0 * prev_u)
	var next_smooth: float = next_u * next_u * (3.0 - 2.0 * next_u)
	var frac: float = maxf(0.0, next_smooth - prev_smooth)

	var body: CharacterBody3D = _player as CharacterBody3D
	var new_vel: Vector3 = body.velocity + _ring_impulse_vec * frac
	if new_vel.length() > RING_MAX_SPEED:
		new_vel = new_vel.normalized() * RING_MAX_SPEED
	body.velocity = new_vel
