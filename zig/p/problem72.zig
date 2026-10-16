export fn problem72(limit: i64) i64 {
    if (limit < 0 or limit > 1_000_000) return -1;
    if (limit < 2) return 0;
    const n: usize = @intCast(limit);
    var phi = [_]u32{0} ** 1_000_001;
    if (n >= 1) phi[1] = 1;
    for (2..n + 1) |value| phi[value] = @intCast(value);
    for (2..n + 1) |prime| {
        if (phi[prime] == prime) {
            var multiple = prime;
            while (multiple <= n) : (multiple += prime) {
                phi[multiple] -= phi[multiple] / @as(u32, @intCast(prime));
            }
        }
    }
    var total: i64 = 0;
    for (2..n + 1) |denominator| total += phi[denominator];
    return total;
}
