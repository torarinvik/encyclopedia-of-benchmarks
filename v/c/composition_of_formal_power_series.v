module composition_of_formal_power_series

const modulus = i64(998244353)
const max_n = 16
const max_input = usize(34)

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'composition_of_formal_power_series']
pub fn composition_of_formal_power_series(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > max_n { return -1 }
		n := int(n_value)
		if length != usize(1 + 2 * n) { return -1 }
		for i in 0 .. 2 * n { if input[i + 1] < 0 || input[i + 1] >= modulus { return -1 } }
		if input[1 + n] != 0 { return -1 }
		bytes := 8 * n
		if output == nil || capacity < usize(bytes) { return -2 }

		mut composed := [max_n]i64{}
		mut outer := n
		for outer > 0 {
			mut bound := n
			for bound > 1 {
				degree := bound - 1
				mut sum := i64(0)
				for inner_degree in 1 .. degree + 1 {
					sum = (sum + composed[degree - inner_degree] * input[1 + n + inner_degree]) % modulus
				}
				composed[degree] = sum
				bound--
			}
			composed[0] = input[outer]
			outer--
		}
		for i in 0 .. n { store_le(mut output, 8 * i, composed[i]) }
		return i64(bytes)
	}
}
