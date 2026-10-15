package weighted_average

import "core:c"

MAX_N :: i64(64)
MAX_ABS_VALUE :: i64(1_000_000)
INVALID_RESULT :: f64 = -1.0e300

@(export)
weighted_average :: proc "c" (packed: [^]i64, length: c.size_t) -> f64 {
	if packed == nil || length < 1 || length > 129 do return INVALID_RESULT
	n := packed[0]
	if n < 1 || n > MAX_N || length != c.size_t(1 + 2 * n) do return INVALID_RESULT
	weighted_sum := i64(0)
	total_weight := i64(0)
	for index := i64(0); index < n; index += 1 {
		value := packed[1 + index]
		weight := packed[1 + n + index]
		if value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE || weight < -MAX_ABS_VALUE || weight > MAX_ABS_VALUE do return INVALID_RESULT
		weighted_sum += value * weight
		total_weight += weight
	}
	if total_weight == 0 do return INVALID_RESULT
	return f64(weighted_sum) / f64(total_weight)
}
