// Solve a 9x9 Sudoku with row-major backtracking and occupancy masks.
#include <cstddef>
#include <cstdint>

namespace {
int search(std::int64_t board[81], std::uint16_t rows[9], std::uint16_t columns[9],
           std::uint16_t boxes[9], std::size_t position) noexcept {
    while (position < 81 && board[position] != 0) ++position;
    if (position == 81) return 1;
    const auto row = position / 9, column = position % 9;
    const auto box = (row / 3) * 3 + column / 3;
    for (std::int64_t digit = 1; digit <= 9; ++digit) {
        const auto bit = static_cast<std::uint16_t>(1u << digit);
        if ((rows[row] & bit) || (columns[column] & bit) || (boxes[box] & bit)) continue;
        board[position] = digit;
        rows[row] |= bit; columns[column] |= bit; boxes[box] |= bit;
        if (search(board, rows, columns, boxes, position + 1)) return 1;
        board[position] = 0;
        rows[row] ^= bit; columns[column] ^= bit; boxes[box] ^= bit;
    }
    return 0;
}
}

extern "C" std::int64_t sudoku_solver(const std::int64_t *values, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length != 81 || values == nullptr) return -1;
    std::int64_t board[81];
    std::uint16_t rows[9]{}, columns[9]{}, boxes[9]{};
    for (std::size_t position = 0; position < 81; ++position) {
        const auto digit = values[position];
        if (digit < 0 || digit > 9) return -1;
        board[position] = digit;
        if (digit == 0) continue;
        const auto row = position / 9, column = position % 9;
        const auto box = (row / 3) * 3 + column / 3;
        const auto bit = static_cast<std::uint16_t>(1u << digit);
        if ((rows[row] & bit) || (columns[column] & bit) || (boxes[box] & bit)) return -1;
        rows[row] |= bit; columns[column] |= bit; boxes[box] |= bit;
    }
    if (output_capacity < 324 || output == nullptr) return -2;
    if (!search(board, rows, columns, boxes, 0)) return -1;
    for (std::size_t position = 0; position < 81; ++position) {
        const auto digit = static_cast<std::uint32_t>(board[position]);
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[position * 4 + byte] = static_cast<std::uint8_t>(digit >> (byte * 8));
    }
    return 81;
}
