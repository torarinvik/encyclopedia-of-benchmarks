#include <stddef.h>
#include <stdint.h>

static void sticky_put_word(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t sticky_sampling_summary(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (!input || length < 3 || length > 323 || input[0] < 1 || input[0] > 8 ||
        input[1] < 0 || input[1] > 64 || input[2] < 0 || input[2] > 256) return -1;
    size_t t = (size_t)input[0], n = (size_t)input[1], k = (size_t)input[2];
    if (length != 3 + n + k) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[3+i] < 0 || input[3+i] > 15) return -1;
    for (size_t i = 0; i < k; ++i)
        if (input[3+n+i] < 0 || input[3+n+i] > 255) return -1;

    int64_t count[16] = {0};
    size_t cursor = 0, rate = 1, phase_end = 2*t;
    for (size_t i = 0; i < n; ++i) {
        if (i == phase_end) {
            rate *= 2;
            phase_end += rate*t;
            for (size_t item = 0; item < 16; ++item) {
                while (count[item] != 0) {
                    if (cursor == k) return -1;
                    int64_t draw = input[3+n+cursor++];
                    if (draw & 1) break;
                    --count[item];
                }
            }
        }
        size_t item = (size_t)input[3+i];
        if (count[item]) ++count[item];
        else {
            if (cursor == k) return -1;
            size_t draw = (size_t)input[3+n+cursor++];
            if (draw % rate == 0) count[item] = 1;
        }
    }
    if (cursor != k) return -1;
    size_t active = 0;
    for (size_t item = 0; item < 16; ++item) active += count[item] != 0;
    size_t bytes = 8 + 16*active;
    if (!output || capacity < bytes) return -2;
    sticky_put_word(output, 0, (int64_t)active);
    size_t offset = 8;
    for (size_t item = 0; item < 16; ++item) if (count[item]) {
        sticky_put_word(output, offset, (int64_t)item);
        sticky_put_word(output, offset+8, count[item]);
        offset += 16;
    }
    return (int64_t)bytes;
}
