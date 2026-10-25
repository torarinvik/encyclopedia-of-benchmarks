module mcgill_chomp;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);

const int COLUMNS = 7;

struct Solver {
    int rows;
    usz[7] powers;
    int[7] heights;
    u8* values;
}

fn usz encode_state(Solver* solver) {
    usz encoded = 0;
    for (int column = 0; column < COLUMNS; ++column)
        encoded += (usz)solver.heights[column] * solver.powers[column];
    return encoded;
}

fn void evaluate_state(Solver* solver) {
    usz state_id = encode_state(solver);
    bool has_move = false;
    bool winning = false;
    for (int row = 0; row < solver.rows; ++row) {
        for (int column = 0; column < COLUMNS; ++column) {
            usz child_id = 0;
            bool changed = false;
            for (int index = 0; index < COLUMNS; ++index) {
                int height = solver.heights[index];
                if (index >= column && height > row) {
                    height = row;
                    changed = true;
                }
                child_id += (usz)height * solver.powers[index];
            }
            if (!changed) continue;
            has_move = true;
            if (solver.values[child_id] == 0) winning = true;
        }
    }
    u8 outcome = 0;
    if (!has_move || winning) outcome = 1;
    solver.values[state_id] = outcome;
}

fn void enumerate_states(Solver* solver, int column, int minimum_height) {
    if (column < 0) {
        evaluate_state(solver);
        return;
    }
    for (int height = minimum_height; height <= solver.rows; ++height) {
        solver.heights[column] = height;
        enumerate_states(solver, column - 1, height);
    }
}

fn long mcgill_chomp(long rows) @export("mcgill_chomp") {
    if (rows != 7 && rows != 8) return -1;
    Solver solver = {0};
    solver.rows = (int)rows;
    usz base = (usz)(solver.rows + 1);
    solver.powers[0] = 1;
    for (int column = 1; column < COLUMNS; ++column)
        solver.powers[column] = solver.powers[column - 1] * base;
    usz state_space = solver.powers[COLUMNS - 1] * base;
    solver.values = (u8*)calloc(state_space, sizeof(u8));
    if (solver.values == null) return -1;
    defer free(solver.values);

    enumerate_states(&solver, COLUMNS - 1, 0);
    usz full_board_id = 0;
    for (int column = 0; column < COLUMNS; ++column)
        full_board_id += (usz)solver.rows * solver.powers[column];
    return (long)solver.values[full_board_id];
}
