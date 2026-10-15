package relu

import "core:math"

INVALID_RESULT :: -1.0e300
MAX_INPUT :: 16777216.0

@(export)
relu :: proc "c" (x: f64) -> f64 {
	if math.is_nan_f64(x) || x < -MAX_INPUT || x > MAX_INPUT || f64(i64(x)) != x do return INVALID_RESULT
	if x > 0.0 do return x
	return 0.0
}
