package binary_step

import "core:math"

INVALID_RESULT :: -1.0e300

@(export)
binary_step :: proc "c" (x: f64) -> f64 {
	if math.is_nan_f64(x) || x < -1_000_000.0 || x > 1_000_000.0 do return INVALID_RESULT
	if x >= 0.0 do return 1.0
	return 0.0
}
