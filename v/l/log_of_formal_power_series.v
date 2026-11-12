module log_of_formal_power_series

const modulus = i64(998244353)
const max_n = 64
const max_input = usize(66)

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'log_of_formal_power_series']
pub fn log_of_formal_power_series(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > max_n { return -1 }
		n := int(n_value)
		if length != usize(n + 1) { return -1 }
		for i in 0 .. n { if input[i + 1] < 0 || input[i + 1] >= modulus { return -1 } }
		if input[1] != 1 { return -1 }
		bytes := 8 * n
		if output == nil || capacity < usize(bytes) { return -2 }

		mut integer_inverse := [max_n]i64{}
		mut logarithm := [max_n]i64{}
		if n > 1 { integer_inverse[1] = 1 }
		for k in 2 .. n {
			remainder := int(modulus % i64(k))
			integer_inverse[k] = modulus - (modulus / i64(k)) * integer_inverse[remainder] % modulus
		}
		for degree in 1 .. n {
			mut numerator := (i64(degree) * input[degree + 1]) % modulus
			for i in 1 .. degree {
				mut term := (i64(i) * logarithm[i]) % modulus
				term = term * input[degree - i + 1] % modulus
				numerator = (numerator - term) % modulus
				if numerator < 0 { numerator += modulus }
			}
			logarithm[degree] = numerator * integer_inverse[degree] % modulus
		}
		for i in 0 .. n { store_le(mut output, 8 * i, logarithm[i]) }
		return i64(bytes)
	}
}
