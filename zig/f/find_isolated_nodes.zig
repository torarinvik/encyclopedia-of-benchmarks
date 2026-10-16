/// Return vertices with no outgoing neighbors, in ascending vertex order.
export fn find_isolated_nodes(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > 65 or (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 or values[0] > 64) return -2;
    const vertices: usize = @intCast(values[0]);
    var adjacency: [64]u64 = @splat(0);
    const edge_count = (length - 1) / 2;
    for (0..edge_count) |edge| {
        const origin_value = values[1 + 2 * edge];
        const destination_value = values[2 + 2 * edge];
        if (origin_value < 0 or destination_value < 0 or
            @as(u64, @intCast(origin_value)) >= vertices or
            @as(u64, @intCast(destination_value)) >= vertices) return -2;
        const origin: usize = @intCast(origin_value);
        const destination: u6 = @intCast(destination_value);
        adjacency[origin] |= @as(u64, 1) << destination;
    }
    var isolated: [64]u8 = @splat(0);
    var count: usize = 0;
    for (0..vertices) |vertex| {
        if (adjacency[vertex] == 0) {
            isolated[count] = @intCast(vertex);
            count += 1;
        }
    }
    if (output_capacity < count) return -2;
    for (0..count) |index| output[index] = isolated[index];
    return @intCast(count);
}
