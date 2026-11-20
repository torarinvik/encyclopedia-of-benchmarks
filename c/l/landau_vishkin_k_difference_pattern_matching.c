#include <stddef.h>
#include <stdint.h>

#define MAX_PATTERN_LENGTH 16
#define MAX_TEXT_LENGTH 32
#define MAX_ERRORS 2
#define MAX_VALID_INPUT_LENGTH (3 + MAX_PATTERN_LENGTH + MAX_TEXT_LENGTH)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1)
#define MAX_DIAGONALS (MAX_TEXT_LENGTH + MAX_ERRORS + 3)
#define MAX_COST_COLUMNS (MAX_ERRORS + 2)

int64_t landau_vishkin_k_difference_pattern_matching(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) {
        return -1;
    }

    const int64_t raw_m = input[0];
    const int64_t raw_n = input[1];
    const int64_t raw_k = input[2];
    if (raw_m < 1 || raw_m > MAX_PATTERN_LENGTH ||
        raw_n < 0 || raw_n > MAX_TEXT_LENGTH ||
        raw_k < 0 || raw_k > MAX_ERRORS || raw_k >= raw_m) {
        return -1;
    }
    const size_t m = (size_t)raw_m;
    const size_t n = (size_t)raw_n;
    const int k = (int)raw_k;
    if (length != 3 + m + n) return -1;

    const int64_t *pattern = input + 3;
    const int64_t *text = pattern + m;
    for (size_t index = 0; index < m + n; ++index) {
        const int64_t symbol = index < m ? pattern[index] : text[index - m];
        if (symbol < 0 || symbol > 3) return -1;
    }
    if (output == NULL || capacity < n) return -2;

    int64_t frontier[MAX_DIAGONALS][MAX_COST_COLUMNS];
    for (size_t diagonal = 0; diagonal < MAX_DIAGONALS; ++diagonal) {
        for (size_t cost = 0; cost < MAX_COST_COLUMNS; ++cost) {
            frontier[diagonal][cost] = -1;
        }
    }

    const int low_diagonal = -(k + 1);
    for (int diagonal = low_diagonal; diagonal < 0; ++diagonal) {
        const int magnitude = -diagonal;
        const size_t slot = (size_t)(diagonal + MAX_ERRORS + 1);
        frontier[slot][(size_t)magnitude] = magnitude - 1;
        frontier[slot][(size_t)(magnitude - 1)] = magnitude - 2;
    }

    uint8_t staged[MAX_TEXT_LENGTH] = {0};
    for (int errors = 0; errors <= k; ++errors) {
        for (int diagonal = -errors; diagonal <= (int)n; ++diagonal) {
            const size_t slot = (size_t)(diagonal + MAX_ERRORS + 1);
            int64_t row = frontier[slot][(size_t)errors] + 1;
            const int64_t from_left = frontier[slot - 1][(size_t)errors];
            const int64_t from_right = frontier[slot + 1][(size_t)errors] + 1;
            if (from_left > row) row = from_left;
            if (from_right > row) row = from_right;
            if (row > raw_m) row = raw_m;

            while (row < raw_m) {
                const int64_t text_index = row + diagonal;
                if (text_index < 0 || text_index >= raw_n ||
                    pattern[row] != text[text_index]) {
                    break;
                }
                ++row;
            }

            frontier[slot][(size_t)(errors + 1)] = row;
            if (row == raw_m) {
                const int64_t endpoint = diagonal + raw_m;
                if (endpoint >= 1 && endpoint <= raw_n) {
                    staged[(size_t)(endpoint - 1)] = 1;
                }
            }
        }
    }

    for (size_t index = 0; index < n; ++index) output[index] = staged[index];
    return (int64_t)n;
}
