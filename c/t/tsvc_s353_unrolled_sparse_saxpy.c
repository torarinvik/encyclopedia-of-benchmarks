/* Clean-room port of TSVC s353; provenance and rights are in the package README. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 20, MAX_INPUT_LENGTH = 2 + 3 * MAX_N, MAX_OUTPUT_BYTES = 8 * MAX_N };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s353_unrolled_sparse_saxpy(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 17 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 5 || input[0] > MAX_N || input[0] % 5 != 0) return -1;
    const size_t n = (size_t)input[0];
    if (length != 2 + 3 * n) return -1;
    const int64_t alpha = input[1];
    if (alpha < -8 || alpha > 8) return -1;
    int64_t a[MAX_N], b[MAX_N], indices[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[2 + i];
        b[i] = input[2 + n + i];
        indices[i] = input[2 + 2 * n + i];
        if (a[i] < -1000000 || a[i] > 1000000 || b[i] < -1000000 || b[i] > 1000000 ||
            indices[i] < 0 || indices[i] >= (int64_t)n) return -1;
    }
    if (output == NULL || capacity < 8 * n) return -2;
    for (size_t i = 0; i < n; i += 5) {
        a[i] += alpha * b[(size_t)indices[i]];
        a[i + 1] += alpha * b[(size_t)indices[i + 1]];
        a[i + 2] += alpha * b[(size_t)indices[i + 2]];
        a[i + 3] += alpha * b[(size_t)indices[i + 3]];
        a[i + 4] += alpha * b[(size_t)indices[i + 4]];
    }
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return (int64_t)n;
}
