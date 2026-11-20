package primitive_root_factorization

import "core:c"

is_prime :: proc "contextless" (value: i64) -> bool {
	if value < 2 do return false
	for divisor := i64(2); divisor * divisor <= value; divisor += 1 {
		if value % divisor == 0 do return false
	}
	return true
}

power_mod :: proc "contextless" (base_input, exponent_input, modulus: i64) -> i64 {
	base := base_input
	exponent := exponent_input
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % modulus
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

@(export)
primitive_root_factorization :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	prime := input[0]
	if prime < 2 || prime > 4093 || !is_prime(prime) do return -1
	if prime == 2 do return 1

	factors: [16]i64
	factor_count := 0
	remaining := prime - 1
	for divisor := i64(2); divisor * divisor <= remaining; divisor += 1 {
		if remaining % divisor == 0 {
			factors[factor_count] = divisor
			factor_count += 1
			for remaining % divisor == 0 { remaining /= divisor }
		}
	}
	if remaining > 1 {
		factors[factor_count] = remaining
		factor_count += 1
	}

	for candidate := i64(2); candidate < prime; candidate += 1 {
		valid := true
		for index := 0; index < factor_count; index += 1 {
			if power_mod(candidate, (prime - 1) / factors[index], prime) == 1 {
				valid = false
				break
			}
		}
		if valid do return candidate
	}
	return -1
}
