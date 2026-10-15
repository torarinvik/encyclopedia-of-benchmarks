package min_number_of_jumps

import "core:c"

MAX_LENGTH :: 64
UNREACHABLE :: i64(1_000_000_000_000)

@(export)
min_number_of_jumps :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_LENGTH do return -1
	for i := c.size_t(0); i < length; i += 1 {
		if values[i] < 0 || values[i] > MAX_LENGTH do return -1
	}
	jumps: [MAX_LENGTH]i64
	for i := 0; i < MAX_LENGTH; i += 1 { jumps[i] = UNREACHABLE }
	jumps[0] = 0
	for i := 1; i < int(length); i += 1 {
		for j := 0; j < i; j += 1 {
			if values[j] + i64(j) >= i64(i) && jumps[j] + 1 < jumps[i] { jumps[i] = jumps[j] + 1 }
		}
	}
	return jumps[int(length) - 1]
}
