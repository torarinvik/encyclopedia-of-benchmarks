package reverse_complement

import "core:c"

@(export)
reverse_complement :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > 1000 || (length != 0 && input == nil) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		base := input[index]
		if base != 65 && base != 67 && base != 71 && base != 84 do return -1
	}
	if output_capacity < length || (length != 0 && output == nil) do return -2
	for index := c.size_t(0); index < length; index += 1 {
		base := input[length - 1 - index]
		complement := 67
		if base == 65 do complement = 84
		if base == 84 do complement = 65
		if base == 67 do complement = 71
		output[index] = u8(complement)
	}
	return i64(length)
}
