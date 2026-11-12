module matrix_det_mod_2

const max_n = 64
const max_input_values = 1 + max_n * max_n

fn store_i64_le(mut output &u8, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'matrix_det_mod_2']
pub fn matrix_det_mod_2(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_values { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_n { return -1 }
	n := int(n_value)
	if length != usize(1 + n * n) { return -1 }

	mut rows := []u64{len: max_n}
	for row in 0 .. n {
		for column in 0 .. n {
			bit := unsafe { input[1 + row * n + column] }
			if bit != 0 && bit != 1 { return -1 }
			rows[row] |= u64(bit) << u64(column)
		}
	}

	mut pivot_row := 0
	for column in 0 .. n {
		mut pivot := pivot_row
		for pivot < n && ((rows[pivot] >> u64(column)) & 1) == 0 { pivot++ }
		if pivot == n { continue }
		rows[pivot_row], rows[pivot] = rows[pivot], rows[pivot_row]
		for row in pivot_row + 1 .. n {
			if ((rows[row] >> u64(column)) & 1) != 0 { rows[row] ^= rows[pivot_row] }
		}
		pivot_row++
	}

	if unsafe { output == nil } || capacity < 8 { return -2 }
	result := if pivot_row == n { i64(1) } else { i64(0) }
	store_i64_le(mut output, result)
	return 8
}
