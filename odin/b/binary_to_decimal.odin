package binary_to_decimal

import "core:c"

// Convert most-significant-first binary digits to a signed 64-bit decimal value.
@(export)
binary_to_decimal :: proc "c" (bits: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > 63 do return -1
	value := u64(0)
	for index := c.size_t(0); index < length; index += 1 {
		if bits[index] != 0 && bits[index] != 1 do return -1
		value = value * 2 + u64(bits[index])
	}
	return i64(value)
}
