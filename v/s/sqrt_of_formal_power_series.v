module sqrt_of_formal_power_series

const modulus = i64(998244353)
const max_n = 64
const max_input = usize(66)

fn mod_power(base_value i64, exponent_value i64) i64 {
	mut base := base_value % modulus
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if exponent % 2 != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent /= 2
	}
	return result
}

fn mod_square_root(value i64) i64 {
	if value == 0 { return 0 }
	if mod_power(value, (modulus - 1) / 2) != 1 { return -1 }
	mut odd_part := modulus - 1
	mut twos := 0
	for odd_part % 2 == 0 { odd_part /= 2; twos++ }
	mut non_residue := i64(2)
	for mod_power(non_residue, (modulus - 1) / 2) != modulus - 1 { non_residue++ }
	mut c := mod_power(non_residue, odd_part)
	mut root := mod_power(value, (odd_part + 1) / 2)
	mut remainder := mod_power(value, odd_part)
	mut order := twos
	for remainder != 1 {
		mut index := 1
		mut probe := remainder * remainder % modulus
		for index < order && probe != 1 { probe = probe * probe % modulus; index++ }
		if index >= order || probe != 1 { return -1 }
		mut exponent := i64(1)
		for _ in 0 .. (order - index - 1) { exponent *= 2 }
		factor := mod_power(c, exponent)
		root = root * factor % modulus
		factor_squared := factor * factor % modulus
		remainder = remainder * factor_squared % modulus
		c = factor_squared
		order = index
	}
	return if root < modulus - root { root } else { modulus - root }
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'sqrt_of_formal_power_series']
pub fn sqrt_of_formal_power_series(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > max_n { return -1 }
		n := int(n_value)
		if length != usize(n + 1) { return -1 }
		for i in 0 .. n { if input[i + 1] < 0 || input[i + 1] >= modulus { return -1 } }
		bytes := 8 * n
		if output == nil || capacity < usize(bytes) { return -2 }

		mut result := [max_n]i64{}
		mut valuation := 0
		for valuation < n && input[valuation + 1] == 0 { valuation++ }
		if valuation == n {
			for i in 0 .. n { store_le(mut output, 8 * i, 0) }
			return i64(bytes)
		}
		if valuation % 2 != 0 { store_le(mut output, 0, -1); return 8 }
		shift := valuation / 2
		leading_root := mod_square_root(input[valuation + 1])
		if leading_root < 0 { store_le(mut output, 0, -1); return 8 }
		inverse_twice_root := mod_power((2 * leading_root) % modulus, modulus - 2)
		width := n - valuation
		result[shift] = leading_root
		for degree in 1 .. width {
			mut cross_terms := i64(0)
			for i in 1 .. degree {
				cross_terms = (cross_terms + result[shift + i] * result[shift + degree - i]) % modulus
			}
			mut delta := (input[valuation + degree + 1] - cross_terms) % modulus
			if delta < 0 { delta += modulus }
			result[shift + degree] = delta * inverse_twice_root % modulus
		}
		for i in 0 .. n { store_le(mut output, 8 * i, result[i]) }
		return i64(bytes)
	}
}
