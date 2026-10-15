/// Tabulated Fibonacci for the bounded signed 64-bit benchmark contract.
export fn fibonacci_dp(n: i64) i64 {
    if (n < 0 or n > 46) return -1;

    var table: [47]i64 = [_]i64{0} ** 47;
    table[0] = 0;
    table[1] = 1;
    var index: usize = 2;
    while (index <= @as(usize, @intCast(n))) : (index += 1) {
        table[index] = table[index - 1] + table[index - 2];
    }
    return table[@intCast(n)];
}
