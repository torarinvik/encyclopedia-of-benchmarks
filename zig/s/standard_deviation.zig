const MAX_LENGTH: usize = 64;
const MAX_ABS_VALUE: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

export fn standard_deviation(values: [*]const i64, length: usize) f64 {
    if (length == 0 or length > MAX_LENGTH) return INVALID_RESULT;
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
        squared_deviations += @pow(difference, 2.0);
    }
    return @sqrt(squared_deviations / @as(f64, @floatFromInt(length)));
}
