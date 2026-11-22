shader_type spatial;

// Polished Dark-Indigo Akasha Temple Marble with Golden Filigree Veins,
// Subtle Art Deco Geometric Inlays, Clearcoat Sheen & Ethereal Rim Glow
// Approved palette: #0A1F44 (Deep Space Blue), #122D6B (Indigo),
// #1E4B9A (Rich Blue), #F6D36B (Soft Gold)

group_uniforms marble_colors;
uniform vec3 dark_marble_color : source_color = vec3(0.039, 0.122, 0.267);   // #0A1F44 Deep Space Blue
uniform vec3 mid_marble_color : source_color = vec3(0.071, 0.176, 0.420);    // #122D6B Indigo
uniform vec3 accent_blue_color : source_color = vec3(0.118, 0.294, 0.604);   // #1E4B9A Rich Blue
uniform vec3 gold_vein_color : source_color = vec3(0.965, 0.827, 0.420);     // #F6D36B Soft Gold
uniform vec3 rim_glow_color : source_color = vec3(0.45, 0.68, 1.0);          // Soft celestial rim bounce

group_uniforms pattern_settings;
uniform float marble_scale : hint_range(0.05, 4.0) = 0.26;
uniform float vein_scale : hint_range(0.05, 4.0) = 0.38;
uniform float vein_sharpness : hint_range(4.0, 32.0) = 15.0;
uniform float vein_intensity : hint_range(0.0, 2.0) = 0.92;
uniform float warp_strength : hint_range(0.0, 3.0) = 1.2;
uniform float art_deco_inlay_strength : hint_range(0.0, 1.0) = 0.32;
uniform float art_deco_grid_scale : hint_range(0.05, 2.0) = 0.22;

group_uniforms surface_properties;
uniform float base_roughness : hint_range(0.05, 0.8) = 0.19;
uniform float vein_roughness : hint_range(0.05, 0.6) = 0.12;
uniform float base_metallic : hint_range(0.0, 1.0) = 0.16;
uniform float vein_metallic : hint_range(0.0, 1.0) = 0.90;
uniform float surface_specular : hint_range(0.0, 1.0) = 0.72;
uniform float clearcoat_amount : hint_range(0.0, 1.0) = 0.55;
uniform float clearcoat_roughness : hint_range(0.0, 1.0) = 0.14;
uniform float vein_emission_strength : hint_range(0.0, 2.0) = 0.42;
uniform float rim_glow_strength : hint_range(0.0, 1.0) = 0.16;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

float hash31(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p.zxy, p.yxz + 19.19);
	return fract(p.x * p.y * p.z);
}

float noise3d(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float n000 = hash31(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));

	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);

	return mix(mix(nx00, nx10, f.y), mix(nx01, nx11, f.y), f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * noise3d(p);
		p = p * 2.04 + vec3(9.2, -5.7, 3.8);
		amp *= 0.5;
	}
	return v;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// World-space procedural coordinates prevent UV stretching on temple pillars & bridges
	vec3 p = v_world_pos * marble_scale;
	float warp_a = fbm(p + vec3(2.4, -1.7, 5.1));
	float warp_b = fbm(p * 1.35 + vec3(-4.1, 3.2, -2.6));
	vec3 warped_p = p + vec3(warp_a, warp_b, warp_a - warp_b) * warp_strength;

	// Deep indigo / space blue marble base clouding
	float base_pattern = fbm(warped_p);
	float subtle_swirl = 0.5 + 0.5 * sin((warped_p.x + warped_p.z * 0.7) * 2.6 + warp_a * 4.0);
	vec3 marble_col = mix(dark_marble_color, mid_marble_color, smoothstep(0.22, 0.78, base_pattern));
	marble_col = mix(marble_col, accent_blue_color, smoothstep(0.62, 0.95, subtle_swirl * base_pattern) * 0.38);

	// Procedural golden filigree veins via domain-warped ridged noise
	vec3 vp = v_world_pos * vein_scale + vec3(warp_a, warp_b, warp_a * 0.5) * (warp_strength * 0.85);
	float ridge_primary = 1.0 - abs(fbm(vp) * 2.0 - 1.0);
	float primary_vein = pow(clamp(ridge_primary, 0.0, 1.0), vein_sharpness);

	float ridge_fine = 1.0 - abs(fbm(vp * 2.2 + vec3(7.3, -3.9, 1.4)) * 2.0 - 1.0);
	float fine_vein = pow(clamp(ridge_fine, 0.0, 1.0), vein_sharpness * 1.45) * 0.55;

	// Subtle Art Deco geometric gold inlay lines on horizontal floor/deck surfaces
	vec2 tile_uv = fract(v_world_pos.xz * art_deco_grid_scale);
	float edge_x = min(tile_uv.x, 1.0 - tile_uv.x);
	float edge_z = min(tile_uv.y, 1.0 - tile_uv.y);
	float grid_line = 1.0 - smoothstep(0.012, 0.026, min(edge_x, edge_z));
	float diag_d = abs(abs(tile_uv.x - 0.5) + abs(tile_uv.y - 0.5) - 0.36);
	float diamond_line = 1.0 - smoothstep(0.008, 0.020, diag_d);
	float up_mask = smoothstep(0.65, 0.92, abs(normalize(v_world_normal).y));
	float deco_inlay = clamp(grid_line * 0.7 + diamond_line * 0.55, 0.0, 1.0) * up_mask * art_deco_inlay_strength;

	float vein_mask = clamp((primary_vein + fine_vein) * vein_intensity + deco_inlay, 0.0, 1.0);

	// Subtle Fresnel rim glow to separate dark indigo architecture against clouds & volumetric fog
	float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 3.2);
	vec3 rim_tint = mix(rim_glow_color, gold_vein_color, vein_mask * 0.65 + 0.25);

	ALBEDO = mix(marble_col, gold_vein_color, vein_mask);
	ROUGHNESS = clamp(mix(base_roughness + (base_pattern - 0.5) * 0.06, vein_roughness, vein_mask), 0.05, 1.0);
	METALLIC = mix(base_metallic, vein_metallic, vein_mask);
	SPECULAR = surface_specular;
	CLEARCOAT = clearcoat_amount * (1.0 - vein_mask * 0.35);
	CLEARCOAT_ROUGHNESS = clearcoat_roughness;
	EMISSION = gold_vein_color * vein_mask * vein_emission_strength + rim_tint * fresnel * rim_glow_strength;
}
