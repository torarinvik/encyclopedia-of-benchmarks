package gaussian_error_linear_unit

import "core:math"

INVALID_RESULT :: -1.0e300

@(export)
gaussian_error_linear_unit :: proc "c" (x: f64) -> f64 {
	if math.isnan_f64(x) || x < -100.0 || x > 100.0 do return INVALID_RESULT
	return x * (1.0 / (1.0 + math.exp_f64(-1.702 * x)))
}
