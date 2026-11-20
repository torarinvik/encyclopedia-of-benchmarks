const INF: i64 = 801;

fn stateIndex(color: usize, groups: usize) usize {
    return color * 9 + groups;
}

export fn paint_house_iii(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 44) return -1;
    const input = input_opt.?;
    const m_value = input[0];
    const n_value = input[1];
    const target_value = input[2];
    if (m_value < 1 or m_value > 8 or n_value < 1 or n_value > 4
        or target_value < 1 or target_value > m_value) return -1;
    const m: usize = @intCast(m_value);
    const n: usize = @intCast(n_value);
    const target: usize = @intCast(target_value);
    if (length != 3 + m + m * n) return -1;
    const houses_at: usize = 3;
    const costs_at: usize = 3 + m;
    for (0..m) |index| {
        if (input[houses_at + index] < 0 or input[houses_at + index] > n_value) return -1;
    }
    for (0..m * n) |index| {
        if (input[costs_at + index] < 0 or input[costs_at + index] > 100) return -1;
    }

    var previous: [45]i64 = [_]i64{INF} ** 45;
    var current: [45]i64 = [_]i64{INF} ** 45;
    const first = input[houses_at];
    for (1..n + 1) |color| {
        if (first == 0 or first == @as(i64, @intCast(color))) {
            previous[stateIndex(color, 1)] = if (first == 0) input[costs_at + color - 1] else 0;
        }
    }
    for (1..m) |house| {
        @memset(&current, INF);
        const fixed = input[houses_at + house];
        for (1..n + 1) |color| {
            if (fixed != 0 and fixed != @as(i64, @intCast(color))) continue;
            const paint_cost = if (fixed == 0) input[costs_at + house * n + color - 1] else 0;
            for (1..target + 1) |groups| {
                var best: i64 = INF;
                for (1..n + 1) |old_color| {
                    const decrement: usize = if (old_color == color) 0 else 1;
                    const old_groups = groups - decrement;
                    if (old_groups >= 1 and previous[stateIndex(old_color, old_groups)] < best)
                        best = previous[stateIndex(old_color, old_groups)];
                }
                if (best < INF) current[stateIndex(color, groups)] = best + paint_cost;
            }
        }
        previous = current;
    }
    var answer: i64 = INF;
    for (1..n + 1) |color| {
        if (previous[stateIndex(color, target)] < answer) answer = previous[stateIndex(color, target)];
    }
    return if (answer >= INF) -1 else answer;
}
