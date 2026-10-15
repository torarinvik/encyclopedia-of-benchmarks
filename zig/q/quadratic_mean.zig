const MAX_LENGTH: usize = 64;
const INVALID_RESULT: f64 = -1.0e300;

export fn quadratic_mean(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length == 0 or length > MAX_LENGTH) return INVALID_RESULT;
    const values = input.?[0..length];
    var square_sum: f64 = 0.0;
    for (values) |value| {
        if (value < -1_000 or value > 1_000) return INVALID_RESULT;
        const converted: f64 = @floatFromInt(value);
        square_sum += converted * converted;
    }
    return @sqrt(square_sum / @as(f64, @floatFromInt(length)));
}
