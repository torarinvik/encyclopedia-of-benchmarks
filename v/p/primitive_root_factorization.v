module primitive_root_factorization

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor * divisor <= value {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn power_mod(base_input i64, exponent_input i64, modulus i64) i64 {
	mut base := base_input
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

@[export: 'primitive_root_factorization']
pub fn primitive_root_factorization(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		prime := input[0]
		if prime < 2 || prime > 4093 || !is_prime(prime) { return -1 }
		if prime == 2 { return 1 }

		mut factors := [16]i64{}
		mut factor_count := 0
		mut remaining := prime - 1
		mut divisor := i64(2)
		for divisor * divisor <= remaining {
			if remaining % divisor == 0 {
				factors[factor_count] = divisor
				factor_count++
				for remaining % divisor == 0 { remaining /= divisor }
			}
			divisor++
		}
		if remaining > 1 {
			factors[factor_count] = remaining
			factor_count++
		}

		mut candidate := i64(2)
		for candidate < prime {
			mut valid := true
			for index in 0 .. factor_count {
				if power_mod(candidate, (prime - 1) / factors[index], prime) == 1 {
					valid = false
					break
				}
			}
			if valid { return candidate }
			candidate++
		}
		return -1
	}
}
