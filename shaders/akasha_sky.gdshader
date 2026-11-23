shader_type sky;

// Akasha Celestial Dawn Sky Dome
// Hand-painted Makoto Shinkai / Sky: Children of the Light / Akashic Chronicles masterpiece.
// Fast, NaN-safe (Metal/Vulkan), 60 FPS friendly on macOS Retina (Godot 4.3 Forward Plus).
//
// Palette:
//   Sapphire Zenith       #164EC2 -> Cerulean Upper Sky    #388EF2 -> Pastel Sky-Aqua      #78D2F8
//   Sakura-Rose Horizon   #FF9EB8 -> Coral-Apricot Dawn    #FFC294 -> Periwinkle Opposite  #B8A8EA
//   Cumulus Shadow Base   #5E67AC -> Pearl Midtone         #EDE4F5 -> Coral-Peach Bounce   #FFA892 -> Ivory-Gold Rim #FFF7DF

group_uniforms sky_palette;
uniform vec3 zenith_color : source_color = vec3(0.086, 0.306, 0.761);           // #164EC2 Deep luminous sapphire zenith
uniform vec3 upper_indigo_color : source_color = vec3(0.220, 0.557, 0.949);     // #388EF2 Vivid cerulean upper sky
uniform vec3 mid_sky_color : source_color = vec3(0.471, 0.824, 0.973);          // #78D2F8 Dreamy pastel sky-aqua
uniform vec3 horizon_warm_color : source_color = vec3(1.000, 0.620, 0.722);     // #FF9EB8 Warm sakura-rose horizon
uniform vec3 horizon_amber_color : source_color = vec3(1.000, 0.761, 0.580);    // #FFC294 Coral-apricot dawn glow
uniform vec3 horizon_cool_color : source_color = vec3(0.722, 0.659, 0.918);     // #B8A8EA Soft periwinkle-lavender opposite sun
uniform vec3 nadir_color : source_color = vec3(0.510, 0.612, 0.835);            // #829CD5 Luminous soft periwinkle-azure below

group_uniforms sun_and_mie;
uniform vec3 sun_direction = vec3(0.0, 0.16, -1.0);                             // -Z toward the Astrolabe Cathedral
uniform vec3 sun_color : source_color = vec3(1.000, 0.953, 0.855);              // Silky warm ivory-gold sunlight
uniform float sun_disk_size : hint_range(0.008, 0.12) = 0.032;
uniform float sun_disk_intensity : hint_range(0.0, 3.0) = 1.05;
uniform float mie_inner_strength : hint_range(0.0, 2.5) = 0.52;
uniform float mie_outer_strength : hint_range(0.0, 2.0) = 0.38;
uniform float horizon_glow_strength : hint_range(0.0, 2.0) = 0.52;

group_uniforms horizon_cumulus;
uniform float cumulus_opacity : hint_range(0.0, 1.0) = 0.92;
uniform float cumulus_height : hint_range(0.10, 0.32) = 0.24;
uniform float cumulus_speed : hint_range(0.0, 0.08) = 0.006;
uniform vec3 cumulus_shadow_color : source_color = vec3(0.565, 0.604, 0.816);   // #909AD0 Soft periwinkle-lavender shadow base
uniform vec3 cumulus_body_color : source_color = vec3(0.965, 0.925, 0.965);     // #F6ECF6 Plush pearl-blush midtone
uniform vec3 cumulus_bounce_color : source_color = vec3(1.000, 0.745, 0.745);   // #FFBEBE Soft sakura-peach bounce light
uniform vec3 cumulus_rim_color : source_color = vec3(1.000, 0.980, 0.925);      // #FFFAEC Sunlit ivory-cream rim

group_uniforms twilight_clouds;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.34;
uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.28;
uniform float cloud_speed : hint_range(0.0, 0.08) = 0.007;
uniform vec3 cloud_shadow_color : source_color = vec3(0.710, 0.790, 0.945);     // Airy periwinkle-blue high cloud underside
uniform vec3 cloud_body_color : source_color = vec3(0.976, 0.984, 1.000);       // Soft cotton-white overhead clouds
uniform vec3 cloud_lit_color : source_color = vec3(1.000, 0.910, 0.905);        // Sunlit cream-blush high clouds

group_uniforms celestial_moon;
uniform float moon_strength : hint_range(0.0, 2.0) = 1.0;
uniform vec3 moon_direction = vec3(0.46, 0.54, -0.70);                          // High upper-right azure vault
uniform float moon_radius : hint_range(0.012, 0.07) = 0.032;
uniform float moon_crescent_offset : hint_range(0.2, 0.85) = 0.56;
uniform vec3 moon_color : source_color = vec3(1.000, 0.980, 0.930);             // Luminous pearl-ivory moonlit limb
uniform vec3 moon_halo_color : source_color = vec3(0.840, 0.925, 1.000);        // Soft opalescent sky-pearl halo

group_uniforms astral_ring;
uniform float river_strength : hint_range(0.0, 1.5) = 0.0;
uniform float iridescent_strength : hint_range(0.0, 1.5) = 0.0;
uniform vec3 river_gold_color : source_color = vec3(1.000, 0.935, 0.785);       // Gossamer golden-pearl celestial filament (disabled)
uniform vec3 river_cyan_color : source_color = vec3(0.760, 0.925, 0.990);       // Opalescent ice-aqua harmonic arc (disabled)

group_uniforms celestial_stars;
uniform float star_density : hint_range(0.0, 1.0) = 0.62;
uniform float star_brightness : hint_range(0.0, 2.5) = 0.72;
uniform float star_twinkle_speed : hint_range(0.0, 3.0) = 0.90;
uniform float star_scale : hint_range(40.0, 220.0) = 116.0;

// --- NaN-Safe Math Helpers (Metal & Vulkan Safe) ---

float sq(float x) {
	return x * x;
}

float cube(float x) {
	return x * x * x;
}

float safe_pow(float x, float p) {
	return pow(max(x, 0.0001), p);
}

vec3 safe_normalize(vec3 v, vec3 fallback) {
	float len2 = dot(v, v);
	return len2 > 1e-8 ? v * inversesqrt(len2) : fallback;
}

// --- Cheap, Artifact-Free Hash & Value Noise ---

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
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

// Horizontally periodic 2D value noise for 100% seamless 360-degree horizon cumulus towers
float value_noise_2d_p(vec2 p, float period_x) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float ix0 = mod(i.x, period_x);
	float ix1 = mod(i.x + 1.0, period_x);

	float a = hash21(vec2(ix0, i.y));
	float b = hash21(vec2(ix1, i.y));
	float c = hash21(vec2(ix0, i.y + 1.0));
	float d = hash21(vec2(ix1, i.y + 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Max 3 octaves per FBM for steady 60 FPS on macOS Retina
float fbm2_2d(vec2 p) {
	float v = 0.0;
	v += 0.64 * value_noise_2d(p);
	p = mat2(vec2(1.62, 1.22), vec2(-1.22, 1.62)) * p + vec2(11.3, 7.7);
	v += 0.36 * value_noise_2d(p);
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

// Seamless periodic 2-octave & 3-octave FBM along X (integer frequency doubling preserves period)
float fbm2_2d_p(vec2 p, float period_x) {
	float v = 0.0;
	v += 0.64 * value_noise_2d_p(p, period_x);
	v += 0.36 * value_noise_2d_p(vec2(p.x * 2.0 + 3.7, p.y * 2.05 + 5.1), period_x * 2.0);
	return v;
}

float fbm3_2d_p(vec2 p, float period_x) {
	float v = 0.0;
	v += 0.54 * value_noise_2d_p(p, period_x);
	v += 0.29 * value_noise_2d_p(vec2(p.x * 2.0 + 4.3, p.y * 2.08 - 3.7), period_x * 2.0);
	v += 0.17 * value_noise_2d_p(vec2(p.x * 4.0 - 2.9, p.y * 4.12 + 6.4), period_x * 4.0);
	return v;
}

// Billowy cauliflower shaping for sculpted painted cumulus lobes
float billow_shape(float n) {
	float b = 1.0 - abs(n * 2.0 - 1.0);
	return mix(n, b * b, 0.44);
}

// Smooth Henyey-Greenstein phase function for silky Mie scattering
float hg_phase(float cos_theta, float g) {
	float g2 = g * g;
	float denom = max(1.0 + g2 - 2.0 * g * cos_theta, 0.001);
	return (1.0 - g2) / (4.0 * 3.14159265 * safe_pow(denom, 1.5));
}

// Anti-aliased soft-cored constellation & stardust layer
vec3 star_layer(vec3 dir, float scale, float threshold, float time_val, float size_min, float size_max, bool hero) {
	vec3 p = dir * scale;
	vec3 cell = floor(p);
	vec3 local = fract(p) - 0.5;

	vec3 rnd = hash33(cell);
	if (rnd.x < threshold) {
		return vec3(0.0);
	}

	vec3 offset = (rnd - 0.5) * 0.54;
	vec3 delta = local - offset;
	float dist = length(delta);

	// Soft-cored anti-aliased profile prevents sub-pixel shimmering on Retina + TAA
	float radius = mix(size_min, size_max, rnd.y);
	float core = smoothstep(radius, radius * 0.10, dist);
	core = core * core;

	// Subtle pearlescent halo + gentle 4-point cross-sparkle on brightest hero constellation stars
	float halo = 0.0;
	if (hero && rnd.y > 0.48) {
		float h = smoothstep(radius * 2.5, 0.0, dist);
		halo = h * h * 0.34;

		if (rnd.y > 0.72) {
			float glint_x = exp(-abs(delta.x) / max(radius * 0.22, 0.004)) * exp(-abs(delta.y) / max(radius * 1.45, 0.01));
			float glint_y = exp(-abs(delta.y) / max(radius * 0.22, 0.004)) * exp(-abs(delta.x) / max(radius * 1.45, 0.01));
			halo += (glint_x + glint_y) * 0.26 * smoothstep(radius * 2.8, 0.0, dist);
		}
	}

	// Slow, meditative breathing twinkle
	float phase = rnd.z * 6.2831853 + time_val * star_twinkle_speed * mix(0.55, 1.35, rnd.y);
	float twinkle = 0.72 + 0.28 * sin(phase);

	// Refined celestial stellar temperature palette: sapphire-ice, warm pearl-ivory, pale gold
	float temp = fract(rnd.z * 17.31 + rnd.y * 5.17);
	vec3 col_ice = vec3(0.75, 0.89, 1.00);
	vec3 col_ivory = vec3(1.00, 0.97, 0.91);
	vec3 col_gold = vec3(1.00, 0.86, 0.62);
	vec3 star_col = temp < 0.5
		? mix(col_ice, col_ivory, temp * 2.0)
		: mix(col_ivory, col_gold, (temp - 0.5) * 2.0);

	float lum = (core + halo) * twinkle * mix(0.55, 1.20, rnd.y);
	return star_col * lum;
}

void sky() {
	vec3 dir = safe_normalize(EYEDIR, vec3(0.0, 1.0, 0.0));
	vec3 sun_dir = safe_normalize(sun_direction, vec3(0.0, 0.16, -1.0));
	float elev = dir.y;
	float cos_sun = clamp(dot(dir, sun_dir), -1.0, 1.0);
	float sun_dot = max(cos_sun, 0.0);

	// Guarded horizontal direction & azimuth relative to the -Z Cathedral axis
	float dir_xz_len = length(dir.xz);
	vec2 dir_xz = dir_xz_len > 0.0001 ? dir.xz / dir_xz_len : vec2(0.0, -1.0);
	float sun_xz_len = length(sun_dir.xz);
	vec2 sun_xz = sun_xz_len > 0.0001 ? sun_dir.xz / sun_xz_len : vec2(0.0, -1.0);

	float azimuth_sun = clamp(dot(dir_xz, sun_xz) * 0.5 + 0.5, 0.0, 1.0);
	float sun_side = safe_pow(azimuth_sun, 1.65);

	// Guarded azimuth angle centered on -Z (az = 0 at -Z Cathedral, +/-PI at +Z)
	float az = dir_xz_len > 0.0001 ? atan(dir.x, -dir.z) : 0.0;

	// =========================================================================
	// 1. Rich, Vivid Multi-Stop Azure-to-Sakura-Dawn Gradient
	// =========================================================================
	// Sakura-rose & coral-apricot dawn band around -Z Cathedral; soft periwinkle-lavender opposite
	vec3 warm_horizon = mix(horizon_amber_color, horizon_warm_color, smoothstep(-0.02, 0.085, elev));
	vec3 cool_horizon = mix(horizon_cool_color, mid_sky_color, smoothstep(0.0, 0.16, elev) * 0.30);
	vec3 horiz_base = mix(cool_horizon, warm_horizon, mix(0.18, 1.0, sun_side));

	// Multi-stop vertical atmospheric ramp: Horizon -> Sky-Aqua -> Cerulean -> Sapphire Zenith
	float aqua_t = smoothstep(0.02, 0.25, elev);
	float cerulean_t = smoothstep(0.16, 0.52, elev);
	float sapphire_t = smoothstep(0.42, 0.88, elev);

	vec3 sky_col = mix(horiz_base, mid_sky_color, aqua_t);
	sky_col = mix(sky_col, upper_indigo_color, cerulean_t);
	sky_col = mix(sky_col, zenith_color, sapphire_t);

	// Delicate luminous sky-aqua atmospheric scatter band above the sakura horizon
	float aqua_band = exp(-sq((elev - 0.19) * 5.4));
	sky_col = mix(sky_col, mid_sky_color, aqua_band * mix(0.10, 0.20, sun_side));

	// Warm coral-apricot & sakura-rose horizon belt bloom behind the Cathedral (-Z)
	float horiz_belt = exp(-abs(elev - 0.018) * 8.0);
	float wide_belt = exp(-abs(elev - 0.055) * 3.8);
	vec3 dawn_bloom_col = mix(horizon_amber_color, horizon_warm_color, 0.55);
	float az_focus = safe_pow(azimuth_sun, 2.5);
	sky_col += dawn_bloom_col * (horiz_belt * az_focus * 0.34 + wide_belt * sq(sun_dot) * 0.22) * horizon_glow_strength;

	// Soft luminous periwinkle-azure nadir reflection below horizon (never dark black)
	float nadir_t = smoothstep(0.015, -0.34, elev);
	vec3 nadir_warm = mix(nadir_color, mix(horizon_cool_color, horizon_warm_color, 0.45), sun_side * 0.28);
	sky_col = mix(sky_col, nadir_warm, nadir_t);

	// =========================================================================
	// 2. Silky Warm Sun Corona (Clean Double-Lobe Mie Scattering, No Harsh Glare)
	// =========================================================================
	float above_nadir = smoothstep(-0.14, 0.04, elev);
	if (above_nadir > 0.001) {
		float sun_angle = acos(cos_sun);
		float sun_disk = smoothstep(sun_disk_size * 1.48, sun_disk_size * 0.24, sun_angle);
		sun_disk = sun_disk * sun_disk;

		// Tight silky inner Mie lobe + wide warm coral-champagne outer veil
		float mie_inner = min(hg_phase(cos_sun, 0.91) * 0.11, 1.15);
		float mie_outer = min(hg_phase(cos_sun, 0.60) * 0.34, 0.62);
		float soft_aureole = safe_pow(sun_dot, 4.5) * 0.20;

		vec3 outer_tint = mix(horizon_amber_color, sun_color, 0.42);
		vec3 corona = sun_color * (sun_disk * sun_disk_intensity + mie_inner * mie_inner_strength)
			+ outer_tint * ((mie_outer + soft_aureole) * mie_outer_strength);

		sky_col += corona * above_nadir;
	}

	// =========================================================================
	// 3. Delicate Celestial Astral Ring & Faint Rainbow-Iridescent Cloud Veil
	// =========================================================================
	float astral_band_mask = 0.0;
	if (elev > 0.14 && (river_strength > 0.001 || iridescent_strength > 0.001)) {
		// Tilted celestial arc arching gracefully high above the -Z Cathedral (~36 deg over -Z)
		vec3 ring_normal = safe_normalize(vec3(0.22, 0.78, 0.57), vec3(0.0, 1.0, 0.0));
		vec3 ring_u = safe_normalize(cross(vec3(0.0, 1.0, 0.0), ring_normal), vec3(1.0, 0.0, 0.0));
		vec3 ring_v = cross(ring_normal, ring_u);

		float ring_lat = dot(dir, ring_normal);
		float ring_elev = smoothstep(0.16, 0.36, elev);
		float ring_sun_fade = 1.0 - smoothstep(0.62, 0.95, sun_dot) * 0.68;

		if (abs(ring_lat) < 0.26 && ring_elev > 0.002) {
			float rx = dot(dir, ring_u);
			float ry = dot(dir, ring_v);
			float ring_ang = (rx * rx + ry * ry > 1e-6) ? atan(ry, rx) : 0.0;

			// Gossamer shimmer along the astral filament
			vec2 arc_uv = vec2(ring_ang * 2.4 + TIME * 0.012, ring_lat * 14.0);
			float veil_n = fbm2_2d(arc_uv);
			float shimmer_n = value_noise_2d(vec2(ring_ang * 9.5 - TIME * 0.025, ring_lat * 26.0));

			// Primary golden-pearl gossamer filament + fine harmonic silver-aqua companion arc
			float filament_main = exp(-sq(ring_lat * 44.0)) * (0.55 + 0.45 * shimmer_n);
			float filament_sub = exp(-sq((ring_lat - 0.036) * 72.0)) * (0.45 + 0.55 * veil_n) * 0.48;
			float soft_aura = exp(-sq(ring_lat * 12.0)) * smoothstep(0.32, 0.80, veil_n) * 0.30;

			vec3 astral_col = river_gold_color * (filament_main * 0.42 + soft_aura * 0.32)
				+ river_cyan_color * (filament_sub * 0.46 + soft_aura * 0.28);

			// Faint rainbow-iridescent ice-crystal cloud veil (refined pastel prism sheen)
			float irid_env = exp(-sq((ring_lat + 0.012) * 13.5)) * smoothstep(0.36, 0.78, veil_n);
			float prism_phase = ring_lat * 18.0 + veil_n * 2.6 + ring_ang * 0.85;
			vec3 prism_rgb = 0.5 + 0.5 * cos(prism_phase + vec3(0.0, 2.09439, 4.18879));
			vec3 pastel_irid = mix(vec3(0.95, 0.96, 1.0), prism_rgb, 0.52);

			float vis = ring_elev * ring_sun_fade;
			sky_col += astral_col * river_strength * vis;
			sky_col += pastel_irid * irid_env * 0.24 * iridescent_strength * vis;

			astral_band_mask = exp(-sq(ring_lat * 9.5)) * vis;
		}
	}

	// =========================================================================
	// 4. Crisp Subtle Constellations & Stardust (Sapphire Zenith, elev > 0.35)
	// =========================================================================
	float star_vis = smoothstep(0.35, 0.62, elev) * (1.0 - smoothstep(0.55, 0.90, sun_dot));
	vec3 stars_col = vec3(0.0);
	if (!AT_CUBEMAP_PASS && star_vis > 0.002 && star_density > 0.001 && star_brightness > 0.001) {
		float dens_boost = clamp(star_density + astral_band_mask * 0.16, 0.0, 0.98);
		float th_hero = mix(0.993, 0.956, star_density);
		float th_mid = mix(0.988, 0.930, dens_boost);
		float th_fine = mix(0.992, 0.946, dens_boost);

		vec3 s_hero = star_layer(dir, star_scale * 0.48, th_hero, TIME * 0.72, 0.080, 0.160, true);
		vec3 s_mid = star_layer(dir + vec3(0.37, 0.19, -0.53), star_scale * 1.04, th_mid, TIME * 1.0, 0.070, 0.132, false);
		vec3 s_fine = star_layer(dir + vec3(-0.61, 0.41, 0.27), star_scale * 1.66, th_fine, TIME * 1.28, 0.065, 0.118, false);

		stars_col = (s_hero * 1.25 + s_mid * 0.72 + s_fine * 0.36) * star_brightness * star_vis;
	}

	// =========================================================================
	// 5. Luminous Crescent Moon (High Upper-Right Azure Sky, Analytic SDF)
	// =========================================================================
	vec3 moon_contrib = vec3(0.0);
	float moon_alpha = 0.0;
	if (moon_strength > 0.001 && elev > 0.10) {
		vec3 m_dir = safe_normalize(moon_direction, vec3(0.46, 0.54, -0.70));
		float cos_moon = dot(dir, m_dir);

		// Quick angular cull (~14 deg cone around moon for halo + disk)
		if (cos_moon > 0.97) {
			// Align crescent lit bow toward the sun naturally
			vec3 m_to_sun = safe_normalize(sun_dir - m_dir * dot(sun_dir, m_dir), vec3(-1.0, 0.0, 0.0));
			vec3 m_ortho = cross(m_dir, m_to_sun);
			vec2 mp = vec2(dot(dir, m_to_sun), dot(dir, m_ortho));
			float m_dist = length(mp);

			// Crisp anti-aliased signed-distance crescent
			float aa = 0.0017;
			float outer_disk = smoothstep(moon_radius + aa, moon_radius - aa, m_dist);
			vec2 cut_center = vec2(-moon_radius * moon_crescent_offset, 0.0);
			float cut_radius = moon_radius * 0.95;
			float inner_cut = smoothstep(cut_radius + aa, cut_radius - aa, length(mp - cut_center));
			float crescent = outer_disk * (1.0 - inner_cut);

			// Subtle lunar maria texture only inside the moon disk
			float maria = 1.0;
			if (!AT_CUBEMAP_PASS && outer_disk > 0.01) {
				float mn = value_noise_2d(mp / max(moon_radius, 0.005) * 3.8 + vec2(2.4, -1.7));
				maria = mix(0.86, 1.04, mn);
			}

			// Faint pearlescent earthshine on dark limb + silky multi-scale halo
			float earthshine = outer_disk * inner_cut * 0.065;
			float halo_tight = exp(-m_dist / max(moon_radius * 0.95, 0.01)) * 0.34;
			float halo_wide = exp(-m_dist / max(moon_radius * 2.8, 0.02)) * 0.14;

			// Blend crescent cleanly over sky without harsh HDR blowout
			moon_contrib = moon_color * (crescent * 1.32 * maria + earthshine)
				+ moon_halo_color * (halo_tight + halo_wide);
			moon_contrib *= moon_strength;
			moon_alpha = crescent;
		}
	}

	// =========================================================================
	// 6. Delicate High-Altitude Feathered Cirrus Brushstrokes
	// =========================================================================
	float cirrus_alpha = 0.0;
	vec3 cirrus_col = vec3(0.0);

	if (elev > 0.045 && cloud_coverage > 0.001 && cloud_opacity > 0.001) {
		float cir_elev_mask = smoothstep(0.05, 0.22, elev) * smoothstep(0.99, 0.62, elev);
		if (cir_elev_mask > 0.002) {
			vec2 cir_plane = dir.xz / (elev + 0.18);
			// Soft dreamy high-altitude watercolor cloud veils (no sharp thin white streaks)
			mat2 wind_rot = mat2(vec2(0.82, -0.57), vec2(0.57, 0.82));
			vec2 cir_uv = wind_rot * cir_plane;
			vec2 drift = vec2(TIME * cloud_speed * 0.65, -TIME * cloud_speed * 0.22);

			// Gentle isotropic-biased domain-warped sky wisps
			vec2 uv_stretch = cir_uv * vec2(0.24, 0.42) + drift;
			float c_warp = fbm2_2d(uv_stretch * 0.72 - drift * 0.35);
			float n_cirrus = fbm3_2d(uv_stretch + vec2(c_warp * 0.55, -c_warp * 0.25));

			float cov_th = mix(0.76, 0.44, cloud_coverage);
			float cir_dens = smoothstep(cov_th, cov_th + 0.34, n_cirrus);
			cir_dens = cir_dens * cir_dens * (3.0 - 2.0 * cir_dens);
			cirrus_alpha = cir_dens * cir_elev_mask * cloud_opacity * 0.62;

			if (cirrus_alpha > 0.003) {
				// Directional sun-side highlight along soft high clouds
				vec2 sun_step = (wind_rot * sun_xz) * vec2(0.08, 0.14);
				float n_cir_sun = fbm2_2d(uv_stretch + sun_step + vec2(c_warp * 0.55, -c_warp * 0.25));
				float lit = clamp((n_cirrus - n_cir_sun) * 1.9 + 0.58, 0.0, 1.0);

				// Sunlit cream-blush near the sun; airy cotton-white high overhead
				float warm_mix = clamp(sun_side * 0.72 + sq(sun_dot) * 0.55, 0.0, 1.0) * smoothstep(0.72, 0.14, elev);
				vec3 cir_top = mix(cloud_body_color, cloud_lit_color, warm_mix);
				vec3 cir_base = mix(cloud_shadow_color, mid_sky_color, 0.35);

				cirrus_col = mix(cir_base, cir_top, clamp(0.48 + lit * 0.52, 0.0, 1.0));
				cirrus_col += sun_color * cube(sun_dot) * 0.18 * (1.0 - cir_dens * 0.35);
			}
		}
	}

	// =========================================================================
	// 7. Soft Painterly Cumulus Cloud Towers on the Horizon (elev = 0.0..0.28)
	// =========================================================================
	float cumulus_alpha = 0.0;
	vec3 cumulus_col = vec3(0.0);

	if (elev > -0.025 && elev < 0.34 && cumulus_opacity > 0.001) {
		// Seamless 360-degree azimuth coordinate [0, 1)
		float az_u = az * 0.15915494 + 0.5;
		float c_drift = TIME * cumulus_speed * 0.022;

		// Gentle cathedral framing dip right at -Z (az = 0) so towers majestically flank the Cathedral & Sun
		float cathedral_frame = 1.0 - 0.30 * exp(-sq(az * 2.1));
		float horizon_base_fade = smoothstep(-0.022, 0.028, elev);

		// --- Layer A: Towering Far Cumulus Cathedrals (period = 14) ---
		float macro_ridge = fbm2_2d_p(vec2((az_u + c_drift * 0.6) * 7.0, 1.35), 7.0);
		float tower_top_far = cumulus_height * (0.42 + 0.76 * safe_pow(macro_ridge, 1.15)) * cathedral_frame;

		vec2 p_far = vec2((az_u + c_drift) * 14.0, elev * 14.5);
		float w_far = fbm2_2d_p(p_far * 0.5 + vec2(0.0, 3.2), 7.0);
		vec2 p_far_w = p_far + vec2((w_far - 0.5) * 1.05, (w_far - 0.5) * 0.78);
		float n_far = fbm3_2d_p(p_far_w, 14.0);
		float lobe_far = billow_shape(n_far);

		float field_far = (tower_top_far - elev) * 6.2 + (lobe_far - 0.46) * 1.35;
		float mask_far = smoothstep(-0.10, 0.18, field_far) * horizon_base_fade;

		vec3 far_col = vec3(0.0);
		if (mask_far > 0.002) {
			float h_frac = clamp(elev / max(tower_top_far, 0.05), 0.0, 1.0);

			// Directional lighting toward the sun (azimuthally toward az=0 and upward toward crowns)
			vec2 sun_off = vec2(-sin(az) * 0.42, 0.55);
			float n_far_sun = fbm2_2d_p(p_far_w + sun_off, 14.0);
			float lobe_lit = clamp((lobe_far - billow_shape(n_far_sun)) * 2.1 + 0.48, 0.0, 1.0);

			// Soft periwinkle-lavender shadow base -> pearl-blush midtone -> sakura-peach bounce -> ivory rim
			float lit_grad = clamp(h_frac * 0.78 + lobe_lit * 0.44 - 0.12, 0.0, 1.0);
			float lit_sculpt = smoothstep(0.10, 0.84, lit_grad);

			vec3 shadow_tone = mix(cumulus_shadow_color * 0.90, cumulus_shadow_color * 1.08, sun_side);
			far_col = mix(shadow_tone, cumulus_body_color, lit_sculpt);

			// Warm sakura-peach bounce light on sun-facing lobes & lower-mid sunlit swells
			float bounce_mask = clamp(lobe_lit * (0.28 + 0.72 * sun_side) * (0.45 + 0.55 * h_frac), 0.0, 1.0);
			far_col = mix(far_col, cumulus_bounce_color, bounce_mask * (0.34 + 0.30 * sun_side));

			// Soft sunlit ivory-cream halo hugging cloud crests
			float crest_rim = smoothstep(0.62, 0.02, field_far) * smoothstep(0.28, 0.85, h_frac);
			float silver_strength = crest_rim * (0.45 + 0.55 * sun_side + cube(sun_dot) * 0.75);
			far_col = mix(far_col, cumulus_rim_color, clamp(silver_strength * 0.80, 0.0, 0.90));
			far_col += sun_color * silver_strength * (0.12 + 0.24 * cube(sun_dot));
		}

		// --- Layer B: Nearer Soft Cumulus Bank for Layered Parallax Depth (period = 20) ---
		float near_ridge = fbm2_2d_p(vec2((az_u + c_drift * 1.45) * 10.0, 5.7), 10.0);
		float tower_top_near = cumulus_height * (0.24 + 0.44 * near_ridge) * mix(0.76, 1.0, cathedral_frame);

		vec2 p_near = vec2((az_u + c_drift * 1.55) * 20.0, elev * 19.0 + 2.4);
		float n_near = fbm3_2d_p(p_near + vec2((w_far - 0.5) * 0.60, 0.0), 20.0);
		float lobe_near = billow_shape(n_near);

		float field_near = (tower_top_near - elev) * 7.5 + (lobe_near - 0.48) * 1.25;
		float mask_near = smoothstep(-0.09, 0.16, field_near) * horizon_base_fade;

		vec3 near_col = vec3(0.0);
		if (mask_near > 0.002) {
			float h_near = clamp(elev / max(tower_top_near, 0.04), 0.0, 1.0);
			vec2 sun_off_n = vec2(-sin(az) * 0.48, 0.58);
			float n_near_sun = fbm2_2d_p(p_near + sun_off_n, 20.0);
			float lit_near = clamp((lobe_near - billow_shape(n_near_sun)) * 2.4 + 0.40, 0.0, 1.0);

			float sculpt_n = smoothstep(0.18, 0.86, h_near * 0.74 + lit_near * 0.45 - 0.18);
			vec3 shadow_n = mix(cumulus_shadow_color * 0.76, cumulus_shadow_color * 0.96, sun_side);
			near_col = mix(shadow_n, cumulus_body_color * 0.97, sculpt_n);

			// Warm coral-peach bounce light on foreground puffs
			float bounce_n = clamp(lit_near * (0.25 + 0.75 * sun_side) * (0.4 + 0.6 * h_near), 0.0, 1.0);
			near_col = mix(near_col, cumulus_bounce_color, bounce_n * (0.38 + 0.28 * sun_side));

			// Crisp ivory-gold sunlit rim on foreground puffs
			float rim_n = smoothstep(0.52, 0.02, field_near) * smoothstep(0.30, 0.86, h_near);
			float silver_n = rim_n * (0.40 + 0.60 * sun_side + cube(sun_dot) * 0.65);
			near_col = mix(near_col, cumulus_rim_color, clamp(silver_n * 0.85, 0.0, 0.92));
			near_col += sun_color * silver_n * (0.12 + 0.22 * cube(sun_dot));
		}

		// Exact Porter-Duff compositing of near cumulus over far cumulus towers (zero dark edge fringe)
		float total_mask = clamp(mask_far + mask_near * (1.0 - mask_far), 0.0, 1.0);
		cumulus_alpha = total_mask * cumulus_opacity;
		if (total_mask > 0.002 && cumulus_alpha > 0.002) {
			vec3 premul = far_col * mask_far * (1.0 - mask_near) + near_col * mask_near;
			vec3 combined = premul / max(total_mask, 0.0001);
			// Soft atmospheric mist blend at the very horizon base (elev ~ 0.0..0.03)
			float base_mist = exp(-max(elev, 0.0) * 34.0) * 0.48;
			combined = mix(combined, horiz_base, base_mist);
			cumulus_col = combined;
		}
	}

	// =========================================================================
	// 8. Final Atmospheric Compositing (Sky -> Stars & Moon -> Cirrus -> Cumulus)
	// =========================================================================
	// Stars & moon sit in the deep celestial vault behind cirrus and cumulus
	float celestial_occlude = (1.0 - cirrus_alpha * 0.78) * (1.0 - cumulus_alpha * 0.98);
	sky_col += stars_col * celestial_occlude;

	// Composite crescent moon cleanly over sky (halo additive, lit crescent crisp)
	sky_col = mix(sky_col, sky_col * 0.25, moon_alpha * celestial_occlude * 0.65);
	sky_col += moon_contrib * celestial_occlude;

	// Blend feathered high-altitude cirrus brushstrokes
	sky_col = mix(sky_col, cirrus_col, cirrus_alpha);

	// Blend sculpted horizon cumulus towers in front of distant sky & cirrus
	sky_col = mix(sky_col, cumulus_col, cumulus_alpha);

	COLOR = sky_col;
}
