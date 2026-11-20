module fornberg_finite_difference_weights

const fornberg_modulus = i64(998244353)
const fornberg_max_input = usize(12)

fn fornberg_mod_norm(value i64) i64 {
	reduced := value % fornberg_modulus
	return if reduced < 0 { reduced + fornberg_modulus } else { reduced }
}

fn fornberg_mod_pow(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % fornberg_modulus }
		base = base * base % fornberg_modulus
		exponent >>= 1
	}
	return result
}

fn fornberg_store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
	}
}

@[export: 'fornberg_finite_difference_weights']
pub fn fornberg_finite_difference_weights(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > fornberg_max_input { return -1 }
		n_value := input[0]
		order := input[1]
		target := input[2]
		if n_value < 1 || n_value > 8 || order < 0 || order > 3 || order >= n_value
			|| int(length) != int(n_value) + 3 { return -1 }
		n := int(n_value)
		if target < 0 || target >= fornberg_modulus { return -1 }
		for index in 0 .. n {
			node := input[3 + index]
			if node < 0 || node >= fornberg_modulus { return -1 }
			for previous in 0 .. index { if node == input[3 + previous] { return -1 } }
		}

		mut table := [8][4]i64{init: 0}
		table[0][0] = 1
		mut previous_product := i64(1)
		for new_index in 1 .. n {
			mut old_last := [4]i64{init: 0}
			for derivative in 0 .. 4 { old_last[derivative] = table[new_index - 1][derivative] }
			mut product := i64(1)
			node := input[3 + new_index]
			factor := fornberg_mod_norm(node - target)
			max_derivative := if new_index < int(order) { new_index } else { int(order) }
			for old_index in 0 .. new_index {
				difference := fornberg_mod_norm(node - input[3 + old_index])
				product = product * difference % fornberg_modulus
				inverse_difference := fornberg_mod_pow(difference, fornberg_modulus - 2)
				for derivative := max_derivative; derivative >= 0; derivative-- {
					lower := i64(0)
					if derivative > 0 { lower = table[old_index][derivative - 1] }
					numerator := fornberg_mod_norm(factor * table[old_index][derivative] - i64(derivative) * lower)
					table[old_index][derivative] = numerator * inverse_difference % fornberg_modulus
				}
			}
			product_inverse := fornberg_mod_pow(product, fornberg_modulus - 2)
			last_factor := fornberg_mod_norm(input[2 + new_index] - target)
			for derivative in 0 .. max_derivative + 1 {
				lower := i64(0)
				if derivative > 0 { lower = old_last[derivative - 1] }
				numerator := fornberg_mod_norm(i64(derivative) * lower - last_factor * old_last[derivative])
				table[new_index][derivative] = previous_product * product_inverse % fornberg_modulus * numerator % fornberg_modulus
			}
			previous_product = product
		}

		required := 8 * (n + 1)
		if output == nil || capacity < usize(required) { return -2 }
		fornberg_store_i64_le(mut output, 0, n_value)
		for index in 0 .. n {
			fornberg_store_i64_le(mut output, 8 * (index + 1), table[index][int(order)])
		}
		return i64(required)
	}
}
