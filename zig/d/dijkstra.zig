/// Directed edge triples, nonnegative weights, separate reachability.
export fn dijkstra(edges: [*]const i64, vertices: usize, edge_count: usize,
                   source: usize, distances: [*]i64, reachable: [*]u8) i64 {
    if (vertices == 0) return if (source == 0 and edge_count == 0) 0 else -3;
    if (source >= vertices) return -3;
    for (0..edge_count) |edge| {
        const origin = edges[3 * edge];
        const destination = edges[3 * edge + 1];
        const weight = edges[3 * edge + 2];
        if (origin < 0 or destination < 0) return -3;
        if (@as(u64, @intCast(origin)) >= @as(u64, @intCast(vertices)) or
            @as(u64, @intCast(destination)) >= @as(u64, @intCast(vertices))) return -3;
        if (weight < 0) return -4;
    }
    for (0..vertices) |vertex| {
        distances[vertex] = 0;
        reachable[vertex] = 0;
    }
    reachable[source] = 1;
    for (0..vertices) |_| {
        var selected = vertices;
        var best: i64 = 0;
        for (0..vertices) |vertex| {
            if (reachable[vertex] == 1 and (selected == vertices or distances[vertex] < best)) {
                selected = vertex;
                best = distances[vertex];
            }
        }
        if (selected == vertices) break;
        reachable[selected] = 2;
        for (0..edge_count) |edge| {
            if (@as(usize, @intCast(edges[3 * edge])) != selected) continue;
            const destination: usize = @intCast(edges[3 * edge + 1]);
            const weight = edges[3 * edge + 2];
            const base = distances[selected];
            if (base > 9223372036854775807 - weight) return -2;
            const candidate = base + weight;
            if (reachable[destination] != 2 and
                (reachable[destination] == 0 or candidate < distances[destination])) {
                distances[destination] = candidate;
                reachable[destination] = 1;
            }
        }
    }
    for (0..vertices) |vertex| {
        if (reachable[vertex] == 2) reachable[vertex] = 1;
    }
    return 0;
}
