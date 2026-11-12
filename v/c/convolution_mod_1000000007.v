module convolution_mod_1000000007

const modulus = i64(1_000_000_007)
const p1 = i64(998_244_353)
const p2 = i64(1_004_535_809)
const p3 = i64(469_762_049)
const max_length = 64
const ntt_size = 128
const max_result = 2 * max_length - 1
const max_input_length = 2 + 2 * max_length

fn power_mod(base_input i64, exponent_input i64, modulus_value i64) i64 {
	mut base := base_input
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = (result * base) % modulus_value }
		base = (base * base) % modulus_value
		exponent >>= 1
	}
	return result
}

fn transform(mut values []i64, n int, modulus_value i64, inverse bool) {
	mut j := 0
	for i in 1 .. n {
		mut bit := n >> 1
		for (j & bit) != 0 { j ^= bit; bit >>= 1 }
		j ^= bit
		if i < j { values[i], values[j] = values[j], values[i] }
	}
	mut stage := 2
	for stage <= n {
		mut root := power_mod(3, (modulus_value - 1) / i64(stage), modulus_value)
		if inverse { root = power_mod(root, modulus_value - 2, modulus_value) }
		mut start := 0
		for start < n {
			mut factor := i64(1)
			for offset in 0 .. stage / 2 {
				left := values[start + offset]
				right := (values[start + offset + stage / 2] * factor) % modulus_value
				values[start + offset] = (left + right) % modulus_value
				values[start + offset + stage / 2] = (left - right + modulus_value) % modulus_value
				factor = (factor * root) % modulus_value
			}
			start += stage
		}
		stage *= 2
	}
	if inverse {
		scale := power_mod(i64(n), modulus_value - 2, modulus_value)
		for i in 0 .. n { values[i] = (values[i] * scale) % modulus_value }
	}
}

fn convolution_residues(input &i64, n int, m int, transform_length int,
	result_length int, modulus_value i64, mut result []i64) {
	mut a := []i64{len: ntt_size}
	mut b := []i64{len: ntt_size}
	unsafe {
		for i in 0 .. n { a[i] = input[2 + i] % modulus_value }
		for i in 0 .. m { b[i] = input[2 + n + i] % modulus_value }
	}
	transform(mut a, transform_length, modulus_value, false)
	transform(mut b, transform_length, modulus_value, false)
	for i in 0 .. transform_length { a[i] = (a[i] * b[i]) % modulus_value }
	transform(mut a, transform_length, modulus_value, true)
	for i in 0 .. result_length { result[i] = a[i] }
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'convolution_mod_1000000007']
pub fn convolution_mod_1000000007(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	unsafe {
		n_value := input[0]
		m_value := input[1]
		if n_value < 1 || n_value > max_length || m_value < 1 || m_value > max_length { return -1 }
		n := int(n_value)
		m := int(m_value)
		if length != usize(2 + n + m) { return -1 }
		for i in 0 .. n + m {
			coefficient := input[2 + i]
			if coefficient < 0 || coefficient >= modulus { return -1 }
		}
		result_length := n + m - 1
		mut transform_length := 1
		for transform_length < result_length { transform_length *= 2 }
		output_bytes := 8 * result_length
		if output == nil || capacity < usize(output_bytes) { return -2 }

		mut r1 := []i64{len: max_result}
		mut r2 := []i64{len: max_result}
		mut r3 := []i64{len: max_result}
		convolution_residues(input, n, m, transform_length, result_length, p1, mut r1)
		convolution_residues(input, n, m, transform_length, result_length, p2, mut r2)
		convolution_residues(input, n, m, transform_length, result_length, p3, mut r3)
		inv1 := power_mod(p1 % p2, p2 - 2, p2)
		p12mod3 := (p1 % p3) * (p2 % p3) % p3
		inv12 := power_mod(p12mod3, p3 - 2, p3)
		p1mod := p1 % modulus
		p12mod := p1mod * (p2 % modulus) % modulus
		for i in 0 .. result_length {
			t1 := ((r2[i] - r1[i] % p2 + p2) % p2) * inv1 % p2
			x12 := (r1[i] % p3 + (p1 % p3) * (t1 % p3)) % p3
			t2 := ((r3[i] - x12 + p3) % p3) * inv12 % p3
			value := (r1[i] + p1mod * (t1 % modulus) + p12mod * (t2 % modulus)) % modulus
			store_i64_le(mut output, 8 * i, value)
		}
		return i64(output_bytes)
	}
}
