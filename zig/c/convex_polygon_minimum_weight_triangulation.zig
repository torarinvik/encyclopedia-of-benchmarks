const max_n: usize = 10;
const max_length: usize = 37;

export fn convex_polygon_minimum_weight_triangulation(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > max_length) return -1;
    const values = input.?;
    if (values[0] < 3 or values[0] > 10) return -1;
    const n: usize = @intCast(values[0]);
    var diagonal_count: usize = 0;
    for (0..n) |i| {
        var j = i + 2;
        while (j < n) : (j += 1) {
            if (!(i == 0 and j == n - 1)) diagonal_count += 1;
        }
    }
    if (length != 1 + diagonal_count) return -1;

    var weight = [_][max_n]i64{[_]i64{0} ** max_n} ** max_n;
    var at: usize = 1;
    for (0..n) |i| {
        var j = i + 2;
        while (j < n) : (j += 1) {
            if (i == 0 and j == n - 1) continue;
            const value = values[at];
            if (value < 0 or value > 1000) return -1;
            weight[i][j] = value;
            at += 1;
        }
    }

    var dp = [_][max_n]i64{[_]i64{0} ** max_n} ** max_n;
    var span: usize = 2;
    while (span < n) : (span += 1) {
        for (0..(n - span)) |left| {
            const right = left + span;
            var best: i64 = 7001;
            var split = left + 1;
            while (split < right) : (split += 1) {
                const left_edge: i64 = if (split - left == 1) 0 else weight[left][split];
                const right_edge: i64 = if (right - split == 1) 0 else weight[split][right];
                const candidate = dp[left][split] + dp[split][right] + left_edge + right_edge;
                if (candidate < best) best = candidate;
            }
            dp[left][right] = best;
        }
    }
    return dp[0][n - 1];
}
