shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

// Spark Hero Luminous Flame Core Shader — calibrated to soul_true_form.png
uniform vec3 core_color : source_color = vec3(1.0, 0.985, 0.86);     // Radiant cream-white heart
uniform vec3 mid_color : source_color = vec3(0.98, 0.85, 0.44);      // Warm golden flame
uniform vec3 rim_color : source_color = vec3(1.0, 0.62, 0.16);       // Luminous amber-gold outer lick
uniform float emission_strength : hint_range(0.5, 5.0) = 2.05;
uniform float flare_intensity : hint_range(0.0, 2.0) = 0.0;
uniform float flicker_speed : hint_range(0.0, 10.0) = 4.2;
uniform float sway_amplitude : hint_range(0.0, 0.25) = 0.032;

varying float v_height;

void vertex() {
	v_height = clamp(VERTEX.y + 0.5, 0.0, 1.5);
	// Gentle organic upward flame sway strongest toward the upper crest
	float sway_mask = smoothstep(0.1, 1.0, v_height);
	float t = TIME * flicker_speed;
	VERTEX.x += sin(t + VERTEX.y * 5.2) * sway_amplitude * sway_mask;
	VERTEX.z += cos(t * 0.85 + VERTEX.y * 4.4) * sway_amplitude * 0.75 * sway_mask;
}

void fragment() {
	float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 1.85);

	float pulse = 0.94 + 0.06 * sin(TIME * flicker_speed * 1.4 - v_height * 6.0);
	vec3 col = mix(core_color, mid_color, smoothstep(0.08, 0.68, fresnel));
	col = mix(col, rim_color, smoothstep(0.55, 0.96, fresnel));

	// Boost core brilliance during wing flaps, surge, or Soul Call
	float energy = (emission_strength + flare_intensity * 1.15) * pulse;
	ALBEDO = col * energy;
}
