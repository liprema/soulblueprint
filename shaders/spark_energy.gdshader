shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Spark Jewel-Luminous Liquid-Crystal Shader (Godot 4.3+ Forward+ ACES)
// - High-contrast jewel orchid-rose, royal amethyst, and luminous electric-aqua palette (never yellow)
// - Inner dark-amethyst Fresnel silhouette contour before outer luminous aqua-pearl rim for instant
//   figure-ground separation against bright sunlit skies and white marble floors
// - Animated internal liquid-light caustics & sparkling starlight pinpoints inside the crystal
// - Undulating gossamer silk-wave motion & luminous pearlescent edges on wing-ribbons
// - Soft-shoulder HDR compression so Spark stays luminous and jewel-rich, never washed out or yellow

uniform vec3 base_albedo : source_color = vec3(0.851, 0.275, 0.561);
uniform vec3 shadow_tint : source_color = vec3(0.165, 0.063, 0.322);
uniform vec3 emission_color : source_color = vec3(0.608, 0.267, 0.910);
uniform vec3 rim_color : source_color = vec3(0.361, 0.882, 1.0);
uniform vec3 iridescence_tint : source_color = vec3(0.878, 0.322, 0.627);

uniform float emission_strength : hint_range(0.0, 2.5) = 0.24;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.16;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.10;
uniform float clearcoat_val : hint_range(0.0, 1.0) = 0.96;
uniform float alpha_base : hint_range(0.1, 1.0) = 0.96;
uniform float iridescence_strength : hint_range(0.0, 2.0) = 1.10;

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

float crystal_hash(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p.zxy, p.yxz + 19.19);
	return fract(p.x * p.y * p.z);
}

float crystal_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float n000 = crystal_hash(i + vec3(0.0, 0.0, 0.0));
	float n100 = crystal_hash(i + vec3(1.0, 0.0, 0.0));
	float n010 = crystal_hash(i + vec3(0.0, 1.0, 0.0));
	float n110 = crystal_hash(i + vec3(1.0, 1.0, 0.0));
	float n001 = crystal_hash(i + vec3(0.0, 0.0, 1.0));
	float n101 = crystal_hash(i + vec3(1.0, 0.0, 1.0));
	float n011 = crystal_hash(i + vec3(0.0, 1.0, 1.0));
	float n111 = crystal_hash(i + vec3(1.0, 1.0, 1.0));

	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);

	return mix(mix(nx00, nx10, f.y), mix(nx01, nx11, f.y), f.z);
}

// Prismatic jewel-crystal thin-film color shift:
// Jewel orchid-rose -> royal amethyst -> electric sky-aqua -> sakura-pearl
vec3 jewel_crystal_iridescence(float phase) {
	vec3 jewel_rose = vec3(0.88, 0.28, 0.58);
	vec3 royal_amethyst = vec3(0.61, 0.27, 0.91);
	vec3 electric_aqua = vec3(0.32, 0.86, 1.0);
	vec3 sakura_pearl = vec3(0.95, 0.54, 0.78);

	float p = fract(phase);
	if (p < 0.25) {
		return mix(jewel_rose, royal_amethyst, smoothstep(0.0, 0.25, p));
	} else if (p < 0.50) {
		return mix(royal_amethyst, electric_aqua, smoothstep(0.25, 0.50, p));
	} else if (p < 0.75) {
		return mix(electric_aqua, sakura_pearl, smoothstep(0.50, 0.75, p));
	}
	return mix(sakura_pearl, jewel_rose, smoothstep(0.75, 1.0, p));
}

void vertex() {
	v_local_y = VERTEX.y;
	v_local_normal = NORMAL;
	v_local_pos = VERTEX;

	float speed_norm = clamp(flight_speed / 26.0, 0.0, 1.35);
	float radial_x = abs(VERTEX.x);

	// Ribbon span (0 at shoulder root -> 1 at gossamer tip) & edge mask (0 center -> 1 outer edge)
	float span_from_pos = smoothstep(0.09, 0.84, radial_x);
	float span_mask = mix(span_from_pos, clamp(UV.x, 0.0, 1.0), is_wing_ribbon * 0.75);
	v_ribbon_span = span_mask * is_wing_ribbon;
	v_ribbon_edge = abs(UV.y * 2.0 - 1.0) * is_wing_ribbon;

	if (sway_scale > 0.001) {
		if (is_wing_ribbon > 0.5) {
			// Undulating silk-wave motion along gossamer wing-ribbons
			float t_wing = TIME * (2.5 + speed_norm * 4.4);
			float anchor = smoothstep(0.04, 0.95, span_mask);
			float wave_phase = t_wing - span_mask * 5.6 + VERTEX.z * 2.4 + VERTEX.y * 1.6;

			float wave_y = sin(wave_phase) * (0.026 + 0.052 * speed_norm + 0.022 * energy_flare);
			float wave_x = cos(wave_phase * 0.85 + 0.9) * (0.012 + 0.024 * speed_norm);
			float wave_z = sin(wave_phase * 1.18 + 0.5) * (0.018 + 0.032 * speed_norm);
			// Aerodynamic trailing sweep-back (+Z in Godot -Z forward space)
			float drag_z = (0.06 + 0.16 * speed_norm) * anchor * anchor;

			VERTEX.x += wave_x * anchor * sway_scale * sign(VERTEX.x);
			VERTEX.y += wave_y * anchor * sway_scale;
			VERTEX.z += (wave_z * anchor + drag_z) * sway_scale;
		} else if (is_droplet > 0.5) {
			// Gentle buoyant levitation drift on orbiting crystal droplets
			float d_phase = TIME * (2.2 + speed_norm * 1.4) + VERTEX.y * 6.5 + VERTEX.x * 8.0;
			VERTEX.y += sin(d_phase) * 0.014 * sway_scale;
			VERTEX.x += cos(d_phase * 0.78) * 0.008 * sway_scale;
			VERTEX.z += (sin(d_phase * 0.65) * 0.008 + speed_norm * 0.045) * sway_scale;
		} else {
			// Spiraled liquid-crystal lower tail-gown gentle hover sway & flight trail
			float tail_mask = smoothstep(0.68, 0.04, VERTEX.y);
			float t_body = TIME * (2.6 + speed_norm * 2.2);
			float spiral_wave = sin(t_body - VERTEX.y * 5.2 + VERTEX.x * 3.0);
			VERTEX.x += spiral_wave * (0.014 + 0.012 * speed_norm) * tail_mask * sway_scale;
			VERTEX.z += (cos(t_body * 0.82 - VERTEX.y * 4.0) * 0.012 + speed_norm * 0.085) * tail_mask * sway_scale;
		}
	}
}

void fragment() {
	vec3 n_view = normalize(NORMAL);
	vec3 v_view = normalize(VIEW);
	float ndotv = clamp(dot(n_view, v_view), 0.0, 1.0);
	float fresnel_soft = pow(1.0 - ndotv, 2.2);
	float fresnel_crisp = pow(1.0 - ndotv, 4.2);
	float speed_norm = clamp(flight_speed / 26.0, 0.0, 1.35);

	// 1. Prismatic Jewel-Crystal Fresnel Iridescence
	float film_phase = (1.0 - ndotv) * 0.72
		+ v_local_y * 0.24
		+ v_ribbon_span * 0.36
		+ TIME * 0.075;
	vec3 jewel_irid = jewel_crystal_iridescence(film_phase);
	vec3 iridescent_blend = mix(jewel_irid, iridescence_tint, 0.28);

	// 2. Sculptural liquid-glass crevice depth + crisp inner dark-amethyst silhouette contour
	// The inner contour band peaks right inside the outer Fresnel rim, giving crystal thickness
	// and immediate figure-ground separation against bright sunlit sky and white marble.
	float up_bias = clamp(normalize(v_local_normal).y * 0.5 + 0.5, 0.0, 1.0);
	float crevice = (1.0 - smoothstep(0.08, 0.78, up_bias)) * 0.42;
	float inner_contour = smoothstep(0.64, 0.26, ndotv) * smoothstep(0.05, 0.24, ndotv);
	float contour_strength = inner_contour * mix(0.66, 0.44, is_wing_ribbon) * (1.0 - is_droplet * 0.35);

	vec3 glass_body_col = mix(base_albedo, shadow_tint * 1.15, crevice);
	// Blend jewel iridescence on lit faces, then carve the deep velvety indigo-amethyst contour
	vec3 opalescent_albedo = mix(
		glass_body_col,
		iridescent_blend,
		clamp((0.20 + fresnel_soft * 0.44) * iridescence_strength, 0.0, 0.72)
	);
	opalescent_albedo = mix(opalescent_albedo, shadow_tint * 0.78, contour_strength);

	// 3. Animated Internal Liquid-Light Caustics & Sparkling Starlight Pinpoints
	float swirl_t = TIME * (1.15 + speed_norm * 1.45);
	float cs = cos(swirl_t * 0.28 + v_local_y * 2.2);
	float sn = sin(swirl_t * 0.28 + v_local_y * 2.2);
	vec3 parallax_p = v_local_pos - v_local_normal * (0.045 * (1.0 - ndotv));
	vec3 caustic_p = vec3(
		parallax_p.x * cs - parallax_p.z * sn,
		parallax_p.y - swirl_t * 0.28,
		parallax_p.x * sn + parallax_p.z * cs
	);

	float c_wave_a = crystal_noise(caustic_p * 7.5);
	float c_wave_b = crystal_noise(caustic_p * 13.0 + vec3(3.7, -TIME * 0.65, 5.9));
	float caustic_ridge = 1.0 - abs((c_wave_a * 0.6 + c_wave_b * 0.4) * 2.0 - 1.0);
	float liquid_caustic = pow(clamp(caustic_ridge, 0.0, 1.0), 4.0);

	float sparkle_grid = crystal_noise(v_local_pos * 26.0 + vec3(0.0, -TIME * 0.45, TIME * 0.32));
	float sparkle_twinkle = 0.5 + 0.5 * sin(TIME * 4.8 + sparkle_grid * 28.0 + v_local_y * 9.0);
	float star_pinpoint = smoothstep(0.75, 0.94, sparkle_grid) * sparkle_twinkle;

	// 4. Wing-ribbon gossamer silk flow & luminous pearlescent edges
	float ribbon_edge_glow = smoothstep(0.42, 0.98, v_ribbon_edge) * is_wing_ribbon;
	float ribbon_tip_glow = smoothstep(0.52, 1.0, v_ribbon_span) * is_wing_ribbon;
	float ribbon_shimmer = (0.5 + 0.5 * sin(v_ribbon_span * 16.0 - swirl_t * 2.6 + c_wave_a * 2.4)) * is_wing_ribbon;

	ALBEDO = opalescent_albedo;
	METALLIC = clamp(metallic_val + fresnel_crisp * 0.14, 0.0, 0.55);
	ROUGHNESS = clamp(roughness_val - liquid_caustic * 0.025 - star_pinpoint * 0.035, 0.06, 0.26);
	SPECULAR = 0.82;
	CLEARCOAT = clearcoat_val;
	CLEARCOAT_ROUGHNESS = 0.06;

	// High-presence translucent liquid-crystal & vibrant gossamer ribbon alpha
	float crystal_alpha = mix(alpha_base, 1.0, clamp(fresnel_soft + inner_contour * 0.45, 0.0, 1.0));
	float ribbon_alpha = clamp(
		mix(alpha_base, alpha_base * 0.68, v_ribbon_span * 0.55)
		+ fresnel_soft * 0.22
		+ ribbon_edge_glow * 0.18,
		0.48, 0.96
	);
	ALPHA = mix(crystal_alpha, ribbon_alpha, is_wing_ribbon);

	// 5. Compose jewel-luminous emission (suppress slightly inside dark-amethyst contour for crisp contrast)
	float contour_emit_damp = 1.0 - contour_strength * 0.55;
	vec3 aqua_pearl = vec3(0.68, 0.95, 1.0);
	vec3 core_emit = mix(emission_color, jewel_irid, 0.36)
		* (emission_strength + energy_flare * 0.14 + is_droplet * 0.08)
		* contour_emit_damp;
	vec3 caustic_emit = mix(rim_color, aqua_pearl, 0.45)
		* (liquid_caustic * 0.18 + star_pinpoint * (0.34 + energy_flare * 0.20));
	vec3 rim_emit = mix(rim_color, jewel_irid, 0.28)
		* (
			fresnel_crisp * 0.48
			+ fresnel_soft * 0.14 * (1.0 - contour_strength * 0.5)
			+ ribbon_edge_glow * 0.26
			+ ribbon_tip_glow * 0.16
			+ ribbon_shimmer * 0.09
			+ energy_flare * fresnel_soft * 0.16
		);

	// Soft-shoulder HDR compression prevents yellow/white blowout while keeping jewel brilliance crisp
	vec3 raw_emit = core_emit + caustic_emit + rim_emit;
	EMISSION = raw_emit / (vec3(1.0) + raw_emit * 0.78);
}

void light() {
	// Jewel liquid-crystal direct lighting (uses uniform clearcoat_val, never CLEARCOAT built-in)
	float ndotl = dot(NORMAL, LIGHT);
	float wrap_ndotl = clamp((ndotl + 0.28) / 1.28, 0.0, 1.0);

	// Rich velvety indigo-amethyst shadow side vs luminous jewel orchid-rose lit side
	vec3 shaded_albedo = mix(ALBEDO * mix(shadow_tint, vec3(0.45, 0.24, 0.68), 0.35), ALBEDO, smoothstep(0.08, 0.76, wrap_ndotl));

	// Backlit liquid-crystal refraction / subsurface transillumination
	vec3 back_dir = normalize(LIGHT + NORMAL * 0.38);
	float backlit = pow(clamp(dot(VIEW, -back_dir), 0.0, 1.0), 3.4);
	vec3 sss_color = mix(emission_color, rim_color, 0.48);
	vec3 sss_contrib = sss_color * (backlit * (0.26 + is_wing_ribbon * 0.26 + is_droplet * 0.16));

	DIFFUSE_LIGHT += (shaded_albedo + sss_contrib) * ATTENUATION * LIGHT_COLOR / PI;

	// Dual-lobe liquid-crystal specular:
	// 1) Broad jewel iridescence satin sheen
	// 2) Razor-sharp aqua-pearl liquid-glass clearcoat glint
	vec3 half_vec = normalize(LIGHT + VIEW);
	float ndoth = clamp(dot(NORMAL, half_vec), 0.0, 1.0);
	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);

	float satin_spec = pow(ndoth, mix(24.0, 64.0, 1.0 - ROUGHNESS)) * 0.30;
	float glass_glint = pow(ndoth, 180.0) * (0.78 + clearcoat_val * 0.46);

	vec3 glint_tint = mix(vec3(0.86, 0.96, 1.0), rim_color, 0.32 * (1.0 - ndotv));
	vec3 satin_tint = mix(emission_color, rim_color, 0.52);

	SPECULAR_LIGHT += (satin_spec * satin_tint + glass_glint * glint_tint) * ATTENUATION * LIGHT_COLOR / PI;
}
