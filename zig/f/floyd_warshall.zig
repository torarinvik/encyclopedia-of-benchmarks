/// Compute bounded all-pairs shortest paths and return one source row.
const max_vertices: usize = 64;
const floyd_storage: usize = max_vertices * max_vertices;

export fn floyd_warshall(edges: [*]const i64, vertices: usize, edge_count: usize,
                         source: usize, distances: [*]i64, reachable: [*]u8) i64 {
    if (vertices == 0) return if (source == 0 and edge_count == 0) 0 else -3;
    if (vertices > max_vertices or source >= vertices) return -3;
    for (0..edge_count) |edge| {
        const origin = edges[3 * edge];
        const destination = edges[3 * edge + 1];
        if (origin < 0 or destination < 0 or @as(u64, @intCast(origin)) >= vertices or
            @as(u64, @intCast(destination)) >= vertices) return -3;
    }
    var all_distances: [floyd_storage]i64 = @splat(0);
    var present: [floyd_storage]u8 = @splat(0);
    for (0..vertices) |vertex| present[vertex * vertices + vertex] = 1;
    for (0..edge_count) |edge| {
        const origin: usize = @intCast(edges[3 * edge]);
        const destination: usize = @intCast(edges[3 * edge + 1]);
        const index = origin * vertices + destination;
        const weight = edges[3 * edge + 2];
        if (present[index] == 0 or weight < all_distances[index]) {
            all_distances[index] = weight;
            present[index] = 1;
        }
    }
    for (0..vertices) |middle| {
        for (0..vertices) |origin| {
            const left_index = origin * vertices + middle;
            if (present[left_index] == 0) continue;
            for (0..vertices) |destination| {
                const right_index = middle * vertices + destination;
                if (present[right_index] == 0) continue;
                const left = all_distances[left_index];
                const right = all_distances[right_index];
                if ((right > 0 and left > 9223372036854775807 - right) or
                    (right < 0 and left < (-9223372036854775807 - 1) - right)) return -2;
                const candidate = left + right;
                const index = origin * vertices + destination;
                if (present[index] == 0 or candidate < all_distances[index]) {
                    all_distances[index] = candidate;
                    present[index] = 1;
                }
            }
        }
    }
    for (0..vertices) |vertex| {
        const index = source * vertices + vertex;
        if (present[index] != 0 and present[vertex * vertices + vertex] != 0 and
            all_distances[vertex * vertices + vertex] < 0) return -1;
    }
    for (0..vertices) |vertex| {
        const index = source * vertices + vertex;
        reachable[vertex] = present[index];
        distances[vertex] = if (present[index] != 0) all_distances[index] else 0;
    }
    return 0;
}
