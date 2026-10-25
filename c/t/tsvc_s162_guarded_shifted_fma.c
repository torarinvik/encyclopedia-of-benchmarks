/* Clean-room bounded port of TSVC s162; see package README for provenance. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_INPUT_LENGTH = 194 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s162_guarded_shifted_fma(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > 1) return -1;
    const size_t n = (size_t)input[0];
    if (length != 2 + 3 * n) return -1;
    for (size_t i = 2; i < length; ++i) {
        if (input[i] < -2 || input[i] > 2) return -1;
    }
    if (output == NULL || capacity < 8 * n) return -2;
    const size_t a_offset = 2;
    const size_t b_offset = a_offset + n;
    const size_t c_offset = b_offset + n;
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, input[a_offset + i]);
    if (input[1] > 0) {
        for (size_t i = 0; i + 1 < n; ++i) {
            const int64_t value = input[a_offset + i + 1] +
                input[b_offset + i] * input[c_offset + i];
            store_i64_le(output, 8 * i, value);
        }
    }
    return (int64_t)n;
}
