package convolution_mod_1000000007

import "core:c"

MODULUS :: i64(1_000_000_007)
P1 :: i64(998_244_353)
P2 :: i64(1_004_535_809)
P3 :: i64(469_762_049)
MAX_LENGTH :: 64
NTT_SIZE :: 128
MAX_RESULT :: 2 * MAX_LENGTH - 1
MAX_INPUT_LENGTH :: 2 + 2 * MAX_LENGTH

power_mod :: proc "contextless" (base_input, exponent_input, modulus: i64) -> i64 {
	base := base_input
	exponent := exponent_input
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = (result * base) % modulus
		base = (base * base) % modulus
		exponent >>= 1
	}
	return result
}

transform :: proc "contextless" (values: [^]i64, n: int, modulus: i64, inverse: bool) {
	j := 0
	for i := 1; i < n; i += 1 {
		bit := n >> 1
		for (j & bit) != 0 { j ^= bit; bit >>= 1 }
		j ^= bit
		if i < j { temporary := values[i]; values[i] = values[j]; values[j] = temporary }
	}
	for stage := 2; stage <= n; stage *= 2 {
		root := power_mod(3, (modulus - 1) / i64(stage), modulus)
		if inverse do root = power_mod(root, modulus - 2, modulus)
		for start := 0; start < n; start += stage {
			factor := i64(1)
			for offset := 0; offset < stage / 2; offset += 1 {
				left := values[start + offset]
				right := (values[start + offset + stage / 2] * factor) % modulus
				values[start + offset] = (left + right) % modulus
				values[start + offset + stage / 2] = (left - right + modulus) % modulus
				factor = (factor * root) % modulus
			}
		}
	}
	if inverse {
		scale := power_mod(i64(n), modulus - 2, modulus)
		for i := 0; i < n; i += 1 do values[i] = (values[i] * scale) % modulus
	}
}

convolution_residues :: proc "contextless" (input: [^]i64, n, m, transform_length,
	result_length: int, modulus: i64, result: [^]i64) {
	a: [NTT_SIZE]i64
	b: [NTT_SIZE]i64
	for i := 0; i < NTT_SIZE; i += 1 { a[i] = 0; b[i] = 0 }
	for i := 0; i < n; i += 1 do a[i] = input[2 + i] % modulus
	for i := 0; i < m; i += 1 do b[i] = input[2 + n + i] % modulus
	transform(&a[0], transform_length, modulus, false)
	transform(&b[0], transform_length, modulus, false)
	for i := 0; i < transform_length; i += 1 do a[i] = (a[i] * b[i]) % modulus
	transform(&a[0], transform_length, modulus, true)
	for i := 0; i < result_length; i += 1 do result[i] = a[i]
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := u64(value)
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
convolution_mod_1000000007 :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_value := input[0]
	m_value := input[1]
	if n_value < 1 || n_value > MAX_LENGTH || m_value < 1 || m_value > MAX_LENGTH do return -1
	n := int(n_value)
	m := int(m_value)
	if length != c.size_t(2 + n + m) do return -1
	for i := 0; i < n + m; i += 1 {
		coefficient := input[2 + i]
		if coefficient < 0 || coefficient >= MODULUS do return -1
	}
	result_length := n + m - 1
	transform_length := 1
	for transform_length < result_length do transform_length *= 2
	output_bytes := c.size_t(8 * result_length)
	if output == nil || capacity < output_bytes do return -2

	r1: [MAX_RESULT]i64
	r2: [MAX_RESULT]i64
	r3: [MAX_RESULT]i64
	convolution_residues(input, n, m, transform_length, result_length, P1, &r1[0])
	convolution_residues(input, n, m, transform_length, result_length, P2, &r2[0])
	convolution_residues(input, n, m, transform_length, result_length, P3, &r3[0])
	inv1 := power_mod(P1 % P2, P2 - 2, P2)
	p12mod3 := (P1 % P3) * (P2 % P3) % P3
	inv12 := power_mod(p12mod3, P3 - 2, P3)
	p1mod := P1 % MODULUS
	p12mod := p1mod * (P2 % MODULUS) % MODULUS
	for i := 0; i < result_length; i += 1 {
		t1 := ((r2[i] - r1[i] % P2 + P2) % P2) * inv1 % P2
		x12 := (r1[i] % P3 + (P1 % P3) * (t1 % P3)) % P3
		t2 := ((r3[i] - x12 + P3) % P3) * inv12 % P3
		value := (r1[i] + p1mod * (t1 % MODULUS) + p12mod * (t2 % MODULUS)) % MODULUS
		store_i64_le(output, c.size_t(8 * i), value)
	}
	return i64(output_bytes)
}
