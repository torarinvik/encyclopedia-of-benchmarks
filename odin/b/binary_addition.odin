package binary_addition

import "core:c"

MAX_OPERAND_BITS :: 2047

// Add two packed binary strings and return their ASCII representation.
@(export)
binary_addition :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 2 + 2 * MAX_OPERAND_BITS do return -1
	if values[0] < 0 || values[0] > MAX_OPERAND_BITS || values[1] < 0 || values[1] > MAX_OPERAND_BITS do return -1
	first_length := c.size_t(values[0])
	second_length := c.size_t(values[1])
	if length != first_length + second_length + 2 do return -1
	for index := c.size_t(0); index < first_length + second_length; index += 1 {
		if values[index + 2] < 0 || values[index + 2] > 1 do return -1
	}
	width := max(first_length, second_length)
	if width == 0 do return 0
	reversed: [MAX_OPERAND_BITS + 1]u8
	result_length := c.size_t(0)
	carry := i64(0)
	for offset := c.size_t(0); offset < width; offset += 1 {
		first := i64(0)
		second := i64(0)
		if offset < first_length do first = values[2 + first_length - 1 - offset]
		if offset < second_length do second = values[2 + first_length + second_length - 1 - offset]
		sum := first + second + carry
		reversed[result_length] = u8('0' + sum % 2)
		result_length += 1
		carry = sum / 2
	}
	if carry != 0 {
		reversed[result_length] = u8('1')
		result_length += 1
	}
	if output_capacity < result_length || output == nil do return -2
	for index := c.size_t(0); index < result_length; index += 1 {
		output[index] = reversed[result_length - 1 - index]
	}
	return i64(result_length)
}
