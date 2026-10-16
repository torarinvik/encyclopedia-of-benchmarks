const SCALE: i64 = 1_000_000;
const MAX_PAIRS: i64 = 64;
const MAX_PARSED_PAIRS: i64 = 65;
const MAX_SAMPLE: i64 = 1_000_000_000;
const MAX_DELTA: i64 = 1_000_000_000;
const MAX_INPUT_LENGTH: usize = 133;
const INVALID_RESULT: f64 = -1.0e300;

export fn huber_loss(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 3 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const delta_value = values[0];
    const true_count = values[1];
    const pred_count = values[2];
    if (delta_value < 0 or delta_value > MAX_DELTA or
        true_count < 0 or true_count > MAX_PARSED_PAIRS or
        pred_count < 0 or pred_count > MAX_PARSED_PAIRS) return INVALID_RESULT;
    if (length != @as(usize, @intCast(3 + true_count + pred_count)) or
        true_count != pred_count or pred_count == 0 or true_count > MAX_PAIRS) return INVALID_RESULT;

    const count: usize = @intCast(true_count);
    for (0..count * 2) |index| {
        if (values[3 + index] < -MAX_SAMPLE or values[3 + index] > MAX_SAMPLE)
            return INVALID_RESULT;
    }
    const delta = @as(f64, @floatFromInt(delta_value)) / @as(f64, @floatFromInt(SCALE));
    var total_loss: f64 = 0.0;
    for (0..count) |index| {
        const true_value = @as(f64, @floatFromInt(values[3 + index])) / @as(f64, @floatFromInt(SCALE));
        const predicted_value = @as(f64, @floatFromInt(values[3 + count + index])) / @as(f64, @floatFromInt(SCALE));
        const difference = true_value - predicted_value;
        const residual = if (difference < 0.0) -difference else difference;
        if (residual <= delta) total_loss += 0.5 * (residual * residual)
        else total_loss += delta * residual - 0.5 * (delta * delta);
    }
    return total_loss / @as(f64, @floatFromInt(count));
}
