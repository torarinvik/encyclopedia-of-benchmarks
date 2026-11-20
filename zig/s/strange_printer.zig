const MAX_LENGTH: usize = 8;
const TABLE_SIDE: usize = MAX_LENGTH + 1;
const MAX_PARSEABLE_LENGTH: usize = MAX_LENGTH + 2;

pub export fn strange_printer(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const n_value = input[0];
    if (n_value < 0 or n_value > MAX_LENGTH or length != @as(usize, @intCast(n_value)) + 1) return -1;
    const n: usize = @intCast(n_value);
    for (0..n) |position| {
        if (input[position + 1] < 0 or input[position + 1] > 2) return -1;
    }
    if (n == 0) return 0;

    var dp: [TABLE_SIDE * TABLE_SIDE]i64 = @splat(0);
    var left = n;
    while (left > 0) {
        left -= 1;
        dp[left * TABLE_SIDE + left] = 1;
        for (left + 1..n) |right| {
            var best = dp[(left + 1) * TABLE_SIDE + right] + 1;
            for (left + 1..right + 1) |merge| {
                if (input[left + 1] != input[merge + 1]) continue;
                const middle: i64 = if (merge == left + 1)
                    0
                else
                    dp[(left + 1) * TABLE_SIDE + merge - 1];
                const candidate = middle + dp[merge * TABLE_SIDE + right];
                if (candidate < best) best = candidate;
            }
            dp[left * TABLE_SIDE + right] = best;
        }
    }
    return dp[n - 1];
}
