module dijkstra;

// Directed edge triples, nonnegative weights, separate reachability.
fn long dijkstra(long* edges, usz vertices, usz edge_count, usz source,
                 long* distances, char* reachable) @export("dijkstra")
{
    if (vertices == 0) return source == 0 && edge_count == 0 ? 0 : -3;
    if (source >= vertices) return -3;
    for (usz edge = 0; edge < edge_count; edge++) {
        long origin = edges[3 * edge];
        long destination = edges[3 * edge + 1];
        long weight = edges[3 * edge + 2];
        if (origin < 0 || destination < 0 || (ulong)origin >= vertices ||
            (ulong)destination >= vertices) return -3;
        if (weight < 0) return -4;
    }
    for (usz vertex = 0; vertex < vertices; vertex++) {
        distances[vertex] = 0;
        reachable[vertex] = 0;
    }
    reachable[source] = 1;
    for (usz round = 0; round < vertices; round++) {
        usz selected = vertices;
        long best = 0;
        for (usz vertex = 0; vertex < vertices; vertex++) {
            if (reachable[vertex] == 1 && (selected == vertices || distances[vertex] < best)) {
                selected = vertex;
                best = distances[vertex];
            }
        }
        if (selected == vertices) break;
        reachable[selected] = 2;
        for (usz edge = 0; edge < edge_count; edge++) {
            if ((usz)edges[3 * edge] != selected) continue;
            usz destination = (usz)edges[3 * edge + 1];
            long weight = edges[3 * edge + 2];
            long base = distances[selected];
            if (base > 9223372036854775807 - weight) return -2;
            long candidate = base + weight;
            if (reachable[destination] != 2 &&
                (reachable[destination] == 0 || candidate < distances[destination])) {
                distances[destination] = candidate;
                reachable[destination] = 1;
            }
        }
    }
    for (usz vertex = 0; vertex < vertices; vertex++) {
        if (reachable[vertex] == 2) reachable[vertex] = 1;
    }
    return 0;
}
