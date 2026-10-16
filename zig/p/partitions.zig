const MAX_N: usize = 100;
fn countParts(n: usize, k: usize, memo: *[101][101]i64) i64 {
    if ((n == 0 and k == 0) or (n > 0 and k == 1) or n == k) return 1;
    if (k == 0 or k > n) return 0;
    if (memo[n][k] >= 0) return memo[n][k];
    memo[n][k] = countParts(n - 1, k - 1, memo) + countParts(n - k, k, memo);
    return memo[n][k];
}
export fn partitions(n: i64) i64 {
    if (n < 0 or n > MAX_N) return -9223372036854775808;
    var memo: [101][101]i64 = undefined;
    for (&memo) |*row| { for (row) |*cell| { cell.* = -1; } }
    var total: i64 = 0;
    var k: usize = 1; const count: usize = @intCast(n);
    while (k <= count) : (k += 1) total += countParts(count, k, &memo);
    return if (n == 0) 1 else total;
}
