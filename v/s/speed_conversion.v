module speed_conversion

import math


fn round_two_php(value f64) f64 {
	return math.floor(value * 100.0 + 0.5) / 100.0
}

@[export: 'speed_conversion']
pub fn speed_conversion(speed f64, route f64) f64 {
	if !(speed >= 0.0 && speed <= 1_000_000.0) || !(route >= 0.0 && route <= 24.0) || math.floor(route) != route {
		return -1.0
	}
	factors := [5]f64{1.609344, 1.0, 3.6, 1.097, 1.852}
	inverse_factors := [5]f64{0.6213712, 1.0, 0.277778, 0.911344, 0.539957}
	encoded := int(route)
	unit_from := encoded / 5
	unit_to := encoded % 5
	return round_two_php(speed * factors[unit_from] * inverse_factors[unit_to])
}
