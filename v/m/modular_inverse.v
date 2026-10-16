module modular_inverse

fn normalized_mod(value i64, modulus i64) i64 {
	mut remainder := value % modulus
	if remainder < 0 { remainder += modulus }
	return remainder
}

@[export: 'modular_inverse']
pub fn modular_inverse(a i64, modulus i64) i64 {
	if a < 0 || a > 1000000 || modulus < 2 || modulus > 1000000 { return -1 }

	mut old_remainder := normalized_mod(a, modulus)
	mut remainder := modulus
	mut old_coefficient := i64(1)
	mut coefficient := i64(0)
	for remainder != 0 {
		quotient := old_remainder / remainder
		next_remainder := old_remainder - quotient * remainder
		next_coefficient := old_coefficient - quotient * coefficient
		old_remainder = remainder
		remainder = next_remainder
		old_coefficient = coefficient
		coefficient = next_coefficient
	}
	if old_remainder != 1 { return -1 }
	return normalized_mod(old_coefficient, modulus)
}
