module bragg_angle

import math

const pi_value = 3.141592653589793238462643383279502884

fn round_one_even(value f64) f64 {
	scaled := value * 10.0
	lower := math.floor(scaled)
	fraction := scaled - lower
	mut rounded := i64(lower)
	if fraction > 0.5 || (fraction == 0.5 && rounded % 2 != 0) {
		rounded += 1
	}
	return f64(rounded) / 10.0
}

@[export: 'bragg_angle']
pub fn bragg_angle(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	distance := unsafe { values[0] }
	order := unsafe { values[1] }
	wavelength := unsafe { values[2] }
	if distance < 1 || distance > 1000000 || order < -1000 || order > 1000 || wavelength < 0 || wavelength > 1000000 {
		return -1.0e300
	}
	sine := (f64(order) * f64(wavelength)) / (2.0 * f64(distance))
	if sine < -1.0 || sine > 1.0 { return -1.0e300 }
	degrees := math.asin(sine) * (180.0 / pi_value)
	return round_one_even(degrees)
}
