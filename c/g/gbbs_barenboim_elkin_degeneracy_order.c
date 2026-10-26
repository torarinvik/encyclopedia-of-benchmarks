/* Clean-room bounded GBBS Barenboim-Elkin profile; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 20, MAX_M = 190, MAX_INPUT = 2 + 2 * MAX_M };

static void store_i64_le(uint8_t *output, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { output[byte] = (uint8_t)(bits & 255u); bits >>= 8; }
}

int64_t gbbs_barenboim_elkin_degeneracy_order(const int64_t *input, size_t length,
                                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || length != 2 + 2 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    int64_t initial_degree[MAX_N] = {0};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = 1;
        ++initial_degree[u]; ++initial_degree[v];
    }
    if (output == NULL || capacity < 8 * n) return -2;

    int64_t degree[MAX_N];
    uint8_t alive[MAX_N] = {0};
    for (size_t v = 0; v < n; ++v) { degree[v] = initial_degree[v]; alive[v] = 1; }
    size_t remaining = n;
    int64_t best_num = 0, best_den = 1;
    while (remaining > 0) {
        int64_t total = 0;
        for (size_t v = 0; v < n; ++v) if (alive[v]) total += degree[v];
        if (total * best_den > best_num * (int64_t)remaining) { best_num = total; best_den = (int64_t)remaining; }
        uint8_t removed[MAX_N] = {0};
        size_t count = 0;
        for (size_t v = 0; v < n; ++v)
            if (alive[v] && 10 * degree[v] * (int64_t)remaining <= 11 * total) { removed[v] = 1; ++count; }
        if (count == 0) return -1;
        for (size_t v = 0; v < n; ++v) if (removed[v]) alive[v] = 0;
        remaining -= count;
        for (size_t v = 0; v < n; ++v) if (alive[v]) {
            int64_t dec = 0;
            for (size_t u = 0; u < n; ++u) dec += removed[u] && adjacent[v][u];
            degree[v] -= dec;
        }
    }
    int64_t cutoff = (best_num + 10 * best_den - 1) / (10 * best_den);
    if (cutoff < 1) cutoff = 1;

    for (size_t v = 0; v < n; ++v) { degree[v] = initial_degree[v]; alive[v] = 1; }
    size_t order[MAX_N], used = 0;
    while (used < n) {
        size_t shell[MAX_N], count = 0;
        for (size_t v = 0; v < n; ++v) if (alive[v] && degree[v] < cutoff) shell[count++] = v;
        if (count == 0) {
            for (size_t v = 0; v < n; ++v) if (alive[v]) { shell[count++] = v; break; }
        }
        for (size_t i = 0; i < count; ++i) { alive[shell[i]] = 0; order[used++] = shell[i]; }
        for (size_t v = 0; v < n; ++v) if (alive[v]) {
            int64_t dec = 0;
            for (size_t i = 0; i < count; ++i) dec += adjacent[v][shell[i]] != 0;
            degree[v] -= dec;
        }
    }
    int64_t rank[MAX_N];
    for (size_t i = 0; i < n; ++i) rank[order[i]] = (int64_t)i;
    for (size_t v = 0; v < n; ++v) store_i64_le(output + 8 * v, rank[v]);
    return (int64_t)(8 * n);
}
