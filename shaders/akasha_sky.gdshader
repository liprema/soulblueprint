shader_type sky;

// Akasha Celestial Sky Dome — Sky: Children of the Light inspired
// Approved palette: #0A1F44 (Deep Space Blue), #122D6B (Indigo),
// #1E4B9A (Rich Blue), #F6D36B (Soft Gold)

group_uniforms sky_palette;
uniform vec3 zenith_color : source_color = vec3(0.039, 0.122, 0.267);      // #0A1F44 Deep Space Blue
uniform vec3 upper_indigo_color : source_color = vec3(0.071, 0.176, 0.420); // #122D6B Indigo
uniform vec3 mid_sky_color : source_color = vec3(0.118, 0.294, 0.604);      // #1E4B9A Rich Blue
uniform vec3 horizon_color : source_color = vec3(0.965, 0.827, 0.420);      // #F6D36B Soft Gold
uniform vec3 horizon_amber : source_color = vec3(0.910, 0.640, 0.300);      // Warm golden-amber band
uniform vec3 nadir_color : source_color = vec3(0.045, 0.115, 0.255);        // Deep abyss below clouds

group_uniforms sun_and_halo;
uniform vec3 sun_direction = vec3(0.0, 0.14, -1.0);                         // -Z toward the Astrolabe Cathedral
uniform vec3 sun_color : source_color = vec3(1.0, 0.92, 0.68);              // Warm luminous gold-white
uniform float sun_disk_size : hint_range(0.005, 0.15) = 0.032;
uniform float sun_halo_intensity : hint_range(0.0, 4.0) = 1.35;
uniform float sun_halo_spread : hint_range(1.0, 32.0) = 6.5;
uniform float horizon_glow_strength : hint_range(0.0, 2.0) = 0.85;

group_uniforms celestial_stars;
uniform float star_density : hint_range(0.0, 1.0) = 0.68;
uniform float star_brightness : hint_range(0.0, 3.0) = 1.25;
uniform float star_twinkle_speed : hint_range(0.0, 5.0) = 1.6;
uniform float star_scale : hint_range(40.0, 300.0) = 155.0;

group_uniforms nebula_mist;
uniform float nebula_strength : hint_range(0.0, 1.0) = 0.22;

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

float star_layer(vec3 dir, float scale, float threshold, float time_val) {
	vec3 p = dir * scale;
	vec3 cell = floor(p);
	vec3 local = fract(p) - 0.5;

	vec3 rnd = hash33(cell);
	if (rnd.x < threshold) {
		return 0.0;
	}

	vec3 star_offset = (rnd - 0.5) * 0.65;
	float dist = length(local - star_offset);
	float size = mix(0.035, 0.095, rnd.y);
	float core = smoothstep(size, 0.0, dist);
	core = pow(core, 2.2);

	float twinkle_phase = rnd.z * 6.2831853 + time_val * (star_twinkle_speed * mix(0.6, 1.6, rnd.y));
	float twinkle = 0.58 + 0.42 * sin(twinkle_phase);

	return core * twinkle;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 sun_dir = normalize(sun_direction);
	float elev = dir.y;

	// Vertical sky gradient: golden-amber horizon -> rich blue -> deep indigo -> deep space zenith
	float h_band = smoothstep(-0.08, 0.14, elev);
	float mid_band = smoothstep(0.04, 0.42, elev);
	float upper_band = smoothstep(0.28, 0.72, elev);
	float zenith_band = smoothstep(0.55, 0.96, elev);

	vec3 sky_col = mix(horizon_amber, horizon_color, smoothstep(-0.04, 0.05, elev));
	sky_col = mix(sky_col, mid_sky_color, mid_band);
	sky_col = mix(sky_col, upper_indigo_color, upper_band);
	sky_col = mix(sky_col, zenith_color, zenith_band);

	// Blend smoothly into deep nadir below the horizon
	float below_horizon = smoothstep(0.02, -0.35, elev);
	sky_col = mix(sky_col, nadir_color, below_horizon);

	// Subtle painterly celestial nebula wisps in the upper sky
	float nebula_n = fbm_sky(dir * 3.2 + vec3(0.0, TIME * 0.004, 0.0));
	float nebula_mask = smoothstep(0.38, 0.78, nebula_n) * smoothstep(0.08, 0.45, elev);
	vec3 nebula_tint = mix(mid_sky_color * 1.35, horizon_color * 0.7, 0.22);
	sky_col += nebula_tint * nebula_mask * nebula_strength;

	// Warm horizon glow concentrated toward the -Z sun / Cathedral axis
	float sun_dot = max(dot(dir, sun_dir), 0.0);
	float horizon_proximity = exp(-abs(elev) * 7.5);
	float sun_azimuth_glow = pow(sun_dot, 2.5) * horizon_proximity;
	sky_col += mix(horizon_amber, horizon_color, 0.6) * sun_azimuth_glow * horizon_glow_strength;

	// Soft celestial sun halo and luminous core
	float sun_angle = acos(clamp(dot(dir, sun_dir), -1.0, 1.0));
	float sun_disk = smoothstep(sun_disk_size * 1.45, sun_disk_size * 0.25, sun_angle);
	float inner_halo = pow(sun_dot, sun_halo_spread * 3.2) * 0.95;
	float outer_halo = pow(sun_dot, sun_halo_spread) * 0.48;
	vec3 sun_contrib = sun_color * (sun_disk * 2.2 + inner_halo * sun_halo_intensity)
		+ horizon_color * (outer_halo * sun_halo_intensity);
	sky_col += sun_contrib * smoothstep(-0.18, 0.02, elev);

	// Twinkling stars in the upper indigo/zenith dome (fading near horizon & sun halo)
	float star_visibility = smoothstep(0.06, 0.38, elev) * (1.0 - smoothstep(0.75, 0.98, sun_dot));
	if (star_visibility > 0.001 && star_density > 0.001) {
		float thresh_primary = mix(0.985, 0.915, star_density);
		float thresh_fine = mix(0.992, 0.945, star_density);
		float s1 = star_layer(dir, star_scale, thresh_primary, TIME);
		float s2 = star_layer(dir + vec3(0.37, 0.19, -0.53), star_scale * 1.65, thresh_fine, TIME * 1.25);

		// Subtle warm gold & pale ice-blue star color variation
		vec3 star_tint = mix(vec3(0.84, 0.92, 1.0), horizon_color, smoothstep(0.2, 0.8, s1));
		sky_col += star_tint * (s1 + s2 * 0.65) * star_brightness * star_visibility;
	}

	COLOR = sky_col;
}
