package newtons_law_of_gravitation

import "core:c"
import "core:math"

GRAVITATIONAL_CONSTANT :: 6.6743e-11

@(export)
newtons_law_of_gravitation :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 4 do return -1.0e300
	target, a, b, c_value := values[0], values[1], values[2], values[3]
	if target < 0 || target > 3 || a < 1 || a > 1000 || b < 1 || b > 1000 || c_value < 1 || c_value > 1000 do return -1.0e300
	switch target {
	case 0: return GRAVITATIONAL_CONSTANT * (f64(a) * f64(b)) / (f64(c_value) * f64(c_value))
	case 1: return f64(a) * (f64(c_value) * f64(c_value)) / (GRAVITATIONAL_CONSTANT * f64(b))
	case 2: return f64(a) * (f64(c_value) * f64(c_value)) / (GRAVITATIONAL_CONSTANT * f64(b))
	case: return math.sqrt((GRAVITATIONAL_CONSTANT * (f64(b) * f64(c_value))) / f64(a))
	}
}
