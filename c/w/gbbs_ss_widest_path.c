/* Clean-room bounded GBBS widest-path profile; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 3 + 3 * MAX_M };
static const int64_t SOURCE_INFINITY = INT64_C(2147483647);

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t gbbs_ss_widest_path(const int64_t *input, size_t length,
                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1], source64 = input[2];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        source64 < 0 || source64 >= n64 || length != 3 + 3 * (size_t)m64) return -1;
    const int n = (int)n64, m = (int)m64, source = (int)source64;
    int edge_from[MAX_M], edge_to[MAX_M], edge_capacity[MAX_M];
    for (int edge = 0; edge < m; ++edge) {
        const int64_t from = input[3 + 3 * (size_t)edge];
        const int64_t to = input[4 + 3 * (size_t)edge];
        const int64_t edge_width = input[5 + 3 * (size_t)edge];
        if (from < 0 || from >= n64 || to < 0 || to >= n64 || edge_width < 1 || edge_width > 32) return -1;
        edge_from[edge] = (int)from;
        edge_to[edge] = (int)to;
        edge_capacity[edge] = (int)edge_width;
    }
    const size_t output_bytes = 8 * (size_t)n;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t width[MAX_N] = {0};
    int settled[MAX_N] = {0};
    width[source] = SOURCE_INFINITY;
    for (int step = 0; step < n; ++step) {
        int u = -1;
        for (int vertex = 0; vertex < n; ++vertex) {
            if (!settled[vertex] && (u < 0 || width[vertex] > width[u])) u = vertex;
        }
        if (u < 0 || width[u] == 0) break;
        settled[u] = 1;
        for (int edge = 0; edge < m; ++edge) {
            if (edge_from[edge] != u) continue;
            const int v = edge_to[edge];
            if (settled[v]) continue;
            const int64_t candidate = width[u] < edge_capacity[edge] ? width[u] : edge_capacity[edge];
            if (candidate > width[v]) width[v] = candidate;
        }
    }
    for (int vertex = 0; vertex < n; ++vertex) store_i64_le(output, 8 * (size_t)vertex, width[vertex]);
    return (int64_t)output_bytes;
}
