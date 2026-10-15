/// Directed cycle detection with Kahn's zero-indegree queue.
export fn cycle_check_directed_graph_kahn(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length == 0 or length > 65 or (length - 1) % 2 != 0) return -1;
    const input = values.?;
    if (input[0] < 0 or input[0] > 64) return -1;
    const vertices: usize = @intCast(input[0]);
    const edge_count = (length - 1) / 2;
    if (edge_count > 32) return -1;
    var adjacency: [64]u64 = @splat(0);
    var indegree: [64]usize = @splat(0);
    for (0..edge_count) |edge| {
        const source_value = input[1 + 2 * edge];
        const destination_value = input[2 + 2 * edge];
        if (source_value < 0 or destination_value < 0 or
            @as(u64, @intCast(source_value)) >= vertices or
            @as(u64, @intCast(destination_value)) >= vertices) return -1;
        const source: usize = @intCast(source_value);
        const destination: usize = @intCast(destination_value);
        const mask = @as(u64, 1) << @intCast(destination);
        if ((adjacency[source] & mask) == 0) {
            adjacency[source] |= mask;
            indegree[destination] += 1;
        }
    }
    var queue: [64]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 0;
    for (0..vertices) |vertex| {
        if (indegree[vertex] == 0) {
            queue[tail] = vertex;
            tail += 1;
        }
    }
    var removed: usize = 0;
    while (head < tail) {
        const source = queue[head];
        head += 1;
        removed += 1;
        for (0..vertices) |destination| {
            if ((adjacency[source] & (@as(u64, 1) << @intCast(destination))) != 0) {
                indegree[destination] -= 1;
                if (indegree[destination] == 0) {
                    queue[tail] = destination;
                    tail += 1;
                }
            }
        }
    }
    return if (removed == vertices) 0 else 1;
}
