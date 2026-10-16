package parse_integer

import "core:c"

INVALID_RESULT :: i64 = -9_223_372_036_854_775_808
UINT32_MODULUS :: i64 = 4_294_967_296

@(export)
parse_integer :: proc "c" (bytes: [^]i64, length: c.size_t) -> i64 {
	if bytes == nil || length == 0 || length > 64 do return INVALID_RESULT
	for index := 0; index < int(length); index += 1 {
		if bytes[index] < 0 || bytes[index] > 127 do return INVALID_RESULT
	}
	negative := bytes[0] == 45
	index := 0
	if bytes[0] == 45 || bytes[0] == 43 do index = 1
	number := i64(0)
	for index < int(length) {
		byte := bytes[index]
		if byte < 48 || byte > 57 do return INVALID_RESULT
		number = (number * 10 + byte - 48) % UINT32_MODULUS
		index += 1
	}
	if negative && number != 0 do number = UINT32_MODULUS - number
	if number >= 2_147_483_648 do return number - UINT32_MODULUS
	return number
}
