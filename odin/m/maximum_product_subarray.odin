package maximum_product_subarray

import "core:c"

INVALID_RESULT :: i64(-9_223_372_036_854_775_807) - 1

@(export)
maximum_product_subarray :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length == 0 || length > 9 do return INVALID_RESULT
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] < -10 || values[index] > 10 do return INVALID_RESULT
	}

	current_max := values[0]
	current_min := values[0]
	best := values[0]
	for index := c.size_t(1); index < length; index += 1 {
		value := values[index]
		prior_max := current_max
		prior_min := current_min
		from_max := prior_max * value
		from_min := prior_min * value
		current_max = max(value, max(from_max, from_min))
		current_min = min(value, min(from_max, from_min))
		best = max(best, current_max)
	}
	return best
}
