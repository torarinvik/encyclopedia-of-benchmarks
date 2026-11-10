package count_leading_zeros

import "core:math/bits"

@(export)
count_leading_zeros :: proc "c" (value: i64) -> i64 {
	if value < -2147483648 || value > 2147483647 do return -1
	return i64(bits.count_leading_zeros(u32(value)))
}
