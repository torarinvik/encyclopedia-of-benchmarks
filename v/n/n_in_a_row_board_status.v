module n_in_a_row_board_status

// Check full rows, columns, and diagonals for one square-board player.
@[export: 'n_in_a_row_board_status']
pub fn n_in_a_row_board_status(values &i64, length usize) i64 {
	unsafe {
		if length < 2 || length > 258 || values[0] < 2 || values[0] > 16 || (values[1] != 1 && values[1] != 2) { return -1 }
		size := usize(values[0])
		player := values[1]
		if length != 2 + size * size { return -1 }
		for index := usize(0); index < size * size; index++ {
			if values[2 + index] < 0 || values[2 + index] > 2 { return -1 }
		}
		mut has_empty := false
		for row := usize(0); row < size; row++ {
			mut row_win := true
			for column := usize(0); column < size; column++ {
				cell := values[2 + row * size + column]
				if cell == 0 { has_empty = true }
				if cell != player { row_win = false }
			}
			if row_win { return 1 }
		}
		for column := usize(0); column < size; column++ {
			mut column_win := true
			for row := usize(0); row < size; row++ {
				if values[2 + row * size + column] != player { column_win = false }
			}
			if column_win { return 1 }
		}
		mut main_diagonal_win := true
		mut anti_diagonal_win := true
		for index := usize(0); index < size; index++ {
			if values[2 + index * size + index] != player { main_diagonal_win = false }
			if values[2 + index * size + size - 1 - index] != player { anti_diagonal_win = false }
		}
		if main_diagonal_win || anti_diagonal_win { return 1 }
		return if has_empty { 0 } else { 2 }
	}
}
