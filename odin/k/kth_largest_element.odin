package kth_largest_element

import "core:c"

MAX_LENGTH :: 512

// Descending Lomuto quickselect with the final element as pivot.
@(export)
kth_largest_element :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_LENGTH + 1 do return -1
	n := int(length) - 1
	if input[0] < 1 || input[0] > i64(n) do return -1
	values: [MAX_LENGTH]i32
	for index := 0; index < n; index += 1 {
		value := input[index + 1]
		if value < -2147483648 || value > 2147483647 do return -1
		values[index] = i32(value)
	}
	target := int(input[0]) - 1
	low := 0
	high := n - 1
	for low <= high {
		pivot := values[high]
		boundary := low
		for scan := low; scan < high; scan += 1 {
			if values[scan] >= pivot {
				temporary := values[boundary]
				values[boundary] = values[scan]
				values[scan] = temporary
				boundary += 1
			}
		}
		temporary := values[boundary]
		values[boundary] = values[high]
		values[high] = temporary
		if boundary == target do return i64(values[boundary])
		if boundary > target do high = boundary - 1
		else do low = boundary + 1
	}
	return -1
}
