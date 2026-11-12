module stirling_number_of_the_first_kind_small_p_large_n

const max_n = i64(1000000000000000000)
const max_t = 8
const max_k = 8
const width = 9

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn stirling_value(n i64, k int, modulus i64) i64 {
	quotient := n / modulus
	remainder := n % modulus
	if quotient > i64(k) { return 0 }
	target := k - int(quotient)
	mut coefficients := [9]i64{}
	coefficients[0] = 1
	mut residue := i64(0)
	for residue < remainder {
		mut degree := target
		for degree > 0 {
			coefficients[degree] = (coefficients[degree - 1] - residue * coefficients[degree]) % modulus
			if coefficients[degree] < 0 { coefficients[degree] += modulus }
			degree--
		}
		coefficients[0] = (-residue * coefficients[0]) % modulus
		if coefficients[0] < 0 { coefficients[0] += modulus }
		residue++
	}
	coefficient := coefficients[target]
	if quotient % 2 == 0 || coefficient == 0 { return coefficient }
	return modulus - coefficient
}

@[export: 'stirling_number_of_the_first_kind_small_p_large_n']
pub fn stirling_number_of_the_first_kind_small_p_large_n(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 18 { return -1 }
		count_value := input[0]
		modulus := input[1]
		if count_value < 1 || count_value > max_t { return -1 }
		if length != usize(2 + 2 * count_value) || modulus < 11 || modulus > 97 || !is_prime(modulus) { return -1 }

		mut result := i64(0)
		for case_index in 0 .. int(count_value) {
			n := input[2 + 2 * case_index]
			k_value := input[3 + 2 * case_index]
			if n < 0 || n > max_n || k_value < 0 || k_value > max_k || k_value > n { return -1 }
			value := stirling_value(n, int(k_value), modulus)
			next := i64(case_index + 1)
			result = (result + next * next * value) % modulus
		}
		return result
	}
}
