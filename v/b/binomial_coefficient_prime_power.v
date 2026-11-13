module binomial_coefficient_prime_power

const max_queries = 32
const max_n = 128
const max_parseable = 68
const max_modulus = i64(1_000_000_000)

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

@[export: 'binomial_coefficient_prime_power']
pub fn binomial_coefficient_prime_power(input &i64, length usize,
		mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_parseable { return -1 }
		p, e, q_value := input[0], input[1], input[2]
		if p < 2 || p > 31 || !is_prime(p) || e < 1 || e > 8 || q_value < 0 || q_value > max_queries { return -1 }
		mut modulus := i64(1)
		for index := i64(0); index < e; index++ {
			modulus *= p
			if modulus > max_modulus { return -1 }
		}
		q := int(q_value)
		if length != usize(3 + 2 * q) { return -1 }
		for i in 0 .. q {
			n, k := input[3 + 2 * i], input[4 + 2 * i]
			if n < 0 || n > max_n || k < 0 || k > n { return -1 }
		}
		if q == 0 { return 0 }
		required := 4 * q
		if output == nil || capacity < usize(required) { return -2 }

		mut unit_prefix := [max_n + 1]i64{}
		mut p_free_factorial := [max_n + 1]i64{}
		mut valuation := [max_n + 1]u16{}
		mut residues := [max_queries]u32{}
		unit_prefix[0], p_free_factorial[0] = 1, 1
		for n in 1 .. max_n + 1 {
			mut factor := i64(n)
			if n % int(p) == 0 { factor = 1 }
			unit_prefix[n] = unit_prefix[n - 1] * factor % modulus
			p_free_factorial[n] = unit_prefix[n] * p_free_factorial[n / int(p)] % modulus
			valuation[n] = u16(n / int(p) + int(valuation[n / int(p)]))
		}
		phi := modulus / p * (p - 1)
		for i in 0 .. q {
			n, k := int(input[3 + 2 * i]), int(input[4 + 2 * i])
			p_power := int(valuation[n]) - int(valuation[k]) - int(valuation[n - k])
			if p_power < int(e) {
				denominator := p_free_factorial[k] * p_free_factorial[n - k] % modulus
				inverse := pow_mod(denominator, phi - 1, modulus)
				prime_factor := pow_mod(p, i64(p_power), modulus)
				residues[i] = u32(p_free_factorial[n] * inverse % modulus * prime_factor % modulus)
			}
		}
		for i in 0 .. q {
			for byte in 0 .. 4 {
				output[4 * i + byte] = u8(residues[i] >> (8 * byte))
			}
		}
		return i64(required)
	}
}
