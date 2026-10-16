package rectangular_to_polar

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300
DEGREE_FACTOR :: 57.2957795130823208768

round_two_away :: proc "contextless" (value: f64) -> f64 {
	if value == 0.0 do return value
	scaled := value * 100.0
	if scaled >= 0.0 do return f64(i64(scaled + 0.5)) / 100.0
	units := i64(scaled - 0.5)
	if units == 0 do return -0.0
	return f64(units) / 100.0
}

@(export)
rectangular_to_polar :: proc "c" (real, imag, component: f64) -> f64 {
	if real != real || imag != imag || component != component ||
		abs(real) > 1000000.0 || abs(imag) > 1000000.0 ||
		(component != 0.0 && component != 1.0) do return INVALID_RESULT
	if component == 0.0 do return round_two_away(math.sqrt(real * real + imag * imag))
	return round_two_away(math.atan2(imag, real) * DEGREE_FACTOR)
}
