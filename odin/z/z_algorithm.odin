package z_algorithm

import "core:c"

MAX_LENGTH :: 2047

@(export)
z_algorithm :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 2048 do return -1
	if input[0] < 0 || input[0] > MAX_LENGTH do return -1
	count := c.size_t(input[0])
	if length != count + 1 do return -1
	output_bytes := count * 4
	if output_capacity < output_bytes || (count > 0 && output == nil) do return -2

	z: [MAX_LENGTH]c.size_t
	for index := c.size_t(0); index < MAX_LENGTH; index += 1 { z[index] = 0 }
	left, right := c.size_t(0), c.size_t(0)
	for index := c.size_t(1); index < count; index += 1 {
		if index < right do z[index] = min(z[index - left], right - index)
		for index + z[index] < count && input[1 + z[index]] == input[1 + index + z[index]] {
			z[index] += 1
		}
		if index + z[index] > right {
			left = index
			right = index + z[index]
		}
	}
	for index := c.size_t(0); index < count; index += 1 {
		for byte := c.size_t(0); byte < 4; byte += 1 { output[index * 4 + byte] = u8(z[index] >> (byte * 8)) }
	}
	return i64(count)
}
