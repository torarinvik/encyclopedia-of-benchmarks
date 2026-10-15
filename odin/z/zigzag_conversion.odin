package zigzag_conversion

import "core:c"

MAX_INPUT_LENGTH :: 1025
MAX_ROWS :: 1024

is_ascii_letter :: proc(value: i64) -> bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

@(export)
zigzag_conversion :: proc "contextless" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length == 0 || length > MAX_INPUT_LENGTH || values == nil do return -1
	rows_value := values[0]
	if rows_value < 1 || rows_value > MAX_ROWS do return -1
	text_length := length - 1
	for index := c.size_t(0); index < text_length; index += 1 {
		if !is_ascii_letter(values[index + 1]) do return -1
	}
	if output_capacity < text_length || (text_length != 0 && output == nil) do return -2
	if text_length == 0 do return 0
	rows := c.size_t(rows_value)
	if rows == 1 || rows >= text_length {
		for index := c.size_t(0); index < text_length; index += 1 {
			output[index] = u8(values[index + 1])
		}
		return i64(text_length)
	}
	cycle := 2 * (rows - 1)
	written := c.size_t(0)
	for row := c.size_t(0); row < rows; row += 1 {
		index := row
		step := cycle
		if row > 0 && row + 1 < rows do step = cycle - 2 * row
		for index < text_length {
			output[written] = u8(values[index + 1])
			written += 1
			index += step
			if row > 0 && row + 1 < rows do step = cycle - step
		}
	}
	return i64(written)
}
