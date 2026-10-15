const MAX_OBSERVATIONS: usize = 128;
const INVALID_RESULT: f64 = -1.0e300;

export fn linear_regression_ols(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 5 or length > 257 or length % 2 == 0) return INVALID_RESULT;
    const values = input.?[0..length];
    const count_value = values[0];
    if (count_value < 2 or count_value > MAX_OBSERVATIONS) return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    if (length != 1 + 2 * count) return INVALID_RESULT;

    var sum_x: f64 = 0.0;
    var sum_y: f64 = 0.0;
    for (0..count) |index| {
        const x = values[1 + 2 * index];
        const y = values[2 + 2 * index];
        if (x < -1_000_000 or x > 1_000_000 or y < -1_000_000 or y > 1_000_000) return INVALID_RESULT;
        sum_x += @floatFromInt(x);
        sum_y += @floatFromInt(y);
    }
    const mean_x = sum_x / @as(f64, @floatFromInt(count));
    const mean_y = sum_y / @as(f64, @floatFromInt(count));
    var covariance: f64 = 0.0;
    var variance_x: f64 = 0.0;
    var variance_y: f64 = 0.0;
    for (0..count) |index| {
        const dx = @as(f64, @floatFromInt(values[1 + 2 * index])) - mean_x;
        const dy = @as(f64, @floatFromInt(values[2 + 2 * index])) - mean_y;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if (variance_x <= 1e-12 or variance_y <= 1e-12) return INVALID_RESULT;
    return covariance / variance_x;
}
