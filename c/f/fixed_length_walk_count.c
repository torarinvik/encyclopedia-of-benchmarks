/* Uncompiled exact-length directed walk counting draft. */
#include <stddef.h>
#include <stdint.h>

int64_t fixed_length_walk_count(const int64_t *input, size_t length) {
    const int64_t mod = 1000000007;
    if (!input || length < 4 || length > 261) return -1;
    int64_t nv = input[0], k = input[1], source = input[2], target = input[3];
    if (nv < 1 || nv > 16 || k < 0 || k > 1000000000 || source < 0 || source >= nv ||
        target < 0 || target >= nv || length != 4 + (size_t)(nv*nv)) return -1;
    size_t n = (size_t)nv;
    int64_t matrix[16][16] = {{0}}, next[16][16], vector[16] = {0}, temp[16];
    for (size_t i = 0; i < n; ++i) for (size_t j = 0; j < n; ++j) {
        int64_t x = input[4+i*n+j];
        if (x < 0 || x > 100) return -1;
        matrix[i][j] = x;
    }
    vector[source] = 1;
    while (k) {
        if (k & 1) {
            for (size_t j = 0; j < n; ++j) {
                temp[j] = 0;
                for (size_t i = 0; i < n; ++i)
                    temp[j] = (temp[j] + vector[i] * matrix[i][j]) % mod;
            }
            for (size_t i = 0; i < n; ++i) vector[i] = temp[i];
        }
        k >>= 1;
        if (k) {
            for (size_t i = 0; i < n; ++i) for (size_t j = 0; j < n; ++j) {
                next[i][j] = 0;
                for (size_t p = 0; p < n; ++p)
                    next[i][j] = (next[i][j] + matrix[i][p] * matrix[p][j]) % mod;
            }
            for (size_t i = 0; i < n; ++i) for (size_t j = 0; j < n; ++j) matrix[i][j] = next[i][j];
        }
    }
    return vector[target];
}
