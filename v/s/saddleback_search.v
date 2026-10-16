module saddleback_search

@[export: 'saddleback_search']
pub fn saddleback_search(values &i64, length usize) i64 {
	if length < 3 { return -1 }
	unsafe {
		rows_value := values[0]
		columns_value := values[1]
		target := values[2]
		if rows_value <= 0 || rows_value > 32 || columns_value <= 0 || columns_value > 32 {
			return -1
		}
		if target < -2147483648 || target > 2147483647 { return -1 }
		rows := usize(rows_value)
		columns := usize(columns_value)
		cells := rows * columns
		if length != 3 + cells { return -1 }
		for index := usize(0); index < cells; index++ {
			value := values[3 + index]
			if value < -2147483648 || value > 2147483647 { return -1 }
		}

		mut row := usize(0)
		mut column := columns - 1
		for row < rows {
			value := values[3 + row * columns + column]
			if value == target { return i64(row * columns + column + 1) }
			if value < target {
				row++
			} else if column == 0 {
				break
			} else {
				column--
			}
		}
	}
	return 0
}
