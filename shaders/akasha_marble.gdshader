shader_type spatial;

// Painterly Velvety Matte-Satin Celestial Stone Shader (Sky: Children of the Light / GRIS inspired)
// Calm twilight indigo sandstone/slate with ultra-fine natural stone grain,
// subtle warm-lit bevel/crest highlights, soft Fresnel horizon lift, and ZERO mirror glare.

group_uniforms stone_colors;
uniform vec3 stone_base_color : source_color = vec3(0.086, 0.157, 0.310);      // #16284F Calm Twilight Indigo
uniform vec3 stone_highlight_color : source_color = vec3(0.125, 0.216, 0.400); // #203766 Warm-lit Bevel / Crest
uniform vec3 stone_pore_color : source_color = vec3(0.059, 0.110, 0.227);      // #0F1C3A Soft Shadowed Pores
uniform vec3 horizon_tint_color : source_color = vec3(0.38, 0.52, 0.78);       // Soft Sky-like Fresnel Horizon Lift

group_uniforms grain_settings;
uniform float broad_wash_scale : hint_range(0.02, 2.0) = 0.14;
uniform float fine_grain_scale : hint_range(0.5, 16.0) = 3.8;
uniform float pore_strength : hint_range(0.0, 1.0) = 0.36;
uniform float crest_lift_strength : hint_range(0.0, 1.0) = 0.42;

group_uniforms surface_properties;
uniform float base_roughness : hint_range(0.76, 0.92) = 0.82;
uniform float surface_specular : hint_range(0.0, 0.35) = 0.16;
uniform float surface_metallic : hint_range(0.0, 0.15) = 0.02;
uniform float fresnel_lift_strength : hint_range(0.0, 0.35) = 0.12;

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

float fbm3(vec3 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 3; i++) {
		v += amp * noise3d(p);
		p = p * 2.03 + vec3(7.4, -4.3, 2.9);
		amp *= 0.5;
	}
	return v;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Broad painterly watercolor-like stone tonal wash (world-space, seamless across architecture)
	vec3 wash_p = v_world_pos * broad_wash_scale;
	float broad_wash = fbm3(wash_p);

	// Soft natural sandstone / slate micro-grain (subtle, calm, never noisy)
	vec3 grain_p = v_world_pos * fine_grain_scale;
	float grain_a = noise3d(grain_p);
	float grain_b = noise3d(grain_p * 2.15 + vec3(13.7, -8.2, 5.4));
	float subtle_grain = (grain_a * 0.65 + grain_b * 0.35) - 0.5;

	// Soft shadowed pores where broad wash and fine grain dip
	float pore_mask = smoothstep(0.52, 0.18, broad_wash + subtle_grain * 0.35) * pore_strength;

	// Gentle warm-lit bevel/crest lift on upward-facing & gently angled surfaces
	vec3 wn = normalize(v_world_normal);
	float up_crest = smoothstep(-0.15, 0.85, wn.y);
	float crest_mask = clamp((broad_wash * 0.65 + up_crest * 0.55 - 0.32) * crest_lift_strength, 0.0, 1.0);

	// Compose velvety twilight indigo stone albedo
	vec3 stone_col = mix(stone_base_color, stone_pore_color, pore_mask);
	stone_col = mix(stone_col, stone_highlight_color, crest_mask);
	stone_col += stone_col * (subtle_grain * 0.06);

	// Soft Fresnel horizon-tint lift so silhouettes read gently against the clouds
	float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 2.8);
	vec3 horizon_lift = horizon_tint_color * fresnel * fresnel_lift_strength;

	ALBEDO = stone_col;
	ROUGHNESS = clamp(base_roughness + subtle_grain * 0.08, 0.76, 0.92);
	SPECULAR = surface_specular;
	METALLIC = surface_metallic;
	EMISSION = horizon_lift;
}
