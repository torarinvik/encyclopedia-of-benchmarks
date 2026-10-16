package remove_duplicate_characters

import "core:c"

MAX_INPUT_LENGTH :: 4096

@(export)
remove_duplicate_characters :: proc "c" (values: [^]i64, length: c.size_t,
                                            output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || values[0] < 0 || values[0] > MAX_INPUT_LENGTH do return -1
	text_length := int(values[0])
	if length != c.size_t(text_length + 1) do return -1
	for index := 0; index < text_length; index += 1 {
		if values[index + 1] < 0 || values[index + 1] > 127 do return -1
	}

	seen: [128]bool
	for index := 0; index < 128; index += 1 do seen[index] = false
	output_length := 0
	for index := 0; index < text_length; index += 1 {
		byte := int(values[index + 1])
		if !seen[byte] { seen[byte] = true; output_length += 1 }
	}
	if c.size_t(output_length) > output_capacity || (output_length > 0 && output == nil) do return -2

	for index := 0; index < 128; index += 1 do seen[index] = false
	written := 0
	for index := 0; index < text_length; index += 1 {
		byte := int(values[index + 1])
		if !seen[byte] {
			seen[byte] = true
			output[written] = u8(byte)
			written += 1
		}
	}
	return i64(written)
}
