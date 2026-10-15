package remove_duplicates_from_sorted_array

import "core:c"

MAX_LENGTH :: 4096

// Compact each value in an ascending array to its first occurrence.
@(export)
remove_duplicates_from_sorted_array :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && input == nil) do return -1
	unique_count := c.size_t(0)
	for index := c.size_t(0); index < length; index += 1 {
		value := input[index]
		if value < -2147483648 || value > 2147483647 ||
			(index > 0 && input[index - 1] > value) { return -1 }
		if index == 0 || input[index - 1] != value do unique_count += 1
	}
	output_bytes := unique_count * 4
	if output_capacity < output_bytes || (output_bytes != 0 && output == nil) do return -2
	written := c.size_t(0)
	for index := c.size_t(0); index < length; index += 1 {
		value := input[index]
		if index == 0 || input[index - 1] != value {
			bits := u32(i32(value))
			for byte := c.size_t(0); byte < 4; byte += 1 {
				output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff)
			}
			written += 1
		}
	}
	if written != unique_count do return -1
	return i64(written)
}
