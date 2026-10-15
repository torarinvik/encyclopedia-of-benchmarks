package doppler_frequency

import "core:c"

@(export)
doppler_frequency :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 4 do return -1.0e300
	org_freq := values[0]
	wave_vel := values[1]
	obs_vel := values[2]
	src_vel := values[3]
	if org_freq < 1 || org_freq > 1000 || wave_vel < 200 || wave_vel > 1000 || obs_vel < -100 || obs_vel > 100 || src_vel < -100 || src_vel > 100 do return -1.0e300
	return (f64(org_freq) * (f64(wave_vel) + f64(obs_vel))) / (f64(wave_vel) - f64(src_vel))
}
