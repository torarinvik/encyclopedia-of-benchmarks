/// Unrestricted Damerau-Levenshtein distance over ASCII byte strings.
export fn damerau_levenshtein_distance(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 66) return -1;
    const left_n_value = values[0];
    const right_n_value = values[1];
    if (left_n_value < 0 or left_n_value > 32 or right_n_value < 0 or right_n_value > 32) return -1;
    const n: usize = @intCast(left_n_value);
    const m: usize = @intCast(right_n_value);
    if (length != 2 + n + m) return -1;
    for (values[2..][0 .. n + m]) |byte| {
        if (byte < 0 or byte > 127) return -1;
    }

    var dp: [34][34]i64 = @splat(@splat(0));
    var last: [128]usize = @splat(0);
    const max_distance: i64 = @intCast(n + m);
    dp[0][0] = max_distance;
    for (0..n + 1) |i| { dp[i + 1][0] = max_distance; dp[i + 1][1] = @intCast(i); }
    for (0..m + 1) |j| { dp[0][j + 1] = max_distance; dp[1][j + 1] = @intCast(j); }
    for (1..n + 1) |i| {
        var last_match_column: usize = 0;
        for (1..m + 1) |j| {
            const last_match_row = last[@intCast(values[2 + n + j - 1])];
            const prior_match_column = last_match_column;
            const cost: i64 = if (values[2 + i - 1] == values[2 + n + j - 1]) 0 else 1;
            if (cost == 0) last_match_column = j;
            const transposition = dp[last_match_row][prior_match_column]
                + @as(i64, @intCast(i - last_match_row - 1)) + 1
                + @as(i64, @intCast(j - prior_match_column - 1));
            dp[i + 1][j + 1] = @min(@min(dp[i][j] + cost, dp[i + 1][j] + 1),
                @min(dp[i][j + 1] + 1, transposition));
        }
        last[@intCast(values[2 + i - 1])] = i;
    }
    return dp[n + 1][m + 1];
}
