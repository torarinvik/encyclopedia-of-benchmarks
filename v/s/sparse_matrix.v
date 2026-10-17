module sparse_matrix

@[export: 'sparse_matrix']
pub fn sparse_matrix(values &i64, length usize) i64 {
	if values == nil || length < 2 || length > 4099 { return -1 }
	rows_value := unsafe { values[0] }
	columns_value := unsafe { values[1] }
	if rows_value < 1 || rows_value > 64 || columns_value < 1 || columns_value > 64 { return -1 }
	rows := int(rows_value)
	columns := int(columns_value)
	cells := rows * columns
	if length != usize(2 + cells) { return -1 }
	mut zero_count := 0
	for index in 0 .. cells {
		value := unsafe { values[2 + index] }
		if value < -2147483648 || value > 2147483647 { return -1 }
		if value == 0 { zero_count++ }
	}
	return if zero_count > cells / 2 { 1 } else { 0 }
}
