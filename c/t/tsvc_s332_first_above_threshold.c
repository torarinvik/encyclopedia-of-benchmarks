/* Clean-room bounded port of TSVC s332; see package README for provenance. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 256, MAX_INPUT_LENGTH = 2 + MAX_N };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s332_first_above_threshold(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    const int64_t threshold = input[1];
    if (threshold < -1000000 || threshold > 1000000 || length != 2 + n) return -1;
    int64_t values[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        values[i] = input[2 + i];
        if (values[i] < -1000000 || values[i] > 1000000) return -1;
    }
    if (output == NULL || capacity < 16) return -2;
    int64_t index = -2;
    int64_t value = -1;
    for (size_t i = 0; i < n; ++i) {
        if (values[i] > threshold) {
            index = (int64_t)i;
            value = values[i];
            break;
        }
    }
    store_i64_le(output, 0, index);
    store_i64_le(output, 8, value);
    return 2;
}
