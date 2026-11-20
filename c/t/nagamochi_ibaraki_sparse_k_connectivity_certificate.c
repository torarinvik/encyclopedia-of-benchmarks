#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define NI_MAX_N 8
#define NI_MAX_M 28
#define NI_MAX_INPUT 60

static void ni_put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) {
        out[at + i] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t nagamochi_ibaraki_sparse_k_connectivity_certificate(
        const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > NI_MAX_INPUT) return -1;
    int64_t n64 = input[0], m64 = input[1], k64 = input[2];
    if (n64 < 3 || n64 > NI_MAX_N || m64 < 0 || m64 > NI_MAX_M
            || k64 < 1 || k64 > 3 || length != 3 + 2 * (size_t)m64) return -1;
    size_t n = (size_t)n64, m = (size_t)m64, k = (size_t)k64;
    size_t u[NI_MAX_M], v[NI_MAX_M], incident[NI_MAX_N][NI_MAX_N] = {{0}};
    size_t degree[NI_MAX_N] = {0};
    for (size_t e = 0; e < m; ++e) {
        int64_t a = input[3 + 2 * e], b = input[4 + 2 * e];
        if (a < 0 || a >= b || b >= n64) return -1;
        u[e] = (size_t)a;
        v[e] = (size_t)b;
        for (size_t j = 0; j < e; ++j)
            if (u[j] == u[e] && v[j] == v[e]) return -1;
        incident[u[e]][degree[u[e]]++] = e;
        incident[v[e]][degree[v[e]]++] = e;
    }

    size_t bytes = 8 * (m + 1);
    if (output == NULL || capacity < bytes) return -2;

    size_t rank[NI_MAX_N] = {0}, layer[NI_MAX_M] = {0};
    bool scanned_vertex[NI_MAX_N] = {false}, scanned_edge[NI_MAX_M] = {false};
    for (size_t step = 0; step < n; ++step) {
        size_t x = n;
        for (size_t vertex = 0; vertex < n; ++vertex)
            if (!scanned_vertex[vertex] && (x == n || rank[vertex] > rank[x])) x = vertex;
        for (size_t slot = 0; slot < degree[x]; ++slot) {
            size_t e = incident[x][slot];
            if (scanned_edge[e]) continue;
            size_t y = u[e] == x ? v[e] : u[e];
            layer[e] = rank[y] + 1;
            if (rank[x] == rank[y]) ++rank[x];
            ++rank[y];
            scanned_edge[e] = true;
        }
        scanned_vertex[x] = true;
    }

    ni_put_i64(output, 0, (int64_t)m);
    for (size_t e = 0; e < m; ++e)
        ni_put_i64(output, 8 * (e + 1), (int64_t)(layer[e] <= k ? layer[e] : 0));
    return (int64_t)bytes;
}
