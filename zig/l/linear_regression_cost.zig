const MAX_OBSERVATIONS: usize = 64;
const MAX_FEATURES: usize = 16;
const MAX_INPUT_LENGTH: usize = 2 + MAX_OBSERVATIONS * MAX_FEATURES + MAX_FEATURES + MAX_OBSERVATIONS;
const INVALID_RESULT: f64 = -1.0e300;

export fn linear_regression_cost(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > MAX_OBSERVATIONS or
        values[1] < 1 or values[1] > MAX_FEATURES) return INVALID_RESULT;
    const observations: usize = @intCast(values[0]);
    const features: usize = @intCast(values[1]);
    const matrix_length = observations * features;
    if (length != 2 + matrix_length + features + observations) return INVALID_RESULT;
    for (values[2..]) |value| if (value < -1000 or value > 1000) return INVALID_RESULT;

    const weights_start = 2 + matrix_length;
    const targets_start = weights_start + features;
    var squared_error_sum: f64 = 0.0;
    for (0..observations) |row| {
        var prediction: f64 = 0.0;
        const row_start = 2 + row * features;
        for (0..features) |column| {
            prediction += @as(f64, @floatFromInt(values[row_start + column])) *
                          @as(f64, @floatFromInt(values[weights_start + column]));
        }
        const residual = prediction - @as(f64, @floatFromInt(values[targets_start + row]));
        squared_error_sum += residual * residual;
    }
    return squared_error_sum / (2.0 * @as(f64, @floatFromInt(observations)));
}
