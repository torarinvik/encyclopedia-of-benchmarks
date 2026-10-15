/// Directed cycle detection with iterative depth-first search and three colors.
export fn cycle_check_directed_graph(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length == 0 or length > 65 or (length - 1) % 2 != 0) return -1;
    const input = values.?;
    if (input[0] < 0 or input[0] > 64) return -1;
    const vertices: usize = @intCast(input[0]);
    const edge_count = (length - 1) / 2;
    if (edge_count > 32) return -1;
    var adjacency: [64]u64 = @splat(0);
    var state: [64]u8 = @splat(0);
    var stack: [64]usize = @splat(0);
    var next_neighbor: [64]usize = @splat(0);
    for (0..edge_count) |edge| {
        const source_value = input[1 + 2 * edge];
        const destination_value = input[2 + 2 * edge];
        if (source_value < 0 or destination_value < 0 or
            @as(u64, @intCast(source_value)) >= vertices or
            @as(u64, @intCast(destination_value)) >= vertices) return -1;
        const source: usize = @intCast(source_value);
        const destination: usize = @intCast(destination_value);
        adjacency[source] |= @as(u64, 1) << @intCast(destination);
    }
    for (0..vertices) |root| {
        if (state[root] != 0) continue;
        var top: usize = 0;
        stack[0] = root;
        next_neighbor[0] = 0;
        state[root] = 1;
        while (true) {
            const node = stack[top];
            var destination = next_neighbor[top];
            while (destination < vertices and
                (adjacency[node] & (@as(u64, 1) << @intCast(destination))) == 0) : (destination += 1) {}
            if (destination == vertices) {
                state[node] = 2;
                if (top == 0) break;
                top -= 1;
                continue;
            }
            next_neighbor[top] = destination + 1;
            if (state[destination] == 1) return 1;
            if (state[destination] == 0) {
                top += 1;
                stack[top] = destination;
                next_neighbor[top] = 0;
                state[destination] = 1;
            }
        }
    }
    return 0;
}
