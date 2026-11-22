shader_type sky;

// Akasha Celestial Twilight Sky Dome
// Painterly AAA twilight inspired by Sky: Children of the Light, Journey, and Stray.
// Palette: #050918 (Velvet Cosmic Indigo), #0D1E3E (Sapphire-Indigo), #1D4866 (Cerulean-Teal),
// #D89A58 (Silky Amber-Peach), #8E4F34 (Warm Terracotta-Amber), #030610 (Nocturnal Abyss).

group_uniforms sky_palette;
uniform vec3 zenith_color : source_color = vec3(0.020, 0.035, 0.094);       // #050918 Deep Velvet Cosmic Indigo
uniform vec3 upper_indigo_color : source_color = vec3(0.051, 0.118, 0.243); // #0D1E3E Rich Sapphire-Indigo
uniform vec3 mid_sky_color : source_color = vec3(0.114, 0.282, 0.400);      // #1D4866 Atmospheric Cerulean-Teal
uniform vec3 horizon_color : source_color = vec3(0.847, 0.604, 0.345);      // #D89A58 Silky Amber-Peach
uniform vec3 horizon_amber : source_color = vec3(0.557, 0.310, 0.204);      // #8E4F34 Warm Terracotta-Amber
uniform vec3 nadir_color : source_color = vec3(0.012, 0.024, 0.063);        // #030610 Nocturnal Abyss

group_uniforms sun_and_mie;
uniform vec3 sun_direction = vec3(0.0, 0.14, -1.0);                         // -Z toward the Astrolabe Cathedral
uniform vec3 sun_color : source_color = vec3(1.0, 0.910, 0.745);            // Soft warm ivory-amber
uniform float sun_disk_size : hint_range(0.008, 0.12) = 0.032;
uniform float sun_disk_intensity : hint_range(0.0, 3.0) = 1.35;
uniform float mie_inner_strength : hint_range(0.0, 2.5) = 0.68;
uniform float mie_outer_strength : hint_range(0.0, 2.0) = 0.46;
uniform float horizon_glow_strength : hint_range(0.0, 2.0) = 0.85;

group_uniforms akashic_river;
uniform float river_strength : hint_range(0.0, 1.5) = 0.58;
uniform vec3 river_indigo_color : source_color = vec3(0.196, 0.173, 0.388); // Soft indigo-violet dust
uniform vec3 river_cyan_color : source_color = vec3(0.282, 0.635, 0.765);   // Ethereal cyan wisps
uniform vec3 river_gold_color : source_color = vec3(0.910, 0.725, 0.460);   // Warm golden star-cloud core

group_uniforms twilight_clouds;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.54;
uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.78;
uniform float cloud_speed : hint_range(0.0, 0.08) = 0.008;
uniform vec3 cloud_top_color : source_color = vec3(0.090, 0.155, 0.265);    // Deep twilight indigo-slate
uniform vec3 cloud_lit_color : source_color = vec3(0.945, 0.710, 0.475);    // Warm peach-gold sunlit underside

group_uniforms ethereal_aurora;
uniform float aurora_strength : hint_range(0.0, 1.0) = 0.26;
uniform float aurora_speed : hint_range(0.0, 0.2) = 0.028;
uniform vec3 aurora_cyan_color : source_color = vec3(0.320, 0.785, 0.790);  // Translucent painterly cyan
uniform vec3 aurora_gold_color : source_color = vec3(0.925, 0.805, 0.560);  // Pale champagne gold

group_uniforms celestial_stars;
uniform float star_density : hint_range(0.0, 1.0) = 0.72;
uniform float star_brightness : hint_range(0.0, 2.5) = 1.15;
uniform float star_twinkle_speed : hint_range(0.0, 3.0) = 0.85;
uniform float star_scale : hint_range(40.0, 220.0) = 112.0;

// --- Cheap, Artifact-Free Hash & Value Noise Helpers ---

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float hash31(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p.zxy, p.yxz + 19.19);
	return fract(p.x * p.y * p.z);
}

vec3 hash33(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yxz + 19.19);
	return fract((p.xxy + p.yxx) * p.zyx);
}

float value_noise_2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float value_noise_3d(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float n000 = hash31(i);
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));

	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);

	return mix(mix(nx00, nx10, f.y), mix(nx01, nx11, f.y), f.z);
}

// Max 3 octaves per FBM for steady 60 FPS on macOS Retina
float fbm2_2d(vec2 p) {
	float v = 0.0;
	v += 0.65 * value_noise_2d(p);
	p = mat2(vec2(1.62, 1.22), vec2(-1.22, 1.62)) * p + vec2(11.3, 7.7);
	v += 0.35 * value_noise_2d(p);
	return v;
}

float fbm3_2d(vec2 p) {
	float v = 0.0;
	float amp = 0.54;
	mat2 rot = mat2(vec2(1.62, 1.22), vec2(-1.22, 1.62));
	for (int i = 0; i < 3; i++) {
		v += amp * value_noise_2d(p);
		p = rot * p + vec2(13.1, -8.7);
		amp *= 0.48;
	}
	return v;
}

float fbm3_3d(vec3 p) {
	float v = 0.0;
	float amp = 0.54;
	for (int i = 0; i < 3; i++) {
		v += amp * value_noise_3d(p);
		p = p * 2.04 + vec3(11.7, -6.3, 4.9);
		amp *= 0.48;
	}
	return v;
}

float sq(float x) {
	return x * x;
}

// Smooth Henyey-Greenstein phase function for silky Mie scattering
float hg_phase(float cos_theta, float g) {
	float g2 = g * g;
	float denom = max(1.0 + g2 - 2.0 * g * cos_theta, 0.001);
	return (1.0 - g2) / (4.0 * 3.14159265 * pow(denom, 1.5));
}

// Anti-aliased soft-cored star layer with varied color temperature & gentle breathing twinkle
vec3 star_layer(vec3 dir, float scale, float threshold, float time_val, float size_min, float size_max, bool hero) {
	vec3 p = dir * scale;
	vec3 cell = floor(p);
	vec3 local = fract(p) - 0.5;

	vec3 rnd = hash33(cell);
	if (rnd.x < threshold) {
		return vec3(0.0);
	}

	vec3 offset = (rnd - 0.5) * 0.56;
	vec3 delta = local - offset;
	float dist = length(delta);

	// Soft-cored profile prevents 1-pixel flickering under 0.75x scaling and TAA
	float radius = mix(size_min, size_max, rnd.y);
	float core = smoothstep(radius, radius * 0.08, dist);
	core = core * core;

	// Subtle soft halo around brighter hero stars
	float halo = 0.0;
	if (hero && rnd.y > 0.55) {
		float h = smoothstep(radius * 2.4, 0.0, dist);
		halo = h * h * 0.32;
	}

	// Slow, meditative breathing twinkle
	float phase = rnd.z * 6.2831853 + time_val * star_twinkle_speed * mix(0.55, 1.35, rnd.y);
	float twinkle = 0.74 + 0.26 * sin(phase);

	// Multi-temperature stellar palette: pale ice-blue, warm ivory, soft gold
	float temp = fract(rnd.z * 17.31 + rnd.y * 5.17);
	vec3 col_ice = vec3(0.76, 0.89, 1.0);
	vec3 col_ivory = vec3(1.0, 0.96, 0.89);
	vec3 col_gold = vec3(1.0, 0.83, 0.58);
	vec3 star_col = temp < 0.5
		? mix(col_ice, col_ivory, temp * 2.0)
		: mix(col_ivory, col_gold, (temp - 0.5) * 2.0);

	float lum = (core + halo) * twinkle * mix(0.55, 1.15, rnd.y);
	return star_col * lum;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 sun_dir = normalize(sun_direction);
	float elev = dir.y;
	float cos_sun = dot(dir, sun_dir);
	float sun_dot = max(cos_sun, 0.0);

	// Directional azimuth alignment toward the -Z Cathedral sun axis (safe at zenith)
	float dir_xz_len = length(dir.xz);
	vec2 dir_xz = dir_xz_len > 0.0001 ? dir.xz / dir_xz_len : vec2(0.0, -1.0);
	float sun_xz_len = length(sun_dir.xz);
	vec2 sun_xz = sun_xz_len > 0.0001 ? sun_dir.xz / sun_xz_len : vec2(0.0, -1.0);
	float azimuth_sun = clamp(dot(dir_xz, sun_xz) * 0.5 + 0.5, 0.0, 1.0);
	float sun_side = pow(azimuth_sun, 1.8);

	// -------------------------------------------------------------------------
	// 1. Rich Multi-Layered Celestial Twilight Gradient
	// -------------------------------------------------------------------------
	// Warm amber-peach horizon concentrated toward -Z Cathedral, cooler dusk opposite
	vec3 cool_horizon = mix(upper_indigo_color, mid_sky_color, 0.72) + horizon_amber * 0.14;
	vec3 warm_horizon = mix(horizon_amber, horizon_color, smoothstep(-0.04, 0.055, elev));
	vec3 horiz_base = mix(cool_horizon, warm_horizon, mix(0.24, 1.0, sun_side));

	float mid_t = smoothstep(0.015, 0.30, elev);
	float upper_t = smoothstep(0.18, 0.58, elev);
	float zenith_t = smoothstep(0.46, 0.92, elev);

	vec3 sky_col = mix(horiz_base, mid_sky_color, mid_t);
	sky_col = mix(sky_col, upper_indigo_color, upper_t);
	sky_col = mix(sky_col, zenith_color, zenith_t);

	// Soft atmospheric cerulean-teal veil hovering above the horizon band
	float teal_band = exp(-sq((elev - 0.17) * 5.2));
	sky_col += mid_sky_color * teal_band * mix(0.16, 0.28, sun_side);

	// Warm silky amber-peach horizon bloom concentrated behind the Cathedral (-Z)
	float horiz_belt = exp(-abs(elev - 0.018) * 7.5);
	float wide_belt = exp(-abs(elev - 0.05) * 3.4);
	vec3 warm_bloom_col = mix(horizon_amber, horizon_color, 0.65);
	sky_col += warm_bloom_col * (horiz_belt * pow(azimuth_sun, 2.4) * 0.62 + wide_belt * pow(sun_dot, 2.2) * 0.36) * horizon_glow_strength;

	// Seamless transition into deep nocturnal abyss below the cloud sea (dir.y < 0)
	float nadir_t = smoothstep(0.02, -0.32, elev);
	sky_col = mix(sky_col, nadir_color, nadir_t);

	// -------------------------------------------------------------------------
	// 2. Sweeping Akashic Starlight River (Tilted Milky Way Arch)
	// -------------------------------------------------------------------------
	float mw_band_mask = 0.0;
	if (elev > -0.02 && river_strength > 0.001) {
		// Orthonormal tilted galactic frame arching diagonally across the upper vault
		vec3 gal_normal = normalize(vec3(0.60, 0.44, 0.668));
		vec3 gal_u = normalize(cross(vec3(0.0, 1.0, 0.0), gal_normal));
		vec3 gal_v = cross(gal_normal, gal_u);

		float gal_lat = dot(dir, gal_normal);
		vec3 gal_dir = vec3(dot(dir, gal_u), gal_lat, dot(dir, gal_v));

		float river_outer = exp(-sq(gal_lat * 2.1));
		float river_core = exp(-sq(gal_lat * 5.2));
		float river_elev = smoothstep(0.03, 0.30, elev);
		float river_sun_fade = 1.0 - smoothstep(0.55, 0.94, sun_dot) * 0.72;

		if (river_outer * river_elev > 0.004) {
			vec3 flow_p = gal_dir * vec3(2.8, 5.2, 2.8) + vec3(TIME * 0.0012, 0.0, -TIME * 0.0008);
			float n_broad = fbm3_3d(flow_p);
			float n_wisp = fbm3_3d(gal_dir * vec3(6.0, 9.5, 6.0) + vec3(n_broad * 1.1, 0.0, -n_broad * 0.9));

			// Subtle dark cosmic dust rift threading through the bright star-cloud core
			float dust_rift = smoothstep(0.46, 0.76, n_wisp) * exp(-sq(gal_lat * 10.0));

			float indigo_cloud = smoothstep(0.24, 0.76, n_broad) * river_outer;
			float cyan_wisps = smoothstep(0.38, 0.80, n_broad * 0.55 + n_wisp * 0.45) * river_outer;
			float gold_core = smoothstep(0.32, 0.78, n_broad * 0.7 + n_wisp * 0.3) * river_core;

			vec3 river_col = river_indigo_color * indigo_cloud * 0.58
				+ river_cyan_color * cyan_wisps * 0.34
				+ river_gold_color * gold_core * 0.42;

			river_col *= (1.0 - dust_rift * 0.52);

			float river_vis = river_elev * river_sun_fade * river_strength;
			sky_col += river_col * river_vis;
			mw_band_mask = river_core * river_elev * river_sun_fade;
		}
	}

	// -------------------------------------------------------------------------
	// 3. Silky Ethereal Aurora Curtains (High Vault)
	// -------------------------------------------------------------------------
	if (elev > 0.10 && aurora_strength > 0.001) {
		float aurora_elev = smoothstep(0.14, 0.36, elev) * smoothstep(0.92, 0.50, elev);
		if (aurora_elev > 0.002) {
			vec2 aur_uv = dir.xz / (elev + 0.38);
			float t_aur = TIME * aurora_speed;

			// Gently undulating curtain ribbons
			float wave_a = sin(aur_uv.x * 1.45 + aur_uv.y * 0.65 + t_aur * 1.4) * 0.55
				+ sin(aur_uv.x * 2.8 - aur_uv.y * 1.2 - t_aur * 0.9) * 0.25;
			float curtain_n = fbm2_2d(vec2(aur_uv.x * 1.35 + t_aur * 0.35, aur_uv.y * 0.85 + wave_a * 0.6));

			float ribbon_1 = exp(-sq((curtain_n - 0.54) * 7.8));
			float ribbon_2 = exp(-sq((curtain_n - 0.36) * 9.2)) * 0.55;

			// Soft vertical silk striations
			float silk = 0.65 + 0.35 * value_noise_2d(vec2(aur_uv.x * 6.5 + wave_a * 2.2, elev * 2.2 - t_aur * 0.5));

			float curtain_val = (ribbon_1 + ribbon_2) * silk * aurora_elev;
			vec3 aurora_tint = mix(aurora_cyan_color, aurora_gold_color, smoothstep(0.24, 0.68, elev));
			// Keep aurora poetic and unobtrusive near the bright sun
			float aur_sun_fade = 1.0 - smoothstep(0.65, 0.96, sun_dot) * 0.65;
			sky_col += aurora_tint * curtain_val * aurora_strength * aur_sun_fade * 0.62;
		}
	}

	// -------------------------------------------------------------------------
	// 4. Silky Double-Layered Mie Scattering Sun Corona (No Radial Spokes)
	// -------------------------------------------------------------------------
	float above_nadir = smoothstep(-0.18, 0.04, elev);
	if (above_nadir > 0.001) {
		float sun_angle = acos(clamp(cos_sun, -1.0, 1.0));
		// Soft-edged solar disk with controlled peak luminance (no harsh white blowout)
		float sun_disk = smoothstep(sun_disk_size * 1.45, sun_disk_size * 0.25, sun_angle);
		sun_disk = sun_disk * sun_disk;

		// Dual-lobe Henyey-Greenstein Mie scattering: tight inner corona + wide silky veil
		float mie_inner = min(hg_phase(cos_sun, 0.92) * 0.14, 1.65);
		float mie_outer = min(hg_phase(cos_sun, 0.62) * 0.42, 0.85);
		float soft_aureole = pow(sun_dot, 5.0) * 0.28;

		vec3 corona = sun_color * (sun_disk * sun_disk_intensity + mie_inner * mie_inner_strength)
			+ mix(horizon_color, sun_color, 0.38) * ((mie_outer + soft_aureole) * mie_outer_strength);

		sky_col += corona * above_nadir;
	}

	// -------------------------------------------------------------------------
	// 5. Anti-Aliased Multi-Temperature Starfield (Before Clouds for Occlusion)
	// -------------------------------------------------------------------------
	float star_vis = smoothstep(0.04, 0.32, elev) * (1.0 - smoothstep(0.68, 0.96, sun_dot));
	vec3 stars_col = vec3(0.0);
	if (!AT_CUBEMAP_PASS && star_vis > 0.002 && star_density > 0.001) {
		float dens_boost = clamp(star_density + mw_band_mask * 0.16, 0.0, 0.98);
		float th_hero = mix(0.992, 0.948, star_density);
		float th_mid = mix(0.986, 0.916, dens_boost);
		float th_fine = mix(0.990, 0.932, dens_boost);

		vec3 s_hero = star_layer(dir, star_scale * 0.56, th_hero, TIME * 0.75, 0.085, 0.170, true);
		vec3 s_mid = star_layer(dir + vec3(0.37, 0.19, -0.53), star_scale * 1.02, th_mid, TIME * 1.0, 0.075, 0.140, false);
		vec3 s_fine = star_layer(dir + vec3(-0.61, 0.41, 0.27), star_scale * 1.58, th_fine, TIME * 1.25, 0.070, 0.125, false);

		stars_col = (s_hero * 1.25 + s_mid * 0.78 + s_fine * 0.42) * star_brightness * star_vis;
	}

	// -------------------------------------------------------------------------
	// 6. Painterly High-Altitude Twilight Clouds (Cirrus & Layered Wisps)
	// -------------------------------------------------------------------------
	float cloud_alpha = 0.0;
	vec3 cloud_col = vec3(0.0);

	if (elev > 0.015 && cloud_coverage > 0.001 && cloud_opacity > 0.001) {
		float cloud_horizon_fade = smoothstep(0.02, 0.20, elev);
		if (cloud_horizon_fade > 0.001) {
			vec2 cloud_uv = dir.xz / (elev + 0.22);
			vec2 drift = vec2(TIME * cloud_speed, -TIME * cloud_speed * 0.42);

			// Layer A: Broad painterly stratocirrus banks
			vec2 uv_main = cloud_uv * 0.34 + drift;
			float warp = fbm2_2d(uv_main * 1.15 - drift * 0.5);
			float n_main = fbm3_2d(uv_main + vec2(warp * 0.55, -warp * 0.35));

			// Layer B: High swept cirrus wisps
			vec2 uv_cirrus = cloud_uv * vec2(0.72, 0.42) + drift * 1.45 + vec2(3.7, -2.1);
			float n_cirrus = fbm2_2d(uv_cirrus + vec2(warp * 0.3, 0.0));

			float cov_thresh = mix(0.76, 0.34, cloud_coverage);
			float main_density = smoothstep(cov_thresh, cov_thresh + 0.30, n_main);
			float cirrus_density = smoothstep(cov_thresh + 0.06, cov_thresh + 0.36, n_cirrus) * 0.52;

			float total_density = clamp(main_density + cirrus_density * (1.0 - main_density * 0.5), 0.0, 1.0);
			cloud_alpha = total_density * cloud_horizon_fade * cloud_opacity;

			if (cloud_alpha > 0.002) {
				// Cheap sun-facing edge sample for sunlit peach-gold undersides vs deep indigo tops
				vec2 sun_step = sun_xz * 0.14;
				float n_sun = fbm2_2d(uv_main + sun_step + vec2(warp * 0.55, -warp * 0.35));
				float edge_lit = clamp((n_main - n_sun) * 2.4 + 0.48, 0.0, 1.0);

				// Forward-scattered golden-peach glow strongest facing the Cathedral sun
				float sun_scatter = pow(sun_dot, 3.2) * 0.85 + pow(sun_dot, 12.0) * 0.65;
				float underside_light = clamp(edge_lit * (0.28 + 0.72 * sun_side) + sun_scatter * 0.55, 0.0, 1.0);
				// Thinner cirrus edges catch more warm light; thick cores stay deep twilight slate
				float thin_boost = (1.0 - main_density * 0.55);

				vec3 shadow_col = mix(cloud_top_color, upper_indigo_color * 0.95, smoothstep(0.15, 0.70, elev));
				vec3 lit_col = mix(horizon_color, cloud_lit_color, 0.65);

				cloud_col = mix(shadow_col, lit_col, clamp(underside_light * thin_boost, 0.0, 1.0));
				// Silky silver-peach Mie rim when clouds drift across the sun corona
				cloud_col += sun_color * pow(sun_dot, 8.0) * (1.0 - main_density * 0.45) * 0.38;
			}
		}
	}

	// Composite stars (softly occluded by clouds) and blend painterly twilight clouds over sky
	sky_col += stars_col * (1.0 - cloud_alpha * 0.88);
	sky_col = mix(sky_col, cloud_col, cloud_alpha);

	COLOR = sky_col;
}
