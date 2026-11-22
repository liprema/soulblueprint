shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

// Golden Volumetric Light Shaft / God Rays Shader for the Astrolabe Cathedral & Sanctuary Islands
// Approved palette: #F6D36B (Soft Gold)

group_uniforms beam_appearance;
uniform vec3 beam_color : source_color = vec3(0.965, 0.827, 0.420); // #F6D36B Soft Gold
uniform vec3 core_tint : source_color = vec3(1.0, 0.965, 0.82);      // Warm luminous gold-white core
uniform float intensity : hint_range(0.0, 3.0) = 0.58;
uniform float edge_falloff : hint_range(0.5, 6.0) = 2.15;

group_uniforms vertical_fade_and_shimmer;
uniform float top_fade : hint_range(0.01, 0.5) = 0.16;
uniform float bottom_fade : hint_range(0.01, 0.6) = 0.34;
uniform float shimmer_speed : hint_range(0.0, 3.0) = 0.38;
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.36;
uniform float ray_stripe_count : hint_range(1.0, 24.0) = 8.0;

group_uniforms proximity_fade;
uniform float near_fade_min : hint_range(0.5, 15.0) = 3.0;
uniform float near_fade_max : hint_range(2.0, 45.0) = 16.0;

void fragment() {
	// Smooth grazing-angle Fresnel falloff so volumetric cone edges dissolve cleanly
	float ndotv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fresnel_mask = pow(ndotv, edge_falloff);

	// Smooth vertical fade at both ends of the light shaft
	float v_fade = smoothstep(0.0, top_fade, UV.y) * smoothstep(1.0, 1.0 - bottom_fade, UV.y);

	// Dual-frequency shimmering light streaks & gentle ascending golden dust curtains
	float t = TIME * shimmer_speed;
	float streak_a = 0.5 + 0.5 * sin(UV.x * ray_stripe_count * 6.2831853 + t * 0.65 + UV.y * 2.2);
	float streak_b = 0.5 + 0.5 * sin(UV.x * (ray_stripe_count * 1.65) * 6.2831853 - t * 1.05 + UV.y * 3.8);
	float dust_drift = 0.5 + 0.5 * sin(UV.y * 9.5 - t * 1.85 + UV.x * 12.0);
	float shimmer = mix(1.0, (streak_a * 0.48 + streak_b * 0.32 + dust_drift * 0.20), shimmer_strength);

	// Smooth camera proximity fade so flying through shafts feels soft and atmospheric
	float cam_dist = length(VERTEX);
	float dist_fade = smoothstep(near_fade_min, near_fade_max, cam_dist);

	float beam_mask = fresnel_mask * v_fade * shimmer * dist_fade;
	vec3 final_col = mix(beam_color, core_tint, pow(ndotv, 1.8) * 0.62);

	ALBEDO = final_col * intensity;
	ALPHA = clamp(beam_mask * intensity, 0.0, 1.0);
}
