package hex_to_oct

const INVALID_RESULT: i64 = -2_147_483_649
const I32_MODULUS: u64 = 4_294_967_296

hex_digit :: proc(code: i64) -> i64 {
	if code >= 48 && code <= 57 do return code - 48
	if code >= 65 && code <= 70 do return code - 55
	if code >= 97 && code <= 102 do return code - 87
	return -1
}

signed_i32 :: proc(bits: u64) -> i64 {
	if bits <= 2_147_483_647 do return i64(bits)
	return i64(bits) - i64(I32_MODULUS)
}

@(export)
hex_to_oct :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > 8 || (length != 0 && input == nil) do return INVALID_RESULT
	decimal_bits: u64 = 0
	for index := c.size_t(0); index < length; index += 1 {
		digit := hex_digit(input[index])
		if digit < 0 do return INVALID_RESULT
		decimal_bits = (decimal_bits * 16 + u64(digit)) % I32_MODULUS
	}
	decimal := signed_i32(decimal_bits)
	if decimal <= 0 do return 0

	octal_bits: u64 = 0
	place_value: u64 = 1
	for decimal > 0 {
		octal_bits = (octal_bits + u64(decimal % 8)*place_value) % I32_MODULUS
		decimal /= 8
		place_value = (place_value * 10) % I32_MODULUS
	}
	return signed_i32(octal_bits)
}
