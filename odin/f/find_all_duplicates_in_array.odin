package find_all_duplicates_in_array

import "core:c"

MAX_LENGTH :: 100_000

sift_down :: proc "contextless" (values: [^]i32, root_value, end: c.size_t) {
	root := root_value
	for root*2+1 < end {
		child := root*2 + 1
		if child+1 < end && values[child] < values[child+1] do child += 1
		if values[root] >= values[child] do break
		temporary := values[root]
		values[root] = values[child]
		values[child] = temporary
		root = child
	}
}

heap_sort :: proc "contextless" (values: [^]i32, length: c.size_t) {
	start := length / 2
	for start > 0 {
		start -= 1
		sift_down(values, start, length)
	}
	ending := length
	for ending > 1 {
		ending -= 1
		temporary := values[0]
		values[0] = values[ending]
		values[ending] = temporary
		sift_down(values, 0, ending)
	}
}

// Sort a bounded copy and emit sorted duplicate values as little-endian i32s.
@(export)
find_all_duplicates_in_array :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && values == nil) do return -1
	if length == 0 do return 0

	sorted: [MAX_LENGTH]i32
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] < 1 || values[index] > i64(length) do return -1
		sorted[index] = i32(values[index])
	}
	heap_sort(&sorted[0], length)

	duplicate_count := c.size_t(0)
	index := c.size_t(0)
	for index < length {
		ending := index + 1
		for ending < length && sorted[ending] == sorted[index] do ending += 1
		frequency := ending - index
		if frequency > 2 do return -1
		if frequency == 2 do duplicate_count += 1
		index = ending
	}
	output_bytes := duplicate_count * 4
	if output_capacity < output_bytes || (output_bytes != 0 && output == nil) do return -2

	destination := c.size_t(0)
	index = 0
	for index < length {
		ending := index + 1
		for ending < length && sorted[ending] == sorted[index] do ending += 1
		if ending-index == 2 {
			value := u32(sorted[index])
			for byte := 0; byte < 4; byte += 1 {
				output[destination*4+c.size_t(byte)] = u8((value >> u32(byte*8)) & 255)
			}
			destination += 1
		}
		index = ending
	}
	return i64(duplicate_count)
}
