#include <stddef.h>
#include <stdint.h>

enum { MAX_K = 3, MAX_P = 32, MAX_INPUT = 69, MAX_OUTPUT = 256 };
static const int64_t MOD = INT64_C(998244353);
static void store_le(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) { out[at + b] = (uint8_t)(bits & 255u); bits >>= 8; }
}
int64_t multivariate_convolution(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > MAX_INPUT) return -1;
    int64_t k0 = input[0]; if (k0 < 0 || k0 > MAX_K) return -1;
    size_t k = (size_t)k0; if (length < 1 + k) return -1;
    size_t dims[MAX_K], p = 1;
    for (size_t axis = 0; axis < k; ++axis) {
        int64_t d0 = input[1 + axis];
        if (d0 < 2 || d0 > MAX_P || p > MAX_P / (size_t)d0) return -1;
        dims[axis] = (size_t)d0; p *= dims[axis];
    }
    if (length != 1 + k + 2 * p) return -1;
    size_t start = 1 + k;
    for (size_t q = start; q < length; ++q) if (input[q] < 0 || input[q] >= MOD) return -1;
    size_t bytes = 8 * p; if (bytes > MAX_OUTPUT) return -1;
    if (!output || capacity < bytes) return -2;
    int64_t a[MAX_P], b[MAX_P], result[MAX_P] = {0};
    for (size_t i = 0; i < p; ++i) { a[i] = input[start + i]; b[i] = input[start + p + i]; }
    for (size_t i = 0; i < p; ++i) for (size_t j = 0; j < p; ++j) {
        size_t target = 0, stride = 1; int valid = 1;
        for (size_t axis = 0; axis < k; ++axis) {
            size_t d = dims[axis], sum = (i / stride) % d + (j / stride) % d;
            if (sum >= d) { valid = 0; break; }
            target += sum * stride; stride *= d;
        }
        if (valid) result[target] = (result[target] + a[i] * b[j]) % MOD;
    }
    for (size_t i = 0; i < p; ++i) store_le(output, 8 * i, result[i]);
    return (int64_t)bytes;
}
