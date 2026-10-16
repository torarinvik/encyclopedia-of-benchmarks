package range_in_sorted_array

import "core:c"

MAX_N :: 512
INT32_MIN_VALUE :: -2147483648
INT32_MAX_VALUE :: 2147483647

find_bound :: proc "contextless" (values: [^]i64, offset, n: int, key: i64, find_left: bool) -> i32 {
	left := 0
	right := n - 1
	for left <= right {
		mid := left + (right - left) / 2
		if values[offset + mid] > key { right = mid - 1 }
		else if values[offset + mid] < key { left = mid + 1 }
		else if find_left {
			if mid == 0 || values[offset + mid - 1] != key do return i32(mid)
			right = mid - 1
		} else {
			if mid == n - 1 || values[offset + mid + 1] != key do return i32(mid)
			left = mid + 1
		}
	}
	return -1
}

put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
	bits := u32(value)
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8((bits >> u32(8 * byte)) & 255)
	}
}

@(export)
range_in_sorted_array :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || input[0] < 0 || input[0] > MAX_N || length != c.size_t(input[0] + 2) do return -1
	n := int(input[0])
	key := input[n + 1]
	if key < INT32_MIN_VALUE || key > INT32_MAX_VALUE do return -1
	for index := 0; index < n; index += 1 {
		value := input[index + 1]
		if value < INT32_MIN_VALUE || value > INT32_MAX_VALUE do return -1
		if index > 0 && input[index] > value do return -1
	}
	first := find_bound(input, 1, n, key, true)
	last := find_bound(input, 1, n, key, false)
	if output == nil || output_capacity < 8 do return -2
	put_i32_le(output, 0, first)
	put_i32_le(output, 4, last)
	return 8
}
