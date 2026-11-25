shader_type spatial;
render_mode cull_back;

// Painterly Stylized Tree Canopy Shader for Akashic Chronicles (Godot 4.3+ Forward+, Apple Silicon Metal Safe)
// - ZERO dFdx/dFdy/fwidth, ZERO CLEARCOAT, ZERO unguarded normalize()/pow()
// - All smoothstep(a, b, x) strictly satisfy a < b
// - 3-step painterly canopy gradient: warm sunlit crown -> rich mid foliage -> deep plum-violet underside shadow
// - 3D world-space painterly brushstroke leaf texture + soft pearlescent Fresnel rim on upper edges
// - Stable per-tree variation from MODEL_MATRIX[3].xyz (works cleanly with both MeshInstance3D & MultiMeshInstance3D)
// - Noble matte painterly surface (ROUGHNESS = 0.78, SPECULAR = 0.14, METALLIC = 0.0 — zero plasticine shine)

group_uniforms canopy_palette;
uniform vec3 top_sun_color : source_color = vec3(0.96, 0.56, 0.56);
uniform vec3 mid_foliage_color : source_color = vec3(0.82, 0.36, 0.44);
uniform vec3 shadow_bottom_color : source_color = vec3(0.36, 0.14, 0.28);
uniform vec3 rim_glow_color : source_color = vec3(1.00, 0.84, 0.80);

group_uniforms canopy_gradient;
uniform float canopy_min_y : hint_range(0.0, 6.0) = 2.0;
uniform float canopy_max_y : hint_range(3.0, 12.0) = 8.5;

group_uniforms painterly_detail;
uniform float rim_strength : hint_range(0.0, 0.8) = 0.32;
uniform float leaf_texture_strength : hint_range(0.0, 0.5) = 0.24;
uniform float per_tree_variation : hint_range(0.0, 0.25) = 0.10;

varying float v_local_y;
varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying flat float v_tree_hash;

float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise3d(vec3 p) {
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

void vertex() {
	v_local_y = VERTEX.y;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec3 wn_raw = MODEL_NORMAL_MATRIX * NORMAL;
	float wn_len = length(wn_raw);
	v_world_normal = wn_len > 0.0001 ? (wn_raw / wn_len) : vec3(0.0, 1.0, 0.0);

	// Stable per-tree hash from instance world origin (works for MeshInstance3D & MultiMeshInstance3D)
	vec3 tree_origin = MODEL_MATRIX[3].xyz;
	v_tree_hash = hash31(tree_origin * 0.37 + vec3(13.1, 7.7, 29.3));
}

void fragment() {
	// NaN-safe world normal
	float wn_len = length(v_world_normal);
	vec3 wn = wn_len > 0.0001 ? (v_world_normal / wn_len) : vec3(0.0, 1.0, 0.0);

	// 1. 3-step painterly canopy gradient driven by local height + upward normal orientation
	float h = clamp((v_local_y - canopy_min_y) / max(canopy_max_y - canopy_min_y, 0.5), 0.0, 1.0);
	float up_n = clamp(wn.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 sun_dir = vec3(0.380, 0.860, 0.340);
	float sun_face = clamp(dot(wn, sun_dir) * 0.5 + 0.5, 0.0, 1.0);

	// Warm sunlit top crown, rich saturated mid, deep plum-violet underside shadow
	float grad = clamp(h * 0.56 + up_n * 0.34 + sun_face * 0.16 - 0.04, 0.0, 1.0);
	vec3 col = mix(shadow_bottom_color, mid_foliage_color, smoothstep(0.08, 0.54, grad));
	col = mix(col, top_sun_color, smoothstep(0.48, 0.92, grad));

	// 2. Silky painterly brushstroke leaf texture (softened frequencies + clean LOD fade for zero TAA/FSR flicker)
	float cam_dist = length(VERTEX);
	float near_fade = 1.0 - smoothstep(14.0, 52.0, cam_dist);

	vec3 leaf_p = v_world_pos * 1.15 + vec3(v_tree_hash * 17.3, v_tree_hash * 9.1, -v_tree_hash * 13.7);
	float brush_macro = noise3d(leaf_p);
	float brush_micro = noise3d(leaf_p * 1.8 + vec3(4.7, -3.2, 6.1));
	float leaf_dab = mix(brush_macro, brush_macro * 0.70 + brush_micro * 0.30, near_fade);

	float dab_shadow = (1.0 - smoothstep(0.18, 0.52, leaf_dab)) * leaf_texture_strength;
	float dab_light = smoothstep(0.54, 0.88, leaf_dab) * leaf_texture_strength;

	col = mix(col, shadow_bottom_color * 0.92, dab_shadow * 0.65);
	col = mix(col, top_sun_color * 1.08, dab_light * 0.55 * smoothstep(0.20, 0.85, grad));

	// 3. Soft per-tree hue/warmth variation so groves feel hand-painted and organic
	float tree_shift = (v_tree_hash - 0.5) * 2.0;
	float tree_shift_g = (fract(v_tree_hash * 7.13) - 0.5) * 2.0;
	vec3 tree_tint = vec3(
		1.0 + tree_shift * per_tree_variation * 0.70,
		1.0 + tree_shift_g * per_tree_variation * 0.45,
		1.0 - tree_shift * per_tree_variation * 0.50
	);
	col *= tree_tint;

	// 4. Delicate pearlescent Fresnel rim on upper sunlit canopy edges (NaN-safe)
	float n_len = length(NORMAL);
	vec3 n_view = n_len > 0.0001 ? (NORMAL / n_len) : vec3(0.0, 0.0, 1.0);
	float v_len = length(VIEW);
	vec3 v_view = v_len > 0.0001 ? (VIEW / v_len) : vec3(0.0, 0.0, 1.0);
	float ndotv = clamp(dot(n_view, v_view), 0.0, 1.0);
	float fresnel = pow(max(1.0 - ndotv, 0.0001), 2.6);

	float upper_rim_mask = smoothstep(0.22, 0.86, grad) * smoothstep(0.15, 0.78, up_n);
	float rim_amt = clamp(fresnel * rim_strength * upper_rim_mask * (0.78 + 0.22 * leaf_dab), 0.0, 0.65);
	col = mix(col, rim_glow_color, rim_amt);

	// 5. Noble matte painterly PBR outputs (zero plasticine gloss)
	ALBEDO = clamp(col, vec3(0.0), vec3(1.0));
	ROUGHNESS = 0.78;
	SPECULAR = 0.14;
	METALLIC = 0.0;
	AO = clamp(mix(0.76, 1.0, smoothstep(0.05, 0.65, grad)) - dab_shadow * 0.18, 0.68, 1.0);
	AO_LIGHT_AFFECT = 0.30;
	EMISSION = rim_glow_color * (rim_amt * 0.08);
}
