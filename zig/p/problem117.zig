export fn problem117(length: i64) i64 {
    if (length < 0 or length > 67) return -1;
    const n: usize = @intCast(length);
    var ways = [_]i64{0} ** 68;
    ways[0] = 1;
    for (1..n + 1) |row| {
        ways[row] = ways[row - 1];
        if (row >= 2) ways[row] += ways[row - 2];
        if (row >= 3) ways[row] += ways[row - 3];
        if (row >= 4) ways[row] += ways[row - 4];
    }
    return ways[n];
}
