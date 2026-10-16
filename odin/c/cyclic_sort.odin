package cyclic_sort

import "core:c"

@(export)
cyclic_sort :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	max_length :: 1024
	if length > max_length || (length > 0 && values == nil) { return -1 }
	seen: [max_length + 1]bool
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < 1 || value > i64(length) || seen[int(value)] { return -1 }
		seen[int(value)] = true
	}

	sorted: [max_length]i64
	for index := 0; index < int(length); index += 1 { sorted[index] = values[index] }
	index := 0
	for index < int(length) {
		destination := int(sorted[index] - 1)
		if destination == index {
			index += 1
		} else {
			sorted[index], sorted[destination] = sorted[destination], sorted[index]
		}
	}

	output_length := int(length) * 8
	if c.size_t(output_length) > output_capacity || (output_length > 0 && output == nil) { return -2 }
	for item := 0; item < int(length); item += 1 {
		bits := u64(sorted[item])
		for byte := 0; byte < 8; byte += 1 {
			output[item * 8 + byte] = u8((bits >> u64(byte * 8)) & 255)
		}
	}
	return i64(length)
}
