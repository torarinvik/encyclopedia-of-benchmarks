@[export: 'number_of_ways_of_cutting_a_pizza']
pub fn number_of_ways_of_cutting_a_pizza(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 39 { return -1 }
		rows_value := input[0]
		columns_value := input[1]
		cuts_value := input[2]
		if rows_value < 1 || rows_value > 6 || columns_value < 1 || columns_value > 6 ||
			cuts_value < 0 || cuts_value > 5 { return -1 }
		rows := int(rows_value)
		columns := int(columns_value)
		cuts := int(cuts_value)
		if length != usize(3 + rows*columns) { return -1 }
		mut cells := []i64{len: 36, init: 0}
		for index in 0 .. rows*columns {
			cell := input[3+index]
			if cell != 0 && cell != 1 { return -1 }
			cells[index] = cell
		}
		mut suffix := []i64{len: 49, init: 0}
		for row_offset in 0 .. rows {
			row := rows - 1 - row_offset
			for column_offset in 0 .. columns {
				column := columns - 1 - column_offset
				at := row*7 + column
				suffix[at] = cells[row*columns+column] + suffix[(row+1)*7+column] +
					suffix[row*7+column+1] - suffix[(row+1)*7+column+1]
			}
		}
		mut previous := []i64{len: 49, init: 0}
		mut current := []i64{len: 49, init: 0}
		for row in 0 .. rows {
			for column in 0 .. columns {
				if suffix[row*7+column] > 0 { previous[row*7+column] = 1 }
			}
		}
		for _ in 0 .. cuts {
			for index in 0 .. 49 { current[index] = 0 }
			for row_offset in 0 .. rows {
				row := rows - 1 - row_offset
				for column_offset in 0 .. columns {
					column := columns - 1 - column_offset
					origin := row*7 + column
					mut ways := i64(0)
					for cut_row in row + 1 .. rows {
						if suffix[origin]-suffix[cut_row*7+column] > 0 {
							ways += previous[cut_row*7+column]
						}
					}
					for cut_column in column + 1 .. columns {
						if suffix[origin]-suffix[row*7+cut_column] > 0 {
							ways += previous[row*7+cut_column]
						}
					}
					current[origin] = ways % 1000000007
				}
			}
			for index in 0 .. 49 { previous[index] = current[index] }
		}
		return previous[0]
	}
}
