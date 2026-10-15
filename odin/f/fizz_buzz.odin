package fizz_buzz

import "core:c"

token_length :: proc "contextless" (value: i64) -> c.size_t {
	if value % 15 == 0 do return 8
	if value % 3 == 0 || value % 5 == 0 do return 4
	if value >= 100 do return 3
	if value >= 10 do return 2
	return 1
}

append_number :: proc "contextless" (value_value: i64, output: [^]u8, position_value: c.size_t) -> c.size_t {
	value := value_value
	position := position_value
	if value >= 100 {
		output[position] = u8(48 + value / 100)
		position += 1
		value %= 100
		output[position] = u8(48 + value / 10)
		position += 1
		output[position] = u8(48 + value % 10)
		position += 1
	} else if value >= 10 {
		output[position] = u8(48 + value / 10)
		position += 1
		output[position] = u8(48 + value % 10)
		position += 1
	} else {
		output[position] = u8(48 + value)
		position += 1
	}
	return position
}

@(export)
fizz_buzz :: proc "c" (value: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if value < 1 || value > 512 do return -1
	width := c.size_t(0)
	for current := i64(1); current <= value; current += 1 { width += token_length(current) + 1 }
	if output == nil || output_capacity < width do return -2
	position := c.size_t(0)
	for current := i64(1); current <= value; current += 1 {
		if current % 15 == 0 {
			for byte in [8]u8{'F', 'i', 'z', 'z', 'B', 'u', 'z', 'z'} { output[position] = byte; position += 1 }
		} else if current % 3 == 0 {
			for byte in [4]u8{'F', 'i', 'z', 'z'} { output[position] = byte; position += 1 }
		} else if current % 5 == 0 {
			for byte in [4]u8{'B', 'u', 'z', 'z'} { output[position] = byte; position += 1 }
		} else {
			position = append_number(current, output, position)
		}
		output[position] = u8(' ')
		position += 1
	}
	return i64(position)
}
