#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

enum { CHOMP_COLUMNS = 7 };

typedef struct {
    int rows;
    size_t powers[CHOMP_COLUMNS];
    int heights[CHOMP_COLUMNS];
    uint8_t *values;
} ChompSolver;

static size_t encode_state(const ChompSolver *solver) {
    size_t encoded = 0;
    for (int column = 0; column < CHOMP_COLUMNS; ++column)
        encoded += (size_t)solver->heights[column] * solver->powers[column];
    return encoded;
}

static void evaluate_state(ChompSolver *solver) {
    const size_t state_id = encode_state(solver);
    int has_move = 0;
    int winning = 0;
    for (int row = 0; row < solver->rows; ++row) {
        for (int column = 0; column < CHOMP_COLUMNS; ++column) {
            size_t child_id = 0;
            int changed = 0;
            for (int index = 0; index < CHOMP_COLUMNS; ++index) {
                int height = solver->heights[index];
                if (index >= column && height > row) {
                    height = row;
                    changed = 1;
                }
                child_id += (size_t)height * solver->powers[index];
            }
            if (!changed) continue;
            has_move = 1;
            if (solver->values[child_id] == 0) winning = 1;
        }
    }
    solver->values[state_id] = (uint8_t)(has_move ? winning : 1);
}

static void enumerate_states(ChompSolver *solver, int column, int minimum_height) {
    if (column < 0) {
        evaluate_state(solver);
        return;
    }
    for (int height = minimum_height; height <= solver->rows; ++height) {
        solver->heights[column] = height;
        enumerate_states(solver, column - 1, height);
    }
}

int64_t mcgill_chomp(int64_t rows) {
    if (rows != 7 && rows != 8) return -1;
    ChompSolver solver = {0};
    solver.rows = (int)rows;
    const size_t base = (size_t)solver.rows + 1;
    solver.powers[0] = 1;
    for (int column = 1; column < CHOMP_COLUMNS; ++column)
        solver.powers[column] = solver.powers[column - 1] * base;
    const size_t state_space = solver.powers[CHOMP_COLUMNS - 1] * base;
    solver.values = (uint8_t *)calloc(state_space, sizeof(uint8_t));
    if (solver.values == NULL) return -1;

    enumerate_states(&solver, CHOMP_COLUMNS - 1, 0);
    size_t full_board_id = 0;
    for (int column = 0; column < CHOMP_COLUMNS; ++column)
        full_board_id += (size_t)solver.rows * solver.powers[column];
    const int64_t result = solver.values[full_board_id];
    free(solver.values);
    return result;
}
