shader_type spatial;
render_mode cull_back;

// Pixar-Style Procedural Building Facade & Roof Shader (Godot 4.3+ Forward+, Apple Silicon Metal Safe)
// - 100% Apple Silicon Metal Safe: ZERO dFdx/dFdy/fwidth, ZERO CLEARCOAT, ZERO light() overrides,
//   ZERO normal perturbation, all pow() guarded with max(..., 0.0001), all smoothstep(a, b, x) strictly a < b.
// - Per-building deterministic color variation from MODEL_MATRIX[3].xyz so 700+ buildings feel alive and hand-painted.
// - Seamless 3D world-space plaster/stucco grain, subtle running-bond masonry courses on walls,
//   and overlapping terracotta/slate tile scallops on sloped roofs.
// - Soft vertical ground AO gradient near the base (v_local_y < base_ao_height) for Pixar-grade grounding & volume.

group_uniforms facade_colors;
uniform vec3 base_color : source_color = vec3(0.82, 0.36, 0.30);
uniform vec3 accent_color : source_color = vec3(0.68, 0.26, 0.22);

group_uniforms pbr_settings;
uniform float roughness_val : hint_range(0.1, 1.0) = 0.72;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.0;

group_uniforms procedural_detail;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.38;
uniform float per_building_variation : hint_range(0.0, 0.35) = 0.16;
uniform float base_ao_height : hint_range(0.2, 4.0) = 1.8;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying float v_local_y;
varying vec3 v_building_hash;

float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

vec3 hash33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float value_noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);

	float n000 = hash31(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));

	float nx00 = mix(n000, n100, u.x);
	float nx10 = mix(n010, n110, u.x);
	float nx01 = mix(n001, n101, u.x);
	float nx11 = mix(n011, n111, u.x);

	float nxy0 = mix(nx00, nx10, u.y);
	float nxy1 = mix(nx01, nx11, u.y);

	return mix(nxy0, nxy1, u.z);
}

float fbm3(vec3 p) {
	float v = 0.60 * value_noise3(p);
	v += 0.28 * value_noise3(p * 2.13 + vec3(11.7, -5.3, 8.1));
	v += 0.12 * value_noise3(p * 4.47 + vec3(-6.2, 14.9, -3.7));
	return v;
}

vec3 apply_building_variation(vec3 col, vec3 h, float amount) {
	// Warmth / tint shift (Mediterranean ochre-coral-terracotta micro-palette)
	float warm_shift = (h.x - 0.5) * 2.0 * amount;
	vec3 warm_mul = vec3(
		1.0 + warm_shift * 0.42,
		1.0 + warm_shift * 0.10,
		1.0 - warm_shift * 0.36
	);
	vec3 varied = col * warm_mul;

	// Brightness variation per building
	float value_shift = 1.0 + (h.y - 0.5) * 2.0 * (amount * 0.62);
	varied *= value_shift;

	// Saturation variation per building
	float luma = dot(varied, vec3(0.2126, 0.7152, 0.0722));
	float sat_factor = 1.0 + (h.z - 0.5) * 2.0 * (amount * 0.85);
	varied = mix(vec3(luma), varied, clamp(sat_factor, 0.55, 1.45));

	return clamp(varied, vec3(0.0), vec3(1.0));
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_local_y = VERTEX.y;

	// Stable per-building hash derived from world-space building origin (MODEL_MATRIX[3].xyz)
	vec3 snapped_origin = floor(MODEL_MATRIX[3].xyz * 10.0 + 0.5) * 0.1;
	v_building_hash = hash33(snapped_origin + vec3(7.13, 19.41, 31.77));
}

void fragment() {
	vec3 wn = normalize(v_world_normal);
	vec3 abs_n = abs(wn);
	float safe_grain = clamp(grain_strength, 0.0, 1.0);
	float safe_var = clamp(per_building_variation, 0.0, 0.35);

	// 1. Per-building hand-painted color variation
	vec3 b_base = apply_building_variation(base_color, v_building_hash, safe_var);
	vec3 b_accent = apply_building_variation(accent_color, v_building_hash.yzx, safe_var * 0.85);

	// 2. Seamless 3D procedural plaster & stucco grain
	float broad_stucco = fbm3(v_world_pos * 0.42);
	float med_plaster = value_noise3(v_world_pos * 1.85 + vec3(3.7, 9.2, -4.1));
	float fine_grain = value_noise3(v_world_pos * 6.8 + vec3(-8.4, 2.5, 13.1));

	// Painterly sun-washed mottling blending base and accent hues
	float wash_mix = smoothstep(0.28, 0.74, broad_stucco * 0.70 + med_plaster * 0.30);
	vec3 wall_col = mix(b_base, b_accent, wash_mix * (0.22 + 0.45 * safe_grain));

	// 3. Running-bond masonry / stone block courses on vertical walls (triplanar-safe projection)
	// Select horizontal wall axis based on dominant normal without branching flicker
	float use_z_axis = smoothstep(0.42, 0.58, abs_n.x);
	float wall_u = mix(v_world_pos.x, v_world_pos.z, use_z_axis);
	vec2 masonry_uv = vec2(wall_u * 1.15, v_world_pos.y * 2.25);

	float course_row = floor(masonry_uv.y);
	float course_offset = fract(course_row * 0.5);
	vec2 brick_coord = vec2(masonry_uv.x + course_offset, masonry_uv.y);
	vec2 brick_id = floor(brick_coord);
	vec2 brick_f = fract(brick_coord);

	float brick_rand = hash21(brick_id + vec2(17.3, 41.9));
	float d_horiz = min(brick_f.y, 1.0 - brick_f.y);
	float d_vert = min(brick_f.x, 1.0 - brick_f.x) * 1.85;
	float d_mortar = min(d_horiz, d_vert);

	// Soft recessed mortar seams (subtly revealed through plaster via broad_stucco)
	float plaster_reveal = smoothstep(0.32, 0.78, med_plaster * 0.65 + broad_stucco * 0.35);
	float mortar_line = (1.0 - smoothstep(0.03, 0.11, d_mortar)) * plaster_reveal * safe_grain;
	float block_tint = mix(0.93, 1.06, brick_rand);
	wall_col *= mix(1.0, block_tint, 0.38 * safe_grain);
	wall_col = mix(wall_col, b_accent * 0.76, mortar_line * 0.45);

	// 4. Overlapping terracotta / slate tile texture on roofs & upper slopes
	float roof_mask = smoothstep(0.38, 0.74, abs_n.y);
	vec2 tile_uv = v_world_pos.xz * vec2(2.4, 2.8);
	float tile_row = floor(tile_uv.y);
	float tile_col_coord = tile_uv.x + fract(tile_row * 0.5) * 0.5;
	vec2 tile_id = vec2(floor(tile_col_coord), tile_row);
	vec2 tile_f = vec2(fract(tile_col_coord), fract(tile_uv.y));

	float tile_rand = hash21(tile_id + vec2(63.1, 12.7));
	// Scalloped roof tile overlap shadow along the lower edge of each course
	float scallop_curve = sin(tile_f.x * 3.14159265);
	float tile_overlap = 1.0 - smoothstep(0.02, 0.24, tile_f.y + scallop_curve * 0.08);
	float tile_seam = 1.0 - smoothstep(0.02, 0.09, min(tile_f.x, 1.0 - tile_f.x));
	float roof_crevice = clamp(max(tile_overlap * 0.85, tile_seam * 0.65), 0.0, 1.0) * safe_grain;

	vec3 roof_col = mix(b_base, b_accent, smoothstep(0.30, 0.75, tile_rand) * 0.55);
	roof_col *= mix(0.90, 1.08, tile_rand);
	roof_col *= mix(1.0, 0.78, roof_crevice * 0.65);

	vec3 surface_col = mix(wall_col, roof_col, roof_mask);

	// Fine plaster tactile grain modulation
	float grain_mod = mix(1.0 - 0.10 * safe_grain, 1.0 + 0.09 * safe_grain, fine_grain * 0.6 + med_plaster * 0.4);
	surface_col *= grain_mod;

	// 5. Vertical Ground AO gradient near building base (v_local_y < base_ao_height)
	float safe_ao_h = max(base_ao_height, 0.2);
	float ao_t = smoothstep(0.0, safe_ao_h, v_local_y);
	// Softly curve the falloff with guarded pow() for grounded Pixar contact depth
	float ao_curve = pow(max(ao_t, 0.0001), 0.78);
	// Slight organic unevenness along the ground damp/weathering line
	float base_edge_jitter = (broad_stucco - 0.5) * 0.14 * (1.0 - ao_t);
	float ground_ao = clamp(mix(0.62, 1.0, ao_curve) + base_edge_jitter, 0.55, 1.0);

	// Grounded cozy darkening in albedo + cool-earthy depth near foundation
	vec3 foundation_tint = mix(vec3(0.76, 0.73, 0.74), vec3(1.0), ao_curve);
	surface_col *= foundation_tint;

	// Combine ground AO with subtle procedural crevice AO (mortar / roof tiles)
	float crevice_ao = mix(mortar_line * 0.24, roof_crevice * 0.28, roof_mask);
	float final_ao = clamp(ground_ao * (1.0 - crevice_ao), 0.45, 1.0);

	// 6. Tactile PBR roughness & metallic outputs
	float rough_detail = (fine_grain - 0.5) * 0.14 * safe_grain
		+ (1.0 - ao_curve) * 0.10
		+ mix(mortar_line * 0.16, roof_crevice * 0.14, roof_mask);
	float final_roughness = clamp(roughness_val + rough_detail, 0.10, 0.98);
	float final_metallic = clamp(metallic_val, 0.0, 1.0);

	ALBEDO = clamp(surface_col, vec3(0.0), vec3(1.0));
	ROUGHNESS = final_roughness;
	METALLIC = final_metallic;
	SPECULAR = mix(0.42, 0.54, roof_mask);
	AO = final_ao;
}
