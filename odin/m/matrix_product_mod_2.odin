package matrix_product_mod_2

import "core:c"

MAX_DIMENSION :: 64
MAX_INPUT_VALUES :: 3 + 2 * MAX_DIMENSION * MAX_DIMENSION
MAX_OUTPUT_VALUES :: MAX_DIMENSION * MAX_DIMENSION

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
matrix_product_mod_2 :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_VALUES do return -1
	n_value, m_value, k_value := input[0], input[1], input[2]
	if n_value < 1 || n_value > i64(MAX_DIMENSION) || m_value < 1 ||
		m_value > i64(MAX_DIMENSION) || k_value < 1 || k_value > i64(MAX_DIMENSION) do return -1
	n, m, k := int(n_value), int(m_value), int(k_value)
	a_length, b_length := n * m, m * k
	if length != c.size_t(3 + a_length + b_length) do return -1

	packed_b: [MAX_DIMENSION]u64
	for inner := 0; inner < MAX_DIMENSION; inner += 1 do packed_b[inner] = 0
	b_start := 3 + a_length
	for inner := 0; inner < m; inner += 1 {
		for column := 0; column < k; column += 1 {
			bit := input[b_start + inner * k + column]
			if bit != 0 && bit != 1 do return -1
			packed_b[inner] |= u64(bit) << u64(column)
		}
	}

	staged: [MAX_OUTPUT_VALUES]i64
	for row := 0; row < n; row += 1 {
		accumulator: u64 = 0
		for inner := 0; inner < m; inner += 1 {
			bit := input[3 + row * m + inner]
			if bit != 0 && bit != 1 do return -1
			if bit == 1 do accumulator = accumulator ^ packed_b[inner]
		}
		for column := 0; column < k; column += 1
			staged[row * k + column] = i64((accumulator >> u64(column)) & 1)
	}

	required := 8 * n * k
	if output == nil || capacity < c.size_t(required) do return -2
	for index := 0; index < n * k; index += 1
		store_i64_le(output, 8 * index, staged[index])
	return i64(required)
}
