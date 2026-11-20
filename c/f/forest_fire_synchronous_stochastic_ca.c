#include <stddef.h>
#include <stdint.h>

enum { MAX_CELLS = 64, MAX_INPUT = 1095, MAX_STEPS = 8 };

static void put_i64(uint8_t *out, size_t word, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[word * 8 + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t forest_fire_synchronous_stochastic_ca(const int64_t *input, size_t length,
                                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 6 || length > MAX_INPUT) return -1;
    const int64_t rw = input[0], cw = input[1], tw = input[2];
    if (rw < 1 || rw > 8 || cw < 1 || cw > 8 || tw < 0 || tw > MAX_STEPS ||
        input[3] != 10000 || input[4] < 0 || input[4] > 10000 ||
        input[5] < 0 || input[5] > 10000) return -1;
    const size_t rows = (size_t)rw, cols = (size_t)cw, steps = (size_t)tw;
    const size_t cells = rows * cols;
    if (length != 6 + cells + 2 * steps * cells) return -1;
    const int64_t grow_limit = input[4], lightning_limit = input[5];
    for (size_t i = 0; i < cells; ++i) if (input[6 + i] < 0 || input[6 + i] > 2) return -1;
    for (size_t row = 0; row < rows; ++row) for (size_t col = 0; col < cols; ++col)
        if ((row == 0 || row + 1 == rows || col == 0 || col + 1 == cols) && input[6 + row * cols + col] != 0) return -1;
    const size_t tape = 6 + cells;
    for (size_t i = 0; i < 2 * steps * cells; ++i)
        if (input[tape + i] < 0 || input[tape + i] >= 10000) return -1;
    const size_t words = 1 + 3 * steps + cells;
    const size_t bytes = words * 8;
    if (output == NULL || capacity < bytes) return -2;

    uint8_t current[MAX_CELLS] = {0}, next[MAX_CELLS] = {0};
    for (size_t i = 0; i < cells; ++i) current[i] = (uint8_t)input[6 + i];
    put_i64(output, 0, (int64_t)steps);
    for (size_t step = 0; step < steps; ++step) {
        for (size_t row = 0; row < rows; ++row) for (size_t col = 0; col < cols; ++col) {
            const size_t site = row * cols + col;
            const uint8_t state = current[site];
            if (row == 0 || row + 1 == rows || col == 0 || col + 1 == cols) { next[site] = 0; continue; }
            if (state == 2) { next[site] = 0; continue; }
            if (state == 0) {
                next[site] = input[tape + step * cells + site] < grow_limit ? 1 : 0;
                continue;
            }
            int burning = 0;
            const size_t r0 = row == 0 ? 0 : row - 1;
            const size_t r1 = row + 1 < rows ? row + 1 : row;
            const size_t c0 = col == 0 ? 0 : col - 1;
            const size_t c1 = col + 1 < cols ? col + 1 : col;
            for (size_t r = r0; r <= r1 && !burning; ++r)
                for (size_t c = c0; c <= c1; ++c)
                    if ((r != row || c != col) && current[r * cols + c] == 2) { burning = 1; break; }
            const int64_t strike = input[tape + steps * cells + step * cells + site];
            next[site] = burning || strike < lightning_limit ? 2 : 1;
        }
        size_t empty = 0, trees = 0, fire = 0;
        for (size_t i = 0; i < cells; ++i) { empty += next[i] == 0; trees += next[i] == 1; fire += next[i] == 2; }
        const size_t base = 1 + 3 * step;
        put_i64(output, base, (int64_t)empty);
        put_i64(output, base + 1, (int64_t)trees);
        put_i64(output, base + 2, (int64_t)fire);
        for (size_t i = 0; i < cells; ++i) current[i] = next[i];
    }
    const size_t final_base = 1 + 3 * steps;
    for (size_t i = 0; i < cells; ++i) put_i64(output, final_base + i, current[i]);
    return (int64_t)bytes;
}
