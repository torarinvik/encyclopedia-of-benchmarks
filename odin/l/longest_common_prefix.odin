package longest_common_prefix

import "core:c"

compare_strings :: proc(input: [^]i64, start_a, len_a, start_b, len_b: int) -> int {
	limit := min(len_a, len_b)
	for i := 0; i < limit; i += 1 {
		if input[start_a + i] < input[start_b + i] do return -1
		if input[start_a + i] > input[start_b + i] do return 1
	}
	if len_a < len_b do return -1
	if len_a > len_b do return 1
	return 0
}

@(export)
longest_common_prefix :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if length < 1 || length > 1041 do return -1
	if input[0] < 0 || input[0] > 16 do return -1
	count := int(input[0])
	starts: [16]int = {}
	sizes: [16]int = {}
	position := 1
	for i := 0; i < count; i += 1 {
		if position >= int(length) || input[position] < 0 || input[position] > 64 do return -1
		sizes[i] = int(input[position]); position += 1
		if sizes[i] > int(length) - position do return -1
		starts[i] = position
		for j := 0; j < sizes[i]; j += 1 {
			if input[position + j] < 0 || input[position + j] > 127 do return -1
		}
		position += sizes[i]
	}
	if position != int(length) do return -1
	if count == 0 do return 0
	order: [16]int = {}
	for i := 0; i < count; i += 1 { order[i] = i }
	for i := 1; i < count; i += 1 {
		value := order[i]
		j := i
		for j > 0 && compare_strings(input, starts[order[j - 1]], sizes[order[j - 1]], starts[value], sizes[value]) > 0 {
			order[j] = order[j - 1]; j -= 1
		}
		order[j] = value
	}
	first := order[0]; last := order[count - 1]
	limit := min(sizes[first], sizes[last])
	prefix := 0
	for prefix < limit && input[starts[first] + prefix] == input[starts[last] + prefix] { prefix += 1 }
	if capacity < c.size_t(prefix) || (prefix > 0 && output == nil) do return -2
	for i := 0; i < prefix; i += 1 { output[i] = u8(input[starts[first] + i]) }
	return i64(prefix)
}
