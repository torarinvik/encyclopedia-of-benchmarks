package powvialogarithm

import "core:math"

INVALID_RESULT :: -1.0e300

@(export)
powvialogarithm :: proc "c" (base, exponent: f64) -> f64 {
	if !(base >= -4.0 && base <= 4.0 && exponent >= -8.0 && exponent <= 8.0) do return INVALID_RESULT
	if math.floor_f64(base) != base || math.floor_f64(exponent) != exponent do return INVALID_RESULT
	if base == 0.0 && exponent <= 0.0 do return INVALID_RESULT
	if (base == 2.0 || base == -2.0) && exponent == -1.0 do return INVALID_RESULT

	sign := 1.0
	power := i64(exponent)
	if base < 0.0 && power % 2 != 0 do sign = -1.0
	logarithm := math.ln_f64(math.abs(base))
	exponential := math.exp_f64(exponent * logarithm)
	result := exponential * sign
	return math.round_f64(result)
}
