const MAX_LENGTH: usize = 64;
const MAX_ABS_VALUE: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

export fn variance(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 2 or length > MAX_LENGTH) return INVALID_RESULT;
    var sum: f64 = 0.0;
    for (0..length) |index| {
        const value = values[index];
        if (value < -MAX_ABS_VALUE or value > MAX_ABS_VALUE) return INVALID_RESULT;
        sum += @floatFromInt(value);
    }
    const average = sum / @as(f64, @floatFromInt(length));
    var squared_deviations: f64 = 0.0;
    for (0..length) |index| {
        const difference = @as(f64, @floatFromInt(values[index])) - average;
        squared_deviations += difference * difference;
    }
    return squared_deviations / @as(f64, @floatFromInt(length - 1));
}
