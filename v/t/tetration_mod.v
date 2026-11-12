module tetration_mod

const max_value = i64(1_000_000_000)

fn totient(value i64) i64 {
	mut result := value
	mut remaining := value
	if remaining % 2 == 0 {
		result -= result / 2
		for remaining % 2 == 0 { remaining /= 2 }
	}
	mut factor := i64(3)
	for factor <= remaining / factor {
		if remaining % factor == 0 {
			result -= result / factor
			for remaining % factor == 0 { remaining /= factor }
		}
		factor += 2
	}
	if remaining > 1 { result -= result / remaining }
	return result
}

fn power_capped(base i64, exponent_input i64, cap i64) i64 {
	mut result := i64(1)
	mut factor := if base < cap { base } else { cap }
	mut exponent := exponent_input
	for exponent > 0 {
		if exponent % 2 != 0 {
			result *= factor
			if result >= cap { return cap }
		}
		exponent /= 2
		if exponent > 0 {
			factor *= factor
			if factor >= cap { factor = cap }
		}
	}
	return result
}

fn tower_capped(base i64, height_input i64, cap i64) i64 {
	if height_input == 0 { return if i64(1) < cap { i64(1) } else { cap } }
	if base == 0 { return if height_input % 2 == 0 { i64(1) } else { i64(0) } }
	if base == 1 { return if i64(1) < cap { i64(1) } else { cap } }
	mut value := i64(1)
	if value >= cap { return cap }
	mut height := height_input
	for height > 0 {
		value = power_capped(base, value, cap)
		if value >= cap { return cap }
		height -= 1
	}
	return value
}

fn modular_power(base_input i64, exponent_input i64, modulus i64) i64 {
	mut result := i64(1) % modulus
	mut base := base_input % modulus
	mut exponent := exponent_input
	for exponent > 0 {
		if exponent % 2 != 0 { result = (result * base) % modulus }
		exponent /= 2
		base = (base * base) % modulus
	}
	return result
}

fn tetration(base i64, height i64, modulus i64) i64 {
	if modulus == 1 { return 0 }
	if height == 0 { return i64(1) % modulus }
	if height == 1 { return base % modulus }
	exponent_modulus := totient(modulus)
	mut exponent := tetration(base, height - 1, exponent_modulus)
	if tower_capped(base, height - 1, exponent_modulus) >= exponent_modulus {
		exponent += exponent_modulus
	}
	return modular_power(base, exponent, modulus)
}

// Packed input [A, B, M], where B is the power-tower height.
@[export: 'tetration_mod']
pub fn tetration_mod(values &i64, length usize) i64 {
	if values == nil || length != 3 { return -1 }
	unsafe {
		base, height, modulus := values[0], values[1], values[2]
		if base < 0 || base > max_value || height < 0 || height > max_value ||
			modulus < 1 || modulus > max_value { return -1 }
		return tetration(base, height, modulus)
	}
}
