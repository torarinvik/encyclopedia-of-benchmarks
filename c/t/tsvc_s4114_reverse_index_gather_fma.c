/* Clean-room bounded port of TSVC s4114; see package README for provenance. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_INPUT_LENGTH = 257 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s4114_reverse_index_gather_fma(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 4 * n) return -1;
    const size_t ip_offset = 1, b_offset = 1 + n;
    const size_t c_offset = 1 + 2 * n, d_offset = 1 + 3 * n;
    for (size_t i = 0; i < n; ++i) {
        if (input[ip_offset + i] < 0 || input[ip_offset + i] >= (int64_t)n) return -1;
        if (input[b_offset + i] < -2 || input[b_offset + i] > 2 ||
            input[c_offset + i] < -2 || input[c_offset + i] > 2 ||
            input[d_offset + i] < -2 || input[d_offset + i] > 2) return -1;
    }
    if (output == NULL || capacity < 8 * n) return -2;
    for (size_t i = 0; i < n; ++i) {
        const size_t gathered = n - 1 - (size_t)input[ip_offset + i];
        const int64_t value = input[b_offset + i] +
            input[c_offset + gathered] * input[d_offset + i];
        store_i64_le(output, 8 * i, value);
    }
    return (int64_t)n;
}
