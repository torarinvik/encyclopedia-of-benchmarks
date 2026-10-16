const MAX_COUNT: usize = 256;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_COUNT;
const INVALID_RESULT: f64 = -1.0e300;

export fn gaussian_negative_log_likelihood_loss(values: [*]const i64, length: usize) f64 {
    if (length < 4 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const count_value = values[0];
    if (count_value < 1 or count_value > MAX_COUNT) return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    if (length != 1 + 3 * count) return INVALID_RESULT;
    var total: f64 = 0.0;
    for (0..count) |i| {
        const y_scaled = values[1 + i];
        const mu_scaled = values[1 + count + i];
        const variance_nano = values[1 + 2 * count + i];
        if (y_scaled < -1_000_000 or y_scaled > 1_000_000 or mu_scaled < -1_000_000 or mu_scaled > 1_000_000 or
            variance_nano < 1 or variance_nano > 1_000_000_000) return INVALID_RESULT;
        const y = @as(f64, @floatFromInt(y_scaled)) / 1_000_000.0;
        const mu = @as(f64, @floatFromInt(mu_scaled)) / 1_000_000.0;
        var variance = @as(f64, @floatFromInt(variance_nano)) / 1_000_000_000.0;
        if (variance < 1e-6) variance = 1e-6;
        const residual = y - mu;
        const loss_var = 0.5 * @log(variance);
        const loss_exp = 0.5 * ((residual * residual) / variance);
        total += loss_var + loss_exp;
    }
    return total / @as(f64, @floatFromInt(count));
}
