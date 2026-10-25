const COLUMNS: usize = 7;

struct Solver {
    rows: usize,
    powers: [usize; COLUMNS],
    heights: [usize; COLUMNS],
    values: Vec<u8>,
}

fn encode_state(solver: &Solver) -> usize {
    let mut encoded = 0;
    for column in 0..COLUMNS {
        encoded += solver.heights[column] * solver.powers[column];
    }
    encoded
}

fn evaluate_state(solver: &mut Solver) {
    let state_id = encode_state(solver);
    let mut has_move = false;
    let mut winning = false;
    for row in 0..solver.rows {
        for column in 0..COLUMNS {
            let mut child_id = 0;
            let mut changed = false;
            for index in 0..COLUMNS {
                let mut height = solver.heights[index];
                if index >= column && height > row {
                    height = row;
                    changed = true;
                }
                child_id += height * solver.powers[index];
            }
            if !changed { continue; }
            has_move = true;
            if solver.values[child_id] == 0 { winning = true; }
        }
    }
    solver.values[state_id] = if has_move { u8::from(winning) } else { 1 };
}

fn enumerate_states(solver: &mut Solver, column: isize, minimum_height: usize) {
    if column < 0 {
        evaluate_state(solver);
        return;
    }
    for height in minimum_height..=solver.rows {
        solver.heights[column as usize] = height;
        enumerate_states(solver, column - 1, height);
    }
}

#[no_mangle]
pub extern "C" fn mcgill_chomp(rows: i64) -> i64 {
    if rows != 7 && rows != 8 { return -1; }
    let rows = rows as usize;
    let base = rows + 1;
    let mut powers = [0usize; COLUMNS];
    powers[0] = 1;
    for column in 1..COLUMNS { powers[column] = powers[column - 1] * base; }
    let state_space = powers[COLUMNS - 1] * base;
    let mut solver = Solver {
        rows,
        powers,
        heights: [0; COLUMNS],
        values: vec![0; state_space],
    };

    enumerate_states(&mut solver, COLUMNS as isize - 1, 0);
    let mut full_board_id = 0;
    for column in 0..COLUMNS { full_board_id += rows * solver.powers[column]; }
    i64::from(solver.values[full_board_id])
}
