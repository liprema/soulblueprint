shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

// Hyper-Detailed Volumetric Painterly 3D Cumulus Cloud Shader
// Combines 3D Worley/Voronoi cellular cauliflower lobes, 5-octave domain-warped FBM,
// 3-tap directional sun-marching volumetric self-shadowing, and depth-soft architecture blending.
// Palette: #6C8CC0 deep shadow -> #9DB8E0 mid shadow -> #EDF2FA sunlit cloud -> #FFFFFF pure crown -> #FFEAC4 silver-lining.

group_uniforms cloud_colors;
uniform vec3 deep_shadow_color : source_color = vec3(0.424, 0.549, 0.753); // #6C8CC0 Deep airy sky-blue crevice shadow
uniform vec3 shadow_color : source_color = vec3(0.616, 0.722, 0.878);      // #9DB8E0 Periwinkle-blue mid-shadow
uniform vec3 mid_color : source_color = vec3(0.929, 0.949, 0.980);         // #EDF2FA Clean sunlit cloud body
uniform vec3 sunlit_color : source_color = vec3(1.000, 1.000, 1.000);      // #FFFFFF Crisp pure sunlit cauliflower crown
uniform vec3 gold_rim_color : source_color = vec3(1.000, 0.918, 0.769);    // #FFEAC4 Delicate warm sunlit silver-lining

group_uniforms lighting;
uniform vec3 sun_direction = vec3(0.0, 0.17, -1.0);                        // -Z Cathedral sun direction
uniform float sun_shadow_strength : hint_range(0.0, 3.0) = 1.35;
uniform float crevice_ao_strength : hint_range(0.0, 1.0) = 0.42;
uniform float rim_strength : hint_range(0.0, 3.0) = 0.62;
uniform float rim_power : hint_range(0.5, 8.0) = 2.65;
uniform float forward_scatter_strength : hint_range(0.0, 2.5) = 0.42;
uniform float detail_contrast : hint_range(0.0, 1.0) = 0.56;

group_uniforms billowing_motion;
uniform float billow_amplitude : hint_range(0.0, 2.0) = 0.68;
uniform float billow_frequency : hint_range(0.1, 3.0) = 0.78;
uniform float billow_speed : hint_range(0.0, 2.0) = 0.20;

group_uniforms softness_and_fade;
uniform float base_opacity : hint_range(0.0, 1.0) = 0.95;
uniform float fresnel_softness : hint_range(0.05, 1.0) = 0.46;
uniform float proximity_fade_near : hint_range(0.5, 25.0) = 4.0;
uniform float proximity_fade_far : hint_range(2.0, 50.0) = 18.0;
uniform float soft_intersection_distance : hint_range(0.5, 25.0) = 8.0;

uniform sampler2D depth_tex : hint_depth_texture, filter_linear_mipmap;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying float v_billow_factor;
varying float v_base_mask;

// Fast pure-ALU hashes (no trig) for macOS Retina 60 FPS
float hash31(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p.zxy, p.yxz + 19.19);
	return fract(p.x * p.y * p.z);
}

vec3 hash33(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p.zxy, p.yxz + 19.19);
	return fract(vec3(p.x * p.y, p.y * p.z, p.z * p.x));
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

// Fast seamless 2x2x2 3D Worley / Voronoi cellular cumulus lobe (inverted f1: 1.0 at dome centers, 0.0 in tucked crevices).
// Jitter amplitude <= 0.32 guarantees the closest cell always lies inside the 2x2x2 cube (3.4x faster than 3x3x3 with zero seams).
float worley_cumulus_3d(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float min_d2 = 4.0;

	for (int z = 0; z <= 1; z++) {
		for (int y = 0; y <= 1; y++) {
			for (int x = 0; x <= 1; x++) {
				vec3 corner = vec3(float(x), float(y), float(z));
				vec3 jitter = (hash33(i + corner) - vec3(0.5)) * 0.64;
				vec3 diff = corner + jitter - f;
				float d2 = dot(diff, diff);
				min_d2 = min(min_d2, d2);
			}
		}
	}

	float f1 = sqrt(min_d2);
	// Inverted smooth cellular dome: puffy rounded tops with crisp tucked crevices
	float dome = clamp(1.0 - f1 * 1.12, 0.0, 1.0);
	return dome * dome * (3.0 - 2.0 * dome);
}

// 5-octave sculpted cumulus FBM for fine wispy tufts and painterly brush detail
float fbm_cloud_5(vec3 p) {
	float v = 0.0;
	float amp = 0.50;
	float norm = 0.0;
	for (int i = 0; i < 5; i++) {
		v += amp * smooth_noise_3d(p);
		norm += amp;
		p = p * 2.07 + vec3(5.3, -3.7, 4.9);
		amp *= 0.49;
	}
	return v / max(norm, 0.001);
}

// Fast 2-octave Worley + value density used for 3-tap directional sun-marching
float cloud_density_march(vec3 p) {
	float w1 = worley_cumulus_3d(p * 1.08);
	float n2 = smooth_noise_3d(p * 2.35 + vec3(3.1, -2.4, 5.7));
	return clamp(w1 * 0.68 + n2 * 0.32, 0.0, 1.0);
}

void vertex() {
	vec3 world_origin = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 sample_p = world_origin * (billow_frequency * 0.13)
		+ vec3(TIME * billow_speed * 0.06, TIME * billow_speed * 0.15, TIME * billow_speed * 0.12);

	// 2-octave 3D Worley cellular cauliflower displacement + FBM secondary organic undulation
	float lobe_primary = worley_cumulus_3d(sample_p * 1.15);
	float lobe_secondary = worley_cumulus_3d(sample_p * 2.45 + vec3(4.3, -2.7, 7.1));
	float organic_swell = smooth_noise_3d(sample_p * 1.65 + vec3(-2.1, 3.8, 1.5));
	float combined_lobe = lobe_primary * 0.54 + lobe_secondary * 0.28 + organic_swell * 0.18;

	// Flat-bottomed cumulus cloud-base shaping: compress underside, let upper crown billow into cauliflower turrets
	float crown_mask = smoothstep(-0.32, 0.48, NORMAL.y);
	float underside_flatten = 1.0 - smoothstep(-0.78, 0.06, NORMAL.y);

	vec3 pos = VERTEX;
	if (pos.y < 0.0) {
		pos.y *= mix(1.0, 0.38, underside_flatten);
	}

	float signed_disp = (combined_lobe - 0.44) * 2.0;
	float vertical_scale = mix(0.22, 1.14, crown_mask);
	pos += NORMAL * signed_disp * billow_amplitude * vertical_scale;
	// Extra upward crown puffing on top domes for classic sunlit fairytale cumulus towers
	pos.y += max(signed_disp, 0.0) * billow_amplitude * 0.38 * crown_mask;

	VERTEX = pos;
	v_billow_factor = combined_lobe;
	v_base_mask = underside_flatten;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n_world = normalize(v_world_normal);
	vec3 sun_dir = normalize(sun_direction);

	// Animated world-space coordinates for seamless inter-puff continuity
	vec3 drift = vec3(TIME * billow_speed * 0.045, TIME * billow_speed * 0.075, TIME * billow_speed * 0.09);
	vec3 p_base = v_world_pos * 0.088 + drift;

	// Domain warp for swirling painterly cumulus forms
	vec3 warp = vec3(
		smooth_noise_3d(p_base * 0.72 + vec3(1.7, 9.2, 3.4)),
		smooth_noise_3d(p_base * 0.72 + vec3(8.3, 2.8, 6.1)),
		smooth_noise_3d(p_base * 0.72 + vec3(4.1, 6.7, 1.9))
	) - vec3(0.5);
	vec3 p_warped = p_base + warp * 0.82;

	// 2-octave 3D Worley cauliflower lobes + 5-octave domain-warped FBM wisps
	float worley_large = worley_cumulus_3d(p_warped * 1.12);
	float worley_med = worley_cumulus_3d(p_warped * 2.38 + vec3(3.7, -4.1, 2.9));
	float cumulus_lobe = worley_large * 0.64 + worley_med * 0.36;

	float warped_fbm = fbm_cloud_5(p_warped * 1.18);
	float fine_tufts = smooth_noise_3d(p_warped * 4.2 + warp * 1.15);

	// Sculpt crisp sunlit cauliflower crowns and deep tucked sky-blue crevices
	float combined_detail = mix(warped_fbm, cumulus_lobe, 0.56);
	float tuft_ridge = smoothstep(0.18, 0.84, combined_detail);
	float valley_carve = (tuft_ridge - 0.46) * detail_contrast + (fine_tufts - 0.5) * (detail_contrast * 0.32);
	float crevice_ao = (1.0 - smoothstep(0.10, 0.76, cumulus_lobe)) * crevice_ao_strength;

	// 3-tap directional sun-marching toward sun_dir for authentic volumetric self-shadowing
	float d_tap1 = cloud_density_march(p_warped + sun_dir * 0.24);
	float d_tap2 = cloud_density_march(p_warped + sun_dir * 0.62);
	float d_tap3 = cloud_density_march(p_warped + sun_dir * 1.25);
	float optical_depth = d_tap1 * 0.46 + d_tap2 * 0.34 + d_tap3 * 0.20;
	float sun_transmittance = exp(-optical_depth * sun_shadow_strength);
	// Local micro-relief highlights sunlit edge of each cauliflower bump
	float micro_sun_relief = clamp((cumulus_lobe - d_tap1) * 1.45, -0.34, 0.38) * detail_contrast;

	// Wrapped volumetric lighting combining sun direction, sky zenith bounce, 3-tap sun marching, and crevice AO
	float sun_wrap = clamp(dot(n_world, sun_dir) * 0.55 + 0.45, 0.0, 1.0);
	float up_grad = clamp(n_world.y * 0.5 + 0.5, 0.0, 1.0);
	float base_shadow = v_base_mask * 0.28;

	// Blend geometric macro lighting with volumetric sun transmittance
	float direct_sun = sun_wrap * mix(0.55, 1.25, sun_transmittance);
	float macro_light = mix(up_grad * 0.94, direct_sun, 0.56);

	float light_factor = clamp(
		macro_light
		+ (v_billow_factor - 0.46) * 0.28
		+ valley_carve
		+ micro_sun_relief
		- crevice_ao
		- base_shadow,
		0.0,
		1.0
	);

	// Fairytale painterly 4-stop shading ramp: #6C8CC0 -> #9DB8E0 -> #EDF2FA -> #FFFFFF
	vec3 col = mix(deep_shadow_color, shadow_color, smoothstep(0.05, 0.34, light_factor));
	col = mix(col, mid_color, smoothstep(0.30, 0.62, light_factor));
	col = mix(col, sunlit_color, smoothstep(0.58, 0.86, light_factor));

	// Delicate warm sunlit silver-lining (#FFEAC4) hugging upper & sun-facing cauliflower rims
	float ndotv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fresnel_rim = pow(1.0 - ndotv, rim_power);
	float top_sun_mask = smoothstep(0.20, 0.82, up_grad) * smoothstep(0.20, 0.88, sun_wrap);
	float rim_tuft_mod = mix(0.52, 1.32, tuft_ridge) * mix(0.70, 1.20, sun_transmittance);
	col += gold_rim_color * fresnel_rim * top_sun_mask * rim_tuft_mod * rim_strength;

	// Luminous warm forward scattering when looking toward the Cathedral sun (-Z)
	vec3 view_dir_world = normalize(v_world_pos - CAMERA_POSITION_WORLD);
	float cos_theta = max(dot(view_dir_world, sun_dir), 0.0);
	float forward_scatter = pow(cos_theta, 3.6);
	float backlit_silver = pow(cos_theta, 8.5) * fresnel_rim;
	float scatter_mod = mix(0.65, 1.25, sun_transmittance);
	col += gold_rim_color * (forward_scatter * (0.26 + 0.74 * fresnel_rim) + backlit_silver * 0.90) * forward_scatter_strength * scatter_mod;

	// Painterly scalloped cloud silhouette modulated by Worley domes + high-frequency FBM wisps
	float edge_wisp = (cumulus_lobe - 0.5) * 0.24 + (warped_fbm - 0.5) * 0.22 + (fine_tufts - 0.5) * 0.14;
	float feathered_ndotv = clamp(ndotv + edge_wisp, 0.0, 1.0);
	float edge_alpha = smoothstep(0.04, fresnel_softness, feathered_ndotv);

	// Smooth camera proximity fade
	float cam_distance = length(VERTEX);
	float proximity_alpha = smoothstep(proximity_fade_near, proximity_fade_far, cam_distance);

	// Soft depth-buffer intersection fade so clouds melt seamlessly into cliffs, islands, and viaduct piers
	float soft_intersect = 1.0;
	float depth_raw = texture(depth_tex, SCREEN_UV).r;
	if (depth_raw > 0.00001 && depth_raw < 0.99999) {
		vec4 scene_view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_raw, 1.0);
		if (abs(scene_view.w) > 0.00001) {
			float linear_scene_z = -(scene_view.z / scene_view.w);
			float linear_frag_z = -VERTEX.z;
			float depth_diff = linear_scene_z - linear_frag_z;
			soft_intersect = smoothstep(0.0, soft_intersection_distance, depth_diff);
		}
	}

	ALBEDO = col;
	ALPHA = clamp(base_opacity * edge_alpha * proximity_alpha * soft_intersect, 0.0, 1.0);
}
