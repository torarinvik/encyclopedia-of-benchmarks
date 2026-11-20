#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 9, MAX_INPUT_LENGTH = 111 };
static const int64_t INF = INT64_C(1) << 60;

static void store_i64_le(uint8_t *output, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t minimum_weight_cycle_floyd(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    if (n_value < 3 || n_value > MAX_N || m_value < 0
            || m_value > n_value * (n_value - 1) / 2) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value;
    if (length != 2 + 3 * m) return -1;

    int64_t edge[MAX_N][MAX_N];
    int64_t dist[MAX_N][MAX_N];
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) edge[i][j] = i == j ? 0 : INF;
    }
    for (size_t e = 0; e < m; ++e) {
        const size_t offset = 2 + 3 * e;
        const int64_t u_value = input[offset], v_value = input[offset + 1];
        const int64_t weight = input[offset + 2];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
                || u_value == v_value || weight < 1 || weight > 1000) return -1;
        const size_t u = (size_t)u_value, v = (size_t)v_value;
        if (edge[u][v] != INF) return -1;
        edge[u][v] = edge[v][u] = weight;
    }

    if (output == NULL || capacity < 8) return -2;
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j) dist[i][j] = edge[i][j];

    int64_t best = INF;
    for (size_t k = 0; k < n; ++k) {
        for (size_t i = 0; i < k; ++i) {
            if (edge[i][k] == INF) continue;
            for (size_t j = i + 1; j < k; ++j) {
                if (edge[k][j] == INF || dist[i][j] == INF) continue;
                const int64_t candidate = edge[i][k] + edge[k][j] + dist[i][j];
                if (candidate < best) best = candidate;
            }
        }
        for (size_t i = 0; i < n; ++i) {
            if (dist[i][k] == INF) continue;
            for (size_t j = 0; j < n; ++j) {
                if (dist[k][j] == INF) continue;
                const int64_t candidate = dist[i][k] + dist[k][j];
                if (candidate < dist[i][j]) dist[i][j] = candidate;
            }
        }
    }
    store_i64_le(output, best == INF ? -1 : best);
    return 8;
}
