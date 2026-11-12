#include <stddef.h>
#include <stdint.h>

enum { MAX_INPUT = 259, MAX_OUTPUT = 2040, MAX_N = 128, MAX_M = 128 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

static int is_convex(const int64_t *values, size_t length) {
    for (size_t i = 0; i + 2 < length; ++i)
        if (values[i + 1] - values[i] > values[i + 2] - values[i + 1]) return 0;
    return 1;
}

int64_t min_plus_convolution_convex_convex(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > MAX_N || m0 < 1 || m0 > MAX_M) return -1;
    const size_t n = (size_t)n0, m = (size_t)m0;
    if (length != 2 + n + m) return -1;
    const int64_t *a = input + 2, *b = input + 2 + n;
    for (size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 1000000000) return -1;
    if (!is_convex(a, n) || !is_convex(b, m)) return -1;

    const size_t count = n + m - 1, bytes = 8 * count;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < bytes) return -2;

    int64_t result[MAX_N + MAX_M - 1];
    result[0] = a[0] + b[0];
    size_t ai = 0, bi = 0, out = 1;
    while (ai + 1 < n || bi + 1 < m) {
        int64_t slope;
        if (bi + 1 == m || (ai + 1 < n && a[ai + 1] - a[ai] <= b[bi + 1] - b[bi])) {
            slope = a[ai + 1] - a[ai];
            ++ai;
        } else {
            slope = b[bi + 1] - b[bi];
            ++bi;
        }
        result[out] = result[out - 1] + slope;
        ++out;
    }
    for (size_t i = 0; i < count; ++i) store_i64_le(output, 8 * i, result[i]);
    return (int64_t)bytes;
}
