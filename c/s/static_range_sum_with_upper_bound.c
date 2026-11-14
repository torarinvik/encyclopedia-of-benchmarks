#include <stddef.h>
#include <stdint.h>

/* A bounded wavelet matrix with per-level zero-partition prefix sums. */
int64_t static_range_sum_with_upper_bound(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (!input || length < 2 || input[0] < 1 || input[0] > 64 ||
        input[1] < 1 || input[1] > 64) return -1;
    size_t n = (size_t)input[0], q = (size_t)input[1];
    if (length != 2 + n + 3*q) return -1;
    uint32_t current[64], next[64];
    for (size_t i = 0; i < n; ++i) {
        if (input[2+i] < 0 || input[2+i] > 1000000000) return -1;
        current[i] = (uint32_t)input[2+i];
    }
    for (size_t i = 0; i < q; ++i) {
        int64_t l = input[2+n+3*i], r = input[3+n+3*i], x = input[4+n+3*i];
        if (l < 0 || l > r || r > (int64_t)n || x < 0 || x > 1000000000) return -1;
    }
    if (!output || capacity < 16*q) return -2;
    uint8_t zeros[30][65] = {{0}}, zero_total[30] = {0};
    uint64_t sums[30][65] = {{0}};
    for (size_t level = 0; level < 30; ++level) {
        unsigned bit = 29u-(unsigned)level;
        for (size_t i = 0; i < n; ++i) {
            int zero = ((current[i] >> bit) & 1u) == 0;
            zeros[level][i+1] = (uint8_t)(zeros[level][i]+zero);
            sums[level][i+1] = sums[level][i] + (zero ? current[i] : 0);
        }
        zero_total[level] = zeros[level][n];
        size_t a = 0, b = zero_total[level];
        for (size_t i = 0; i < n; ++i)
            next[((current[i] >> bit) & 1u) ? b++ : a++] = current[i];
        for (size_t i = 0; i < n; ++i) current[i] = next[i];
    }
    for (size_t i = 0; i < q; ++i) {
        size_t l = (size_t)input[2+n+3*i], r = (size_t)input[3+n+3*i];
        uint32_t upper = (uint32_t)input[4+n+3*i] + 1u;
        uint64_t count = 0, sum = 0;
        for (size_t level = 0; level < 30; ++level) {
            size_t zl = zeros[level][l], zr = zeros[level][r];
            if ((upper >> (29u-(unsigned)level)) & 1u) {
                count += zr-zl;
                sum += sums[level][r]-sums[level][l];
                l = zero_total[level] + l-zl;
                r = zero_total[level] + r-zr;
            } else { l = zl; r = zr; }
        }
        for (size_t byte = 0; byte < 8; ++byte) {
            output[16*i+byte] = (uint8_t)(count >> (8*byte));
            output[16*i+8+byte] = (uint8_t)(sum >> (8*byte));
        }
    }
    return (int64_t)(16*q);
}
