package wave_string

import "core:c"

is_ascii_letter :: proc "contextless" (value: i64) -> bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

@(export)
wave_string :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	max_text_length :: 512
	if values == nil || length < 1 || values[0] < 0 || values[0] > max_text_length ||
		length != c.size_t(1 + values[0]) { return -1 }
	text_length := int(values[0])
	letter_count := 0
	for index := 0; index < text_length; index += 1 {
		byte := values[index + 1]
		if byte < 32 || byte > 126 { return -1 }
		if is_ascii_letter(byte) { letter_count += 1 }
	}
	output_length := letter_count * (text_length + 2)
	if c.size_t(output_length) > output_capacity || (output_length > 0 && output == nil) { return -2 }

	written := 0
	for position := 0; position < text_length; position += 1 {
		if !is_ascii_letter(values[position + 1]) { continue }
		output[written] = u8(text_length & 255)
		output[written + 1] = u8(text_length >> 8)
		written += 2
		for index := 0; index < text_length; index += 1 {
			byte := values[index + 1]
			if index == position && byte >= 97 && byte <= 122 { byte -= 32 }
			output[written] = u8(byte)
			written += 1
		}
	}
	return i64(letter_count)
}
