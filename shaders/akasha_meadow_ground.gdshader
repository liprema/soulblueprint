shader_type spatial;

// Plush Velvety Sunlit Pixar Meadow Carpet Shader for CastleIslandGrass
// Optimized for 60 FPS on macOS Apple Silicon Metal:
// - 100% pure unperturbed geometry normals (ZERO dFdx/dFdy glitches, ZERO CLEARCOAT in light())
// - Vertex color (COLOR) seamlessly blended with rich multi-scale emerald-to-chartreuse meadow hues
// - Fine anisotropic velvety grass-blade grain simulating thousands of soft sunlit blades
// - Lazy drifting wind-ripple shimmer waves across rolling hills
// - Delicate scattered micro-clover & white-periwinkle daisy flecks
// - Soft velvet Fresnel rim sheen on sunlit crests (zero plastic shine)

group_uniforms meadow_palette;
uniform vec3 valley_emerald_color : source_color = vec3(0.14, 0.30, 0.22);       // Deep Noble Emerald-Pine Valley
uniform vec3 meadow_mid_color : source_color = vec3(0.24, 0.44, 0.28);           // Soft Sage-Emerald Meadow
uniform vec3 crest_chartreuse_color : source_color = vec3(0.40, 0.56, 0.32);     // Warm Sunlit Olive-Chartreuse Crest
uniform vec3 velvet_rim_color : source_color = vec3(0.76, 0.86, 0.64);           // Soft Sunlit Velvet Halo
uniform vec3 daisy_petal_color : source_color = vec3(0.910, 0.935, 1.000);       // Soft White-Periwinkle Daisy Fleck
uniform vec3 daisy_center_color : source_color = vec3(0.985, 0.905, 0.560);      // Subtle Warm Clover/Daisy Center

group_uniforms grass_texture;
uniform float macro_patch_scale : hint_range(0.02, 0.5) = 0.085;
uniform float blade_grain_scale : hint_range(1.0, 24.0) = 8.5;
uniform float blade_anisotropy : hint_range(1.0, 6.0) = 3.2;
uniform float vertex_color_blend : hint_range(0.0, 1.0) = 0.42;
uniform float daisy_density : hint_range(0.0, 1.0) = 0.55;

group_uniforms wind_motion;
uniform vec2 wind_direction = vec2(0.84, 0.54);
uniform float wind_wave_speed : hint_range(0.0, 3.0) = 0.0;
uniform float wind_wave_scale : hint_range(0.02, 0.4) = 0.11;
uniform float wind_shimmer_strength : hint_range(0.0, 0.35) = 0.0;

group_uniforms surface_properties;
uniform float base_roughness : hint_range(0.65, 0.96) = 0.84;
uniform float surface_specular : hint_range(0.0, 0.25) = 0.12;
uniform float velvet_rim_strength : hint_range(0.0, 0.50) = 0.24;

varying vec3 v_world_pos;
varying vec4 v_vertex_color;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm2_fast(vec2 p) {
	float v = 0.64 * noise2d(p);
	v += 0.36 * noise2d(p * 2.11 + vec2(7.3, -4.9));
	return v;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_vertex_color = COLOR;
}

void fragment() {
	// NaN-safe world normal
	vec3 world_n_raw = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	float wn_len = length(world_n_raw);
	vec3 wn = wn_len > 0.0001 ? (world_n_raw / wn_len) : vec3(0.0, 1.0, 0.0);

	// Distance fade so micro-blades & daisies stay silky smooth at range
	float cam_dist = length(VERTEX);
	float near_detail = 1.0 - smoothstep(12.0, 58.0, cam_dist);
	float daisy_fade = 1.0 - smoothstep(10.0, 42.0, cam_dist);

	vec2 xz = v_world_pos.xz;
	float wd_len = length(wind_direction);
	vec2 w_dir = wd_len > 0.0001 ? (wind_direction / wd_len) : vec2(0.84, 0.54);
	vec2 w_perp = vec2(-w_dir.y, w_dir.x);

	// 1. Lazy drifting wind-ripple shimmer waves across the rolling hills
	float wave_coord_a = dot(xz, w_dir) * wind_wave_scale - TIME * wind_wave_speed;
	float wave_warp = fbm2_fast(xz * (wind_wave_scale * 0.65) + vec2(1.7, -3.1)) * 2.4;
	float wind_wave_a = sin(wave_coord_a + wave_warp) * 0.5 + 0.5;
	vec2 w_dir_b_raw = w_dir + w_perp * 0.45;
	float w_dir_b_len = length(w_dir_b_raw);
	vec2 w_dir_b = w_dir_b_len > 0.0001 ? (w_dir_b_raw / w_dir_b_len) : w_dir;
	float wave_coord_b = dot(xz, w_dir_b) * (wind_wave_scale * 1.45) - TIME * (wind_wave_speed * 0.78);
	float wind_wave_b = sin(wave_coord_b - wave_warp * 0.6) * 0.5 + 0.5;
	float wind_ripple = smoothstep(0.28, 0.86, wind_wave_a * 0.65 + wind_wave_b * 0.35);

	// 2. Multi-scale organic rolling meadow patches (deep emerald valleys -> sunlit golden-chartreuse crests)
	float macro_patch = fbm2_fast(xz * macro_patch_scale + vec2(3.4, -2.1));
	float micro_patch = noise2d(xz * (macro_patch_scale * 3.1) + vec2(-6.2, 4.7));
	float slope_sun = smoothstep(0.32, 0.94, wn.y);
	// Softly lift hilltops and sunlit south/west-facing slopes
	float sun_facing = clamp(dot(wn, vec3(0.4205, 0.8410, 0.3404)) * 0.5 + 0.5, 0.0, 1.0);
	float hill_warmth = clamp(macro_patch * 0.46 + micro_patch * 0.18 + slope_sun * 0.26 + sun_facing * 0.24 - 0.18, 0.0, 1.0);

	vec3 grass_col = mix(valley_emerald_color, meadow_mid_color, smoothstep(0.12, 0.62, hill_warmth));
	grass_col = mix(grass_col, crest_chartreuse_color, smoothstep(0.52, 0.94, hill_warmth));

	// Blend vertex color (COLOR) smoothly so painted island shading & sunlit ridges shine through
	vec3 vcol = clamp(v_vertex_color.rgb, vec3(0.05), vec3(1.5));
	float vcol_luma = dot(vcol, vec3(0.299, 0.587, 0.114));
	// Modulate with vertex color tint while preserving lush Pixar meadow saturation
	vec3 tinted_grass = mix(grass_col, grass_col * (vcol / max(vcol_luma, 0.22)) * mix(0.75, 1.15, clamp(vcol_luma, 0.0, 1.0)), vertex_color_blend);
	grass_col = mix(grass_col, tinted_grass, 0.85);

	// 3. Fine anisotropic velvety grass-blade grain (thousands of combed soft blades)
	// Project xz onto wind-combed basis + gentle swirl so grass looks organically brushed, never striped
	float comb_swirl = (macro_patch - 0.5) * 0.85 + wind_ripple * 0.18;
	float cs = cos(comb_swirl);
	float sn = sin(comb_swirl);
	vec2 combed_uv = vec2(
		dot(xz, w_dir) * cs - dot(xz, w_perp) * sn,
		dot(xz, w_dir) * sn + dot(xz, w_perp) * cs
	);
	vec2 blade_uv_a = vec2(combed_uv.x * (blade_grain_scale / blade_anisotropy), combed_uv.y * blade_grain_scale);
	vec2 blade_uv_b = vec2(combed_uv.x * (blade_grain_scale * 0.58), combed_uv.y * (blade_grain_scale * 1.65)) + vec2(11.3, -7.8);

	float blade_a = noise2d(blade_uv_a + vec2(wind_ripple * 0.22, 0.0));
	float blade_b = noise2d(blade_uv_b);
	float tuft_grain = mix(blade_a, blade_a * 0.62 + blade_b * 0.38, near_detail);

	// Darken tiny grass root crevices & brighten sunlit blade tips
	float blade_tip = smoothstep(0.48, 0.88, tuft_grain) * near_detail;
	float blade_root = (1.0 - smoothstep(0.10, 0.46, tuft_grain)) * near_detail;
	grass_col = mix(grass_col, valley_emerald_color * 0.78, blade_root * 0.28);
	grass_col = mix(grass_col, crest_chartreuse_color * 1.10, blade_tip * 0.22 * (0.45 + 0.55 * slope_sun));

	// Apply lazy sunlit wind-ripple shimmer across the grass tips
	float shimmer_mask = wind_ripple * wind_shimmer_strength * slope_sun * (0.60 + 0.40 * blade_tip);
	grass_col = mix(grass_col, velvet_rim_color, shimmer_mask);

	// 4. Tiny scattered micro-clover & white-periwinkle daisy flecks on sunlit slopes
	float daisy_cluster = smoothstep(0.44, 0.78, fbm2_fast(xz * 0.26 + vec2(-8.3, 5.9)));
	vec2 flower_grid = xz * 2.85;
	vec2 f_cell = floor(flower_grid);
	vec2 f_local = fract(flower_grid);
	vec2 f_rand = hash22(f_cell + vec2(19.7, 41.3));
	float f_spawn = step(1.0 - clamp(daisy_density * 0.42 * daisy_cluster, 0.0, 0.45), hash21(f_cell + vec2(7.1, 13.9)));

	vec2 f_center = mix(vec2(0.22), vec2(0.78), f_rand);
	float f_dist = length(f_local - f_center);
	float f_radius = mix(0.055, 0.105, f_rand.x);
	float petal_mask = (1.0 - smoothstep(f_radius * 0.45, f_radius, f_dist)) * f_spawn * daisy_fade * smoothstep(0.55, 0.88, wn.y);
	float core_mask = (1.0 - smoothstep(f_radius * 0.12, f_radius * 0.38, f_dist)) * petal_mask;

	// Slight per-flower tint between crisp white and soft periwinkle
	vec3 flower_col = mix(daisy_petal_color, vec3(0.82, 0.87, 1.0), f_rand.y * 0.55);
	flower_col = mix(flower_col, daisy_center_color, core_mask * 0.75);
	grass_col = mix(grass_col, flower_col, petal_mask * 0.88);

	// 5. Soft velvet Fresnel rim sheen on sunlit hilltops (NaN-safe, zero plastic glare)
	float n_len = length(NORMAL);
	vec3 n_view = n_len > 0.0001 ? (NORMAL / n_len) : vec3(0.0, 0.0, 1.0);
	float v_len = length(VIEW);
	vec3 v_view = v_len > 0.0001 ? (VIEW / v_len) : vec3(0.0, 0.0, 1.0);
	float ndotv = clamp(dot(n_view, v_view), 0.0, 1.0);
	float velvet_fresnel = pow(max(1.0 - ndotv, 0.0001), 2.4);

	float rim_factor = velvet_fresnel * velvet_rim_strength * smoothstep(0.18, 0.86, wn.y) * (0.68 + 0.32 * wind_ripple);
	grass_col = mix(grass_col, velvet_rim_color, clamp(rim_factor, 0.0, 0.45));

	// Warm sunlit bounce in subtle roughness & AO
	float final_rough = clamp(base_roughness + blade_root * 0.06 - blade_tip * 0.04 - wind_ripple * 0.02, 0.76, 0.94);

	ALBEDO = clamp(grass_col, vec3(0.0), vec3(1.0));
	ROUGHNESS = final_rough;
	SPECULAR = surface_specular;
	METALLIC = 0.0;
	AO = clamp(1.0 - blade_root * 0.20, 0.78, 1.0);
	AO_LIGHT_AFFECT = 0.25;
	EMISSION = vec3(0.0);
}
