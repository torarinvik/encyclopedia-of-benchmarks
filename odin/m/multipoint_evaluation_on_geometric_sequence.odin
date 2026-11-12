package multipoint_evaluation_on_geometric_sequence

import "core:c"

MODULUS :: i64(998244353)
MAX_N :: 8
MAX_M :: 8
NTT_SIZE :: 32
MAX_INPUT :: 12
Transform :: [NTT_SIZE]i64

mod_pow :: proc(base_value, exponent_value: i64) -> i64 {
	base := base_value
	exponent := exponent_value
	result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % MODULUS
		base = base * base % MODULUS
		exponent >>= 1
	}
	return result
}

ntt :: proc(values: ^Transform, inverse: bool) {
	j := 0
	for i := 1; i < NTT_SIZE; i += 1 {
		bit := NTT_SIZE / 2
		for (j & bit) != 0 { j ^= bit; bit >>= 1 }
		j ^= bit
		if i < j { values^[i], values^[j] = values^[j], values^[i] }
	}
	block := 2
	for block <= NTT_SIZE {
		root := mod_pow(3, (MODULUS - 1) / i64(block))
		if inverse { root = mod_pow(root, MODULUS - 2) }
		half := block / 2
		for start := 0; start < NTT_SIZE; start += block {
			factor := i64(1)
			for offset := 0; offset < half; offset += 1 {
				even := values^[start + offset]
				odd := values^[start + offset + half] * factor % MODULUS
				values^[start + offset] = (even + odd) % MODULUS
				values^[start + offset + half] = (even - odd + MODULUS) % MODULUS
				factor = factor * root % MODULUS
			}
		}
		block *= 2
	}
	if inverse {
		scale := mod_pow(i64(NTT_SIZE), MODULUS - 2)
		for i := 0; i < NTT_SIZE; i += 1 { values^[i] = values^[i] * scale % MODULUS }
	}
}

evaluate :: proc(coefficients: [^]i64, offset, count: int, x: i64) -> i64 {
	value := i64(0)
	for i := count; i > 0; i -= 1 { value = (value * x + coefficients[offset + i - 1]) % MODULUS }
	return value
}

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
multipoint_evaluation_on_geometric_sequence :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT do return -1
	if input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_M do return -1
	n := int(input[0])
	m := int(input[1])
	start := input[2]
	ratio := input[3]
	if int(length) != n + 4 || start < 0 || start >= MODULUS || ratio < 0 || ratio >= MODULUS do return -1
	for i := 0; i < n; i += 1 { if input[4 + i] < 0 || input[4 + i] >= MODULUS do return -1 }
	bytes := 8 * m
	if output == nil || int(capacity) < bytes do return -2
	if start == 0 {
		for i := 0; i < m; i += 1 { store_le(output, 8 * i, input[4]) }
		return i64(bytes)
	}
	if ratio == 0 {
		store_le(output, 0, evaluate(input, 4, n, start))
		for i := 1; i < m; i += 1 { store_le(output, 8 * i, input[4]) }
		return i64(bytes)
	}

	mut left := [NTT_SIZE]i64{}
	mut right := [NTT_SIZE]i64{}
	inverse_ratio := mod_pow(ratio, MODULUS - 2)
	start_power := i64(1)
	inverse_chirp := i64(1)
	inverse_ratio_power := i64(1)
	for degree := 0; degree < n; degree += 1 {
		left[n - 1 - degree] = input[4 + degree] * start_power % MODULUS * inverse_chirp % MODULUS
		start_power = start_power * start % MODULUS
		inverse_chirp = inverse_chirp * inverse_ratio_power % MODULUS
		inverse_ratio_power = inverse_ratio_power * inverse_ratio % MODULUS
	}
	chirp := i64(1)
	ratio_power := i64(1)
	for index := 0; index < n + m - 1; index += 1 {
		right[index] = chirp
		chirp = chirp * ratio_power % MODULUS
		ratio_power = ratio_power * ratio % MODULUS
	}
	ntt(&left, false)
	ntt(&right, false)
	for i := 0; i < NTT_SIZE; i += 1 { left[i] = left[i] * right[i] % MODULUS }
	ntt(&left, true)
	inverse_chirp = 1
	inverse_ratio_power = 1
	for i := 0; i < m; i += 1 {
		store_le(output, 8 * i, left[n - 1 + i] * inverse_chirp % MODULUS)
		inverse_chirp = inverse_chirp * inverse_ratio_power % MODULUS
		inverse_ratio_power = inverse_ratio_power * inverse_ratio % MODULUS
	}
	return i64(bytes)
}
