package bernoulli_number

import "core:c"

MODULUS :: i64(998244353)
MAX_N :: 32

modular_power :: proc(base_value, exponent_value: i64) -> i64 {
	base, exponent := base_value, exponent_value
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % MODULUS
		base = base * base % MODULUS
		exponent = exponent >> 1
	}
	return result
}

@(export)
bernoulli_number :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	n64 := input[0]
	if n64 < 0 || n64 > i64(MAX_N) do return -1
	n := int(n64)
	output_bytes := 4 * (n + 1)
	if output == nil || capacity < c.size_t(output_bytes) do return -2

	inverse: [MAX_N + 2]i64
	bernoulli: [MAX_N + 1]i64
	inverse[1] = 1
	for i := 2; i <= n + 1; i += 1 {
		inverse[i] = modular_power(i64(i), MODULUS - 2)
	}

	bernoulli[0] = 1
	for m := 1; m <= n; m += 1 {
		choose, total: i64 = 1, 0
		for k := 0; k < m; k += 1 {
			total = (total + choose * bernoulli[k]) % MODULUS
			choose = choose * i64(m + 1 - k) % MODULUS * inverse[k + 1] % MODULUS
		}
		bernoulli[m] = ((MODULUS - total) % MODULUS) * inverse[m + 1] % MODULUS
	}

	for i := 0; i <= n; i += 1 {
		value := u32(bernoulli[i])
		output[4 * i] = u8(value)
		output[4 * i + 1] = u8(value >> 8)
		output[4 * i + 2] = u8(value >> 16)
		output[4 * i + 3] = u8(value >> 24)
	}
	return i64(output_bytes)
}
