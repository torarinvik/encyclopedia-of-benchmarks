module cycle_check_directed_graph_kahn;

fn long cycle_check_directed_graph_kahn(long* values, usz length)
    @export("cycle_check_directed_graph_kahn") {
    if (values == null || length < 1 || length > 65 || (length - 1) % 2 != 0) return -1;
    if (values[0] < 0 || values[0] > 64) return -1;
    usz vertices = (usz)values[0];
    usz edge_count = (length - 1) / 2;
    if (edge_count > 32) return -1;
    ulong[64] adjacency;
    usz[64] indegree;
    for (usz vertex = 0; vertex < 64; vertex++) {
        adjacency[vertex] = 0ul;
        indegree[vertex] = 0;
    }
    for (usz edge = 0; edge < edge_count; edge++) {
        long source_value = values[1 + 2 * edge];
        long destination_value = values[2 + 2 * edge];
        if (source_value < 0 || destination_value < 0 ||
            (ulong)source_value >= (ulong)vertices || (ulong)destination_value >= (ulong)vertices) return -1;
        usz source = (usz)source_value;
        usz destination = (usz)destination_value;
        ulong mask = 1ul << (ulong)destination;
        if ((adjacency[source] & mask) == 0ul) {
            adjacency[source] = adjacency[source] | mask;
            indegree[destination]++;
        }
    }
    usz[64] queue;
    usz head = 0;
    usz tail = 0;
    for (usz vertex = 0; vertex < vertices; vertex++) {
        if (indegree[vertex] == 0) {
            queue[tail] = vertex;
            tail++;
        }
    }
    usz removed = 0;
    while (head < tail) {
        usz source = queue[head];
        head++;
        removed++;
        for (usz destination = 0; destination < vertices; destination++) {
            if ((adjacency[source] & (1ul << (ulong)destination)) != 0ul) {
                indegree[destination]--;
                if (indegree[destination] == 0) {
                    queue[tail] = destination;
                    tail++;
                }
            }
        }
    }
    if (removed != vertices) return 1;
    return 0;
}
