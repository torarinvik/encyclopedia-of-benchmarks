const INVALID_RESULT: f64 = -1.0e300;

export fn kendall_rank_correlation_coefficient(values: [*]const i64, length: usize) f64 {
    if (length < 5 or length > 257) return INVALID_RESULT;
    const count = values[0];
    if (count < 2 or count > 128 or length != 1 + 2 * @as(usize, @intCast(count))) return INVALID_RESULT;
    const n: usize = @intCast(count);
    for (0..2 * n) |i| {
        const value = values[1 + i];
        if (value < -1_000_000 or value > 1_000_000) return INVALID_RESULT;
    }

    var concordant: i64 = 0;
    var discordant: i64 = 0;
    var ties_x: i64 = 0;
    var ties_y: i64 = 0;
    for (0..n) |i| {
        for (i + 1..n) |j| {
            const x1 = values[1 + i];
            const x2 = values[1 + j];
            const y1 = values[1 + n + i];
            const y2 = values[1 + n + j];
            if (x1 == x2) ties_x += 1;
            if (y1 == y2) ties_y += 1;
            if ((x1 < x2 and y1 < y2) or (x1 > x2 and y1 > y2)) concordant += 1
            else if ((x1 < x2 and y1 > y2) or (x1 > x2 and y1 < y2)) discordant += 1;
        }
    }
    const pairs: f64 = @floatFromInt(n * (n - 1) / 2);
    const denominator = @sqrt((pairs - @as(f64, @floatFromInt(ties_x))) * (pairs - @as(f64, @floatFromInt(ties_y))));
    if (denominator == 0.0) return INVALID_RESULT;
    return @as(f64, @floatFromInt(concordant - discordant)) / denominator;
}
