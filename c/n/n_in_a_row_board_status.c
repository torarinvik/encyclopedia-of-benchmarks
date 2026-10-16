/* Check full rows, columns, and diagonals for one square-board player. */
#include <stddef.h>
#include <stdint.h>

int64_t n_in_a_row_board_status(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 258) return -1;
    if (values[0] < 2 || values[0] > 16 || (values[1] != 1 && values[1] != 2)) return -1;
    const size_t size = (size_t)values[0];
    if (length != 2 + size * size) return -1;
    const int64_t player = values[1];
    for (size_t index = 0; index < size * size; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 2) return -1;

    int has_empty = 0;
    for (size_t row = 0; row < size; ++row) {
        int row_win = 1;
        for (size_t column = 0; column < size; ++column) {
            const int64_t cell = values[2 + row * size + column];
            if (cell == 0) has_empty = 1;
            if (cell != player) row_win = 0;
        }
        if (row_win) return 1;
    }
    for (size_t column = 0; column < size; ++column) {
        int column_win = 1;
        for (size_t row = 0; row < size; ++row)
            if (values[2 + row * size + column] != player) column_win = 0;
        if (column_win) return 1;
    }
    int main_diagonal_win = 1;
    int anti_diagonal_win = 1;
    for (size_t index = 0; index < size; ++index) {
        if (values[2 + index * size + index] != player) main_diagonal_win = 0;
        if (values[2 + index * size + (size - 1 - index)] != player) anti_diagonal_win = 0;
    }
    if (main_diagonal_win || anti_diagonal_win) return 1;
    return has_empty ? 0 : 2;
}
