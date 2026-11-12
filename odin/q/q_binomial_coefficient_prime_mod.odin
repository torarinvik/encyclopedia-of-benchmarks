package q_binomial_coefficient_prime_mod

import "core:c"

MAX_T :: 16
MAX_N :: 16
MAX_MODULUS :: i64(31)
MAX_PARSEABLE_INPUT_LENGTH :: 36

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	for divisor := i64(2); divisor <= value / divisor; divisor += 1 {
		if value % divisor == 0 do return false
	}
	return true
}

modular_power :: proc(base_value: i64, exponent_value: int, modulus: i64) -> i64 {
	base, exponent := base_value, exponent_value
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % modulus
		base = base * base % modulus
		exponent = exponent >> 1
	}
	return result
}

@(export)
q_binomial_coefficient_prime_mod :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	count_value, modulus, q_value := input[0], input[1], input[2]
	if count_value < 1 || count_value > MAX_T || modulus < 2 || modulus > MAX_MODULUS ||
		!is_prime(modulus) || q_value < 0 || q_value >= modulus do return -1
	count := int(count_value)
	if length != c.size_t(3 + 2 * count) do return -1

	max_n := 0
	for query := 0; query < count; query += 1 {
		n_value, k_value := input[3 + 2 * query], input[4 + 2 * query]
		if n_value < 0 || n_value > MAX_N || k_value < 0 || k_value > MAX_N ||
			n_value >= modulus || k_value >= modulus do return -1
		if int(n_value) > max_n do max_n = int(n_value)
	}
	if output == nil || capacity < c.size_t(count) do return -2

	table := [17 * 17]i64{}
	table[0] = 1
	for n := 1; n <= max_n; n += 1 {
		table[n * 17] = 1
		for k := 1; k <= n; k += 1 {
			previous_same := i64(0)
			if k < n do previous_same = table[(n - 1) * 17 + k]
			weight := modular_power(q_value, n - k, modulus)
			table[n * 17 + k] =
				(previous_same + weight * table[(n - 1) * 17 + k - 1]) % modulus
		}
	}
	for query := 0; query < count; query += 1 {
		n, k := int(input[3 + 2 * query]), int(input[4 + 2 * query])
		value := i64(0)
		if k <= n do value = table[n * 17 + k]
		output[query] = u8(value)
	}
	return i64(count)
}
