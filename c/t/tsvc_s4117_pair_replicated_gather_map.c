/* Clean-room bounded port of TSVC s4117; see package README for provenance. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_INPUT_LENGTH = 161 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s4117_pair_replicated_gather_map(const int64_t *input, size_t length,
                                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    const size_t c_length = (n + 1) / 2;
    if (length != 1 + 2 * n + c_length) return -1;
    for (size_t i = 1; i < length; ++i) {
        if (input[i] < -2 || input[i] > 2) return -1;
    }
    if (output == NULL || capacity < 8 * n) return -2;
    const size_t b_offset = 1;
    const size_t c_offset = 1 + n;
    const size_t d_offset = c_offset + c_length;
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[b_offset + i] +
            input[c_offset + i / 2] * input[d_offset + i];
        store_i64_le(output, 8 * i, value);
    }
    return (int64_t)n;
}
