module matrix_rank

fn matrix_rank_is_zero(value f64) bool {
	magnitude := if value < 0.0 { -value } else { value }
	return magnitude < 1e-10
}

@[export: 'matrix_rank']
pub fn matrix_rank(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > 66 { return -1 }
	rows_value := unsafe { values[0] }
	cols_value := unsafe { values[1] }
	if rows_value < 1 || rows_value > 8 || cols_value < 1 || cols_value > 8 { return -1 }

	rows := int(rows_value)
	cols := int(cols_value)
	cells := rows * cols
	if length != usize(2 + cells) { return -1 }

	mut matrix := [64]f64{}
	mut row_marked := [8]bool{}
	for index in 0 .. cells {
		cell := unsafe { values[2 + index] }
		if cell != 0 && cell != 1 { return -1 }
		matrix[index] = f64(cell)
	}

	mut rank := i64(0)
	for col in 0 .. cols {
		mut pivot_row := rows
		for row in 0 .. rows {
			if !row_marked[row] && !matrix_rank_is_zero(matrix[row * cols + col]) {
				pivot_row = row
				break
			}
		}
		if pivot_row == rows { continue }

		rank++
		row_marked[pivot_row] = true
		pivot_value := matrix[pivot_row * cols + col]
		for next_col in col + 1 .. cols {
			matrix[pivot_row * cols + next_col] /= pivot_value
		}
		for other_row in 0 .. rows {
			if other_row == pivot_row { continue }
			factor := matrix[other_row * cols + col]
			if !matrix_rank_is_zero(factor) {
				for next_col in col + 1 .. cols {
					matrix[other_row * cols + next_col] -= matrix[pivot_row * cols + next_col] * factor
				}
			}
		}
	}
	return rank
}
