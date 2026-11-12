package system_of_linear_equations_mod_2

import "core:c"

MAX_N :: 32
MAX_M :: 32
MAX_INPUT_VALUES :: 2 + MAX_N * MAX_M + MAX_N

store_u64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: u64) {
	bits := value
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
system_of_linear_equations_mod_2 :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_VALUES) do return -1
	n_value := input[0]
	m_value := input[1]
	if n_value < 1 || n_value > i64(MAX_N) || m_value < 1 || m_value > i64(MAX_M) do return -1
	n := int(n_value)
	m := int(m_value)
	if length != c.size_t(2 + n * m + n) do return -1

	rows: [MAX_N]u64
	rhs: [MAX_N]u8
	for row := 0; row < MAX_N; row += 1 { rows[row] = 0; rhs[row] = 0 }
	for row := 0; row < n; row += 1 {
		for column := 0; column < m; column += 1 {
			bit := input[2 + row * m + column]
			if bit != 0 && bit != 1 do return -1
			rows[row] |= u64(bit) << u64(column)
		}
		bit := input[2 + n * m + row]
		if bit != 0 && bit != 1 do return -1
		rhs[row] = u8(bit)
	}

	pivot_columns: [MAX_N]int
	pivot_row := 0
	for column := 0; column < m; column += 1 {
		pivot := pivot_row
		for pivot < n && ((rows[pivot] >> u64(column)) & 1) == 0 do pivot += 1
		if pivot == n do continue
		temporary := rows[pivot_row]
		rows[pivot_row] = rows[pivot]
		rows[pivot] = temporary
		rhs_temporary := rhs[pivot_row]
		rhs[pivot_row] = rhs[pivot]
		rhs[pivot] = rhs_temporary
		for row := 0; row < n; row += 1 {
			if row != pivot_row && ((rows[row] >> u64(column)) & 1) != 0 {
				rows[row] ^= rows[pivot_row]
				rhs[row] ^= rhs[pivot_row]
			}
		}
		pivot_columns[pivot_row] = column
		pivot_row += 1
	}

	for row := pivot_row; row < n; row += 1 {
		if rows[row] == 0 && rhs[row] != 0 {
			if output == nil || capacity < 8 do return -2
			store_u64_le(output, 0, 0xffffffffffffffff)
			return 8
		}
	}

	is_pivot: [MAX_M]bool
	for row := 0; row < pivot_row; row += 1 do is_pivot[pivot_columns[row]] = true
	nullity := m - pivot_row
	output_bytes := 8 * (nullity + 2)
	if output == nil || capacity < c.size_t(output_bytes) do return -2

	particular: u64 = 0
	for row := 0; row < pivot_row; row += 1 {
		if rhs[row] != 0 do particular |= 1 << u64(pivot_columns[row])
	}
	store_u64_le(output, 0, u64(nullity))
	store_u64_le(output, 8, particular)
	basis_index := 0
	for free_column := 0; free_column < m; free_column += 1 {
		if is_pivot[free_column] do continue
		basis := u64(1) << u64(free_column)
		for row := 0; row < pivot_row; row += 1 {
			if ((rows[row] >> u64(free_column)) & 1) != 0 do basis |= u64(1) << u64(pivot_columns[row])
		}
		store_u64_le(output, c.size_t(16 + 8 * basis_index), basis)
		basis_index += 1
	}
	return i64(output_bytes)
}
