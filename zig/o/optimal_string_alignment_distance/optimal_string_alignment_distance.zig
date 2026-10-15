/// Restricted Damerau-Levenshtein (optimal string alignment) distance.
export fn optimal_string_alignment_distance(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 66) return -1;
    const left_n_value = values[0];
    const right_n_value = values[1];
    if (left_n_value < 0 or left_n_value > 32 or right_n_value < 0 or right_n_value > 32) return -1;
    const n: usize = @intCast(left_n_value);
    const m: usize = @intCast(right_n_value);
    if (length != 2 + n + m) return -1;
    for (values[2..][0 .. n + m]) |byte| { if (byte < 0 or byte > 127) return -1; }
    var dp: [34][34]i64 = @splat(@splat(0));
    for (0..n + 1) |i| { dp[i][0] = @intCast(i); }
    for (0..m + 1) |j| { dp[0][j] = @intCast(j); }
    for (1..n + 1) |i| {
        for (1..m + 1) |j| {
            const cost: i64 = if (values[2 + i - 1] == values[2 + n + j - 1]) 0 else 1;
            var best = @min(@min(dp[i - 1][j - 1] + cost, dp[i][j - 1] + 1), dp[i - 1][j] + 1);
            if (i > 1 and j > 1 and values[2 + i - 1] == values[2 + n + j - 2] and values[2 + i - 2] == values[2 + n + j - 1]) {
                best = @min(best, dp[i - 2][j - 2] + cost);
            }
            dp[i][j] = best;
        }
    }
    return dp[n][m];
}
