package string_fibonacci

import "core:c"

MAX_N :: 256
DECIMAL_CAPACITY :: 80

add_decimal :: proc(left, right: [^]u8, left_length, right_length: int,
                    result: [^]u8) -> int {
	var reversed: [DECIMAL_CAPACITY]u8
	length := 0
	left_remaining := left_length
	right_remaining := right_length
	carry := 0
	for left_remaining > 0 || right_remaining > 0 || carry != 0 {
		left_digit := 0
		right_digit := 0
		if left_remaining > 0 {
			left_remaining -= 1
			left_digit = int(left[left_remaining] - 48)
		}
		if right_remaining > 0 {
			right_remaining -= 1
			right_digit = int(right[right_remaining] - 48)
		}
		sum := left_digit + right_digit + carry
		reversed[length] = u8(48 + sum%10)
		length += 1
		carry = sum / 10
	}
	for i := 0; i < length; i += 1 {
		result[i] = reversed[length-1-i]
	}
	result[length] = 0
	return length
}

@(export, link_name="string_fibonacci")
string_fibonacci :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	n := input[0]
	if n < 0 || n > MAX_N do return -1

	var fib_minus_one: [DECIMAL_CAPACITY]u8
	var fib_minus_two: [DECIMAL_CAPACITY]u8
	fib_minus_one[0] = 49
	fib_minus_two[0] = 48
	minus_one_length := 1
	minus_two_length := 1
	for step := 0; step < int(n); step += 1 {
		var sum: [DECIMAL_CAPACITY]u8
		sum_length := add_decimal(&fib_minus_one[0], &fib_minus_two[0],
			minus_one_length, minus_two_length, &sum[0])
		for i := 0; i < minus_one_length; i += 1 {
			fib_minus_two[i] = fib_minus_one[i]
		}
		minus_two_length = minus_one_length
		for i := 0; i < sum_length; i += 1 {
			fib_minus_one[i] = sum[i]
		}
		fib_minus_one[sum_length] = 0
		minus_one_length = sum_length
	}

	if output == nil || capacity < c.size_t(minus_two_length) do return -2
	for i := 0; i < minus_two_length; i += 1 {
		output[i] = fib_minus_two[i]
	}
	return i64(minus_two_length)
}
