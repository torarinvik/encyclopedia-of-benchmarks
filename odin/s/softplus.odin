package softplus

import "core:math"

INVALID_RESULT :: f64 = -1.0e300

@(export)
softplus :: proc "c" (x: f64) -> f64 {
	if math.isnan_f64(x) || x < -100.0 || x > 100.0 do return INVALID_RESULT
	return math.ln_f64(1.0 + math.exp_f64(x))
}
