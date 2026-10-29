module three_edge_connected_components;

const usz MAX_VERTICES = 8;
const usz MAX_EDGES = 32;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES;

fn void refine_for_removal(long* edge_from, long* edge_to, usz vertex_count, usz edge_count,
                           int removed_first, int removed_second, bool* same) {
    int component[8];
    int queue[8];
    for (usz vertex = 0; vertex < vertex_count; vertex++) component[vertex] = -1;
    int next_component = 0;
    for (usz start = 0; start < vertex_count; start++) {
        if (component[start] >= 0) continue;
        int head = 0;
        int tail = 0;
        component[start] = next_component;
        queue[tail++] = (int)start;
        while (head < tail) {
            int vertex = queue[head++];
            for (usz edge = 0; edge < edge_count; edge++) {
                if ((int)edge == removed_first || (int)edge == removed_second) continue;
                int neighbor = -1;
                if (edge_from[edge] == vertex) neighbor = (int)edge_to[edge];
                else if (edge_to[edge] == vertex) neighbor = (int)edge_from[edge];
                if (neighbor >= 0 && component[neighbor] < 0) {
                    component[neighbor] = next_component;
                    queue[tail++] = neighbor;
                }
            }
        }
        next_component++;
    }
    for (usz first = 0; first < vertex_count; first++) {
        for (usz second = first + 1; second < vertex_count; second++) {
            if (component[first] != component[second]) {
                same[first * MAX_VERTICES + second] = false;
                same[second * MAX_VERTICES + first] = false;
            }
        }
    }
}

fn long three_edge_connected_components(long* values, usz length) @export("three_edge_connected_components") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 1 || values[0] > (long)MAX_VERTICES
        || values[1] < 0 || values[1] > (long)MAX_EDGES) return -1;
    usz vertex_count = (usz)values[0];
    usz edge_count = (usz)values[1];
    if (length != 2 + 2 * edge_count) return -1;
    long[MAX_EDGES] edge_from;
    long[MAX_EDGES] edge_to;
    for (usz edge = 0; edge < edge_count; edge++) {
        edge_from[edge] = values[2 + 2 * edge];
        edge_to[edge] = values[3 + 2 * edge];
        if (edge_from[edge] < 0 || edge_from[edge] >= (long)vertex_count
            || edge_to[edge] < 0 || edge_to[edge] >= (long)vertex_count) return -1;
    }

    bool[64] same;
    for (int pair = 0; pair < 64; pair++) same[pair] = true;
    refine_for_removal(&edge_from[0], &edge_to[0], vertex_count, edge_count, -1, -1, &same[0]);
    for (usz first = 0; first < edge_count; first++) {
        refine_for_removal(&edge_from[0], &edge_to[0], vertex_count, edge_count, (int)first, -1, &same[0]);
        for (usz second = first + 1; second < edge_count; second++)
            refine_for_removal(&edge_from[0], &edge_to[0], vertex_count, edge_count,
                               (int)first, (int)second, &same[0]);
    }

    int labels[8];
    for (usz vertex = 0; vertex < vertex_count; vertex++) labels[vertex] = -1;
    int next_label = 0;
    for (usz first = 0; first < vertex_count; first++) {
        if (labels[first] >= 0) continue;
        for (usz vertex = first; vertex < vertex_count; vertex++) {
            if (labels[vertex] < 0 && same[first * MAX_VERTICES + vertex]) labels[vertex] = next_label;
        }
        next_label++;
    }
    long encoded = 0;
    long place = 1;
    for (usz vertex = 0; vertex < vertex_count; vertex++) {
        encoded += (long)labels[vertex] * place;
        place *= 8;
    }
    return encoded;
}
