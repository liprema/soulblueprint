shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Adorable Spirit Soul Iridescent Aqua-Lavender Shader (Godot 4.3+ Forward+ ACES)
// - Translucent aqua-cyan (#6CE4FF) & orchid-lavender (#B88CFF) spirit body
// - Warm golden-peach (#FFE09E) pulsing inner belly radiance around the heart core
// - Delicate swirling internal starlight sparkles across the body and wisp tail
// - Crisp periwinkle-blue (#3B78E0) inner contour + luminous aqua (#8AE8FF) outer Fresnel rim
//   for instant figure-ground readability against bright sunlit skies and white marble
// - Gentle animated sway on upper flame tufts (y > 1.25), lower wisp tail (y < 0.35),
//   buoyant droplets, and fluttering mini angel wings (is_wing_ribbon)

uniform vec3 base_albedo : source_color = vec3(0.424, 0.894, 1.0);       // #6CE4FF aqua-cyan
uniform vec3 shadow_tint : source_color = vec3(0.231, 0.471, 0.878);     // #3B78E0 periwinkle-blue contour
uniform vec3 emission_color : source_color = vec3(0.722, 0.549, 1.0);    // #B88CFF orchid-lavender
uniform vec3 rim_color : source_color = vec3(0.541, 0.910, 1.0);         // #8AE8FF luminous aqua rim
uniform vec3 iridescence_tint : source_color = vec3(0.722, 0.549, 1.0);  // #B88CFF lavender-pearl shift
uniform vec3 belly_glow_color : source_color = vec3(1.0, 0.878, 0.620);  // #FFE09E warm golden-peach

uniform float emission_strength : hint_range(0.0, 2.5) = 0.28;
uniform float belly_glow_strength : hint_range(0.0, 2.5) = 0.85;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.08;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.12;
uniform float clearcoat_val : hint_range(0.0, 1.0) = 0.94;
uniform float alpha_base : hint_range(0.1, 1.0) = 0.88;
uniform float iridescence_strength : hint_range(0.0, 2.0) = 1.05;

uniform float is_wing_ribbon : hint_range(0.0, 1.0) = 0.0;
uniform float is_droplet : hint_range(0.0, 1.0) = 0.0;

uniform float flight_speed : hint_range(0.0, 40.0) = 0.0;
uniform float energy_flare : hint_range(0.0, 2.5) = 0.0;
uniform float sway_scale : hint_range(0.0, 2.0) = 1.0;

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

// Iridescent aqua-cyan -> periwinkle -> orchid-lavender -> pearl-pink thin-film shift
vec3 spirit_iridescence(float phase) {
	vec3 aqua_cyan = vec3(0.424, 0.894, 1.0);
	vec3 periwinkle = vec3(0.48, 0.72, 1.0);
	vec3 orchid_lav = vec3(0.722, 0.549, 1.0);
	vec3 pearl_rose = vec3(0.96, 0.78, 0.94);

	float p = fract(phase);
	if (p < 0.25) {
		return mix(aqua_cyan, periwinkle, smoothstep(0.0, 0.25, p));
	} else if (p < 0.50) {
		return mix(periwinkle, orchid_lav, smoothstep(0.25, 0.50, p));
	} else if (p < 0.75) {
		return mix(orchid_lav, pearl_rose, smoothstep(0.50, 0.75, p));
	}
	return mix(pearl_rose, aqua_cyan, smoothstep(0.75, 1.0, p));
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
	float ndotv = clamp(dot(n_view, v_view), 0.0, 1.0);
	float fresnel_soft = pow(1.0 - ndotv, 2.0);
	float fresnel_crisp = pow(1.0 - ndotv, 3.8);
	float speed_norm = clamp(flight_speed / 26.0, 0.0, 1.35);

	// 1. Iridescent aqua-cyan & orchid-lavender gradient across silhouette
	// Subtle orchid-lavender tint on the lower tail, outer cheeks, and flame tips (matching concept art)
	float lav_grad = smoothstep(0.75, 0.12, v_local_y) * 0.42
		+ smoothstep(1.32, 1.72, v_local_y) * 0.25
		+ fresnel_soft * 0.35;
	float film_phase = (1.0 - ndotv) * 0.65
		+ v_local_y * 0.22
		+ v_ribbon_span * 0.42
		+ TIME * 0.065;
	vec3 irid_col = mix(spirit_iridescence(film_phase), iridescence_tint, 0.25);

	vec3 spirit_body_col = mix(base_albedo, emission_color, clamp(lav_grad, 0.0, 0.62));
	spirit_body_col = mix(
		spirit_body_col,
		irid_col,
		clamp((0.18 + fresnel_soft * 0.42) * iridescence_strength, 0.0, 0.68)
	);

	// 2. Crisp periwinkle-blue (#3B78E0) inner contour right inside the luminous outer rim
	// Keeps the cute aqua spirit sharply legible against bright skies & white marble!
	float inner_contour = smoothstep(0.60, 0.24, ndotv) * smoothstep(0.05, 0.22, ndotv);
	float contour_strength = inner_contour * mix(0.68, 0.50, is_wing_ribbon) * (1.0 - is_droplet * 0.35);
	spirit_body_col = mix(spirit_body_col, shadow_tint, contour_strength);

	// 3. Warm golden-peach inner belly radiance (#FFE09E) pulsing gently inside the torso (y ≈ 0.56)
	float belly_dist = length((v_local_pos - vec3(0.0, 0.56, 0.0)) * vec3(1.15, 1.35, 1.15));
	float belly_pulse = 0.88 + 0.12 * sin(TIME * 2.4);
	float belly_mask = smoothstep(0.32, 0.04, belly_dist)
		* (1.0 - is_wing_ribbon)
		* (1.0 - is_droplet)
		* (0.35 + 0.65 * ndotv);
	float belly_glow = belly_mask * belly_glow_strength * belly_pulse;
	spirit_body_col = mix(spirit_body_col, belly_glow_color, clamp(belly_glow * 0.42, 0.0, 0.48));

	// 4. Delicate swirling internal starlight & shimmering galaxy wisps across body & tail
	float swirl_t = TIME * (0.95 + speed_norm * 1.25);
	float cs = cos(swirl_t * 0.32 + v_local_y * 2.8);
	float sn = sin(swirl_t * 0.32 + v_local_y * 2.8);
	vec3 parallax_p = v_local_pos - v_local_normal * (0.04 * (1.0 - ndotv));
	vec3 swirl_p = vec3(
		parallax_p.x * cs - parallax_p.z * sn,
		parallax_p.y - swirl_t * 0.24,
		parallax_p.x * sn + parallax_p.z * cs
	);

	float w_a = spirit_noise(swirl_p * 7.2);
	float w_b = spirit_noise(swirl_p * 12.5 + vec3(3.1, -TIME * 0.55, 4.7));
	float wisp_ridge = 1.0 - abs((w_a * 0.6 + w_b * 0.4) * 2.0 - 1.0);
	float swirl_ribbon = pow(clamp(wisp_ridge, 0.0, 1.0), 4.2);

	float star_grid = spirit_noise(v_local_pos * 28.0 + vec3(0.0, -TIME * 0.38, TIME * 0.28));
	float star_twinkle = 0.5 + 0.5 * sin(TIME * 5.2 + star_grid * 30.0 + v_local_y * 10.0);
	float star_pinpoint = smoothstep(0.76, 0.94, star_grid) * star_twinkle;

	// Wing-specific pearlescent edge & tip shimmer
	float wing_edge_glow = smoothstep(0.45, 0.98, v_ribbon_edge) * is_wing_ribbon;
	float wing_tip_glow = smoothstep(0.55, 1.0, v_ribbon_span) * is_wing_ribbon;

	ALBEDO = spirit_body_col;
	METALLIC = clamp(metallic_val + fresnel_crisp * 0.10, 0.0, 0.40);
	ROUGHNESS = clamp(roughness_val - swirl_ribbon * 0.025 - star_pinpoint * 0.03, 0.06, 0.24);
	SPECULAR = 0.85;
	CLEARCOAT = clearcoat_val;
	CLEARCOAT_ROUGHNESS = 0.05;

	// Translucent spirit alpha: slightly clearer in the center of the belly so SparkHeartCore shines through!
	float belly_window = smoothstep(0.26, 0.06, belly_dist) * (1.0 - is_wing_ribbon) * (1.0 - is_droplet) * ndotv;
	float body_alpha = clamp(
		mix(alpha_base - belly_window * 0.20, 0.98, clamp(fresnel_soft + inner_contour * 0.42, 0.0, 1.0)),
		0.58, 0.98
	);
	float wing_alpha = clamp(
		mix(alpha_base, alpha_base * 0.76, v_ribbon_span * 0.45) + fresnel_soft * 0.18 + wing_edge_glow * 0.14,
		0.62, 0.96
	);
	ALPHA = mix(body_alpha, wing_alpha, is_wing_ribbon);

	// 5. Compose luminous emission (soft-shoulder compressed for ACES beauty)
	float contour_damp = 1.0 - contour_strength * 0.62;
	vec3 body_emit = mix(base_albedo, emission_color, 0.35)
		* (emission_strength + energy_flare * 0.16 + is_droplet * 0.12)
		* contour_damp;
	vec3 warm_belly_emit = belly_glow_color * (belly_glow * 0.58);
	vec3 sparkle_emit = mix(rim_color, vec3(1.0, 0.96, 0.88), 0.45)
		* (swirl_ribbon * 0.16 + star_pinpoint * (0.42 + energy_flare * 0.22));
	vec3 rim_emit = mix(rim_color, irid_col, 0.25)
		* (
			fresnel_crisp * 0.56
			+ fresnel_soft * 0.14 * contour_damp
			+ wing_edge_glow * 0.22
			+ wing_tip_glow * 0.18
			+ energy_flare * fresnel_soft * 0.18
		);

	vec3 raw_emit = body_emit + warm_belly_emit + sparkle_emit + rim_emit;
	EMISSION = raw_emit / (vec3(1.0) + raw_emit * 0.72);
}

void light() {
	// Soft Pixar spirit lighting (NEVER use CLEARCOAT built-in inside light() — use uniform clearcoat_val)
	float ndotl = dot(NORMAL, LIGHT);
	float wrap_ndotl = clamp((ndotl + 0.34) / 1.34, 0.0, 1.0);

	// Soft periwinkle-lavender shadow side vs luminous aqua-cyan lit side
	vec3 shaded_albedo = mix(
		ALBEDO * mix(shadow_tint, vec3(0.55, 0.62, 0.95), 0.42),
		ALBEDO,
		smoothstep(0.06, 0.78, wrap_ndotl)
	);

	// Translucent backlit spirit glow
	vec3 back_dir = normalize(LIGHT + NORMAL * 0.42);
	float backlit = pow(clamp(dot(VIEW, -back_dir), 0.0, 1.0), 3.0);
	vec3 sss_color = mix(base_albedo, rim_color, 0.52);
	vec3 sss_contrib = sss_color * (backlit * (0.28 + is_wing_ribbon * 0.24 + is_droplet * 0.18));

	DIFFUSE_LIGHT += (shaded_albedo + sss_contrib) * ATTENUATION * LIGHT_COLOR / PI;

	// Glossy spirit sheen + crisp glassy clearcoat specular glint
	vec3 half_vec = normalize(LIGHT + VIEW);
	float ndoth = clamp(dot(NORMAL, half_vec), 0.0, 1.0);
	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);

	float satin_spec = pow(ndoth, mix(22.0, 56.0, 1.0 - ROUGHNESS)) * 0.28;
	float glass_glint = pow(ndoth, 160.0) * (0.72 + clearcoat_val * 0.48);

	vec3 glint_tint = mix(vec3(0.92, 0.98, 1.0), rim_color, 0.28 * (1.0 - ndotv));
	vec3 satin_tint = mix(base_albedo, rim_color, 0.55);

	SPECULAR_LIGHT += (satin_spec * satin_tint + glass_glint * glint_tint) * ATTENUATION * LIGHT_COLOR / PI;
}
