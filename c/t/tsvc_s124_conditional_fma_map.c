/* Clean-room port of TSVC s124; provenance and rights are in the package README. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_INPUT_LENGTH = 1 + 4 * MAX_N };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s124_conditional_fma_map(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 4 * n) return -1;
    int64_t a[MAX_N], b[MAX_N], c[MAX_N], d[MAX_N], e[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        b[i] = input[1 + i];
        c[i] = input[1 + n + i];
        d[i] = input[1 + 2 * n + i];
        e[i] = input[1 + 3 * n + i];
        if (b[i] < -100 || b[i] > 100 || c[i] < -100 || c[i] > 100 ||
            d[i] < -100 || d[i] > 100 || e[i] < -100 || e[i] > 100) return -1;
    }
    if (output == NULL || capacity < 8 * n) return -2;
    int64_t j = -1;
    for (size_t i = 0; i < n; ++i) {
        if (b[i] > 0) {
            ++j;
            a[(size_t)j] = b[i] + d[i] * e[i];
        } else {
            ++j;
            a[(size_t)j] = c[i] + d[i] * e[i];
        }
    }
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return (int64_t)n;
}
