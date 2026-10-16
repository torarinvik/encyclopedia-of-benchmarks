/// Exact-equality reciprocal progression predicate for IEEE-754 inputs.
const MAX_VALUES = 32;
const INVALID_RESULT: f64 = -1.0e300;

export fn is_harmonic_series(values: ?[*]const i64, length: usize) f64 {
    if (values == null or length < 2 or length > MAX_VALUES + 1) return INVALID_RESULT;
    const input = values.?;
    const count_value = input[0];
    if (count_value < 1 or count_value > MAX_VALUES or length != @as(usize, @intCast(count_value + 1)))
        return INVALID_RESULT;

    var reciprocals: [MAX_VALUES]f64 = undefined;
    const count: usize = @intCast(count_value);
    for (0..count) |index| {
        const value: f64 = @bitCast(input[index + 1]);
        if (value == 0.0) return INVALID_RESULT;
        reciprocals[index] = 1.0 / value;
    }
    if (count == 1) return 1.0;
    const common_difference = reciprocals[1] - reciprocals[0];
    for (2..count) |index| {
        if (reciprocals[index] - reciprocals[index - 1] != common_difference) return 0.0;
    }
    return 1.0;
}
