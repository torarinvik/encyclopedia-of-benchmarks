package inverted_list_svs_binary_search

import "core:c"

MIN_LISTS :: 2
MAX_LISTS :: 8
MAX_LIST_LENGTH :: 32
MAX_INPUT_LENGTH :: 266
BYTES_PER_VALUE :: 4

store_i32_le :: proc "contextless" (output: [^]u8, position: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < BYTES_PER_VALUE; byte += 1 { output[position + byte] = u8((bits >> u64(byte * 8)) & 255) }
}

@(export)
inverted_list_svs_binary_search :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < MIN_LISTS + 1 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < MIN_LISTS || input[0] > MAX_LISTS do return -1
	count := int(input[0])
	starts: [MAX_LISTS]int
	sizes: [MAX_LISTS]int
	order: [MAX_LISTS]int
	position := 1
	for list := 0; list < count; list += 1 {
		if position >= int(length) || input[position] < 0 || input[position] > MAX_LIST_LENGTH do return -1
		size := int(input[position]); position += 1
		if size > int(length) - position do return -1
		starts[list] = position; sizes[list] = size; order[list] = list
		for i := 0; i < size; i += 1 {
			value := input[position + i]
			if value < -2147483648 || value > 2147483647 do return -1
			if i > 0 && input[position + i - 1] >= value do return -1
		}
		position += size
	}
	if position != int(length) do return -1
	for i := 1; i < count; i += 1 {
		key := order[i]; j := i
		for j > 0 && sizes[order[j - 1]] > sizes[key] { order[j] = order[j - 1]; j -= 1 }
		order[j] = key
	}
	maximum_result := sizes[order[0]]
	if output_capacity < c.size_t(maximum_result * BYTES_PER_VALUE) || (maximum_result > 0 && output == nil) do return -2
	candidates: [MAX_LIST_LENGTH]i32
	candidate_count := maximum_result
	for i := 0; i < candidate_count; i += 1 { candidates[i] = i32(input[starts[order[0]] + i]) }
	for rank := 1; rank < count; rank += 1 {
		if candidate_count == 0 do break
		list := order[rank]; start := starts[list]; size := sizes[list]
		cursor := 0; kept := 0
		for i := 0; i < candidate_count; i += 1 {
			candidate := candidates[i]; low := cursor; high := size
			for low < high {
				middle := low + (high - low) / 2
				if input[start + middle] < i64(candidate) { low = middle + 1 } else { high = middle }
			}
			if low < size && input[start + low] == i64(candidate) {
				candidates[kept] = candidate; kept += 1; cursor = low + 1
			} else { cursor = low }
		}
		candidate_count = kept
	}
	for i := 0; i < candidate_count; i += 1 { store_i32_le(output, i * BYTES_PER_VALUE, candidates[i]) }
	return i64(candidate_count)
}
