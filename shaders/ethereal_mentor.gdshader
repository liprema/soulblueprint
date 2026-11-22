shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, unshaded;

// Ethereal Celestial Mentor Shader (Alatea & Mira)
// Deep celestial indigo silhouette (#041028) contrasted against a razor-clean
// luminous cyan Fresnel rim (#58C4FF -> #B5F0FF), cloth-fold ridge highlights,
// internal drifting starlight motes, and a soft mist fade at the robe hem.

uniform vec3 body_color : source_color = vec3(0.016, 0.063, 0.157);
uniform vec3 rim_color : source_color = vec3(0.345, 0.769, 1.0);
uniform vec3 rim_highlight_color : source_color = vec3(0.71, 0.94, 1.0);
uniform float base_opacity : hint_range(0.0, 1.0) = 0.82;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.4;
uniform float emission_strength : hint_range(0.2, 4.0) = 1.55;
uniform float shimmer_speed : hint_range(0.0, 4.0) = 0.85;
uniform float stardust_intensity : hint_range(0.0, 2.0) = 0.55;
uniform float hem_fade_start : hint_range(-100.0, 100.0) = -100.0;
uniform float hem_fade_end : hint_range(-100.0, 100.0) = -99.0;

varying vec3 v_world_pos;
varying vec3 v_local_pos;
varying vec3 v_world_normal;

float hash31(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p, p.yxz + 19.19);
	return fract((p.x + p.y) * p.z);
}

float starfield_layer(vec3 p, float scale, float t) {
	vec3 sp = p * scale;
	vec3 cell = floor(sp);
	vec3 f = fract(sp) - 0.5;
	float rnd = hash31(cell);
	// Sparse bright celestial motes
	if (rnd < 0.88) {
		return 0.0;
	}
	vec3 jitter = vec3(
		hash31(cell + 1.3) - 0.5,
		hash31(cell + 2.7) - 0.5,
		hash31(cell + 4.1) - 0.5
	) * 0.55;
	float d = length(f - jitter);
	float twinkle = 0.45 + 0.55 * sin(t * (2.2 + rnd * 3.5) + rnd * 62.8318);
	return smoothstep(0.14, 0.015, d) * twinkle;
}

void vertex() {
	v_local_pos = VERTEX;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	float ndotv = clamp(abs(dot(n, v)), 0.0, 1.0);

	// Dual-stage Fresnel: broad luminous aura + razor-clean bright outer silhouette edge
	float fresnel_broad = pow(1.0 - ndotv, fresnel_power);
	float fresnel_sharp = pow(1.0 - ndotv, fresnel_power * 2.15 + 1.4);

	// Subtle fold / ridge curvature highlight (catches drapery creases, hair locks, nose & lips)
	float normal_curv = clamp((length(dFdx(n)) + length(dFdy(n))) * 1.45, 0.0, 1.0);
	float fold_glow = smoothstep(0.08, 0.52, normal_curv) * (0.28 + 0.72 * fresnel_broad);

	// Gentle vertical celestial shimmer wave
	float wave = 0.5 + 0.5 * sin(v_world_pos.y * 1.35 - TIME * shimmer_speed * 1.4 + v_world_pos.x * 0.45);
	float upper_sheen = smoothstep(-0.3, 0.9, v_world_normal.y) * 0.16;

	// Internal drifting stardust motes inside the deep indigo core
	vec3 star_pos = v_world_pos + vec3(0.0, -TIME * shimmer_speed * 0.22, 0.0);
	float stars_a = starfield_layer(star_pos, 3.2, TIME * shimmer_speed);
	float stars_b = starfield_layer(star_pos * 1.35 + vec3(7.1, 3.4, 5.2), 5.6, TIME * shimmer_speed * 1.25);
	float stardust = (stars_a + stars_b * 0.75) * stardust_intensity * (1.0 - fresnel_sharp * 0.45);

	// Compose deep celestial indigo core -> luminous cyan rim -> bright ice-cyan edge
	vec3 core_col = body_color * (0.85 + 0.22 * wave + upper_sheen);
	float rim_mix = clamp(fresnel_broad * 1.08 + fold_glow * 0.42, 0.0, 1.0);
	vec3 col = mix(core_col, rim_color * emission_strength, rim_mix);
	col += rim_highlight_color * (fresnel_sharp * emission_strength * 0.95);
	col += mix(rim_color, rim_highlight_color, 0.65) * stardust * (0.8 + 0.45 * emission_strength);

	// Soft mist fade at the very bottom hem of the robe (controlled via hem_fade_start/end)
	float hem_fade = smoothstep(hem_fade_start, hem_fade_end, v_local_pos.y);

	// Translucent cosmic core that becomes crisply solid along the glowing cyan rim
	float alpha = mix(base_opacity, 0.98, clamp(fresnel_broad * 1.15 + fresnel_sharp * 0.5, 0.0, 1.0));
	alpha *= hem_fade;

	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
