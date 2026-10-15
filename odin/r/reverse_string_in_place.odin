package reverse_string_in_place

import "core:c"

MAX_LENGTH :: 4096

// Reverse bytes by swapping inward from both ends.
@(export)
reverse_string_in_place :: proc "contextless" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_LENGTH || (length != 0 && input == nil) do return -1
	for index := c.size_t(0); index < length; index += 1 {
		if input[index] < 0 || input[index] > 255 do return -1
	}
	if output_capacity < length || (length != 0 && output == nil) do return -2
	for index := c.size_t(0); index < length; index += 1 { output[index] = u8(input[index]) }
	left := c.size_t(0)
	right := length
	for left < right {
		right -= 1
		if left >= right do break
		temporary := output[left]
		output[left] = output[right]
		output[right] = temporary
		left += 1
	}
	return i64(length)
}
