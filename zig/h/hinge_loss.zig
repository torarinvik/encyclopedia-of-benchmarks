const MAX_COUNT: usize = 256;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_COUNT;
const PREDICTION_SCALE: f64 = 1_000_000.0;
const INVALID_RESULT: f64 = -1.0e300;

export fn hinge_loss(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 3 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const count_value = values[0];
    if (count_value < 1 or count_value > MAX_COUNT) return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    if (length != 1 + 2 * count) return INVALID_RESULT;

    var total: f64 = 0.0;
    for (0..count) |index| {
        const label = values[1 + index];
        const score_scaled = values[1 + count + index];
        if ((label != -1 and label != 1) or score_scaled < -1_000_000 or score_scaled > 1_000_000) return INVALID_RESULT;
        const prediction = @as(f64, @floatFromInt(score_scaled)) / PREDICTION_SCALE;
        const loss = 1.0 - @as(f64, @floatFromInt(label)) * prediction;
        if (loss > 0.0) total += loss;
    }
    return total / @as(f64, @floatFromInt(count));
}
