package greedy_best_first

import "core:c"

heuristic :: proc(cell, goal, columns: int) -> int {
	row, column := cell / columns, cell % columns
	goal_row, goal_column := goal / columns, goal % columns
	row_distance := row - goal_row
	if row_distance < 0 do row_distance = -row_distance
	column_distance := column - goal_column
	if column_distance < 0 do column_distance = -column_distance
	return row_distance + column_distance
}

@(export)
greedy_best_first :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 7 || length > 9 do return -1
	row_value, column_value := values[0], values[1]
	if row_value < 1 || row_value > 3 || column_value < 1 || column_value > 3 do return -1
	rows, columns := int(row_value), int(column_value)
	if length != c.size_t(6 + rows) do return -1
	start_row, start_column, goal_row, goal_column := values[2], values[3], values[4], values[5]
	if start_row < 0 || start_row >= row_value || goal_row < 0 || goal_row >= row_value || start_column < 0 || start_column >= column_value || goal_column < 0 || goal_column >= column_value do return -1
	masks: [3]int
	for row := 0; row < rows; row += 1 {
		mask := values[6 + row]
		if mask < 0 || mask >= (i64(1) << columns) do return -1
		masks[row] = int(mask)
	}
	start, goal := int(start_row) * columns + int(start_column), int(goal_row) * columns + int(goal_column)
	if (masks[start / columns] & (1 << (start % columns))) != 0 || (masks[goal / columns] & (1 << (goal % columns))) != 0 do return -1
	opened: [9]int
	parent: [9]int
	closed, in_open: [9]bool
	for cell := 0; cell < 9; cell += 1 do parent[cell] = -1
	open_count, found := 1, false
	opened[0], in_open[start] = start, true
	for open_count > 0 {
		for index := 1; index < open_count; index += 1 {
			current := opened[index]
			position := index
			for position > 0 && heuristic(opened[position - 1], goal, columns) > heuristic(current, goal, columns) {
				opened[position] = opened[position - 1]
				position -= 1
			}
			opened[position] = current
		}
		current := opened[0]
		for index := 1; index < open_count; index += 1 do opened[index - 1] = opened[index]
		open_count -= 1
		in_open[current] = false
		if current == goal { found = true; break }
		closed[current] = true
		row, column := current / columns, current % columns
		next_rows := [4]int{row - 1, row, row + 1, row}
		next_columns := [4]int{column, column - 1, column, column + 1}
		for direction := 0; direction < 4; direction += 1 {
			next_row, next_column := next_rows[direction], next_columns[direction]
			if next_row < 0 || next_row >= rows || next_column < 0 || next_column >= columns do continue
			child := next_row * columns + next_column
			if (masks[next_row] & (1 << next_column)) != 0 || closed[child] || in_open[child] do continue
			parent[child], opened[open_count] = current, child
			open_count += 1
			in_open[child] = true
		}
	}
	path: [9]int
	path_count := 0
	if found {
		current := goal
		for current >= 0 && path_count < 9 {
			path[path_count] = current
			path_count += 1
			current = parent[current]
		}
	} else {
		path[0], path_count = start, 1
	}
	packed: u64 = 0
	for index := 0; index < path_count; index += 1 do packed |= u64(path[path_count - 1 - index] + 1) << (4 * index)
	return i64((u64(path_count) << 36) | packed)
}
