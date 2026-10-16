module problem82

@[export: 'problem82']
pub fn problem82(values &i64, length usize) i64 {
	if length < 3 || unsafe { values == nil } { return -1 }
	row_value := values[0]
	column_value := values[1]
	if row_value < 1 || row_value > 80 || column_value < 1 || column_value > 80 { return -1 }
	rows := int(row_value)
	columns := int(column_value)
	if length != usize(2 + rows * columns) { return -1 }
	unsafe {
		for index in 2 .. int(length) {
			if values[index] < 0 || values[index] > 9999 { return -1 }
		}
		mut costs := [80]i64{}
		for row in 0 .. rows { costs[row] = values[2 + row * columns] }
		for column in 1 .. columns {
			offset := 2 + column
			for row in 0 .. rows { costs[row] += values[offset + row * columns] }
			for row in 1 .. rows {
				from_above := costs[row - 1] + values[offset + row * columns]
				if from_above < costs[row] { costs[row] = from_above }
			}
			mut row := rows - 1
			for row > 0 {
				from_below := costs[row] + values[offset + (row - 1) * columns]
				if from_below < costs[row - 1] { costs[row - 1] = from_below }
				row--
			}
		}
		mut best := costs[0]
		for row in 1 .. rows { if costs[row] < best { best = costs[row] } }
		return best
	}
}
