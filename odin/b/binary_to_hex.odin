package binary_to_hex

import "core:c"

MAX_LENGTH :: 4096

@(export)
binary_to_hex :: proc "c" (values: [^]i64, length: c.size_t,
							 output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && values == nil) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] != 48 && values[index] != 49 do return -1
	}

	output_length := (length + 3) / 4
	if output_length == 0 do return 0
	if output == nil || output_capacity < output_length do return -2

	first_width := length % 4
	if first_width == 0 do first_width = 4
	start := c.size_t(0)
	for group := c.size_t(0); group < output_length; group += 1 {
		width := c.size_t(4)
		if group == 0 do width = first_width
		nibble := 0
		for offset := c.size_t(0); offset < width; offset += 1 {
			nibble = nibble * 2 + int(values[start + offset] - 48)
		}
		if nibble < 10 {
			output[group] = u8(48 + nibble)
		} else {
			output[group] = u8(55 + nibble)
		}
		start += width
	}
	return i64(output_length)
}
