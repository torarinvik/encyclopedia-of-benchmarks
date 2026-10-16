package triplet_sum_two_pointer

import "core:c"

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

sift_down :: proc "contextless" (values: [^]i64, root_start, ending: int) {
	root := root_start
	for root < ending / 2 {
		child := root * 2 + 1
		if child + 1 < ending && values[child] < values[child + 1] { child += 1 }
		if values[root] >= values[child] { break }
		values[root], values[child] = values[child], values[root]
		root = child
	}
}

heap_sort :: proc "contextless" (values: [^]i64, length: int) {
	start := length / 2
	for start > 0 {
		start -= 1
		sift_down(values, start, length)
	}
	ending := length
	for ending > 1 {
		ending -= 1
		values[0], values[ending] = values[ending], values[0]
		sift_down(values, 0, ending)
	}
}

@(export)
triplet_sum_two_pointer :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	max_items :: 1024
	if input == nil || length < 1 || length > max_items + 1 { return -1 }
	target := input[0]
	if target < -3_000_000 || target > 3_000_000 { return -1 }
	item_count := int(length - 1)
	values: [max_items]i64
	for index := 0; index < item_count; index += 1 {
		value := input[index + 1]
		if value < -1_000_000 || value > 1_000_000 { return -1 }
		values[index] = value
	}
	if output_capacity < 24 || output == nil { return -2 }
	heap_sort(&values[0], item_count)

	result: [3]i64
	if item_count >= 3 {
		for first := 0; first < item_count - 2; first += 1 {
			left, right := first + 1, item_count - 1
			for left < right {
				sum := values[first] + values[left] + values[right]
				if sum == target {
					result = [3]i64{values[first], values[left], values[right]}
					for index := 0; index < 3; index += 1 { put_i64_le(output, index * 8, result[index]) }
					return 3
				}
				if sum < target { left += 1 } else { right -= 1 }
			}
		}
	}
	for index := 0; index < 3; index += 1 { put_i64_le(output, index * 8, result[index]) }
	return 3
}
