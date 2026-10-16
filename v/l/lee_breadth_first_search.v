module lee_breadth_first_search

@[export: 'lee_breadth_first_search']
pub fn lee_breadth_first_search(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 6 || length > 70 { return -2 }
	unsafe {
		rows := values[0]
		cols := values[1]
		source_row := values[2]
		source_col := values[3]
		destination_row := values[4]
		destination_col := values[5]
		if rows < 1 || rows > 8 || cols < 1 || cols > 8 ||
			length != usize(6 + rows * cols) || source_row < 0 || source_row >= rows ||
			destination_row < 0 || destination_row >= rows || source_col < 0 || source_col >= cols ||
			destination_col < 0 || destination_col >= cols { return -2 }

		cell_count := int(rows * cols)
		mut cells := []i64{len: 64, init: 0}
		mut distance := []i64{len: 64, init: -1}
		mut queue := []int{len: 64, init: 0}
		for index in 0 .. cell_count {
			cells[index] = values[6 + index]
			if cells[index] != 0 && cells[index] != 1 { return -2 }
		}

		start := int(source_row * cols + source_col)
		goal := int(destination_row * cols + destination_col)
		if cells[start] == 0 || cells[goal] == 0 { return -1 }
		distance[start] = 0
		queue[0] = start
		mut head := 0
		mut tail := 1
		for head < tail {
			current := queue[head]
			head++
			if current == goal { return distance[current] }
			row := current / int(cols)
			column := current % int(cols)
			next_rows := [4]int{row - 1, row, row, row + 1}
			next_columns := [4]int{column, column - 1, column + 1, column}
			for direction in 0 .. 4 {
				next_row := next_rows[direction]
				next_column := next_columns[direction]
				if next_row >= 0 && next_row < int(rows) && next_column >= 0 && next_column < int(cols) {
					next := next_row * int(cols) + next_column
					if cells[next] == 1 && distance[next] < 0 {
						distance[next] = distance[current] + 1
						queue[tail] = next
						tail++
					}
				}
			}
		}
		return -1
	}
}
