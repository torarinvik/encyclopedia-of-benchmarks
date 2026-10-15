/// Return shortest common supersequence length for two packed ASCII sequences.
export fn shortest_common_supersequence_length(input_values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 512) return -1;
    const m = input_values[0];
    const n = input_values[1];
    if (m < 0 or m > 255 or n < 0 or n > 255) return -1;
    if (length != 2 + @as(usize, @intCast(m)) + @as(usize, @intCast(n))) return -1;
    for (0..@as(usize, @intCast(m + n))) |k| {
        const value = input_values[2 + k];
        if (value < 0 or value > 127) return -1;
    }

    const columns: usize = @intCast(n + 1);
    var dp: [256 * 256]i64 = @splat(0);
    for (1..@as(usize, @intCast(m)) + 1) |i| {
        for (1..@as(usize, @intCast(n)) + 1) |j| {
            const cell = i * columns + j;
            if (input_values[1 + i] == input_values[1 + @as(usize, @intCast(m)) + j]) {
                dp[cell] = dp[(i - 1) * columns + j - 1] + 1;
            } else {
                dp[cell] = @max(dp[(i - 1) * columns + j], dp[i * columns + j - 1]);
            }
        }
    }
    return m + n - dp[@as(usize, @intCast(m)) * columns + @as(usize, @intCast(n))];
}
