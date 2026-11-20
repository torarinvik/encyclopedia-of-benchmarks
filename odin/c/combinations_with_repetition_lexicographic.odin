package combinations_with_repetition_lexicographic

import "core:c"

multiset_count :: proc(n, r: int) -> int {
	if r == 0 do return 1
	if n == 0 do return 0
	top := n + r - 1
	result := 1
	for index := 1; index <= r; index += 1 {
		result = result * (top - r + index) / index
	}
	return result
}

@(export)
combinations_with_repetition_lexicographic :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	if input[0] < 0 || input[0] > 4 || input[1] < 0 || input[1] > 4 do return -1
	n := int(input[0])
	r := int(input[1])
	count := multiset_count(n, r)
	byte_count := 2 + count * r
	if output == nil || int(capacity) < byte_count do return -2

	output[0] = u8(count & 255)
	output[1] = u8((count >> 8) & 255)
	current: [4]u8 = {}
	for ordinal := 0; ordinal < count; ordinal += 1 {
		for position := 0; position < r; position += 1 {
			output[2 + ordinal * r + position] = current[position]
		}
		if ordinal + 1 < count && r > 0 {
			position := r
			for int(current[position - 1]) == n - 1 { position -= 1 }
			position -= 1
			current[position] += 1
			for suffix := position + 1; suffix < r; suffix += 1 { current[suffix] = current[position] }
		}
	}
	return i64(byte_count)
}
