package arithmeticmean

import "core:c"

MAX_VALUE :: i64(9_000_000_000_000_000_000)

// Overflow-safe floor arithmetic mean using the bitwise identity.
@(export)
arithmeticmean :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	left := values[0]
	right := values[1]
	if left < 0 || left > MAX_VALUE || right < 0 || right > MAX_VALUE do return -1
	return ((left ~ right) >> 1) + (left & right)
}
