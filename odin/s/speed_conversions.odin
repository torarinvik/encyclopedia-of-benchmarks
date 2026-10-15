package speed_conversions

import "core:math"
import "core:c/libc"

round_three_even :: proc "contextless" (value: f64) -> f64 {
	lower := math.floor(value * 1000.0)
	midpoint := lower + 0.5
	exact_side := libc.fma(value, 1000.0, -midpoint)
	rounded := i64(lower)
	if exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0) do rounded += 1
	return f64(rounded) / 1000.0
}

@(export)
speed_conversions :: proc "c" (speed, route: f64) -> f64 {
	if !(speed >= 0.0 && speed <= 1000000.0) || !(route >= 0.0 && route <= 15.0) || math.floor(route) != route do return -1.0
	factors := [4]f64{1.0, 3.6, 1.609344, 1.852}
	inverse_factors := [4]f64{1.0, 0.277777778, 0.621371192, 0.539956803}
	encoded := i64(route)
	unit_from := int(encoded / 4)
	unit_to := int(encoded % 4)
	return round_three_even(speed * factors[unit_from] * inverse_factors[unit_to])
}
