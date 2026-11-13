#include <stddef.h>
#include <stdint.h>

enum { CELL_COUNT = 16 };

int64_t fifteen_puzzle_solvability(const int64_t *input, size_t length) {
    if (input == NULL || length != CELL_COUNT) return -1;

    int64_t blank = -1;
    for (size_t i = 0; i < CELL_COUNT; ++i) {
        if (input[i] < 0 || input[i] >= CELL_COUNT) return -1;
        for (size_t j = 0; j < i; ++j) {
            if (input[i] == input[j]) return -1;
        }
        if (input[i] == 0) blank = (int64_t)i;
    }
    if (blank < 0) return -1;

    int64_t inversions = 0;
    for (size_t i = 0; i < CELL_COUNT; ++i) {
        if (input[i] == 0) continue;
        for (size_t j = i + 1; j < CELL_COUNT; ++j) {
            if (input[j] != 0 && input[i] > input[j]) ++inversions;
        }
    }
    const int64_t blank_row_from_top = blank / 4 + 1;
    return (inversions + blank_row_from_top) % 2 == 0 ? 1 : 0;
}
