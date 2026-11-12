package balanced_ternary_conversion

import "core:c"

MAX_OUTPUT_BYTES :: 41

@(export)
balanced_ternary_conversion :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	var reversed: [MAX_OUTPUT_BYTES]u8
	digit_count := 0
	value := input[0]
	if value == 0 {
		reversed[digit_count] = u8('0')
		digit_count += 1
	}
	for value != 0 {
		quotient := value / 3
		remainder := value % 3
		digit: u8
		if remainder == 2 {
			digit = u8('Z')
			quotient += 1
		} else if remainder == -2 {
			digit = u8('1')
			quotient -= 1
		} else if remainder == -1 {
			digit = u8('Z')
		} else if remainder == 0 {
			digit = u8('0')
		} else {
			digit = u8('1')
		}
		reversed[digit_count] = digit
		digit_count += 1
		value = quotient
	}
	if output == nil || capacity < c.size_t(digit_count) do return -2
	for index := 0; index < digit_count; index += 1 {
		output[index] = reversed[digit_count - index - 1]
	}
	return i64(digit_count)
}
