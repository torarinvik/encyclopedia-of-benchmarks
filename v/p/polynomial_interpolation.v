module polynomial_interpolation

const modulus = i64(998244353)
const max_n = 12
const max_input = 25

fn normalize(value i64) i64 {
	reduced := value % modulus
	if reduced < 0 { return reduced + modulus }
	return reduced
}

fn power_mod(base_value i64, exponent_value i64) i64 {
	mut base := base_value
	mut exponent := exponent_value
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
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

@[export: 'polynomial_interpolation']
pub fn polynomial_interpolation(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		n_value := input[0]
		if n_value < 1 || n_value > max_n { return -1 }
		n := int(n_value)
		if length != usize(1 + 2 * n) { return -1 }
		for i in 0 .. n {
			xi := input[1 + i]
			yi := input[1 + n + i]
			if xi < 0 || xi >= modulus || yi < 0 || yi >= modulus { return -1 }
			for j in 0 .. i {
				if xi == input[1 + j] { return -1 }
			}
		}
		bytes := 8 * n
		if output == nil || capacity < usize(bytes) { return -2 }
		mut coefficients := [max_n]i64{}
		for i in 0 .. n {
			mut basis := [max_n + 1]i64{}
			basis[0] = 1
			mut degree := 0
			mut denominator := i64(1)
			for j in 0 .. n {
				if j == i { continue }
				xj := input[1 + j]
				denominator = denominator * (input[1 + i] - xj) % modulus
				mut expanded := [max_n + 1]i64{}
				for k in 0 .. degree + 1 {
					expanded[k] = normalize(expanded[k] - basis[k] * xj)
					expanded[k + 1] = normalize(expanded[k + 1] + basis[k])
				}
				for k in 0 .. degree + 2 { basis[k] = expanded[k] }
				degree++
			}
			scale := input[1 + n + i] * power_mod(normalize(denominator), modulus - 2) % modulus
			for k in 0 .. n { coefficients[k] = (coefficients[k] + scale * basis[k]) % modulus }
		}
		for i in 0 .. n { store_le(mut output, 8 * i, coefficients[i]) }
		return i64(bytes)
	}
}
