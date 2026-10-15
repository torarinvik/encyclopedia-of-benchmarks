module validate_sudoku_board

@[export: 'validate_sudoku_board']
pub fn validate_sudoku_board(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 81 { return -1 }
	unsafe {
		for i in 0 .. 81 {
			value := input[i]
			if value != i64(`.`) && (value < i64(`1`) || value > i64(`9`)) { return -1 }
		}
		if output == nil || capacity < 1 { return -2 }
		mut rows := []u16{len: 9}
		mut columns := []u16{len: 9}
		mut boxes := []u16{len: 9}
		mut valid := true
		for i in 0 .. 81 {
			value := input[i]
			if value == i64(`.`) { continue }
			row := i / 9; col := i % 9; box := (row / 3) * 3 + col / 3
			bit := u16(1 << (value - i64(`0`)))
			if rows[row] & bit != 0 || columns[col] & bit != 0 || boxes[box] & bit != 0 { valid = false }
			rows[row] |= bit; columns[col] |= bit; boxes[box] |= bit
		}
		if valid { output[0] = 1 } else { output[0] = 0 }
		return 1
	}
}
