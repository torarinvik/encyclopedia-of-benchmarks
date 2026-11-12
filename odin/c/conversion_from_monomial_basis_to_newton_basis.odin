package conversion_from_monomial_basis_to_newton_basis

import "core:c"

MODULUS :: i64(998244353)
MAX_N :: 12
MAX_INPUT :: 25
Coefficients :: [MAX_N]i64

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
conversion_from_monomial_basis_to_newton_basis :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	if int(length) != 1 + 2 * n do return -1
	for i := 0; i < 2 * n; i += 1 {
		if input[i + 1] < 0 || input[i + 1] >= MODULUS do return -1
	}
	bytes := 8 * n
	if output == nil || int(capacity) < bytes do return -2
	residual := Coefficients{}
	answer := Coefficients{}
	for i := 0; i < n; i += 1 { residual[i] = input[i + 1] }

	active := n
	for i := 0; i < n; i += 1 {
		node := input[n + 1 + i]
		value: i64 = 0
		for degree := active; degree > 0; degree -= 1 {
			value = (value * node + residual[degree - 1]) % MODULUS
		}
		answer[i] = value
		if active == 1 { continue }
		quotient := Coefficients{}
		quotient[active - 2] = residual[active - 1]
		for degree := active - 2; degree > 0; degree -= 1 {
			quotient[degree - 1] = (residual[degree] + node * quotient[degree]) % MODULUS
		}
		for degree := 0; degree + 1 < active; degree += 1 { residual[degree] = quotient[degree] }
		active -= 1
	}
	for i := 0; i < n; i += 1 { store_le(output, 8 * i, answer[i]) }
	return i64(bytes)
}
