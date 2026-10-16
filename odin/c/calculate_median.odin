package calculate_median

import "core:c"

MAX_LENGTH :: 1024
INVALID_RESULT :: i64(-9223372036854775807 - 1)

@(export)
calculate_median :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_LENGTH do return INVALID_RESULT
	count := int(length)
	middle := count / 2
	if count % 2 != 0 do return values[middle] * 2
	return values[middle - 1] + values[middle]
}
