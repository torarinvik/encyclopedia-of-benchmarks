module tsvc_s2102_identity_matrix_initialize

const max_side = 8
const max_passes = 8
const max_cells = max_side * max_side

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'tsvc_s2102_identity_matrix_initialize']
pub fn tsvc_s2102_identity_matrix_initialize(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	side_raw := unsafe { input[0] }
	passes_raw := unsafe { input[1] }
	if side_raw < 1 || side_raw > max_side || passes_raw < 1 || passes_raw > max_passes { return -1 }
	side := int(side_raw)
	cells := side * side
	if unsafe { output == nil } || output_capacity < usize(8 * cells) { return -2 }

	mut matrix := [max_cells]i64{}
	for _ in 0 .. int(passes_raw) {
		for col in 0 .. side {
			for row in 0 .. side { matrix[row * side + col] = 0 }
			matrix[col * side + col] = 1
		}
	}
	for cell in 0 .. cells { store_i64_le(mut output, 8 * cell, matrix[cell]) }
	return i64(cells)
}
