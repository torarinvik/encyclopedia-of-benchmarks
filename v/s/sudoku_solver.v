module sudoku_solver

fn search_sudoku(mut board []i64, mut rows []u16, mut columns []u16, mut boxes []u16, position int) bool {
	mut current := position
	for current < 81 && board[current] != 0 { current++ }
	if current == 81 { return true }
	row := current / 9
	column := current % 9
	box_index := (row / 3) * 3 + column / 3
	for digit in 1 .. 10 {
		bit := u16(1 << digit)
		if rows[row] & bit != 0 || columns[column] & bit != 0 || boxes[box_index] & bit != 0 { continue }
		board[current] = i64(digit)
		rows[row] |= bit
		columns[column] |= bit
		boxes[box_index] |= bit
		if search_sudoku(mut board, mut rows, mut columns, mut boxes, current + 1) { return true }
		board[current] = 0
		rows[row] ^= bit
		columns[column] ^= bit
		boxes[box_index] ^= bit
	}
	return false
}

// Row-major backtracking Sudoku solver with row, column, and box masks.
@[export: 'sudoku_solver']
pub fn sudoku_solver(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 81 { return -1 }
	unsafe {
		mut board := []i64{len: 81}
		mut rows := []u16{len: 9}
		mut columns := []u16{len: 9}
		mut boxes := []u16{len: 9}
		for position in 0 .. 81 {
			digit := values[position]
			if digit < 0 || digit > 9 { return -1 }
			board[position] = digit
			if digit == 0 { continue }
			row := position / 9
			column := position % 9
			box_index := (row / 3) * 3 + column / 3
			bit := u16(1 << int(digit))
			if rows[row] & bit != 0 || columns[column] & bit != 0 || boxes[box_index] & bit != 0 { return -1 }
			rows[row] |= bit
			columns[column] |= bit
			boxes[box_index] |= bit
		}
		if output_capacity < 324 { return -2 }
		if !search_sudoku(mut board, mut rows, mut columns, mut boxes, 0) { return -1 }
		for position in 0 .. 81 {
			bits := u32(i32(board[position]))
			for byte in 0 .. 4 {
				output[position * 4 + byte] = u8((bits >> u32(byte * 8)) & 255)
			}
		}
		return 81
	}
}
