const MAX_VERTICES = 32;
const MAX_EDGES = 2047;

fn putI64(output: [*c]u8, slot: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[slot * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn graph_c_undirected_simple(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    if (input[0] < 1 or input[0] > MAX_VERTICES or input[1] < 0 or input[1] > MAX_EDGES) return -1;
    const vertices: usize = @intCast(input[0]);
    const edge_count: usize = @intCast(input[1]);
    if (length != 2 + 2 * edge_count) return -1;

    var adjacency: [MAX_VERTICES][MAX_VERTICES]i64 = @splat(@splat(0));
    for (0..edge_count) |edge| {
        const left_value = input[2 + 2 * edge];
        const right_value = input[3 + 2 * edge];
        if (left_value < 0 or right_value < 0 or @as(u64, @intCast(left_value)) >= vertices or
            @as(u64, @intCast(right_value)) >= vertices) return -1;
        const left: usize = @intCast(left_value);
        const right: usize = @intCast(right_value);
        adjacency[left][right] = 1;
        adjacency[right][left] = 1;
    }
    const count = vertices * vertices;
    if (output == null or capacity < count * 8) return -2;
    for (0..vertices) |row| {
        for (0..vertices) |column| putI64(output, row * vertices + column, adjacency[row][column]);
    }
    return @intCast(count * 8);
}
