const MAX_LENGTH: usize = 20;
const MODULUS: i64 = 1_000_000_007;

fn normalize(value: i64) i64 {
    return @mod(value, MODULUS);
}

export fn count_different_palindromic_subsequences(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_LENGTH + 2) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_LENGTH or length != @as(usize, @intCast(input[0])) + 1) return -1;
    const n: usize = @intCast(input[0]);
    var symbols: [MAX_LENGTH]usize = @splat(0);
    for (0..n) |i| {
        if (input[i + 1] < 0 or input[i + 1] > 3) return -1;
        symbols[i] = @intCast(input[i + 1]);
    }
    if (n == 0) return 0;
    var next_equal: [MAX_LENGTH]usize = @splat(MAX_LENGTH);
    var previous_equal: [MAX_LENGTH]usize = @splat(MAX_LENGTH);
    var next_at: [4]usize = @splat(MAX_LENGTH);
    var previous_at: [4]usize = @splat(MAX_LENGTH);
    for (0..n) |i| {
        const reverse_i = n - 1 - i;
        next_equal[reverse_i] = next_at[symbols[reverse_i]];
        next_at[symbols[reverse_i]] = reverse_i;
    }
    for (0..n) |i| {
        previous_equal[i] = previous_at[symbols[i]];
        previous_at[symbols[i]] = i;
    }
    var dp: [MAX_LENGTH][MAX_LENGTH]i64 = @splat(@splat(0));
    for (0..n) |i| dp[i][i] = 1;
    for (2..n + 1) |width| {
        for (0..n - width + 1) |left| {
            const right = left + width - 1;
            const inner: i64 = if (width > 2) dp[left + 1][right - 1] else 0;
            if (symbols[left] != symbols[right]) {
                dp[left][right] = normalize(dp[left + 1][right] + dp[left][right - 1] - inner);
            } else {
                const first = next_equal[left];
                const last = previous_equal[right];
                var value: i64 = undefined;
                if (first >= right or last <= left or first > last) value = 2 * inner + 2
                else if (first == last) value = 2 * inner + 1
                else {
                    const duplicates: i64 = if (first + 1 <= last - 1) dp[first + 1][last - 1] else 0;
                    value = 2 * inner - duplicates;
                }
                dp[left][right] = normalize(value);
            }
        }
    }
    return dp[0][n - 1];
}
