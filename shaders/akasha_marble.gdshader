shader_type spatial;

// Tactile Velvety Celestial Stone Shader (Stray / Sky: Children of the Light inspired)
// World-space triplanar-blended twilight indigo sandstone/slate with multi-scale mineral grain,
// subtle carved micro-fractures & veins, cavity darkening, upward twilight dust patina,
// micro-roughness variation (0.74..0.93), distance-faded procedural normal relief, and ZERO glare.

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
uniform float base_roughness : hint_range(0.74, 0.93) = 0.82;
uniform float surface_specular : hint_range(0.0, 0.35) = 0.16;
uniform float surface_metallic : hint_range(0.0, 0.15) = 0.02;
uniform float fresnel_lift_strength : hint_range(0.0, 0.35) = 0.12;

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

// Returns vec2(surface_height, micro_fracture_vein_mask) on a 2D triplanar projection
vec2 stone_detail_2d(vec2 uv, float grain_scale) {
	// Multi-scale mineral grain: medium sandstone body + crisp fine mineral grit + micro-tooth
	float g_med = noise2d(uv * (grain_scale * 0.72));
	float g_fine = noise2d(uv * (grain_scale * 2.15) + vec2(13.7, -8.2));
	float g_micro = noise2d(uv * (grain_scale * 5.40) + vec2(-6.1, 19.4));
	float grain = g_med * 0.50 + g_fine * 0.34 + g_micro * 0.16;

	// Subtle carved stone micro-fractures & organic mineral veins via domain-warped ridged noise
	vec2 vein_uv = uv * (grain_scale * 0.24);
	vec2 warp = vec2(
		noise2d(vein_uv * 1.35 + vec2(4.1, -2.7)),
		noise2d(vein_uv * 1.35 + vec2(-9.3, 6.4))
	) - 0.5;
	float ridge_n = noise2d(vein_uv + warp * 0.85);
	float ridge = 1.0 - abs(ridge_n * 2.0 - 1.0);
	float vein = smoothstep(0.85, 0.985, ridge);

	// Secondary delicate cross-vein hairline
	float ridge_n2 = noise2d(vein_uv * 1.92 + warp * 0.55 + vec2(11.2, -5.8));
	float vein2 = smoothstep(0.89, 0.99, 1.0 - abs(ridge_n2 * 2.0 - 1.0)) * 0.55;
	float vein_mask = clamp(max(vein, vein2), 0.0, 1.0);

	// Height combines raised mineral grain and recessed hairline micro-fractures
	float height = grain * 0.72 - vein_mask * 0.42;
	return vec2(height, vein_mask);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// World-space surface normal (respects mesh transforms & front-facing orientation)
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 tri_w = pow(abs(wn), vec3(4.0));
	tri_w /= max(tri_w.x + tri_w.y + tri_w.z, 0.0001);

	// Seamless triplanar broad stone tonal wash (zero UV stretching on any .glb)
	vec3 wp_wash = v_world_pos * broad_wash_scale;
	float broad_wash = fbm2(wp_wash.yz) * tri_w.x
	                 + fbm2(wp_wash.xz) * tri_w.y
	                 + fbm2(wp_wash.xy) * tri_w.z;

	// Triplanar multi-scale mineral grain & micro-fractures
	vec2 det_x = stone_detail_2d(v_world_pos.yz, fine_grain_scale);
	vec2 det_y = stone_detail_2d(v_world_pos.xz, fine_grain_scale);
	vec2 det_z = stone_detail_2d(v_world_pos.xy, fine_grain_scale);

	float surface_h = det_x.x * tri_w.x + det_y.x * tri_w.y + det_z.x * tri_w.z;
	float vein_mask = det_x.y * tri_w.x + det_y.y * tri_w.y + det_z.y * tri_w.z;
	float subtle_grain = surface_h - 0.34;

	// Distance-attenuated procedural normal perturbation for crisp close-up stone relief
	float cam_dist = length(VERTEX);
	float detail_fade = 1.0 - smoothstep(14.0, 68.0, cam_dist);
	vec3 perturbed_wn = wn;
	if (detail_fade > 0.005) {
		float eps = 0.018;
		float hx_u = stone_detail_2d(v_world_pos.yz + vec2(eps, 0.0), fine_grain_scale).x;
		float hx_v = stone_detail_2d(v_world_pos.yz + vec2(0.0, eps), fine_grain_scale).x;
		float hy_u = stone_detail_2d(v_world_pos.xz + vec2(eps, 0.0), fine_grain_scale).x;
		float hy_v = stone_detail_2d(v_world_pos.xz + vec2(0.0, eps), fine_grain_scale).x;
		float hz_u = stone_detail_2d(v_world_pos.xy + vec2(eps, 0.0), fine_grain_scale).x;
		float hz_v = stone_detail_2d(v_world_pos.xy + vec2(0.0, eps), fine_grain_scale).x;

		vec3 grad_x = vec3(0.0, (hx_u - det_x.x), (hx_v - det_x.x)) / eps;
		vec3 grad_y = vec3((hy_u - det_y.x), 0.0, (hy_v - det_y.x)) / eps;
		vec3 grad_z = vec3((hz_u - det_z.x), (hz_v - det_z.x), 0.0) / eps;

		vec3 world_grad = grad_x * tri_w.x + grad_y * tri_w.y + grad_z * tri_w.z;
		vec3 surf_grad = world_grad - wn * dot(world_grad, wn);
		perturbed_wn = normalize(wn - surf_grad * (0.042 * detail_fade));
		NORMAL = normalize((VIEW_MATRIX * vec4(perturbed_wn, 0.0)).xyz);
	}

	// Crevice & cavity darkening: shadowed pores + recessed micro-fractures + underside occlusion
	float pore_mask = smoothstep(0.54, 0.16, broad_wash + subtle_grain * 0.40) * pore_strength;
	float underside_ao = smoothstep(0.15, -0.78, perturbed_wn.y) * 0.22;
	float cavity_mask = clamp(pore_mask + vein_mask * 0.42 + underside_ao, 0.0, 0.88);

	// Gentle warm-lit bevel/crest lift on upward-facing & gently angled surfaces
	float up_crest = smoothstep(-0.15, 0.85, perturbed_wn.y);
	float crest_mask = clamp((broad_wash * 0.65 + up_crest * 0.55 - 0.32) * crest_lift_strength, 0.0, 1.0);

	// Subtle upward-facing twilight dust / ancient temple patina tint
	float patina_mask = smoothstep(0.38, 0.94, perturbed_wn.y) * mix(0.45, 1.0, broad_wash) * 0.22;
	vec3 patina_tint = mix(stone_highlight_color, horizon_tint_color * 0.55, 0.38);

	// Compose tactile twilight indigo stone albedo
	vec3 stone_col = mix(stone_base_color, stone_pore_color, cavity_mask);
	stone_col = mix(stone_col, stone_highlight_color, crest_mask * (1.0 - vein_mask * 0.65));
	stone_col = mix(stone_col, patina_tint, patina_mask);
	stone_col += stone_col * (subtle_grain * 0.09);

	// Soft Fresnel horizon-tint lift so silhouettes read gently against the twilight clouds
	float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 2.8);
	vec3 horizon_lift = horizon_tint_color * fresnel * fresnel_lift_strength;

	// Tactile micro-roughness variation (0.74..0.93): burnished flats vs rougher pores, veins & dust
	float rough_var = -subtle_grain * 0.07 + vein_mask * 0.07 + patina_mask * 0.12 + pore_mask * 0.05;

	ALBEDO = stone_col;
	ROUGHNESS = clamp(base_roughness + rough_var, 0.74, 0.93);
	SPECULAR = surface_specular * (1.0 - cavity_mask * 0.35);
	METALLIC = surface_metallic;
	EMISSION = horizon_lift;
}
