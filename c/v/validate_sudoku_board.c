#include <stddef.h>
#include <stdint.h>

int64_t validate_sudoku_board(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length != 81) return -1;
    for (size_t i = 0; i < 81; ++i) {
        if (input[i] != '.' && (input[i] < '1' || input[i] > '9')) return -1;
    }
    if (output == NULL || capacity < 1) return -2;
    uint16_t rows[9] = {0}, columns[9] = {0}, boxes[9] = {0};
    uint8_t valid = 1;
    for (size_t i = 0; i < 81; ++i) {
        if (input[i] == '.') continue;
        const size_t row = i / 9, col = i % 9, box = (row / 3) * 3 + col / 3;
        const uint16_t bit = (uint16_t)(1u << (input[i] - '0'));
        if ((rows[row] & bit) || (columns[col] & bit) || (boxes[box] & bit)) valid = 0;
        rows[row] |= bit; columns[col] |= bit; boxes[box] |= bit;
    }
    output[0] = valid;
    return 1;
}
