package pow_of_formal_power_series

import "core:c"

MODULUS :: i64(998244353)
MAX_EXPONENT :: i64(1_000_000_000_000_000_000)
MAX_N :: 32
MAX_INPUT :: 34
Polynomial :: [MAX_N]i64

multiply_truncated :: proc(left, right: Polynomial, n: int) -> Polynomial {
	product := Polynomial{}
	for i := 0; i < n; i += 1 {
		for j := 0; j < n - i; j += 1 {
			product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS
		}
	}
	return product
}

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
pow_of_formal_power_series :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_EXPONENT do return -1
	n := int(input[0])
	if int(length) != n + 2 do return -1
	for i := 0; i < n; i += 1 {
		if input[i + 2] < 0 || input[i + 2] >= MODULUS do return -1
	}
	bytes := 8 * n
	if output == nil || int(capacity) < bytes do return -2
	result := Polynomial{}
	base := Polynomial{}
	result[0] = 1
	for i := 0; i < n; i += 1 { base[i] = input[i + 2] }
	exponent := input[1]
	for exponent > 0 {
		if exponent & 1 != 0 { result = multiply_truncated(result, base, n) }
		exponent >>= 1
		if exponent > 0 { base = multiply_truncated(base, base, n) }
	}
	for i := 0; i < n; i += 1 { store_le(output, 8 * i, result[i]) }
	return i64(bytes)
}
