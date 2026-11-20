module binomial_coefficient_lucas

const max_p = i64(1009)
const table_len = 1009

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn pow_mod(base_value i64, exponent_value i64, modulus i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

@[export: 'binomial_coefficient_lucas']
pub fn binomial_coefficient_lucas(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		n, k, p := input[0], input[1], input[2]
		if n < 0 || k < 0 || k > n || p < 2 || p > max_p || !is_prime(p) { return -1 }

		p_index := int(p)
		mut factorial := [table_len]i64{}
		mut inverse_factorial := [table_len]i64{}
		factorial[0] = 1
		for i in 1 .. p_index {
			factorial[i] = factorial[i - 1] * i64(i) % p
		}
		inverse_factorial[p_index - 1] = pow_mod(factorial[p_index - 1], p - 2, p)
		mut i := p_index - 1
		for i > 0 {
			inverse_factorial[i - 1] = inverse_factorial[i] * i64(i) % p
			i--
		}

		mut remaining_n := n
		mut remaining_k := k
		mut result := i64(1)
		for remaining_n > 0 || remaining_k > 0 {
			n_digit := int(remaining_n % p)
			k_digit := int(remaining_k % p)
			if k_digit > n_digit { return 0 }
			result = result * factorial[n_digit] % p
			result = result * inverse_factorial[k_digit] % p
			result = result * inverse_factorial[n_digit - k_digit] % p
			remaining_n /= p
			remaining_k /= p
		}
		return result
	}
}
