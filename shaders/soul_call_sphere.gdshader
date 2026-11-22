shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 rim_color : source_color = vec4(1.0, 0.965, 0.8, 1.0); // #FFF6CC
uniform vec4 core_color : source_color = vec4(0.965, 0.827, 0.420, 1.0); // #F6D36B
uniform float alpha_fade : hint_range(0.0, 1.0) = 1.0;
uniform float fresnel_power : hint_range(0.5, 8.0) = 2.6;
uniform float emission_strength : hint_range(0.5, 8.0) = 2.6;
uniform float ripple_speed : hint_range(0.0, 8.0) = 2.4;
uniform float ripple_density : hint_range(1.0, 24.0) = 10.0;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	// Use abs() so both front and back faces produce a clean Fresnel rim with cull_disabled.
	float ndotv = clamp(abs(dot(n, v)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, fresnel_power);

	// Subtle harmonic resonance shimmer rings traveling along the sphere.
	float wave = sin(local_pos.y * ripple_density - TIME * ripple_speed) * 0.5 + 0.5;
	float shimmer = pow(wave, 3.0) * (0.18 + 0.35 * fresnel);

	// Bright golden-white rim with a soft ethereal golden center.
	vec3 color = mix(core_color.rgb, rim_color.rgb, clamp(fresnel * 1.15 + shimmer * 0.35, 0.0, 1.0));
	float intensity = (0.045 + fresnel * 0.95 + shimmer * 0.22) * alpha_fade;

	ALBEDO = color * emission_strength * alpha_fade;
	ALPHA = clamp(intensity, 0.0, 1.0);
}
