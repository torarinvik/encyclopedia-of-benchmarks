package gray_to_decimal

import "core:c"

@(export)
gray_to_decimal :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > 64 do return -1
	bit_length := values[0]
	if bit_length < 1 || bit_length > 63 || length != c.size_t(bit_length + 1) do return -1

	prefix := i64(0)
	binary := i64(0)
	for index := c.size_t(1); index < length; index += 1 {
		character := values[index]
		if character != 48 && character != 49 do return -1
		prefix ^= character - 48
		binary = binary * 2 + prefix
	}
	return binary
}
