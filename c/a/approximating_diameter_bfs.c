#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[b] = (uint8_t)(bits >> (8 * b));
}

int64_t approximating_diameter_bfs(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 242) return -1;
    const int64_t n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 16 || m0 < 0 || m0 > 120 || length != 2 + 2 * (size_t)m0) return -1;
    const size_t n = (size_t)n0, m = (size_t)m0;
    uint8_t adj[16][16] = {{0}};
    for (size_t i = 0; i < m; ++i) {
        const int64_t u0 = input[2 + 2*i], v0 = input[3 + 2*i];
        if (u0 < 0 || v0 <= u0 || v0 >= n0) return -1;
        const size_t u = (size_t)u0, v = (size_t)v0;
        if (adj[u][v]) return -1;
        adj[u][v] = adj[v][u] = 1;
    }
    int64_t dist[16]; size_t queue[16];
    for (size_t i = 0; i < n; ++i) dist[i] = -1;
    dist[0] = 0; queue[0] = 0;
    size_t head = 0, tail = 1;
    while (head < tail) {
        const size_t u = queue[head++];
        for (size_t v = 0; v < n; ++v) if (adj[u][v] && dist[v] < 0) {
            dist[v] = dist[u] + 1; queue[tail++] = v;
        }
    }
    if (tail != n) return -1;
    int64_t estimate = 0;
    for (size_t i = 0; i < n; ++i) if (dist[i] > estimate) estimate = dist[i];
    if (!output || capacity < 8) return -2;
    put_i64(output, estimate);
    return 8;
}
