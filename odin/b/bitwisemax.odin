package bitwisemax

import "core:c"

MAX_VALUE :: i64(2_147_483_647)

// Select the larger signed-32-bit nonnegative value with a sign bit.
@(export)
bitwisemax :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	left := values[0]
	right := values[1]
	if left < 0 || left > MAX_VALUE || right < 0 || right > MAX_VALUE do return -1
	difference := left - right
	choose_right := i64(u32(difference) >> 31)
	return left - choose_right * difference
}
