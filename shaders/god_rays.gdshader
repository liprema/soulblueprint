shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

// Golden Volumetric Light Beam / God Rays Shader for the Astrolabe Cathedral
// Approved palette: #F6D36B (Soft Gold)

group_uniforms beam_appearance;
uniform vec3 beam_color : source_color = vec3(0.965, 0.827, 0.420); // #F6D36B Soft Gold
uniform vec3 core_tint : source_color = vec3(1.0, 0.95, 0.78);       // Warm luminous gold-white core
uniform float intensity : hint_range(0.0, 3.0) = 0.55;
uniform float edge_falloff : hint_range(0.5, 6.0) = 2.4;

group_uniforms vertical_fade_and_shimmer;
uniform float top_fade : hint_range(0.01, 0.5) = 0.18;
uniform float bottom_fade : hint_range(0.01, 0.6) = 0.32;
uniform float shimmer_speed : hint_range(0.0, 3.0) = 0.45;
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.32;
uniform float ray_stripe_count : hint_range(1.0, 24.0) = 7.0;

group_uniforms proximity_fade;
uniform float near_fade_min : hint_range(0.5, 15.0) = 2.5;
uniform float near_fade_max : hint_range(2.0, 35.0) = 12.0;

void fragment() {
	// Smooth grazing-angle Fresnel falloff so cone/cylinder edges dissolve cleanly
	float ndotv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float fresnel_mask = pow(ndotv, edge_falloff);

	// Smooth vertical fade at both ends of the light shaft
	float v_fade = smoothstep(0.0, top_fade, UV.y) * smoothstep(1.0, 1.0 - bottom_fade, UV.y);

	// Gentle vertical shimmer & subtle radial light streaks
	float t = TIME * shimmer_speed;
	float streak_a = 0.5 + 0.5 * sin(UV.x * ray_stripe_count * 6.2831853 + t * 0.7 + UV.y * 2.5);
	float streak_b = 0.5 + 0.5 * sin(UV.x * (ray_stripe_count * 1.7) * 6.2831853 - t * 1.15 + UV.y * 4.2);
	float vertical_wave = 0.5 + 0.5 * sin(UV.y * 7.0 - t * 2.2);
	float shimmer = mix(1.0, (streak_a * 0.5 + streak_b * 0.3 + vertical_wave * 0.2), shimmer_strength);

	// Smooth camera proximity fade so flying through beams never pops
	float cam_dist = length(VERTEX);
	float dist_fade = smoothstep(near_fade_min, near_fade_max, cam_dist);

	float beam_mask = fresnel_mask * v_fade * shimmer * dist_fade;
	vec3 final_col = mix(beam_color, core_tint, pow(ndotv, 2.0) * 0.55);

	ALBEDO = final_col * intensity;
	ALPHA = clamp(beam_mask * intensity, 0.0, 1.0);
}
