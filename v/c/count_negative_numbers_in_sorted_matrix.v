module count_negative_numbers_in_sorted_matrix

@[export: 'count_negative_numbers_in_sorted_matrix']
pub fn count_negative_numbers_in_sorted_matrix(input &i64, length usize) i64 {
	if length < 3 || length > 514 { return -1 }
	rows_value := unsafe { input[0] }
	columns_value := unsafe { input[1] }
	if rows_value < 1 || rows_value > 512 || columns_value < 1 || columns_value > 512 { return -1 }
	rows := int(rows_value)
	columns := int(columns_value)
	if rows * columns > 512 || length != usize(2 + rows * columns) { return -1 }
	mut nonnegative := 0
	mut bound := columns
	for row in 0 .. rows {
		mut left := 0
		mut right := bound
		for left < right {
			middle := left + (right - left) / 2
			value := unsafe { input[2 + row * columns + middle] }
			if value >= 0 { left = middle + 1 } else { right = middle }
		}
		bound = left
		nonnegative += bound
	}
	return i64(rows * columns - nonnegative)
}
