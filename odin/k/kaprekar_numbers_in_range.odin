package kaprekar_numbers_in_range

import "core:c"

MAX_END :: i64(100000)

is_kaprekar :: proc "contextless" (number: i64) -> bool {
	if number == 0 || number == 1 do return true
	square := number * number
	split := i64(1)
	for remaining := number; remaining > 0; remaining /= 10 { split *= 10 }
	right := square % split
	return right != 0 && square / split + right == number
}

decimal_length :: proc "contextless" (number_value: i64) -> c.size_t {
	remaining := number_value
	length := c.size_t(1)
	for remaining >= 10 { remaining /= 10; length += 1 }
	return length
}

required_length :: proc "contextless" (start, ending: i64) -> c.size_t {
	bytes := c.size_t(0)
	for number := start; number <= ending; number += 1 {
		if is_kaprekar(number) do bytes += decimal_length(number) + 1
	}
	return bytes
}

append_decimal :: proc "contextless" (number_value: i64, output: [^]u8,
	position_value: c.size_t) -> c.size_t {
	digits: [20]u8
	count := c.size_t(0)
	remaining := number_value
	for remaining > 0 {
		digits[count] = u8(i64('0') + remaining % 10)
		count += 1
		remaining /= 10
	}
	if count == 0 { digits[0] = u8(i64('0')); count = 1 }
	position := position_value
	for count > 0 { count -= 1; output[position] = digits[count]; position += 1 }
	return position
}

@(export)
kaprekar_numbers_in_range :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	start, ending := values[0], values[1]
	if start < 0 || start > ending || ending > MAX_END do return -1
	required := required_length(start, ending)
	if output == nil || output_capacity < required do return -2
	position := c.size_t(0)
	for number := start; number <= ending; number += 1 {
		if !is_kaprekar(number) do continue
		position = append_decimal(number, output, position)
		output[position] = 0
		position += 1
	}
	return i64(position)
}
