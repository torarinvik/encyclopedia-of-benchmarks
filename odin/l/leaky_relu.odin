package leaky_relu

import "core:math"

INVALID_RESULT :: -1.0e300
MAX_INPUT :: 1_000_000.0

@(export)
leaky_relu :: proc "c" (x, alpha: f64) -> f64 {
	if math.is_nan_f64(x) || math.is_nan_f64(alpha) || x < -MAX_INPUT || x > MAX_INPUT || alpha < -MAX_INPUT || alpha > MAX_INPUT do return INVALID_RESULT
	if x < 0.0 do return x * alpha
	return x
}
