package n_in_a_row_board_status

import "core:c"

// Check full rows, columns, and diagonals for one square-board player.
@(export)
n_in_a_row_board_status :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 258 || values[0] < 2 || values[0] > 16 || (values[1] != 1 && values[1] != 2) do return -1
	size := c.size_t(values[0])
	player := values[1]
	if length != 2 + size * size do return -1
	for index: c.size_t = 0; index < size * size; index += 1 {
		if values[2 + index] < 0 || values[2 + index] > 2 do return -1
	}
	has_empty := false
	for row: c.size_t = 0; row < size; row += 1 {
		row_win := true
		for column: c.size_t = 0; column < size; column += 1 {
			cell := values[2 + row * size + column]
			if cell == 0 do has_empty = true
			if cell != player do row_win = false
		}
		if row_win do return 1
	}
	for column: c.size_t = 0; column < size; column += 1 {
		column_win := true
		for row: c.size_t = 0; row < size; row += 1 {
			if values[2 + row * size + column] != player do column_win = false
		}
		if column_win do return 1
	}
	main_diagonal_win := true
	ant_diagonal_win := true
	for index: c.size_t = 0; index < size; index += 1 {
		if values[2 + index * size + index] != player do main_diagonal_win = false
		if values[2 + index * size + size - 1 - index] != player do ant_diagonal_win = false
	}
	if main_diagonal_win || ant_diagonal_win do return 1
	if has_empty do return 0
	return 2
}
