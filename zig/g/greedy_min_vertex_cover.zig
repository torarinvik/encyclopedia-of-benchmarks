const MAX_VERTICES: usize = 16;

fn bitCount(value: u64) i64 {
    var remaining = value;
    var count: i64 = 0;
    while (remaining != 0) { remaining &= remaining - 1; count += 1; }
    return count;
}

export fn greedy_min_vertex_cover(values: ?[*]const i64, length: usize) callconv(.c) i64 {
    if (values == null or length < 2 or length > MAX_VERTICES + 1) return -1;
    const input = values.?;
    const count_value = input[0];
    if (count_value < 1 or count_value > MAX_VERTICES or length != @as(usize, @intCast(count_value)) + 1) return -1;
    const count: usize = @intCast(count_value);
    const limit = (@as(u64, 1) << @as(u6, @intCast(count))) - 1;
    var neighbors: [MAX_VERTICES]u64 = @splat(0);
    for (0..count) |vertex| {
        const mask_value = input[vertex + 1];
        if (mask_value < 0 or @as(u64, @intCast(mask_value)) > limit) return -1;
        const mask: u64 = @intCast(mask_value);
        if ((mask & (@as(u64, 1) << @as(u6, @intCast(vertex)))) != 0) return -1;
        neighbors[vertex] = mask;
    }
    for (0..count) |vertex| {
        for (vertex + 1..count) |other| {
            if (((neighbors[vertex] >> @as(u6, @intCast(other))) & 1) !=
                ((neighbors[other] >> @as(u6, @intCast(vertex))) & 1)) return -1;
        }
    }
    var chosen: u64 = 0;
    while (true) {
        var best_vertex: ?usize = null;
        var best_degree: i64 = 0;
        for (0..count) |vertex| {
            const degree = bitCount(neighbors[vertex]);
            if (degree > best_degree) { best_vertex = vertex; best_degree = degree; }
        }
        const vertex = best_vertex orelse return @intCast(chosen);
        const bit = @as(u64, 1) << @as(u6, @intCast(vertex));
        chosen |= bit;
        for (0..count) |index| neighbors[index] &= ~bit;
        neighbors[vertex] = 0;
    }
}
