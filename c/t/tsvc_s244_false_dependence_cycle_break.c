/* Clean-room port of TSVC s244; provenance and rights are in the package README. */
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

int64_t tsvc_s244_false_dependence_cycle_break(const int64_t *input, size_t length,
                                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 9 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 4 * n) return -1;
    int64_t a[MAX_N], b[MAX_N], c[MAX_N], d[MAX_N], trace[MAX_N - 1];
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[1 + i];
        b[i] = input[1 + n + i];
        c[i] = input[1 + 2 * n + i];
        d[i] = input[1 + 3 * n + i];
        if (a[i] < -2 || a[i] > 2 || b[i] < -2 || b[i] > 2 ||
            c[i] < -2 || c[i] > 2 || d[i] < -2 || d[i] > 2) return -1;
    }
    const size_t output_values = 3 * n - 1;
    if (output == NULL || capacity < 8 * output_values) return -2;
    for (size_t i = 0; i < n - 1; ++i) {
        a[i] = b[i] + c[i] * d[i];
        b[i] = c[i] + b[i];
        a[i + 1] = b[i] + a[i + 1] * d[i];
        trace[i] = a[i + 1];
    }
    size_t offset = 0;
    for (size_t i = 0; i < n; ++i, ++offset) store_i64_le(output, 8 * offset, a[i]);
    for (size_t i = 0; i < n; ++i, ++offset) store_i64_le(output, 8 * offset, b[i]);
    for (size_t i = 0; i < n - 1; ++i, ++offset) store_i64_le(output, 8 * offset, trace[i]);
    return (int64_t)output_values;
}
