package matrix_based_game

import "core:c"

matrix_based_game_is_symbol :: proc(value: i64) -> bool {
	return (value >= 48 && value <= 57) ||
		(value >= 65 && value <= 90) ||
		(value >= 97 && value <= 122)
}

@(export)
matrix_based_game :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 194 do return -1
	n_value := values[0]
	if n_value < 1 || n_value > 8 do return -1
	n := int(n_value)
	cells := n * n
	move_count_index := 1 + cells
	if length < c.size_t(move_count_index + 1) do return -1
	move_count_value := values[move_count_index]
	if move_count_value < 0 || move_count_value > 64 do return -1
	move_count := int(move_count_value)
	if length != c.size_t(2 + cells + 2 * move_count) do return -1

	board: [64]i64
	visited: [64]bool
	stack: [64]int
	for index := 0; index < cells; index += 1 {
		if !matrix_based_game_is_symbol(values[1 + index]) do return -1
		board[index] = values[1 + index]
	}
	for movement := 0; movement < move_count; movement += 1 {
		x := values[move_count_index + 1 + 2 * movement]
		y := values[move_count_index + 2 + 2 * movement]
		if x < 0 || x >= n_value || y < 0 || y >= n_value do return -1
	}

	total_score := i64(0)
	for movement := 0; movement < move_count; movement += 1 {
		x := int(values[move_count_index + 1 + 2 * movement])
		y := int(values[move_count_index + 2 + 2 * movement])
		start_row := n - 1 - y
		start := start_row * n + x
		color := board[start]
		if color == -1 do continue

		for index := 0; index < cells; index += 1 {
			visited[index] = false
		}
		stack_count := 0
		stack[stack_count] = start
		stack_count += 1
		visited[start] = true
		component_size := i64(0)
		for stack_count > 0 {
			stack_count -= 1
			current := stack[stack_count]
			row := current / n
			col := current % n
			if row > 0 {
				neighbor := current - n
				if !visited[neighbor] && board[neighbor] == color {
					visited[neighbor] = true
					stack[stack_count] = neighbor
					stack_count += 1
				}
			}
			if row + 1 < n {
				neighbor := current + n
				if !visited[neighbor] && board[neighbor] == color {
					visited[neighbor] = true
					stack[stack_count] = neighbor
					stack_count += 1
				}
			}
			if col > 0 {
				neighbor := current - 1
				if !visited[neighbor] && board[neighbor] == color {
					visited[neighbor] = true
					stack[stack_count] = neighbor
					stack_count += 1
				}
			}
			if col + 1 < n {
				neighbor := current + 1
				if !visited[neighbor] && board[neighbor] == color {
					visited[neighbor] = true
					stack[stack_count] = neighbor
					stack_count += 1
				}
			}
			board[current] = -1
			component_size += 1
		}
		total_score += component_size * (component_size + 1) / 2

		for col := 0; col < n; col += 1 {
			target_row := n
			for row_cursor := n; row_cursor > 0; row_cursor -= 1 {
				row := row_cursor - 1
				value := board[row*n+col]
				if value != -1 {
					target_row -= 1
					board[target_row*n+col] = value
				}
			}
			for row := 0; row < target_row; row += 1 {
				board[row*n+col] = -1
			}
		}
		write_col := 0
		for col := 0; col < n; col += 1 {
			nonempty := false
			for row := 0; row < n; row += 1 {
				if board[row*n+col] != -1 do nonempty = true
			}
			if !nonempty do continue
			if write_col != col {
				for row := 0; row < n; row += 1 {
					board[row*n+write_col] = board[row*n+col]
				}
			}
			write_col += 1
		}
		for col := write_col; col < n; col += 1 {
			for row := 0; row < n; row += 1 {
				board[row*n+col] = -1
			}
		}
	}
	return total_score
}
