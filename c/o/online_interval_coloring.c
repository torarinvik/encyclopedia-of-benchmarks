/* Clean-room bounded Kierstead-Trotter online interval coloring profile. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_INTERVALS = 64, MAX_INPUT = 129 };

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static int level_fits(const int64_t *left, const int64_t *right,
                      const size_t *levels, size_t last, size_t candidate_level) {
    for (size_t anchor = 0; anchor <= last; ++anchor) {
        const int64_t point = left[anchor];
        size_t overlap = 0;
        for (size_t item = 0; item <= last; ++item) {
            if ((item == last || levels[item] <= candidate_level) &&
                left[item] <= point && point <= right[item]) ++overlap;
        }
        if (overlap > candidate_level) return 0;
    }
    return 1;
}

int64_t online_interval_coloring(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT || input[0] < 0 ||
        input[0] > MAX_INTERVALS || length != 1 + 2 * (size_t)input[0]) return -1;
    const size_t n = (size_t)input[0];
    int64_t left[MAX_INTERVALS], right[MAX_INTERVALS];
    size_t level[MAX_INTERVALS], local_color[MAX_INTERVALS], colors[MAX_INTERVALS];
    for (size_t i = 0; i < n; ++i) {
        left[i] = input[1 + 2 * i];
        right[i] = input[2 + 2 * i];
        if (left[i] < -1000 || left[i] > 1000 || right[i] < -1000 ||
            right[i] > 1000 || left[i] > right[i]) return -1;
    }
    const size_t output_bytes = 8 * n;
    if (output == NULL || capacity < output_bytes) return -2;

    for (size_t i = 0; i < n; ++i) {
        size_t chosen = 1;
        while (!level_fits(left, right, level, i, chosen)) {
            ++chosen;
            if (chosen > i + 1) return -1;
        }
        level[i] = chosen;
        int used[3] = {0, 0, 0};
        for (size_t prior = 0; prior < i; ++prior) {
            if (level[prior] == chosen && left[prior] <= right[i] && left[i] <= right[prior] &&
                local_color[prior] < 3) used[local_color[prior]] = 1;
        }
        size_t color = 0;
        while (color < 3 && used[color]) ++color;
        if (color == 3) return -1;
        local_color[i] = color;
        colors[i] = 3 * (chosen - 1) + color;
    }
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, (int64_t)colors[i]);
    return (int64_t)output_bytes;
}
