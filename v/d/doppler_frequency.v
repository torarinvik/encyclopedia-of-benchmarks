module doppler_frequency

@[export: 'doppler_frequency']
pub fn doppler_frequency(values &i64, length usize) f64 {
	if length != 4 { return -1.0e300 }
	org_freq := unsafe { values[0] }
	wave_vel := unsafe { values[1] }
	obs_vel := unsafe { values[2] }
	src_vel := unsafe { values[3] }
	if org_freq < 1 || org_freq > 1000 || wave_vel < 200 || wave_vel > 1000 || obs_vel < -100 || obs_vel > 100 || src_vel < -100 || src_vel > 100 { return -1.0e300 }
	return (f64(org_freq) * (f64(wave_vel) + f64(obs_vel))) / (f64(wave_vel) - f64(src_vel))
}
