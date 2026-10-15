/* Solve a 9x9 Sudoku with row-major backtracking and occupancy masks. */
#include <stddef.h>
#include <stdint.h>

static int sudoku_search(int64_t board[81], uint16_t rows[9], uint16_t columns[9],
                         uint16_t boxes[9], size_t position)
{
    while (position < 81 && board[position] != 0) ++position;
    if (position == 81) return 1;
    const size_t row = position / 9;
    const size_t column = position % 9;
    const size_t box = (row / 3) * 3 + column / 3;
    for (int digit = 1; digit <= 9; ++digit) {
        const uint16_t bit = (uint16_t)(1u << digit);
        if ((rows[row] & bit) || (columns[column] & bit) || (boxes[box] & bit)) continue;
        board[position] = digit;
        rows[row] |= bit; columns[column] |= bit; boxes[box] |= bit;
        if (sudoku_search(board, rows, columns, boxes, position + 1)) return 1;
        board[position] = 0;
        rows[row] ^= bit; columns[column] ^= bit; boxes[box] ^= bit;
    }
    return 0;
}

int64_t sudoku_solver(const int64_t *values, size_t length,
                     uint8_t *output, size_t output_capacity)
{
    if (length != 81 || values == NULL) return -1;
    int64_t board[81];
    uint16_t rows[9] = {0}, columns[9] = {0}, boxes[9] = {0};
    for (size_t position = 0; position < 81; ++position) {
        const int64_t digit = values[position];
        if (digit < 0 || digit > 9) return -1;
        board[position] = digit;
        if (digit == 0) continue;
        const size_t row = position / 9, column = position % 9;
        const size_t box = (row / 3) * 3 + column / 3;
        const uint16_t bit = (uint16_t)(1u << digit);
        if ((rows[row] & bit) || (columns[column] & bit) || (boxes[box] & bit)) return -1;
        rows[row] |= bit; columns[column] |= bit; boxes[box] |= bit;
    }
    if (output_capacity < 324 || output == NULL) return -2;
    if (!sudoku_search(board, rows, columns, boxes, 0)) return -1;
    for (size_t position = 0; position < 81; ++position) {
        const uint32_t digit = (uint32_t)board[position];
        for (size_t byte = 0; byte < 4; ++byte)
            output[position * 4 + byte] = (uint8_t)(digit >> (byte * 8));
    }
    return 81;
}
