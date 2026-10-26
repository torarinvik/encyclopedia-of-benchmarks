#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_M 64
#define MAX_INPUT (3 + MAX_N + 2 * MAX_M)
#define MAX_PRIORITY INT64_C(99999998)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t pannotia_priority_coloring(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1], mode64 = input[2];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        (mode64 != 0 && mode64 != 1) ||
        length != 3 + (size_t)n64 + 2 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    const int mode = (int)mode64;
    uint64_t adjacency[MAX_N] = {0};
    size_t degree[MAX_N] = {0};
    int64_t priority[MAX_N];
    int64_t color[MAX_N];
    int active[MAX_N] = {0};
    for (size_t v = 0; v < n; ++v) {
        priority[v] = input[3 + v];
        if (priority[v] < 0 || priority[v] > MAX_PRIORITY) return -1;
        for (size_t prior = 0; prior < v; ++prior)
            if (priority[prior] == priority[v]) return -1;
        color[v] = -1;
        active[v] = 1;
    }
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[3 + n + 2 * edge];
        const int64_t v64 = input[4 + n + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacency[u] & (UINT64_C(1) << v)) return -1;
        adjacency[u] |= UINT64_C(1) << v;
        adjacency[v] |= UINT64_C(1) << u;
        ++degree[u]; ++degree[v];
    }
    for (size_t v = 0; v < n; ++v) if (degree[v] == 1) return -1;
    const size_t output_bytes = 8 * n;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t current_color = 1;
    for (;;) {
        int chosen[MAX_N] = {0};
        size_t chosen_count = 0;
        for (size_t v = 0; v < n; ++v) {
            if (!active[v]) continue;
            int64_t maximum = -1, minimum = INT64_C(99999999);
            for (size_t u = 0; u < n; ++u) {
                if (active[u] && (adjacency[v] & (UINT64_C(1) << u))) {
                    if (priority[u] > maximum) maximum = priority[u];
                    if (priority[u] < minimum) minimum = priority[u];
                }
            }
            if (priority[v] > maximum) { color[v] = current_color; chosen[v] = 1; }
            if (mode == 1 && priority[v] < minimum) { color[v] = current_color + 1; chosen[v] = 1; }
            if (chosen[v]) ++chosen_count;
        }
        if (chosen_count == 0) return -1;
        for (size_t v = 0; v < n; ++v) if (chosen[v]) active[v] = 0;
        size_t remaining = 0;
        for (size_t v = 0; v < n; ++v) remaining += (size_t)active[v];
        if (remaining == 0) break;
        current_color += mode == 1 ? 2 : 1;
    }
    for (size_t v = 0; v < n; ++v) store_i64_le(output, 8 * v, color[v]);
    return (int64_t)output_bytes;
}
