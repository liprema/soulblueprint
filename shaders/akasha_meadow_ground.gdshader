shader_type spatial;

// Hand-Painted Studio Ghibli / Pixar / Genshin Meadow Ground Shader
// Optimized for 60 FPS on macOS Apple Silicon Metal + FSR 1.0 (0.75x) + TAA:
// - 100% pure unperturbed geometry normals (ZERO dFdx/dFdy/fwidth, ZERO CLEARCOAT in light())
// - Strictly NaN-safe normalize(), atan(), pow(), and strictly ordered smoothstep(a < b)
// - Rich, joyful, glare-free sunlit meadow green palette harmonizing with the Baroque Palace
// - Broad, velvety, softly anti-aliased sunlit gouache bands (ZERO moire, ZERO sub-pixel shimmer)
// - Crisp-yet-smooth 5-petal white daisies with plump golden-marigold centers + golden buttercups
// - Broad soft sunlit-lime clover leaf clusters with generous distance-adaptive anti-aliasing
// - Static calm meadow by default (wind_wave_speed = 0.0, wind_shimmer_strength = 0.0)
// - Clean distance LOD fade (14m -> 48m) so distant hills stay buttery-smooth with zero twinkle

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
	float v = 0.66 * noise2d(p);
	v += 0.34 * noise2d(p * 2.03 + vec2(7.3, -4.9));
	return v;
}

vec2 rot2(vec2 v, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

// NaN-safe 5-petal stylized daisy SDF evaluated cleanly inside a single jittered cell.
// Uses generous distance-adaptive anti-aliasing so flowers stay crisp up close and zero-twinkle at range.
// Returns vec4(drop_shadow, petal_mask, core_mask, variant_seed)
vec4 eval_daisy_cell(vec2 cell_local, vec2 cell_id, float spawn_prob, float min_r, float max_r, float edge_aa, out float out_lobe_shade) {
	vec2 rnd = hash22(cell_id + vec2(19.7, 41.3));
	float spawn_roll = hash21(cell_id + vec2(7.1, 13.9));
	float size_roll = hash21(cell_id + vec2(53.2, 11.8));
	float spawn = step(1.0 - clamp(spawn_prob, 0.0, 0.90), spawn_roll);

	// Keep center inside [0.31, 0.66] so petals + soft drop shadow never clip cell edges
	vec2 center = mix(vec2(0.31), vec2(0.66), rnd);
	float base_r = mix(min_r, max_r, size_roll);
	float rot = rnd.x * 6.2831853;

	vec2 dp = cell_local - center;
	float dp_len = length(dp);
	float ang = dp_len > 0.0001 ? atan(dp.y, dp.x) : 0.0;

	// Smooth 5-lobe polar corolla
	float lobe = cos(5.0 * ang + rot);
	float r_petal = base_r * (0.78 + 0.22 * lobe);
	float aa = max(edge_aa, 0.024);
	float p_lo = max(r_petal - aa, 0.0);
	float p_hi = r_petal + aa;
	float petal_mask = (1.0 - smoothstep(p_lo, p_hi, dp_len)) * spawn;

	// Subtle petal-crease shading near inner notches for plump hand-painted petals
	out_lobe_shade = clamp(0.5 + 0.5 * lobe, 0.0, 1.0) * smoothstep(base_r * 0.28, base_r * 0.96, dp_len);

	// Plump warm golden-marigold center
	float core_r = base_r * 0.44;
	float c_lo = max(core_r - aa * 0.85, 0.0);
	float c_hi = core_r + aa * 0.85;
	float core_mask = (1.0 - smoothstep(c_lo, c_hi, dp_len)) * petal_mask;

	// Soft emerald drop-shadow tucked beneath the flower
	vec2 dp_s = dp - vec2(0.020, 0.026);
	float s_len = length(dp_s);
	float s_ang = s_len > 0.0001 ? atan(dp_s.y, dp_s.x) : 0.0;
	float r_shad = base_r * (0.78 + 0.16 * cos(5.0 * s_ang + rot));
	float s_lo = r_shad * 0.50;
	float s_hi = r_shad + min(aa * 1.45, 0.085);
	float shadow_mask = (1.0 - smoothstep(s_lo, s_hi, s_len)) * spawn;

	return vec4(shadow_mask, petal_mask, core_mask, rnd.y);
}

// Broad, soft sunlit-lime clover leaf clusters around flower pockets (zero sub-pixel aliasing)
// Returns vec2(leaf_shadow, leaf_mask)
vec2 eval_clover_sprigs(vec2 xz, float cluster_bias, float detail_lod) {
	vec2 grid = rot2(xz, -0.45) * 1.72 + vec2(-31.4, 12.7);
	vec2 cell = floor(grid);
	vec2 local = fract(grid);

	vec2 rnd = hash22(cell + vec2(47.1, 83.9));
	float spawn_prob = clamp(0.18 + 0.50 * cluster_bias, 0.0, 0.70);
	float spawn = step(1.0 - spawn_prob, hash21(cell + vec2(12.3, 29.7)));

	vec2 p = local - mix(vec2(0.30), vec2(0.70), rnd);
	p = rot2(p, rnd.x * 6.2831853);

	// Trio of plump broad oval clover leaves
	vec2 p1 = rot2(p - vec2(-0.062, 0.025), 0.42);
	float d1 = length(vec2(p1.x * 1.25, p1.y * 0.86));
	vec2 p2 = rot2(p - vec2(0.062, -0.015), -0.52);
	float d2 = length(vec2(p2.x * 1.30, p2.y * 0.88));
	vec2 p3 = rot2(p - vec2(0.005, -0.062), 0.08);
	float d3 = length(vec2(p3.x * 1.20, p3.y * 0.90));

	float leaf_r = mix(0.082, 0.120, rnd.y);
	float leaf_aa = mix(0.030, 0.078, 1.0 - detail_lod);
	float d_min = min(min(d1, d2), d3);
	float leaf_mask = (1.0 - smoothstep(max(leaf_r - leaf_aa, 0.0), leaf_r + leaf_aa, d_min)) * spawn * detail_lod;

	// Soft tucked shadow under clover cluster
	vec2 ps = p - vec2(0.022, 0.030);
	float ds = length(ps * vec2(0.92, 1.10));
	float leaf_shad = (1.0 - smoothstep(leaf_r * 0.62, leaf_r * 1.45 + leaf_aa * 0.75, ds)) * spawn * detail_lod;

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

	// Clean distance LOD fades so daisies/clover stay buttery-smooth and never twinkle at range
	float cam_dist = length(VERTEX);
	float detail_lod = 1.0 - smoothstep(14.0, 48.0, cam_dist);
	float band_aa = mix(0.11, 0.24, smoothstep(12.0, 65.0, cam_dist));

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

	// 1. Broad, Velvety, Softly Anti-Aliased Sunlit Gouache Bands (zero jagged edges or moire)
	float macro_patch = fbm2_fast(xz * macro_patch_scale + vec2(-5.1, 4.3));
	float band_warp = (fbm2_fast(xz * (macro_patch_scale * 1.12) + vec2(3.4, -2.1)) - 0.5) * 2.4;
	float band_wave = sin(dot(xz, w_perp) * (macro_patch_scale * 4.0) + band_warp) * 0.5 + 0.5;

	float slope_sun = smoothstep(0.30, 0.94, wn.y);
	float sun_facing = clamp(dot(wn, vec3(0.280619, 0.461017, -0.841857)) * 0.5 + 0.5, 0.0, 1.0);
	float base_tone = clamp(band_wave * 0.44 + macro_patch * 0.36 + slope_sun * 0.14 + sun_facing * 0.14 - 0.08, 0.0, 1.0);

	// Gentle low-frequency painterly modulation (no high-frequency teeth or razor lines)
	vec2 tuft_uv = vec2(dot(xz, w_dir), dot(xz, w_perp));
	float soft_aniso = max(blade_anisotropy, 1.0);
	float soft_grain_freq = clamp(blade_grain_scale * 0.085, 0.25, 1.35);
	float gouache_macro = noise2d(vec2(tuft_uv.x * 0.72, tuft_uv.y * 0.48) + vec2(macro_patch * 1.2, -band_warp * 0.35));
	float gouache_soft = noise2d(vec2(tuft_uv.x * soft_grain_freq, tuft_uv.y * (soft_grain_freq / soft_aniso)) + vec2(7.3, -4.1));
	float organic_mod = (gouache_macro - 0.5) * 0.18 + (gouache_soft - 0.5) * 0.08 * detail_lod;

	float painterly_val = clamp(base_tone + organic_mod, 0.0, 1.0);

	// Lush emerald -> meadow -> sunlit-lime gouache palette with wide anti-aliased transitions
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

	vec3 smooth_col = mix(deep_shadow_col, fresh_mid_col, smoothstep(0.10, 0.62, base_tone));
	smooth_col = mix(smooth_col, sunlit_lime_col, smoothstep(0.50, 0.94, base_tone));

	// Velvety painterly bands up close, seamlessly blending into sunlit rolling hills at distance
	vec3 grass_col = mix(smooth_col, stepped_col, 0.55 + 0.25 * detail_lod);

	// Optional vertex color modulation (used on CastleIslandGrass; 0.0 on city meadow)
	if (vertex_color_blend > 0.001) {
		vec3 vcol = clamp(v_vertex_color.rgb, vec3(0.05), vec3(1.5));
		float vcol_luma = dot(vcol, vec3(0.299, 0.587, 0.114));
		vec3 tinted_grass = mix(grass_col, grass_col * (vcol / max(vcol_luma, 0.22)) * mix(0.82, 1.12, clamp(vcol_luma, 0.0, 1.0)), vertex_color_blend);
		grass_col = mix(grass_col, tinted_grass, 0.80);
	}

	// 2. Soft Broad Gouache Depth & Sunlit Highlights (zero sub-pixel strokes)
	float soft_shade = (1.0 - smoothstep(0.18, 0.54, gouache_macro)) * 0.14 * detail_lod;
	float soft_sun = smoothstep(0.56, 0.90, gouache_soft) * 0.11 * detail_lod * (0.45 + 0.55 * slope_sun);
	grass_col = mix(grass_col, valley_emerald_color * 0.80, soft_shade);
	grass_col = mix(grass_col, crest_chartreuse_color * 1.08, soft_sun);

	if (wind_shimmer_strength > 0.0001) {
		grass_col = mix(grass_col, velvet_rim_color, wind_ripple * wind_shimmer_strength * slope_sun);
	}

	// 3. Organic Flower Bouquet Cluster Mask (pockets of daisies with open green bands between)
	float bouquet_noise = fbm2_fast(xz * 0.30 + vec2(-8.3, 5.9));
	float bouquet_mask = smoothstep(0.32, 0.70, bouquet_noise);
	float flat_mask = smoothstep(0.52, 0.86, wn.y);
	float flower_vis = detail_lod * flat_mask;

	// 4. Broad Soft Sunlit-Lime Clover Leaf Clusters around flower pockets
	vec2 clover = eval_clover_sprigs(xz, bouquet_mask, detail_lod);
	vec3 clover_leaf_col = crest_chartreuse_color * vec3(1.16, 1.14, 0.88);
	grass_col = mix(grass_col, valley_emerald_color * 0.72, clover.x * 0.26 * flat_mask);
	grass_col = mix(grass_col, clover_leaf_col, clover.y * 0.76 * flat_mask);

	// 5. Crisp-Yet-Smooth 5-Petal White Daisies & Companion Golden Buttercups
	float flower_aa = mix(0.036, 0.095, 1.0 - detail_lod);

	// Secondary Grid (companion white daisies & warm golden-yellow buttercups)
	vec2 sec_grid = rot2(xz, 0.62) * 2.05 + vec2(17.3, -29.1);
	vec2 sec_cell = floor(sec_grid);
	vec2 sec_local = fract(sec_grid);
	float sec_spawn = daisy_density * (0.12 + 0.82 * bouquet_mask);
	float sec_lobe_shade = 0.0;
	vec4 sec_flower = eval_daisy_cell(sec_local, sec_cell, sec_spawn, 0.125, 0.185, flower_aa, sec_lobe_shade);

	float is_buttercup = step(0.60, sec_flower.w);
	vec3 buttercup_petal = mix(daisy_center_color * vec3(1.06, 1.18, 0.92), daisy_petal_color * vec3(1.0, 0.94, 0.28), 0.24);
	vec3 buttercup_core = daisy_center_color * vec3(0.95, 0.62, 0.35);
	vec3 sec_petal_col = mix(daisy_petal_color * mix(0.93, 1.02, sec_lobe_shade), buttercup_petal, is_buttercup);
	vec3 sec_core_col = mix(daisy_center_color, buttercup_core, is_buttercup);
	vec3 sec_col = mix(sec_petal_col, sec_core_col, sec_flower.z);

	grass_col = mix(grass_col, valley_emerald_color * 0.68, sec_flower.x * 0.30 * flower_vis);
	grass_col = mix(grass_col, sec_col, sec_flower.y * 0.92 * flower_vis);

	// Primary Bouquet Grid (hero 5-petal white daisies with warm golden-marigold centers)
	vec2 pri_grid = xz * 1.42;
	vec2 pri_cell = floor(pri_grid);
	vec2 pri_local = fract(pri_grid);
	float pri_spawn = daisy_density * (0.14 + 0.78 * bouquet_mask);
	float pri_lobe_shade = 0.0;
	vec4 pri_flower = eval_daisy_cell(pri_local, pri_cell, pri_spawn, 0.140, 0.210, flower_aa, pri_lobe_shade);

	vec3 pri_petal_col = daisy_petal_color * mix(0.92, 1.02, pri_lobe_shade);
	vec3 pri_core_col = mix(daisy_center_color * vec3(0.96, 0.82, 0.72), daisy_center_color * 1.06, pri_flower.z);
	vec3 pri_col = mix(pri_petal_col, pri_core_col, pri_flower.z);

	grass_col = mix(grass_col, valley_emerald_color * 0.66, pri_flower.x * 0.36 * flower_vis);
	grass_col = mix(grass_col, pri_col, pri_flower.y * 0.95 * flower_vis);

	// 6. Soft Matte Velvet Fresnel Rim Sheen on Sunlit Hilltops (NaN-safe, zero glare)
	float n_len = length(NORMAL);
	vec3 n_view = n_len > 0.0001 ? (NORMAL / n_len) : vec3(0.0, 0.0, 1.0);
	float v_len = length(VIEW);
	vec3 v_view = v_len > 0.0001 ? (VIEW / v_len) : vec3(0.0, 0.0, 1.0);
	float ndotv = clamp(dot(n_view, v_view), 0.0, 1.0);
	float velvet_fresnel = pow(max(1.0 - ndotv, 0.0001), 2.5);

	float rim_factor = velvet_fresnel * velvet_rim_strength * smoothstep(0.20, 0.86, wn.y);
	grass_col = mix(grass_col, velvet_rim_color, clamp(rim_factor, 0.0, 0.28));

	// Glare-free matte velvet finish
	float final_rough = clamp(base_roughness + soft_shade * 0.06 - soft_sun * 0.04, 0.84, 0.92);

	ALBEDO = clamp(grass_col, vec3(0.0), vec3(1.0));
	ROUGHNESS = final_rough;
	SPECULAR = surface_specular;
	METALLIC = 0.0;
	AO = clamp(1.0 - soft_shade * 0.25, 0.84, 1.0);
	AO_LIGHT_AFFECT = 0.22;
	EMISSION = vec3(0.0);
}
