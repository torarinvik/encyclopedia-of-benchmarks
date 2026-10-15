package sigmoid

import "core:math"

INVALID_RESULT :: f64 = -1.0e300

@(export)
sigmoid :: proc "c" (x: f64) -> f64 {
	if math.isnan_f64(x) || x < -20.0 || x > 20.0 do return INVALID_RESULT
	return 1.0 / (1.0 + math.exp_f64(-x))
}
