shader_type spatial;
render_mode cull_back;

// Pixar-Style Chaotic Warm Window Glow Shader (Godot 4.3+ Forward+, Apple Silicon Metal Safe)
// - 100% Apple Silicon Metal Safe: ZERO dFdx/dFdy/fwidth, ZERO CLEARCOAT, ZERO light() overrides,
//   all smoothstep(a, b, x) strictly a < b, NaN-safe math.
// - Per-window deterministic state quantized in world space + building origin seed so every window pane
//   on every floor of every house glows organically (~44% unlit slate-blue glass, ~20% softly lit,
//   ~36% warmly glowing honey/amber/cream interior with subtle vertical curtain gradient).

group_uniforms window_colors;
uniform vec3 unlit_glass_color : source_color = vec3(0.16, 0.22, 0.32);
uniform vec3 warm_glow_a : source_color = vec3(1.00, 0.80, 0.44);
uniform vec3 warm_glow_b : source_color = vec3(1.00, 0.68, 0.36);
uniform vec3 warm_glow_c : source_color = vec3(0.98, 0.88, 0.66);

group_uniforms glow_controls;
uniform float lit_ratio : hint_range(0.0, 1.0) = 0.56;
uniform float emission_strength : hint_range(0.0, 3.0) = 1.35;

varying vec3 v_world_pos;
varying flat vec3 v_building_seed;

float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_building_seed = floor(MODEL_MATRIX[3].xyz * 2.0);
}

void fragment() {
	// Quantize world position into individual window pane cells & hash with building seed
	vec3 win_cell = floor(v_world_pos / vec3(1.35, 1.95, 1.35));
	vec3 cell_key = win_cell + v_building_seed * 0.37;

	float h1 = hash31(cell_key + vec3(13.7, 29.3, 47.1));
	float h2 = hash31(cell_key * 1.73 + vec3(71.9, 11.3, 53.7));
	float h3 = hash31(cell_key * 2.31 + vec3(5.1, 89.7, 19.3));

	float safe_lit_ratio = clamp(lit_ratio, 0.0, 1.0);
	float safe_emission = clamp(emission_strength, 0.0, 3.0);

	// Split thresholds (at default lit_ratio = 0.56: ~44% unlit, ~20% dimly lit, ~36% warmly glowing)
	float unlit_cutoff = 1.0 - safe_lit_ratio;
	float dim_cutoff = unlit_cutoff + safe_lit_ratio * 0.357;

	// Vertical coordinate within the window cell for subtle curtain/interior shading
	float cell_v = fract(v_world_pos.y / 1.95);
	float curtain_grad = mix(0.80, 1.12, smoothstep(0.05, 0.52, cell_v))
		* mix(1.0, 0.70, smoothstep(0.66, 0.98, cell_v));

	// Cozy twilight slate-blue unlit glass with subtle vertical sky sheen
	vec3 unlit_col = clamp(unlit_glass_color * mix(0.84, 1.18, smoothstep(0.0, 1.0, cell_v)), vec3(0.0), vec3(1.0));

	// Organic honey / amber / sunlit-cream interior color selection
	vec3 warm_ab = mix(warm_glow_a, warm_glow_b, smoothstep(0.15, 0.55, h3));
	vec3 warm_col = mix(warm_ab, warm_glow_c, smoothstep(0.55, 0.92, h3));

	if (h1 < unlit_cutoff) {
		// Unlit twilight glass
		ALBEDO = unlit_col;
		EMISSION = vec3(0.0);
		ROUGHNESS = 0.28;
		SPECULAR = 0.38;
	} else if (h1 < dim_cutoff) {
		// Softly dimly lit warm interior
		float dim_energy = safe_emission * 0.45 * curtain_grad;
		ALBEDO = clamp(mix(unlit_col, warm_col * 0.65, 0.72), vec3(0.0), vec3(1.0));
		EMISSION = warm_col * dim_energy;
		ROUGHNESS = 0.34;
		SPECULAR = 0.28;
	} else {
		// Warmly glowing honey/amber/cream interior
		float bright_energy = safe_emission * mix(0.75, 1.30, h2) * curtain_grad;
		ALBEDO = clamp(mix(unlit_col, warm_col * 0.85, 0.90), vec3(0.0), vec3(1.0));
		EMISSION = warm_col * bright_energy;
		ROUGHNESS = 0.32;
		SPECULAR = 0.24;
	}

	METALLIC = 0.0;
}
