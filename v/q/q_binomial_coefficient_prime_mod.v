module q_binomial_coefficient_prime_mod

const max_t = 16
const max_n = 16
const max_modulus = i64(31)
const max_parseable_input_length = usize(36)

fn is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor += 1
	}
	return true
}

fn modular_power(base_value i64, exponent_value int, modulus i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

@[export: 'q_binomial_coefficient_prime_mod']
pub fn q_binomial_coefficient_prime_mod(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_parseable_input_length { return -1 }
		count_value, modulus, q_value := input[0], input[1], input[2]
		if count_value < 1 || count_value > max_t || modulus < 2 || modulus > max_modulus ||
			!is_prime(modulus) || q_value < 0 || q_value >= modulus { return -1 }
		count := int(count_value)
		if length != usize(3 + 2 * count) { return -1 }

		mut max_row := 0
		for query in 0 .. count {
			n_value, k_value := input[3 + 2 * query], input[4 + 2 * query]
			if n_value < 0 || n_value > max_n || k_value < 0 || k_value > max_n ||
				n_value >= modulus || k_value >= modulus { return -1 }
			if int(n_value) > max_row { max_row = int(n_value) }
		}
		if output == nil || capacity < usize(count) { return -2 }

		mut table := [17 * 17]i64{}
		table[0] = 1
		for n in 1 .. max_row + 1 {
			table[n * 17] = 1
			for k in 1 .. n + 1 {
				mut previous_same := i64(0)
				if k < n { previous_same = table[(n - 1) * 17 + k] }
				weight := modular_power(q_value, n - k, modulus)
				table[n * 17 + k] =
					(previous_same + weight * table[(n - 1) * 17 + k - 1]) % modulus
			}
		}
		for query in 0 .. count {
			n, k := int(input[3 + 2 * query]), int(input[4 + 2 * query])
			value := i64(0)
			if k <= n { value = table[n * 17 + k] }
			output[query] = u8(value)
		}
		return i64(count)
	}
}
