#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_M = 66, MAX_Q = 32, MAX_INPUT = 266, MAX_OUTPUT = 264 };
#define INF INT64_C(0x3fffffffffffffff)

static void put_i64_le(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (unsigned b = 0; b < 8; ++b) out[at + b] = (uint8_t)(bits >> (8u * b));
}

int64_t thorup_zwick_distance_oracle(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], m64 = input[1], mask = input[2];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M) return -1;
    int n = (int)n64, m = (int)m64;
    if (mask <= 0 || ((uint64_t)mask >> (unsigned)n) != 0) return -1;
    size_t q_at = 3u + 3u * (size_t)m;
    if (q_at >= length) return -1;
    int64_t q64 = input[q_at];
    if (q64 < 0 || q64 > MAX_Q || length != q_at + 1u + 2u * (size_t)q64) return -1;
    int q = (int)q64;

    int64_t d[MAX_N][MAX_N];
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j) d[i][j] = i == j ? 0 : INF;
    for (int e = 0; e < m; ++e) {
        int64_t u64 = input[3 + 3 * e], v64 = input[4 + 3 * e], w = input[5 + 3 * e];
        if (u64 < 0 || v64 <= u64 || v64 >= n || w < 1 || w > 1000) return -1;
        int u = (int)u64, v = (int)v64;
        if (d[u][v] != INF) return -1;
        d[u][v] = d[v][u] = w;
    }
    for (int k = 0; k < n; ++k)
        for (int i = 0; i < n; ++i)
            for (int j = 0; j < n; ++j)
                if (d[i][k] != INF && d[k][j] != INF && d[i][k] + d[k][j] < d[i][j])
                    d[i][j] = d[i][k] + d[k][j];
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            if (d[i][j] == INF) return -1;

    int nearest[MAX_N];
    int64_t nearest_d[MAX_N];
    for (int v = 0; v < n; ++v) {
        nearest[v] = -1; nearest_d[v] = INF;
        for (int a = 0; a < n; ++a) if (((uint64_t)mask >> (unsigned)a) & 1u) {
            if (d[v][a] < nearest_d[v] || (d[v][a] == nearest_d[v] && a < nearest[v])) {
                nearest[v] = a; nearest_d[v] = d[v][a];
            }
        }
    }
    uint8_t bunch[MAX_N][MAX_N] = {{0}};
    for (int u = 0; u < n; ++u) {
        for (int x = 0; x < n; ++x) {
            if (((uint64_t)mask >> (unsigned)x) & 1u) bunch[u][x] = 1;
            else if (d[u][x] < nearest_d[u]) bunch[u][x] = 1;
        }
    }

    int64_t staged[MAX_Q + 1] = {0};
    staged[0] = q;
    for (int qi = 0; qi < q; ++qi) {
        int64_t u64 = input[q_at + 1u + 2u * (size_t)qi];
        int64_t v64 = input[q_at + 2u + 2u * (size_t)qi];
        if (u64 < 0 || u64 >= n || v64 < 0 || v64 >= n) return -1;
        int u = (int)u64, v = (int)v64;
        int found = 0;
        for (int level = 0; level < 2; ++level) {
            int pivot = level == 0 ? v : nearest[v];
            if (bunch[u][pivot]) {
                staged[qi + 1] = d[u][pivot] + d[v][pivot];
                found = 1; break;
            }
            int tmp = u; u = v; v = tmp;
        }
        if (!found) return -1;
    }
    size_t bytes = 8u * (size_t)(q + 1);
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < (size_t)q + 1u; ++i) put_i64_le(output, 8u * i, staged[i]);
    return (int64_t)bytes;
}
