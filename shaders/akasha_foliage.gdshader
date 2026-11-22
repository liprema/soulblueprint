shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Painterly Botanical Foliage & Wind-Sway Shader (Godot 4.3+ Forward+)
// Optimized for 60 FPS on macOS Retina with MultiMeshInstance3D GPU instancing:
// - World-space rolling breeze wave anchored cleanly at roots (UV.y = 0.0 -> 1.0)
// - Rich root-to-tip botanical height gradient (mossy shaded base -> luminous sunlit tip)
// - Optional multi-part botanical mask (UV.x) for flower bushes (green stems/leaves + per-instance petals + golden pollen)
// - Studio Ghibli / BotW upward-blended soft normals (zero harsh polygon seams on both faces)
// - Warm golden-green / rosy-petal subsurface translucency via BACKLIGHT

group_uniforms wind_animation;
uniform float wind_strength : hint_range(0.0, 0.35) = 0.088;
uniform float wind_speed : hint_range(0.1, 3.0) = 1.0;
uniform float wind_gust_strength : hint_range(0.0, 0.25) = 0.036;
uniform float sway_root_power : hint_range(1.0, 3.0) = 1.85;
uniform float use_vertex_y_fallback : hint_range(0.0, 1.0) = 0.0;

group_uniforms botanical_shading;
uniform float base_shade : hint_range(0.2, 1.0) = 0.52;
uniform float tip_bright : hint_range(0.8, 1.6) = 1.18;
uniform vec3 base_tint : source_color = vec3(0.78, 0.94, 0.80);
uniform vec3 tip_tint : source_color = vec3(1.06, 1.09, 0.86);
uniform vec3 backlight_color : source_color = vec3(0.38, 0.52, 0.22);
uniform float backlight_strength : hint_range(0.0, 1.5) = 1.0;
uniform float roughness_val : hint_range(0.2, 1.0) = 0.62;
uniform float specular_val : hint_range(0.0, 1.0) = 0.28;
uniform float normal_up_blend : hint_range(0.0, 1.0) = 0.45;
uniform vec3 emission_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float emission_strength : hint_range(0.0, 1.0) = 0.0;

group_uniforms flower_bush_mask;
uniform float stem_mask_enabled : hint_range(0.0, 1.0) = 0.0;
uniform vec3 stem_base_color : source_color = vec3(0.16, 0.45, 0.23);
uniform vec3 stem_tip_color : source_color = vec3(0.34, 0.72, 0.36);
uniform vec3 pollen_color : source_color = vec3(1.0, 0.86, 0.32);

varying float v_height;
varying float v_part;

void vertex() {
	float h_uv = clamp(UV.y, 0.0, 1.0);
	float h_vert = clamp(VERTEX.y, 0.0, 1.0);
	float height_mask = mix(h_uv, h_vert, use_vertex_y_fallback);
	v_height = height_mask;
	v_part = UV.x;

	// Smooth root-anchored bend mask (0.0 at ground root, 1.0 at blade tip / blossom head; NaN-safe on Metal)
	float bend = height_mask * height_mask * mix(1.0, height_mask, clamp(sway_root_power - 2.0, 0.0, 1.0));

	// World-space rolling breeze wave so entire meadows and ivy curtains breathe coherently
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * wind_speed;

	float rolling_wave = sin(world_pos.x * 0.22 + t * 1.65) + cos(world_pos.z * 0.19 + t * 1.35);
	float cross_wave = cos(world_pos.x * 0.26 - t * 1.25) * 0.55 + sin(world_pos.z * 0.29 + t * 1.80) * 0.45;
	float micro_flutter = sin(world_pos.x * 1.35 + world_pos.z * 1.15 + t * 3.4) * wind_gust_strength;

	vec3 world_sway = vec3(
		(rolling_wave * 0.50 + micro_flutter) * wind_strength * bend,
		-abs(rolling_wave) * wind_strength * 0.14 * bend,
		(cross_wave * 0.55 + micro_flutter * 0.75) * wind_strength * bend
	);

	// Convert world-space breeze offset into local instance space so rotated MultiMesh tufts sway together
	mat3 inv_model = inverse(mat3(MODEL_MATRIX));
	VERTEX += inv_model * world_sway;
}

void fragment() {
	float h = clamp(v_height, 0.0, 1.0);
	float grad = mix(base_shade, tip_bright, smoothstep(0.0, 1.0, h));
	vec3 height_tint = mix(base_tint, tip_tint, smoothstep(0.12, 0.95, h));

	vec3 final_albedo = COLOR.rgb * grad * height_tint;
	vec3 final_backlight = backlight_color;

	// Flower-bush multi-part mask: UV.x < 0.25 = green stems/leaves, 0.25..0.75 = per-instance petals, > 0.75 = golden pollen
	if (stem_mask_enabled > 0.5) {
		if (v_part < 0.25) {
			vec3 stem_col = mix(stem_base_color, stem_tip_color, smoothstep(0.0, 0.78, h));
			final_albedo = stem_col * grad;
			final_backlight = vec3(0.34, 0.50, 0.20);
		} else if (v_part > 0.75) {
			final_albedo = pollen_color * mix(0.92, 1.16, h);
			final_backlight = vec3(0.58, 0.48, 0.18);
		} else {
			float petal_grad = mix(0.84, 1.16, smoothstep(0.35, 1.0, h));
			final_albedo = COLOR.rgb * petal_grad * tip_tint;
			final_backlight = mix(backlight_color, COLOR.rgb * 0.58, 0.45);
		}
	}

	// Upward-blended soft normals (post-FRONT_FACING flip) for velvety, seam-free painterly foliage
	vec3 view_up = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	NORMAL = normalize(mix(NORMAL, view_up, normal_up_blend));

	ALBEDO = final_albedo;
	ROUGHNESS = roughness_val;
	SPECULAR = specular_val;
	BACKLIGHT = final_backlight * backlight_strength * mix(0.42, 1.0, h);

	if (emission_strength > 0.001) {
		float emit_mask = smoothstep(0.42, 1.0, h);
		if (stem_mask_enabled > 0.5 && v_part < 0.25) {
			emit_mask = 0.0;
		}
		EMISSION = final_albedo * emission_color * emission_strength * emit_mask;
	}
}
