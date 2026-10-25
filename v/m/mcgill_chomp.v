module mcgill_chomp

const chomp_columns = 7

struct ChompSolver {
	rows int
	mut:
		powers [chomp_columns]int
		heights [chomp_columns]int
		values []u8
}

fn encode_state(solver &ChompSolver) int {
	mut encoded := 0
	for column in 0 .. chomp_columns {
		encoded += solver.heights[column] * solver.powers[column]
	}
	return encoded
}

fn evaluate_state(mut solver ChompSolver) {
	state_id := encode_state(solver)
	mut has_move := false
	mut winning := false
	for row in 0 .. solver.rows {
		for column in 0 .. chomp_columns {
			mut child_id := 0
			mut changed := false
			for index in 0 .. chomp_columns {
				mut height := solver.heights[index]
				if index >= column && height > row {
					height = row
					changed = true
				}
				child_id += height * solver.powers[index]
			}
			if !changed { continue }
			has_move = true
			if solver.values[child_id] == u8(0) { winning = true }
		}
	}
	mut outcome := u8(0)
	if !has_move || winning { outcome = u8(1) }
	solver.values[state_id] = outcome
}

fn enumerate_states(mut solver ChompSolver, column int, minimum_height int) {
	if column < 0 {
		evaluate_state(mut solver)
		return
	}
	for height in minimum_height .. solver.rows + 1 {
		solver.heights[column] = height
		enumerate_states(mut solver, column - 1, height)
	}
}

@[export: 'mcgill_chomp']
pub fn mcgill_chomp(rows i64) i64 {
	if rows != 7 && rows != 8 { return -1 }
	mut solver := ChompSolver{rows: int(rows)}
	base := solver.rows + 1
	solver.powers[0] = 1
	for column in 1 .. chomp_columns {
		solver.powers[column] = solver.powers[column - 1] * base
	}
	state_space := solver.powers[chomp_columns - 1] * base
	solver.values = []u8{len: state_space, init: 0}
	enumerate_states(mut solver, chomp_columns - 1, 0)
	mut full_board_id := 0
	for column in 0 .. chomp_columns {
		full_board_id += solver.rows * solver.powers[column]
	}
	return i64(solver.values[full_board_id])
}
