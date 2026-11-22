shader_type spatial;

// Tactile Wet Twilight Basalt & Carved Slate Shader (Stray-inspired Forward Plus Look-Dev)
// World-space triplanar carved ashlar stone blocks & paving slabs with recessed mortar seams,
// multi-scale mineral grain & micro-fractures, Stray-style organic dampness & puddle roughness
// breakup (0.10..0.28 wet SSR mirror sheen vs 0.66..0.88 dry porous slate), physically accurate
// wet albedo darkening, liquid-flattened puddle normals, and zero fake ambient emission.

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
varying vec3 v_world_normal;

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

float fbm2(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	mat2 rot = mat2(vec2(0.80, -0.60), vec2(0.60, 0.80));
	for (int i = 0; i < 3; i++) {
		v += amp * noise2d(p);
		p = rot * p * 2.04 + vec2(7.4, -4.3);
		amp *= 0.5;
	}
	return v;
}

// Carved ashlar stone blocks / temple paving slabs in 2D world projection.
// Returns vec3(bevel_height [0..1], mortar_mask [0..1], per_block_hash [0..1]).
vec3 ashlar_blocks_2d(vec2 uv, vec2 tile_size, float edge_softness) {
	// Gentle hand-hewn edge wobble so stone seams feel ancient and carved
	vec2 wobble = vec2(
		noise2d(uv * 2.7 + vec2(3.1, -5.4)),
		noise2d(uv * 2.7 + vec2(-8.2, 4.9))
	) - 0.5;
	vec2 p = (uv + wobble * 0.022) / tile_size;

	float row = floor(p.y);
	// Running-bond stagger with subtle per-row variation
	float row_offset = mod(row, 2.0) * 0.5 + (hash21(vec2(row, 17.3)) - 0.5) * 0.14;
	p.x += row_offset;

	vec2 cell = floor(p);
	vec2 f = fract(p);
	float cell_id = hash21(cell + vec2(13.7, 29.1));

	// Distance to nearest mortar seam in world-proportional units
	vec2 dist_edge = min(f, 1.0 - f) * tile_size;
	float d_seam = min(dist_edge.x, dist_edge.y);

	float mortar_half = 0.016;
	float bevel_width = max(0.055, edge_softness);
	float mortar_mask = 1.0 - smoothstep(mortar_half * 0.45, mortar_half + edge_softness * 0.55, d_seam);
	float bevel_height = smoothstep(mortar_half * 0.6, mortar_half + bevel_width, d_seam);

	// Subtle per-block surface relief variation so adjacent slabs catch light slightly differently
	float block_tilt = (cell_id - 0.5) * 0.10;
	return vec3(clamp(bevel_height + block_tilt, 0.0, 1.0), mortar_mask, cell_id);
}

// Returns vec2(surface_height, micro_fracture_vein_mask) on a 2D triplanar projection
vec2 stone_detail_2d(vec2 uv, float grain_scale) {
	// Multi-scale mineral grain: medium slate cleavage + crisp fine grit + micro-tooth
	float g_med = noise2d(uv * (grain_scale * 0.72));
	float g_fine = noise2d(uv * (grain_scale * 2.25) + vec2(13.7, -8.2));
	float g_micro = noise2d(uv * (grain_scale * 5.60) + vec2(-6.1, 19.4));
	float grain = g_med * 0.48 + g_fine * 0.34 + g_micro * 0.18;

	// Carved stone micro-fractures & organic mineral veins via domain-warped ridged noise
	vec2 vein_uv = uv * (grain_scale * 0.24);
	vec2 warp = vec2(
		noise2d(vein_uv * 1.35 + vec2(4.1, -2.7)),
		noise2d(vein_uv * 1.35 + vec2(-9.3, 6.4))
	) - 0.5;
	float ridge_n = noise2d(vein_uv + warp * 0.85);
	float ridge = 1.0 - abs(ridge_n * 2.0 - 1.0);
	float vein = smoothstep(0.84, 0.985, ridge);

	// Secondary delicate cross-vein hairline
	float ridge_n2 = noise2d(vein_uv * 1.92 + warp * 0.55 + vec2(11.2, -5.8));
	float vein2 = smoothstep(0.88, 0.99, 1.0 - abs(ridge_n2 * 2.0 - 1.0)) * 0.58;
	float vein_mask = clamp(max(vein, vein2), 0.0, 1.0);

	// Height combines raised mineral grain and recessed hairline micro-fractures
	float height = grain * 0.72 - vein_mask * 0.46;
	return vec2(height, vein_mask);
}

float combined_height_2d(vec2 uv, vec2 tile_size, float grain_scale, float edge_softness) {
	float grain_h = stone_detail_2d(uv, grain_scale).x;
	float block_h = ashlar_blocks_2d(uv, tile_size, edge_softness).x;
	return grain_h * 0.65 + block_h * (0.85 * seam_strength);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// World-space surface normal (respects mesh transforms & front-facing orientation)
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 tri_w = pow(abs(wn), vec3(5.0));
	tri_w /= max(tri_w.x + tri_w.y + tri_w.z, 0.0001);

	float cam_dist = length(VERTEX);
	float detail_fade = 1.0 - smoothstep(16.0, 74.0, cam_dist);
	float seam_aa = mix(0.016, 0.065, smoothstep(8.0, 58.0, cam_dist));

	// Seamless triplanar broad stone tonal wash (zero UV stretching on any .glb)
	vec3 wp_wash = v_world_pos * broad_wash_scale;
	float broad_wash = fbm2(wp_wash.yz) * tri_w.x
	                 + fbm2(wp_wash.xz) * tri_w.y
	                 + fbm2(wp_wash.xy) * tri_w.z;

	// Architectural block dimensions: larger paving slabs on floors/plazas, coursed ashlar on walls/columns
	vec2 wall_tile = vec2(1.45, 0.58) / max(block_scale, 0.1);
	vec2 floor_tile = vec2(1.55, 1.15) / max(block_scale, 0.1);

	vec3 blk_x = ashlar_blocks_2d(vec2(v_world_pos.z, v_world_pos.y), wall_tile, seam_aa);
	vec3 blk_y = ashlar_blocks_2d(v_world_pos.xz, floor_tile, seam_aa);
	vec3 blk_z = ashlar_blocks_2d(vec2(v_world_pos.x, v_world_pos.y), wall_tile, seam_aa);

	float block_bevel = blk_x.x * tri_w.x + blk_y.x * tri_w.y + blk_z.x * tri_w.z;
	float mortar_mask = (blk_x.y * tri_w.x + blk_y.y * tri_w.y + blk_z.y * tri_w.z) * seam_strength;
	float block_tone = (blk_x.z * tri_w.x + blk_y.z * tri_w.y + blk_z.z * tri_w.z) - 0.5;

	// Triplanar multi-scale mineral grain & micro-fractures
	vec2 det_x = stone_detail_2d(v_world_pos.zy, fine_grain_scale);
	vec2 det_y = stone_detail_2d(v_world_pos.xz, fine_grain_scale);
	vec2 det_z = stone_detail_2d(v_world_pos.xy, fine_grain_scale);

	float surface_h = det_x.x * tri_w.x + det_y.x * tri_w.y + det_z.x * tri_w.z;
	float vein_mask = det_x.y * tri_w.x + det_y.y * tri_w.y + det_z.y * tri_w.z;
	float subtle_grain = surface_h - 0.34;

	// Stray-style organic wetness & puddle field on upward-facing stonework (for Forward+ SSR)
	float up_mask = smoothstep(0.45, 0.86, wn.y);
	float wet_macro = fbm2(v_world_pos.xz * 0.13 + vec2(3.1, -7.4));
	float wet_med = fbm2(v_world_pos.xz * 0.38 + vec2(-11.2, 5.8));
	float wet_field = wet_macro * 0.62 + wet_med * 0.38 - subtle_grain * 0.14 + mortar_mask * 0.08;

	// Damp worn sheen + pooled glossy puddles
	float damp_mask = smoothstep(0.38, 0.62, wet_field) * up_mask * wetness_strength;
	float puddle_mask = smoothstep(0.55, 0.74, wet_field) * up_mask * wetness_strength;

	// Subtle vertical rain-dampness streaks on walls and pillars
	float wall_damp_n = fbm2(vec2((v_world_pos.x + v_world_pos.z) * 0.52, v_world_pos.y * 0.14));
	float wall_damp = smoothstep(0.54, 0.82, wall_damp_n) * (1.0 - up_mask) * 0.34 * wetness_strength;
	float total_wet = clamp(max(damp_mask, wall_damp), 0.0, 1.0);

	// Distance-attenuated procedural normal relief (mineral grain + fractures + carved block bevels)
	// Dampened inside pooled puddles so liquid reflections stay clean and mirror-like
	vec3 perturbed_wn = wn;
	if (detail_fade > 0.005) {
		float eps = 0.016;
		float h0_x = det_x.x * 0.65 + blk_x.x * (0.85 * seam_strength);
		float h0_y = det_y.x * 0.65 + blk_y.x * (0.85 * seam_strength);
		float h0_z = det_z.x * 0.65 + blk_z.x * (0.85 * seam_strength);

		float hx_u = combined_height_2d(vec2(v_world_pos.z + eps, v_world_pos.y), wall_tile, fine_grain_scale, seam_aa);
		float hx_v = combined_height_2d(vec2(v_world_pos.z, v_world_pos.y + eps), wall_tile, fine_grain_scale, seam_aa);
		float hy_u = combined_height_2d(v_world_pos.xz + vec2(eps, 0.0), floor_tile, fine_grain_scale, seam_aa);
		float hy_v = combined_height_2d(v_world_pos.xz + vec2(0.0, eps), floor_tile, fine_grain_scale, seam_aa);
		float hz_u = combined_height_2d(vec2(v_world_pos.x + eps, v_world_pos.y), wall_tile, fine_grain_scale, seam_aa);
		float hz_v = combined_height_2d(vec2(v_world_pos.x, v_world_pos.y + eps), wall_tile, fine_grain_scale, seam_aa);

		vec3 grad_x = vec3(0.0, (hx_v - h0_x), (hx_u - h0_x)) / eps;
		vec3 grad_y = vec3((hy_u - h0_y), 0.0, (hy_v - h0_y)) / eps;
		vec3 grad_z = vec3((hz_u - h0_z), (hz_v - h0_z), 0.0) / eps;

		vec3 world_grad = grad_x * tri_w.x + grad_y * tri_w.y + grad_z * tri_w.z;
		vec3 surf_grad = world_grad - wn * dot(world_grad, wn);

		float liquid_flatten = mix(1.0, 0.16, puddle_mask);
		float relief_strength = 0.072 * detail_fade * liquid_flatten;
		perturbed_wn = normalize(wn - surf_grad * relief_strength);
		NORMAL = normalize((VIEW_MATRIX * vec4(perturbed_wn, 0.0)).xyz);
	}

	// Crevice & cavity darkening: shadowed pores + recessed mortar joints + micro-fractures + underside AO
	float pore_mask = smoothstep(0.54, 0.16, broad_wash + subtle_grain * 0.40) * pore_strength;
	float underside_ao = smoothstep(0.15, -0.78, perturbed_wn.y) * 0.28;
	float cavity_mask = clamp(pore_mask + vein_mask * 0.45 + mortar_mask * 0.72 + underside_ao, 0.0, 0.92);

	// Worn stone bevel / crest lift along carved slab edges and upward-facing stonework
	float edge_wear = smoothstep(0.35, 0.92, block_bevel) * (1.0 - mortar_mask);
	float up_crest = smoothstep(-0.12, 0.85, perturbed_wn.y);
	float crest_mask = clamp((broad_wash * 0.55 + up_crest * 0.45 + edge_wear * 0.24 - 0.34) * crest_lift_strength, 0.0, 1.0);

	// Subtle cool atmospheric dust patina on dry high flats (suppressed where wet)
	float patina_mask = smoothstep(0.42, 0.94, perturbed_wn.y) * mix(0.40, 1.0, broad_wash) * 0.14 * (1.0 - total_wet);
	vec3 patina_tint = mix(stone_highlight_color, horizon_tint_color * 0.42, 0.30);

	// Compose tactile dark basalt / wet slate albedo with per-block stone variation
	vec3 stone_col = mix(stone_base_color, stone_pore_color, cavity_mask);
	stone_col = mix(stone_col, stone_highlight_color, crest_mask * (1.0 - vein_mask * 0.65) * (1.0 - mortar_mask * 0.8));
	stone_col = mix(stone_col, patina_tint, patina_mask);
	stone_col *= (1.0 + block_tone * 0.14 * seam_strength + subtle_grain * 0.09);

	// Physically accurate wet stone darkening (* 0.72 on damp stone, deeper in pooled water)
	float wet_darken = mix(1.0, 0.72, total_wet);
	wet_darken = mix(wet_darken, 0.64, puddle_mask);
	stone_col *= wet_darken;

	// Tactile micro-roughness breakup:
	// Dry porous stone stays matte-satin (0.66..0.88), mortar rougher (~0.92),
	// while damp worn stone & pooled puddles drop to 0.10..0.28 for rich Forward+ SSR reflections!
	float dry_rough_var = -subtle_grain * 0.07 + vein_mask * 0.08 + mortar_mask * 0.16 + pore_mask * 0.06 - crest_mask * 0.05;
	float dry_rough = clamp(base_roughness + dry_rough_var, 0.66, 0.90);
	float damp_rough = mix(0.28, 0.20, clamp(broad_wash, 0.0, 1.0));
	float puddle_rough = mix(0.16, 0.10, puddle_mask);

	float final_rough = mix(dry_rough, damp_rough, total_wet);
	final_rough = mix(final_rough, puddle_rough, puddle_mask);
	final_rough = clamp(final_rough + mortar_mask * 0.12 * (1.0 - puddle_mask * 0.7), 0.10, 0.92);

	// Specular rises from matte dielectric stone to 0.55..0.72 on wet spots for crisp reflections
	float dry_spec = clamp(max(surface_specular, 0.32), 0.0, 0.55) * (1.0 - cavity_mask * 0.42);
	float wet_spec = mix(0.55, 0.72, puddle_mask);
	float final_spec = mix(dry_spec, wet_spec, clamp(total_wet * 0.75 + puddle_mask * 0.5, 0.0, 1.0));

	ALBEDO = stone_col;
	ROUGHNESS = final_rough;
	SPECULAR = final_spec;
	METALLIC = surface_metallic;
	// Zero fake blue emission — let real lighting, amber lanterns, and shadows carve the depth
	EMISSION = vec3(0.0);
}
