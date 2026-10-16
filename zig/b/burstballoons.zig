const MAX_BALLOONS: usize = 128;

export fn burstballoons(values: [*]const i64, length: usize) i64 {
    if (length > MAX_BALLOONS) return -1;
    for (0..length) |index| {
        if (values[index] < 0 or values[index] > 1000) return -1;
    }
    if (length == 0) return 0;

    var padded: [MAX_BALLOONS + 2]i64 = @splat(0);
    var dp: [MAX_BALLOONS + 2][MAX_BALLOONS + 2]i64 = @splat(@splat(0));
    padded[0] = 1;
    padded[length + 1] = 1;
    for (0..length) |index| padded[index + 1] = values[index];

    for (1..length + 1) |span| {
        for (1..length - span + 2) |left| {
            const right = left + span - 1;
            var best: i64 = 0;
            for (left..right + 1) |last| {
                const coins = dp[left][last - 1] + dp[last + 1][right]
                    + padded[left - 1] * padded[last] * padded[right + 1];
                best = @max(best, coins);
            }
            dp[left][right] = best;
        }
    }
    return dp[1][length];
}
