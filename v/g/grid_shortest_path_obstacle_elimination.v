module grid_shortest_path_obstacle_elimination

@[export: 'grid_shortest_path_obstacle_elimination']
pub fn grid_shortest_path_obstacle_elimination(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 3 || length > 40 { return -2 }
	unsafe {
		rows := values[0]
		columns := values[1]
		budget := values[2]
		if rows < 1 || rows > 6 || columns < 1 || columns > 6 || budget < 0 || budget > 6 { return -2 }
		if length != usize(3 + rows * columns) { return -2 }

		cell_count := int(rows * columns)
		mut cells := []i64{len: 36, init: 0}
		for cell in 0 .. cell_count {
			value := values[3 + cell]
			if value != 0 && value != 1 { return -2 }
			cells[cell] = value
		}
		if cells[0] != 0 || cells[cell_count - 1] != 0 { return -2 }

		stride := int(budget + 1)
		mut queue := []int{len: 252, init: 0}
		mut distance := []i64{len: 252, init: -1}
		start := int(budget)
		mut head := 0
		mut tail := 1
		queue[0] = start
		distance[start] = 0

		for head < tail {
			state := queue[head]
			head++
			cell := state / stride
			remaining := state % stride
			if cell + 1 == cell_count { return distance[state] }
			row := cell / int(columns)
			column := cell % int(columns)
			next_rows := [4]int{row - 1, row, row, row + 1}
			next_columns := [4]int{column, column - 1, column + 1, column}
			for direction in 0 .. 4 {
				next_row := next_rows[direction]
				next_column := next_columns[direction]
				if next_row < 0 || next_row >= int(rows) || next_column < 0 || next_column >= int(columns) { continue }
				next_cell := next_row * int(columns) + next_column
				next_remaining := remaining - int(cells[next_cell])
				if next_remaining < 0 { continue }
				next_state := next_cell * stride + next_remaining
				if distance[next_state] != -1 { continue }
				distance[next_state] = distance[state] + 1
				queue[tail] = next_state
				tail++
			}
		}
		return -1
	}
}
