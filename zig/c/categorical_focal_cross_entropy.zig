const INVALID_RESULT: f64 = -1.0e300;
export fn categorical_focal_cross_entropy(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 2 or length > 2050) return INVALID_RESULT;
    const batch_value = values[0];
    const classes_value = values[1];
    if (batch_value < 1 or batch_value > 64 or classes_value < 2 or classes_value > 16) return INVALID_RESULT;
    const batch: usize = @intCast(batch_value);
    const classes: usize = @intCast(classes_value);
    const cells = batch * classes;
    if (length != 2 + 2 * cells) return INVALID_RESULT;
    for (0..batch) |row| {
        var label_sum: i64 = 0;
        var probability_sum: i64 = 0;
        for (0..classes) |column| {
            const index = row * classes + column;
            const label = values[2 + index];
            const probability = values[2 + cells + index];
            if (label != 0 and label != 1) return INVALID_RESULT;
            if (probability < 0 or probability > 1000000) return INVALID_RESULT;
            label_sum += label;
            probability_sum += probability;
        }
        if (label_sum != 1 or probability_sum != 1000000) return INVALID_RESULT;
    }
    var total: f64 = 0.0;
    for (0..batch) |row| {
        var row_loss: f64 = 0.0;
        for (0..classes) |column| {
            const index = row * classes + column;
            const label = @as(f64, @floatFromInt(values[2 + index]));
            var probability = @as(f64, @floatFromInt(values[2 + cells + index])) / 1000000.0;
            if (probability < 1e-15) probability = 1e-15;
            if (probability > 1.0 - 1e-15) probability = 1.0 - 1e-15;
            const negative_probability = 1.0 - probability;
            row_loss -= negative_probability * negative_probability * label * @log(probability);
        }
        total += row_loss;
    }
    return total / @as(f64, @floatFromInt(batch));
}
