shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

// Painterly Volumetric-Feeling Stylized 3D Cloud Shader — Sky: Children of the Light inspired
// Calibrated palette: #0A1F44 (Deep Space Blue), #122D6B (Indigo),
// #1E4B9A (Rich Blue), #F6D36B (Warm Radiant Gold)

group_uniforms cloud_colors;
uniform vec3 deep_shadow_color : source_color = vec3(0.039, 0.115, 0.265); // #0A1F44 Deep cosmic underside
uniform vec3 shadow_color : source_color = vec3(0.085, 0.195, 0.445);      // #122D6B Indigo belly
uniform vec3 mid_color : source_color = vec3(0.265, 0.435, 0.725);         // Soft luminous cobalt-lavender
uniform vec3 sunlit_color : source_color = vec3(0.996, 0.948, 0.825);      // Warm sunlit cream-gold crown
uniform vec3 gold_rim_color : source_color = vec3(0.965, 0.827, 0.420);    // #F6D36B Soft Gold silver-lining

group_uniforms lighting;
uniform vec3 sun_direction = vec3(0.0, 0.24, -1.0);                        // -Z Cathedral sun direction
uniform float rim_strength : hint_range(0.0, 3.0) = 1.45;
uniform float rim_power : hint_range(0.5, 8.0) = 2.35;
uniform float forward_scatter_strength : hint_range(0.0, 2.5) = 0.92;
uniform float detail_contrast : hint_range(0.0, 1.0) = 0.34;

group_uniforms billowing_motion;
uniform float billow_amplitude : hint_range(0.0, 2.0) = 0.42;
uniform float billow_frequency : hint_range(0.1, 3.0) = 0.62;
uniform float billow_speed : hint_range(0.0, 2.0) = 0.24;

group_uniforms softness_and_fade;
uniform float base_opacity : hint_range(0.0, 1.0) = 0.94;
uniform float fresnel_softness : hint_range(0.05, 1.0) = 0.56;
uniform float proximity_fade_near : hint_range(0.5, 25.0) = 3.5;
uniform float proximity_fade_far : hint_range(2.0, 50.0) = 17.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying float v_billow_factor;

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

float fbm_cloud(vec3 p) {
	float v = 0.0;
	float amp = 0.55;
	for (int i = 0; i < 3; i++) {
		v += amp * smooth_noise_3d(p);
		p = p * 2.12 + vec3(5.2, -3.1, 4.7);
		amp *= 0.48;
	}
	return v;
}

void vertex() {
	vec3 world_origin = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 sample_p = world_origin * (billow_frequency * 0.13) + vec3(TIME * billow_speed * 0.08, TIME * billow_speed * 0.22, TIME * billow_speed * 0.16);
	float n1 = smooth_noise_3d(sample_p);
	float n2 = smooth_noise_3d(sample_p * 2.15 + vec3(4.3, -2.1, 7.7));
	float disp = (n1 * 0.65 + n2 * 0.35 - 0.5) * 2.0;

	VERTEX += NORMAL * disp * billow_amplitude;
	v_billow_factor = n1 * 0.65 + n2 * 0.35;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n_world = normalize(v_world_normal);
	vec3 sun_dir = normalize(sun_direction);

	// Painterly 3D cumulus surface sculpting (gives crisp billowy lobes like Sky: Children of the Light)
	vec3 drift = vec3(TIME * billow_speed * 0.06, TIME * billow_speed * 0.09, TIME * billow_speed * 0.11);
	float wisp_detail = fbm_cloud(v_world_pos * 0.085 + drift);
	float lobe_sculpt = (wisp_detail - 0.5) * detail_contrast;

	// Soft wrapped volumetric lighting combining sun direction, sky zenith bounce, and cumulus ridges
	float sun_wrap = clamp(dot(n_world, sun_dir) * 0.52 + 0.48, 0.0, 1.0);
	float up_grad = clamp(n_world.y * 0.5 + 0.5, 0.0, 1.0);
	float light_factor = clamp(mix(up_grad, sun_wrap, 0.54) + (v_billow_factor - 0.5) * 0.18 + lobe_sculpt, 0.0, 1.0);

	// Multi-stop painterly cloud ramp: deep indigo underside -> cobalt mid -> warm sunlit crown
	vec3 col = mix(deep_shadow_color, shadow_color, smoothstep(0.02, 0.34, light_factor));
	col = mix(col, mid_color, smoothstep(0.24, 0.62, light_factor));
	col = mix(col, sunlit_color, smoothstep(0.54, 0.90, light_factor));

	// Golden sunlit silver-lining rim on upper & sun-facing edges
	float ndotv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fresnel_rim = pow(1.0 - ndotv, rim_power);
	float top_sun_mask = smoothstep(0.18, 0.84, up_grad) * smoothstep(0.20, 0.92, sun_wrap);
	col += gold_rim_color * fresnel_rim * top_sun_mask * rim_strength;

	// Warm golden Henyey-Greenstein-style forward scattering when looking toward the Cathedral sun
	vec3 view_dir_world = normalize(v_world_pos - CAMERA_POSITION_WORLD);
	float cos_theta = max(dot(view_dir_world, sun_dir), 0.0);
	float forward_scatter = pow(cos_theta, 3.6);
	float backlit_silver = pow(cos_theta, 9.0) * fresnel_rim;
	col += gold_rim_color * (forward_scatter * (0.30 + 0.70 * fresnel_rim) + backlit_silver * 0.9) * forward_scatter_strength;

	// Painterly feathered Fresnel edges + smooth camera proximity fade when flying through clouds
	float feathered_ndotv = clamp(ndotv + (wisp_detail - 0.5) * 0.16, 0.0, 1.0);
	float edge_alpha = smoothstep(0.02, fresnel_softness, feathered_ndotv);
	float cam_distance = length(VERTEX);
	float proximity_alpha = smoothstep(proximity_fade_near, proximity_fade_far, cam_distance);

	ALBEDO = col;
	ALPHA = clamp(base_opacity * edge_alpha * proximity_alpha, 0.0, 1.0);
}
