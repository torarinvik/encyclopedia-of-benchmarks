const MAX_COUNT: i64 = 64;
const MAX_INPUT_LENGTH: usize = 130;
const SCALE: f64 = 1_000_000.0;
const EPSILON: f64 = 1e-5;
const INVALID_RESULT: f64 = -1.0e300;

export fn kl_divergence_loss(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const values = input.?[0..length];
    const actual_count_value = values[0];
    const predicted_count_value = values[1];
    if (actual_count_value < 0 or actual_count_value > MAX_COUNT or
        predicted_count_value < 0 or predicted_count_value > MAX_COUNT) return INVALID_RESULT;
    const actual_count: usize = @intCast(actual_count_value);
    const predicted_count: usize = @intCast(predicted_count_value);
    if (length != 2 + actual_count + predicted_count) return INVALID_RESULT;
    for (values[2 .. 2 + actual_count]) |value| {
        if (value < 0 or value > 1_000_000) return INVALID_RESULT;
    }
    for (values[2 + actual_count ..]) |value| {
        if (value < 0 or value > 1_000_000) return INVALID_RESULT;
    }

    const paired_count = @min(actual_count, predicted_count);
    var total: f64 = 0.0;
    for (0..paired_count) |index| {
        const actual = @as(f64, @floatFromInt(values[2 + index])) / SCALE + EPSILON;
        const predicted = @as(f64, @floatFromInt(values[2 + actual_count + index])) / SCALE + EPSILON;
        total += actual * @log(actual / predicted);
    }
    return total;
}
