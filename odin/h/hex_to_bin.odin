package hex_to_bin

import "core:c"

INVALID_RESULT :: i64(-9223372036854775807 - 1)

hex_digit :: proc(byte: i64) -> i64 {
	if byte >= 48 && byte <= 57 do return byte - 48
	if byte >= 65 && byte <= 70 do return byte - 65 + 10
	if byte >= 97 && byte <= 102 do return byte - 97 + 10
	return -1
}

@(export)
hex_to_bin :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 5 do return INVALID_RESULT
	start := 0
	sign := i64(1)
	if input[0] == 45 {
		sign = -1
		start = 1
	}
	if length - c.size_t(start) < 1 || length - c.size_t(start) > 4 do return INVALID_RESULT

	value := i64(0)
	for index := start; index < int(length); index += 1 {
		digit := hex_digit(input[index])
		if digit < 0 do return INVALID_RESULT
		value = value * 16 + digit
	}
	if value == 0 do return INVALID_RESULT

	decimal_binary_digits, place := i64(0), i64(1)
	for value > 0 {
		decimal_binary_digits += (value % 2) * place
		value /= 2
		if value > 0 do place *= 10
	}
	return sign * decimal_binary_digits
}
