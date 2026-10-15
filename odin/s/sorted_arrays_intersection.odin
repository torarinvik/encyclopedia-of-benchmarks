package sorted_arrays_intersection

import "core:c"

ARRAY_COUNT :: 3
MAX_ARRAY_LENGTH :: 64
BYTES_PER_VALUE :: 4

store_i32_le :: proc "contextless" (output: [^]u8, position: int, value: i64) {
	bits := u32(value)
	for byte := 0; byte < BYTES_PER_VALUE; byte += 1 {
		output[position + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
sorted_arrays_intersection :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < ARRAY_COUNT || length > ARRAY_COUNT * (MAX_ARRAY_LENGTH + 1) do return -1
	starts: [ARRAY_COUNT]int
	sizes: [ARRAY_COUNT]int
	position := 0
	for array := 0; array < ARRAY_COUNT; array += 1 {
		if position >= int(length) || input[position] < 0 || input[position] > MAX_ARRAY_LENGTH do return -1
		size := int(input[position])
		position += 1
		if size > int(length) - position do return -1
		starts[array] = position
		sizes[array] = size
		for index := 0; index < size; index += 1 {
			if input[position + index] < -2147483648 || input[position + index] > 2147483647 do return -1
			if index > 0 && input[position + index - 1] >= input[position + index] do return -1
		}
		position += size
	}
	if position != int(length) do return -1
	maximum_result := min(sizes[0], min(sizes[1], sizes[2]))
	if output_capacity < c.size_t(maximum_result * BYTES_PER_VALUE) || (maximum_result > 0 && output == nil) do return -2

	cursor: [ARRAY_COUNT]int = {}
	result_count := 0
	for cursor[0] < sizes[0] && cursor[1] < sizes[1] && cursor[2] < sizes[2] {
		first := input[starts[0] + cursor[0]]
		second := input[starts[1] + cursor[1]]
		third := input[starts[2] + cursor[2]]
		if first == second && first == third {
			store_i32_le(output, result_count * BYTES_PER_VALUE, first)
			result_count += 1
			cursor[0] += 1; cursor[1] += 1; cursor[2] += 1
		} else if first < second {
			cursor[0] += 1
		} else if second < third {
			cursor[1] += 1
		} else {
			cursor[2] += 1
		}
	}
	return i64(result_count)
}
