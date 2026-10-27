#include <stddef.h>
#include <stdint.h>

enum { MAX_PATTERN = 6, MAX_TARGET = 8, MAX_COORD = 16, MAX_INPUT = 31 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int point_less(int64_t ax, int64_t ay, int64_t bx, int64_t by) {
    return ax < bx || (ax == bx && ay < by);
}

int64_t point_pattern_translation_lex_scan(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t pattern_raw = input[0], target_raw = input[1];
    if (pattern_raw < 1 || pattern_raw > MAX_PATTERN || target_raw < 1 || target_raw > MAX_TARGET ||
            pattern_raw > target_raw) return -1;
    const int pattern_count = (int)pattern_raw, target_count = (int)target_raw;
    if (length != (size_t)(2 + 2 * (pattern_count + target_count))) return -1;
    int64_t px[MAX_PATTERN], py[MAX_PATTERN], tx[MAX_TARGET], ty[MAX_TARGET];
    size_t cursor = 2;
    for (int i = 0; i < pattern_count; ++i) {
        px[i] = input[cursor++]; py[i] = input[cursor++];
        if (px[i] < -MAX_COORD || px[i] > MAX_COORD || py[i] < -MAX_COORD || py[i] > MAX_COORD) return -1;
        if (i > 0 && !point_less(px[i - 1], py[i - 1], px[i], py[i])) return -1;
    }
    for (int i = 0; i < target_count; ++i) {
        tx[i] = input[cursor++]; ty[i] = input[cursor++];
        if (tx[i] < -MAX_COORD || tx[i] > MAX_COORD || ty[i] < -MAX_COORD || ty[i] > MAX_COORD) return -1;
        if (i > 0 && !point_less(tx[i - 1], ty[i - 1], tx[i], ty[i])) return -1;
    }
    if (output == NULL || capacity < 24) return -2;

    int found = 0;
    int64_t best_x = 0, best_y = 0;
    for (int anchor = 0; anchor < target_count && !found; ++anchor) {
        const int64_t dx = tx[anchor] - px[0], dy = ty[anchor] - py[0];
        int target_index = anchor + 1;
        int matches = 1;
        for (int pattern_index = 1; pattern_index < pattern_count; ++pattern_index) {
            const int64_t wanted_x = px[pattern_index] + dx;
            const int64_t wanted_y = py[pattern_index] + dy;
            while (target_index < target_count &&
                    point_less(tx[target_index], ty[target_index], wanted_x, wanted_y)) ++target_index;
            if (target_index >= target_count || tx[target_index] != wanted_x || ty[target_index] != wanted_y) {
                matches = 0;
                break;
            }
            ++target_index;
        }
        if (matches) { found = 1; best_x = dx; best_y = dy; }
    }

    uint8_t staged[24] = {0};
    store_i64_le(staged, 0, found);
    store_i64_le(staged, 8, best_x);
    store_i64_le(staged, 16, best_y);
    for (size_t byte = 0; byte < sizeof(staged); ++byte) output[byte] = staged[byte];
    return 24;
}
