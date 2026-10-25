/* Clean-room port of TSVC s122; provenance and rights are in the package README. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_INPUT_LENGTH = 3 + 2 * MAX_N };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s122_reverse_strided_gather_add(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (input[1] < 1 || input[1] > (int64_t)n || input[2] < 1 || input[2] > (int64_t)n) return -1;
    if (length != 3 + 2 * n) return -1;
    const size_t start = (size_t)input[1];
    const size_t stride = (size_t)input[2];
    int64_t a[MAX_N], b[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[3 + i];
        b[i] = input[3 + n + i];
        if (a[i] < -100 || a[i] > 100 || b[i] < -100 || b[i] > 100) return -1;
    }
    if (output == NULL || capacity < 8 * n) return -2;
    int64_t j = 1, k = 0;
    for (size_t i = start - 1; i < n; i += stride) {
        k += j;
        a[i] += b[n - (size_t)k];
    }
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return (int64_t)n;
}
