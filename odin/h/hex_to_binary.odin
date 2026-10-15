package hex_to_binary

import "core:c"

hex_value :: proc(value: i64) -> int {
	if value >= 48 && value <= 57 do return int(value - 48)
	if value >= 65 && value <= 70 do return int(value - 65 + 10)
	if value >= 97 && value <= 102 do return int(value - 97 + 10)
	return -1
}

@(export)
hex_to_binary :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if length > 256 || (length != 0 && values == nil) do return -1
	for index := 0; index < int(length); index += 1 {
		if hex_value(values[index]) < 0 do return -1
	}

	required := int(length) * 4
	if output == nil || capacity < c.size_t(required) do return -2
	for index := 0; index < int(length); index += 1 {
		digit := hex_value(values[index])
		for bit := 0; bit < 4; bit += 1 {
			if ((digit >> (3 - bit)) & 1) != 0 {
				output[index * 4 + bit] = '1'
			} else {
				output[index * 4 + bit] = '0'
			}
		}
	}
	return i64(required)
}
