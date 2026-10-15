const MAX_LENGTH: usize = 64;
const INVALID_RESULT: f64 = -1.0e300;

export fn autocorrelation(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 4 or length > MAX_LENGTH + 2) return INVALID_RESULT;
    const values = input.?[0..length];
    const count_value = values[0];
    const lag_value = values[1];
    if (count_value < 2 or count_value > MAX_LENGTH or length != @as(usize, @intCast(count_value)) + 2 or
        lag_value < 0 or lag_value >= count_value) return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    const lag: usize = @intCast(lag_value);
    var sum: f64 = 0.0;
    for (0..count) |index| {
        const value = values[index + 2];
        if (value < -1_000 or value > 1_000) return INVALID_RESULT;
        sum += @floatFromInt(value);
    }
    const mean = sum / @as(f64, @floatFromInt(count));
    var variance_sum: f64 = 0.0;
    for (0..count) |index| {
        const difference = @as(f64, @floatFromInt(values[index + 2])) - mean;
        variance_sum += difference * difference;
    }
    if (variance_sum == 0.0) return INVALID_RESULT;
    const variance = variance_sum / @as(f64, @floatFromInt(count));
    var covariance_sum: f64 = 0.0;
    var index = lag;
    while (index < count) : (index += 1) {
        const current = @as(f64, @floatFromInt(values[index + 2])) - mean;
        const delayed = @as(f64, @floatFromInt(values[index - lag + 2])) - mean;
        covariance_sum += current * delayed;
    }
    return (covariance_sum / @as(f64, @floatFromInt(count))) / variance;
}
