/// Deterministic depth-first topological sort with three-color cycle detection.
export fn topological_sort_dfs(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 66 or (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 or values[0] > 40) return -2;
    const vertices: usize = @intCast(values[0]);
    const edge_count = (length - 1) / 2;
    var adjacency: [40]u64 = @splat(0);
    var state: [40]u8 = @splat(0);
    var stack: [40]usize = @splat(0);
    var next_neighbor: [40]usize = @splat(0);
    var order: [40]usize = @splat(0);

    for (0..edge_count) |edge| {
        const origin_value = values[1 + 2 * edge];
        const destination_value = values[2 + 2 * edge];
        if (origin_value < 0 or destination_value < 0 or
            @as(u64, @intCast(origin_value)) >= vertices or
            @as(u64, @intCast(destination_value)) >= vertices) return -2;
        const origin: usize = @intCast(origin_value);
        const destination: usize = @intCast(destination_value);
        adjacency[origin] |= @as(u64, 1) << @intCast(destination);
    }

    var count: usize = 0;
    for (0..vertices) |root| {
        if (state[root] != 0) continue;
        var top: usize = 0;
        stack[top] = root;
        next_neighbor[top] = 0;
        state[root] = 1;
        while (true) {
            const origin = stack[top];
            var destination = next_neighbor[top];
            while (destination < vertices and
                (adjacency[origin] & (@as(u64, 1) << @intCast(destination))) == 0) {
                destination += 1;
            }
            if (destination == vertices) {
                state[origin] = 2;
                order[count] = origin;
                count += 1;
                if (top == 0) break;
                top -= 1;
                continue;
            }
            next_neighbor[top] = destination + 1;
            if (state[destination] == 1) return -1;
            if (state[destination] == 0) {
                top += 1;
                stack[top] = destination;
                next_neighbor[top] = 0;
                state[destination] = 1;
            }
        }
    }

    if (output_capacity < vertices) return -2;
    for (0..count) |index| output[index] = @intCast(order[count - 1 - index]);
    return @intCast(count);
}
