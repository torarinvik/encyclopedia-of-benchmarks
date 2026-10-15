package booths_algorithm

import "core:c"

@(export)
booths_algorithm :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length == 0 || length > 256 do return -1
	for index := 0; index < int(length); index += 1 {
		if values[index] < 0 || values[index] > 127 do return -1
	}
	if output == nil || capacity < length do return -2

	failure: [512]i64
	for index := 0; index < 2 * int(length); index += 1 do failure[index] = -1
	start := 0
	for j := 1; j < 2 * int(length); j += 1 {
		current := values[j % int(length)]
		matched := failure[j - start - 1]
		for matched != -1 && current != values[(start + int(matched) + 1) % int(length)] {
			if current < values[(start + int(matched) + 1) % int(length)] do start = j - int(matched) - 1
			matched = failure[int(matched)]
		}
		if matched == -1 && current != values[start % int(length)] {
			if current < values[start % int(length)] do start = j
			failure[j - start] = -1
		} else {
			failure[j - start] = matched + 1
		}
	}

	for index := 0; index < int(length); index += 1 {
		output[index] = u8(values[(start + index) % int(length)])
	}
	return i64(length)
}
