package convolution_mod

import "core:c"

MODULUS :: i64(998244353)
MAX_LENGTH :: 256
MAX_NTT_SIZE :: 512
MAX_INPUT_LENGTH :: 2 + 2 * MAX_LENGTH

power_mod :: proc "contextless" (base_input, exponent_input: i64) -> i64 {
	base := base_input
	exponent := exponent_input
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = (result * base) % MODULUS
		base = (base * base) % MODULUS
		exponent >>= 1
	}
	return result
}

transform :: proc "contextless" (values: [^]i64, n: int, inverse: bool) {
	j := 0
	for i := 1; i < n; i += 1 {
		bit := n >> 1
		for (j & bit) != 0 { j ^= bit; bit >>= 1 }
		j ^= bit
		if i < j { temporary := values[i]; values[i] = values[j]; values[j] = temporary }
	}
	for stage := 2; stage <= n; stage *= 2 {
		root := power_mod(3, (MODULUS - 1) / i64(stage))
		if inverse do root = power_mod(root, MODULUS - 2)
		for start := 0; start < n; start += stage {
			factor := i64(1)
			for offset := 0; offset < stage / 2; offset += 1 {
				left := values[start + offset]
				right := (values[start + offset + stage / 2] * factor) % MODULUS
				values[start + offset] = (left + right) % MODULUS
				values[start + offset + stage / 2] = (left - right + MODULUS) % MODULUS
				factor = (factor * root) % MODULUS
			}
		}
	}
	if inverse {
		scale := power_mod(i64(n), MODULUS - 2)
		for i := 0; i < n; i += 1 do values[i] = (values[i] * scale) % MODULUS
	}
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := u64(value)
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
convolution_mod :: proc "c" (input: [^]i64, length: c.size_t,
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
	output_bytes := 8 * result_length
	if output == nil || capacity < c.size_t(output_bytes) do return -2

	a: [MAX_NTT_SIZE]i64
	b: [MAX_NTT_SIZE]i64
	for i := 0; i < MAX_NTT_SIZE; i += 1 { a[i] = 0; b[i] = 0 }
	for i := 0; i < n; i += 1 do a[i] = input[2 + i]
	for i := 0; i < m; i += 1 do b[i] = input[2 + n + i]
	transform(&a[0], transform_length, false)
	transform(&b[0], transform_length, false)
	for i := 0; i < transform_length; i += 1 do a[i] = (a[i] * b[i]) % MODULUS
	transform(&a[0], transform_length, true)
	for i := 0; i < result_length; i += 1 do store_i64_le(output, c.size_t(8 * i), a[i])
	return i64(output_bytes)
}
