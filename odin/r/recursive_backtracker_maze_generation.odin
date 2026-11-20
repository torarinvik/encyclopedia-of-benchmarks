package recursive_backtracker_maze_generation

import "core:c"

@(export)
recursive_backtracker_maze_generation :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 68 do return -1
	rows_word, cols_word, start_word, draw_count := input[0], input[1], input[2], input[3]
	if rows_word < 1 || rows_word > 64 || cols_word < 1 || cols_word > 64 do return -1
	rows, cols := int(rows_word), int(cols_word)
	cells := rows * cols
	if cells > 64 || start_word < 0 || start_word >= i64(cells) ||
		draw_count != i64(cells - 1) || length != c.size_t(4 + cells - 1) do return -1
	for draw := 0; draw < cells - 1; draw += 1 {
		if input[4 + draw] < 0 || input[4 + draw] > 3 do return -1
	}

	visited: [64]bool = [64]bool{}
	walls: [64]u8
	stack: [64]int
	for cell := 0; cell < cells; cell += 1 do walls[cell] = 15
	depth, cursor := 1, 0
	stack[0] = int(start_word)
	visited[stack[0]] = true
	for depth > 0 {
		cell := stack[depth - 1]
		row, col := cell / cols, cell % cols
		next_cells: [4]int
		directions: [4]int
		count := 0
		if row > 0 && !visited[cell - cols] do { next_cells[count] = cell - cols; directions[count] = 0; count += 1 }
		if col + 1 < cols && !visited[cell + 1] do { next_cells[count] = cell + 1; directions[count] = 1; count += 1 }
		if row + 1 < rows && !visited[cell + cols] do { next_cells[count] = cell + cols; directions[count] = 2; count += 1 }
		if col > 0 && !visited[cell - 1] do { next_cells[count] = cell - 1; directions[count] = 3; count += 1 }
		if count == 0 { depth -= 1; continue }
		if cursor >= cells - 1 do return -1
		choice := int(input[4 + cursor])
		cursor += 1
		if choice >= count do return -1
		next, direction := next_cells[choice], directions[choice]
		visited[next] = true
		walls[cell] &= u8(15 - (1 << direction))
		walls[next] &= u8(15 - (1 << ((direction + 2) % 4)))
		stack[depth] = next
		depth += 1
	}
	if cursor != cells - 1 do return -1
	for cell := 0; cell < cells; cell += 1 do if !visited[cell] do return -1
	if output == nil || capacity < c.size_t(cells) do return -2
	for cell := 0; cell < cells; cell += 1 do output[cell] = walls[cell]
	return i64(cells)
}
