shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

// Soft Volumetric-Look 3D Cloud Puff Shader — Sky: Children of the Light inspired
// Approved palette: #0A1F44 (Deep Space Blue), #122D6B (Indigo),
// #1E4B9A (Rich Blue), #F6D36B (Soft Gold)

group_uniforms cloud_colors;
uniform vec3 shadow_color : source_color = vec3(0.071, 0.176, 0.420);     // #122D6B Indigo underside
uniform vec3 deep_shadow_color : source_color = vec3(0.039, 0.122, 0.267); // #0A1F44 Deep Space Blue core
uniform vec3 mid_color : source_color = vec3(0.235, 0.395, 0.695);         // Soft luminous indigo-blue
uniform vec3 sunlit_color : source_color = vec3(0.992, 0.945, 0.820);      // Warm sunlit cloud crown
uniform vec3 gold_rim_color : source_color = vec3(0.965, 0.827, 0.420);    // #F6D36B Soft Gold top rim

group_uniforms lighting;
uniform vec3 sun_direction = vec3(0.0, 0.28, -1.0);                        // -Z Cathedral sun direction
uniform float rim_strength : hint_range(0.0, 2.5) = 1.15;
uniform float rim_power : hint_range(0.5, 8.0) = 2.6;
uniform float forward_scatter_strength : hint_range(0.0, 2.0) = 0.65;

group_uniforms billowing_motion;
uniform float billow_amplitude : hint_range(0.0, 2.0) = 0.35;
uniform float billow_frequency : hint_range(0.1, 3.0) = 0.65;
uniform float billow_speed : hint_range(0.0, 2.0) = 0.28;

group_uniforms softness_and_fade;
uniform float base_opacity : hint_range(0.0, 1.0) = 0.92;
uniform float fresnel_softness : hint_range(0.05, 1.0) = 0.48;
uniform float proximity_fade_near : hint_range(0.5, 25.0) = 4.0;
uniform float proximity_fade_far : hint_range(2.0, 50.0) = 16.0;

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

void vertex() {
	vec3 world_origin = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 sample_p = world_origin * (billow_frequency * 0.14) + vec3(0.0, TIME * billow_speed * 0.25, TIME * billow_speed * 0.18);
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

	// Soft wrapped volumetric lighting combining sun direction and vertical sky bounce
	float sun_wrap = clamp(dot(n_world, sun_dir) * 0.5 + 0.5, 0.0, 1.0);
	float up_grad = clamp(n_world.y * 0.5 + 0.5, 0.0, 1.0);
	float light_factor = clamp(mix(up_grad, sun_wrap, 0.52) + (v_billow_factor - 0.5) * 0.22, 0.0, 1.0);

	// Multi-stop cloud shading: deep space underside -> indigo -> luminous blue -> warm sunlit crown
	vec3 col = mix(deep_shadow_color, shadow_color, smoothstep(0.0, 0.32, light_factor));
	col = mix(col, mid_color, smoothstep(0.24, 0.64, light_factor));
	col = mix(col, sunlit_color, smoothstep(0.58, 0.94, light_factor));

	// Golden sunlit top rim + Fresnel halo
	float ndotv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float fresnel_rim = pow(1.0 - ndotv, rim_power);
	float top_sun_mask = smoothstep(0.22, 0.85, up_grad) * smoothstep(0.25, 0.95, sun_wrap);
	col += gold_rim_color * fresnel_rim * top_sun_mask * rim_strength;

	// Subtle warm golden forward scattering when looking toward the sun
	vec3 view_dir_world = normalize(v_world_pos - CAMERA_POSITION_WORLD);
	float forward_scatter = pow(max(dot(view_dir_world, sun_dir), 0.0), 4.0);
	col += gold_rim_color * forward_scatter * (0.35 + 0.65 * fresnel_rim) * forward_scatter_strength;

	// Soft Fresnel silhouette edges + smooth camera proximity fade when flying close/through
	float edge_alpha = smoothstep(0.0, fresnel_softness, ndotv);
	float cam_distance = length(VERTEX);
	float proximity_alpha = smoothstep(proximity_fade_near, proximity_fade_far, cam_distance);

	ALBEDO = col;
	ALPHA = clamp(base_opacity * edge_alpha * proximity_alpha, 0.0, 1.0);
}
