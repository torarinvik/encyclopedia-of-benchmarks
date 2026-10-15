package average

import "core:c"

MAX_INPUT_LENGTH :: 4096
MAX_ABS_VALUE :: i64(1_000_000_000)
INVALID_RESULT :: f64 = -1.0e300

@(export)
average :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if length == 0 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	sum := i64(0)
	for index := c.size_t(0); index < length; index += 1 {
		value := values[index]
		if value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE do return INVALID_RESULT
		sum += value
	}
	return f64(sum) / f64(length)
}
