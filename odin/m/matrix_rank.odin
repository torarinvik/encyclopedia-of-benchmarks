package matrix_rank

import "core:c"

matrix_rank_is_zero :: proc(value: f64) -> bool {
	magnitude := value
	if magnitude < 0 do magnitude = -magnitude
	return magnitude < 1e-10
}

@(export)
matrix_rank :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 66 do return -1
	rows_value := values[0]
	cols_value := values[1]
	if rows_value < 1 || rows_value > 8 || cols_value < 1 || cols_value > 8 do return -1

	rows := int(rows_value)
	cols := int(cols_value)
	cells := rows * cols
	if length != c.size_t(2 + cells) do return -1

	matrix: [64]f64
	row_marked: [8]bool
	for row := 0; row < rows; row += 1 {
		row_marked[row] = false
	}
	for index := 0; index < cells; index += 1 {
		cell := values[2 + index]
		if cell != 0 && cell != 1 do return -1
		matrix[index] = f64(cell)
	}

	rank := i64(0)
	for col := 0; col < cols; col += 1 {
		pivot_row := rows
		for row := 0; row < rows; row += 1 {
			if !row_marked[row] && !matrix_rank_is_zero(matrix[row*cols+col]) {
				pivot_row = row
				break
			}
		}
		if pivot_row == rows do continue

		rank += 1
		row_marked[pivot_row] = true
		pivot_value := matrix[pivot_row*cols+col]
		for next_col := col + 1; next_col < cols; next_col += 1 {
			matrix[pivot_row*cols+next_col] /= pivot_value
		}
		for other_row := 0; other_row < rows; other_row += 1 {
			if other_row == pivot_row do continue
			factor := matrix[other_row*cols+col]
			if !matrix_rank_is_zero(factor) {
				for next_col := col + 1; next_col < cols; next_col += 1 {
					matrix[other_row*cols+next_col] -= matrix[pivot_row*cols+next_col] * factor
				}
			}
		}
	}
	return rank
}
