const MAX_VERTICES: usize = 12;
const MAX_EDGES: i64 = 66;
const MAX_INPUT_VALUES: usize = 134;
const MAX_PARSEABLE_VALUES: usize = 135;

fn popcount(value: u32) usize {
    return @intCast(@popCount(value));
}

export fn dsatur_greedy_coloring(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_VALUES) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > @as(i64, @intCast(MAX_VERTICES)) or m64 < 0 or m64 > MAX_EDGES) return -1;
    const max_edges = n64 * (n64 - 1) / 2;
    if (m64 > max_edges) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (length != 2 + 2 * m or length > MAX_INPUT_VALUES) return -1;

    var adjacency: [MAX_VERTICES]u32 = @splat(0);
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge];
        const v64 = input[3 + 2 * edge];
        if (u64 < 0 or v64 < 0 or u64 >= v64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        const v_bit = @as(u32, 1) << @intCast(v);
        if ((adjacency[u] & v_bit) != 0) return -1;
        adjacency[u] |= v_bit;
        adjacency[v] |= @as(u32, 1) << @intCast(u);
    }

    var colors: [MAX_VERTICES]i32 = @splat(-1);
    var saturation: [MAX_VERTICES]u32 = @splat(0);
    var residual_degree: [MAX_VERTICES]usize = @splat(0);
    for (0..n) |vertex| residual_degree[vertex] = popcount(adjacency[vertex]);

    var color_count: usize = 0;
    for (0..n) |_| {
        var selected: i32 = -1;
        var selected_saturation: usize = 0;
        var selected_degree: usize = 0;
        for (0..n) |vertex| {
            if (colors[vertex] >= 0) continue;
            const sat_count = popcount(saturation[vertex]);
            const degree = residual_degree[vertex];
            if (selected < 0 or sat_count > selected_saturation or
                (sat_count == selected_saturation and (degree > selected_degree or
                    (degree == selected_degree and vertex < @as(usize, @intCast(selected)))))
            ) {
                selected = @intCast(vertex);
                selected_saturation = sat_count;
                selected_degree = degree;
            }
        }
        const chosen: usize = @intCast(selected);
        var color: usize = 0;
        while ((saturation[chosen] & (@as(u32, 1) << @intCast(color))) != 0) color += 1;
        colors[chosen] = @intCast(color);
        color_count = @max(color_count, color + 1);
        const color_bit = @as(u32, 1) << @intCast(color);
        for (0..n) |neighbor| {
            if (colors[neighbor] < 0 and (adjacency[chosen] & (@as(u32, 1) << @intCast(neighbor))) != 0) {
                residual_degree[neighbor] -= 1;
                saturation[neighbor] |= color_bit;
            }
        }
    }

    var packed: u64 = @as(u64, @intCast(color_count)) << 48;
    for (0..n) |vertex| {
        packed |= @as(u64, @intCast(colors[vertex])) << @intCast(4 * vertex);
    }
    return @intCast(packed);
}
