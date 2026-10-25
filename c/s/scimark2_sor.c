#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 8
#define MAX_COLS 8
#define MAX_INPUT (3 + MAX_ROWS * MAX_COLS)

int64_t scimark2_sor(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 2 || input[0] > MAX_ROWS || input[1] < 2 || input[1] > MAX_COLS ||
        input[2] < 0 || input[2] > 8) return -1;
    const int rows = (int)input[0];
    const int cols = (int)input[1];
    const int iterations = (int)input[2];
    if (length != 3 + (size_t)rows * (size_t)cols) return -1;
    int64_t grid[MAX_ROWS * MAX_COLS];
    for (int i = 0; i < rows * cols; ++i) {
        const int64_t value = input[3 + (size_t)i];
        if (value < -1000 || value > 1000) return -1;
        grid[i] = value;
    }

    for (int pass = 0; pass < iterations; ++pass) {
        for (int row = 1; row < rows - 1; ++row) {
            for (int col = 1; col < cols - 1; ++col) {
                const int index = row * cols + col;
                const int64_t neighbors = grid[index - cols] + grid[index + cols] +
                                          grid[index - 1] + grid[index + 1];
                const int64_t numerator = 1250 * neighbors - 1000 * grid[index];
                grid[index] = numerator / 4000;
            }
        }
    }

    int64_t checksum = 0;
    for (int i = 0; i < rows * cols; ++i) checksum += (int64_t)(i + 1) * grid[i];
    return checksum;
}
