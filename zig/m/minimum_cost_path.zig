const std = @import("std");
const INVALID_RESULT: i64 = std.math.minInt(i64);

export fn minimum_cost_path(values: [*]const i64, length: usize) i64 {
    if (length < 3) return INVALID_RESULT;
    const rv = values[0];
    const cv = values[1];
    if (rv < 1 or rv > 16 or cv < 1 or cv > 16) return INVALID_RESULT;
    const rows: usize = @intCast(rv);
    const cols: usize = @intCast(cv);
    if (length != 2 + rows * cols) return INVALID_RESULT;
    var dp = [_][16]i64{[_]i64{0} ** 16} ** 16;
    for (0..rows) |r| {
        for (0..cols) |c| {
            const x = values[2 + r * cols + c];
            if (x < std.math.minInt(i32) or x > std.math.maxInt(i32)) return INVALID_RESULT;
            dp[r][c] = x;
        }
    }
    for (1..cols) |c| dp[0][c] += dp[0][c - 1];
    for (1..rows) |r| dp[r][0] += dp[r - 1][0];
    for (1..rows) |r| {
        for (1..cols) |c| dp[r][c] += @min(dp[r - 1][c], dp[r][c - 1]);
    }
    return dp[rows - 1][cols - 1];
}
