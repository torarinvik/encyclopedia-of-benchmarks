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

    uint16_t costs[MAX_N + 2];
    uint16_t next_costs[MAX_N];
    costs[0] = 32768;
    costs[n + 1] = 32768;
    for (size_t column = 0; column < n; ++column)
        costs[column + 1] = (uint16_t)(input[1 + column] + 100);
    for (size_t row = 1; row < n; ++row) {
        for (size_t column = 0; column < n; ++column) {
            const uint16_t left = costs[column];
            const uint16_t center = costs[column + 1];
            const uint16_t right = costs[column + 2];
            const uint16_t left_or_center = left < center ? left : center;
            const uint16_t best = right < left_or_center ? right : left_or_center;
            next_costs[column] = best + (uint16_t)(input[1 + row * n + column] + 100);
        }
        for (size_t column = 0; column < n; ++column)
            costs[column + 1] = next_costs[column];
    }
    uint16_t minimum = costs[1];
    for (size_t column = 1; column < n; ++column)
        if (costs[column + 1] < minimum) minimum = costs[column + 1];
    return (int64_t)(minimum) - 100 * (int64_t)(n);
}
