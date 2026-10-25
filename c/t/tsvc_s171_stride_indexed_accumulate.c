/* Clean-room bounded port of TSVC s171; see package README for provenance. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_STRIDE = 4, MAX_INPUT_LENGTH = 159 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s171_stride_indexed_accumulate(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_STRIDE) return -1;
    const size_t n = (size_t)input[0], stride = (size_t)input[1];
    const size_t a_length = 1 + (n - 1) * stride;
    if (length != 2 + a_length + n) return -1;
    for (size_t i = 0; i < a_length + n; ++i) {
        const int64_t value = input[2 + i];
        if (value < -8 || value > 8) return -1;
    }
    if (output == NULL || capacity < 8 * a_length) return -2;
    for (size_t i = 0; i < a_length; ++i) store_i64_le(output, 8 * i, input[2 + i]);
    const size_t b_offset = 2 + a_length;
    for (size_t i = 0; i < n; ++i) {
        const size_t destination = i * stride;
        store_i64_le(output, 8 * destination,
                     input[2 + destination] + input[b_offset + i]);
    }
    return (int64_t)a_length;
}
