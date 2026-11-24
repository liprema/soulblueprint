shader_type canvas_item;

// Painterly atmospheric vignette background shader for Lesson 1 ("Было всё, кроме времени").
// Morphs smoothly between 4 emotional states in GRIS + Spiritfarer + Makoto Shinkai aesthetic.
// All pow() and normalize() operations are strictly NaN-safe for Godot 4.3+ Forward+ / macOS Retina.

uniform vec4 sky_top : source_color = vec4(0.055, 0.086, 0.165, 1.0);
uniform vec4 sky_mid : source_color = vec4(0.118, 0.165, 0.255, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.188, 0.231, 0.318, 1.0);
uniform vec4 ray_color : source_color = vec4(1.0, 0.875, 0.588, 1.0);

uniform float warmth : hint_range(0.0, 1.0) = 0.0;
uniform vec2 sun_pos = vec2(0.5, 0.36);
uniform float ray_strength : hint_range(0.0, 1.6) = 0.25;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.38;
uniform float grain_strength : hint_range(0.0, 0.08) = 0.014;
uniform float bokeh_strength : hint_range(0.0, 1.0) = 0.0;
uniform float watercolor_wash : hint_range(0.0, 1.0) = 0.36;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm3(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	mat2 rot = mat2(vec2(0.80, -0.60), vec2(0.60, 0.80));
	for (int i = 0; i < 3; i++) {
		v += amp * value_noise(p);
		p = rot * p * 2.04 + vec2(11.3, 7.1);
		amp *= 0.5;
	}
	return v;
}

float soft_bokeh_disc(vec2 uv_aspect, vec2 center_aspect, float radius) {
	float d = length(uv_aspect - center_aspect);
	float safe_r = max(radius, 0.001);
	float edge = 1.0 - smoothstep(safe_r * 0.62, safe_r, d);
	float rim = smoothstep(safe_r * 0.55, safe_r * 0.88, d) * edge;
	return edge * 0.45 + rim * 0.55;
}

void fragment() {
	vec2 uv = UV;
	float aspect = 1.777778;
	vec2 uv_aspect = vec2(uv.x * aspect, uv.y);
	vec2 sun_aspect = vec2(sun_pos.x * aspect, sun_pos.y);

	// 1. Three-stop painterly sky gradient with soft horizon bloom
	float t_upper = smoothstep(0.0, 0.54, uv.y);
	float t_lower = smoothstep(0.46, 1.0, uv.y);
	vec3 col = mix(sky_top.rgb, sky_mid.rgb, t_upper);
	col = mix(col, sky_bottom.rgb, t_lower);

	// 2. GRIS-style drifting watercolor atmospheric wash
	float t_slow = TIME * 0.028;
	float wash1 = fbm3(uv * vec2(2.6, 1.8) + vec2(t_slow, -t_slow * 0.45));
	float wash2 = fbm3(uv * vec2(4.8, 3.2) + vec2(-t_slow * 0.7, t_slow * 0.35) + vec2(4.2, 1.9));
	float paper_grain = value_noise(uv * vec2(46.0, 28.0));
	float wash_delta = (wash1 * 0.65 + wash2 * 0.35 - 0.5) * watercolor_wash;
	vec3 wash_tint = mix(sky_mid.rgb * 1.18 + vec3(0.02, 0.03, 0.05), ray_color.rgb, warmth * 0.45);
	col = mix(col, wash_tint, clamp(wash_delta * 0.65 + 0.14 * watercolor_wash, 0.0, 0.45));
	col += vec3((paper_grain - 0.5) * 0.018 * watercolor_wash);

	// 3. Radial sun/moon glow + soft volumetric rays (NaN-safe)
	vec2 delta = uv_aspect - sun_aspect;
	float dist = length(delta);
	vec2 dir = (dist > 0.0001) ? (delta / dist) : vec2(1.0, 0.0);

	float core_glow = pow(max(1.0 - clamp(dist * 1.15, 0.0, 1.0), 0.0001), 2.4);
	float wide_glow = pow(max(1.0 - clamp(dist * 0.52, 0.0, 1.0), 0.0001), 1.65);

	float angle = atan(dir.y, dir.x);
	float ray_wave_a = 0.5 + 0.5 * sin(angle * 7.0 + TIME * 0.14);
	float ray_wave_b = 0.5 + 0.5 * sin(angle * 13.0 - TIME * 0.09 + 1.4);
	float ray_pattern = pow(max(ray_wave_a * 0.62 + ray_wave_b * 0.38, 0.0001), 1.8);
	float ray_falloff = 1.0 - smoothstep(0.04, 1.25, dist);
	float rays = ray_pattern * ray_falloff * ray_strength;

	vec3 light_col = mix(ray_color.rgb, vec3(1.0, 0.91, 0.68), warmth * 0.4);
	col += light_col * (core_glow * 0.36 + wide_glow * 0.22 + rays * 0.28) * clamp(ray_strength + 0.15, 0.0, 1.5);

	// 4. Tender amber hearth warmth suffusion
	float hearth_dist = length((uv - vec2(0.5, 0.62)) * vec2(1.15, 1.0));
	float hearth_mask = pow(max(1.0 - clamp(hearth_dist * 0.92, 0.0, 1.0), 0.0001), 1.85);
	vec3 amber_glow = vec3(0.98, 0.72, 0.36);
	col = mix(col, col + amber_glow * 0.24, warmth * hearth_mask);

	// 5. Soft sunlit garden bokeh circles (Chapter 2 Spring 1)
	if (bokeh_strength > 0.001) {
		float b = 0.0;
		b += soft_bokeh_disc(uv_aspect, vec2(0.24 * aspect + sin(TIME * 0.21) * 0.04, 0.26 + cos(TIME * 0.18) * 0.03), 0.11);
		b += soft_bokeh_disc(uv_aspect, vec2(0.76 * aspect + cos(TIME * 0.17) * 0.05, 0.22 + sin(TIME * 0.22) * 0.03), 0.14);
		b += soft_bokeh_disc(uv_aspect, vec2(0.54 * aspect + sin(TIME * 0.15 + 1.2) * 0.06, 0.40 + cos(TIME * 0.16) * 0.04), 0.09);
		b += soft_bokeh_disc(uv_aspect, vec2(0.16 * aspect + cos(TIME * 0.19 + 2.0) * 0.04, 0.56 + sin(TIME * 0.14) * 0.03), 0.08);
		b += soft_bokeh_disc(uv_aspect, vec2(0.84 * aspect + sin(TIME * 0.20 + 0.7) * 0.04, 0.52 + cos(TIME * 0.17) * 0.03), 0.10);
		vec3 bokeh_col = mix(vec3(1.0, 0.95, 0.78), vec3(0.88, 0.98, 0.92), 0.32);
		col += bokeh_col * b * bokeh_strength * 0.24;
	}

	// 6. Soft cinematic vignette
	vec2 centered = uv - vec2(0.5);
	float vig_dist = length(centered * vec2(1.12, 1.04));
	float vig_mask = smoothstep(0.24, 0.88, vig_dist);
	vec3 vig_tint = mix(vec3(0.03, 0.05, 0.11), vec3(0.10, 0.06, 0.05), warmth * 0.45);
	col = mix(col, mix(col * 0.32, vig_tint, 0.45), vig_mask * vignette_strength);

	// 7. Subtle animated film/watercolor grain to eliminate banding
	float t_seed = fract(TIME * 11.73) * 100.0;
	float grain = hash12(FRAGCOORD.xy + vec2(t_seed * 13.7, t_seed * 7.9)) - 0.5;
	col += vec3(grain * grain_strength);

	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), 1.0);
}
