// Independent bounded subset-assignment draft; not compiled or run.
export fn tree_sibling_distinct_cost_coloring(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > 354) return -1;
    if (input[0] < 1 or input[0] > 32 or input[1] < 1 or input[1] > 10) return -1;
    const n: usize = @intCast(input[0]);
    const k: usize = @intCast(input[1]);
    if (length != n + 1 + n * k) return -1;
    for (1..n) |v| {
        if (input[1+v] < 0 or input[1+v] >= @as(i64, @intCast(v))) return -1;
    }
    for (0..n*k) |i| {
        if (input[n+1+i] < 0 or input[n+1+i] > 1_000_000) return -1;
    }
    const inf: i64 = 1_000_000_000_000;
    const states: usize = @as(usize, 1) << @as(u6, @intCast(k));
    var dp = [_]i64{0} ** 320;
    var current = [_]i64{0} ** 1024;
    var next = [_]i64{0} ** 1024;
    var v = n;
    while (v > 0) {
        v -= 1;
        for (0..k) |color| {
            @memset(current[0..states], inf);
            current[@as(usize, 1) << @as(u6, @intCast(color))] = 0;
            for (v+1..n) |child| {
                if (input[1+child] != @as(i64, @intCast(v))) continue;
                @memset(next[0..states], inf);
                for (0..states) |mask| {
                    if (current[mask] == inf) continue;
                    for (0..k) |c| {
                        const bit = @as(usize, 1) << @as(u6, @intCast(c));
                        if ((mask & bit) != 0 or dp[10*child+c] == inf) continue;
                        const target = mask | bit;
                        next[target] = @min(next[target], current[mask] + dp[10*child+c]);
                    }
                }
                @memcpy(current[0..states], next[0..states]);
            }
            var best = inf;
            for (current[0..states]) |value| best = @min(best, value);
            dp[10*v+color] = if (best == inf) inf else best + input[n+1+v*k+color];
        }
    }
    var best = inf;
    for (dp[0..k]) |value| best = @min(best, value);
    return if (best == inf) -2 else best;
}
