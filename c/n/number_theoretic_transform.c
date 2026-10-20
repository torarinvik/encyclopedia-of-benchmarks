/* New bounded NTT port based on AtCoder Library convolution semantics (CC0); see benchmarks/n/number_theoretic_transform/LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

#define NTT_MOD INT64_C(998244353)
#define NTT_ROOT INT64_C(3)
#define NTT_MAX_N 64

static int64_t ntt_pow(int64_t a, int64_t e) {
    int64_t r = 1;
    while (e > 0) { if (e & 1) r = (r * a) % NTT_MOD; a = (a * a) % NTT_MOD; e >>= 1; }
    return r;
}

int64_t number_theoretic_transform(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > NTT_MAX_N + 1) return -1;
    int64_t n0 = input[0];
    if (n0 < 1 || n0 > NTT_MAX_N || (n0 & (n0 - 1)) != 0 || length != (size_t)n0 + 1) return -1;
    size_t n = (size_t)n0;
    int64_t a[NTT_MAX_N];
    for (size_t i = 0; i < n; ++i) { if (input[i + 1] < 0 || input[i + 1] >= NTT_MOD) return -1; a[i] = input[i + 1]; }
    if (output == NULL || capacity < 4 * n) return -2;
    for (size_t i = 1, j = 0; i < n; ++i) {
        size_t bit = n >> 1;
        for (; j & bit; bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) { int64_t t = a[i]; a[i] = a[j]; a[j] = t; }
    }
    for (size_t len = 2; len <= n; len <<= 1) {
        int64_t step = ntt_pow(NTT_ROOT, (NTT_MOD - 1) / (int64_t)len);
        for (size_t base = 0; base < n; base += len) {
            int64_t w = 1;
            for (size_t j = 0; j < len / 2; ++j) {
                int64_t u = a[base + j], v = (a[base + j + len / 2] * w) % NTT_MOD;
                a[base + j] = (u + v) % NTT_MOD;
                a[base + j + len / 2] = (u - v + NTT_MOD) % NTT_MOD;
                w = (w * step) % NTT_MOD;
            }
        }
    }
    for (size_t i = 0; i < n; ++i) { uint32_t x = (uint32_t)a[i]; for (size_t b = 0; b < 4; ++b) output[4*i+b] = (uint8_t)(x >> (8*b)); }
    return (int64_t)(4 * n);
}
