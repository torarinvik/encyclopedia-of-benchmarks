export fn unique_subsequences_count(input: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 31) return -1;
    const n_value = input[0];
    if (n_value < 0 or n_value > 30 or length != @as(usize, @intCast(n_value)) + 1) return -1;
    const n: usize = @intCast(n_value);
    for (0..n) |i| {
        if (input[i + 1] < 0 or input[i + 1] > 127) return -1;
    }
    var dp: [31]i64 = @splat(0);
    var end = n;
    while (end > 0) {
        const i = end - 1;
        var seen: [128]bool = @splat(false);
        for (i..n) |j| {
            const ch: usize = @intCast(input[j + 1]);
            if (!seen[ch]) {
                seen[ch] = true;
                dp[i] += 1 + dp[j + 1];
            }
        }
        end -= 1;
    }
    return dp[0];
}
