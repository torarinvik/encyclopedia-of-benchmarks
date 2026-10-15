const MAX_INPUT_LENGTH: usize = 4096;
const MAX_ABS_VALUE: i64 = 1_000_000_000;
const INVALID_RESULT: f64 = -1.0e300;

export fn average(values: [*]const i64, length: usize) f64 {
    if (length == 0 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    var sum: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < -MAX_ABS_VALUE or value > MAX_ABS_VALUE) return INVALID_RESULT;
        sum += value;
    }
    return @as(f64, @floatFromInt(sum)) / @as(f64, @floatFromInt(length));
}
