/* Clean-room bounded GBBS k-core profile; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 2 + 2 * MAX_M };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t gbbs_k_core_decomposition(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;
    const int n = (int)n64, m = (int)m64;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    for (int edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * (size_t)edge];
        const int64_t v64 = input[3 + 2 * (size_t)edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const int u = (int)u64, v = (int)v64;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = 1;
    }
    const size_t output_bytes = 8 * (size_t)n;
    if (output == NULL || capacity < output_bytes) return -2;

    int degree[MAX_N] = {0}, core[MAX_N] = {0};
    int alive[MAX_N], shell[MAX_N];
    for (int u = 0; u < n; ++u) {
        alive[u] = 1;
        for (int v = 0; v < n; ++v) degree[u] += adjacent[u][v] != 0;
    }
    int remaining = n;
    while (remaining > 0) {
        int k = n;
        for (int u = 0; u < n; ++u)
            if (alive[u] && degree[u] < k) k = degree[u];
        for (int u = 0; u < n; ++u) {
            shell[u] = alive[u] && degree[u] == k;
            if (shell[u]) { alive[u] = 0; core[u] = k; --remaining; }
        }
        for (int v = 0; v < n; ++v) if (alive[v]) {
            int removed = 0;
            for (int u = 0; u < n; ++u) removed += shell[u] && adjacent[u][v];
            if (removed > 0) {
                int next = degree[v] - removed;
                degree[v] = next < k ? k : next;
            }
        }
    }
    for (int u = 0; u < n; ++u) store_i64_le(output, 8 * (size_t)u, core[u]);
    return (int64_t)output_bytes;
}
