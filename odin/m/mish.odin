package mish

import "core:math"

INVALID_RESULT :: -1.0e300

@(export)
mish :: proc "c" (x: f64) -> f64 {
	if !(x >= -20 && x <= 20) do return INVALID_RESULT
	softplus := math.ln_f64(1.0 + math.exp_f64(x))
	return x * math.tanh_f64(softplus)
}
