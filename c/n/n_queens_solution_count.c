#include <stddef.h>
#include <stdint.h>

#define MAX_N 8

static int64_t count_from(int n, int column, uint8_t *rows, uint8_t *diag_down, uint8_t *diag_up) {
    if (column == n) return 1;
    int64_t count = 0;
    for (int row = 0; row < n; ++row) {
        int down = row - column + n - 1;
        int up = row + column;
        if (!rows[row] && !diag_down[down] && !diag_up[up]) {
            rows[row] = diag_down[down] = diag_up[up] = 1;
            count += count_from(n, column + 1, rows, diag_down, diag_up);
            rows[row] = diag_down[down] = diag_up[up] = 0;
        }
    }
    return count;
}

int64_t n_queens_solution_count(const int64_t *values, size_t length) {
    if (values == NULL || length != 1 || values[0] < 0 || values[0] > MAX_N) return -1;
    uint8_t rows[MAX_N] = {0}, diag_down[2 * MAX_N] = {0}, diag_up[2 * MAX_N] = {0};
    return count_from((int)values[0], 0, rows, diag_down, diag_up);
}
