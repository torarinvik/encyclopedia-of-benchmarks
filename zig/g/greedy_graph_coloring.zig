const MAX_VERTICES: usize = 14;

export fn greedy_graph_coloring(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_VERTICES + 1) return -1;
    const values = input;
    const count_value = values[0];
    if (count_value < 0 or count_value > MAX_VERTICES or length != @as(usize, @intCast(count_value + 1))) return -1;
    const count: usize = @intCast(count_value);
    const limit = (@as(i64, 1) << @intCast(count)) - 1;
    var adjacency: [MAX_VERTICES]i64 = @splat(0);
    var degree: [MAX_VERTICES]usize = @splat(0);
    var order: [MAX_VERTICES]usize = @splat(0);
    var colors: [MAX_VERTICES]usize = @splat(0);
    for (0..count) |vertex| {
        const mask = values[1 + vertex];
        if (mask < 0 or mask > limit or (mask & (@as(i64, 1) << @intCast(vertex))) != 0) return -1;
        adjacency[vertex] = mask;
        order[vertex] = vertex;
        var remaining = mask;
        while (remaining != 0) { remaining &= remaining - 1; degree[vertex] += 1; }
    }
    for (0..count) |vertex| {
        for (0..count) |other| {
            if (((adjacency[vertex] >> @intCast(other)) & 1) != ((adjacency[other] >> @intCast(vertex)) & 1)) return -1;
        }
    }
    for (1..count) |index| {
        const current = order[index];
        var position = index;
        while (position > 0 and degree[order[position - 1]] < degree[current]) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = current;
    }
    var color_count: usize = 0;
    for (0..count) |position| {
        const vertex = order[position];
        var used: u32 = 0;
        for (0..count) |other| {
            if (adjacency[vertex] & (@as(i64, 1) << @intCast(other)) != 0 and colors[other] != 0)
                used |= @as(u32, 1) << @intCast(colors[other]);
        }
        var color: usize = 1;
        while (used & (@as(u32, 1) << @intCast(color)) != 0) color += 1;
        colors[vertex] = color;
        color_count = @max(color_count, color);
    }
    var packed: i64 = @intCast(color_count);
    for (0..count) |vertex| packed |= @as(i64, @intCast(colors[vertex])) << @intCast(4 * (vertex + 1));
    return packed;
}
