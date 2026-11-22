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
	vec2 scaled = uv * scale;
	vec2 gv = fract(scaled) - 0.5;
	vec2 id = floor(scaled);
	float rnd = hash21(id);
	vec2 offset = vec2(rnd - 0.5, fract(rnd * 31.7) - 0.5) * 0.48;
	float d = length(gv - offset);
	float px = max(length(fwidth(scaled)), 0.025);
	float size = mix(0.09, 0.19, fract(rnd * 17.3));
	float speck = smoothstep(size + px * 1.25, size * 0.15, d);
	float aa_fade = 1.0 - smoothstep(0.14, 0.45, px);
	float twinkle = 0.62 + 0.38 * sin(TIME * (0.9 + rnd * 1.4) + rnd * 6.28318 + time_offset);
	float rarity = step(0.72, rnd);
	return speck * twinkle * rarity * aa_fade;
}

void fragment() {
	vec2 centered = UV - vec2(0.5, 0.5);
	float r = length(centered);
	float angle = atan(centered.y, centered.x);
	float r_fw = max(fwidth(r), 0.004);

	// Smooth anti-aliased circular boundary falloff for r > 0.475
	float edge_aa = max(0.024, r_fw * 1.6);
	float circle_alpha = 1.0 - smoothstep(0.496 - edge_aa, 0.498, r);

	// Slow, velvety concentric starlight ripples with distance antialiasing
	float ripple_speed = mix(0.65, 1.25, awakened_amount);
	float ripple_aa = 1.0 - smoothstep(0.012, 0.055, r_fw);
	float ripple_primary = 0.5 + 0.5 * sin(r * 16.0 - TIME * ripple_speed);
	float ripple_secondary = 0.5 + 0.5 * sin(r * 24.0 - TIME * (ripple_speed * 1.25) + angle * 2.0);
	float ripple_raw = ripple_primary * 0.72 + ripple_secondary * 0.28;
	float ripples = mix(0.5, ripple_raw, ripple_aa) * (1.0 - smoothstep(0.30, 0.485, r));

	// Soft bokeh star specks across two low-frequency parallax layers (zero sub-pixel sparkle)
	float swirl_rot = TIME * mix(0.03, 0.18, awakened_amount);
	float cs = cos(swirl_rot);
	float sn = sin(swirl_rot);
	vec2 rot_uv = mat2(vec2(cs, -sn), vec2(sn, cs)) * centered;
	float stars_a = star_field(rot_uv + vec2(0.5), 6.0, 0.0);
	float stars_b = star_field(centered * 1.08 + vec2(0.5) + vec2(TIME * 0.005, -TIME * 0.004), 9.0, 2.1);
	float stars = clamp(stars_a + stars_b * 0.65, 0.0, 1.0) * (1.0 - smoothstep(0.36, 0.48, r));

	// Luminous swirling dawn vortex in the center when awakened_amount -> 1.0
	// Mask out r -> 0 so atan() singularity never pinches or flickers
	float center_mask = smoothstep(0.02, 0.14, r);
	float swirl_phase = angle * 2.0 + r * 9.0 - TIME * 1.15;
	float spiral_band = 0.5 + 0.5 * sin(swirl_phase);
	float counter_spiral = 0.5 + 0.5 * sin(angle * 2.0 - r * 7.0 + TIME * 0.82);
	float vortex_pattern = mix(0.5, mix(spiral_band, counter_spiral, 0.42), center_mask * ripple_aa);
	float center_glow = exp(-r * r * mix(14.0, 6.8, awakened_amount));
	float dawn_swirl = vortex_pattern * (1.0 - smoothstep(0.08, 0.47, r)) * awakened_amount;

	// Soft Fresnel & anti-aliased radial golden rim
	float ndotv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 2.4);
	float radial_rim = smoothstep(0.34, 0.465, r) * (1.0 - smoothstep(0.465, 0.498, r));
	float rim_factor = clamp(radial_rim * 0.80 + fresnel * 0.28, 0.0, 1.0);

	// Base mirror color blending velvety indigo -> sky cyan -> warm dawn gold
	vec3 deep_pool = mix(dormant_color * 0.80, dormant_color * 1.20, ripples);
	vec3 portal_cyan = mix(awakened_color * 0.80, awakened_color * 1.10, vortex_pattern);
	vec3 dawn_core = mix(portal_cyan, gold_rim_color, clamp(center_glow * 0.72 + dawn_swirl * 0.35, 0.0, 1.0));

	vec3 base_col = mix(deep_pool, dawn_core, awakened_amount);
	base_col += awakened_color * ripples * (0.12 + 0.22 * awakened_amount + 0.20 * pulse_boost);
	base_col += mix(awakened_color, gold_rim_color, 0.55) * stars * (0.45 + 0.55 * awakened_amount + 0.30 * pulse_boost);
	base_col = mix(base_col, gold_rim_color, rim_factor * (0.38 + 0.34 * awakened_amount + 0.22 * pulse_boost));

	// Gentle, poetic emission (velvety and shimmer-free)
	float emission_gain = mix(0.24, 1.05, awakened_amount) + pulse_boost * 0.40;
	vec3 emission_col = base_col * emission_gain;
	emission_col += gold_rim_color * (radial_rim * (0.22 + 0.38 * awakened_amount) + center_glow * awakened_amount * 0.50);
	emission_col += vec3(0.95, 0.92, 0.78) * stars * (0.28 + 0.38 * awakened_amount);

	ALBEDO = base_col;
	EMISSION = emission_col;
	ROUGHNESS = mix(0.48, 0.36, awakened_amount);
	METALLIC = 0.0;
	SPECULAR = 0.16;
	ALPHA = clamp(circle_alpha * mix(0.92, 0.98, awakened_amount), 0.0, 1.0);
}
