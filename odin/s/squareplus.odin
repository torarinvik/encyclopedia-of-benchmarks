package squareplus

import "core:math"

INVALID_RESULT :: -1.0e300

@(export)
squareplus :: proc "c" (x, beta: f64) -> f64 {
	if !(x >= -10000 && x <= 10000 && beta >= 0.25 && beta <= 10000) do return INVALID_RESULT
	return (x + math.sqrt_f64(x * x + beta)) / 2
}
