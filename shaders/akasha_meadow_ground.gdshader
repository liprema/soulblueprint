shader_type spatial;

// Hand-Painted Studio Ghibli / Pixar / Genshin Meadow Ground Shader
// Optimized for 60 FPS on macOS Apple Silicon Metal + FSR 1.0:
// - 100% pure unperturbed geometry normals (ZERO dFdx/dFdy, ZERO CLEARCOAT in light())
// - Strictly NaN-safe normalize(), atan(), pow(), and strictly ordered smoothstep(a < b)
// - Rich, joyful, glare-free sunlit meadow green palette harmonizing with the Baroque Palace
// - Layered painterly grass-tuft scallops & gouache brushstroke bands (NOT blurry Perlin noise)
// - Crisp stylized 5-petal white daisies with plump golden-marigold centers across 2 bouquet grids
// - Companion warm golden-yellow buttercup buds, sunlit clover/leaf sprigs & white pollen specks
// - Static calm meadow by default (wind_wave_speed = 0.0, wind_shimmer_strength = 0.0)
// - Smooth distance LOD fade so distant hills remain silky-smooth with zero aliasing/shimmer

group_uniforms meadow_palette;
uniform vec3 valley_emerald_color : source_color = vec3(0.18, 0.42, 0.14);       // Deep Leafy Emerald Shadow Band
uniform vec3 meadow_mid_color : source_color = vec3(0.36, 0.62, 0.17);           // Vibrant Fresh Meadow Green
uniform vec3 crest_chartreuse_color : source_color = vec3(0.54, 0.74, 0.20);     // Sunlit Warm Lime-Yellow Highlight
uniform vec3 velvet_rim_color : source_color = vec3(0.76, 0.86, 0.46);           // Soft Warm Sunlit Velvet Rim
uniform vec3 daisy_petal_color : source_color = vec3(0.96, 0.96, 0.92);          // Crisp 5-Petal Warm-White Corolla
uniform vec3 daisy_center_color : source_color = vec3(0.95, 0.72, 0.16);         // Plump Warm Golden-Marigold Center

group_uniforms grass_texture;
uniform float macro_patch_scale : hint_range(0.02, 0.5) = 0.085;
uniform float blade_grain_scale : hint_range(1.0, 24.0) = 8.5;
uniform float blade_anisotropy : hint_range(1.0, 6.0) = 3.2;
uniform float vertex_color_blend : hint_range(0.0, 1.0) = 0.28;
uniform float daisy_density : hint_range(0.0, 1.0) = 0.58;

group_uniforms wind_motion;
uniform vec2 wind_direction = vec2(0.84, 0.54);
uniform float wind_wave_speed : hint_range(0.0, 3.0) = 0.0;
uniform float wind_wave_scale : hint_range(0.02, 0.4) = 0.11;
uniform float wind_shimmer_strength : hint_range(0.0, 0.35) = 0.0;

group_uniforms surface_properties;
uniform float base_roughness : hint_range(0.65, 0.96) = 0.88;
uniform float surface_specular : hint_range(0.0, 0.25) = 0.08;
uniform float velvet_rim_strength : hint_range(0.0, 0.50) = 0.16;

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

vec2 rot2(vec2 v, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

// NaN-safe 5-petal stylized daisy SDF evaluated cleanly inside a single jittered cell.
// Returns vec4(drop_shadow, petal_mask, core_mask, variant_seed)
vec4 eval_daisy_cell(vec2 cell_local, vec2 cell_id, float spawn_prob, float min_r, float max_r, float edge_aa, out float out_lobe_shade) {
	vec2 rnd = hash22(cell_id + vec2(19.7, 41.3));
	float spawn_roll = hash21(cell_id + vec2(7.1, 13.9));
	float size_roll = hash21(cell_id + vec2(53.2, 11.8));
	float spawn = step(1.0 - clamp(spawn_prob, 0.0, 0.90), spawn_roll);

	// Keep center inside [0.29, 0.67] so petals (max_r <= 0.205) + drop shadow never clip cell edges
	vec2 center = mix(vec2(0.29), vec2(0.67), rnd);
	float base_r = mix(min_r, max_r, size_roll);
	float rot = rnd.x * 6.2831853;

	vec2 dp = cell_local - center;
	float dp_len = length(dp);
	float ang = dp_len > 0.0001 ? atan(dp.y, dp.x) : 0.0;

	// 5-lobe polar corolla
	float lobe = cos(5.0 * ang + rot);
	float r_petal = base_r * (0.76 + 0.24 * lobe);
	float aa = max(edge_aa, 0.012);
	float p_lo = max(r_petal - aa, 0.0);
	float p_hi = r_petal + aa;
	float petal_mask = (1.0 - smoothstep(p_lo, p_hi, dp_len)) * spawn;

	// Subtle petal-crease shading near inner notches for plump hand-painted petals
	out_lobe_shade = clamp(0.5 + 0.5 * lobe, 0.0, 1.0) * smoothstep(base_r * 0.28, base_r * 0.95, dp_len);

	// Plump warm golden-marigold center
	float core_r = base_r * 0.43;
	float c_lo = max(core_r - aa * 0.85, 0.0);
	float c_hi = core_r + aa * 0.85;
	float core_mask = (1.0 - smoothstep(c_lo, c_hi, dp_len)) * petal_mask;

	// Subtle emerald drop-shadow tucked slightly beneath the flower
	vec2 dp_s = dp - vec2(0.020, 0.026);
	float s_len = length(dp_s);
	float s_ang = s_len > 0.0001 ? atan(dp_s.y, dp_s.x) : 0.0;
	float r_shad = base_r * (0.76 + 0.18 * cos(5.0 * s_ang + rot));
	float s_lo = r_shad * 0.52;
	float s_hi = r_shad + min(aa * 1.5, 0.055);
	float shadow_mask = (1.0 - smoothstep(s_lo, s_hi, s_len)) * spawn;

	return vec4(shadow_mask, petal_mask, core_mask, rnd.y);
}

// Hand-painted grass-blade tuft strokes (fanned V-blades + dark emerald root base)
// Returns vec2(dark_stroke_mask, sunlit_tip_mask)
vec2 eval_grass_tuft_strokes(vec2 xz, vec2 w_dir, vec2 w_perp, float detail_lod) {
	vec2 tuft_space = vec2(dot(xz, w_dir), dot(xz, w_perp)) * 2.35;
	vec2 cell = floor(tuft_space);
	vec2 local = fract(tuft_space);

	vec2 rnd = hash22(cell + vec2(31.7, 17.3));
	float spawn = step(0.32, hash21(cell + vec2(9.4, 61.2)));
	vec2 p = local - mix(vec2(0.28), vec2(0.72), rnd);
	p = rot2(p, (rnd.x - 0.5) * 0.75);

	// Two fanned curved blades springing from a shared root base
	// Left-leaning blade
	float y_l = clamp(p.y + 0.10, 0.0, 0.30);
	float x_curve_l = p.x + 0.16 * y_l + 0.55 * y_l * y_l;
	float width_l = mix(0.028, 0.006, clamp(y_l / 0.30, 0.0, 1.0));
	float in_y_l = smoothstep(-0.11, -0.07, p.y) * (1.0 - smoothstep(0.14, 0.20, p.y));
	float blade_l = (1.0 - smoothstep(width_l * 0.45, width_l + 0.016, abs(x_curve_l))) * in_y_l;

	// Right-leaning blade
	float y_r = clamp(p.y + 0.09, 0.0, 0.26);
	float x_curve_r = p.x - 0.22 * y_r - 0.50 * y_r * y_r;
	float width_r = mix(0.026, 0.005, clamp(y_r / 0.26, 0.0, 1.0));
	float in_y_r = smoothstep(-0.10, -0.06, p.y) * (1.0 - smoothstep(0.11, 0.17, p.y));
	float blade_r = (1.0 - smoothstep(width_r * 0.45, width_r + 0.016, abs(x_curve_r))) * in_y_r;

	// Tiny tucked emerald shadow-base at the root of the tuft
	float root_d = length(vec2(p.x * 1.15, (p.y + 0.10) * 1.9));
	float root_shad = (1.0 - smoothstep(0.04, 0.12, root_d));

	float blade_union = clamp(max(blade_l, blade_r), 0.0, 1.0);
	float tip_grad = smoothstep(-0.02, 0.15, p.y);

	float dark_stroke = clamp(max(root_shad * 0.72, blade_union * (1.0 - tip_grad * 0.75)), 0.0, 1.0) * spawn * detail_lod;
	float sunlit_tip = blade_union * tip_grad * spawn * detail_lod;
	return vec2(dark_stroke, sunlit_tip);
}

// Bright sunlit-lime clover / oval leaf sprig pairs (as seen near flower pockets in reference)
// Returns vec2(leaf_shadow, leaf_mask)
vec2 eval_clover_sprigs(vec2 xz, float cluster_bias, float detail_lod) {
	vec2 grid = rot2(xz, -0.45) * 2.15 + vec2(-31.4, 12.7);
	vec2 cell = floor(grid);
	vec2 local = fract(grid);

	vec2 rnd = hash22(cell + vec2(47.1, 83.9));
	float spawn_prob = clamp(0.18 + 0.52 * cluster_bias, 0.0, 0.72);
	float spawn = step(1.0 - spawn_prob, hash21(cell + vec2(12.3, 29.7)));

	vec2 p = local - mix(vec2(0.28), vec2(0.72), rnd);
	p = rot2(p, rnd.x * 6.2831853);

	// Pair of plump oval leaves at gentle V-angle
	vec2 p1 = rot2(p - vec2(-0.055, 0.02), 0.42);
	float d1 = length(vec2(p1.x * 1.35, p1.y * 0.82));
	vec2 p2 = rot2(p - vec2(0.055, -0.015), -0.52);
	float d2 = length(vec2(p2.x * 1.45, p2.y * 0.88));

	float leaf_r = mix(0.068, 0.105, rnd.y);
	float leaf_aa = mix(0.014, 0.042, 1.0 - detail_lod);
	float d_min = min(d1, d2);
	float leaf_mask = (1.0 - smoothstep(max(leaf_r - leaf_aa, 0.0), leaf_r + leaf_aa, d_min)) * spawn * detail_lod;

	// Subtle soft shadow under leaf pair
	vec2 ps = p - vec2(0.02, 0.03);
	float ds = length(ps * vec2(0.95, 1.15));
	float leaf_shad = (1.0 - smoothstep(leaf_r * 0.65, leaf_r * 1.55 + leaf_aa, ds)) * spawn * detail_lod;

	return vec2(leaf_shad, leaf_mask);
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

	// Smooth distance LOD fades for crisp close-ups and silky-smooth distant hills (zero aliasing/shimmer)
	float cam_dist = length(VERTEX);
	float detail_lod = 1.0 - smoothstep(22.0, 75.0, cam_dist);
	float micro_lod = 1.0 - smoothstep(14.0, 52.0, cam_dist);
	float band_aa = mix(0.028, 0.16, smoothstep(18.0, 85.0, cam_dist));

	vec2 xz = v_world_pos.xz;
	float wd_len = length(wind_direction);
	vec2 w_dir = wd_len > 0.0001 ? (wind_direction / wd_len) : vec2(0.84, 0.54);
	vec2 w_perp = vec2(-w_dir.y, w_dir.x);

	// Optional wind shimmer (strictly 0.0 by default so meadow stays calm and never drifts)
	float wind_ripple = 0.0;
	if (wind_shimmer_strength > 0.0001) {
		float wave_coord = dot(xz, w_dir) * wind_wave_scale - TIME * wind_wave_speed;
		float wave_warp = fbm2_fast(xz * (wind_wave_scale * 0.65) + vec2(1.7, -3.1)) * 2.2;
		wind_ripple = smoothstep(0.28, 0.86, sin(wave_coord + wave_warp) * 0.5 + 0.5);
	}

	// 1. Layered Painterly Grass-Tuft Scallops & Sweeping Sunlit Brushstroke Bands
	float macro_patch = fbm2_fast(xz * macro_patch_scale + vec2(-5.1, 4.3));
	float band_warp = (fbm2_fast(xz * (macro_patch_scale * 1.18) + vec2(3.4, -2.1)) - 0.5) * 2.8;
	float band_wave = sin(dot(xz, w_perp) * (macro_patch_scale * 4.4) + band_warp) * 0.5 + 0.5;

	float slope_sun = smoothstep(0.30, 0.94, wn.y);
	float sun_facing = clamp(dot(wn, vec3(0.4205, 0.8410, 0.3404)) * 0.5 + 0.5, 0.0, 1.0);
	float base_tone = clamp(band_wave * 0.44 + macro_patch * 0.36 + slope_sun * 0.14 + sun_facing * 0.14 - 0.08, 0.0, 1.0);

	// Scalloped tuft-crown edge perturbation so band boundaries read as layered grass tufts, not blurry noise
	vec2 tuft_uv = vec2(dot(xz, w_dir), dot(xz, w_perp));
	float scallop_macro = noise2d(vec2(tuft_uv.x * 1.65, tuft_uv.y * 0.78) + vec2(macro_patch * 1.5, -band_warp * 0.45));
	float scallop_blade = noise2d(vec2(tuft_uv.x * (blade_grain_scale * 0.52), tuft_uv.y * (blade_grain_scale * 0.52 / max(blade_anisotropy, 0.1))) + vec2(7.3, -4.1));
	float blade_teeth = abs(fract(tuft_uv.x * 2.4 + scallop_macro * 2.1) * 2.0 - 1.0);
	float tuft_serration = (scallop_macro - 0.5) * 0.26 * (0.35 + 0.65 * detail_lod)
		+ ((scallop_blade - 0.5) * 0.14 + (blade_teeth - 0.5) * 0.08) * detail_lod;

	float painterly_val = clamp(base_tone + tuft_serration, 0.0, 1.0);

	// 4-tier stylized Ghibli gouache value steps
	vec3 deep_shadow_col = valley_emerald_color;
	vec3 shaded_mid_col = mix(valley_emerald_color, meadow_mid_color, 0.52);
	vec3 fresh_mid_col = meadow_mid_color;
	vec3 sunlit_lime_col = crest_chartreuse_color;

	float step1 = smoothstep(0.26 - band_aa, 0.26 + band_aa, painterly_val);
	float step2 = smoothstep(0.50 - band_aa, 0.50 + band_aa, painterly_val);
	float step3 = smoothstep(0.73 - band_aa, 0.73 + band_aa, painterly_val);

	vec3 stepped_col = mix(deep_shadow_col, shaded_mid_col, step1);
	stepped_col = mix(stepped_col, fresh_mid_col, step2);
	stepped_col = mix(stepped_col, sunlit_lime_col, step3);

	vec3 smooth_col = mix(deep_shadow_col, fresh_mid_col, smoothstep(0.10, 0.60, base_tone));
	smooth_col = mix(smooth_col, sunlit_lime_col, smoothstep(0.52, 0.94, base_tone));

	// Rich painterly band structure up close, gently softening into rolling sunlit bands at distance
	vec3 grass_col = mix(smooth_col, stepped_col, 0.76 + 0.12 * detail_lod);

	// Optional vertex color modulation (used on CastleIslandGrass; 0.0 on city meadow)
	if (vertex_color_blend > 0.001) {
		vec3 vcol = clamp(v_vertex_color.rgb, vec3(0.05), vec3(1.5));
		float vcol_luma = dot(vcol, vec3(0.299, 0.587, 0.114));
		vec3 tinted_grass = mix(grass_col, grass_col * (vcol / max(vcol_luma, 0.22)) * mix(0.82, 1.12, clamp(vcol_luma, 0.0, 1.0)), vertex_color_blend);
		grass_col = mix(grass_col, tinted_grass, 0.80);
	}

	// 2. Tucked Emerald Tuft Shadow-Bases & Crisp Directional Grass-Blade Strokes
	float band_crease = (step2 * (1.0 - step2) + step3 * (1.0 - step3)) * 4.0 * smoothstep(0.32, 0.76, scallop_blade) * detail_lod;
	vec2 tuft_strokes = eval_grass_tuft_strokes(xz, w_dir, w_perp, detail_lod);
	float blade_shadow = clamp(band_crease * 0.34 + tuft_strokes.x * 0.42, 0.0, 0.55);
	float blade_hi = clamp(tuft_strokes.y * 0.34 + smoothstep(0.62, 0.92, scallop_blade) * 0.12 * detail_lod, 0.0, 0.40);

	grass_col = mix(grass_col, valley_emerald_color * 0.72, blade_shadow);
	grass_col = mix(grass_col, crest_chartreuse_color * 1.12, blade_hi * (0.45 + 0.55 * slope_sun));

	if (wind_shimmer_strength > 0.0001) {
		grass_col = mix(grass_col, velvet_rim_color, wind_ripple * wind_shimmer_strength * slope_sun);
	}

	// 3. Organic Flower Bouquet Cluster Mask (pockets of 2-5 daisies with open green bands between)
	float bouquet_noise = fbm2_fast(xz * 0.30 + vec2(-8.3, 5.9));
	float bouquet_mask = smoothstep(0.32, 0.70, bouquet_noise);
	float flat_mask = smoothstep(0.52, 0.86, wn.y);
	float flower_vis = detail_lod * flat_mask;

	// 4. Bright Sunlit-Lime Clover / Leaf Sprigs around flower clusters & shadowed bands
	vec2 clover = eval_clover_sprigs(xz, bouquet_mask, detail_lod);
	vec3 clover_leaf_col = crest_chartreuse_color * vec3(1.18, 1.15, 0.86);
	grass_col = mix(grass_col, valley_emerald_color * 0.68, clover.x * 0.32 * flat_mask);
	grass_col = mix(grass_col, clover_leaf_col, clover.y * 0.82 * flat_mask);

	// 5. Crisp Stylized 5-Petal White Daisies + Companion Micro-Daisies & Golden Buttercup Buds
	float flower_aa = mix(0.018, 0.056, 1.0 - detail_lod);

	// Secondary Grid (smaller companion white daisies & warm golden-yellow buttercup buds)
	vec2 sec_grid = rot2(xz, 0.62) * 2.45 + vec2(17.3, -29.1);
	vec2 sec_cell = floor(sec_grid);
	vec2 sec_local = fract(sec_grid);
	float sec_spawn = daisy_density * (0.12 + 0.84 * bouquet_mask);
	float sec_lobe_shade = 0.0;
	vec4 sec_flower = eval_daisy_cell(sec_local, sec_cell, sec_spawn, 0.115, 0.175, flower_aa, sec_lobe_shade);

	float is_buttercup = step(0.62, sec_flower.w);
	vec3 buttercup_petal = mix(daisy_center_color * vec3(1.06, 1.18, 0.92), daisy_petal_color * vec3(1.0, 0.94, 0.28), 0.24);
	vec3 buttercup_core = daisy_center_color * vec3(0.95, 0.62, 0.35);
	vec3 sec_petal_col = mix(daisy_petal_color * mix(0.93, 1.02, sec_lobe_shade), buttercup_petal, is_buttercup);
	vec3 sec_core_col = mix(daisy_center_color, buttercup_core, is_buttercup);
	vec3 sec_col = mix(sec_petal_col, sec_core_col, sec_flower.z);

	grass_col = mix(grass_col, valley_emerald_color * 0.64, sec_flower.x * 0.36 * flower_vis);
	grass_col = mix(grass_col, sec_col, sec_flower.y * 0.94 * flower_vis);

	// Primary Bouquet Grid (hero 5-petal white daisies with plump golden-marigold centers)
	vec2 pri_grid = xz * 1.48;
	vec2 pri_cell = floor(pri_grid);
	vec2 pri_local = fract(pri_grid);
	float pri_spawn = daisy_density * (0.14 + 0.78 * bouquet_mask);
	float pri_lobe_shade = 0.0;
	vec4 pri_flower = eval_daisy_cell(pri_local, pri_cell, pri_spawn, 0.135, 0.205, flower_aa, pri_lobe_shade);

	vec3 pri_petal_col = daisy_petal_color * mix(0.92, 1.02, pri_lobe_shade);
	// Plump golden-marigold center with subtle warm orange rim & sunlit top highlight
	vec3 pri_core_col = mix(daisy_center_color * vec3(0.96, 0.82, 0.72), daisy_center_color * 1.06, pri_flower.z);
	vec3 pri_col = mix(pri_petal_col, pri_core_col, pri_flower.z);

	grass_col = mix(grass_col, valley_emerald_color * 0.62, pri_flower.x * 0.42 * flower_vis);
	grass_col = mix(grass_col, pri_col, pri_flower.y * 0.96 * flower_vis);

	// 6. Delicate White Pollen / Micro-Blossom Specks scattered around clusters
	vec2 speck_grid = xz * 4.15 + vec2(43.2, -19.8);
	vec2 sp_cell = floor(speck_grid);
	vec2 sp_local = fract(speck_grid);
	vec2 sp_rnd = hash22(sp_cell + vec2(11.3, 67.9));
	float sp_spawn = step(1.0 - clamp(daisy_density * (0.16 + 0.44 * bouquet_mask), 0.0, 0.58), hash21(sp_cell + vec2(23.1, 5.7)));
	float sp_dist = length(sp_local - mix(vec2(0.22), vec2(0.78), sp_rnd));
	float sp_r = mix(0.042, 0.072, sp_rnd.x);
	float sp_mask = (1.0 - smoothstep(sp_r * 0.45, sp_r + 0.025, sp_dist)) * sp_spawn * micro_lod * flat_mask;
	grass_col = mix(grass_col, daisy_petal_color * 1.02, sp_mask * 0.90);

	// 7. Soft Matte Velvet Fresnel Rim Sheen on Sunlit Hilltops (NaN-safe, zero glare)
	float n_len = length(NORMAL);
	vec3 n_view = n_len > 0.0001 ? (NORMAL / n_len) : vec3(0.0, 0.0, 1.0);
	float v_len = length(VIEW);
	vec3 v_view = v_len > 0.0001 ? (VIEW / v_len) : vec3(0.0, 0.0, 1.0);
	float ndotv = clamp(dot(n_view, v_view), 0.0, 1.0);
	float velvet_fresnel = pow(max(1.0 - ndotv, 0.0001), 2.5);

	float rim_factor = velvet_fresnel * velvet_rim_strength * smoothstep(0.20, 0.86, wn.y);
	grass_col = mix(grass_col, velvet_rim_color, clamp(rim_factor, 0.0, 0.28));

	// Glare-free matte velvet finish
	float final_rough = clamp(base_roughness + blade_shadow * 0.04 - blade_hi * 0.03, 0.84, 0.92);

	ALBEDO = clamp(grass_col, vec3(0.0), vec3(1.0));
	ROUGHNESS = final_rough;
	SPECULAR = surface_specular;
	METALLIC = 0.0;
	AO = clamp(1.0 - blade_shadow * 0.16, 0.82, 1.0);
	AO_LIGHT_AFFECT = 0.22;
	EMISSION = vec3(0.0);
}
