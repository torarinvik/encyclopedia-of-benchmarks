/// 0-1 BFS over a bounded directed graph encoded as weighted edge triples.
export fn zero_one_bfs(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 3 or length > 3075) return -1;
    if (values[0] < 1 or values[0] > 64 or values[2] < 0 or values[2] > 1024) return -1;
    const vertices: usize = @intCast(values[0]);
    const source_value = values[1];
    const edge_count_value = values[2];
    if (source_value < 0 or @as(u64, @intCast(source_value)) >= vertices or
        edge_count_value < 0 or edge_count_value > 1024) return -1;
    const source: usize = @intCast(source_value);
    const edge_count: usize = @intCast(edge_count_value);
    if (length != 3 + 3 * edge_count) return -1;

    var zero_edges: [64]u64 = @splat(0);
    var one_edges: [64]u64 = @splat(0);
    var distance: [64]u8 = @splat(255);
    var deque: [4097]u8 = @splat(0);
    for (0..edge_count) |edge| {
        const origin_value = values[3 + 3 * edge];
        const destination_value = values[4 + 3 * edge];
        const weight = values[5 + 3 * edge];
        if (origin_value < 0 or destination_value < 0 or
            @as(u64, @intCast(origin_value)) >= vertices or
            @as(u64, @intCast(destination_value)) >= vertices or
            (weight != 0 and weight != 1)) return -1;
        const origin: usize = @intCast(origin_value);
        const destination: usize = @intCast(destination_value);
        const mask = @as(u64, 1) << @intCast(destination);
        if (weight == 0) zero_edges[origin] |= mask
        else one_edges[origin] |= mask;
    }
    if (output_capacity < vertices) return -2;

    var head: usize = 0;
    var tail: usize = 1;
    var queued: usize = 1;
    deque[0] = @intCast(source);
    distance[source] = 0;
    while (queued != 0) {
        const origin: usize = @intCast(deque[head]);
        head = (head + 1) % 4097;
        queued -= 1;
        const base = distance[origin];
        for (0..vertices) |destination| {
            const mask = @as(u64, 1) << @intCast(destination);
            if ((zero_edges[origin] & mask) != 0 and base < distance[destination]) {
                distance[destination] = base;
                if (head == 0) head = 4096 else head -= 1;
                deque[head] = @intCast(destination);
                queued += 1;
            }
            const candidate = base + 1;
            if ((one_edges[origin] & mask) != 0 and candidate < distance[destination]) {
                distance[destination] = candidate;
                deque[tail] = @intCast(destination);
                tail = (tail + 1) % 4097;
                queued += 1;
            }
        }
    }

    for (0..vertices) |vertex| output[vertex] = distance[vertex];
    return @intCast(vertices);
}
