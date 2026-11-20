#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_EDGES = 15, MAX_ARCS = 30, MAX_INPUT_LENGTH = 48 };

static int root_of(int parent[MAX_N], int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tree_random_walk_edge_hitting_cost(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0], root_value = input[1];
    if (n_value < 1 || n_value > MAX_N || root_value < 0 || root_value >= n_value)
        return -1;
    const int n = (int)n_value, root = (int)root_value, edge_count = n - 1;
    if (length != 2 + 3 * (size_t)edge_count) return -1;

    int head[MAX_N], to[MAX_ARCS], next[MAX_ARCS];
    int set_parent[MAX_N];
    int input_u[MAX_EDGES], input_v[MAX_EDGES];
    int64_t incident_sum[MAX_N] = {0}, down[MAX_N] = {0}, up[MAX_N] = {0};
    for (int vertex = 0; vertex < n; ++vertex) {
        head[vertex] = -1;
        set_parent[vertex] = vertex;
    }

    int arc_count = 0;
    for (int edge = 0; edge < edge_count; ++edge) {
        const size_t offset = 2 + 3 * (size_t)edge;
        const int64_t u_value = input[offset], v_value = input[offset + 1];
        const int64_t weight_value = input[offset + 2];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n
                || u_value == v_value || weight_value < 1 || weight_value > 9)
            return -1;
        const int u = (int)u_value, v = (int)v_value, weight = (int)weight_value;
        const int root_u = root_of(set_parent, u), root_v = root_of(set_parent, v);
        if (root_u == root_v) return -1;
        set_parent[root_v] = root_u;
        input_u[edge] = u;
        input_v[edge] = v;
        to[arc_count] = v; next[arc_count] = head[u]; head[u] = arc_count++;
        to[arc_count] = u; next[arc_count] = head[v]; head[v] = arc_count++;
        incident_sum[u] += weight;
        incident_sum[v] += weight;
    }

    const size_t output_bytes = 16 * (size_t)edge_count;
    if (!output || capacity < output_bytes) return -2;

    int parent[MAX_N], order[MAX_N];
    for (int vertex = 0; vertex < n; ++vertex) parent[vertex] = -1;
    parent[root] = root;
    order[0] = root;
    int order_size = 1;
    for (int cursor = 0; cursor < order_size; ++cursor) {
        const int vertex = order[cursor];
        for (int arc = head[vertex]; arc != -1; arc = next[arc]) {
            const int neighbor = to[arc];
            if (parent[neighbor] == -1) {
                parent[neighbor] = vertex;
                order[order_size++] = neighbor;
            }
        }
    }
    for (int position = n - 1; position >= 0; --position) {
        const int vertex = order[position];
        down[vertex] = incident_sum[vertex];
        for (int arc = head[vertex]; arc != -1; arc = next[arc]) {
            const int child = to[arc];
            if (parent[child] == vertex) down[vertex] += down[child];
        }
    }
    for (int position = 0; position < n; ++position) {
        const int vertex = order[position];
        for (int arc = head[vertex]; arc != -1; arc = next[arc]) {
            const int child = to[arc];
            if (parent[child] == vertex) up[child] = up[vertex] + down[vertex] - down[child];
        }
    }
    for (int edge = 0; edge < edge_count; ++edge) {
        const int u = input_u[edge], v = input_v[edge];
        const int64_t toward_v = parent[u] == v ? down[u] : up[v];
        const int64_t toward_u = parent[u] == v ? up[u] : down[v];
        store_i64_le(output, 16 * (size_t)edge, toward_v);
        store_i64_le(output, 16 * (size_t)edge + 8, toward_u);
    }
    return (int64_t)output_bytes;
}
