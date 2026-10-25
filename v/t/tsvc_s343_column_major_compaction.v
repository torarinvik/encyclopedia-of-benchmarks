module tsvc_s343_column_major_compaction

const max_rows = 8
const max_cols = 8
const max_cells = max_rows * max_cols
const max_input_length = 2 + 2 * max_cells
const bytes_per_value = 8

fn store_i64_le(mut output &u8, position int, value i64) {
	bits := u64(value)
	for byte in 0 .. bytes_per_value {
		unsafe { output[position + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'tsvc_s343_column_major_compaction']
pub fn tsvc_s343_column_major_compaction(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
	rows_raw := unsafe { input[0] }
	cols_raw := unsafe { input[1] }
	if rows_raw < 1 || rows_raw > max_rows || cols_raw < 1 || cols_raw > max_cols { return -1 }
	rows := int(rows_raw)
	cols := int(cols_raw)
	cells := rows * cols
	if int(length) != 2 + 2 * cells { return -1 }
	if unsafe { output == nil } || output_capacity < usize(cells * bytes_per_value) { return -2 }

	data_start := 2
	mask_start := data_start + cells
	mut written := 0
	for col := 0; col < cols; col++ {
		for row := 0; row < rows; row++ {
			index := row * cols + col
			if unsafe { input[mask_start + index] > 0 } {
				value := unsafe { input[data_start + index] }
				store_i64_le(mut output, written * bytes_per_value, value)
				written++
			}
		}
	}
	return i64(written)
}
