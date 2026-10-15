module escape_velocity

import math

#include <math.h>
fn C.fma(first f64, second f64, third f64) f64

fn round_three_even(value f64) f64 {
	scaled := value * 1000.0
	lower := math.floor(scaled)
	midpoint := lower + 0.5
	exact_side := C.fma(value, 1000.0, -midpoint)
	mut rounded := i64(lower)
	if exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0) {
		rounded += 1
	}
	return f64(rounded) / 1000.0
}

@[export: 'escape_velocity']
pub fn escape_velocity(values &i64, length usize) f64 {
	if length != 2 { return -1.0e300 }
	mass := unsafe { values[0] }
	radius := unsafe { values[1] }
	if mass < 0 || mass > 1000000000000000 || radius < 1 || radius > 1000000000 {
		return -1.0e300
	}
	velocity := math.sqrt(2.0 * 6.67430e-11 * f64(mass) / f64(radius))
	return round_three_even(velocity)
}
