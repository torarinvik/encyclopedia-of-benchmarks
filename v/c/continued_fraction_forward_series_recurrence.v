module continued_fraction_forward_series_recurrence

const modulus = i64(998244353)

fn mod_pow(base_value i64, exponent_value i64) i64 {
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

fn next_numerator(coefficient i64, rho i64) i64 {
	return coefficient * ((rho + 1) % modulus) % modulus
}

fn divisors_are_nonzero(input &i64, count int) bool {
	mut rho := i64(0)
	unsafe {
		for index in 1 .. count {
			top := next_numerator(input[index + 1], rho)
			denominator := (1 + modulus - top) % modulus
			if denominator == 0 { return false }
			rho = top * mod_pow(denominator, modulus - 2) % modulus
		}
	}
	return true
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
		}
	}
}

@[export: 'continued_fraction_forward_series_recurrence']
pub fn continued_fraction_forward_series_recurrence(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 11 { return -1 }
		count_value := input[0]
		if count_value < 2 || count_value > 9 { return -1 }
		count := int(count_value)
		if int(length) != count + 1 { return -1 }
		for index in 1 .. count + 1 {
			if input[index] < 0 || input[index] >= modulus { return -1 }
		}
		if !divisors_are_nonzero(input, count) { return -1 }
		required := usize(8 * (count + 1))
		if output == nil || capacity < required { return -2 }

		store_i64_le(mut output, 0, count_value)
		mut rho := i64(0)
		mut term := input[1]
		mut total := term
		store_i64_le(mut output, 8, total)
		for index in 1 .. count {
			top := next_numerator(input[index + 1], rho)
			denominator := (1 + modulus - top) % modulus
			rho = top * mod_pow(denominator, modulus - 2) % modulus
			term = rho * term % modulus
			total = (total + term) % modulus
			store_i64_le(mut output, 8 * (index + 1), total)
		}
		return i64(required)
	}
}
