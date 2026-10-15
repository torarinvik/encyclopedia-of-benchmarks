const MAX_LENGTH: usize = 256;
const INVALID_RESULT: f64 = -1.0e300;

export fn mean_absolute_deviation(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 2 or length > MAX_LENGTH + 1) return INVALID_RESULT;
    const values = input.?[0..length];
    const count_value = values[0];
    if (count_value < 1 or count_value > MAX_LENGTH or length != @as(usize, @intCast(count_value)) + 1)
        return INVALID_RESULT;
    const data = values[1..];
    var sum: f64 = 0.0;
    for (data) |value| {
        if (value < -1_000_000 or value > 1_000_000) return INVALID_RESULT;
        sum += @floatFromInt(value);
    }
    const count: f64 = @floatFromInt(data.len);
    const mean = sum / count;
    var absolute_sum: f64 = 0.0;
    for (data) |value| absolute_sum += @abs(@as(f64, @floatFromInt(value)) - mean);
    return absolute_sum / count;
}
