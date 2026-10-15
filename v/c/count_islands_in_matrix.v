module count_islands_in_matrix

fn flood(values &i64, mut visited []bool, rows int, cols int, row int, col int) {
	if row < 0 || col < 0 || row >= rows || col >= cols { return }
	index := row * cols + col
	cell := unsafe { values[2 + index] }
	if cell != 1 || visited[index] { return }
	visited[index] = true
	for dr in -1 .. 2 {
		for dc in -1 .. 2 {
			if dr != 0 || dc != 0 { flood(values, mut visited, rows, cols, row + dr, col + dc) }
		}
	}
}

@[export: 'count_islands_in_matrix']
pub fn count_islands_in_matrix(values &i64, length usize) i64 {
	if length < 3 { return -1 }
	rows_value := unsafe { values[0] }
	cols_value := unsafe { values[1] }
	if rows_value < 1 || rows_value > 16 || cols_value < 1 || cols_value > 16 { return -1 }
	rows := int(rows_value)
	cols := int(cols_value)
	if length != usize(2 + rows * cols) { return -1 }
	for i in 2 .. length {
		cell := unsafe { values[i] }
		if cell != 0 && cell != 1 { return -1 }
	}
	mut visited := []bool{len: rows * cols}
	mut count := i64(0)
	for row in 0 .. rows {
		for col in 0 .. cols {
			index := row * cols + col
			cell := unsafe { values[2 + index] }
			if cell == 1 && !visited[index] {
				count++
				flood(values, mut visited, rows, cols, row, col)
			}
		}
	}
	return count
}
