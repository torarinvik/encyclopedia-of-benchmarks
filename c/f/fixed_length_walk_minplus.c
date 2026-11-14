/* Uncompiled exact-length shortest-walk draft. */
#include <stddef.h>
#include <stdint.h>

#define FLW_INF INT64_C(1000000000000000)

int64_t fixed_length_walk_minplus(const int64_t *input, size_t length) {
    if (!input || length < 4 || length > 261) return -100000002;
    int64_t nv = input[0], k = input[1], s = input[2], t = input[3];
    if (nv < 1 || nv > 16 || k < 0 || k > 1000000 ||
        s < 0 || s >= nv || t < 0 || t >= nv || length != 4 + (size_t)(nv*nv))
        return -100000002;
    size_t n = (size_t)nv;
    int64_t matrix[16][16], next[16][16], distance[16], temp[16];
    for (size_t i = 0; i < n; ++i) {
        distance[i] = i == (size_t)s ? 0 : FLW_INF;
        for (size_t j = 0; j < n; ++j) {
            int64_t x = input[4 + i*n+j];
            if (x != 1000000 && (x < -100 || x > 100)) return -100000002;
            matrix[i][j] = x == 1000000 ? FLW_INF : x;
        }
    }
    while (k) {
        if (k & 1) {
            for (size_t j = 0; j < n; ++j) {
                temp[j] = FLW_INF;
                for (size_t i = 0; i < n; ++i)
                    if (distance[i] != FLW_INF && matrix[i][j] != FLW_INF &&
                        distance[i] + matrix[i][j] < temp[j])
                        temp[j] = distance[i] + matrix[i][j];
            }
            for (size_t i = 0; i < n; ++i) distance[i] = temp[i];
        }
        k >>= 1;
        if (k) {
            for (size_t i = 0; i < n; ++i)
                for (size_t j = 0; j < n; ++j) {
                    next[i][j] = FLW_INF;
                    for (size_t p = 0; p < n; ++p)
                        if (matrix[i][p] != FLW_INF && matrix[p][j] != FLW_INF &&
                            matrix[i][p] + matrix[p][j] < next[i][j])
                            next[i][j] = matrix[i][p] + matrix[p][j];
                }
            for (size_t i = 0; i < n; ++i)
                for (size_t j = 0; j < n; ++j) matrix[i][j] = next[i][j];
        }
    }
    return distance[t] == FLW_INF ? -100000001 : distance[t];
}
