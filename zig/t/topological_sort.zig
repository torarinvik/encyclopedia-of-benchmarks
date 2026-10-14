/// Kahn topological sort over a bounded directed graph encoded as edge pairs.
export fn topological_sort(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 66 or (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 or values[0] > 64) return -2;
    const vertices: usize = @intCast(values[0]);
    const edge_count = (length - 1) / 2;
    var adjacency: [64]u64 = @splat(0);
    var indegree: [64]usize = @splat(0);
    var queue: [64]usize = @splat(0);
    var order: [64]usize = @splat(0);

    for (0..edge_count) |edge| {
        const origin_value = values[1 + 2 * edge];
        const destination_value = values[2 + 2 * edge];
        if (origin_value < 0 or destination_value < 0 or
            @as(u64, @intCast(origin_value)) >= vertices or
            @as(u64, @intCast(destination_value)) >= vertices) return -2;
        const origin: usize = @intCast(origin_value);
        const destination: usize = @intCast(destination_value);
        const mask = @as(u64, 1) << @intCast(destination);
        if ((adjacency[origin] & mask) == 0) {
            adjacency[origin] |= mask;
            indegree[destination] += 1;
        }
    }
    var head: usize = 0;
    var tail: usize = 0;
    for (0..vertices) |vertex| {
        if (indegree[vertex] == 0) {
            queue[tail] = vertex;
            tail += 1;
        }
    }
    var count: usize = 0;
    while (head < tail) {
        const origin = queue[head];
        head += 1;
        order[count] = origin;
        count += 1;
        for (0..vertices) |destination| {
            if ((adjacency[origin] & (@as(u64, 1) << @intCast(destination))) != 0) {
                indegree[destination] -= 1;
                if (indegree[destination] == 0) {
                    queue[tail] = destination;
                    tail += 1;
                }
            }
        }
    }
    if (count != vertices) return -1;
    if (output_capacity < vertices) return -2;
    for (0..count) |index| output[index] = @intCast(order[index]);
    return @intCast(count);
}
