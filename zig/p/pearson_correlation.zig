const MAX_OBSERVATIONS: usize = 128;
const MAX_ABS_VALUE: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

export fn pearson_correlation(values: [*]const i64, length: usize) f64 {
    if (length < 5 or length > 257) return INVALID_RESULT;
    const count = values[0];
    if (count < 2 or count > MAX_OBSERVATIONS or length != 1 + 2 * @as(usize, @intCast(count))) return INVALID_RESULT;
    const n: usize = @intCast(count);

    var sum_x: f64 = 0.0;
    var sum_y: f64 = 0.0;
    for (0..n) |i| {
        const x = values[1 + i];
        const y = values[1 + n + i];
        if (x < -MAX_ABS_VALUE or x > MAX_ABS_VALUE or y < -MAX_ABS_VALUE or y > MAX_ABS_VALUE) return INVALID_RESULT;
        sum_x += @as(f64, @floatFromInt(x));
        sum_y += @as(f64, @floatFromInt(y));
    }
    const mean_x = sum_x / @as(f64, @floatFromInt(count));
    const mean_y = sum_y / @as(f64, @floatFromInt(count));
    var covariance: f64 = 0.0;
    var variance_x: f64 = 0.0;
    var variance_y: f64 = 0.0;
    for (0..n) |i| {
        const dx = @as(f64, @floatFromInt(values[1 + i])) - mean_x;
        const dy = @as(f64, @floatFromInt(values[1 + n + i])) - mean_y;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if (variance_x == 0.0 or variance_y == 0.0) return INVALID_RESULT;
    return covariance / @sqrt(variance_x * variance_y);
}
