const MAX_LENGTH: usize = 256;
const MIN_VALUE: i64 = -2_147_483_648;
const MAX_VALUE: i64 = 2_147_483_647;
const INVALID_RESULT: f64 = -1.0e300;
export fn average_absolute_deviation(values: [*]const i64, length: usize) f64 {
    if (length == 0 or length > MAX_LENGTH) return INVALID_RESULT;
    var sum: f64 = 0.0;
    for (0..length) |index| {
        const value = values[index];
        if (value < MIN_VALUE or value > MAX_VALUE) return INVALID_RESULT;
        sum += @floatFromInt(value);
    }
    const average = sum / @as(f64, @floatFromInt(length));
    var deviations: f64 = 0.0;
    for (0..length) |index| {
        const value: f64 = @floatFromInt(values[index]);
        deviations += if (value >= average) value - average else average - value;
    }
    return deviations / @as(f64, @floatFromInt(length));
}
