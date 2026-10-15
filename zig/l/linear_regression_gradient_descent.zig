const INVALID_RESULT: f64 = -1.0e300;

export fn linear_regression_gradient_descent(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 7 or length > 131 or length % 2 == 0) return INVALID_RESULT;
    const values = input.?[0..length];
    const count_value = values[0];
    const rate_microunits = values[1];
    const epochs_value = values[2];
    if (count_value < 2 or count_value > 64 or rate_microunits < 1 or rate_microunits > 1000 or epochs_value < 1 or epochs_value > 10_000) return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    if (length != 3 + 2 * count) return INVALID_RESULT;
    const epochs: usize = @intCast(epochs_value);
    for (0..count) |index| {
        const x = values[3 + 2 * index];
        const y = values[4 + 2 * index];
        if (x < -10 or x > 10 or y < -100 or y > 100) return INVALID_RESULT;
    }

    const alpha = @as(f64, @floatFromInt(rate_microunits)) / 1_000_000.0;
    const scale = alpha / @as(f64, @floatFromInt(count));
    var slope: f64 = 0.0;
    var intercept: f64 = 0.0;
    for (0..epochs) |_| {
        var slope_gradient: f64 = 0.0;
        var intercept_gradient: f64 = 0.0;
        for (0..count) |index| {
            const x = @as(f64, @floatFromInt(values[3 + 2 * index]));
            const y = @as(f64, @floatFromInt(values[4 + 2 * index]));
            const error = slope * x + intercept - y;
            slope_gradient += error * x;
            intercept_gradient += error;
        }
        slope -= scale * slope_gradient;
        intercept -= scale * intercept_gradient;
    }
    return slope;
}
