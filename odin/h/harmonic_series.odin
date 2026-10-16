package harmonic_series

import "core:c"

append_decimal :: proc(output: [^]u8, position_input: int, value_input: int) -> int {
	value := value_input
	digits: [4]u8
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
harmonic_series :: proc "c" (n: i64, output: [^]u8, capacity: c.size_t) -> i64 {
	if n < -512 || n > 512 do return -1
	if n <= 0 do return 0
	needed := 2
	for term := 2; term <= int(n); term += 1 {
		value := term
		digits := 0
		for {
			digits += 1
			value /= 10
			if value == 0 do break
		}
		needed += digits + 3
	}
	if output == nil || capacity < c.size_t(needed) do return -2
	position := 0
	output[position] = u8('1'); position += 1
	output[position] = u8('\n'); position += 1
	for term := 2; term <= int(n); term += 1 {
		output[position] = u8('1'); position += 1
		output[position] = u8('/'); position += 1
		position = append_decimal(output, position, term)
		output[position] = u8('\n'); position += 1
	}
	return i64(position)
}
