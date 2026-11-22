shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

// Colossal Ethereal Celestial Mentor Apparition Shader (#58C4FF)
// Inspired by Alateya's translucent cyan silhouette in the Sanctuary reference frame

uniform vec3 body_color : source_color = vec3(0.18, 0.58, 0.92);
uniform vec3 rim_color : source_color = vec3(0.55, 0.92, 1.0);
uniform float base_opacity : hint_range(0.0, 1.0) = 0.24;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.1;
uniform float emission_strength : hint_range(0.2, 4.0) = 1.65;
uniform float shimmer_speed : hint_range(0.0, 4.0) = 0.85;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float ndotv = clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, fresnel_power);

	// Soft vertical ethereal shimmer & gentle fade near lower robe base
	float wave = 0.5 + 0.5 * sin(v_world_pos.y * 0.22 - TIME * shimmer_speed + v_world_pos.x * 0.08);
	float height_fade = smoothstep(-14.0, 16.0, v_world_pos.y);

	vec3 col = mix(body_color, rim_color, clamp(fresnel * 1.15 + wave * 0.15, 0.0, 1.0));
	float alpha = (base_opacity * 0.35 + fresnel * 0.82) * (0.82 + 0.18 * wave) * height_fade;

	ALBEDO = col * emission_strength;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
