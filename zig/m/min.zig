const MAX_VALUES: usize = 256;
const INVALID_RESULT: i64 = -9223372036854775807 - 1;

export fn min_values(values: [*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_VALUES + 1) return INVALID_RESULT;
    const count = values[0];
    if (count < 1 or count > MAX_VALUES or length != @as(usize, @intCast(count)) + 1) return INVALID_RESULT;
    var result = values[1];
    if (result < -2147483648 or result > 2147483647) return INVALID_RESULT;
    for (2..length) |index| {
        const value = values[index];
        if (value < -2147483648 or value > 2147483647) return INVALID_RESULT;
        if (value < result) result = value;
    }
    return result;
}
