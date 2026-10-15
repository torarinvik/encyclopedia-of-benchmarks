package validate_sudoku_board

import "core:c"

@(export)
validate_sudoku_board :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 81 do return -1
	for i: usize = 0; i < 81; i += 1 {
		value := input[i]
		if value != i64('.') && (value < i64('1') || value > i64('9')) do return -1
	}
	if output == nil || capacity < 1 do return -2
	var rows, columns, boxes: [9]u16
	valid := true
	for i: usize = 0; i < 81; i += 1 {
		value := input[i]
		if value == i64('.') do continue
		row, col := i / 9, i % 9
		box := (row / 3) * 3 + col / 3
		bit := u16(1) << u16(value - i64('0'))
		if rows[row] & bit != 0 || columns[col] & bit != 0 || boxes[box] & bit != 0 do valid = false
		rows[row] |= bit; columns[col] |= bit; boxes[box] |= bit
	}
	if valid do output[0] = 1 else output[0] = 0
	return 1
}
