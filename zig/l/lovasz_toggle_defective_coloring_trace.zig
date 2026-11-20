export fn lovasz_toggle_defective_coloring_trace(input_opt: ?[*]const i64, length: usize) callconv(.c) i64 {
    if (input_opt == null or length < 5 or length > 246) return -1;
    const input = input_opt.?[0..length];
    const n_value = input[0];
    const red_bound = input[1];
    const blue_bound = input[2];
    if (n_value < 0 or n_value > 16 or red_bound < 1 or red_bound > 8 or blue_bound < 1 or blue_bound > 8) return -1;
    const n: usize = @intCast(n_value);
    const red_mask_value = input[3];
    if (red_mask_value < 0 or @as(u64, @intCast(red_mask_value)) >= (@as(u64, 1) << @intCast(n))) return -1;
    const m_value = input[4];
    if (m_value < 0 or m_value > n_value * (n_value - 1) / 2) return -1;
    const m: usize = @intCast(m_value);
    if (length != 5 + 2 * m) return -1;

    var adjacency: [16]u32 = @splat(0);
    var degree: [16]i64 = @splat(0);
    for (0..m) |edge| {
        const u_value = input[5 + 2 * edge];
        const v_value = input[6 + 2 * edge];
        if (u_value < 0 or v_value <= u_value or v_value >= n_value) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        const bit_v = @as(u32, 1) << @intCast(v);
        const bit_u = @as(u32, 1) << @intCast(u);
        if ((adjacency[u] & bit_v) != 0) return -1;
        adjacency[u] |= bit_v;
        adjacency[v] |= bit_u;
        degree[u] += 1;
        degree[v] += 1;
    }
    for (0..n) |vertex| {
        if (degree[vertex] > red_bound + blue_bound + 1) return -1;
    }

    var red_mask: u64 = @intCast(red_mask_value);
    var toggle_count: i64 = 0;
    while (true) {
        var bad_vertex: ?usize = null;
        for (0..n) |vertex| {
            var red_degree: i64 = 0;
            for (0..n) |neighbor| {
                const bit = @as(u32, 1) << @intCast(neighbor);
                if ((adjacency[vertex] & bit) != 0 and (red_mask & (@as(u64, 1) << @intCast(neighbor))) != 0) {
                    red_degree += 1;
                }
            }
            const blue_degree = degree[vertex] - red_degree;
            const is_red = (red_mask & (@as(u64, 1) << @intCast(vertex))) != 0;
            if ((is_red and red_degree > red_bound) or (!is_red and blue_degree > blue_bound)) {
                bad_vertex = vertex;
                break;
            }
        }
        if (bad_vertex) |vertex| {
            red_mask ^= @as(u64, 1) << @intCast(vertex);
            toggle_count += 1;
        } else break;
    }
    const multiplier: i64 = @intCast(@as(u64, 1) << @intCast(n));
    return (toggle_count * multiplier) | @as(i64, @intCast(red_mask));
}
