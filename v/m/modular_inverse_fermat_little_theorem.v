module modular_inverse_fermat_little_theorem

fn is_prime(value i64) bool {
	if value <= 1 { return false }
	mut divisor := i64(2)
	for divisor * divisor <= value {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn binary_exponentiation(base_input i64, exponent_input i64, modulus i64) i64 {
	mut base := base_input % modulus
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if exponent % 2 != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent /= 2
	}
	return result
}

@[export: 'modular_inverse_fermat_little_theorem']
pub fn modular_inverse_fermat_little_theorem(a i64, m i64) i64 {
	if a < -1000000 || a > 1000000 || m < 2 || m > 1000000 { return -1 }
	if a == 0 || a <= -m || a >= m || !is_prime(m) { return -1 }
	mut normalized := a
	for normalized < 0 { normalized += m }
	return binary_exponentiation(normalized, m - 2, m)
}
