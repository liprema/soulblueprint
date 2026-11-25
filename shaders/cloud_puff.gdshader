shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

// Ultra-Soft Plush Cotton-Wool & Cotton-Candy Cumulus Shader (macOS Retina 60 FPS, Metal/Vulkan NaN-Safe)
// Inspired by plush velvety backlit cotton-wool clouds and dreamy pastel sakura-peach cumulus:
// - Minimal smooth low-frequency vertex breathing (billow_amplitude = 0.08) for round, pillowy silhouettes
// - Creamy, velvety 4-stop cushion shading (warm ivory crown -> blush-pearl mid -> airy periwinkle -> lavender cushion)
// - Delicate high-frequency cotton-wool micro-fuzz sheen & backlit fuzzy Fresnel velvet halo
// - Dual-lobe Henyey-Greenstein forward/back scattering for luminous downy edges
// - Soft depth-buffer intersection fade (10m) so clouds melt seamlessly into islands & architecture

group_uniforms cloud_colors;
uniform vec3 underside_color : source_color = vec3(0.698, 0.745, 0.878);      // #B2BEE0 Gentle periwinkle-lavender cushion shadow
uniform vec3 shadow_color : source_color = vec3(0.812, 0.847, 0.941);         // #CFD8F0 Airy powder-periwinkle mid-shadow
uniform vec3 mid_color : source_color = vec3(0.976, 0.933, 0.957);            // #F9EEF4 Soft pastel blush-pearl midtone
uniform vec3 sunlit_color : source_color = vec3(1.000, 0.992, 0.976);         // #FFFDF9 Warm sunlit ivory-cream crown
uniform vec3 silver_lining_color : source_color = vec3(1.000, 0.976, 0.945);  // #FFF9F1 Plush backlit cotton-wool velvet halo
uniform vec3 horizon_bounce_color : source_color = vec3(1.000, 0.839, 0.871); // #FFD6DE Soft sakura-peach horizon bounce

group_uniforms lighting;
uniform vec3 sun_direction = vec3(0.280619, 0.461017, -0.841857);             // Canonical golden-hour sun direction
uniform float sun_shadow_strength : hint_range(0.0, 2.0) = 0.52;
uniform float crevice_ao_strength : hint_range(0.0, 0.6) = 0.14;
uniform float hg_forward_g : hint_range(0.1, 0.85) = 0.56;
uniform float hg_back_g : hint_range(-0.6, 0.0) = -0.20;
uniform float forward_scatter_strength : hint_range(0.0, 1.5) = 0.42;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.72;
uniform float rim_power : hint_range(0.8, 6.0) = 2.15;
uniform float horizon_bounce_strength : hint_range(0.0, 0.6) = 0.22;
uniform float detail_contrast : hint_range(0.0, 0.6) = 0.18;
uniform float cotton_fuzz_strength : hint_range(0.0, 0.8) = 0.34;
uniform float cotton_fuzz_scale : hint_range(0.2, 3.0) = 0.82;

group_uniforms billowing_motion;
uniform float billow_amplitude : hint_range(0.0, 0.5) = 0.08;
uniform float billow_frequency : hint_range(0.1, 2.0) = 0.42;
uniform float billow_speed : hint_range(0.0, 1.0) = 0.14;

group_uniforms softness_and_fade;
uniform float base_opacity : hint_range(0.0, 1.0) = 0.95;
uniform float fresnel_softness : hint_range(0.05, 1.0) = 0.40;
uniform float edge_erosion_strength : hint_range(0.0, 0.6) = 0.18;
uniform float proximity_fade_near : hint_range(0.5, 25.0) = 4.5;
uniform float proximity_fade_far : hint_range(2.0, 50.0) = 19.0;
uniform float soft_intersection_distance : hint_range(0.5, 25.0) = 10.0;

uniform sampler2D depth_tex : hint_depth_texture, filter_linear_mipmap;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying float v_breath_factor;
varying float v_base_mask;

// --- NaN-Safe Math Helpers (Apple Silicon Metal & Vulkan Safe) ---
vec3 safe_normalize(vec3 v, vec3 fallback) {
	float len2 = dot(v, v);
	return len2 > 1e-8 ? v * inversesqrt(len2) : fallback;
}

float safe_pow(float x, float p) {
	return pow(max(x, 0.0001), p);
}

// Fast pure-ALU hash (no trig) for steady 60 FPS on macOS Retina
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

// Soft 2-octave pillowy FBM for creamy internal cloud volume
float soft_fbm_2(vec3 p) {
	float n0 = smooth_noise_3d(p);
	float n1 = smooth_noise_3d(p * 2.05 + vec3(5.3, -3.7, 4.9));
	return n0 * 0.65 + n1 * 0.35;
}

// Smooth Henyey-Greenstein phase function for velvety backlit wool glow
float hg_phase(float cos_theta, float g) {
	float g2 = g * g;
	float denom = max(1.0 + g2 - 2.0 * g * cos_theta, 0.001);
	return (1.0 - g2) / (4.0 * 3.14159265 * safe_pow(denom, 1.5));
}

void vertex() {
	vec3 world_origin = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 sample_p = world_origin * (billow_frequency * 0.065)
		+ vec3(TIME * billow_speed * 0.04, TIME * billow_speed * 0.07, TIME * billow_speed * 0.05);

	// Ultra-smooth low-frequency breathing keeps silhouettes plump, round, and pillowy (zero jaggedness)
	float swell = smooth_noise_3d(sample_p);
	float crown_mask = smoothstep(-0.35, 0.50, NORMAL.y);
	float underside_mask = 1.0 - smoothstep(-0.75, 0.12, NORMAL.y);

	vec3 pos = VERTEX;
	float signed_disp = (swell - 0.5) * 2.0;
	float vertical_scale = mix(0.35, 1.0, crown_mask);
	pos += NORMAL * signed_disp * billow_amplitude * vertical_scale;

	VERTEX = pos;
	v_breath_factor = swell;
	v_base_mask = underside_mask;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = safe_normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz, vec3(0.0, 1.0, 0.0));
}

void fragment() {
	vec3 n_world = safe_normalize(v_world_normal, vec3(0.0, 1.0, 0.0));
	vec3 sun_dir = safe_normalize(sun_direction, vec3(0.280619, 0.461017, -0.841857));

	// Gentle animated world-space coordinates for seamless inter-cloud velvety continuity
	vec3 drift = vec3(TIME * billow_speed * 0.025, TIME * billow_speed * 0.035, TIME * billow_speed * 0.04);
	vec3 p_macro = v_world_pos * 0.055 + drift;

	// Taps 1-2: Broad pillowy volume shading (creamy, zero sharp Worley craters)
	float pillow_fbm = soft_fbm_2(p_macro);

	// Tap 3: Soft directional sun-marching tap for gentle milky self-shadowing
	float sun_depth = smooth_noise_3d((p_macro + sun_dir * 0.42) * 1.15 + vec3(2.3, -1.7, 3.1));
	float sun_transmittance = exp(-sun_depth * sun_shadow_strength);

	// Taps 4-5: Delicate fine cotton-wool micro-fuzz (velvety wool fibers on surface & backlit edge)
	vec3 p_fuzz = v_world_pos * (0.28 * cotton_fuzz_scale) + drift * 1.6;
	float fuzz_coarse = smooth_noise_3d(p_fuzz);
	float fuzz_fine = smooth_noise_3d(p_fuzz * 2.35 + vec3(7.1, -5.4, 3.9));
	float cotton_fuzz = fuzz_coarse * 0.55 + fuzz_fine * 0.45;

	// Ultra-soft velvety cushion lighting (wrapped sun + airy sky hemisphere ambient)
	float sun_wrap = clamp(dot(n_world, sun_dir) * 0.46 + 0.54, 0.0, 1.0);
	float up_grad = clamp(n_world.y * 0.46 + 0.54, 0.0, 1.0);

	// Keep shadows luminous, creamy, and soft like plush cotton wool
	float direct_sun = sun_wrap * mix(0.76, 1.16, sun_transmittance);
	float macro_light = mix(up_grad, direct_sun, 0.50);

	float soft_relief = (pillow_fbm - 0.5) * detail_contrast;
	float fuzz_relief = (cotton_fuzz - 0.5) * (cotton_fuzz_strength * 0.24);
	float gentle_crevice = (1.0 - smoothstep(0.18, 0.78, pillow_fbm)) * crevice_ao_strength;
	float base_shadow = v_base_mask * 0.16;

	float light_factor = clamp(
		macro_light
		+ (v_breath_factor - 0.5) * 0.08
		+ soft_relief
		+ fuzz_relief
		- gentle_crevice
		- base_shadow,
		0.0,
		1.0
	);

	// Creamy 4-stop plush cotton palette:
	// Gentle periwinkle-lavender underside -> airy powder-periwinkle -> blush-pearl mid -> sunlit ivory crown
	vec3 col = mix(underside_color, shadow_color, smoothstep(0.05, 0.38, light_factor));
	col = mix(col, mid_color, smoothstep(0.32, 0.68, light_factor));
	col = mix(col, sunlit_color, smoothstep(0.60, 0.92, light_factor));

	// Soft sakura-peach horizon bounce kissing the lower rounded cloud belly
	float belly_bounce_mask = v_base_mask * (1.0 - smoothstep(0.15, 0.68, up_grad)) * mix(0.75, 1.15, pillow_fbm);
	col = mix(col, horizon_bounce_color, clamp(belly_bounce_mask * horizon_bounce_strength, 0.0, 0.34));

	// Plush fuzzy cotton-wool rim halo (velvet Fresnel + backlit Henyey-Greenstein glow)
	vec3 n_view = safe_normalize(NORMAL, vec3(0.0, 0.0, 1.0));
	vec3 v_view = safe_normalize(VIEW, vec3(0.0, 0.0, 1.0));
	float ndotv = clamp(abs(dot(n_view, v_view)), 0.0, 1.0);

	float velvet_fresnel = safe_pow(1.0 - ndotv, rim_power);
	// Fine cotton fibers catch extra light right along the grazing silhouette
	float wool_sheen = velvet_fresnel * mix(0.72, 1.32, cotton_fuzz);

	vec3 view_dir_world = safe_normalize(v_world_pos - CAMERA_POSITION_WORLD, vec3(0.0, 0.0, -1.0));
	float cos_theta = clamp(dot(view_dir_world, sun_dir), -1.0, 1.0);
	float hg_forward = hg_phase(cos_theta, hg_forward_g);
	float hg_back = hg_phase(cos_theta, hg_back_g);
	float hg_dual = mix(hg_back, hg_forward, 0.72);

	// Soft backlit cotton scatter
	float backlit_glow = clamp(hg_dual * 1.15, 0.0, 1.10) * mix(0.30, 1.0, velvet_fresnel) * mix(0.70, 1.15, sun_transmittance);
	col = mix(col, silver_lining_color, clamp(wool_sheen * rim_strength * 0.42, 0.0, 0.58));
	col += silver_lining_color * (backlit_glow * forward_scatter_strength * 0.45 + wool_sheen * smoothstep(0.18, 0.85, up_grad) * rim_strength * 0.24);

	// Plump, velvety cotton-wool edge feathering:
	// Keeps cloud domes full and round while giving the outer silhouette a delicate fuzzy wool softness
	float silhouette_falloff = smoothstep(0.01, fresnel_softness, ndotv);
	float fuzz_edge_mod = (1.0 - cotton_fuzz) * edge_erosion_strength * (1.0 - ndotv);
	float edge_alpha = smoothstep(0.0, 0.32, silhouette_falloff - fuzz_edge_mod);
	// Soft fuzzy wool halo right at the outermost translucent edge
	edge_alpha = clamp(edge_alpha + velvet_fresnel * (1.0 - velvet_fresnel) * cotton_fuzz * cotton_fuzz_strength * 0.35, 0.0, 1.0);

	// Smooth camera proximity fade
	float cam_distance = length(VERTEX);
	float proximity_alpha = smoothstep(proximity_fade_near, proximity_fade_far, cam_distance);

	// Soft depth-buffer intersection fade (10m) so clouds melt seamlessly into islands & architecture
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
