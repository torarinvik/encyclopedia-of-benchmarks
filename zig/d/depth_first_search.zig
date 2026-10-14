/// Traverse a directed graph from start with fixed-size adjacency bitsets.
export fn depth_first_search(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 66 or (length - 2) % 2 != 0) return -2;
    if (values[0] < 0 or values[0] > 64) return -2;
    const vertices: usize = @intCast(values[0]);
    const start_value = values[1];
    if (vertices == 0) return if (start_value == -1 and length == 2) 0 else -2;
    if (start_value < 0 or @as(u64, @intCast(start_value)) >= vertices) return -2;
    var adjacency: [64]u64 = @splat(0);
    var visited: [64]bool = @splat(false);
    var order: [64]usize = @splat(0);
    const edge_count = (length - 2) / 2;
    for (0..edge_count) |edge| {
        const origin_value = values[2 + 2 * edge];
        const destination_value = values[3 + 2 * edge];
        if (origin_value < 0 or destination_value < 0 or
            @as(u64, @intCast(origin_value)) >= vertices or
            @as(u64, @intCast(destination_value)) >= vertices) return -2;
        const origin: usize = @intCast(origin_value);
        const destination: usize = @intCast(destination_value);
        adjacency[origin] |= @as(u64, 1) << @intCast(destination);
    }
    const start: usize = @intCast(start_value);
    var count: usize = 0;
    visited[start] = true;
    var stack_vertex: [64]usize = @splat(0);
    var stack_next: [64]usize = @splat(0);
    var depth: usize = 1;
    stack_vertex[0] = start;
    order[count] = start;
    count += 1;
    while (depth != 0) {
        const frame = depth - 1;
        const origin = stack_vertex[frame];
        if (stack_next[frame] == vertices) {
            depth -= 1;
        } else {
            const destination = stack_next[frame];
            stack_next[frame] += 1;
            if ((adjacency[origin] & (@as(u64, 1) << @intCast(destination))) != 0 and !visited[destination]) {
                visited[destination] = true;
                order[count] = destination;
                count += 1;
                stack_vertex[depth] = destination;
                stack_next[depth] = 0;
                depth += 1;
            }
        }
    }
    if (output_capacity < count) return -2;
    for (0..count) |index| output[index] = @intCast(order[index]);
    return @intCast(count);
}
