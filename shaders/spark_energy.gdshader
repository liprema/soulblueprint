shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Spark Liquid-Crystal & Iridescent Mother-of-Pearl Shader (Godot 4.3 Forward+ ACES)
// Inspired by translucent liquid-crystal humanoid sculpture (ref_10):
// - Pearlescent crystal-glass surface (low roughness 0.08-0.18, crisp clearcoat sheen)
// - Prismatic Fresnel iridescence shifting smoothly between warm pearl-white,
//   opalescent sakura-blush (#F4A0C8), soft orchid-lilac (#B48AF2), and icy sky-aqua (#9CEBFF)
// - Animated internal liquid-light caustics & sparkling starlight pinpoints inside the crystal
// - Undulating gossamer silk-wave motion & luminous pearlescent edges on wing-ribbons
// - Soft-shoulder HDR compression so Spark stays luminous and opalescent, never yellow or blown-out

uniform vec3 base_albedo : source_color = vec3(0.96, 0.92, 0.96);
uniform vec3 shadow_tint : source_color = vec3(0.54, 0.36, 0.72);
uniform vec3 emission_color : source_color = vec3(0.957, 0.627, 0.784);
uniform vec3 rim_color : source_color = vec3(0.612, 0.922, 1.0);
uniform vec3 iridescence_tint : source_color = vec3(0.706, 0.541, 0.949);

uniform float emission_strength : hint_range(0.0, 2.5) = 0.16;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.12;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.12;
uniform float clearcoat_val : hint_range(0.0, 1.0) = 0.92;
uniform float alpha_base : hint_range(0.1, 1.0) = 0.94;
uniform float iridescence_strength : hint_range(0.0, 2.0) = 1.0;

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

// Prismatic mother-of-pearl thin-film color shift:
// Warm pearl-white -> sakura-blush -> orchid-lilac -> icy sky-aqua
vec3 mother_of_pearl_iridescence(float phase) {
	vec3 pearl_white = vec3(0.985, 0.955, 0.985);
	vec3 sakura_blush = vec3(0.957, 0.627, 0.784);
	vec3 orchid_lilac = vec3(0.706, 0.541, 0.949);
	vec3 sky_aqua = vec3(0.612, 0.922, 1.0);

	float p = fract(phase);
	if (p < 0.25) {
		return mix(pearl_white, sakura_blush, smoothstep(0.0, 0.25, p));
	} else if (p < 0.50) {
		return mix(sakura_blush, orchid_lilac, smoothstep(0.25, 0.50, p));
	} else if (p < 0.75) {
		return mix(orchid_lilac, sky_aqua, smoothstep(0.50, 0.75, p));
	}
	return mix(sky_aqua, pearl_white, smoothstep(0.75, 1.0, p));
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
	float fresnel_crisp = pow(1.0 - ndotv, 4.4);
	float speed_norm = clamp(flight_speed / 26.0, 0.0, 1.35);

	// 1. Prismatic Mother-of-Pearl Fresnel Iridescence
	// Smooth thin-film shift across pearl-white, sakura-blush, orchid-lilac, and sky-aqua
	float film_phase = (1.0 - ndotv) * 0.78
		+ v_local_y * 0.24
		+ v_ribbon_span * 0.32
		+ TIME * 0.075;
	vec3 pearl_irid = mother_of_pearl_iridescence(film_phase);
	vec3 iridescent_blend = mix(pearl_irid, iridescence_tint, 0.22);

	// 2. Sculptural liquid-glass crevice depth (keeps cheekbones, collarbone, gown flutes crisp)
	float up_bias = clamp(normalize(v_local_normal).y * 0.5 + 0.5, 0.0, 1.0);
	float crevice = (1.0 - smoothstep(0.06, 0.76, up_bias)) * 0.34;
	vec3 glass_body_col = mix(base_albedo, base_albedo * shadow_tint, crevice);

	// Blend pearlescent sheen into albedo, stronger near grazing angles
	vec3 opalescent_albedo = mix(glass_body_col, iridescent_blend, clamp((0.18 + fresnel_soft * 0.52) * iridescence_strength, 0.0, 0.78));

	// 3. Animated Internal Liquid-Light Caustics & Sparkling Starlight Pinpoints (ref_10 inspired)
	float swirl_t = TIME * (1.15 + speed_norm * 1.45);
	float cs = cos(swirl_t * 0.28 + v_local_y * 2.2);
	float sn = sin(swirl_t * 0.28 + v_local_y * 2.2);
	// Subtle view-dependent parallax offset gives crystal depth inside the form
	vec3 parallax_p = v_local_pos - v_local_normal * (0.045 * (1.0 - ndotv));
	vec3 caustic_p = vec3(
		parallax_p.x * cs - parallax_p.z * sn,
		parallax_p.y - swirl_t * 0.28,
		parallax_p.x * sn + parallax_p.z * cs
	);

	float c_wave_a = crystal_noise(caustic_p * 7.5);
	float c_wave_b = crystal_noise(caustic_p * 13.0 + vec3(3.7, -TIME * 0.65, 5.9));
	// Sharp liquid-caustic filaments where noise ridges intersect
	float caustic_ridge = 1.0 - abs((c_wave_a * 0.6 + c_wave_b * 0.4) * 2.0 - 1.0);
	float liquid_caustic = pow(clamp(caustic_ridge, 0.0, 1.0), 4.2);

	// Tiny crystalline starlight pinpoints sparkling gently inside the form
	float sparkle_grid = crystal_noise(v_local_pos * 26.0 + vec3(0.0, -TIME * 0.45, TIME * 0.32));
	float sparkle_twinkle = 0.5 + 0.5 * sin(TIME * 4.8 + sparkle_grid * 28.0 + v_local_y * 9.0);
	float star_pinpoint = smoothstep(0.76, 0.94, sparkle_grid) * sparkle_twinkle;

	// 4. Wing-ribbon gossamer silk flow & luminous pearlescent edges
	float ribbon_edge_glow = smoothstep(0.45, 0.98, v_ribbon_edge) * is_wing_ribbon;
	float ribbon_tip_glow = smoothstep(0.55, 1.0, v_ribbon_span) * is_wing_ribbon;
	float ribbon_shimmer = (0.5 + 0.5 * sin(v_ribbon_span * 16.0 - swirl_t * 2.6 + c_wave_a * 2.4)) * is_wing_ribbon;

	ALBEDO = opalescent_albedo;
	METALLIC = clamp(metallic_val + fresnel_crisp * 0.12, 0.0, 0.55);
	ROUGHNESS = clamp(roughness_val - liquid_caustic * 0.03 - star_pinpoint * 0.04, 0.06, 0.28);
	SPECULAR = 0.78;
	CLEARCOAT = clearcoat_val;
	CLEARCOAT_ROUGHNESS = 0.06;

	// Translucent liquid-crystal & gossamer ribbon alpha
	float crystal_alpha = mix(alpha_base, min(1.0, alpha_base + 0.14), fresnel_soft);
	float ribbon_alpha = clamp(
		mix(0.76, 0.44, v_ribbon_span * 0.65)
		+ fresnel_soft * 0.26
		+ ribbon_edge_glow * 0.14,
		0.32, 0.94
	);
	ALPHA = mix(crystal_alpha, ribbon_alpha, is_wing_ribbon);

	// 5. Compose cool opalescent emission (silver-pearl, sakura-rose, orchid-lilac, sky-aqua)
	vec3 silver_pearl = vec3(0.93, 0.97, 1.0);
	vec3 core_emit = mix(emission_color, pearl_irid, 0.42)
		* (emission_strength + energy_flare * 0.12 + is_droplet * 0.06);
	vec3 caustic_emit = mix(rim_color, silver_pearl, 0.52)
		* (liquid_caustic * 0.14 + star_pinpoint * (0.28 + energy_flare * 0.18));
	vec3 rim_emit = mix(rim_color, pearl_irid, 0.48)
		* (
			fresnel_soft * 0.16
			+ fresnel_crisp * 0.28
			+ ribbon_edge_glow * 0.18
			+ ribbon_tip_glow * 0.12
			+ ribbon_shimmer * 0.07
			+ energy_flare * fresnel_soft * 0.12
		);

	// Soft-shoulder HDR compression prevents yellow/white blowout while keeping crystal sparkle crisp
	vec3 raw_emit = core_emit + caustic_emit + rim_emit;
	EMISSION = raw_emit / (vec3(1.0) + raw_emit * 0.72);
}

void light() {
	// Liquid-crystal glass-pearl direct lighting:
	// Soft translucent diffuse wrap + backlit crystal transillumination + dual-lobe specular sheen
	float ndotl = dot(NORMAL, LIGHT);
	float wrap_ndotl = clamp((ndotl + 0.34) / 1.34, 0.0, 1.0);

	// Cool lavender-pearl shadow side vs luminous mother-of-pearl lit side
	vec3 shaded_albedo = mix(ALBEDO * shadow_tint, ALBEDO, smoothstep(0.08, 0.78, wrap_ndotl));

	// Backlit liquid-crystal refraction / subsurface transillumination
	vec3 back_dir = normalize(LIGHT + NORMAL * 0.38);
	float backlit = pow(clamp(dot(VIEW, -back_dir), 0.0, 1.0), 3.6);
	vec3 sss_color = mix(emission_color, rim_color, 0.45);
	vec3 sss_contrib = sss_color * (backlit * (0.22 + is_wing_ribbon * 0.22 + is_droplet * 0.14));

	DIFFUSE_LIGHT += (shaded_albedo + sss_contrib) * ATTENUATION * LIGHT_COLOR / PI;

	// Dual-lobe liquid-crystal specular:
	// 1) Broad pearlescent iridescence sheen
	// 2) Razor-sharp silver-pearl liquid-glass clearcoat glint (ref_10 highlight)
	vec3 half_vec = normalize(LIGHT + VIEW);
	float ndoth = clamp(dot(NORMAL, half_vec), 0.0, 1.0);
	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);

	float satin_spec = pow(ndoth, mix(24.0, 64.0, 1.0 - ROUGHNESS)) * 0.28;
	float glass_glint = pow(ndoth, 180.0) * (0.75 + CLEARCOAT * 0.45);

	vec3 glint_tint = mix(vec3(0.95, 0.98, 1.0), rim_color, 0.22 * (1.0 - ndotv));
	vec3 satin_tint = mix(emission_color, rim_color, 0.55);

	SPECULAR_LIGHT += (satin_spec * satin_tint + glass_glint * glint_tint) * ATTENUATION * LIGHT_COLOR / PI;
}
