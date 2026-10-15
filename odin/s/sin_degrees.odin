package sin_degrees

import "core:math"

@(export)
sin_degrees :: proc "c" (angle_value: f64) -> f64 {
	if !(angle_value >= -1_000_000.0 && angle_value <= 1_000_000.0) do return -1.0

	angle := angle_value - math.floor_f64(angle_value / 360.0) * 360.0
	radians := angle * (3.141592653589793 / 180.0)
	result := radians
	sign := -1.0
	exponent := 3
	for term := 0; term < 18; term += 1 {
		factorial := f64(1.0)
		for factor := 2; factor <= exponent; factor += 1 {
			factorial *= f64(factor)
		}
		result += sign * math.pow_f64(radians, f64(exponent)) / factorial
		sign = -sign
		exponent += 2
	}
	return math.round_f64(result * 10_000_000_000.0) / 10_000_000_000.0
}
