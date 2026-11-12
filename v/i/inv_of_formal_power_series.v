module inv_of_formal_power_series

const modulus = i64(998244353)
const max_n = 64
const max_input = usize(66)

fn power_mod(base_input i64, exponent_input i64) i64 {
	mut base := base_input
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if exponent & 1 != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
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

@[export: 'inv_of_formal_power_series']
pub fn inv_of_formal_power_series(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > max_n { return -1 }
		n := int(n_value)
		if length != usize(n + 1) { return -1 }
		for i in 0 .. n { if input[i + 1] < 0 || input[i + 1] >= modulus { return -1 } }
		if input[1] == 0 { return -1 }
		bytes := 8 * n
		if output == nil || capacity < usize(bytes) { return -2 }

		mut inverse := [max_n]i64{}
		inverse_constant := power_mod(input[1], modulus - 2)
		inverse[0] = inverse_constant
		for degree in 1 .. n {
			mut sum := i64(0)
			for i in 1 .. degree + 1 { sum = (sum + input[i + 1] * inverse[degree - i]) % modulus }
			inverse[degree] = (modulus - inverse_constant * sum % modulus) % modulus
		}
		for i in 0 .. n { store_le(mut output, 8 * i, inverse[i]) }
		return i64(bytes)
	}
}
