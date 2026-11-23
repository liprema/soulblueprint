shader_type spatial;

// Aristocratic Baroque Carrara / Calacatta Palace Marble Shader
// Optimized for 60 FPS on macOS Apple Silicon Metal:
// - 100% unperturbed geometry normals (ZERO dFdx/dFdy bump, zero floor lighting flicker)
// - Large-scale organic domain-warped cloudy mineral washes
// - Ultra-delicate, softly feathered Calacatta marble veins (low contrast, wispy, never stripes)
// - Subtle wide palace slab bevels on floors ONLY (0.0 brick strips on vertical walls)
// - Soft warm pearlescent Baroque satin sheen with cool sky-tint shadows

group_uniforms stone_colors;
uniform vec3 stone_base_color : source_color = vec3(0.922, 0.914, 0.894);      // Warm Ivory Carrara Marble
uniform vec3 stone_highlight_color : source_color = vec3(0.980, 0.973, 0.957); // Sunlit Pearlescent Highlight
uniform vec3 stone_pore_color : source_color = vec3(0.706, 0.769, 0.847);      // Soft Cool Mineral Vein / Shadow
uniform vec3 horizon_tint_color : source_color = vec3(0.722, 0.847, 0.973);    // Celestial Sky-Tint Shadow Lift

group_uniforms grain_settings;
uniform float broad_wash_scale : hint_range(0.02, 2.0) = 0.14;
uniform float fine_grain_scale : hint_range(0.5, 16.0) = 4.2;
uniform float pore_strength : hint_range(0.0, 1.0) = 0.42;
uniform float crest_lift_strength : hint_range(0.0, 1.0) = 0.46;

group_uniforms surface_properties;
uniform float base_roughness : hint_range(0.10, 0.95) = 0.56;
uniform float surface_specular : hint_range(0.0, 1.0) = 0.42;
uniform float surface_metallic : hint_range(0.0, 0.15) = 0.02;
uniform float fresnel_lift_strength : hint_range(0.0, 0.35) = 0.10;

group_uniforms stray_lookdev;
uniform float block_scale : hint_range(0.25, 4.0) = 1.0;
uniform float seam_strength : hint_range(0.0, 1.0) = 0.78;
uniform float wetness_strength : hint_range(0.0, 1.0) = 0.30;

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
	v += 0.35 * noise2d(p * 2.07 + vec2(7.4, -4.3));
	return v;
}

// Soft 3-octave FBM for organic cloudy Carrara marble washes
float fbm3_soft(vec2 p) {
	float v = 0.54 * noise2d(p);
	v += 0.30 * noise2d(p * 2.03 + vec2(11.3, -6.7));
	v += 0.16 * noise2d(p * 4.11 + vec2(-5.2, 9.8));
	return v;
}

// Subtle wide palace marble paving slabs (used on horizontal floors ONLY).
// Returns vec3(bevel_height [0..1], hairline_grout [0..1], per_slab_hash [0..1]).
vec3 palace_floor_slabs(vec2 uv, vec2 slab_size, float edge_softness) {
	vec2 p = uv / max(slab_size, vec2(0.25));
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float cell_id = hash21(cell + vec2(13.7, 29.1));

	vec2 dist_edge = min(f, 1.0 - f) * slab_size;
	float d_seam = min(dist_edge.x, dist_edge.y);

	float grout_half = 0.012;
	float bevel_width = max(0.065, edge_softness * 1.4);
	float grout_mask = 1.0 - smoothstep(grout_half * 0.4, grout_half + edge_softness * 0.65, d_seam);
	float bevel_height = smoothstep(grout_half * 0.5, grout_half + bevel_width, d_seam);

	return vec3(clamp(bevel_height, 0.0, 1.0), grout_mask, cell_id);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 world_n_raw = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	float wn_len = length(world_n_raw);
	vec3 wn = wn_len > 0.0001 ? (world_n_raw / wn_len) : vec3(0.0, 1.0, 0.0);
	vec3 awn = abs(wn);

	// Dominant-axis world-space projection with subtle 3D offset so adjacent faces flow organically
	vec2 proj_uv;
	if (awn.y >= awn.x && awn.y >= awn.z) {
		proj_uv = v_world_pos.xz + vec2(v_world_pos.y * 0.17, -v_world_pos.y * 0.13);
	} else if (awn.x >= awn.z) {
		proj_uv = vec2(v_world_pos.z, v_world_pos.y) + vec2(v_world_pos.x * 0.21, v_world_pos.x * 0.11);
	} else {
		proj_uv = vec2(v_world_pos.x, v_world_pos.y) + vec2(v_world_pos.z * 0.19, -v_world_pos.z * 0.13);
	}

	float cam_dist = length(VERTEX);
	float detail_fade = 1.0 - smoothstep(14.0, 64.0, cam_dist);
	float seam_aa = mix(0.014, 0.065, smoothstep(8.0, 52.0, cam_dist));

	// 1. Large-scale organic domain-warped Carrara cloudy mineral washes
	float wash_freq = broad_wash_scale * 0.85;
	vec2 warp_offset = vec2(
		fbm2_fast(proj_uv * (wash_freq * 0.72) + vec2(2.3, -4.1)),
		fbm2_fast(proj_uv * (wash_freq * 0.72) + vec2(-5.7, 3.8))
	) - 0.5;
	vec2 warped_uv = proj_uv * wash_freq + warp_offset * 1.65;

	float cloud_wash = fbm3_soft(warped_uv);
	float mineral_bloom = fbm2_fast(warped_uv * 1.9 + vec2(7.1, -3.4));
	float soft_cloud = mix(cloud_wash, mineral_bloom, 0.35);

	// 2. Ultra-delicate, softly feathered Calacatta veins (sparse, meandering, low contrast)
	vec2 vein_uv = warped_uv * 0.82 + vec2(mineral_bloom * 0.55, -cloud_wash * 0.48);
	float vein_field = fbm2_fast(vein_uv + vec2(4.2, 8.6));
	// Sparse regional presence so veins drift in and fade out into serene ivory marble
	float vein_region = smoothstep(0.42, 0.74, fbm2_fast(proj_uv * (wash_freq * 0.45) + vec2(-9.1, 3.3)));
	float vein_dist = abs(vein_field - 0.5);
	// Softly feathered wispy core + gentle mineral halo (never sharp zebra stripes)
	float vein_core = (1.0 - smoothstep(0.0, 0.042, vein_dist)) * 0.55;
	float vein_halo = (1.0 - smoothstep(0.0, 0.145, vein_dist)) * 0.45;
	float primary_vein = (vein_core + vein_halo) * vein_region;

	// Subtle gossamer secondary wisp that fades cleanly with distance
	float wisp_field = noise2d(vein_uv * 2.35 + vec2(-6.4, 5.1));
	float secondary_wisp = (1.0 - smoothstep(0.0, 0.065, abs(wisp_field - 0.5))) * vein_region * 0.32 * detail_fade;
	float marble_vein = clamp((primary_vein * 0.65 + secondary_wisp) * (0.55 + pore_strength * 0.45), 0.0, 1.0);

	// Ultra-fine crystalline alabaster micro-grain (fades with distance)
	float crystal_grain = (noise2d(proj_uv * (fine_grain_scale * 1.35) + vec2(13.7, -8.2)) - 0.5) * detail_fade;

	// 3. Subtle wide palace slab bevels on HORIZONTAL FLOORS ONLY (0.0 strips on vertical walls)
	float floor_mask = smoothstep(0.68, 0.92, wn.y);
	float inv_bs = 1.0 / max(block_scale, 0.15);
	vec2 floor_slab_size = vec2(2.65, 2.65) * inv_bs;
	vec3 slab = palace_floor_slabs(v_world_pos.xz, floor_slab_size, seam_aa);
	float floor_grout = slab.y * floor_mask * seam_strength * 0.24;
	float floor_bevel = mix(1.0, slab.x, floor_mask * seam_strength * 0.35);
	float floor_slab_tone = (slab.z - 0.5) * floor_mask * seam_strength * 0.04;

	// 4. Soft warm pearlescent Baroque tonal composition
	float up_crest = smoothstep(-0.15, 0.88, wn.y);
	float underside_ao = smoothstep(0.18, -0.78, wn.y) * 0.24;

	// Gentle mineral cloud shading between base and pore color
	float cloud_depth = smoothstep(0.62, 0.20, soft_cloud) * pore_strength * 0.32;
	float vein_blend = marble_vein * 0.22;
	float cavity_mask = clamp(cloud_depth + vein_blend + floor_grout * 0.85 + underside_ao, 0.0, 0.78);

	vec3 marble_col = mix(stone_base_color, stone_pore_color, cavity_mask);

	// Sunlit warm pearlescent highlight on luminous clouds & upward crests
	float pearl_crest = clamp((soft_cloud * 0.58 + up_crest * 0.42 - 0.32) * crest_lift_strength * floor_bevel, 0.0, 1.0);
	vec3 warm_pearl_highlight = mix(stone_highlight_color, stone_highlight_color * vec3(1.02, 1.00, 0.96), 0.45);
	marble_col = mix(marble_col, warm_pearl_highlight, pearl_crest * (1.0 - vein_blend * 0.7) * (1.0 - floor_grout));

	// Cool celestial sky-tint in subtle shadow undersides and calm atmospheric flats
	float sky_shadow_tint = clamp(underside_ao * 0.65 + (1.0 - up_crest) * 0.08, 0.0, 0.32);
	vec3 cool_shadow_col = mix(stone_pore_color, horizon_tint_color, 0.42);
	marble_col = mix(marble_col, cool_shadow_col, sky_shadow_tint * 0.35);

	// Delicate alabaster crystal & wide floor-slab variation (zero checkerboard bricks)
	marble_col *= (1.0 + floor_slab_tone + crystal_grain * 0.032);

	// 5. Smooth pearlescent Fresnel sheen using pure untouched geometry NORMAL (NaN-safe)
	float n_len = length(NORMAL);
	vec3 n_view = n_len > 0.0001 ? (NORMAL / n_len) : vec3(0.0, 0.0, 1.0);
	float v_len = length(VIEW);
	vec3 v_view = v_len > 0.0001 ? (VIEW / v_len) : vec3(0.0, 0.0, 1.0);
	float ndotv = clamp(dot(n_view, v_view), 0.0, 1.0);
	float fresnel = pow(max(1.0 - ndotv, 0.0001), 3.0);

	vec3 pearl_rim_col = mix(warm_pearl_highlight, horizon_tint_color, 0.32);
	marble_col = mix(marble_col, pearl_rim_col, fresnel * fresnel_lift_strength * (1.0 - floor_grout * 0.5));

	// 6. Calm satin Baroque polish (zero plastic glare, zero vertical rain streaks)
	float satin_sheen_var = -soft_cloud * 0.05 + marble_vein * 0.04 + floor_grout * 0.14 - crystal_grain * 0.02;
	float polished_bias = wetness_strength * 0.10 * mix(0.65, 1.0, soft_cloud);
	float final_rough = clamp(base_roughness + satin_sheen_var - polished_bias, 0.36, 0.80);
	float final_spec = clamp(surface_specular * (1.0 - floor_grout * 0.35 - vein_blend * 0.18), 0.24, 0.44);

	ALBEDO = marble_col;
	ROUGHNESS = final_rough;
	SPECULAR = final_spec;
	METALLIC = surface_metallic;
	AO = clamp(1.0 - (floor_grout * 0.45 + underside_ao * 0.55 + vein_blend * 0.15), 0.68, 1.0);
	AO_LIGHT_AFFECT = 0.22;
	EMISSION = vec3(0.0);
}
