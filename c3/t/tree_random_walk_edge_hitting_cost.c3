module tree_random_walk_edge_hitting_cost;

const usz MAX_N = 16;
const usz MAX_EDGES = 15;
const usz MAX_ARCS = 30;
const usz MAX_INPUT_LENGTH = 48;

fn void store_i64_le(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long tree_random_walk_edge_hitting_cost(long *input, usz length,
        char *output, usz capacity) @export("tree_random_walk_edge_hitting_cost") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0], root_value = input[1];
    if (n_value < 1 || n_value > 16 || root_value < 0 || root_value >= n_value) return -1;
    usz n = (usz)n_value, root = (usz)root_value, edge_count = n - 1;
    if (length != 2 + 3 * edge_count) return -1;

    long[MAX_N] head;
    long[MAX_ARCS] to;
    long[MAX_ARCS] next_arc;
    long[MAX_N] sets;
    long[MAX_EDGES] input_u;
    long[MAX_EDGES] input_v;
    long[MAX_N] incident_sum;
    long[MAX_N] down;
    long[MAX_N] up;
    for (usz vertex = 0; vertex < n; vertex++) {
        head[vertex] = -1;
        sets[vertex] = (long)vertex;
        incident_sum[vertex] = 0;
        down[vertex] = 0;
        up[vertex] = 0;
    }

    usz arc_count = 0;
    for (usz edge = 0; edge < edge_count; edge++) {
        usz offset = 2 + 3 * edge;
        long u_value = input[offset], v_value = input[offset + 1], weight = input[offset + 2];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
                || u_value == v_value || weight < 1 || weight > 9) return -1;
        usz u = (usz)u_value, v = (usz)v_value;
        usz set_u = u, set_v = v;
        while (sets[set_u] != (long)set_u) {
            sets[set_u] = sets[(usz)sets[set_u]];
            set_u = (usz)sets[set_u];
        }
        while (sets[set_v] != (long)set_v) {
            sets[set_v] = sets[(usz)sets[set_v]];
            set_v = (usz)sets[set_v];
        }
        if (set_u == set_v) return -1;
        sets[set_v] = (long)set_u;
        input_u[edge] = u_value;
        input_v[edge] = v_value;
        to[arc_count] = (long)v;
        next_arc[arc_count] = head[u];
        head[u] = (long)arc_count;
        arc_count++;
        to[arc_count] = (long)u;
        next_arc[arc_count] = head[v];
        head[v] = (long)arc_count;
        arc_count++;
        incident_sum[u] += weight;
        incident_sum[v] += weight;
    }

    usz output_bytes = 16 * edge_count;
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_N] parent;
    long[MAX_N] order;
    for (usz vertex = 0; vertex < n; vertex++) parent[vertex] = -1;
    parent[root] = (long)root;
    order[0] = (long)root;
    usz order_size = 1;
    for (usz cursor = 0; cursor < order_size; cursor++) {
        usz vertex = (usz)order[cursor];
        long arc = head[vertex];
        while (arc >= 0) {
            usz index = (usz)arc, neighbor = (usz)to[index];
            if (parent[neighbor] == -1) {
                parent[neighbor] = (long)vertex;
                order[order_size] = (long)neighbor;
                order_size++;
            }
            arc = next_arc[index];
        }
    }
    usz position = n;
    while (position > 0) {
        position--;
        usz vertex = (usz)order[position];
        down[vertex] = incident_sum[vertex];
        long arc = head[vertex];
        while (arc >= 0) {
            usz index = (usz)arc, child = (usz)to[index];
            if (parent[child] == (long)vertex) down[vertex] += down[child];
            arc = next_arc[index];
        }
    }
    for (usz position = 0; position < n; position++) {
        usz vertex = (usz)order[position];
        long arc = head[vertex];
        while (arc >= 0) {
            usz index = (usz)arc, child = (usz)to[index];
            if (parent[child] == (long)vertex)
                up[child] = up[vertex] + down[vertex] - down[child];
            arc = next_arc[index];
        }
    }
    for (usz edge = 0; edge < edge_count; edge++) {
        usz u = (usz)input_u[edge], v = (usz)input_v[edge];
        long toward_v, toward_u;
        if (parent[u] == (long)v) {
            toward_v = down[u]; toward_u = up[u];
        } else {
            toward_v = up[v]; toward_u = down[v];
        }
        store_i64_le(output, 16 * edge, toward_v);
        store_i64_le(output, 16 * edge + 8, toward_u);
    }
    return (long)output_bytes;
}
