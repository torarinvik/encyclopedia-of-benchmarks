module convolution_mod

const modulus = i64(998244353)
const max_length = 256
const max_ntt_size = 512
const max_input_length = 2 + 2 * max_length

fn power_mod(base_input i64, exponent_input i64) i64 {
	mut base := base_input
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = (result * base) % modulus }
		base = (base * base) % modulus
		exponent >>= 1
	}
	return result
}

fn transform(mut values []i64, n int, inverse bool) {
	mut j := 0
	for i in 1 .. n {
		mut bit := n >> 1
		for (j & bit) != 0 {
			j ^= bit
			bit >>= 1
		}
		j ^= bit
		if i < j { values[i], values[j] = values[j], values[i] }
	}
	mut stage := 2
	for stage <= n {
		mut root := power_mod(3, (modulus - 1) / i64(stage))
		if inverse { root = power_mod(root, modulus - 2) }
		mut start := 0
		for start < n {
			mut factor := i64(1)
			for offset in 0 .. stage / 2 {
				left := values[start + offset]
				right := (values[start + offset + stage / 2] * factor) % modulus
				values[start + offset] = (left + right) % modulus
				values[start + offset + stage / 2] = (left - right + modulus) % modulus
				factor = (factor * root) % modulus
			}
			start += stage
		}
		stage *= 2
	}
	if inverse {
		scale := power_mod(i64(n), modulus - 2)
		for i in 0 .. n { values[i] = (values[i] * scale) % modulus }
	}
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

@[export: 'convolution_mod']
pub fn convolution_mod(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_length || m_value < 1 || m_value > max_length { return -1 }
	n := int(n_value)
	m := int(m_value)
	if length != usize(2 + n + m) { return -1 }
	for i in 0 .. n + m {
		coefficient := unsafe { input[2 + i] }
		if coefficient < 0 || coefficient >= modulus { return -1 }
	}

	result_length := n + m - 1
	mut transform_length := 1
	for transform_length < result_length { transform_length *= 2 }
	output_bytes := 8 * result_length
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }

	mut a := []i64{len: max_ntt_size}
	mut b := []i64{len: max_ntt_size}
	for i in 0 .. n { a[i] = unsafe { input[2 + i] } }
	for i in 0 .. m { b[i] = unsafe { input[2 + n + i] } }
	transform(mut a, transform_length, false)
	transform(mut b, transform_length, false)
	for i in 0 .. transform_length { a[i] = (a[i] * b[i]) % modulus }
	transform(mut a, transform_length, true)
	for i in 0 .. result_length { store_i64_le(mut output, 8 * i, a[i]) }
	return i64(output_bytes)
}
