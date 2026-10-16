package modpow
import "core:c"
INVALID_RESULT :: i64 = -9_223_372_036_854_775_808
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t = 4
MAX_COMPONENT :: i64 = 89_000_000
MAX_EXPONENT :: i64 = 64
@(export)
modpow :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH do return INVALID_RESULT
	if length != 3 do return INVALID_RESULT
	base, exponent, modulus := input[0], input[1], input[2]
	if base < 0 || base > MAX_COMPONENT || exponent < 0 || exponent > MAX_EXPONENT do return INVALID_RESULT
	if modulus < 1 || modulus > MAX_COMPONENT do return INVALID_RESULT
	if exponent == 0 {
		if base == 0 do return INVALID_RESULT
		return 1 % modulus
	}
	if base == 0 do return 0
	result := i64(1) % modulus
	for exponent > 0 {
		if exponent % 2 == 1 {
			result = (result * base) % modulus
			exponent -= 1
		} else {
			base = (base * base) % modulus
			exponent /= 2
		}
	}
	return result
}
