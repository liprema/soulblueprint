shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

// Photorealistic Sunlit Volumetric Cumulus Cloud Shader (macOS Retina 60 FPS Optimized)
// Features:
// - Real dual-lobe Henyey-Greenstein phase function (g = 0.62 forward silver-lining + soft back-scatter)
// - Realistic atmospheric cumulus palette with warm-peach horizon bounce on cloud undersides
// - Lean 8-tap 3D noise pipeline (2D domain warp + 2x2x2 Worley + 3-oct FBM + 2-tap sun marching)
// - Wispy, tattered multi-frequency silhouette erosion (zero hard geometric edges)
// - Soft depth-buffer intersection fade (10m) for seamless mist blending around floating islands & piers

group_uniforms cloud_colors;
uniform vec3 underside_color : source_color = vec3(0.365, 0.455, 0.588);      // #5D7496 Deep muted slate-periwinkle cloud base
uniform vec3 shadow_color : source_color = vec3(0.565, 0.659, 0.784);         // #90A8C8 Powder-blue sky-ambient shaded sides
uniform vec3 mid_color : source_color = vec3(0.894, 0.925, 0.965);            // #E4ECF6 Natural soft atmospheric mid-white
uniform vec3 sunlit_color : source_color = vec3(1.000, 0.992, 0.969);         // #FFFDF7 Crisp warm-sunlit ivory cloud crowns
uniform vec3 silver_lining_color : source_color = vec3(1.000, 0.945, 0.839);  // #FFF1D6 Sunlit silver-lining scattering tint
uniform vec3 horizon_bounce_color : source_color = vec3(0.949, 0.784, 0.659); // #F2C8A8 Subtle warm-peach horizon bounce

group_uniforms lighting;
uniform vec3 sun_direction = vec3(0.0, 0.17, -1.0);                           // -Z Cathedral sun direction
uniform float sun_shadow_strength : hint_range(0.0, 3.0) = 1.48;
uniform float crevice_ao_strength : hint_range(0.0, 1.0) = 0.44;
uniform float hg_forward_g : hint_range(0.1, 0.88) = 0.62;
uniform float hg_back_g : hint_range(-0.6, 0.0) = -0.22;
uniform float forward_scatter_strength : hint_range(0.0, 2.5) = 0.72;
uniform float rim_strength : hint_range(0.0, 3.0) = 0.55;
uniform float rim_power : hint_range(0.5, 8.0) = 2.85;
uniform float horizon_bounce_strength : hint_range(0.0, 0.6) = 0.16;
uniform float detail_contrast : hint_range(0.0, 1.0) = 0.58;

group_uniforms billowing_motion;
uniform float billow_amplitude : hint_range(0.0, 2.0) = 0.42;
uniform float billow_frequency : hint_range(0.1, 3.0) = 0.72;
uniform float billow_speed : hint_range(0.0, 2.0) = 0.18;

group_uniforms softness_and_fade;
uniform float base_opacity : hint_range(0.0, 1.0) = 0.94;
uniform float fresnel_softness : hint_range(0.05, 1.0) = 0.58;
uniform float edge_erosion_strength : hint_range(0.0, 1.2) = 0.78;
uniform float proximity_fade_near : hint_range(0.5, 25.0) = 4.5;
uniform float proximity_fade_far : hint_range(2.0, 50.0) = 19.0;
uniform float soft_intersection_distance : hint_range(0.5, 25.0) = 10.0;

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

// Fast seamless 2x2x2 3D Worley cellular cumulus lobe (1.0 at dome centers, 0.0 in crevices).
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
	float dome = clamp(1.0 - f1 * 1.14, 0.0, 1.0);
	return dome * dome * (3.0 - 2.0 * dome);
}

// 3-octave sculpted cumulus FBM returning vec2(combined_fbm, fine_3rd_octave_wisp) at zero extra tap cost
vec2 fbm_cloud_3_with_fine(vec3 p) {
	float n0 = smooth_noise_3d(p);
	vec3 p1 = p * 2.12 + vec3(5.3, -3.7, 4.9);
	float n1 = smooth_noise_3d(p1);
	vec3 p2 = p1 * 2.18 + vec3(-4.1, 6.2, -2.9);
	float n2 = smooth_noise_3d(p2);

	float combined = (n0 * 0.54 + n1 * 0.28 + n2 * 0.18);
	return vec2(combined, n2);
}

// Physical Henyey-Greenstein scattering phase function
float hg_phase(float cos_theta, float g) {
	float g2 = g * g;
	float denom = max(1.0 + g2 - 2.0 * g * cos_theta, 0.0001);
	return (1.0 - g2) / (4.0 * PI * pow(denom, 1.5));
}

void vertex() {
	vec3 world_origin = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 sample_p = world_origin * (billow_frequency * 0.11)
		+ vec3(TIME * billow_speed * 0.05, TIME * billow_speed * 0.13, TIME * billow_speed * 0.10);

	// Gentle living atmospheric boiling on top of the pre-sculpted multi-lobe cumulus mesh
	float lobe_primary = worley_cumulus_3d(sample_p * 1.15);
	float organic_swell = smooth_noise_3d(sample_p * 1.85 + vec3(-2.1, 3.8, 1.5));
	float combined_lobe = lobe_primary * 0.62 + organic_swell * 0.38;

	// Preserve flat condensation cloud-base underside while allowing upper crowns to billow
	float crown_mask = smoothstep(-0.30, 0.45, NORMAL.y);
	float underside_mask = 1.0 - smoothstep(-0.75, 0.08, NORMAL.y);

	vec3 pos = VERTEX;
	float signed_disp = (combined_lobe - 0.46) * 2.0;
	float vertical_scale = mix(0.18, 1.05, crown_mask);
	pos += NORMAL * signed_disp * billow_amplitude * vertical_scale;
	pos.y += max(signed_disp, 0.0) * billow_amplitude * 0.28 * crown_mask;

	VERTEX = pos;
	v_billow_factor = combined_lobe;
	v_base_mask = underside_mask;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n_world = normalize(v_world_normal);
	vec3 sun_dir = normalize(sun_direction);

	// Animated world-space coordinates for seamless inter-cloud continuity
	vec3 drift = vec3(TIME * billow_speed * 0.04, TIME * billow_speed * 0.065, TIME * billow_speed * 0.08);
	vec3 p_base = v_world_pos * 0.082 + drift;

	// Taps 1-2: Lightweight 3D domain warp for natural turbulent cumulus curls
	float warp_a = smooth_noise_3d(p_base * 0.70 + vec3(1.7, 9.2, 3.4)) - 0.5;
	float warp_b = smooth_noise_3d(p_base * 0.70 + vec3(8.3, 2.8, 6.1)) - 0.5;
	vec3 warp = vec3(warp_a, warp_b, -(warp_a + warp_b) * 0.55);
	vec3 p_warped = p_base + warp * 0.88;

	// Tap 3: 2x2x2 3D Worley cauliflower domes
	float cumulus_lobe = worley_cumulus_3d(p_warped * 1.26);
	// Taps 4-6: 3-octave domain-warped FBM + free high-frequency wisp detail
	vec2 fbm_data = fbm_cloud_3_with_fine(p_warped * 1.28);
	float warped_fbm = fbm_data.x;
	float fine_wisp = fbm_data.y;

	// Sculpt organic cumulus billow relief and tucked atmospheric crevices
	float combined_detail = mix(warped_fbm, cumulus_lobe, 0.52);
	float tuft_ridge = smoothstep(0.18, 0.84, combined_detail);
	float valley_carve = (tuft_ridge - 0.48) * (detail_contrast * 1.05);
	float crevice_ao = (1.0 - smoothstep(0.10, 0.78, cumulus_lobe)) * crevice_ao_strength;

	// Taps 7-8: 2-tap directional sun-marching for Beer-Lambert volumetric self-shadowing
	float d_tap1 = smooth_noise_3d((p_warped + sun_dir * 0.30) * 1.38);
	float d_tap2 = smooth_noise_3d((p_warped + sun_dir * 0.92) * 1.12 + vec3(2.7, -1.9, 4.3));
	float optical_depth = d_tap1 * 0.58 + d_tap2 * 0.42;
	float sun_transmittance = exp(-optical_depth * sun_shadow_strength);
	// Powder-sugar multiple-scattering lift on sunlit edges
	float powder_term = 1.0 - exp(-optical_depth * 2.1);
	float micro_sun_relief = clamp((cumulus_lobe - d_tap1) * 1.32, -0.30, 0.34) * detail_contrast;

	// Meteorological lighting: wrapped direct sunlight + sky hemisphere ambient + underside shading
	float sun_wrap = clamp(dot(n_world, sun_dir) * 0.56 + 0.44, 0.0, 1.0);
	float up_grad = clamp(n_world.y * 0.5 + 0.5, 0.0, 1.0);
	float base_shadow = v_base_mask * 0.32;

	float direct_sun = sun_wrap * mix(0.48, 1.26, sun_transmittance * mix(0.75, 1.18, powder_term));
	float macro_light = mix(up_grad * 0.92, direct_sun, 0.58);

	float light_factor = clamp(
		macro_light
		+ (v_billow_factor - 0.48) * 0.24
		+ valley_carve
		+ micro_sun_relief
		- crevice_ao
		- base_shadow,
		0.0,
		1.0
	);

	// Photorealistic 4-stop cumulus palette:
	// #5D7496 slate-periwinkle base -> #90A8C8 powder-blue shadow -> #E4ECF6 atmospheric mid -> #FFFDF7 warm ivory crown
	vec3 col = mix(underside_color, shadow_color, smoothstep(0.06, 0.36, light_factor));
	col = mix(col, mid_color, smoothstep(0.32, 0.66, light_factor));
	col = mix(col, sunlit_color, smoothstep(0.62, 0.90, light_factor));

	// Subtle warm-peach horizon bounce kissing the lower cloud belly
	float belly_bounce_mask = v_base_mask * (1.0 - smoothstep(0.18, 0.62, up_grad)) * mix(0.65, 1.15, warped_fbm);
	col = mix(col, horizon_bounce_color, clamp(belly_bounce_mask * horizon_bounce_strength, 0.0, 0.28));

	// Real dual-lobe Henyey-Greenstein phase function for sunlit silver-lining & soft back-scatter
	float ndotv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fresnel_rim = pow(1.0 - ndotv, rim_power);
	vec3 view_dir_world = normalize(v_world_pos - CAMERA_POSITION_WORLD);
	float cos_theta = dot(view_dir_world, sun_dir);

	float hg_forward = hg_phase(cos_theta, hg_forward_g);
	float hg_back = hg_phase(cos_theta, hg_back_g);
	float hg_dual = mix(hg_back, hg_forward, 0.76);
	// Scale HG phase into natural atmospheric radiance (peaks softly at backlit edges)
	float silver_scatter = clamp(hg_dual * 1.45, 0.0, 1.65) * mix(0.35, 1.0, fresnel_rim) * mix(0.55, 1.28, sun_transmittance);
	col += silver_lining_color * silver_scatter * forward_scatter_strength;

	// Subtle crisp sunlit crown rim hugging upper & sun-facing cauliflower tufts
	float top_sun_mask = smoothstep(0.24, 0.84, up_grad) * smoothstep(0.22, 0.88, sun_wrap);
	float rim_tuft_mod = mix(0.48, 1.25, tuft_ridge) * mix(0.68, 1.18, sun_transmittance);
	col += silver_lining_color * fresnel_rim * top_sun_mask * rim_tuft_mod * rim_strength * 0.55;

	// Wispy, tattered cumulus edge erosion using multi-frequency 3D FBM + Worley + fine vapor detail
	float wisp_field = warped_fbm * 0.50 + cumulus_lobe * 0.30 + fine_wisp * 0.20;
	float silhouette_falloff = smoothstep(0.02, fresnel_softness, ndotv);
	// Strongly erode grazing angles into soft wispy vapor tendrils while keeping cloud cores dense
	float edge_erode = (1.0 - wisp_field) * edge_erosion_strength * (1.0 - ndotv * 0.58);
	float eroded_density = silhouette_falloff - edge_erode;
	float edge_alpha = smoothstep(0.0, 0.34, eroded_density);
	// Extra feathery wisp break-up on ultra-thin outer fringes
	edge_alpha *= smoothstep(0.18, 0.72, wisp_field + ndotv * 0.85);

	// Smooth camera proximity fade
	float cam_distance = length(VERTEX);
	float proximity_alpha = smoothstep(proximity_fade_near, proximity_fade_far, cam_distance);

	// Soft depth-buffer intersection fade (10m) so clouds melt like mist around floating islands & viaduct piers
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
