#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr int columns = 7;

struct Solver {
    int rows;
    std::array<std::size_t, columns> powers{};
    std::array<int, columns> heights{};
    std::vector<std::uint8_t> values;
};

std::size_t encode_state(const Solver& solver) {
    std::size_t encoded = 0;
    for (int column = 0; column < columns; ++column)
        encoded += static_cast<std::size_t>(solver.heights[column]) * solver.powers[column];
    return encoded;
}

void evaluate_state(Solver& solver) {
    const std::size_t state_id = encode_state(solver);
    bool has_move = false;
    bool winning = false;
    for (int row = 0; row < solver.rows; ++row) {
        for (int column = 0; column < columns; ++column) {
            std::size_t child_id = 0;
            bool changed = false;
            for (int index = 0; index < columns; ++index) {
                int height = solver.heights[index];
                if (index >= column && height > row) {
                    height = row;
                    changed = true;
                }
                child_id += static_cast<std::size_t>(height) * solver.powers[index];
            }
            if (!changed) continue;
            has_move = true;
            if (solver.values[child_id] == 0) winning = true;
        }
    }
    solver.values[state_id] = static_cast<std::uint8_t>(has_move ? winning : true);
}

void enumerate_states(Solver& solver, int column, int minimum_height) {
    if (column < 0) {
        evaluate_state(solver);
        return;
    }
    for (int height = minimum_height; height <= solver.rows; ++height) {
        solver.heights[column] = height;
        enumerate_states(solver, column - 1, height);
    }
}
}

extern "C" std::int64_t mcgill_chomp(std::int64_t rows) {
    if (rows != 7 && rows != 8) return -1;
    Solver solver{};
    solver.rows = static_cast<int>(rows);
    const std::size_t base = static_cast<std::size_t>(solver.rows + 1);
    solver.powers[0] = 1;
    for (int column = 1; column < columns; ++column)
        solver.powers[column] = solver.powers[column - 1] * base;
    const std::size_t state_space = solver.powers[columns - 1] * base;
    solver.values.assign(state_space, 0);

    enumerate_states(solver, columns - 1, 0);
    std::size_t full_board_id = 0;
    for (int column = 0; column < columns; ++column)
        full_board_id += static_cast<std::size_t>(solver.rows) * solver.powers[column];
    return solver.values[full_board_id];
}
