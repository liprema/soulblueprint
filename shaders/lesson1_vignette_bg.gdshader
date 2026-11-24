shader_type canvas_item;

// Pixar / Disney cinematic color-script background shader for Lesson 1 ("Было всё, кроме времени").
// Rich warm key light, cool velvet shadows, soft volumetric god rays, drifting cinematic bokeh,
// horizon bloom, and atmospheric air haze.
// Strictly Apple Silicon / Metal NaN-safe: all pow() guarded with max(..., 0.0001),
// all smoothstep(a, b, x) strictly satisfy a < b, atan() and divisions guarded against zero.

uniform vec4 sky_top : source_color = vec4(0.055, 0.086, 0.165, 1.0);
uniform vec4 sky_mid : source_color = vec4(0.118, 0.165, 0.255, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.188, 0.231, 0.318, 1.0);
uniform vec4 ray_color : source_color = vec4(1.0, 0.875, 0.588, 1.0);

uniform float warmth : hint_range(0.0, 1.0) = 0.0;
uniform vec2 sun_pos = vec2(0.5, 0.36);
uniform float ray_strength : hint_range(0.0, 1.6) = 0.25;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.38;
uniform float grain_strength : hint_range(0.0, 0.08) = 0.012;
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
		p = rot * p * 2.02 + vec2(11.3, 7.1);
		amp *= 0.5;
	}
	return v;
}

float soft_bokeh_disc(vec2 uv_aspect, vec2 center_aspect, float radius) {
	float d = length(uv_aspect - center_aspect);
	float safe_r = max(radius, 0.002);
	float body = 1.0 - smoothstep(safe_r * 0.55, safe_r, d);
	float rim = smoothstep(safe_r * 0.50, safe_r * 0.88, d) * body;
	float core = 1.0 - smoothstep(0.0, safe_r * 0.65, d);
	return body * 0.42 + rim * 0.48 + core * 0.22;
}

void fragment() {
	vec2 uv = UV;
	float aspect = 1.777778;
	vec2 uv_aspect = vec2(uv.x * aspect, uv.y);
	vec2 sun_aspect = vec2(sun_pos.x * aspect, sun_pos.y);

	// 1. Multi-stop Pixar color-script sky gradient (warm key vs. cool velvet shadow)
	float t_upper = smoothstep(0.0, 0.56, uv.y);
	float t_lower = smoothstep(0.42, 1.0, uv.y);
	vec3 col = mix(sky_top.rgb, sky_mid.rgb, t_upper);
	col = mix(col, sky_bottom.rgb, t_lower);

	// Subtle cool velvet lift in upper shadows + warm creamy scatter near the horizon
	float upper_shadow = 1.0 - smoothstep(0.0, 0.45, uv.y);
	vec3 velvet_tint = mix(vec3(0.04, 0.06, 0.16), vec3(0.12, 0.09, 0.18), warmth);
	col = mix(col, max(col, velvet_tint), upper_shadow * 0.18);

	float horizon_band = exp(-pow(max(abs(uv.y - 0.60) * 3.4, 0.0001), 2.0));
	vec3 horizon_col = mix(sky_bottom.rgb * 1.12, ray_color.rgb, 0.48 + warmth * 0.28);
	col += horizon_col * horizon_band * (0.08 + warmth * 0.16 + ray_strength * 0.08);

	// 2. Soft painterly atmospheric air haze & drifting storybook clouds
	float t_slow = TIME * 0.022;
	float haze1 = fbm3(uv * vec2(2.4, 1.65) + vec2(t_slow, -t_slow * 0.35));
	float haze2 = fbm3(uv * vec2(4.4, 2.9) + vec2(-t_slow * 0.65, t_slow * 0.28) + vec2(3.7, 2.1));
	float air_density = clamp((haze1 * 0.62 + haze2 * 0.38 - 0.38) * 1.35, 0.0, 1.0);
	vec3 air_tint = mix(sky_mid.rgb * 1.16 + vec3(0.03, 0.04, 0.06), ray_color.rgb * 0.96, 0.35 + warmth * 0.45);
	col = mix(col, air_tint, air_density * 0.26 * clamp(watercolor_wash + 0.18, 0.0, 1.0));

	// 3. Radial Pixar key-light bloom + delicate volumetric god rays (Metal-safe)
	vec2 delta = uv_aspect - sun_aspect;
	float dist = length(delta);
	vec2 dir = (dist > 0.0001) ? (delta / dist) : vec2(1.0, 0.0);

	float core_glow = pow(max(1.0 - clamp(dist * 1.08, 0.0, 1.0), 0.0001), 2.5);
	float wide_glow = pow(max(1.0 - clamp(dist * 0.46, 0.0, 1.0), 0.0001), 1.65);

	float angle = atan(dir.y, dir.x);
	float ray_a = 0.5 + 0.5 * sin(angle * 6.0 + TIME * 0.11);
	float ray_b = 0.5 + 0.5 * sin(angle * 11.0 - TIME * 0.08 + 1.7);
	float ray_c = 0.5 + 0.5 * sin(angle * 17.0 + TIME * 0.05 + 0.6);
	float ray_pattern = pow(max(ray_a * 0.48 + ray_b * 0.34 + ray_c * 0.18, 0.0001), 1.9);
	float ray_falloff = 1.0 - smoothstep(0.03, 1.38, dist);
	// Soft downward bias so god rays feel like cinema light streaming into the scene
	float downward_bias = 0.65 + 0.35 * smoothstep(-0.35, 0.55, uv.y - sun_pos.y);
	float rays = ray_pattern * ray_falloff * downward_bias * ray_strength;

	vec3 key_light_col = mix(ray_color.rgb, vec3(1.0, 0.92, 0.72), warmth * 0.42);
	float light_gain = clamp(ray_strength + 0.16, 0.0, 1.55);
	col += key_light_col * (core_glow * 0.38 + wide_glow * 0.24 + rays * 0.30) * light_gain;

	// 4. Cozy honey-amber hearth suffusion & warm atmospheric mist near lower center
	float hearth_dist = length((uv - vec2(0.5, 0.64)) * vec2(1.08, 1.05));
	float hearth_mask = pow(max(1.0 - clamp(hearth_dist * 0.88, 0.0, 1.0), 0.0001), 1.75);
	vec3 honey_glow = vec3(1.0, 0.76, 0.38);
	col += honey_glow * (0.22 * warmth * hearth_mask);

	// 5. Warm cinematic floating bokeh circles (Tangled / Up / Soul lens feel)
	float eff_bokeh = clamp(max(bokeh_strength, warmth * 0.20), 0.0, 1.0);
	if (eff_bokeh > 0.005) {
		float b_warm = 0.0;
		float b_soft = 0.0;
		b_warm += soft_bokeh_disc(uv_aspect, vec2(0.20 * aspect + sin(TIME * 0.19) * 0.045, 0.24 + cos(TIME * 0.16) * 0.030), 0.115);
		b_soft += soft_bokeh_disc(uv_aspect, vec2(0.78 * aspect + cos(TIME * 0.15) * 0.050, 0.22 + sin(TIME * 0.20) * 0.032), 0.145);
		b_warm += soft_bokeh_disc(uv_aspect, vec2(0.54 * aspect + sin(TIME * 0.14 + 1.2) * 0.055, 0.38 + cos(TIME * 0.15) * 0.036), 0.088);
		b_soft += soft_bokeh_disc(uv_aspect, vec2(0.14 * aspect + cos(TIME * 0.18 + 2.1) * 0.038, 0.58 + sin(TIME * 0.13) * 0.028), 0.082);
		b_warm += soft_bokeh_disc(uv_aspect, vec2(0.86 * aspect + sin(TIME * 0.17 + 0.8) * 0.042, 0.54 + cos(TIME * 0.16) * 0.030), 0.105);
		b_soft += soft_bokeh_disc(uv_aspect, vec2(0.36 * aspect + cos(TIME * 0.13 + 3.1) * 0.040, 0.18 + sin(TIME * 0.17) * 0.024), 0.068);
		b_warm += soft_bokeh_disc(uv_aspect, vec2(0.66 * aspect + sin(TIME * 0.21 + 2.4) * 0.035, 0.62 + cos(TIME * 0.14) * 0.026), 0.072);
		b_soft += soft_bokeh_disc(uv_aspect, vec2(0.45 * aspect + cos(TIME * 0.12 + 4.2) * 0.048, 0.68 + sin(TIME * 0.15) * 0.025), 0.125);

		vec3 bokeh_gold = mix(vec3(1.0, 0.92, 0.68), ray_color.rgb, 0.35);
		vec3 bokeh_peach = mix(vec3(1.0, 0.84, 0.72), vec3(0.88, 0.97, 0.93), clamp(bokeh_strength * 0.65, 0.0, 0.65));
		col += (bokeh_gold * b_warm * 0.20 + bokeh_peach * b_soft * 0.16) * eff_bokeh;
	}

	// 6. Velvet cinematic vignette (cool midnight indigo in cold scenes, warm plum-umber in cozy scenes)
	vec2 centered = uv - vec2(0.5);
	float vig_dist = length(centered * vec2(1.10, 1.04));
	float vig_mask = smoothstep(0.26, 0.90, vig_dist);
	vec3 vig_tint = mix(vec3(0.028, 0.045, 0.115), vec3(0.115, 0.065, 0.062), warmth * 0.62);
	col = mix(col, mix(col * 0.34, vig_tint, 0.48), vig_mask * vignette_strength);

	// 7. Ultra-fine cinema film grain to keep Apple Silicon Retina gradients silky smooth
	float t_seed = fract(TIME * 11.73) * 100.0;
	float grain = hash12(FRAGCOORD.xy + vec2(t_seed * 13.7, t_seed * 7.9)) - 0.5;
	col += vec3(grain * grain_strength);

	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), 1.0);
}
