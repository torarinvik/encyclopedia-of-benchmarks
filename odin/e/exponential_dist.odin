package exponential_dist

import "core:c"
import "core:math"

MAX_RATE_MICRO :: i64(1_000_000_000)
INVALID_RESULT :: f64(-1.0e300)

@(export)
exponential_dist :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return INVALID_RESULT
	operation, rate_micro := values[0], values[1]
	if operation < 0 || operation > 2 || rate_micro <= 0 || rate_micro > MAX_RATE_MICRO do return INVALID_RESULT
	rate := f64(rate_micro) / 1_000_000.0
	if operation == 1 do return 1.0 / math.pow_f64(rate, 2.0)
	return 1.0 / rate
}
