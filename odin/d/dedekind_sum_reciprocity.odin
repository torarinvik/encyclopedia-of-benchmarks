package dedekind_sum_reciprocity

import "core:c"

MAX_MODULUS :: i64(100_000)
RESULT_OFFSET :: i64(29_999_700_001)

gcd :: proc(left_value, right_value: i64) -> i64 {
	left := left_value
	right := right_value
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

scaled_sum :: proc(numerator, modulus: i64) -> i64 {
	if modulus == 1 do return 0
	tail := scaled_sum(modulus % numerator, numerator)
	top := numerator*numerator + modulus*modulus + 1 - 3*numerator*modulus - modulus*tail
	return top/numerator
}

@(export)
dedekind_sum_reciprocity :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	numerator := input[0]
	modulus := input[1]
	if modulus < 1 || modulus > MAX_MODULUS || numerator < 0 || numerator >= modulus do return -1
	if gcd(numerator, modulus) != 1 do return -1
	return RESULT_OFFSET + scaled_sum(numerator, modulus)
}
