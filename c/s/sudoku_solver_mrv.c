/* Solve Sudoku with constraint propagation and minimum-remaining-values search. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define SUDOKU_CELLS 81
#define ALL_DIGITS UINT16_C(0x03FE)

static bool is_single(uint16_t candidates)
{
    return candidates != 0 && (candidates & (uint16_t)(candidates - 1)) == 0;
}

static unsigned int digit_for(uint16_t candidate)
{
    unsigned int digit = 1;
    while ((candidate & (uint16_t)(UINT16_C(1) << digit)) == 0) ++digit;
    return digit;
}

static bool assign(uint16_t *candidates, size_t cell, uint16_t selected);

static bool eliminate(uint16_t *candidates, size_t cell, uint16_t removed)
{
    if ((candidates[cell] & removed) == 0) return true;
    candidates[cell] = (uint16_t)(candidates[cell] & (uint16_t)~removed);
    const uint16_t remaining = candidates[cell];
    if (remaining == 0) return false;

    if (is_single(remaining)) {
        for (size_t peer = 0; peer < SUDOKU_CELLS; ++peer) {
            if (peer == cell) continue;
            const size_t row = cell / 9, column = cell % 9;
            const size_t peer_row = peer / 9, peer_column = peer % 9;
            const bool shares_row = row == peer_row;
            const bool shares_column = column == peer_column;
            const bool shares_box = row / 3 == peer_row / 3 && column / 3 == peer_column / 3;
            if ((shares_row || shares_column || shares_box) &&
                !eliminate(candidates, peer, remaining)) return false;
        }
    }

    const size_t row = cell / 9, column = cell % 9;
    const size_t box_row = row / 3 * 3, box_column = column / 3 * 3;
    for (size_t unit = 0; unit < 3; ++unit) {
        size_t only_place = 0;
        size_t place_count = 0;
        for (size_t offset = 0; offset < 9; ++offset) {
            size_t place;
            if (unit == 0) place = row * 9 + offset;
            else if (unit == 1) place = offset * 9 + column;
            else place = (box_row + offset / 3) * 9 + box_column + offset % 3;
            if ((candidates[place] & removed) != 0) {
                only_place = place;
                ++place_count;
            }
        }
        if (place_count == 0) return false;
        if (place_count == 1 && !assign(candidates, only_place, removed)) return false;
    }
    return true;
}

static bool assign(uint16_t *candidates, size_t cell, uint16_t selected)
{
    if ((candidates[cell] & selected) == 0) return false;
    uint16_t other = (uint16_t)(candidates[cell] & (uint16_t)~selected);
    while (other != 0) {
        const uint16_t bit = (uint16_t)(other & (uint16_t)(0U - other));
        other = (uint16_t)(other & (uint16_t)~bit);
        if (!eliminate(candidates, cell, bit)) return false;
    }
    return true;
}

static bool search(uint16_t *candidates)
{
    size_t best_cell = SUDOKU_CELLS;
    unsigned int best_count = 10;
    for (size_t cell = 0; cell < SUDOKU_CELLS; ++cell) {
        unsigned int count = 0;
        for (uint16_t bits = candidates[cell]; bits != 0; bits &= (uint16_t)(bits - 1)) ++count;
        if (count == 0) return false;
        if (count > 1 && count < best_count) {
            best_cell = cell;
            best_count = count;
        }
    }
    if (best_cell == SUDOKU_CELLS) return true;

    const uint16_t choices = candidates[best_cell];
    for (unsigned int digit = 1; digit <= 9; ++digit) {
        const uint16_t bit = (uint16_t)(UINT16_C(1) << digit);
        if ((choices & bit) == 0) continue;
        uint16_t branch[SUDOKU_CELLS];
        memcpy(branch, candidates, sizeof(branch));
        if (assign(branch, best_cell, bit) && search(branch)) {
            memcpy(candidates, branch, sizeof(branch));
            return true;
        }
    }
    return false;
}

int64_t sudoku_solver_mrv(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != SUDOKU_CELLS) return -1;
    uint16_t candidates[SUDOKU_CELLS];
    for (size_t cell = 0; cell < SUDOKU_CELLS; ++cell) {
        if (values[cell] < 0 || values[cell] > 9) return -1;
        candidates[cell] = ALL_DIGITS;
    }
    for (size_t cell = 0; cell < SUDOKU_CELLS; ++cell) {
        if (values[cell] != 0 &&
            !assign(candidates, cell, (uint16_t)(UINT16_C(1) << values[cell]))) return -1;
    }
    if (!search(candidates)) return -1;
    if (output == NULL || output_capacity < 4 * SUDOKU_CELLS) return -2;
    for (size_t cell = 0; cell < SUDOKU_CELLS; ++cell) {
        const uint32_t digit = digit_for(candidates[cell]);
        output[cell * 4] = (uint8_t)digit;
        output[cell * 4 + 1] = (uint8_t)(digit >> 8);
        output[cell * 4 + 2] = (uint8_t)(digit >> 16);
        output[cell * 4 + 3] = (uint8_t)(digit >> 24);
    }
    return SUDOKU_CELLS;
}
