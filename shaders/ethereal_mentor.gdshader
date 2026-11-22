shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, unshaded;

// Ethereal Celestial Mentor Shader (Alatea & Mira)
// Sculpted translucent alabaster, liquid crystal, and iridescent mother-of-pearl
// silk-organza celestial beings with soft directional sunlight wrap, cool
// pearl-lavender shadow folds, warm sunlit ivory planes, subtle grazing-angle
// nacreous sheen, drifting crystal stardust motes, and a soft mist hem fade.

uniform vec3 body_color : source_color = vec3(0.76, 0.84, 0.92);
uniform vec3 rim_color : source_color = vec3(0.98, 0.93, 0.84);
uniform vec3 rim_highlight_color : source_color = vec3(0.84, 0.95, 1.0);
uniform float base_opacity : hint_range(0.0, 1.0) = 0.90;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.4;
uniform float emission_strength : hint_range(0.2, 4.0) = 0.72;
uniform float shimmer_speed : hint_range(0.0, 4.0) = 0.85;
uniform float stardust_intensity : hint_range(0.0, 2.0) = 0.32;
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
	vec3 wn = normalize(v_world_normal);
	float ndotv = clamp(abs(dot(n, v)), 0.0, 1.0);

	// Dual-stage Fresnel: broad silk-organza aura + crisp crystal outer silhouette edge
	float fresnel_broad = pow(1.0 - ndotv, fresnel_power);
	float fresnel_sharp = pow(1.0 - ndotv, fresnel_power * 2.15 + 1.4);

	// Sculptural directional sunlight wrap against world normal for luminous 3D marble/silk folds
	vec3 sun_dir = normalize(vec3(0.16, 0.34, 0.92));
	float sun_ndotl = dot(wn, sun_dir);
	float sun_wrap = clamp((sun_ndotl + 0.44) / 1.44, 0.0, 1.0);
	float sun_lit = smoothstep(0.08, 0.92, sun_wrap);
	float upper_bounce = smoothstep(-0.35, 0.88, wn.y);

	// Cool pearl-blue-lavender shadow folds -> warm sunlit ivory-pearl lit planes
	vec3 shadow_pearl = body_color * vec3(0.58, 0.63, 0.78);
	vec3 lit_pearl = mix(body_color, vec3(1.0, 0.96, 0.88), 0.38) * (0.94 + 0.10 * upper_bounce);
	vec3 sculpted_core = mix(shadow_pearl, lit_pearl, sun_lit);

	// Subtle fold / ridge curvature highlight (catches drapery creases, hair locks, nose & lips)
	float normal_curv = clamp((length(dFdx(n)) + length(dFdy(n))) * 1.35, 0.0, 1.0);
	float fold_glow = smoothstep(0.08, 0.54, normal_curv) * (0.24 + 0.76 * fresnel_broad);

	// Gentle vertical celestial shimmer wave
	float wave = 0.5 + 0.5 * sin(v_world_pos.y * 1.35 - TIME * shimmer_speed * 1.4 + v_world_pos.x * 0.45);
	sculpted_core *= (0.94 + 0.09 * wave);

	// Subtle mother-of-pearl iridescent sheen along glancing angles:
	// shifts softly between champagne-rose (#FFEBD8), pearl-ivory (#FFF8EC), and sky-aqua (#BCE4FF)
	float irid_phase = 0.5 + 0.5 * sin((1.0 - ndotv) * 4.8 + wn.y * 2.2 + wn.x * 1.6 - TIME * shimmer_speed * 0.45);
	vec3 irid_rose = vec3(1.0, 0.84, 0.69);
	vec3 irid_ivory = vec3(1.0, 0.94, 0.84);
	vec3 irid_aqua = vec3(0.51, 0.78, 1.0);
	vec3 pearl_irid = mix(
		mix(irid_rose, irid_ivory, smoothstep(0.0, 0.55, irid_phase)),
		irid_aqua,
		smoothstep(0.45, 1.0, irid_phase)
	);
	float irid_mask = clamp(fresnel_broad * 0.85 + fold_glow * 0.35, 0.0, 1.0);

	// Internal drifting crystal stardust motes inside the translucent alabaster core
	vec3 star_pos = v_world_pos + vec3(0.0, -TIME * shimmer_speed * 0.22, 0.0);
	float stars_a = starfield_layer(star_pos, 3.2, TIME * shimmer_speed);
	float stars_b = starfield_layer(star_pos * 1.35 + vec3(7.1, 3.4, 5.2), 5.6, TIME * shimmer_speed * 1.25);
	float stardust = (stars_a + stars_b * 0.75) * stardust_intensity * (1.0 - fresnel_sharp * 0.45);

	// Compose sculpted sunlit alabaster core -> mother-of-pearl silk sheen -> luminous crystal rim
	float emit_scale = clamp(emission_strength, 0.2, 2.0);
	vec3 rim_tint = mix(rim_color, pearl_irid, 0.42);
	float rim_mix = clamp(fresnel_broad * 0.78 + fold_glow * 0.32, 0.0, 0.92);
	vec3 col = mix(sculpted_core, rim_tint * (0.62 + emit_scale * 0.48), rim_mix);
	col += pearl_irid * (irid_mask * (0.08 + emit_scale * 0.07));
	col += rim_highlight_color * (fresnel_sharp * emit_scale * 0.52);
	col += mix(rim_color, rim_highlight_color, 0.55) * stardust * (0.42 + 0.38 * emit_scale);

	// Soft-shoulder roll-off keeps luminous alabaster serene without clipping to flat white
	col = col / (vec3(1.0) + col * 0.16);

	// Soft mist fade at the very bottom hem of the robe (controlled via hem_fade_start/end)
	float hem_fade = smoothstep(hem_fade_start, hem_fade_end, v_local_pos.y);

	// Translucent liquid-crystal core that becomes crisply solid along the silk-pearl rim
	float alpha = mix(base_opacity, 0.98, clamp(fresnel_broad * 1.15 + fresnel_sharp * 0.5, 0.0, 1.0));
	alpha *= hem_fade;

	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
