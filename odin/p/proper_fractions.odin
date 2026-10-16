package proper_fractions

import "core:c"

gcd :: proc(left_input, right_input: i64) -> i64 {
	left, right := left_input, right_input
	for right != 0 {
		remainder := left % right
		left, right = right, remainder
	}
	return left
}

decimal_width :: proc(value_input: i64) -> int {
	value := value_input
	width := 1
	for value >= 10 { value /= 10; width += 1 }
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
proper_fractions :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 1 do return -1
	denominator := values[0]
	if denominator < 0 || denominator > 256 do return -1
	if denominator <= 1 do return 0
	needed := 0
	for numerator := i64(1); numerator < denominator; numerator += 1 {
		if gcd(numerator, denominator) == 1 do needed += decimal_width(numerator) + decimal_width(denominator) + 2
	}
	if output == nil || output_capacity < c.size_t(needed) do return -2
	position := 0
	for numerator := i64(1); numerator < denominator; numerator += 1 {
		if gcd(numerator, denominator) != 1 do continue
		position = append_decimal(output, position, numerator)
		output[position] = u8('/'); position += 1
		position = append_decimal(output, position, denominator)
		output[position] = u8('\n'); position += 1
	}
	return i64(position)
}
