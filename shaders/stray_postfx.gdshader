shader_type canvas_item;

// Airy pearlescent filmic lens post-processing for SoulBlueprint (Godot 4.3 Forward+)
// Placed on CanvasLayer 5 (below SkyHUD layer 10 and MainMenu layer 50) so UI stays razor sharp.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float edge_ca : hint_range(0.0, 0.005, 0.0001) = 0.0006;
uniform float split_tone_strength : hint_range(0.0, 0.25, 0.005) = 0.035;
uniform vec3 shadow_tint : source_color = vec3(0.54, 0.66, 0.82);   // Soft periwinkle-sky shadow tint
uniform vec3 highlight_tint : source_color = vec3(1.0, 0.96, 0.90); // Warm sunlit pearl-cream highlight
uniform float vignette_strength : hint_range(0.0, 0.8, 0.01) = 0.11;
uniform float vignette_softness : hint_range(0.2, 1.2, 0.01) = 0.78;
uniform float grain_strength : hint_range(0.0, 0.08, 0.001) = 0.008;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - vec2(0.5);

	// 1. Subtle radial lens chromatic softness at extreme screen edges (zero blur in center)
	float r2 = dot(centered, centered) * 4.0;
	vec2 ca_offset = centered * r2 * edge_ca;

	float r = texture(screen_texture, clamp(uv + ca_offset, vec2(0.0), vec2(1.0))).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, clamp(uv - ca_offset, vec2(0.0), vec2(1.0))).b;
	vec3 col = vec3(r, g, b);

	// 2. Delicate Periwinkle-Sky Shadows & Warm Pearl-Cream Highlights split-toning
	float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
	float shadow_w = 1.0 - smoothstep(0.0, 0.48, luma);
	float high_w = smoothstep(0.45, 1.0, luma);

	vec3 shadow_target = mix(col, shadow_tint * max(luma * 1.45, 0.18), 0.65);
	col = mix(col, shadow_target, shadow_w * split_tone_strength);

	vec3 highlight_target = col * highlight_tint * 1.04;
	col = mix(col, highlight_target, high_w * split_tone_strength);

	// 3. Airy pearlescent vignette framing the center without darkening the sky
	float vig_dist = length(centered * vec2(1.08, 1.0));
	float vig_mask = smoothstep(0.28, 0.28 + vignette_softness, vig_dist);
	vec3 vig_col = mix(col, col * vec3(0.90, 0.94, 1.0), 0.18);
	col = mix(col, vig_col * (1.0 - vignette_strength), vig_mask);

	// 4. Animated micro film grain to eliminate digital flatness and fog/sky banding
	float t_seed = fract(TIME * 13.371) * 100.0;
	float grain = hash12(FRAGCOORD.xy + vec2(t_seed * 17.13, t_seed * 9.47)) - 0.5;
	float grain_mask = 1.0 - smoothstep(0.75, 1.0, luma) * 0.5;
	col += vec3(grain * grain_strength * grain_mask);

	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), 1.0);
}
