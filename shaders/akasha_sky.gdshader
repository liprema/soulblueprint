shader_type sky;

// Akasha Celestial Sky Dome — Sky: Children of the Light / Journey inspired
// Calibrated palette: #0A1F44 (Deep Space Blue), #122D6B (Indigo),
// #1E4B9A (Rich Blue), #58C4FF (Ethereal Cyan), #F6D36B (Warm Radiant Gold)

group_uniforms sky_palette;
uniform vec3 zenith_color : source_color = vec3(0.039, 0.122, 0.267);      // #0A1F44 Deep Space Blue
uniform vec3 upper_indigo_color : source_color = vec3(0.071, 0.176, 0.420); // #122D6B Indigo
uniform vec3 mid_sky_color : source_color = vec3(0.118, 0.294, 0.604);      // #1E4B9A Rich Blue
uniform vec3 cyan_mist_color : source_color = vec3(0.345, 0.769, 1.000);    // #58C4FF Ethereal Cyan
uniform vec3 horizon_color : source_color = vec3(0.965, 0.827, 0.420);      // #F6D36B Soft Gold
uniform vec3 horizon_amber : source_color = vec3(0.940, 0.675, 0.310);      // Warm golden-amber band
uniform vec3 nadir_color : source_color = vec3(0.032, 0.088, 0.215);        // Deep abyss below clouds

group_uniforms sun_and_halo;
uniform vec3 sun_direction = vec3(0.0, 0.15, -1.0);                         // -Z toward the Astrolabe Cathedral
uniform vec3 sun_color : source_color = vec3(1.0, 0.945, 0.74);             // Luminous gold-white
uniform float sun_disk_size : hint_range(0.005, 0.15) = 0.036;
uniform float sun_halo_intensity : hint_range(0.0, 4.0) = 1.55;
uniform float sun_halo_spread : hint_range(1.0, 32.0) = 5.2;
uniform float horizon_glow_strength : hint_range(0.0, 2.5) = 1.05;

group_uniforms celestial_stars;
uniform float star_density : hint_range(0.0, 1.0) = 0.72;
uniform float star_brightness : hint_range(0.0, 3.0) = 1.35;
uniform float star_twinkle_speed : hint_range(0.0, 5.0) = 1.5;
uniform float star_scale : hint_range(40.0, 300.0) = 148.0;

group_uniforms aurora_and_nebula;
uniform float nebula_strength : hint_range(0.0, 1.0) = 0.26;
uniform float aurora_strength : hint_range(0.0, 1.0) = 0.22;

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

float value_noise_3d(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float n000 = hash31(i + vec3(0.0, 0.0, 0.0));
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

	float nxy0 = mix(nx00, nx10, f.y);
	float nxy1 = mix(nx01, nx11, f.y);

	return mix(nxy0, nxy1, f.z);
}

float fbm_sky(vec3 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * value_noise_3d(p);
		p = p * 2.03 + vec3(13.7, -7.2, 5.4);
		amp *= 0.5;
	}
	return v;
}

float star_layer(vec3 dir, float scale, float threshold, float time_val, bool with_glint) {
	vec3 p = dir * scale;
	vec3 cell = floor(p);
	vec3 local = fract(p) - 0.5;

	vec3 rnd = hash33(cell);
	if (rnd.x < threshold) {
		return 0.0;
	}

	vec3 star_offset = (rnd - 0.5) * 0.62;
	vec3 delta = local - star_offset;
	float dist = length(delta);
	float size = mix(0.032, 0.092, rnd.y);
	float core = smoothstep(size, 0.0, dist);
	core = pow(core, 2.2);

	float glint = 0.0;
	if (with_glint && rnd.y > 0.72) {
		float cross_a = exp(-abs(delta.x) * 42.0) * smoothstep(size * 2.6, 0.0, abs(delta.y));
		float cross_b = exp(-abs(delta.y) * 42.0) * smoothstep(size * 2.6, 0.0, abs(delta.x));
		glint = (cross_a + cross_b) * 0.35;
	}

	float twinkle_phase = rnd.z * 6.2831853 + time_val * (star_twinkle_speed * mix(0.55, 1.55, rnd.y));
	float twinkle = 0.56 + 0.44 * sin(twinkle_phase);

	return (core + glint) * twinkle;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 sun_dir = normalize(sun_direction);
	float elev = dir.y;

	// Multi-stop vertical gradient: golden-amber horizon -> rich blue -> deep indigo -> cosmic zenith
	float mid_band = smoothstep(0.03, 0.38, elev);
	float upper_band = smoothstep(0.24, 0.68, elev);
	float zenith_band = smoothstep(0.52, 0.94, elev);

	vec3 sky_col = mix(horizon_amber, horizon_color, smoothstep(-0.05, 0.06, elev));
	sky_col = mix(sky_col, mid_sky_color, mid_band);
	sky_col = mix(sky_col, upper_indigo_color, upper_band);
	sky_col = mix(sky_col, zenith_color, zenith_band);

	// Subtle ethereal cyan atmospheric wash along the mid-horizon
	float cyan_band = exp(-pow((elev - 0.14) * 6.5, 2.0));
	sky_col += cyan_mist_color * cyan_band * 0.085;

	// Smooth blend into deep cosmic nadir beneath the cloud sea
	float below_horizon = smoothstep(0.01, -0.34, elev);
	sky_col = mix(sky_col, nadir_color, below_horizon);

	// Painterly celestial nebula wisps in the upper dome
	float nebula_n = fbm_sky(dir * 3.1 + vec3(0.0, TIME * 0.0035, 0.0));
	float nebula_detail = fbm_sky(dir * 6.4 - vec3(TIME * 0.002, 0.0, TIME * 0.003));
	float nebula_mask = smoothstep(0.36, 0.78, nebula_n * 0.7 + nebula_detail * 0.3) * smoothstep(0.08, 0.44, elev);
	vec3 nebula_tint = mix(mid_sky_color * 1.4, cyan_mist_color * 0.65, nebula_detail);
	nebula_tint = mix(nebula_tint, horizon_color * 0.65, 0.22);
	sky_col += nebula_tint * nebula_mask * nebula_strength;

	// Soft celestial aurora light ribbons sweeping gently across the high indigo vault
	float aurora_coord = dir.x * 2.4 + sin(dir.z * 2.8 + TIME * 0.05) * 0.65;
	float aurora_wave = fbm_sky(vec3(aurora_coord, dir.y * 1.8, dir.z * 1.6 + TIME * 0.012));
	float aurora_ribbon = exp(-pow((aurora_wave - 0.56) * 8.5, 2.0));
	float aurora_elev = smoothstep(0.16, 0.42, elev) * smoothstep(0.88, 0.48, elev);
	vec3 aurora_col = mix(cyan_mist_color * 0.85, horizon_color * 0.9, smoothstep(0.25, 0.72, dir.y));
	sky_col += aurora_col * aurora_ribbon * aurora_elev * aurora_strength;

	// Warm luminous golden-amber horizon bloom concentrated toward the -Z Cathedral axis
	float sun_dot = max(dot(dir, sun_dir), 0.0);
	float horizon_proximity = exp(-abs(elev - 0.02) * 6.2);
	float sun_azimuth_glow = pow(sun_dot, 2.1) * horizon_proximity;
	sky_col += mix(horizon_amber, horizon_color, 0.68) * sun_azimuth_glow * horizon_glow_strength;

	// Stylized radiant sun / Cathedral corona & soft crepuscular rays
	float sun_angle = acos(clamp(dot(dir, sun_dir), -1.0, 1.0));
	float sun_disk = smoothstep(sun_disk_size * 1.5, sun_disk_size * 0.22, sun_angle);
	float inner_halo = pow(sun_dot, sun_halo_spread * 3.0) * 1.05;
	float mid_halo = pow(sun_dot, sun_halo_spread) * 0.52;
	float wide_bloom = pow(sun_dot, 2.2) * 0.16;

	// Subtle radial light rays emanating around the Cathedral sun axis
	float ray_angle = atan(dir.y - sun_dir.y, dir.x - sun_dir.x);
	float radial_rays = 0.5 + 0.5 * sin(ray_angle * 7.0 + TIME * 0.08) * cos(ray_angle * 4.0 - TIME * 0.05);
	float ray_glow = pow(sun_dot, 6.0) * radial_rays * 0.24;

	vec3 sun_contrib = sun_color * (sun_disk * 2.4 + inner_halo * sun_halo_intensity + ray_glow)
		+ horizon_color * ((mid_halo + wide_bloom) * sun_halo_intensity);
	sky_col += sun_contrib * smoothstep(-0.20, 0.03, elev);

	// Multi-scale twinkling starfield in the indigo/zenith dome
	float star_visibility = smoothstep(0.05, 0.36, elev) * (1.0 - smoothstep(0.72, 0.97, sun_dot));
	if (star_visibility > 0.001 && star_density > 0.001) {
		float thresh_hero = mix(0.992, 0.945, star_density);
		float thresh_mid = mix(0.985, 0.918, star_density);
		float thresh_fine = mix(0.992, 0.940, star_density);

		float s_hero = star_layer(dir, star_scale * 0.62, thresh_hero, TIME * 0.85, true);
		float s_mid = star_layer(dir + vec3(0.37, 0.19, -0.53), star_scale * 1.15, thresh_mid, TIME * 1.1, false);
		float s_fine = star_layer(dir + vec3(-0.61, 0.41, 0.27), star_scale * 1.95, thresh_fine, TIME * 1.4, false);

		vec3 hero_tint = mix(vec3(0.86, 0.94, 1.0), horizon_color, 0.58);
		vec3 mid_tint = mix(vec3(0.76, 0.88, 1.0), cyan_mist_color, 0.25);
		sky_col += (hero_tint * s_hero * 1.35 + mid_tint * s_mid * 0.85 + vec3(0.85, 0.92, 1.0) * s_fine * 0.5)
			* star_brightness * star_visibility;
	}

	COLOR = sky_col;
}
