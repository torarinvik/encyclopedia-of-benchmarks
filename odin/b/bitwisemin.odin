package bitwisemin

import "core:c"

MAX_LENGTH :: c.size_t(4096)
MAX_VALUE :: i64(2_147_483_647)

// Reduce the input array to its minimum with a sign-bit mask.
@(export)
bitwisemin :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length == 0 || length > MAX_LENGTH do return -1
	minimum := values[0]
	if minimum < 0 || minimum > MAX_VALUE do return -1
	for index := c.size_t(1); index < length; index += 1 {
		value := values[index]
		if value < 0 || value > MAX_VALUE do return -1
		difference := minimum - value
		sign := (u32(difference) >> 31) & 1
		keep_minimum := u32(0xFFFF_FFFF) * sign
		minimum = i64((u32(minimum) & keep_minimum) | (u32(value) & ~keep_minimum))
	}
	return minimum
}
