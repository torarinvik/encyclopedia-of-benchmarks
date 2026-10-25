module tsvc_s2101_diagonal_matrix_fma

const max_n = 8
const max_cells = max_n * max_n
const max_input_length = 1 + 3 * max_cells
const max_value = i64(100)

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'tsvc_s2101_diagonal_matrix_fma']
pub fn tsvc_s2101_diagonal_matrix_fma(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	n_raw := unsafe { input[0] }
	if n_raw < 1 || n_raw > max_n { return -1 }
	n := int(n_raw)
	cells := n * n
	if int(length) != 1 + 3 * cells { return -1 }
	for i in 0 .. 3 * cells {
		value := unsafe { input[i + 1] }
		if value < -max_value || value > max_value { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(8 * cells) { return -2 }

	for cell in 0 .. cells {
		store_i64_le(mut output, 8 * cell, unsafe { input[cell + 1] })
	}
	for i in 0 .. n {
		diagonal := i * n + i
		value := unsafe {
			input[1 + diagonal] + input[1 + cells + diagonal] * input[1 + 2 * cells + diagonal]
		}
		store_i64_le(mut output, 8 * diagonal, value)
	}
	return i64(cells)
}
