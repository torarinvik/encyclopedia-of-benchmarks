package tanh

import "core:math"

INVALID_RESULT :: -1.0e300

@(export)
tanh :: proc "c" (x: f64) -> f64 {
	if math.isnan_f64(x) || x < -10.0 || x > 10.0 do return INVALID_RESULT
	return (2.0 / (1.0 + math.exp_f64(-2.0 * x))) - 1.0
}
