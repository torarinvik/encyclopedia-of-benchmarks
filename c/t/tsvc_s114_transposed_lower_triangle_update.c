/* Clean-room port of TSVC s114; provenance and rights are in the package README. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_INPUT_LENGTH = 1 + 2 * MAX_N * MAX_N, MAX_OUTPUT_BYTES = 8 * MAX_N * MAX_N };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s114_transposed_lower_triangle_update(const int64_t *input, size_t length,
                                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 9 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0], cells = n * n;
    if (length != 1 + 2 * cells) return -1;
    int64_t a[MAX_N * MAX_N], b[MAX_N * MAX_N];
    for (size_t i = 0; i < cells; ++i) {
        a[i] = input[1 + i];
        b[i] = input[1 + cells + i];
        if (a[i] < -1000000 || a[i] > 1000000 || b[i] < -1000000 || b[i] > 1000000) return -1;
    }
    const size_t output_bytes = 8 * cells;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < i; ++j)
            a[i * n + j] = a[j * n + i] + b[i * n + j];
    for (size_t i = 0; i < cells; ++i) store_i64_le(output, 8 * i, a[i]);
    return (int64_t)cells;
}
