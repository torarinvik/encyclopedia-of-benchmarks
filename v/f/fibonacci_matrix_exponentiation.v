module fibonacci_matrix_exponentiation

const max_index = f64(9007199254740991)
const max_modulus = f64(4294967295)

fn multiply_sum(a u64, b u64, c u64, d u64, modulus u64) u64 {
	return ((a * b) % modulus + (c * d) % modulus) % modulus
}

@[export: 'fibonacci_matrix_exponentiation']
pub fn fibonacci_matrix_exponentiation(index_input f64, modulus_input f64) f64 {
	if !(index_input >= 1.0 && index_input <= max_index) ||
		!(modulus_input >= 1.0 && modulus_input <= max_modulus) { return -1.0 }
	index := u64(index_input)
	modulus := u64(modulus_input)
	if f64(index) != index_input || f64(modulus) != modulus_input { return -1.0 }

	mut r00 := u64(1) % modulus
	mut r01 := u64(0)
	mut r10 := u64(0)
	mut r11 := u64(1) % modulus
	mut t00 := u64(0)
	mut t01 := u64(1) % modulus
	mut t10 := u64(1) % modulus
	mut t11 := u64(1) % modulus
	mut exponent := index - 1
	for exponent > 0 {
		if exponent % 2 == 1 {
			n00 := multiply_sum(r00, t00, r01, t10, modulus)
			n01 := multiply_sum(r00, t01, r01, t11, modulus)
			n10 := multiply_sum(r10, t00, r11, t10, modulus)
			n11 := multiply_sum(r10, t01, r11, t11, modulus)
			r00 = n00; r01 = n01; r10 = n10; r11 = n11
			exponent--
		} else {
			n00 := multiply_sum(t00, t00, t01, t10, modulus)
			n01 := multiply_sum(t00, t01, t01, t11, modulus)
			n10 := multiply_sum(t10, t00, t11, t10, modulus)
			n11 := multiply_sum(t10, t01, t11, t11, modulus)
			t00 = n00; t01 = n01; t10 = n10; t11 = n11
			exponent /= 2
		}
	}
	return f64((r00 + r10) % modulus)
}
