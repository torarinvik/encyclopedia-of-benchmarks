module binary_search2d_array

fn search_row(values &i64, row_base i64, low i64, high i64, target i64) i64 {
	mut lo := low
	mut hi := high
	for lo <= hi {
		middle := lo + (hi - lo) / 2
		value := unsafe { values[3 + row_base + middle] }
		if value == target { return middle }
		if value < target { lo = middle + 1 } else { hi = middle - 1 }
	}
	return -1
}

@[export: 'binary_search2d_array']
pub fn binary_search2d_array(values &i64, length usize) i64 {
	if length < 3 { return -1 }
	rows := unsafe { values[0] }
	cols := unsafe { values[1] }
	target := unsafe { values[2] }
	if rows < 2 || rows > 32 || cols < 3 || cols > 32 { return -1 }
	if length != usize(3 + rows * cols) { return -1 }
	middle_col := cols / 2
	mut start_row := i64(0)
	mut end_row := rows - 1
	for start_row < end_row - 1 {
		middle_row := start_row + (end_row - start_row) / 2
		value := unsafe { values[3 + middle_row * cols + middle_col] }
		if value == target { return middle_row * cols + middle_col }
		if value < target { start_row = middle_row } else { end_row = middle_row }
	}
	if unsafe { values[3 + start_row * cols + middle_col] } == target { return start_row * cols + middle_col }
	if unsafe { values[3 + end_row * cols + middle_col] } == target { return end_row * cols + middle_col }
	if target <= unsafe { values[3 + start_row * cols + middle_col - 1] } {
		col := search_row(values, start_row * cols, 0, middle_col - 1, target)
		if col < 0 { return -1 }
		return start_row * cols + col
	}
	if target >= unsafe { values[3 + start_row * cols + middle_col + 1] } && target <= unsafe { values[3 + start_row * cols + cols - 1] } {
		col := search_row(values, start_row * cols, middle_col + 1, cols - 1, target)
		if col < 0 { return -1 }
		return start_row * cols + col
	}
	if target <= unsafe { values[3 + end_row * cols + middle_col - 1] } {
		col := search_row(values, end_row * cols, 0, middle_col - 1, target)
		if col < 0 { return -1 }
		return end_row * cols + col
	}
	col := search_row(values, end_row * cols, middle_col + 1, cols - 1, target)
	if col < 0 { return -1 }
	return end_row * cols + col
}
