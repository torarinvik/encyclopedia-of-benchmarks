package cyclotomic_polynomial_coefficients

import "core:c"

MAX_N :: 32
MAX_INPUT_LENGTH :: 2

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := transmute(u64)value
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
cyclotomic_polynomial_coefficients :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length == 0 || length > MAX_INPUT_LENGTH do return -1
	n_value := input[0]
	if n_value < 1 || n_value > MAX_N || length != 1 do return -1
	n := int(n_value)

	polynomials: [MAX_N + 1][MAX_N + 1]i64
	degrees: [MAX_N + 1]int
	polynomials[1][0] = -1
	polynomials[1][1] = 1
	degrees[1] = 1
	for k := 2; k <= n; k += 1 {
		divisor: [MAX_N + 1]i64
		divisor[0] = 1
		divisor_degree := 0
		for d := 1; d < k; d += 1 {
			if k % d != 0 do continue
			product: [MAX_N + 1]i64
			for i := 0; i <= divisor_degree; i += 1 {
				for j := 0; j <= degrees[d]; j += 1 {
					product[i+j] += divisor[i] * polynomials[d][j]
				}
			}
			divisor_degree += degrees[d]
			for i := 0; i <= divisor_degree; i += 1 { divisor[i] = product[i] }
		}
		remainder: [MAX_N + 1]i64
		remainder[0] = -1
		remainder[k] = 1
		quotient_degree := k - divisor_degree
		degrees[k] = quotient_degree
		for q := quotient_degree; q >= 0; q -= 1 {
			leading := remainder[divisor_degree+q]
			polynomials[k][q] = leading
			for j := 0; j <= divisor_degree; j += 1 {
				remainder[q+j] -= leading * divisor[j]
			}
		}
	}

	coefficient_count := degrees[n] + 1
	required := c.size_t(8 * coefficient_count)
	if output == nil || capacity < required do return -2
	for index := 0; index < coefficient_count; index += 1 {
		store_i64_le(output, c.size_t(8*index), polynomials[n][index])
	}
	return i64(required)
}
