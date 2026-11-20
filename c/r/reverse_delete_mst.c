#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 20, MAX_INPUT = 63 };

typedef struct { int32_t u, v, weight; } edge_t;

static int graph_connected(int n, const edge_t *edges, int m, uint32_t active) {
    int seen[MAX_N] = {0};
    int queue[MAX_N];
    int head = 0, tail = 0;
    seen[0] = 1;
    queue[tail++] = 0;
    while (head < tail) {
        const int vertex = queue[head++];
        for (int id = 0; id < m; ++id) {
            if (((active >> id) & 1u) == 0) continue;
            int neighbor = -1;
            if (edges[id].u == vertex) neighbor = edges[id].v;
            else if (edges[id].v == vertex) neighbor = edges[id].u;
            if (neighbor >= 0 && !seen[neighbor]) {
                seen[neighbor] = 1;
                queue[tail++] = neighbor;
            }
        }
    }
    for (int vertex = 0; vertex < n; ++vertex)
        if (!seen[vertex]) return 0;
    return 1;
}

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        out[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t reverse_delete_mst(const int64_t *input, size_t length,
                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 2 || input[0] > MAX_N || input[1] < input[0] - 1 || input[1] > MAX_M) return -1;
    const int n = (int)input[0];
    const int m = (int)input[1];
    if (length != (size_t)(2 + 3 * m)) return -1;

    edge_t edges[MAX_M];
    int order[MAX_M];
    for (int id = 0; id < m; ++id) {
        const int64_t u = input[2 + 3 * id];
        const int64_t v = input[3 + 3 * id];
        const int64_t w = input[4 + 3 * id];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v || w < 0 || w > 1000) return -1;
        edges[id] = (edge_t){(int32_t)u, (int32_t)v, (int32_t)w};
        order[id] = id;
        const int low = u < v ? (int)u : (int)v;
        const int high = u < v ? (int)v : (int)u;
        for (int prior = 0; prior < id; ++prior) {
            const int prior_low = edges[prior].u < edges[prior].v ? edges[prior].u : edges[prior].v;
            const int prior_high = edges[prior].u < edges[prior].v ? edges[prior].v : edges[prior].u;
            if (low == prior_low && high == prior_high) return -1;
        }
    }
    for (int i = 1; i < m; ++i) {
        const int item = order[i];
        int j = i;
        while (j > 0 && (edges[order[j - 1]].weight < edges[item].weight ||
               (edges[order[j - 1]].weight == edges[item].weight && order[j - 1] < item))) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = item;
    }

    uint32_t active = (1u << m) - 1u;
    if (!graph_connected(n, edges, m, active)) return -1;
    for (int position = 0; position < m; ++position) {
        const uint32_t candidate = active & ~(1u << order[position]);
        if (graph_connected(n, edges, m, candidate)) active = candidate;
    }
    int64_t total_weight = 0;
    for (int id = 0; id < m; ++id)
        if ((active >> id) & 1u) total_weight += edges[id].weight;
    if (output == NULL || capacity < 16) return -2;
    store_i64_le(output, 0, (int64_t)active);
    store_i64_le(output, 8, total_weight);
    return 16;
}
