shader_type spatial;
render_mode cull_disabled, unshaded, blend_mix, depth_draw_opaque;

// Pixar-Style Animated Cascade Waterfall Shader (Godot 4.3+ Forward+, Apple Silicon Metal Safe)
// - ZERO dFdx/dFdy, ZERO CLEARCOAT, all pow() guarded with max(..., 0.0001)
// - All smoothstep(a, b, x) strictly satisfy a < b
// - Pure procedural 2D value noise (zero external textures)
// - Multi-layered rushing turquoise currents, sunlit crest spillover (UV.y < 0.14),
//   boiling plunge foam (UV.y > 0.80), and organic lateral rock-blending fade (UV.x)

group_uniforms waterfall_colors;
uniform vec3 water_top_color : source_color = vec3(0.24, 0.84, 0.90);
uniform vec3 water_deep_color : source_color = vec3(0.10, 0.56, 0.78);
uniform vec3 foam_color : source_color = vec3(0.96, 0.99, 1.00);

group_uniforms flow_settings;
uniform float flow_speed : hint_range(0.2, 4.0) = 1.45;
uniform float stream_scale : hint_range(1.0, 12.0) = 4.2;
uniform float foam_intensity : hint_range(0.0, 1.5) = 1.0;
uniform float edge_fade : hint_range(0.02, 0.40) = 0.16;
uniform float water_opacity : hint_range(0.4, 1.0) = 0.92;
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.28;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.53);
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

float fbm2(vec2 p) {
	float v = 0.64 * value_noise(p);
	v += 0.36 * value_noise(p * 2.09 + vec2(7.3, -4.1));
	return v;
}

vec3 safe_normalize(vec3 v, vec3 fallback) {
	float len = length(v);
	return len > 0.0001 ? (v / len) : fallback;
}

void vertex() {
	float t = TIME * flow_speed;
	float side_env = smoothstep(0.0, 0.20, min(UV.x, 1.0 - UV.x));
	float vert_env = smoothstep(0.0, 0.12, UV.y) * (1.0 - smoothstep(0.86, 1.0, UV.y));
	float wave = sin((UV.y * 10.0 - t * 3.2) + sin(UV.x * 7.0) * 0.8);
	vec3 n_dir = safe_normalize(NORMAL, vec3(0.0, 0.0, 1.0));
	VERTEX += n_dir * (wave * 0.022 * side_env * vert_env);
}

void fragment() {
	float t = TIME * flow_speed;
	vec2 uv = UV;

	// Gentle organic domain warp so vertical water streams undulate naturally
	float warp_a = value_noise(vec2(uv.x * (stream_scale * 0.75), uv.y * 2.2 - t * 0.65)) - 0.5;
	float warp_b = value_noise(vec2(uv.x * (stream_scale * 1.4) + 3.7, uv.y * 3.4 - t * 1.10)) - 0.5;
	float x_warped = uv.x + warp_a * 0.055 + warp_b * 0.025;

	// Multi-layered downward-flowing water currents (UV.y - TIME * flow_speed)
	float flow_broad = fbm2(vec2(x_warped * stream_scale, uv.y * 1.65 - t * 0.85));
	float flow_mid = fbm2(vec2(x_warped * (stream_scale * 2.05) + 5.2, uv.y * 2.55 - t * 1.35));
	float flow_fine = value_noise(vec2(x_warped * (stream_scale * 3.85) - 2.4, uv.y * 4.20 - t * 1.95));

	// Vibrant Pixar turquoise-aquamarine gradient from bright crest to deep cascading body
	float depth_mix = clamp(
		smoothstep(0.06, 0.78, uv.y) * 0.72 + (1.0 - flow_broad) * 0.38,
		0.0,
		1.0
	);
	vec3 water_col = mix(water_top_color, water_deep_color, depth_mix);

	// Bright sunlit turquoise ribbons catching the light inside the cascade
	float ribbon_highlight = smoothstep(0.52, 0.84, flow_mid * 0.65 + flow_broad * 0.35);
	vec3 sunlit_aqua = mix(water_top_color, foam_color, 0.38);
	water_col = mix(water_col, sunlit_aqua, ribbon_highlight * 0.45);

	// Crisp aerated white foam streaks racing down the waterfall
	float streak_field = flow_mid * 0.55 + flow_fine * 0.45;
	float cascade_streaks = smoothstep(0.58, 0.84, streak_field) * (0.48 + 0.52 * flow_broad);

	// Soft bright white spillover crest at the very top (UV.y < 0.14)
	float crest_noise = value_noise(vec2(uv.x * (stream_scale * 1.8), uv.y * 4.5 - t * 1.25));
	float crest_limit = clamp(0.14 + (crest_noise - 0.5) * 0.055, 0.07, 0.21);
	float top_crest = 1.0 - smoothstep(0.0, crest_limit, uv.y);
	float top_lip = 1.0 - smoothstep(0.0, 0.065, uv.y);
	float top_tendrils = (1.0 - smoothstep(0.04, 0.26, uv.y)) * smoothstep(0.46, 0.78, flow_mid);
	float top_foam = clamp(top_crest * 0.88 + top_lip * 0.45 + top_tendrils * 0.52, 0.0, 1.0);

	// Lush boiling white foam at the foot / plunge pool (UV.y > 0.80)
	float boil_primary = fbm2(vec2(uv.x * (stream_scale * 1.95), uv.y * 5.2 - t * 1.55));
	float boil_billow = value_noise(vec2(uv.x * (stream_scale * 3.1) + sin(t * 0.85) * 0.25, uv.y * 6.8 - t * 2.15));
	float boil_start = clamp(0.79 + (boil_primary - 0.5) * 0.09, 0.72, 0.86);
	float bottom_foam_core = smoothstep(boil_start, 0.96, uv.y);
	float bottom_puffs = smoothstep(0.66, 0.92, uv.y) * smoothstep(0.40, 0.76, boil_primary * 0.6 + boil_billow * 0.4);
	float bottom_foam = clamp(bottom_foam_core * 1.05 + bottom_puffs * 0.72, 0.0, 1.0);

	// Combine all foam layers with Pixar painterly crispness
	float total_foam = clamp(
		(cascade_streaks * 0.62 + top_foam * 0.95 + bottom_foam * 1.05) * foam_intensity,
		0.0,
		1.0
	);
	float foam_soft = smoothstep(0.08, 0.88, total_foam);

	// Subtle sunlit diamond shimmer across fast water filaments
	float sparkle_raw = value_noise(vec2(x_warped * (stream_scale * 5.4), uv.y * 7.5 - t * 2.45));
	float sparkle = pow(max(sparkle_raw, 0.0001), 5.0) * shimmer_strength * (1.0 - foam_soft * 0.6);

	vec3 final_color = mix(water_col, foam_color, foam_soft);
	final_color += foam_color * sparkle;

	// Soft lateral fade along UV.x so the waterfall hugs cliff rock organically
	float side_dist = min(uv.x, 1.0 - uv.x);
	float edge_jitter = (value_noise(vec2(uv.x * 7.0, uv.y * 4.5 - t * 1.15)) - 0.5) * 0.038;
	float safe_edge_fade = max(edge_fade, 0.02);
	float lateral_alpha = smoothstep(0.0, safe_edge_fade, side_dist + edge_jitter);

	// Subtle feather at extreme top and bottom edges to avoid hard quad seams
	float top_feather = smoothstep(0.0, 0.025, uv.y);
	float bottom_feather = 1.0 - smoothstep(0.95, 1.0, uv.y);
	float body_alpha = clamp(water_opacity + foam_soft * 0.14, 0.0, 1.0);

	ALBEDO = clamp(final_color, vec3(0.0), vec3(1.15));
	ALPHA = clamp(body_alpha * lateral_alpha * top_feather * bottom_feather, 0.0, 1.0);
}
