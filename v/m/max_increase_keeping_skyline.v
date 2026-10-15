module max_increase_keeping_skyline

// Return the total allowable increase while preserving row and column skylines.
@[export: 'max_increase_keeping_skyline']
pub fn max_increase_keeping_skyline(values &i64, length usize) i64 {
	if length < 2 || length > 2501 { return -1 }
	n_value := unsafe { values[0] }
	if n_value < 2 || n_value > 50 { return -1 }
	n := int(n_value)
	if length != usize(1 + n * n) { return -1 }

	mut row_max := [50]i64{}
	mut column_max := [50]i64{}
	for row in 0 .. n {
		for column in 0 .. n {
			height := unsafe { values[1 + row * n + column] }
			if height < 0 || height > 100 { return -1 }
			if height > row_max[row] { row_max[row] = height }
			if height > column_max[column] { column_max[column] = height }
		}
	}

	mut total := i64(0)
	for row in 0 .. n {
		for column in 0 .. n {
			height := unsafe { values[1 + row * n + column] }
			skyline := if row_max[row] < column_max[column] { row_max[row] } else { column_max[column] }
			total += skyline - height
		}
	}
	return total
}
