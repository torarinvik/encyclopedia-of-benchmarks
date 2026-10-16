module greedy_best_first

fn gbf_heuristic(cell int, goal int, columns int) int {
	row, column := cell / columns, cell % columns
	goal_row, goal_column := goal / columns, goal % columns
	row_distance := if row > goal_row { row - goal_row } else { goal_row - row }
	column_distance := if column > goal_column { column - goal_column } else { goal_column - column }
	return row_distance + column_distance
}

@[export: 'greedy_best_first']
pub fn greedy_best_first(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 7 || length > 9 { return -1 }
	row_value, column_value := unsafe { values[0] }, unsafe { values[1] }
	if row_value < 1 || row_value > 3 || column_value < 1 || column_value > 3 { return -1 }
	rows, columns := int(row_value), int(column_value)
	if length != usize(6 + rows) { return -1 }
	start_row, start_column := unsafe { values[2] }, unsafe { values[3] }
	goal_row, goal_column := unsafe { values[4] }, unsafe { values[5] }
	if start_row < 0 || start_row >= row_value || goal_row < 0 || goal_row >= row_value || start_column < 0 || start_column >= column_value || goal_column < 0 || goal_column >= column_value { return -1 }
	mut masks := [3]int{}
	for row in 0 .. rows {
		mask := unsafe { values[6 + row] }
		if mask < 0 || mask >= (i64(1) << columns) { return -1 }
		masks[row] = int(mask)
	}
	start, goal := int(start_row) * columns + int(start_column), int(goal_row) * columns + int(goal_column)
	if (masks[start / columns] & (1 << (start % columns))) != 0 || (masks[goal / columns] & (1 << (goal % columns))) != 0 { return -1 }
	mut opened := [9]int{}
	mut parent := [9]int{}
	mut closed := [9]bool{}
	mut in_open := [9]bool{}
	for cell in 0 .. 9 { parent[cell] = -1 }
	mut open_count := 1
	mut found := false
	opened[0], in_open[start] = start, true
	for open_count > 0 {
		for index in 1 .. open_count {
			current := opened[index]
			mut position := index
			for position > 0 && gbf_heuristic(opened[position - 1], goal, columns) > gbf_heuristic(current, goal, columns) {
				opened[position] = opened[position - 1]
				position--
			}
			opened[position] = current
		}
		current := opened[0]
		for index in 1 .. open_count { opened[index - 1] = opened[index] }
		open_count--
		in_open[current] = false
		if current == goal { found = true; break }
		closed[current] = true
		row, column := current / columns, current % columns
		next_rows := [4]int{row - 1, row, row + 1, row}
		next_columns := [4]int{column, column - 1, column, column + 1}
		for direction in 0 .. 4 {
			next_row, next_column := next_rows[direction], next_columns[direction]
			if next_row < 0 || next_row >= rows || next_column < 0 || next_column >= columns { continue }
			child := next_row * columns + next_column
			if (masks[next_row] & (1 << next_column)) != 0 || closed[child] || in_open[child] { continue }
			parent[child], opened[open_count] = current, child
			open_count++
			in_open[child] = true
		}
	}
	mut path := [9]int{}
	mut path_count := 0
	if found {
		mut current := goal
		for current >= 0 && path_count < 9 {
			path[path_count] = current
			path_count++
			current = parent[current]
		}
	} else {
		path[0], path_count = start, 1
	}
	mut packed := u64(0)
	for index in 0 .. path_count { packed |= u64(path[path_count - 1 - index] + 1) << (4 * index) }
	return i64((u64(path_count) << 36) | packed)
}
