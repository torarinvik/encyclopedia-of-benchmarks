package power_for_huge_numbers

import "core:c"

MAX_OUTPUT_BYTES :: 513

@(export)
power_for_huge_numbers :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	base, exponent := input[0], input[1]
	if base < 1 || base > 10000 || exponent < 0 || exponent > 128 do return -1

	digits: [MAX_OUTPUT_BYTES]u8
	digits[0] = 1
	digit_count := c.size_t(1)
	for power := i64(0); power < exponent; power += 1 {
		carry := i64(0)
		for i := c.size_t(0); i < digit_count; i += 1 {
			product := i64(digits[i]) * base + carry
			digits[i] = u8(product % 10)
			carry = product / 10
		}
		for carry != 0 {
			if digit_count == MAX_OUTPUT_BYTES do return -1
			digits[digit_count] = u8(carry % 10)
			digit_count += 1
			carry /= 10
		}
	}
	if output == nil || capacity < digit_count do return -2
	for i := c.size_t(0); i < digit_count; i += 1 {
		output[i] = u8(i64('0') + i64(digits[digit_count - 1 - i]))
	}
	return i64(digit_count)
}
