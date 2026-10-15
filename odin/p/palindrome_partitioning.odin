package palindrome_partitioning

import "core:c"

MAX_LENGTH :: 256

@(export)
palindrome_partitioning :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_LENGTH do return -1
	n := int(length)
	for index := 0; index < n; index += 1 {
		if input[index] < 0 || input[index] > 127 do return -1
	}
	if output == nil || output_capacity < 8 do return -2

	palindrome: [MAX_LENGTH * MAX_LENGTH]bool = {}
	cuts: [MAX_LENGTH]i64 = {}
	for end := 0; end < n; end += 1 {
		best := i64(end)
		for start := 0; start <= end; start += 1 {
			if input[start] == input[end] &&
				(end - start < 2 || palindrome[(start + 1) * MAX_LENGTH + end - 1]) {
				palindrome[start * MAX_LENGTH + end] = true
				candidate := i64(0)
				if start > 0 do candidate = cuts[start - 1] + 1
				if candidate < best do best = candidate
			}
		}
		cuts[end] = best
	}

	bits := u64(cuts[n - 1])
	for byte := 0; byte < 8; byte += 1 {
		output[byte] = u8(bits >> (8 * byte))
	}
	return 1
}
