package next_permutation

import "core:c"

MAX_LENGTH :: 128

reverse :: proc "contextless" (values: [^]i32, left, right: int) {
	low := left
	high := right
	for low < high {
		temporary := values[low]
		values[low] = values[high]
		values[high] = temporary
		low += 1
		high -= 1
	}
}

@(export)
next_permutation :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_LENGTH + 1 do return -1
	n_value := input[0]
	if n_value < 0 || n_value > MAX_LENGTH || length != c.size_t(n_value + 1) do return -1
	n := int(n_value)
	values: [MAX_LENGTH]i32
	for i := 0; i < n; i += 1 {
		value := input[i + 1]
		if value < -2147483648 || value > 2147483647 do return -1
		values[i] = i32(value)
	}
	required := c.size_t(n * 4)
	if output_capacity < required || (required > 0 && output == nil) do return -2
	pivot := n
	index := n
	for index > 1 {
		index -= 1
		if values[index - 1] < values[index] { pivot = index - 1; break }
	}
	if pivot == n {
		if n > 1 do reverse(&values[0], 0, n - 1)
	} else {
		successor := n - 1
		for values[successor] <= values[pivot] { successor -= 1 }
		temporary := values[pivot]
		values[pivot] = values[successor]
		values[successor] = temporary
		if pivot + 1 < n do reverse(&values[0], pivot + 1, n - 1)
	}
	for i := 0; i < n; i += 1 {
		bits := u32(values[i])
		for byte := 0; byte < 4; byte += 1 { output[i * 4 + byte] = u8((bits >> u32(byte * 8)) & 255) }
	}
	return i64(n)
}
