module recursive_backtracker_maze_generation

@[export: 'recursive_backtracker_maze_generation']
pub fn recursive_backtracker_maze_generation(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 4 || length > 68 { return -1 }
	unsafe {
		rows_word, cols_word, start_word, draw_count := input[0], input[1], input[2], input[3]
		if rows_word < 1 || rows_word > 64 || cols_word < 1 || cols_word > 64 { return -1 }
		rows, cols := int(rows_word), int(cols_word)
		cells := rows * cols
		if cells > 64 || start_word < 0 || start_word >= i64(cells) || draw_count != i64(cells - 1) || length != usize(4 + cells - 1) { return -1 }
		for draw in 0 .. cells - 1 { if input[4 + draw] < 0 || input[4 + draw] > 3 { return -1 } }

		mut visited := [64]bool{}
		mut walls := [64]u8{}
		mut stack := [64]int{}
		for cell in 0 .. cells { walls[cell] = 15 }
		mut depth, mut cursor := 1, 0
		stack[0] = int(start_word)
		visited[stack[0]] = true
		for depth > 0 {
			cell := stack[depth - 1]
			row, col := cell / cols, cell % cols
			mut next_cells := [4]int{}
			mut directions := [4]int{}
			mut count := 0
			if row > 0 && !visited[cell - cols] { next_cells[count] = cell - cols; directions[count] = 0; count++ }
			if col + 1 < cols && !visited[cell + 1] { next_cells[count] = cell + 1; directions[count] = 1; count++ }
			if row + 1 < rows && !visited[cell + cols] { next_cells[count] = cell + cols; directions[count] = 2; count++ }
			if col > 0 && !visited[cell - 1] { next_cells[count] = cell - 1; directions[count] = 3; count++ }
			if count == 0 { depth--; continue }
			if cursor >= cells - 1 { return -1 }
			choice := int(input[4 + cursor])
			cursor++
			if choice >= count { return -1 }
			next, direction := next_cells[choice], directions[choice]
			visited[next] = true
			walls[cell] &= u8(15 - (1 << direction))
			walls[next] &= u8(15 - (1 << ((direction + 2) % 4)))
			stack[depth] = next
			depth++
		}
		if cursor != cells - 1 { return -1 }
		for cell in 0 .. cells { if !visited[cell] { return -1 } }
		if output == nil || capacity < usize(cells) { return -2 }
		for cell in 0 .. cells { output[cell] = walls[cell] }
		return i64(cells)
	}
}
