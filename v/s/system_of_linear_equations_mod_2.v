module system_of_linear_equations_mod_2

const max_n = 32
const max_m = 32
const max_input_values = 2 + max_n * max_m + max_n

fn store_u64_le(mut output &u8, offset usize, value u64) {
	mut bits := value
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'system_of_linear_equations_mod_2']
pub fn system_of_linear_equations_mod_2(input &i64, length usize, mut output &u8,
	capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	if n_value < 1 || n_value > max_n || m_value < 1 || m_value > max_m { return -1 }
	n := int(n_value)
	m := int(m_value)
	if length != usize(2 + n * m + n) { return -1 }

	mut rows := []u64{len: max_n}
	mut rhs := []u8{len: max_n}
	for row in 0 .. n {
		for column in 0 .. m {
			bit := unsafe { input[2 + row * m + column] }
			if bit != 0 && bit != 1 { return -1 }
			rows[row] |= u64(bit) << u64(column)
		}
		bit := unsafe { input[2 + n * m + row] }
		if bit != 0 && bit != 1 { return -1 }
		rhs[row] = u8(bit)
	}

	mut pivot_columns := []int{len: max_n}
	mut pivot_row := 0
	for column in 0 .. m {
		mut pivot := pivot_row
		for pivot < n && ((rows[pivot] >> u64(column)) & 1) == 0 { pivot++ }
		if pivot == n { continue }
		rows[pivot_row], rows[pivot] = rows[pivot], rows[pivot_row]
		rhs[pivot_row], rhs[pivot] = rhs[pivot], rhs[pivot_row]
		for row in 0 .. n {
			if row != pivot_row && ((rows[row] >> u64(column)) & 1) != 0 {
				rows[row] ^= rows[pivot_row]
				rhs[row] ^= rhs[pivot_row]
			}
		}
		pivot_columns[pivot_row] = column
		pivot_row++
	}

	for row in pivot_row .. n {
		if rows[row] == 0 && rhs[row] != 0 {
			if unsafe { output == nil } || capacity < 8 { return -2 }
			store_u64_le(mut output, 0, u64(0xffffffffffffffff))
			return 8
		}
	}

	mut is_pivot := []bool{len: max_m}
	for row in 0 .. pivot_row { is_pivot[pivot_columns[row]] = true }
	nullity := m - pivot_row
	output_bytes := 8 * (nullity + 2)
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }

	mut particular := u64(0)
	for row in 0 .. pivot_row {
		if rhs[row] != 0 { particular |= u64(1) << u64(pivot_columns[row]) }
	}
	store_u64_le(mut output, 0, u64(nullity))
	store_u64_le(mut output, 8, particular)
	mut basis_index := 0
	for free_column in 0 .. m {
		if is_pivot[free_column] { continue }
		mut basis := u64(1) << u64(free_column)
		for row in 0 .. pivot_row {
			if ((rows[row] >> u64(free_column)) & 1) != 0 {
				basis |= u64(1) << u64(pivot_columns[row])
			}
		}
		store_u64_le(mut output, usize(16 + 8 * basis_index), basis)
		basis_index++
	}
	i64(output_bytes)
}
