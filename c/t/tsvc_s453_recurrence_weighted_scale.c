/* Clean-room port of TSVC s453; provenance and rights are in the package README. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_INPUT_LENGTH = 1 + MAX_N };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s453_recurrence_weighted_scale(const int64_t *input, size_t length,
                                            uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + n) return -1;
    int64_t b[MAX_N], a[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        b[i] = input[1 + i];
        if (b[i] < -100 || b[i] > 100) return -1;
    }
    if (output == NULL || capacity < 8 * n) return -2;
    int64_t s = 0;
    for (size_t i = 0; i < n; ++i) {
        s += 2;
        a[i] = s * b[i];
    }
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return (int64_t)n;
}
