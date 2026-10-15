const MAX_LENGTH: usize = 256;
const INVALID_RESULT: f64 = -1.0e300;

export fn average_margin_ranking_loss(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 5 or length > 2 * MAX_LENGTH + 3) return INVALID_RESULT;
    const values = input.?[0..length];
    const count_value = values[0];
    const margin_value = values[1];
    const label_value = values[2];
    if (count_value < 1 or count_value > MAX_LENGTH or length != 2 * @as(usize, @intCast(count_value)) + 3 or
        margin_value < 0 or margin_value > 1000 or (label_value != 1 and label_value != -1)) return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    var total: f64 = 0.0;
    for (0..count) |index| {
        const first = values[index + 3];
        const second = values[index + 3 + count];
        if (first < -1_000 or first > 1_000 or second < -1_000 or second > 1_000) return INVALID_RESULT;
        const loss = @as(f64, @floatFromInt(margin_value)) - @as(f64, @floatFromInt(label_value)) *
            (@as(f64, @floatFromInt(first)) - @as(f64, @floatFromInt(second)));
        total += @max(loss, 0.0);
    }
    return total / @as(f64, @floatFromInt(count));
}
