package quadratic_mean

import "core:c"
import "core:math"

MAX_LENGTH :: 64
INVALID_RESULT :: f64(-1.0e300)

@(export)
quadratic_mean :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length == 0 || length > MAX_LENGTH do return INVALID_RESULT
	square_sum := f64(0)
	for index := c.size_t(0); index < length; index += 1 {
		value := values[index]
		if value < -1000 || value > 1000 do return INVALID_RESULT
		converted := f64(value)
		square_sum += converted * converted
	}
	return math.sqrt(square_sum / f64(length))
}
