package grid_shortest_path_obstacle_elimination

import "core:c"

@(export)
grid_shortest_path_obstacle_elimination :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 3 || length > 40 do return -2
	rows, columns, budget := values[0], values[1], values[2]
	if rows < 1 || rows > 6 || columns < 1 || columns > 6 || budget < 0 || budget > 6 do return -2
	if length != c.size_t(3 + rows * columns) do return -2

	cell_count := int(rows * columns)
	cells: [36]i64
	for cell := 0; cell < cell_count; cell += 1 {
		value := values[3 + cell]
		if value != 0 && value != 1 do return -2
		cells[cell] = value
	}
	if cells[0] != 0 || cells[cell_count - 1] != 0 do return -2

	stride := int(budget + 1)
	state_count := cell_count * stride
	queue: [252]int
	distance: [252]i64
	for state := 0; state < state_count; state += 1 do distance[state] = -1
	start := int(budget)
	head, tail := 0, 1
	queue[0] = start
	distance[start] = 0

	for head < tail {
		state := queue[head]
		head += 1
		cell := state / stride
		remaining := state % stride
		if cell + 1 == cell_count do return distance[state]
		row := cell / int(columns)
		column := cell % int(columns)
		next_rows := [4]int{row - 1, row, row, row + 1}
		next_columns := [4]int{column, column - 1, column + 1, column}
		for direction := 0; direction < 4; direction += 1 {
			next_row, next_column := next_rows[direction], next_columns[direction]
			if next_row < 0 || next_row >= int(rows) || next_column < 0 || next_column >= int(columns) do continue
			next_cell := next_row * int(columns) + next_column
			next_remaining := remaining - int(cells[next_cell])
			if next_remaining < 0 do continue
			next_state := next_cell * stride + next_remaining
			if distance[next_state] != -1 do continue
			distance[next_state] = distance[state] + 1
			queue[tail] = next_state
			tail += 1
		}
	}
	return -1
}
