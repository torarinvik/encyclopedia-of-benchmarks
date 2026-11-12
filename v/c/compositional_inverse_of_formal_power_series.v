module compositional_inverse_of_formal_power_series

const modulus = i64(998244353)
const min_n = 2
const max_n = 16
const max_input = usize(18)

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

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'compositional_inverse_of_formal_power_series']
pub fn compositional_inverse_of_formal_power_series(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < min_n + 1 || length > max_input { return -1 }
		n_value := input[0]
		if n_value < min_n || n_value > max_n { return -1 }
		n := int(n_value)
		if length != usize(n + 1) { return -1 }
		for i in 0 .. n { if input[i + 1] < 0 || input[i + 1] >= modulus { return -1 } }
		if input[1] != 0 || input[2] == 0 { return -1 }
		bytes := 8 * n
		if output == nil || capacity < usize(bytes) { return -2 }

		mut powers := [max_n * max_n]i64{}
		mut inverse_series := [max_n]i64{}
		inverse_linear := mod_power(input[2], modulus - 2)
		inverse_series[1] = inverse_linear
		powers[max_n + 1] = inverse_linear
		for degree in 2 .. n {
			for power in 2 .. degree + 1 {
				mut coefficient := i64(0)
				for split in 1 .. degree {
					coefficient = (coefficient + powers[(power - 1) * max_n + degree - split] *
						inverse_series[split]) % modulus
				}
				powers[power * max_n + degree] = coefficient
			}
			mut composed_coefficient := i64(0)
			for power in 2 .. degree + 1 {
				composed_coefficient = (composed_coefficient + input[power + 1] *
					powers[power * max_n + degree]) % modulus
			}
			inverse_series[degree] = (modulus - composed_coefficient) * inverse_linear % modulus
			powers[max_n + degree] = inverse_series[degree]
		}
		for i in 0 .. n { store_le(mut output, 8 * i, inverse_series[i]) }
		return i64(bytes)
	}
}
