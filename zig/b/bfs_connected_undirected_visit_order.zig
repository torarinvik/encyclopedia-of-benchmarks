const MAX_VERTICES = 40;
const MAX_EDGES = 780;

fn putI64(output: [*c]u8, slot: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[slot * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn bfs_connected_undirected_visit_order(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3) return -1;
    if (input[0] < 1 or input[0] > MAX_VERTICES or input[1] < 0 or input[1] > MAX_EDGES or input[2] != 0) return -1;
    const vertices: usize = @intCast(input[0]);
    const edge_count: usize = @intCast(input[1]);
    if (length != 3 + 2 * edge_count) return -1;

    var adjacency: [MAX_VERTICES]u64 = @splat(0);
    for (0..edge_count) |edge| {
        const left_value = input[3 + 2 * edge];
        const right_value = input[4 + 2 * edge];
        if (left_value < 0 or right_value < 0 or @as(u64, @intCast(left_value)) >= vertices or
            @as(u64, @intCast(right_value)) >= vertices) return -1;
        const left: usize = @intCast(left_value);
        const right: usize = @intCast(right_value);
        adjacency[left] |= @as(u64, 1) << @intCast(right);
        adjacency[right] |= @as(u64, 1) << @intCast(left);
    }
    var visited: [MAX_VERTICES]bool = @splat(false);
    var queue: [MAX_VERTICES]usize = @splat(0);
    var order: [MAX_VERTICES]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 0;
    var count: usize = 0;
    visited[0] = true;
    queue[tail] = 0;
    tail += 1;
    while (head < tail) {
        const vertex = queue[head];
        head += 1;
        order[count] = vertex;
        count += 1;
        for (0..vertices) |neighbor| {
            if ((adjacency[vertex] & (@as(u64, 1) << @intCast(neighbor))) != 0 and !visited[neighbor]) {
                visited[neighbor] = true;
                queue[tail] = neighbor;
                tail += 1;
            }
        }
    }
    if (count != vertices) return -1;
    if (output == null or capacity < vertices * 8) return -2;
    for (0..count) |index| putI64(output, index, @intCast(order[index]));
    return @intCast(count);
}
