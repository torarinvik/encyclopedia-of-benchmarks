/* Clean-room implementation of TSVC s293; see package rights note. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_INPUT_LENGTH = 33, MAX_OUTPUT_BYTES = 256 };

static void store_i64_le(uint8_t *out, size_t pos, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) { out[pos + b] = (uint8_t)(bits & 255u); bits >>= 8; }
}

int64_t tsvc_s293_first_element_broadcast(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || length != 1 + (size_t)input[0]) return -1;
    const size_t n = (size_t)input[0];
    for (size_t i = 1; i < length; ++i) if (input[i] < -8 || input[i] > 8) return -1;
    const size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;
    int64_t staged[MAX_N];
    const int64_t first = input[1];
    for (size_t i = 0; i < n; ++i) staged[i] = first;
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, staged[i]);
    return (int64_t)bytes;
}
