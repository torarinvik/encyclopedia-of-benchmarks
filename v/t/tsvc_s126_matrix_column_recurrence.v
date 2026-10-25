module tsvc_s126_matrix_column_recurrence

const max_n = 6
const max_cells = max_n * max_n
const max_input_length = 1 + 3 * max_cells

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'tsvc_s126_matrix_column_recurrence']
pub fn tsvc_s126_matrix_column_recurrence(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 13 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > max_n { return -1 }
		n := int(input[0])
		cells := n * n
		if int(length) != 1 + 3 * cells { return -1 }
		mut coefficients := [max_cells]i64{}
		mut c_matrix := [max_cells]i64{}
		mut b_matrix := [max_cells]i64{}
		for p in 0 .. cells {
			coefficients[p] = input[1 + p]
			c_matrix[p] = input[1 + cells + p]
			b_matrix[p] = input[1 + 2 * cells + p]
			if coefficients[p] < -100 || coefficients[p] > 100 ||
				c_matrix[p] < -100 || c_matrix[p] > 100 || b_matrix[p] < -100 || b_matrix[p] > 100 { return -1 }
		}
		if unsafe { output == nil } || output_capacity < usize(8 * cells) { return -2 }
		mut k := 1
		for i in 0 .. n {
			for j in 1 .. n {
				target := j * n + i
				b_matrix[target] = b_matrix[target - n] + coefficients[k - 1] * c_matrix[target]
				k++
			}
			k++
		}
		for p in 0 .. cells { store_i64_le(mut output, 8 * p, b_matrix[p]) }
		return i64(cells)
	}
}
