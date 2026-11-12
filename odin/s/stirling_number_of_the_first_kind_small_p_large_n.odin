package stirling_number_of_the_first_kind_small_p_large_n

import "core:c"

MAX_N :: i64(1000000000000000000)
MAX_T :: 8
MAX_K :: 8
WIDTH :: 9

is_prime :: proc(value: i64) -> bool {
	if value < 2 do return false
	divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 do return false
		divisor += 1
	}
	return true
}

stirling_value :: proc(n: i64, k: int, modulus: i64) -> i64 {
	quotient := n / modulus
	remainder := n % modulus
	if quotient > i64(k) do return 0
	target := k - int(quotient)
	coefficients := [9]i64{}
	coefficients[0] = 1
	for residue := i64(0); residue < remainder; residue += 1 {
		for degree := target; degree > 0; degree -= 1 {
			coefficients[degree] = (coefficients[degree - 1] - residue * coefficients[degree]) % modulus
			if coefficients[degree] < 0 do coefficients[degree] += modulus
		}
		coefficients[0] = (-residue * coefficients[0]) % modulus
		if coefficients[0] < 0 do coefficients[0] += modulus
	}
	coefficient := coefficients[target]
	if quotient % 2 == 0 || coefficient == 0 do return coefficient
	return modulus - coefficient
}

@(export)
stirling_number_of_the_first_kind_small_p_large_n :: proc "c" (input: [^]i64,
	length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 18 do return -1
	count_value := input[0]
	modulus := input[1]
	if count_value < 1 || count_value > MAX_T do return -1
	if length != c.size_t(2 + 2 * count_value) do return -1
	if modulus < 11 || modulus > 97 || !is_prime(modulus) do return -1

	result := i64(0)
	for case_index := 0; case_index < int(count_value); case_index += 1 {
		n := input[2 + 2 * case_index]
		k_value := input[3 + 2 * case_index]
		if n < 0 || n > MAX_N || k_value < 0 || k_value > MAX_K || k_value > n do return -1
		value := stirling_value(n, int(k_value), modulus)
		next := i64(case_index + 1)
		result = (result + next * next * value) % modulus
	}
	return result
}
