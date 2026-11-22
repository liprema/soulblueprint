shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

// Expanding Golden Soul Call [Q] Resonance Dome — calibrated to Sanctuary AAA reference
uniform vec4 rim_color : source_color = vec4(1.0, 0.975, 0.84, 1.0);  // Luminous white-gold rim
uniform vec4 core_color : source_color = vec4(0.965, 0.827, 0.420, 1.0); // #F6D36B Soft Gold
uniform float alpha_fade : hint_range(0.0, 1.0) = 1.0;
uniform float fresnel_power : hint_range(0.5, 8.0) = 2.4;
uniform float emission_strength : hint_range(0.5, 8.0) = 2.85;
uniform float ripple_speed : hint_range(0.0, 8.0) = 2.6;
uniform float ripple_density : hint_range(1.0, 24.0) = 11.0;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	// abs() ensures clean Fresnel rim on both inner and outer surfaces with cull_disabled.
	float ndotv = clamp(abs(dot(n, v)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, fresnel_power);
	float outer_edge = pow(1.0 - ndotv, fresnel_power * 2.1);

	// Ascending harmonic resonance waves + luminous equatorial golden band
	float wave = sin(local_pos.y * ripple_density - TIME * ripple_speed) * 0.5 + 0.5;
	float shimmer = pow(wave, 3.2) * (0.16 + 0.40 * fresnel);
	float equator = exp(-abs(local_pos.y) * 9.5) * (0.28 + 0.45 * fresnel);

	// Bright golden-white rim with a soft ethereal golden center
	vec3 color = mix(core_color.rgb, rim_color.rgb, clamp(fresnel * 1.1 + outer_edge * 0.8 + equator * 0.5, 0.0, 1.0));
	float intensity = (0.04 + fresnel * 0.92 + outer_edge * 0.45 + shimmer * 0.24 + equator * 0.35) * alpha_fade;

	ALBEDO = color * emission_strength * alpha_fade;
	ALPHA = clamp(intensity, 0.0, 1.0);
}
