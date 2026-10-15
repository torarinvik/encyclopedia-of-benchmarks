package exponential_linear_unit

import "core:math"

INVALID_RESULT :: -1.0e300
ALPHA_MAX :: 1_000_000.0

@(export)
exponential_linear_unit :: proc "c" (x, alpha: f64) -> f64 {
	if math.is_nan_f64(x) || math.is_nan_f64(alpha) || x < -100.0 || x > 100.0 || alpha < -ALPHA_MAX || alpha > ALPHA_MAX do return INVALID_RESULT
	if x < 0.0 do return x * (alpha * (math.exp_f64(x) - 1.0))
	return x
}
