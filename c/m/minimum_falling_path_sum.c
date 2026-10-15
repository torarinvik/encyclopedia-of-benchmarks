#include <stddef.h>
#include <stdint.h>

#define MAX_N 100
#define INVALID_RESULT INT64_C(-10001)

int64_t minimum_falling_path_sum(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || input[0] < 1 || input[0] > MAX_N) return INVALID_RESULT;
    const size_t n = (size_t)input[0];
    if (length != 1 + n * n) return INVALID_RESULT;
    for (size_t index = 0; index < n * n; ++index)
        if (input[1 + index] < -100 || input[1 + index] > 100) return INVALID_RESULT;

    int64_t costs[MAX_N];
    int64_t next_costs[MAX_N];
    for (size_t column = 0; column < n; ++column) costs[column] = input[1 + column];
    for (size_t row = 1; row < n; ++row) {
        for (size_t column = 0; column < n; ++column) {
            int64_t best = costs[column];
            if (column > 0 && costs[column - 1] < best) best = costs[column - 1];
            if (column + 1 < n && costs[column + 1] < best) best = costs[column + 1];
            next_costs[column] = best + input[1 + row * n + column];
        }
        for (size_t column = 0; column < n; ++column) costs[column] = next_costs[column];
    }
    int64_t minimum = costs[0];
    for (size_t column = 1; column < n; ++column)
        if (costs[column] < minimum) minimum = costs[column];
    return minimum;
}
