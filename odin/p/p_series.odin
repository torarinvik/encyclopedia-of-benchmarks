package p_series

import "core:c"

decimal_width :: proc(value_input: i64) -> int {
	value := value_input
	width := 1
	for value >= 10 {
		value /= 10
		width += 1
	}
	return width
}

append_decimal :: proc(output: [^]u8, position_input: int, value_input: i64) -> int {
	value := value_input
	digits: [20]u8
	count := 0
	for {
		digits[count] = u8(value % 10)
		count += 1
		value /= 10
		if value == 0 do break
	}
	position := position_input
	for count > 0 {
		count -= 1
		output[position] = u8('0') + digits[count]
		position += 1
	}
	return position
}

@(export)
p_series :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	nth_term, power := values[0], values[1]
	if nth_term < -256 || nth_term > 256 || power < 0 || power > 7 do return -1
	if nth_term <= 0 do return 0
	needed := 2
	for term := i64(2); term <= nth_term; term += 1 {
		denominator := i64(1)
		for exponent := i64(0); exponent < power; exponent += 1 { denominator *= term }
		needed += 5 + decimal_width(denominator)
	}
	if output == nil || output_capacity < c.size_t(needed) do return -2
	position := 0
	output[position] = u8('1'); position += 1
	output[position] = u8('\n'); position += 1
	for term := i64(2); term <= nth_term; term += 1 {
		denominator := i64(1)
		for exponent := i64(0); exponent < power; exponent += 1 { denominator *= term }
		output[position] = u8('1'); position += 1
		output[position] = u8(' '); position += 1
		output[position] = u8('/'); position += 1
		output[position] = u8(' '); position += 1
		position = append_decimal(output, position, denominator)
		output[position] = u8('\n'); position += 1
	}
	return i64(position)
}
