module convolution_mod_2_64

const max_length = 64
const max_ntt_size = 128
const max_input_length = 2 + 2 * max_length + 1
const max_result_length = 2 * max_length - 1
const p0 = i64(998244353)
const p1 = i64(985661441)
const p2 = i64(943718401)
const p3 = i64(935329793)
const p4 = i64(918552577)

fn power_mod(base_value i64, exponent_value i64, modulus i64) i64 {
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

fn transform(mut values []i64, n int, modulus i64, primitive_root i64, inverse bool) {
	mut j := 0
	for i in 1 .. n {
		mut bit := n >> 1
		for (j & bit) != 0 { j ^= bit; bit >>= 1 }
		j ^= bit
		if i < j { values[i], values[j] = values[j], values[i] }
	}
	mut stage := 2
	for stage <= n {
		mut root := power_mod(primitive_root, (modulus - 1) / i64(stage), modulus)
		if inverse { root = power_mod(root, modulus - 2, modulus) }
		for start := 0; start < n; start += stage {
			mut factor := i64(1)
			for offset := 0; offset < stage / 2; offset++ {
				left := values[start + offset]
				right := values[start + offset + stage / 2] * factor % modulus
				values[start + offset] = (left + right) % modulus
				values[start + offset + stage / 2] = (left - right + modulus) % modulus
				factor = factor * root % modulus
			}
		}
		stage <<= 1
	}
	if inverse {
		scale := power_mod(i64(n), modulus - 2, modulus)
		for i in 0 .. n { values[i] = values[i] * scale % modulus }
	}
}

fn convolution_residues(input &i64, n int, m int, transform_length int,
	modulus i64, primitive_root i64, mut result []i64) {
	mut a := []i64{len: max_ntt_size}
	mut b := []i64{len: max_ntt_size}
	unsafe {
		for i in 0 .. n { a[i] = i64(u64(input[2 + i]) % u64(modulus)) }
		for i in 0 .. m { b[i] = i64(u64(input[2 + n + i]) % u64(modulus)) }
	}
	transform(mut a, transform_length, modulus, primitive_root, false)
	transform(mut b, transform_length, modulus, primitive_root, false)
	for i in 0 .. transform_length { a[i] = a[i] * b[i] % modulus }
	transform(mut a, transform_length, modulus, primitive_root, true)
	for i in 0 .. n + m - 1 { result[i] = a[i] }
}

fn positive_delta(value i64, partial i64, modulus i64) i64 {
	delta := value - partial
	if delta < 0 { return delta + modulus }
	return delta
}

fn store_u64_le(mut output &u8, offset usize, value u64) {
	mut bits := value
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'convolution_mod_2_64']
pub fn convolution_mod_2_64(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_length || m_value < 1 || m_value > max_length { return -1 }
	n, m := int(n_value), int(m_value)
	if length != usize(2 + n + m) { return -1 }
	result_length := n + m - 1
	mut transform_length := 1
	for transform_length < result_length { transform_length <<= 1 }
	output_bytes := 8 * result_length
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }

	mut r0 := []i64{len: max_result_length}
	mut r1 := []i64{len: max_result_length}
	mut r2 := []i64{len: max_result_length}
	mut r3 := []i64{len: max_result_length}
	mut r4 := []i64{len: max_result_length}
	convolution_residues(input, n, m, transform_length, p0, 3, mut r0)
	convolution_residues(input, n, m, transform_length, p1, 3, mut r1)
	convolution_residues(input, n, m, transform_length, p2, 7, mut r2)
	convolution_residues(input, n, m, transform_length, p3, 3, mut r3)
	convolution_residues(input, n, m, transform_length, p4, 5, mut r4)

	p01_p2 := (p0 % p2) * (p1 % p2) % p2
	p01_p3 := (p0 % p3) * (p1 % p3) % p3
	p01_p4 := (p0 % p4) * (p1 % p4) % p4
	p012_p3 := p01_p3 * (p2 % p3) % p3
	p012_p4 := p01_p4 * (p2 % p4) % p4
	p0123_p4 := p012_p4 * (p3 % p4) % p4
	inv0_p1 := power_mod(p0 % p1, p1 - 2, p1)
	inv01_p2 := power_mod(p01_p2, p2 - 2, p2)
	inv012_p3 := power_mod(p012_p3, p3 - 2, p3)
	inv0123_p4 := power_mod(p0123_p4, p4 - 2, p4)
	for i in 0 .. result_length {
		t0 := r0[i]
		t1 := positive_delta(r1[i], t0 % p1, p1) * inv0_p1 % p1
		x01_p2 := (r0[i] % p2 + (p0 % p2) * t1) % p2
		t2 := positive_delta(r2[i], x01_p2, p2) * inv01_p2 % p2
		x012_p3 := (r0[i] % p3 + (p0 % p3) * t1 + p01_p3 * t2) % p3
		t3 := positive_delta(r3[i], x012_p3, p3) * inv012_p3 % p3
		x0123_p4 := (r0[i] % p4 + (p0 % p4) * t1 + p01_p4 * t2 + p012_p4 * t3) % p4
		t4 := positive_delta(r4[i], x0123_p4, p4) * inv0123_p4 % p4
		value := u64(t0) + u64(p0) * u64(t1) + u64(p0) * u64(p1) * u64(t2)
			+ u64(p0) * u64(p1) * u64(p2) * u64(t3)
			+ u64(p0) * u64(p1) * u64(p2) * u64(p3) * u64(t4)
		store_u64_le(mut output, usize(8 * i), value)
	}
	return i64(output_bytes)
}
