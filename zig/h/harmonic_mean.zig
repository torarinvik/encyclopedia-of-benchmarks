const MAX_LENGTH: usize = 64;
const INVALID_RESULT: f64 = -1.0e300;

export fn harmonic_mean(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length == 0 or length > MAX_LENGTH) return INVALID_RESULT;
    const values = input.?[0..length];
    var reciprocal_sum: f64 = 0.0;
    for (values) |value| {
        if (value < 1 or value > 1000) return INVALID_RESULT;
        reciprocal_sum += 1.0 / @as(f64, @floatFromInt(value));
    }
    return @as(f64, @floatFromInt(length)) / reciprocal_sum;
}
