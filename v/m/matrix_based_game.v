module matrix_based_game

fn matrix_based_game_is_symbol(value i64) bool {
	return (value >= 48 && value <= 57) ||
		(value >= 65 && value <= 90) ||
		(value >= 97 && value <= 122)
}

@[export: 'matrix_based_game']
pub fn matrix_based_game(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > 194 { return -1 }
	n_value := unsafe { values[0] }
	if n_value < 1 || n_value > 8 { return -1 }
	n := int(n_value)
	cells := n * n
	move_count_index := 1 + cells
	if length < usize(move_count_index + 1) { return -1 }
	move_count_value := unsafe { values[move_count_index] }
	if move_count_value < 0 || move_count_value > 64 { return -1 }
	move_count := int(move_count_value)
	if length != usize(2 + cells + 2 * move_count) { return -1 }

	mut board := [64]i64{}
	mut visited := [64]bool{}
	mut stack := [64]int{}
	for index in 0 .. cells {
		cell := unsafe { values[1 + index] }
		if !matrix_based_game_is_symbol(cell) { return -1 }
		board[index] = cell
	}
	for movement in 0 .. move_count {
		x := unsafe { values[move_count_index + 1 + 2 * movement] }
		y := unsafe { values[move_count_index + 2 + 2 * movement] }
		if x < 0 || x >= n_value || y < 0 || y >= n_value { return -1 }
	}

	mut total_score := i64(0)
	for movement in 0 .. move_count {
		x := int(unsafe { values[move_count_index + 1 + 2 * movement] })
		y := int(unsafe { values[move_count_index + 2 + 2 * movement] })
		start_row := n - 1 - y
		start := start_row * n + x
		color := board[start]
		if color == -1 { continue }

		for index in 0 .. cells { visited[index] = false }
		mut stack_count := 0
		stack[stack_count] = start
		stack_count++
		visited[start] = true
		mut component_size := i64(0)
		for stack_count > 0 {
			stack_count--
			current := stack[stack_count]
			row := current / n
			col := current % n
			if row > 0 {
				neighbor := current - n
				if !visited[neighbor] && board[neighbor] == color {
					visited[neighbor] = true
					stack[stack_count] = neighbor
					stack_count++
				}
			}
			if row + 1 < n {
				neighbor := current + n
				if !visited[neighbor] && board[neighbor] == color {
					visited[neighbor] = true
					stack[stack_count] = neighbor
					stack_count++
				}
			}
			if col > 0 {
				neighbor := current - 1
				if !visited[neighbor] && board[neighbor] == color {
					visited[neighbor] = true
					stack[stack_count] = neighbor
					stack_count++
				}
			}
			if col + 1 < n {
				neighbor := current + 1
				if !visited[neighbor] && board[neighbor] == color {
					visited[neighbor] = true
					stack[stack_count] = neighbor
					stack_count++
				}
			}
			board[current] = -1
			component_size++
		}
		total_score += component_size * (component_size + 1) / 2

		for col in 0 .. n {
			mut target_row := n
			mut row_cursor := n
			for row_cursor > 0 {
				row_cursor--
				value := board[row_cursor * n + col]
				if value != -1 {
					target_row--
					board[target_row * n + col] = value
				}
			}
			for row in 0 .. target_row { board[row * n + col] = -1 }
		}
		mut write_col := 0
		for col in 0 .. n {
			mut nonempty := false
			for row in 0 .. n {
				if board[row * n + col] != -1 { nonempty = true }
			}
			if !nonempty { continue }
			if write_col != col {
				for row in 0 .. n { board[row * n + write_col] = board[row * n + col] }
			}
			write_col++
		}
		for col in write_col .. n {
			for row in 0 .. n { board[row * n + col] = -1 }
		}
	}
	return total_score
}
