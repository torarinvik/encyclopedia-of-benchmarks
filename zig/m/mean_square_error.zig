const MAX_LENGTH: usize = 256;
const INVALID_RESULT: f64 = -1.0e300;

export fn mean_square_error(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 3 or length > 2 * MAX_LENGTH + 1) return INVALID_RESULT;
    const values = input.?[0..length];
    const count_value = values[0];
    if (count_value < 1 or count_value > MAX_LENGTH or length != 2 * @as(usize, @intCast(count_value)) + 1)
        return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    var error_sum: f64 = 0.0;
    for (0..count) |index| {
        const predicted = values[index + 1];
        const expected = values[index + 1 + count];
        if (predicted < -1_000_000 or predicted > 1_000_000 or expected < -1_000_000 or expected > 1_000_000)
            return INVALID_RESULT;
        const difference: f64 = @floatFromInt(expected - predicted);
        error_sum += difference * difference;
    }
    return error_sum / @as(f64, @floatFromInt(count));
}
