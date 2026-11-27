shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, specular_schlick_ggx;

// Earth Life Ocean Water Shader — Lesson 1 ("Было всё, кроме времени")
// Pixar / Disney Golden Sunset seaside aesthetic.
// Features: Gentle Gerstner swells, sunlight glint, depth absorption
// (deep oceanic azure to crystal turquoise shore), soft shoreline foam
// against sandy beach and wooden pier pylons, and sunlit diamond sparkles.
// Apple Silicon Metal Strict Compliance:
// - Standard PBR lighting without screen derivatives
// - Safe smoothstep(a < b)
// - Guarded safe_normalize, safe_pow, and safe_atan

group_uniforms ocean_palette;
uniform vec3 deep_color : source_color = vec3(0.043, 0.231, 0.380);       // #0B3B61 Deep Oceanic Azure
uniform vec3 mid_color : source_color = vec3(0.098, 0.478, 0.588);        // #197A96 Luminous Teal Swell
uniform vec3 shallow_color : source_color = vec3(0.322, 0.804, 0.776);    // #52CDC6 Crystal Warm Turquoise
uniform vec3 sky_reflect_color : source_color = vec3(0.988, 0.824, 0.690); // #FCD2B0 Warm Sunset Sky Reflection
uniform vec3 foam_color : source_color = vec3(0.980, 0.965, 0.941);       // #FAF6F0 Soft Cream Foam
uniform vec3 sun_tint : source_color = vec3(1.0, 0.880, 0.620);           // #FFE09E Honey-Golden Sun Glint

group_uniforms wave_physics;
uniform float wave_speed : hint_range(0.1, 3.0) = 0.85;
uniform float swell_scale : hint_range(0.02, 0.5) = 0.085;
uniform float wave_amplitude : hint_range(0.0, 1.5) = 0.32;
uniform float steepness : hint_range(0.0, 1.0) = 0.38;
uniform float ripple_frequency : hint_range(0.5, 8.0) = 2.4;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.35;

group_uniforms optical_settings;
uniform float water_alpha : hint_range(0.3, 1.0) = 0.88;
uniform float fresnel_power : hint_range(1.0, 6.0) = 3.4;
uniform float fresnel_strength : hint_range(0.0, 1.0) = 0.72;
uniform float glint_intensity : hint_range(0.0, 4.0) = 1.65;
uniform float foam_distance : hint_range(0.1, 4.0) = 1.25;
uniform float beach_z_start : hint_range(-60.0, 0.0) = -35.0;
uniform vec3 sunset_sun_direction = vec3(0.12, 0.28, -0.95);

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec2 v_wave_offset;

// Metal-safe guarded helper functions
vec3 safe_normalize(vec3 v) {
	float l = length(v);
	return (l > 0.0001) ? (v / l) : vec3(0.0, 1.0, 0.0);
}

float safe_pow(float base_val, float exp_val) {
	return pow(max(base_val, 0.0), exp_val);
}

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
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

// Single Gerstner wave displacement & partial derivatives
void evaluate_gerstner(
	vec2 dir, float amp, float len, float spd, float q,
	vec2 pos, float time,
	inout vec3 disp, inout vec3 tangent_acc, inout vec3 binormal_acc
) {
	float k = 6.2831853 / max(len, 0.01);
	float c = sqrt(9.8 / k) * spd;
	vec2 d = safe_normalize(vec3(dir.x, 0.0, dir.y)).xz;
	float f = k * (dot(d, pos) - c * time);
	float cos_f = cos(f);
	float sin_f = sin(f);
	float qa = q * amp;

	disp.x += d.x * (qa * cos_f);
	disp.z += d.y * (qa * cos_f);
	disp.y += amp * sin_f;

	tangent_acc.x -= d.x * d.x * (k * qa * sin_f);
	tangent_acc.y += d.x * (k * amp * cos_f);
	tangent_acc.z -= d.x * d.y * (k * qa * sin_f);

	binormal_acc.x -= d.x * d.y * (k * qa * sin_f);
	binormal_acc.y += d.y * (k * amp * cos_f);
	binormal_acc.z -= d.y * d.y * (k * qa * sin_f);
}

void vertex() {
	vec3 world_pos_orig = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * wave_speed;

	vec3 disp = vec3(0.0);
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);

	// Multi-octave gentle ocean swell waves rolling toward the shore (+Z)
	// Wave 1: Primary gentle swell
	evaluate_gerstner(vec2(0.08, 0.99), wave_amplitude * 0.58, 22.0, 0.95, steepness, world_pos_orig.xz, t, disp, tangent, binormal);
	// Wave 2: Oblique shore cross-swell
	evaluate_gerstner(vec2(0.32, 0.94), wave_amplitude * 0.28, 12.5, 1.15, steepness * 0.85, world_pos_orig.xz, t, disp, tangent, binormal);
	// Wave 3: Fine surface chop
	evaluate_gerstner(vec2(-0.25, 0.96), wave_amplitude * 0.14, 6.2, 1.45, steepness * 0.70, world_pos_orig.xz, t, disp, tangent, binormal);

	// Shoreline attenuation: waves gently dampen as they reach shallow water
	float shore_dist = clamp((beach_z_start - world_pos_orig.z) * 0.05, 0.0, 1.0);
	float shore_damping = smoothstep(0.0, 0.35, shore_dist);
	disp *= shore_damping;

	// Apply displacement in local space
	vec3 new_world_pos = world_pos_orig + disp;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(new_world_pos, 1.0)).xyz;

	// Compute world normal from Gerstner tangent and binormal cross product
	vec3 norm_world = safe_normalize(cross(binormal, tangent));
	v_world_normal = norm_world;
	v_world_pos = new_world_pos;
	v_wave_offset = disp.xz;
}

void fragment() {
	float t = TIME * wave_speed;
	vec2 xz = v_world_pos.xz;

	// High frequency central-difference normal ripple
	float eps = 0.15;
	float n_scale = ripple_frequency;
	float n0 = value_noise(xz * n_scale + vec2(t * 0.4, -t * 0.3));
	float nx = value_noise((xz + vec2(eps, 0.0)) * n_scale + vec2(t * 0.4, -t * 0.3));
	float nz = value_noise((xz + vec2(0.0, eps)) * n_scale + vec2(t * 0.4, -t * 0.3));

	vec3 ripple_norm = safe_normalize(vec3((n0 - nx) * normal_strength, 1.0, (n0 - nz) * normal_strength));
	vec3 world_n = safe_normalize(v_world_normal * 0.65 + ripple_norm * 0.35);
	vec3 view_n = safe_normalize((VIEW_MATRIX * vec4(world_n, 0.0)).xyz);
	NORMAL = view_n;

	// Scene depth reconstruction for soft shore and pier pylon foam
	float raw_depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, raw_depth, 1.0);
	float scene_view_z = -(upos.z / max(abs(upos.w), 0.0001));
	float water_surface_view_z = -VERTEX.z;
	float contact_depth = max(scene_view_z - water_surface_view_z, 0.0);

	// Beach coordinate distance factor (ensures warm turquoise shore even without contact)
	float shore_dist = clamp((beach_z_start - v_world_pos.z) * 0.04, 0.0, 1.0);
	float depth_factor = clamp(min(contact_depth / max(foam_distance * 4.0, 0.1), shore_dist), 0.0, 1.0);

	// Depth color absorption gradient: shallow crystal turquoise -> luminous mid teal -> deep oceanic azure
	vec3 shallow_to_mid = mix(shallow_color, mid_color, smoothstep(0.08, 0.55, depth_factor));
	vec3 water_base = mix(shallow_to_mid, deep_color, smoothstep(0.45, 0.95, depth_factor));

	// Animated lacy foam along beach contact and pier pylon collisions
	float foam_noise = value_noise(xz * 3.2 + vec2(-t * 0.6, t * 0.45));
	float foam_wave = sin(contact_depth * 14.0 - t * 3.8 + foam_noise * 5.0) * 0.5 + 0.5;
	float contact_mask = 1.0 - smoothstep(0.0, foam_distance, contact_depth);
	float shore_edge_mask = 1.0 - smoothstep(0.0, 0.35, shore_dist);
	float total_contact = max(contact_mask, shore_edge_mask);

	float foam_factor = clamp(
		total_contact * (0.65 + 0.35 * foam_noise) +
		total_contact * foam_wave * 0.45,
		0.0, 1.0
	);
	foam_factor = smoothstep(0.22, 0.72, foam_factor);

	// Fresnel sky reflection (sunset pink-amber horizon bounce)
	float ndotv = clamp(dot(view_n, safe_normalize(VIEW)), 0.0, 1.0);
	float fresnel = safe_pow(1.0 - ndotv, fresnel_power) * fresnel_strength;
	vec3 water_col = mix(water_base, sky_reflect_color, fresnel);

	// Blend shoreline foam
	water_col = mix(water_col, foam_color, foam_factor * 0.92);

	// Sunset specular glint and sunbeam reflections on wave crests
	vec3 sun_dir_n = safe_normalize(sunset_sun_direction);
	vec3 view_dir_world = safe_normalize(CAMERA_POSITION_WORLD - v_world_pos);
	vec3 half_v = safe_normalize(sun_dir_n + view_dir_world);
	float spec_dot = clamp(dot(world_n, half_v), 0.0, 1.0);
	float sun_glint = safe_pow(spec_dot, 84.0) * glint_intensity;

	// Sparkling micro-facets on wave tips
	float glint_noise = value_noise(xz * 6.5 + vec2(t * 1.2, -t * 0.8));
	float sparkle = sun_glint * smoothstep(0.35, 0.85, glint_noise);

	ALBEDO = water_col;
	ROUGHNESS = mix(0.06, 0.42, foam_factor);
	METALLIC = 0.02;
	SPECULAR = 0.94;

	// Warm sunset glow emission on foam and glints
	vec3 glint_glow = sun_tint * (sparkle * 1.6);
	vec3 fresnel_glow = sky_reflect_color * (fresnel * 0.12);
	vec3 foam_warmth = foam_color * (foam_factor * 0.15);
	EMISSION = glint_glow + fresnel_glow + foam_warmth;

	// Alpha with soft edge feathering into the sand
	float shore_alpha_mask = smoothstep(0.0, 0.18, contact_depth);
	float base_alpha = mix(water_alpha * 0.65, water_alpha, shore_alpha_mask);
	ALPHA = clamp(mix(base_alpha, 0.98, foam_factor * 0.85) + fresnel * 0.12, 0.0, 0.98);
}
