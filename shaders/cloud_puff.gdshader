shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

// Painterly Sculpted 3D Cumulus Cloud Shader — Crisp Fairytale White & Celestial Sky-Blue
// Calibrated palette: #7492C2 (Rich Cool Sky-Blue Shadow Belly), #A8C0E2 (Airy Periwinkle-Blue Mid-Shadow),
// #EBF0F8 (Clean Sunlit Cloud White), #FFFFFF (Crisp Pure Sunlit Crown), #FFEAC8 (Delicate Warm Sunlit Silver-Lining)

group_uniforms cloud_colors;
uniform vec3 deep_shadow_color : source_color = vec3(0.455, 0.573, 0.761); // #7492C2 Rich cool sky-blue shadow belly
uniform vec3 shadow_color : source_color = vec3(0.659, 0.753, 0.886);      // #A8C0E2 Airy periwinkle-blue mid-shadow
uniform vec3 mid_color : source_color = vec3(0.922, 0.941, 0.973);         // #EBF0F8 Clean sunlit cloud white
uniform vec3 sunlit_color : source_color = vec3(1.000, 1.000, 1.000);      // #FFFFFF Crisp pure sunlit crown
uniform vec3 gold_rim_color : source_color = vec3(1.000, 0.918, 0.784);    // #FFEAC8 Delicate warm sunlit silver-lining

group_uniforms lighting;
uniform vec3 sun_direction = vec3(0.0, 0.17, -1.0);                        // -Z Cathedral sun direction
uniform float rim_strength : hint_range(0.0, 3.0) = 0.54;
uniform float rim_power : hint_range(0.5, 8.0) = 2.45;
uniform float forward_scatter_strength : hint_range(0.0, 2.5) = 0.36;
uniform float detail_contrast : hint_range(0.0, 1.0) = 0.48;

group_uniforms billowing_motion;
uniform float billow_amplitude : hint_range(0.0, 2.0) = 0.62;
uniform float billow_frequency : hint_range(0.1, 3.0) = 0.76;
uniform float billow_speed : hint_range(0.0, 2.0) = 0.22;

group_uniforms softness_and_fade;
uniform float base_opacity : hint_range(0.0, 1.0) = 0.96;
uniform float fresnel_softness : hint_range(0.05, 1.0) = 0.42;
uniform float proximity_fade_near : hint_range(0.5, 25.0) = 3.5;
uniform float proximity_fade_far : hint_range(2.0, 50.0) = 17.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying float v_billow_factor;
varying float v_base_mask;

float hash31(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p.zxy, p.yxz + 19.19);
	return fract(p.x * p.y * p.z);
}

float smooth_noise_3d(vec3 p) {
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

// Crisp rounded cauliflower-lobe noise: bulges upward with tucked creases
float cauliflower_lobe(vec3 p) {
	float n = smooth_noise_3d(p);
	float ridge = 1.0 - abs(n * 2.0 - 1.0);
	return mix(n, ridge * ridge, 0.45);
}

// 4-octave sculpted cumulus FBM for painterly tufts and crisp valleys
float fbm_cloud_4(vec3 p) {
	float v = 0.0;
	float amp = 0.52;
	float norm = 0.0;
	for (int i = 0; i < 4; i++) {
		v += amp * smooth_noise_3d(p);
		norm += amp;
		p = p * 2.08 + vec3(5.3, -3.7, 4.9);
		amp *= 0.48;
	}
	return v / max(norm, 0.001);
}

void vertex() {
	vec3 world_origin = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 sample_p = world_origin * (billow_frequency * 0.14)
		+ vec3(TIME * billow_speed * 0.07, TIME * billow_speed * 0.18, TIME * billow_speed * 0.14);

	// 2-octave crisp cauliflower cumulus lobe displacement
	float lobe_primary = cauliflower_lobe(sample_p);
	float lobe_secondary = cauliflower_lobe(sample_p * 2.35 + vec3(4.3, -2.7, 7.1));
	float combined_lobe = lobe_primary * 0.64 + lobe_secondary * 0.36;

	// Flat-bottomed cumulus cloud-base shaping: compress underside, let upper crown billow generously
	float crown_mask = smoothstep(-0.35, 0.45, NORMAL.y);
	float underside_flatten = smoothstep(0.08, -0.78, NORMAL.y);

	vec3 pos = VERTEX;
	if (pos.y < 0.0) {
		pos.y *= mix(1.0, 0.42, underside_flatten);
	}

	float signed_disp = (combined_lobe - 0.46) * 2.0;
	float vertical_scale = mix(0.24, 1.08, crown_mask);
	pos += NORMAL * signed_disp * billow_amplitude * vertical_scale;
	// Extra upward crown puffing on top lobes for classic fairytale cumulus towers
	pos.y += max(signed_disp, 0.0) * billow_amplitude * 0.34 * crown_mask;

	VERTEX = pos;
	v_billow_factor = combined_lobe;
	v_base_mask = underside_flatten;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n_world = normalize(v_world_normal);
	vec3 sun_dir = normalize(sun_direction);

	// 4-octave domain-warped fragment sculpting for crisp sunlit cumulus tufts & deep painterly valleys
	vec3 drift = vec3(TIME * billow_speed * 0.05, TIME * billow_speed * 0.08, TIME * billow_speed * 0.10);
	vec3 p_base = v_world_pos * 0.095 + drift;

	vec3 warp = vec3(
		smooth_noise_3d(p_base * 0.72 + vec3(1.7, 9.2, 3.4)),
		smooth_noise_3d(p_base * 0.72 + vec3(8.3, 2.8, 6.1)),
		smooth_noise_3d(p_base * 0.72 + vec3(4.1, 6.7, 1.9))
	) - vec3(0.5);

	float warped_fbm = fbm_cloud_4(p_base + warp * 0.85);
	float fine_tufts = smooth_noise_3d(p_base * 3.1 + warp * 1.25);

	// Sculpt crisp sunlit domes and tucked valleys
	float tuft_ridge = smoothstep(0.22, 0.82, warped_fbm);
	float valley_carve = (tuft_ridge - 0.48) * detail_contrast + (fine_tufts - 0.5) * (detail_contrast * 0.34);

	// Directional sun-side derivative approximation for painterly cumulus self-shadowing
	float sun_offset_fbm = fbm_cloud_4(p_base + warp * 0.85 + sun_dir * 0.36);
	float micro_sun_relief = clamp((warped_fbm - sun_offset_fbm) * 1.35, -0.35, 0.35) * detail_contrast;

	// Wrapped volumetric lighting combining sun direction, sky zenith bounce, flat-base shadow, and cumulus tufts
	float sun_wrap = clamp(dot(n_world, sun_dir) * 0.54 + 0.46, 0.0, 1.0);
	float up_grad = clamp(n_world.y * 0.5 + 0.5, 0.0, 1.0);
	float base_shadow = v_base_mask * 0.24;

	float light_factor = clamp(
		mix(up_grad, sun_wrap, 0.52)
		+ (v_billow_factor - 0.48) * 0.28
		+ valley_carve
		+ micro_sun_relief
		- base_shadow,
		0.0,
		1.0
	);

	// Crisp fairytale white-and-sky-blue painterly shading ramp
	vec3 col = mix(deep_shadow_color, shadow_color, smoothstep(0.06, 0.34, light_factor));
	col = mix(col, mid_color, smoothstep(0.30, 0.62, light_factor));
	col = mix(col, sunlit_color, smoothstep(0.58, 0.86, light_factor));

	// Delicate warm sunlit silver-lining on upper & sun-facing cauliflower rims
	float ndotv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fresnel_rim = pow(1.0 - ndotv, rim_power);
	float top_sun_mask = smoothstep(0.22, 0.84, up_grad) * smoothstep(0.22, 0.90, sun_wrap);
	float rim_tuft_mod = mix(0.65, 1.25, tuft_ridge);
	col += gold_rim_color * fresnel_rim * top_sun_mask * rim_tuft_mod * rim_strength;

	// Subtle warm forward scattering when looking toward the Cathedral sun
	vec3 view_dir_world = normalize(v_world_pos - CAMERA_POSITION_WORLD);
	float cos_theta = max(dot(view_dir_world, sun_dir), 0.0);
	float forward_scatter = pow(cos_theta, 3.8);
	float backlit_silver = pow(cos_theta, 9.0) * fresnel_rim;
	col += gold_rim_color * (forward_scatter * (0.28 + 0.72 * fresnel_rim) + backlit_silver * 0.85) * forward_scatter_strength;

	// Sharper, painterly scalloped cloud edge modulated by high-detail FBM wisps
	float edge_wisp = (warped_fbm - 0.5) * 0.30 + (fine_tufts - 0.5) * 0.14;
	float feathered_ndotv = clamp(ndotv + edge_wisp, 0.0, 1.0);
	float edge_alpha = smoothstep(0.04, fresnel_softness, feathered_ndotv);
	float cam_distance = length(VERTEX);
	float proximity_alpha = smoothstep(proximity_fade_near, proximity_fade_far, cam_distance);

	ALBEDO = col;
	ALPHA = clamp(base_opacity * edge_alpha * proximity_alpha, 0.0, 1.0);
}
