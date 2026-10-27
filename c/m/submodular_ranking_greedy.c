#include <stddef.h>
#include <stdint.h>

#define MAX_N 5
#define MAX_M 4
#define MAX_SUBSETS 32
#define MAX_INPUT 131

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) { out[offset + b] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t submodular_ranking_greedy(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 1 || m64 > MAX_M) return -1;
    size_t n = (size_t)n64, m = (size_t)m64, size = (size_t)1 << n;
    if (length != 2 + m * size) return -1;
    int64_t f[MAX_M][MAX_SUBSETS] = {{0}};
    for (size_t i = 0; i < m; ++i) {
        for (size_t mask = 0; mask < size; ++mask) {
            int64_t v = input[2 + i * size + mask];
            if (v < 0 || v > 8) return -1;
            f[i][mask] = v;
        }
        if (f[i][0] != 0 || f[i][size - 1] != 8) return -1;
        for (size_t a = 0; a < size; ++a) for (size_t bit = 0; bit < n; ++bit) {
            size_t b = (size_t)1 << bit;
            if ((a & b) == 0 && f[i][a] > f[i][a | b]) return -1;
        }
        for (size_t a = 0; a < size; ++a) for (size_t b = 0; b < size; ++b) {
            if ((a & b) != a) continue;
            for (size_t bit = 0; bit < n; ++bit) {
                size_t e = (size_t)1 << bit;
                if ((b & e) == 0 && f[i][a | e] - f[i][a] < f[i][b | e] - f[i][b]) return -1;
            }
        }
    }
    size_t out_bytes = 8 * (1 + n + m);
    if (output == NULL || capacity < out_bytes) return -2;
    size_t order[MAX_N], mask = 0;
    int64_t times[MAX_M] = {0}, total = 0;
    for (size_t t = 1; t <= n; ++t) {
        size_t winner = 0;
        int64_t best_num = -1, best_den = 1;
        for (size_t e = 0; e < n; ++e) {
            size_t bit = (size_t)1 << e;
            if (mask & bit) continue;
            int64_t num = 0, den = 1;
            for (size_t i = 0; i < m; ++i) {
                int64_t cur = f[i][mask];
                if (cur == 8) continue;
                int64_t d = 8 - cur, gain = f[i][mask | bit] - cur;
                num = num * d + gain * den;
                den *= d;
            }
            if (best_num < 0 || num * best_den > best_num * den) {
                winner = e; best_num = num; best_den = den;
            }
        }
        mask |= (size_t)1 << winner;
        order[t - 1] = winner;
        for (size_t i = 0; i < m; ++i) if (times[i] == 0 && f[i][mask] == 8) {
            times[i] = (int64_t)t; total += (int64_t)t;
        }
    }
    store_i64_le(output, 0, total);
    for (size_t j = 0; j < n; ++j) store_i64_le(output, 8 * (1 + j), (int64_t)order[j]);
    for (size_t i = 0; i < m; ++i) store_i64_le(output, 8 * (1 + n + i), times[i]);
    return (int64_t)out_bytes;
}
