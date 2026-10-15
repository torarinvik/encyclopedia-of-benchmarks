module pascal_triangle_row

// Compute one row of Pascal's triangle using in-place dynamic programming.
@[export: 'pascal_triangle_row']
pub fn pascal_triangle_row(row_index i64, output &u8, output_capacity usize) i64 {
	if row_index < 0 || row_index > 33 { return -1 }
	count := int(row_index) + 1
	required := usize(count * 4)
	if output_capacity < required { return -2 }

	mut coefficients := [34]u32{}
	for column in 0 .. count {
		coefficients[column] = 1
	}
	for row in 2 .. int(row_index) + 1 {
		mut column := row - 1
		for column > 0 {
			coefficients[column] += coefficients[column - 1]
			column--
		}
	}

	mut position := usize(0)
	for column in 0 .. count {
		for byte in 0 .. 4 {
			unsafe {
				output[position] = u8((coefficients[column] >> u32(byte * 8)) & 255)
			}
			position++
		}
	}
	return i64(position)
}
