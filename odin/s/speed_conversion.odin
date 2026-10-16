package speed_conversion

import "core:math"

round_two_php :: proc "contextless" (value: f64) -> f64 {
	return math.floor(value * 100.0 + 0.5) / 100.0
}

@(export)
speed_conversion :: proc "c" (speed, route: f64) -> f64 {
	if !(speed >= 0.0 && speed <= 1000000.0) || !(route >= 0.0 && route <= 24.0) || math.floor(route) != route do return -1.0
	factors := [5]f64{1.609344, 1.0, 3.6, 1.097, 1.852}
	inverse_factors := [5]f64{0.6213712, 1.0, 0.277778, 0.911344, 0.539957}
	encoded := i64(route)
	unit_from := int(encoded / 5)
	unit_to := int(encoded % 5)
	return round_two_php(speed * factors[unit_from] * inverse_factors[unit_to])
}
