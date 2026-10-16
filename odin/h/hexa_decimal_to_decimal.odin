package hexa_decimal_to_decimal

import "core:c"

MAX_INPUT_LENGTH :: 64
MAX_PARSEABLE_INPUT_LENGTH :: 65
INVALID_RESULT :: i64(-2_147_483_649)
UINT32_MODULUS :: u64(4_294_967_296)

@(export)
hexa_decimal_to_decimal :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_PARSEABLE_INPUT_LENGTH do return INVALID_RESULT
	if length == 0 do return 0
	if length > MAX_INPUT_LENGTH || input == nil do return INVALID_RESULT

	accumulator := u64(0)
	for index := 0; index < int(length); index += 1 {
		code := input[index]
		digit: i64
		if code >= 48 && code <= 57 do digit = code - 48
		else if code >= 65 && code <= 70 do digit = code - 55
		else if code >= 97 && code <= 102 do digit = code - 87
		else do return INVALID_RESULT
		accumulator = (accumulator * 16 + u64(digit)) % UINT32_MODULUS
	}
	if accumulator <= u64(2_147_483_647) do return i64(accumulator)
	return i64(accumulator) - 4_294_967_296
}
