module cycle_check_directed_graph;

fn bool has_cycle_dfs(usz origin, usz vertices, ulong* adjacency, char* state,
        usz* stack, usz* next_neighbor) {
    usz top = 0;
    stack[0] = origin;
    next_neighbor[0] = 0;
    state[origin] = 1;
    while (true) {
        usz node = stack[top];
        usz destination = next_neighbor[top];
        while (destination < vertices &&
            (adjacency[node] & (1ul << (ulong)destination)) == 0ul) destination++;
        if (destination == vertices) {
            state[node] = 2;
            if (top == 0) return false;
            top--;
            continue;
        }
        next_neighbor[top] = destination + 1;
        if (state[destination] == 1) return true;
        if (state[destination] == 0) {
            top++;
            stack[top] = destination;
            next_neighbor[top] = 0;
            state[destination] = 1;
        }
    }
}

fn long cycle_check_directed_graph(long* values, usz length) @export("cycle_check_directed_graph") {
    if (values == null || length < 1 || length > 65 || (length - 1) % 2 != 0) return -1;
    if (values[0] < 0 || values[0] > 64) return -1;
    usz vertices = (usz)values[0];
    usz edge_count = (length - 1) / 2;
    if (edge_count > 32) return -1;
    ulong[64] adjacency;
    char[64] state;
    usz[64] stack, next_neighbor;
    for (usz vertex = 0; vertex < 64; vertex++) {
        adjacency[vertex] = 0ul;
        state[vertex] = 0;
    }
    for (usz edge = 0; edge < edge_count; edge++) {
        long source_value = values[1 + 2 * edge];
        long destination_value = values[2 + 2 * edge];
        if (source_value < 0 || destination_value < 0 ||
            (ulong)source_value >= (ulong)vertices || (ulong)destination_value >= (ulong)vertices) return -1;
        usz source = (usz)source_value;
        usz destination = (usz)destination_value;
        adjacency[source] = adjacency[source] | (1ul << (ulong)destination);
    }
    for (usz root = 0; root < vertices; root++) {
        if (state[root] == 0 && has_cycle_dfs(root, vertices, &adjacency[0], &state[0], &stack[0], &next_neighbor[0])) return 1;
    }
    return 0;
}
