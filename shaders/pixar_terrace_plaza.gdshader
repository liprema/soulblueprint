shader_type spatial;
render_mode cull_back;

// Pixar-Style Sunlit Terracotta & Limestone Terrace Plaza Shader (Godot 4.3+ Forward+, Apple Silicon Metal Safe)
// - ZERO dFdx/dFdy, ZERO normal perturbation (0 floor flicker on Apple Silicon Metal)
// - ZERO CLEARCOAT, all pow() guarded with max(..., 0.0001), all smoothstep(a, b, x) strictly a < b
// - radial_mode = 1.0: Circular concentric mosaic with 12 radial rays, golden rings & fan-laid stone tiles
// - radial_mode = 0.0: Cozy warm running-bond Mediterranean cobblestone paving for streets & promenades
// - Pure PBR: metallic gold inlays, sunlit limestone/terracotta roughness, soft micro-relief via ALBEDO & AO

group_uniforms plaza_colors;
uniform vec3 stone_light : source_color = vec3(0.84, 0.80, 0.74);
uniform vec3 stone_terracotta : source_color = vec3(0.68, 0.50, 0.44);
uniform vec3 gold_inlay : source_color = vec3(0.80, 0.66, 0.36);
uniform vec3 grout_color : source_color = vec3(0.46, 0.42, 0.39);

group_uniforms pattern_settings;
uniform float pattern_scale : hint_range(1.0, 24.0) = 6.0;
uniform float radial_mode : hint_range(0.0, 1.0) = 1.0;

group_uniforms pbr_settings;
uniform float stone_roughness : hint_range(0.25, 0.95) = 0.72;
uniform float gold_metallic : hint_range(0.0, 1.0) = 0.80;
uniform float gold_roughness : hint_range(0.08, 0.55) = 0.26;
uniform float weathering_strength : hint_range(0.0, 1.0) = 0.44;

varying vec3 v_world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm2(vec2 p) {
	float v = 0.65 * value_noise(p);
	v += 0.35 * value_noise(p * 2.07 + vec2(7.4, -4.3));
	return v;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float safe_scale = max(pattern_scale, 1.0);
	float mode_w = clamp(radial_mode, 0.0, 1.0);

	// -------------------------------------------------------------------------
	// 1. RADIAL CIRCULAR PLAZA MOSAIC (radial_mode = 1.0)
	//    12 radial rays + concentric gold/ochre rings + fan-laid stone courses
	// -------------------------------------------------------------------------
	vec2 centered = (UV - vec2(0.5)) * 2.0;
	float r = length(centered);
	float angle = (r > 0.0001) ? atan(centered.y, centered.x) : 0.0;
	float ang01 = fract(angle / 6.2831853 + 1.0);

	// 12 radial rays (constant physical arc width across radius)
	float ray_coord = ang01 * 12.0;
	float ray_id = floor(ray_coord);
	float ray_f = fract(ray_coord);
	float ray_dist_arc = min(ray_f, 1.0 - ray_f) * max(r, 0.08) * (6.2831853 / 12.0);
	float ray_gold = (1.0 - smoothstep(0.007, 0.017, ray_dist_arc)) * smoothstep(0.11, 0.16, r) * (1.0 - smoothstep(0.92, 0.99, r));

	// Concentric stone courses scaled by pattern_scale
	float ring_pos = r * safe_scale;
	float ring_id = floor(ring_pos);
	float ring_f = fract(ring_pos);
	float ring_radius = (ring_id + 0.5) / safe_scale;

	// Wedge stone subdivisions per ring (always multiples of 12 so seams align cleanly with the 12 rays)
	float subdiv = max(1.0, floor(ring_id * 0.85 + 1.0));
	float stones_in_ring = 12.0 * subdiv;
	float seg_coord = ang01 * stones_in_ring;
	float seg_id = floor(seg_coord);
	float seg_f = fract(seg_coord);

	// Mortar seam & soft micro-relief bevel for radial wedge tiles
	float d_ring_seam = min(ring_f, 1.0 - ring_f);
	float aspect_fix = max((ring_radius * 6.2831853 / stones_in_ring) * safe_scale, 0.28);
	float d_seg_seam = min(seg_f, 1.0 - seg_f) * aspect_fix;
	float d_rad_seam = min(d_ring_seam, d_seg_seam);

	float rad_grout = 1.0 - smoothstep(0.018, 0.052, d_rad_seam);
	float rad_bevel = smoothstep(0.024, 0.155, d_rad_seam);
	float rad_tile_hash = hash21(vec2(ring_id + 3.1, seg_id + 17.4));

	// Concentric architectural gold rings (inner medallion, mid accent ring, outer promenade ring + fine course inlays)
	float gold_center_dot = 1.0 - smoothstep(0.032, 0.050, r);
	float gold_ring_inner = 1.0 - smoothstep(0.009, 0.021, abs(r - 0.15));
	float gold_ring_mid = 1.0 - smoothstep(0.010, 0.023, abs(r - 0.50));
	float gold_ring_outer = 1.0 - smoothstep(0.011, 0.025, abs(r - 0.86));
	float d_even_ring = abs(fract(ring_pos * 0.5 + 0.5) - 0.5) * 2.0;
	float gold_ring_accent = (1.0 - smoothstep(0.012, 0.032, d_even_ring)) * smoothstep(0.16, 0.24, r) * 0.65;

	float rad_gold = clamp(
		max(max(gold_center_dot, ray_gold), max(max(gold_ring_inner, gold_ring_mid), max(gold_ring_outer, gold_ring_accent))),
		0.0,
		1.0
	);

	// Warm sunlit limestone & Mediterranean terracotta radial mosaic rhythm
	float ring_band = step(0.5, fract(ring_id * 0.5));
	float sector_checker = step(0.5, fract((ray_id + ring_id) * 0.5));
	float terra_mix_rad = clamp(ring_band * 0.62 + sector_checker * 0.26 + (rad_tile_hash - 0.5) * 0.20, 0.0, 1.0);
	// Keep the central sun medallion bright warm limestone framed by terracotta outer accent
	float center_mask = 1.0 - smoothstep(0.11, 0.16, r);
	terra_mix_rad = mix(terra_mix_rad, 0.12, center_mask);

	vec3 rad_stone_col = mix(stone_light, stone_terracotta, terra_mix_rad);
	rad_stone_col *= mix(0.92, 1.05, rad_tile_hash);
	// Soft micro-relief shading baked cleanly into ALBEDO (no normal perturbation)
	rad_stone_col *= mix(0.87, 1.04, rad_bevel);
	rad_stone_col = mix(rad_stone_col, grout_color, rad_grout * (1.0 - rad_gold));

	// -------------------------------------------------------------------------
	// 2. WARM MEDITERRANEAN COBBLESTONE PAVING (radial_mode = 0.0)
	//    World-space running-bond cut stones for streets, terraces & promenades
	// -------------------------------------------------------------------------
	vec2 street_p = v_world_pos.xz * (safe_scale * 0.24);
	float row_id = floor(street_p.y);
	float row_offset = fract(row_id * 0.5) * 1.0; // 0.0 on even rows, 0.5 on odd rows
	float row_jitter = (hash21(vec2(row_id, 9.7)) - 0.5) * 0.24;
	vec2 brick_uv = vec2(street_p.x * 0.68 + row_offset + row_jitter, street_p.y);

	vec2 brick_cell = floor(brick_uv);
	vec2 brick_f = fract(brick_uv);
	float brick_hash = hash21(brick_cell + vec2(41.3, 19.8));

	// Slightly rounded cobblestone distance to mortar seam
	vec2 corner_box = max(abs(brick_f - vec2(0.5)) - vec2(0.39, 0.36), vec2(0.0));
	float corner_dist = length(corner_box);
	float d_brick_seam = clamp(0.12 - corner_dist, 0.0, 0.12) / 0.12;

	float street_grout = 1.0 - smoothstep(0.10, 0.30, d_brick_seam);
	float street_bevel = smoothstep(0.16, 0.72, d_brick_seam);

	// Cozy sunlit limestone base with warm terracotta accent flagstones
	float terra_mix_street = smoothstep(0.56, 0.88, brick_hash) * 0.85 + value_noise(brick_cell * 0.45) * 0.18;
	vec3 street_stone_col = mix(stone_light, stone_terracotta, clamp(terra_mix_street, 0.0, 1.0));
	street_stone_col *= mix(0.91, 1.06, hash21(brick_cell + vec2(5.2, 83.1)));
	street_stone_col *= mix(0.86, 1.05, street_bevel);
	street_stone_col = mix(street_stone_col, grout_color, street_grout);

	// -------------------------------------------------------------------------
	// 3. BLEND MODES + PAINTERLY PIXAR WEATHERING & PURE PBR OUTPUTS
	// -------------------------------------------------------------------------
	vec3 base_stone = mix(street_stone_col, rad_stone_col, mode_w);
	float grout_mask = mix(street_grout, rad_grout, mode_w);
	float bevel_mask = mix(street_bevel, rad_bevel, mode_w);
	float gold_mask = rad_gold * mode_w;

	// Subtle world-space warm sunlit mottling & fine limestone grain (zero seams)
	float broad_wash = fbm2(v_world_pos.xz * 0.38);
	float fine_grain = value_noise(v_world_pos.xz * 5.8);
	float grain_tint = mix(1.0 - 0.09 * weathering_strength, 1.0 + 0.08 * weathering_strength, broad_wash * 0.65 + fine_grain * 0.35);
	base_stone *= grain_tint;

	// Rich luminous gold inlay with soft brushed-gold micro-sheen
	vec3 gold_col = gold_inlay * mix(0.92, 1.12, broad_wash * 0.5 + fine_grain * 0.5);
	// Subtle dark hairline around gold inlay so it reads as set into the stone
	float gold_rim_ao = smoothstep(0.05, 0.45, gold_mask) * (1.0 - smoothstep(0.46, 0.88, gold_mask));
	base_stone *= mix(1.0, 0.86, gold_rim_ao);

	vec3 final_albedo = mix(base_stone, gold_col, gold_mask);

	// Pure PBR roughness & metallic
	float stone_rough = clamp(
		stone_roughness + (fine_grain - 0.5) * 0.12 + grout_mask * 0.22 - bevel_mask * 0.05,
		0.22,
		0.95
	);
	float final_roughness = mix(stone_rough, gold_roughness, gold_mask);
	float final_metallic = gold_mask * gold_metallic;

	ALBEDO = clamp(final_albedo, vec3(0.0), vec3(1.0));
	METALLIC = clamp(final_metallic, 0.0, 1.0);
	ROUGHNESS = clamp(final_roughness, 0.08, 0.96);
	SPECULAR = mix(0.46, 0.72, gold_mask);
	AO = mix(1.0, 0.72, grout_mask * (1.0 - gold_mask));
}
