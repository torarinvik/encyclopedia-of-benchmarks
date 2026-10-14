package hexadecimal_to_decimal

import "core:c"

// Convert most-significant-first hexadecimal digits to a signed 64-bit value.
@(export)
hexadecimal_to_decimal :: proc "c" (digits: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > 16 do return -1
	if length == 16 && digits[0] > 7 do return -1
	result: i64 = 0
	for index := c.size_t(0); index < length; index += 1 {
		digit := digits[index]
		if digit < 0 || digit > 15 do return -1
		result = result * 16 + digit
	}
	return result
}
