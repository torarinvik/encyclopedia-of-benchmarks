#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_M 24
#define MAX_INPUT 92

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) out[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t deterministic_linear_threshold_spread(const int64_t *input, size_t length,
                                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0], m_value = input[1], s_value = input[2];
    if (n_value < 1 || n_value > MAX_N || m_value < 0 || m_value > MAX_M ||
        s_value < 0 || s_value > n_value) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value, seeds_count = (size_t)s_value;
    if (length != 3 + seeds_count + 3 * m + n) return -1;
    size_t seed_offset = 3, edge_offset = seed_offset + seeds_count;
    size_t threshold_offset = edge_offset + 3 * m;
    uint8_t is_seed[MAX_N] = {0}, seen[MAX_N][MAX_N] = {{0}};
    int64_t head[MAX_N], edge_to[MAX_M], edge_weight[MAX_M], edge_next[MAX_M];
    int64_t incoming[MAX_N] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) head[vertex] = -1;
    for (size_t i = 0; i < seeds_count; ++i) {
        const int64_t seed = input[seed_offset + i];
        if (seed < 0 || (uint64_t)seed >= n || is_seed[seed]) return -1;
        is_seed[seed] = 1;
    }
    for (size_t i = 0; i < m; ++i) {
        const int64_t u = input[edge_offset + 3 * i];
        const int64_t v = input[edge_offset + 3 * i + 1];
        const int64_t w = input[edge_offset + 3 * i + 2];
        if (u < 0 || (uint64_t)u >= n || v < 0 || (uint64_t)v >= n || u == v ||
            w < 0 || w > 16 || seen[u][v]) return -1;
        seen[u][v] = 1;
        incoming[v] += w;
        if (incoming[v] > 16) return -1;
        edge_to[i] = v;
        edge_weight[i] = w;
        edge_next[i] = head[u];
        head[u] = (int64_t)i;
    }
    int64_t threshold[MAX_N], activation_round[MAX_N];
    for (size_t v = 0; v < n; ++v) {
        threshold[v] = input[threshold_offset + v];
        if (threshold[v] < 1 || threshold[v] > 16) return -1;
        activation_round[v] = is_seed[v] ? 0 : -1;
    }
    const size_t output_bytes = 8 * (n + 2);
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t accumulated[MAX_N] = {0};
    size_t frontier[MAX_N], following[MAX_N], frontier_count = 0;
    for (size_t v = 0; v < n; ++v) if (is_seed[v]) frontier[frontier_count++] = v;
    int64_t waves = 0;
    while (frontier_count != 0) {
        size_t following_count = 0;
        for (size_t i = 0; i < frontier_count; ++i) {
            const size_t source = frontier[i];
            for (int64_t e = head[source]; e >= 0; e = edge_next[e]) {
                const size_t target = (size_t)edge_to[e];
                if (activation_round[target] >= 0) continue;
                accumulated[target] += edge_weight[e];
                if (accumulated[target] >= threshold[target]) {
                    activation_round[target] = waves + 1;
                    following[following_count++] = target;
                }
            }
        }
        frontier_count = following_count;
        for (size_t i = 0; i < following_count; ++i) frontier[i] = following[i];
        if (following_count != 0) ++waves;
    }
    store_i64_le(output, 0, n_value);
    store_i64_le(output, 8, waves);
    for (size_t v = 0; v < n; ++v) store_i64_le(output, 8 * (v + 2), activation_round[v]);
    return (int64_t)output_bytes;
}
