/* Clean-room bounded GARDENIA Gebremedhin-Manne coloring profile. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 130, MAX_COLOR = 128 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t gardenia_gm_vertex_coloring(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;
    const int n = (int)n64, m = (int)m64;
    uint8_t adjacent[MAX_N * MAX_N] = {0};
    for (int e = 0; e < m; ++e) {
        const int64_t u64 = input[2 + 2 * (size_t)e];
        const int64_t v64 = input[3 + 2 * (size_t)e];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacent[u * MAX_N + v]) return -1;
        adjacent[u * MAX_N + v] = adjacent[v * MAX_N + u] = 1;
    }
    const size_t output_bytes = 8 * (size_t)n;
    if (output == NULL || capacity < output_bytes) return -2;
    int colors[MAX_N], prior[MAX_N], pending[MAX_N], next_pending[MAX_N];
    int pending_count = n;
    for (int u = 0; u < n; ++u) {
        colors[u] = MAX_COLOR;
        pending[u] = u;
    }
    int rounds = 0;
    while (pending_count > 0) {
        if (++rounds > n + 1) return -1;
        for (int u = 0; u < n; ++u) prior[u] = colors[u];
        for (int item = 0; item < pending_count; ++item) {
            const int u = pending[item];
            uint8_t forbidden[MAX_N] = {0};
            for (int v = 0; v < n; ++v)
                if (adjacent[(size_t)u * MAX_N + (size_t)v] && prior[v] != MAX_COLOR)
                    forbidden[prior[v]] = 1;
            int color = 0;
            while (color < MAX_COLOR && forbidden[color]) ++color;
            if (color >= MAX_COLOR) return -1;
            colors[u] = color;
        }
        int next_count = 0;
        for (int item = 0; item < pending_count; ++item) {
            const int u = pending[item];
            int conflict = 0;
            for (int v = u + 1; v < n; ++v)
                if (adjacent[(size_t)u * MAX_N + (size_t)v] && colors[u] == colors[v]) {
                    conflict = 1;
                    break;
                }
            if (conflict) {
                colors[u] = MAX_COLOR;
                next_pending[next_count++] = u;
            }
        }
        pending_count = next_count;
        for (int item = 0; item < pending_count; ++item) pending[item] = next_pending[item];
    }
    for (int u = 0; u < n; ++u) store_i64_le(output, 8 * (size_t)u, colors[u]);
    return (int64_t)output_bytes;
}
