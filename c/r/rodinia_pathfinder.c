/* Rodinia pathfinder bounded grid dynamic-programming core. */
#include <stddef.h>
#include <stdint.h>

#define PF_MAX_ROWS 32
#define PF_MAX_COLS 32
#define PF_MAX_CELLS (PF_MAX_ROWS * PF_MAX_COLS)

int64_t rodinia_pathfinder(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > 3 + PF_MAX_CELLS) return -1;
    const int64_t cols_value = input[0];
    const int64_t rows_value = input[1];
    const int64_t height_value = input[2];
    if (cols_value < 1 || cols_value > PF_MAX_COLS ||
        rows_value < 1 || rows_value > PF_MAX_ROWS ||
        height_value < 1 || height_value > 4) return -1;
    const size_t cols = (size_t)cols_value;
    const size_t rows = (size_t)rows_value;
    const size_t height = (size_t)height_value;
    const size_t cells = cols * rows;
    if (length != 3 + cells) return -1;
    for (size_t index = 0; index < cells; ++index)
        if (input[3 + index] < 0 || input[3 + index] > 9) return -1;

    int64_t previous[PF_MAX_COLS], current[PF_MAX_COLS];
    for (size_t col = 0; col < cols; ++col) previous[col] = input[3 + col];
    for (size_t first_row = 1; first_row < rows; first_row += height) {
        size_t steps = rows - first_row;
        if (steps > height) steps = height;
        for (size_t step = 0; step < steps; ++step) {
            const size_t row = first_row + step;
            for (size_t col = 0; col < cols; ++col) {
                int64_t best = previous[col];
                if (col > 0 && previous[col - 1] < best) best = previous[col - 1];
                if (col + 1 < cols && previous[col + 1] < best) best = previous[col + 1];
                current[col] = best + input[3 + row * cols + col];
            }
            for (size_t col = 0; col < cols; ++col) previous[col] = current[col];
        }
    }
    int64_t answer = previous[0];
    for (size_t col = 1; col < cols; ++col)
        if (previous[col] < answer) answer = previous[col];
    return answer;
}
