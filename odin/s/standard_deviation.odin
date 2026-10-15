package standard_deviation

import "core:c"
import "core:math"

MAX_LENGTH :: 64
MAX_ABS_VALUE :: i64(1_000_000)
INVALID_RESULT :: f64 = -1.0e300

@(export)
standard_deviation :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length == 0 || length > MAX_LENGTH do return INVALID_RESULT
	sum := f64(0.0)
	for index := c.size_t(0); index < length; index += 1 {
		value := values[index]
		if value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE do return INVALID_RESULT
		sum += f64(value)
	}
	average := sum / f64(length)
	squared_deviations := f64(0.0)
	for index := c.size_t(0); index < length; index += 1 {
		difference := f64(values[index]) - average
		squared_deviations += math.pow(difference, 2.0)
	}
	return math.sqrt(squared_deviations / f64(length))
}
