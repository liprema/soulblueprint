shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

// Interdimensional World Portal Vortex Shader for Akasha City Portals
// 100% Apple Silicon Metal safe: zero derivatives (dFdx/dFdy/fwidth),
// zero CLEARCOAT, strictly increasing smoothstep(a, b, x) bounds,
// NaN-safe atan() and pow().

uniform vec3 core_color : source_color = vec3(0.98, 0.94, 0.80);
uniform vec3 mid_color : source_color = vec3(0.30, 0.72, 0.96);
uniform vec3 outer_color : source_color = vec3(0.10, 0.16, 0.38);
uniform float swirl_speed : hint_range(0.0, 3.0) = 0.75;
uniform float glow_strength : hint_range(0.5, 4.0) = 2.2;

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

float fbm_nebula(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	mat2 rot = mat2(vec2(0.80, -0.60), vec2(0.60, 0.80));
	for (int i = 0; i < 4; i++) {
		v += amp * value_noise(p);
		p = rot * p * 2.04 + vec2(1.7, 9.2);
		amp *= 0.5;
	}
	return v;
}

vec2 rotate2d(vec2 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(p.x * c - p.y * s, p.x * s + p.y * c);
}

float star_layer(vec2 uv, float scale, float t, float phase_offset) {
	vec2 scaled = uv * scale;
	vec2 id = floor(scaled);
	vec2 gv = fract(scaled) - 0.5;
	float rnd = hash21(id);
	vec2 jitter = (vec2(rnd, fract(rnd * 37.3)) - 0.5) * 0.52;
	float d = length(gv - jitter);
	float radius = mix(0.06, 0.14, fract(rnd * 19.7));
	float core = 1.0 - smoothstep(0.01, radius, d);
	float halo = 1.0 - smoothstep(0.02, radius * 2.2, d);
	float twinkle = 0.55 + 0.45 * sin(t * (1.4 + rnd * 2.2) + rnd * 6.28318 + phase_offset);
	float density = step(0.68, rnd);
	return (core * 0.85 + halo * 0.30) * twinkle * density;
}

void fragment() {
	vec2 p = UV - vec2(0.5, 0.5);
	float r = length(p);
	float t = TIME * swirl_speed;

	// Guarded polar angle for NaN-free swirl near center
	float angle = atan(p.y, (r > 0.0001) ? p.x : 1.0);
	float center_fade = smoothstep(0.015, 0.12, r);
	float outer_mask = 1.0 - smoothstep(0.38, 0.50, r);

	// Multi-arm swirling cosmic spiral (primary + counter-rotating harmonic)
	float twist = r * 11.5 - t * 1.45;
	float arm_primary = 0.5 + 0.5 * sin(angle * 3.0 + twist);
	float arm_secondary = 0.5 + 0.5 * sin(angle * 5.0 - r * 8.0 + t * 0.95);
	float spiral_raw = arm_primary * 0.68 + arm_secondary * 0.32;
	float spiral = mix(0.55, spiral_raw, center_fade);

	// Swirl-warped layered nebula FBM clouds
	float swirl_angle = t * 0.35 + (0.5 - min(r, 0.5)) * 3.6;
	vec2 nebula_uv_a = rotate2d(p, swirl_angle) * 4.8 + vec2(t * 0.12, -t * 0.09);
	vec2 nebula_uv_b = rotate2d(p, -swirl_angle * 0.65) * 7.2 + vec2(-t * 0.08, t * 0.11);
	float neb_a = fbm_nebula(nebula_uv_a);
	float neb_b = fbm_nebula(nebula_uv_b + vec2(neb_a * 0.75, neb_a * 0.55));
	float nebula = clamp(neb_a * 0.58 + neb_b * 0.42, 0.0, 1.0);

	// Combined vortex energy field
	float vortex_density = clamp(spiral * 0.52 + nebula * 0.48, 0.0, 1.0);
	float vortex_sculpted = pow(max(vortex_density, 0.0001), 1.35);

	// Twinkling micro-starlight sparks across two parallax depth planes
	vec2 star_uv_a = rotate2d(p, t * 0.16) + vec2(0.5, 0.5);
	vec2 star_uv_b = rotate2d(p * 1.15, -t * 0.11) + vec2(0.5, 0.5);
	float stars_a = star_layer(star_uv_a, 8.0, t, 0.0);
	float stars_b = star_layer(star_uv_b, 13.0, t, 2.4);
	float stars = clamp(stars_a + stars_b * 0.75, 0.0, 1.5) * outer_mask;

	// Luminous core + pearlescent inner horizon ring + smooth cosmic rim
	float core_glow = exp(-r * r * 14.5) * (0.90 + 0.10 * sin(t * 2.1));
	float horizon_ring = smoothstep(0.30, 0.39, r) * (1.0 - smoothstep(0.39, 0.47, r));
	float horizon_shimmer = 0.78 + 0.22 * sin(angle * 4.0 - t * 1.8 + nebula * 3.0);
	float pearl_ring = horizon_ring * mix(0.85, horizon_shimmer, center_fade);

	// Soft edge rim vignette into deep cosmic outer_color (opaque, zero sorting bugs)
	vec3 deep_space = mix(outer_color * 0.65, outer_color * 1.25, nebula);
	vec3 mid_nebula = mix(deep_space, mid_color, clamp(vortex_sculpted * 0.92 * outer_mask + 0.15 * outer_mask, 0.0, 1.0));
	vec3 col = mix(mid_nebula, outer_color * 0.55, smoothstep(0.42, 0.50, r));

	// Add luminous core, pearlescent horizon ring, and twinkling starlight sparks
	vec3 pearl_tint = mix(mid_color, core_color, 0.68);
	col = mix(col, core_color, clamp(core_glow * 0.88, 0.0, 1.0));
	col += pearl_tint * pearl_ring * 0.72;
	col += mid_color * vortex_sculpted * outer_mask * 0.28;
	col += mix(core_color, vec3(0.96, 0.98, 1.0), 0.45) * stars * 0.95;

	// Gentle radial energy boost scaled by glow_strength
	float energy_scale = mix(0.55, glow_strength, clamp(outer_mask * 0.85 + pearl_ring * 0.55 + core_glow * 0.50, 0.0, 1.0));
	ALBEDO = col * energy_scale;
}
