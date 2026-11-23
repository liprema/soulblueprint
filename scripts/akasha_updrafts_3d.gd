class_name AkashaUpdrafts3D
extends Node3D

## Whisper-Soft Ethereal Rising Wind Currents for the Akashic Chronicles Prologue.
## Inspired by Journey and GRIS — places 4 nearly invisible, poetic rising thermals
## in the natural air gaps between the ascending islands. Zero floating hoops or
## garish neon ribbons: only ultra-delicate translucent gossamer mist wisps
## (alpha 0.16..0.22) and a handful of faint drifting air flecks so the sky stays
## 100% pure while flight between islands feels effortlessly buoyant.

# ---------------------------------------------------------------------------
# Updraft Constants
# ---------------------------------------------------------------------------

const UPDRAFT_RADIUS: float = 6.2
const UPDRAFT_HEIGHT: float = 24.0
const UPDRAFT_TARGET_LIFT: float = 11.5
const UPDRAFT_LIFT_RESPONSE: float = 6.2
const UPDRAFT_ENERGY_RATE: float = 1.15
const UPDRAFT_AUDIO_COOLDOWN: float = 1.8

const MOTES_PER_UPDRAFT: int = 4

const UPDRAFT_POSITIONS: Array[Vector3] = [
	# 2 flanking the climb from Start Plaza toward the first twin islands
	Vector3(-18.0, 1.5, -55.0),
	Vector3(18.0, 1.5, -55.0),
	# 2 lifting smoothly from the central island toward the upper twin islands
	Vector3(-22.0, 4.5, -140.0),
	Vector3(22.0, 4.5, -140.0),
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
var _updraft_wisp_nodes: Array[MeshInstance3D] = []
var _updraft_cooldowns: PackedFloat32Array = PackedFloat32Array()

# Shared MultiMesh for a whisper-faint handful of rising gossamer air flecks (16 total)
var _motes_multimesh_inst: MultiMeshInstance3D = null
var _motes_multimesh: MultiMesh = null
var _mote_updraft_idx: PackedInt32Array = PackedInt32Array()
var _mote_phases: PackedFloat32Array = PackedFloat32Array()
var _mote_speeds: PackedFloat32Array = PackedFloat32Array()
var _mote_radii: PackedFloat32Array = PackedFloat32Array()
var _mote_angle_offsets: PackedFloat32Array = PackedFloat32Array()
var _mote_base_scales: PackedFloat32Array = PackedFloat32Array()


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
		_is_built = true
	_discover_references()
	set_process(true)
	set_physics_process(true)


func _process(delta: float) -> void:
	_elapsed_time += delta
	_animate_updrafts(delta)
	_animate_updraft_motes()


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

	# Respect player cutscene / menu lock
	var ctrl_enabled: Variant = _player.get("input_enabled")
	if ctrl_enabled is bool and not (ctrl_enabled as bool):
		return

	_process_updraft_gameplay(delta)


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
# Ethereal Rising Wind Currents — Ultra-Delicate Gossamer Mist Wisps
# ---------------------------------------------------------------------------

func _build_updrafts() -> void:
	var updrafts_root: Node3D = Node3D.new()
	updrafts_root.name = "EtherealWindCurrents"
	add_child(updrafts_root)

	var wisp_mesh: ArrayMesh = _create_gossamer_wisp_mesh()
	var wisp_mat: ShaderMaterial = _create_gossamer_wisp_material()

	var updraft_count: int = UPDRAFT_POSITIONS.size()
	_updraft_cooldowns.resize(updraft_count)

	for i: int in range(updraft_count):
		_updraft_cooldowns[i] = 0.0
		var pos: Vector3 = UPDRAFT_POSITIONS[i]

		var column_root: Node3D = Node3D.new()
		column_root.name = "WindCurrent_%02d" % i
		column_root.position = pos
		updrafts_root.add_child(column_root)

		var wisp_inst: MeshInstance3D = MeshInstance3D.new()
		wisp_inst.name = "GossamerWisps"
		wisp_inst.mesh = wisp_mesh
		wisp_inst.material_override = wisp_mat
		wisp_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wisp_inst.rotation.y = float(i) * 1.5708
		column_root.add_child(wisp_inst)
		_updraft_wisp_nodes.append(wisp_inst)


func _create_gossamer_wisp_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Only 2 slender, whisper-graceful ascending silk wisps per current
	var strand_count: int = 2
	var vertical_steps: int = 28
	var turns: float = 1.45
	var wisp_half_width: float = 0.20

	for s: int in range(strand_count):
		var strand_angle_offset: float = (float(s) / float(strand_count)) * TAU
		var radius_scale: float = 0.92 + float(s) * 0.14

		for step: int in range(vertical_steps):
			var t0: float = float(step) / float(vertical_steps)
			var t1: float = float(step + 1) / float(vertical_steps)

			var y0: float = t0 * UPDRAFT_HEIGHT
			var y1: float = t1 * UPDRAFT_HEIGHT

			# Wide, airy drift radius so it reads as natural wind rather than a tight tube
			var r0: float = lerpf(1.85, 3.65, pow(t0, 0.85)) * radius_scale
			var r1: float = lerpf(1.85, 3.65, pow(t1, 0.85)) * radius_scale

			var a0: float = strand_angle_offset + t0 * turns * TAU
			var a1: float = strand_angle_offset + t1 * turns * TAU

			var c0: Vector3 = Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var c1: Vector3 = Vector3(cos(a1) * r1, y1, sin(a1) * r1)

			var rad0: Vector3 = Vector3(cos(a0), 0.0, sin(a0))
			var rad1: Vector3 = Vector3(cos(a1), 0.0, sin(a1))
			var width_dir0: Vector3 = (Vector3.UP * 0.82 + rad0 * 0.24).normalized() * wisp_half_width
			var width_dir1: Vector3 = (Vector3.UP * 0.82 + rad1 * 0.24).normalized() * wisp_half_width

			var v00: Vector3 = c0 - width_dir0
			var v01: Vector3 = c0 + width_dir0
			var v10: Vector3 = c1 - width_dir1
			var v11: Vector3 = c1 + width_dir1

			# Triangle 1
			st.set_normal(rad0)
			st.set_uv(Vector2(0.0, t0))
			st.add_vertex(v00)

			st.set_normal(rad0)
			st.set_uv(Vector2(1.0, t0))
			st.add_vertex(v01)

			st.set_normal(rad1)
			st.set_uv(Vector2(1.0, t1))
			st.add_vertex(v11)

			# Triangle 2
			st.set_normal(rad0)
			st.set_uv(Vector2(0.0, t0))
			st.add_vertex(v00)

			st.set_normal(rad1)
			st.set_uv(Vector2(1.0, t1))
			st.add_vertex(v11)

			st.set_normal(rad1)
			st.set_uv(Vector2(0.0, t1))
			st.add_vertex(v10)

	return st.commit()


func _create_gossamer_wisp_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec4 mist_pearl : source_color = vec4(0.98, 0.97, 0.94, 1.0);
uniform vec4 mist_azure : source_color = vec4(0.86, 0.93, 1.0, 1.0);
uniform float base_opacity = 0.19;
uniform float scroll_speed = 0.85;

void fragment() {
	float edge_fade = sin(clamp(UV.x, 0.0, 1.0) * 3.14159265);
	edge_fade = edge_fade * edge_fade;

	float bottom_fade = smoothstep(0.0, 0.22, UV.y);
	float top_fade = 1.0 - smoothstep(0.62, 1.0, UV.y);
	float height_fade = bottom_fade * top_fade;

	float breath = 0.62 + 0.38 * sin(UV.y * 9.0 - TIME * scroll_speed * 2.0);
	float wisp_gap = smoothstep(0.18, 0.85, 0.5 + 0.5 * sin(UV.y * 6.5 - TIME * scroll_speed * 1.4));

	vec3 tint = mix(mist_pearl.rgb, mist_azure.rgb, clamp(UV.y * 0.85, 0.0, 1.0));
	ALBEDO = tint;
	ALPHA = clamp(edge_fade * height_fade * breath * wisp_gap * base_opacity, 0.0, 0.22);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("mist_pearl", Color(0.98, 0.97, 0.94, 1.0))
	mat.set_shader_parameter("mist_azure", Color(0.86, 0.93, 1.0, 1.0))
	mat.set_shader_parameter("base_opacity", 0.19)
	mat.set_shader_parameter("scroll_speed", 0.85)
	return mat


func _build_updraft_motes() -> void:
	var updraft_count: int = UPDRAFT_POSITIONS.size()
	var total_motes: int = updraft_count * MOTES_PER_UPDRAFT

	var mote_mesh: SphereMesh = SphereMesh.new()
	mote_mesh.radius = 0.055
	mote_mesh.height = 0.16
	mote_mesh.radial_segments = 6
	mote_mesh.rings = 3

	var mote_mat: StandardMaterial3D = StandardMaterial3D.new()
	mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mote_mat.vertex_color_use_as_albedo = true
	mote_mat.albedo_color = Color(0.98, 0.98, 1.0, 0.22)

	mote_mesh.material = mote_mat

	_motes_multimesh = MultiMesh.new()
	_motes_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_motes_multimesh.use_colors = true
	_motes_multimesh.mesh = mote_mesh
	_motes_multimesh.instance_count = total_motes

	_motes_multimesh_inst = MultiMeshInstance3D.new()
	_motes_multimesh_inst.name = "WindCurrentGossamerFlecks"
	_motes_multimesh_inst.multimesh = _motes_multimesh
	_motes_multimesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_motes_multimesh_inst.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_motes_multimesh_inst.custom_aabb = AABB(Vector3(-60.0, -10.0, -200.0), Vector3(120.0, 60.0, 210.0))
	add_child(_motes_multimesh_inst)

	_mote_updraft_idx.resize(total_motes)
	_mote_phases.resize(total_motes)
	_mote_speeds.resize(total_motes)
	_mote_radii.resize(total_motes)
	_mote_angle_offsets.resize(total_motes)
	_mote_base_scales.resize(total_motes)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260719

	var pearl_fleck: Color = Color(1.0, 0.98, 0.93, 0.22)
	var sky_fleck: Color = Color(0.88, 0.94, 1.0, 0.18)

	var idx: int = 0
	for u: int in range(updraft_count):
		for _m: int in range(MOTES_PER_UPDRAFT):
			_mote_updraft_idx[idx] = u
			_mote_phases[idx] = rng.randf()
			_mote_speeds[idx] = rng.randf_range(0.08, 0.14)
			_mote_radii[idx] = rng.randf_range(1.2, 3.8)
			_mote_angle_offsets[idx] = rng.randf_range(0.0, TAU)
			_mote_base_scales[idx] = rng.randf_range(0.75, 1.15)

			var tint_blend: float = rng.randf()
			_motes_multimesh.set_instance_color(idx, pearl_fleck.lerp(sky_fleck, tint_blend))
			idx += 1

	_animate_updraft_motes()


# ---------------------------------------------------------------------------
# Visual Animations (_process)
# ---------------------------------------------------------------------------

func _animate_updrafts(delta: float) -> void:
	for i: int in range(_updraft_wisp_nodes.size()):
		var wisp: MeshInstance3D = _updraft_wisp_nodes[i]
		var spin_dir: float = 1.0 if (i % 2 == 0) else -1.0
		wisp.rotate_y(delta * 0.24 * spin_dir)


func _animate_updraft_motes() -> void:
	if _motes_multimesh == null:
		return

	var total_motes: int = _motes_multimesh.instance_count
	for idx: int in range(total_motes):
		var u_idx: int = _mote_updraft_idx[idx]
		var base_pos: Vector3 = UPDRAFT_POSITIONS[u_idx]
		var t: float = fposmod(_mote_phases[idx] + _elapsed_time * _mote_speeds[idx], 1.0)

		var height_y: float = t * UPDRAFT_HEIGHT
		var flare: float = lerpf(0.68, 1.16, t)
		var r: float = _mote_radii[idx] * flare
		var spin_sign: float = 1.0 if (u_idx % 2 == 0) else -1.0
		var angle: float = _mote_angle_offsets[idx] + t * 3.4 * spin_sign + _elapsed_time * 0.26 * spin_sign

		var mote_pos: Vector3 = Vector3(
			base_pos.x + cos(angle) * r,
			base_pos.y + height_y,
			base_pos.z + sin(angle) * r
		)

		var fade_in: float = clampf(t / 0.18, 0.0, 1.0)
		var fade_out: float = clampf((1.0 - t) / 0.26, 0.0, 1.0)
		var s: float = _mote_base_scales[idx] * fade_in * fade_out

		var mote_xform_basis: Basis = Basis.from_scale(Vector3(s, s, s))
		_motes_multimesh.set_instance_transform(idx, Transform3D(mote_xform_basis, mote_pos))


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
