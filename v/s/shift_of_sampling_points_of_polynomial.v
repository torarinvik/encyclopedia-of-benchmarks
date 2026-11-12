module shift_of_sampling_points_of_polynomial

const modulus = i64(998244353)
const max_n = 16
const max_m = 16
const max_input = 20

fn mod_pow(base_value i64, exponent_value i64) i64 {
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

@[export: 'shift_of_sampling_points_of_polynomial']
pub fn shift_of_sampling_points_of_polynomial(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		if input[0] < 1 || input[0] > max_n || input[1] < 1 || input[1] > max_m { return -1 }
		n := int(input[0])
		m := int(input[1])
		start := input[2]
		if length != usize(n + 3) || start < 0 || start >= modulus { return -1 }
		for i in 0 .. n {
			if input[i + 3] < 0 || input[i + 3] >= modulus { return -1 }
		}
		bytes := 8 * m
		if output == nil || capacity < usize(bytes) { return -2 }
		mut differences := [max_n]i64{}
		mut newton := [max_n]i64{}
		mut factorial := [max_n]i64{}
		mut inverse_factorial := [max_n]i64{}
		for i in 0 .. n { differences[i] = input[i + 3] }
		factorial[0] = 1
		for k in 1 .. n { factorial[k] = factorial[k - 1] * i64(k) % modulus }
		inverse_factorial[n - 1] = mod_pow(factorial[n - 1], modulus - 2)
		for k := n - 1; k > 0; k-- { inverse_factorial[k - 1] = inverse_factorial[k] * i64(k) % modulus }
		for k in 0 .. n {
			newton[k] = differences[0] * inverse_factorial[k] % modulus
			for i in 0 .. n - k - 1 {
				differences[i] = differences[i + 1] - differences[i]
				if differences[i] < 0 { differences[i] += modulus }
			}
		}
		for offset in 0 .. m {
			mut x := start + i64(offset)
			if x >= modulus { x -= modulus }
			mut basis := i64(1)
			mut value := i64(0)
			for k in 0 .. n {
				value = (value + newton[k] * basis) % modulus
				mut factor := x - i64(k)
				if factor < 0 { factor += modulus }
				basis = basis * factor % modulus
			}
			store_le(mut output, 8 * offset, value)
		}
		return i64(bytes)
	}
}
