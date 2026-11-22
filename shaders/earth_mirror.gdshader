shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;

// Celestial Earth Mirror Portal Shader for the Cathedral of the Astrolabe
// Velvety indigo dormant pool -> luminous swirling dawn portal in satin gold & ethereal cyan

uniform vec3 dormant_color : source_color = vec3(0.05, 0.12, 0.28);
uniform vec3 awakened_color : source_color = vec3(0.32, 0.72, 0.98);
uniform vec3 gold_rim_color : source_color = vec3(0.95, 0.80, 0.42);
uniform float awakened_amount : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_boost : hint_range(0.0, 1.0) = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float star_field(vec2 uv, float scale, float time_offset) {
	vec2 gv = fract(uv * scale) - 0.5;
	vec2 id = floor(uv * scale);
	float rnd = hash21(id);
	vec2 offset = vec2(rnd - 0.5, fract(rnd * 31.7) - 0.5) * 0.58;
	float d = length(gv - offset);
	float size = mix(0.018, 0.055, fract(rnd * 17.3));
	float speck = smoothstep(size, 0.0, d);
	float twinkle = 0.45 + 0.55 * sin(TIME * (1.2 + rnd * 2.4) + rnd * 6.28318 + time_offset);
	float rarity = step(0.68, rnd);
	return speck * twinkle * rarity;
}

void fragment() {
	vec2 centered = UV - vec2(0.5, 0.5);
	float r = length(centered);
	float angle = atan(centered.y, centered.x);

	// Smooth circular boundary falloff for r > 0.48
	float circle_alpha = 1.0 - smoothstep(0.475, 0.498, r);

	// Slow concentric water-like starlight ripples radiating from UV center
	float ripple_speed = mix(0.75, 1.45, awakened_amount);
	float ripple_primary = 0.5 + 0.5 * sin(r * 34.0 - TIME * ripple_speed);
	float ripple_secondary = 0.5 + 0.5 * sin(r * 58.0 - TIME * (ripple_speed * 1.35) + angle * 2.0);
	float ripples = (ripple_primary * 0.68 + ripple_secondary * 0.32) * (1.0 - smoothstep(0.32, 0.49, r));

	// Subtle twinkling star specks across two parallax layers
	float swirl_rot = TIME * mix(0.04, 0.28, awakened_amount);
	float cs = cos(swirl_rot);
	float sn = sin(swirl_rot);
	vec2 rot_uv = mat2(vec2(cs, -sn), vec2(sn, cs)) * centered;
	float stars_a = star_field(rot_uv + vec2(0.5), 11.0, 0.0);
	float stars_b = star_field(centered * 1.15 + vec2(0.5) + vec2(TIME * 0.008, -TIME * 0.006), 19.0, 2.1);
	float stars = clamp(stars_a + stars_b * 0.75, 0.0, 1.0);

	// Luminous swirling dawn vortex in the center when awakened_amount -> 1.0
	float swirl_phase = angle * 3.0 + r * 14.0 - TIME * 1.35;
	float spiral_band = 0.5 + 0.5 * sin(swirl_phase);
	float counter_spiral = 0.5 + 0.5 * sin(angle * 2.0 - r * 10.0 + TIME * 0.95);
	float vortex_pattern = mix(spiral_band, counter_spiral, 0.42);
	float center_glow = exp(-r * r * mix(16.0, 7.5, awakened_amount));
	float dawn_swirl = vortex_pattern * (1.0 - smoothstep(0.08, 0.47, r)) * awakened_amount;

	// Soft Fresnel & radial golden rim
	float ndotv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 2.4);
	float radial_rim = smoothstep(0.35, 0.478, r) * (1.0 - smoothstep(0.478, 0.498, r));
	float rim_factor = clamp(radial_rim * 0.85 + fresnel * 0.32, 0.0, 1.0);

	// Base mirror color blending velvety indigo -> sky cyan -> warm dawn gold
	vec3 deep_pool = mix(dormant_color * 0.75, dormant_color * 1.25, ripples);
	vec3 portal_cyan = mix(awakened_color * 0.78, awakened_color * 1.12, vortex_pattern);
	vec3 dawn_core = mix(portal_cyan, gold_rim_color, clamp(center_glow * 0.72 + dawn_swirl * 0.35, 0.0, 1.0));

	vec3 base_col = mix(deep_pool, dawn_core, awakened_amount);
	base_col += awakened_color * ripples * (0.14 + 0.24 * awakened_amount + 0.22 * pulse_boost);
	base_col += mix(awakened_color, gold_rim_color, 0.55) * stars * (0.55 + 0.65 * awakened_amount + 0.35 * pulse_boost);
	base_col = mix(base_col, gold_rim_color, rim_factor * (0.42 + 0.36 * awakened_amount + 0.25 * pulse_boost));

	// Gentle, poetic emission (never harsh or blinding)
	float emission_gain = mix(0.28, 1.18, awakened_amount) + pulse_boost * 0.45;
	vec3 emission_col = base_col * emission_gain;
	emission_col += gold_rim_color * (radial_rim * (0.28 + 0.45 * awakened_amount) + center_glow * awakened_amount * 0.55);
	emission_col += vec3(0.95, 0.92, 0.78) * stars * (0.35 + 0.45 * awakened_amount);

	ALBEDO = base_col;
	EMISSION = emission_col;
	ROUGHNESS = mix(0.26, 0.14, awakened_amount);
	METALLIC = 0.08;
	SPECULAR = 0.24;
	ALPHA = clamp(circle_alpha * mix(0.92, 0.98, awakened_amount), 0.0, 1.0);
}
