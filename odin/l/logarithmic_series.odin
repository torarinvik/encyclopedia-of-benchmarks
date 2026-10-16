package logarithmic_series

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

has_negative_sign :: proc(delta, term: i64) -> bool {
	return (delta < 0 && term % 2 == 1) || (delta >= 0 && term % 2 == 0)
}

@(export)
logarithmic_series :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	x_value, n_terms := values[0], values[1]
	if x_value < -10 || x_value > 10 || n_terms < -64 || n_terms > 256 do return -1
	if n_terms <= 0 do return 0
	delta := x_value - 1
	base := i64(0)
	if delta < 0 { base = -delta } else { base = delta }
	needed := 0
	for term := i64(1); term <= n_terms; term += 1 {
		prefix := 1
		if has_negative_sign(delta, term) { prefix = 2 }
		needed += prefix + decimal_width(base) + 2 * decimal_width(term) + 4
	}
	if output == nil || output_capacity < c.size_t(needed) do return -2
	position := 0
	for term := i64(1); term <= n_terms; term += 1 {
		if has_negative_sign(delta, term) { output[position] = u8('-'); position += 1 }
		output[position] = u8('('); position += 1
		position = append_decimal(output, position, base)
		output[position] = u8('^'); position += 1
		position = append_decimal(output, position, term)
		output[position] = u8(')'); position += 1
		output[position] = u8('/'); position += 1
		position = append_decimal(output, position, term)
		output[position] = u8('\n'); position += 1
	}
	return i64(position)
}
