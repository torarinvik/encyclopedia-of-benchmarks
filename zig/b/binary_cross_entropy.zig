const INVALID_RESULT: f64 = -1.0e300;
export fn binary_cross_entropy(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 1 or length > 513) return INVALID_RESULT;
    const count_value = values[0];
    if (count_value < 1 or count_value > 256 or length != @as(usize, @intCast(1 + 2 * count_value))) return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    for (0..count) |index| {
        const label = values[1 + index];
        const probability = values[1 + count + index];
        if ((label != 0 and label != 1) or probability < 0 or probability > 1000000) return INVALID_RESULT;
    }
    var total: f64 = 0.0;
    for (0..count) |index| {
        const label = @as(f64, @floatFromInt(values[1 + index]));
        var probability = @as(f64, @floatFromInt(values[1 + count + index])) / 1000000.0;
        if (probability < 1e-15) probability = 1e-15;
        if (probability > 1.0 - 1e-15) probability = 1.0 - 1e-15;
        total -= label * @log(probability) + (1.0 - label) * @log(1.0 - probability);
    }
    return total / @as(f64, @floatFromInt(count));
}
