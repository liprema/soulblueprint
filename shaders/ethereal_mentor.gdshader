shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Realistic Lit Celestial Mentor Drapery Shader (Alatea & Mira)
// Sculpted warm beige-ivory woven silk & fine linen drapery receiving real
// Godot 4.3 Forward+ directional sunlight, crisp 3D shadows, SSAO in every
// drapery pleat, subtle crevice darkening, and a restrained warm golden-cream
// Fresnel rim sheen.

uniform vec3 body_color : source_color = vec3(0.894, 0.835, 0.761);
uniform vec3 rim_color : source_color = vec3(0.973, 0.925, 0.863);
uniform vec3 rim_highlight_color : source_color = vec3(1.0, 0.961, 0.898);
uniform float base_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.6;
uniform float emission_strength : hint_range(0.0, 4.0) = 0.16;
uniform float shimmer_speed : hint_range(0.0, 4.0) = 0.55;
uniform float stardust_intensity : hint_range(0.0, 2.0) = 0.14;
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
	// Very sparse warm woven gold-thread glints
	if (rnd < 0.92) {
		return 0.0;
	}
	vec3 jitter = vec3(
		hash31(cell + 1.3) - 0.5,
		hash31(cell + 2.7) - 0.5,
		hash31(cell + 4.1) - 0.5
	) * 0.55;
	float d = length(f - jitter);
	float twinkle = 0.45 + 0.55 * sin(t * (1.8 + rnd * 2.8) + rnd * 62.8318);
	return smoothstep(0.12, 0.015, d) * twinkle;
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

	// Grazing-angle silk sheen Fresnel
	float fresnel_broad = pow(1.0 - ndotv, fresnel_power);
	float fresnel_sharp = pow(1.0 - ndotv, fresnel_power * 2.1 + 1.2);

	// Delicate woven-silk / fine-linen micro-texture in local space
	float weave_u = sin(v_local_pos.x * 160.0 + v_local_pos.z * 160.0);
	float weave_v = sin(v_local_pos.y * 190.0);
	float fine_weave = weave_u * weave_v;
	float micro_sheen = 0.5 + 0.5 * fine_weave;

	// Delicate warm-beige fold AO darkening in deep drapery crevices
	float normal_curv = clamp((length(dFdx(n)) + length(dFdy(n))) * 1.15, 0.0, 1.0);
	float fold_crevice = smoothstep(0.10, 0.62, normal_curv);
	vec3 crevice_tint = mix(vec3(1.0), vec3(0.83, 0.77, 0.70), fold_crevice * 0.58);

	// Soft silk fiber sheen along grazing edges and subtle woven thread variation
	float hem_blend = smoothstep(hem_fade_start, hem_fade_end, v_local_pos.y);
	float opacity_sheen = mix(0.18, 0.11, clamp(base_opacity, 0.0, 1.0));
	vec3 base_fabric = body_color * crevice_tint * (0.975 + 0.035 * micro_sheen);
	vec3 silk_albedo = mix(base_fabric, rim_color, clamp(fresnel_broad * opacity_sheen, 0.0, 0.22));
	// Gentle warm sand-cream hem softening near the floor
	vec3 hem_soft = mix(body_color * 0.94, rim_color * 0.96, 0.35);
	silk_albedo = mix(hem_soft, silk_albedo, mix(0.65, 1.0, hem_blend));

	// Subtle upward sky-bounce warmth on upward-facing drapery planes
	float upper_plane = smoothstep(-0.25, 0.85, wn.y);
	silk_albedo *= (0.97 + 0.04 * upper_plane);

	// Very subtle, tasteful warm golden-cream Fresnel rim in EMISSION (0.06..0.18 range)
	float emit_scale = clamp(emission_strength, 0.0, 0.65);
	float shimmer_wave = 0.92 + 0.08 * sin(v_world_pos.y * 1.25 - TIME * shimmer_speed + v_world_pos.x * 0.35);

	// Restrained woven gold-dust sparkle along sunlit silk folds
	vec3 star_pos = v_world_pos + vec3(0.0, -TIME * shimmer_speed * 0.14, 0.0);
	float stars_a = starfield_layer(star_pos, 3.6, TIME * shimmer_speed);
	float stars_b = starfield_layer(star_pos * 1.3 + vec3(5.3, 2.7, 4.1), 6.2, TIME * shimmer_speed * 1.15);
	float stardust = (stars_a + stars_b * 0.6) * stardust_intensity * (0.35 + 0.65 * fresnel_broad);

	vec3 rim_glow_col = mix(rim_color, rim_highlight_color, fresnel_sharp);
	float rim_factor = fresnel_broad * 0.44 + fresnel_sharp * 0.36;
	vec3 emission_out = rim_glow_col * (rim_factor * emit_scale * shimmer_wave);
	emission_out += body_color * (0.05 * emit_scale);
	emission_out += rim_highlight_color * (stardust * emit_scale * 0.32);

	ALBEDO = silk_albedo;
	ROUGHNESS = clamp(0.48 + (0.5 - micro_sheen) * 0.06 - fresnel_broad * 0.05, 0.36, 0.58);
	METALLIC = 0.04;
	SPECULAR = 0.35;
	AO = clamp(1.0 - fold_crevice * 0.32, 0.66, 1.0);
	EMISSION = emission_out;
}

