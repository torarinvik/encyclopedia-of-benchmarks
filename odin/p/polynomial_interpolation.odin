package polynomial_interpolation

import "core:c"

MODULUS :: i64(998244353)
MAX_N :: 12
MAX_INPUT :: 25
Coefficients :: [MAX_N]i64
Basis :: [MAX_N + 1]i64

normalize :: proc(value: i64) -> i64 {
	value %= MODULUS
	if value < 0 do value += MODULUS
	return value
}

power_mod :: proc(base_value, exponent_value: i64) -> i64 {
	base := base_value
	exponent := exponent_value
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % MODULUS
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
polynomial_interpolation :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	if int(length) != 1 + 2 * n do return -1
	for i := 0; i < n; i += 1 {
		xi := input[1 + i]
		yi := input[1 + n + i]
		if xi < 0 || xi >= MODULUS || yi < 0 || yi >= MODULUS do return -1
		for j := 0; j < i; j += 1 { if xi == input[1 + j] do return -1 }
	}
	bytes := 8 * n
	if output == nil || int(capacity) < bytes do return -2
	coefficients := Coefficients{}
	for i := 0; i < n; i += 1 {
		basis := Basis{}
		basis[0] = 1
		degree := 0
		denominator := i64(1)
		for j := 0; j < n; j += 1 {
			if j == i do continue
			xj := input[1 + j]
			denominator = denominator * (input[1 + i] - xj) % MODULUS
			expanded := Basis{}
			for k := 0; k <= degree; k += 1 {
				expanded[k] = normalize(expanded[k] - basis[k] * xj)
				expanded[k + 1] = normalize(expanded[k + 1] + basis[k])
			}
			for k := 0; k <= degree + 1; k += 1 { basis[k] = expanded[k] }
			degree += 1
		}
		scale := input[1 + n + i] * power_mod(normalize(denominator), MODULUS - 2) % MODULUS
		for k := 0; k < n; k += 1 {
			coefficients[k] = (coefficients[k] + scale * basis[k]) % MODULUS
		}
	}
	for i := 0; i < n; i += 1 { store_le(output, 8 * i, coefficients[i]) }
	return i64(bytes)
}
