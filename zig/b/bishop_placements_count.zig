const MAX_N: usize = 8;
const MAX_K: usize = 16;
const MAX_DIAGONALS: usize = 2 * MAX_N;

fn diagonalSize(index: usize) usize {
    return if (index & 1 != 0) (index / 4) * 2 + 1 else ((index - 1) / 4) * 2 + 2;
}

fn colorCounts(k: usize, last_diagonal: usize) [MAX_K + 1]i64 {
    var dp = [_]i64{0} ** (MAX_DIAGONALS * (MAX_K + 1));
    dp[0] = 1;
    dp[MAX_K + 1] = 1;
    if (k >= 1) dp[MAX_K + 2] = 1;
    for (2..last_diagonal + 1) |diagonal| {
        dp[diagonal * (MAX_K + 1)] = 1;
        const squares: i64 = @intCast(diagonalSize(diagonal));
        for (1..k + 1) |placed| {
            const offset = diagonal * (MAX_K + 1) + placed;
            const previous = (diagonal - 2) * (MAX_K + 1);
            dp[offset] = dp[previous + placed] + dp[previous + placed - 1] * (squares - @as(i64, @intCast(placed)) + 1);
        }
    }
    var counts = [_]i64{0} ** (MAX_K + 1);
    for (0..k + 1) |placed| counts[placed] = dp[last_diagonal * (MAX_K + 1) + placed];
    return counts;
}

export fn bishop_placements_count(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length != 2) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N)) or
        input[1] < 0 or input[1] > @as(i64, @intCast(MAX_K))) return -1;
    const n: usize = @intCast(input[0]);
    const k: usize = @intCast(input[1]);
    const maximum: usize = if (n == 1) 1 else 2 * n - 2;
    if (k > maximum) return 0;
    const black = colorCounts(k, 2 * n - 1);
    const white = colorCounts(k, 2 * n - 2);
    var result: i64 = 0;
    for (0..k + 1) |left| result += black[left] * white[k - left];
    return result;
}
