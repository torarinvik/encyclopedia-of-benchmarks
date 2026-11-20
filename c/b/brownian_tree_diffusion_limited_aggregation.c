/* Clean-room bounded lattice diffusion-limited aggregation. */
#include <stddef.h>
#include <stdint.h>

enum { SIDE = 33, MAX_ATTEMPTS = 16, MAX_STEPS = 512, MAX_POINTS = 17 };
#define GOLDEN UINT64_C(0x9e3779b97f4a7c15)
#define MULTIPLIER UINT64_C(0x2545f4914f6cdd1d)

static uint64_t next_word(uint64_t *state) {
    uint64_t value = *state;
    value ^= value >> 12;
    value ^= value << 25;
    value ^= value >> 27;
    *state = value;
    return value * MULTIPLIER;
}

static int touches(const uint8_t *occupied, int x, int y) {
    return occupied[y * SIDE + x - 1] || occupied[(y - 1) * SIDE + x] ||
           occupied[y * SIDE + x + 1] || occupied[(y + 1) * SIDE + x];
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t brownian_tree_diffusion_limited_aggregation(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 3) return -1;
    const int64_t attempts_value = input[0];
    const int64_t seed_value = input[1];
    const int64_t steps_value = input[2];
    if (attempts_value < 0 || attempts_value > MAX_ATTEMPTS || seed_value < 1 ||
        steps_value < 1 || steps_value > MAX_STEPS) return -1;
    const int attempts = (int)attempts_value;
    const int step_cap = (int)steps_value;

    uint8_t occupied[SIDE * SIDE] = {0};
    int32_t point_x[MAX_POINTS] = {16};
    int32_t point_y[MAX_POINTS] = {16};
    int point_count = 1;
    occupied[16 * SIDE + 16] = 1;

    for (int attempt = 0; attempt < attempts; ++attempt) {
        uint64_t state = (uint64_t)seed_value ^ (GOLDEN * (uint64_t)(attempt + 1));
        if (state == 0) state = MULTIPLIER;
        const uint64_t side_draw = next_word(&state);
        const uint64_t position_draw = next_word(&state);
        const uint64_t side = side_draw % 4;
        const int position = 1 + (int)(position_draw % 31);
        int x, y;
        if (side == 0) { x = position; y = 1; }
        else if (side == 1) { x = 31; y = position; }
        else if (side == 2) { x = position; y = 31; }
        else { x = 1; y = position; }

        if (occupied[y * SIDE + x]) continue;
        if (touches(occupied, x, y)) {
            occupied[y * SIDE + x] = 1;
            point_x[point_count] = x;
            point_y[point_count++] = y;
            continue;
        }
        for (int step = 0; step < step_cap; ++step) {
            const int direction = (int)(next_word(&state) % 4);
            if (direction == 0) --x;
            else if (direction == 1) --y;
            else if (direction == 2) ++x;
            else ++y;
            if (x == 0 || x == 32 || y == 0 || y == 32) break;
            if (touches(occupied, x, y)) {
                occupied[y * SIDE + x] = 1;
                point_x[point_count] = x;
                point_y[point_count++] = y;
                break;
            }
        }
    }

    const size_t word_count = (size_t)(1 + 2 * point_count);
    const size_t required = word_count * 8;
    if (output == NULL || capacity < required) return -2;
    store_i64_le(output, 0, point_count);
    for (int point = 0; point < point_count; ++point) {
        store_i64_le(output, (size_t)(1 + 2 * point) * 8, point_x[point]);
        store_i64_le(output, (size_t)(2 + 2 * point) * 8, point_y[point]);
    }
    return (int64_t)required;
}
