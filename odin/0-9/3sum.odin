package three_sum

import "core:c"

MAX_ITEMS :: 257
BYTES_PER_TRIPLET :: 12

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

enumerate_triplets :: proc "contextless" (values: [^]i64, count: int,
	output: [^]u8, write_output: bool) -> int {
	result_count := 0
	for first := 0; first + 2 < count; first += 1 {
		if first > 0 && values[first] == values[first - 1] do continue
		left := first + 1
		right := count - 1
		for left < right {
			sum := values[first] + values[left] + values[right]
			if sum < 0 {
				left += 1
			} else if sum > 0 {
				right -= 1
			} else {
				if write_output {
					offset := result_count * BYTES_PER_TRIPLET
					store_i32_le(output, offset, values[first])
					store_i32_le(output, offset + 4, values[left])
					store_i32_le(output, offset + 8, values[right])
				}
				result_count += 1
				left += 1
				right -= 1
				for left < right && values[left] == values[left - 1] do left += 1
				for left < right && values[right] == values[right + 1] do right -= 1
			}
		}
	}
	return result_count
}

// Return unique sorted zero-sum triplets using sort-and-two-pointers.
@(export)
three_sum :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > c.size_t(MAX_ITEMS) || (length != 0 && input == nil) do return -1
	values: [MAX_ITEMS]i64
	for index := 0; index < int(length); index += 1 {
		value := input[index]
		if value < -100000 || value > 100000 do return -1
		values[index] = value
	}
	heap_sort_values(&values[0], int(length))

	maximum_bytes := c.size_t(0)
	if length > 1 do maximum_bytes = length * (length - 1) / 2 * c.size_t(BYTES_PER_TRIPLET)
	if output_capacity < maximum_bytes || output == nil {
		needed := c.size_t(enumerate_triplets(&values[0], int(length), nil, false) * BYTES_PER_TRIPLET)
		if output_capacity < needed || (needed != 0 && output == nil) do return -2
	}
	return i64(enumerate_triplets(&values[0], int(length), output, output != nil))
}
