module bellman_ford;

// Directed edge triples, separate reachability, and checked distance addition.
fn long bellman_ford(long* edges, usz vertices, usz edge_count, usz source,
                    long* distances, char* reachable) @export("bellman_ford")
{
    if (vertices == 0) return source == 0 && edge_count == 0 ? 0 : -3;
    if (source >= vertices) return -3;
    for (usz edge = 0; edge < edge_count; edge++) {
        long origin = edges[3 * edge];
        long destination = edges[3 * edge + 1];
        if (origin < 0 || destination < 0 || (ulong)origin >= vertices ||
            (ulong)destination >= vertices) return -3;
    }
    for (usz vertex = 0; vertex < vertices; vertex++) {
        distances[vertex] = 0;
        reachable[vertex] = 0;
    }
    reachable[source] = 1;
    for (usz round = 0; round < vertices; round++) {
        bool changed = false;
        for (usz edge = 0; edge < edge_count; edge++) {
            usz origin = (usz)edges[3 * edge];
            usz destination = (usz)edges[3 * edge + 1];
            long weight = edges[3 * edge + 2];
            if (reachable[origin] == 0) continue;
            long base = distances[origin];
            if ((weight > 0 && base > 9223372036854775807 - weight) ||
                (weight < 0 && base < (-9223372036854775807 - 1) - weight)) return -2;
            long candidate = base + weight;
            if (reachable[destination] == 0 || candidate < distances[destination]) {
                if (round == vertices - 1) return -1;
                distances[destination] = candidate;
                reachable[destination] = 1;
                changed = true;
            }
        }
        if (!changed) return 0;
    }
    return 0;
}
