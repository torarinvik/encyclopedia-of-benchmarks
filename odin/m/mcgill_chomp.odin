package mcgill_chomp

CHOMP_COLUMNS :: 7

Solver :: struct {
	rows: int,
	powers: [CHOMP_COLUMNS]int,
	heights: [CHOMP_COLUMNS]int,
	values: []u8,
}

encode_state :: proc "contextless" (solver: ^Solver) -> int {
	encoded := 0
	for column := 0; column < CHOMP_COLUMNS; column += 1 {
		encoded += solver.heights[column] * solver.powers[column]
	}
	return encoded
}

evaluate_state :: proc "contextless" (solver: ^Solver) {
	state_id := encode_state(solver)
	has_move := false
	winning := false
	for row := 0; row < solver.rows; row += 1 {
		for column := 0; column < CHOMP_COLUMNS; column += 1 {
			child_id := 0
			changed := false
			for index := 0; index < CHOMP_COLUMNS; index += 1 {
				height := solver.heights[index]
				if index >= column && height > row {
					height = row
					changed = true
				}
				child_id += height * solver.powers[index]
			}
			if !changed do continue
			has_move = true
			if solver.values[child_id] == 0 do winning = true
		}
	}
	outcome := u8(0)
	if !has_move || winning do outcome = 1
	solver.values[state_id] = outcome
}

enumerate_states :: proc "contextless" (solver: ^Solver, column, minimum_height: int) {
	if column < 0 {
		evaluate_state(solver)
		return
	}
	for height := minimum_height; height <= solver.rows; height += 1 {
		solver.heights[column] = height
		enumerate_states(solver, column-1, height)
	}
}

@(export)
mcgill_chomp :: proc "c" (rows: i64) -> i64 {
	if rows != 7 && rows != 8 do return -1
	solver := Solver{rows = int(rows)}
	base := solver.rows + 1
	solver.powers[0] = 1
	for column := 1; column < CHOMP_COLUMNS; column += 1 {
		solver.powers[column] = solver.powers[column-1] * base
	}
	state_space := solver.powers[CHOMP_COLUMNS-1] * base
	solver.values = make([]u8, state_space)
	defer delete(solver.values)
	for state_id := 0; state_id < state_space; state_id += 1 { solver.values[state_id] = 0 }

	enumerate_states(&solver, CHOMP_COLUMNS-1, 0)
	full_board_id := 0
	for column := 0; column < CHOMP_COLUMNS; column += 1 {
		full_board_id += solver.rows * solver.powers[column]
	}
	return i64(solver.values[full_board_id])
}
