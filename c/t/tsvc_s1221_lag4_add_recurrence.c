/* Clean-room port of TSVC s1221; provenance and rights are in package README. */
#include <stddef.h>
#include <stdint.h>

enum { MIN_N = 5, MAX_N = 32, MAX_INPUT_LENGTH = 1 + 2 * MAX_N };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s1221_lag4_add_recurrence(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 + 2 * MIN_N || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < MIN_N || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 2 * n) return -1;
    int64_t a[MAX_N], b[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[1 + i];
        b[i] = input[1 + n + i];
        if (a[i] < -10 || a[i] > 10 || b[i] < -10 || b[i] > 10) return -1;
    }
    if (output == NULL || capacity < 8 * n) return -2;
    for (size_t i = 4; i < n; ++i) b[i] = b[i - 4] + a[i];
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, b[i]);
    return (int64_t)n;
}
