#include <stddef.h>
#include <stdint.h>

#define RSK_MAX_N 8
#define RSK_BASE 9

int64_t rsk_row_insertion(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 10) return INT64_MIN;
    const int64_t n_value = input[0];
    if (n_value < 0 || n_value > RSK_MAX_N || length != (size_t)n_value + 1) return INT64_MIN;
    const size_t n = (size_t)n_value;

    uint8_t seen[RSK_MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[i + 1];
        if (value < 0 || value >= n_value || seen[(size_t)value]) return INT64_MIN;
        seen[(size_t)value] = 1;
    }
    if (n == 0) return 0;

    int64_t p[RSK_MAX_N * RSK_MAX_N] = {0};
    int64_t q[RSK_MAX_N * RSK_MAX_N] = {0};
    size_t row_lengths[RSK_MAX_N] = {0};
    size_t row_count = 0;
    for (size_t step = 1; step <= n; ++step) {
        int64_t value = input[step] + 1;
        size_t row = 0;
        for (;;) {
            if (row == row_count) {
                p[row * RSK_MAX_N] = value;
                q[row * RSK_MAX_N] = (int64_t)step;
                row_lengths[row] = 1;
                ++row_count;
                break;
            }
            size_t column = 0;
            while (column < row_lengths[row] && p[row * RSK_MAX_N + column] < value)
                ++column;
            if (column == row_lengths[row]) {
                p[row * RSK_MAX_N + column] = value;
                q[row * RSK_MAX_N + column] = (int64_t)step;
                ++row_lengths[row];
                break;
            }
            const int64_t bumped = p[row * RSK_MAX_N + column];
            p[row * RSK_MAX_N + column] = value;
            value = bumped;
            ++row;
        }
    }

    int64_t p_row[RSK_MAX_N] = {0};
    int64_t q_row[RSK_MAX_N] = {0};
    for (size_t row = 0; row < row_count; ++row) {
        for (size_t column = 0; column < row_lengths[row]; ++column) {
            p_row[(size_t)p[row * RSK_MAX_N + column] - 1] = (int64_t)row;
            q_row[(size_t)q[row * RSK_MAX_N + column] - 1] = (int64_t)row;
        }
    }
    int64_t code = n_value;
    for (size_t label = 0; label < n; ++label) {
        code = code * RSK_BASE + p_row[label] + 1;
        code = code * RSK_BASE + q_row[label] + 1;
    }
    return code;
}
