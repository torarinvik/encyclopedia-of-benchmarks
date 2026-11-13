module newton_reciprocal_fps

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

@[export: 'newton_reciprocal_fps']
pub fn newton_reciprocal_fps(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 66 { return -1 }
		if input[0] < 1 || input[0] > 64 { return -1 }
		n := int(input[0])
		if length != usize(n + 1) { return -1 }
		for i in 0 .. n { if input[i + 1] < 0 || input[i + 1] >= modulus { return -1 } }
		if input[1] == 0 { return -1 }
		bytes := 8 * n
		if output == nil || capacity < usize(bytes) { return -2 }
		mut inverse := [64]i64{}
		inverse[0] = power(input[1], modulus - 2)
		mut precision := 1
		for precision < n {
			width := if 2 * precision < n { 2 * precision } else { n }
			mut correction := [64]i64{}
			for i in 0 .. width {
				mut j := 0
				for j < precision && i + j < width {
					correction[i + j] = (correction[i + j] + input[i + 1] * inverse[j]) % modulus
					j++
				}
			}
			correction[0] = (2 + modulus - correction[0]) % modulus
			for i in 1 .. width { correction[i] = (modulus - correction[i]) % modulus }
			mut next := [64]i64{}
			for i in 0 .. precision {
				for j in 0 .. width - i {
					next[i + j] = (next[i + j] + inverse[i] * correction[j]) % modulus
				}
			}
			inverse = next
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
