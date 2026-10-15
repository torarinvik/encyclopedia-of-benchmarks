package add_two_numbers

import "core:c"

MAX_DIGITS :: 1024

// Add reverse-order decimal digit lists with a carry propagated per node.
@(export)
add_two_numbers :: proc "contextless" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 2050 do return -1
	if input[0] < 0 || input[0] > MAX_DIGITS || input[1] < 0 || input[1] > MAX_DIGITS do return -1
	first_length := c.size_t(input[0])
	second_length := c.size_t(input[1])
	if length != first_length + second_length + 2 do return -1
	for index := c.size_t(0); index < first_length + second_length; index += 1 {
		if input[index + 2] < 0 || input[index + 2] > 9 do return -1
	}
	digit_count := max(first_length, second_length)
	digits: [MAX_DIGITS + 1]u8 = {}
	result_length := c.size_t(0)
	carry := i64(0)
	for index := c.size_t(0); index < digit_count || carry != 0; index += 1 {
		first := i64(0)
		second := i64(0)
		if index < first_length do first = input[index + 2]
		if index < second_length do second = input[index + 2 + first_length]
		sum := first + second + carry
		digits[result_length] = u8(sum % 10)
		result_length += 1
		carry = sum / 10
	}
	if output_capacity < result_length || (result_length != 0 && output == nil) do return -2
	for index := c.size_t(0); index < result_length; index += 1 { output[index] = digits[index] }
	return i64(result_length)
}
