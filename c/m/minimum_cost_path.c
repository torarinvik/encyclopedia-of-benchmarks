#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN
#define MAX_DIM 16

int64_t minimum_cost_path(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3) return INVALID_RESULT;
    int64_t rows_v = values[0], cols_v = values[1];
    if (rows_v < 1 || rows_v > MAX_DIM || cols_v < 1 || cols_v > MAX_DIM) return INVALID_RESULT;
    size_t rows = (size_t)rows_v, cols = (size_t)cols_v;
    if (length != 2 + rows * cols) return INVALID_RESULT;
    int64_t dp[MAX_DIM][MAX_DIM];
    for (size_t r = 0; r < rows; ++r) for (size_t c = 0; c < cols; ++c) {
        int64_t x = values[2 + r * cols + c];
        if (x < INT32_MIN || x > INT32_MAX) return INVALID_RESULT;
        dp[r][c] = x;
    }
    for (size_t c = 1; c < cols; ++c) dp[0][c] += dp[0][c - 1];
    for (size_t r = 1; r < rows; ++r) dp[r][0] += dp[r - 1][0];
    for (size_t r = 1; r < rows; ++r) for (size_t c = 1; c < cols; ++c)
        dp[r][c] += dp[r - 1][c] < dp[r][c - 1] ? dp[r - 1][c] : dp[r][c - 1];
    return dp[rows - 1][cols - 1];
}
