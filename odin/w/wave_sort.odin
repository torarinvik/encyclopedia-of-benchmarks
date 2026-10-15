package wave_sort

import "core:c"

MAX_ARRAY_LENGTH :: 4096

sift_down :: proc "contextless" (values: [^]i64, root_start, end_value: int) {
	root := root_start
	for root < end_value / 2 {
		child := root * 2 + 1
		if child + 1 < end_value && values[child] < values[child + 1] do child += 1
		if values[root] >= values[child] do break
		temporary := values[root]
		values[root] = values[child]
		values[child] = temporary
		root = child
	}
}

heap_sort_values :: proc "contextless" (values: [^]i64, count: int) {
	start := count / 2
	for start > 0 {
		start -= 1
		sift_down(values, start, count)
	}
	ending := count
	for ending > 1 {
		ending -= 1
		temporary := values[0]
		values[0] = values[ending]
		values[ending] = temporary
		sift_down(values, 0, ending)
	}
}

store_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u32(i32(value))
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8((bits >> u32(byte * 8)) & 255)
	}
}

@(export)
wave_sort :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > c.size_t(MAX_ARRAY_LENGTH) || (length != 0 && input == nil) do return -1
	if output_capacity < length * 4 || (length != 0 && output == nil) do return -2
	values: [MAX_ARRAY_LENGTH]i64
	for index := 0; index < int(length); index += 1 {
		value := input[index]
		if value < -2_147_483_648 || value > 2_147_483_647 do return -1
		values[index] = value
	}
	heap_sort_values(&values[0], int(length))
	for index := 0; index + 1 < int(length); index += 2 {
		temporary := values[index]
		values[index] = values[index + 1]
		values[index + 1] = temporary
	}
	for index := 0; index < int(length); index += 1 {
		store_i32_le(output, index * 4, values[index])
	}
	return i64(length)
}
