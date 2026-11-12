const std = @import("std");
const MaxN: usize = 64;
const MaxInput: usize = 65;
const MaxFrequency: i64 = 1_000_000;

export fn knuth_optimized_optimal_binary_search_tree(v: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MaxInput or v[0] < 1 or v[0] > MaxN or length != @as(usize, @intCast(v[0])) + 1) return -1;
    const n: usize = @intCast(v[0]);
    var prefix: [MaxN + 1]i64 = @splat(0);
    var dp: [MaxN][MaxN]i64 = @splat(@splat(0));
    var opt: [MaxN][MaxN]usize = @splat(@splat(0));
    for (0..n) |i| {
        const f = v[i + 1];
        if (f < 0 or f > MaxFrequency) return -1;
        prefix[i + 1] = prefix[i] + f;
        dp[i][i] = f;
        opt[i][i] = i;
    }
    var width: usize = 2;
    while (width <= n) : (width += 1) {
        var left: usize = 0;
        while (left + width <= n) : (left += 1) {
            const right = left + width - 1;
            const first = opt[left][right - 1];
            const last = opt[left + 1][right];
            const total = prefix[right + 1] - prefix[left];
            var best: i64 = std.math.maxInt(i64);
            var best_root = first;
            var root = first;
            while (root <= last) : (root += 1) {
                var cost = total;
                if (root > left) cost += dp[left][root - 1];
                if (root < right) cost += dp[root + 1][right];
                if (cost < best) { best = cost; best_root = root; }
            }
            dp[left][right] = best;
            opt[left][right] = best_root;
        }
    }
    return dp[0][n - 1];
}
