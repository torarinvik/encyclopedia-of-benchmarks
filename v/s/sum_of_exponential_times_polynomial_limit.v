module sum_of_exponential_times_polynomial_limit

const modulus = i64(998244353)
const max_degree = 256

fn seppl_mod_pow(base_input i64, exponent_input i64) i64 {
	mut base := base_input
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) == 1 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

fn seppl_evaluate(r i64, degree_value i64) i64 {
	if r < 0 || r >= modulus || r == 1 || degree_value < 0 || degree_value > max_degree { return -1 }
	degree := int(degree_value)
	denominator := (1 - r + modulus) % modulus
	inverse := seppl_mod_pow(denominator, modulus - 2)
	if degree == 0 { return inverse }

	mut row := [257]i64{}
	mut next_row := [257]i64{}
	row[0] = 1
	for n in 1 .. degree + 1 {
		for k in 0 .. n + 1 {
			mut value := i64(0)
			if k > 0 { value += i64(n - k) * row[k - 1] }
			if k < n { value += i64(k + 1) * row[k] }
			next_row[k] = value % modulus
		}
		for k in 0 .. n + 1 {
			row[k] = next_row[k]
			next_row[k] = 0
		}
	}

	mut eulerian_value := i64(0)
	mut k := degree
	for k > 0 {
		k--
		eulerian_value = (eulerian_value * r + row[k]) % modulus
	}
	denominator_power := seppl_mod_pow(inverse, i64(degree + 1))
	return r * eulerian_value % modulus * denominator_power % modulus
}

@[export: 'sum_of_exponential_times_polynomial_limit']
pub fn sum_of_exponential_times_polynomial_limit(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		return seppl_evaluate(input[0], input[1])
	}
}
