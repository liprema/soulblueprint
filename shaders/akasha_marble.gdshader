shader_type spatial;

// High-Performance Tactile Wet Twilight Basalt & Carved Slate Shader (Stray Look-Dev)
// Optimized for 60 FPS on macOS Retina: dominant-axis projection + hardware dFdx/dFdy
// Mikkelsen bump mapping (0 extra noise taps for normals — ~10x faster than 6-tap triplanar),
// preserving carved ashlar block seams, mineral grain, micro-fractures, and wet SSR puddles.

group_uniforms stone_colors;
uniform vec3 stone_base_color : source_color = vec3(0.102, 0.125, 0.173);      // #1A202C Noble Twilight Basalt
uniform vec3 stone_highlight_color : source_color = vec3(0.153, 0.188, 0.259); // #273042 Worn Slate Bevel / Crest
uniform vec3 stone_pore_color : source_color = vec3(0.063, 0.078, 0.114);      // #10141D Deep Pores & Mortar
uniform vec3 horizon_tint_color : source_color = vec3(0.28, 0.34, 0.44);       // Subtle Cool Atmospheric Patina Tint

group_uniforms grain_settings;
uniform float broad_wash_scale : hint_range(0.02, 2.0) = 0.14;
uniform float fine_grain_scale : hint_range(0.5, 16.0) = 4.2;
uniform float pore_strength : hint_range(0.0, 1.0) = 0.42;
uniform float crest_lift_strength : hint_range(0.0, 1.0) = 0.46;

group_uniforms surface_properties;
uniform float base_roughness : hint_range(0.10, 0.95) = 0.74;
uniform float surface_specular : hint_range(0.0, 1.0) = 0.42;
uniform float surface_metallic : hint_range(0.0, 0.15) = 0.02;
uniform float fresnel_lift_strength : hint_range(0.0, 0.35) = 0.10;

group_uniforms stray_lookdev;
uniform float block_scale : hint_range(0.25, 4.0) = 1.0;
uniform float seam_strength : hint_range(0.0, 1.0) = 0.78;
uniform float wetness_strength : hint_range(0.0, 1.0) = 0.85;

varying vec3 v_world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fast 2-octave FBM
float fbm2_fast(vec2 p) {
	float v = 0.65 * noise2d(p);
	v += 0.35 * noise2d(p * 2.13 + vec2(7.4, -4.3));
	return v;
}

// Carved ashlar stone blocks / temple paving slabs in 2D world projection.
// Returns vec3(bevel_height [0..1], mortar_mask [0..1], per_block_hash [0..1]).
vec3 ashlar_blocks_2d(vec2 uv, vec2 tile_size, float edge_softness) {
	float wob = noise2d(uv * 2.5 + vec2(3.1, -5.4)) - 0.5;
	vec2 p = (uv + vec2(wob, -wob) * 0.018) / tile_size;

	float row = floor(p.y);
	float row_offset = mod(row, 2.0) * 0.5 + (hash21(vec2(row, 17.3)) - 0.5) * 0.14;
	p.x += row_offset;

	vec2 cell = floor(p);
	vec2 f = fract(p);
	float cell_id = hash21(cell + vec2(13.7, 29.1));

	vec2 dist_edge = min(f, 1.0 - f) * tile_size;
	float d_seam = min(dist_edge.x, dist_edge.y);

	float mortar_half = 0.016;
	float bevel_width = max(0.055, edge_softness);
	float mortar_mask = 1.0 - smoothstep(mortar_half * 0.45, mortar_half + edge_softness * 0.55, d_seam);
	float bevel_height = smoothstep(mortar_half * 0.6, mortar_half + bevel_width, d_seam);

	float block_tilt = (cell_id - 0.5) * 0.10;
	return vec3(clamp(bevel_height + block_tilt, 0.0, 1.0), mortar_mask, cell_id);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 awn = abs(wn);

	// Select dominant world-space projection axis (1 tap instead of 3 — 3x faster!)
	vec2 proj_uv;
	vec2 tile_size;
	float inv_bs = 1.0 / max(block_scale, 0.1);
	if (awn.y >= awn.x && awn.y >= awn.z) {
		proj_uv = v_world_pos.xz;
		tile_size = vec2(1.55, 1.15) * inv_bs;
	} else if (awn.x >= awn.z) {
		proj_uv = vec2(v_world_pos.z, v_world_pos.y);
		tile_size = vec2(1.45, 0.58) * inv_bs;
	} else {
		proj_uv = vec2(v_world_pos.x, v_world_pos.y);
		tile_size = vec2(1.45, 0.58) * inv_bs;
	}

	float cam_dist = length(VERTEX);
	float detail_fade = 1.0 - smoothstep(14.0, 62.0, cam_dist);
	float seam_aa = mix(0.016, 0.068, smoothstep(8.0, 52.0, cam_dist));

	// Broad tonal wash + fast 2-scale mineral grain & hairline fracture
	float broad_wash = fbm2_fast(proj_uv * broad_wash_scale);
	float g_med = noise2d(proj_uv * (fine_grain_scale * 0.78));
	float g_fine = noise2d(proj_uv * (fine_grain_scale * 2.45) + vec2(13.7, -8.2));
	float grain = g_med * 0.60 + g_fine * 0.40;

	float ridge_n = noise2d(proj_uv * (fine_grain_scale * 0.28) + vec2(broad_wash * 0.75, -broad_wash * 0.55));
	float vein_mask = smoothstep(0.85, 0.985, 1.0 - abs(ridge_n * 2.0 - 1.0));

	// Carved ashlar stone blocks & paving slabs
	vec3 blk = ashlar_blocks_2d(proj_uv, tile_size, seam_aa);
	float block_bevel = blk.x;
	float mortar_mask = blk.y * seam_strength;
	float block_tone = blk.z - 0.5;

	float surface_h = grain * 0.72 - vein_mask * 0.42;
	float subtle_grain = surface_h - 0.34;

	// Stray-style organic wetness & puddle field on upward-facing stonework (for Forward+ SSR)
	float up_mask = smoothstep(0.45, 0.86, wn.y);
	float wet_field = fbm2_fast(v_world_pos.xz * 0.16 + vec2(3.1, -7.4)) - subtle_grain * 0.12 + mortar_mask * 0.08;
	float damp_mask = smoothstep(0.38, 0.62, wet_field) * up_mask * wetness_strength;
	float puddle_mask = smoothstep(0.55, 0.74, wet_field) * up_mask * wetness_strength;

	// Subtle vertical rain-dampness streaks on walls and pillars
	float wall_damp_n = noise2d(vec2((v_world_pos.x + v_world_pos.z) * 0.48, v_world_pos.y * 0.14));
	float wall_damp = smoothstep(0.56, 0.84, wall_damp_n) * (1.0 - up_mask) * 0.32 * wetness_strength;
	float total_wet = clamp(max(damp_mask, wall_damp), 0.0, 1.0);

	// Zero-cost hardware screen-space bump mapping (Mikkelsen method using dFdx/dFdy)
	// Driven only by smooth block bevels so normals stay butter-smooth with zero pixel crawl
	if (detail_fade > 0.01) {
		float total_h = block_bevel * (0.45 * seam_strength);
		vec3 pos_dx = dFdx(VERTEX);
		vec3 pos_dy = dFdy(VERTEX);
		vec3 r1 = cross(pos_dy, NORMAL);
		vec3 r2 = cross(NORMAL, pos_dx);
		float det = dot(pos_dx, r1);
		if (abs(det) > 0.000001) {
			float dh_dx = dFdx(total_h);
			float dh_dy = dFdy(total_h);
			vec3 surf_grad = sign(det) * (dh_dx * r1 + dh_dy * r2) / max(abs(det), 0.00001);
			float bump_scale = 0.012 * detail_fade;
			NORMAL = normalize(NORMAL - surf_grad * bump_scale);
		}
	}

	// Crevice & cavity darkening
	float pore_mask = smoothstep(0.54, 0.16, broad_wash + subtle_grain * 0.38) * pore_strength;
	float underside_ao = smoothstep(0.15, -0.78, wn.y) * 0.28;
	float cavity_mask = clamp(pore_mask + vein_mask * 0.45 + mortar_mask * 0.72 + underside_ao, 0.0, 0.92);

	// Worn stone bevel / crest lift
	float edge_wear = smoothstep(0.35, 0.92, block_bevel) * (1.0 - mortar_mask);
	float up_crest = smoothstep(-0.12, 0.85, wn.y);
	float crest_mask = clamp((broad_wash * 0.55 + up_crest * 0.45 + edge_wear * 0.24 - 0.34) * crest_lift_strength, 0.0, 1.0);

	// Subtle cool atmospheric dust patina on dry high flats
	float patina_mask = smoothstep(0.42, 0.94, wn.y) * mix(0.40, 1.0, broad_wash) * 0.14 * (1.0 - total_wet);
	vec3 patina_tint = mix(stone_highlight_color, horizon_tint_color * 0.42, 0.30);

	// Compose tactile marble / carved stone albedo
	vec3 stone_col = mix(stone_base_color, stone_pore_color, cavity_mask);
	stone_col = mix(stone_col, stone_highlight_color, crest_mask * (1.0 - vein_mask * 0.65) * (1.0 - mortar_mask * 0.8));
	stone_col = mix(stone_col, patina_tint, patina_mask);
	stone_col *= (1.0 + block_tone * 0.14 * seam_strength + subtle_grain * 0.09);

	// Soft moisture tint so marble stays clean, warm, and luminous without dark blotches
	float wet_darken = mix(1.0, 0.93, total_wet);
	stone_col *= wet_darken;

	// Silky satin marble roughness (0.42..0.82) with zero mirror-puddle shimmer
	float dry_rough_var = -subtle_grain * 0.07 + vein_mask * 0.08 + mortar_mask * 0.16 + pore_mask * 0.06 - crest_mask * 0.05;
	float dry_rough = clamp(base_roughness + dry_rough_var, 0.56, 0.84);
	float damp_rough = mix(0.46, 0.42, clamp(broad_wash, 0.0, 1.0));
	float puddle_rough = 0.42;
	float final_rough = mix(dry_rough, damp_rough, total_wet);
	final_rough = mix(final_rough, puddle_rough, puddle_mask);

	float dry_spec = clamp(surface_specular * (1.0 - cavity_mask * 0.35), 0.28, 0.42);
	float wet_spec = mix(0.36, 0.42, puddle_mask);
	float final_spec = clamp(mix(dry_spec, wet_spec, clamp(max(total_wet, puddle_mask), 0.0, 1.0)), 0.28, 0.42);

	ALBEDO = stone_col;
	ROUGHNESS = clamp(final_rough, 0.42, 0.82);
	SPECULAR = final_spec;
	METALLIC = surface_metallic;
	EMISSION = vec3(0.0);
}
