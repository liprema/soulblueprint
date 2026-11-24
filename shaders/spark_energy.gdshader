shader_type spatial;
render_mode cull_back;

// Vivid Spirit Soul Iridescent Aqua-Lavender Shader (Godot 4.3+ Forward+ ACES, 100% Opaque)
// - Solid porcelain-luminous jewel aqua-turquoise (#16B4E8) & orchid-lavender (#784AE0) spirit body
//   calibrated for ACES Filmic tonemapping so RGB channels never desaturate toward chalky white
// - Warm golden-peach (#FFAE42) pulsing inner belly subsurface/emissive radiance around the heart core
// - Delicate swirling internal starlight sparkles across the body and wisp tail
// - Deep sapphire-periwinkle (#1C4EC4) 3D underside/contour + saturated sky-cyan Fresnel glow
//   for instant figure-ground readability against bright sunlit skies and white marble
// - Gentle animated sway on upper flame tufts (y > 1.25), lower wisp tail (y < 0.35),
//   buoyant droplets, and fluttering mini angel wings (is_wing_ribbon)

uniform vec3 base_albedo : source_color = vec3(0.086, 0.706, 0.910);       // #16B4E8 jewel aqua-turquoise
uniform vec3 shadow_tint : source_color = vec3(0.110, 0.306, 0.769);       // #1C4EC4 deep sapphire-periwinkle shadow
uniform vec3 emission_color : source_color = vec3(0.157, 0.659, 0.941);    // #28A8F0 saturated sky-aqua emission
uniform vec3 rim_color : source_color = vec3(0.220, 0.784, 1.0);           // #38C8FF vivid sky-cyan rim
uniform vec3 iridescence_tint : source_color = vec3(0.471, 0.290, 0.878);  // #784AE0 rich orchid-lavender
uniform vec3 belly_glow_color : source_color = vec3(1.0, 0.682, 0.259);    // #FFAE42 warm golden-peach belly glow
uniform vec3 gold_love_color : source_color = vec3(1.0, 0.831, 0.420);     // #FFD46B Unconditional Love golden radiance

uniform float emission_strength : hint_range(0.0, 2.5) = 0.28;
uniform float belly_glow_strength : hint_range(0.0, 2.5) = 0.78;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.06;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.16;
uniform float clearcoat_val : hint_range(0.0, 1.0) = 0.62;
uniform float alpha_base : hint_range(0.1, 1.0) = 1.0; // Retained for uniform compatibility; shader is 100% opaque
uniform float iridescence_strength : hint_range(0.0, 2.0) = 0.95;

uniform float is_wing_ribbon : hint_range(0.0, 1.0) = 0.0;
uniform float is_droplet : hint_range(0.0, 1.0) = 0.0;

uniform float flight_speed : hint_range(0.0, 40.0) = 0.0;
uniform float energy_flare : hint_range(0.0, 2.5) = 0.0;
uniform float sway_scale : hint_range(0.0, 2.0) = 1.0;
uniform float gold_love_evolution : hint_range(0.0, 1.0) = 0.0;

varying float v_local_y;
varying float v_ribbon_span;
varying float v_ribbon_edge;
varying vec3 v_local_normal;
varying vec3 v_local_pos;

float spirit_hash(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p.zxy, p.yxz + 19.19);
	return fract(p.x * p.y * p.z);
}

float spirit_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float n000 = spirit_hash(i + vec3(0.0, 0.0, 0.0));
	float n100 = spirit_hash(i + vec3(1.0, 0.0, 0.0));
	float n010 = spirit_hash(i + vec3(0.0, 1.0, 0.0));
	float n110 = spirit_hash(i + vec3(1.0, 1.0, 0.0));
	float n001 = spirit_hash(i + vec3(0.0, 0.0, 1.0));
	float n101 = spirit_hash(i + vec3(1.0, 0.0, 1.0));
	float n011 = spirit_hash(i + vec3(0.0, 1.0, 1.0));
	float n111 = spirit_hash(i + vec3(1.0, 1.0, 1.0));

	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);

	return mix(mix(nx00, nx10, f.y), mix(nx01, nx11, f.y), f.z);
}

// Linear-space deeply saturated aqua-turquoise -> sapphire-periwinkle -> orchid-lavender -> rose-violet shift
vec3 spirit_iridescence(float phase) {
	vec3 aqua_cyan = vec3(0.010, 0.460, 0.810);
	vec3 periwinkle = vec3(0.028, 0.195, 0.840);
	vec3 orchid_lav = vec3(0.190, 0.070, 0.740);
	vec3 rose_violet = vec3(0.360, 0.095, 0.690);

	float p = fract(phase);
	if (p < 0.25) {
		return mix(aqua_cyan, periwinkle, smoothstep(0.0, 0.25, p));
	} else if (p < 0.50) {
		return mix(periwinkle, orchid_lav, smoothstep(0.25, 0.50, p));
	} else if (p < 0.75) {
		return mix(orchid_lav, rose_violet, smoothstep(0.50, 0.75, p));
	}
	return mix(rose_violet, aqua_cyan, smoothstep(0.75, 1.0, p));
}

void vertex() {
	v_local_y = VERTEX.y;
	v_local_normal = NORMAL;
	v_local_pos = VERTEX;

	float speed_norm = clamp(flight_speed / 26.0, 0.0, 1.35);
	float radial_x = abs(VERTEX.x);

	// Wing span (0 at inner scroll base -> 1 at outer feather tip) & edge mask
	float span_from_pos = smoothstep(0.40, 0.72, radial_x);
	float span_mask = mix(span_from_pos, clamp(UV.x, 0.0, 1.0), is_wing_ribbon * 0.80);
	v_ribbon_span = span_mask * is_wing_ribbon;
	v_ribbon_edge = abs(UV.y * 2.0 - 1.0) * is_wing_ribbon;

	if (sway_scale > 0.001) {
		if (is_wing_ribbon > 0.5) {
			// Cute rapid angelic mini-wing flutter in idle & flight
			float flutter_freq = 6.2 + speed_norm * 7.5 + energy_flare * 4.5;
			float anchor = smoothstep(0.05, 0.95, span_mask);
			float flap_phase = TIME * flutter_freq - span_mask * 2.1;

			float flap_y = sin(flap_phase) * (0.022 + 0.036 * speed_norm + 0.030 * energy_flare);
			float flap_z = cos(flap_phase) * (0.018 + 0.028 * speed_norm + 0.024 * energy_flare);
			float sweep_z = (0.025 + 0.085 * speed_norm) * anchor * anchor;

			VERTEX.y += flap_y * anchor * sway_scale;
			VERTEX.z += (flap_z * anchor + sweep_z) * sway_scale;
		} else if (is_droplet > 0.5) {
			// Gentle buoyant levitation drift on floating crown & tail droplets
			float d_phase = TIME * (2.6 + speed_norm * 1.6) + VERTEX.y * 5.8 + VERTEX.x * 7.0;
			VERTEX.y += sin(d_phase) * 0.016 * sway_scale;
			VERTEX.x += cos(d_phase * 0.82) * 0.010 * sway_scale;
			VERTEX.z += (sin(d_phase * 0.70) * 0.010 + speed_norm * 0.055) * sway_scale;
		} else {
			// 1. Upper flame tufts (y > 1.25): flowing spirit-flame flicker & breeze trail
			float flame_mask = smoothstep(1.24, 1.72, VERTEX.y);
			if (flame_mask > 0.001) {
				float t_flame = TIME * (3.6 + speed_norm * 2.8);
				float f_wave = sin(t_flame - VERTEX.y * 6.5 + VERTEX.x * 4.2);
				float f_wave2 = cos(t_flame * 0.85 - VERTEX.y * 5.0);
				VERTEX.x += f_wave * (0.018 + 0.012 * speed_norm + 0.010 * energy_flare) * flame_mask * sway_scale;
				VERTEX.z += (f_wave2 * 0.014 + speed_norm * 0.095) * flame_mask * sway_scale;
			}

			// 2. Lower wisp tail (y < 0.35): graceful undulating ghost-wisp wave
			float tail_mask = smoothstep(0.36, 0.04, VERTEX.y);
			if (tail_mask > 0.001) {
				float t_tail = TIME * (3.0 + speed_norm * 2.4);
				float tail_wave = sin(t_tail - VERTEX.y * 7.5 + VERTEX.x * 3.0);
				VERTEX.x += tail_wave * (0.020 + 0.014 * speed_norm) * tail_mask * sway_scale;
				VERTEX.z += (cos(t_tail * 0.88 - VERTEX.y * 5.8) * 0.014 + speed_norm * 0.11) * tail_mask * sway_scale;
			}
		}
	}
}

void fragment() {
	vec3 n_view = normalize(NORMAL);
	vec3 v_view = normalize(VIEW);
	float nl_len = length(v_local_normal);
	vec3 n_local = nl_len > 0.0001 ? (v_local_normal / nl_len) : vec3(0.0, 1.0, 0.0);
	float ndotv = clamp(dot(n_view, v_view), 0.0, 1.0);
	float one_minus_ndotv = max(1.0 - ndotv, 0.0001);
	float fresnel_soft = pow(one_minus_ndotv, 2.0);
	float fresnel_crisp = pow(one_minus_ndotv, 3.6);
	float speed_norm = clamp(flight_speed / 20.0, 0.0, 1.35);

	// 1. Vibrant jewel aqua-turquoise top/front -> rich orchid-lavender sides/lower tail
	float dome_top = clamp(n_local.y * 0.5 + 0.5, 0.0, 1.0);
	float lav_grad = smoothstep(0.76, 0.12, v_local_y) * 0.46
		+ smoothstep(1.32, 1.72, v_local_y) * 0.26
		+ fresnel_soft * 0.34
		+ (1.0 - dome_top) * 0.18;
	float film_phase = (1.0 - ndotv) * 0.65
		+ v_local_y * 0.22
		+ v_ribbon_span * 0.42
		+ TIME * 0.065;
	vec3 irid_col = mix(spirit_iridescence(film_phase), iridescence_tint, 0.36);

	vec3 spirit_body_col = mix(base_albedo, iridescence_tint, clamp(lav_grad, 0.0, 0.62));
	spirit_body_col = mix(
		spirit_body_col,
		irid_col,
		clamp((0.14 + fresnel_soft * 0.34) * iridescence_strength, 0.0, 0.56)
	);
	// Volumetric 3D deep sapphire-periwinkle underside depth vs saturated sunlit top dome
	vec3 underside_col = mix(spirit_body_col * mix(shadow_tint, vec3(0.08, 0.22, 0.62), 0.45), shadow_tint, 0.38);
	spirit_body_col = mix(underside_col, spirit_body_col * 1.03, smoothstep(0.14, 0.84, dome_top));

	// 2. Deep sapphire-periwinkle inner contour for crisp 3D outline & figure-ground readability
	float inner_contour = smoothstep(0.54, 0.20, ndotv) * smoothstep(0.04, 0.18, ndotv);
	float contour_strength = inner_contour * mix(0.58, 0.44, is_wing_ribbon) * (1.0 - is_droplet * 0.35);
	spirit_body_col = mix(spirit_body_col, shadow_tint, contour_strength);

	// 3. Warm golden-peach inner belly radiance (#FFAE42) expanding into Unconditional Love gold (#FFD46B)
	float gold_evol = clamp(gold_love_evolution, 0.0, 1.0);
	float belly_dist = length((v_local_pos - vec3(0.0, 0.58, 0.0)) * vec3(1.08, 1.24, 1.08));
	float belly_pulse = 0.90 + 0.10 * sin(TIME * 2.4);
	float belly_radius = mix(0.36, 0.56, gold_evol);
	float belly_mask = smoothstep(belly_radius, 0.03, belly_dist)
		* (1.0 - is_wing_ribbon)
		* (1.0 - is_droplet)
		* (0.40 + 0.60 * ndotv);
	float belly_glow = belly_mask * (belly_glow_strength + gold_evol * 0.62) * belly_pulse;
	vec3 heart_radiance_col = mix(belly_glow_color, gold_love_color, gold_evol * 0.78);
	spirit_body_col = mix(spirit_body_col, heart_radiance_col, clamp(belly_glow * mix(0.62, 0.78, gold_evol), 0.0, 0.76));

	// 4. Delicate swirling internal starlight & shimmering galaxy wisps across body & tail
	float swirl_t = TIME * (0.95 + speed_norm * 1.25);
	float cs = cos(swirl_t * 0.32 + v_local_y * 2.8);
	float sn = sin(swirl_t * 0.32 + v_local_y * 2.8);
	vec3 parallax_p = v_local_pos - n_local * (0.04 * (1.0 - ndotv));
	vec3 swirl_p = vec3(
		parallax_p.x * cs - parallax_p.z * sn,
		parallax_p.y - swirl_t * 0.24,
		parallax_p.x * sn + parallax_p.z * cs
	);

	float w_a = spirit_noise(swirl_p * 7.2);
	float w_b = spirit_noise(swirl_p * 12.5 + vec3(3.1, -TIME * 0.55, 4.7));
	float wisp_ridge = 1.0 - abs((w_a * 0.6 + w_b * 0.4) * 2.0 - 1.0);
	float swirl_ribbon = pow(max(clamp(wisp_ridge, 0.0, 1.0), 0.0001), 4.4);

	float star_grid = spirit_noise(v_local_pos * 28.0 + vec3(0.0, -TIME * 0.38, TIME * 0.28));
	float star_twinkle = 0.5 + 0.5 * sin(TIME * 5.2 + star_grid * 30.0 + v_local_y * 10.0);
	float star_pinpoint = smoothstep(0.78, 0.95, star_grid) * star_twinkle;

	// Wing-specific iridescent edge & tip shimmer + delicate golden pearlescent sheen on evolution
	float wing_edge_glow = smoothstep(0.45, 0.98, v_ribbon_edge) * is_wing_ribbon;
	float wing_tip_glow = smoothstep(0.55, 1.0, v_ribbon_span) * is_wing_ribbon;
	float gold_pearl_sheen = gold_evol * (fresnel_soft * 0.36 + wing_edge_glow * 0.32 + wing_tip_glow * 0.38);
	spirit_body_col = mix(spirit_body_col, gold_love_color, clamp(gold_pearl_sheen * 0.42, 0.0, 0.38));

	ALBEDO = spirit_body_col;
	METALLIC = clamp(metallic_val + fresnel_crisp * 0.06 + gold_evol * 0.04, 0.0, 0.28);
	ROUGHNESS = clamp(roughness_val - swirl_ribbon * 0.02 - star_pinpoint * 0.025, 0.10, 0.28);
	SPECULAR = 0.42;
	CLEARCOAT = clearcoat_val;
	CLEARCOAT_ROUGHNESS = 0.12;

	// 5. Saturated, ACES-safe magical self-emission on 100% solid opaque porcelain-luminous body (no ALPHA write!)
	float contour_damp = 1.0 - contour_strength * 0.58;
	float dome_emit_mod = mix(0.72, 1.06, smoothstep(0.08, 0.88, dome_top));
	vec3 body_emit = mix(base_albedo, emission_color, 0.48)
		* (emission_strength + energy_flare * 0.14 + is_droplet * 0.08)
		* contour_damp
		* dome_emit_mod;
	vec3 warm_belly_emit = heart_radiance_col * (belly_glow * mix(0.72, 1.08, gold_evol));
	vec3 sparkle_emit = mix(rim_color, heart_radiance_col, mix(0.34, 0.72, gold_evol))
		* (swirl_ribbon * (0.14 + gold_evol * 0.08) + star_pinpoint * (0.34 + energy_flare * 0.18 + gold_evol * 0.16));
	// Saturated sky-cyan & periwinkle-blue Fresnel glow with golden pearlescent halo on evolution
	vec3 fresnel_glow_tint = mix(rim_color, mix(shadow_tint, iridescence_tint, 0.50), 0.34);
	fresnel_glow_tint = mix(fresnel_glow_tint, gold_love_color, gold_evol * (0.42 + is_wing_ribbon * 0.28));
	vec3 rim_emit = fresnel_glow_tint
		* (
			fresnel_crisp * (0.38 + gold_evol * 0.16)
			+ fresnel_soft * (0.12 + gold_evol * 0.10) * contour_damp
			+ wing_edge_glow * (0.18 + gold_evol * 0.14)
			+ wing_tip_glow * (0.16 + gold_evol * 0.14)
			+ energy_flare * fresnel_soft * 0.14
		);

	vec3 raw_emit = body_emit + warm_belly_emit + sparkle_emit + rim_emit;
	EMISSION = raw_emit / (vec3(1.0) + raw_emit * 1.15);
}

void light() {
	// Saturated volumetric 3D spirit lighting (NEVER use CLEARCOAT built-in inside light() — use uniform clearcoat_val)
	float ndotl = dot(NORMAL, LIGHT);
	float wrap_ndotl = clamp((ndotl + 0.24) / 1.24, 0.0, 1.0);

	// Deep sapphire-periwinkle 3D core-shadow vs vibrant jewel aqua-cyan sunlit top/front
	vec3 core_shadow = ALBEDO * mix(shadow_tint, vec3(0.12, 0.24, 0.64), 0.36);
	vec3 sunlit_albedo = ALBEDO * 1.02;
	vec3 shaded_albedo = mix(core_shadow, sunlit_albedo, smoothstep(0.06, 0.82, wrap_ndotl));

	// Warm backlit porcelain-luminous subsurface sheen (saturated aqua-cyan, no white washout)
	vec3 back_dir = normalize(LIGHT + NORMAL * 0.42);
	float backlit = pow(max(clamp(dot(VIEW, -back_dir), 0.0, 1.0), 0.0001), 3.0);
	vec3 sss_color = mix(base_albedo, rim_color, 0.45);
	vec3 sss_contrib = sss_color * (backlit * (0.22 + is_wing_ribbon * 0.18 + is_droplet * 0.14));

	DIFFUSE_LIGHT += (shaded_albedo + sss_contrib) * ATTENUATION * LIGHT_COLOR / PI;

	// Soft tinted aqua-cyan spirit sheen & glassy clearcoat glint (avoids white face bleach under ACES)
	vec3 half_raw = LIGHT + VIEW;
	float half_len = length(half_raw);
	vec3 half_vec = half_len > 0.0001 ? (half_raw / half_len) : NORMAL;
	float ndoth = max(clamp(dot(NORMAL, half_vec), 0.0, 1.0), 0.0001);
	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);

	float satin_spec = pow(ndoth, mix(24.0, 56.0, 1.0 - ROUGHNESS)) * 0.18;
	float glass_glint = pow(ndoth, 130.0) * (0.26 + clearcoat_val * 0.24);

	vec3 glint_tint = mix(base_albedo, rim_color, 0.62 + 0.22 * (1.0 - ndotv));
	vec3 satin_tint = mix(base_albedo, rim_color, 0.45);

	SPECULAR_LIGHT += (satin_spec * satin_tint + glass_glint * glint_tint) * ATTENUATION * LIGHT_COLOR / PI;
}
