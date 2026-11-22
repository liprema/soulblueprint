shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Spark Celestial Flame & Silk Ribbon Shader (Godot 4.3 Forward+ ACES)
// Stray-grade magical depth: warm amber-gold subsurface transillumination radiating
// from within the translucent flame body, swirling internal starlight shimmer inside
// the core and silk ribbons, and a delicate crisp warm-ivory Fresnel silhouette rim
// that reads cleanly against both twilight stone and bright golden skies without blowout.

uniform vec3 base_albedo : source_color = vec3(0.949, 0.706, 0.220);
uniform vec3 shadow_tint : source_color = vec3(0.58, 0.26, 0.07);
uniform vec3 emission_color : source_color = vec3(1.0, 0.78, 0.28);
uniform vec3 rim_color : source_color = vec3(1.0, 0.92, 0.62);
uniform float emission_strength : hint_range(0.0, 2.5) = 0.14;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.08;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.48;

uniform float flight_speed : hint_range(0.0, 40.0) = 0.0;
uniform float energy_flare : hint_range(0.0, 2.5) = 0.0;
uniform float sway_scale : hint_range(0.0, 2.0) = 1.0;

varying float v_local_y;
varying float v_ribbon_mask;
varying vec3 v_local_normal;
varying vec3 v_local_pos;

float spark_hash(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p.zxy, p.yxz + 19.19);
	return fract(p.x * p.y * p.z);
}

float spark_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float n000 = spark_hash(i + vec3(0.0, 0.0, 0.0));
	float n100 = spark_hash(i + vec3(1.0, 0.0, 0.0));
	float n010 = spark_hash(i + vec3(0.0, 1.0, 0.0));
	float n110 = spark_hash(i + vec3(1.0, 1.0, 0.0));
	float n001 = spark_hash(i + vec3(0.0, 0.0, 1.0));
	float n101 = spark_hash(i + vec3(1.0, 0.0, 1.0));
	float n011 = spark_hash(i + vec3(0.0, 1.0, 1.0));
	float n111 = spark_hash(i + vec3(1.0, 1.0, 1.0));

	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);

	return mix(mix(nx00, nx10, f.y), mix(nx01, nx11, f.y), f.z);
}

void vertex() {
	v_local_y = VERTEX.y;
	v_local_normal = NORMAL;
	v_local_pos = VERTEX;

	float speed_norm = clamp(flight_speed / 28.0, 0.0, 1.35);
	float t = TIME * (2.6 + speed_norm * 4.2);

	// Zero displacement at neck/collar center (y ~ 0.92, |x| < 0.14).
	// Stronger organic wind-wave ripple along outward flowing ribbons.
	float radial_x = abs(VERTEX.x);
	float ribbon_mask = smoothstep(0.14, 0.76, radial_x) * smoothstep(1.02, 0.74, VERTEX.y);
	v_ribbon_mask = ribbon_mask;

	// Upper flame tip gentle living candle-flame flicker sway
	float flame_tip_mask = smoothstep(1.22, 1.62, VERTEX.y) * (1.0 - smoothstep(0.16, 0.28, radial_x));

	// Lower slender flame tail tip gentle trailing drift
	float tail_tip_mask = smoothstep(0.54, 0.06, VERTEX.y) * (1.0 - smoothstep(0.14, 0.26, radial_x));

	if (sway_scale > 0.001) {
		// Travelling silk wave along ribbon span
		float phase_r = t - radial_x * 6.4 + VERTEX.z * 2.2;
		float wave_y = sin(phase_r) * (0.024 + 0.048 * speed_norm + 0.020 * energy_flare);
		float wave_z = cos(phase_r * 1.25 + 0.7) * (0.016 + 0.036 * speed_norm);
		// Gentle aerodynamic sweep-back (+Z in Godot) as flight speed increases
		float drag_z = speed_norm * 0.14 * ribbon_mask;

		VERTEX.y += wave_y * ribbon_mask * sway_scale;
		VERTEX.z += (wave_z * ribbon_mask + drag_z) * sway_scale;

		// Living upper flame tip curl sway
		float flame_t = TIME * (3.8 + speed_norm * 2.4);
		VERTEX.x += sin(flame_t + VERTEX.y * 5.0) * (0.018 + 0.014 * speed_norm) * flame_tip_mask * sway_scale;
		VERTEX.z += (cos(flame_t * 0.82 + VERTEX.y * 4.2) * 0.012 + speed_norm * 0.055) * flame_tip_mask * sway_scale;

		// Lower tail tip soft hover wave & flight trail-back
		VERTEX.x += sin(flame_t * 0.75 + VERTEX.y * 4.5 + 1.4) * 0.014 * tail_tip_mask * sway_scale;
		VERTEX.z += (cos(flame_t * 0.65) * 0.010 + speed_norm * 0.075) * tail_tip_mask * sway_scale;
	}
}

void fragment() {
	float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel_soft = pow(1.0 - ndotv, 2.35);
	float fresnel_crisp = pow(1.0 - ndotv, 4.1);
	float speed_norm = clamp(flight_speed / 28.0, 0.0, 1.35);

	// Sculptural hemisphere crevice shading in object space:
	// deepens neck indentation, underside of lotus collar, and ribbon folds with warm honey-caramel
	float up_bias = clamp(normalize(v_local_normal).y * 0.5 + 0.5, 0.0, 1.0);
	float crevice_factor = (1.0 - smoothstep(0.08, 0.78, up_bias)) * 0.42;
	vec3 sculpted_albedo = base_albedo * mix(vec3(1.0), shadow_tint, crevice_factor);

	// Soft internal amber-gold subsurface warmth radiating from the core outward
	vec3 amber_sss = mix(shadow_tint, emission_color, 0.64);
	float core_trans = pow(ndotv, 1.35) * (1.0 - v_ribbon_mask * 0.35);
	float thin_trans = clamp(
		v_ribbon_mask * 0.75
		+ smoothstep(1.16, 1.60, v_local_y) * 0.55
		+ smoothstep(0.54, 0.08, v_local_y) * 0.45,
		0.0, 1.0
	);

	// Subtle swirling internal starlight shimmer inside the flame core & silk ribbons
	float swirl_t = TIME * (1.35 + speed_norm * 1.65);
	float swirl_ang = swirl_t + v_local_y * 3.4;
	float cs = cos(swirl_ang * 0.35);
	float sn = sin(swirl_ang * 0.35);
	vec3 swirl_p = vec3(
		v_local_pos.x * cs - v_local_pos.z * sn,
		v_local_pos.y - swirl_t * 0.42,
		v_local_pos.x * sn + v_local_pos.z * cs
	);
	float star_layer_a = spark_noise(swirl_p * 6.8);
	float star_layer_b = spark_noise(swirl_p * 13.5 + vec3(4.7, -TIME * 1.1, 8.2));
	float star_motes = smoothstep(0.68, 0.94, star_layer_a * 0.55 + star_layer_b * 0.45);
	float ribbon_flow = 0.5 + 0.5 * sin(abs(v_local_pos.x) * 14.0 - swirl_t * 2.2 + star_layer_a * 3.0);
	float starlight_mask = (star_motes * (0.55 + core_trans * 0.45) + v_ribbon_mask * ribbon_flow * star_layer_b * 0.45);

	// Delicate warm-ivory rim tint (never flat blown-out white)
	vec3 warm_ivory_rim = mix(rim_color, vec3(1.0, 0.96, 0.84), 0.42);

	ALBEDO = mix(sculpted_albedo, warm_ivory_rim, fresnel_soft * 0.14);
	METALLIC = metallic_val;
	ROUGHNESS = clamp(roughness_val - star_motes * 0.06, 0.22, 0.95);

	// Compose living internal glow + starlight shimmer + crisp warm-ivory silhouette rim
	float shimmer = 0.95 + 0.05 * sin(TIME * 3.2 - v_local_y * 4.5);
	vec3 inner_glow = mix(emission_color, amber_sss, 0.32 * (1.0 - core_trans))
		* (emission_strength + core_trans * 0.06 + thin_trans * 0.04 + energy_flare * 0.18);
	vec3 starlight_emit = warm_ivory_rim * starlight_mask * (0.09 + energy_flare * 0.10);
	vec3 rim_emit = warm_ivory_rim * (
		fresnel_soft * 0.11
		+ fresnel_crisp * 0.18
		+ v_ribbon_mask * fresnel_soft * 0.06
		+ energy_flare * fresnel_soft * 0.10
	);

	// Tight soft-shoulder compression keeps Spark luminous without ever clipping to flat white
	vec3 raw_emit = (inner_glow + starlight_emit + rim_emit) * shimmer;
	EMISSION = raw_emit / (vec3(1.0) + raw_emit * 0.65);
}

void light() {
	// Real 3D directional lighting with soft stylized cel-wrap shading
	float ndotl = dot(NORMAL, LIGHT);
	float wrap_ndotl = clamp((ndotl + 0.28) / 1.28, 0.0, 1.0);
	float cel_band = mix(smoothstep(0.14, 0.64, wrap_ndotl), wrap_ndotl, 0.45);

	// Warm painterly honey-caramel shadow side vs sunlit cream-gold lit side
	vec3 shaded_albedo = mix(ALBEDO * shadow_tint, ALBEDO, cel_band);

	// Soft subsurface scattering wrap along the shadow terminator + backlit transillumination
	float sss_wrap = clamp((ndotl + 0.58) / 1.58, 0.0, 1.0);
	float sss_terminator = smoothstep(0.02, 0.58, sss_wrap) * (1.0 - smoothstep(0.32, 0.92, wrap_ndotl));
	vec3 back_scatter_dir = normalize(LIGHT + NORMAL * 0.42);
	float backlit = pow(clamp(dot(VIEW, -back_scatter_dir), 0.0, 1.0), 3.2);
	vec3 sss_tint = mix(shadow_tint, emission_color, 0.58);
	vec3 sss_contrib = sss_tint * (sss_terminator * 0.18 + backlit * (0.14 + v_ribbon_mask * 0.14));

	DIFFUSE_LIGHT += (shaded_albedo + sss_contrib) * ATTENUATION * LIGHT_COLOR / PI;

	// Crisp silky specular accent on curved flame head, collar rim, and ribbon folds
	vec3 half_vec = normalize(LIGHT + VIEW);
	float ndoth = clamp(dot(NORMAL, half_vec), 0.0, 1.0);
	float spec_power = mix(14.0, 48.0, 1.0 - ROUGHNESS);
	float spec = pow(ndoth, spec_power) * (0.14 + METALLIC * 0.20);
	SPECULAR_LIGHT += spec * rim_color * ATTENUATION * LIGHT_COLOR / PI;
}
