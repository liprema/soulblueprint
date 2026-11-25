shader_type spatial;
render_mode cull_back;

// Pixar-Style Cozy Whole-Pane Window Glow Shader (Godot 4.3+ Forward+, Apple Silicon Metal Safe)
// - 100% Apple Silicon Metal Safe: ZERO dFdx/dFdy/fwidth, ZERO CLEARCOAT, ZERO light() overrides,
//   all smoothstep(a, b, x) strictly a < b, NaN-safe math.
// - Quantizes window identity in LOCAL model space + flat building origin seed so every individual
//   window pane gets ONE cohesive state (never sliced in half!).
// - Default ~48% lit: ~30% warm cozy candle-cream/honey-gold interior, ~18% softly dimmed warm interior,
//   ~52% calm twilight sky-reflecting slate-blue-indigo glass.

group_uniforms window_colors;
uniform vec3 unlit_glass_color : source_color = vec3(0.18, 0.24, 0.36);
uniform vec3 warm_glow_a : source_color = vec3(1.00, 0.87, 0.62);
uniform vec3 warm_glow_b : source_color = vec3(0.98, 0.78, 0.46);
uniform vec3 warm_glow_c : source_color = vec3(1.00, 0.93, 0.78);

group_uniforms glow_controls;
uniform float lit_ratio : hint_range(0.0, 1.0) = 0.48;
uniform float emission_strength : hint_range(0.0, 3.0) = 0.95;

varying vec3 v_local_pos;
varying flat vec3 v_building_seed;

float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	v_local_pos = VERTEX;
	v_building_seed = floor(MODEL_MATRIX[3].xyz * 0.5);
}

void fragment() {
	// Quantize window identity in LOCAL model space so each individual window pane gets one cohesive state
	vec3 local_shifted = v_local_pos + vec3(0.5, 0.2, 0.5);
	vec3 win_cell = floor(local_shifted / vec3(2.1, 2.8, 2.1));
	vec3 cell_key = win_cell + v_building_seed * 0.37;

	float h1 = hash31(cell_key + vec3(13.7, 29.3, 47.1));
	float h2 = hash31(cell_key * 1.73 + vec3(71.9, 11.3, 53.7));
	float h3 = hash31(cell_key * 2.31 + vec3(5.1, 89.7, 19.3));

	float safe_lit_ratio = clamp(lit_ratio, 0.0, 1.0);
	float safe_emission = clamp(emission_strength, 0.0, 3.0);

	// Split thresholds (at default lit_ratio = 0.48: ~52% unlit, ~18% softly dimmed, ~30% warmly glowing)
	float unlit_cutoff = 1.0 - safe_lit_ratio;
	float dim_cutoff = unlit_cutoff + safe_lit_ratio * 0.375;

	// Local-space coordinates within the window band for smooth vertical warmth & subtle curtain vignette
	float cell_v = fract(local_shifted.y / 2.8);
	float cell_u = fract((local_shifted.x + local_shifted.z) / 2.1);

	// Gentle vertical lamp warmth: cozy warm lamp glow in lower half, softer amber-cream toward top
	float lamp_warmth = mix(1.12, 0.78, smoothstep(0.18, 0.86, cell_v));
	// Subtle warm curtain vignette near top/bottom/side edges (soft, never harsh)
	float edge_v = min(cell_v, 1.0 - cell_v);
	float edge_u = min(cell_u, 1.0 - cell_u);
	float curtain_vignette = mix(0.84, 1.0, smoothstep(0.02, 0.20, edge_v))
		* mix(0.90, 1.0, smoothstep(0.02, 0.16, edge_u));
	float interior_shade = lamp_warmth * curtain_vignette;

	// Calm unlit twilight sky-reflecting slate-blue-indigo glass (gentle top-to-bottom sky reflection)
	vec3 sky_low = unlit_glass_color * vec3(0.76, 0.80, 0.88);
	vec3 sky_high = unlit_glass_color * vec3(1.16, 1.24, 1.38);
	vec3 unlit_col = clamp(mix(sky_low, sky_high, smoothstep(0.06, 0.94, cell_v)), vec3(0.0), vec3(1.0));

	// Cozy candle-cream / honey-gold interior tint with warmer lower-half lamp hue
	vec3 warm_ab = mix(warm_glow_a, warm_glow_b, smoothstep(0.15, 0.55, h3));
	vec3 warm_base = mix(warm_ab, warm_glow_c, smoothstep(0.55, 0.92, h3));
	vec3 warm_col = clamp(
		mix(warm_base * vec3(1.04, 0.94, 0.82), warm_base * vec3(0.96, 0.98, 1.03), smoothstep(0.18, 0.84, cell_v)),
		vec3(0.0),
		vec3(1.0)
	);

	if (h1 < unlit_cutoff) {
		// Calm unlit twilight sky-reflecting glass
		ALBEDO = unlit_col;
		EMISSION = vec3(0.0);
		ROUGHNESS = 0.26;
		SPECULAR = 0.34;
	} else if (h1 < dim_cutoff) {
		// Softly dimmed warm interior (~18%)
		float dim_energy = safe_emission * 0.38 * interior_shade;
		ALBEDO = clamp(mix(unlit_col, warm_col * 0.68, 0.72), vec3(0.0), vec3(1.0));
		EMISSION = warm_col * dim_energy;
		ROUGHNESS = 0.32;
		SPECULAR = 0.26;
	} else {
		// Warmly lit cozy golden-cream interior (~30%)
		float bright_energy = safe_emission * mix(0.75, 1.15, h2) * interior_shade;
		ALBEDO = clamp(mix(unlit_col, warm_col * 0.88, 0.90), vec3(0.0), vec3(1.0));
		EMISSION = warm_col * bright_energy;
		ROUGHNESS = 0.30;
		SPECULAR = 0.22;
	}

	METALLIC = 0.0;
}
