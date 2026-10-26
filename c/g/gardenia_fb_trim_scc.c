/* Clean-room bounded GARDENIA Forward-Backward-Trim SCC profile. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 130, MAX_TASKS = 34 };

static uint32_t reach(uint32_t active, int pivot, const uint8_t *adj,
                      int reverse, int n) {
    uint32_t seen = UINT32_C(1) << pivot;
    for (;;) {
        uint32_t expanded = seen;
        for (int u = 0; u < n; ++u) {
            const uint32_t ub = UINT32_C(1) << u;
            if (!(seen & ub) || !(active & ub)) continue;
            for (int v = 0; v < n; ++v) {
                const uint32_t vb = UINT32_C(1) << v;
                const int edge = reverse ? adj[(size_t)v * MAX_N + (size_t)u]
                                         : adj[(size_t)u * MAX_N + (size_t)v];
                if ((active & vb) && edge) expanded |= vb;
            }
        }
        if (expanded == seen) return seen;
        seen = expanded;
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t gardenia_fb_trim_scc(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;
    const int n = (int)n64, m = (int)m64;
    uint8_t adj[MAX_N * MAX_N] = {0};
    for (int e = 0; e < m; ++e) {
        const int64_t u64 = input[2 + 2 * (size_t)e];
        const int64_t v64 = input[3 + 2 * (size_t)e];
        if (u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adj[u * MAX_N + v]) return -1;
        adj[u * MAX_N + v] = 1;
    }
    const size_t output_bytes = 8 * (size_t)n;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t labels[MAX_N] = {0};
    uint32_t tasks[MAX_TASKS] = {0};
    size_t task_count = 1;
    tasks[0] = (UINT32_C(1) << n) - 1;
    while (task_count > 0) {
        uint32_t active = tasks[--task_count];
        while (active != 0) {
            uint32_t trimmed = 0;
            for (int u = 0; u < n; ++u) {
                const uint32_t ub = UINT32_C(1) << u;
                if (!(active & ub)) continue;
                int has_in = 0, has_out = 0;
                for (int v = 0; v < n; ++v) {
                    const uint32_t vb = UINT32_C(1) << v;
                    if (!(active & vb)) continue;
                    has_out |= adj[(size_t)u * MAX_N + (size_t)v];
                    has_in |= adj[(size_t)v * MAX_N + (size_t)u];
                }
                if (!has_in || !has_out) trimmed |= ub;
            }
            if (trimmed == 0) break;
            for (int u = 0; u < n; ++u)
                if (trimmed & (UINT32_C(1) << u)) labels[u] = u;
            active &= ~trimmed;
        }
        if (active == 0) continue;
        int pivot = 0;
        while (!(active & (UINT32_C(1) << pivot))) ++pivot;
        const uint32_t forward = reach(active, pivot, adj, 0, n);
        const uint32_t backward = reach(active, pivot, adj, 1, n);
        const uint32_t component = forward & backward;
        int representative = 0;
        while (!(component & (UINT32_C(1) << representative))) ++representative;
        for (int u = 0; u < n; ++u)
            if (component & (UINT32_C(1) << u)) labels[u] = representative;
        const uint32_t children[3] = {
            active & ~(forward | backward), forward & ~backward, backward & ~forward
        };
        for (int child = 0; child < 3; ++child) if (children[child]) {
            if (task_count >= MAX_TASKS) return -1;
            tasks[task_count++] = children[child];
        }
    }
    for (int u = 0; u < n; ++u) store_i64_le(output, 8 * (size_t)u, labels[u]);
    return (int64_t)output_bytes;
}
