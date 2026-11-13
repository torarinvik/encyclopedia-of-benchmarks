module newton_inverse_sqrt_fps

const modulus = i64(998244353)
const half = i64(499122177)

fn multiply(left [64]i64, right [64]i64, width int) [64]i64 {
	mut result := [64]i64{}
	for i in 0 .. width {
		for j in 0 .. width - i {
			result[i + j] = (result[i + j] + left[i] * right[j]) % modulus
		}
	}
	return result
}

@[export: 'newton_inverse_sqrt_fps']
pub fn newton_inverse_sqrt_fps(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 66 { return -1 }
		if input[0] < 1 || input[0] > 64 { return -1 }
		n := int(input[0])
		if length != usize(n + 1) { return -1 }
		for i in 0 .. n { if input[i + 1] < 0 || input[i + 1] >= modulus { return -1 } }
		if input[1] != 1 { return -1 }
		bytes := 8 * n
		if output == nil || capacity < usize(bytes) { return -2 }
		mut f := [64]i64{}
		mut inverse := [64]i64{}
		for i in 0 .. n { f[i] = input[i + 1] }
		inverse[0] = 1
		mut precision := 1
		for precision < n {
			width := if 2 * precision < n { 2 * precision } else { n }
			square := multiply(inverse, inverse, width)
			product := multiply(f, square, width)
			mut correction := [64]i64{}
			correction[0] = (3 + modulus - product[0]) * half % modulus
			for i in 1 .. width { correction[i] = (modulus - product[i]) * half % modulus }
			inverse = multiply(inverse, correction, width)
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
