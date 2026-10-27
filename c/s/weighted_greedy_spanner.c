#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 28, MAX_INPUT = 88 };

int64_t weighted_greedy_spanner(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1], k = input[2];
    if (n64 < 2 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || k < 1 || k > 3 ||
        length != 3 + 3 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    int64_t edge_u[MAX_M], edge_v[MAX_M], edge_w[MAX_M];
    size_t order[MAX_M];
    int64_t distance[MAX_N];
    int settled[MAX_N];
    int64_t adjacency[MAX_N][MAX_N] = {{0}};
    uint8_t selected[MAX_M] = {0};
    for (size_t i = 0; i < m; ++i) {
        edge_u[i] = input[3 + 3 * i];
        edge_v[i] = input[4 + 3 * i];
        edge_w[i] = input[5 + 3 * i];
        if (edge_u[i] < 0 || edge_v[i] <= edge_u[i] || edge_v[i] >= n64 ||
            edge_w[i] < 1 || edge_w[i] > 32) return -1;
        for (size_t j = 0; j < i; ++j)
            if (edge_u[i] == edge_u[j] && edge_v[i] == edge_v[j]) return -1;
        order[i] = i;
    }
    for (size_t i = 1; i < m; ++i) {
        const size_t key = order[i];
        size_t pos = i;
        while (pos > 0) {
            const size_t prev = order[pos - 1];
            if (edge_w[prev] < edge_w[key] ||
                (edge_w[prev] == edge_w[key] && edge_u[prev] < edge_u[key]) ||
                (edge_w[prev] == edge_w[key] && edge_u[prev] == edge_u[key] && edge_v[prev] <= edge_v[key])) break;
            order[pos] = prev;
            --pos;
        }
        order[pos] = key;
    }
    if (output == NULL || capacity < m) return -2;
    for (size_t rank = 0; rank < m; ++rank) {
        const size_t edge = order[rank];
        const size_t source = (size_t)edge_u[edge], target = (size_t)edge_v[edge];
        for (size_t v = 0; v < n; ++v) { distance[v] = INT64_C(1) << 60; settled[v] = 0; }
        distance[source] = 0;
        for (size_t step = 0; step < n; ++step) {
            size_t vertex = n;
            for (size_t v = 0; v < n; ++v)
                if (!settled[v] && (vertex == n || distance[v] < distance[vertex])) vertex = v;
            if (vertex == n || distance[vertex] == (INT64_C(1) << 60)) break;
            settled[vertex] = 1;
            for (size_t v = 0; v < n; ++v)
                if (adjacency[vertex][v] > 0 && distance[v] > distance[vertex] + adjacency[vertex][v])
                    distance[v] = distance[vertex] + adjacency[vertex][v];
        }
        if (distance[target] > (2 * k - 1) * edge_w[edge]) {
            selected[edge] = 1;
            adjacency[source][target] = adjacency[target][source] = edge_w[edge];
        }
    }
    for (size_t i = 0; i < m; ++i) output[i] = selected[i];
    return (int64_t)m;
}
