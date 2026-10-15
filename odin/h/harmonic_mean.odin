package harmonic_mean

import "core:c"

MAX_LENGTH :: 64
INVALID_RESULT :: f64(-1.0e300)

@(export)
harmonic_mean :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length == 0 || length > MAX_LENGTH do return INVALID_RESULT
	reciprocal_sum := f64(0)
	for index := c.size_t(0); index < length; index += 1 {
		value := values[index]
		if value < 1 || value > 1000 do return INVALID_RESULT
		reciprocal_sum += 1.0 / f64(value)
	}
	return f64(length) / reciprocal_sum
}
