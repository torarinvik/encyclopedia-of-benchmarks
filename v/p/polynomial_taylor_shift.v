module polynomial_taylor_shift

const modulus = i64(998244353)
const max_n = 64
const max_input = 66

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'polynomial_taylor_shift']
pub fn polynomial_taylor_shift(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n_value := input[0]
		shift := input[1]
		if n_value < 1 || n_value > max_n { return -1 }
		n := int(n_value)
		if length != usize(n + 2) || shift < 0 || shift >= modulus { return -1 }
		for i in 0 .. n {
			if input[i + 2] < 0 || input[i + 2] >= modulus { return -1 }
		}
		bytes := 8 * n
		if output == nil || capacity < usize(bytes) { return -2 }
		mut shifted := [max_n]i64{}
		mut processed := 0
		for source := n; source > 0; source-- {
			for degree := processed; degree > 0; degree-- {
				shifted[degree] = (shifted[degree] * shift + shifted[degree - 1]) % modulus
			}
			shifted[0] = (shifted[0] * shift + input[source + 1]) % modulus
			processed++
		}
		for i in 0 .. n { store_le(mut output, 8 * i, shifted[i]) }
		return i64(bytes)
	}
}
