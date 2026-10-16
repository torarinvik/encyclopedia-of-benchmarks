package hexa_decimal_to_binary

import "core:c"

hex_digit :: proc(code: i64) -> i64 {
	if code >= 48 && code <= 57 do return code - 48
	if code >= 65 && code <= 70 do return code - 55
	if code >= 97 && code <= 102 do return code - 87
	return -1
}

@(export)
hexa_decimal_to_binary :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length == 0 || length > 65 do return -1
	first_digit := c.size_t(0)
	negative := false
	if input[0] == 45 { negative = true; first_digit = 1 }
	else if input[0] == 43 { first_digit = 1 }
	if first_digit == length do return -1
	limit: u64 = 2_147_483_647
	if negative do limit = 2_147_483_648
	value: u64 = 0
	for index := first_digit; index < length; index += 1 {
		digit := hex_digit(input[index])
		if digit < 0 || value > (limit - u64(digit)) / 16 do return -1
		value = value * 16 + u64(digit)
	}
	bits := u32(value)
	if negative && value != 0 do bits = u32(4_294_967_296 - value)
	width := 0
	for remaining := bits; remaining != 0; remaining >>= 1 { width += 1 }
	if negative && value != 0 do width = 32
	else if width < 8 do width = 8
	var buffer: [32]u8
	remaining := bits
	for position := width; position > 0; {
		position -= 1
		buffer[position] = u8('0' + remaining%2)
		remaining >>= 1
	}
	if c.size_t(width) > output_capacity || output == nil do return -2
	for index := 0; index < width; index += 1 do output[index] = buffer[index]
	return i64(width)
}
