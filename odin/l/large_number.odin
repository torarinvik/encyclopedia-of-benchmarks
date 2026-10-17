package large_number

import "core:c"

MAX_PARSEABLE_INPUT_LENGTH :: 131
MAX_DIGITS :: 64

@(export)
large_number_add :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	left_length_value := input[0]
	right_length_value := input[1]
	if left_length_value < 1 || left_length_value > MAX_DIGITS ||
		right_length_value < 1 || right_length_value > MAX_DIGITS do return -1
	left_length := int(left_length_value)
	right_length := int(right_length_value)
	if int(input_length) != 2+left_length+right_length do return -1

	left, right: [MAX_DIGITS]u8
	for i := 0; i < left_length; i += 1 {
		digit := input[2+i]
		if digit < 48 || digit > 57 || (i == 0 && left_length > 1 && digit == 48) do return -1
		left[left_length-i-1] = u8(digit-48)
	}
	for i := 0; i < right_length; i += 1 {
		digit := input[2+left_length+i]
		if digit < 48 || digit > 57 || (i == 0 && right_length > 1 && digit == 48) do return -1
		right[right_length-i-1] = u8(digit-48)
	}

	sum: [MAX_DIGITS+1]u8
	sum_length := 0
	carry := u8(0)
	longer := max(left_length, right_length)
	for sum_length < longer || carry != 0 {
		total := carry
		if sum_length < right_length do total += right[sum_length]
		if sum_length < left_length do total += left[sum_length]
		sum[sum_length] = total % 10
		carry = total / 10
		sum_length += 1
	}
	staged: [MAX_DIGITS+1]u8
	for i := 0; i < sum_length; i += 1 { staged[i] = u8('0') + sum[sum_length-i-1] }
	if output == nil || output_capacity < c.size_t(sum_length) do return -2
	for i := 0; i < sum_length; i += 1 { output[i] = staged[i] }
	return i64(sum_length)
}
