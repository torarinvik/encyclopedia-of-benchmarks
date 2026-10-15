module sin_degrees

import math

@[export: 'sin_degrees']
pub fn sin_degrees(angle_value f64) f64 {
	if !(angle_value >= -1_000_000.0 && angle_value <= 1_000_000.0) { return -1.0 }

	angle := angle_value - math.floor(angle_value / 360.0) * 360.0
	radians := angle * (3.141592653589793 / 180.0)
	mut result := radians
	mut sign := -1.0
	mut exponent := 3
	for _ in 0 .. 18 {
		mut factorial := 1.0
		for factor in 2 .. exponent + 1 { factorial *= f64(factor) }
		result += sign * math.pow(radians, f64(exponent)) / factorial
		sign = -sign
		exponent += 2
	}
	return math.round(result * 10_000_000_000.0) / 10_000_000_000.0
}
