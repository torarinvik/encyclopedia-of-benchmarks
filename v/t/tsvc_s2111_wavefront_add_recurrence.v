module tsvc_s2111_wavefront_add_recurrence

const max_side = 8
const max_passes = 4
const max_cells = max_side * max_side
const max_input_length = 2 + max_cells

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'tsvc_s2111_wavefront_add_recurrence']
pub fn tsvc_s2111_wavefront_add_recurrence(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 6 || length > max_input_length { return -1 }
	side_raw := unsafe { input[0] }
	passes_raw := unsafe { input[1] }
	if side_raw < 2 || side_raw > max_side || passes_raw < 1 || passes_raw > max_passes { return -1 }
	side := int(side_raw)
	cells := side * side
	if int(length) != 2 + cells { return -1 }

	mut matrix := [max_cells]i64{}
	for cell in 0 .. cells {
		value := unsafe { input[2 + cell] }
		if value < -8 || value > 8 { return -1 }
		matrix[cell] = value
	}
	if unsafe { output == nil } || output_capacity < usize(8 * cells) { return -2 }

	for _ in 0 .. int(passes_raw) {
		for row in 1 .. side {
			for col in 1 .. side {
				matrix[row * side + col] = matrix[row * side + col - 1] + matrix[(row - 1) * side + col]
			}
		}
	}
	for cell in 0 .. cells { store_i64_le(mut output, 8 * cell, matrix[cell]) }
	return i64(cells)
}
