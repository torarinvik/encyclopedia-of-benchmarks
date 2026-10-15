/// Stack-based DFS that marks vertices when they are pushed, matching the source order.
export fn depth_first_search_with_stack(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 66 or (length - 2) % 2 != 0) return -2;
    if (values[0] < 0 or values[0] > 64) return -2;
    const vertices: usize = @intCast(values[0]);
    const start_value = values[1];
    if (vertices == 0) return if (start_value == -1 and length == 2) 0 else -2;
    if (start_value < 0 or @as(u64, @intCast(start_value)) >= vertices) return -2;

    var adjacency: [64 * 32]usize = @splat(0);
    var degree: [64]usize = @splat(0);
    var state: [64]u8 = @splat(0);
    const edge_count = (length - 2) / 2;
    for (0..edge_count) |edge| {
        const origin_value = values[2 + 2 * edge];
        const destination_value = values[3 + 2 * edge];
        if (origin_value < 0 or destination_value < 0 or
            @as(u64, @intCast(origin_value)) >= vertices or
            @as(u64, @intCast(destination_value)) >= vertices) return -2;
        const origin: usize = @intCast(origin_value);
        adjacency[origin * 32 + degree[origin]] = @intCast(destination_value);
        degree[origin] += 1;
    }

    var stack: [33]usize = @splat(0);
    var order: [64]usize = @splat(0);
    var stack_length: usize = 1;
    var count: usize = 0;
    const start: usize = @intCast(start_value);
    state[start] = 1;
    stack[0] = start;
    while (stack_length != 0) {
        stack_length -= 1;
        const vertex = stack[stack_length];
        if (state[vertex] != 1) continue;
        order[count] = vertex;
        count += 1;
        for (0..degree[vertex]) |edge| {
            const neighbor = adjacency[vertex * 32 + edge];
            stack[stack_length] = neighbor;
            stack_length += 1;
            if (state[neighbor] != 2) state[neighbor] = 1;
        }
        state[vertex] = 2;
    }
    if (output_capacity < count) return -2;
    for (0..count) |index| output[index] = @intCast(order[index]);
    return @intCast(count);
}
