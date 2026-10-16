const MAX_LENGTH: usize = 62;
const INVALID_RESULT: i64 = -1;

fn type7Quantile(sorted: [*]const i64, count: usize, probability: f64) f64 {
    const h = @as(f64, @floatFromInt(count - 1)) * probability + 1.0;
    const order: usize = @intFromFloat(h);
    const fraction = h - @as(f64, @floatFromInt(order));
    const lower = order - 1;
    if (fraction == 0.0 or lower + 1 >= count) return @floatFromInt(sorted[lower]);
    return (1.0 - fraction) * @as(f64, @floatFromInt(sorted[lower])) + fraction * @as(f64, @floatFromInt(sorted[lower + 1]));
}

export fn iqr_outlier_indices(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_LENGTH) return INVALID_RESULT;
    var sorted: [MAX_LENGTH]i64 = undefined;
    for (0..length) |i| {
        const value = values[i];
        if (value < -1_000_000 or value > 1_000_000) return INVALID_RESULT;
        var position = i;
        while (position > 0 and sorted[position - 1] > value) {
            sorted[position] = sorted[position - 1];
            position -= 1;
        }
        sorted[position] = value;
    }
    const q1 = type7Quantile(&sorted, length, 0.25);
    const q3 = type7Quantile(&sorted, length, 0.75);
    const iqr = q3 - q1;
    const lower_bound = q1 - 1.5 * iqr;
    const upper_bound = q3 + 1.5 * iqr;
    var mask: i64 = 0;
    for (0..length) |i| {
        const value: f64 = @floatFromInt(values[i]);
        if (value < lower_bound or value > upper_bound) mask |= @as(i64, 1) << @intCast(i);
    }
    return mask;
}
