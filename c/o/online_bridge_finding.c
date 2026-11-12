#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 64
#define MAX_EDGES 128
#define MAX_INPUT_LENGTH (2 + 2 * MAX_EDGES + 1)

typedef struct {
    int dsu_2ecc[MAX_VERTICES];
    int dsu_cc[MAX_VERTICES];
    int dsu_cc_size[MAX_VERTICES];
    int parent[MAX_VERTICES];
    int last_visit[MAX_VERTICES];
    int iteration;
    int bridges;
} bridge_state;

static int find_2ecc(bridge_state *state, int vertex) {
    if (vertex == -1) return -1;
    if (state->dsu_2ecc[vertex] == vertex) return vertex;
    state->dsu_2ecc[vertex] = find_2ecc(state, state->dsu_2ecc[vertex]);
    return state->dsu_2ecc[vertex];
}

static int find_cc(bridge_state *state, int vertex) {
    vertex = find_2ecc(state, vertex);
    if (state->dsu_cc[vertex] == vertex) return vertex;
    state->dsu_cc[vertex] = find_cc(state, state->dsu_cc[vertex]);
    return state->dsu_cc[vertex];
}

static void make_root(bridge_state *state, int vertex) {
    vertex = find_2ecc(state, vertex);
    const int root = vertex;
    int child = -1;
    while (vertex != -1) {
        const int next = find_2ecc(state, state->parent[vertex]);
        state->parent[vertex] = child;
        state->dsu_cc[vertex] = root;
        child = vertex;
        vertex = next;
    }
    state->dsu_cc_size[root] = state->dsu_cc_size[child];
}

static void merge_path(bridge_state *state, int left, int right) {
    ++state->iteration;
    int path_left[MAX_VERTICES];
    int path_right[MAX_VERTICES];
    int left_length = 0;
    int right_length = 0;
    int lca = -1;
    while (lca == -1) {
        if (left != -1) {
            left = find_2ecc(state, left);
            path_left[left_length++] = left;
            if (state->last_visit[left] == state->iteration) {
                lca = left;
                break;
            }
            state->last_visit[left] = state->iteration;
            left = state->parent[left];
        }
        if (right != -1) {
            right = find_2ecc(state, right);
            path_right[right_length++] = right;
            if (state->last_visit[right] == state->iteration) {
                lca = right;
                break;
            }
            state->last_visit[right] = state->iteration;
            right = state->parent[right];
        }
    }
    for (int index = 0; index < left_length; ++index) {
        const int vertex = path_left[index];
        state->dsu_2ecc[vertex] = lca;
        if (vertex == lca) break;
        --state->bridges;
    }
    for (int index = 0; index < right_length; ++index) {
        const int vertex = path_right[index];
        state->dsu_2ecc[vertex] = lca;
        if (vertex == lca) break;
        --state->bridges;
    }
}

static void add_edge(bridge_state *state, int left, int right) {
    left = find_2ecc(state, left);
    right = find_2ecc(state, right);
    if (left == right) return;
    int left_cc = find_cc(state, left);
    int right_cc = find_cc(state, right);
    if (left_cc != right_cc) {
        ++state->bridges;
        if (state->dsu_cc_size[left_cc] > state->dsu_cc_size[right_cc]) {
            const int temporary_vertex = left;
            left = right;
            right = temporary_vertex;
            const int temporary_cc = left_cc;
            left_cc = right_cc;
            right_cc = temporary_cc;
        }
        make_root(state, left);
        state->parent[left] = right;
        state->dsu_cc[left] = right;
        state->dsu_cc_size[right_cc] += state->dsu_cc_size[left];
    } else {
        merge_path(state, left, right);
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)((bits >> (byte * 8)) & UINT64_C(0xff));
}

int64_t online_bridge_finding(const int64_t *values, size_t length,
                              uint8_t *output, size_t capacity) {
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_vertices = values[0];
    const int64_t raw_edges = values[1];
    if (raw_vertices < 1 || raw_vertices > MAX_VERTICES || raw_edges < 0 || raw_edges > MAX_EDGES)
        return -1;
    const size_t vertex_count = (size_t)raw_vertices;
    const size_t edge_count = (size_t)raw_edges;
    if (length != 2 + 2 * edge_count) return -1;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left = values[2 + 2 * edge];
        const int64_t right = values[3 + 2 * edge];
        if (left < 0 || right < 0 || left >= (int64_t)vertex_count || right >= (int64_t)vertex_count)
            return -1;
    }
    const size_t output_bytes = edge_count * 8;
    if (output_bytes > 0 && (output == NULL || capacity < output_bytes)) return -2;

    bridge_state state = {0};
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        state.dsu_2ecc[vertex] = (int)vertex;
        state.dsu_cc[vertex] = (int)vertex;
        state.dsu_cc_size[vertex] = 1;
        state.parent[vertex] = -1;
    }
    for (size_t edge = 0; edge < edge_count; ++edge) {
        add_edge(&state, (int)values[2 + 2 * edge], (int)values[3 + 2 * edge]);
        store_i64_le(output, edge * 8, state.bridges);
    }
    return (int64_t)output_bytes;
}
