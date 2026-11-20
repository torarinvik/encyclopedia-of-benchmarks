const INF: i64 = @as(i64, 1) << 60;

export fn minimum_cost_bipartite_edge_cover_subset_dp(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 67) return -1;
    const left_value = input[0];
    const right_value = input[1];
    if (left_value < 1 or left_value > 8 or right_value < 1 or right_value > 8) return -1;
    const left_count: usize = @intCast(left_value);
    const right_count: usize = @intCast(right_value);
    if (length != 2 + left_count * right_count) return -1;
    for (0..left_count * right_count) |edge| {
        const cost = input[2 + edge];
        if (cost < 0 or cost > 1000) return -1;
    }

    const states: usize = @as(usize, 1) << @intCast(right_count);
    var current = [_]i64{INF} ** 256;
    var following = [_]i64{INF} ** 256;
    var subset_cost = [_]i64{0} ** 256;
    current[0] = 0;
    for (0..left_count) |left| {
        subset_cost[0] = 0;
        for (1..states) |subset| {
            const bit = subset & (~subset + 1);
            const right = @ctz(bit);
            subset_cost[subset] = subset_cost[subset ^ bit] + input[2 + left * right_count + right];
        }
        for (0..states) |mask| following[mask] = INF;
        for (0..states) |covered| {
            if (current[covered] == INF) continue;
            for (1..states) |selected| {
                const combined = covered | selected;
                const candidate = current[covered] + subset_cost[selected];
                if (candidate < following[combined]) following[combined] = candidate;
            }
        }
        for (0..states) |mask| current[mask] = following[mask];
    }
    return current[states - 1];
}
