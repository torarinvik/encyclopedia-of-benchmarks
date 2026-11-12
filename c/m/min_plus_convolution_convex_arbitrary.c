#include <stddef.h>
#include <stdint.h>

enum { MAX_INPUT = 67, MAX_OUTPUT = 504, MAX_N = 32, MAX_M = 32 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t min_plus_convolution_convex_arbitrary(const int64_t *input, size_t length,
                                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > MAX_N || m0 < 1 || m0 > MAX_M) return -1;
    const size_t n = (size_t)n0, m = (size_t)m0;
    if (length != 2 + n + m) return -1;
    const int64_t *a = input + 2, *b = input + 2 + n;
    for (size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 1000000000) return -1;
    for (size_t i = 0; i + 2 < n; ++i)
        if (a[i + 1] - a[i] > a[i + 2] - a[i + 1]) return -1;
    const size_t count = n + m - 1, bytes = 8 * count;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < bytes) return -2;

    int64_t result[MAX_N + MAX_M - 1];
    size_t stack[128][4], top = 0;
    stack[top][0] = 0; stack[top][1] = count - 1;
    stack[top][2] = 0; stack[top][3] = m - 1; ++top;
    while (top != 0) {
        --top;
        const size_t left = stack[top][0], right = stack[top][1];
        const size_t opt_left = stack[top][2], opt_right = stack[top][3];
        if (left > right) continue;
        const size_t mid = left + (right - left) / 2;
        size_t low = opt_left;
        if (mid > n - 1 && low < mid - (n - 1)) low = mid - (n - 1);
        size_t high = opt_right;
        if (high > m - 1) high = m - 1;
        if (high > mid) high = mid;
        int64_t best_value = INT64_MAX;
        size_t best_j = low;
        for (size_t j = low; j <= high; ++j) {
            const int64_t candidate = a[mid - j] + b[j];
            if (candidate < best_value) { best_value = candidate; best_j = j; }
        }
        result[mid] = best_value;
        if (mid < right) {
            stack[top][0] = mid + 1; stack[top][1] = right;
            stack[top][2] = best_j; stack[top][3] = opt_right; ++top;
        }
        if (left < mid) {
            stack[top][0] = left; stack[top][1] = mid - 1;
            stack[top][2] = opt_left; stack[top][3] = best_j; ++top;
        }
    }
    for (size_t i = 0; i < count; ++i) store_i64_le(output, 8 * i, result[i]);
    return (int64_t)bytes;
}
