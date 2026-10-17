const invalid: f64 = -1.0e300;

export fn mean_bias_deviation_percent(input: [*c]const i64, length: usize) f64 {
    if (input == null or length < 1 or length > 131) return invalid;
    if (input[0] < 1 or input[0] > 64) return invalid;
    const count: usize = @intCast(input[0]);
    if (length != 1 + 2 * count) return invalid;
    var difference_sum: i64 = 0;
    var actual_sum: i64 = 0;
    for (0..count) |index| {
        const prediction = input[1 + index];
        const actual = input[1 + count + index];
        if (prediction < -1000 or prediction > 1000 or actual < -1000 or actual > 1000) return invalid;
        difference_sum += prediction - actual;
        actual_sum += actual;
    }
    if (actual_sum == 0) return invalid;
    const numerator = @as(f64, @floatFromInt(difference_sum)) / @as(f64, @floatFromInt(count));
    const denominator = @as(f64, @floatFromInt(actual_sum)) / @as(f64, @floatFromInt(count));
    return numerator / denominator * 100.0;
}
