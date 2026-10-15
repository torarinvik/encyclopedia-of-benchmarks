package softsign

import "core:math"

INVALID_RESULT :: f64 = -1.0e300

@(export)
softsign :: proc "c" (x: f64) -> f64 {
	if math.isnan_f64(x) || x < -1.0e100 || x > 1.0e100 do return INVALID_RESULT
	return x / (1.0 + math.abs(x))
}
