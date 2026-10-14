package octal_to_decimal

import "core:c"

// Convert most-significant-first octal digits to a signed 64-bit value.
@(export)
octal_to_decimal :: proc "c" (digits: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > 21 do return -1
	result: i64 = 0
	for index := c.size_t(0); index < length; index += 1 {
		digit := digits[index]
		if digit < 0 || digit > 7 do return -1
		result = result * 8 + digit
	}
	return result
}
