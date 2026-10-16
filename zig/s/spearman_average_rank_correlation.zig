const INVALID_RESULT: f64 = -1.0e300;

fn averageRank(samples: [*]const i64, count: usize, index: usize) f64 {
    var less: i64 = 0;
    var equal: i64 = 0;
    for (0..count) |j| {
        if (samples[j] < samples[index]) less += 1;
        if (samples[j] == samples[index]) equal += 1;
    }
    return @as(f64, @floatFromInt(less)) + (@as(f64, @floatFromInt(equal)) + 1.0) / 2.0;
}

export fn spearman_average_rank_correlation(values: [*]const i64, length: usize) f64 {
    if (length < 5 or length > 257) return INVALID_RESULT;
    const count = values[0];
    if (count < 2 or count > 128 or length != 1 + 2 * @as(usize, @intCast(count))) return INVALID_RESULT;
    const n: usize = @intCast(count);
    for (0..2 * n) |i| {
        const value = values[1 + i];
        if (value < -1_000_000 or value > 1_000_000) return INVALID_RESULT;
    }
    const x_values = values + 1;
    const y_values = values + 1 + n;
    const mean_rank = (@as(f64, @floatFromInt(n)) + 1.0) / 2.0;
    var covariance: f64 = 0.0;
    var variance_x: f64 = 0.0;
    var variance_y: f64 = 0.0;
    for (0..n) |i| {
        const dx = averageRank(x_values, n, i) - mean_rank;
        const dy = averageRank(y_values, n, i) - mean_rank;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if (variance_x == 0.0 or variance_y == 0.0) return INVALID_RESULT;
    return covariance / @sqrt(variance_x * variance_y);
}
