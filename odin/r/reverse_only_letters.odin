package reverse_only_letters

import "core:c"

MAX_LENGTH :: 4096

is_ascii_letter :: proc(value: u8) -> bool {
	return (value >= u8('A') && value <= u8('Z')) || (value >= u8('a') && value <= u8('z'))
}

@(export)
reverse_only_letters :: proc "contextless" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && input == nil) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if input[index] < 32 || input[index] > 126 do return -1
	}
	if output_capacity < length || (length != 0 && output == nil) do return -2
	for index := c.size_t(0); index < length; index += 1 { output[index] = u8(input[index]) }

	left := c.size_t(0)
	right := length
	for left < right {
		if !is_ascii_letter(output[left]) {
			left += 1
		} else if !is_ascii_letter(output[right - 1]) {
			right -= 1
		} else {
			temporary := output[left]
			output[left] = output[right - 1]
			output[right - 1] = temporary
			left += 1
			right -= 1
		}
	}
	return i64(length)
}
