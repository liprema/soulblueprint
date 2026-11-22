shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Spark Celestial Flame & Silk Ribbon Shader (Godot 4.3 Forward+ ACES)
// Sculptural 3D cel-wrap shading with warm honey-caramel shadow tinting and a crisp
// warm-gold Fresnel silhouette rim so head, neck, lotus collar, torso, diamonds,
// and silk ribbons remain unmistakably distinct from every camera angle.

uniform vec3 base_albedo : source_color = vec3(0.949, 0.706, 0.220);
uniform vec3 shadow_tint : source_color = vec3(0.76, 0.34, 0.08);
uniform vec3 emission_color : source_color = vec3(1.0, 0.78, 0.28);
uniform vec3 rim_color : source_color = vec3(1.0, 0.92, 0.62);
uniform float emission_strength : hint_range(0.0, 2.5) = 0.30;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.08;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.42;

uniform float flight_speed : hint_range(0.0, 40.0) = 0.0;
uniform float energy_flare : hint_range(0.0, 2.5) = 0.0;
uniform float sway_scale : hint_range(0.0, 2.0) = 1.0;

varying float v_local_y;
varying float v_ribbon_mask;
varying vec3 v_local_normal;

void vertex() {
	v_local_y = VERTEX.y;
	v_local_normal = NORMAL;

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
	float fresnel = pow(1.0 - ndotv, 3.0);

	// Sculptural hemisphere crevice shading in object space:
	// deepens neck indentation, underside of lotus collar, and ribbon folds with warm honey-caramel
	float up_bias = clamp(normalize(v_local_normal).y * 0.5 + 0.5, 0.0, 1.0);
	float crevice_factor = (1.0 - smoothstep(0.08, 0.78, up_bias)) * 0.42;
	vec3 sculpted_albedo = base_albedo * mix(vec3(1.0), shadow_tint, crevice_factor);

	// Keep interior material colors crisp; add only a whisper of warm rim tint at grazing edges
	ALBEDO = mix(sculpted_albedo, rim_color, fresnel * 0.12);
	METALLIC = metallic_val;
	ROUGHNESS = roughness_val;

	// Gentle living shimmer + controlled emission + crisp warm-gold Fresnel silhouette rim
	float shimmer = 0.96 + 0.04 * sin(TIME * 3.2 - v_local_y * 4.5);
	vec3 core_emit = emission_color * (emission_strength + energy_flare * 0.36);
	vec3 rim_emit = rim_color * (fresnel * 0.42 + v_ribbon_mask * fresnel * 0.10 + energy_flare * fresnel * 0.22);
	EMISSION = (core_emit + rim_emit) * shimmer;
}

void light() {
	// Real 3D directional lighting with soft stylized cel-wrap shading
	float ndotl = dot(NORMAL, LIGHT);
	float wrap_ndotl = clamp((ndotl + 0.25) / 1.25, 0.0, 1.0);
	float cel_band = mix(smoothstep(0.14, 0.64, wrap_ndotl), wrap_ndotl, 0.42);

	// Warm painterly honey-caramel shadow side vs sunlit cream-gold lit side
	vec3 shaded_albedo = mix(ALBEDO * shadow_tint, ALBEDO, cel_band);
	DIFFUSE_LIGHT += shaded_albedo * ATTENUATION * LIGHT_COLOR / PI;

	// Crisp silky specular accent on curved flame head, collar rim, and ribbon folds
	vec3 half_vec = normalize(LIGHT + VIEW);
	float ndoth = clamp(dot(NORMAL, half_vec), 0.0, 1.0);
	float spec_power = mix(14.0, 48.0, 1.0 - ROUGHNESS);
	float spec = pow(ndoth, spec_power) * (0.24 + METALLIC * 0.35);
	SPECULAR_LIGHT += spec * rim_color * ATTENUATION * LIGHT_COLOR / PI;
}
