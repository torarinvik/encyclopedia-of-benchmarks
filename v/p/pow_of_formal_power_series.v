module pow_of_formal_power_series

const modulus = i64(998244353)
const max_exponent = i64(1_000_000_000_000_000_000)
const max_n = 32
const max_input = 34

fn multiply_truncated(left [max_n]i64, right [max_n]i64, n int) [max_n]i64 {
	mut product := [max_n]i64{}
	for i in 0 .. n {
		for j in 0 .. n - i {
			product[i + j] = (product[i + j] + left[i] * right[j]) % modulus
		}
	}
	return product
}

fn store_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'pow_of_formal_power_series']
pub fn pow_of_formal_power_series(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		if input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > max_exponent { return -1 }
		n := int(input[0])
		if length != usize(n + 2) { return -1 }
		for i in 0 .. n { if input[i + 2] < 0 || input[i + 2] >= modulus { return -1 } }
		bytes := 8 * n
		if output == nil || capacity < usize(bytes) { return -2 }
		mut result := [max_n]i64{}
		mut base := [max_n]i64{}
		result[0] = 1
		for i in 0 .. n { base[i] = input[i + 2] }
		mut exponent := input[1]
		for exponent > 0 {
			if exponent & 1 != 0 { result = multiply_truncated(result, base, n) }
			exponent >>= 1
			if exponent > 0 { base = multiply_truncated(base, base, n) }
		}
		for i in 0 .. n { store_le(mut output, 8 * i, result[i]) }
		return i64(bytes)
	}
}
