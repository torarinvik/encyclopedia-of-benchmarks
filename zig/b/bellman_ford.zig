/// Directed edge triples, separate reachability, and checked distance addition.
export fn bellman_ford(edges: [*]const i64, vertices: usize, edge_count: usize,
                      source: usize, distances: [*]i64, reachable: [*]u8) i64 {
    if (vertices == 0) return if (source == 0 and edge_count == 0) 0 else -3;
    if (source >= vertices) return -3;
    for (0..edge_count) |edge| {
        const origin = edges[3 * edge];
        const destination = edges[3 * edge + 1];
        if (origin < 0 or destination < 0) return -3;
        if (@as(u64, @intCast(origin)) >= @as(u64, @intCast(vertices)) or
            @as(u64, @intCast(destination)) >= @as(u64, @intCast(vertices))) return -3;
    }
    for (0..vertices) |vertex| {
        distances[vertex] = 0;
        reachable[vertex] = 0;
    }
    reachable[source] = 1;
    for (0..vertices) |round| {
        var changed = false;
        for (0..edge_count) |edge| {
            const origin: usize = @intCast(edges[3 * edge]);
            const destination: usize = @intCast(edges[3 * edge + 1]);
            const weight = edges[3 * edge + 2];
            if (reachable[origin] == 0) continue;
            const base = distances[origin];
            if ((weight > 0 and base > 9223372036854775807 - weight) or
                (weight < 0 and base < (-9223372036854775807 - 1) - weight)) return -2;
            const candidate = base + weight;
            if (reachable[destination] == 0 or candidate < distances[destination]) {
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
