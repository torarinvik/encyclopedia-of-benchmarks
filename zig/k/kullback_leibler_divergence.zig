const MAX_COUNT: i64 = 64;
const MAX_INPUT_LENGTH: usize = 129;
const SCALE: f64 = 1_000_000.0;
const INVALID_RESULT: f64 = -1.0e300;

export fn kullback_leibler_divergence(values: [*]const i64, length: usize) f64 {
    if (length < 3 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const count_value = values[0];
    if (count_value < 1 or count_value > MAX_COUNT or length != 1 + 2 * @as(usize, @intCast(count_value))) {
        return INVALID_RESULT;
    }
    const count: usize = @intCast(count_value);
    for (0..count) |i| {
        const target = values[1 + i];
        const prediction = values[1 + count + i];
        if (target < 0 or target > 1_000_000 or prediction < 0 or prediction > 1_000_000 or
            (target > 0 and prediction == 0)) return INVALID_RESULT;
    }
    var total: f64 = 0.0;
    for (0..count) |i| {
        const target_scaled = values[1 + i];
        if (target_scaled == 0) continue;
        const prediction_scaled = values[1 + count + i];
        const target = @as(f64, @floatFromInt(target_scaled)) / SCALE;
        const prediction = @as(f64, @floatFromInt(prediction_scaled)) / SCALE;
        total += target * @log(target / prediction);
    }
    return total;
}
