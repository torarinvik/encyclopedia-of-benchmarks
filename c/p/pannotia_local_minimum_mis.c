#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_M 64
#define MAX_INPUT (2 + MAX_N + 2 * MAX_M)
#define MAX_PRIORITY INT64_C(99999998)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t pannotia_local_minimum_mis(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + (size_t)n64 + 2 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    uint64_t adjacency[MAX_N] = {0};
    int64_t priority[MAX_N];
    for (size_t v = 0; v < n; ++v) {
        priority[v] = input[2 + v];
        if (priority[v] < 0 || priority[v] > MAX_PRIORITY) return -1;
        for (size_t prior = 0; prior < v; ++prior)
            if (priority[prior] == priority[v]) return -1;
    }
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + n + 2 * edge];
        const int64_t v64 = input[3 + n + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if ((adjacency[u] & (UINT64_C(1) << v)) != 0) return -1;
        adjacency[u] |= UINT64_C(1) << v;
        adjacency[v] |= UINT64_C(1) << u;
    }
    const size_t output_bytes = 8 * n;
    if (output == NULL || capacity < output_bytes) return -2;

    int active[MAX_N] = {0};
    int selected[MAX_N] = {0};
    for (size_t v = 0; v < n; ++v) active[v] = 1;
    for (;;) {
        int chosen[MAX_N] = {0};
        size_t chosen_count = 0;
        for (size_t v = 0; v < n; ++v) {
            if (!active[v]) continue;
            int local_minimum = 1;
            for (size_t u = 0; u < n; ++u)
                if (active[u] && (adjacency[v] & (UINT64_C(1) << u)) != 0 && priority[u] < priority[v])
                    local_minimum = 0;
            if (local_minimum) { chosen[v] = 1; ++chosen_count; }
        }
        if (chosen_count == 0) return -1;
        for (size_t v = 0; v < n; ++v) {
            if (!chosen[v]) continue;
            selected[v] = 1;
            active[v] = 0;
        }
        for (size_t v = 0; v < n; ++v) {
            if (!chosen[v]) continue;
            for (size_t u = 0; u < n; ++u)
                if (active[u] && (adjacency[v] & (UINT64_C(1) << u)) != 0) active[u] = 0;
        }
        size_t remaining = 0;
        for (size_t v = 0; v < n; ++v) remaining += (size_t)active[v];
        if (remaining == 0) break;
    }
    for (size_t v = 0; v < n; ++v) store_i64_le(output, 8 * v, selected[v] ? 2 : 0);
    return (int64_t)output_bytes;
}
