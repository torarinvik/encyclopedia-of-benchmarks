module newton_compositional_inverse_fps

const modulus = i64(998244353)

fn power(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if exponent % 2 != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent /= 2
	}
	return result
}

fn multiply(left [16]i64, right [16]i64, width int) [16]i64 {
	mut result := [16]i64{}
	for i in 0 .. width {
		for j in 0 .. width - i {
			result[i + j] = (result[i + j] + left[i] * right[j]) % modulus
		}
	}
	return result
}

fn compose(outer [16]i64, inner [16]i64, width int) [16]i64 {
	mut result := [16]i64{}
	mut degree := width
	for degree > 0 {
		degree--
		result = multiply(result, inner, width)
		result[0] = (result[0] + outer[degree]) % modulus
	}
	return result
}

@[export: 'newton_compositional_inverse_fps']
pub fn newton_compositional_inverse_fps(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 18 { return -1 }
		if input[0] < 2 || input[0] > 16 { return -1 }
		n := int(input[0])
		if length != usize(n + 1) { return -1 }
		for i in 0 .. n { if input[i + 1] < 0 || input[i + 1] >= modulus { return -1 } }
		if input[1] != 0 || input[2] == 0 { return -1 }
		bytes := n * 8
		if output == nil || capacity < usize(bytes) { return -2 }
		mut f := [16]i64{}
		mut derivative := [16]i64{}
		mut inverse := [16]i64{}
		for i in 0 .. n { f[i] = input[i + 1] }
		for i in 1 .. n { derivative[i - 1] = i64(i) * f[i] % modulus }
		inverse_linear := power(f[1], modulus - 2)
		inverse[1] = inverse_linear
		mut precision := 2
		for precision < n {
			width := if 2 * precision < n { 2 * precision } else { n }
			mut residual := compose(f, inverse, width)
			residual[1] = (residual[1] + modulus - 1) % modulus
			slope := compose(derivative, inverse, width)
			mut reciprocal := [16]i64{}
			reciprocal[0] = inverse_linear
			for i in 1 .. width {
				mut sum := i64(0)
				for j in 1 .. i + 1 { sum = (sum + slope[j] * reciprocal[i - j]) % modulus }
				reciprocal[i] = (modulus - sum) * inverse_linear % modulus
			}
			correction := multiply(residual, reciprocal, width)
			for i in 0 .. width { inverse[i] = (inverse[i] + modulus - correction[i]) % modulus }
			precision = width
		}
		for i in 0 .. n {
			mut bits := u64(inverse[i])
			for byte in 0 .. 8 {
				output[8 * i + byte] = u8(bits & 255)
				bits >>= 8
			}
		}
		return i64(bytes)
	}
}
