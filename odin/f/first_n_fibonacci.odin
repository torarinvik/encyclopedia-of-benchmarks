package first_n_fibonacci

import "core:c"

MIN_COUNT :: i64(3)
MAX_COUNT :: i64(79)

decimal_length :: proc "contextless" (number_value: i64) -> c.size_t {
	remaining := number_value
	length := c.size_t(1)
	for remaining >= 10 { remaining /= 10; length += 1 }
	return length
}

required_length :: proc "contextless" (count: i64) -> c.size_t {
	bytes := c.size_t(0)
	previous, current := i64(0), i64(1)
	for index := i64(0); index < count; index += 1 {
		value: i64
		if index == 0 { value = 0 } else if index == 1 { value = 1 }
		else { value = previous + current; previous = current; current = value }
		bytes += decimal_length(value) + 1
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
first_n_fibonacci :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 1 do return -1
	count := values[0]
	if count < MIN_COUNT || count > MAX_COUNT do return -1
	required := required_length(count)
	if output == nil || output_capacity < required do return -2
	position := c.size_t(0)
	previous, current := i64(0), i64(1)
	for index := i64(0); index < count; index += 1 {
		value: i64
		if index == 0 { value = 0 } else if index == 1 { value = 1 }
		else { value = previous + current; previous = current; current = value }
		position = append_decimal(value, output, position)
		output[position] = 0
		position += 1
	}
	return i64(position)
}
