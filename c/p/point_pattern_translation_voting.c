#include <stddef.h>
#include <stdint.h>

enum { MAX_PATTERN = 6, MAX_TARGET = 8, MAX_COORD = 16, MAX_PAIRS = 48, MAX_INPUT = 31 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t point_pattern_translation_voting(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t pattern_count_raw = input[0], target_count_raw = input[1];
    if (pattern_count_raw < 1 || pattern_count_raw > MAX_PATTERN ||
            target_count_raw < 1 || target_count_raw > MAX_TARGET) return -1;
    const int pattern_count = (int)pattern_count_raw, target_count = (int)target_count_raw;
    if (length != (size_t)(2 + 2 * (pattern_count + target_count))) return -1;
    int64_t px[MAX_PATTERN], py[MAX_PATTERN], tx[MAX_TARGET], ty[MAX_TARGET];
    size_t cursor = 2;
    for (int i = 0; i < pattern_count; ++i) {
        px[i] = input[cursor++]; py[i] = input[cursor++];
        if (px[i] < -MAX_COORD || px[i] > MAX_COORD || py[i] < -MAX_COORD || py[i] > MAX_COORD) return -1;
        for (int j = 0; j < i; ++j) if (px[i] == px[j] && py[i] == py[j]) return -1;
    }
    for (int i = 0; i < target_count; ++i) {
        tx[i] = input[cursor++]; ty[i] = input[cursor++];
        if (tx[i] < -MAX_COORD || tx[i] > MAX_COORD || ty[i] < -MAX_COORD || ty[i] > MAX_COORD) return -1;
        for (int j = 0; j < i; ++j) if (tx[i] == tx[j] && ty[i] == ty[j]) return -1;
    }
    if (output == NULL) return -2;

    int64_t dx[MAX_PAIRS], dy[MAX_PAIRS];
    int pair_count = 0;
    for (int p = 0; p < pattern_count; ++p) for (int t = 0; t < target_count; ++t) {
        dx[pair_count] = tx[t] - px[p];
        dy[pair_count] = ty[t] - py[p];
        ++pair_count;
    }
    for (int i = 1; i < pair_count; ++i) {
        const int64_t key_x = dx[i], key_y = dy[i];
        int j = i;
        while (j > 0 && (dx[j - 1] > key_x || (dx[j - 1] == key_x && dy[j - 1] > key_y))) {
            dx[j] = dx[j - 1]; dy[j] = dy[j - 1]; --j;
        }
        dx[j] = key_x; dy[j] = key_y;
    }
    int best_count = 0;
    int64_t best_x = dx[0], best_y = dy[0];
    for (int i = 0; i < pair_count;) {
        int end = i + 1;
        while (end < pair_count && dx[end] == dx[i] && dy[end] == dy[i]) ++end;
        if (end - i > best_count) { best_count = end - i; best_x = dx[i]; best_y = dy[i]; }
        i = end;
    }
    if (capacity < 24) return -2;
    uint8_t staged[24] = {0};
    store_i64_le(staged, 0, best_count);
    store_i64_le(staged, 8, best_x);
    store_i64_le(staged, 16, best_y);
    for (size_t byte = 0; byte < sizeof(staged); ++byte) output[byte] = staged[byte];
    return 24;
}
