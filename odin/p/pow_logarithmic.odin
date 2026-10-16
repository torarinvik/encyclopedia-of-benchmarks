package pow_logarithmic
import "core:c"
INVALID_RESULT :: i64 = -9_223_372_036_854_775_808
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t = 3
pow_logarithmic_value :: proc(base: i64, exponent: int) -> i64 {
	if exponent == 0 do return 1
	half := pow_logarithmic_value(base, exponent / 2)
	square := half * half
	if exponent % 2 == 0 do return square
	return square * base
}
@(export)
pow_logarithmic :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return INVALID_RESULT
	if length != 2 do return INVALID_RESULT
	base, exponent := input[0], input[1]
	if base < -10 || base > 10 || exponent < 0 || exponent > 15 do return INVALID_RESULT
	return pow_logarithmic_value(base, int(exponent))
}
