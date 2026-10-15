/// Bottom-up dynamic programming for the bounded rod-cutting problem.
export fn rod_cutting(values: [*]const i64, length: usize) i64 {
    if (length < 2) return -1;
    const n_value = values[0];
    if (n_value < 1 or n_value > 30) return -1;
    const n: usize = @intCast(n_value);
    if (length != n + 1) return -1;
    for (0..n) |i| {
        const price = values[i + 1];
        if (price < 1 or price > 1000) return -1;
    }
    var profit: [31]i64 = [_]i64{0} ** 31;
    for (1..n + 1) |rod| {
        var best: i64 = 0;
        for (1..rod + 1) |cut| {
            const candidate = values[cut] + profit[rod - cut];
            if (candidate > best) best = candidate;
        }
        profit[rod] = best;
    }
    return profit[n];
}
