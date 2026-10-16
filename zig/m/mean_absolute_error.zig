const MAX_COUNT: i64 = 256;
const MAX_PARSED_COUNT: i64 = 257;
const MAX_SAMPLE: i64 = 1000000;
const MAX_INPUT_LENGTH: usize = 515;
const INVALID_RESULT: f64 = -1.0e300;

export fn mean_absolute_error(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 1 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const count_value = values[0];
    if (count_value < 0 or count_value > MAX_PARSED_COUNT) return INVALID_RESULT;
    if (length != @as(usize, @intCast(1 + 2 * count_value)) or
        count_value == 0 or count_value > MAX_COUNT) return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    for (0..count * 2) |index| {
        if (values[1 + index] < -MAX_SAMPLE or values[1 + index] > MAX_SAMPLE)
            return INVALID_RESULT;
    }
    var total: f64 = 0.0;
    for (0..count) |index| {
        const true_value = @as(f64, @floatFromInt(values[1 + index])) / 1000000.0;
        const predicted_value = @as(f64, @floatFromInt(values[1 + count + index])) / 1000000.0;
        const difference = true_value - predicted_value;
        const residual = if (difference < 0.0) -difference else difference;
        total += residual;
    }
    return total / @as(f64, @floatFromInt(count));
}
