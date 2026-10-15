package binary_to_excess3

import "core:c"

const MAX_TEXT_LENGTH :: 128
const MAX_MAGNITUDE :: i64(4_611_686_018_427_387_904)

is_ascii_space :: proc(value: i64) -> bool {
	return value == 32 || (value >= 9 && value <= 13)
}

is_binary_digit :: proc(value: i64) -> bool {
	return value == i64('0') || value == i64('1')
}

@(export)
binary_to_excess3 :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length == 0 || length > MAX_TEXT_LENGTH do return -1
	start := c.size_t(0)
	end := length
	for start < end && is_ascii_space(values[start]) { start += 1 }
	for end > start && is_ascii_space(values[end - 1]) { end -= 1 }
	if start == end do return -1

	negative := false
	if values[start] == i64('+') || values[start] == i64('-') {
		negative = values[start] == i64('-')
		start += 1
		if start == end do return -1
	}
	prefixed := end - start >= 2 && values[start] == i64('0') &&
		(values[start + 1] == i64('b') || values[start + 1] == i64('B'))
	if prefixed do start += 2
	if start == end do return -1

	digit_start := start
	allow_prefix_underscore := prefixed
	have_digit := false
	last_was_digit := false
	magnitude: i64 = 0
	for index := start; index < end; index += 1 {
		value := values[index]
		if is_binary_digit(value) {
			digit := value - i64('0')
			if magnitude > (MAX_MAGNITUDE - digit) / 2 do return -1
			magnitude = magnitude * 2 + digit
			have_digit = true
			last_was_digit = true
			allow_prefix_underscore = false
		} else if value == i64('_') {
			if last_was_digit && index + 1 < end && is_binary_digit(values[index + 1]) {
				last_was_digit = false
			} else if allow_prefix_underscore && !have_digit && index == digit_start &&
				index + 1 < end && is_binary_digit(values[index + 1]) {
				allow_prefix_underscore = false
			} else {
				return -1
			}
		} else {
			return -1
		}
	}
	if !have_digit || !last_was_digit do return -1

	result := magnitude
	if negative do result = -result
	result += 3
	result_is_negative := result < 0
	remaining := result
	if result_is_negative do remaining = -result
	var reversed: [64]u8
	digit_count := c.size_t(0)
	for {
		reversed[digit_count] = u8('0') + u8(remaining % 2)
		digit_count += 1
		remaining /= 2
		if remaining == 0 do break
	}

	sign_length := c.size_t(0)
	if result_is_negative do sign_length = 1
	output_length := sign_length + digit_count
	if output_length < 4 do output_length = 4
	if output == nil || output_capacity < output_length do return -2
	position := c.size_t(0)
	if result_is_negative {
		output[position] = u8('-')
		position += 1
	}
	digit_width := output_length - sign_length
	for pad := digit_count; pad < digit_width; pad += 1 { output[position] = u8('0'); position += 1 }
	for digit_count > 0 {
		digit_count -= 1
		output[position] = reversed[digit_count]
		position += 1
	}
	return i64(output_length)
}
