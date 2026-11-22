shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

// Spark Hero Flowing Mantle / Cape Shader with Wind-Wave Ripple & Golden Edge Glow
uniform vec3 base_color : source_color = vec3(0.98, 0.68, 0.20);     // Warm golden-amber cloth
uniform vec3 tip_color : source_color = vec3(1.0, 0.90, 0.52);       // Radiant sunlit gold tips
uniform vec3 edge_glow_color : source_color = vec3(1.0, 0.96, 0.78); // White-gold luminous trim
uniform float wind_speed : hint_range(0.0, 12.0) = 3.2;
uniform float wave_amplitude : hint_range(0.0, 0.35) = 0.085;
uniform float flap_burst : hint_range(0.0, 2.0) = 0.0;
uniform float opacity : hint_range(0.1, 1.0) = 0.92;
uniform float emission_strength : hint_range(0.5, 4.0) = 1.55;

varying vec2 v_uv;
varying float v_tip_factor;

void vertex() {
	v_uv = UV;
	// Greater wind-wave flutter further away from the shoulder pivot
	float dist_from_pivot = clamp(length(VERTEX.xz) * 0.9, 0.0, 1.2);
	v_tip_factor = clamp(dist_from_pivot, 0.0, 1.0);

	float t = TIME * (2.6 + wind_speed * 0.85);
	float wave_a = sin(t - dist_from_pivot * 6.5 + VERTEX.x * 3.0);
	float wave_b = cos(t * 1.35 - dist_from_pivot * 9.0 - VERTEX.z * 2.5);
	float amp = wave_amplitude * (1.0 + wind_speed * 0.08 + flap_burst * 0.55) * v_tip_factor;

	VERTEX.y += (wave_a * 0.7 + wave_b * 0.3) * amp;
	VERTEX.z += wave_b * amp * 0.35;
}

void fragment() {
	float ndotv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 2.1);

	// Subtle luminous edge trim along cape borders and wingtips
	float edge_x = min(v_uv.x, 1.0 - v_uv.x);
	float edge_y = min(v_uv.y, 1.0 - v_uv.y);
	float trim = 1.0 - smoothstep(0.02, 0.14, min(edge_x, edge_y));

	vec3 col = mix(base_color, tip_color, smoothstep(0.15, 0.92, v_tip_factor));
	col = mix(col, edge_glow_color, clamp(trim * 0.65 + fresnel * 0.55 + flap_burst * 0.35, 0.0, 1.0));

	float energy = emission_strength + flap_burst * 0.95 + trim * 0.45;
	ALBEDO = col * energy;
	ALPHA = clamp(opacity * (0.86 + 0.14 * (1.0 - v_tip_factor * 0.4) + trim * 0.14), 0.0, 1.0);
}
