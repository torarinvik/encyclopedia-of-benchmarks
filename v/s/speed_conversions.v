module speed_conversions

import math

#include <math.h>
fn C.fma(first f64, second f64, third f64) f64

fn round_three_even(value f64) f64 {
	lower := math.floor(value * 1000.0)
	midpoint := lower + 0.5
	exact_side := C.fma(value, 1000.0, -midpoint)
	mut rounded := i64(lower)
	if exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0) { rounded++ }
	return f64(rounded) / 1000.0
}

@[export: 'speed_conversions']
pub fn speed_conversions(speed f64, route f64) f64 {
	if !(speed >= 0.0 && speed <= 1_000_000.0) || !(route >= 0.0 && route <= 15.0) || math.floor(route) != route {
		return -1.0
	}
	mut factors := [4]f64{}
	factors[0] = 1.0
	factors[1] = 3.6
	factors[2] = 1.609344
	factors[3] = 1.852
	mut inverse_factors := [4]f64{}
	inverse_factors[0] = 1.0
	inverse_factors[1] = 0.277777778
	inverse_factors[2] = 0.621371192
	inverse_factors[3] = 0.539956803
	encoded := int(route)
	unit_from := encoded / 4
	unit_to := encoded % 4
	return round_three_even(speed * factors[unit_from] * inverse_factors[unit_to])
}
