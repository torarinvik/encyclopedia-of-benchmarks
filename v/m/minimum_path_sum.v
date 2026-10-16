module minimum_path_sum

@[export: 'minimum_path_sum']
pub fn minimum_path_sum(values &i64, length usize) i64 {
	if length < 2 || length > 66 || unsafe { values == nil } { return i64(-9223372036854775807) - 1 }
	row_value := values[0]
	column_value := values[1]
	if row_value < 1 || row_value > 8 || column_value < 1 || column_value > 8 { return i64(-9223372036854775807) - 1 }
	rows := int(row_value)
	columns := int(column_value)
	if length != usize(2 + rows * columns) { return i64(-9223372036854775807) - 1 }
	unsafe {
		mut costs := [8]i64{}
		for row in 0 .. rows {
			for column in 0 .. columns {
				cell := values[2 + row * columns + column]
				if cell < 0 || cell > 1000 { return i64(-9223372036854775807) - 1 }
				if row == 0 && column == 0 { costs[column] = cell }
				else if row == 0 { costs[column] = costs[column - 1] + cell }
				else if column == 0 { costs[column] += cell }
				else if costs[column - 1] < costs[column] { costs[column] = costs[column - 1] + cell }
				else { costs[column] += cell }
			}
		}
		return costs[columns - 1]
	}
}
