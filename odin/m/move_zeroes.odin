package move_zeroes

import "core:c"

MAX_LENGTH :: 4096

write_i32_le :: proc "contextless" (output: [^]u8, index: c.size_t, value: i64) {
	bits := u32(i32(value))
	for byte := c.size_t(0); byte < 4; byte += 1 {
		output[index * 4 + byte] = u8((bits >> (byte * 8)) & 0xff)
	}
}

// Stable nonzero compaction followed by a zero-fill pass.
@(export)
move_zeroes :: proc "contextless" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && input == nil) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if input[index] < -2147483648 || input[index] > 2147483647 do return -1
	}
	output_bytes := length * 4
	if output_capacity < output_bytes || (output_bytes != 0 && output == nil) do return -2
	write_index := c.size_t(0)
	for index := c.size_t(0); index < length; index += 1 {
		if input[index] != 0 {
			write_i32_le(output, write_index, input[index])
			write_index += 1
		}
	}
	for write_index < length {
		write_i32_le(output, write_index, 0)
		write_index += 1
	}
	return i64(length)
}
