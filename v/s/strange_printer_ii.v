module strange_printer_ii

const max_rows = 6
const max_columns = 6
const max_colors = 6
const color_side = 7

@[export: 'strange_printer_ii']
pub fn strange_printer_ii(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 39 { return -1 }
		rows_value := input[0]
		columns_value := input[1]
		if rows_value < 1 || rows_value > max_rows || columns_value < 1 || columns_value > max_columns { return -1 }
		rows := int(rows_value)
		columns := int(columns_value)
		if length != usize(2 + rows * columns) { return -1 }
		for cell in 0 .. rows * columns {
			if input[cell + 2] < 1 || input[cell + 2] > max_colors { return -1 }
		}
		mut first_row := [7]i64{}
		mut last_row := [7]i64{}
		mut first_column := [7]i64{}
		mut last_column := [7]i64{}
		mut outgoing := [7]i64{}
		mut indegree := [7]i64{}
		mut queue := [7]i64{}
		for color in 0 .. color_side {
			first_row[color] = rows_value
			last_row[color] = -1
			first_column[color] = columns_value
			last_column[color] = -1
		}
		for row in 0 .. rows {
			for column in 0 .. columns {
				color := int(input[2 + row * columns + column])
				if i64(row) < first_row[color] { first_row[color] = i64(row) }
				if i64(row) > last_row[color] { last_row[color] = i64(row) }
				if i64(column) < first_column[color] { first_column[color] = i64(column) }
				if i64(column) > last_column[color] { last_column[color] = i64(column) }
			}
		}
		mut present_count := i64(0)
		for color in 1 .. max_colors + 1 {
			if last_row[color] < 0 { continue }
			present_count++
			for row := int(first_row[color]); row <= int(last_row[color]); row++ {
				for column := int(first_column[color]); column <= int(last_column[color]); column++ {
					covered := int(input[2 + row * columns + column])
					bit := i64(1) << covered
					if covered != color && (outgoing[color] & bit) == 0 {
						outgoing[color] |= bit
						indegree[covered]++
					}
				}
			}
		}
		mut head := 0
		mut tail := 0
		for color in 1 .. max_colors + 1 {
			if last_row[color] >= 0 && indegree[color] == 0 {
				queue[tail] = i64(color)
				tail++
			}
		}
		mut processed := i64(0)
		for head < tail {
			color := int(queue[head])
			head++
			processed++
			for later in 1 .. max_colors + 1 {
				if (outgoing[color] & (i64(1) << later)) != 0 {
					indegree[later]--
					if indegree[later] == 0 {
						queue[tail] = i64(later)
						tail++
					}
				}
			}
		}
		if processed == present_count { return 1 }
		return 0
	}
}
