package swap_pairs

import "core:c"

MAX_LENGTH :: 1024

// Swap adjacent node values in a bounded array representation of a list.
@(export)
swap_pairs :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && input == nil) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if input[index] < -2147483648 || input[index] > 2147483647 do return -1
	}
	output_bytes := length * 4
	if output_capacity < output_bytes || (output_bytes != 0 && output == nil) do return -2

	for index := c.size_t(0); index < length; index += 1 {
		pair_start := (index / 2) * 2
		source_index := pair_start
		if index % 2 == 0 && pair_start + 1 < length do source_index = pair_start + 1
		bits := u32(i32(input[source_index]))
		for byte := c.size_t(0); byte < 4; byte += 1 {
			output[index * 4 + byte] = u8((bits >> (byte * 8)) & 0xff)
		}
	}
	return i64(length)
}
