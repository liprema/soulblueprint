shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_schlick_ggx;

// Turquoise-Crystal Garden Lake & Reflecting Pond Shader (Godot 4.3 Forward+)
// Optimized for 60 FPS on macOS Retina: dual scrolling sine + value-noise ripples,
// shallow-to-deep luminous turquoise-emerald gradient, Fresnel sky reflection,
// sunlit diamond glints, soft shoreline foam rim, and gentle underwater caustic glow.

group_uniforms water_colors;
uniform vec3 shallow_color : source_color = vec3(0.486, 0.910, 0.941); // #7CE8F0 Crystal Aqua
uniform vec3 mid_color : source_color = vec3(0.165, 0.659, 0.722);     // #2AA8B8 Luminous Turquoise
uniform vec3 deep_color : source_color = vec3(0.118, 0.478, 0.588);    // #1E7A96 Emerald Teal
uniform vec3 sky_reflect_color : source_color = vec3(0.847, 0.949, 1.0); // #D8F2FF Sky Reflection
uniform vec3 foam_color : source_color = vec3(0.945, 0.988, 1.0);      // #F1FCFF Soft Shoreline Foam
uniform vec3 caustic_color : source_color = vec3(0.620, 0.960, 0.980); // #9EF5FA Gentle Caustic Glow

group_uniforms surface_settings;
uniform float water_alpha : hint_range(0.4, 0.98) = 0.84;
uniform float wave_speed : hint_range(0.05, 2.0) = 0.42;
uniform float wave_scale : hint_range(0.1, 4.0) = 0.68;
uniform float normal_strength : hint_range(0.0, 0.45) = 0.14;
uniform float fresnel_power : hint_range(1.5, 6.0) = 3.2;
uniform float fresnel_strength : hint_range(0.0, 1.0) = 0.62;
uniform float sparkle_strength : hint_range(0.0, 2.0) = 0.85;
uniform float caustic_strength : hint_range(0.0, 1.0) = 0.24;
uniform float foam_width : hint_range(0.02, 0.35) = 0.14;
uniform float ring_mode : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.53);
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

float water_height(vec2 xz, float t) {
	vec2 p1 = xz * wave_scale + vec2(t * 0.55, t * 0.38);
	vec2 p2 = xz * (wave_scale * 1.65) + vec2(-t * 0.44, t * 0.61);

	float s1 = sin(p1.x * 2.1 + p1.y * 1.4) * 0.35;
	float s2 = sin(p2.x * 1.8 - p2.y * 2.3) * 0.28;
	float n1 = (value_noise(p1 * 1.35) - 0.5) * 0.72;
	float n2 = (value_noise(p2 * 1.95) - 0.5) * 0.52;
	return (s1 + s2 + n1 + n2) * 0.5;
}

float compute_depth_factor(vec2 uv) {
	if (ring_mode > 0.5) {
		float edge_d = min(uv.y, 1.0 - uv.y) * 2.0;
		return clamp(edge_d, 0.0, 1.0);
	}
	float radial = length(uv - vec2(0.5)) * 2.0;
	return clamp(1.0 - radial, 0.0, 1.0);
}

void vertex() {
	vec3 world_p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float depth_f = compute_depth_factor(UV);
	float t = TIME * wave_speed;
	float gentle_bob = sin(world_p.x * 0.75 + t * 2.1) * cos(world_p.z * 0.65 - t * 1.7);
	VERTEX.y += gentle_bob * 0.022 * smoothstep(0.0, 0.22, depth_f);
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = TIME * wave_speed;
	vec2 xz = v_world_pos.xz;

	// Central-difference world-space ripple normal (UV-seam-free across ovals & rings)
	float eps = 0.12;
	float h_c = water_height(xz, t);
	float h_x = water_height(xz + vec2(eps, 0.0), t);
	float h_z = water_height(xz + vec2(0.0, eps), t);

	float dx = (h_x - h_c) / eps;
	float dz = (h_z - h_c) / eps;
	vec3 world_n = normalize(vec3(-dx * normal_strength, 1.0, -dz * normal_strength));
	vec3 view_n = normalize((VIEW_MATRIX * vec4(world_n, 0.0)).xyz);
	NORMAL = view_n;

	// Depth gradient: shallow crystal aqua -> turquoise -> deep emerald teal
	float depth_raw = compute_depth_factor(UV);
	float depth_ripple = clamp(depth_raw + h_c * 0.07, 0.0, 1.0);
	vec3 col_shallow_mid = mix(shallow_color, mid_color, smoothstep(0.05, 0.52, depth_ripple));
	vec3 water_col = mix(col_shallow_mid, deep_color, smoothstep(0.45, 0.96, depth_ripple));

	// Subtle underwater sunlit caustics (dual interfering cellular waves)
	float c1 = value_noise(xz * 1.45 + vec2(t * 0.42, -t * 0.31));
	float c2 = value_noise(xz * 2.15 + vec2(-t * 0.36, t * 0.48));
	float caustic_net = pow(clamp(1.0 - abs(c1 - c2) * 2.6, 0.0, 1.0), 3.0);
	float caustic_mask = smoothstep(0.02, 0.30, depth_raw) * (0.55 + 0.45 * (1.0 - depth_raw));

	// Fresnel sky reflection
	float ndotv = clamp(dot(view_n, normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, fresnel_power);
	water_col = mix(water_col, sky_reflect_color, fresnel * fresnel_strength);

	// Soft animated lacy shoreline foam rim
	float foam_noise = value_noise(xz * 2.4 + vec2(t * 0.5, -t * 0.35));
	float foam_wave = sin(depth_raw * 18.0 - t * 3.2 + foam_noise * 4.5) * 0.5 + 0.5;
	float rim_mask = 1.0 - smoothstep(0.0, foam_width, depth_raw);
	float foam_factor = clamp(rim_mask * (0.55 + 0.45 * foam_noise) + rim_mask * foam_wave * 0.32, 0.0, 1.0);
	foam_factor = smoothstep(0.28, 0.78, foam_factor);
	water_col = mix(water_col, foam_color, foam_factor * 0.85);

	// Sparkling sunlit specular glints on wave crests
	vec3 sun_dir_world = vec3(0.280619, 0.461017, -0.841857);
	vec3 view_dir_world = normalize(CAMERA_POSITION_WORLD - v_world_pos);
	vec3 half_vec = normalize(sun_dir_world + view_dir_world);
	float spec_peak = pow(clamp(dot(world_n, half_vec), 0.0, 1.0), 96.0);
	float glint_noise = value_noise(xz * 5.2 + vec2(t * 1.1, -t * 0.9));
	float sparkle = spec_peak * smoothstep(0.45, 0.88, glint_noise) * sparkle_strength;

	ALBEDO = water_col;
	ROUGHNESS = mix(0.07, 0.34, foam_factor);
	METALLIC = 0.04;
	SPECULAR = 0.90;

	// Gentle magical caustic & sky-glint emission
	vec3 caustic_glow = caustic_color * (caustic_net * caustic_mask * caustic_strength);
	vec3 fresnel_glow = sky_reflect_color * (fresnel * 0.14);
	vec3 glint_glow = vec3(1.0, 0.99, 0.95) * (sparkle * 1.45);
	EMISSION = caustic_glow + fresnel_glow + glint_glow;

	// Semi-transparent with gentle shore feathering and slightly opaque foam
	float base_alpha = mix(water_alpha * 0.86, water_alpha, smoothstep(0.0, 0.18, depth_raw));
	ALPHA = clamp(mix(base_alpha, 0.95, foam_factor * 0.75) + fresnel * 0.08, 0.0, 0.98);
}
