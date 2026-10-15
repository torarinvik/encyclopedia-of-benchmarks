package harshad_numbers_in_base

import "core:c"

MAX_LIMIT :: i64(10000)

digit_sum :: proc "contextless" (number_value, base: i64) -> i64 {
	remaining := number_value
	sum: i64 = 0
	for remaining > 0 {
		sum += remaining % base
		remaining /= base
	}
	return sum
}

base_length :: proc "contextless" (number_value, base: i64) -> c.size_t {
	remaining := number_value
	length := c.size_t(0)
	for remaining > 0 {
		length += 1
		remaining /= base
	}
	return length
}

required_length :: proc "contextless" (limit, base: i64) -> c.size_t {
	length := c.size_t(0)
	for number := i64(1); number < limit; number += 1 {
		if number % digit_sum(number, base) != 0 do continue
		length += base_length(number, base) + 1
	}
	return length
}

digit_byte :: proc "contextless" (digit: i64) -> u8 {
	return u8(if digit < 10 then i64('0') + digit else i64('A') + digit - 10)
}

append_base :: proc "contextless" (number_value, base: i64, output: [^]u8,
	position_value: c.size_t) -> c.size_t {
	digits: [64]u8
	count := c.size_t(0)
	remaining := number_value
	for remaining > 0 {
		digits[count] = digit_byte(remaining % base)
		count += 1
		remaining /= base
	}
	position := position_value
	for count > 0 {
		count -= 1
		output[position] = digits[count]
		position += 1
	}
	return position
}

@(export)
harshad_numbers_in_base :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	limit, base := values[0], values[1]
	if limit > MAX_LIMIT || base < 2 || base > 36 do return -1
	required := required_length(limit, base)
	if output == nil || output_capacity < required do return -2
	position := c.size_t(0)
	for number := i64(1); number < limit; number += 1 {
		if number % digit_sum(number, base) != 0 do continue
		position = append_base(number, base, output, position)
		output[position] = 0
		position += 1
	}
	return i64(position)
}
