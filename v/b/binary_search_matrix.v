module binary_search_matrix

fn search_row(values &i64, base usize, lower i64, upper i64, target i64) i64 {
	unsafe {
		middle := (lower + upper) / 2
		value := values[base + usize(middle)]
		if value == target { return middle }
		if lower >= upper { return -1 }
		if value < target { return search_row(values, base, middle + 1, upper, target) }
		return search_row(values, base, lower, middle - 1, target)
	}
}

@[export: 'binary_search_matrix']
pub fn binary_search_matrix(values &i64, length usize) i64 {
	if length < 3 { return -1 }
	unsafe {
		rows_value := values[0]
		columns_value := values[1]
		target := values[2]
		if rows_value <= 0 || rows_value > 32 || columns_value <= 0 || columns_value > 32 { return -1 }
		rows := usize(rows_value)
		columns := usize(columns_value)
		if length != 3 + rows * columns { return -1 }
		if values[3] == target { return 0 }
		mut row := 0
		for row < rows && values[3 + row * columns] < target {
			column := search_row(values, 3 + row * columns, 0, i64(columns) - 1, target)
			if column != -1 { return i64(row * columns) + column }
			row++
		}
	}
	return -1
}
