module modular_division

// Fermat modular division for a bounded prime modulus.
fn modular_division_is_prime(value i64) bool {
	if value < 2 { return false }
	mut divisor := i64(2)
	for divisor <= value / divisor {
		if value % divisor == 0 { return false }
		divisor++
	}
	return true
}

fn modular_division_power(base_input i64, exponent_input u64, modulus i64) i64 {
	mut base := base_input % modulus
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent != 0 {
		if exponent & 1 != 0 { result = (result * base) % modulus }
		exponent >>= 1
		base = (base * base) % modulus
	}
	return result
}

@[export: 'modular_division']
pub fn modular_division(values &i64, length usize) i64 {
	if length != 3 { return -1 }
	numerator := unsafe { values[0] }
	denominator := unsafe { values[1] }
	modulus := unsafe { values[2] }
	if numerator < 0 || numerator > 1000000000000 || denominator < 0 || denominator > 1000000000000 ||
		modulus < 2 || modulus > 1000000 || !modular_division_is_prime(modulus) || denominator % modulus == 0 {
		return -1
	}
	inverse := modular_division_power(denominator, u64(modulus-2), modulus)
	return ((numerator % modulus) * inverse) % modulus
}
