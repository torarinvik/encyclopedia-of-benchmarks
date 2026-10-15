module count_paths

// Count four-neighbor vertex-simple grid paths by recursive DFS.
fn count_from(values &i64, rows int, cols int, row int, col int, visited u32) i64 {
	if row < 0 || col < 0 || row >= rows || col >= cols { return 0 }
	index := row * cols + col
	mask := u32(1) << u32(index)
	cell := unsafe { values[2 + index] }
	if cell == 1 || (visited & mask) != 0 { return 0 }
	if row == rows - 1 && col == cols - 1 { return 1 }
	seen := visited | mask
	mut count := i64(0)
	count += count_from(values, rows, cols, row + 1, col, seen)
	count += count_from(values, rows, cols, row - 1, col, seen)
	count += count_from(values, rows, cols, row, col + 1, seen)
	count += count_from(values, rows, cols, row, col - 1, seen)
	return count
}

@[export: 'count_paths']
pub fn count_paths(values &i64, length usize) i64 {
	if length < 3 { return -1 }
	rows_value := unsafe { values[0] }
	cols_value := unsafe { values[1] }
	if rows_value < 1 || rows_value > 5 || cols_value < 1 || cols_value > 5 { return -1 }
	rows := int(rows_value)
	cols := int(cols_value)
	if rows * cols > 25 || length != usize(2 + rows * cols) { return -1 }
	for i := 2; i < int(length); i++ {
		cell := unsafe { values[i] }
		if cell != 0 && cell != 1 { return -1 }
	}
	return count_from(values, rows, cols, 0, 0, 0)
}
