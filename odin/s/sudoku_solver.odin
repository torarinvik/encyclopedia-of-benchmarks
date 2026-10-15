package sudoku_solver

import "core:c"

search_sudoku :: proc "contextless" (board: [^]i64, rows, columns, boxes: [^]i64,
		position: c.size_t) -> bool {
	current := position
	for current < 81 && board[current] != 0 do current += 1
	if current == 81 do return true
	row := current / 9
	column := current % 9
	box := (row / 3) * 3 + column / 3
	for digit := i64(1); digit <= 9; digit += 1 {
		bit := i64(1) << u64(digit)
		if (rows[row] & bit) != 0 || (columns[column] & bit) != 0 || (boxes[box] & bit) != 0 do continue
		board[current] = digit
		rows[row] |= bit; columns[column] |= bit; boxes[box] |= bit
		if search_sudoku(board, rows, columns, boxes, current+1) do return true
		board[current] = 0
		rows[row] = rows[row] & ~bit
		columns[column] = columns[column] & ~bit
		boxes[box] = boxes[box] & ~bit
	}
	return false
}

// Row-major backtracking Sudoku solver with row, column, and box masks.
@(export)
sudoku_solver :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length != 81 || values == nil do return -1
	board: [81]i64
	rows, columns, boxes: [9]i64
	for position := c.size_t(0); position < 81; position += 1 {
		digit := values[position]
		if digit < 0 || digit > 9 do return -1
		board[position] = digit
		if digit == 0 do continue
		row := position / 9
		column := position % 9
		box := (row / 3) * 3 + column / 3
		bit := i64(1) << u64(digit)
		if (rows[row] & bit) != 0 || (columns[column] & bit) != 0 || (boxes[box] & bit) != 0 do return -1
		rows[row] |= bit; columns[column] |= bit; boxes[box] |= bit
	}
	if output_capacity < 324 || output == nil do return -2
	if !search_sudoku(&board[0], &rows[0], &columns[0], &boxes[0], 0) do return -1
	for position := c.size_t(0); position < 81; position += 1 {
		bits := u64(board[position])
		for byte := c.size_t(0); byte < 4; byte += 1 {
			output[position*4+byte] = u8((bits >> (byte*8)) & 255)
		}
	}
	return 81
}
