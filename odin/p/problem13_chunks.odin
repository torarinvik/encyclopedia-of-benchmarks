package problem13_chunks

import "core:c"

@(export)
problem13_chunks :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 5001 do return -1
	if values[0] < 1 || values[0] > 5000 || c.size_t(values[0]) != length - 1 do return -1

	byte_length := int(values[0])
	for index := 0; index < byte_length; index += 1 {
		if values[index + 1] < 48 || values[index + 1] > 57 do return -1
	}

	width := byte_length
	if width > 50 do width = 50
	var reversed: [52]u8
	reversed_length := 0
	carry := i64(0)
	for remaining := width; remaining > 0; remaining -= 1 {
		position := remaining - 1
		column := carry
		for start := 0; start < byte_length; start += 50 {
			chunk_length := byte_length - start
			if chunk_length > 50 do chunk_length = 50
			if position < chunk_length do column += values[1 + start + position] - 48
		}
		reversed[reversed_length] = u8(column % 10)
		reversed_length += 1
		carry = column / 10
	}
	for carry > 0 {
		reversed[reversed_length] = u8(carry % 10)
		reversed_length += 1
		carry /= 10
	}

	output_length := reversed_length
	if output_length > 10 do output_length = 10
	if output == nil || capacity < c.size_t(output_length) do return -2
	for index := 0; index < output_length; index += 1 {
		output[index] = u8(48 + i64(reversed[reversed_length - 1 - index]))
	}
	return i64(output_length)
}
