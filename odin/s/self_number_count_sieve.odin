package self_number_count_sieve

import "core:c"

MAX_LIMIT :: 100000
MAX_PARSEABLE_LENGTH :: 2

digit_sum10 :: proc(value: i64) -> i64 {
	remaining := value
	sum := i64(0)
	for remaining > 0 {
		sum += remaining % 10
		remaining /= 10
	}
	return sum
}

@(export)
self_number_count_sieve :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	limit := input[0]
	if length != 1 || limit < 1 || limit > i64(MAX_LIMIT) do return -1

	generated: [1563]u64 = {}
	for source := i64(1); source <= limit; source += 1 {
		target := source + digit_sum10(source)
		if target <= limit do generated[int(target / 64)] |= u64(1) << u32(target % 64)
	}
	count := i64(0)
	for value := i64(1); value <= limit; value += 1 {
		if (generated[int(value / 64)] & (u64(1) << u32(value % 64))) == 0 do count += 1
	}
	return count
}
