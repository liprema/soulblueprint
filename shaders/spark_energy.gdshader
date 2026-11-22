shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Spark Celestial Flame & Silk Ribbon Shader (Godot 4.3 Forward+ ACES Bloom)
// Preserves per-surface albedo/emission colors from spark.glb while adding
// luminous cream-gold Fresnel rim glow and speed-responsive wind-wave motion.

uniform vec3 base_albedo : source_color = vec3(0.969, 0.788, 0.282);
uniform vec3 emission_color : source_color = vec3(1.0, 0.730, 0.141);
uniform vec3 rim_color : source_color = vec3(1.0, 0.965, 0.80);
uniform float emission_strength : hint_range(0.0, 5.0) = 1.45;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.06;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.22;

uniform float flight_speed : hint_range(0.0, 40.0) = 0.0;
uniform float energy_flare : hint_range(0.0, 2.5) = 0.0;
uniform float sway_scale : hint_range(0.0, 2.0) = 1.0;

varying float v_local_y;
varying float v_ribbon_mask;

void vertex() {
	v_local_y = VERTEX.y;

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
	float fresnel = pow(1.0 - ndotv, 2.15);

	// Soft living celestial shimmer traveling upward
	float shimmer = 0.94 + 0.06 * sin(TIME * 3.6 - v_local_y * 4.8);
	float rim_weight = clamp(fresnel * 0.72 + v_ribbon_mask * 0.16 + energy_flare * 0.25, 0.0, 1.0);

	ALBEDO = mix(base_albedo, rim_color, fresnel * 0.35);
	METALLIC = metallic_val;
	ROUGHNESS = roughness_val;

	vec3 glow_col = mix(emission_color, rim_color, rim_weight);
	float glow_energy = (emission_strength + fresnel * 0.85 + energy_flare * 1.05) * shimmer;
	EMISSION = glow_col * glow_energy;
}
