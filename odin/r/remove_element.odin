package remove_element

import "core:c"

MAX_LENGTH :: 4096

// Remove every occurrence of target while preserving the surviving order.
@(export)
remove_element :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length == 0 || length > MAX_LENGTH || input == nil do return -1
	target := input[0]
	if target < -2147483648 || target > 2147483647 do return -1
	survivor_count := c.size_t(0)
	for index := c.size_t(1); index < length; index += 1 {
		value := input[index]
		if value < -2147483648 || value > 2147483647 do return -1
		if value != target do survivor_count += 1
	}
	output_bytes := survivor_count * 4
	if output_capacity < output_bytes || (output_bytes != 0 && output == nil) do return -2
	written := c.size_t(0)
	for index := c.size_t(1); index < length; index += 1 {
		value := input[index]
		if value != target {
			bits := u32(i32(value))
			for byte := c.size_t(0); byte < 4; byte += 1 {
				output[written * 4 + byte] = u8((bits >> (byte * 8)) & 0xff)
			}
			written += 1
		}
	}
	if written != survivor_count do return -1
	return i64(written)
}
