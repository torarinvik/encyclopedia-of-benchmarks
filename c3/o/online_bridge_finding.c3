module online_bridge_finding;

const int MAX_VERTICES = 64;
const int MAX_EDGES = 128;
const usz MAX_INPUT_LENGTH = 259;

struct BridgeState {
    int[MAX_VERTICES] dsu_2ecc;
    int[MAX_VERTICES] dsu_cc;
    int[MAX_VERTICES] dsu_cc_size;
    int[MAX_VERTICES] parent;
    int[MAX_VERTICES] last_visit;
    int iteration;
    int bridges;
}

fn int find_2ecc(BridgeState* state, int vertex) {
    if (vertex == -1) return -1;
    if (state->dsu_2ecc[vertex] == vertex) return vertex;
    state->dsu_2ecc[vertex] = find_2ecc(state, state->dsu_2ecc[vertex]);
    return state->dsu_2ecc[vertex];
}

fn int find_cc(BridgeState* state, int vertex) {
    vertex = find_2ecc(state, vertex);
    if (state->dsu_cc[vertex] == vertex) return vertex;
    state->dsu_cc[vertex] = find_cc(state, state->dsu_cc[vertex]);
    return state->dsu_cc[vertex];
}

fn void make_root(BridgeState* state, int vertex) {
    int root = find_2ecc(state, vertex);
    int child = -1;
    while (vertex != -1) {
        int next = find_2ecc(state, state->parent[vertex]);
        state->parent[vertex] = child;
        state->dsu_cc[vertex] = root;
        child = vertex;
        vertex = next;
    }
    state->dsu_cc_size[root] = state->dsu_cc_size[child];
}

fn void merge_path(BridgeState* state, int left, int right) {
    state->iteration++;
    int[MAX_VERTICES] path_left = {};
    int[MAX_VERTICES] path_right = {};
    int left_length = 0;
    int right_length = 0;
    int lca = -1;
    while (lca == -1) {
        if (left != -1) {
            left = find_2ecc(state, left);
            path_left[left_length++] = left;
            if (state->last_visit[left] == state->iteration) { lca = left; break; }
            state->last_visit[left] = state->iteration;
            left = state->parent[left];
        }
        if (right != -1) {
            right = find_2ecc(state, right);
            path_right[right_length++] = right;
            if (state->last_visit[right] == state->iteration) { lca = right; break; }
            state->last_visit[right] = state->iteration;
            right = state->parent[right];
        }
    }
    for (int index = 0; index < left_length; index++) {
        int vertex = path_left[index];
        state->dsu_2ecc[vertex] = lca;
        if (vertex == lca) break;
        state->bridges--;
    }
    for (int index = 0; index < right_length; index++) {
        int vertex = path_right[index];
        state->dsu_2ecc[vertex] = lca;
        if (vertex == lca) break;
        state->bridges--;
    }
}

fn void add_edge(BridgeState* state, int left, int right) {
    left = find_2ecc(state, left);
    right = find_2ecc(state, right);
    if (left == right) return;
    int left_cc = find_cc(state, left);
    int right_cc = find_cc(state, right);
    if (left_cc != right_cc) {
        state->bridges++;
        if (state->dsu_cc_size[left_cc] > state->dsu_cc_size[right_cc]) {
            int temporary = left; left = right; right = temporary;
            temporary = left_cc; left_cc = right_cc; right_cc = temporary;
        }
        make_root(state, left);
        state->parent[left] = right;
        state->dsu_cc[left] = right;
        state->dsu_cc_size[right_cc] += state->dsu_cc_size[left];
    } else {
        merge_path(state, left, right);
    }
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 0xff);
        bits >>= 8;
    }
}

fn long online_bridge_finding(long* values, usz length, char* output,
                              usz output_capacity) @export("online_bridge_finding") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long raw_vertices = values[0], raw_edges = values[1];
    if (raw_vertices < 1 || raw_vertices > MAX_VERTICES || raw_edges < 0 || raw_edges > MAX_EDGES) return -1;
    int vertex_count = (int)raw_vertices, edge_count = (int)raw_edges;
    if (length != (usz)(2 + 2 * edge_count)) return -1;
    for (int edge = 0; edge < edge_count; edge++) {
        long left = values[2 + 2 * edge], right = values[3 + 2 * edge];
        if (left < 0 || right < 0 || left >= raw_vertices || right >= raw_vertices) return -1;
    }
    usz output_bytes = (usz)edge_count * 8;
    if (output_bytes > 0 && (output == null || output_capacity < output_bytes)) return -2;

    BridgeState state = {};
    for (int vertex = 0; vertex < vertex_count; vertex++) {
        state.dsu_2ecc[vertex] = vertex;
        state.dsu_cc[vertex] = vertex;
        state.dsu_cc_size[vertex] = 1;
        state.parent[vertex] = -1;
    }
    for (int edge = 0; edge < edge_count; edge++) {
        add_edge(&state, (int)values[2 + 2 * edge], (int)values[3 + 2 * edge]);
        store_i64_le(output, (usz)edge * 8, (long)state.bridges);
    }
    return (long)output_bytes;
}
