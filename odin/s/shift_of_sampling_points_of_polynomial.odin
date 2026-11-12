package shift_of_sampling_points_of_polynomial

import "core:c"

MODULUS :: i64(998244353)
MAX_N :: 16
MAX_M :: 16
MAX_INPUT :: 20
Values :: [MAX_N]i64

mod_pow :: proc(base_value, exponent_value: i64) -> i64 {
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
shift_of_sampling_points_of_polynomial :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_M do return -1
	n := int(input[0])
	m := int(input[1])
	start := input[2]
	if int(length) != n + 3 || start < 0 || start >= MODULUS do return -1
	for i := 0; i < n; i += 1 {
		if input[i + 3] < 0 || input[i + 3] >= MODULUS do return -1
	}
	bytes := 8 * m
	if output == nil || int(capacity) < bytes do return -2
	differences := Values{}
	newton := Values{}
	factorial := Values{}
	inverse_factorial := Values{}
	for i := 0; i < n; i += 1 { differences[i] = input[i + 3] }
	factorial[0] = 1
	for k := 1; k < n; k += 1 { factorial[k] = factorial[k - 1] * i64(k) % MODULUS }
	inverse_factorial[n - 1] = mod_pow(factorial[n - 1], MODULUS - 2)
	for k := n - 1; k > 0; k -= 1 { inverse_factorial[k - 1] = inverse_factorial[k] * i64(k) % MODULUS }
	for k := 0; k < n; k += 1 {
		newton[k] = differences[0] * inverse_factorial[k] % MODULUS
		for i := 0; i + k + 1 < n; i += 1 {
			differences[i] = differences[i + 1] - differences[i]
			if differences[i] < 0 do differences[i] += MODULUS
		}
	}
	for offset := 0; offset < m; offset += 1 {
		x := start + i64(offset)
		if x >= MODULUS do x -= MODULUS
		basis := i64(1)
		value := i64(0)
		for k := 0; k < n; k += 1 {
			value = (value + newton[k] * basis) % MODULUS
			factor := x - i64(k)
			if factor < 0 do factor += MODULUS
			basis = basis * factor % MODULUS
		}
		store_le(output, 8 * offset, value)
	}
	return i64(bytes)
}
